<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="cron" uri="http://www.jobx.org" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/functions" prefix="fn" %>

<!DOCTYPE html>
<html lang="en">
<head>
    <script type="text/javascript" src="${contextPath}/static/js/ztree/jquery.ztree.core.min.js?resId=${resourceId}"></script> <!-- jQuery Library -->
    <link rel="stylesheet" href="${contextPath}/static/js/ztree/css/zTreeStyle/zTreeStyle.css" type="text/css">
    <script type="text/javascript" src="${contextPath}/static/js/ztree/jquery.ztree.excheck.min.js"></script>
    <script type="text/javascript" src="${contextPath}/static/js/ztree/jquery.ztree.exedit.min.js"></script>

    <style type="text/css">
        #sortJob{
            background-color: rgba(0, 0, 0, 0.3);
            border-radius: 13px;
            width:450px;
        }
        .ztree li a {
            color: #fff;
        }

        .ztree li a.curSelectedNode {
            background:none;
            color:white;
            border:none;
        }
        .ztree li span.button.ico_open { margin-right:2px;background: url('/static/img/folder-close.png') no-repeat scroll 0 0 transparent; vertical-align:top; *vertical-align:middle}
        .ztree li span.button.ico_close { margin-right:2px;background: url('/static/img/folder-close.png') no-repeat scroll 0 0 transparent; vertical-align:top; *vertical-align:middle}
        .ztree li span.button.ico_docu { margin-right:2px;background: url('/static/img/folder-close.png') no-repeat scroll 0 0 transparent; vertical-align:top; *vertical-align:middle}
        /*.ztree li span.switch.root_open {background-image: none}
        .ztree li span.switch.roots_open {background-image:none}
        .ztree li span.switch.bottom_open{background-image: none}*/
    </style>

    <script type="text/javascript" src="${contextPath}/static/js/job.validata.js"></script>

    <script type="text/javascript">
        var setting = {
            edit: {
                enable: true,
                showRemoveBtn: function(treeId, treeNode) {
                    return treeNode.id != 0;
                },
                showRenameBtn: false,
                drag:{
                    inner:true,
                    prev:true,
                    next:true,
                    isMove:true
                }
            },
            data: {
                simpleData: {
                    enable: true
                }
            },
            callback: {
                beforeDrag: beforeDrag,
                beforeDrop: beforeDrop,
                beforeRemove:function(treeId, treeNode){
                    if (treeNode.id == 0 ) {
                        return false;
                    }
                },
                onClick: onClick,
                beforeCollapse:function () {
                    return true;
                }
            }
        };

        function beforeDrag(treeId, treeNodes) {
            for (var i=0,l=treeNodes.length; i<l; i++) {
                if (treeNodes[i].drag === false) {
                    return false;
                }
            }
            return true;
        }
        function beforeDrop(treeId, treeNodes, targetNode, moveType) {
            return targetNode ? targetNode.drop !== false : true;
        }

        function addNode(id,name) {
            var zTree = $.fn.zTree.getZTreeObj("sortJob");
            zTree.addNodes(null, {id:id, pId:0, name:name,drag:true});
        }

        function onClick(event, treeId, treeNode, clickFlag) {
            if (treeNode.id != 0) {
                jobxValidata.subJob.edit(treeNode.id);
                $('#jobModal').modal('show');
            }
        }

        $(document).ready(function(){
            window.jobxValidata = new Validata('${contextPath}');
            var currentJob = [{ id:0, pId:0, name:"当前作业", open:true,showRemoveBtn:false}];
            $.fn.zTree.init($("#sortJob"), setting,currentJob );
        });
    </script>

</head>

