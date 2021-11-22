<%@ Page language="c#" Codebehind="list-purge.aspx.cs" AutoEventWireup="false" Inherits="Bandl.VaultLedger.Web.UI.list_purge" %>
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
                    <h1>List Purge Preferences</h1>
                    Instruct the application as to how you would like lists purged from the system.
                    <div id="headerConstants"><a class="headerLink" style="LEFT:635px" id="arrow" href="index.aspx">Tools 
                            Menu</a></div>
                </div> <!-- end pageHeader //-->
                <asp:placeholder id="PlaceHolder1" runat="server" EnableViewState="False"></asp:placeholder>
                <div class="tabNavigation fourTabs" id="tabSection" runat="server">
                    <div id="tab1" runat="server"><A href="list-statuses.aspx">Statuses Employed</A></div>
                    <div id="tab2" runat="server"><A href="list-email-status.aspx">Email Status 
                            Notifications</A></div>
                    <div id="tab3" runat="server"><A href="list-email-alert.aspx">Email Overdue Alerts</A></div>
                    <div id="tab4" runat="server"><A href="#">Purge Preferences</A></div>
                </div>
                <div class="contentArea">
                    <div class="content">
                        <asp:datagrid id="DataGrid1" HeaderStyle-Font-Bold="True" HeaderStyle-Wrap="False" runat="server"
                            CssClass="detailTable" AutoGenerateColumns="False" BorderStyle="None">
                            <AlternatingItemStyle Height="33px" CssClass="alternate"></AlternatingItemStyle>
                            <ItemStyle Height="33px"></ItemStyle>
                            <HeaderStyle Font-Bold="True" Wrap="False" CssClass="header"></HeaderStyle>
                            <Columns>
                                <asp:TemplateColumn HeaderText="List Type">
                                    <ItemTemplate>
                                        <asp:Label Text='<%# GetListTypeName(DataBinder.Eval(Container.DataItem, "ListType").ToString()) %>' runat="server" ID="lblCategory" />
                                    </ItemTemplate>
                                </asp:TemplateColumn>
                                <asp:TemplateColumn HeaderText="Days">
                                    <ItemTemplate>
                                        <asp:TextBox id="txtDays" runat="server" Text='<%# DataBinder.Eval(Container.DataItem, "Days").ToString() %>' Width="50px" MaxLength="3">
                                        </asp:TextBox>
                                    </ItemTemplate>
                                </asp:TemplateColumn>
                                <asp:TemplateColumn HeaderText="Archive">
                                    <ItemTemplate>
                                        <asp:DropDownList id="ddlArchive" runat="server" Width="74px" SelectedIndex='<%# Convert.ToBoolean(DataBinder.Eval(Container.DataItem, "Archive")) ? 0 : 1 %>'>
                                            <asp:ListItem Value="true">Yes</asp:ListItem>
                                            <asp:ListItem Value="false">No</asp:ListItem>
                                        </asp:DropDownList>
                                    </ItemTemplate>
                                </asp:TemplateColumn>
                                <asp:TemplateColumn Visible="False">
                                    <ItemTemplate>
                                        <asp:Label Text='<%# DataBinder.Eval(Container.DataItem, "ListType").ToString() %>' runat="server" ID="lblListType" />
                                    </ItemTemplate>
                                </asp:TemplateColumn>
                            </Columns>
                        </asp:datagrid>
                    </div>
                    <div class="contentBoxBottom">
                        <asp:button id="btnSave" runat="server" CssClass="formBtn btnSmall" Text="Save"></asp:button>
                    </div>
                    <!-- BEGIN SAVE MESSAGE BOX -->
                    <div class="msgBoxSmall" id="msgBoxSave" style="DISPLAY:none">
                        <h1><%= ProductName %></h1>
                        <div class="msgBoxBody">
                            Purge preferences were updated successfully.
                        </div>
                        <div class="msgBoxFooter">
                            <asp:button id="btnOK" runat="server" Text="OK" CssClass="formBtn btnSmallTop"></asp:button>
                        </div>
                    </div>
                    <!-- END SAVE MESSAGE BOX -->
                </div>
            </div>
        </form>
    </body>
</HTML>
