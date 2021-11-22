<%@ Page language="c#" Codebehind="compare-discrepancy-two.aspx.cs" AutoEventWireup="false" Inherits="Bandl.VaultLedger.Web.UI.compare_discrepancy_two" %>
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
                    <h1>Compare Discrepancies</h1>
                    View and resolve discrepancies between a list and the compare files associated 
                    with it.
					<div id="headerConstants"><asp:linkbutton id="listLink" style="LEFT: 644px" runat="server" CssClass="headerLink">List Detail</asp:linkbutton></div>
                </div>
                <!-- end pageHeader //-->
                <div class="tabNavigation twoTabs" id="divTabsTwo" runat="server">
                    <div class="tabs" id="twoTabOne"><A id="twoTabOneLink" runat="server">On List/Not In 
                            Compare Files</A></div>
                    <div class="tabs" id="twoTabTwoSelected"><A href="#">In Compare Files/Not On List</A></div>
                </div>
                <div class="tabNavigation threeTabs" id="divTabsThree" runat="server">
                    <div class="tabs" id="threeTabOne"><A id="threeTabOneLink" runat="server">On List/Not 
                            In Compare Files</A></div>
                    <div class="tabs" id="threeTabTwoSelected"><A href="#">In Compare Files/Not On List</A></div>
                    <div class="tabs" id="threeTabThree" runat="server"><A id="threeTabThreeLink" runat="server">Case 
                            Discrepancies</A></div>
                </div>
                <div class="contentArea">
                    <div class="contentBoxTop"><asp:dropdownlist id="ddlSelectAction" runat="server" CssClass="selectAction">
                            <asp:ListItem Value="-Choose an Action-" Selected="True">-Choose an Action-</asp:ListItem>
                            <asp:ListItem Value="Add">Add To List</asp:ListItem>
                        </asp:dropdownlist>&nbsp;&nbsp;<asp:button id="btnGo" runat="server" CssClass="formBtn btnSmallGo" Text="Go"></asp:button>
                    </div>
                    <asp:placeholder id="PlaceHolder1" runat="server" EnableViewState="False"></asp:placeholder>
                    <div class="content">
                        <asp:datagrid id="DataGrid1" runat="server" CssClass="detailTable" AutoGenerateColumns="False"
                            BorderStyle="None">
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
                                <asp:BoundColumn DataField="SerialNo" HeaderText="Serial Number">
                                    <HeaderStyle Font-Bold="True"></HeaderStyle>
                                </asp:BoundColumn>
                                <asp:BoundColumn DataField="CaseName" HeaderText="Case Name">
                                    <HeaderStyle Font-Bold="True"></HeaderStyle>
                                </asp:BoundColumn>
                            </Columns>
                        </asp:datagrid>
                    </div>
                </div>
            </div>
            <!-- BEGIN MOVED MESSAGE BOX -->
            <div class="msgBoxSmall" id="msgBoxMove" style="DISPLAY:none">
                <h1><%= ProductName %></h1>
                <div class="msgBoxBody">
                Media were successfully moved.
                <br>
                They will not be removed from the grid below because they are still in the compare file but not on the list.
                </div>
                <div class="msgBoxFooter"><asp:button id="btnOK1" runat="server" Text="OK" CssClass="formBtn btnSmallTop"></asp:button></div>
            </div>
            <!-- END MOVED MESSAGE BOX -->
            <!-- BEGIN ADD MESSAGE BOX -->
            <div class="msgBoxSmall" id="msgBoxAdd" style="DISPLAY:none">
                <h1><%= ProductName %></h1>
                <div class="msgBoxBody">Media were successfully added to the list</div>
                <div class="msgBoxFooter"><asp:button id="btnOK2" runat="server" Text="OK" CssClass="formBtn btnSmallTop"></asp:button></div>
            </div>
            <!-- END ADD MESSAGE BOX -->
        </form>
    </body>
</HTML>
