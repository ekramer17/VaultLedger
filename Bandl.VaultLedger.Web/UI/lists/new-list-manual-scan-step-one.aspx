<%@ Page language="c#" Codebehind="new-list-manual-scan-step-one.aspx.cs" AutoEventWireup="false" Inherits="Bandl.VaultLedger.Web.UI.new_list_manual_scan_step_one" %>
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
                    Enter a serial number along with a return date, case number, and description as 
                    desired.&nbsp;&nbsp;When finished, if entering the serial number via keyboard, 
                    click Add; this is done automatically when using a scanner.&nbsp;&nbsp;Repeat 
                    for all media you wish to add to the list, and then click Next.
                </div> <!-- end pageHeader //--><asp:placeholder id="PlaceHolder1" runat="server" EnableViewState="False"></asp:placeholder>
                <!-- Should be visible when tabs are not to be shown -->
                <div class="contentArea" id="contentBorderTop" runat="server"></div>
                <!-- Should be visible only when tabs are to be shown -->
                <div id="tabControls1" runat="server">
                    <div class="tabNavigation threeTabs">
                        <div class="tabs" id="threeTabOneSelected"><A href="#">Manual / Scan</A>
                        </div>
                        <div class="tabs" id="threeTabTwo"><A href="new-list-batch-file-step-one.aspx">Batch 
                                File</A>
                        </div>
                        <div class="tabs" id="threeTabThree"><A href="new-list-tms-file.aspx">TMS Report</A></div>
                    </div>
                </div>
                <div id="tabControls2" runat="server">
                    <div class="tabNavigation fourTabs">
                        <div class="tabs" id="fourTabOneSelected"><A href="#">Manual / Scan</A></div>
                        <div class="tabs" id="fourTabTwo"><A href="new-list-batch-file-step-one.aspx">Batch 
                                File</A></div>
                        <div class="tabs" id="fourTabThree"><A href="new-list-tms-file.aspx">TMS Report</A></div>
                        <div class="tabs" id="fourTabFour"><A href="new-list-rfid-file.aspx">Imation RFID</A></div>
                    </div>
                </div>
                <div class="contentArea" id="contentArea" runat="server">
                    <div id="accountDetail">
                        <div class="stepHeader">Step 1 of 2</div>
                        <hr class="step">
                        <div class="introHeader">Enter media information below:</div>
                        <br>
                        <table cellSpacing="0" cellPadding="0" border="0">
                            <tr vAlign="top">
                                <td width="100" height="23">Serial Number:</td>
                                <td width="290" height="23"><asp:textbox id="txtSerialNum" runat="server" CssClass="large"></asp:textbox></td>
                                <td width="93" height="23">Case Number:</td>
                                <td width="250" height="23"><asp:textbox id="txtCaseNum" runat="server" CssClass="large"></asp:textbox></td>
                            </tr>
                            <tr vAlign="top">
                                <td>Return Date:</td>
                                <td>
                                    <table cellSpacing="0" cellPadding="0" width="270" border="0">
                                        <tr>
                                            <td width="217"><asp:textbox id="txtReturnDate" runat="server" CssClass="calendar"></asp:textbox></td>
                                            <td class="calendarCell" width="53"><A class="iconLink calendarLink" href="javascript:openCalendar('txtReturnDate');"></A></td>
                                        </tr>
                                    </table>
                                </td>
                                <td>Notes:</td>
                                <td class="textArea"><asp:textbox id="txtDescription" runat="server" CssClass="large" TextMode="MultiLine" Rows="5"
                                        Columns="10"></asp:textbox></td>
                            </tr>
                        </table>
                        <br>
                    </div>
                    <div class="contentBoxBottom"><input class="formBtn btnMedium" id="btnAdd" onclick="createRow()" type="button" value="Add"
                            runat="server">
                    </div>
                </div>
                <!-- end contentArea //-->
                <div class="contentArea" id="todaysList" style="DISPLAY: none">
                    <h2 class="contentBoxHeader">Items to be Added</h2>
                    <div class="contentBoxTop" id="findMedia">
                        <table cellSpacing="0" cellPadding="0" border="0">
                            <tr>
                                <td><input class="formBtn btnLargeTop" id="btnDelete" onclick="deleteRows()" type="button"
                                        value="Delete Selected">
                                </td>
                                <td align="right"><asp:label id="lblAccount" runat="server" Font-Bold="False">List Account:</asp:label>&nbsp;&nbsp;&nbsp;&nbsp;
                                    <asp:dropdownlist id="ddlAccount" runat="server"></asp:dropdownlist></td>
                            </tr>
                        </table>
                    </div>
                    <asp:datagrid id="DataGrid1" runat="server" EnableViewState="False" CssClass="detailTable" AutoGenerateColumns="False">
                        <AlternatingItemStyle CssClass="alternate"></AlternatingItemStyle>
                        <HeaderStyle CssClass="header"></HeaderStyle>
                        <Columns>
                            <asp:TemplateColumn>
                                <HeaderStyle CssClass="checkbox"></HeaderStyle>
                                <ItemStyle CssClass="checkbox"></ItemStyle>
                                <HeaderTemplate>
                                    <input id="cbCheckAll" onclick="javascript:toggleAllChecks(this.checked);" type="checkbox"
                                        runat="server" NAME="cbCheckAll" />
                                </HeaderTemplate>
                                <ItemTemplate>
                                    <input id="cbItemChecked" onclick="checkFirst('DataGrid1', 'cbCheckAll', false)" type="checkbox"
                                        runat="server" NAME="cbItemChecked" />
                                </ItemTemplate>
                            </asp:TemplateColumn>
                            <asp:BoundColumn DataField="SerialNo" HeaderText="Serial Number">
                                <HeaderStyle Font-Bold="True"></HeaderStyle>
                            </asp:BoundColumn>
                            <asp:BoundColumn DataField="ReturnDate" HeaderText="Return Date">
                                <HeaderStyle Font-Bold="True"></HeaderStyle>
                            </asp:BoundColumn>
                            <asp:BoundColumn DataField="CaseName" HeaderText="Case Number">
                                <HeaderStyle Font-Bold="True"></HeaderStyle>
                            </asp:BoundColumn>
                            <asp:BoundColumn DataField="Notes" HeaderText="Notes">
                                <HeaderStyle Font-Bold="True"></HeaderStyle>
                            </asp:BoundColumn>
                        </Columns>
                    </asp:datagrid>
                    <div class="contentBoxBottom"><input class="formBtn btnSmall" id="btnNext" type="button" value="Next >" runat="server">&nbsp;
                        <input class="formBtn btnSmall" id="btnCancel" type="button" value="Cancel" name="btnCancel"
                            runat="server">
                    </div> <!-- end contentBoxBottom //--></div> <!-- end contentArea //--></div> <!-- end contentWrapper //-->
            <input id="tableContents" type="hidden" name="tableContents" runat="server"> <input id="maxSerialLength" type="hidden" name="maxSerialLength" runat="server">
            <input id="serialEditFormat" type="hidden" name="serialEditFormat" runat="server">
        </form>
        <script language="javascript">
        //
        // Function: renderTable
        //
        function renderTable()
        {
            var d1 = -1;
            var d2 = -1;
            // Delete all the rows
            deleteTable();    
            // Get the data to render
            var dataString = getObjectById('tableContents').value;
            // Add rows to the table
            while (dataString.length != 0)
            {
               // Get the delimiter position
               d1 = dataString.indexOf('`0;');
               d2 = dataString.indexOf('`1;');
               // Break if neither string found
               if (d1 == -1 && d2 == -1) break;
               // Get the smaller of the two (but must be positive)
               if (d1 == -1 || (d2 != -1 && d2 < d1)) d1 = d2;
               // Use d1 as the position from here on out               
               var rowString = dataString.substring(0, d1 + 2);
               // Serial number
               var serial = rowString.substring(0, rowString.indexOf('`'));
               rowString = rowString.substr(rowString.indexOf('`') + 1);
               // Return date
               var rdate = rowString.substring(0, rowString.indexOf('`'));
               rowString = rowString.substr(rowString.indexOf('`') + 1);
               // Case name
               var caseName = rowString.substring(0, rowString.indexOf('`'));
               rowString = rowString.substr(rowString.indexOf('`') + 1);
               // Note
               var itemNote = rowString.substring(0, rowString.lastIndexOf('`'));
               // Checked status
               var checkStatus = rowString[d1+1];
               // Add the row
               addRow(serial, rdate, caseName, itemNote, checkStatus);
               // Truncate the data string
               dataString = dataString.substring(d1+3);
            }
        }
        //
        // Function: toggleCheck
        //
        function toggleCheck(checkBox)
        {
            // Get the array of cells for the row
            var c = checkBox.parentNode.parentNode.cells;
            // Change the value in the hidden field
            var s = c[1].innerHTML + '`' + c[2].innerHTML + '`' + c[3].innerHTML + '`' + c[4].innerHTML + '`';
            // Get the current value of the table contents control
            var o = getObjectById('tableContents')
            // Adjust the check mark value
            if (checkBox.checked)
               o.value = o.value.replace(s + '0', s + '1');
            else            
               o.value = o.value.replace(s + '1', s + '0');
        }
        //
        // Function: toggleAllChecks
        //
        function toggleAllChecks(checkStatus)
        {
            var theTable = getObjectById('DataGrid1');
            var checkBoxes = theTable.getElementsByTagName('input');
            // Check all the checkboxes                               
            for (i = 0; i < checkBoxes.length; i++)
            {
               checkBoxes[i].checked = checkStatus;
               if (i != 0) toggleCheck(checkBoxes[i]);
            }
        }
        //
        // Function: deleteTable
        //
        function deleteTable()
        {
            var theTable = getObjectById('DataGrid1');
            // Uncheck the header row checkbox
            theTable.getElementsByTagName('input')[0].checked = false;
            // Delete all rows but last row
            for (i = theTable.rows.length-1; i > 0; i -= 1)
               theTable.tBodies[0].removeChild(theTable.tBodies[0].rows[i]);
            // Make the section invisible
            getObjectById('todaysList').style.display = 'none';
        }
        //
        // Function: deleteRows
        //
        function deleteRows()
        {
            var o = getObjectById('tableContents')
            var theTable = getObjectById('DataGrid1');
            var tableRow = theTable.rows[theTable.rows.length-1];     
            // Uncheck the header row checkbox
            theTable.getElementsByTagName('input')[0].checked = false;
            // Delete any checked rows
            for (i = theTable.rows.length-1; i > 0; i -= 1)
            {
               // Get the row
               tableRow = theTable.rows[i];
               // If it isn't checked, leave it alone
               if (!tableRow.getElementsByTagName('input')[0].checked)
               {
                  tableRow = tableRow.previousSibling;
               }
               else
               {
                  var serial = tableRow.cells[1].innerHTML;
                  var rdate = tableRow.cells[2].innerHTML;
                  var caseName = tableRow.cells[3].innerHTML;
                  var itemNote = tableRow.cells[4].innerHTML;
                  // Delete the row
                  tableRow.parentNode.removeChild(tableRow);
                  // Remove the string from the hidden field value
                  var s = serial + '`' + rdate + '`' + caseName + '`' + itemNote + '`1;'
                  o.value = o.value.replace(s, '');
               }
            }
            // If only the header row is left, make the table invisible.  Otherwise, renumerate the checkboxes.
            if (theTable.rows.length == 1)
            {
               getObjectById('todaysList').style.display = 'none';
               getObjectById('txtSerialNum').select();
            }
            else
            {
               for (i = 1; i < theTable.rows.length; i += 1)
               {
                   var checkBox = theTable.rows[i].cells[0].firstChild;
                   checkBox.name = 'DataGrid1:_ctl' + (i+1).toString() + ':cbItemChecked'
                   checkBox.id = 'DataGrid1__ctl' + (i+1).toString() + '_cbItemChecked'
                   theTable.rows[i].className = i % 2 == 1 ? '' : 'alternate';
               }
            }
        }
        //
        // Function: createRow
        //
        function createRow()
        {
            var serial = getObjectById('txtSerialNum').value;
            var caseName = getObjectById('txtCaseNum').value;
            var rdate = getObjectById('txtReturnDate').value;
            var itemNote = getObjectById('txtDescription').value;
            // Make sure that the return date is valid
            if (rdate.length != 0)
                if (parseDate(rdate) == null)
                    alert('Return date is not valid');
            // Add the row to the table.  Append if successful
            if (true == addRow(serial, rdate, caseName, itemNote, 0))
            {
                var s = serial + '`' + rdate + '`' + caseName + '`' + itemNote + '`0;';
                getObjectById('tableContents').value += s;
            }
        }
        //
        // Function: addRow
        //
        function addRow(serial, rdate, caseName, itemNote, checkStatus)
        {
            var theTable = getObjectById('DataGrid1');
            // Make sure the serial number has not already been submitted
            for (i = 1; i < theTable.rows.length; i += 1)
            {
                if (theTable.rows[i].cells[1].innerHTML == serial)
                {
                    // Replace the string in the table contents control
                    var s = serial + '`';
                    var o = getObjectById('tableContents');
                    s += theTable.rows[i].cells[2].innerHTML + '`';
                    s += theTable.rows[i].cells[3].innerHTML + '`';
                    s += theTable.rows[i].cells[4].innerHTML + '`';
                    o.value = o.value.replace(s, serial + '`' + rdate + '`' + caseName + '`' + itemNote + '`');
                    // Replace the row values
                    theTable.rows[i].cells[2].innerHTML = rdate;
                    theTable.rows[i].cells[3].innerHTML = caseName;
                    theTable.rows[i].cells[4].innerHTML = itemNote;
                    getObjectById('txtSerialNum').select();
                    return false;
                }
            }
            // Create the new row         
            var rowNo = 0;
            var newRow = document.createElement('tr');
            // Create the three cells for the row
            var cell1 = document.createElement('td');
            var cell2 = document.createElement('td');
            var cell3 = document.createElement('td');
            var cell4 = document.createElement('td');
            var cell5 = document.createElement('td');
            // Append the new row            
            rowNo = theTable.rows.length;
            theTable.tBodies[0].appendChild(newRow);
            // Alternate style?
            if (rowNo % 2 == 0) newRow.className = 'alternate';
            // Create the checkbox
            var checkBox = document.createElement('input');
            checkBox.type = 'checkbox';
            checkBox.id = 'DataGrid1__ctl' + (rowNo+1).toString() + '_cbItemChecked'
            checkBox.name = 'DataGrid1:_ctl' + (rowNo+1).toString() + ':cbItemChecked'
            checkBox.onclick = function (e) { checkFirst('DataGrid1', 'cbCheckAll', false); toggleCheck(this); };
            cell1.appendChild(checkBox);
            // Serial number
            cell2.appendChild(document.createTextNode(serial));
            // Return date
            cell3.appendChild(document.createTextNode(rdate));
            // Case name
            cell4.appendChild(document.createTextNode(caseName));
            // Notes
            cell5.appendChild(document.createTextNode(itemNote));
            // Append the cells to the row
            newRow.appendChild(cell1);
            newRow.appendChild(cell2);
            newRow.appendChild(cell3);
            newRow.appendChild(cell4);
            newRow.appendChild(cell5);
            // Check the checkbox if check status is 1
            cell1.firstChild.checked = checkStatus == '1';
            // Make the section visible
            getObjectById('todaysList').style.display = 'block';
            // Select the serial number box
            getObjectById('txtSerialNum').select();
            // Return true
            return true;
        }
        //
        // Function: addRowRfid -- adds rows via the rfid applet
        //
        function reportRfidTagInfo(appletString)
        {
            var caseName = '';
            var maxSerialLen = 0;
            var editFormatType = 0;
            var tapeSerials = new Array();
            // if empty string then just return
            if (appletString.length == 0) return;
            var rdate = getObjectById('txtReturnDate').value;
            var itemNote = getObjectById('txtDescription').value;
            // Separate the string into entries
            var rfidStringArray = appletString.split(';');
            // Get the characters to strip
            if (getObjectById('maxSerialLength').value.length != 0)
                maxSerialLen = parseInt(getObjectById('maxSerialLength').value);
            // Get the format editting type
            editFormatType = parseInt(getObjectById('serialEditFormat').value);
            // Add the entries to the serial number array.  We have to run through
            // the whole string to make sure that we get the case number if there
            // is one.  After running through the whole string, we can add rows.
            for (k = 0; k < rfidStringArray.length; k += 1)
            {
                if (rfidStringArray[k].length != 0)
                {
                    var fieldArray = rfidStringArray[k].split('&');
                    // Are we getting the case name or a serial number?  If the
                    // second parameter is '1' then we have a case name.
                    if (fieldArray[1] == '1')
                    {
                        caseName = fieldArray[0];
                    }
                    else
                    {
                        var serialNo = trim(fieldArray[0]);
                        // Format the serial number?
                        if (editFormatType == 1)
                        {
                            serialNo = serialNo.toUpperCase();
                        }
                        else if (editFormatType == 2)
                        {
                            serialNo = recallSerial(serialNo, true);
                        }
                        // Strip characters from the serial number?
                        if (serialNo.length > maxSerialLen)
                        {
                            serialNo = serialNo.substr(0, maxSerialLen);
                        }
                        // Add to the serial number array
                        if (serialNo.length != 0) 
                        {
                            tapeSerials[tapeSerials.length] = serialNo;
                        }
                    }
                }
            }
            // Now add the rows
            for (k = 0; k < tapeSerials.length; k++)
            {
                if (true == addRow(tapeSerials[k], rdate, caseName, itemNote, 0))
                {
                    var s = tapeSerials[k] + '`' + rdate + '`' + caseName + '`' + itemNote + '`0;';
                    getObjectById('tableContents').value += s;
                }
            }
        }
        // Render the table
        renderTable();
        </script>
        <!--        <applet codebase="<%= System.Web.HttpRuntime.AppDomainAppVirtualPath %>" code="rfid.applet.RFIDApplet.class" ARCHIVE=<%= "\"" + System.Web.HttpRuntime.AppDomainAppVirtualPath + "/rfid/applet/OBIDISC4J.jar\""%> VIEWASTEXT width="1" height="1" MAYSCRIPT></applet> -->
    </body>
</HTML>
