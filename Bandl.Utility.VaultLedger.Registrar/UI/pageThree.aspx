<%@ Page language="c#" Codebehind="pageThree.aspx.cs" AutoEventWireup="false" Inherits="Bandl.Utility.VaultLedger.Registrar.UI.pageThree" %>
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
                <H1>Deployment Method</H1>
                Please select the desired method of deployment for your ReQuest Media Manager 
                system. You may download your own set of application files to install at your 
                company, or you may elect to have Recall host the entire application for you.
            </DIV>
            <FORM id="Form1" runat="server">
                <div id="contentBorderTop"></div>
                <DIV class="contentArea">
                    <TABLE class="detailTable">
                        <TR>
                            <TD "PADDING-TOP: 12px" width="500" height="27">
                                <asp:RadioButton id="rbDownload" groupName="DeploymentMethod" text="Download application for local installation"
                                    runat="server"></asp:RadioButton>
                            </TD>
                        </TR>
                        <TR>
                            <TD "PADDING-BOTTOM: 12px" height="27">
                                <asp:RadioButton id="rbAllowHost" groupName="DeploymentMethod" text="Allow Recall to host the application for you"
                                    checked="True" runat="server"></asp:RadioButton>
                            </TD>
                        </TR>
                    </TABLE>
                </DIV>
                <DIV style="MARGIN-TOP: 10px">
                    <table width="100%">
                        <tr>
                            <td align="left" valign="center">
                                <div class="stepHeader">Step 3 of 3</div>
                            </td>
                            <td align="right">
                                <asp:button id="btnBack" runat="server" Text="<<  Back" CssClass="mediumButton" />
                                &nbsp;
                                <asp:button id="btnNext" runat="server" Text="Next  >>" CssClass="mediumButton" />
                            </td>
                        </tr>
                    </table>
                </DIV>
            </FORM>
        </DIV>
    </body>
</HTML>
