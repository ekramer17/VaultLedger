<%@ Page language="c#" Codebehind="new-list-rfid-file.aspx.cs" AutoEventWireup="false" Inherits="Bandl.VaultLedger.Web.UI.new_list_rfid_file" %>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<HTML>
  <HEAD>
        <META http-equiv=Content-Type content="text/html; charset=iso-8859-1">
        <meta content="Microsoft Visual Studio .NET 7.1" name=GENERATOR>
        <meta content=C# name=CODE_LANGUAGE>
        <meta content=JavaScript name=vs_defaultClientScript>
        <meta content=http://schemas.microsoft.com/intellisense/ie5 name=vs_targetSchema>
        <!--#include file = "../includes/baseHead.inc"-->
        <script type="text/javascript">
        var maxSerial = 100; // maximum serial length
        var formatType = 1; // serial number editing format code
        var readyState = false;
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
                    // Decrement from total items
                    var x = getObjectById('totalItems');
                    x.innerHTML = (parseInt(x.innerHTML) - 1).toString();
                }
            }
            // If only the header row is left, make the table invisible.  Otherwise, renumerate the checkboxes.
            if (theTable.rows.length == 1)
            {
                getObjectById('todaysList').style.display = 'none';
                getObjectById('txtReturnDate').select();
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
		    var serial = '';
		    var caseName  = '';
            var theTable = getObjectById('DataGrid1');
            var rdate = getObjectById('txtReturnDate').value;
            var itemNote = getObjectById('txtDescription').value;
            var checkBoxes = theTable.getElementsByTagName('input');
            // Make sure that the return date is valid
            if (rdate.length != 0)
                if (parseDate(rdate) == null)
                    alert('Return date is not valid');
            // Create the row        
            for (i = 0; i < checkBoxes.length; i++)
            {
			    if(checkBoxes[i].checked == true)
			    {
				    serial = theTable.rows[i].cells[1].innerHTML;
				    caseName = theTable.rows[i].cells[3].innerHTML;
				    if (true == addRow(serial, rdate, caseName, itemNote, 0))
				    {
					    var s = serial + '`' + rdate + '`' + caseName + '`' + itemNote + '`0;';
					    getObjectById('tableContents').value += s;
				    }
			    }
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
                    var s = serial + '`';
                    var o = getObjectById('tableContents');
                    // Create the string to replace
                    s += theTable.rows[i].cells[2].innerHTML + '`';
                    s += theTable.rows[i].cells[3].innerHTML + '`';
                    s += theTable.rows[i].cells[4].innerHTML + '`';
                    // If the case name is an empty string, leave it alone
                    caseName = caseName.length != 0 ? caseName : theTable.rows[i].cells[3].innerHTML;
                    // Replace the string
                    o.value = o.value.replace(s, serial + '`' + rdate + '`' + caseName + '`' + itemNote + '`');
                    // Replace the row values
                    theTable.rows[i].cells[2].innerHTML = rdate;
                    theTable.rows[i].cells[3].innerHTML = caseName;
                    theTable.rows[i].cells[4].innerHTML = itemNote;
                    getObjectById('txtDescription').select();
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
            getObjectById('txtReturnDate').select();
            // Return true
            return true;
        }
        //
        // Function: addRowRfid -- adds rows via the rfid applet
        //
        function reportRfidTagInfo(appletString)
        {
            var caseName = '';
            var rowsAdded = 0;
            var numScanned = 0;
            var tapeSerials = new Array();
            // Necessary for Firefox to realize that appletString is a string        
            appletString = appletString + '';
            // if empty string then just return
            if (appletString.length == 0) return;
            // if not ready for scan then just return
            if (readyState == false) return;
            // Get the return date and the notes field
            var rdate = getObjectById('txtReturnDate').value;
            var itemNote = getObjectById('txtDescription').value;
            // Separate the string into entries
            var rfidStringArray = appletString.split(';');
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
                        // Get the serial number
                        var serialNo = trim(fieldArray[0]);
                        // Format the serial number?
                        if (formatType == 1)
                        {
                            serialNo = serialNo.toUpperCase();
                        }
                        else if (formatType == 2)
                        {
                            serialNo = recallSerial(serialNo, true);
                        }
                        // Strip characters from the serial number?
                        if (serialNo.length > maxSerial)
                        {
                            serialNo = serialNo.substr(0, maxSerial);
                        }
                        // Add to the serial number array
                        if (serialNo.length != 0) 
                        {
                            tapeSerials[tapeSerials.length] = serialNo;
                            readyState = false;
                            numScanned += 1;
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
					rowsAdded += 1;
                }
            }
            // Really a duplicate call here, but necessary b/c if tapes are on pad when page
            // is first brought up, table may be rendered before all rows are added.  Not
			// lovely, but a necessary evil.  Really not worth the rewrite at this time.
            if (rowsAdded != 0)
            {
                renderTable();
            }
            // If the lastScan is not zero, update the total items and last scan fields
            if (numScanned != 0)
            {
                readyState = true;
                getObjectById('lastScan').innerHTML = numScanned.toString();
                // Get the number of rows in the table.  This is the total number of items.
                getObjectById('totalItems').innerHTML = (getObjectById('DataGrid1').rows.length - 1).toString();
                // Check the number scanned
                readyState = checkNumber(numScanned);
            }
            else
            {
                readyState = true;
            }
        }
        //
        // Function: declareReady
        //
        // This function is called by the applet.  On this page it serves no purpose, but
        // it must be present in order to avoid a browser error.
        //
        function declareReady(messageText)
        {
            ;
        }
        //
        // function: checkNumber - checks number of media scanned on last scan
        //
        function checkNumber(number)
        {
            var val = getObjectById('txtExpected').value;
            if (!isNaN(parseInt(val)) && number != parseInt(val) && parseInt(val) != 0)
            {
                getObjectById('mediaScanned').innerHTML = number.toString() + (number != 1 ? ' media' : ' medium');
                getObjectById('mediaExpected').innerHTML = val + (parseInt(val) != 1 ? ' media' : ' medium');
                showMsgBox('msgBoxExpected');
                return false;
            }
            else
            {
                return true;
            }
        }
        // function: doStartup
        //
        function doStartup(action)
        {
            // If we have missing tapes that were marked as found, display them one at a time
            if (getObjectById('missingTapes').value.length != 0)
            {
                // Get the missing tapes object
                var m = getObjectById('missingTapes');
                // Set the message box serial number
                getObjectById('foundTape').innerHTML = m.value.substr(0,m.value.indexOf(';'));
                // Show the message box
                showMsgBox('msgBoxFoundTape');
                // Remove the serial number from the front of the missing control
                if (m.value.indexOf(';') == m.value.length - 1)
                {
                    m.value = '';
                }
                else
                {
                    m.value = m.value.substr(m.value.indexOf(';') + 1);
                }
            }
            else if (action == 1)
            {
                getObjectById('Form1').submit();
            }
            else
            {
                readyState = true;
            }
        }
        //
        // Function: assignDate - assigns return date and notes to checked items
        //
        function assignDate()
        {
            var o = getObjectById('tableContents')
            var theTable = getObjectById('DataGrid1');
            var tableRow = theTable.rows[theTable.rows.length-1];     
            // Uncheck the header row checkbox
            theTable.getElementsByTagName('input')[0].checked = false;
            // Get the return date and notes
            var rdate = getObjectById('txtReturnDate').value;
            var itemNote = getObjectById('txtDescription').value;
            // Assign data to checked rows
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
                    // Get the original data
                    var serial = tableRow.cells[1].innerHTML;
                    var oldDate = tableRow.cells[2].innerHTML;
                    var caseName = tableRow.cells[3].innerHTML;
                    var oldNote = tableRow.cells[4].innerHTML;
                    // Assign the return date and note to the row
                    tableRow.cells[2].innerHTML = rdate;
                    tableRow.cells[4].innerHTML = itemNote;
                    // Replace the string in the tableContents hidden field value
                    var s1 = serial + '`' + oldDate + '`' + caseName + '`' + oldNote + '`1;'
                    var s2 = serial + '`' + rdate + '`' + caseName + '`' + itemNote + '`1;'
                    o.value = o.value.replace(s1, s2);
                }
            }
        }
        //
        // Function: handleGo -- handles the Go button
        //
        function handleGo()
        {
            switch(getObjectById('ddlSelectAction').selectedIndex)
            {
                case 1:
                    deleteRows();
                    break;
                case 2:
                    assignDate();
                    break;
                default:
                    break;
            }
        }
        //
        // Function: statusReady -- handles the readyState variable
        //
        function statusReady(r)
        {
            readyState = r != 1 ? false : true;
        }
        </script>
    </HEAD>
    <body>
    <!--#include file = "../includes/baseBody.inc"-->
    <form id="Form1" method="post" runat="server">
        <div class="contentWrapper">
            <div class="pageHeader">
                <h1>New Shipping List&nbsp;&nbsp;-&nbsp;&nbsp;Step 1</h1>To 
                create a new list through RFID, begin scanning media and/or cases over the pad. 
                Use the return date and notes field to assign appropriate return dates and notes 
                to subsequent scans.
            </div> <!-- end pageHeader //-->
            <asp:placeholder id="PlaceHolder1" runat="server" EnableViewState="False"></asp:placeholder>
            <div class="tabNavigation fourTabs">
                <div class="tabs" id="fourTabOne"><A href="new-list-manual-scan-step-one.aspx" >Manual / Scan</A></div>
                <div class="tabs" id="fourTabTwo"><A href="new-list-batch-file-step-one.aspx" >Batch File</A></div>
                <div class="tabs" id="fourTabThree"><A href="new-list-tms-file.aspx" >TMS Report</A></div>
                <div class="tabs" id="fourTabFourSelected"><A href="#" >Imation RFID</A></div>
            </div>
            <div class="contentArea">
                <div id="accountDetail">
                    <div class="introHeader">Step 1 of 2</div>
                        <hr class="step">
                        <div class="introHeader">Enter media information below:</div>
                        <br>
                        <asp:Table id="Table1" runat="server" style="width:97%">
                            <asp:TableRow>
                                <asp:TableCell VerticalAlign="Top" style="width:140px">
                                    <asp:Table id="Table2" runat="server">
                                        <asp:TableRow VerticalAlign="Top" style="height:25px">
                                            <asp:TableCell>Return Date:</asp:TableCell>
                                        </asp:TableRow>
                                        <asp:TableRow VerticalAlign="Top">
                                            <asp:TableCell>Expected Media Per Scan:</asp:TableCell>
                                        </asp:TableRow>
                                    </asp:Table>
                                </asp:TableCell>
                                <asp:TableCell VerticalAlign="Top" HorizontalAlign="Left" style="width:126px">
                                    <asp:Table id="Table3" runat="server">
                                        <asp:TableRow VerticalAlign="Top" style="height:25px">
                                            <asp:TableCell>
                                                <asp:textbox id="txtReturnDate" tabIndex="1" runat="server" ></asp:textbox>
                                            </asp:TableCell>
                                        </asp:TableRow>
                                        <asp:TableRow VerticalAlign="Top" style="height:23px">
                                            <asp:TableCell>
                                                <asp:textbox id="txtExpected" MaxLength="3" tabIndex="3" runat="server"></asp:textbox>
                                            </asp:TableCell>
                                        </asp:TableRow>
                                    </asp:Table>
                                </asp:TableCell>
                                <asp:TableCell CssClass="calendarCell" HorizontalAlign="Left" style="width:55px">
                                    <A class="iconLink calendarLink" tabIndex="2" href="javascript:openCalendar('txtReturnDate');"></A>
                                </asp:TableCell>
                                <asp:TableCell VerticalAlign="Top" HorizontalAlign="Left" style="width:45px">
                                    Notes:
                                </asp:TableCell>
                                <asp:TableCell VerticalAlign="Top">
                                    <asp:textbox id="txtDescription" tabIndex="4" runat="server" TextMode="MultiLine" style="width:345px;height:40px"></asp:textbox>
                                </asp:TableCell>
                            </asp:TableRow>
                        </asp:Table>
                        <br>
                    </div>
                </div>
                <div class="contentArea" id="todaysList" style="DISPLAY: none">
                    <h2 class="contentBoxHeader">Items To Be Added</h2>
                    <div class="contentBoxTop" id="findMedia">
                        <table width="100%">
                            <tr>
                                <td style="WIDTH:140px">
                                    <asp:dropdownlist id="ddlSelectAction" runat="server" CssClass="selectAction">
                                        <asp:ListItem Value="-Choose an Action-">-Choose an Action-</asp:ListItem>
                                        <asp:ListItem Value="delete">Delete Selected</asp:ListItem>
                                        <asp:ListItem Value="assign">Assign Date and Notes</asp:ListItem>
                                    </asp:dropdownlist>
                                </td>
                                <td style="WIDTH:40px">
                                    &nbsp;<input class="formBtn btnSmallGo" id="btnGo" onclick="handleGo()" type="button" value="Go">
                                </td>
                                <td align="right">
                                    <b>Last Scan:&nbsp;&nbsp;<span id="lastScan">0</span>&nbsp;&nbsp;&nbsp;&nbsp;Total Items:&nbsp;&nbsp;<span id="totalItems">0</span></b>
                                </td>
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
                    <div class="contentBoxBottom">
                        <input class="formBtn btnSmall" id="btnNext" type="button" value="Next >" runat="server" NAME="btnNext"> 
                        &nbsp;
                        <input class="formBtn btnSmall" id="btnCancel" type="button" value="Cancel" runat="server" NAME="btnCancel"> 
                    </div>
                </div> <!-- end contentArea //-->
            </div> <!-- end contentWrapper //-->
            <!-- BEGIN FOUND TAPE MESSAGE BOX -->
            <div class="msgBoxSmall" id="msgBoxFoundTape" style="DISPLAY: none">
                <h1><%= ProductName %></h1>
                <div class="msgBoxBody">Medium&nbsp;<span id="foundTape"></span>&nbsp;was missing and has been marked as found.</div>
                <div class="msgBoxFooter">
                    <input class="formBtn btnSmallTop" type="button" value="OK" onclick="hideMsgBox('msgBoxFoundTape');doStartup(1);">
                </div>
            </div>
            <!-- END FOUND TAPE MESSAGE BOX -->
            <!-- BEGIN SCAN COUNT ERROR MESSAGE BOX -->
            <div class="msgBoxSmall" id="msgBoxExpected" style="DISPLAY: none">
                <h1><%= ProductName %></h1>
                <div class="msgBoxBody">
                    Only&nbsp;<span id="mediaScanned"></span>&nbsp;out of an expected&nbsp;<span id="mediaExpected"></span>&nbsp;were scanned.
                </div>
                <div class="msgBoxFooter">
                    <input class="formBtn btnSmallTop" type="button" value="OK" onclick="hideMsgBox('msgBoxExpected');statusReady(1);"/>
                </div>
            </div>
            <!-- END SCAN COUNT ERROR MESSAGE BOX -->
            <!-- Hidden fields -->
            <input id="tableContents" type="hidden" NAME="tableContents" runat="server">
            <input id="missingTapes" type="hidden" NAME="missingTapes" runat="server">
            <script language='javascript'>
		    renderTable();
            </script>
        </form>
        <applet codebase="<%= System.Web.HttpRuntime.AppDomainAppVirtualPath %>" code="rfid.applet.RFIDApplet.class" ARCHIVE=<%= "\"" + System.Web.HttpRuntime.AppDomainAppVirtualPath + "/rfid/applet/OBIDISC4J.jar\""%> VIEWASTEXT width="1" height="1" MAYSCRIPT></applet>
    </body>
</HTML>
