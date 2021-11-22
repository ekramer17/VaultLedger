<%@ Page language="c#" Codebehind="index.aspx.cs" AutoEventWireup="false" Inherits="Bandl.VaultLedger.Web.UI.index" %>
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
                    <h1>Administrative Tools Menu</h1>
                    Set operating parameters, define users, and view accounts.
                </div> <!-- end pageHeader //-->
                <div class="contentArea" id="contentBorderTop">
                    <div class="content" id="subMainMenu">
                        <table border="0" width="725">
                            <tr>
                                <!-- START Bar code formats -->
                                <td width="250" valign="top">
                                    <a href="bar-code-formats.aspx" class="mainMenuHeader">Bar Code Formats</a>
                                    <ul class="menuList">
                                        <li>
                                            <a href="bar-code-formats.aspx?new=1">Add a new bar code format</a></li>
                                        <li>
                                            <a href="bar-code-formats.aspx">View existing bar code formats</a></li>
                                    </ul>
                                </td>
                                <!-- END Bar code formats -->
                                <!-- START Users -->
                                <td width="250" valign="top">
                                    <a href="security.aspx" class="mainMenuHeader">Users</a>
                                    <ul class="menuList">
                                        <li>
                                            <a href="user-detail.aspx">Add a new user</a></li>
                                        <li>
                                            <a href="security.aspx">View existing users</a></li>
                                    </ul>
                                </td>
                                <!-- END Users -->
                                <!-- START Site maps -->
                                <td valign="top">
                                    <a href="view-sites.aspx" class="mainMenuHeader">Site Maps</a>
                                    <ul class="menuList">
                                        <li>
                                            <a href="add-sites.aspx">Add a new site map</a></li>
                                        <li>
                                            <a href="view-sites.aspx">View existing site maps</a></li>
                                    </ul>
                                </td>
                                <!-- END Site maps -->
                            </tr>
                            <tr>
                                <!-- START Case formats -->
                                <td valign="top">
                                    <a href="case-formats.aspx" class="mainMenuHeader">Case Formats</a>
                                    <ul class="menuList">
                                        <li>
                                            <a href="case-formats.aspx?new=1">Add a new case format</a></li>
                                        <li>
                                            <a href="case-formats.aspx">View existing case formats</a></li>
                                    </ul>
                                </td>
                                <!-- END Case formats -->
                                <!-- START Accounts -->
                                <td valign="top">
                                    <a href="accounts.aspx" class="mainMenuHeader">Accounts</a>
                                    <ul class="menuList" id="accountList" runat="server">
                                        <li>
                                            <a href="account-detail.aspx">Add a new account</a></li>
                                        <li>
                                            <a href="accounts.aspx">View existing accounts</a></li>
                                    </ul>
                                </td>
                                <!-- END Accounts -->
                                <!-- START System Parameters -->
                                <td valign="top">
                                    <a href="system-defaults.aspx" class="mainMenuHeader">Preferences</a>
                                    <ul class="menuList">
                                        <li>
                                            <a href="system-defaults.aspx">General preferences</a></li>
                                        <li>
                                            <a href="audit-expirations.aspx">Audit trail expirations</a></li>
                                        <li>
                                            <a href="list-statuses.aspx" id="listOption" runat="server">List preferences and 
                                                statuses</a></li>
                                    </ul>
                                </td>
                                <!-- END System Parameters -->
                            </tr>
                            <tr>
                                <!-- START Email groups -->
                                <td width="250" valign="top" id="emailSection" runat="server">
                                    <a href="email-groups.aspx" class="mainMenuHeader">Email Groups</a>
                                    <ul class="menuList">
                                        <li>
                                            <a href="email-group-detail.aspx">Add a new email group</a></li>
                                        <li>
                                            <a href="email-groups.aspx">View existing email groups</a></li>
                                    </ul>
                                </td>
                                <!-- END Email groups -->
                                <!-- START Ftp profiles -->
                                <td width="250" valign="top" id="ftpSection" runat="server">
                                    <a href="ftp-profiles.aspx" class="mainMenuHeader">Ftp Profiles</a>
                                    <ul class="menuList">
                                        <li>
                                            <a href="ftp-detail.aspx">Add a new ftp profile</a></li>
                                        <li>
                                            <a href="ftp-profiles.aspx">View existing ftp profiles</a></li>
                                    </ul>
                                </td>
                                <!-- END Ftp profiles -->
                                <td valign="top"></td>
                            </tr>
                        </table>
                    </div> <!-- end content //-->
                </div> <!-- end contentArea // -->
            </div> <!-- end contentWrapper // -->
        </form>
    </body>
</HTML>
