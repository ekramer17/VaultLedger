<%@ Page language="c#" Codebehind="media-rpt-filter.aspx.cs" AutoEventWireup="false" Inherits="Bandl.VaultLedger.Web.UI.media_rpt_filter" %>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<HTML>
    <HEAD>
        <META http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
        <meta content="Microsoft Visual Studio .NET 7.1" name="GENERATOR">
        <meta content="C#" name="CODE_LANGUAGE">
        <meta content="JavaScript" name="vs_defaultClientScript">
        <meta content="http://schemas.microsoft.com/intellisense/ie5" name="vs_targetSchema">
        <!--#include file = "../includes/baseHead.inc"-->
    </HEAD>
    <body>
        <!--#include file = "../includes/baseBody.inc"-->
        <form id="Form1" method="post" runat="server">
            <div class="contentWrapper" runat="server">
                <!-- page header -->
                <div class="pageHeader">
                    <h1>Media Report Filter</h1>
                    Specify one or more criteria on which to filter, and then click Report to see 
                    the results.
                </div>
                <asp:placeholder id="PlaceHolder1" EnableViewState="False" runat="server"></asp:placeholder>
                <div class="contentArea" id="contentBorderTop">
                    <div id="accountDetail">
                        <div class="introHeader">Please enter your filter criteria below:</div>
                        <hr class="step">
                        <table cellSpacing="0" cellPadding="0" border="0">
                            <tr height="24">
                                <td width="120">Return Start Date:</td>
                                <td width="270">
                                    <table cellSpacing="0" cellPadding="0" width="270" border="0">
                                        <tr>
                                            <td width="217">
                                                <asp:textbox id="txtStartDate" runat="server" CssClass="calendar"></asp:textbox>
                                            </td>
                                            <td width="53" class="calendarCell">
                                                <a href="javascript:openCalendar('txtStartDate');" class="iconLink calendarLink"></a>
                                            </td>
                                        </tr>
                                    </table>
                                </td>
                                <td width="110">&nbsp;&nbsp;&nbsp;&nbsp;Missing:
                                </td>
                                <td>
                                    <asp:DropDownList id="ddlMissing" runat="server" Width="154px">
                                        <asp:ListItem Value="" Selected="True"></asp:ListItem>
                                        <asp:ListItem Value="True">Yes</asp:ListItem>
                                        <asp:ListItem Value="False">No</asp:ListItem>
                                    </asp:DropDownList>
                                </td>
                            </tr>
                            <tr height="24">
                                <td>Return End Date:</td>
                                <td>
                                    <table cellSpacing="0" cellPadding="0" width="270" border="0">
                                        <tr>
                                            <td width="217">
                                                <asp:textbox id="txtEndDate" runat="server" CssClass="calendar"></asp:textbox>
                                            </td>
                                            <td width="53" class="calendarCell">
                                                <a href="javascript:openCalendar('txtEndDate');" class="iconLink calendarLink"></a>
                                            </td>
                                        </tr>
                                    </table>
                                </td>
                                <td>&nbsp;&nbsp;&nbsp;&nbsp;Account</td>
                                <td>
                                    <asp:DropDownList id="ddlAccount" runat="server" Width="154px"></asp:DropDownList>
                                </td>
                            </tr>
                            <tr height="24">
                                <td>Location:</td>
                                <td>
                                    <asp:DropDownList id="ddlLocation" runat="server" Width="154px">
                                        <asp:ListItem Value="" Selected="True"></asp:ListItem>
                                        <asp:ListItem Value="Enterprise">Enterprise</asp:ListItem>
                                        <asp:ListItem Value="Vault">Vault</asp:ListItem>
                                    </asp:DropDownList>
                                </td>
                                <td>&nbsp;&nbsp;&nbsp;&nbsp;Media Type:</td>
                                <td>
                                    <asp:DropDownList id="ddlMediaType" runat="server" Width="154px"></asp:DropDownList>
                                </td>
                            </tr>
                            <tr height="24">
                                <td>Serial Number:</td>
                                <td>
                                    <asp:textbox id="txtSerialNo" runat="server" CssClass="calendar"></asp:textbox>
                                </td>
                            </tr>
                        </table>
                    </div>
                    <!-- SEARCH BUTTON //-->
                    <div class="contentBoxBottom">
                        <asp:button id="btnReport" runat="server" CssClass="formBtn btnMedium" Text="Report"></asp:button>
                        &nbsp; <input type="button" id="btnCancel" onclick="location.href='report-list.aspx'" class="formBtn btnMedium"
                            value="Cancel">
                    </div>
                </div>
            </div>
        </form>
    </body>
</HTML>
