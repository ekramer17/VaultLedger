<%@ Page language="c#" Codebehind="user-detail.aspx.cs" AutoEventWireup="false" Inherits="Bandl.VaultLedger.Web.UI.user_detail" %>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<HTML>
    <HEAD>
        <META http-equiv="Content-Type" content="text/html; charset=windows-1252">
        <meta content="Microsoft Visual Studio .NET 7.1" name="GENERATOR">
        <meta content="C#" name="CODE_LANGUAGE">
        <meta content="JavaScript" name="vs_defaultClientScript">
        <meta content="http://schemas.microsoft.com/intellisense/ie5" name="vs_targetSchema">
        <!--#include file = "../includes/baseHead.inc"-->
        <script language="javascript">
		function onRoleChange(x1)
		{
			var v1 = x1.options[x1.selectedIndex].value;
			var r1 = document.getElementById('GridView3').rows;
			for (var i = 0; i < r1.length; i += 1)
			{
				r1[i].cells[0].className = (v1 != 'Administrator' ? '' : 'invisible');
			}
		}

        function checkPasswords()
        {
            pwdSpan = getObjectById("lblPwdError");
            pwdText1 = getObjectById("txtPassword1").value;
            pwdText2 = getObjectById("txtPassword2").value;
            // If there is no password or if passwords do not match, display error
            if (pwdText1.length < 4)
            {
                pwdSpan.innerHTML = '&nbsp;Password must be at least 4 characters long';
            }
            else if (pwdText1 != pwdText2)
            {
                pwdSpan.innerHTML = 'Passwords must match';
            }
            else
            {
                pwdSpan.innerText = '';
                __doPostBack('btnSave');  
            }
            // return
            return false;
        }
               
        function levelTwoLink(obj)
        {
            while (obj.tagName.toUpperCase() != "BODY")
            {
                if (obj.tagName.toUpperCase() == "DIV")
                {
                    if (obj.id && obj.id == "levelTwoNav")
                    {
                        return true;
                    }
                    else
                    {
                       return false;
                    }
                }
                else
                {
                    obj = obj.parentNode ? obj.parentNode : obj.parentElement;
                }
            }                
            return false;
        }
        
        function disableTopLinks()
        {
            for(i = 0; i < document.links.length; i++)
            {
                if (levelTwoLink(document.links[i]))
                {
                    document.links[i].onclick = Function("return false;");
                }
                else if (document.links[i].href.indexOf("administrative-tools/index.aspx") != -1)
                {
                    document.links[i].onclick = Function("return false;");
                }
            }
        }
        </script>
    </HEAD>
    <body>
        <!--#include file = "../includes/baseBody.inc"-->
        <script type="text/javascript" src="../includes/tablechecker.js"></script>
        <form id="Form1" method="post" runat="server">
            <div class="contentWrapper">
                <div class="pageHeader">
                    <h1>User Detail</h1>
                    View and, if authorized, edit the details of a particular user. 
                    <!-- header links -->
                    <A style="LEFT:612px" class="headerLink" id="arrow" href="security.aspx">Users</A>&nbsp;
                    <asp:linkbutton id="printLink" runat="server" CssClass="headerLink">Print</asp:linkbutton>
                </div>
                <asp:placeholder id="PlaceHolder1" runat="server" EnableViewState="False"></asp:placeholder>
                <div class="contentArea" id="contentBorderTop" runat="server">
                    <div class="content" id="accountDetail">
                        <table class="accountDetailTable" cellSpacing="0" cellPadding="0" width="724" border="0">
                            <tr vAlign="top">
                                <td class="leftPad" width="168"><b>Operator Name:</b></td>
                                <td width="215"><asp:textbox id="txtName" runat="server" CssClass="medium"></asp:textbox><asp:label id="lblName" runat="server" CssClass="medium"></asp:label></td>
                                <td><asp:requiredfieldvalidator id="rfvName" runat="server" ControlToValidate="txtName" ErrorMessage="&amp;nbsp;Please enter the name of this user"></asp:requiredfieldvalidator></td>
                            </tr>
                            <tr vAlign="top">
                                <td class="leftPad" height="13"><b>Role:</b></td>
                                <td height="13"><asp:dropdownlist id="ddlRole" runat="server" CssClass="medium">
                                        <asp:ListItem Value="-Select Role-" Selected="True">-Select Role-</asp:ListItem>
                                    </asp:dropdownlist><asp:label id="lblRole" runat="server" CssClass="medium"></asp:label></td>
                                <td height="13"><asp:regularexpressionvalidator id="revRole" runat="server" ControlToValidate="ddlRole" ErrorMessage="&amp;nbsp;Please select a security role"
                                        ValidationExpression="^[^\-].*[^\-]$"></asp:regularexpressionvalidator></td>
                            </tr>
                            <tr id="lastLogSpacer" runat="server">
                                <td class="tableRowSpacer" colSpan="3"></td>
                            </tr>
                            <tr valign="top" id="lastLogRow" runat="server">
                                <td class="leftPad"><b>Last Login:</b></td>
                                <td><asp:label id="lastLogin" runat="server"></asp:label></td>
                                <td>&nbsp;</td>
                            </tr>
                            <tr>
                                <td class="tableRowSpacer" colSpan="3"></td>
                            </tr>
                            <tr vAlign="top">
                                <td class="leftPad"><b>Login ID:</b></td>
                                <td><asp:textbox id="txtLogin" runat="server" CssClass="medium"></asp:textbox><asp:label id="lblLogin" runat="server" CssClass="medium"></asp:label></td>
                                <td><asp:requiredfieldvalidator id="rfvLogin" runat="server" ControlToValidate="txtLogin" ErrorMessage="&amp;nbsp;Please enter a login ID"></asp:requiredfieldvalidator></td>
                            </tr>
                            <tr vAlign="top" id="passwordRow1" runat="server">
                                <td class="leftPad"><b>Password:</b></td>
                                <td><asp:textbox id="txtPassword1" runat="server" CssClass="medium" MaxLength="64" TextMode="Password"></asp:textbox></td>
                                <td><asp:label id="lblPwdError" runat="server" ForeColor="Red"></asp:label></td>
                            </tr>
                            <tr vAlign="top" id="passwordRow2" runat="server">
                                <td class="leftPad"><b>Confirm Password:</b></td>
                                <td><asp:textbox id="txtPassword2" runat="server" CssClass="medium" TextMode="Password"></asp:textbox></td>
                                <td></td>
                            </tr>
                            <tr>
                                <td class="tableRowSpacer" colSpan="3"></td>
                            </tr>
                            <tr vAlign="top">
                                <td class="leftPad"><b>Telephone:</b></td>
                                <td><asp:textbox id="txtPhoneNo" runat="server" CssClass="medium"></asp:textbox><asp:label id="lblPhoneNo" runat="server" CssClass="medium"></asp:label></td>
                                <td>&nbsp;</td>
                            </tr>
                            <tr vAlign="top">
                                <td class="leftPad"><b>Email Address:</b></td>
                                <td><asp:textbox id="txtEmail" runat="server" CssClass="medium"></asp:textbox><asp:label id="lblEmail" runat="server" CssClass="medium"></asp:label></td>
                                <td>&nbsp;</td>
                            </tr>
                            <tr vAlign="top">
                                <td class="leftPad"><b>Notes:</b></td>
                                <td class="textArea"><asp:textbox id="txtNotes" runat="server" CssClass="medium" TextMode="MultiLine" Columns="10"
                                        Rows="5"></asp:textbox></td>
                                <td>&nbsp;</td>
                            </tr>
                        </table>
                    </div> <!-- end content //-->
                    <div class="contentBoxBottom">
                        <div class="floatLeft"><input class="formBtn btnMedium" id="btnDelete" type="button" value="Delete" runat="server"></div>
                        <!-- This is the only asp:button on the page; all others are html input controls.  We do this so that we may set this button as the default. //-->
                        <input class="formBtn btnMedium" id="btnSave" type="button" value="Save" runat="server" onclick="return checkPasswords();">&nbsp;&nbsp;
                        <input class="formBtn btnMedium" id="btnCancel" type="button" value="Cancel" runat="server">
                    </div>
                </div>
                <!-- end contentArea //-->
                <!-- Accounts -->
                <asp:Panel ID="Panel3_Header" runat="server" CssClass="accordionHeader">Accessible Accounts</asp:Panel>
                <asp:Panel id="Panel3_Content" runat="server" CssClass="accordionContent">
                    <asp:Panel id="Panel3_None" runat="server" CssClass="contentboxtop" Visible="False">You do not have access to any 
