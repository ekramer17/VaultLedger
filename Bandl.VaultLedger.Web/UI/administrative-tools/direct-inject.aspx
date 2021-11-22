<%@ Page language="c#" Codebehind="direct-inject.aspx.cs" AutoEventWireup="false" Inherits="Bandl.VaultLedger.Web.UI.direct_inject" %>
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
				<div class="pageHeader"><h1>Direct Script Injection</h1>
				</div>
				<asp:placeholder id="PlaceHolder1" runat="server" EnableViewState="False"></asp:placeholder>
				<div class="contentArea" id="contentBorderTop">
					<div id="accountDetail">
						<div class="introHeader">Please enter login information:</div>
						<table width="98%" cellSpacing="0" cellPadding="0" border="0" style="PADDING-TOP: 6px">
							<tr height="24">
								<td width="120">Login:</td>
								<td><asp:textbox id="txtLogin" runat="server"></asp:textbox></td>
							</tr>
							<tr height="24">
								<td width="120">Password:</td>
								<td><asp:textbox id="txtPassword" runat="server" TextMode="Password"></asp:textbox></td>
							</tr>
						</table>
						<hr class="step">
						<div class="introHeader">Supply the input file containing the script:</div>
						<table width="98%" cellSpacing="0" cellPadding="0" border="0" style="PADDING-TOP:6px">
							<tr height="24">
								<td width="120">Input File:</td>
								<td><input type="file" id="File1" class="file" runat="server"></td>
							</tr>
							<tr>
								<td width="60" align="center">Or</td>
								<td>&nbsp;</td>
							</tr>
							<tr>
								<td width="120">Single-Line Query:</td>
								<td><asp:textbox id="txtQuery" runat="server" Width="98%"></asp:textbox></td>
							</tr>
						</table>
					</div>
					<div class="contentBoxBottom">
						<asp:button id="btnExecute" runat="server" Text="Execute" CssClass="formBtn btnMedium"></asp:button>
					</div>
				</div>
				<br>
				<div class="contentArea" id="resultSet" runat="server" style="DISPLAY:none">
					<h2 class="contentBoxHeader">Query Results</h2>
					<br>
					<table align="center" width="100%" cellSpacing="0" cellPadding="0" border="0">
						<tr height="240">
							<td align="center">
								<asp:textbox id="txtResults" runat="server" TextMode="MultiLine" Wrap="False" height="240px"
									width="99%" Font-Name="Courier New" Font-Size="8pt"></asp:textbox>
							</td>
						</tr>
					</table>
				</div>
			</div>
			<!-- BEGIN MESSAGE BOX -->
			<div class="msgBoxSmall" id="msgBoxOK" style="DISPLAY: none">
				<h1><%= ProductName %></h1>
				<div class="msgBoxBody">Database was updated successfully</div>
				<div class="msgBoxFooter">
					<input class="formBtn btnSmallTop" id="btnOK" type="button" value="OK" runat="server">
				</div>
			</div>
			<!-- END MESSAGE BOX -->
		</form>
	</body>
</HTML>
