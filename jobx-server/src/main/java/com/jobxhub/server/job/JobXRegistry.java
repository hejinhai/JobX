/**
 * Copyright (c) 2015 The JobX Project
 * <p>
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements. See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership. The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License. You may obtain a copy of the License at
 * <p>
 * http://www.apache.org/licenses/LICENSE-2.0
 * <p>
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied. See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

package com.jobxhub.server.job;

import net.sf.ehcache.store.chm.ConcurrentHashMap;
import com.jobxhub.common.Constants;
import com.jobxhub.common.ext.ExtensionLoader;
import com.jobxhub.common.logging.LoggerFactory;
import com.jobxhub.common.util.*;
import com.jobxhub.registry.URL;
import com.jobxhub.registry.api.Registry;
import com.jobxhub.registry.zookeeper.ChildListener;
import com.jobxhub.registry.zookeeper.ZookeeperClient;
import com.jobxhub.registry.zookeeper.ZookeeperRegistry;
import com.jobxhub.registry.zookeeper.ZookeeperTransporter;
import com.jobxhub.server.domain.Agent;
import com.jobxhub.server.domain.Job;
import com.jobxhub.server.service.*;
import com.jobxhub.server.support.JobXTools;
import com.jobxhub.server.vo.JobInfo;
import org.slf4j.Logger;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

import java.util.*;
import java.util.concurrent.locks.Lock;
import java.util.concurrent.locks.ReentrantLock;

import static com.jobxhub.common.util.CommonUtils.toLong;
import static com.jobxhub.common.util.StringUtils.*;
import static com.jobxhub.common.util.StringUtils.line;

/**
 * @author benjobs.
 */

@Component
public class JobXRegistry {

    private static final Logger logger = LoggerFactory.getLogger(JobXRegistry.class);

    @Autowired
    private JobService jobService;

    @Autowired
    private JobXCollector jobxCollector;

    @Autowired
    private AgentService agentService;

    @Autowired
    private SchedulerService schedulerService;

    @Autowired
    private ExecuteService executeService;

    private final URL registryURL = URL.valueOf(PropertyPlaceholder.get(Constants.PARAM_JOBX_REGISTRY_KEY));

    private final String registryPath = Constants.ZK_REGISTRY_SERVER_PATH + "/" + JobXTools.SERVER_ID;

    private ZookeeperTransporter transporter = ExtensionLoader.load(ZookeeperTransporter.class);

    private final Registry registryService = new ZookeeperRegistry(registryURL, transporter);

    private final ZookeeperClient zookeeperClient = registryService.getClient();

    private final Map<String, String> agents = new ConcurrentHashMap<String, String>(0);

    private final Map<Long, Long> jobs = new ConcurrentHashMap<Long, Long>(0);

    private List<String> servers = new ArrayList<String>(0);

    private Integer serverSize = 0;//server集群大小

    private Integer preServerSize = 0;

    //在server销毁之前会将server从zookeeper中移除,这有可能会在此触发回调事件,而回调触发的时候server可能已经终止.
    private volatile boolean destroy = false;

    private Lock lock = new ReentrantLock();

    public JobXRegistry() {

    }

    public void initialize() {
        //server第一次启动检查所有的agent是否可用
        List<Agent> agentList = this.agentService.getAll();
        if (CommonUtils.notEmpty(agentList)) {
            for (Agent agent : agentList) {
                executeService.ping(agent);
            }
        }

        if (!Constants.JOBX_CLUSTER) {
            return;
        }

        //扫描zookeeper里已有的agent,连接....
        List<String> children = this.zookeeperClient.getChildren(Constants.ZK_REGISTRY_AGENT_PATH);
        if (CommonUtils.notEmpty(children)) {
            for (String agent : children) {
                agents.put(agent, agent);
                if (logger.isInfoEnabled()) {
                    logger.info("[JobX] agent auto connected! info:{}", agent);
                }
                agentService.doConnect(agent);
            }
        }
    }

