<%@ Page language="c#" Codebehind="disaster-recovery-list-browse.aspx.cs" AutoEventWireup="false" Inherits="Bandl.VaultLedger.Web.UI.disaster_recovery_list_browse" %>
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
                    <h1>Disaster Recovery Lists</h1>
                    View the details of a particular disaster recovery list by clicking a list 
                    name, or perform an action on one or more lists by selecting them, choosing the 
                    action, and clicking Go.
                    <div id="headerConstants"><asp:linkbutton CssClass="headerLink" runat="server" id="printLink">Print</asp:linkbutton></div>
                </div>
                <!-- end pageHeader //--><asp:placeholder id="PlaceHolder1" runat="server" EnableViewState="False"></asp:placeholder>
                <div class="contentArea" id="contentBorderTop">
                    <div class="contentBoxTop">
                        <div class="floatRight"><asp:button id="btnNew" runat="server" CssClass="formBtn btnSmallTopPlus" Text="New List"></asp:button></div>
                        <asp:dropdownlist id="ddlSelectAction" runat="server" CssClass="selectAction" Width="140">
                            <asp:ListItem Value="-Choose an Action-" Selected="True">-Choose an Action-</asp:ListItem>
                            <asp:ListItem Value="Delete">Delete Selected</asp:ListItem>
                            <asp:ListItem Value="Merge">Merge Selected</asp:ListItem>
                            <asp:ListItem Value="Extract">Extract Selected</asp:ListItem>
                            <asp:ListItem Value="Xmit">Transmit Selected</asp:ListItem>
                        </asp:dropdownlist>&nbsp;&nbsp;
                        <asp:button id="btnGo" runat="server" CssClass="formBtn btnSmallGo" Text="Go"></asp:button></div>
                    <div class="content"><asp:datagrid id="DataGrid1" runat="server" CssClass="detailTable" AutoGenerateColumns="False">
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
                                <asp:HyperLinkColumn DataNavigateUrlFormatString="disaster-recovery-list-detail.aspx?listNumber={0}"
                                    DataNavigateUrlField="Name" DataTextField="Name" HeaderText="List Number">
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
                        </asp:datagrid></div> <!-- end content //-->
                    <!-- PAGE LINKS //-->
                    <br>
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
                    </table> <!-- end pageLinks //--></div> <!-- end contentArea //--></div> <!-- end contentWrapper //-->
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
            <!-- END DELETE MESSAGE BOX --></form>
    </body>
</HTML>
