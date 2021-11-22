<%@ Page language="c#" Codebehind="shipping-list-reconcile.aspx.cs" AutoEventWireup="false" Inherits="Bandl.VaultLedger.Web.UI.shipping_list_reconcile" %>
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
				<div class="pageHeader">
					<h1>Shipping Compare - Batch Reconcile</h1>
					Reconcile all the compare files against the list.<br>
					<br>
					<table cellSpacing="0" cellPadding="0" border="0">
						<tr>
							<td width="160"><b>List Number:</b>&nbsp;&nbsp;
								<asp:label id="lblListNo" runat="server"></asp:label></td>
							<td width="150"><b>Status:</b>&nbsp;&nbsp;
								<asp:label id="lblStatus" runat="server"></asp:label></td>
							<td width="160"><b>Create Date:</b>&nbsp;&nbsp;
								<asp:label id="lblCreateDate" runat="server"></asp:label></td>
							<td><b>Account:</b>&nbsp;&nbsp;
								<asp:label id="lblAccount" runat="server"></asp:label></td>
						</tr>
					</table>
					<div id="headerConstants"><asp:linkbutton id="listLink" style="LEFT: 644px" runat="server" CssClass="headerLink">List Detail</asp:linkbutton></div>
				</div>
				<!-- end pageHeader //-->
				<div class="tabNavigation twoTabs" id="twoTabs" runat="server">
					<div class="tabs" id="twoTabOne"><A href="javascript:redirectPage('shipping-compare-online-reconcile.aspx?listNumber=' + getObjectById('lblListNo').innerHTML);">Online 
							Reconcile</A></div>
					<div class="tabs" id="twoTabTwoSelected"><A href="#">Batch Reconcile</A></div>
				</div>
				<div class="tabNavigation threeTabs" id="threeTabs" runat="server">
					<div class="tabs" id="threeTabOne"><A href="javascript:redirectPage('shipping-compare-online-reconcile.aspx?listNumber=' + getObjectById('lblListNo').innerHTML);">Online 
							Reconcile</A></div>
					<div class="tabs" id="threeTabTwoSelected"><A href="#">Batch Reconcile</A></div>
					<div class="tabs" id="threeTabThree"><A href="javascript:redirectPage('shipping-list-reconcile-rfid.aspx?listNumber=' + getObjectById('lblListNo').innerHTML);">RFID 
							Reconcile</A></div>
				</div>
				<!-- end tabNavigation //-->
				<div class="contentArea" id="contentBorderTopNone">
					<div class="contentBoxTop"><asp:placeholder id="PlaceHolder1" runat="server" EnableViewState="False"></asp:placeholder>
						<div class="floatRight"><asp:button id="btnNewFile" runat="server" CssClass="formBtn btnSmallTopPlus" Text="New File"></asp:button></div>
						<asp:dropdownlist id="ddlSelectAction" runat="server" CssClass="selectAction">
							<asp:ListItem Value="-Choose an Action-">-Choose an Action-</asp:ListItem>
							<asp:ListItem Value="D">Delete Selected</asp:ListItem>
							<asp:ListItem Value="S">Download List</asp:ListItem>
							<asp:ListItem Value="U">Upload File</asp:ListItem>
						</asp:dropdownlist>
						<asp:button id="btnGo" runat="server" Text="Go" CssClass="formBtn btnSmallGo" style="MARGIN-LEFT:3px"></asp:button></div>
					<!-- end contentBoxTop //--><asp:datagrid id="DataGrid1" runat="server" CssClass="detailTable" AutoGenerateColumns="False">
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
							<asp:HyperLinkColumn DataNavigateUrlField="Name" DataTextField="Name" HeaderText="File Name">
								<HeaderStyle Font-Bold="True"></HeaderStyle>
							</asp:HyperLinkColumn>
							<asp:TemplateColumn HeaderText="Create Date">
								<HeaderStyle Font-Bold="True"></HeaderStyle>
								<ItemTemplate>
									<%# DisplayDate(DataBinder.Eval(Container.DataItem, "CreateDate")) %>
								</ItemTemplate>
							</asp:TemplateColumn>
							<asp:TemplateColumn HeaderText="Last Compared">
								<HeaderStyle Font-Bold="True"></HeaderStyle>
								<ItemTemplate>
									<%# DisplayDate((String)DataBinder.Eval(Container.DataItem, "LastCompared")) %>
								</ItemTemplate>
							</asp:TemplateColumn>
						</Columns>
					</asp:datagrid>
					<div class="contentBoxBottom"><asp:button id="btnCompare" runat="server" CssClass="formBtn btnMedium" Text="Compare"></asp:button>&nbsp;
						<asp:button id="btnCancel" runat="server" Text="Cancel" CssClass="formBtn btnMedium"></asp:button></div>
				</div>
				<!-- end contentArea //--></div> <!-- end contentWrapper //-->
			<!-- BEGIN TRANSMIT MESSAGE BOX -->
			<div class="msgBox" id="msgBoxTransmit" style="DISPLAY: none">
				<h1><%= ProductName %></h1>
				<div class="msgBoxBody">
					<h2>Fully Verified</h2>
					There are no discrepancies. Would you like to transmit the list now?
				</div>
				<div class="msgBoxFooter"><asp:button id="btnYes" runat="server" CssClass="formBtn btnSmallTop" Text="Yes"></asp:button>
					&nbsp;
					<asp:button id="btnNo" runat="server" Text="No" CssClass="formBtn btnSmallTop"></asp:button></div>
			</div>
			<!-- END TRANSMIT MESSAGE BOX -->
			<!-- BEGIN VERIFIED MESSAGE BOX -->
			<div class="msgBox" id="msgBoxDone" style="DISPLAY: none">
				<h1><%= ProductName %></h1>
				<div class="msgBoxBody">
					<h2>Fully Verified</h2>
					There are no discrepancies. The list has been completely reconciled.</div>
				<div class="msgBoxFooter">
					<asp:button id="btnOK" runat="server" Text="OK" CssClass="formBtn btnSmallTop"></asp:button></div>
			</div>
			<!-- END VERIFIED MESSAGE BOX -->
			<!-- BEGIN OTHER VERIFIED MESSAGE BOX -->
			<div class="msgBox" id="msgBoxOther" style="DISPLAY: none">
				<h1><%= ProductName %></h1>
				<div class="msgBoxBody">
					<h2>Fully Verified</h2>
					There are no discrepancies, and the list has been fully verified.<br>
					<br>
					However, there were entries in the scan file that did not appear on the list 
					and/or discrepancies involving cases. Click OK to view.</div>
				<div class="msgBoxFooter"><asp:button id="btnOther" runat="server" Text="OK" CssClass="formBtn btnSmallTop"></asp:button></div>
			</div>
			<!-- BEGIN MISCELLANEOUS MESSAGE BOX -->
			<div class="msgBox" id="msgBox1" style="DISPLAY:none">
				<h1><%= ProductName %></h1>
				<div id="msgboxbody1" class="msgBoxBody"></div>
				<div class="msgBoxFooter">
					<input type="button" id="button1" value="OK" class="formBtn btnSmallTop" onclick="hideMsgBox('msgBox1')" />
				</div>
			</div>
			<!-- END MISCELLANEOUS MESSAGE BOX -->
			<div id="AppletHolder" runat="server" />
			<input type="hidden" id="Hidden1" runat="server">
			<script type="text/javascript">
			function runapp()
			{
				var a1 = document.getElementById('applet1');
				
				if (a1 != null)
				{
					if (a1.isTrusted())
					{
						var s1 = a1.execute();

						if (s1.substr(0,2) != "OK")
						{
							getObjectById('msgboxbody1').innerHTML = '<b>ERROR</b><br /><br />' + s1.substr(7);	// error
							showMsgBox('msgBox1');
						}
						else if (s1.indexOf(':') != 2)
						{
							getObjectById('msgboxbody1').innerHTML = '<br />List downloaded successfully';	// download ok - show message box
							showMsgBox('msgBox1');
						}
						else
						{
							getObjectById('Hidden1').value = s1.substr(3);	// upload ok - post data back to server
							__doPostBack('btnGo', 'R');
						}
					}
					else
					{
						getObjectById('msgboxbody1').innerHTML = '<b>ERROR</b><br /><br />Applet not granted trusted permission';
						getObjectById('button1').onclick = function() {hideMsgBox('msgBox1')};
						showMsgBox('msgBox1');
					}
				}
			}
			
			function onUpload()
			{
				getObjectById('msgboxbody1').innerHTML = '<br />List uploaded successfully';
				showMsgBox('msgBox1');
			}
			</script>
		</form>
	</body>
</HTML>
