<%@ Page language="c#" Codebehind="disaster-recovery-list-edit.aspx.cs" AutoEventWireup="false" Inherits="Bandl.VaultLedger.Web.UI.disaster_recovery_list_edit" %>
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
                    Enter the new disaster recovery code and then click Save.
                </div>
                <asp:placeholder id="PlaceHolder1" runat="server" EnableViewState="False"></asp:placeholder>
                <div class="contentArea" id="contentBorderTop" runat="server">
                    <div id="accountDetail">
                        <div class="introHeader">Enter disaster recovery code below:</div>
                        <br>
                        <table cellSpacing="0" cellPadding="0" border="0">
                            <tr vAlign="top">
                                <td width="100" height="23">DR Code:</td>
                                <td width="300" height="23"><asp:textbox id="txtDisasterCode" runat="server" CssClass="large"></asp:textbox></td>
                            </tr>
                        </table>
                        <br>
                    </div>
                    <div class="contentBoxBottom">
                        <input type="button" id="btnSave" runat="server" class="formBtn btnMedium" value="Save" />
                        <asp:button id="btnSave1" runat="server" CssClass="formBtn btnMedium" Text="Save"></asp:button>
                        &nbsp;&nbsp;
                        <asp:button id="btnCancel" runat="server" CssClass="formBtn btnSmall" Text="Cancel"></asp:button>
                    </div>
                </div>
                <!-- end contentArea //--></div>
        </form>
    </body>
</HTML>
