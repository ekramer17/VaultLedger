<%@ Page language="c#" Codebehind="report-list.aspx.cs" AutoEventWireup="false" Inherits="Bandl.VaultLedger.Web.UI.report_list" %>
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
					<h1>Operator Reports</h1>
					Select a report to produce
				</div>
				<!-- Three tabs //-->
				<div class="tabNavigation threeTabs" id="threeTabs" runat="server">
					<div class="tabs" id="threeTabOneSelected">
						<A href="#">Operator Reports</A>
					</div>
					<div class="tabs" id="threeTabTwo">
						<A href="report-list-two.aspx">Auditor Reports</A>
					</div>
					<div class="tabs" id="threeTabThree">
						<A href="report-list-three.aspx">Administrator Reports</A>
					</div>
				</div>
				<!-- Two tabs //-->
				<div class="tabNavigation twoTabs" id="twoTabs" runat="server">
					<div class="tabs" id="twoTabOneSelected">
						<A href="#">Operator Reports</A>
					</div>
					<div class="tabs" id="twoTabTwo">
						<A href="report-list-two.aspx">Auditor Reports</A>
					</div>
				</div>
				<!-- One tab //-->
				<div id="oneTab" runat="server">
					<div id="contentBorderTop"></div>
				</div>
				<!-- Content //-->
				<div class="topContentArea">
					<table height="50">
						<tr>
							<td><asp:LinkButton id="LinkMedia" runat="server">Media Report</asp:LinkButton></td>							
						</tr>
						<tr>
							<td>&nbsp;</td>
						</tr>						
						<tr>
							<td><asp:LinkButton id="linkSend" runat="server">Shipping Lists Report</asp:LinkButton></td>
						</tr>
						<tr>
							<td>&nbsp;</td>
						</tr>						
						<tr>
							<td><asp:LinkButton id="linkReceive" runat="server">Receiving Lists Report</asp:LinkButton></td>
						</tr>
						<tr>
							<td>&nbsp;</td>
						</tr>						
						<tr>
							<td><asp:LinkButton id="linkDisaster" runat="server">Disaster Recovery Lists Report</asp:LinkButton></td>
						</tr>
					</table>
				</div>
			</div>
		</form>
	</body>
</HTML>
