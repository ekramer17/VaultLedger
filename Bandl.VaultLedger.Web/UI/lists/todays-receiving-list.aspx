<%@ Page language="c#" Codebehind="todays-receiving-list.aspx.cs" AutoEventWireup="false" Inherits="Bandl.VaultLedger.Web.UI.todays_receiving_list" %>
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
                    <h1>Today's Lists</h1>Select one or more lists to transmit,
                    to merge, or to extract into discrete lists, and then click
                    Go.&nbsp;&nbsp;Or click a list number to view detailed information on that
                    list.
                    <div id="headerConstants">
                        <asp:linkbutton CssClass="headerLink" runat="server" id="printLink">Print</asp:linkbutton>
                    </div>
                </div><!-- end pageHeader //-->
                <asp:placeholder id="PlaceHolder1" runat="server" EnableViewState="False"></asp:placeholder>
                <div class="tabNavigation twoTabs">
                    <div class="tabs" id="twoTabOne"><A href="todays-list.aspx">Today's Shipping Lists</A></div>
                    <div class="tabs" id="twoTabTwoSelected"><A href="todays-receiving-list.aspx">Today's
                            Receiving Lists</A></div>
                </div>
                <div class="contentArea contentBorderTopNone">
                    <div class="contentBoxTop">
                        <div class="floatRight"><asp:button id="btnNew" runat="server" Text="New List" CssClass="formBtn btnSmallTopPlus"></asp:button></div>
                        <table cellSpacing="0" cellPadding="0" border="0">
                            <tr>
                                <td width="140"><asp:dropdownlist id="ddlSelectAction" runat="server" CssClass="selectAction">
                                        <asp:ListItem Value="-Choose an Action-">-Choose an Action-</asp:ListItem>
                                        <asp:ListItem Value="Delete">Delete Selected</asp:ListItem>
                                        <asp:ListItem Value="Merge">Merge Selected</asp:ListItem>
                                        <asp:ListItem Value="Extract">Extract Selected</asp:ListItem>
                                    </asp:dropdownlist></td>
                                <td width="40">&nbsp;<asp:button id="btnGo" runat="server" Text="Go" CssClass="formBtn btnSmallGo"></asp:button></td>
                            </tr>
                        </table>
                    </div><!-- end contentBoxTop //-->
                    <div class="content">
                        <asp:datagrid id="DataGrid1" runat="server" CssClass="detailTable" AutoGenerateColumns="False">
                            <AlternatingItemStyle CssClass="alternate"></AlternatingItemStyle>
                            <HeaderStyle CssClass="header"></HeaderStyle>
                            <Columns>
                                <asp:TemplateColumn>
                                    <HeaderStyle CssClass="checkbox"></HeaderStyle>
                                    <ItemStyle CssClass="checkbox"></ItemStyle>
                                    <HeaderTemplate>
                                        <input id="cbCheckAll" onclick="checkAll('DataGrid1', 'cbItemChecked', this.checked)" type="checkbox" runat="server" NAME="cbCheckAll" />
                                    </HeaderTemplate>
                                    <ItemTemplate>
                                        <input id="cbItemChecked" onclick="checkFirst('DataGrid1', 'cbCheckAll', false)" type="checkbox" runat="server" NAME="cbItemChecked" />
                                    </ItemTemplate>
                                </asp:TemplateColumn>
                                <asp:HyperLinkColumn DataNavigateUrlFormatString="receiving-list-detail.aspx?listNumber={0}" DataNavigateUrlField="Name" DataTextField="Name" HeaderText="List Number">
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
                        </asp:datagrid>
                    </div><!-- end content //-->
                </div><!-- end contentArea //-->
                <!-- BEGIN DELETE MESSAGE BOX -->
                <div class="msgBox" id="msgBoxDelete" style="DISPLAY:none">
                    <h1><%= ProductName %></h1>
                    <div class="msgBoxBody">
                        Deleting a list permanently removes it from the database.<br>
                        <br>
                        Are you sure you want to delete the selected list(s)?
                    </div>
                    <div class="msgBoxFooter">
                        <asp:button id="btnYes" runat="server" Text="Yes" CssClass="formBtn btnSmallTop"></asp:button>
                        &nbsp;
                        <asp:button id="btnNo" runat="server" Text="No" CssClass="formBtn btnSmallTop"></asp:button>
                    </div>
                </div>
                <!-- END DELETE MESSAGE BOX -->
            </div><!-- end contentWrapper //-->
        </form>
    </body>
</HTML>
