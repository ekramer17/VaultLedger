<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="list-history-popup.aspx.cs" Inherits="Bandl.VaultLedger.Web.UI.lists.list_history_popup" %>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
    <meta content="Microsoft Visual Studio .NET 7.1" name="GENERATOR">
    <meta content="C#" name="CODE_LANGUAGE">
    <meta content="JavaScript" name="vs_defaultClientScript">
    <meta content="http://schemas.microsoft.com/intellisense/ie5" name="vs_targetSchema">
    <!--#include file = "../includes/baseHead.inc"-->
    <style>
    body {
	    background: #2e2b24 !important;
    }
    </style>
</head>
<body>
    <form id="form1" runat="server">
        <asp:datagrid id="DataGrid1" runat="server" CssClass="detailTable" AllowCustomPaging="True" AutoGenerateColumns="False">
            <AlternatingItemStyle CssClass="alternate"></AlternatingItemStyle>
            <HeaderStyle CssClass="header"></HeaderStyle>
            <Columns>
                <asp:TemplateColumn HeaderText="Date">
                    <HeaderStyle Width="110px" Font-Bold="True"></HeaderStyle>
                    <ItemTemplate>
                        <asp:Label BorderWidth=0 runat="server" id="lblDate" Text='<%# DisplayDate(DataBinder.Eval(Container.DataItem, "RecordDate"), true, true, false) %>'>
                        </asp:Label>
                    </ItemTemplate>
                </asp:TemplateColumn>
                <asp:BoundColumn DataField="Login" HeaderText="Login">
                    <HeaderStyle Width="90px"></HeaderStyle>
                </asp:BoundColumn>
                <asp:BoundColumn DataField="Detail" HeaderText="Detail" ItemStyle-Wrap="True">
                    <HeaderStyle></HeaderStyle>
                </asp:BoundColumn>
            </Columns>
        </asp:datagrid>
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
        </table>
    </form>
</body>
</html>
