<%@ Import Namespace="System.Data" %>
<%@ Page language="c#" Codebehind="report-list-three.aspx.cs" AutoEventWireup="false" Inherits="Bandl.VaultLedger.Web.UI.report_list_three" %>
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
                    <h1>Administrator Reports</h1>
                    Select a report to produce
                </div>
                <asp:placeholder id="PlaceHolder1" runat="server" EnableViewState="False"></asp:placeholder>
                <!-- Three tabs //-->
                <div class="tabNavigation threeTabs" id="threeTabs" runat="server">
                    <div class="tabs" id="threeTabOne">
                        <A href="report-list.aspx">Operator Reports</A>
                    </div>
                    <div class="tabs" id="threeTabTwo">
                        <A href="report-list-two.aspx">Auditor Reports</A>
                    </div>
                    <div class="tabs" id="threeTabThreeSelected">
                        <A href="#">Administrator Reports</A>
                    </div>
                </div>
                <!-- Content //-->
                <div class="topContentArea">
                    <table height="50">
                        <tr>
                            <td><asp:LinkButton id="linkBarCodeMedium" runat="server">Bar Code Formats Report</asp:LinkButton></td>
                        </tr>
						<tr>
							<td>&nbsp;</td>
						</tr>                        
                        <tr>
                            <td><asp:LinkButton id="linkBarCodeCase" runat="server">Case Formats Report</asp:LinkButton></td>
                        </tr>
						<tr>
							<td>&nbsp;</td>
						</tr>                        
                        <tr>
                            <td><asp:LinkButton id="linkExternalSite" runat="server">Site Maps Lists Report</asp:LinkButton></td>
                        </tr>
						<tr>
							<td>&nbsp;</td>
						</tr>                        
                        <tr>
                            <td><asp:LinkButton id="linkUserSecurity" runat="server">Users Report</asp:LinkButton></td>
                        </tr>
						<tr>
							<td>&nbsp;</td>
						</tr>                        
                        <tr>
                            <td><asp:LinkButton id="linkAccounts" runat="server">Accounts Report</asp:LinkButton></td>
                        </tr>
                    </table>
                </div>
            </div>
        </form>
    </body>
</HTML>