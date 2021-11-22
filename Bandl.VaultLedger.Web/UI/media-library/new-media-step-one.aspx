<%@ Page CodeBehind="new-media-step-one.aspx.cs" Language="c#" AutoEventWireup="false" Inherits="Bandl.VaultLedger.Web.UI.new_media_step_one" %>
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
            <div class="contentWrapper"><!-- page header -->
                <DIV class="pageHeader">
                    <H1>New Media</H1>
                    Enter a range of media serial numbers to add to the system.&nbsp;&nbsp;Then 
                    click Next to see which media types and accounts correspond to the serial 
                    numbers.
                </DIV>
                <asp:PlaceHolder id="PlaceHolder1" EnableViewState="False" runat="server"></asp:PlaceHolder>
                <div class="contentArea" id="contentBorderTop" runat="server">
                    <div class="content" id="newMedia">
                        <div class="stepHeader">
                            Step 1 of 2
                        </div>
                        <hr class="step" />
                        <TABLE cellSpacing="0" cellPadding="0" border="0">
                            <TR height="27" valign="top">
                                <TD width="140">Starting Serial Number:</TD>
                                <TD width="215"><asp:textbox id="txtSSN" CssClass="medium" runat="server"></asp:textbox></TD>
                            </TR>
                            <TR valign="top">
                                <TD>Ending Serial Number:</TD>
                                <TD><asp:textbox id="txtESN" CssClass="medium" runat="server"></asp:textbox></TD>
                            </TR>
                        </TABLE>
                    </div>
                    <div class="contentBoxBottom">
                        <input type="button" id="btnNext" class="formBtn btnSmall" runat="server" value="Next >">
                        &nbsp; <input type="button" id="btnCancel" onclick="location.href='find-media.aspx'" class="formBtn btnMedium"
                            value="Cancel">
                    </div>
                </div>
            </div>
        </form>
    </body>
</HTML>
