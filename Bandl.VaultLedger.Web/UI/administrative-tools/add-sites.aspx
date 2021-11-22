<%@ Page CodeBehind="add-sites.aspx.cs" Language="c#" AutoEventWireup="false" Inherits="Bandl.VaultLedger.Web.UI.add_sites" %>
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
        <form id="Form1" method="get" runat="server">
            <div class="contentWrapper">
                <!-- page header -->
                <div class="pageHeader">
                    <h1>New Site Map</h1>
                    Map a TMS report site to one of two locations: Enterprise (onsite) or Vault 
                    (offsite).&nbsp;&nbsp;When you finish, click Save.
                    <div id="headerConstants"><a class="headerLink" style="LEFT:635px" id="arrow" href="index.aspx">Tools 
                            Menu</a></div>
                </div> <!-- end pageHeader //-->
                <asp:PlaceHolder id="PlaceHolder1" EnableViewState="False" runat="server"></asp:PlaceHolder>
                <div class="contentArea" id="contentBorderTop">
                    <div class="content" id="accountDetail">
                        <table class="accountDetailTable" cellSpacing="0" cellPadding="0" width="724" border="0">
                            <tr>
                                <td height="23" width="110">Site Name:</td>
                                <td height="23">
                                    <asp:textbox id="txtSiteName" runat="server" CssClass="medium"></asp:textbox><asp:RequiredFieldValidator id="rfvSiteName" runat="server" ErrorMessage="&amp;nbsp;Please enter a site name"
                                        ControlToValidate="txtSiteName"></asp:RequiredFieldValidator>
                                </td>
                            </tr>
                            <tr>
                                <td>Location:</td>
                                <td>
                                    <asp:dropdownlist id="ddlLocation" runat="server" CssClass="medium">
                                        <asp:ListItem Value="-Select Location-" Selected="True">-Select Location-</asp:ListItem>
                                        <asp:ListItem Value="0">Vault</asp:ListItem>
                                        <asp:ListItem Value="1">Enterprise</asp:ListItem>
                                    </asp:dropdownlist>
                                    <asp:RegularExpressionValidator id="revLocation" runat="server" ErrorMessage="&amp;nbsp;Please select a location"
                                        ValidationExpression="^[01]$" ControlToValidate="ddlLocation"></asp:RegularExpressionValidator>
                                </td>
                            </tr>
                            <tr id="rowAccount" runat="server">
                                <td>
                                    Account:
                                </td>
                                <td>
                                    <asp:dropdownlist id="ddlAccount" runat="server" CssClass="medium">
                                        <asp:ListItem Value="-Select Account-" Selected="True">-Select Account-</asp:ListItem>
                                        <asp:ListItem Value="None">None</asp:ListItem>
                                    </asp:dropdownlist>
                                </td>
                            </tr>
                        </table>
                    </div> <!-- end content //-->
                    <div class="contentBoxBottom">
                        <asp:button id="btnSave" runat="server" CssClass="formBtn btnSmall" Text="Save"></asp:button>
                        &nbsp; <input type="button" id="btnCancel" onclick="location.href='view-sites.aspx'" class="formBtn btnMedium"
                            value="Cancel">
                    </div>
                </div> <!-- end contentArea //-->
            </div> <!-- end contentWrapper //-->
        </form>
    </body>
</HTML>
