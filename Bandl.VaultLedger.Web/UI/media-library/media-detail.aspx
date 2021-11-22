<%@ Page language="c#" Codebehind="media-detail.aspx.cs" AutoEventWireup="false" Inherits="Bandl.VaultLedger.Web.UI.media_detail" %>
<!DOCTYPE html PUBLIC "-//W3C//Dtd XHTML 1.0 Transitional//EN" "http://www.w3.org/tr/xhtml1/Dtd/xhtml1-transitional.dtd">
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
                    <h1><asp:label id="lblPageHeader" runat="server">Medium Detail</asp:label></h1>
                    Review detailed medium information.
                    <asp:linkbutton CssClass="headerLink" id="arrow" style="LEFT:620px" runat="server">Find</asp:linkbutton>
                    &nbsp;
                    <asp:linkbutton id="printLink" runat="server" CssClass="headerLink">Print</asp:linkbutton>
                </div> <!-- end pageHeader //-->
                <asp:placeholder id="PlaceHolder1" runat="server" EnableViewState="False"></asp:placeholder>
                <div class="contentArea" id="contentBorderTop">
                    <div class="content" id="accountDetail">
                        <table class="accountDetailTable" cellSpacing="0" cellPadding="0" width="724" border="0">
                            <tr vAlign="top">
                                <td class="leftPad" width="100"><b>Serial Number:</b></td>
                                <td width="242"><asp:label id="lblSerialNo" runat="server"></asp:label></td>
                                <td width="33">&nbsp;</td>
                                <td width="100">&nbsp;</td>
                                <td width="242">&nbsp;</td>
                            </tr>
                            <tr vAlign="top">
                                <td class="leftPad"><b>Location:</b></td>
                                <td><asp:label id="lblLocation" runat="server"></asp:label></td>
                                <td>&nbsp;</td>
                                <td><b>Missing:</b></td>
                                <td><asp:label id="lblMissing" runat="server"></asp:label></td>
                            </tr>
                            <tr>
                            <tr>
                                <td class="tableRowSpacer" colSpan="5"></td>
                            </tr>
                            <tr vAlign="top">
                                <td class="leftPad"><b>Account:</b></td>
                                <td><asp:label id="lblAccount" runat="server"></asp:label></td>
                                <td>&nbsp;</td>
                                <td><b>Return Date:</b></td>
                                <td><asp:label id="lblReturnDate" runat="server"></asp:label></td>
                            </tr>
                            <tr vAlign="top">
                                <td class="leftPad"><b>Medium Type:</b></td>
                                <td><asp:label id="lblMediumType" runat="server"></asp:label></td>
                                <td>&nbsp;</td>
                                <td><b>Case Number:</b></td>
                                <td><asp:label id="lblCaseNo" runat="server"></asp:label></td>
                            </tr>
                            <TR>
                                <td class="tableRowSpacer" colSpan="5"></td>
                            </TR>
                            <tr vAlign="top">
                                <td class="leftPad"><b>Active List:</b></td>
                                <td><a id="listAnchor" runat="server"><asp:label id="lblListName" runat="server"></asp:label></a></td>
                                <td>&nbsp;</td>
                                <td><b>List Status:</b></td>
                                <td><asp:label id="lblListStatus" runat="server"></asp:label></td>
                            </tr>
                            <TR>
                                <td class="tableRowSpacer" colSpan="5"></td>
                            </TR>
                            <tr vAlign="top">
                                <td class="leftPad"><b>Notes:</b></td>
                                <td colSpan="4"><asp:label id="lblNotes" runat="server"></asp:label></td>
                            </tr>
                        </table>
                    </div> <!-- end content //-->
                </div> <!-- end contentArea //-->
                <br>
                <div class="contentArea" id="todaysList" runat="server">
                    <h2 class="contentBoxHeader" style="PADDING-LEFT: 10px; MARGIN-BOTTOM: 10px">Medium 
                        History</h2>
                    <asp:datagrid id="DataGrid1" runat="server" CssClass="detailTable" AutoGenerateColumns="False">
                        <AlternatingItemStyle CssClass="alternate"></AlternatingItemStyle>
                        <HeaderStyle CssClass="header" Font-Bold="True"></HeaderStyle>
                        <Columns>
                            <asp:TemplateColumn HeaderText="Record Date">
                                <HeaderStyle Width="110px"></HeaderStyle>
                                <ItemTemplate>
                                    <asp:Label BorderWidth=0 runat="server" id="lblDate" Text='<%# DisplayDate(DataBinder.Eval(Container.DataItem, "RecordDate"), true, true, false) %>'>
                                    </asp:Label>
                                </ItemTemplate>
                            </asp:TemplateColumn>
                            <asp:BoundColumn DataField="Login" HeaderText="Login">
                                <HeaderStyle Width="90px"></HeaderStyle>
                            </asp:BoundColumn>
                            <asp:BoundColumn DataField="Detail" HeaderText="Detail" ItemStyle-Wrap="True">
                                <HeaderStyle></HeaderStyle>
                            </asp:BoundColumn>
                        </Columns>
                    </asp:datagrid>
                </div>
            </div> <!-- end contentWrapper //-->
        </form>
    </body>
</HTML>
