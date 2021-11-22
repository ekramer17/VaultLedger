<%@ Page CodeBehind="reconcile-inventory.aspx.cs" Language="c#" AutoEventWireup="false" Inherits="Bandl.VaultLedger.Web.UI.reconcile_inventory" %>
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
        <script src="../includes/tablechecker.js" type="text/javascript"></script>
        <form id="Form1" method="post" runat="server">
            <div class="contentWrapper">
                <div class="pageHeader">
                    <h1>Reconcile Inventory</h1>
                    <asp:label id="pageCaption" runat="server">To compare your inventory with
                    that of the vault, click Compare to Recall.&nbsp;&nbsp;Any
                    discrepancies resulting from the comparison will be listed
                    below.&nbsp;&nbsp;You
                    may resolve discrepancies now by selecting discrepancies, choosing the desired
                    action, and clicking Go.&nbsp;&nbsp; Alternatively, you may choose to return to
                    this page and resolve discrepancies at a later time.</asp:label>
                    <div id="headerConstants"><asp:linkbutton id="printLink" runat="server" CssClass="headerLink">Print</asp:linkbutton></div>
                </div> <!-- end pageHeader //--><asp:placeholder id="PlaceHolder1" runat="server" EnableViewState="False"></asp:placeholder>
                <div class="contentArea contentBorderTopNone">
                    <h2 class="contentBoxHeader">Inventory Discrepancies</h2>
                    <div class="contentBoxTop">
                        <asp:button id="btnUpload" style="MARGIN-LEFT: 10px" runat="server" CssClass="floatRight formBtn btnMediumPlus"
                            Text="Upload Local"></asp:button>
                        <input class="floatRight formBtn btnLargeTopPlus" id="btnCompare" onclick="showMsgBox('msgBoxAccounts')"
                            type="button" value="Compare to Recall" runat="server">
                        <asp:dropdownlist id="ddlSelectAction" runat="server" Width="136px">
                            <asp:ListItem Value="-Choose an Action-" Selected="True">-Choose an Action-</asp:ListItem>
                            <asp:ListItem Value="Ignore">Ignore Discrepancies</asp:ListItem>
                            <asp:ListItem Value="Missing">Mark Missing</asp:ListItem>
                            <asp:ListItem Value="Move">Change Location</asp:ListItem>
                            <asp:ListItem Value="Add">Add Media</asp:ListItem>
                            <asp:ListItem Value="AddCase">Add Empty Cases</asp:ListItem>
                        </asp:dropdownlist>
                        &nbsp; <input id="btnGo" type="button" tabindex="12" class="formBtn btnSmallGo" value="Go" onclick="doGo()">
                        <asp:HyperLink style="MARGIN-LEFT:120px" ID="FilterLink" NavigateUrl="javascript:doFilter()" Runat="server" Font-Bold="True"></asp:HyperLink>
                    </div>
                    <!-- end contentBoxTop //-->
                    <div class="content"><asp:datagrid id="DataGrid1" runat="server" CssClass="detailTable" AutoGenerateColumns="False">
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
                                <asp:BoundColumn DataField="SerialNo" HeaderText="Serial">
                                    <HeaderStyle Font-Bold="True" Width="80px"></HeaderStyle>
                                </asp:BoundColumn>
                                <asp:TemplateColumn HeaderText="Discrepancy Type" Visible="False">
                                    <ItemTemplate>
                                        <%# Convert.ToInt32(DataBinder.Eval(Container.DataItem, "ConflictType")) %>
                                    </ItemTemplate>
                                </asp:TemplateColumn>
                                <asp:BoundColumn DataField="AccountName" HeaderText="Account">
                                    <HeaderStyle Font-Bold="True" Width="100px"></HeaderStyle>
                                </asp:BoundColumn>
                                <asp:TemplateColumn HeaderText="Recorded Date">
                                    <HeaderStyle Font-Bold="True" Width="140px"></HeaderStyle>
                                    <ItemTemplate>
                                        <%# DisplayDate(DataBinder.Eval(Container.DataItem, "RecordedDate")) %>
                                    </ItemTemplate>
                                </asp:TemplateColumn>
                                <asp:BoundColumn DataField="Details" HeaderText="Details">
                                    <HeaderStyle Font-Bold="True"></HeaderStyle>
                                </asp:BoundColumn>
                            </Columns>
                        </asp:datagrid>
                        <!-- PAGE LINKS //--><br>
                        <table class="detailTable">
                            <tr>
                                <td align="left"><asp:linkbutton id="lnkPageFirst" tabIndex="14" runat="server" Text="[First Page]" OnCommand="LinkButton_Command"
                                        CommandName="pageFirst">[<<]</asp:linkbutton>&nbsp;
                                    <asp:linkbutton id="lnkPagePrev" tabIndex="15" runat="server" Text="[Previous Page]" OnCommand="LinkButton_Command"
                                        CommandName="pagePrev">[<]</asp:linkbutton>&nbsp;
                                    <asp:textbox id="txtPageGoto" tabIndex="16" runat="server" Width="40px"></asp:textbox>&nbsp;
                                    <asp:linkbutton id="lnkPageNext" tabIndex="17" runat="server" Text="[Next Page]" OnCommand="LinkButton_Command"
                                        CommandName="pageNext">[>]</asp:linkbutton>&nbsp;
                                    <asp:linkbutton id="lnkPageLast" tabIndex="18" runat="server" Text="[Last Page]" OnCommand="LinkButton_Command"
                                        CommandName="pageLast">[>>]</asp:linkbutton></td>
                                <td style="PADDING-RIGHT: 10px; TEXT-ALIGN: right"><asp:label id="lblPage" runat="server" Font-Bold="True"></asp:label></td>
                            </tr>
                        </table> <!-- end divPageLinks --></div> <!-- end content //--></div> <!-- end contentArea //--></div> <!-- end contentWrapper //-->
            <!-- BEGIN MISSING MESSAGE BOX -->
            <div class="msgBox" id="msgBoxMissing" style="DISPLAY: none">
                <h1><%= ProductName %></h1>
                <div class="msgBoxBody">At least one of the media checked resides in a sealed case.<br>
                    <br>
                    You may either designate only this medium as missing (it will be removed from 
                    its case), or you may designate all media in the case as missing.<br>
                    <br>
                    Which would you prefer?
                </div>
                <div class="msgBoxFooter"><asp:button id="btnSolo" runat="server" CssClass="formBtn btnMediumTop" Text="Single"></asp:button>&nbsp;
                    <asp:button id="btnCase" runat="server" CssClass="formBtn btnMediumTop" Text="All Media"></asp:button>&nbsp;
                    <asp:button id="btnCancel" runat="server" CssClass="formBtn btnMediumTop" Text="Cancel"></asp:button></div>
            </div>
            <!-- END MISSING MESSAGE BOX -->
            <!-- BEGIN NO DISCREPANCIES MESSAGE BOX -->
            <div class="msgBoxSmall" id="msgBoxNone" style="DISPLAY: none">
                <h1><%= ProductName %></h1>
                <div class="msgBoxBody">There are currently no inventory discrepancies.</div>
                <div class="msgBoxFooter"><input class="formBtn btnMediumTop" id="btnNone" onclick="location.href='reconcile-inventory.aspx'"
                        type="button" value="OK"></div>
            </div>
            <!-- END NO DISCREPANCIES MESSAGE BOX -->
            <!-- BEGIN MESSAGE BOX -->
            <div class="messagebox" id="msgBoxAccounts" style="DISPLAY: none; WIDTH: 400px">
                <div class="messagebox_header"><%= ProductName %></div>
                <div class="messagebox_body">Select the accounts for which you would like to 
                    reconcile inventory
                    <br>
                    <br>
                    <br>
                    <asp:datagrid id="GridView1" style="MARGIN: 0px auto" runat="server" CssClass="detailTable" EnableViewState="True"
                        Width="370" AutoGenerateColumns="False">
                        <AlternatingItemStyle CssClass="alternate"></AlternatingItemStyle>
                        <HeaderStyle CssClass="header"></HeaderStyle>
                        <Columns>
                            <asp:TemplateColumn>
                                <HeaderStyle CssClass="checkbox"></HeaderStyle>
                                <ItemStyle CssClass="checkbox"></ItemStyle>
                                <HeaderTemplate>
                                    <input type="checkbox" id="HeaderBox" runat="server" onclick="x1.click(this)" NAME="HeaderBox" />
                                </HeaderTemplate>
                                <ItemTemplate>
                                    <input type="checkbox" id="ItemBox" runat="server" onclick="x1.click(this)" NAME="ItemBox" />
                                </ItemTemplate>
                            </asp:TemplateColumn>
                            <asp:BoundColumn DataField="Id" HeaderStyle-CssClass="invisible" ItemStyle-CssClass="invisible" />
                            <asp:BoundColumn DataField="Name" HeaderText="Account Name">
                                <HeaderStyle Font-Bold="True" Wrap="False"></HeaderStyle>
                            </asp:BoundColumn>
                        </Columns>
                    </asp:datagrid></div>
                <div class="messagebox_footer"><asp:button id="btnAccountOK" runat="server" CssClass="formBtn btnMediumTop" Text="OK"></asp:button>&nbsp;
                    <asp:button id="btnAccountCancel" runat="server" CssClass="formBtn btnMediumTop" Text="Cancel"></asp:button></div>
            </div>
            <!-- END MESSAGE BOX -->
            <!-- BEGIN MESSAGE BOX -->
            <div class="messagebox" id="msgBoxFilter1" style="DISPLAY:none;WIDTH:400px">
                <div class="messagebox_header"><%= ProductName %></div>
                <div class="messagebox_body">
                    Select the accounts for which you would like to view conflicts
                    <br>
                    <br>
                    <br>
                    <asp:DataGrid id="GridView2" runat="server" CssClass="detailTable" EnableViewState="True" AutoGenerateColumns="False"
                        style="MARGIN:0px auto" Width="370">
                        <AlternatingItemStyle CssClass="alternate"></AlternatingItemStyle>
                        <HeaderStyle CssClass="header"></HeaderStyle>
                        <Columns>
                            <asp:TemplateColumn>
                                <HeaderStyle CssClass="checkbox"></HeaderStyle>
                                <ItemStyle CssClass="checkbox"></ItemStyle>
                                <HeaderTemplate>
                                    <input type="checkbox" id="GridView2_HeaderBox" runat="server" onclick="x2.click(this)"
                                        NAME="HeaderBox" />
                                </HeaderTemplate>
                                <ItemTemplate>
                                    <input type="checkbox" id="GridView2_ItemBox" runat="server" onclick="x2.click(this)" NAME="ItemBox" />
                                </ItemTemplate>
                            </asp:TemplateColumn>
                            <asp:BoundColumn DataField="Id" HeaderStyle-CssClass="invisible" ItemStyle-CssClass="invisible" />
                            <asp:BoundColumn DataField="Name" HeaderText="Account Name">
                                <HeaderStyle Font-Bold="True" Wrap="False"></HeaderStyle>
                            </asp:BoundColumn>
                        </Columns>
                    </asp:DataGrid>
                </div>
                <div class="messagebox_footer">
                    <input type="button" value="Next" class="formBtn btnMediumTop" onclick="doFilter1()">
                    &nbsp; <input type="button" value="Cancel" class="formBtn btnMediumTop" onclick="hideMsgBox('msgBoxFilter1')">
                </div>
            </div>
            <!-- END MESSAGE BOX -->
            <!-- BEGIN MESSAGE BOX -->
            <div class="messagebox" id="msgBoxFilter2" style="DISPLAY:none;WIDTH:400px">
                <div class="messagebox_header"><%= ProductName %></div>
                <div class="messagebox_body">
                    Select the types of conflicts you would like to view
                    <br>
                    <br>
                    <br>
                    <asp:DataGrid id="GridView3" runat="server" CssClass="detailTable" EnableViewState="True" AutoGenerateColumns="False"
                        style="MARGIN:0px auto" Width="370">
                        <AlternatingItemStyle CssClass="alternate"></AlternatingItemStyle>
                        <HeaderStyle CssClass="header"></HeaderStyle>
                        <Columns>
                            <asp:TemplateColumn>
                                <HeaderStyle CssClass="checkbox"></HeaderStyle>
                                <ItemStyle CssClass="checkbox"></ItemStyle>
                                <HeaderTemplate>
                                    <input type="checkbox" id="GridView3_HeaderBox" runat="server" onclick="x3.click(this)"
                                        NAME="HeaderBox" />
                                </HeaderTemplate>
                                <ItemTemplate>
                                    <input type="checkbox" id="GridView3_ItemBox" runat="server" onclick="x3.click(this)" NAME="ItemBox" />
                                </ItemTemplate>
                            </asp:TemplateColumn>
                            <asp:BoundColumn DataField="Id" HeaderStyle-CssClass="invisible" ItemStyle-CssClass="invisible" />
                            <asp:BoundColumn DataField="Type" HeaderText="Conflict Type">
                                <HeaderStyle Font-Bold="True" Wrap="False"></HeaderStyle>
                            </asp:BoundColumn>
                        </Columns>
                    </asp:DataGrid>
                </div>
                <div class="messagebox_footer">
                    <input type="button" value="OK" class="formBtn btnMediumTop" onclick="doFilter2()">
                    &nbsp; <input type="button" value="Cancel" class="formBtn btnMediumTop" onclick="hideMsgBox('msgBoxFilter2')">
                </div>
            </div>
            <!-- END MESSAGE BOX -->
        </form>
        <script type="text/javascript">
        var x1 = new TableChecker(1).initialize('GridView1');
        var x2 = new TableChecker(1).initialize('GridView2');
        var x3 = new TableChecker(1).initialize('GridView3');
        
        function doFilter()
        {
            if (document.getElementById('GridView2').rows.length > 2)
            {
                showMsgBox('msgBoxFilter1');
            }
            else
            {
                showMsgBox('msgBoxFilter2');
            }
        }
        
        function doFilter1()
        {
            if (x2.checked().length != 0)
            {
                hideMsgBox('msgBoxFilter1');
                showMsgBox('msgBoxFilter2');
            }
        }
        
        function doFilter2()
        {
            if (x3.checked().length != 0)
            {
                hideMsgBox('msgBoxFilter2');
                __doPostBack('DoFilter');
            }
        }
        
        function doGo()
        {
            if (document.getElementById('ddlSelectAction').selectedIndex != 0)
            {
                __doPostBack('btnGo');
            }
        }
        </script>
    </body>
</HTML>
