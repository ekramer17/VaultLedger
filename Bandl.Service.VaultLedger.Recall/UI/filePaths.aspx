<%@ Page language="c#" Codebehind="filePaths.aspx.cs" AutoEventWireup="false" Inherits="Bandl.Service.VaultLedger.Recall.UI.filePaths" %>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<HTML>
    <HEAD>
        <meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
        <meta content="http://schemas.microsoft.com/intellisense/ie5" name="vs_targetSchema">
        <LINK href="mainStyle.css" type="text/css" rel="stylesheet">
    </HEAD>
    <BODY>
        <!--#include file = "masterPage.inc"-->
        <div class="contentWrapper">
            <DIV class="pageHeader">
                <H1>Account File Transfer Paths</H1>
                Review the file transfer path of each global account currently using ReQuest Media Manager.  To edit a path, click the Edit link on the row of the path you would like to edit.  Then enter the desired path and click the Update link.
            </DIV>
            <asp:placeholder id="PlaceHolder1" runat="server" EnableViewState="False"></asp:placeholder>            
            <form id="Form1" runat="server">
                <div id="contentBorderTop"></div>
                <div class="contentArea">
                    <asp:datagrid id="DataGrid1" runat="server" CssClass="detailTable" AutoGenerateColumns="False">
                        <AlternatingItemStyle CssClass="alternate"></AlternatingItemStyle>
                        <HeaderStyle CssClass="header"></HeaderStyle>
                        <Columns>
                            <asp:BoundColumn DataField="Name" HeaderText="Account Number" ReadOnly="True">
                                <HeaderStyle Font-Bold="True" Wrap="False"></HeaderStyle>
                            </asp:BoundColumn>
                            <asp:BoundColumn DataField="FilePath" HeaderText="File Transfer Path">
                                <HeaderStyle Font-Bold="True" Wrap="False"></HeaderStyle>
                            </asp:BoundColumn>
                            <asp:EditCommandColumn EditText="Edit" CancelText="Cancel" UpdateText="Update" HeaderText="Edit Path">
                                <HeaderStyle Font-Bold="True" Wrap="False"></HeaderStyle>
                            </asp:EditCommandColumn>
                        </Columns>
                    </asp:datagrid>
                </div>
            </form>
        </div>
    </BODY>
</HTML>