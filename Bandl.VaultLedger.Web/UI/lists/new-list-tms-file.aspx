<%@ Page language="c#" Codebehind="new-list-tms-file.aspx.cs" AutoEventWireup="false" Inherits="Bandl.VaultLedger.Web.UI.new_list_tms_file" %>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<HTML>
    <HEAD>
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
                    <h1>New Shipping List</h1>
                    To add serial numbers from a list already compiled by a tape management system, 
                    click browse to locate the TMS report, and then click OK.
                </div> <!-- end pageHeader //-->
                <asp:PlaceHolder id="PlaceHolder1" runat="server" EnableViewState="False"></asp:PlaceHolder>
                <div id="tabControls1" runat="server">
                    <div class="tabNavigation threeTabs">
                        <div class="tabs" id="threeTabOne"><a href="new-list-manual-scan-step-one.aspx">Manual 
                                / Scan</a></div>
                        <div class="tabs" id="threeTabTwo"><a href="new-list-batch-file-step-one.aspx">Batch 
                                File</a></div>
                        <div class="tabs" id="threeTabThreeSelected"><a href="#">TMS Report</a></div>
                    </div>
                </div>
                <div id="tabControls2" runat="server">
                    <div class="tabNavigation fourTabs">
                        <div class="tabs" id="fourTabOne"><A href="new-list-manual-scan-step-one.aspx">Manual / 
                                Scan</A></div>
                        <div class="tabs" id="fourTabTwo"><A href="new-list-batch-file-step-one.aspx">Batch 
                                File</A></div>
                        <div class="tabs" id="fourTabThreeSelected"><A href="#">TMS Report</A></div>
                        <div class="tabs" id="fourTabFour"><A href="new-list-rfid-file.aspx">Imation RFID</A></div>
                    </div>
                </div>
                <div class="contentArea">
                    <div class="content" id="newMedia">
                        <div class="introHeader">Enter the path of the TMS report file:</div>
                        <br>
                        <table>
                            <tr>
                                <td width="120">
                                    TMS Report File:
                                </td>
                                <td>
                                    <input type="file" id="File1" class="file" runat="server">
                                </td>
                            </tr>
                            <tr id="rowAccount" runat="server">
                                <td style="PADDING-TOP:4px">List Account:</td>
                                <td style="PADDING-TOP:4px"><asp:DropDownList id="ddlAccount" runat="server"></asp:DropDownList></td>
                            </tr>
                        </table>
                    </div> <!-- end content //-->
                    <div class="contentBoxBottom">
                        <asp:button id="btnOK" runat="server" Text="OK" CssClass="formBtn btnSmall"></asp:button>
                        &nbsp; <input type="button" id="btnCancel" onclick="location.href('send-lists.aspx')" value="Cancel"
                            class="formBtn btnSmall">
                    </div>
                </div> <!-- end contentArea //-->
            </div> <!-- end contentWrapper //-->
        </form>
    </body>
</HTML>
