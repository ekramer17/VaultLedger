<%@ Page language="c#" Codebehind="new-case-format.aspx.cs" AutoEventWireup="false" Inherits="Bandl.VaultLedger.Web.UI.new_case_format" %>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<HTML>
    <HEAD>
        <META http-equiv="Content-Type" content="text/html; charset=windows-1252">
        <meta content="Microsoft Visual Studio .NET 7.1" name="GENERATOR">
        <meta content="C#" name="CODE_LANGUAGE">
        <meta content="JavaScript" name="vs_defaultClientScript">
        <meta content="http://schemas.microsoft.com/intellisense/ie5" name="vs_targetSchema">
        <!--#include file = "../includes/baseHead.inc"-->
    </HEAD>
    <body>
        <!--#include file = "../includes/baseBody.inc"-->
        <form id="Form1" method="post" runat="server">
            <div class="contentWrapper">
                <div class="pageHeader">
                    <h1><asp:label id="lblCaption" runat="server"></asp:label></h1>Create
                    a format as a regular expression that will match names of cases within the
                    system.&nbsp;&nbsp;Then associate a case type with that format.
                    <div id="headerConstants"><a class="headerLink" style="left:635px" id="arrow" href="index.aspx">Tools Menu</a></div>
                </div><!-- end pageHeader //-->
                <asp:placeholder id="PlaceHolder1" runat="server" EnableViewState="False"></asp:placeholder>
                <div class="contentArea" id="contentBorderTop">
                    <div class="content" id="accountDetail">
                        <table class="accountDetailTable" cellSpacing="0" cellPadding="0" width="724" border="0">
                            <tr>
                                <td width="130">Case
                                        Format:</td>
                                <td width="210"><asp:textbox id="txtCaseFormat" runat="server" CssClass="medium"></asp:textbox></td>
                                <td><asp:requiredfieldvalidator id="rfvFormat" runat="server" ControlToValidate="txtCaseFormat" ErrorMessage="&nbsp;Please enter a bar code format"></asp:requiredfieldvalidator></td></tr>
                            <tr>
                                <td>Case Type:</td>
                                <td>
                                    <asp:dropdownlist id="ddlCaseType" DataTextField="Name" runat="server" CssClass="medium">
                                        <asp:ListItem Value="-Select Case Type-" Selected="True">-Select Case Type-</asp:ListItem>
                                    </asp:dropdownlist></td>
                                <td><asp:RegularExpressionValidator id="revCaseType" runat="server" ErrorMessage="&nbsp;Please select a case type" ControlToValidate="ddlCaseType" ValidationExpression="^[^\-].*[^\-]$"></asp:RegularExpressionValidator></td></tr></table></div>
                    <!-- end content //-->
                    <div class="contentBoxBottom">
                        <asp:button id="btnSave" runat="server" CssClass="formBtn btnSmall" Text="Save"></asp:button>
                        &nbsp;
                        <input type="button" id="btnCancel" onclick="location.href='case-formats.aspx'" class="formBtn btnMedium" value="Cancel">
                    </div></div><!-- end contentArea //--></div><!-- end contentWrapper //--></form>
    </body>
</HTML>