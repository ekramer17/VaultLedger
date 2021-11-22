/*-----------------------------------------------------------------------------
*
* calendar.js
*
* Pops up the calendar page.  Supply the full name of the control into which
* the result should be placed
*
*----------------------------------------------------------------------------*/
function openCalendar(controlName)
{
   calendar_window = window.open('../includes/calendar.aspx?controlName=' + controlName,
                                 'calendar_window',
                                 'left=100, top=100, width=260, height=240, location=no, menubar=no, resizable=no, scrollbars=no, status=no, toolbar=no');
   if (!calendar_window) 
   {
      alert("To use the calendar window, you must disable popup blockers.");
   }
   else
   {
      calendar_window.focus();
   }
}