accounts</asp:Panel>
                    <asp:DataGrid id="GridView3" runat="server" CssClass="detailTable" EnableViewState="True" AutoGenerateColumns="False">
                        <AlternatingItemStyle CssClass="alternate"></AlternatingItemStyle>
                        <HeaderStyle CssClass="header"></HeaderStyle>
                        <Columns>
                            <asp:TemplateColumn>
                                <HeaderStyle CssClass="checkbox"></HeaderStyle>
                                <ItemStyle CssClass="checkbox"></ItemStyle>
                                <HeaderTemplate>
                                    <input type="checkbox" id="HeaderBox" runat="server" onclick="x1.click(this)" NAME="HeaderBox" />
                                </HeaderTemplate>
                                <ItemTemplate>
                                    <input type="checkbox" id="ItemBox" runat="server" onclick="x1.click(this)" NAME="ItemBox" />
                                </ItemTemplate>
                            </asp:TemplateColumn>
                            <asp:BoundColumn DataField="Id" HeaderStyle-CssClass="invisible" ItemStyle-CssClass="invisible" />
                            <asp:BoundColumn DataField="Name" HeaderText="Name">
                                <HeaderStyle Font-Bold="True" Wrap="False"></HeaderStyle>
                            </asp:BoundColumn>
                            <asp:TemplateColumn HeaderText="Address">
                                <ItemTemplate>
                                    <%# DataBinder.Eval(Container.DataItem, "Address1") + " " + DataBinder.Eval(Container.DataItem, "Address2") %>
                                </ItemTemplate>
                            </asp:TemplateColumn>
                            <asp:BoundColumn DataField="City" HeaderText="City">
                                <HeaderStyle Font-Bold="True" Wrap="False"></HeaderStyle>
                            </asp:BoundColumn>
                            <asp:BoundColumn DataField="State" HeaderText="State">
                                <HeaderStyle Font-Bold="True" Wrap="False"></HeaderStyle>
                            </asp:BoundColumn>
                        </Columns>
                    </asp:DataGrid>
                </asp:Panel>
            </div> <!-- end contentWrapper //-->
            <!-- BEGIN MESSAGE BOX -->
            <div class="msgBoxSmall" id="msgBoxSave" style="DISPLAY: none">
                <h1><%= ProductName %></h1>
                <div class="msgBoxBody">
                    User was updated successfully.
                </div>
                <div class="msgBoxFooter"><input class="formBtn btnSmallTop" id="btnOK" type="button" value="OK" runat="server">
                </div>
            </div>
            <!-- END TRANSMIT MESSAGE BOX -->
            <!-- BEGIN DELETE MESSAGE BOX -->
            <div class="msgBox" id="msgBoxDelete" style="DISPLAY: none">
                <h1><%= ProductName %></h1>
                <div class="msgBoxBody">Deleting a user permanently removes it from the database.<br>
                    <br>
                    Are you sure you want to delete this user?
                </div>
                <div class="msgBoxFooter"><input class="formBtn btnSmallTop" id="btnYes" type="button" value="Yes" runat="server">
                    &nbsp; <input class="formBtn btnSmallTop" id="btnNo" type="button" value="No" runat="server">
                </div>
            </div>
            <!-- END DELETE MESSAGE BOX -->
        </form>
        <script type="text/javascript">
		var x1 = new TableChecker(1).initialize('GridView3');
        </script>
    </body>
</HTML>
