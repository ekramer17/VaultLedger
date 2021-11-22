<%@ Page language="c#" Codebehind="list-statuses.aspx.cs" AutoEventWireup="false" Inherits="Bandl.VaultLedger.Web.UI.list_statuses" %>
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
                    <h1>Statuses Employed</h1>
                    Instruct
                    <%=ProductName%>
                    as to which statuses will be used for each list type.
                    <div id="headerConstants"><A class="headerLink" id="arrow" style="LEFT: 635px" href="index.aspx">Tools 
                            Menu</A></div>
                </div> <!-- end pageHeader //--><asp:placeholder id="PlaceHolder1" runat="server" EnableViewState="False"></asp:placeholder>
                <div class="tabNavigation fourTabs" id="tabSection" runat="server">
                    <div class="tabs fourTabOneSelected" id="statusLink" runat="server"><A href="#">Statuses Employed</A></div>
                    <div class="tabs fourTabTwo" id="emailLink" runat="server"><A href="list-email-status.aspx">Email Status Notifications</A></div>
                    <div class="tabs fourTabThree" id="alertLink" runat="server"><A href="list-email-alert.aspx">Email Overdue Alerts</A></div>
                    <div class="tabs fourTabFour" id="purgeLink" runat="server"><A href="list-purge.aspx">Purge Preferences</A></div>
                </div>
                <div class="contentArea">
                    <div class="content" style="OVERFLOW: hidden">
                        <table class="detailTable" id="tblGeneral">
                            <tr height="40">
                                <td width="550"><asp:label id="topQues" Runat="server">Do the people at the vault have access to your <%=ProductName%>?</asp:label></td>
                                <td><asp:dropdownlist id="ddlAccess" runat="server" width="50" AutoPostBack="True">
                                        <asp:ListItem Value="Yes">Yes</asp:ListItem>
                                        <asp:ListItem Value="No">No</asp:ListItem>
                                    </asp:dropdownlist></td>
                            </tr>
                        </table>
                    </div>
                </div> <!-- end contentArea //--><br>
                <div class="contentArea">
                    <h2 class="contentBoxHeader">Shipping Lists</h2>
                    <div class="content" style="OVERFLOW: hidden">
                        <table class="detailTable" id="tblShip">
                            <tr id="rowShip1" height="40" runat="server">
                                <td width="550">Will you be transmitting your shipping lists to the vault using
                                    <%=ProductName%>
                                    ?</td>
                                <td><asp:dropdownlist id="ddlShip1" runat="server" width="50">
                                        <asp:ListItem Value="Yes">Yes</asp:ListItem>
                                        <asp:ListItem Value="No">No</asp:ListItem>
                                    </asp:dropdownlist></td>
                            </tr>
                            <tr id="rowShip2" height="40" runat="server">
                                <td width="550">Do you verify outgoing media before they leave your enterprise?</td>
                                <td><asp:dropdownlist id="ddlShip2" runat="server" width="50">
                                        <asp:ListItem Value="Yes">Yes</asp:ListItem>
                                        <asp:ListItem Value="No">No</asp:ListItem>
                                    </asp:dropdownlist></td>
                            </tr>
                            <tr id="rowShip3" height="40" runat="server">
                                <td width="550">Would you like to actively declare when your media have been picked 
                                    up and are in transit?</td>
                                <td><asp:dropdownlist id="ddlShip3" runat="server" width="50">
                                        <asp:ListItem Value="Yes">Yes</asp:ListItem>
                                        <asp:ListItem Value="No">No</asp:ListItem>
                                    </asp:dropdownlist></td>
                            </tr>
                            <tr id="rowShip4" height="40" runat="server">
                                <td width="550">Will the people at the vault be actively declaring when your media 
                                    have arrived?</td>
                                <td><asp:dropdownlist id="ddlShip4" runat="server" width="50">
                                        <asp:ListItem Value="Yes">Yes</asp:ListItem>
                                        <asp:ListItem Value="No">No</asp:ListItem>
                                    </asp:dropdownlist></td>
                            </tr>
                            <tr id="rowShip5" height="40" runat="server">
                                <td width="550">Will the people at the vault be verifying your media after those 
                                    media have arrived at the vault?</td>
                                <td><asp:dropdownlist id="ddlShip5" runat="server" width="50">
                                        <asp:ListItem Value="Yes">Yes</asp:ListItem>
                                        <asp:ListItem Value="No">No</asp:ListItem>
                                    </asp:dropdownlist></td>
                            </tr>
                        </table>
                    </div>
                </div> <!-- end contentArea //--><br>
                <div class="contentArea">
                    <h2 class="contentBoxHeader">Receiving Lists</h2>
                    <div class="content" style="OVERFLOW: hidden">
                        <table class="detailTable" id="tblReceive" runat="server">
                            <tr id="rowRecv1" height="40" runat="server">
                                <td width="550">Will you be transmitting your receiving lists to the vault using
                                    <%=ProductName%>
                                    ?</td>
                                <td><asp:dropdownlist id="ddlRecv1" runat="server" width="50">
                                        <asp:ListItem Value="Yes">Yes</asp:ListItem>
                                        <asp:ListItem Value="No">No</asp:ListItem>
                                    </asp:dropdownlist></td>
                            </tr>
                            <tr id="rowRecv2" height="40" runat="server">
                                <td width="550">Will the people at the vault be verifying your media before those 
                                    media leave the vault?</td>
                                <td><asp:dropdownlist id="ddlRecv2" runat="server" width="50">
                                        <asp:ListItem Value="Yes">Yes</asp:ListItem>
                                        <asp:ListItem Value="No">No</asp:ListItem>
                                    </asp:dropdownlist></td>
                            </tr>
                            <tr id="rowRecv3" height="40" runat="server">
                                <td width="550">Will the people at the vault be actively declaring when those media 
                                    have left the vault and are in transit?</td>
                                <td><asp:dropdownlist id="ddlRecv3" runat="server" width="50">
                                        <asp:ListItem Value="Yes">Yes</asp:ListItem>
                                        <asp:ListItem Value="No">No</asp:ListItem>
                                    </asp:dropdownlist></td>
                            </tr>
                            <tr id="rowRecv4" height="40" runat="server">
                                <td width="550">Would you like to actively declare when returning media have 
                                    arrived at your enterprise?</td>
                                <td><asp:dropdownlist id="ddlRecv4" runat="server" width="50">
                                        <asp:ListItem Value="Yes">Yes</asp:ListItem>
                                        <asp:ListItem Value="No">No</asp:ListItem>
                                    </asp:dropdownlist></td>
                            </tr>
                            <tr id="rowRecv5" height="40" runat="server">
                                <td width="550">Do you verify returning media after they have arrived?</td>
                                <td><asp:dropdownlist id="ddlRecv5" runat="server" width="50">
                                        <asp:ListItem Value="Yes">Yes</asp:ListItem>
                                        <asp:ListItem Value="No">No</asp:ListItem>
                                    </asp:dropdownlist></td>
                            </tr>
                        </table>
                    </div>
                    <div class="contentBoxBottom" id="bottom1" runat="server">
                        <div class="floatLeft"><asp:button id="btnDefaults1" runat="server" Text="Restore Defaults" CssClass="formBtn btnLargeTop floatLeft"></asp:button></div>
                        <asp:button id="btnSave1" runat="server" Text="Save" CssClass="formBtn btnSmall"></asp:button>
                    </div>
                </div> <!-- end contentArea //-->
                <br>
                <div class="contentArea" id="disasterSection" runat="server">
                    <h2 class="contentBoxHeader">Disaster Recovery Lists</h2>
                    <div class="content" style="OVERFLOW: hidden">
                        <table class="detailTable" id="tblDisaster" runat="server">
                            <tr height="40">
                                <td width="550">Will you be transmitting your disaster recovery lists to the vault 
                                    using
                                    <%=ProductName%>
                                    ?</td>
                                <td><asp:dropdownlist id="ddlDis1" runat="server" width="50">
                                        <asp:ListItem Value="Yes">Yes</asp:ListItem>
                                        <asp:ListItem Value="No">No</asp:ListItem>
                                    </asp:dropdownlist>
                                </td>
                            </tr>
                        </table>
                    </div>
                    <div class="contentBoxBottom">
                        <div class="floatLeft"><asp:button id="btnDefaults2" runat="server" Text="Restore Defaults" CssClass="formBtn btnLargeTop floatLeft"></asp:button></div>
                        <asp:button id="btnSave2" runat="server" Text="Save" CssClass="formBtn btnSmall"></asp:button>
                    </div>
                </div> <!-- end contentArea //-->
                <!-- BEGIN SAVE MESSAGE BOX -->
                <div class="msgBoxSmall" id="msgBoxSave" style="DISPLAY: none">
                    <h1><%=ProductName%></h1>
                    <div class="msgBoxBody">Statuses were updated successfully.
                    </div>
                    <div class="msgBoxFooter">
                        <asp:button id="btnOK" runat="server" Text="OK" CssClass="formBtn btnSmallTop"></asp:button>
                    </div>
                </div>
                <!-- END SAVE MESSAGE BOX --></div>
            <DIV></DIV>
        </form>
    </body>
</HTML>
