<%@ Page language="c#" Codebehind="rfid-tag-initialize.aspx.cs" AutoEventWireup="false" Inherits="Bandl.VaultLedger.Web.UI.rfid_tag_initialize" %>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<HTML>
    <HEAD>
        <META http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
        <meta content="Microsoft Visual Studio .NET 7.1" name="GENERATOR">
        <meta content="C#" name="CODE_LANGUAGE">
        <meta content="JavaScript" name="vs_defaultClientScript">
        <meta content="http://schemas.microsoft.com/intellisense/ie5" name="vs_targetSchema">
        <!--#include file = "../includes/baseHead.inc"-->
        <script language="javascript">
        var uniqueId = '';
        var serialNo = '';
        var lastType = '';
        var maxSerial = 100;
        // Set the state of the page : 1 = Ready, 2 = Active, 3 = Error
        function displayState(state)
        {
            switch (state)
            {
                case 1:
                    getObjectById('btnInit').disabled = false;
                    getObjectById('lblStatus').innerHTML = 'Ready';
                    getObjectById('lblStatus').style.color = 'blue';
                    getObjectById('txtSerial').focus();   
                    break;
                case 2:
                    getObjectById('btnInit').disabled = true;
                    getObjectById('lblStatus').innerHTML = 'Active';
                    getObjectById('lblStatus').style.color = 'blue';
                    break;
                case 3:
                    getObjectById('btnInit').disabled = true;
                    getObjectById('lblStatus').innerHTML = 'Error!';
                    getObjectById('lblStatus').style.color = 'red';
                    break;
            }
        }
        // Send information to applet
        function sendInfoToApplet()
        {
            // Get the serial number
            incrementSerial = getObjectById('ddlIncrement').selectedIndex == 0;
            // Get the serial number
            serialNo = trim(getObjectById('txtSerial').value);
            // Get the tag type
            var isCase = getObjectById('ddlType').selectedIndex != 0 ? '1' : '0';
            // Make the call to the applet
            var returnValue = document.RFIDInterface.acceptSerial(uniqueId, serialNo, isCase);
            // Evaluate the return value
            if (returnValue == 0)
            {
                // Set the last tag type
                lastType = isCase != '1' ? 'Medium' : 'Case';
                // Everything okay
                declareReady('R');
            }
            else
            {
                declareError(returnValue);
            }
        }
        //
        // Function: reportRfidTagInfo
        //
        // Still retrieves information in form serial&case&guid.  On this page, 
        // serial and case should always be empty, as all we care about its the guid.
        //
        function reportRfidTagInfo(appletString)
        {
            // Necessary for Firefox to realize that appletString is a string        
            appletString = appletString + '';
            // if empty string then blank the current fields and return
            if (appletString.length == 0)
            {
                getObjectById('lblCurrentSerial').innerHTML = '';
                getObjectById('lblCurrentType').innerHTML = '';
            }
            else
            {   
                // If there is a semicolon in the string, then we have two elements
                // on the pad, which is an error.  Display in the current labels.
                // register error in the current labels
                if (appletString.indexOf(';') != -1)
                {
                    getObjectById('lblCurrentSerial').innerHTML = 'Error - multiple tags on pad';
                    getObjectById('lblCurrentType').innerHTML = '';
                }
                else
                {
                    // Get the field array, populate the current elements
                    var fieldArray = appletString.split('&');
                    getObjectById('lblCurrentSerial').innerHTML = fieldArray[0];
                    getObjectById('lblCurrentType').innerHTML = fieldArray[1] == '1' ? 'Case' : 'Medium';
                    uniqueId = fieldArray[2];
                }
            }
        }
        //
        // Is pad ready for a scan?
        //
        function declareReady(messageText)
        {
            if (messageText != null && messageText.length != 0 && messageText.substr(0,1).toUpperCase() == 'R')
            {
                // Enable the initialize button
                getObjectById('btnInit').disabled = false;
                // If the serial number is not empty then set the last 
                // serial and attempt to increment if necessary
                if (serialNo.length != 0)
                {
                    getObjectById('lblLastSerial').innerHTML = serialNo;
                    getObjectById('lblLastType').innerHTML = lastType;
                    // Increment if requested...otherwise, select serial number
                    if (getObjectById('ddlIncrement').selectedIndex != 0)
                    {
                        getObjectById('txtSerial').select();
                    }
                    else if (!doIncrement())
                    {
                        getObjectById('txtSerial').select();
                        declareError(6);
                        return;
                    }
                }
                // Set back to ready state
                displayState(1);
            }
        }
        // Declare error
        function declareError(e)
        {
            string1 = "No object was found on tag.<br>Please one object on the on the pad and try again."
            string2 = "More than one object was found.<br>Please remove all but one object and try again."
            string3 = "A unique id conflict has occurred.&nbsp;&nbsp;Object must be on pad before clicking the Initialize button."
            string4 = "A write error has occurred."
            string5 = "A general error has occurred."
            string6 = "Unable to increment serial number."
            string7 = "Please enter a serial number with which to initialize the RFID tag."
            // Set the error message
            switch (e)
            {
               case 1:
                  getObjectById('lblMessage').innerHTML = string1;
                  break;
               case 2:
                  getObjectById('lblMessage').innerHTML = string2;
                  break;
               case 3:
                  getObjectById('lblMessage').innerHTML = string3;
                  break;
               case 4:
                  getObjectById('lblMessage').innerHTML = string4;
                  break;
               case 5:
                  getObjectById('lblMessage').innerHTML = string5;
                  break;
               case 6:
                  getObjectById('lblMessage').innerHTML = string6;
                  break;
               case 7:
                  getObjectById('lblMessage').innerHTML = string7;
                  break;
               default:
                  return;
            }
            // Set the page state
            displayState(3);
            // Display message box and beep
            showMsgBox('msgBoxError');
        }
        // Increment serial number
        function doIncrement()
        {
            var len = 0;
            var digits = '';
            var prefix = '';
            var leftSide = '';
            var rightSide = '';
            // Strip the right side
            leftSide = serialNo.substr(0, maxSerial > serialNo.length ? serialNo.length : maxSerial);
            // Make sure the last character of the left side is a digit
            if (isNaN(parseInt(leftSide.charAt(leftSide.length-1))))
            {
                return false;
            }
            // If the length of the left side is less then the length of the serial number, get the right side
            if (leftSide.length < serialNo.length)
            {
                rightSide = serialNo.substring(leftSide.length);
            }
            // Get the trailing portion of the left side that is numerical
            for (i = leftSide.length-1; i >= 0; i--)
            {
                if (isNaN(parseInt(leftSide.charAt(i))))
                {
                    break;
                }
                else
                {
                    digits = leftSide.charAt(i) + digits;
                }
            }
            // Get the prefix of the left side if the left side is not all digits
            if (digits.length != leftSide.length)
            {
                prefix = leftSide.substr(0,leftSide.length - digits.length);
            }
            // Add one to the digits portion
            digits = (parseInt(digits,10) + 1).toString();
            // If the new left side (prefix plus digits) is longer than the old left side, raise error
            if (leftSide.length < prefix.length + digits.length)
            {
                return false;
            }
            // Pad the digits portion if necesary
            while (leftSide.length > prefix.length + digits.length)
            {
                digits = '0' + digits;
            }
            // Set the new serial number
            serialNo = prefix + digits + rightSide;
            getObjectById('txtSerial').value = serialNo;
            // Return true
            return true;
        }
        //
        // function: overwriteCheck
        //
        function overwriteCheck()
        {
            // If nothing is in the current tag field, just go ahead 
            // and initialize.  Otherwise, show the overwrite message box.
            // Note that we check the current type label b/c serial will 
            // display error text string if multiple tags on pad.
            if (trim(getObjectById('txtSerial').value).length == 0) 
            {
                declareError(7);
            }
            else if (getObjectById('lblCurrentType').innerHTML.length == 0)
            {
                // Initialize the tag
                displayState(2);
                // Initialize the tag
                sendInfoToApplet();
            }
            else if (getObjectById('lblCurrentSerial').innerHTML != getObjectById('txtSerial').value)   // serial numbers don't match
            {
                // Set state to active
                displayState(2);
                // Set the overwrite fields
                getObjectById('oSerial1').innerHTML = getObjectById('lblCurrentSerial').innerHTML;
                getObjectById('oSerial2').innerHTML = getObjectById('txtSerial').value;
                getObjectById('oType1').innerHTML = getObjectById('lblCurrentType').innerHTML;
                getObjectById('oType2').innerHTML = getObjectById('ddlType').selectedIndex != 0 ? 'case' : 'medium';
                // Show the display box
                showMsgBox('msgBoxOverwrite');
            }
            else if (getObjectById('lblCurrentType').innerHTML != getObjectById('ddlType').options[getObjectById('ddlType').selectedIndex].text)   // types don't match
            {
                // Set state to active
                displayState(2);
                // Set the overwrite fields
                getObjectById('oSerial1').innerHTML = getObjectById('lblCurrentSerial').innerHTML;
                getObjectById('oSerial2').innerHTML = getObjectById('txtSerial').value;
                getObjectById('oType1').innerHTML = getObjectById('lblCurrentType').innerHTML;
                getObjectById('oType2').innerHTML = getObjectById('ddlType').selectedIndex != 0 ? 'case' : 'medium';
                // Show the display box
                showMsgBox('msgBoxOverwrite');
            }
            else
            {
                // Quick active blink
                displayState(2);
                displayState(1);
            }
        }
        </script>
    </HEAD>
    <body>
        <!--#include file = "../includes/baseBody.inc"-->
        <form id="Form1" method="post" runat="server">
            <div class="contentWrapper">
                <div class="pageHeader">
                    <h1>Imation RFID Tag Initialization</h1>
                    Select the options desired, then scan items to initialize RFID tags with new 
                    serial numbers.
                </div>
                <asp:placeholder id="PlaceHolder1" runat="server" EnableViewState="False"></asp:placeholder>
                <div class="contentArea" id="contentBorderTop">
                    <div class="content" id="accountDetail">
                        <table class="accountDetailTable" cellSpacing="0" cellPadding="0" width="724" border="0">
                            <tr valign="top">
                                <td class="leftPad" width="145" style="PADDING-TOP:2px"><b>Serial Number:</b></td>
                                <td width="350">
                                    <asp:textbox id="txtSerial" runat="server" CssClass="medium"></asp:textbox>
                                    &nbsp;&nbsp;
                                    <input type="button" id="btnInit" value="Initialize" onclick="javascript:overwriteCheck();" class="formBtn btnMedium" disabled>
                                </td>
                                <td align="right" style="PADDING-TOP:2px"><b>Operation Status:&nbsp;&nbsp;&nbsp;<asp:Label id="lblStatus" runat="server" style="COLOR:blue">Inactive</asp:Label></b></td>
                            </tr>
                            <tr valign="top">
                                <td class="leftPad" height="13" style="PADDING-TOP:2px"><b>Autoincrement:</b></td>
                                <td height="13" colspan="2">
                                    <asp:dropdownlist id="ddlIncrement" runat="server" CssClass="small">
                                        <asp:ListItem Value="Yes" Selected="True">Yes</asp:ListItem>
                                        <asp:ListItem Value="No">No</asp:ListItem>
                                    </asp:dropdownlist>
                                </td>
                            </tr>
                            <tr valign="top">
                                <td class="leftPad" height="13" style="PADDING-TOP:2px"><b>Tag Type:</b></td>
                                <td height="13" colspan="2">
                                    <asp:dropdownlist id="ddlType" runat="server" CssClass="small">
                                        <asp:ListItem Value="Medium" Selected="True">Medium</asp:ListItem>
                                        <asp:ListItem Value="Case">Case</asp:ListItem>
                                    </asp:dropdownlist>
                                </td>
                            </tr>
                            <tr>
                                <td class="tableRowSpacer" colSpan="3"></td>
                            </tr>
                            <tr valign="top">
                                <td class="leftPad" height="13"><b>Current Tag:</b></td>
                                <td height="13" width="215">
                                    <asp:Label id="lblCurrentSerial" runat="server"></asp:Label>
                                </td>
                            </tr>
                            <tr valign="top">
                                <td class="leftPad" height="13"><b>Current Tag Type:</b></td>
                                <td height="13" width="215">
                                    <asp:Label id="lblCurrentType" runat="server"></asp:Label>
                                </td>
                            </tr>
                            <tr>
                                <td class="tableRowSpacer" colSpan="3"></td>
                            </tr>
                            <tr valign="top">
                                <td class="leftPad" height="13"><b>Last Assigned:</b></td>
                                <td height="13" width="215">
                                    <asp:Label id="lblLastSerial" runat="server"></asp:Label>
                                </td>
                            </tr>
                            <tr valign="top">
                                <td class="leftPad" height="13"><b>Last Tag Type:</b></td>
                                <td height="13" width="215">
                                    <asp:Label id="lblLastType" runat="server"></asp:Label>
                                </td>
                            </tr>
                        </table>
                    </div> <!-- end content //-->
                </div> <!-- end contentArea //-->
            </div> <!-- end contentWrapper //-->
            <!-- BEGIN MESSAGE BOX -->
            <div class="msgBoxSmall" id="msgBoxError" style="DISPLAY:none">
                <h1><%= ProductName %></h1>
                <div class="msgBoxBody"><asp:Label id="lblMessage" runat="server"></asp:Label></div>
                <div class="msgBoxFooter"><input class="formBtn btnSmallTop" type="button" value="OK" onclick="javascript:hideMsgBox('msgBoxError');displayState(1);"></div>
            </div>
            <!-- END MESSAGE BOX -->
            <!-- BEGIN MESSAGE BOX -->
            <div class="msgBoxSmallPlus" id="msgBoxOverwrite" style="DISPLAY:none">
                <h1><%= ProductName %></h1>
                <div class="msgBoxBody">
                    <span id="oType1"></span>&nbsp;serial number&nbsp;<span id="oSerial1"></span>&nbsp;will be replaced with&nbsp;<span id="oType2"></span>&nbsp;serial number&nbsp;<span id="oSerial2"></span>.
                    <br><br>
                    Proceed with overwrite?
                 </div>
                <div class="msgBoxFooter">
                    <input class="formBtn btnSmallTop" type="button" value="Yes" onclick="javascript:hideMsgBox('msgBoxOverwrite');sendInfoToApplet();">
                    &nbsp;
                    <input class="formBtn btnSmallTop" type="button" value="No" onclick="javascript:hideMsgBox('msgBoxOverwrite');displayState(1);">
                </div>
            </div>
            <!-- END MESSAGE BOX -->
        </form>
        <applet codebase="<%= System.Web.HttpRuntime.AppDomainAppVirtualPath %>" code="rfid.applet.RFIDApplet.class" name="RFIDInterface" ARCHIVE=<%= "\"" + System.Web.HttpRuntime.AppDomainAppVirtualPath + "/rfid/applet/OBIDISC4J.jar\""%> VIEWASTEXT width="1" height="1" MAYSCRIPT></applet>
    </body>
</HTML>
