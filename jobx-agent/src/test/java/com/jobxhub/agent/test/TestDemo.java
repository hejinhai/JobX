package com.jobxhub.agent.test;

import org.junit.Test;
import com.jobxhub.common.util.SystemPropertyUtils;

import java.io.File;

public class TestDemo {

    @Test
    public void test1(){

        File file = new File("/");
        for (File item:file.listFiles()) {
            if (!item.isHidden()) {
                if (item.isDirectory()) {
                    System.out.println(item.getAbsolutePath()+"---");
                }else {
                    System.out.println(item.getAbsolutePath());
                }
            }
        }
    }
}