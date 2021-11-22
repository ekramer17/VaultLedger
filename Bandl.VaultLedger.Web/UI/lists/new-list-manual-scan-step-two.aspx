<%@ Page language="c#" Codebehind="new-list-manual-scan-step-two.aspx.cs" AutoEventWireup="false" Inherits="Bandl.VaultLedger.Web.UI.new_list_manual_scan_step_two" %>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<HTML>
    <HEAD>
        <meta content="Microsoft Visual Studio .NET 7.1" name="GENERATOR">
        <meta content="C#" name="CODE_LANGUAGE">
        <meta content="JavaScript" name="vs_defaultClientScript">
        <meta content="http://schemas.microsoft.com/intellisense/ie5" name="vs_targetSchema">
        <!--#include file = "../includes/baseHead.inc"-->
        <script language="javascript">
        function initialVisible(radioYes, ctrl)
        {
	        if (document.layers)
	        {
	            makeVisible(ctrl, document.layers[radioYes].checked);
	        }
	        else if (document.all)
	        {
	            makeVisible(ctrl, document.all[radioYes].checked);
	        }
	        else if (document.getElementById)
	        {
	            makeVisible(ctrl, document.getElementById(radioYes).checked);
	        }
        }
        </script>
    </HEAD>
    <body>
        <!--#include file = "../includes/baseBody.inc"-->
        <form id="Form1" method="post" runat="server">
            <div class="contentWrapper">
                <div class="pageHeader">
                    <h1><asp:label id="lblCaption" runat="server"></asp:label></h1>
                    Indicate whether or not each case on the list is sealed. For sealed cases,
                    enter return dates as desired. When finished, click Save.
                </div><!-- end pageHeader //-->
                <asp:placeholder id="PlaceHolder1" runat="server" EnableViewState="False"></asp:placeholder>
                <div class="contentArea" id="contentBorderTop">
                    <div id="accountDetail">
                        <div class="stepHeader">Step 2 of 2</div>
                        <hr class="step">
                        <asp:repeater id="Repeater1" EnableViewState="True" runat="server">
                            <ItemTemplate>
                                <div class="introHeader">Case Number:&nbsp;&nbsp;<asp:Label id="lblCaseName" runat="server" Text='<%# DataBinder.Eval(Container.DataItem, "Name") %>'></asp:Label></div>
                                <br>
                                <table cellpadding="0" cellspacing="0" border="0">
                                    <tr>
                                        <td width="85"><b>Case Sealed:</b></td>
                                        <td width="180">
                                            <asp:RadioButton id="rbYes" GroupName="Sealed" runat="server" Text="Yes" Checked='<%# Convert.ToString(DataBinder.Eval(Container.DataItem, "Sealed"))== "True" %>'></asp:RadioButton>
                                            &nbsp;&nbsp;
                                            <asp:RadioButton id="rbNo" GroupName="Sealed" runat="server" Text="No" Checked='<%# Convert.ToString(DataBinder.Eval(Container.DataItem, "Sealed"))== "False" %>'></asp:RadioButton>
                                        </td>
                                        <td width="92"><asp:label id="lblReturnDate" runat="server" Font-Bold="True">Return Date:</asp:label></td>
                                        <td>
                								     <table style="MARGIN-TOP: 4px">
								                       <tr>
                                                  <td width="150px"><asp:TextBox id="txtReturnDate" runat="server" Text='<%# DisplayDate((string)DataBinder.Eval(Container.DataItem, "ReturnDate"), false, false) %>' Width="143px"></asp:TextBox></td>
                                                  <td class="calendarCell"><a id="calendarLink" href="javascript:openCalendar('[CONTROL_NAME]');" runat="server" class="iconLink calendarLink"/></td>
                                               </tr>
                                            </table>
                                        </td>
                                    </tr>
                                </table>
                            </ItemTemplate>
                            <SeparatorTemplate>
                                <br>
                                <hr class="step">
                            </SeparatorTemplate>
                            <FooterTemplate>
                                <br>
                                <br>
                            </FooterTemplate>
                        </asp:repeater>
                    </div><!-- end accountDetail //-->
                    <div class="contentBoxBottom">
                        <asp:button id="btnBack" runat="server" Text="< Back" CssClass="formBtn btnSmall"></asp:button>
                        &nbsp;
                        <asp:button id="btnSave" runat="server" Text="Save" CssClass="formBtn btnSmall"></asp:button>
                        &nbsp;
                        <asp:button id="btnCancel" runat="server" Text="Cancel" CssClass="formBtn btnSmall"></asp:button>
                    </div><!-- end contentBoxBottom //-->
                </div><!-- end contentArea //-->
            </div><!-- end contentWrapper //-->
        </form>
    </body>
</HTML>
