<%@ Page language="c#" Codebehind="email-configure.aspx.cs" AutoEventWireup="false" Inherits="Bandl.VaultLedger.Web.UI.email_configure" %>
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
                    <h1>Email Server</h1>
                    Set the name of the SMTP relay mail server to use as well as the email address 
                    from which to send email alerts.
                    <div id="headerConstants"><A class="headerLink" id="arrow" style="LEFT: 635px" href="index.aspx">Tools 
                            Menu</A></div>
                </div> <!-- end pageHeader //--><asp:placeholder id="PlaceHolder1" runat="server" EnableViewState="False"></asp:placeholder>
                <div class="contentArea" id="contentBorderTop">
                    <div class="content" id="accountDetail">
                        <table cellSpacing="0" cellPadding="0" width="724" border="0">
                            <tr height="24">
                                <td class="leftPad" width="105"><b>Server Name:</b></td>
                                <td><asp:textbox id="txtServerName" runat="server" CssClass="medium"></asp:textbox></td>
                            </tr>
                            <tr height="24">
                                <td class="leftPad" width="105"><b>From Address:</b></td>
                                <td><asp:textbox id="txtFromAddress" runat="server" CssClass="medium"></asp:textbox></td>
                            </tr>
                        </table>
                    </div>
                    <div class="contentBoxBottom"><input class="formBtn btnSmall" onclick="showMsgBox('msgBoxTo')" type="button" value="Test">
                    </div>
                </div> <!-- end contentArea //--></div> <!-- end contentWrapper //-->
            <div class="msgBox" id="msgBoxTo" style="DISPLAY:none">
                <h1><%= ProductName %></h1>
                <div class="msgBoxBody">Supply an email address to which the test email should be 
                    sent:
                    <br>
                    <br>
                    <asp:textbox id="txtToAddress" runat="server" CssClass="medium"></asp:textbox></div>
                <div class="msgBoxFooter">
                    <asp:Button ID="DoTest" CssClass="formBtn btnSmallTop" Text="OK" Runat="server"></asp:Button>
                    &nbsp; <input class="formBtn btnSmallTop" onclick="hideMsgBox('msgBoxTo')" type="button" value="Cancel">
                </div>
            </div>
            <div class="msgBox" id="msgBoxTest" style="DISPLAY: none">
                <h1><%= ProductName %></h1>
                <div class="msgBoxBody">The test email appears to have been sent 
                    successfully.&nbsp;&nbsp;It is recommended that you check the inbox of the test 
                    email recipient to verify that the message was received.
                    <br>
                    <br>
                    <br>
                    Save these email server parameters?
                </div>
                <div class="msgBoxFooter">
                    <asp:Button ID="SaveButton" Runat="server" Text="OK" CssClass="formBtn btnSmallTop"></asp:Button>
                    &nbsp; <input class="formBtn btnSmallTop" type="button" value="Cancel" onclick="hideMsgBox('msgBoxTest')">
                </div>
            </div>
            <div class="msgBoxSmall" id="msgBoxPassword" style="DISPLAY: none">
                <h1><%= ProductName %></h1>
                <div class="msgBoxBody">Please supply the password that
                    <%= ProductName %>
                    requires to change the email server parameters.
                    <br>
                    <br>
                    <asp:TextBox id="txtPassword" CssClass="medium" runat="server"></asp:TextBox>
                </div>
                <div class="msgBoxFooter" style="margin-top:10px">
                    <asp:Button ID="DoPassword" Runat="server" Text="OK" CssClass="formBtn btnMediumTop"></asp:Button>
                    &nbsp; <input type="button" value="Cancel" class="formBtn btnMediumTop" onclick="hideMsgBox('msgBoxPassword')">
                </div>
            </div>
            <div class="msgBoxSmall" id="msgBoxSuccess" style="DISPLAY:none">
                <h1><%= ProductName %></h1>
                <div class="msgBoxBody">Email server parameters were saved successfully.</div>
                <div class="msgBoxFooter">
                    <asp:Button ID="DoRedirect" Runat="server" Text="OK" CssClass="formBtn btnSmallTop"></asp:Button>
                </div>
            </div>
            <div class="msgBoxSmall" id="msgBoxPasswordFail" style="DISPLAY:none">
                <h1><%= ProductName %></h1>
                <div class="msgBoxBody">The password supplied was incorrect. Please try again.</div>
                <div class="msgBoxFooter">
                    <input class="formBtn btnSmallTop" type="button" value="OK" onclick="doPassword()">
                </div>
            </div>
        </form>
        <script type="text/javascript">
        function doPassword()
        {
            hideMsgBox('msgBoxPasswordFail');
            showMsgBox('msgBoxPassword');
        }
        </script>
    </body>
</HTML>
