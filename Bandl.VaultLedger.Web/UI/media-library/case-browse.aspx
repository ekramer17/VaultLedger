<%@ Page language="c#" Codebehind="case-browse.aspx.cs" AutoEventWireup="false" Inherits="Bandl.VaultLedger.Web.UI.case_browse" %>
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
                    <h1>Browse Cases</h1>
                    Browse all cases currently known to
                    <%=ProductName%>
                    , delete empty cases, and edit return dates as desired.
                </div> <!-- end pageHeader //-->
                <asp:placeholder id="PlaceHolder1" runat="server" EnableViewState="False"></asp:placeholder>
                <div class="contentArea" id="contentBorderTop">
                    <div class="contentBoxTop">
                        <asp:dropdownlist id="ddlSelectAction" runat="server" CssClass="selectAction" Width="140">
                            <asp:ListItem Value="-Choose an Action-" Selected="True">-Choose an Action-</asp:ListItem>
                            <asp:ListItem Value="Delete">Delete Selected</asp:ListItem>
                            <asp:ListItem Value="EditSerial">Edit Case Serial</asp:ListItem>
                            <asp:ListItem Value="EditReturn">Edit Return Date</asp:ListItem>
                        </asp:dropdownlist>
                        &nbsp;&nbsp;
                        <asp:button id="btnGo" runat="server" CssClass="formBtn btnSmallGo" Text="Go"></asp:button>
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
                                        <input id="cbItemChecked" onclick="checkFirst('DataGrid1', 'cbCheckAll', false)" type="checkbox" class="item-checkbox"
                                            runat="server" NAME="cbItemChecked" />
                                    </ItemTemplate>
                                </asp:TemplateColumn>
                                <asp:BoundColumn DataField="CaseName" HeaderText="Case Name">
                                    <HeaderStyle Font-Bold="True"></HeaderStyle>
                                </asp:BoundColumn>
                                <asp:TemplateColumn HeaderText="Case Name">
                                    <HeaderStyle Font-Bold="True"></HeaderStyle>
                                    <ItemTemplate>
                                        <asp:LinkButton id="caseLink" runat="server" CommandName="casePage" CommandArgument='<%# DataBinder.Eval(Container.DataItem, "CaseName") %>'>
                                            <%# DataBinder.Eval(Container.DataItem, "CaseName") %>
                                        </asp:LinkButton>
                                    </ItemTemplate>
                                </asp:TemplateColumn>
                                <asp:BoundColumn DataField="CaseType" HeaderText="Case Type">
                                    <HeaderStyle Font-Bold="True"></HeaderStyle>
                                </asp:BoundColumn>
                                <asp:BoundColumn DataField="NumTapes" HeaderText="Tapes">
                                    <HeaderStyle Font-Bold="True" Width="55px"></HeaderStyle>
                                </asp:BoundColumn>
                                <asp:BoundColumn DataField="Sealed" HeaderText="Sealed">
                                    <HeaderStyle Font-Bold="True" Width="55px"></HeaderStyle>
                                </asp:BoundColumn>
                                <asp:BoundColumn DataField="Location" HeaderText="Location">
                                    <HeaderStyle Font-Bold="True" Width="65px"></HeaderStyle>
                                </asp:BoundColumn>
                                <asp:TemplateColumn HeaderText="Return Date">
                                    <HeaderStyle Font-Bold="True"></HeaderStyle>
                                    <ItemTemplate>
                                        <%# DisplayDate((string)DataBinder.Eval(Container.DataItem, "ReturnDate"), false, false) %>
                                    </ItemTemplate>
                                </asp:TemplateColumn>
                                <asp:TemplateColumn HeaderText="Current List">
                                    <HeaderStyle Font-Bold="True"></HeaderStyle>
                                    <ItemTemplate>
                                        <asp:LinkButton id="listLink" runat="server" CommandName="listPage" CommandArgument='<%# DataBinder.Eval(Container.DataItem, "ListName") %>'>
                                            <%# DataBinder.Eval(Container.DataItem, "ListName") %>
                                        </asp:LinkButton>
                                    </ItemTemplate>
                                </asp:TemplateColumn>
                            </Columns>
                        </asp:datagrid>
                    </div> <!-- end content //-->
                </div> <!-- end contentArea //-->
            </div> <!-- end contentWrapper //-->
            <!-- BEGIN DELETE MESSAGE BOX -->
            <div class="msgBox" id="msgBoxDelete" style="DISPLAY: none">
                <h1><%= ProductName %></h1>
                <div class="msgBoxBody">Are you sure you want to remove the selected cases from the 
                    database?
                </div>
                <div class="msgBoxFooter">
                    <asp:button id="btnYes" runat="server" CssClass="formBtn btnSmallTop" Text="Yes"></asp:button>
                    &nbsp; <input type="button" id="btnNo" class="formBtn btnSmallTop" value="No" onclick="hideMsgBox('msgBoxDelete');">
                </div>
            </div>
            <!-- END DELETE MESSAGE BOX -->
            <!-- BEGIN RETURN DATE BOX -->
            <div class="msgBox" id="msgBoxReturnDate" style="DISPLAY:none">
                <h1><%= ProductName %></h1>
                <div class="msgBoxBody">
                    Enter the return date to assign to the selected cases:
                    <br>
                    <br>
                    <br>
                    <table width="210" cellSpacing="0" cellPadding="0" border="0" align="center">
                        <tr>
                            <td>
                                <asp:textbox id="txtReturnDate" runat="server" Width="162"></asp:textbox>
                            </td>
                            <td width="32" class="calendarCell">
                                <a href="javascript:openCalendar('txtReturnDate');" class="iconLink calendarLink" id="calendar">
                                </a>
                            </td>
                        </tr>
                    </table>
                </div>
                <div class="msgBoxFooter">
                    <input class="formBtn btnSmallTop" id="btnOK" type="button" value="OK" runat="server">
                    &nbsp; <input class="formBtn btnSmallTop" id="btnCancel" type="button" value="Cancel" onclick="hideMsgBox('msgBoxReturnDate');">
                </div>
            </div>
            <!-- END RETURN DATE BOX -->
            <!-- BEGIN SERIAL CASE BOX -->
            <div class="msgBox" id="msgBoxSerial" style="display:none">
	            <h1><%= ProductName %></h1>
	            <div class="msgBoxBody">Enter the new case serial number below
		            <br>
		            <br>
		            <div align="center">
			            <asp:textbox id="txtNewSerial" runat="server" Width="162"></asp:textbox>
		            </div>
	            </div>
	            <div class="msgBoxFooter">
		            <asp:button class="formBtn btnSmallTop" id="btnSerialOK" type="button" name="btnSerialOK" runat="server" Text="OK"></asp:button>
		            &nbsp;
		            <input class="formBtn btnMediumTop" id="serialCancel" onclick="hideMsgBox('msgBoxSerial');" type="button" value="Cancel">
	            </div>
            </div>
            <!-- END SERIAL CASE BOX -->
        </form>
        <script type="text/javascript" src="https://code.jquery.com/jquery-3.1.1.slim.min.js"></script>
        <script type="text/javascript">
            $(document).ready(function ()
            {
                $('.btnSmallGo').on('click', function ()
                {
                    checkboxes = $('.item-checkbox:checked');
                    if (checkboxes.length == 0) return false;
                });
            })
        </script>
    </body>
</HTML>
