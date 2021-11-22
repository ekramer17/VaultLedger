<%@ Page language="c#" Codebehind="compare-file-view.aspx.cs" AutoEventWireup="false" Inherits="Bandl.VaultLedger.Web.UI.compare_file_view" %>
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
                    Review the contents of the compare file
                    <br>
                    <div id="headerConstants">
                        <asp:linkbutton id="listLink" runat="server" style="LEFT:627px" CssClass="headerLink">Compare File</asp:linkbutton>
                    </div>
                </div>
                <div class="contentArea" id="contentBorderTop">
                    <div class="content">
                        <asp:table id="Table1" runat="server" CssClass="detailTable2" BorderWidth="1px" EnableViewState="True"></asp:table>
                    </div>
                </div>
            </div>
        </form>
    </body>
</HTML>