    public void destroy() {
        destroy = true;
        if (logger.isInfoEnabled()) {
            logger.info("[JobX] run destroy now...");
        }

        if (!Constants.JOBX_CLUSTER) return;

        //job unregister
        if (CommonUtils.notEmpty(jobs)) {
            for (Long job : jobs.keySet()) {
                this.registryService.unRegister(Constants.ZK_REGISTRY_JOB_PATH + "/" + job);
            }
        }

        //server unregister
        this.registryService.unRegister(registryPath);
    }

    public void registryAgent() {

        this.zookeeperClient.addChildListener(Constants.ZK_REGISTRY_AGENT_PATH, new ChildListener() {
            @Override
            public void childChanged(String path, List<String> children) {

                lock.lock();

                if (destroy) {
                    return;
                }

                if (agents.isEmpty()) {
                    for (String agent : children) {
                        agents.put(agent, agent);
                        if (logger.isInfoEnabled()) {
                            logger.info("[JobX] agent connected! info:{}", agent);
                        }
                        agentService.doConnect(agent);
                    }
                } else {
                    Map<String, String> unAgents = new ConcurrentHashMap<String, String>(agents);
                    for (String agent : children) {
                        unAgents.remove(agent);
                        if (!agents.containsKey(agent)) {
                            //新增...
                            agents.put(agent, agent);
                            logger.info("[JobX] agent connected! info:{}", agent);
                            agentService.doConnect(agent);
                        }
                    }
                    if (CommonUtils.notEmpty(unAgents)) {
                        for (String child : unAgents.keySet()) {
                            agents.remove(child);
                            logger.info("[JobX] agent doDisconnect! info:{}", child);
                            agentService.doDisconnect(child);
                        }
                    }
                }
                lock.unlock();
            }
        });
    }

    public void registryServer() {

        if (!Constants.JOBX_CLUSTER) {
            return;
        }

        //server监控增加和删除
        this.zookeeperClient.addChildListener(Constants.ZK_REGISTRY_SERVER_PATH, new ChildListener() {
            @Override
            public void childChanged(String path, List<String> children) {

                try {

                    lock.lock();

                    preServerSize = serverSize;

                    serverSize = children.size();

                    if (destroy) {
                        return;
                    }
                    servers = children;
                    //一致性哈希计算出每个Job落在哪个server上
                    ConsistentHash<String> hash = new ConsistentHash<String>(servers);

                    List<Job> jobList = jobService.getScheduleJob();

                    for (Job job : jobList) {
                        Long jobId = job.getJobId();
                        //该任务落在当前的机器上
                        if (!jobs.containsKey(jobId) && JobXTools.SERVER_ID.equals(hash.get(jobId))) {
                            jobDispatch(jobId);
                        } else {
                            jobRemove(jobId);
                        }
                    }
                } catch (Exception e) {
                    e.printStackTrace();
                } finally {
                    lock.unlock();
                }
            }
        });

        //将server加入到注册中心
        this.registryService.register(registryPath, true);

        //register shutdown hook
        Runtime.getRuntime().addShutdownHook(new Thread(new Runnable() {
            @Override
            public void run() {
                if (logger.isInfoEnabled()) {
                    logger.info("[JobX] run shutdown hook now...");
                }
                registryService.unRegister(registryPath);
            }
        }, "JobXShutdownHook"));

    }


    public void registryJob() {

        if (Constants.JOBX_CLUSTER) {
            //job的监控
            this.zookeeperClient.addChildListener(Constants.ZK_REGISTRY_JOB_PATH, new ChildListener() {
                @Override
                public void childChanged(String path, List<String> children) {
                    try {

                        lock.lock();

                        if (destroy) {
                            return;
                        }

                        Map<Long, Long> unJobs = new HashMap<Long, Long>(jobs);

                        ConsistentHash<String> hash = new ConsistentHash<String>(servers);

                        for (String job : children) {

                            Long jobId = toLong(job);
                            unJobs.remove(jobId);
                            if (!jobs.containsKey(jobId) && hash.get(jobId).equals(JobXTools.SERVER_ID)) {
                                jobDispatch(jobId);
                            }

                        }

                        for (Long job : unJobs.keySet()) {
                            jobRemove(job);
                        }

                    } catch (Exception e) {
                        e.printStackTrace();
                    } finally {
                        lock.unlock();
                    }
                }
            });
        } else {
            List<Job> jobList = jobService.getScheduleJob();
            for (Job job : jobList) {
                jobDispatch(job.getJobId());
            }
        }

    }

