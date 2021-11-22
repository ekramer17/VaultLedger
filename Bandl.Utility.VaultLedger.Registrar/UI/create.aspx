<%@ Page language="c#" Codebehind="create.aspx.cs" AutoEventWireup="false" Inherits="Bandl.Utility.VaultLedger.Registrar.UI.create" %>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<HTML>
    <HEAD>
        <meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
        <meta content="http://schemas.microsoft.com/intellisense/ie5" name="vs_targetSchema">
        <!--#include file = "masterHead.inc"-->
    </HEAD>
    <body>
        <!--#include file = "masterBody.inc"-->
        <DIV class="contentWrapper">
            <DIV class="pageHeader">
                <H1>Registration Successful!</H1>
                Your
                <%=ProductName%>
                application has been created successfully and is ready for use.
            </DIV>
            <FORM id="Form1" runat="server">
                <DIV id="contentBorderTop"></DIV>
                <DIV class="contentArea">
                    <TABLE class="detailTable">
                        <tr>
                            <td style="PADDING-BOTTOM: 12px; PADDING-TOP: 12px">
                                Thank you for registering.&nbsp;&nbsp;You should momentarily be receiving an email confirming your <%=ProductName%> registration.
                                <br>
                                <br>
                                When you are ready, click Go to access the <%=ProductName%> login page.&nbsp;&nbsp;To log in, please use the following login and password:
                                <br>
                                <br>
                                <table cellpadding="0" cellspacing="0" width="95%" border="0">
                                    <tr>
                                        <td width="75px">Login:</td>
                                        <td><%=Uid%></td>
                                    </tr>
                                    <tr>
                                        <td width="75px">Password:</td>
                                        <td><%=Pwd%></td>
                                    </tr>
                                </table>
                                <br>
                                Once you have logged in, you may change the login and password to something more meaningful.
                            </td>
                        </tr>
                    </TABLE>
                </DIV>
                <DIV style="MARGIN-TOP: 10px" align="right">
                    <asp:button id="btnGo" runat="server" Text="Go" CssClass="mediumButton" />
                </DIV>
            </FORM>
        </DIV>
    </body>
</HTML>
