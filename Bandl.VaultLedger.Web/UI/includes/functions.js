
function openBrowser(url)
{
	window.open(url, "openBrowser", "height=600,width=800,resizable=yes");
}

function getObjectById(documentId)
{
   if (document.getElementById)
   {
      return document.getElementById(documentId);
   }
   else if (document.all)
   {
      return document.all[documentId];
   }
   else if (document.layers)
   {
      return document.layers[documentId];
   }
   else
   {
      return null;
   }
}

function CheckAllDataGridCheckBoxes(aspCheckBoxID, checkVal)
{
	re = new RegExp(':' + aspCheckBoxID);

	for (i = 0; i < document.forms[0].elements.length; i++)
	{	
		elm = document.forms[0].elements[i];
		
		if (elm.type == 'checkbox')
		{
			if (re.test(elm.name))
			{
				elm.checked = checkVal;
			}
		}
	}
}

function UnCheckDataGridHeaderCheckBox(aspCheckBoxID)
{
	//generated control name starts with a colon
	re = new RegExp(':' + aspCheckBoxID);
	
	for (i=0; i < document.forms[0].elements.length; i++)
	{
		elm = document.forms[0].elements[i];
		
		if (elm.type == 'checkbox')
		{
			if (re.test(elm.name))
			{
				elm.checked = false;
				break;
			}
		}
	}
}

function checkAll(parent, checkBox, value)
{

    parentNode = getObjectById(parent)
    children = parentNode.getElementsByTagName('input')
    
    for (i = 0; i < children.length; i++)
    {
        if (children[i].type == 'checkbox' && children[i].id.indexOf(checkBox) != -1)
        {
            children[i].checked = value
        }
    }
    
}

function checkFirst(parent, checkBox, value)
{
    parentNode = getObjectById(parent)
    children = parentNode.getElementsByTagName('input')
    
    for (i = 0; i < children.length; i++)
    {
        if (children[i].type == 'checkbox' && children[i].id.indexOf(checkBox) != -1)
        {
            children[i].checked = value
            break;
        }
    }
}

function playSound(soundObj)
{
	var thissound = getObjectById(soundObj);
	if (thissound == null)
	{
		alert("Sound object does not exist!");
		return;
	}
	
	if (navigator.appName == "Netscape")
	{
		if (parseInt(navigator.appVersion) >= 3)
		{
			if (navigator.javaEnabled())
			{
				if (navigator.mimeTypes["audio/x-wav"] != null)
				{
					if (navigator.mimeTypes["audio/x-wav"].enabledPlugin != null)
					{
						thissound.play(false); // play sound in Netscape
					}
					else
						alert("Your browser does not have a plug-in to play audio/x-wav mime types!");
                }
				else
					alert("Your browser does not support the audio/x-wav mime type!");
            }
			else
				alert("Requires Java enabled to be enabled");
		}
		else
			alert("Only works in Netscape Navigator 3 or greater");
	}
	else
	{
		thissound.play(); // play sound in Explorer
	}
}

function keyCode(e)
{
    if (!e) var e = window.event;
    // Return the key value
    return e.keyCode ? e.keyCode : e.charCode;
}

function recallSerial(sText, finalized)
{
   var s1 = sText.toUpperCase().replace(/\s*/g, '');
   // Special recall format?
   if (finalized && s1.length >= 8 && (s1.match(/^[0-9]{4,5}[A-Z]{2}/) || s1.match(/^[A-Z][0-9]{3,4}[A-Z]{2}/)))
   {
      // Get rid of the first four characters, so we don't trip on the alpha in the serial number
      s1 = s1.substring(4);
      // Isolate the serial number portion (two spots after first letter)
      return s1.substring(s1.search(/[A-Z]/) + 2);
   }
   else
   {
      return s1;
   }
}

function upperOnly(textBox)
{
   if (textBox.value != textBox.value.toUpperCase())
      textBox.value = textBox.value.toUpperCase();
}

function digitsOnly(textBox)
{
   var sText = textBox.value;
   if (!sText.match(/^[0-9]*$/))
   {
      var newValue = ''
      for (i = 0; i < sText.length; i++)
         if (sText.substring(i,i+1).match(/^[0-9]$/))
            newValue += sText.substring(i,i+1);
      textBox.value = newValue;
   }
}

function stripCharsFromEnd(stringObject, numChars)
{
   if (numChars == 0) return stringObject;
   return stringObject.substr(0, stringObject.length - numChars);
}

function fakeFileUploads(imageName)
{
	if (document.createElement && document.getElementsByTagName)
	{
	    var fakeFile = document.createElement('div');
	    fakeFile.className = 'fakefile';
	    fakeFile.appendChild(document.createElement('input'));
	    var image = document.createElement('img');
	    image.src = imageName;
	    fakeFile.appendChild(image);
	    var x = document.getElementsByTagName('input');
	    for (var i = 0;i < x.length; i++)
	    {
		    if (x[i].type != 'file') continue;
		    if (x[i].parentNode.className != 'fileinputs') continue;
		    x[i].className = 'file hidden';
		    var clone = fakeFile.cloneNode(true);
		    x[i].parentNode.appendChild(clone);
		    x[i].relatedElement = clone.getElementsByTagName('input')[0];
		    x[i].onchange = x[i].onmouseout = function () {this.relatedElement.value = this.value;}
	    }
	}
}

function makeVisible(ctrl, doShow)
{
	if (document.layers)
	{
		document.layers[ctrl].visibility = (doShow ? 'show' : 'hide');
	}
	else if (document.all)
	{
		document.all[ctrl].style.visibility = (doShow ? 'visible' : 'hidden');
	}
	else if (getObjectById)
	{
		getObjectById(ctrl).style.visibility = (doShow ? 'visible' : 'hidden');

	}
}

function trim(s)
{
	if (s.length != 0)
	{
	   // Beginning of string
	   while (s.length != 0 && s.charCodeAt(0) <= 32)
          s = s.substring(1, s.length);
	   // End of string		
	   while (s.length != 0 && s.charCodeAt(s.length-1) <= 32)		
          s = s.substring(0, s.length-1);
	}
	// Return
	return s;		
}

function enterClick(button, e)
{
    if (!e) var e = window.event;
    var key = e.keyCode ? e.keyCode : e.charCode;
    // If not the enter key, just return
    if (key != 13) return true;
    // Stop propagation
    e.cancelBubble = true;
	if (e.stopPropagation) e.stopPropagation();
	// Give button focus
	button.focus();
    // Simulate button click and return false
    button.click();
    return false;
}

// This function tries several methods of creating the XmlHttpRequest object,
// depending on the browser in use. Also note that as of this writing, the
// Opera browser does not support the XmlHttpRequest.
function createXmlHttpRequest()
{
	try
	{
		q1 = new ActiveXObject("Msxml2.XMLHTTP");
	}
	catch(e)
	{
		try
		{
			q1 = new ActiveXObject("Microsoft.XMLHTTP");
		}
		catch(e1)
		{
			q1 = null;
		}
	}
    // If still no request, create manually
	if(!q1 && typeof XMLHttpRequest != 'undefined')
		q1 = new XMLHttpRequest();
    // Return the request
	return q1;
}

//
// Function: redirectPage - just redirects the current page
//
function redirectPage(url)
{
    location.href = url;
}

//
// Function: focusSelect - just redirects the current page
//
function focusSelect(id)
{
    getObjectById(id).focus();
    getObjectById(id).select();
}
