<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="cron"  uri="http://www.jobx.org"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/functions" prefix="fn" %>

<!DOCTYPE html>
<html lang="en">
<head>

    <script type="text/javascript">

        function editPwd(id){
            ajax({
                type: "post",
                url:"${contextPath}/user/get.do",
                data:{"id":id}
            },function (data) {
                $("#pwdform")[0].reset();
                if(data!=null){
                    $("#oldpwd").html("");
                    $("#checkpwd").html("");
                    $("#id").val(data.userId);
                    $("#pwdModal").modal("show");
                    return;
                }
            });
        }

        function savePwd(){
            var id = $("#id").val();
            if (!id){
                alert("页面异常，请刷新重试!");
                return false;
            }
            var pwd0 = $("#pwd0").val();
            if (!pwd0){
                alert("请填原密码!");
                return false;
            }
            var pwd1 = $("#pwd1").val();
            if (!pwd1){
                alert("请填新密码!");
                return false;
            }
            if (pwd1.length < 6 || pwd1.length > 15){
                alert("密码长度请在6-15位之间!");
                return false;
            }
            var pwd2 = $("#pwd2").val();
            if (!pwd2){
                alert("请填写确认密码!");
                return false;
            }
            if (pwd2.length < 6 || pwd2.length > 15){
                alert("密码长度请在6-15位之间!");
                return false;
            }
            if (pwd1 != pwd2){
                alert("两密码不一致!");
                return false;
            }
            ajax({
                type: "post",
                url:"${contextPath}/user/pwd.do",
                data:{
                    "id":id,
                    "pwd0":calcMD5(pwd0),
                    "pwd1":calcMD5(pwd1),
                    "pwd2":calcMD5(pwd2)
                }
            },function (data) {
                if (data == "true"){
                    $('#pwdModal').modal('hide');
                    alertMsg("修改成功");
                    return false;
                }
                if(data == "one"){
                    $("#oldpwd").html("<font color='red'>" + '<i class="glyphicon glyphicon-remove-sign"></i>&nbsp;密码不正确' + "</font>");
                    return false;
                }
                if(data == "two"){
                    $("#checkpwd").html("<font color='red'>" + '<i class="glyphicon glyphicon-remove-sign"></i>&nbsp;密码不一致' + "</font>");
                    return false;
                }
            });
        }

        $(document).ready(function(){
            $("#size").change(function(){
                var pageSize = $("#size").val();
                window.location.href = "${contextPath}/user/view.htm?pageSize="+pageSize;
            });

            $("#pwd1").change(function(){
                if ($("#pwd1").val().length < 6 || $("#pwd1").val().length > 15){
                    alert("密码长度请在6-15位之间!");
                    return false;
                }
            });

            $("#pwd0").focus(function(){
                $("#oldpwd").html("");
            });

            $("#pwd2").focus(function(){
                $("#checkpwd").html("");
            });

            $("#pwd0").blur(function(){
                if (!$("#pwd0").val()){
                    $("#oldpwd").html("<font color='red'>" + '<i class="glyphicon glyphicon-remove-sign"></i>&nbsp;请输入原密码' + "</font>");
                }
            });

            $("#pwd2").change(function(){
                if ($("#pwd2").val()==$("#pwd1").val()){
                    $("#checkpwd").html("<font color='green'>" + '<i class="glyphicon glyphicon-ok-sign"></i>&nbsp;两密码一致' + "</font>");
                }else {
                    $("#checkpwd").html("<font color='red'>" + '<i class="glyphicon glyphicon-remove-sign"></i>&nbsp;密码不一致' + "</font>");
                }
            });
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
        <li><a href="">用户管理</a></li>
    </ol>
    <h4 class="page-title"><i aria-hidden="true" class="fa fa-user"></i>&nbsp;用户管理</h4>
    <div class="block-area" id="defaultStyle">

        <div style="float: left">
            <label>
                每页 <select size="1" class="select-jobx" id="size" style="width: 50px;">
                <option value="15">15</option>
                <option value="30" ${pageBean.pageSize eq 30 ? 'selected' : ''}>30</option>
                <option value="50" ${pageBean.pageSize eq 50 ? 'selected' : ''}>50</option>
                <option value="100" ${pageBean.pageSize eq 100 ? 'selected' : ''}>100</option>
            </select> 条记录
            </label>
        </div>

        <div style="float: right;margin-top: -10px">
            <a href="${contextPath}/user/add.htm" class="btn btn-sm m-t-10" style="margin-left: 50px;margin-bottom: 8px"><i class="icon">&#61943;</i>添加</a>
        </div>

        <table class="table tile textured">
            <thead>
            <tr>
                <th>用户名</th>
                <th>用户角色</th>
                <th>真实姓名</th>
                <th>联系方式</th>
                <th>电子邮箱</th>
                <th>QQ号码</th>
                <th class="text-center">操作</th>
            </tr>
            </thead>

            <tbody id="tableContent">

            <c:forEach var="u" items="${pageBean.result}" varStatus="index">
                <tr>
                    <td>${u.userName}</td>
                    <td>${u.roleName}</td>
                    <td>${u.realName}</td>
                    <td>${u.contact}</td>
                    <td>${u.email}</td>
                    <td>${u.qq}</td>
                    <td class="text-center">
                            <a href="#" onclick="editPwd('${u.userId}')" title="修改密码">
                                <i class="glyphicon glyphicon-lock"></i>
                            </a>&nbsp;&nbsp;
                            <a href="${contextPath}/user/edit/${u.userId}.htm" title="编辑资料">
                                <i class="glyphicon glyphicon-pencil"></i>
                            </a>&nbsp;&nbsp;
                            <a href="${contextPath}/user/detail/${u.userId}.htm" title="查看详情">
                                <i class="glyphicon glyphicon-eye-open"></i>
                            </a>
                    </td>
                </tr>
            </c:forEach>
            </tbody>
        </table>

        <cron:pager href="${contextPath}/user/view.htm" id="${pageBean.pageNo}" size="${pageBean.pageSize}" total="${pageBean.totalCount}"/>

    </div>

    <!-- 修改密码弹窗 -->
    <div class="modal fade" id="pwdModal" tabindex="-1" role="dialog" aria-hidden="true">
        <div class="modal-dialog">
            <div class="modal-content">
                <div class="modal-header">
                    <button class="close btn-float" data-dismiss="modal" aria-hidden="true"><i class="md md-close"></i></button>
                    <h4>修改密码</h4>
                </div>
                <div class="modal-body">
                    <form class="form-horizontal" role="form" id="pwdform">
                        <input type="hidden" id="id">
                        <div class="form-group" style="margin-bottom: 4px;">
                            <label for="pwd0" class="col-lab control-label"><i class="glyphicon glyphicon-lock"></i>&nbsp;&nbsp;原&nbsp;&nbsp;密&nbsp;&nbsp;码：</label>
                            <div class="col-md-9">
                                <input type="password" class="form-control " id="pwd0" placeholder="请输入原密码">&nbsp;&nbsp;<label id="oldpwd"></label>
                            </div>
                        </div>
                        <div class="form-group" style="margin-bottom: 20px;">
                            <label for="pwd1" class="col-lab control-label"><i class="glyphicon glyphicon-lock"></i>&nbsp;&nbsp;新&nbsp;&nbsp;密&nbsp;&nbsp;码：</label>
                            <div class="col-md-9">
                                <input type="password" class="form-control " id="pwd1" placeholder="请输入新密码">
                            </div>
                        </div>
                        <div class="form-group">
                            <label for="pwd2" class="col-lab control-label"><i class="glyphicon glyphicon-lock"></i>&nbsp;&nbsp;确认密码：</label>
                            <div class="col-md-9">
                                <input type="password" class="form-control " id="pwd2" placeholder="请输入确认密码"/>&nbsp;&nbsp;<label id="checkpwd"></label>
                            </div>
                        </div>
                    </form>
                </div>
                <div class="modal-footer">
                    <center>
                        <button type="button" class="btn btn-sm"  onclick="savePwd()">保存</button>&nbsp;&nbsp;
                        <button type="button" class="btn btn-sm"  data-dismiss="modal">关闭</button>
                    </center>
                </div>
            </div>
        </div>
    </div>

</section>


</body>

</html>
