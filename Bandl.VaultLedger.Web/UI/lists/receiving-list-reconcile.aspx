<%@ Page language="c#" Codebehind="receiving-list-reconcile.aspx.cs" AutoEventWireup="false" Inherits="Bandl.VaultLedger.Web.UI.receiving_list_reconcile" %>
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
					<h1>Receiving Compare - Batch Reconcile</h1>
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
					<div id="headerConstants">
						<asp:linkbutton id="listLink" runat="server" style="LEFT:644px" CssClass="headerLink">List Detail</asp:linkbutton>
					</div>
				</div>
				<!-- end pageHeader //-->
				<div id="twoTabs" class="tabNavigation twoTabs" runat="server">
					<div class="tabs" id="twoTabOne"><A href="javascript:redirectPage('receiving-compare-online-reconcile.aspx?listNumber=' + getObjectById('lblListNo').innerHTML);">Online 
							Reconcile</A></div>
					<div class="tabs" id="twoTabTwoSelected"><A href="#">Batch Reconcile</A></div>
				</div>
				<div id="threeTabs" class="tabNavigation threeTabs" runat="server">
					<div class="tabs" id="threeTabOne"><A href="javascript:redirectPage('receiving-compare-online-reconcile.aspx?listNumber=' + getObjectById('lblListNo').innerHTML);">Online 
							Reconcile</A></div>
					<div class="tabs" id="threeTabTwoSelected"><A href="#">Batch Reconcile</A></div>
					<div class="tabs" id="threeTabThree"><A href="javascript:redirectPage('receiving-list-reconcile-rfid.aspx?listNumber=' + getObjectById('lblListNo').innerHTML);">RFID 
							Reconcile</A></div>
				</div>
				<!-- end tabNavigation //-->
				<div class="contentArea" id="contentBorderTopNone">
					<div class="contentBoxTop">
						<asp:placeholder id="PlaceHolder1" runat="server" EnableViewState="False"></asp:placeholder>
						<div class="floatRight">
							<input id="btnNewFile" type="button" runat="server" value="New File" class="formBtn btnSmallTopPlus">
						</div>
						<asp:dropdownlist id="ddlSelectAction" runat="server" CssClass="selectAction">
							<asp:ListItem Value="-Choose an Action-">-Choose an Action-</asp:ListItem>
							<asp:ListItem Value="D">Delete Selected</asp:ListItem>
							<asp:ListItem Value="S">Download List</asp:ListItem>
							<asp:ListItem Value="U">Upload File</asp:ListItem>
						</asp:dropdownlist>
						<asp:button id="btnGo" runat="server" Text="Go" CssClass="formBtn btnSmallGo" style="MARGIN-LEFT:3px"></asp:button></div>
				</div> <!-- end contentBoxTop //-->
				<asp:datagrid id="DataGrid1" runat="server" CssClass="detailTable" AutoGenerateColumns="False">
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
				<div class="contentBoxBottom">
					<input id="btnCompare" type="button" runat="server" value="Compare" class="formBtn btnMedium">
					&nbsp; <input id="btnCancel" type="button" runat="server" value="Cancel" class="formBtn btnMedium">
				</div>
			</div> <!-- end contentArea //-->
			<DIV></DIV> <!-- end contentWrapper //-->
			<!-- BEGIN OTHER MESSAGE BOX -->
			<div class="msgBox" id="msgBoxOther" style="DISPLAY:none" runat="server">
				<h1><%= ProductName %></h1>
				<div class="msgBoxBody">
					<h2>Fully Verified</h2>
					There are no discrepancies, and the list has been fully verified.<br>
					<br>
					However, there were entries in the scan file that did not appear on the list. 
					Click OK to view.</div>
				<div class="msgBoxFooter">
					<input id="btnOther" type="button" runat="server" value="OK" class="formBtn btnSmallTop">
				</div>
			</div>
			<!-- END OTHER MESSAGE BOX -->
			<!-- BEGIN CLEAR MESSAGE BOX -->
			<div class="msgBox" id="msgBoxDone" style="DISPLAY:none">
				<h1><%= ProductName %></h1>
				<div class="msgBoxBody">
					<h2>Fully Verified</h2>
					There are no discrepancies. The list has been fully verified.</div>
				<div class="msgBoxFooter">
					<input type="button" id="btnOK" runat="server" value="OK" class="formBtn btnSmallTop">
				</div>
			</div>
			<!-- END CLEAR MESSAGE BOX -->
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
			<input type="hidden" id="Hidden1" runat="server" NAME="Hidden1">
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
