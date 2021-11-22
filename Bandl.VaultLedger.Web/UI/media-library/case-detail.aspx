<%@ Page language="c#" Codebehind="case-detail.aspx.cs" AutoEventWireup="false" Inherits="Bandl.VaultLedger.Web.UI.case_detail" %>
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
                    <h1>Case Detail&nbsp;&nbsp;-&nbsp;&nbsp;<asp:label id="lblCaption" runat="server"></asp:label></h1>
                    View the media currently residing in the specified case.
                </div> <!-- end pageHeader //-->
                <asp:placeholder id="PlaceHolder1" runat="server" EnableViewState="False"></asp:placeholder>
                <div class="contentArea" id="contentBorderTop">
                    <div class="content">
                        <asp:datagrid id="DataGrid1" runat="server" CssClass="detailTable" AutoGenerateColumns="False">
                            <AlternatingItemStyle CssClass="alternate"></AlternatingItemStyle>
                            <HeaderStyle CssClass="header"></HeaderStyle>
                            <Columns>
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
                                    <HeaderStyle Font-Bold="True" Width="55px"></HeaderStyle>
                                    <ItemTemplate>
                                        <%# Convert.ToBoolean(DataBinder.Eval(Container.DataItem, "Missing")) ? "Yes" : "No" %>
                                    </ItemTemplate>
                                </asp:TemplateColumn>
                                <asp:BoundColumn DataField="Account" HeaderText="Account">
                                    <HeaderStyle Font-Bold="True"></HeaderStyle>
                                </asp:BoundColumn>
                                <asp:BoundColumn DataField="MediumType" HeaderText="Media Type">
                                    <HeaderStyle Font-Bold="True"></HeaderStyle>
                                </asp:BoundColumn>
                            </Columns>
                        </asp:datagrid>
                    </div> <!-- end content //-->
                </div> <!-- end contentArea //-->
            </div> <!-- end contentWrapper //-->
        </form>
    </body>
</HTML>
