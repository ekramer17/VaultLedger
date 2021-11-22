<%@ Page language="c#" Codebehind="report-list-two.aspx.cs" AutoEventWireup="false" Inherits="Bandl.VaultLedger.Web.UI.report_list_two" %>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<HTML>
    <HEAD>
        <META http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
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
                <!-- page header -->
                <div class="pageHeader">
                    <h1>Auditor Reports</h1>
                    Select a report to produce
                </div>
                <!-- Three tabs //-->
                <div class="tabNavigation threeTabs" id="threeTabs" runat="server">
                    <div class="tabs" id="threeTabOne"><A href="report-list.aspx">Operator Reports</A>
                    </div>
                    <div class="tabs" id="threeTabTwoSelected"><A href="#">Auditor Reports</A>
                    </div>
                    <div class="tabs" id="threeTabThree"><A href="report-list-three.aspx">Administrator 
                            Reports</A>
                    </div>
                </div>
                <!-- Two tabs //-->
                <div class="tabNavigation twoTabs" id="twoTabs" runat="server">
                    <div class="tabs" id="twoTabOne"><A href="report-list.aspx">Operator Reports</A>
                    </div>
                    <div class="tabs" id="twoTabTwoSelected"><A href="#">Auditor Reports</A>
                    </div>
                </div>
                <div class="topContentArea">
                    <table height="50">
                        <tr>
                            <td width="220"><asp:linkbutton id="medium" runat="server">Media History Auditor Report</asp:linkbutton></td>
                            <td width="220"><asp:linkbutton id="sendList" runat="server">Shipping Lists Auditor Report</asp:linkbutton></td>
                            <td width="220"><asp:linkbutton id="externalSite" runat="server">Site Maps Auditor Report</asp:linkbutton></td>
                        </tr>
                        <tr>
                            <td>&nbsp;</td>
                        </tr>
                        <tr>
                            <td><asp:linkbutton id="mediumMovement" runat="server">Media Movement History Auditor Report</asp:linkbutton></td>
                            <td><asp:linkbutton id="receiveList" runat="server">Receiving List Auditor Report</asp:linkbutton></td>
                            <td><asp:linkbutton id="user" runat="server">Users Auditor Report</asp:linkbutton></td>
                        </tr>
                        <tr>
                            <td>&nbsp;</td>
                        </tr>
                        <tr>
                            <td><asp:linkbutton id="sealedCase" runat="server">Sealed Cases Auditor Report</asp:linkbutton></td>
                            <td><asp:linkbutton id="disasterCodeList" runat="server">Disaster Recovery Lists Auditor Report</asp:linkbutton></td>
                            <td><asp:linkbutton id="miscellaneous" runat="server">Miscellaneous Auditor Report</asp:linkbutton></td>
                        </tr>
                        <tr>
                            <td>&nbsp;</td>
                        </tr>
                        <tr>
                            <td><asp:linkbutton id="inventory" runat="server">Inventory Auditor Report</asp:linkbutton></td>
                            <td><asp:linkbutton id="barCodePattern" runat="server">Bar Code Formats Auditor Report</asp:linkbutton></td>
                            <td><asp:linkbutton id="complete" runat="server">Complete Activity Auditor Report</asp:linkbutton></td>
                        </tr>
                        <tr>
                            <td>&nbsp;</td>
                        </tr>
                        <tr>
                            <td><asp:linkbutton id="inventoryConflict" runat="server">Inventory Discrepancy Auditor Report</asp:linkbutton></td>
                            <td><asp:linkbutton id="account" runat="server">Accounts Auditor Report</asp:linkbutton></td>
                            <td>&nbsp;</td>
                        </tr>
                    </table>
                </div>
            </div>
        </form>
    </body>
</HTML>
