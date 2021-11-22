<%@ Page language="c#" Codebehind="new-dr-list-tms-file.aspx.cs" AutoEventWireup="false" Inherits="Bandl.VaultLedger.Web.UI.new_dr_list_tms_file" %>
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
    <body onload="fakeFileUploads('../img/btns/form_browse.gif')">
        <!--#include file = "../includes/baseBody.inc"-->
        <form id="Form1" method="post" runat="server">
            <div class="contentWrapper">
                <div class="pageHeader">
                    <h1>New Disaster Recovery List</h1>
                    To create a new list from information stored in a
                    report file issued by another tape management system, enter the full path of the file and click OK.
                </div><!-- end pageHeader //-->
                <asp:PlaceHolder id="PlaceHolder1" runat="server" EnableViewState="False"></asp:PlaceHolder>
                <div class="tabNavigation threeTabs">
                    <div class="tabs" id="threeTabOne"><A href="disaster-recovery-list-append.aspx">Manual / 
                            Scan</A></div>
                    <div class="tabs" id="threeTabTwo"><A href="new-dr-list-batch-file-step-one.aspx">Batch File</A></div>
                    <div class="tabs" id="threeTabThreeSelected"><A href="#">TMS Report</A></div>
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
	                                <input type="file" id="File1" class="file" runat="server" NAME="File1">
                                </td>
                            </tr>
                        </table>
                    </div><!-- end content //-->
                    <div class="contentBoxBottom">
                        <asp:button id="btnOK" runat="server" Text="OK" CssClass="formBtn btnSmall"></asp:button>
                        &nbsp;
                        <input type="button" id="btnCancel" onclick="location.href('disaster-recovery-list-browse.aspx')" value="Cancel" class="formBtn btnSmall">
                    </div>
                </div><!-- end contentArea //-->
            </div><!-- end contentWrapper //-->
        </form>
    </body>
</HTML>
