<%@ Page language="c#" Codebehind="waitPage.aspx.cs" AutoEventWireup="false" Inherits="Bandl.Utility.VaultLedger.Registrar.UI.waitPage" %>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<HTML>
    <HEAD>
        <meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
        <meta content="http://schemas.microsoft.com/intellisense/ie5" name="vs_targetSchema">
        <!--#include file = "masterHead.inc"-->
    </HEAD>
    <body id="b1">
        <!--#include file = "masterBody.inc"-->
        <DIV class="contentWrapper">
            <DIV class="pageHeader"></DIV>
            <FORM id="Form1" runat="server">
                <div id="contentBorderTop"></div>
                <DIV class="contentArea">
                    <TABLE class="detailTable">
                        <TR>
                            <TD style="PADDING-BOTTOM:12px;PADDING-TOP:12px;TEXT-ALIGN:center">
                                Please wait while your
                                <%=ProductTitle%>
                                application is created.
                            </TD>
                        </TR>
                        <TR valign="top">
                            <TD style="TEXT-ALIGN:center">
                                <img id="pleaseWait" name="pleaseWait" src="resources/img/recall/pleaseWait.gif" runat="server">
                            </TD>
                        </TR>
                        <TR>
                            <TD style="PADDING-BOTTOM:12px;PADDING-TOP:12px;TEXT-ALIGN:center">
                                This may take a few minutes. During this time, please do not click the Back 
                                button on your browser.
                            </TD>
                        </TR>
                    </TABLE>
                </DIV>
            </FORM>
        </DIV>
        <input id="nextUrl" type="hidden" runat="server" NAME="nextUrl"> <input id="gifPath" type="hidden" runat="server" NAME="gifPath">
        <input id="errorUrl" type="hidden" runat="server" NAME="errorUrl">
        <script language="javascript">
	    <!--
	    var q = null;
	    var b = false;
        var minTime = new Date().getTime() + 2000;
        
        // Sets the gif
        getObjectById('pleaseWait').src = getObjectById('gifPath').value;

	    // this tells the wait page to check the status every so often
	    window.setInterval("doStatus()", 500);
    	
	    function doStatus()
	    {
		    if(!b && createReq() != null)
		    {
			    q.onreadystatechange = checkState;
			    q.open("GET", "status.aspx", true);
			    q.send(null);
		    }
	    }

	    function checkState()
	    {
		    if (q.readyState == 4 && q.status == 200) 
		    {
			    if (q.responseText == "1")
			    {
				    b = true;
				    url = getObjectById('nextUrl').value;
				    window.setTimeout("location.replace('" + url + "')", minTime - new Date().getTime());
		        }
		        else if (q.responseText == "E")
			    {
				    b = true;
				    url = getObjectById('errorUrl').value;
				    window.setTimeout("location.replace('" + url + "')", minTime - new Date().getTime());
		        }
		    }
	    }

	    /*
	    Note that this tries several methods of creating the XmlHttpRequest object,
	    depending on the browser in use. Also note that as of this writing, the
	    Opera browser does not support the XmlHttpRequest.
	    */
	    function createReq()
	    {
		    try
		    {
			    q = new ActiveXObject("Msxml2.XMLHTTP");
		    }
		    catch(e)
		    {
			    try
			    {
				    q = new ActiveXObject("Microsoft.XMLHTTP");
			    }
			    catch(oc)
			    {
				    q = null;
			    }
		    }

		    if(!q && typeof XMLHttpRequest != "undefined")
			    q = new XMLHttpRequest();
    		
		    return q;
	    }
        //-->
        </script>
    </body>
</HTML>
