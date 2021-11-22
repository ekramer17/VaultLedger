<%@ Page language="c#" Codebehind="login.aspx.cs" AutoEventWireup="false" Inherits="Bandl.VaultLedger.Web.UI.Login" %>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<HTML>
    <HEAD>
        <meta content="Microsoft Visual Studio .NET 7.1" name="GENERATOR">
        <meta content="C#" name="CODE_LANGUAGE">
        <meta content="JavaScript" name="vs_defaultClientScript">
        <meta content="http://schemas.microsoft.com/intellisense/ie5" name="vs_targetSchema">
        <!--#include file = "includes/baseHead.inc"-->
    </HEAD>
    <body id="top">
        <!--#include file = "includes/baseBody.inc"-->
        <form id="Form1" method="post" runat="server">
            <div class="contentWrapper"><!-- page header -->
                <div class="pageHeader">
                    <H1><asp:label id="lblPageHeader" runat="server"></asp:label></H1>
                    <asp:label id="lblPageCaption" runat="server"></asp:label>
                </div>
                <asp:placeholder id="PlaceHolder1" runat="server" EnableViewState="False"></asp:placeholder>
                <div class="contentArea" id="contentBorderTop">
                    <div class="content" id="newMedia" runat="server">
                        <div id="normalContent" runat="server">
                            <table cellSpacing="0" cellPadding="0" border="0">
                                <tr>
                                    <td width="130">&nbsp;</td>
                                    <td width="185">&nbsp;</td>
                                    <td width="380">&nbsp;</td>
                                </tr>
                                <tr vAlign="top">
                                    <td style="HEIGHT: 24px"><b>Usercode:</b></td>
                                    <td style="HEIGHT: 24px"><asp:textbox id="txtLogin" runat="server" Width="168px" CssClass="medium"></asp:textbox></td>
                                    <td style="HEIGHT: 24px" valign="center"><asp:label id="lblError1" runat="server" ForeColor="Red" EnableViewState="False"></asp:label></td>
                                </tr>
                                <tr vAlign="top">
                                    <td><b>Password:</b></td>
                                    <td><asp:textbox id="txtPassword" runat="server" Width="168px" CssClass="medium" TextMode="Password"></asp:textbox></td>
                                    <td><asp:label id="lblError2" runat="server" ForeColor="Red" EnableViewState="False"></asp:label></td>
                                </tr>
                            </table>
                        </div>
                        <div id="registerContent" runat="server">
                            <table cellSpacing="0" cellPadding="0" border="0">
                                <tr>
                                    <td width="130">&nbsp;</td>
                                    <td width="185">&nbsp;</td>
                                    <td width="380">&nbsp;</td>
                                </tr>
                                <tr vAlign="top">
                                    <td style="HEIGHT: 36px"><b>Company Name:</b></td>
                                    <td style="HEIGHT: 36px"><asp:textbox id="txtCompany" runat="server" Width="168px" CssClass="medium"></asp:textbox></td>
                                    <td><asp:label id="lblError3" runat="server" ForeColor="Red" EnableViewState="False"></asp:label></td>
                                </tr>
                                <tr vAlign="top">
                                    <td style="HEIGHT: 36px"><b>Contact Name:</b></td>
                                    <td style="HEIGHT: 36px"><asp:textbox id="txtContact" runat="server" Width="168px" CssClass="medium"></asp:textbox></td>
                                    <td><asp:label id="lblError4" runat="server" ForeColor="Red" EnableViewState="False"></asp:label></td>
                                </tr>
                                <tr vAlign="top">
                                    <td style="HEIGHT: 36px"><b>Phone Number:</b></td>
                                    <td style="HEIGHT: 36px"><asp:textbox id="txtPhoneNo" runat="server" Width="168px" CssClass="medium"></asp:textbox></td>
                                    <td><asp:label id="lblError5" runat="server" ForeColor="Red" EnableViewState="False"></asp:label></td>
                                </tr>
                                <tr vAlign="top">
                                    <td style="HEIGHT: 36px"><b>Email:</b></td>
                                    <td style="HEIGHT: 36px"><asp:textbox id="txtEmail" runat="server" Width="168px" CssClass="medium"></asp:textbox></td>
                                    <td><asp:label id="lblError6" runat="server" ForeColor="Red" EnableViewState="False"></asp:label></td>
                                </tr>
                            </table>
                        </div>
                    </div>
                    <div id="entrustContent" runat="server" class="content">
                        <table class="detailTable">
                            <tr>
                                <td style="PADDING-BOTTOM: 15px">
                                    <asp:label id="lblEntrust" runat="server" ForeColor="Red"></asp:label>
                                    <br>
                                    <font color="red">If you are not redirected to the Recall login page within ten 
                                        seconds, please click <a href="http://www.recall.com">here</a>.</font>
                                    <br>
                                </td>
                            </tr>
                        </table>
                    </div>
                    <div class="contentBoxBottom" id="bottomButtons" runat="server">
                        <div id="normalButtons" runat="server">
                            <asp:button id="btnAuthenticate" runat="server" CssClass="formBtn btnSmall" Text="Login" EnableViewState="False"></asp:button>&nbsp;
                            <asp:button id="btnCancel" runat="server" CssClass="formBtn btnSmall" Text="Cancel"></asp:button>
                        </div>
                        <asp:button id="btnRegister" runat="server" CssClass="formBtn btnMedium" Text="Register"></asp:button>
                    </div>
                </div>
                <input id="javaTester" type="hidden" value="false" runat="server" NAME="javaTester"> <input id="localTime" type="hidden" runat="server" NAME="localTime">
                <!-- BEGIN MESSAGE BOX -->
                <div class="msgBoxSmall" id="msgBoxRegister" style="DISPLAY: none">
                    <h1><%= ProductName %></h1>
                    <div class="msgBoxBody">Thank you for registering</div>
                    <div class="msgBoxFooter"><asp:button id="btnOK" runat="server" Text="OK" CssClass="formBtn btnSmallTop"></asp:button></div>
                </div>
            </div>
            <!-- END MESSAGE BOX -->
        </form>
        <script language="javascript">
        function checkText()
        {
            error1 = getObjectById('lblError1');
            error2 = getObjectById("lblError2");
            ctlLogin = getObjectById("txtLogin");
            ctlPassword = getObjectById("txtPassword");
            // Password
            if (ctlPassword.value.length != 0)
            {
                error2.innerHTML = '';
            }
            else
            {
                ctlPassword.focus();
                error2.innerHTML = '&nbsp;Please enter a password';
            }
            // Usercode
            if (ctlLogin.value.length != 0)
            {
                error1.innerHTML = '';
            }
            else
            {
                ctlLogin.focus();
                error1.innerHTML = '&nbsp;Please enter a usercode';
            }
            // Return value
            if (error1.innerHTML.length != 0 || error2.innerHTML.length != 0)
            {
                return false;
            }
            else
            {
                return true;
            }
        }
        // Get local time offset
        getObjectById('javaTester').value = 'true';
        </script>
    </body>
</HTML>
