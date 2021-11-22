<%@ Page language="c#" Codebehind="shipping-list-detail.aspx.cs" AutoEventWireup="false" Inherits="Bandl.VaultLedger.Web.UI.shipping_list_detail" %>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<HTML>
	<HEAD>
		<META http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
		<meta content="Microsoft Visual Studio .NET 7.1" name="GENERATOR">
		<meta content="C#" name="CODE_LANGUAGE">
		<meta content="JavaScript" name="vs_defaultClientScript">
		<meta content="http://schemas.microsoft.com/intellisense/ie5" name="vs_targetSchema">
		<!--#include file = "../includes/baseHead.inc"-->
		<style type="text/css">
		.sortlink {text-decoration:none;}
		.sortlink:hover {text-decoration:underline;}
		</style>
	</HEAD>
	<body>
		<input type="hidden" id="order" runat="server"> 
		<!--#include file = "../includes/baseBody.inc"-->
		<form id="Form1" method="post" runat="server">
			<div class="contentWrapper">
				<div class="pageHeader">
					<h1><asp:label id="lblCaption" runat="server"></asp:label></h1>
					View media currently on a list and perform actions such as adding, removing, 
					editing and verifying the media on the list. You may also edit case details and 
					transmit the list to the offsite vendor.
					<br>
					<br>
					<table cellSpacing="0" cellPadding="0" border="0">
						<tr>
							<td width="160"><b>List Number:</b>&nbsp;&nbsp;<asp:label id="lblListNo" runat="server"></asp:label></td>
							<td width="150"><b>Status:</b>&nbsp;&nbsp;<asp:label id="lblStatus" runat="server"></asp:label></td>
							<td width="160"><b>Create Date:</b>&nbsp;&nbsp;<asp:label id="lblCreateDate" runat="server"></asp:label></td>
							<td><b>Account:</b>&nbsp;&nbsp;<asp:label id="lblAccount" runat="server"></asp:label></td>
						</tr>
					</table>
					<div id="headerConstants"><asp:linkbutton id="listLink" CssClass="headerLink" Runat="server">Lists</asp:linkbutton>
						<asp:linkbutton id="exportLink" style="LEFT: 608px" runat="server" CssClass="headerLink">Export</asp:linkbutton><asp:linkbutton id="printLink" runat="server" CssClass="headerLink">Print</asp:linkbutton></div>
				</div> <!-- end pageHeader //--><asp:placeholder id="PlaceHolder1" runat="server" EnableViewState="False"></asp:placeholder>
				<div class="contentArea" id="contentBorderTop">
					<div class="contentBoxTop">
						<div class="floatRight"><asp:button id="btnAdd" runat="server" CssClass="formBtn btnSmallTop" Text="Add"></asp:button></div>
						<asp:dropdownlist id="ddlSelectAction" runat="server" CssClass="selectAction" Width="140">
							<asp:ListItem Value="-Choose an Action-" Selected="True">-Choose an Action-</asp:ListItem>
							<asp:ListItem Value="Remove">Remove Selected</asp:ListItem>
							<asp:ListItem Value="AssignCase">Assign to Case</asp:ListItem>
							<asp:ListItem Value="RemoveCase">Remove from Case</asp:ListItem>
							<asp:ListItem Value="ReturnDate">Edit Return Date</asp:ListItem>
							<asp:ListItem Value="Missing">Mark Missing</asp:ListItem>
						</asp:dropdownlist>&nbsp;&nbsp;
						<asp:button id="btnGo" runat="server" CssClass="formBtn btnSmallGo" Text="Go"></asp:button></div> <!-- end contentBoxTop //-->
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
									<HeaderTemplate>
									<asp:LinkButton CssClass="sortlink" ForeColor="white" Font-Bold="True" id="SerialLink" runat="server" Text="Serial Number" OnCommand="SortLink_Command" CommandName="1">Serial Number</asp:LinkButton>
									</HeaderTemplate>
									<ItemTemplate>
									<%# DataBinder.Eval(Container.DataItem, "SerialNo") %>
									</ItemTemplate>
								</asp:TemplateColumn>
								<asp:TemplateColumn HeaderText="Return Date">
									<HeaderStyle Font-Bold="True"></HeaderStyle>
									<ItemTemplate>
										<%# DisplayDate((string)DataBinder.Eval(Container.DataItem, "ReturnDate"), false, false) %>
									</ItemTemplate>
								</asp:TemplateColumn>
								<asp:TemplateColumn HeaderText="Status">
									<HeaderStyle Font-Bold="True"></HeaderStyle>
									<ItemTemplate>
										<%# StatusString(DataBinder.Eval(Container.DataItem, "Status")) %>
									</ItemTemplate>
								</asp:TemplateColumn>
                                <asp:ButtonColumn DataTextField="CaseName" HeaderText="Case Number" CommandName="ModifyCase">
                                    <HeaderStyle Font-Bold="True"></HeaderStyle>
                                </asp:ButtonColumn>
                                <asp:BoundColumn DataField="CaseName" HeaderText="Case Number">
                                    <HeaderStyle Font-Bold="True"></HeaderStyle>
                                </asp:BoundColumn>
								<asp:TemplateColumn>
									<HeaderTemplate>
									<asp:LinkButton CssClass="sortlink" ForeColor="white" Font-Bold="True" id="AccountLink" runat="server" Text="Account" OnCommand="SortLink_Command" CommandName="2">Account</asp:LinkButton>
									</HeaderTemplate>
									<ItemTemplate>
									<%# DataBinder.Eval(Container.DataItem, "Account") %>
									</ItemTemplate>
								</asp:TemplateColumn>
							</Columns>
						</asp:datagrid></div> <!-- end content //-->
					<!-- PAGE LINKS //--><br>
					<table class="detailTable">
						<tr>
							<td align="left"><asp:linkbutton id="lnkPageFirst" tabIndex="14" runat="server" Text="[First Page]" OnCommand="LinkButton_Command"
									CommandName="pageFirst">[<<]</asp:linkbutton>&nbsp;
								<asp:linkbutton id="lnkPagePrev" tabIndex="15" runat="server" Text="[Previous Page]" OnCommand="LinkButton_Command"
									CommandName="pagePrev">[<]</asp:linkbutton>&nbsp;
								<asp:textbox id="txtPageGoto" tabIndex="16" runat="server" Width="40px"></asp:textbox><input id="enterGoto" type="hidden" name="enterGoto" runat="server">
								&nbsp;
								<asp:linkbutton id="lnkPageNext" tabIndex="17" runat="server" Text="[Next Page]" OnCommand="LinkButton_Command"
									CommandName="pageNext">[>]</asp:linkbutton>&nbsp;
								<asp:linkbutton id="lnkPageLast" tabIndex="18" runat="server" Text="[Last Page]" OnCommand="LinkButton_Command"
									CommandName="pageLast">[>>]</asp:linkbutton></td>
							<td style="PADDING-RIGHT: 10px; TEXT-ALIGN: right"><asp:label id="lblPage" runat="server" Font-Bold="True"></asp:label></td>
						</tr>
					</table> <!-- end pageLinks //-->
					<div class="contentBoxBottom" id="divButtons" runat="server" style="text-align:left">
                        <asp:button id="btnReconcile" runat="server" CssClass="formBtn btnMedium" style="float:right" Text="Reconcile"></asp:button>
						<asp:button id="btnTransmit" runat="server" CssClass="formBtn btnMedium" style="float:right" Text="Transmit"></asp:button>
                        <input type="button" id="btnHistory" class="formBtn btnMedium" value="History" onclick="history()" />
                    </div>
				</div> <!-- end contentArea //--></div> <!-- end contentWrapper //-->
			<!-- BEGIN TRANSMIT MESSAGE BOX -->
			<div class="msgBoxSmall" id="msgBoxTransmit" style="DISPLAY: none">
				<h1><%= ProductName %></h1>
				<div class="msgBoxBody"><asp:label id="lblTransmit" runat="server"></asp:label></div>
				<div class="msgBoxFooter"><input class="formBtn btnSmallTop" onclick="window.location='send-lists.aspx'" type="button"
						value="OK"></div>
			</div>
			<!-- END TRANSMIT MESSAGE BOX -->
			<!-- BEGIN RECONCILE MESSAGE BOX -->
			<div class="msgBoxSmall" id="msgBoxReconcile" style="DISPLAY: none">
				<h1><%= ProductName %></h1>
				<div class="msgBoxBody"><asp:label id="lblReconciled" runat="server"></asp:label></div>
				<div class="msgBoxFooter"><input class="formBtn btnSmallTop" id="btnOK" type="button" value="OK" name="btnOK" runat="server">
				</div>
			</div>
			<!-- END RECONCILE MESSAGE BOX -->
			<!-- BEGIN DELETE MESSAGE BOX -->
			<div class="msgBox" id="msgBoxDelete" style="DISPLAY: none">
				<h1><%= ProductName %></h1>
				<div class="msgBoxBody">Are you sure you want to remove the selected media from 
					this list?
				</div>
				<div class="msgBoxFooter"><asp:button id="btnYes" runat="server" CssClass="formBtn btnSmallTop" Text="Yes"></asp:button>&nbsp;
					<input class="formBtn btnSmallTop" id="btnNo" onclick="hideMsgBox('msgBoxDelete');" type="button"
						value="No">
				</div>
			</div>
			<!-- END DELETE MESSAGE BOX -->
			<!-- BEGIN RETURN DATE BOX -->
			<div class="msgBox" id="msgBoxReturnDate" style="DISPLAY: none">
				<h1><%= ProductName %></h1>
				<div class="msgBoxBody">Enter the return date to assign to the selected media:
					<br>
					<br>
					<br>
					<table cellSpacing="0" cellPadding="0" width="210" align="center" border="0">
						<tr>
							<td><asp:textbox id="txtReturnDate" runat="server" Width="162"></asp:textbox></td>
							<td class="calendarCell" width="32"><A class="iconLink calendarLink" id="calendar" href="javascript:openCalendar('txtReturnDate');"></A></td>
						</tr>
					</table>
				</div>
				<div class="msgBoxFooter"><input class="formBtn btnSmallTop" id="btnReturnOK" type="button" value="OK" runat="server">
					&nbsp; <input class="formBtn btnSmallTop" id="btnReturnCancel" onclick="hideMsgBox('msgBoxReturnDate');"
						type="button" value="Cancel">
				</div>
			</div>
			<!-- END RETURN DATE BOX -->
			<!-- BEGIN ASSIGN CASE BOX -->
			<div class="msgBox" id="msgBoxCase" style="DISPLAY: none">
				<h1><%= ProductName %></h1>
				<div class="msgBoxBody">Into which case you would like to insert the selected 
					media?
					<br>
					<br>
					<div align="center"><asp:dropdownlist id="ddlCases" runat="server" Width="162">
							<asp:ListItem Value="CreateCase" Selected="True">-Create New Case-</asp:ListItem>
						</asp:dropdownlist>
						<div id="createCaseSection" style="MARGIN-TOP: 9px">Enter the name of the new case:
							<br>
							<div style="MARGIN-TOP: 5px"><asp:textbox id="createCase" runat="server" Width="162"></asp:textbox></div>
						</div>
					</div>
				</div>
				<div class="msgBoxFooter"><input class="formBtn btnSmallTop" id="caseOK" type="button" value="OK" name="caseOK" runat="server">
					&nbsp; <input class="formBtn btnMediumTop" id="caseCancel" onclick="hideMsgBox('msgBoxCase');"
						type="button" value="Cancel">
				</div>
			</div>
			<!-- END ASSIGN CASE BOX -->
        </form>
		<script type="text/javascript">
        function caseSelect(o)
        {
            if (o == null || o.options[0] == null)
            {
                return;
            }
            else if (o.options[0].selected)
            {
                getObjectById('createCaseSection').style.display = "block";
            }
            else
            {
                getObjectById('createCaseSection').style.display = "none";
            }
        }

        function history()
        {
            listName = document.getElementById('<%= lblListNo.ClientID %>').innerHTML;
            openBrowser('list-history-popup.aspx?listName=' + listName.replace(/^\s+|\s+$/gm, ''))
        }
		</script>
	</body>
</HTML>
