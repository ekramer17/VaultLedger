<%@ Page language="c#" Codebehind="receiving-list-reconcile-rfid.aspx.cs" AutoEventWireup="false" Inherits="Bandl.VaultLedger.Web.UI.receiving_list_reconcile_rfid" %>
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
        var tapes1 = new Array();  // Tapes of serial numbers in last scan currently in one of the four control (verified, unverified, verifyThese, unrecognized)
        var tapes2 = new Array();  // Tapes of serial numbers not currently in any of the four controls
        var caseName = '';  // Name of case in last scan
        var index = 0;  // index used for counters in various places
        var oSwitch = 0;  // Control in which case is being switched (1 - verified, 2 - unverified, 3 - verifyThese, 4 - unrecognized
        var onStartup = 0;  // 0 - do nothing extraordinary, 1 - show fully verified box, 2 - show deleted list box, 3 - redirect to detail page
        var readyState = false; // whether or not the page is ready for the next scan; scans will be ignored when false
        var action1 = 3;  // flags for doTapes1() : 1 - display switches, 2 - display removals, 4 - autoswitch, 8 - autoremove
        var verifyStage = 2; // verification stage
        var maxSerial = 100; // maximum serial length
        var formatType = 1; // serial number editing format code
        var manual = false; // whether or not the manual verify button was clicked
        //
        // function: turnPage
        //
        function turnPage(type)
        {
            var x = getObjectById('pageValues').value;
            var y = x.substring(x.indexOf(';'));
            // Make sure type is an acceptable value
            if (type < 0 || type > 4) return;
            // Adjust the page number
            if (type == 1)
            {
                getObjectById('pageValues').value = '1' + y;
            }
            else if (type == 2)
            {
                var n = parseInt(x.substring(0, x.indexOf(';')));
                getObjectById('pageValues').value = (n-1).toString() + y;
            }
            else if (type == 3)
            {
                var n = parseInt(x.substring(0, x.indexOf(';')));
                getObjectById('pageValues').value = (n+1).toString() + y;
            }
            else if (type == 4)
            {
                var p = getObjectById('lblPage').innerHTML;
                var n = p.substring(p.lastIndexOf(' ') + 1);
                getObjectById('pageValues').value = n.toString() + y;
            }
            // Render the table
            renderTable();
        }        
        //
        // function: jumpPage
        //
        function jumpPage()
        {
            var p = getObjectById('txtPageGoto').value;
            var x = getObjectById('pageValues').value;
            var y = x.substring(x.indexOf(';'));
            // Set the page values
            getObjectById('txtPageGoto').value = '';
            getObjectById('pageValues').value = p + y;
            // Render the table
            renderTable();
        }
        //
        // Function: deleteTable
        //
        function deleteTable()
        {
            var theTable = getObjectById('DataGrid1');
            // Uncheck the header row checkbox
            theTable.getElementsByTagName('input')[0].checked = false;
            // Delete all rows
            for (i = theTable.rows.length-1; i > 0; i -= 1)
               theTable.tBodies[0].removeChild(theTable.tBodies[0].rows[i]);
        }
        //
        // function: getNumberOfUnverifiedTapes()
        //
        function getNumberOfUnverifiedTapes()
        {
            var c = 0;
            var s = getObjectById('unverifiedTapes').value;
            while (s.indexOf(';') != -1)
            {
                c += 1;
                s = s.substring(s.indexOf(';') + 1, s.length);
            }
            return c;
        }
        //
        // Function: createContents
        //
        function createContents()
        {
            var c = '';
            var p1 = -1;
            var p2 = -1;
            var x = getObjectById('pageValues').value;
            var tc = ';' + getObjectById('tableContents').value;
            var pn = parseInt(x.substring(0, x.indexOf(';')));
            var pp = parseInt(x.substring(x.indexOf(';') + 1));
            var ds = getObjectById('unverifiedTapes').value;
            var ti = getNumberOfUnverifiedTapes();
            // If there are no unverified tapes, do nothing
            if (ds.length == 0) return;
            // Get the page number
            if (((pn - 1) * pp) + 1 > ti)
                pn = Math.floor(ti % pp != 0 ? (ti / pp) + 1 : ti / pp);
            // Skip to the first element
            for (i = 0; i < ((pn - 1) * pp); i++)
                p1 = ds.indexOf(';', p1 + 1);
            // Start placing serial numbers
            for (i = 0; i < pp; i++)
            {
                p2 = ds.indexOf(';', p1 + 1);
                if (p2 == -1) break;
                // Get the check status.  If it was checked in old 
                // contents, check it here.  Otherwise, don't check.
                var serialNo = ds.substring(p1 + 1, p2);
                serialNo += tc.indexOf(';' + serialNo + '`1;') != -1 ? '`1;' : '`0;';
                c += serialNo;
                // Move p1 up to current p2 position
                p1 = p2;
            }
            // Place the contents in the hidden variable
            getObjectById('tableContents').value = c;
            // Set the page number and label
            var pc = Math.floor(ti % pp != 0 ? (ti / pp) + 1 : ti / pp);
            getObjectById('pageValues').value = pn.toString() + ';' + pp.toString();
            getObjectById('lblPage').innerHTML = 'Page ' + pn.toString() + ' of ' + pc.toString();
            getObjectById('lnkPageFirst').disabled = (pn == 1);
            getObjectById('lnkPagePrev').disabled = (pn == 1);
            getObjectById('lnkPageNext').disabled = (pn == pc);
            getObjectById('lnkPageLast').disabled = (pn == pc);
        }        
        //
        // Function: renderTable
        //
        function renderTable()
        {
            var d1 = -1;
            var d2 = -1;
            // Delete all the rows
            deleteTable();    
            // Create the table contents
            createContents();
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
               // Use d1 as the position just before the check status flag
               var rowString = dataString.substring(0, d1 + 2);
               var p1 = rowString.indexOf('`');
               var p2 = rowString.lastIndexOf('`');
               // Serial number and case name
               var serial = rowString.substring(0, p1);
               var caseSerial = rowString.substring(p1 + 1, p2);
               // Checked status
               var checkStatus = rowString.substring(p2+1);
               // Add the row
               addRow(serial, caseSerial, checkStatus);
               // Truncate the data string
               dataString = dataString.substring(p2+3);
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
            var s = c[1].innerHTML + '`' + c[2].innerHTML + '`';
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
        // Function: addRow
        //
        function addRow(serial, caseSerial, checkStatus)
        {
            var theTable = getObjectById('DataGrid1');
            // Create the new row         
            var rowNo = 0;
            var newRow = document.createElement('tr');
            // Create the three cells for the row
            var cell1 = document.createElement('td');
            var cell2 = document.createElement('td');
            var cell3 = document.createElement('td');
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
            // Case number
            cell3.appendChild(document.createTextNode(caseSerial));
            // Append the cells to the row
            newRow.appendChild(cell1);
            newRow.appendChild(cell2);
            newRow.appendChild(cell3);
            // Check the checkbox if check status is 1
            cell1.firstChild.checked = checkStatus == '1';
            // Return true
            return true;
        }
        //
        // Function: reportRfidTagInfo -- gets information from the applet
        //
        function reportRfidTagInfo(appletString)
        {
            // Necessary for Firefox to realize that appletString is a string        
            appletString = appletString + '';
            // If the ready state is false or no applet string then just return
            if (readyState != false && appletString.length != 0)
            {
                // Set the ready state to false
                readyState = false;
                // Set the manual flag to false
                manual = false;
                // Reset the global objects
                index = 0;
                action1 = 3;    // display case switches, display case removals
                caseName = '';
                tapes1 = new Array();
                tapes2 = new Array();
                // Collect the rfid info
                collectRfidInfo(appletString);
                // If we have no tapes, just set the ready status to true.  If we have
                // a case, evaluate it; otherwise go straight to evaluating tapes.
                if (tapes1.length == 0 && tapes2.length == 0)
                {
                    readyState = true;
                }
                else if (checkNumber(tapes1.length + tapes2.length) == true)
                {
                    doCase();
                }
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
            // Check the number scanned against the number expected
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
        //
        // Function: collectRfidInfo -- parses the information from the applet
        //
        function collectRfidInfo(appletString)
        {
            // Declare locals
            var k = -1;
            var tapeSerials = new Array();
            // Separate the string into entries
            var stringArray = appletString.split(';');
            // Add the entries to the serial number array.  We have to run through
            // the whole string to make sure that we get the case number if there
            // is one.  After running through the whole string, we can add rows.
            for (k = 0; k < stringArray.length; k += 1)
            {
                if (stringArray[k].length != 0)
                {
                    var fieldArray = stringArray[k].split('&');
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
                        if (serialNo.length > maxSerial && manual == false)
                        {
                            serialNo = serialNo.substr(0, maxSerial);
                        }
                        // Add to the serial number array
                        if (serialNo.length != 0) 
                        {
                            tapeSerials[tapeSerials.length] = serialNo;
                        }
                    }
                }
            }
            // Separate into recognized and unrecognized tapes
            var v1 = ';' + getObjectById('verifiedTapes').value;
            var v2 = ';' + getObjectById('unverifiedTapes').value;
            var v3 = ';' + getObjectById('verifyThese').value;
            var v4 = ';' + getObjectById('unrecognizedTapes').value;
            // Run through the tapes
            for (k = 0; k < tapeSerials.length; k += 1)
            {
                var testString = ';' + tapeSerials[k] + '`';
                // Recognized or unrecognized?
                if (v1.indexOf(testString) != -1 || v2.indexOf(testString) != -1 || v3.indexOf(testString) != -1 || v4.indexOf(testString) != -1)
                {
                    tapes1[tapes1.length] = tapeSerials[k];
                }
                else
                {
                    tapes2[tapes2.length] = tapeSerials[k];
                }
            }
        }                
        //
        // Function: doManual -- called when the manual verification button is clicked
        //
        function doManual()
        {
            // Get the serial number in the textbox
            var serialNo = getObjectById('txtSerialNo').value;
            // If the ready state is false or no applet string then just return
            if (readyState != false && serialNo.length != 0)
            {
                // Set the ready state to false
                readyState = false;
                // Set the manual flag to true
                manual = true;
                // Reset the global objects
                index = 0;
                action1 = 3;    // display case switches, display case removals
                caseName = '';
                tapes1 = new Array();
                tapes2 = new Array();
                // Collect the rfid info
                collectRfidInfo(serialNo + '&0&UNIQUEID');
                // Perform tape handling actions
                doTapes1(action1);
            }
            else
            {
                focusSelect('txtSerialNo');
            }
        }
        //
        // Function: doCase -- takes action based on recognition and status of case
        //
        function doCase()
        {
            // If we have no case name, go right to the tapes
            if (caseName.length == 0)
            {
                doTapes1(action1);
            }
            else
            {
                // Add a semicolon to the front of the control value to that the first element
                // can be compared against.  For example, if the first case is ABC123, and the case
                // we are testing for is C123, then we would get a match if we didn't prepend a semicolon.
                var semiString = ";" + getObjectById('unrecognizedCases').value;
                // Check to see if the case is already in the unrecognized control
                if ((pos1 = semiString.indexOf(";" + caseName + "`")) != -1)
                {
                    var caseString = semiString.substr(pos1 + 1, semiString.indexOf(';', pos1 + 1) - pos1 - 1);
                    // If it is being ignored, set the ready state to true.  Otherwise, go 
                    // ahead and process the tapes for possible case switches.
                    if (caseString.substr(caseString.lastIndexOf('`') + 1, 1) == '0')
                    {
                        readyState = true;
                    }
                    else
                    {
                        doTapes1(action1);
                    }
                }
                else
                {
                    var v1 = getObjectById('verifiedTapes').value;
                    var v2 = getObjectById('unverifiedTapes').value;
                    var v3 = getObjectById('verifyThese').value;
                    var v4 = getObjectById('unrecognizedTapes').value;
                    var testString = "`" + caseName + ";";
                    // If the tape is in presently in any of the relevant controls, process tapes.  Otherwise prompt user as unknown case.
                    if (v1.indexOf(testString) != -1 || v2.indexOf(testString) != -1 || v3.indexOf(testString) != -1)
                    {
                        doTapes1(action1);
                    }
                    else if (v4.indexOf("`" + caseName + "`") != -1)    // test string ends with ` rather than ; in unrecognized control
                    {
                        doTapes1(action1);
                    }
                    else
                    {
                        getObjectById('unrecognizedCase').innerHTML = caseName;
                        showMsgBox('msgBoxUnrecognizedCase');
                    }
                }
            }
        }
        //
        // function: doTapes1 (process the tapes found in the controls)
        //
        function doTapes1(action)   // display case switch message where appropriate or not 0 - switch but do not display, 1 - display for switch, 2 - do not switch
        {
            // Set the global action
            action1 = action;
            // If no more tapes, go to doTapes2
            if (index >= tapes1.length)
            {
                index = 0;
                doTapes2(0);
            }
            else
            {
                var pos1 = -1;
                var pos2 = -1;
                var caseSerial = '';
                var tapeString = '';
                var serialNo = tapes1[index++];
                // Add a semicolon to the front of the control values to that the first element
                // can be compared against.  For example, if the first tape is ABC123, and the tape
                // we are testing for is C123, then we would get a match if we didn't prepend a semicolon.
                var verifiedSemi = ';' + getObjectById('verifiedTapes').value;
                var unverifiedSemi = ';' + getObjectById('unverifiedTapes').value;
                var verifyTheseSemi = ';' + getObjectById('verifyThese').value;
                var unrecognizedSemi = ';' + getObjectById('unrecognizedTapes').value;
                // Take action depending on which control a tape is in or, if not in any, take unrecognized tape action
                if ((pos1 = verifiedSemi.indexOf(';' + serialNo + '`')) != -1)  // verified control
                {
                    // Set the control in event of case switch
                    oSwitch = 1;
                    // Get the old case
                    tapeString = ';' + verifiedSemi.substr(pos1 + 1, verifiedSemi.indexOf(';', pos1 + 1) - pos1 - 1);
                    caseSerial = tapeString.substr(tapeString.indexOf('`') + 1);
                }
                else if ((pos1 = unverifiedSemi.indexOf(';' + serialNo + '`')) != -1)  // unverified control
                {
                    // Set the control in event of case switch (note that the flag is 3, since we'll be moving into the verifyThese control)
                    oSwitch = 3;
                    // Get the old case
                    tapeString = ';' + unverifiedSemi.substr(pos1 + 1, unverifiedSemi.indexOf(';', pos1 + 1) - pos1 - 1);
                    caseSerial = tapeString.substr(tapeString.indexOf('`') + 1);
                    // Remove from unverified
                    unverifiedSemi = unverifiedSemi.replace(';' + serialNo + '`' + caseSerial + ';', ';');
                    getObjectById('unverifiedTapes').value = unverifiedSemi.substr(1);
                    // Decrement the unverified label
                    getObjectById('lblItemsUnverified').innerHTML = (parseInt(getObjectById('lblItemsUnverified').innerHTML) - 1).toString();
                    // Move to the verifyThese control
                    getObjectById('verifyThese').value += serialNo + '`' + caseSerial + ';';
                    // If in the table contents control, redraw the table
                    if ((';' + getObjectById('tableContents').value).indexOf(';' + serialNo + '`') != -1)
                    {
                        renderTable();
                    }
                }
                else if ((pos1 = verifyTheseSemi.indexOf(';' + serialNo + '`')) != -1)  // verifyThese control
                {
                    // Set the control in event of case switch
                    oSwitch = 3;
                    // Get the old case
                    tapeString = ';' + verifyTheseSemi.substr(pos1 + 1, verifyTheseSemi.indexOf(';', pos1 + 1) - pos1 - 1);
                    caseSerial = tapeString.substr(tapeString.indexOf('`') + 1);
                }
                else if ((pos1 = unrecognizedSemi.indexOf(';' + serialNo + '`')) != -1)  // unrecognizedTapes control
                {
                    // Get the tape string and split into fields
                    tapeString = ';' + unrecognizedSemi.substr(pos1 + 1, unrecognizedSemi.indexOf(';', pos1 + 1) - pos1);
                    var fields = tapeString.split('`');
                    // Only take action if not ignoring tape
                    if (fields[3] != '1;')
                    {
                        doTapes1(action1);
                        return;
                    }
                    else
                    {
                        oSwitch = 4;
                        // Case is the second field
                        caseSerial = fields[1];
                    }
                }
                // Are the cases different?  Only relevant if stage 1 verification
                if (verifyStage == 1 && caseSerial != caseName)
                {
                    if (caseName.length != 0)
                    {
                        if ((action & 0x01) != 0)     // Display?
                        {
                            displaySwitch(serialNo, caseSerial, caseName);
                        }
                        else if ((action & 0x04) != 0)    // Autoswitch?
                        {
                            doSwitch(serialNo, caseSerial, caseName);
                        }
                        else
                        {
                            doTapes1(action);
                        }
                    }
                    else
                    {
                        if ((action & 0x02) != 0)     // Display?
                        {
                            displaySwitch(serialNo, caseSerial, caseName);
                        }
                        else if ((action & 0x08) != 0)    // Autoswitch?
                        {
                            doSwitch(serialNo, caseSerial, caseName);
                        }
                        else
                        {
                            doTapes1(action);
                        }
                    }
                }
                else
                {
                    doTapes1(action);
                }
            }
        }
        //
        // function: doTapes2 (process the tapes not found in the controls)
        //
        function doTapes2(action)
        {
            if (index < tapes2.length)
            {
                switch (action)
                {
                    case 0:
                        if (verifyStage == 2)
                        {
                            // If coming from the manual box, eliminate the Yes To All and No To All buttons
                            getObjectById('unrecognizedButtons1').style.display = manual ? 'none' : 'block';
                            getObjectById('unrecognizedButtons2').style.display = manual ? 'block' : 'none';
                            getObjectById('unrecognizedButtons3').style.display = 'none';
                            getObjectById('unrecognizedTape').innerHTML = tapes2[index];
                            showMsgBox('msgBoxUnrecognizedTape');
                        }
                        else
                        {
                            // Vault cannot add tapes to a list
                            getObjectById('msgBoxUnrecognizedTapeBody').innerHTML = 'Medium ' + tapes2[index] + ' does not appear on the list.';
                            getObjectById('unrecognizedButtons1').style.display = 'none';
                            getObjectById('unrecognizedButtons2').style.display = 'none';
                            getObjectById('unrecognizedButtons3').style.display = 'block';
                            showMsgBox('msgBoxUnrecognizedTape');
                        }
                        break;
                    case 1:
                    case 2:                       
                        // Place in unrecognized tapes control as a tape to add (last field is a 1)
                        getObjectById('unrecognizedTapes').value += tapes2[index] + '`' + caseName + '`1;';
                        // Increment the items not on list label
                        getObjectById('lblItemsNotOnList').innerHTML = (parseInt(getObjectById('lblItemsNotOnList').innerHTML) + 1).toString();
                        // Increment the index
                        index += 1;
                        // Call again
                        doTapes2(action == 2 ? 2 : 0);
                        break;
                    case 3:
                    case 4:
                        // Place in unrecognized tapes control as a tape to ignore (last field is a 0) -- no need for case name, just supply delimiters
                        if (manual == false)
                        {
                            getObjectById('unrecognizedTapes').value += tapes2[index] + '``0;';
                        }
                        // Increment the index
                        index += 1;
                        // Call again
                        doTapes2(action == 4 ? 4 : 0);
                        break;
                }
            }
            else
            {
                var k = -1;
                var tapeLabel = '';
                var c1 = tapes1.length;
                var c2 = tapes2.length;
                // Update labels
                if (caseName.length != 0)
                {
                    getObjectById('lblLastItem').innerHTML = 'Case ' + caseName + ' (' + (c1 + c2).toString() + ' pieces of media)';
                }
                else if (c1 + c2 > 5)
                {
                    getObjectById('lblLastItem').innerHTML = (c1 + c2).toString() + ' pieces of media';
                }
                else 
                {
                    // Tapes in a control
                    for (k = 0; k < c1; k++)
                    {
                        if (tapeLabel.length != 0)
                        {
                            tapeLabel += ', ' + tapes1[k];
                        }
                        else
                        {
                            tapeLabel = tapes1[k];
                        }
                    }
                    // Tapes not in a control
                    for (k = 0; k < c2; k++)
                    {
                        if (tapeLabel.length != 0)
                        {
                            tapeLabel += ', ' + tapes2[k];
                        }
                        else
                        {
                            tapeLabel = tapes2[k];
                        }
                    }
                    // Update the label
                    getObjectById('lblLastItem').innerHTML = tapeLabel;
                }
                // If there are no tapes left in the unverified section, list is fully verified;
                // we have to submit it so that the verifications will be committed.
                if (getObjectById('unverifiedTapes').value.length == 0)
                {
                    getObjectById('btnLater').click();
                }
                else
                {
                    // Set the ready state to true
                    readyState = true;
                    // If manual entry, set the focus back to the control
                    if (manual)
                    {
                        focusSelect('txtSerialNo');
                    }
                }
            }
        }
        //
        // function: displaySwitch (asks the user for permission to switch case or remove tape from case)
        //
        function displaySwitch(serialNo, case1, case2) // tape serial number, old case, new case
        {
            if (case2.length != 0)
            {
                getObjectById('switchTape').innerHTML = serialNo;
                getObjectById('switchCase1').innerHTML = case1;
                getObjectById('switchCase2').innerHTML = case2;
                getObjectById('switchSituation').innerHTML = case1.length != 0 ? '&nbsp;was listed in case&nbsp;' : '&nbsp;was not listed in a case';
                showMsgBox('msgBoxCaseSwitch');
            }
            else
            {
                getObjectById('removeTape').innerHTML = serialNo;
                getObjectById('removeCase').innerHTML = case1;
                showMsgBox('msgBoxCaseRemove');
            }
        }
        //
        // function: doSwitch (actually performs the case switch)
        //
        function doSwitch(serialNo, case1, case2)  // tape serial number, old case, new case
        {
            var semiString = '';
            // Perform switch based on control            
            switch (oSwitch)
            {
                case 1: // verified control
                    semiString = ';' + getObjectById('verifiedTapes').value;
                    semiString = semiString.replace(';' + serialNo + '`' + case1 + ';', ';' + serialNo + '`' + case2 + ';');
                    getObjectById('verifiedTapes').value = semiString.substr(1);
                    break;
                case 2: // unverified control;  should never be called with this value
                    break;
                case 3:
                    semiString = ';' + getObjectById('verifyThese').value;
                    semiString = semiString.replace(';' + serialNo + '`' + case1 + ';', ';' + serialNo + '`' + case2 + ';');
                    getObjectById('verifyThese').value = semiString.substr(1);
                    break;
                case 4:
                    semiString = ';' + getObjectById('unrecognizedTapes').value;
                    semiString = semiString.replace(';' + serialNo + '`' + case1 + '`', ';' + serialNo + '`' + case2 + '`');
                    getObjectById('unrecognizedTapes').value = semiString.substr(1);
                    break;
            }
            // Call doTapes
            doTapes1(action1);
        }
        //
        // function: doStartup
        //
        function doStartup(action)
        {
            // Record the action
            if (onStartup == 0) 
            {
                onStartup = action;
            }
            // If we have missing tapes that were marked as found, display them one at a time
            if (getObjectById('missingTapes').value.length != 0)
            {
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
            else 
            {
                switch (onStartup)
                {
                    case 1:
                        showMsgBox('msgBoxVerified');
                        break;
                    case 2:
                        showMsgBox('msgBoxDeleted');
                        break;
                    case 3:
                        location.href = 'receiving-list-detail.aspx?listNumber=' + getObjectById('lblListNo').innerHTML;
                        break;
                    default:
                        readyState = true;
                        break;
                }            
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
                    Scan media and cases across the RFID pad. As each is scanned, the appropriate 
                    media will be marked as verified and will no longer be displayed below.
                    <br>
                    <table cellSpacing="0" cellPadding="0" border="0">
                        <tr>
                            <td width="160"><b>List Number:</b>&nbsp;&nbsp;<asp:label id="lblListNo" runat="server"></asp:label></td>
                            <td width="150"><b>Total Items:</b>&nbsp;&nbsp;<asp:label id="lblTotalItems" runat="server"></asp:label></td>
                            <td width="160"><b>Items Unverified:</b>&nbsp;&nbsp;<asp:label id="lblItemsUnverified" runat="server"></asp:label></td>
                            <td width="150"><b>Items Not On List:</b>&nbsp;&nbsp;<asp:label id="lblItemsNotOnList" runat="server">0</asp:label></td>
                        </tr>
                        <tr>
                            <td width="300" colSpan="4">
                                <b>Last Scanned:</b>&nbsp;&nbsp;<asp:label id="lblLastItem" runat="server" CssClass="introHeader"></asp:label>
                            </td>
                        </tr>
                    </table>
                    <div id="headerConstants">
                        <A class="headerLink" id="listLink" style="LEFT: 644px" href="javascript:redirectPage('receiving-list-detail.aspx?listNumber=' + getObjectById('lblListNo').innerHTML);">
                            List Detail</A>
                    </div>
                </div> <!-- end pageHeader //-->
                <div class="tabNavigation threeTabs">
                    <div class="tabs" id="threeTabOne"><A href="javascript:redirectPage('receiving-compare-online-reconcile.aspx?listNumber=' + getObjectById('lblListNo').innerHTML);">Online 
                            Reconcile</A></div>
                    <div class="tabs" id="threeTabTwo"><A href="javascript:redirectPage('receiving-list-reconcile.aspx?listNumber=' + getObjectById('lblListNo').innerHTML);">Batch 
                            Reconcile</A></div>
                    <div class="tabs" id="threeTabThreeSelected"><A href="#">RFID Reconcile</A></div>
                </div> <!-- end tabNavigation //-->
                <!-- BEGIN MANUAL BOX //-->
                <div class="topContentArea" id="manualBox" style="DISPLAY:none" runat="server">
                    <div style="MARGIN-TOP: 10px; MARGIN-BOTTOM: 10px">
                        <input type="button" value="Verify" style="FLOAT:right" class="formBtn btnMedium" id="btnVerify"
                            onclick="doManual()"><b>Serial Number:</b>
                        <asp:textbox id="txtSerialNo" runat="server" CssClass="medium" style="MARGIN-LEFT:20px"></asp:textbox>
                    </div>
                </div>
                <!-- END MANUAL BOX //-->
                <div class="contentArea contentBorderTopNone">
                    <div class="contentBoxTop">
                        <asp:placeholder id="Placeholder1" runat="server" EnableViewState="False"></asp:placeholder>
                        <asp:Table id="Table1" runat="server" Width="100%">
                            <asp:TableRow>
                                <asp:TableCell Width="145px">
                                    <asp:dropdownlist id="ddlChooseAction" runat="server" CssClass="selectAction">
                                        <asp:ListItem Value="-Choose an Action-">-Choose an Action-</asp:ListItem>
                                        <asp:ListItem Value="Verify">Verify Selected</asp:ListItem>
                                        <asp:ListItem Value="Missing">Mark Missing</asp:ListItem>
                                    </asp:dropdownlist>
                                </asp:TableCell>
                                <asp:TableCell Width="60px">
                                    <input class="formBtn btnSmallGo" id="btnGo" type="button" value="Go" runat="server">
                                </asp:TableCell>
                                <asp:TableCell HorizontalAlign="right">
                                    <span style="MARGIN-RIGHT:5px">Expected Media Per Scan:</span>
                                    <asp:textbox id="txtExpected" MaxLength="3" tabIndex="3" runat="server" style="width:25px;text-align:right;"></asp:textbox>
                                    <input type="button" value="Manual" class="formBtn btnMedium" id="btnManual" style="margin-left:10px;"
                                        onclick="getObjectById('manualBox').style.display='block';this.style.display='none';focusSelect('txtSerialNo');" />
                                </asp:TableCell>
                            </asp:TableRow>
                        </asp:Table>
                    </div>
                    <div class="content"><asp:datagrid id="DataGrid1" runat="server" CssClass="detailTable" EnableViewState="False" AutoGenerateColumns="False">
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
                                <asp:BoundColumn DataField="CaseName" HeaderText="Case Number">
                                    <HeaderStyle Font-Bold="True"></HeaderStyle>
                                </asp:BoundColumn>
                            </Columns>
                        </asp:datagrid></div>
                    <!-- PAGE LINKS //-->
                    <div id="divPageLinks" runat="server"><br>
                        <table class="detailTable">
                            <tr>
                                <td align="left"><A id="lnkPageFirst" onclick="turnPage(1);return false;" href="#">[&lt;&lt;]</A>
                                    &nbsp; <A id="lnkPagePrev" onclick="turnPage(2);return false;" href="#">[&lt;]</A>
                                    &nbsp; <input onkeypress="digitsOnly(this);if (keyCode(event) == 13) {jumpPage(); return false;}"
                                        id="txtPageGoto" style="WIDTH: 40px" type="text"> <A id="lnkPageNext" onclick="turnPage(3);return false;" href="#">
                                        [&gt;]</A> &nbsp; <A id="lnkPageLast" onclick="turnPage(4);return false;" href="#">
                                        [&gt;&gt;]</A>
                                </td>
                                <td style="PADDING-RIGHT: 10px; TEXT-ALIGN: right"><b><asp:label id="lblPage" runat="server" Font-Bold="True"></asp:label></b></td>
                            </tr>
                        </table>
                    </div> <!-- end pageLinks //-->
                    <div class="contentBoxBottom">
                        <asp:button id="btnLater" runat="server" CssClass="formBtn btnMediumLarge" Text="Finish Later"></asp:button>
                    </div>
                </div> <!-- end contentArea //-->
            </div> <!-- end contentWrapper //-->
            <!-- BEGIN FULLY VERIFIED MESSAGE BOX -->
            <div class="msgBoxSmall" id="msgBoxVerified" style="DISPLAY: none">
                <h1><%= ProductName %></h1>
                <div class="msgBoxBody">
                    Receiving list
                    <%= ListName %>
                    has been fully verified.
                </div>
                <div class="msgBoxFooter">
                    <input class="formBtn btnSmallTop" id="btnOK" onclick="hideMsgBox('msgBoxVerified');redirectPage('receiving-list-detail.aspx?listNumber=' + getObjectById('lblListNo').innerHTML);"
                        type="button" value="OK">
                </div>
            </div>
            <!-- END FULLY VERIFIED MESSAGE BOX -->
            <!-- BEGIN DELETED LIST MESSAGE BOX -->
            <div class="msgBoxSmall" id="msgBoxDeleted" style="DISPLAY:none">
                <h1><%= ProductName %></h1>
                <div class="msgBoxBody">
                    No media remain on list.&nbsp;&nbsp;List will be automatically deleted.
                </div>
                <div class="msgBoxFooter">
                    <input class="formBtn btnSmallTop" onclick="hideMsgBox('msgBoxDeleted');redirectPage('receive-lists.aspx');"
                        type="button" value="OK">
                </div>
            </div>
            <!-- END DELETED LIST MESSAGE BOX -->
            <!-- BEGIN FOUND TAPE MESSAGE BOX -->
            <div class="msgBoxSmall" id="msgBoxFoundTape" style="DISPLAY: none">
                <h1><%= ProductName %></h1>
                <div class="msgBoxBody">Medium&nbsp;<span id="foundTape"></span>&nbsp;was missing 
                    and has been marked as found.
                </div>
                <div class="msgBoxFooter">
                    <input class="formBtn btnSmallTop" onclick="hideMsgBox('msgBoxFoundTape');doStartup(0);"
                        type="button" value="OK">
                </div>
            </div>
            <!-- END FOUND TAPE MESSAGE BOX -->
            <!-- BEGIN UNRECOGNIZED CASE MESSAGE BOX -->
            <div class="msgBoxSmall" id="msgBoxUnrecognizedCase" style="DISPLAY: none">
                <h1><%= ProductName %></h1>
                <div class="msgBoxBody">
                    Case&nbsp;<span id="unrecognizedCase"></span>&nbsp;does not appear on the list.
                    <br>
                    <br>
                    Would you like to proceed with scans of this case?
                </div>
                <div class="msgBoxFooter">
                    <input class="formBtn btnSmallTop" onclick="hideMsgBox('msgBoxUnrecognizedCase');getObjectById('unrecognizedCases').value += getObjectById('unrecognizedCase').innerHTML + '``0`1;';doTapes1(action1);"
                        type="button" value="Yes"> &nbsp; <input class="formBtn btnSmallTop" onclick="hideMsgBox('msgBoxUnrecognizedCase');getObjectById('unrecognizedCases').value += getObjectById('unrecognizedCase').innerHTML + '``0`0;';readyState=true;"
                        type="button" value="No">
                </div>
            </div>
            <!-- END UNRECOGNIZED CASE MESSAGE BOX -->
            <!-- BEGIN UNRECOGNIZED TAPE MESSAGE BOX -->
            <div class="msgBoxSmall" id="msgBoxUnrecognizedTape" style="DISPLAY: none">
                <h1><%= ProductName %></h1>
                <div class="msgBoxBody" id="msgBoxUnrecognizedTapeBody">
                    Medium&nbsp;<span id="unrecognizedTape"></span>&nbsp;does not appear on the 
                    list.
                    <br>
                    <br>
                    Move it to the enterprise upon submittal?
                </div>
                <div class="msgBoxFooter">
                    <div id="unrecognizedButtons1">
                        <input class="formBtn btnSmallTop" onclick="hideMsgBox('msgBoxUnrecognizedTape');doTapes2(1)"
                            type="button" value="Yes"> &nbsp; <input class="formBtn btnSmallTopPlus" onclick="hideMsgBox('msgBoxUnrecognizedTape');doTapes2(2);"
                            type="button" value="Yes To All"> &nbsp; <input class="formBtn btnSmallTop" onclick="hideMsgBox('msgBoxUnrecognizedTape');doTapes2(3);"
                            type="button" value="No"> &nbsp; <input class="formBtn btnSmallTopPlus" onclick="hideMsgBox('msgBoxUnrecognizedTape');doTapes2(4);"
                            type="button" value="No To All">
                    </div>
                    <div id="unrecognizedButtons2">
                        <input class="formBtn btnSmallTop" onclick="hideMsgBox('msgBoxUnrecognizedTape');doTapes2(1)"
                            type="button" value="Yes"> &nbsp; <input class="formBtn btnSmallTop" onclick="hideMsgBox('msgBoxUnrecognizedTape');doTapes2(3);"
                            type="button" value="No">
                    </div>
                    <div id="unrecognizedButtons3">
                        <input class="formBtn btnSmallTop" onclick="hideMsgBox('msgBoxUnrecognizedTape');doTapes2(1)"
                            type="button" value="OK">
                    </div>
                </div>
            </div>
            <!-- END UNRECOGNIZED TAPE MESSAGE BOX -->
            <!-- BEGIN SCAN COUNT ERROR MESSAGE BOX -->
            <div class="msgBoxSmallPlus" id="msgBoxExpected" style="DISPLAY:none">
                <h1><%= ProductName %></h1>
                <div class="msgBoxBody">
                    Only&nbsp;<span id="mediaScanned"></span>&nbsp;out of an expected&nbsp;<span id="mediaExpected"></span>&nbsp;were 
                    scanned.<br>
                    <br>
                    Continue?
                </div>
                <div class="msgBoxFooter">
                    <input class="formBtn btnSmallTop" type="button" value="Yes" onclick="hideMsgBox('msgBoxExpected');doCase();">
                    &nbsp; <input class="formBtn btnSmallTop" type="button" value="No" onclick="hideMsgBox('msgBoxExpected');">
                </div>
            </div>
            <!-- END SCAN COUNT ERROR MESSAGE BOX -->
            <!-- Hidden fields //-->
            <input id="pageValues" type="hidden" name="pageValues" runat="server"> <!-- page number;items per page //-->
            <input id="tableContents" type="hidden" name="tableContents" runat="server"> <!-- contents of table: serialNo`caseName`checkedStatus//-->
            <!-- TAPE HOLDERS //-->
            <input id="verifiedTapes" type="hidden" name="verifiedTapes" runat="server"> <!-- all tapes that have already been verified //-->
            <input id="unverifiedTapes" type="hidden" name="unverifiedTapes" runat="server"> <!-- all tapes that have yet to be verified (not just those in table) //-->
            <input id="verifyThese" type="hidden" name="verifyThese" runat="server"> <!-- tapes to be verified on next postback : serialNo`caseName //-->
            <input id="unrecognizedTapes" type="hidden" name="unrecognizedTapes" runat="server"> <!-- tapes not on list serialNo`caseName`returnDate`ignore (0=ignore)//-->
            <!-- OTHER HOLDERS //-->
            <input id="unrecognizedCases" type="hidden" name="unrecognizedCases" runat="server"> <!-- cases not on list : caseName`returnDate`sealed`ignore (0=ignore)//-->
            <!-- OTHER INFORMATION //-->
            <input id="missingTapes" type="hidden" name="missingTapes" runat="server"> <!-- tapes that were marked as missing and are now found //-->
            <!-- STARTUP SCRIPT //-->
            <script>renderTable();</script>
            <applet codebase="<%= System.Web.HttpRuntime.AppDomainAppVirtualPath %>" code="rfid.applet.RFIDApplet.class" ARCHIVE=<%= "\"" + System.Web.HttpRuntime.AppDomainAppVirtualPath + "/rfid/applet/OBIDISC4J.jar\""%> VIEWASTEXT width="1" height="1" MAYSCRIPT></applet>
        </form>
    </body>
</HTML>
