<%@ Page language="c#" Codebehind="media-types.aspx.cs" AutoEventWireup="false" Inherits="Bandl.VaultLedger.Web.UI.media_types" %>
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
                    <h1>Media Types</h1>Review media types currently known to
                    the system.&nbsp;&nbsp;To add an additional media type, click New Type. </div>
                <!-- end pageHeader //--><asp:placeholder id="PlaceHolder1" runat="server" EnableViewState="False"></asp:placeholder>
                <div class="contentArea" id="contentBorderTop">
                    <div class="contentBoxTop textLeft" id="actionTable" align="left" runat="server">
                        <table style="width:100%">
                            <tr>
                                <td align="left"><asp:button id="btnDelete" runat="server" CssClass="formBtn btnLargeTop" Text="Delete Selected"></asp:button></td>
                                <td align="right"><asp:button id="btnNew" runat="server" CssClass="formBtn btnMediumTop" Text="New Type"></asp:button></td></tr></table></div>
                    <!-- end contentBoxTop //-->
                    <div class="content"><asp:datagrid id="DataGrid1" runat="server" CssClass="detailTable" AutoGenerateColumns="False">
                            <AlternatingItemStyle CssClass="alternate"></AlternatingItemStyle>
                            <HeaderStyle CssClass="header"></HeaderStyle>
                            <Columns>
                                <asp:TemplateColumn>
                                    <HeaderStyle CssClass="checkbox"></HeaderStyle>
                                    <ItemStyle CssClass="checkbox"></ItemStyle>
                                    <HeaderTemplate>
                                        <input type="checkbox" id="cbCheckAll" runat="server" onclick="checkAll('DataGrid1', 'cbItemChecked', this.checked)" NAME="cbCheckAll">
                                    </HeaderTemplate>
                                    <ItemTemplate>
                                        <input type="checkbox" id="cbItemChecked" runat="server" onclick="checkFirst('DataGrid1', 'cbCheckAll', false)" NAME="cbItemChecked">
                                    </ItemTemplate>
                                </asp:TemplateColumn>
                                <asp:HyperLinkColumn DataNavigateUrlFormatString="media-type-detail.aspx?typeName={0}" DataNavigateUrlField="Name" DataTextField="Name" HeaderText="Type Name">
                                    <HeaderStyle Font-Bold="True"></HeaderStyle>
                                </asp:HyperLinkColumn>
                                <asp:TemplateColumn HeaderText="Container">
                                    <HeaderStyle Font-Bold="True"></HeaderStyle>
                                    <ItemTemplate><%# Convert.ToBoolean(DataBinder.Eval(Container.DataItem, "Container")) ? "Yes" : "No" %></ItemTemplate>
                                </asp:TemplateColumn>
                                <asp:BoundColumn DataField="RecallCode" HeaderText="Transmit Code">
                                    <HeaderStyle Font-Bold="True">
                                    </HeaderStyle>
                                </asp:BoundColumn>
                                <asp:TemplateColumn HeaderText="Two-Sided">
                                    <HeaderStyle Font-Bold="True"></HeaderStyle>
                                    <ItemTemplate><%# Convert.ToBoolean(DataBinder.Eval(Container.DataItem, "TwoSided")) ? "Yes" : "No" %></ItemTemplate>
                                </asp:TemplateColumn>
                            </Columns>
                        </asp:datagrid></div><!-- end content //--></div><!-- end contentArea //--></div>
            <!-- end contentWrapper //-->
            <!-- BEGIN DELETE MESSAGE BOX -->
            <div class="msgBox" id="msgBoxDelete" style="DISPLAY: none">
                <h1><%= ProductName %></h1>
                <div class="msgBoxBody">Deleting a media type permanently
                    removes it from the database.<br><br>Are you sure you want to delete the media 
                    type(s)? </div>
                <div class="msgBoxFooter"><asp:button id="btnYes" runat="server" CssClass="formBtn btnSmallTop" Text="Yes"></asp:button>&nbsp;
                    <asp:button id="btnNo" runat="server" CssClass="formBtn btnSmallTop" Text="No"></asp:button></div></div>
            <!-- END DELETE MESSAGE BOX --></form>
    </body>
</HTML>