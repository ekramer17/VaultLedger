<%@ Page CodeBehind="view-sites.aspx.cs" Language="c#" AutoEventWireup="false" Inherits="Bandl.VaultLedger.Web.UI.view_sites" %>
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
					<h1>Site Maps</h1>
					View the current mappings of external TMS sites to either the enterprise or 
					vault.&nbsp;&nbsp;To create a new map, click New Site Map. 
					<!-- header links -->
					<div id="headerConstants">
                        <a style="left:580px" class="headerLink" id="arrow" href="index.aspx">Tools Menu</a>
						<asp:linkbutton CssClass="headerLink" runat="server" id="printLink">Print</asp:linkbutton>
					</div>
				</div> <!-- end pageHeader -->
				<asp:PlaceHolder id="PlaceHolder1" runat="server" EnableViewState="False"></asp:PlaceHolder>
				<div class="contentArea" id="contentBorderTop">
					<div class="contentBoxTop">
						<div class="floatLeft">
							<asp:Button id="btnDelete" runat="server" CssClass="formBtn btnLargeTop" Text="Delete Selected"></asp:Button>
						</div>
						<div class="floatRight">
							<asp:button id="btnNew" runat="server" CssClass="formBtn btnLargeTopPlus" Text="New Site Map"></asp:button>
						</div>
						<div>&nbsp;</div>
					</div>
					<div class="content">
						<asp:DataGrid id="DataGrid1" runat="server" CssClass="detailTable" AutoGenerateColumns="False">
							<AlternatingItemStyle CssClass="alternate"></AlternatingItemStyle>
							<HeaderStyle CssClass="header"></HeaderStyle>
							<Columns>
								<asp:TemplateColumn>
                                    <HeaderStyle CssClass="checkbox"></HeaderStyle>
                                    <ItemStyle CssClass="checkbox"></ItemStyle>
									<HeaderTemplate>
										<input type="checkbox" id="cbCheckAll" runat="server" onclick="checkAll('DataGrid1', 'cbItemChecked', this.checked)"
											NAME="cbAllItems">
									</HeaderTemplate>
									<ItemTemplate>
										<input type="checkbox" id="cbItemChecked" runat="server" onclick="checkFirst('DataGrid1', 'cbCheckAll', false)"
											NAME="cbItemChecked">
									</ItemTemplate>
								</asp:TemplateColumn>
								<asp:BoundColumn DataField="Name" HeaderText="Site">
									<HeaderStyle Font-Bold="True" Wrap="False"></HeaderStyle>
								</asp:BoundColumn>
								<asp:BoundColumn DataField="Location" HeaderText="Location">
									<HeaderStyle Font-Bold="True" Wrap="False"></HeaderStyle>
								</asp:BoundColumn>
								<asp:BoundColumn DataField="Account" HeaderText="Account">
									<HeaderStyle Font-Bold="True" Wrap="False"></HeaderStyle>
								</asp:BoundColumn>
							</Columns>
						</asp:DataGrid>
					</div> <!-- end content -->
				</div> <!-- end contentArea -->
			</div> <!-- end contentWrapper -->
			<!-- BEGIN DELETE MESSAGE BOX -->
			<div class="msgBox" id="msgBoxDelete" style="DISPLAY:none">
				<h1><%= ProductName %></h1>
				<div class="msgBoxBody">
					Deleting a site map permanently removes it from the database.<br>
					<br>
					Are you sure you want to delete the selected site map(s)?
				</div>
				<div class="msgBoxFooter">
					<asp:button id="btnYes" runat="server" Text="Yes" CssClass="formBtn btnSmallTop"></asp:button>
					&nbsp;
					<asp:button id="btnNo" runat="server" Text="No" CssClass="formBtn btnSmallTop"></asp:button>
				</div>
			</div>
			<!-- END DELETE MESSAGE BOX -->
		</form>
	</body>
</HTML>
