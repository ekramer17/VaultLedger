<%@ Page language="c#" Codebehind="new-compare-receive-list-rfid-file-step-one.aspx.cs" AutoEventWireup="false" Inherits="Bandl.VaultLedger.Web.UI.new_compare_receive_list_rfid_file_step_one" %>
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
                    To create a new list from serial numbers and case numbers already stored in an 
                    RFID output file, enter the full path of the file, supply a name for the new 
                    compare file, and click OK.
                </div>
                <asp:placeholder id="PlaceHolder1" runat="server" EnableViewState="False"></asp:placeholder>
                <div class="tabNavigation threeTabs">
                    <div class="tabs" id="threeTabOne"><A id="manualLink" runat="server">Manual / Scan</A></div>
                    <div class="tabs" id="threeTabTwo"><A id="batchLink" runat="server">Batch File</A></div>
                    <div class="tabs" id="threeTabThreeSelected"><A id="rfidLink" href="#">Imation RFID</A></div>
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
                        <div class="introHeader">Enter the path of the RFID output file:</div>
                        <br>
                        <table cellSpacing="0" cellPadding="0" border="0" height="0">
                            <tr>
                                <td width="143" height="23">RFID Output File:</td>
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
