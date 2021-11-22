<%@ Page language="c#" Codebehind="list-email-alert.aspx.cs" AutoEventWireup="false" Inherits="Bandl.VaultLedger.Web.UI.list_email_alert" %>
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
                    <h1><asp:Label id="lblTitle" runat="server">Email Overdue Alerts</asp:Label></h1>
                    Send email alerts to specified groups when a list is overdue for processing.
                    <div id="headerConstants"><a class="headerLink" style="LEFT:635px" id="arrow" href="index.aspx">Tools 
                            Menu</a></div>
                </div> <!-- end pageHeader //-->
                <asp:placeholder id="PlaceHolder1" runat="server" EnableViewState="False"></asp:placeholder>
                <div class="tabNavigation fourTabs">
                    <div class="tabs fourTabOne"><A href="list-statuses.aspx">Statuses Employed</A></div>
                    <div class="tabs fourTabTwo"><A href="list-email-status.aspx">Email Status 
                            Notifications</A></div>
                    <div class="tabs fourTabThreeSelected"><A href="#">Email Overdue Alerts</A></div>
                    <div class="tabs fourTabFour"><A href="list-purge.aspx">Purge Preferences</A></div>
                </div>
                <div class="contentArea contentBorderTopNone">
                    <div class="contentBoxTop" id="divConfigure" runat="server">
                        <div class="floatRight">
                            <asp:button id="btnEmail" runat="server" Text="Configure Email" CssClass="formBtn btnLargeTop"></asp:button>
                        </div>
                    </div>
                    <!-- end contentTop //-->
                    <div class="content">
                        <asp:datagrid id="DataGrid1" runat="server" CssClass="detailTable" HeaderStyle-Font-Bold="True"
                            HeaderStyle-Wrap="False" AutoGenerateColumns="False" BorderStyle="None">
                            <AlternatingItemStyle Height="33px" CssClass="alternate"></AlternatingItemStyle>
                            <ItemStyle Height="33px"></ItemStyle>
                            <HeaderStyle Font-Bold="True" Wrap="False" CssClass="header"></HeaderStyle>
                            <Columns>
                                <asp:HyperLinkColumn HeaderStyle-Width="160px" DataNavigateUrlFormatString="list-email-detail.aspx?listType={0}&alert=1"
                                    DataNavigateUrlField="TypeInt" DataTextField="ListType" HeaderText="List Type">
                                    <HeaderStyle Font-Bold="True"></HeaderStyle>
                                </asp:HyperLinkColumn>
                                <asp:TemplateColumn HeaderText="Days" HeaderStyle-Width="120px">
                                    <ItemTemplate>
                                        <asp:TextBox id="txtDays" runat="server" Text='<%# DataBinder.Eval(Container.DataItem, "Days").ToString() %>' Width="50px" MaxLength="3">
                                        </asp:TextBox>
                                    </ItemTemplate>
                                </asp:TemplateColumn>
                                <asp:TemplateColumn HeaderText="Email Groups">
                                    <ItemTemplate>
                                        <asp:Label Text='<%# DataBinder.Eval(Container.DataItem, "EmailGroups").ToString() %>' runat="server" Id="lblEmailGroups" />
                                    </ItemTemplate>
                                </asp:TemplateColumn>
                            </Columns>
                        </asp:datagrid>
                    </div> <!-- end content //-->
                    <div class="contentBoxBottom">
                        <input class="formBtn btnMedium" id="btnSave" type="button" value="Save" runat="server">
                    </div>
                </div> <!-- end contentArea //-->
            </div> <!-- end contentWrapper //-->
            <!-- BEGIN OK MESSAGE BOX -->
            <div class="msgBoxSmall" id="msgBoxOK" style="DISPLAY:none">
                <h1><%= ProductName %></h1>
                <div class="msgBoxBody">Email overdue alerts have been updated.</div>
                <div class="msgBoxFooter"><input class="formBtn btnSmallTop" type="button" value="OK" id="btnOK" runat="server"></div>
            </div>
            <!-- END OK MESSAGE BOX -->
        </form>
    </body>
</HTML>
