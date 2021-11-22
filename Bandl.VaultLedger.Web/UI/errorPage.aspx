<%@ Page language="c#" Codebehind="errorPage.aspx.cs" AutoEventWireup="false" Inherits="Bandl.VaultLedger.Web.UI.errorPage" %>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<HTML>
  <HEAD>
        <META http-equiv="Content-Type" content="text/html; charset=windows-1252">
        <meta content="Microsoft Visual Studio .NET 7.1" name="GENERATOR">
        <meta content="C#" name="CODE_LANGUAGE">
        <meta content="JavaScript" name="vs_defaultClientScript">
        <meta content="http://schemas.microsoft.com/intellisense/ie5" name="vs_targetSchema">
        <!--#include file = "includes/baseHead.inc"-->
  </HEAD>
    <body>
        <!--#include file = "includes/baseBody.inc"-->
        <form id="Form1" method="post" runat="server">
            <div class="contentWrapper">
                <!-- page header -->
                <div class="pageHeader">
                    <h1><asp:Label id="lblTitle" runat="server">Application Error</asp:Label></h1>
                    <asp:Label id="lblCaption" runat="server">An application error has occurred.&nbsp;&nbsp;Information on this error has 
                    been sent to the support team.&nbsp;&nbsp;We apologize for any inconvenience.</asp:Label>
                </div><!-- end pageHeader //-->
                <div class="contentArea" id="contentBorderTop">
                    <div class="content">
                        <table class="detailTable">
                            <tr>
                                <td style="PADDING-BOTTOM: 12px; PADDING-TOP: 12px"><asp:label id="lblError" runat="server" ForeColor="Red">General error.  No information available.</asp:label></td>
                            </tr>
                        </table>
                    </div>
                        <div class="contentBoxBottom">
                            <asp:Button id="btnOK" runat="server" Text="OK" CssClass="formBtn btnSmall"></asp:Button>
                        </div>
                </div>
            </div>
        </form>
    </body>
</HTML>
