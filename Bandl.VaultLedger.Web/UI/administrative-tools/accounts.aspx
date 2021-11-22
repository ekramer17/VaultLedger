<%@ Page language="c#" Codebehind="accounts.aspx.cs" AutoEventWireup="false" Inherits="Bandl.VaultLedger.Web.UI.accounts" %>
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
					<h1>Accounts</h1>
					These are the accounts for which media are currently being 
					tracked.&nbsp;&nbsp;To view the details of a particular account, click its 
					account number.<asp:label id="lblPageCaption" runat="server"></asp:label>
					<div id="headerConstants">
                        <a style="left:580px" class="headerLink" id="arrow" href="index.aspx">Tools Menu</a>
					    <asp:linkbutton id="printLink" runat="server" CssClass="headerLink">Print</asp:linkbutton>
					</div>
				</div>
				<!-- end pageHeader //-->
				<asp:placeholder id="PlaceHolder1" runat="server" EnableViewState="False"></asp:placeholder>
				<div class="contentArea" id="contentBorderTop">
					<div class="contentBoxTop textLeft" align="left">
						<table style="width:100%">
							<tr>
								<td align="left">
									<asp:button id="btnDelete" runat="server" Text="Delete Selected" CssClass="formBtn btnLargeTop"></asp:button>
								</td>
								<td align="right">
									<asp:button id="btnNew" runat="server" Text="New Account" CssClass="formBtn btnLargeTop"></asp:button>
									<asp:button id="btnUpdate" runat="server" Text="Update Accounts" CssClass="formBtn btnLargeTopPlus"></asp:button>
								</td>
							</tr>
						</table>
					</div> <!-- end contentBoxTop //-->
					<div class="content"><asp:datagrid id="DataGrid1" runat="server" CssClass="detailTable" AutoGenerateColumns="False">
							<AlternatingItemStyle CssClass="alternate"></AlternatingItemStyle>
							<HeaderStyle CssClass="header"></HeaderStyle>
							<Columns>
								<asp:TemplateColumn>
                                    <HeaderStyle CssClass="checkbox"></HeaderStyle>
                                    <ItemStyle CssClass="checkbox"></ItemStyle>
									<HeaderTemplate>
										<input id="cbCheckAll" onclick="checkAll('DataGrid1', 'cbItemChecked', this.checked)" type="checkbox"
											runat="server" NAME="cbCheckAll" />
									</HeaderTemplate>
									<ItemTemplate>
										<input id="cbItemChecked" onclick="checkFirst('DataGrid1', 'cbCheckAll', false)" type="checkbox"
											runat="server" NAME="cbItemChecked" />
									</ItemTemplate>
								</asp:TemplateColumn>
								<asp:TemplateColumn>
									<HeaderStyle CssClass="globe"></HeaderStyle>
									<ItemStyle CssClass="globe"></ItemStyle>
									<ItemTemplate>
										<asp:Image id="imgGlobe" runat="server" Visible="False" Width="17px" Height="17px"></asp:Image>
									</ItemTemplate>
								</asp:TemplateColumn>
								<asp:HyperLinkColumn DataNavigateUrlField="Name" DataNavigateUrlFormatString="account-detail.aspx?accountNo={0}" 
 DataTextField="Name" HeaderText="Account Number" NavigateUrl="account-detail.aspx">
									<HeaderStyle Font-Bold="True"></HeaderStyle>
								</asp:HyperLinkColumn>
								<asp:BoundColumn DataField="City" HeaderText="City">
									<HeaderStyle Font-Bold="True" Wrap="False"></HeaderStyle>
								</asp:BoundColumn>
								<asp:BoundColumn DataField="State" HeaderText="State/Province">
									<HeaderStyle Font-Bold="True" Wrap="False"></HeaderStyle>
								</asp:BoundColumn>
								<asp:BoundColumn DataField="PhoneNo" HeaderText="Telephone">
									<HeaderStyle Font-Bold="True" Wrap="False"></HeaderStyle>
								</asp:BoundColumn>
								<asp:BoundColumn DataField="Primary" Visible="False"></asp:BoundColumn>
							</Columns>
						</asp:datagrid></div> <!-- end content //-->
					<div class="contentBoxBottom" id="contentBottom" runat="server">
						<div class="floatLeft" id="globalAccountIcon">
						   <asp:Image width="17px" height="17px" runat="server" id="smallGlobe"/>
						   Indicates global account
						</div>
						<div>&nbsp;</div>
					</div>
				</div> <!-- end contentArea //--></div>
			<!-- BEGIN DELETE MESSAGE BOX -->
			<div class="msgBox" id="msgBoxDelete" style="DISPLAY: none">
				<h1><%= ProductName %></h1>
				<div class="msgBoxBody">Deleting an account permanently removes it from the 
					database and removes any lists belonging to that account.<br>
					<br>
					Are you sure you want to delete the selected account(s)?</div>
				<div class="msgBoxFooter"><asp:button id="btnYes" runat="server" CssClass="formBtn btnSmallTop" Text="Yes"></asp:button>&nbsp;
					<asp:button id="btnNo" runat="server" CssClass="formBtn btnSmallTop" Text="No"></asp:button></div>
			</div>
			<!-- END DELETE MESSAGE BOX --></form>
	</body>
</HTML>
