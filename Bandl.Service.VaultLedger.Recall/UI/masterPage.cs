using System;
using System.Drawing;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Web.UI.HtmlControls;

namespace Bandl.Service.VaultLedger.Recall.UI
{
    public class masterPage : Page
    {
        protected void SetFocus(Control ctrl)
        {
            // Define the JavaScript function for the specified control.
            string focusScript = "<script language='javascript'>document.getElementById('" + ctrl.ClientID + "').focus();</script>";
            // Add the JavaScript code to the page.
            Page.RegisterStartupScript("SetControlFocus", focusScript);
        }

        /// <summary>
        /// Page load event tripped by load in this base page.  Page
        /// classes descending from this class should override this
        /// method and implement page loading code in it rather than
        /// creating a Page_Load event handler, which would override
        /// the one in this base page.
        /// </summary>
        virtual protected void Event_PageLoad(object sender, System.EventArgs e) {}

        /// <summary>
        /// Page load event handler.  No descendents should implement
        /// a page load event handler.  Override the Event_PageLoad 
        /// method instead.
        /// </summary>
        protected void Page_Load(object sender, System.EventArgs e)
        {
            Event_PageLoad(sender, e);
        }

        #region Web Form Designer generated code
        override protected void OnInit(EventArgs e)
        {
            //
            //
            // CODEGEN: This call is required by the ASP.NET Web Form Designer.
            //
            InitializeComponent();
            base.OnInit(e);
        }
             
        /// <summary>
        /// Required method for Designer support - do not modify
        /// the contents of this method with the code editor.
        /// </summary>
        private void InitializeComponent()
        {    
            this.Load += new System.EventHandler(this.Page_Load);

        }
        #endregion
    
        #region Error Display Methods
        /// <summary>
        /// Displays an error message, in a label within the given placeholder.
        /// </summary>
        /// <param name="placeHolder">
        /// Placeholder in which to create a table containing the error message
        /// </param>
        /// <param name="eMessage">
        /// An error message ro display
        /// </param>
        protected void DisplayErrors(PlaceHolder placeHolder, string eMessage)
        {
            this.DisplayErrors(placeHolder, new string[1] {eMessage});
        }
        /// <summary>
        /// Displays an error message, in a label within the given placeholder.
        /// </summary>
        /// <param name="placeHolder">
        /// Placeholder in which to create a table containing the error message
        /// </param>
        /// <param name="eMessage">
        /// An error message ro display
        /// </param>
        /// <param name="caption">
        /// Caption to display before displaying the error messages
        /// </param>
        protected void DisplayErrors(PlaceHolder placeHolder, string eMessage, string caption)
        {
            this.DisplayErrors(placeHolder, new string[1] {eMessage}, caption);
        }
        /// <summary>
        /// Displays an array of error messages, one on each line, in the given
        /// placeholder.  A table is created in the placeholder and one error
        /// message is placed on each line.
        /// </summary>
        /// <param name="placeHolder">
        /// Placeholder in which to create a table containing the error messages
        /// </param>
        /// <param name="eMessages">
        /// An array of error messages ro display
        /// </param>
        protected void DisplayErrors(PlaceHolder placeHolder, string[] eMessages)
        {
            this.DisplayErrors(placeHolder, eMessages, "The following error(s) have occurred:");
        }
        /// <summary>
        /// Displays an array of error messages, one on each line, in the given
        /// placeholder.  A table is created in the placeholder and one error
        /// message is placed on each line.
        /// </summary>
        /// <param name="placeHolder">
        /// Placeholder in which to create a table containing the error messages
        /// </param>
        /// <param name="eMessages">
        /// An array of error messages ro display
        /// </param>
        /// <param name="caption">
        /// Caption to display before displaying the error messages
        /// </param>
        protected void DisplayErrors(PlaceHolder placeHolder, string[] eMessages, string caption)
        {
            Table tblError = null;
            // If there is already a table in the placeholder, then get
            // a reference to it.  Otherwise, create a new table.
            if (placeHolder.Controls.Count != 0 && placeHolder.Controls[0] is Table)
            {
                tblError = (Table)placeHolder.Controls[0];
            }
            else
            {
                tblError = new Table();
                tblError.BackColor = Color.LightGray;
            }
            // Add the row announcing that errors have occurred
            TableRow newRow = new TableRow();
            TableCell newCell = new TableCell();
            Label errorText = new Label();
            errorText.ForeColor = Color.Red;
            errorText.Text = caption;
            newCell.Controls.Add(errorText);
            newRow.Cells.Add(newCell);
            tblError.Rows.Add(newRow);
            // Add the error messages to the table
            foreach(string eMessage in eMessages)
            {
                newRow = new TableRow();
                newCell = new TableCell();
                errorText = new Label();
                errorText.ForeColor = Color.Red;
                errorText.Text = "* " + eMessage;
                newCell.Controls.Add(errorText);
                newRow.Cells.Add(newCell);
                tblError.Rows.Add(newRow);
            }
            // Add the table to the placeholder
            placeHolder.Controls.Add(tblError);
        }

        #endregion
    }
}
