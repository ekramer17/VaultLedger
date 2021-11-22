<%@ Page language="c#" Codebehind="pageOne.aspx.cs" AutoEventWireup="false" Inherits="Bandl.Utility.VaultLedger.Registrar.UI.pageTest" %>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<HTML>
    <HEAD>
        <meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
        <meta content="http://schemas.microsoft.com/intellisense/ie5" name="vs_targetSchema">
        <!--#include file = "masterHead.inc"-->
    </HEAD>
    <BODY>
        <!--#include file = "masterBody.inc"-->
        <DIV class="contentWrapper">
            <DIV class="pageHeader">
                <H1>Client Registration</H1>
                To register your company to use <%=ProductName%>, please fill out the 
                client information form below. When you finish, click Next.
            </DIV>
            <FORM id="Form1" runat="server">
                <div id="contentBorderTop"></div>
                <DIV class="contentArea">
                    <TABLE class="detailTable" id="Table1" runat="server">
                        <TR>
                            <TD style="PADDING-TOP: 12px" width="115" height="27"><strong>Company:</strong></TD>
                            <TD style="PADDING-TOP: 12px"><asp:textbox id="txtCompany" runat="server" MaxLength="256" Width="250px"></asp:textbox><asp:requiredfieldvalidator id="rfvCompany" runat="server" Display="Dynamic" ControlToValidate="txtCompany"
                                    ErrorMessage="&amp;nbsp;Entry required"></asp:requiredfieldvalidator></TD>
                        </TR>
                        <TR>
                            <TD><strong>Address 1:</strong></TD>
                            <TD><asp:textbox id="txtAddress1" runat="server" MaxLength="128" Width="250px"></asp:textbox><asp:requiredfieldvalidator id="rfvAddress1" runat="server" Display="Dynamic" ControlToValidate="txtAddress1"
                                    ErrorMessage="&amp;nbsp;Entry required"></asp:requiredfieldvalidator></TD>
                        </TR>
                        <TR>
                            <TD><strong>Address 2:</strong></TD>
                            <TD><asp:textbox id="txtAddress2" runat="server" MaxLength="128" Width="250px"></asp:textbox></TD>
                        </TR>
                        <TR>
                            <TD><strong>City:</strong></TD>
                            <TD><asp:textbox id="txtCity" runat="server" MaxLength="128" Width="250px"></asp:textbox><asp:requiredfieldvalidator id="rfvCity" runat="server" Display="Dynamic" ControlToValidate="txtCity" ErrorMessage="&amp;nbsp;Entry required"></asp:requiredfieldvalidator></TD>
                        </TR>
                        <TR>
                            <TD><strong>State / Province:</strong></TD>
                            <TD><asp:dropdownlist id="ddlbState" runat="server">
                                    <asp:ListItem></asp:ListItem>
                                    <asp:ListItem Value="Alabama">Alabama</asp:ListItem>
                                    <asp:ListItem Value="Alaska">Alaska</asp:ListItem>
                                    <asp:ListItem Value="Alberta">Alberta</asp:ListItem>
                                    <asp:ListItem Value="Arizona">Arizona</asp:ListItem>
                                    <asp:ListItem Value="Arkansas">Arkansas</asp:ListItem>
                                    <asp:ListItem Value="British Columbia">British Columbia</asp:ListItem>
                                    <asp:ListItem Value="California">California</asp:ListItem>
                                    <asp:ListItem Value="Colorado">Colorado</asp:ListItem>
                                    <asp:ListItem Value="Connecticut">Connecticut</asp:ListItem>
                                    <asp:ListItem Value="Delaware">Delaware</asp:ListItem>
                                    <asp:ListItem Value="Florida">Florida</asp:ListItem>
                                    <asp:ListItem Value="Georgia">Georgia</asp:ListItem>
                                    <asp:ListItem Value="Hawaii">Hawaii</asp:ListItem>
                                    <asp:ListItem Value="Idaho">Idaho</asp:ListItem>
                                    <asp:ListItem Value="Illinois">Illinois</asp:ListItem>
                                    <asp:ListItem Value="Indiana">Indiana</asp:ListItem>
                                    <asp:ListItem Value="Iowa">Iowa</asp:ListItem>
                                    <asp:ListItem Value="Kansas">Kansas</asp:ListItem>
                                    <asp:ListItem Value="Kentucky">Kentucky</asp:ListItem>
                                    <asp:ListItem Value="Louisiana">Louisiana</asp:ListItem>
                                    <asp:ListItem Value="Maine">Maine</asp:ListItem>
                                    <asp:ListItem Value="Manitoba">Manitoba</asp:ListItem>
                                    <asp:ListItem Value="Maryland">Maryland</asp:ListItem>
                                    <asp:ListItem Value="Massachusetts">Massachusetts</asp:ListItem>
                                    <asp:ListItem Value="Michigan">Michigan</asp:ListItem>
                                    <asp:ListItem Value="Minnesota">Minnesota</asp:ListItem>
                                    <asp:ListItem Value="Mississippi">Mississippi</asp:ListItem>
                                    <asp:ListItem Value="Missouri">Missouri</asp:ListItem>
                                    <asp:ListItem Value="Montana">Montana</asp:ListItem>
                                    <asp:ListItem Value="Nebraska">Nebraska</asp:ListItem>
                                    <asp:ListItem Value="Nevada">Nevada</asp:ListItem>
                                    <asp:ListItem Value="New Brunswick">New Brunswick</asp:ListItem>
                                    <asp:ListItem Value="New Hampshire">New Hampshire</asp:ListItem>
                                    <asp:ListItem Value="New Jersey">New Jersey</asp:ListItem>
                                    <asp:ListItem Value="New Mexico">New Mexico</asp:ListItem>
                                    <asp:ListItem Value="New York">New York</asp:ListItem>
                                    <asp:ListItem Value="Newfoundland">Newfoundland</asp:ListItem>
                                    <asp:ListItem Value="North Carolina">North Carolina</asp:ListItem>
                                    <asp:ListItem Value="North Dakota">North Dakota</asp:ListItem>
                                    <asp:ListItem Value="Nova Scotia">Nova Scotia</asp:ListItem>
                                    <asp:ListItem Value="Ohio">Ohio</asp:ListItem>
                                    <asp:ListItem Value="Oklahoma">Oklahoma</asp:ListItem>
                                    <asp:ListItem Value="Ontario">Ontario</asp:ListItem>
                                    <asp:ListItem Value="Oregon">Oregon</asp:ListItem>
                                    <asp:ListItem Value="Pennsylvania">Pennsylvania</asp:ListItem>
                                    <asp:ListItem Value="Prince Edward Island">Prince Edward Island</asp:ListItem>
                                    <asp:ListItem Value="Quebec">Quebec</asp:ListItem>
                                    <asp:ListItem Value="Rhode Island">Rhode Island</asp:ListItem>
                                    <asp:ListItem Value="Saskatchewan">Saskatchewan</asp:ListItem>
                                    <asp:ListItem Value="South Carolina">South Carolina</asp:ListItem>
                                    <asp:ListItem Value="South Dakota">South Dakota</asp:ListItem>
                                    <asp:ListItem Value="Tennessee">Tennessee</asp:ListItem>
                                    <asp:ListItem Value="Texas">Texas</asp:ListItem>
                                    <asp:ListItem Value="Utah">Utah</asp:ListItem>
                                    <asp:ListItem Value="Vermont">Vermont</asp:ListItem>
                                    <asp:ListItem Value="Virginia">Virginia</asp:ListItem>
                                    <asp:ListItem Value="Washington">Washington</asp:ListItem>
                                    <asp:ListItem Value="Washington, D.C.">Washington, D.C.</asp:ListItem>
                                    <asp:ListItem Value="West Virginia">West Virginia</asp:ListItem>
                                    <asp:ListItem Value="Wisconsin">Wisconsin</asp:ListItem>
                                    <asp:ListItem Value="Wyoming">Wyoming</asp:ListItem>
                                </asp:dropdownlist><asp:customvalidator id="cvState" runat="server" Display="Dynamic"></asp:customvalidator></TD>
                        </TR>
                        <TR>
                            <TD><strong>Postal Code:</strong></TD>
                            <TD><asp:textbox id="txtZipCode" runat="server" MaxLength="16" Width="150px"></asp:textbox><asp:requiredfieldvalidator id="rfvZipCode" runat="server" Display="Dynamic" ControlToValidate="txtZipCode"
                                    ErrorMessage="&amp;nbsp;Entry required"></asp:requiredfieldvalidator></TD>
                        </TR>
                        <TR>
                            <TD><strong>Country:</strong></TD>
                            <TD><asp:dropdownlist id="ddlbCountry" runat="server" Width="150px">
                                    <asp:ListItem></asp:ListItem>
                                    <asp:ListItem Value="Canada">Canada</asp:ListItem>
                                    <asp:ListItem Value="United States">United States</asp:ListItem>
                                </asp:dropdownlist><asp:requiredfieldvalidator id="rfvCountry" runat="server" Display="Dynamic" ControlToValidate="ddlbCountry"
                                    ErrorMessage="&amp;nbsp;Entry required"></asp:requiredfieldvalidator></TD>
                        </TR>
                        <TR>
                            <TD><strong>Recall Account:</strong></TD>
                            <TD><asp:textbox id="txtAccount" runat="server" MaxLength="5" Width="100px"></asp:textbox><asp:customvalidator id="cvAccount" runat="server" Display="Dynamic"></asp:customvalidator></TD>
                        </TR>
                    </TABLE>
                </DIV>
                <DIV style="MARGIN-TOP: 10px">
                    <table width="100%">
                        <tr>
                            <td align="left" valign="middle">
                                <div class="stepHeader">Step 1 of <%=TotalPages%></div>
                            </td>
                            <td align="right"><asp:button id="btnNext" runat="server" CssClass="mediumButton" Text="Next  >>"></asp:button></td>
                        </tr>
                    </table>
                </DIV>
            </FORM>
        </DIV>
    </BODY>
</HTML>
