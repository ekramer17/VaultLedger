<%@ Page CodeBehind="new-media-step-two.aspx.cs" Language="c#" AutoEventWireup="false" Inherits="Bandl.VaultLedger.Web.UI.new_media_step_two" %>
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
                    <H1>New Media</H1>These are the media types and accounts
                    that would be assigned to the new serial numbers.&nbsp;&nbsp;To assign 
                    different
                    media types or accounts, adjust your bar code formats.&nbsp;&nbsp;Otherwise
                    click Add to add the media to the system.
                </div>
                <asp:placeholder id="PlaceHolder1" EnableViewState="False" runat="server"></asp:placeholder>
                <div class="contentArea" id="contentBorderTop">
                    <div class="content" id="newMedia">
                        <div class="stepHeader">
                            Step 2 of 2
                        </div>
                        <hr class="step" />
                        <div class="introHeader">These are the media types and
                            accounts that will be assigned to the new media:
                        </div>
                        <br>
                        <asp:datagrid id="DataGrid1" runat="server" width="715" BorderWidth="1" CssClass="detailTable" AutoGenerateColumns="False" BorderColor="Black" BorderStyle="Solid">
                            <AlternatingItemStyle CssClass="alternate"></AlternatingItemStyle>
                            <HeaderStyle CssClass="header"></HeaderStyle>
                            <Columns>
                                <asp:BoundColumn DataField="SerialStart" HeaderText="Range Start">
                                    <HeaderStyle Font-Bold="True">
                                    </HeaderStyle>
                                </asp:BoundColumn>
                                <asp:BoundColumn DataField="SerialEnd" HeaderText="Range End">
                                    <HeaderStyle Font-Bold="True">
                                    </HeaderStyle>
                                </asp:BoundColumn>
                                <asp:BoundColumn HeaderStyle-Width="225" DataField="MediumType" HeaderText="Medium Type">
                                    <HeaderStyle Font-Bold="True">
                                    </HeaderStyle>
                                </asp:BoundColumn>
                                <asp:BoundColumn DataField="AccountName" HeaderText="Account">
                                    <HeaderStyle Font-Bold="True">
                                    </HeaderStyle>
                                </asp:BoundColumn>
                            </Columns>
                        </asp:datagrid>
                    </div>
                    <div class="contentBoxBottom">
                        <asp:button id="btnAdd" CssClass="formBtn btnSmall" runat="server" Text="Add"></asp:button>
                        &nbsp;
                        <input type="button" id="btnCancel" onclick="location.href='find-media.aspx'" class="formBtn btnMedium" value="Cancel" />                        
                    </div>
                </div>
            </div>
        </form>
    </body>
</HTML>