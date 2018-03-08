package org.opencron.server.support;

import com.jcraft.jsch.SftpProgressMonitor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.text.DecimalFormat;
import java.util.Timer;
import java.util.TimerTask;


public class SftpMonitor extends TimerTask implements SftpProgressMonitor {

    private static Logger logger = LoggerFactory.getLogger(SftpMonitor.class);

    private long progressInterval = 2 * 1000; // 默认间隔时间为5秒

    private boolean isEnd = false; // 记录传输是否结束

    private long transfered; // 记录已传输的数据总大小

    private long fileSize; // 记录文件总大小

    private Timer timer; // 定时器对象

    private boolean isScheduled = false; // 记录是否已启动timer记时器

    public SftpMonitor(long fileSize) {
        this.fileSize = fileSize;
    }

    @Override
    public void run() {
        if (!isEnd()) { // 判断传输是否已结束
            long transfered = getTransfered();
            if (transfered != fileSize) { // 判断当前已传输数据大小是否等于文件总大小
                sendProgressMessage(transfered);
            } else {
                if (logger.isInfoEnabled()) {
                    logger.info("[opencron] Sftp file transfering is done.");
                }
                setEnd(true); // 如果当前已传输数据大小等于文件总大小，说明已完成，设置end
            }
        } else {
            if (logger.isInfoEnabled()) {
                logger.info("[opencron] Sftp file transfering is done.cancel timer");
            }
            stop(); // 如果传输结束，停止timer记时器
            return;
        }
    }

    public void stop() {
        if (logger.isInfoEnabled()) {
            logger.info("[opencron] Sftp progress monitor Stopping...");
        }
        if (timer != null) {
            timer.cancel();
            timer.purge();
            timer = null;
            isScheduled = false;
        }
        if (logger.isInfoEnabled()) {
            logger.info("[opencron] Sftp progress monitor Stoped.");
        }
    }

    public void start() {
        if (logger.isInfoEnabled()) {
            logger.info("[opencron] Sftp progress monitor Starting...");
        }
        if (timer == null) {
            timer = new Timer();
        }
        timer.schedule(this, 1000, progressInterval);
        isScheduled = true;
    }

    private void sendProgressMessage(long transfered) {
        if (fileSize != 0) {
            double d = ((double) transfered * 100) / (double) fileSize;
            DecimalFormat df = new DecimalFormat("#.##");
            if (logger.isInfoEnabled()) {
                logger.info("[opencron] Sftp Sending progress message: {} %", df.format(d));
            }
        } else {
            if (logger.isInfoEnabled()) {
                logger.info("[opencron] Sftp Sending progress message: ", transfered);
            }
        }
    }

    public boolean count(long count) {
        if (isEnd()) return false;
        if (!isScheduled) {
            start();
        }
        add(count);
        return true;
    }

    public void end() {
        setEnd(true);
    }

    private synchronized void add(long count) {
        transfered = transfered + count;
    }

    private synchronized long getTransfered() {
        return transfered;
    }

    public synchronized void setTransfered(long transfered) {
        this.transfered = transfered;
    }

    private synchronized void setEnd(boolean isEnd) {
        this.isEnd = isEnd;
    }

    private synchronized boolean isEnd() {
        return isEnd;
    }

    public void init(int op, String src, String dest, long max) {
    }
}