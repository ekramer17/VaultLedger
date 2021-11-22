<%@ Page language="c#" Codebehind="tms-lists-shipping.aspx.cs" AutoEventWireup="false" Inherits="Bandl.VaultLedger.Web.UI.tms_lists_shipping" %>
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
                    <h1>TMS Lists</h1>
                    View the details of a particular list by clicking a list name, or perform an 
                    action on one or more lists by selecting them, choosing the action, and 
                    clicking Go.
                    <div id="headerConstants"><asp:linkbutton id="printLink" runat="server" CssClass="headerLink">Print</asp:linkbutton></div>
                </div> <!-- end pageHeader //--><asp:placeholder id="PlaceHolder1" runat="server" EnableViewState="False"></asp:placeholder>
                <div class="tabNavigation twoTabs">
                    <div class="tabs" id="twoTabOneSelected"><asp:hyperlink id="tabOne" runat="server" NavigateUrl="#">TMS Shipping Lists</asp:hyperlink></div>
                    <div class="tabs" id="twoTabTwo"><asp:linkbutton id="tabTwo" runat="server">TMS Receiving Lists</asp:linkbutton></div>
                </div>
                <div class="contentArea" id="contentBorderTopNone">
                    <div class="contentBoxTop"><asp:dropdownlist id="ddlSelectAction" runat="server" CssClass="selectAction" Width="140">
                            <asp:ListItem Value="-Choose an Action-" Selected="True">-Choose an Action-</asp:ListItem>
                            <asp:ListItem Value="Delete">Delete Selected</asp:ListItem>
                            <asp:ListItem Value="Extract">Extract Selected</asp:ListItem>
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
                                        <input id="cbCheckAll1" onclick="checkAll('DataGrid1', 'cbItemChecked1', this.checked)"
                                            type="checkbox" runat="server" NAME="cbCheckAll1" />
                                    </HeaderTemplate>
                                    <ItemTemplate>
                                        <input id="cbItemChecked1" onclick="checkFirst('DataGrid1', 'cbCheckAll1', false)" type="checkbox"
                                            runat="server" NAME="cbItemChecked1" />
                                    </ItemTemplate>
                                </asp:TemplateColumn>
                                <asp:HyperLinkColumn DataNavigateUrlField="Name" DataNavigateUrlFormatString="shipping-list-detail.aspx?listNumber={0}"
                                    DataTextField="Name" HeaderText="List Number">
                                    <HeaderStyle Font-Bold="True"></HeaderStyle>
                                </asp:HyperLinkColumn>
                                <asp:TemplateColumn HeaderText="Create Date">
                                    <HeaderStyle Font-Bold="True"></HeaderStyle>
                                    <ItemTemplate>
                                        <%# DisplayDate(DataBinder.Eval(Container.DataItem, "CreateDate")) %>
                                    </ItemTemplate>
                                </asp:TemplateColumn>
                                <asp:TemplateColumn HeaderText="Status">
                                    <HeaderStyle Font-Bold="True"></HeaderStyle>
                                    <ItemTemplate>
                                        <%# StatusString(DataBinder.Eval(Container.DataItem, "Status")) %>
                                    </ItemTemplate>
                                </asp:TemplateColumn>
                                <asp:BoundColumn DataField="Account" HeaderText="Account">
                                    <HeaderStyle Font-Bold="True"></HeaderStyle>
                                </asp:BoundColumn>
                            </Columns>
                        </asp:datagrid></div> <!-- end content //--></div> <!-- end contentArea //--></div> <!-- end contentWrapper //-->
            <!-- BEGIN DELETE MESSAGE BOX -->
            <div class="msgBox" id="msgBoxDelete" style="DISPLAY: none">
                <h1><%= ProductName %></h1>
                <div class="msgBoxBody">Deleting a list permanently removes it from the database.<br>
                    <br>
                    Are you sure you want to delete the selected list(s)?
                </div>
                <div class="msgBoxFooter"><asp:button id="btnYes" runat="server" CssClass="formBtn btnSmallTop" Text="Yes"></asp:button>&nbsp;
                    <asp:button id="btnNo" runat="server" CssClass="formBtn btnSmallTop" Text="No"></asp:button></div>
            </div>
            <!-- END DELETE MESSAGE BOX -->
            <!-- BEGIN EXCLUDED MESSAGE BOX -->
            <div class="msgBoxSmall" id="msgBoxExcluded" style="DISPLAY: none">
                <h1><%= ProductName %></h1>
                <div class="msgBoxBody" id="excludedMessage" runat="server">&nbsp;</div>
                <div class="msgBoxFooter">
                    <asp:button id="btnExport" runat="server" CssClass="formBtn btnSmallTop" Text="Yes"></asp:button>&nbsp;
                    <input id="btnNoExport" runat="server" type="button" class="formBtn btnSmallTop" value="No" />
                </div>
            </div>
            <!-- END EXCLUDED MESSAGE BOX -->
            </form>
    </body>
</HTML>
