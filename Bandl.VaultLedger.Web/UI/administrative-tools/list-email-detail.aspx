<%@ Page language="c#" Codebehind="list-email-detail.aspx.cs" AutoEventWireup="false" Inherits="Bandl.VaultLedger.Web.UI.list_email_detail" %>
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
                    <h1><asp:Label id="lblTitle" runat="server">List Status Email Groups</asp:Label></h1>
                    <asp:Label id="lblDesc" runat="server">Assign groups to receive an alert email when a ??? list attains ??? status.</asp:Label>
                </div> <!-- end pageHeader //-->
                <asp:placeholder id="PlaceHolder1" EnableViewState="False" runat="server"></asp:placeholder>
                <div class="contentArea">
                    <div class="content">
                        <asp:datagrid id="DataGrid1" runat="server" CssClass="detailTable" AutoGenerateColumns="False">
                            <AlternatingItemStyle CssClass="alternate"></AlternatingItemStyle>
                            <HeaderStyle CssClass="header"></HeaderStyle>
                            <Columns>
                                <asp:TemplateColumn>
                                    <HeaderStyle CssClass="checkbox"></HeaderStyle>
                                    <ItemStyle CssClass="checkbox"></ItemStyle>
                                    <HeaderTemplate>
                                        <input type="checkbox" id="cbCheckAll" runat="server" onclick="checkAll('DataGrid1', 'cbItemChecked', this.checked)"
                                            NAME="cbCheckAll">
                                    </HeaderTemplate>
                                    <ItemTemplate>
                                        <input type="checkbox" id="cbItemChecked" runat="server" onclick="checkFirst('DataGrid1', 'cbCheckAll', false)"
                                            NAME="cbItemChecked">
                                    </ItemTemplate>
                                </asp:TemplateColumn>
                                <asp:HyperLinkColumn DataNavigateUrlFormatString="email-group-detail.aspx?name={0}" DataNavigateUrlField="Name" DataTextField="Name" HeaderText="Group Name">
                                    <HeaderStyle Width="25%" Font-Bold="True"></HeaderStyle>
                                </asp:HyperLinkColumn>
                                <asp:BoundColumn DataField="Operators" HeaderText="Email Addresses">
                                    <HeaderStyle Font-Bold="True"></HeaderStyle>
                                </asp:BoundColumn>
                            </Columns>
                        </asp:datagrid>
                    </div> <!-- end content //-->
                    <div class="contentBoxBottom">
                        <asp:button id="btnSave" runat="server" CssClass="formBtn btnSmall" Text="Save"></asp:button>
                    </div>
                </div> <!-- end contentArea //-->
            </div> <!-- end contentWrapper //-->
        </form>
    </body>
</HTML>
