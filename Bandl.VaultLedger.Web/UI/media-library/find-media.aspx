<%@ Page language="c#" Codebehind="find-media.aspx.cs" AutoEventWireup="false" Inherits="Bandl.VaultLedger.Web.UI.find_media" %>
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
        <script src="../includes/tablescroller.js" type="text/javascript"></script>
        <form id="Form1" method="post" runat="server">
            <div class="contentWrapper">
                <div class="pageHeader">
                    <h1>Find Media</h1>
                    Specify one or more search criteria and click Search to see the 
                    results.&nbsp;&nbsp; When your search is completed, you may select individual 
                    media in order to edit their specifications or delete them from the system.
                </div>
                <asp:placeholder id="PlaceHolder1" EnableViewState="False" runat="server"></asp:placeholder>
                <div class="topContentArea" id="contentBorderTop" runat="server">
                    <br>
                    <div class="introHeader">Please enter your search criteria below:</div>
                    <br>
                    <!-- CRITERIA ENTRY TABLE //-->
                    <table style="WIDTH:100%">
                        <tr style="HEIGHT:23px" valign="middle">
                            <td width="120">Starting Serial Number:</td>
                            <td width="270"><asp:textbox id="txtStartSerialNum" tabIndex="1" runat="server" CssClass="large"></asp:textbox></td>
                            <td width="93">Account:</td>
                            <td width="250">
                                <asp:dropdownlist id="ddlAccount" tabIndex="7" runat="server" CssClass="large">
                                    <asp:ListItem Value="-Select Account-" Selected="True">-Select Account-</asp:ListItem>
                                </asp:dropdownlist>
                            </td>
                        </tr>
                        <tr style="HEIGHT:23px" valign="middle">
                            <td>Ending Serial Number:</td>
                            <td><asp:textbox id="txtEndSerialNum" tabIndex="2" runat="server" CssClass="large"></asp:textbox></td>
                            <td>Location:</td>
                            <td>
                                <asp:dropdownlist id="ddlLocation" tabIndex="8" runat="server" CssClass="large">
                                    <asp:ListItem Value="-Select Location-" Selected="True">-Select Location-</asp:ListItem>
                                    <asp:ListItem Value="0">Vault</asp:ListItem>
                                    <asp:ListItem Value="1">Enterprise</asp:ListItem>
                                </asp:dropdownlist>
                            </td>
                        </tr>
                        <tr style="HEIGHT:23px" valign="middle">
                            <td>Return Date:</td>
                            <td>
                                <table cellSpacing="0" cellPadding="0" width="270" border="0">
                                    <tr>
                                        <td width="217">
                                            <asp:textbox id="txtReturnDate" tabIndex="3" runat="server" CssClass="calendar"></asp:textbox>
                                        </td>
                                        <td width="53" class="calendarCell">
                                            <a href="javascript:openCalendar('txtReturnDate');" class="iconLink calendarLink"></a>
                                        </td>
                                    </tr>
                                </table>
                            </td>
                            <td>Case Number:</td>
                            <td>
                                <asp:textbox id="txtCaseNum" tabIndex="9" runat="server" CssClass="large"></asp:textbox>
                            </td>
                        </tr>
                        <tr style="HEIGHT:23px" valign="middle">
                            <td>Status:</td>
                            <td>
                                <table>
                                    <tr>
                                        <td style="WIDTH:10px">Missing</td>
                                        <td style="WIDTH:50px"><asp:CheckBox ID="chkMissing" Runat="server" style="MARGIN-LEFT:4px" TabIndex="4"></asp:CheckBox></td>
                                        <td style="WIDTH:10px">Destroyed</td>
                                        <td><asp:CheckBox ID="chkDestroyed" Runat="server" style="MARGIN-LEFT:4px" TabIndex="5"></asp:CheckBox></td>
                                    </tr>
                                </table>
                            </td>
                            <td>Media Type:</td>
                            <td>
                                <asp:dropdownlist id="ddlMediaType" tabIndex="10" runat="server" CssClass="large">
                                    <asp:ListItem Value="-Select Medium Type-" Selected="True">-Select Medium Type-</asp:ListItem>
                                </asp:dropdownlist>
                            </td>
                        </tr>
                        <tr style="HEIGHT:23px" valign="middle">
                            <td>DR Code:</td>
                            <td><asp:textbox id="txtDisaster" tabIndex="6" runat="server" MaxLength="3" Width="50"></asp:textbox></td>
                            <td>Notes:</td>
                            <td><asp:textbox id="txtNote" tabIndex="11" runat="server" CssClass="large"></asp:textbox></td>
                        </tr>
                    </table>
                    <br>
                    <!-- SEARCH BUTTON //-->
                    <div class="textRight">
                        <input type="button" id="btnSearch" tabIndex="12" runat="server" class="formBtn btnMedium"
                            value="Search">
                    </div>
                </div>
                <!-- RESULTS AREA //-->
                <a name="#resultArea"></a><!-- Anchor //-->
                <div class="contentArea" id="divResultArea" runat="server">
                    <h2 class="contentBoxHeader">Search Results&nbsp;&nbsp;&nbsp;<asp:Label id="numItems" runat="server"></asp:Label></h2>
                    <div class="contentBoxTop">
                        <div id="divAction" runat="server">
                            <asp:linkbutton CssClass="floatRight iconLink" runat="server" id="printLink">Print</asp:linkbutton>
                            <asp:linkbutton CssClass="floatRight iconLink" runat="server" id="exportLink" style="PADDING-RIGHT:10px">Export</asp:linkbutton>
                            <asp:linkbutton CssClass="floatRight iconLink" runat="server" id="arrow" style="PADDING-RIGHT:10px">Notes</asp:linkbutton>
                            <asp:linkbutton CssClass="floatRight iconLink" runat="server" id="arrowRight" style="PADDING-RIGHT:10px"
                                visible="false">Notes</asp:linkbutton>
                            <asp:dropdownlist id="ddlSelectAction" runat="server" Width="120px" tabIndex="11">
                                <asp:ListItem Value="-Choose an Action-">-Choose an Action-</asp:ListItem>
                                <asp:ListItem Value="edit">Edit Selected</asp:ListItem>
                                <asp:ListItem Value="delete">Delete Selected</asp:ListItem>
                                <asp:ListItem Value="destroy">Destroy Selected</asp:ListItem>
                            </asp:dropdownlist>
                            &nbsp;&nbsp;
                            <asp:button id="btnGo" runat="server" CssClass="formBtn btnSmallGo" Text="Go" tabIndex="12"></asp:button>
                        </div>
                        <asp:placeholder id="PlaceHolder2" EnableViewState="False" runat="server"></asp:placeholder>
                    </div>
                    <div class="content" id="GridWrapper1" style="OVERFLOW:hidden">
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
                                <asp:BoundColumn DataField="SerialNo" HeaderText="Serial No.">
                                    <HeaderStyle Font-Bold="True"></HeaderStyle>
                                </asp:BoundColumn>
                                <asp:TemplateColumn HeaderText="Serial No.">
                                    <HeaderStyle Font-Bold="True"></HeaderStyle>
                                    <ItemTemplate>
                                        <asp:LinkButton id="serialLink" runat="server">
                                            <%# DataBinder.Eval(Container.DataItem, "SerialNo") %>
                                        </asp:LinkButton>
                                    </ItemTemplate>
                                </asp:TemplateColumn>
                                <asp:BoundColumn DataField="Location" HeaderText="Location">
                                    <HeaderStyle Font-Bold="True"></HeaderStyle>
                                </asp:BoundColumn>
                                <asp:TemplateColumn HeaderText="Return Date">
                                    <HeaderStyle Font-Bold="True"></HeaderStyle>
                                    <ItemTemplate>
                                        <%# DisplayDate((string)DataBinder.Eval(Container.DataItem, "ReturnDate"), false, false) %>
                                    </ItemTemplate>
                                </asp:TemplateColumn>
                                <asp:TemplateColumn HeaderText="Missing">
                                    <HeaderStyle Font-Bold="True"></HeaderStyle>
                                    <ItemTemplate>
                                        <%# Convert.ToBoolean(DataBinder.Eval(Container.DataItem, "Missing")) ? "Yes" : "No" %>
                                    </ItemTemplate>
                                </asp:TemplateColumn>
                                <asp:TemplateColumn HeaderText="Destroyed">
                                    <HeaderStyle Font-Bold="True"></HeaderStyle>
                                    <ItemTemplate>
                                        <%# Convert.ToBoolean(DataBinder.Eval(Container.DataItem, "Destroyed")) ? "Yes" : "No" %>
                                    </ItemTemplate>
                                </asp:TemplateColumn>
                                <asp:BoundColumn DataField="Account" HeaderText="Account">
                                    <HeaderStyle Font-Bold="True"></HeaderStyle>
                                </asp:BoundColumn>
                                <asp:BoundColumn DataField="CaseName" HeaderText="Case Number">
                                    <HeaderStyle Font-Bold="True"></HeaderStyle>
                                </asp:BoundColumn>
                                <asp:BoundColumn DataField="MediumType" HeaderText="Media Type">
                                    <HeaderStyle Font-Bold="True"></HeaderStyle>
                                </asp:BoundColumn>
                                <asp:BoundColumn DataField="Disaster" HeaderText="DR Code">
                                    <HeaderStyle Font-Bold="True"></HeaderStyle>
                                </asp:BoundColumn>
                                <asp:BoundColumn DataField="Notes" HeaderText="Notes">
                                    <HeaderStyle Font-Bold="True"></HeaderStyle>
                                </asp:BoundColumn>
                            </Columns>
                        </asp:datagrid>
                    </div>
                    <!-- PAGE LINKS //-->
                    <div id="divPageLinks" runat="server">
                        <br>
                        <table class="detailTable">
                            <tr>
                                <td align="left">
                                    <asp:linkbutton id="lnkPageFirst" runat="server" Text="[First Page]" OnCommand="LinkButton_Command"
                                        CommandName="pageFirst" tabIndex="14">[<<]</asp:linkbutton>
                                    &nbsp;
                                    <asp:linkbutton id="lnkPagePrev" runat="server" Text="[Previous Page]" OnCommand="LinkButton_Command"
                                        CommandName="pagePrev" tabIndex="15">[<]</asp:linkbutton>
                                    &nbsp;
                                    <asp:textbox id="txtPageGoto" runat="server" Width="40px" tabIndex="16"></asp:textbox>
                                    &nbsp;
                                    <asp:linkbutton id="lnkPageNext" runat="server" Text="[Next Page]" OnCommand="LinkButton_Command"
                                        CommandName="pageNext" tabIndex="17">[>]</asp:linkbutton>
                                    &nbsp;
                                    <asp:linkbutton id="lnkPageLast" runat="server" Text="[Last Page]" OnCommand="LinkButton_Command"
                                        CommandName="pageLast" tabIndex="18">[>>]</asp:linkbutton>
                                </td>
                                <td style="PADDING-RIGHT:10px;TEXT-ALIGN:right">
                                    <asp:label id="lblPage" runat="server" Font-Bold="True"></asp:label>
                                </td>
                            </tr>
                        </table>
                    </div>
                </div>
                <!-- BEGIN DELETE MESSAGE BOX -->
                <div class="msgBox" id="msgBoxDelete" style="DISPLAY:none">
                    <h1><%= ProductName %></h1>
                    <div class="msgBoxBody">
                        Deleting a medium permanently removes it from the database.
                        <br>
                        <br>
                        Are you sure you want to delete the selected media?
                    </div>
                    <div class="msgBoxFooter">
                        <asp:button id="btnYes" runat="server" CssClass="formBtn btnSmallTop" Text="Yes"></asp:button>
                        &nbsp; <input type="button" class="formBtn btnSmallTop" value="No" onclick="hideMsgBox('msgBoxDelete')">
                    </div>
                </div>
                <!-- END DELETE MESSAGE BOX -->
                <!-- BEGIN DELETE MESSAGE BOX -->
                <div class="msgBox" id="msgBoxDestroy" style="DISPLAY:none">
                    <h1><%= ProductName %></h1>
                    <div class="msgBoxBody">
                        Are you sure you want to mark the selected media as destroyed?
                    </div>
                    <div class="msgBoxFooter">
                        <asp:button id="btnDestroy" runat="server" CssClass="formBtn btnSmallTop" Text="Yes"></asp:button>
                        &nbsp; <input type="button" class="formBtn btnSmallTop" value="No" onclick="hideMsgBox('msgBoxDestroy')">
                    </div>
                </div>
                <!-- END DELETE MESSAGE BOX -->
            </div>
        </form>
        <script type="text/javascript">
        new TableScroller().doScroll('GridWrapper1');    
        </script>
    </body>
</HTML>
