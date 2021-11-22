<%@ Page language="c#" Codebehind="media-type-detail.aspx.cs" AutoEventWireup="false" Inherits="Bandl.VaultLedger.Web.UI.media_type_detail" %>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<HTML>
    <HEAD>
        <META http-equiv="Content-Type" content="text/html; charset=windows-1252">
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
                    <h1><asp:label id="lblPageHeader" runat="server"></asp:label></h1>
                    <asp:label id="lblPageCaption" runat="server">View and, if desired, edit the details of a particular media type.</asp:label></div>
                <!-- end pageHeader //--><asp:placeholder id="PlaceHolder1" runat="server" EnableViewState="False"></asp:placeholder>
                <div class="contentArea" id="contentBorderTop">
                    <div class="content" id="accountDetail">
                        <table class="accountDetailTable" cellSpacing="0" cellPadding="0" width="724" border="0">
                            <tr>
                                <td width="130"><b>Type Name:</b></td>
                                <td width="210"><asp:textbox id="txtTypeName" runat="server" CssClass="medium"></asp:textbox></td>
                                <td><asp:requiredfieldvalidator id="rfvTypeName" runat="server" ControlToValidate="txtTypeName" ErrorMessage="&amp;nbsp;Please enter a media type name"></asp:requiredfieldvalidator></td>
                            </tr>
                            <tr>
                                <td><b>Container:</b></td>
                                <td><asp:dropdownlist id="ddlContainer" runat="server" CssClass="small">
                                        <asp:ListItem Value="True">Yes</asp:ListItem>
                                        <asp:ListItem Value="False" Selected="True">No</asp:ListItem>
                                    </asp:dropdownlist><asp:label id="lblContainer" runat="server"></asp:label></td>
                                <td>&nbsp;</td>
                            </tr>
                            <tr>
                                <td width="130"><b>Transmit Code:</b></td>
                                <td width="210"><asp:textbox id="txtXmitCode" runat="server" CssClass="small"></asp:textbox></td>
                                <td><asp:RegularExpressionValidator id="revXmitCode" runat="server" ErrorMessage="&amp;nbsp;Xmit code may only consist of alphanumerics"
                                        ValidationExpression="^[0-9A-Za-z]*$" ControlToValidate="txtXmitCode"></asp:RegularExpressionValidator></td>
                            </tr>
                            <tr id="twoSided" runat="server">
                                <td><b>Two-Sided:</b></td>
                                <td><asp:dropdownlist id="ddlTwoSided" runat="server" CssClass="small">
                                        <asp:ListItem Value="True">Yes</asp:ListItem>
                                        <asp:ListItem Value="False" Selected="True">No</asp:ListItem>
                                    </asp:dropdownlist><asp:label id="lblTwoSided" runat="server"></asp:label></td>
                                <td>&nbsp;</td>
                            </tr>
                        </table>
                    </div> <!-- end content //-->
                    <div class="contentBoxBottom"><asp:button id="btnSave" runat="server" CssClass="formBtn btnSmall" Text="Save"></asp:button>&nbsp;
                        <input class="formBtn btnMedium" id="btnCancel" onclick="location.href='media-types.aspx'"
                            type="button" value="Cancel">
                    </div>
                </div> <!-- end contentArea //--></div> <!-- end contentWrapper //--></form>
        <script language="javascript">
        function containerChange(dropDown)
        {
            if (dropDown.options[dropDown.selectedIndex].value == 'True') 
            {
                document.getElementById('ddlTwoSided').selectedIndex = 1;
                document.getElementById('ddlTwoSided').disabled = true;
            }
            else
            {
                document.getElementById('ddlTwoSided').disabled = false;
            }
        }

        function sidedChange(dropDown)
        {
            if (dropDown.options[dropDown.selectedIndex].value == 'True') 
            {
                document.getElementById('ddlContainer').selectedIndex = 1;
                document.getElementById('ddlContainer').disabled = true;
            }
            else
            {
                document.getElementById('ddlContainer').disabled = false;
            }
        }
        </script>
    </body>
</HTML>
