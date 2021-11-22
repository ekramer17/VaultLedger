<%@ Page language="c#" Codebehind="audit-expirations.aspx.cs" AutoEventWireup="false" Inherits="Bandl.VaultLedger.Web.UI.audit_expirations" %>
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
                <!-- page header -->
                <div class="pageHeader">
                    <h1>Audit Trail Expirations</h1>
                    Specify how long you would like to keep records of each audit type before they 
                    are purged from the database.
                    <div id="headerConstants"><a class="headerLink" style="LEFT:635px" id="arrow" href="index.aspx">Tools 
                            Menu</a></div>
                </div>
                <asp:placeholder id="PlaceHolder1" runat="server" EnableViewState="False"></asp:placeholder>
                <div class="contentArea" id="contentBorderTop" runat="server">
                    <div class="content"><asp:datagrid id="DataGrid1" runat="server" CssClass="detailTable" HeaderStyle-Font-Bold="True"
                            HeaderStyle-Wrap="False" AutoGenerateColumns="False" BorderStyle="None">
                            <AlternatingItemStyle Height="33px" CssClass="alternate"></AlternatingItemStyle>
                            <ItemStyle Height="33px"></ItemStyle>
                            <HeaderStyle Font-Bold="True" Wrap="False" CssClass="header"></HeaderStyle>
                            <Columns>
                                <asp:TemplateColumn HeaderText="Category">
                                    <ItemTemplate>
                                        <asp:Label Text='<%# GetCategoryName(DataBinder.Eval(Container.DataItem, "AuditType").ToString()) %>' runat="server" ID="lblCategory" />
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
                                        <asp:Label Text='<%# DataBinder.Eval(Container.DataItem, "AuditType").ToString() %>' runat="server" ID="lblAuditType" />
                                    </ItemTemplate>
                                </asp:TemplateColumn>
                            </Columns>
                        </asp:datagrid></div> <!-- end content //-->
                    <div class="contentBoxBottom">
                        <!-- Prune button must be of html input type so that Save may act as default -->
                        <input type="button" id="btnPrune" runat="server" value="Prune" class="formBtn btnSmall">
                        &nbsp; <input type="button" id="btnSave" runat="server" value="Save" class="formBtn btnSmall">
                    </div>
                </div> <!-- end contentArea //-->
            </div> <!-- end contentWrapper //-->
            <!-- BEGIN SAVE MESSAGE BOX -->
            <div class="msgBoxSmall" id="msgBoxSave" style="DISPLAY: none">
                <h1><%= ProductName %></h1>
                <div class="msgBoxBody">Audit trail expirations were updated successfully.
                </div>
                <div class="msgBoxFooter"><asp:button id="btnOK1" runat="server" Text="OK" CssClass="formBtn btnSmallTop"></asp:button></div>
            </div>
            <!-- END SAVE MESSAGE BOX -->
            <!-- BEGIN AUDIT TRAIL PRUNE CONFIRMATION MESSAGE BOX -->
            <div class="msgBox" id="msgBoxConfirm" style="DISPLAY:none">
                <h1><%= ProductName %></h1>
                <div class="msgBoxBody">
                    Pruning the audit trails will delete any audit records aged beyond the 
                    expiration parameters that you have specified.
                    <br>
                    <br>
                    Are you sure you wish to prune the audit trails?
                </div>
                <div class="msgBoxFooter">
                    <asp:Button Text="Yes" CssClass="formBtn btnSmallTop" Runat="server" id="btnYes"></asp:Button>
                    &nbsp;
                    <asp:Button Text="No" CssClass="formBtn btnSmallTop" Runat="server" id="btnNo"></asp:Button>
                </div>
            </div>
            <!-- END AUDIT TRAIL PRUNE CONFIRMATION MESSAGE BOX -->
            <!-- BEGIN AUDIT TRAIL CLEAN MESSAGE BOX -->
            <div class="msgBoxSmall" id="msgBoxPrune" style="DISPLAY:none">
                <h1><%= ProductName %></h1>
                <div class="msgBoxBody">
                    The audit trails have been pruned.
                </div>
                <div class="msgBoxFooter">
                    <asp:button id="btnOK2" runat="server" Text="OK" CssClass="formBtn btnSmallTop"></asp:button>
                </div>
            </div>
            <!-- END AUDIT TRAIL CLEAN MESSAGE BOX -->
        </form>
        </A>
        <DIV></DIV>
        <DIV></DIV>
    </body>
</HTML>
