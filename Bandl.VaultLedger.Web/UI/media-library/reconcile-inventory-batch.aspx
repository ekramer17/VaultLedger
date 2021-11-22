<%@ Page language="c#" Codebehind="reconcile-inventory-batch.aspx.cs" AutoEventWireup="false" Inherits="Bandl.VaultLedger.Web.UI.reconcile_inventory_batch" %>
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
                    <h1>Reconcile Inventory</h1>
                    To reconcile the inventory against the contents of a batch scanner inventory 
                    file, enter the full path of the file and click OK.
                </div> <!-- end pageHeader //-->
                <asp:PlaceHolder id="PlaceHolder1" runat="server" EnableViewState="False"></asp:PlaceHolder>
                <!-- Should be visible when tabs are not to be shown -->
                <div id="contentBorderTop" class="contentArea" runat="server"></div>
                <!-- Should be visible when tabs are to be shown -->
                <div id="tabControls" runat="server">
                    <div class="tabNavigation twoTabs">
                        <div class="tabs" id="twoTabOneSelected"><A href="#">Batch File</A></div>
                        <div class="tabs" id="twoTabTwo"><A id="rfidLink" runat="server">Imation RFID</A></div>
                    </div>
                </div>
                <div class="contentArea">
                    <div class="content" id="newMedia">
                        <div class="introHeader">Enter the path of the batch scanner inventory file:</div>
                        <br>
                        <table>
                            <tr>
                                <td width="110">
                                    Batch Scanner File:
                                </td>
                                <td>
                                    <input type="file" id="File1" class="file" runat="server" NAME="File1">
                                </td>
                            </tr>
                        </table>
                    </div> <!-- end content //-->
                    <div class="contentBoxBottom">
                        <asp:button id="btnOK" runat="server" CssClass="formBtn btnSmall" Text="OK"></asp:button>
                    </div>
                </div> <!-- end contentArea //-->
            </div> <!-- end contentWrapper //-->
        </form>
    </body>
</HTML>
