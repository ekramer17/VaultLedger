<%@ Page language="c#" Codebehind="email-group-detail.aspx.cs" AutoEventWireup="false" Inherits="Bandl.VaultLedger.Web.UI.email_group_detal" %>
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
                    <h1><asp:Label id="lblTitle" runat="server">Email Group Detail</asp:Label></h1>
                    <asp:Label id="lblDesc" runat="server"></asp:Label>
                    <div id="headerConstants"><a class="headerLink" style="left:630px" id="arrow" href="email-groups.aspx">Email Groups</a></div>
                </div> <!-- end pageHeader //-->
                <asp:placeholder id="PlaceHolder1" EnableViewState="False" runat="server"></asp:placeholder>
                <div class="contentArea" id="contentBorderTop">
                    <div class="content" id="accountDetail">
                        <table cellSpacing="0" cellPadding="0" width="724" border="0">
                            <tr>
                                <td class="leftPad" width="105"><b>Group Name:</b></td>
                                <td><asp:textbox id="txtGroupName" runat="server" CssClass="medium"></asp:textbox></td>
                            </tr>
                        </table>
                    </div>
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
                                <asp:HyperLinkColumn DataNavigateUrlFormatString="user-detail.aspx?login={0}" DataNavigateUrlField="Login" DataTextField="Name" HeaderText="Operator Name">
                                    <HeaderStyle Width="25%" Font-Bold="True"></HeaderStyle>
                                </asp:HyperLinkColumn>
                                <asp:BoundColumn DataField="Login" HeaderText="Login">
                                    <HeaderStyle Width="20%" Font-Bold="True"></HeaderStyle>
                                </asp:BoundColumn>
                                <asp:BoundColumn DataField="Email" HeaderText="Email Address">
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
