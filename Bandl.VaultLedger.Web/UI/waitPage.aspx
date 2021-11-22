<%@ Page language="c#" Codebehind="waitPage.aspx.cs" AutoEventWireup="false" Inherits="Bandl.VaultLedger.Web.UI.waitPage" %>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<HTML>
    <HEAD>
        <META http-equiv="Content-Type" content="text/html; charset=windows-1252">
        <meta content="Microsoft Visual Studio .NET 7.1" name="GENERATOR">
        <meta content="C#" name="CODE_LANGUAGE">
        <meta content="JavaScript" name="vs_defaultClientScript">
        <meta content="http://schemas.microsoft.com/intellisense/ie5" name="vs_targetSchema">
        <!--#include file = "includes/baseHead.inc"-->
    </HEAD>
    <body>
        <!--#include file = "includes/baseBody.inc"-->
        <form id="Form1" method="post" runat="server">
            <div class="contentWrapper">
                <!-- page header -->
                <div class="pageHeader">
                    <h1>Busy&nbsp;....&nbsp;Please Wait</h1>
                </div> <!-- end pageHeader //-->
                <div class="contentArea" id="contentBorderTop">
                    <table class="detailTable">
                        <tr>
                            <td style="PADDING-BOTTOM:12px; PADDING-TOP:12px; TEXT-ALIGN:center"><asp:label id="lblWaitText" Runat="server">Please wait for [insert action here].</asp:label></td>
                        </tr>
                        <tr vAlign="top">
                            <td style="TEXT-ALIGN:center"><img id="pleaseWait" src="" name="pleaseWait" runat="server"></td>
                        </tr>
                        <tr>
                            <td style="PADDING-BOTTOM: 12px; PADDING-TOP: 12px; TEXT-ALIGN: center">This may 
                                take a few minutes.&nbsp;&nbsp;During this time, please do not click the Back 
                                button on your browser.
                            </td>
                        </tr>
                        <tr>
                            <td style="TEXT-ALIGN:right"><span style="PADDING-RIGHT:10px" class="tinted" id="elapsed">0:00</span></td>
                        </tr>
                    </table>
                </div>
            </div>
        </form>
        <input id="url" type="hidden" runat="server"> <input id="gif" type="hidden" runat="server">
        <input id="eUrl" type="hidden" runat="server"> <input id="rUrl" type="hidden" runat="server">
        <script language="javascript">
	    var q = null;
	    var sTime = new Date().getTime();
        var minTime = sTime + 1750;
        // Sets the gif
        getObjectById('pleaseWait').src = getObjectById('gif').value;
        // Post the request
        setTimeout('doRequest()', 10);
        // Updates the timer on the wait page
        window.setInterval("doElapsed()", 1000);
        
        function doRequest()
        {
            q = createXmlHttpRequest();
            q.onreadystatechange = initiate;
            // 'true' specifies that it's a async call.  Url should be handled by the asynchronous handler.
            q.open("GET", getObjectById('rUrl').value, true);
            // Send the request.  Note that no callback is necessary, as we will monitor the request using the status.aspx page
            q.send(null);
        }

        function initiate()
        {
            if (q.readyState == 4) 
            {
                if (q.status == 200)
                {
                    q = createXmlHttpRequest();
                    q.onreadystatechange = checkState;
                    q.open("GET", "status.aspx", true);
                    q.send(null);
                }
            }
        }

        function checkState()
        {
            if (q.readyState == 4) 
            {
                if (q.status == 200)
                {
                    if (q.responseText == "1")
                    {
                        window.setTimeout("location.replace('" + getObjectById('url').value + "')", minTime - new Date().getTime());
                    }
                    else if (q.responseText == "E")
                    {
                        window.setTimeout("location.replace('" + getObjectById('eUrl').value + "')", minTime - new Date().getTime());
                    }
                }
            }
        }

	    function doElapsed()
	    {
	        eTime = new Date((new Date().getTime() - sTime));
	        mm = eTime.getMinutes().toString();
	        ss = eTime.getSeconds().toString();
	        if (ss.length == 1) ss = '0' + ss;
	        getObjectById('elapsed').innerHTML = mm + ':' + ss;
	    }
        </script>
    </body>
</HTML>
