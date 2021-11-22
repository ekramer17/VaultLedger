<%@ Page language="c#" Codebehind="shipping-list-detail-edit-case.aspx.cs" AutoEventWireup="false" Inherits="Bandl.VaultLedger.Web.UI.shipping_list_detail_edit_case" %>
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
                    <h1><asp:label id="lblCaption" runat="server"></asp:label></h1>
                    <asp:label id="lblDesc" runat="server"></asp:label>
                </div> <!-- end pageHeader //-->
                <asp:placeholder id="PlaceHolder1" runat="server" EnableViewState="False"></asp:placeholder>
                <div class="contentArea" id="titleBar1" runat="server">
                    <h2 class="contentBoxHeader" id="titleBar2" runat="server">Step 2 of 2</h2>
                    <div class="contentBoxTop">
                        <asp:dropdownlist id="ddlSelectAction" runat="server" CssClass="selectAction" Width="140">
                            <asp:ListItem Value="-Choose an Action-" Selected="True">-Choose an Action-</asp:ListItem>
                            <asp:ListItem Value="Seal">Mark Sealed</asp:ListItem>
                            <asp:ListItem Value="Unseal">Mark Unsealed</asp:ListItem>
                            <asp:ListItem Value="ReturnDate">Edit Return Date</asp:ListItem>
                        </asp:dropdownlist>
                        &nbsp;&nbsp;
                        <asp:button id="btnGo" runat="server" Text="Go" CssClass="formBtn btnSmallGo"></asp:button>
                    </div>
                    <!-- end contentBoxTop //-->
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
                                            runat="server" />
                                    </HeaderTemplate>
                                    <ItemTemplate>
                                        <input id="cbItemChecked" onclick="checkFirst('DataGrid1', 'cbCheckAll', false)" type="checkbox"
                                            runat="server" />
                                    </ItemTemplate>
                                </asp:TemplateColumn>
                                <asp:BoundColumn DataField="Name" HeaderText="Case Number">
                                    <HeaderStyle Font-Bold="True"></HeaderStyle>
                                </asp:BoundColumn>
                                <asp:TemplateColumn HeaderText="Sealed">
                                    <HeaderStyle Font-Bold="True" Width="105px"></HeaderStyle>
                                    <ItemTemplate>
                                        <%# Convert.ToBoolean(DataBinder.Eval(Container.DataItem, "Sealed")) ? "Yes" : "No" %>
                                    </ItemTemplate>
                                </asp:TemplateColumn>
                                <asp:TemplateColumn HeaderText="Return Date">
                                    <HeaderStyle Font-Bold="True"></HeaderStyle>
                                    <ItemTemplate>
                                        <%# DisplayDate((string)DataBinder.Eval(Container.DataItem, "ReturnDate"), false, false) %>
                                    </ItemTemplate>
                                </asp:TemplateColumn>
                            </Columns>
                        </asp:datagrid>
                    </div> <!-- end content //-->
                    <!-- PAGE LINKS //-->
                    <div class="contentBoxBottom">
                        <asp:button id="btnSave" runat="server" Text="Save" CssClass="formBtn btnSmall"></asp:button>
                        &nbsp;
                        <asp:button id="btnCancel" runat="server" Text="Cancel" CssClass="formBtn btnSmall"></asp:button>
                    </div> <!-- end contentBoxBottom //-->
                </div>
                <!-- end contentArea //-->
            </div> <!-- end contentWrapper //-->
            <!-- BEGIN RETURN DATE BOX -->
            <div class="msgBox" id="msgBoxReturnDate" style="DISPLAY:none">
                <h1><%= ProductName %></h1>
                <div class="msgBoxBody">
                    Enter the return date to assign to the sealed cases:
                    <br>
                    <br>
                    <br>
                    <table width="210" cellSpacing="0" cellPadding="0" border="0" align="center">
                        <tr>
                            <td>
                                <asp:textbox id="txtReturnDate" runat="server" Width="162"></asp:textbox>
                            </td>
                            <td width="32" class="calendarCell">
                                <a href="javascript:openCalendar('txtReturnDate');" class="iconLink calendarLink" id="msgBoxLinkCalendar">
                                </a>
                            </td>
                        </tr>
                    </table>
                </div>
                <div class="msgBoxFooter">
                    <input class="formBtn btnSmallTop" id="btnOK" type="button" value="OK" runat="server">
                    &nbsp; <input class="formBtn btnSmallTop" id="btnCancel2" type="button" value="Cancel" runat="server">
                </div>
            </div>
            <!-- END RETURN DATE BOX -->
        </form>
        </script>
    </body>
</HTML>
