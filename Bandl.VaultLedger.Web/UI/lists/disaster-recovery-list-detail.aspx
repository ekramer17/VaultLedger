<%@ Page language="c#" Codebehind="disaster-recovery-list-detail.aspx.cs" AutoEventWireup="false" Inherits="Bandl.VaultLedger.Web.UI.disaster_recovery_list_detail" %>
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
            <div class="contentWrapper">
                <div class="pageHeader">
                    <h1><asp:Label id="lblCaption" runat="server"></asp:Label></h1>
                    View media currently on a list and perform actions such as adding, removing, 
                    and editing the media on the list. You may also transmit the list to the 
                    offsite vendor.
                    <br>
                    <br>
                    <table cellSpacing="0" cellPadding="0" border="0">
                        <tr>
                            <td width="160"><b>List Number:</b>&nbsp;&nbsp;<asp:label id="lblListNo" runat="server"></asp:label></td>
                            <td width="150"><b>Status:</b>&nbsp;&nbsp;<asp:label id="lblStatus" runat="server"></asp:label></td>
                            <td width="160"><b>Create Date:</b>&nbsp;&nbsp;<asp:label id="lblCreateDate" runat="server"></asp:label></td>
                            <td><b>Account:</b>&nbsp;&nbsp;<asp:label id="lblAccount" runat="server"></asp:label></td>
                        </tr>
                    </table>
                    <!-- header links -->
                    <div id="headerConstants">
                        <A class="headerLink" style="LEFT:552px" id="listLink" href="disaster-recovery-list-browse.aspx">
                            Lists</A>
                        <asp:linkbutton CssClass="headerLink" style="LEFT:608px" runat="server" id="exportLink">Export</asp:linkbutton>
                        <asp:linkbutton CssClass="headerLink" runat="server" id="printLink">Print</asp:linkbutton>
                    </div>
                </div> <!-- end pageHeader //-->
                <asp:placeholder id="PlaceHolder1" runat="server" EnableViewState="False"></asp:placeholder>
                <div class="contentArea" id="contentBorderTop">
                    <div class="contentBoxTop">
                        <div class="floatRight">
                            <asp:button id="btnAdd" runat="server" Text="Add" CssClass="formBtn btnSmallTop"></asp:button>
                        </div>
                        <asp:dropdownlist id="ddlSelectAction" runat="server" CssClass="selectAction" Width="140">
                            <asp:ListItem Value="-Choose an Action-" Selected="True">-Choose an Action-</asp:ListItem>
                            <asp:ListItem Value="Remove">Remove Selected</asp:ListItem>
                            <asp:ListItem Value="Edit">Edit Selected</asp:ListItem>
                        </asp:dropdownlist>
                        &nbsp;&nbsp;
                        <asp:button id="btnGo" runat="server" Text="Go" CssClass="formBtn btnSmallGo"></asp:button>
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
                                        <input id="cbCheckAll" onclick="checkAll('DataGrid1', 'cbItemChecked', this.checked)" type="checkbox"
                                            runat="server" NAME="cbCheckAll" />
                                    </HeaderTemplate>
                                    <ItemTemplate>
                                        <input id="cbItemChecked" onclick="checkFirst('DataGrid1', 'cbCheckAll', false)" type="checkbox"
                                            runat="server" NAME="cbItemChecked" />
                                    </ItemTemplate>
                                </asp:TemplateColumn>
                                <asp:BoundColumn DataField="SerialNo" HeaderText="Serial Number">
                                    <HeaderStyle Font-Bold="True"></HeaderStyle>
                                </asp:BoundColumn>
                                <asp:BoundColumn DataField="Code" HeaderText="DR Code">
                                    <HeaderStyle Font-Bold="True"></HeaderStyle>
                                </asp:BoundColumn>
                                <asp:TemplateColumn HeaderText="Status">
                                    <HeaderStyle Font-Bold="True"></HeaderStyle>
                                    <ItemTemplate>
                                        <%# StatusString(DataBinder.Eval(Container.DataItem, "Status")) %>
                                    </ItemTemplate>
                                </asp:TemplateColumn>
                                <asp:BoundColumn DataField="Account" HeaderText="Account">
                                    <HeaderStyle Font-Bold="True"></HeaderStyle>
                                </asp:BoundColumn>
                            </Columns>
                        </asp:datagrid>
                    </div> <!-- end content //-->
                    <!-- PAGE LINKS //-->
                    <br>
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
                    </table> <!-- end pageLinks //-->
                    <div class="contentBoxBottom" id="divButtons" runat="server">
                        <asp:button id="btnTransmit" runat="server" Text="Transmit" CssClass="formBtn btnMedium"></asp:button>
                    </div>
                </div> <!-- end contentArea //-->
            </div> <!-- end contentWrapper //-->
            <!-- BEGIN TRANSMIT CONFIRMATION MESSAGE BOX -->
            <div class="msgBox" id="msgBoxConfirm" style="DISPLAY: none">
                <h1><%= ProductName %></h1>
                <div class="msgBoxBody"><asp:Label id="lblConfirm" runat="server"></asp:Label><br>
                    <br>
                    Are you sure you wish to transmit it?</div>
                <div class="msgBoxFooter">
                    <asp:button id="btnXmitYes" runat="server" Text="Yes" CssClass="formBtn btnSmallTop"></asp:button>
                    &nbsp;
                    <asp:button id="btnXmitNo" runat="server" Text="No" CssClass="formBtn btnSmallTop"></asp:button>
                </div>
            </div>
            <!-- END TRANSMIT MESSAGE BOX -->
            <!-- BEGIN TRANSMIT MESSAGE BOX -->
            <div class="msgBoxSmall" id="msgBoxTransmit" style="DISPLAY: none">
                <h1><%= ProductName %></h1>
                <div class="msgBoxBody"><asp:label id="lblTransmit" runat="server"></asp:label></div>
                <div class="msgBoxFooter"><input class="formBtn btnSmallTop" onclick="window.location='disaster-recovery-list-browse.aspx'"
                        type="button" value="OK">
                </div>
            </div>
            <!-- END TRANSMIT MESSAGE BOX -->
            <!-- BEGIN DELETE MESSAGE BOX -->
            <div class="msgBox" id="msgBoxDelete" style="DISPLAY: none">
                <h1><%= ProductName %></h1>
                <div class="msgBoxBody">Are you sure you want to remove the selected media from 
                    this list?</div>
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
