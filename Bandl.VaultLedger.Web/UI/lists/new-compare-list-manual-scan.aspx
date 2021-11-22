<%@ Page language="c#" Codebehind="new-compare-list-manual-scan.aspx.cs" AutoEventWireup="false" Inherits="Bandl.VaultLedger.Web.UI.new_compare_list_manual_scan" %>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<HTML>
    <HEAD>
        <meta content="Microsoft Visual Studio .NET 7.1" name="GENERATOR">
        <meta content="C#" name="CODE_LANGUAGE">
        <meta content="JavaScript" name="vs_defaultClientScript">
        <meta content="http://schemas.microsoft.com/intellisense/ie5" name="vs_targetSchema">
        <!--#include file = "../includes/baseHead.inc"-->
    </HEAD>
    <body onload="javascript:initializePage()">
        <!--#include file = "../includes/baseBody.inc"-->
        <form id="Form1" method="post" runat="server">
            <div class="contentWrapper">
                <div class="pageHeader">
                    <h1><asp:label id="lblCaption" runat="server"></asp:label></h1>
                    Choose a name for the new compare file, and then add serial numbers and case 
                    numbers, either by scanning them or by typing each and clicking 
                    Add.&nbsp;&nbsp;When finished, click Save to save the compare file.
                </div>
                <asp:placeholder id="PlaceHolder1" runat="server" EnableViewState="False"></asp:placeholder>
                <!-- Visible when RFID enabled -->
                <div id="threeTabs" class="tabNavigation threeTabs" runat="server">
                    <div class="tabs" id="threeTabOneSelected"><A href="#">Manual / Scan</A></div>
                    <div class="tabs" id="threeTabTwo"><A id="batchLink" runat="server">Batch File</A></div>
                    <div class="tabs" id="threeTabThree"><A id="rfidLink" runat="server">Imation RFID</A></div>
                </div>
                <!-- Visible when RFID not enabled -->
                <div id="twoTabs" class="tabNavigation twoTabs" runat="server">
                    <div class="tabs" id="twoTabOneSelected"><A href="#">Manual / Scan</A></div>
                    <div class="tabs" id="twoTabTwo"><A id="batchLinkTwo" runat="server">Batch File</A></div>
                </div>
                <div class="contentArea">
                    <div id="accountDetail">
                        <table cellSpacing="0" cellPadding="0" border="0">
                            <tr>
                                <td width="143" height="23">Compare File Name:</td>
                                <td><asp:textbox id="txtFileName" runat="server" CssClass="large"></asp:textbox></td>
                            </tr>
                        </table>
                        <br>
                        <hr class="step">
                        <div class="introHeader">Enter serial numbers and case numbers below:</div>
                        <br>
                        <table cellSpacing="0" cellPadding="0" border="0">
                            <tr>
                                <td width="143" height="23">Serial Number:</td>
                                <td width="250"><asp:textbox id="txtSerialNo" runat="server" CssClass="large"></asp:textbox></td>
                            </tr>
                            <tr>
                                <td>Case Number:</td>
                                <td><asp:textbox id="txtCaseName" runat="server" CssClass="large"></asp:textbox></td>
                            </tr>
                        </table>
                    </div>
                    <div class="contentBoxBottom">
                        <input class="formBtn btnMedium" id="btnAdd" onclick="clickAdd();return false;" type="submit"
                            runat="server" value="Add" name="btnAdd">
                    </div>
                </div>
                <div class="contentArea" id="todaysList" runat="server">
                    <h2 class="contentBoxHeader">Items to be Added</h2>
                    <div class="contentBoxTop" id="findMedia">
                        <input class="formBtn btnLargeTop" id="btnDelete" type="button" value="Delete Selected"
                            onclick="javascript:deleteRows();">
                    </div>
                    <asp:datagrid id="DataGrid1" runat="server" CssClass="detailTable" AutoGenerateColumns="False"
                        EnableViewState="False">
                        <AlternatingItemStyle CssClass="alternate"></AlternatingItemStyle>
                        <HeaderStyle CssClass="header"></HeaderStyle>
                        <Columns>
                            <asp:TemplateColumn>
                                <HeaderStyle CssClass="checkbox"></HeaderStyle>
                                <ItemStyle CssClass="checkbox"></ItemStyle>
                                <HeaderTemplate>
                                    <input id="cbCheckAll" onclick="checkAll('DataGrid1', 'cbItemChecked', this.checked); toggleAllChecks(this.checked);"
                                        type="checkbox" runat="server" NAME="cbCheckAll" />
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
                    </asp:datagrid>
                    <div class="contentBoxBottom">
                        <input class="formBtn btnSmall" id="btnSave" type="button" value="Save" runat="server">
                        &nbsp; <input class="formBtn btnSmall" id="btnCancel" type="button" value="Cancel" runat="server">
                    </div>
                </div>
            </div>
            <input type="hidden" id="tableContents" runat="server">
        </form>
        <script language="javascript">
      //
      // Function: initializePage
      //
      function initializePage()
      {
         var dataString = getObjectById('tableContents').value;
         var tempString = dataString;
         var semiIndex = 0;

         while ((semiIndex = tempString.indexOf(';')) != -1)
         {
            var rowString = tempString.substring(0, semiIndex);
            var serialNo = rowString.substring(0, rowString.indexOf('|'));
            var caseName = rowString.substring(rowString.indexOf('|') + 1, rowString.lastIndexOf('|'));
            var checkStatus = rowString.substr(rowString.lastIndexOf('|') + 1, 1);
            // Add the row
            addRow(serialNo, caseName, checkStatus);
            // Truncate the data string
            tempString = tempString.substring(semiIndex + 1);
         }
         // Replace the hidden element string (altered by calls to addRow)
         getObjectById('tableContents').value = dataString;
      }
      //
      // Function: toggleCheck
      //
      function toggleCheck(checkBox)
      {
         var tableRow = getObjectById(checkBox.id).parentNode.parentNode;
         // Change the value in the hidden field
         var s = tableRow.firstChild.nextSibling.innerHTML + '|'
         s += tableRow.firstChild.nextSibling.nextSibling.innerHTML + '|'
         // Check box value
         var hiddenObject = getObjectById('tableContents')
         if (checkBox.checked)
            hiddenObject.value = hiddenObject.value.replace(s + '0', s + '1');
         else            
            hiddenObject.value = hiddenObject.value.replace(s + '1', s + '0');
      }
      //
      // Function: toggleAllChecks
      //
      function toggleAllChecks(checkStatus)
      {
         var theTable = getObjectById('DataGrid1');
         for (i = 1; i < theTable.tBodies[0].rows.length; i++)
         {
            var checkBox = theTable.tBodies[0].rows[i].firstChild.firstChild;
            checkBox.checked = checkStatus;
            toggleCheck(checkBox);
         }
      }
      //
      // Function: deleteRows
      //
      function deleteRows()
      {
         var theTable = getObjectById('DataGrid1');
         var tableRow = theTable.tBodies[0].rows[theTable.tBodies[0].rows.length-1];     
         // Uncheck the header row checkbox
         theTable.tBodies[0].rows[0].firstChild.firstChild.checked = false;
         // Delete any checked rows
         for (i = theTable.tBodies[0].rows.length-1; i > 0; i -= 1)
         {
            // Get the row
            tableRow = theTable.tBodies[0].rows[i];
            // If it isn't checked, leave it alone
            if (!tableRow.firstChild.firstChild.checked)
            {
               tableRow = tableRow.previousSibling;
            }
            else
            {
               var serialNo = tableRow.firstChild.nextSibling.innerHTML;
               var caseName = tableRow.firstChild.nextSibling.nextSibling.innerHTML;
               // If there is olny row left, simply edit the row.  Otherwise, delete it.
               if (theTable.tBodies[0].rows.length != 2)
               {
                  tableRow.parentNode.removeChild(tableRow);
               }
               else
               {
                  tableRow.firstChild.firstChild.checked = false;
                  tableRow.firstChild.nextSibling.innerHTML = '&nbsp;';
                  tableRow.firstChild.nextSibling.nextSibling.innerHTML = '&nbsp;';
                  getObjectById('todaysList').style.display = 'none';
               }
               // Remove the string from the hidden field value
               var s = serialNo + '|' + caseName + '|1;'
               var hiddenObject = getObjectById('tableContents')
               hiddenObject.value = hiddenObject.value.replace(s, '');
            }
         }
         // Renumerate checkboxes
         for (i = 1; i < theTable.tBodies[0].rows.length; i += 1)
         {
            var checkBox = theTable.tBodies[0].rows[i].firstChild.firstChild;
            checkBox.name = 'DataGrid1:_ctl' + i+1 + ':cbItemChecked'
            checkBox.id = 'DataGrid1__ctl' + i+1 + '_cbItemChecked'
            theTable.tBodies[0].rows[i].className = i % 2 == 1 ? '' : 'alternate';
         }
         // Set focus back to serial textbox
         var serialObj = getObjectById('txtSerialNo');
         serialObj.focus();
         serialObj.select();
      }
      //
      // Function: clickAdd
      //
      function clickAdd()
      {
         var serialBox = getObjectById('txtSerialNo');
         addRow(serialBox.value,getObjectById('txtCaseName').value,'0');
         serialBox.focus();      
      }
      //
      // Function: addRow
      //
      function addRow(serialNo, caseName, checkStatus)
      {
         serialNo = trim(serialNo);
         caseName = trim(caseName);
         var theTable = getObjectById('DataGrid1');
         var hiddenElem = getObjectById('tableContents');
         // Make sure we have a serial number
         if (serialNo.length == 0) return;
         // Make sure serial number does not already exist in table.  If it does,
         // change the case for that row.
         for (i = 1; i < theTable.tBodies[0].rows.length; i++)
         {
            if (theTable.tBodies[0].rows[i].firstChild.nextSibling.innerHTML == serialNo)
            {
               var caseNode = theTable.tBodies[0].rows[i].firstChild.nextSibling.nextSibling;
               // Replace old case with new case
               caseNode.innerHTML = caseName;
               var newString = serialNo + '|' + caseName + '|';
               var currentString = serialNo + '|' + caseNode.innerHTML + '|';
               hiddenElem.value = hiddenElem.value.replace(currentString, newString);
               // Erase the text in the serial number checkbox
               getObjectById('txtSerialNo').value = '';
               // Return
               return;
            }
         }
         // Create the new row         
         var rowNo = 0;
         var newRow = document.createElement('tr');
         // Create the three cells for the row
         var cell1 = document.createElement('td');
         var cell2 = document.createElement('td');
         var cell3 = document.createElement('td');
         // Do we have contents?
         if (theTable.tBodies[0].rows[1].firstChild.nextSibling.innerHTML != '&nbsp;')
         {
            rowNo = theTable.tBodies[0].rows.length;
            theTable.tBodies[0].appendChild(newRow);
         }
         else
         {
            rowNo = theTable.tBodies[0].rows.length - 1;
            theTable.tBodies[0].replaceChild(newRow, theTable.tBodies[0].childNodes[1]);
         }
         // Alternate style?
         if (rowNo % 2 == 0)
            newRow.className = 'alternate';
         // Create the checkbox
         var checkBox = document.createElement('input');
         checkBox.type = 'checkbox';
         checkBox.id = 'DataGrid1__ctl' + rowNo+1 + '_cbItemChecked'
         checkBox.name = 'DataGrid1:_ctl' + rowNo+1 + ':cbItemChecked'
         checkBox.onclick = function (e) { checkFirst('DataGrid1', 'cbCheckAll', false); toggleCheck(this); };
         cell1.appendChild(checkBox);
         // Serial number
         cell2.appendChild(document.createTextNode(serialNo));
         // Case name
         cell3.appendChild(document.createTextNode(caseName));
         // Append the cells to the row
         newRow.appendChild(cell1);
         newRow.appendChild(cell2);
         newRow.appendChild(cell3);
         // Render the section visible
         getObjectById('todaysList').style.display = 'block';
         // Append to the hidden element (serialNo|caseName|checked;)
         hiddenElem.value += serialNo + '|' + caseName + '|' + checkStatus + ';';
         // Erase the text in the serial number checkbox
         getObjectById('txtSerialNo').value = '';
      }
        </script>
    </body>
</HTML>
