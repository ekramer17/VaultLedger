<%@ Page language="c#" Codebehind="mailTest.aspx.cs" AutoEventWireup="false" Inherits="Bandl.Utility.VaultLedger.Registrar.UI.mailTest" %>
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
                <H1>E-Mail Test</H1>
                Enter the recipient address and message body below. When finished, click Send 
                to attempt to send an email.
            </DIV>
            <FORM id="Form1" runat="server">
                <asp:placeholder id="msgHolder" runat="server"></asp:placeholder>
                <div id="contentBorderTop"></div>
                <DIV class="contentArea">
                    <TABLE class="detailTable">
                        <TR>
                            <TD style="PADDING-TOP: 12px" width="100" height="27"><strong>To:</strong></TD>
                            <TD style="PADDING-TOP: 12px"><asp:TextBox id="txtTo" Width="250px" runat="server" MaxLength="128"></asp:TextBox>
                                <asp:RequiredFieldValidator id="rfvTo" runat="server" ControlToValidate="txtTo" ErrorMessage="&amp;nbsp;Entry Required"></asp:RequiredFieldValidator></TD>
                        </TR>
                        <TR valign="top">
                            <TD style="PADDING-BOTTOM: 12px" height="125"><strong>Body:</strong></TD>
                            <TD style="PADDING-BOTTOM: 12px" width="1000">
                                <asp:TextBox id="txtBody" Width="352px" runat="server" Height="112px" TextMode="MultiLine"></asp:TextBox>
                            </TD>
                        </TR>
                    </TABLE>
                </DIV>
                <DIV style="MARGIN-TOP: 10px" align="right">
                    <asp:button id="btnSend" runat="server" Text="Go" CssClass="mediumButton" />
                </DIV>
            </FORM>
        </DIV>
        </HMTL>
    </body>
</HTML>
