/*-----------------------------------------------------------------------------
*
* msgBox.js
*
* Contains functions that faciliate behavior of message boxes, such as
* centering and the ability to be draagged by the title bar.
*
*----------------------------------------------------------------------------*/
function getPosX(obj)
{
  var curLeft = 0;
  if(obj.offsetParent)
  {
    while (obj.offsetParent)
    {
      curLeft += obj.offsetLeft;
      obj = obj.offsetParent;
    }
  }
  else if (obj.x)
  {
    curLeft += obj.x;
  }
  return curLeft;
}

function getPosY(obj)
{
  var curTop = 0;
  if(obj.offsetParent)
  {
    while (obj.offsetParent)
    {
      curTop += obj.offsetTop;
      obj = obj.offsetParent;
    }
  }
  else if (obj.y)
  {
    curTop += obj.y;
  }
  return curTop;
}

function getStyle(obj, styleProp)
{
  if (window.getComputedStyle)
  {
    return window.getComputedStyle(obj,null).getPropertyValue(styleProp);
  }
  else if (obj.currentStyle)
  {
    return eval('obj.currentStyle.' + styleProp);
  }
  else
  {
    return null;
  }
}

function centerPanel(obj)
{
  var width = getStyle(obj, 'width')
  var height = getStyle(obj, 'height')
  
  if (document.layers)
  {
    obj.style.left = (window.innerWidth - parseInt(width)) / 2;
    obj.style.top = 100;
  }
  else
  {
    obj.style.left = (document.body.clientWidth - parseInt(width)) / 2;
    obj.style.top = 100;
  }
}

// Determines whether or not an element falls under a message box
function msgBoxElement(obj)
{
  while (obj.tagName.toUpperCase() != "BODY")
  {
    if (obj.id && obj.id.indexOf("msgBox") == 0)
    {
      return true
    }
    else
    {
      obj = obj.parentNode ? obj.parentNode : obj.parentElement
    }
  }
  // Not part of a message box
  return false
}

// Determines whether or not an element falls under a message box
function msgBoxLink(lnk)
{
  var obj = lnk.parentNode;
  
  while (obj.tagName.toUpperCase() != "BODY")
  {
    if (obj.id && obj.id.indexOf("msgBox") == 0)
    {
      return true
    }
    else
    {
      obj = obj.parentNode ? obj.parentNode : obj.parentElement
    }
  }
  // Not part of a message box
  return false
}

function disableElements()
{
   for(i = 0; i < document.forms.length; i++)
   {
     for(j = 0; j < document.forms[i].elements.length; j++)
     {
       var o = document.forms[i].elements[j]
       o.disabled = !msgBoxElement(o)
     }
   }
}

function enableElements()
{
  for(i = 0; i < document.forms.length; i++)
  {
    for(j = 0; j < document.forms[i].elements.length; j++)
    { 
       document.forms[i].elements[j].disabled = false
    }
  }
}

// We need to delay the disabling of links because datagrids do not seem to render
// until after the disabling script has run. Slight pause allows us to disable
// any links in any datagrid that may appear on the page.
function disableLinks()
{
    setTimeout('disableLinksDelay()', 100);
}

function enableLinks()
{
    setTimeout('enableLinksDelay()', 100);
}

function disableLinksDelay()
{
   for(i = 0; i < document.links.length; i++)
   {
     if (!document.links[i].id || !msgBoxLink(document.links[i]))
     {
       document.links[i].onclick = Function("return false;")
     }
   }
}

function enableLinksDelay()
{
   for(i = 0; i < document.links.length; i++)
   {
     document.links[i].onclick = Function("return true;")
   }
}

function hideMsgBox(id)
{
  enableLinks()
  enableElements()
  getObjectById(id).style.display = 'none'
}

function showMsgBox(id)
{
  o = getObjectById(id);
  centerPanel(o);
  disableLinks();
  disableElements();
  o.style.display = 'block';
  playBeep();   // Won't do anything if message box renders immediately
}
//
// Function: playBeep -- used for calling message boxes from javascript
//
function playBeep()
{
    var o = eval('document.beep');
    // Do we have anything?
    if (o == null) return;
    // Play the beep
    if (navigator.appName == 'Netscape')
    {
        o.play();
    }
    else
    {
        if (document.playSound == null)
        {
            var x = null;
            document.playSound = false;
            
            for (x in o) 
            {
                if (x == "ActiveMovie")
                {
                    document.playSound = true; 
                    break;
                }
            }
        }
        // Play sound?
        if (document.playSound)
        {
            o.SelectionStart = 0;
            o.play();
        }
    }
}
