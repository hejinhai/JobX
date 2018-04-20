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

import com.jobxhub.server.service.ConfigService;
import com.jobxhub.server.service.SchedulerService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

import javax.annotation.PostConstruct;
import javax.annotation.PreDestroy;

@Component
public class JobXInitializer {

    @Autowired
    private ConfigService configService;

    @Autowired
    private SchedulerService schedulerService;

    @Autowired
    private JobXRegistry jobxRegistry;


    @PostConstruct
    public void initialize() throws Exception {
        //初始化数据库...
        configService.initDB();

        //init job...
        schedulerService.initJob();

        this.jobxRegistry.initialize();

        this.jobxRegistry.registryAgent();

        this.jobxRegistry.registryServer();

        this.jobxRegistry.registryJob();

    }

    @PreDestroy
    public void destroy() {
        this.jobxRegistry.destroy();
    }

}
