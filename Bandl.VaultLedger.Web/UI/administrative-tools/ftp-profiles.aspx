<%@ Page language="c#" Codebehind="ftp-profiles.aspx.cs" AutoEventWireup="false" Inherits="Bandl.VaultLedger.Web.UI.ftp_profiles" %>
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
                    <h1>FTP Profiles</h1>
                    View the FTP profiles defined to the system.&nbsp;&nbsp;To edit the details of a profile, click on its
                    link.
                    <div id="headerConstants"><a class="headerLink" style="left:635px" id="arrow" href="index.aspx">Tools Menu</a></div>
                </div>
                <!-- end pageHeader //--><asp:placeholder id="PlaceHolder1" runat="server" EnableViewState="False"></asp:placeholder>
                <div class="contentArea" id="contentBorderTop">
                    <div class="contentBoxTop">
                        <div class="floatLeft">
                            <asp:button id="btnDelete" runat="server" CssClass="formBtn btnLargeTop" Text="Delete Selected"></asp:button>
                        </div>
                        <div class="floatRight">
                            <asp:button id="btnNew" runat="server" CssClass="formBtn btnLargeTop" Text="New Profile"></asp:button>
                        </div>
                    </div><!-- end contentBoxTop //-->
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
                                <asp:HyperLinkColumn DataTextField="Name" DataNavigateUrlFormatString="ftp-detail.aspx?profile={0}" DataNavigateUrlField="Name" HeaderText="Profile Name" HeaderStyle-Font-Bold="True" HeaderStyle-Width="125"/>
                                <asp:BoundColumn DataField="Server" HeaderText="Server" HeaderStyle-Font-Bold="True" HeaderStyle-Width="125"/>
                                <asp:BoundColumn DataField="Login" HeaderText="Login" HeaderStyle-Font-Bold="True" HeaderStyle-Width="110"/>
                                <asp:TemplateColumn HeaderText="Passive" HeaderStyle-Font-Bold="True" HeaderStyle-Width="60">
                                    <ItemTemplate><%# Convert.ToBoolean(DataBinder.Eval(Container.DataItem, "Passive")) ? "Yes" : "No" %></ItemTemplate>
                                </asp:TemplateColumn>
                                <asp:TemplateColumn HeaderText="Secure" HeaderStyle-Font-Bold="True" HeaderStyle-Width="55">
                                    <ItemTemplate><%# Convert.ToBoolean(DataBinder.Eval(Container.DataItem, "Secure")) ? "Yes" : "No" %></ItemTemplate>
                                </asp:TemplateColumn>
                                <asp:BoundColumn DataField="FilePath" HeaderText="Path" HeaderStyle-Font-Bold="True" />
                            </Columns>
                        </asp:datagrid>
                    </div><!-- end content //-->
                </div><!-- end contentArea //-->
            </div>
            <!-- BEGIN DELETE MESSAGE BOX -->
            <div class="msgBox" id="msgBoxDel" style="DISPLAY:none">
                <h1><%= ProductName %></h1>
                <div class="msgBoxBody">
                    Deleting an FTP profile permanently removes it from the
                    database.&nbsp;&nbsp;Those accounts employing the deleted profile will have
                    no associated FTP profile.
                    <br><br>
                    Are you sure you want to delete the selected FTP profile(s)?
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