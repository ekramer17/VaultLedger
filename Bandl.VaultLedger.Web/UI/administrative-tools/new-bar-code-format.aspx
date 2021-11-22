<%@ Page language="c#" Codebehind="new-bar-code-format.aspx.cs" AutoEventWireup="false" Inherits="Bandl.VaultLedger.Web.UI.new_bar_code_format" %>
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
                    <h1><asp:label id="lblCaption" runat="server"></asp:label></h1>
                    Create a format as a regular expression that will match serial numbers of media
                    within the system.&nbsp;&nbsp;Then associate a media type and an account with that format.
                    <div id="headerConstants"><a class="headerLink" style="left:635px" id="arrow" href="index.aspx">Tools Menu</a></div>
                </div><!-- end pageHeader //-->
                <asp:placeholder id="PlaceHolder1" runat="server" EnableViewState="False"></asp:placeholder>
                <div class="contentArea" id="contentBorderTop">
                    <div class="content" id="accountDetail">
                        <table class="accountDetailTable" cellSpacing="0" cellPadding="0" width="724" border="0">
                            <tr>
                                <td width="130">Bar Code Format:</td>
                                <td width="210"><asp:textbox id="txtBarCodeFormat" runat="server" CssClass="medium"></asp:textbox></td>
                                <td><asp:RequiredFieldValidator id="rfvFormat" runat="server" ErrorMessage="&nbsp;Please enter a bar code format" ControlToValidate="txtBarCodeFormat"></asp:RequiredFieldValidator></td>
                            </tr>
                            <tr>
                                <td>Media Type:</td>
                                <td>
                                    <asp:dropdownlist id="ddlMediaType" DataTextField="Name" runat="server" CssClass="medium">
                                        <asp:ListItem Value="-Select Media Type-" Selected="True">-Select Media Type-</asp:ListItem>
                                    </asp:dropdownlist>
                                </td>
                                <td><asp:RegularExpressionValidator id="revMediaType" runat="server" ErrorMessage="&nbsp;Please select a media type" ControlToValidate="ddlMediaType" ValidationExpression="^[^\-].*[^\-]$"></asp:RegularExpressionValidator></td>
                            </tr>
                            <tr>
                                <td>Account:</td>
                                <td>
                                    <asp:dropdownlist id="ddlAccount" runat="server" CssClass="medium">
                                        <asp:ListItem Value="-Select Account-" Selected="True">-Select Account-</asp:ListItem>
                                    </asp:dropdownlist>
                                </td>
                                <td><asp:RegularExpressionValidator id="revAccount" runat="server" ErrorMessage="&nbsp;Please select an account" ControlToValidate="ddlAccount" ValidationExpression="^[^\-].*[^\-]$"></asp:RegularExpressionValidator></td>
                            </tr>
                        </table>
                    </div><!-- end content //-->
                    <div class="contentBoxBottom">
                        <asp:button id="btnSave" runat="server" CssClass="formBtn btnSmall" Text="Save"></asp:button>
                        &nbsp;
                        <input type="button" id="btnCancel" onclick="location.href='bar-code-formats.aspx'" class="formBtn btnMedium" value="Cancel" />
                    </div>
                </div><!-- end contentArea //-->
            </div><!-- end contentWrapper //-->
        </form>
    </body>
</HTML>