<%@ Page language="c#" Codebehind="default.aspx.cs" AutoEventWireup="false" Inherits="Bandl.VaultLedger.Web.UI.defaultPage"%>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<HTML>
    <HEAD>
        <META http-equiv="Content-Type" content="text/html; charset=windows-1252">
        <meta content="Microsoft Visual Studio .NET 7.1" name="GENERATOR">
        <meta content="C#" name="CODE_LANGUAGE">
        <meta content="JavaScript" name="vs_defaultClientScript">
        <meta content="http://schemas.microsoft.com/intellisense/ie5" name="vs_targetSchema">
        <!--#include file = "includes/baseHead.inc"-->
    </HEAD>
    <body onload="abc()">
        <!--#include file = "includes/baseBody.inc"-->
        <form id="Form1" method="get" runat="server">
            <div class="contentWrapper">
                <!-- page header -->
                <div class="pageHeader">
                    <h1><asp:Label id="lblPageHeader" runat="server"></asp:Label></h1>
                    <%= ProductName %>
                    helps you manage your enterprise media library and tracks media as they are 
                    shipped to and received from your offsite storage vault.
                </div> <!-- end pageHeader //-->
                <div class="contentArea" id="contentBorderTop">
                    <div class="content" id="mainMenu">
                        <div id="menuTop">
                            <!-- lists -->
                            <div class="menuItem" id="mainLists">
                                <a id="linkList" runat="server" href="#">Lists</a> Create, review, and 
                                reconcile lists reporting on the media sent to or returned from the offsite 
                                vault.
                                <span style="DISPLAY:none;FLOAT:right;MARGIN-TOP:38px" runat="server" class="tinted" id="version1"></span>
                            </div>
                            <!-- media library -->
                            <div class="menuItem" id="mainMedia">
                                <a id="linkMedia" runat="server" href="#">Media Library</a> Identify the media 
                                in your library, compare onsite media records with an offsite inventory, and 
                                find specified media.
                        </div>
                        </div> <!-- end menuTop //-->
                        <div id="menuBottom" runat="server">
                            <!-- system administration -->
                            <div class="menuItem" id="mainAdmin" runat="server">
                                <a id="linkAdmin" runat="server" href="#">Administrative Tools</a> Set the 
                                system defaults, establish client accounts, create media bar code formats, and 
                                define system users.
                                <span style="FLOAT:right;MARGIN-TOP:38px" runat="server" class="tinted" id="version2"></span>
                            </div>
                            <!-- reports -->
                            <div class="menuItem" id="mainReports">
                                <a id="linkReport" runat="server" href="#">Reports</a> Report on the media and 
                                lists in your library.
                            </div>
                        </div>
                    </div> <!-- end content //-->
                </div> <!-- end contentArea //-->
                <div id="divNews" runat="server">
                    <br>
                    <div class="contentArea">
                        <table class="detailTable">
                            <tr>
                                <td style="PADDING-BOTTOM: 12px; PADDING-TOP: 12px"><asp:label id="lblNews" runat="server" ForeColor="Red"></asp:label></td>
                            </tr>
                        </table>
                    </div>
                </div>
            </div> <!-- end contentWrapper //-->
            <!-- BEGIN DELETE MESSAGE BOX -->
            <div class="msgBoxSmall" id="msgBoxDisplay" style="DISPLAY:none">
                <h1><%= ProductName %></h1>
                <div class="msgBoxBody">
                    <asp:Label Runat="server" ID="lblMsgBoxDisplay"></asp:Label>
                </div>
                <div class="msgBoxFooter">
                    <input type="button" id="btnOK" runat="server" class="formBtn btnSmallTop" value="OK" NAME="btnOK">
                </div>
            </div>
            <!-- END DELETE MESSAGE BOX -->
            <script type="text/javascript">
            function abc()
            {
                var q1 = createXmlHttpRequest();
                var x1 = new Date().getTimezoneOffset() / -60;
                var u1 = "handlers/requesthandlerasync.ashx?timezone=" + x1.toString() + "&x1=" + new Date().getTime();
                q1.open("GET", u1, true);
                q1.send(null);
            }
            </script>
        </form>
    </body>
</HTML>
