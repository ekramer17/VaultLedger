<%@ Page language="c#" Codebehind="disaster-recovery-list-append.aspx.cs" AutoEventWireup="false" Inherits="Bandl.VaultLedger.Web.UI.disaster_recovery_list_append" %>
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
            <div class="contentWrapper">
                <div class="pageHeader">
                    <h1><asp:label id="lblCaption" runat="server"></asp:label></h1>
                    Enter a medium to include in disaster recovery, type its related disaster 
                    recovery code, and click Add.&nbsp;&nbsp; Repeat for all media you wish to add 
                    to the list, and then click Save.
                </div> <!-- end pageHeader //--><asp:placeholder id="PlaceHolder1" runat="server" EnableViewState="False"></asp:placeholder>
                <!-- Should be visible when tabs are not to be shown -->
                <div class="contentArea" id="contentBorderTop" runat="server"></div>
                <!-- Should be visible only when tabs are to be shown -->
                <div id="tabControls" runat="server">
                    <div class="tabNavigation threeTabs">
                        <div class="tabs" id="threeTabOneSelected"><A href="#">Manual / Scan</A></div>
                        <div class="tabs" id="threeTabTwo"><A href="new-dr-list-batch-file-step-one.aspx">Batch 
                                File</A></div>
                        <div class="tabs" id="threeTabThree"><A id="A1" href="new-dr-list-tms-file.aspx">TMS 
                                Report</A></div>
                    </div>
                </div> <!-- end tabControls //-->
                <div class="contentArea" id="topPanel" runat="server">
                    <div id="accountDetail">
                        <div class="introHeader">Enter media and recovery code below:</div>
                        <br>
                        <table cellSpacing="0" cellPadding="0" border="0">
                            <tr>
                                <td width="100" height="23">Serial Number:</td>
                                <td width="290"><asp:textbox id="txtSerialNo" runat="server" CssClass="large"></asp:textbox></td>
                            </tr>
                            <tr>
                                <td>DR Code:</td>
                                <td><asp:textbox id="txtDisasterCode" runat="server" CssClass="large"></asp:textbox></td>
                            </tr>
                        </table>
                    </div>
                    <br>
                    <div class="contentBoxBottom">
                        <input class="formBtn btnMedium" id="btnAdd" onclick="createRow()" type="button" value="Add"
                            runat="server">
                    </div>
                </div> <!-- end contentArea //-->
                <div class="contentArea" id="todaysList" style="DISPLAY: none">
                    <h2 class="contentBoxHeader">Items to be Added</h2>
                    <div class="contentBoxTop" id="findMedia"><input class="formBtn btnLargeTop" id="btnDelete" onclick="javascript:deleteRows();" type="button"
                            value="Delete Selected">
                    </div>
                    <asp:datagrid id="DataGrid1" runat="server" CssClass="detailTable" AutoGenerateColumns="False">
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
                            <asp:BoundColumn DataField="Code" HeaderText="DR Code">
                                <HeaderStyle Font-Bold="True"></HeaderStyle>
                            </asp:BoundColumn>
                        </Columns>
                    </asp:datagrid>
                    <div class="contentBoxBottom"><input id="btnSave" type="button" runat="server" class="formBtn btnSmall" value="Save">&nbsp;
                        <input class="formBtn btnSmall" id="btnCancel" type="button" value="Cancel" runat="server">
                    </div>
                </div>
            </div>
            <input id="tableContents" type="hidden" runat="server">
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
               // Note
               var code = rowString.substring(0, rowString.lastIndexOf('`'));
               // Checked status
               var checkStatus = rowString[d1+1];
               // Add the row
               addRow(serial, code, checkStatus);
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
                  var drcode = tableRow.cells[2].innerHTML;
                  // Delete the row
                  tableRow.parentNode.removeChild(tableRow);
                  // Remove the string from the hidden field value
                  var s = serial + '`' + drcode + '`1;'
                  o.value = o.value.replace(s, '');
               }
            }
            // If only the header row is left, make the table invisible.  Otherwise, renumerate the checkboxes.
            if (theTable.rows.length == 1)
            {
               getObjectById('todaysList').style.display = 'none';
               getObjectById('txtSerialNo').select();
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
            var serial = getObjectById('txtSerialNo').value;
            var drcode = getObjectById('txtDisasterCode').value;
            // Add the row to the table
            if (true == addRow(serial, drcode, 0))
                getObjectById('tableContents').value += serial + '`' + drcode + '`0;';
        }
        //
        // Function: addRow
        //
        function addRow(serial, drcode, checkStatus)
        {
            var theTable = getObjectById('DataGrid1');
            // Make sure the serial number has not already been submitted
            for (i = 1; i < theTable.rows.length; i += 1)
            {
                if (theTable.rows[i].cells[1].innerHTML == serial)
                {
                    // Replace the string in the table contents control
                    var o = getObjectById('tableContents');
                    var s = serial + '`' + theTable.rows[i].cells[2].innerHTML + '`';
                    o.value = o.value.replace(s, serial + '`' + drcode + '`');
                    // Replace the row values
                    theTable.rows[i].cells[2].innerHTML = drcode;
                    getObjectById('txtSerialNo').select();
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
            // Notes
            cell3.appendChild(document.createTextNode(drcode));
            // Append the cells to the row
            newRow.appendChild(cell1);
            newRow.appendChild(cell2);
            newRow.appendChild(cell3);
            // Check the checkbox if check status is 1
            cell1.firstChild.checked = checkStatus == '1';
            // Make the section visible
            getObjectById('todaysList').style.display = 'block';
            // Select the serial number box
            getObjectById('txtSerialNo').select();
            // Return true
            return true;
        }

        // Render the table
        renderTable();       
        </script>
    </body>
</HTML>
