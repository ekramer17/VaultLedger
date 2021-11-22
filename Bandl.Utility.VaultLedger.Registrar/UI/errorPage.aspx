<%@ Page language="c#" Codebehind="errorPage.aspx.cs" AutoEventWireup="false" Inherits="Bandl.Utility.VaultLedger.Registrar.UI.errorPage" %>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<HTML>
    <HEAD>
        <meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
        <meta content="http://schemas.microsoft.com/intellisense/ie5" name="vs_targetSchema">
		<!--#include file = "masterHead.inc"-->
    </HEAD>
    <body>
        <!--#include file = "masterBody.inc"-->
        <DIV class="contentWrapper">
            <DIV class="pageHeader">
                <H1>Registration Error!</H1>
                The application creation process encountered an error as described below. To 
                try creating the application again, click Retry.
            </DIV>
            <FORM id="Form1" runat="server">
                <DIV id="contentBorderTop"></DIV>
                <DIV class="contentArea">
                    <TABLE class="detailTable">
                        <tr>
                            <td style="PADDING-BOTTOM: 12px; PADDING-TOP: 12px"><asp:label id="lblError" runat="server" ForeColor="Red"></asp:label></td>
                        </tr>
                    </TABLE>
                </DIV>
                <DIV style="MARGIN-TOP: 10px" align="right">
                    <asp:button id="btnRetry" runat="server" Text="Retry" CssClass="mediumButton" />
                </DIV>
            </FORM>
        </DIV>
    </body>
</HTML>
