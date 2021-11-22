<%@ Page language="c#" Codebehind="email-groups.aspx.cs" AutoEventWireup="false" Inherits="Bandl.VaultLedger.Web.UI.email_groups" %>
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
                    <h1>Email Groups</h1>
                    Review current email groups.&nbsp;&nbsp;To add an additional email group, click 
                    New Email Group. To edit an existing group, click the group name.&nbsp;&nbsp;To set the name of the email server, click Configure Email.
                    <div id="headerConstants"><a class="headerLink" style="left:635px" id="arrow" href="index.aspx">Tools Menu</a></div>
                </div> <!-- end pageHeader //-->
                <asp:placeholder id="PlaceHolder1" EnableViewState="False" runat="server"></asp:placeholder>
                <div class="contentArea" id="contentBorderTop">
                    <div class="contentBoxTop textLeft" align="left">
                        <table style="width:100%">
                            <tr>
                                <td align="left">
                                    <asp:button id="btnDelete" runat="server" Text="Delete Selected" CssClass="formBtn btnLargeTop"></asp:button>
                                </td>
                                <td align="right">
                                    <asp:button id="btnNew" runat="server" Text="New Email Group" CssClass="formBtn btnLargeTop"></asp:button>
                                    &nbsp;
                                    <asp:button id="btnEmail" runat="server" Text="Configure Email" CssClass="formBtn btnLargeTop"></asp:button>
                                </td>
                            </tr>
                        </table>
                    </div> <!-- end contentBoxTop //-->
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
                                <asp:HyperLinkColumn DataNavigateUrlFormatString="email-group-detail.aspx?name={0}" DataNavigateUrlField="Name"
                                    DataTextField="Name" HeaderText="Group Name">
                                    <HeaderStyle Width="25%" Font-Bold="True"></HeaderStyle>
                                </asp:HyperLinkColumn>
                                <asp:BoundColumn DataField="Operators" HeaderText="Email Addresses">
                                    <HeaderStyle Font-Bold="True"></HeaderStyle>
                                </asp:BoundColumn>
                            </Columns>
                        </asp:datagrid>
                    </div> <!-- end content //-->
                </div> <!-- end contentArea //-->
            </div> <!-- end contentWrapper //-->
            <!-- BEGIN DELETE MESSAGE BOX -->
            <div class="msgBox" id="msgBoxDel" style="DISPLAY:none">
                <h1><%= ProductName %></h1>
                <div class="msgBoxBody">
                    Deleting an email group permanently removes it from the database.<br>
                    <br>
                    Are you sure you want to delete the selected email group(s)?
                </div>
                <div class="msgBoxFooter">
                    <asp:button id="btnYes" runat="server" Text="Yes" CssClass="formBtn btnSmallTop"></asp:button>
                    &nbsp;
                    <asp:button id="btnNo" runat="server" Text="No" CssClass="formBtn btnSmallTop"></asp:button>
                </div>
            </div>
            <!-- END DELETE MESSAGE BOX -->
        </form>
    </body>
</HTML>
