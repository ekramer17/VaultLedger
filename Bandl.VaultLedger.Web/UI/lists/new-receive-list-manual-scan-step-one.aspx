<%@ Page language="c#" Codebehind="new-receive-list-manual-scan-step-one.aspx.cs" AutoEventWireup="false" Inherits="Bandl.VaultLedger.Web.UI.new_receive_list_manual_scan_step_one" %>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<HTML>
    <HEAD>
        <meta content="Microsoft Visual Studio .NET 7.1" name="GENERATOR">
        <meta content="C#" name="CODE_LANGUAGE">
        <meta content="JavaScript" name="vs_defaultClientScript">
        <meta content="http://schemas.microsoft.com/intellisense/ie5" name="vs_targetSchema">
        <!--#include file = "../includes/baseHead.inc"-->
    </HEAD>
    <body>
        <!--#include file = "../includes/baseBody.inc"-->
        <script type="text/javascript" src="../includes/tablechecker.js"></script>
        <form id="Form1" method="post" runat="server">
            <div class="contentWrapper">
                <div class="pageHeader">
                    <h1><asp:label id="lblCaption" runat="server"></asp:label></h1>
                    Enter a serial number or case number and notes as desired, then click 
                    Add.&nbsp;&nbsp;Repeat for all media and sealed cases you wish to add to the 
                    list, then click Next.&nbsp;&nbsp;Alternatively, you may click the Generate 
                    button to produce a list containing media and cases with return dates of today 
                    and earlier.
                </div>
                <!-- end pageHeader //--><asp:placeholder id="PlaceHolder1" runat="server" EnableViewState="False"></asp:placeholder>
                <!-- Should be visible when tabs are not to be shown -->
                <div class="contentArea" id="contentBorderTop" runat="server"></div>
                <!-- Should be visible only when tabs are to be shown -->
                <div class="tabNavigation twoTabs" id="tabControls" runat="server">
                    <div class="tabs" id="twoTabOneSelected"><A href="#">Manual / Scan</A>
                    </div>
                    <div class="tabs" id="twoTabTwo"><A href="new-receive-list-tms-file.aspx">TMS Report</A></div>
                </div>
                <div class="contentArea">
                    <div id="accountDetail" runat="server">
                        <table cellSpacing="0" cellPadding="0" border="0">
                            <tr>
                                <td style="BORDER-RIGHT: #dedfe2 thin solid" width="330" height="40">
                                    <div class="introHeader">Option 1:&nbsp;&nbsp;Click the Generate button</div>
                                </td>
                                <td height="40">
                                    <div class="introHeader" style="PADDING-LEFT:15px">Option 2:&nbsp;&nbsp;Enter media 
                                        information manually</div>
                                </td>
                            </tr>
                            <tr>
                                <td style="BORDER-RIGHT:#dedfe2 thin solid; PADDING-RIGHT:30px" valign="top" align="left">
                                    <table style="MARGIN-BOTTOM:3px">
                                        <tr>
                                            <td style="WIDTH:90px">Latest date:
                                            </td>
                                            <td style="WIDTH:auto">
                                                <table>
                                                    <tr>
                                                        <td><asp:textbox id="txtReturnDate" runat="server" width="170px" MaxLength="10"></asp:textbox></td>
                                                        <td class="calendarCell" width="30"><a class="iconLink calendarLink" href="javascript:openCalendar('txtReturnDate');"></a></td>
                                                    </tr>
                                                </table>
                                            </td>
                                        </tr>
                                    </table>
                                    <table style="MARGIN-BOTTOM:3px">
                                        <tr valign="top">
                                            <td style="WIDTH:90px">Accounts:</td>
                                            <td style="WIDTH:auto"><asp:DropDownList ID="ddlAccounts" Runat="server" Width="205"></asp:DropDownList><input type="hidden" id="hidden1" runat="server" NAME="hidden1"></td>
                                        </tr>
                                        <tr>
                                            <td colspan="2" align="right" style="PADDING-TOP:12px"><input class="formBtn btnMedium" id="btnAuto" type="button" value="Generate" runat="server"
                                                    name="btnAuto"></td>
                                        </tr>
                                    </table>
                                </td>
                                <td>
                                    <table cellSpacing="0" cellPadding="0" border="0">
                                        <tr>
                                            <td style="PADDING-LEFT:15px" valign="top" align="left">Serial Number:</td>
                                            <td align="left" width="290"><asp:textbox id="txtSerialNum" runat="server" width="270" CssClass="large"></asp:textbox></td>
                                        </tr>
                                        <tr valign="top">
                                            <td style="PADDING-LEFT:15px" valign="top" width="100">Notes:</td>
                                            <td class="textArea" align="left" width="290"><asp:textbox id="txtNotes" runat="server" width="270" Columns="10" Rows="1" TextMode="MultiLine"></asp:textbox></td>
                                        </tr>
                                        <tr>
                                            <td colspan="2" align="right" style="PADDING-TOP:12px"><input class="formBtn btnMedium" id="btnAdd" onclick="createRow()" type="button" value="Add"
                                                    runat="server" name="btnAdd" style="MARGIN-RIGHT:13px"></td>
                                        </tr>
                                    </table>
                                </td>
                            </tr>
                        </table>
                        <br>
                    </div>
                </div>
                <!-- end contentArea //-->
                <div class="contentArea" id="todaysList" style="DISPLAY: none">
                    <h2 class="contentBoxHeader">Items to be Added</h2>
                    <div class="contentBoxTop" id="findMedia"><input class="formBtn btnLargeTop" id="btnDelete" onclick="javascript:deleteRows();" type="button"
                            value="Delete Selected">
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
                            <asp:BoundColumn DataField="Notes" HeaderText="Notes">
                                <HeaderStyle Font-Bold="True"></HeaderStyle>
                            </asp:BoundColumn>
                        </Columns>
                    </asp:datagrid>
                    <div class="contentBoxBottom"><input class="formBtn btnSmall" id="btnNext" type="button" value="Next >" runat="server">&nbsp;
                        <input class="formBtn btnSmall" id="btnCancel" type="button" value="Cancel" runat="server">
                    </div> <!-- end contentBoxBottom //--></div> <!-- end contentArea //--></div>
            <!-- end contentWrapper //-->
            <!-- BEGIN MESSAGE BOX -->
            <div class="msgBoxSmall" id="msgBoxNone" style="DISPLAY: none">
                <h1><%= ProductName %></h1>
                <div class="msgBoxBody" style="PADDING-TOP: 5px">No media qualify for placement on 
                    a receiving list.</div>
                <div class="msgBoxFooter"><asp:button id="btnOK" runat="server" CssClass="formBtn btnSmallTop" Text="OK"></asp:button></div>
            </div>
            <!-- END MESSAGE BOX -->
            <!-- BEGIN MESSAGE BOX -->
            <div class="messagebox" id="msgBoxAccounts" style="DISPLAY:none;WIDTH:400px">
                <div class="messagebox_header"><%= ProductName %></div>
                <div class="messagebox_body">
                    Please select the desired accounts
                    <br>
                    <br>
                    <br>
                    <asp:DataGrid id="GridView1" runat="server" CssClass="detailTable" EnableViewState="True" AutoGenerateColumns="False"
                        style="MARGIN:0px auto" Width="370">
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
                            <asp:BoundColumn DataField="Name" HeaderText="Account Name">
                                <HeaderStyle Font-Bold="True" Wrap="False"></HeaderStyle>
                            </asp:BoundColumn>
                        </Columns>
                    </asp:DataGrid>
                </div>
                <div class="messagebox_footer">
                    <asp:button id="btnAccountOK" runat="server" Text="OK" CssClass="formBtn btnMediumTop"></asp:button>
                    &nbsp;
                    <asp:button id="btnAccountCancel" runat="server" CssClass="formBtn btnMediumTop" Text="Cancel"></asp:button>
                </div>
            </div>
            <!-- END MESSAGE BOX -->
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
               var itemNote = rowString.substring(0, rowString.lastIndexOf('`'));
               // Checked status
               var checkStatus = rowString[d1+1];
               // Add the row
               addRow(serial, itemNote, checkStatus);
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
                  var itemNote = tableRow.cells[2].innerHTML;
                  // Delete the row
                  tableRow.parentNode.removeChild(tableRow);
                  // Remove the string from the hidden field value
                  var s = serial + '`' + itemNote + '`1;'
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
            var itemNote = getObjectById('txtNotes').value;
            // Add the row to the table.  Append to the data string on success.
            if (trim(serial).length != 0 && addRow(serial, itemNote, 0))
                getObjectById('tableContents').value += serial + '`' + itemNote + '`0;';
        }
        //
        // Function: addRow
        //
        function addRow(serial, itemNote, checkStatus)
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
                    o.value = o.value.replace(s, serial + '`' + itemNote + '`');
                    // Replace the row values
                    theTable.rows[i].cells[2].innerHTML = itemNote;
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
            cell3.appendChild(document.createTextNode(itemNote));
            // Append the cells to the row
            newRow.appendChild(cell1);
            newRow.appendChild(cell2);
            newRow.appendChild(cell3);
            // Check the checkbox if check status is 1
            cell1.firstChild.checked = checkStatus == '1';
            // Make the section visible
            getObjectById('todaysList').style.display = 'block';
            // Select the serial number box
            getObjectById('txtSerialNum').select();
            // Return true
            return true;
        }

        // Render the table
        renderTable();
        
        function onChange(o1)
        {
           if (o1.selectedIndex == o1.options.length - 1)
           {
              document.getElementById('hidden1').value = 'true';
              showMsgBox('msgBoxAccounts');
           }
           else
           {
              document.getElementById('hidden1').value = '';
           }
        }
        </script>
    </body>
</HTML>
