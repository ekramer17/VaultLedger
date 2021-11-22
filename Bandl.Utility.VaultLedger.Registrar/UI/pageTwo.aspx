<%@ Page language="c#" Codebehind="pageTwo.aspx.cs" AutoEventWireup="false" Inherits="Bandl.Utility.VaultLedger.Registrar.UI.pageTwo" %>
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
                <H1>Enterprise Administrator</H1>
                Please provide contact information on the person who will act as the 
                administrator of your
                <%=ProductName%>
                system. After registration, this person will receive system initialization 
                information at the email address provided below.
            </DIV>
            <FORM id="Form1" runat="server">
                <div id="contentBorderTop"></div>
                <DIV class="contentArea">
                    <TABLE class="detailTable">
                        <TR>
                            <TD style="PADDING-TOP:12px" width="100" height="27"><strong>Name:</strong></TD>
                            <TD style="PADDING-TOP:12px" width="350"><asp:TextBox id="txtContact" Width="250px" runat="server" MaxLength="128"></asp:TextBox>
                                <asp:RequiredFieldValidator id="rfvContact" runat="server" ControlToValidate="txtContact" ErrorMessage="&amp;nbsp;Entry Required"></asp:RequiredFieldValidator></TD>
                            <TD style="PADDING-TOP:12px"></TD>
                        </TR>
                        <TR>
                            <TD><strong>Email:</strong></TD>
                            <TD width="1000">
                                <asp:TextBox id="txtEmail" Width="250px" runat="server" MaxLength="128"></asp:TextBox>
                                <asp:CustomValidator id="cvEmail" runat="server" Display="Dynamic"></asp:CustomValidator>
                            </TD>
                            <TD></TD>
                        </TR>
                        <TR>
                            <TD style="PADDING-BOTTOM:12px"><strong>Phone:</strong></TD>
                            <TD style="PADDING-BOTTOM:12px" width="455">
                                <asp:TextBox id="txtPhone" Width="200px" runat="server" MaxLength="64"></asp:TextBox>
                                <asp:CustomValidator id="cvPhone" runat="server" ErrorMessage="&amp;nbsp;Invalid phone number" Display="Dynamic"></asp:CustomValidator></TD>
                            <TD style="PADDING-BOTTOM:12px"></TD>
                        </TR>
                    </TABLE>
                </DIV>
                <DIV style="MARGIN-TOP: 10px">
                    <table width="100%">
                        <tr>
                            <td align="left" valign="middle">
                                <div class="stepHeader">Step 2 of
                                    <%=TotalPages%>
                                </div>
                            </td>
                            <td align="right">
                                <input type="button" id="btnBack" runat="server" value="<<  Back" class="mediumButton">
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
