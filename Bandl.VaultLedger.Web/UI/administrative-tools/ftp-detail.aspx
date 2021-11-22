<%@ Page language="c#" Codebehind="ftp-detail.aspx.cs" AutoEventWireup="false" Inherits="Bandl.VaultLedger.Web.UI.ftp_detail" %>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<HTML>
    <HEAD>
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
                    <h1><asp:label id="lblPageTitle" runat="server"></asp:label></h1>
                    <asp:label id="lblPageCaption" runat="server">
                       View and, if desired, edit detailed FTP profile information.
                    </asp:label>
                    <div id="headerConstants"><a class="headerLink" style="LEFT:635px" id="arrow" href="ftp-profiles.aspx">Ftp 
                            Profiles</a></div>
                </div>
                <!-- end pageHeader //--><asp:placeholder id="PlaceHolder1" runat="server" EnableViewState="False"></asp:placeholder>
                <div class="contentArea" id="contentBorderTop">
                    <div class="content" id="accountDetail">
                        <table class="accountDetailTable" cellSpacing="0" cellPadding="0" width="724" border="0">
                            <tr vAlign="top">
                                <td class="leftPad" width="168"><b>Profile Name:</b></td>
                                <td width="207"><asp:textbox id="txtName" runat="server" CssClass="medium" tabIndex="1"></asp:textbox></td>
                                <td width="28">&nbsp;</td>
                                <td width="140">&nbsp;</td>
                                <td width="174">&nbsp;</td>
                            </tr>
                            <tr vAlign="top">
                                <td class="leftPad"><b>Server:</b></td>
                                <td><asp:textbox id="txtServer" runat="server" CssClass="medium" tabIndex="2"></asp:textbox></td>
                                <td>&nbsp;</td>
                                <td>&nbsp;</td>
                                <td>&nbsp;</td>
                            </tr>
                            <tr vAlign="top">
                                <td class="leftPad"><b>Login:</b></td>
                                <td><asp:textbox id="txtLogin" runat="server" CssClass="medium" tabIndex="3"></asp:textbox></td>
                                <td>&nbsp;</td>
                                <td><b>Passive Mode:</b></td>
                                <td><asp:dropdownlist id="ddlPassive" runat="server" CssClass="small" tabIndex="6">
                                        <asp:ListItem Value="True">Yes</asp:ListItem>
                                        <asp:ListItem Value="False" Selected="True">No</asp:ListItem>
                                    </asp:dropdownlist></td>
                            </tr>
                            <tr vAlign="top">
                                <td class="leftPad"><b>Password:</b></td>
                                <td><asp:textbox id="txtPassword1" runat="server" CssClass="medium" tabIndex="4" TextMode="Password"></asp:textbox></td>
                                <td>&nbsp;</td>
                                <td><b>Secure Transfer:</b></td>
                                <td><asp:dropdownlist id="ddlSecure" runat="server" CssClass="small" tabIndex="7">
                                        <asp:ListItem Value="True">Yes</asp:ListItem>
                                        <asp:ListItem Value="False" Selected="True">No</asp:ListItem>
                                    </asp:dropdownlist></td>
                            <tr>
                                <td class="leftPad"><b>Confirm Password:</b></td>
                                <td><asp:textbox id="txtPassword2" runat="server" CssClass="medium" tabIndex="5" TextMode="Password"></asp:textbox></td>
                                <td>&nbsp;</td>
                                <td>&nbsp;</td>
                                <td>&nbsp;</td>
                            <tr>
                            </tr>
                            <TR>
                                <td class="tableRowSpacer" colSpan="5"></td>
                            </TR>
                            <tr vAlign="top">
                                <td class="leftPad"><b>File Format:</b></td>
                                <td colSpan="4"><asp:dropdownlist id="ddlFormat" runat="server" width="140" tabIndex="8">
                                        <asp:ListItem Value="0" Selected="True">-Choose a Format-</asp:ListItem>
                                        <asp:ListItem Value="1">Iron Mountain</asp:ListItem>
                                        <asp:ListItem Value="2">Vital Records</asp:ListItem>
                                        <asp:ListItem Value="3">Recall Corporation</asp:ListItem>
                                        <asp:ListItem Value="4">Datasafe</asp:ListItem>
                                    </asp:dropdownlist></td>
                            </tr>
                            <tr vAlign="top">
                                <td class="leftPad"><b>File Path:</b></td>
                                <td colSpan="4"><asp:textbox id="txtFilePath" runat="server" CssClass="medium" tabIndex="9"></asp:textbox></td>
                            </tr>
                        </table>
                    </div>
                    <!-- end content //-->
                    <div class="contentBoxBottom"><asp:button id="btnSave" runat="server" CssClass="formBtn btnSmall" Text="Save" tabIndex="10"></asp:button></div>
                </div>
                <!-- end contentArea //--></div> <!-- end contentWrapper //--></form>
    </body>
</HTML>
