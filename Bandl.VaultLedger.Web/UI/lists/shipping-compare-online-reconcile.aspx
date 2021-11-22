<%@ Page language="c#" Codebehind="shipping-compare-online-reconcile.aspx.cs" AutoEventWireup="false" Inherits="Bandl.VaultLedger.Web.UI.shipping_compare_online_reconcile" %>
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
                    Scan the serial numbers and/or case numbers on the list. As each is scanned, it 
                    will be marked as verified and will no longer be displayed below.
                    <br>
                    <br>
                    <table cellSpacing="0" cellPadding="0" border="0">
                        <tr>
                            <td width="160"><b>List Number:</b>&nbsp;&nbsp;<asp:label id="lblListNo" runat="server"></asp:label></td>
                            <td width="150"><b>Total Items:</b>&nbsp;&nbsp;<asp:label id="lblTotalItems" runat="server"></asp:label></td>
                            <td width="160"><b>Items Unverified:</b>&nbsp;&nbsp;<asp:label id="lblItemsUnverified" runat="server"></asp:label></td>
                            <td width="150"><b>Items Added:</b>&nbsp;&nbsp;<asp:label id="lblItemsAdded" runat="server">0</asp:label></td>
                        </tr>
                        <tr>
                            <td width="300" colSpan="4"><b>Last Scanned:</b>&nbsp;&nbsp;<asp:label id="lblLastItem" runat="server" CssClass="introHeader"></asp:label></td>
                        </tr>
                    </table>
                    <div id="headerConstants">
                        <asp:linkbutton id="listLink" runat="server" style="LEFT:644px" CssClass="headerLink">List Detail</asp:linkbutton>
                    </div>
                </div> <!-- end pageHeader //-->
                <div id="twoTabs" class="tabNavigation twoTabs" runat="server">
                    <div class="tabs" id="twoTabOneSelected"><A href="#">Online Reconcile</A></div>
                    <div class="tabs" id="twoTabTwo"><A href="javascript:redirectPage('shipping-list-reconcile.aspx?listNumber=' + getObjectById('lblListNo').innerHTML);">Batch 
                            Reconcile</A></div>
                </div>
                <div id="threeTabs" class="tabNavigation threeTabs" runat="server">
                    <div class="tabs" id="threeTabOneSelected"><A href="#">Online Reconcile</A></div>
                    <div class="tabs" id="threeTabTwo"><A href="javascript:redirectPage('shipping-list-reconcile.aspx?listNumber=' + getObjectById('lblListNo').innerHTML);">Batch 
                            Reconcile</A></div>
                    <div class="tabs" id="threeTabThree"><A href="javascript:redirectPage('shipping-list-reconcile-rfid.aspx?listNumber=' + getObjectById('lblListNo').innerHTML);">RFID 
                            Reconcile</A></div>
                </div>
                <!-- end tabNavigation //-->
                <div class="topContentArea">
                    <div id="divSerial" style="MARGIN-TOP: 10px; MARGIN-BOTTOM: 10px" runat="server">
                        <div class="floatRight"><input class="formBtn btnMedium" id="btnVerify" onclick="doVerify()" type="button" value="Verify"
                                runat="server">
                        </div>
                        <b>Serial/Case Number:</b>&nbsp;&nbsp;<asp:textbox id="txtSerialNum" runat="server" CssClass="medium"></asp:textbox>
                    </div>
                </div> <!-- end topContentArea //-->
                <div class="contentArea" id="todaysList">
                    <h2 class="contentBoxHeader">Items On List</h2>
                    <div class="contentBoxTop" id="findMedia"><asp:placeholder id="PlaceHolder1" runat="server" EnableViewState="False"></asp:placeholder><asp:dropdownlist id="ddlChooseAction" runat="server" CssClass="selectAction">
                            <asp:ListItem Value="-Choose an Action-" Selected="True">-Choose an Action-</asp:ListItem>
                            <asp:ListItem Value="Remove">Remove Selected</asp:ListItem>
                            <asp:ListItem Value="Verify">Verify Selected</asp:ListItem>
                            <asp:ListItem Value="Missing">Mark Missing</asp:ListItem>
                        </asp:dropdownlist>&nbsp;&nbsp;<input class="formBtn btnSmallGo" id="btnGo" type="button" value="Go" runat="server">
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
                                            runat="server" />
                                    </HeaderTemplate>
                                    <ItemTemplate>
                                        <input id="cbItemChecked" onclick="checkFirst('DataGrid1', 'cbCheckAll', false)" type="checkbox"
                                            runat="server" />
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
                                <td align="left"><A id="lnkPageFirst" onclick="turnPage(1);return false;" href="#">[&lt;&lt;]</A>&nbsp;
                                    <A id="lnkPagePrev" onclick="turnPage(2);return false;" href="#">[&lt;]</A>&nbsp;
                                    <input onkeypress="digitsOnly(this);if (keyCode(event) == 13) {jumpPage(); return false;}"
                                        id="txtPageGoto" style="WIDTH: 40px" type="text"> <A id="lnkPageNext" onclick="turnPage(3);return false;" href="#">
                                        [&gt;]</A>&nbsp; <A id="lnkPageLast" onclick="turnPage(4);return false;" href="#">
                                        [&gt;&gt;]</A></td>
                                <td style="PADDING-RIGHT: 10px; TEXT-ALIGN: right"><b><asp:label id="lblPage" runat="server" Font-Bold="True"></asp:label></b></td>
                            </tr>
                        </table>
                    </div> <!-- end pageLinks //-->
                    <div class="contentBoxBottom"><asp:button id="btnLater" runat="server" CssClass="formBtn btnMediumLarge" Text="Finish Later"></asp:button></div>
                </div> <!-- end contentArea //--></div> <!-- end contentWrapper //-->
            <!-- BEGIN ADD MEDIUM MESSAGE BOX -->
            <div class="msgBox" id="msgBoxAdd" style="DISPLAY: none">
                <h1><%= ProductName %></h1>
                <div class="msgBoxBody">Medium&nbsp;<asp:label id="lblSerialNo" runat="server"></asp:label>&nbsp;is 
                    not currently on the list.<br>
                    <br>
                    Would you like to add it to the list now?
                </div>
                <div class="msgBoxFooter"><asp:button id="btnYes" runat="server" CssClass="formBtn btnSmallTop" Text="Yes"></asp:button>&nbsp;
                    <input class="formBtn btnSmallTop" id="btnNo" onclick="hideMsgBox('msgBoxAdd');getObjectById('txtSerialNum').value = '';getObjectById('txtSerialNum').select()" type="button" value="No">
                </div>
            </div>
            <!-- END ADD MEDIUM MESSAGE BOX -->
            <!-- BEGIN RECONCILE MESSAGE BOX -->
            <div class="msgBoxSmall" id="msgBoxVerify" style="DISPLAY: none">
                <h1><%= ProductName %></h1>
                <div class="msgBoxBody">Shipping list
                    <%= ListName %>
                    has been fully verified.
                </div>
                <div class="msgBoxFooter"><input class="formBtn btnSmallTop" id="btnOK" type="button" value="OK" runat="server">
                </div>
            </div>
            <!-- END RECONCILE MESSAGE BOX -->
            <!-- BEGIN NO MORE MEDIA MESSAGE BOX -->
            <div class="msgBoxSmall" id="msgBoxEmpty" style="DISPLAY: none">
                <h1><%= ProductName %></h1>
                <div class="msgBoxBody">No media remain on list.&nbsp;&nbsp;List will be 
                    automatically deleted.</div>
                <div class="msgBoxFooter"><input class="formBtn btnSmallTop" onclick="location.href='send-lists.aspx'" type="button"
                        value="OK"></div>
            </div>
            <!-- END NO MORE MEDIA MESSAGE BOX -->
            <!-- BEGIN SEALED CASE REMOVAL MESSAGE BOX -->
            <div class="msgBox" id="msgBoxSealed" style="DISPLAY: none">
                <h1><%= ProductName %></h1>
                <div class="msgBoxBody">
                    Medium&nbsp;<asp:label id="lblSealedTape1" runat="server" />&nbsp;is in a 
                    sealed case, so you should not have been able to reconcile it individually.
                    <br>
                    <br>
                    Would you like
                    <%=ProductName%>
                    to remove it from its case?
                    <br>
                    <br>
                    Please note that if you choose not to remove&nbsp;<asp:label id="lblSealedTape2" runat="server" />&nbsp;from 
                    its case, it will be verified only when its case is verified.
                </div>
                <div class="msgBoxFooter">
                    <input type="button" id="btnSealedYes" class="formBtn btnSmallTop" value="Yes" runat="server">
                    &nbsp; <input type="button" id="btnSealedNo" class="formBtn btnSmallTop" value="No" onclick="hideMsgBox('msgBoxSealed');getObjectById('sealedTape').value='';getObjectById('txtSerialNum').select();">
                </div>
            </div>
            <!-- END SEALED CASE REMOVAL MESSAGE BOX -->
            <!-- BEGIN CASE MEDIUM MESSAGE BOX -->
            <div class="msgBox" id="msgBoxMove" style="DISPLAY: none">
                <h1><%= ProductName %></h1>
                <div class="msgBoxBody">Medium&nbsp;<asp:label id="lblMoveSerial" runat="server"></asp:label>&nbsp;is 
                    not on the list.
                    <br>
                    <br>
                    Would you like to move it to the vault now?
                </div>
                <div class="msgBoxFooter"><asp:button id="btnMove" runat="server" CssClass="formBtn btnSmallTop" Text="Yes"></asp:button>&nbsp;
                    <input class="formBtn btnSmallTop" id="btnNoMove" onclick="hideMsgBox('msgBoxMove');getObjectById('txtSerialNum').select();"
                        type="button" value="No"></div>
            </div>
            <!-- END MOVE MEDIA MESSAGE BOX -->
            <!-- Hidden fields //--><input id="tableContents" type="hidden" runat="server"> <input id="unverifiedTapes" type="hidden" runat="server">
            <input id="alreadyVerified" type="hidden" runat="server"> <input id="verifyThese" type="hidden" runat="server">
            <input id="caseSerials" type="hidden" runat="server"> <input id="totalItems" type="hidden" runat="server">
            <input id="pageValues" type="hidden" runat="server"> <!--// page number;items per page --><input id="checkThis" type="hidden" runat="server">
            <input id="sealedTape" type="hidden" runat="server"> <input id="sealedCases" type="hidden" runat="server">
            <input id="verifyStage" type="hidden" runat="server">
        </form>
        <script language="javascript">
        var doDraw = false;
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
            var ti = countUnverified();
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
                c += serialNo; // + (tc.indexOf(';' + serialNo + '`1;') != -1 ? '`1;' : '`0;');
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
               // Serial number
               var serial = rowString.substring(0, p1);
               var caseName = rowString.substring(p1 + 1, p2);
               // Checked status
               var checkStatus = rowString.substring(p2+1);
               // Add the row
               addRow(serial, caseName, checkStatus);
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
        function addRow(serial, caseName, checkStatus)
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
            cell3.appendChild(document.createTextNode(caseName));
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
        //
        // Function: sealedTape
        //
        function sealedTape(serialNo)
        {
            var x = '';
            var i = -1;
            var c = getObjectById('caseSerials').value;

            while (c.length > 1 && (i = c.indexOf(';')) != -1)
            {
                if ((x = c.substring(0, i)).indexOf(serialNo + ',') != -1 || x.indexOf(serialNo + ')') != -1)
                {
                    // Get the name of the case
                    x = x.substring(0, x.indexOf('('));
                    // Check the sealed cases for the tape
                    if (getObjectById('sealedCases').value.indexOf(x + ';') != -1)
                    {
                        getObjectById('sealedTape').value = serialNo;
                        getObjectById('txtSerialNum').select();
                        return true;
                    }
                    else
                    {
						return false;
					};
                }
                else
                {
                    c = c.replace(x + ';', '');
                }
            }
            // Tape not in sealed case
            return false;
        }
        //
        // Function: doVerify
        //
        function doVerify()
        {
            var i = -1;
            doDraw = false;
            var cs = getObjectById('caseSerials').value;
            var control = getObjectById('txtSerialNum');
            var serialNo = control.value;
            // if no serial number, return
            if (serialNo.length == 0) {control.select(); return;}
            // if the item is already in the verified control, do nothing
            var x = ';' + getObjectById('verifyThese').value;
            if (x.indexOf(';' + serialNo + ';') != -1) {control.select(); return;}
            // If the item has already been verified, do nothing
            x = ';' + getObjectById('alreadyVerified').value;
            if (x.indexOf(';' + serialNo + ';') != -1) {control.select(); return;}
            // Attempt to verify the tape
            var returnValue = verifyTape(serialNo, false);
            // If tape was in a sealed case and verify stage was 1, submit and return
            if (returnValue == -2) {Form1.submit(); return;}
            // Is the item in the unverified tapes control?  If not, is it a case number?
            if (returnValue == -1)
            {
                if ((i = (';' + cs + '(').indexOf(';' + serialNo) - 1) != -2)
                {
                    // The item is a case.  We have to remove each item in the case from the
                    // unverified items control string.  Once done, we have to remove the
                    // tapes, but leave the case name.
                    var j1 = cs.indexOf('(', i) + 1;
                    var j2 = cs.indexOf(')', i) - 1;
                    // Only verify if tapes exist
                    if (j1 < j2)
                    {
                        // Get the tape list into an array
                        var ta = new Array();
                        ta = cs.substring(j1, j2+1).split(',');
                        // For each tape, move to verified
                        for (k = 0; k < ta.length; k++) verifyTape(ta[k], true);
                        // Remove the tapes from the case list
                        getObjectById('caseSerials').value = cs.replace(cs.substring(j1-1, j2 + 2), '()');
                        // Add to last scanned label
                        getObjectById('lblLastItem').innerHTML = serialNo;
                    }
                }
                else
                {
                    getObjectById('lblLastItem').innerHTML = serialNo;
                    getObjectById('checkThis').value = serialNo;
                    getObjectById('Form1').submit();
                    // Not a tape and not a case...we have to submit the form so that we can
                    // first determine if the tape is on the list or not (might already be verified), and then, if the tape
                    // is not on the list, so we can ask whether or not the user wants to add the new tape.
                }
            }
            // If the draw flag was set, render the table
            if (doDraw == true) renderTable();
            // Select the serial number field
            getObjectById('txtSerialNum').select();
            // If there are no tapes left in the unverified section, list is fully verified;
            // we have to submit it so that the verifications will be committed.
            if (getObjectById('unverifiedTapes').value.length == 0) getObjectById('btnLater').click();
        }
        //
        // Function: verifyTape
        //{
        function verifyTape(serialNo, ignoreSealed)
        {
            var u = ';' + getObjectById('unverifiedTapes').value;
            var i = u.indexOf(';' + serialNo + '`');
            // If -1, tape is not unverified
            if (i == -1) {getObjectById('txtSerialNum').select(); return -1;}
            // If the tape is in a sealed case and the verify stage is 1, return -2
            if (!ignoreSealed && getObjectById('verifyStage').value == '2' && sealedTape(serialNo))
            {
                getObjectById('txtSerialNum').select();
                return -2;
            }
            // Remove the item from the unverified control
            var c = u.substring(0, i) + u.substring(u.indexOf(';',i+1));
            getObjectById('unverifiedTapes').value = c.substring(1);
            // Insert the item into the verified control.
            c = serialNo + ';';
            getObjectById('verifyThese').value += c;
            // Decrement the total items
            var ti = parseInt(getObjectById('totalItems').value) - 1;
            getObjectById('totalItems').value = ti.toString();
            // If the tape was in the table contents, we have to redraw the table
            var m = ';' + getObjectById('tableContents').value;
            if (doDraw == false) doDraw = m.indexOf(';' + serialNo + '`') != -1;
            // Set the focus to the serial number text box
            getObjectById('txtSerialNum').select();
            // Decrement the items unverified label
            var o = getObjectById('lblItemsUnverified');
            o.innerHTML = (parseInt(o.innerHTML) - 1).toString();
            // Add to last scanned label
            getObjectById('lblLastItem').innerHTML = serialNo;
            // Return true
            return 1;
        }
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
        // function: countUnverified()
        //
        function countUnverified()
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
        // Render the table
        renderTable();       
        </script>
    </body>
</HTML>
