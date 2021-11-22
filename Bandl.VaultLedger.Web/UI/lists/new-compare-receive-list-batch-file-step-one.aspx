<%@ Page language="c#" Codebehind="new-compare-receive-list-batch-file-step-one.aspx.cs" AutoEventWireup="false" Inherits="Bandl.VaultLedger.Web.UI.new_compare_receive_list_batch_file_step_one" %>
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
                    <h1><asp:label id="lblCaption" runat="server"></asp:label></h1>
                    To create a new list from serial numbers and case numbers already stored in a 
                    batch scanner file, enter the full path of the file, supply a name for the new 
                    compare file, and click OK.
                </div>
                <asp:placeholder id="PlaceHolder1" runat="server" EnableViewState="False"></asp:placeholder>
                <!-- Visible when RFID enabled -->
                <div id="threeTabs" runat="server">
                    <div class="tabNavigation threeTabs">
                        <div class="tabs" id="threeTabOne"><A id="manualLink" runat="server">Manual / Scan</A></div>
                        <div class="tabs" id="threeTabTwoSelected"><A href="#">Batch File</A></div>
                        <div class="tabs" id="threeTabThree"><A id="rfidLink" runat="server">Imation RFID</A></div>
                    </div>
                </div>
                <!-- Visible when RFID not enabled -->
                <div id="twoTabs" class="tabNavigation twoTabs" runat="server">
                    <div class="tabs" id="twoTabOne"><A id="manualLinkTwo" runat="server">Manual / Scan</A></div>
                    <div class="tabs" id="twoTabTwoSelected"><A href="#">Batch File</A></div>
                </div>
                <div class="contentArea">
                    <div id="accountDetail">
                        <table cellSpacing="0" cellPadding="0" border="0">
                            <tr>
                                <td width="143" height="23">Compare File Name:</td>
                                <td><asp:textbox id="txtFileName" runat="server" CssClass="large"></asp:textbox></td>
                            </tr>
                        </table>
                        <br>
                        <hr class="step">
                        <div class="introHeader">Enter the path of the batch scanner file:</div>
                        <br>
                        <table cellSpacing="0" cellPadding="0" border="0" height="0">
                            <tr>
                                <td width="143" height="23">Batch Scanner File:</td>
                                <td><input type="file" id="File1" class="file" runat="server" NAME="File1"></td>
                            </tr>
                        </table>
                    </div>
                    <div class="contentBoxBottom">
                        <asp:button id="btnOK" runat="server" Text="OK" CssClass="formBtn btnSmall"></asp:button>
                        &nbsp; <input class="formBtn btnSmall" id="btnCancel" type="button" value="Cancel" name="btnCancel"
                            runat="server">
                    </div>
                </div>
            </div>
        </form>
    </body>
</HTML>