<body>
<!-- Content -->
<section id="content" class="container">

    <!-- Messages Drawer -->
    <jsp:include page="/WEB-INF/layouts/message.jsp"/>

    <!-- Breadcrumb -->
    <ol class="breadcrumb hidden-xs">
        <li class="icon">&#61753;</li>
        当前位置：
        <li><a href="">jobx</a></li>
        <li><a href="">作业管理</a></li>
        <li><a href="">添加作业</a></li>
    </ol>
    <h4 class="page-title"><i class="fa fa-plus" aria-hidden="true"></i>&nbsp;添加作业</h4>

    <div style="float: right;margin-top: 5px">
        <a onclick="goback();" class="btn btn-sm m-t-10" style="margin-right: 16px;margin-bottom: -4px"><i class="fa fa-mail-reply" aria-hidden="true"></i>&nbsp;返回</a>
    </div>

    <div class="block-area" id="basic">
        <div class="tile p-15 textured">
            <form class="form-horizontal" role="form" id="jobform" action="${contextPath}/job/save.do" method="post"></br>
                <input type="hidden" name="command" id="command">
                <div class="form-group">
                    <label for="agentId" class="col-lab control-label wid150"><i class="glyphicon glyphicon-leaf"></i>&nbsp;&nbsp;执&nbsp;&nbsp;行&nbsp;&nbsp;器&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</label>
                    <div class="col-md-10">
                        <c:if test="${empty agent}">
                            <select id="agentId" name="agentId" class="form-control m-b-10 input-sm">
                                <c:forEach var="d" items="${agents}">
                                    <option value="${d.agentId}">${d.host}&nbsp;(${d.name})</option>
                                </c:forEach>
                            </select>
                        </c:if>
                        <c:if test="${!empty agent}">
                            <input type="hidden" id="agentId" name="agentId" value="${agent.agentId}">
                            <input type="text" class="form-control input-sm" value="${agent.name}&nbsp;&nbsp;&nbsp;${agent.host}" readonly>
                            <font color="red">&nbsp;*只读</font>
                        </c:if>
                        <span class="tips">&nbsp;&nbsp;要执行此作业的机器名称和Host</span>
                    </div>
                </div>

                <div class="form-group">
                    <label for="jobName" class="col-lab control-label wid150"><i class="glyphicon glyphicon-tasks"></i>&nbsp;&nbsp;作业名称&nbsp;&nbsp;<b>*&nbsp;</b></label>
                    <div class="col-md-10">
                        <input type="text" class="form-control input-sm" id="jobName" name="jobName">
                        <span class="tips" tip="必填项,该作业的名称">必填项,该作业的名称</span>
                    </div>
                </div>

                <div class="form-group cronExpDiv">
                    <label class="col-lab control-label wid150"><i class="glyphicon glyphicon-bookmark"></i>&nbsp;&nbsp;规则类型&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</label>
                    <div class="col-md-10">
                        <label for="cronType0" class="radio-label"><input type="radio" name="cronType" value="0" id="cronType0" checked>crontab&nbsp;&nbsp;&nbsp;</label>
                        <label for="cronType1" class="radio-label"><input type="radio" name="cronType" value="1" id="cronType1">quartz</label>&nbsp;&nbsp;&nbsp;
                        </br><span class="tips" id="cronTip" tip="crontab: unix/linux的时间格式表达式">crontab: unix/linux的时间格式表达式</span>
                    </div>
                </div>

                <div class="form-group cronExpDiv">
                    <label for="cronExp" class="col-lab control-label wid150"><i class="glyphicon glyphicon-filter"></i>&nbsp;&nbsp;时间规则&nbsp;&nbsp;<b>*&nbsp;</b></label>
                    <div class="col-md-10">
                        <input type="text" class="form-control input-sm" id="cronExp" name="cronExp">
                        <span class="tips" id="expTip" tip="请采用unix/linux的时间格式表达式,如 00 01 * * *">请采用unix/linux的时间格式表达式,如 00 01 * * *</span>
                    </div>
                </div>

                <div id="cronSelector" class="form-group cronExpDiv" style="display: none;">
                    <label class="col-lab control-label wid150">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</label>
                    <div class="col-md-10">
                        <select id="year" size="8" multiple="multiple" style="width:75px;">
                            <option value="*" selected="selected">每年</option>
                            <c:forEach var="i" begin="2018" end="2050" step="1">
                                <option value="${i}">${i}年</option>
                            </c:forEach>
                        </select>
                        <select id="month" size="8" multiple="multiple" style="width:75px;">
                            <option value="*" selected="selected">每月</option>
                            <c:forEach var="i" begin="1" end="12" step="1">
                                <option value="${i}">${i}月</option>
                            </c:forEach>
                        </select>
                        <select id="day" size="8" multiple="multiple" style="width:75px;">
                            <option value="*" selected="selected">每日</option>
                            <c:forEach var="i" begin="1" end="31" step="1">
                                <option value="${i}">${i}日</option>
                            </c:forEach>
                        </select>
                        <select id="week" size="8" multiple="multiple" style="width:75px;">
                            <option value="*" selected="selected">每星期</option>
                            <c:forEach var="i" begin="1" end="7" step="1">
                                <option value="${i}">星期${i}</option>
                            </c:forEach>
                        </select>
                        <select id="hour" size="8" multiple="multiple" style="width:75px;">
                            <option value="*" selected="selected">每时</option>
                            <c:forEach var="i" begin="0" end="23" step="1">
                                <option value="${i}">${i}时</option>
                            </c:forEach>
                        </select>
                        <select id="minutes" size="8" multiple="multiple" style="width:75px;">
                            <option value="*" selected="selected">每分</option>
                            <c:forEach var="i" begin="0" end="59" step="1">
                                <option value="${i}">${i}分</option>
                            </c:forEach>
                        </select>
                        <select id="seconds" size="8" multiple="multiple" style="width:75px;">
                            <option value="*" >每秒</option>
                            <c:forEach var="i" begin="0" end="59" step="1">
                                <option value="${i}">${i}秒</option>
                            </c:forEach>
                        </select>
                        &nbsp;&nbsp;&nbsp;&nbsp;<button type="button" class="btn btn-sm" id="remove-cron-btn">收起</button>
                    </div>
                </div>

                <br>

                <div class="form-group">
                    <label for="cmd" class="col-lab control-label wid150"><i class="glyphicon glyphicon-th-large"></i>&nbsp;&nbsp;执行命令&nbsp;&nbsp;<b>*&nbsp;</b></label>
                    <div class="col-md-10">
                        <textarea class="form-control input-sm" id="cmd" style="height:200px;resize:vertical"></textarea>
                        <span class="tips" tip="请采用unix/linux的shell支持的命令">请采用unix/linux的shell支持的命令</span>
                    </div>
                </div>

                <div class="form-group">
                    <label for="successExit" class="col-lab control-label wid150"><i class="glyphicons glyphicons-tags"></i>&nbsp;&nbsp;成功标识&nbsp;&nbsp;<b>*&nbsp;</b></label>
                    <div class="col-md-10">
                        <input type="text" class="form-control input-sm" id="successExit" name="successExit" value="0">
                        <span class="tips" tip="自定义作业执行成功的返回标识(默认执行成功是0)">自定义作业执行成功的返回标识(默认执行成功是0)</span>
                    </div>
                </div>
                <br>

                <div class="form-group">
                    <label class="col-lab control-label wid150"><i class="glyphicon  glyphicon glyphicon-forward"></i>&nbsp;&nbsp;失败重跑&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</label>
                    <div class="col-md-10">
                        <label for="redo01" class="radio-label"><input type="radio" name="redo" value="1" id="redo01">是&nbsp;&nbsp;&nbsp;</label>
                        <label for="redo00" class="radio-label"><input type="radio" name="redo" value="0" id="redo00" checked>否</label>&nbsp;&nbsp;&nbsp;
                        <br><span class="tips">执行失败时是否自动重新执行</span>
                    </div>
                </div>

                <div class="form-group countDiv">
                    <label for="runCount" class="col-lab control-label wid150"><i class="glyphicon glyphicon-repeat"></i>&nbsp;&nbsp;重跑次数&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</label>
                    <div class="col-md-10">
                        <input type="text" class="form-control input-sm" id="runCount" name="runCount">
                        <span class="tips" tip="执行失败时自动重新执行的截止次数">执行失败时自动重新执行的截止次数</span>
                    </div>
                </div>

                <div class="form-group">
                    <label for="timeout" class="col-lab control-label wid150"><i class="glyphicon glyphicon-ban-circle"></i>&nbsp;&nbsp;超时时间&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</label>
                    <div class="col-md-10">
                        <input type="text" class="form-control input-sm" id="timeout" name="timeout" value="0">
                        <span class="tips" tip="执行作业允许的最大时间,超过则为超时(0:忽略超时时间,分钟为单位)">执行作业允许的最大时间,超过则为超时(0:忽略超时时间,分钟为单位)</span>
                    </div>
                </div>

                <div class="form-group">
                    <label class="col-lab control-label wid150"><i class="glyphicon  glyphicon-random"></i>&nbsp;&nbsp;作业类型&nbsp;&nbsp;<b>*&nbsp;</b></label>
                    <div class="col-md-10">
                        <label for="jobType0" class="radio-label"><input type="radio" name="jobType" value="0" id="jobType0" checked>单一作业&nbsp;&nbsp;&nbsp;</label>
                        <label for="jobType1" class="radio-label"><input type="radio" name="jobType" value="1" id="jobType1">流程作业</label>&nbsp;&nbsp;&nbsp;
                        <br><span class="tips" id="jobTypeTip">单一作业: 当前定义作业为要执行的目标&nbsp;流程作业: 有多个作业组成作业组</span>
                    </div>
                </div>

                <div class="form-group">
                    <span class="subJob" style="display: none">
                        <label class="col-lab control-label wid150"><i class="glyphicon glyphicon-sort"></i>&nbsp;&nbsp;作业依赖&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</label>
                        <div class="col-md-10" style="top: -5px;">
                            <a data-toggle="modal" href="#jobModal" onclick="jobxValidata.subJob.add()" class="btn btn-sm m-t-10">添加作业依赖</a>
                        </div>
                         <div class="col-md-10" style="top:5px;margin-left:150px;">
                            <ul id="sortJob" class="ztree"></ul>
                            <ul id="subJobDiv" style="display: none;"></ul>
                        </div>
                    </span>
                </div>

                <div class="form-group">
                    <label class="col-lab control-label wid150"><i class="glyphicon glyphicon-warning-sign"></i>&nbsp;&nbsp;失败报警&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</label>
                    <div class="col-md-10">
                        <label for="warning1" class="radio-label"><input type="radio" name="warning" value="1" id="warning1" checked>是&nbsp;&nbsp;&nbsp;</label>
                        <label for="warning0" class="radio-label"><input type="radio" name="warning" value="0" id="warning0">否</label>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
                        </br><span class="tips" tip="任务执行失败时是否发信息报警">任务执行失败时是否发信息报警</span>
                    </div>
                </div>

                <div class="form-group contact">
                    <label for="mobiles" class="col-lab control-label wid150"><i class="glyphicon glyphicon-comment"></i>&nbsp;&nbsp;报警手机&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</label>
                    <div class="col-md-10">
                        <input type="text" class="form-control input-sm" id="mobiles" name="mobiles">
                        <span class="tips" tip="任务执行失败时将发送短信给此手机,多个请以逗号(英文)隔开">任务执行失败时将发送短信给此手机,多个请以逗号(英文)隔开</span>
                    </div>
                </div>

                <div class="form-group contact">
                    <label for="email" class="col-lab control-label wid150"><i class="glyphicon glyphicon-envelope"></i>&nbsp;&nbsp;报警邮箱&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</label>
                    <div class="col-md-10">
                        <input type="text" class="form-control input-sm" id="email" name="emailAddress">
                        <span class="tips" tip="任务执行失败时将发送报告给此邮箱,多个请以逗号(英文)隔开">任务执行失败时将发送报告给此邮箱,多个请以逗号(英文)隔开</span>
                    </div>
                </div>
                <br>

                <div class="form-group">
                    <label for="comment" class="col-lab control-label wid150"><i class="glyphicon glyphicon-magnet"></i>&nbsp;&nbsp;描&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;述&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</label>
                    <div class="col-md-10">
                        <textarea class="form-control input-sm" id="comment" name="comment" style="height: 50px;"></textarea>
                    </div>
                </div>

                <div class="form-group">
                    <div class="col-md-offset-1 col-md-10">
                        <button type="button" id="save-btn" class="btn btn-sm m-t-10"><i class="icon">&#61717;</i>&nbsp;保存</button>&nbsp;&nbsp;
                        <button type="button" onclick="history.back()" class="btn btn-sm m-t-10"><i class="icon">&#61740;</i>&nbsp;取消</button>
                    </div>
                </div>
            </form>
        </div>
    </div>

    <%--添加流程作业弹窗--%>
    <div class="modal fade" id="jobModal" tabindex="-1" role="dialog" aria-hidden="true">
        <div class="modal-dialog">
            <div class="modal-content">
                <div class="modal-header">
                    <button class="close btn-float" data-dismiss="modal" aria-hidden="true"><i class="md md-close"></i>
                    </button>
                    <h4 id="subTitle" action="add" tid="">添加作业依赖</h4>
                </div>
                <div class="modal-body">
                    <form class="form-horizontal" role="form" id="subForm"><br>

                        <input type="hidden" id="itemRedo" value="1"/>
                        <div class="form-group">
                            <label for="agentId1" class="col-lab control-label wid100" title="要执行此作业的机器名称和IP地址">执&nbsp;&nbsp;行&nbsp;&nbsp;器&nbsp;&nbsp;&nbsp;</label>
                            <div class="col-md-9">
                                <select id="agentId1" name="agentId1" class="form-control m-b-10 ">
                                    <c:forEach var="d" items="${agents}">
                                        <option value="${d.agentId}">${d.host}&nbsp;(${d.name})</option>
                                    </c:forEach>
                                </select>
                            </div>
                        </div>

                        <div class="form-group">
                            <label for="jobName1" class="col-lab control-label wid100" title="作业名称必填">作业名称&nbsp;<b>*</b></label>
                            <div class="col-md-9">
                                <input type="text" class="form-control " id="jobName1">
                                <span class="tips" tip="必填项,该作业的名称">必填项,该作业的名称</span>
                            </div>
                        </div>

                        <div class="form-group">
                            <label for="cmd1" class="col-lab control-label wid100" title="请采用unix/linux的shell支持的命令">执行命令&nbsp;<b>*</b></label>
                            <div class="col-md-9">
                                <textarea class="form-control" id="cmd1" name="cmd1" style="height:100px;resize:vertical"></textarea>
                                <span class="tips" tip="请采用unix/linux的shell支持的命令">请采用unix/linux的shell支持的命令</span>
                            </div>
                        </div>

                        <div class="form-group">
                            <label for="successExit1" class="col-lab control-label wid100">成功标识&nbsp;<b>*</b></label>
                            <div class="col-md-9">
                                <input type="text" class="form-control" id="successExit1" name="successExit1" value="0">
                                <span class="tips" tip="自定义作业执行成功的返回标识(默认执行成功是0)">自定义作业执行成功的返回标识(默认执行成功是0)</span>
                            </div>
                        </div>
                        <br>

                        <div class="form-group">
                            <label class="col-lab control-label wid100" title="执行失败时是否自动重新执行">失败重跑&nbsp;&nbsp;&nbsp;</label>&nbsp;&nbsp;
                            <label for="redo1" class="radio-label"><input type="radio" name="itemRedo" id="redo1" checked> 是&nbsp;&nbsp;&nbsp;</label>
                            <label for="redo0" class="radio-label"><input type="radio" name="itemRedo" id="redo0">否</label><br>
                        </div>
                        <br>
                        <div class="form-group countDiv1">
                            <label for="runCount1" class="col-lab control-label wid100" title="执行失败时自动重新执行的截止次数">重跑次数&nbsp;&nbsp;&nbsp;</label>&nbsp;&nbsp;
                            <div class="col-md-9">
                                <input type="text" class="form-control " id="runCount1"/>
                                <span class="tips" tip="执行失败时自动重新执行的截止次数">执行失败时自动重新执行的截止次数</span>
                            </div>
                        </div>

                        <div class="form-group">
                            <label for="timeout1" class="col-lab control-label wid100">超时时间&nbsp;<b>*</b></label>
                            <div class="col-md-9">
                                <input type="text" class="form-control" id="timeout1" value="0">
                                <span class="tips" tip="执行作业允许的最大时间,超过则为超时(0:忽略超时时间,分钟为单位)">执行作业允许的最大时间,超过则为超时(0:忽略超时时间,分钟为单位)</span>
                            </div>
                        </div>
                        <br>

                        <div class="form-group">
                            <label for="comment1" class="col-lab control-label wid100" title="此作业内容的描述">描&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;述&nbsp;&nbsp;&nbsp;</label>&nbsp;&nbsp;
                            <div class="col-md-9">
                                <input type="text" class="form-control " id="comment1"/>&nbsp;
                            </div>
                        </div>
                    </form>
                </div>
                <div class="modal-footer">
                    <center>
                        <button type="button" class="btn btn-sm" id="subjob-btn">保存</button>&nbsp;&nbsp;
                        <button type="button" class="btn btn-sm" data-dismiss="modal">关闭</button>
                    </center>
                </div>
            </div>
        </div>
    </div>

</section>

</body>

</html>
