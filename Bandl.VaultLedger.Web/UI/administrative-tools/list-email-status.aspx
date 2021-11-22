<%@ Page language="c#" Codebehind="list-email-status.aspx.cs" AutoEventWireup="false" Inherits="Bandl.VaultLedger.Web.UI.list_email_status" %>
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
                    <h1><asp:Label id="lblTitle" runat="server">Email Status Notifications</asp:Label></h1>
                    Send email alerts to specified groups when a list status changes.
                    <div id="headerConstants"><a class="headerLink" style="left:635px" id="arrow" href="index.aspx">Tools Menu</a></div>
                </div> <!-- end pageHeader //-->
                <asp:placeholder id="PlaceHolder1" runat="server" EnableViewState="False"></asp:placeholder>
                <div class="tabNavigation fourTabs" >
                    <div class="tabs fourTabOne"><A href="list-statuses.aspx">Statuses Employed</A></div>
                    <div class="tabs fourTabTwoSelected"><A href="#">Email Status Notifications</A></div>
                    <div class="tabs fourTabThree"><A href="list-email-alert.aspx">Email Overdue Alerts</A></div>
                    <div class="tabs fourTabFour"><A href="list-purge.aspx">Purge Preferences</A></div>
                </div>
                <div class="contentArea contentBorderTopNone">
                    <div class="contentBoxTop">
                        <div class="floatRight">
                            <asp:button id="btnEmail" runat="server" Text="Configure Email" CssClass="formBtn btnLargeTop"></asp:button>
                        </div>
                        <table cellSpacing="0" cellPadding="0" border="0">
                            <tr>
                                <td width="140"><asp:dropdownlist id="ddlListType" runat="server" CssClass="selectAction">
                                        <asp:ListItem Value="-Choose a List Type-">-Choose a List Type-</asp:ListItem>
                                        <asp:ListItem Value="Shipping">Shipping</asp:ListItem>
                                        <asp:ListItem Value="Receiving">Receiving</asp:ListItem>
                                        <asp:ListItem Value="Disaster">Disaster Recovery</asp:ListItem>
                                    </asp:dropdownlist></td>
                                <td width="40">&nbsp;
                                    <asp:button id="btnGo" runat="server" Text="Go" CssClass="formBtn btnSmallGo"></asp:button>
                                </td>
                            </tr>
                        </table>
                    </div>
                    <!-- end contentTop //-->
                    <div class="content">
                        <asp:table id="Table1" runat="server" CssClass="detailTable" cellspacing="0" BorderWidth="1"
                            style="BORDER-COLLAPSE:collapse">
                            <asp:TableRow CssClass="header">
                                <asp:TableCell style="FONT-WEIGHT:bold" width="150">List Status</asp:TableCell>
                                <asp:TableCell style="FONT-WEIGHT:bold">Email Groups</asp:TableCell>
                            </asp:TableRow>
                        </asp:table>
                    </div> <!-- end content //-->
                </div> <!-- end contentArea //-->
            </div> <!-- end contentWrapper //-->
        </form>
    </body>
</HTML>
