<%@ Page language="c#" Codebehind="media-edit.aspx.cs" AutoEventWireup="false" Inherits="Bandl.VaultLedger.Web.UI.media_edit" %>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<HTML>
  <HEAD>
        <meta content="Microsoft Visual Studio .NET 7.1" name="GENERATOR">
        <meta content="C#" name="CODE_LANGUAGE">
        <meta content="JavaScript" name="vs_defaultClientScript">
        <meta content="http://schemas.microsoft.com/intellisense/ie5" name="vs_targetSchema">
        <!--#include file = "../includes/baseHead.inc"-->
  </HEAD>
    <body onload="bounceCheckBox('txtReturnDate')">
        <!--#include file = "../includes/baseBody.inc"-->
        <form id="Form1" method="post" runat="server">
            <div class="contentWrapper">
                <div class="pageHeader">
                    <h1>Media - Edit<asp:label id="lblPageTitle" runat="server"></asp:label></h1>
                    <asp:label id="lblCaption" runat="server"></asp:label></div>
                <div><asp:placeholder id="PlaceHolder1" EnableViewState="False" runat="server"></asp:placeholder></div>
                <div class="contentArea" id="contentBorderTop">
                    <div id="accountDetail">
                        <div class="introHeader">Please edit media information below:</div>
                        <br>
                        <!-- CRITERIA ENTRY TABLE //-->
                        <table cellSpacing="0" cellPadding="0" width="97%">
                            <tr valign="top" style="HEIGHT:26px">
                                <td style="WIDTH:100px">Medium Type:</td>
                                <td style="WIDTH:215px">
                                    <asp:dropdownlist id="ddlType" runat="server" Width="150px">
                                        <asp:ListItem Value="-Select Type-" Selected="True">-Select Type-</asp:ListItem>
                                    </asp:dropdownlist>
                                </td>
                                <!-- Notes //-->
                                <td style="WIDTH:50px" rowspan="5" valign="top">Notes:</td>
                                <td rowspan="5">
                                    <asp:textbox id="txtNotes" style="height:115px;width:98%" runat="server" TextMode="MultiLine"></asp:textbox>
                                </td>
                            </tr>
                            <tr valign="top" style="HEIGHT:26px">
                                <td>Account:</td>
                                <td>
                                    <asp:dropdownlist id="ddlAccount" runat="server" Width="150">
                                        <asp:ListItem Value="-Select Account-" Selected="True">-Select Account-</asp:ListItem>
                                    </asp:dropdownlist>
                                </td>
                            </tr>
                            <tr valign="top" style="HEIGHT:26px">
                                <!-- Location //-->
                                <td>Location:</td>
                                <td>
                                    <asp:dropdownlist id="ddlLocation" runat="server" Width="150">
                                        <asp:ListItem Value="-Select Location-" Selected="True">-Select Location-</asp:ListItem>
                                        <asp:ListItem Value="0">Vault</asp:ListItem>
                                        <asp:ListItem Value="1">Enterprise</asp:ListItem>
                                    </asp:dropdownlist>
                                </td>
                            </tr>
                            <tr valign="top" style="HEIGHT:26px">
                                <!-- Missing //-->
                                <td>Missing:</td>
                                <td>
                                    <asp:dropdownlist id="ddlMissing" runat="server" Width="150">
                                        <asp:ListItem Value="-Select Status-" Selected="True">-Select Status-</asp:ListItem>
                                        <asp:ListItem Value="True">Yes</asp:ListItem>
                                        <asp:ListItem Value="False">No</asp:ListItem>
                                    </asp:dropdownlist>
                                </td>
                            </tr>
                            <tr valign="top">
                                <!-- Return Date //-->
                                <td>Return Date:</td>
                                <td>
                                    <a style="PADDING-RIGHT:31px;FLOAT:right" href="javascript:openCalendar('txtReturnDate');" class="calendarLink iconLink"></a>
                                    <asp:textbox id="txtReturnDate" runat="server" Width="145px"></asp:textbox>
                                </td>
                            </tr>
                        </table>
                    </div>
                    <!-- SAVE BUTTON //-->
                    <div class="contentBoxBottom">
                        <asp:button id="btnSave" runat="server" CssClass="formBtn btnSmall" Text="Save"></asp:button>
                        &nbsp; 
                        <input type="button" id="btnCancel" onclick="location.href='find-media.aspx'" class="formBtn btnMedium" value="Cancel">
                    </div>
                </div>
            </div>
            <!-- BEGIN MISSING MESSAGE BOX -->
            <div class="msgBox" id="msgBoxMissing" style="DISPLAY: none">
                <h1><%= ProductName %></h1>
                <div class="msgBoxBody">At least one of the selected media resides in a sealed 
                    case.<br>
                    <br>
                    <asp:Label id="lblMsgMissing" runat="server">You
                    may either designate only this medium as missing (it will be removed from its
                    case), or you may designate all media in the case as missing.</asp:Label><br>
                    <br>
                    Which would you prefer?
                </div>
                <div class="msgBoxFooter">
                    <asp:button id="btnSolo" runat="server" CssClass="formBtn btnMediumTop" Text="Single"></asp:button>
                    &nbsp;
                    <asp:button id="btnCase" runat="server" CssClass="formBtn btnMediumTop" Text="All Media"></asp:button>
                    &nbsp;
                    <asp:button id="btnCancel2" runat="server" Text="Cancel" CssClass="formBtn btnMediumTop"></asp:button>
                </div>
            </div>
            <!-- END MISSING MESSAGE BOX -->
        </form>
        <!-- 
        For some reason, the first time the disabled status of txtReturnDate field
        is changed (i.e. when we click the checkbox), the detail area shifts downward a
        bit.  We can get around this by bouncing the disabled status on document load.
        //-->
        <script language="javascript">
        function bounceCheckBox(boxName)
        {
            o = document.getElementById(boxName)
            o.disabled = !o.disabled
            o.disabled = !o.disabled
        }
        </script>
    </body>
</HTML>
