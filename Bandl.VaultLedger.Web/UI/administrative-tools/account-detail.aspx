<%@ Page language="c#" Codebehind="account-detail.aspx.cs" AutoEventWireup="false" Inherits="Bandl.VaultLedger.Web.UI.account_detail" %>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<HTML>
  <HEAD>
        <meta content="Microsoft Visual Studio .NET 7.1" name=GENERATOR>
        <meta content=C# name=CODE_LANGUAGE>
        <meta content=JavaScript name=vs_defaultClientScript>
        <meta content=http://schemas.microsoft.com/intellisense/ie5 name=vs_targetSchema>
        <!--#include file = "../includes/baseHead.inc"-->
  </HEAD>
<body>
    <!--#include file = "../includes/baseBody.inc"-->
    <form id="Form1" method="post" runat="server">
        <div class="contentWrapper">
            <div class="pageHeader">
                <h1>Account Detail</h1>
                <asp:label id="lblPageCaption" runat="server">Review detailed account information.&nbsp;&nbsp;You may also make changes to contact information and 
                any notes you attach to this account.&nbsp;&nbsp;Other fields may only be modified by Recall.</asp:label>
                <div id="headerConstants">
                    <A class="headerLink" id="arrow" href="accounts.aspx">Accounts</A>
                    &nbsp;
                    <asp:linkbutton id="printLink" runat="server" CssClass="headerLink">Print</asp:linkbutton>
                </div>
            </div> <!-- end pageHeader //-->
            <asp:placeholder id="PlaceHolder1" runat="server" EnableViewState="False"></asp:placeholder>
            <div class="contentArea" id="contentBorderTop">
                <div class="content" id="accountDetail">
                    <table class="accountDetailTable" cellSpacing="0" cellPadding="0" width="724" border="0">
                        <tr vAlign="top">
                            <td class="leftPad" width="135"><b>Account Number:</b></td>
                            <td width="207"><asp:label id="lblAccountNum" runat="server"></asp:label><asp:textbox id="txtAccountNum" runat="server" CssClass="medium" tabIndex="1"></asp:textbox></td>
                            <td width="33">&nbsp;</td>
                            <td width="135">&nbsp;</td>
                            <td width="207">&nbsp;</td></tr>
                        <tr id="globalAccount" vAlign="top" runat="server">
                            <td class="leftPad"><b>Global Account:</b></td>
                            <td><asp:label id="lblGlobalAcct" runat="server"></asp:label></td>
                            <td>&nbsp;</td>
                            <td>&nbsp;</td>
                            <td>&nbsp;</td></tr>
                        <tr>
                            <td class=tableRowSpacer colSpan=5></td></tr>
                        <tr vAlign=top>
                            <td class=leftPad><b>Address (Line 1):</b></td>
                            <td><asp:label id=lblAddress1 runat="server"></asp:label><asp:textbox id=txtAddress1 tabIndex=2 runat="server" CssClass="medium"></asp:textbox></td>
                            <td>&nbsp;</td>
                            <td>&nbsp;</td>
                            <td>&nbsp;</td></tr>
                        <tr vAlign=top>
                            <td class=leftPad><b>Address (Line 2):</b></td>
                            <td><asp:label id=lblAddress2 runat="server"></asp:label><asp:textbox id=txtAddress2 tabIndex=3 runat="server" CssClass="medium"></asp:textbox></td>
                            <td>&nbsp;</td>
                            <td>&nbsp;</td>
                            <td>&nbsp;</td></tr>
                        <tr vAlign=top>
                            <td class=leftPad><b>City:</b></td>
                            <td><asp:label id=lblCity runat="server"></asp:label><asp:textbox id=txtCity tabIndex=4 runat="server" CssClass="medium"></asp:textbox></td>
                            <td>&nbsp;</td>
                            <td><b>Zip/Postal Code:</b></td>
                            <td><asp:label id=lblZipCode runat="server"></asp:label><asp:textbox id=txtZipCode tabIndex=6 runat="server" CssClass="medium"></asp:textbox></td></tr>
                        <tr vAlign=top>
                            <td class=leftPad><b>State/Province:</b></td>
                            <td><asp:label id=lblState runat="server"></asp:label><asp:textbox id=txtState tabIndex=5 runat="server" CssClass="medium"></asp:textbox></td>
                            <td>&nbsp;</td>
                            <td><b>Country:</b></td>
                            <td><asp:label id=lblCountry runat="server"></asp:label><asp:textbox id=txtCountry tabIndex=7 runat="server" CssClass="medium"></asp:textbox></td></tr>
                        <tr>
                            <td class=tableRowSpacer colSpan=5></td></tr>
                        <tr vAlign=top>
                            <td class=leftPad><b>Contact:</b></td>
                            <td><asp:textbox id=txtContact tabIndex=8 runat="server" CssClass="medium"></asp:textbox></td>
                            <td>&nbsp;</td>
                            <td><asp:label id=lblFtpProfile runat="server" Font-Bold="True">FTP Profile:</asp:label></td>
                            <td><asp:dropdownlist id=ddlFtpProfile tabIndex=12 runat="server" CssClass="medium"></asp:dropdownlist></td></tr>
                        <tr vAlign=top>
                            <td class=leftPad><b 
                            >Telephone:</b></td>
                            <td><asp:textbox id=txtTelephone tabIndex=9 runat="server" CssClass="medium"></asp:textbox></td>
                            <td>&nbsp;</td>
                            <td>&nbsp;</td>
                            <td>&nbsp;</td></tr>
                        <tr vAlign=top>
                            <td class=leftPad><b>Email:</b></td>
                            <td><asp:textbox id=txtEmail tabIndex=10 runat="server" CssClass="medium"></asp:textbox></td>
                            <td>&nbsp;</td>
                            <td>&nbsp;</td>
                            <td>&nbsp;</td></tr>
                        <tr vAlign=top>
                            <td class=leftPad><b>Notes:</b></td>
                            <td class="textArea"><asp:textbox id="txtNotes" runat="server" CssClass="medium" TextMode="MultiLine" Rows="5" Columns="10" tabIndex="11"></asp:textbox></td></tr>
                    </table>
                </div><!-- end content //-->
                <div class="contentBoxBottom">
                    <asp:button id="btnSave" runat="server" CssClass="formBtn btnSmall" Text="Save" tabIndex="13"></asp:button>
                </div>
            </div><!-- end contentArea //-->
        </div><!-- end contentWrapper //-->
    </form>
</body>
</HTML>