    //job新增的时候手动触发.....
    public void jobRegister(Long jobId) {
        if (Constants.JOBX_CLUSTER) {
            this.registryService.register(Constants.ZK_REGISTRY_JOB_PATH + "/" + jobId, true);
        } else {
            this.jobDispatch(jobId);
        }
    }

    //job删除的时候手动触发.....
    public void jobUnRegister(Long jobId) {
        if (Constants.JOBX_CLUSTER) {
            this.registryService.unRegister(Constants.ZK_REGISTRY_JOB_PATH + "/" + jobId);
        } else {
            this.jobRemove(jobId);
        }
    }

    public void agentUnRegister(Agent agent) {
        //mac_password
        String registryPath = String.format("%s/%s_%s", Constants.ZK_REGISTRY_AGENT_PATH, agent.getMachineId(), agent.getPassword());
        registryService.unRegister(registryPath);

        registryPath = String.format("%s/%s_%s_%s_%s",
                Constants.ZK_REGISTRY_AGENT_PATH,
                agent.getMachineId(),
                agent.getPassword(),
                agent.getHost(),
                agent.getPort());

        registryService.unRegister(registryPath);
    }

    public void agentRegister(Agent agent) {
        String registryPath = String.format("%s/%s_%s_%s_%s",
                Constants.ZK_REGISTRY_AGENT_PATH,
                agent.getMachineId(),
                agent.getPassword(),
                agent.getHost(),
                agent.getPort());
        registryService.register(registryPath, true);
    }

    /**
     * 作业的分发一定要经过一致性哈希算法,计算是否落在该server上....
     *
     * @param jobId
     */
    private void jobDispatch(Long jobId) {
        try {
            this.lock.lock();
            if (Constants.JOBX_CLUSTER) {
                this.jobs.put(jobId, jobId);
                this.jobUnRegister(jobId);
                this.jobRegister(jobId);
            } else {
                this.jobRemove(jobId);
            }
            JobInfo jobInfo = this.jobService.getJobInfoById(jobId);
            Constants.CronType cronType = Constants.CronType.getByType(jobInfo.getCronType());
            switch (cronType) {
                case CRONTAB:
                    this.jobxCollector.add(jobInfo);
                    break;
                case QUARTZ:
                    this.schedulerService.put(jobInfo);
                    break;
            }
            dispatchedInfo(1, jobId);
        } catch (Exception e) {
            new RuntimeException(e);
        } finally {
            this.lock.unlock();
        }
    }

    private void jobRemove(Long jobId) {
        try {
            this.lock.lock();
            if (Constants.JOBX_CLUSTER) {
                this.jobs.remove(jobId);
            }
            this.jobxCollector.remove(jobId);
            this.schedulerService.remove(jobId);
            dispatchedInfo(0, jobId);
        } catch (Exception e) {
            throw new RuntimeException(e);
        } finally {
            this.lock.unlock();
        }
    }

    /**
     * action 1:addJob
     * 0:removeJob
     *
     * @param action
     */
    private void dispatchedInfo(int action, Long jobId) {
        String headerFormat = line(1) + tab(1);
        String bodyFormat = line(1) + tab(3);
        String endFormat = line(2);

        String infoFormat = headerFormat + "███████████████ [JOBX] serverChanged,print dispatched info ███████████████" +
                bodyFormat + "datetime: \"{}\"" +
                bodyFormat + "previous serverSize:{}" +
                bodyFormat + "current serverSize:{}" +
                bodyFormat + "action:{}" +
                bodyFormat + "jobId:{}" +
                bodyFormat + "totalJobs:[ {} ]" + endFormat;

        logger.info(
                infoFormat,
                DateUtils.formatFullDate(new Date()),
                this.preServerSize,
                this.serverSize,
                action == 0 ? " removeJob " : "addJob",
                jobId,
                StringUtils.join(this.jobs.keySet().toArray(new Long[0]), "|")
        );
    }

}
    
