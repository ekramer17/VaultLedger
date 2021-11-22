<%@ Page language="c#" Codebehind="bar-code-formats.aspx.cs" AutoEventWireup="false" Inherits="Bandl.VaultLedger.Web.UI.bar_code_formats" %>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<HTML>
   <HEAD>
      <meta http-equiv="Content-Type" content="text/html; charset=windows-1252">
      <meta content="Microsoft Visual Studio .NET 7.1" name="GENERATOR">
      <meta content="C#" name="CODE_LANGUAGE">
      <meta content="JavaScript" name="vs_defaultClientScript">
      <meta content="http://schemas.microsoft.com/intellisense/ie5" name="vs_targetSchema">
      <!--#include file = "../includes/baseHead.inc"-->
      <script language="javascript">
      var n = -1;  // new format if -1, else row index
      //
      // Function: renderTable
      //
      function renderTable()
      {
         // Delete all the rows
         deleteTable();    
         // Get the data to render
         var dataString = getObjectById('tableContents').value;
         // Add rows to the table
         while ((semi = dataString.indexOf(';')) != -1)
         {
            var rowString = dataString.substring(0, semi);
            // Bar code format
            var format = rowString.substring(0, rowString.indexOf('`'));
            rowString = rowString.substr(rowString.indexOf('`') + 1);
            // Medium type
            var typeName = rowString.substring(0, rowString.indexOf('`'));
            rowString = rowString.substr(rowString.indexOf('`') + 1);
            // Account name
            var accountNo = rowString.substring(0, rowString.indexOf('`'));
            rowString = rowString.substr(rowString.indexOf('`') + 1);
            // Checked status
            var checkStatus = rowString.substr(0, 1);
            // Add the row
            addRow(format, typeName, accountNo, checkStatus);
            // Truncate the data string
            dataString = dataString.substring(semi + 1);
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
         var s = c[1].firstChild.innerHTML + '`' + c[2].innerHTML + '`' + c[3].innerHTML + '`';
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
         for (i = 0; i < checkBoxes.length - 1; i++)
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
         // Delete all rows but last row, which is always catch-all)
         for (i = theTable.rows.length-2; i > 0; i -= 1)
            theTable.tBodies[0].removeChild(theTable.tBodies[0].rows[i]);
         // Set the last row (catch-all) pattern to blank if it exists
         if (theTable.rows.length == 2)
            theTable.rows[1].cells[2].innerHTML = '&nbsp;';
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
         // Delete any checked rows (but not last row, which is always catch-all)
         for (i = theTable.rows.length-2; i > 0; i -= 1)
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
               var format = tableRow.cells[1].firstChild.innerHTML;
               var typeName = tableRow.cells[2].innerHTML;
               var accountNo = tableRow.cells[3].innerHTML;
               // If default format, do not delete
               if (format != '.*')
               {
                    // If we only have one row left, simply edit the row.  Otherwise, delete it.
                    if (theTable.rows.length != 2)
                    {
                    tableRow.parentNode.removeChild(tableRow);
                    }
                    else
                    {
                    tableRow.cells[0].firstChild.checked = false;
                    tableRow.cells[1].firstChild.innerHTML = '&nbsp;';
                    tableRow.cells[2].innerHTML = '&nbsp;';
                    tableRow.cells[3].innerHTML = '&nbsp;';
                    }
                    // Remove the string from the hidden field value
                    var s = format + '`' + typeName + '`' + accountNo + '`1;'
                    o.value = o.value.replace(s, '');
                    }
            }
         }
      }
      //
      // Function: addRow
      //
      function addRow(format, typeName, accountNo, checkStatus)
      {
         var theTable = getObjectById('DataGrid1');
         // Create the new row         
         var rowNo = 0;
         var newRow = document.createElement('tr');
         // Create the three cells for the row
         var cell1 = document.createElement('td');
         var cell2 = document.createElement('td');
         var cell3 = document.createElement('td');
         var cell4 = document.createElement('td');
         // Get the innerHTML for the first text cell of the first row
         var firstText = theTable.rows[1].cells[2].innerHTML;
         // If we have no contents, we have a dummy row -- remove it
         if (firstText.length == 0 || firstText == '&nbsp;' || escape(firstText.substring(0,1)) == '%A0')
            theTable.tBodies[0].removeChild(theTable.tBodies[0].rows[theTable.rows.length - 1]);
         // Append the new row            
         rowNo = theTable.rows.length;
         theTable.tBodies[0].appendChild(newRow);
         // Alternate style?
         if (rowNo % 2 == 0) newRow.className = 'alternate';
         // Create the checkbox.  If the pattern is '.*', then insert a blank node instead.
//         if (format != '.*')
//         {
            var checkBox = document.createElement('input');
            checkBox.type = 'checkbox';
            checkBox.id = 'DataGrid1__ctl' + (rowNo+1).toString() + '_cbItemChecked'
            checkBox.name = 'DataGrid1:_ctl' + (rowNo+1).toString() + ':cbItemChecked'
            checkBox.onclick = function (e) { checkFirst('DataGrid1', 'cbCheckAll', false); toggleCheck(this); };
            cell1.appendChild(checkBox);
//         }
         // Bar code format
         var hyperLink = document.createElement('a');
         hyperLink.href = "javascript:displayBox('" + format + "','" + typeName + "','" + accountNo + "'," + rowNo.toString() + ");";
         hyperLink.innerHTML = format;
         cell2.appendChild(hyperLink);
         // Serial number
         cell3.appendChild(document.createTextNode(typeName));
         // Case name
         cell4.appendChild(document.createTextNode(accountNo));
         // Append the cells to the row
         newRow.appendChild(cell1);
         newRow.appendChild(cell2);
         newRow.appendChild(cell3);
         newRow.appendChild(cell4);
         // Check the checkbox if check status is 1 and not catch-all pattern
//         if (format != '.*')
//		 {
            cell1.firstChild.checked = checkStatus == '1';
//		 }            
      }
      //
      // Function: moveUp
      //
      function moveUp()
      {
         var s = '';
         var lastChecked = -1;
         var firstUnchecked = -1;
         var tableContents = getObjectById('tableContents');
         var theTable = getObjectById('DataGrid1');
         var valueArray = tableContents.value.split(';');
         var checkArray = new Array(valueArray.length);
         // Get last checked and first unchecked
         for (i = 1; i < theTable.rows.length; i++)
         {
            if (theTable.rows[i].cells[0].firstChild.checked)
            {
               lastChecked = i - 1;
               checkArray[i] = true;
            }
            else if (firstUnchecked == -1)
            {
               firstUnchecked = i - 1;
               checkArray[i] = false;
            }
         }
         // If all checked or none checked, no further work necessary
         if (lastChecked == -1 || firstUnchecked == -1) return;
         // Move all checked items that occur after the first unchecked item up one spot.
         for (i = firstUnchecked + 1; i < theTable.rows.length; i++)
         {
            if (checkArray[i] == true)
            {
               var x = valueArray[i-2];
               var y = valueArray[i-1];
 
if (y.substr(0,3) != '.*`' || x.substr(0,3) == '.*`')
{
               valueArray[i-2] = y;            
               valueArray[i-1] = x;            
}               
            }
         }
         // Concatenate the string array
         for (i = 0; i < valueArray.length-1; i++)
         {
            s += valueArray[i] + ';';
		 }
         // Assign the string to the table contents field
         tableContents.value = s;            
         // Reinitialize the page
         renderTable();
      }
      //
      // Function: moveDown
      //
      function moveDown()
      {
         var s = '';
         var lastChecked = -1;
         var lastUnchecked = -1;
         var tableContents = getObjectById('tableContents');
         var theTable = getObjectById('DataGrid1');
         var valueArray = tableContents.value.split(';');
         var checkArray = new Array(valueArray.length);
         // Get last checked and last unchecked
         for (i = 1; i < theTable.rows.length; i++)
         {
            if (theTable.rows[i].cells[0].firstChild.checked)
            {
               lastChecked = i - 1;
               checkArray[i] = true;
            }
            else
            {
               lastUnchecked = i - 1;
               checkArray[i] = false;
            }
         }
         // If all checked or none checked, no further work necessary
         if (lastChecked == -1 || lastUnchecked == -1) return;

         // Move all checked items down one spot.
         for (i = lastUnchecked; i > 0; i--)
         {
            if (checkArray[i] == true)
            {
               var x = valueArray[i-1];
               var y = valueArray[i];
               
if (x.substr(0,3) == '.*`' || y.substr(0,3) != '.*`')
{
               valueArray[i-1] = y;    
               valueArray[i] = x;
}               
            }
         }
         // Concatenate the string array
         for (i = 0; i < valueArray.length-1; i++)
            s += valueArray[i] + ';';
         // Assign the string to the table contents field
         tableContents.value = s;
         // Reinitialize the page
         renderTable();
      }
      //
      // Function: appendRow
      //
      function appendRow()
      {
         // If no format supplied then just return
         var f1 = getObjectById('txtFormat').value;
         if (f1.length == 0) return;
         // Get the type name and account
         var o1 = getObjectById('ddlTypes');
         var o2 = getObjectById('ddlAccounts');
         var t1 = o1.options[o1.selectedIndex].value;
         var a1 = o2.options[o2.selectedIndex].value;
         // Get the datagrid
         var o = getObjectById('tableContents');
         // Remove the string from the hidden field value
         var s1 = o.value.substring(0, o.value.lastIndexOf('.*'));
         var s2 = o.value.substring(o.value.lastIndexOf('.*'), o.value.length);
         o.value = s1 + f1 + '`' + t1 + '`' + a1 + '`0;' + s2;
         // Render the table
         renderTable();
      }
      //
      // Function: displayBox
      //
      function displayBox(format, typeName, accountNo, nval)
      {
         n = nval;
         var i = -1;
         var o1 = getObjectById('ddlTypes');
         var o2 = getObjectById('ddlAccounts');
         // Set the format
         getObjectById('txtFormat').value = format;
         getObjectById('defaultAccount').innerHTML = accountNo;
         // Set the medium type
         if (typeName.length == 0)
         {
            o1.selectedIndex = 0;
         }
         else
         {
            for (i = 0; i < o1.options.length; i++)
            {
                if (o1.options[i].text == typeName)
                {
                    o1.selectedIndex = i;
                    break;
                }
            }
         }
         // Set the account type
         if (accountNo.length == 0)
         {
            o2.selectedIndex = 0;
         }
         else
         {
            for (i = 0; i < o2.options.length; i++)
            {
                if (o2.options[i].text == accountNo)
                {
                    o2.selectedIndex = i;
                    break;
                }
            }
         }
         // Show the assign message box
         showMsgBox('msgBoxAssign');
         // Should we show the format text box or span?
         if (format == '.*')
         {
            getObjectById('defaultFormat').style.display = 'block';
            getObjectById('defaultAccount').style.display = 'block';
            getObjectById('ddlAccounts').style.display = 'none';
            getObjectById('txtFormat').style.display = 'none';
            getObjectById('ddlTypes').focus();
         }
         else
         {
            getObjectById('defaultFormat').style.display = 'none';
            getObjectById('defaultAccount').style.display = 'none';
            getObjectById('ddlAccounts').style.display = 'block';
            getObjectById('txtFormat').style.display = 'block';
            getObjectById('txtFormat').focus();
         }
      }
      //
      // Function: hideBox
      //
      function hideBox()
      {
         hideMsgBox('msgBoxAssign');
         // If no format supplied then just return
         var f2 = getObjectById('txtFormat').value;
         if (f2.length == 0) return;
         // Append or replace
         if (n == -1)
         {
            appendRow();
         }
         else
         {
            var c = getObjectById('DataGrid1').rows[n].cells;
            // Get the old values
            var f1 = c[1].firstChild.innerHTML;
            var t1 = c[2].innerHTML;
            var a1 = c[3].innerHTML;
            // Get the new values
            var o1 = getObjectById('ddlTypes');
            var o2 = getObjectById('ddlAccounts');
            var f2 = getObjectById('txtFormat').value;
            var t2 = o1.options[o1.selectedIndex].value;
            var a2 = o2.options[o2.selectedIndex].value;
            // Create the old and new string
            var s1 = f1 + '`' + t1 + '`' + a1 + '`';
            var s2 = f2 + '`' + t2 + '`' + a2 + '`';
            // Replace the string 
            var o = getObjectById('tableContents');
            if (o.value.indexOf(s1) != 0)
            {
                o.value = o.value.replace(';' + s1, ';' + s2);
            }
            else
            {
                o.value = s2 + o.value.substring(o.value.indexOf(';') - 1, o.value.length);
            }
            // Render the table
            renderTable();
         }
      }      
      //
      // Function: displayNew
      //
      function displayNew()
      {
         displayBox('','','',-1);
      }
      //
      // Function: eventGo
      //
      function eventGo()
      {
         var o = getObjectById('ddlSelectAction');
         // Take action based on index
         switch (o.selectedIndex)
         {
            case 1:
               deleteRows();
               break;
            case 2:
               moveUp();
               break;
            case 3:
               moveDown();
               break;
           }
      }
      </script>
   </HEAD>
   <body>
      <!--#include file = "../includes/baseBody.inc"-->
      <form id="Form1" method="post" runat="server">
         <div class="contentWrapper">
            <div class="pageHeader">
               <h1>Bar Code Formats</h1>
               These are the bar code formats that determine the account and media 
               type for a medium when it is added to the system.&nbsp;&nbsp;To define a new bar code format, click New 
               Format.
               <div id="headerConstants">
                  <a style="LEFT:580px" class="headerLink" id="arrow" href="index.aspx">Tools Menu</a>
                  <asp:linkbutton id="printLink" runat="server" CssClass="headerLink">Print</asp:linkbutton>
               </div>
            </div> <!-- end pageHeader //-->
            <asp:placeholder id="PlaceHolder1" runat="server" EnableViewState="False"></asp:placeholder>
            <div class="contentArea" id="contentBorderTop">
               <div class="contentBoxTop">
                  <div class="floatRight"><input class="formBtn btnMediumLarge" id="btnNew" type="button" value="New Format" onclick="javascript:displayNew();"></div>
                  <asp:dropdownlist id="ddlSelectAction" runat="server" CssClass="selectAction" Width="140">
                     <asp:ListItem Value="-Choose an Action-" Selected="True">-Choose an Action-</asp:ListItem>
                     <asp:ListItem Value="Delete">Delete Selected</asp:ListItem>
                     <asp:ListItem Value="MoveUp">Raise Priority</asp:ListItem>
                     <asp:ListItem Value="MoveDown">Lower Priority</asp:ListItem>
                  </asp:dropdownlist>&nbsp;&nbsp; <input class="formBtn btnSmallGo" id="btnGo" onclick="javascript:eventGo();" type="button" value="Go">
               </div> <!-- end contentBoxTop //-->
               <div class="content">
                  <asp:datagrid id="DataGrid1" runat="server" CssClass="detailTable" EnableViewState="False" AutoGenerateColumns="False">
                     <AlternatingItemStyle CssClass="alternate"></AlternatingItemStyle>
                     <HeaderStyle CssClass="header"></HeaderStyle>
                     <Columns>
                        <asp:TemplateColumn>
                           <HeaderStyle CssClass="checkbox"></HeaderStyle>
                           <ItemStyle CssClass="checkbox"></ItemStyle>
                           <HeaderTemplate>
                              <input type="checkbox" id="cbCheckAll" runat="server" onclick="checkAll('DataGrid1', 'cbItemChecked', this.checked)"
                                 NAME="cbAllItems">
                           </HeaderTemplate>
                           <ItemTemplate>
                              <input type="checkbox" id="cbItemChecked" runat="server" onclick="checkFirst('DataGrid1', 'cbCheckAll', false)"
                                 NAME="cbItemChecked">
                           </ItemTemplate>
                        </asp:TemplateColumn>
                        <asp:HyperLinkColumn DataNavigateUrlFormatString="#" DataTextField="Pattern" HeaderText="Bar Code Format">
                           <HeaderStyle Font-Bold="True" Wrap="False"></HeaderStyle>
                        </asp:HyperLinkColumn>
                        <asp:BoundColumn DataField="MediumType" HeaderText="Media Type">
                           <HeaderStyle Font-Bold="True" Wrap="False"></HeaderStyle>
                        </asp:BoundColumn>
                        <asp:BoundColumn DataField="Account" HeaderText="Account">
                           <HeaderStyle Font-Bold="True" Wrap="False"></HeaderStyle>
                        </asp:BoundColumn>
                     </Columns>
                  </asp:datagrid>
               </div> <!-- end content //-->
               <div class="contentBoxBottom">
                  <input class="formBtn btnMedium" id="btnSave" type="button" value="Save" runat="server">
               </div>
            </div> <!-- end contentArea //-->
         </div> <!-- end contentWrapper //-->
         <input id="tableContents" type="hidden" runat="server">
        <!-- BEGIN SAVE MESSAGE BOX -->
        <div class="msgBoxSmall" id="msgBoxSave" style="DISPLAY: none">
            <h1><%= ProductName %></h1>
            <div class="msgBoxBody">Bar code formats were updated successfully.</div>
            <div class="msgBoxFooter"><input type="button" value="OK" class="formBtn btnSmallTop" onclick="hideMsgBox('msgBoxSave');"/></div>
        </div>
        <!-- END SAVE MESSAGE BOX -->
         <!-- BEGIN CHANGE FORMAT BOX -->
         <div class="msgBox" id="msgBoxAssign" style="DISPLAY:none">
            <h1><%= ProductName %></h1>
            <div class="msgBoxBody">
               Please enter the bar code format information:
               <br>
               <br>
               <table style="width:100%">
                  <tr height="27">
                     <td width="80" align="right" style="PADDING-RIGHT:11px">Format pattern:</td>
                     <td align="left"><span id="defaultFormat" style="MARGIN-LEFT:7px">.*</span><asp:textbox id="txtFormat" runat="server" Width="157" style="MARGIN-LEFT:7px"></asp:textbox></td>
                  </tr>
                  <tr height="27">
                     <td align="right" style="PADDING-RIGHT:11px">Medium type:</td>
                     <td><asp:dropdownlist id="ddlTypes" runat="server" Width="162"></asp:dropdownlist></td>
                  </tr>
                  <tr height="27">
                     <td align="right" style="PADDING-RIGHT:11px">Account:</td>
                     <td><span id="defaultAccount" style="TEXT-ALIGN:left;MARGIN-LEFT:7px"></span><asp:dropdownlist id="ddlAccounts" runat="server" Width="162"></asp:dropdownlist></td>
                  </tr>
               </table>
            </div>
            <div class="msgBoxFooter">
               <input class="formBtn btnSmallTop" id="btnOK" type="button" value="OK" onclick="hideBox();">
               &nbsp; <input class="formBtn btnSmallTop" id="btnCancel" type="button" value="Cancel" onclick="hideMsgBox('msgBoxAssign');">
            </div>
         </div>
         <!-- END CHANGE FORMAT BOX -->
     </form>
</body>
</HTML>
