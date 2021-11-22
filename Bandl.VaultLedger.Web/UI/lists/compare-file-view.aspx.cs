using System;
using System.Web.UI.WebControls;
using Bandl.Library.VaultLedger.BLL;
using Bandl.Library.VaultLedger.Model;

namespace Bandl.VaultLedger.Web.UI
{
	/// <summary>
	/// Summary description for compare_file_view.
	/// </summary>
	public class compare_file_view : BasePage
	{
        protected System.Web.UI.WebControls.LinkButton listLink;
        protected System.Web.UI.WebControls.Label lblCaption;
        protected System.Web.UI.WebControls.Table Table1;
        private string scanName = null;
        private string listName = null;
	
        #region Web Form Designer generated code
        override protected void OnInit(EventArgs e)
        {
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
            this.listLink.Click += new EventHandler(listLink_Click);
        }
        #endregion

        /// <summary>
        /// Page initialization event handler (thrown by page master)
        /// </summary>
        protected override void Event_PageInit(object sender, System.EventArgs e)
        {
            this.helpId = 40;
            this.pageTitle = "Compare File View";
        }
        /// <summary>
        /// Page load event handler (thrown by page master)
        /// </summary>
        protected override void Event_PageLoad(object sender, System.EventArgs e)
        {
            if (Page.IsPostBack)
            {
                scanName = (string)ViewState["ScanName"];
                listName = (string)ViewState["ListName"];
            }
            else
            {
                scanName = Request.QueryString["fileName"];
                listName = Request.QueryString["listNumber"];
                // If scanName is null, check listName.  If we have a listname, redirect
                // to the appropriate list page.
                if (scanName == null && listName != null)
                {
                    Response.Redirect(listName.StartsWith("R") ? "receive-lists.aspx" : "send-lists.aspx", false);
                }
                else if (listName == null)
                {
                    Response.Redirect("todays-list.aspx", false);
                }
                // Place values in viewstate
                ViewState["ScanName"] = scanName;
                ViewState["ListName"] = listName;
                // Set the page caption
                lblCaption.Text = String.Format("Compare File View  :  {0}  (List: {1})", scanName, listName);
                // Create the table
                Table1.BorderColor = System.Drawing.Color.LightSlateGray;
                Table1.GridLines = GridLines.Both;
                Table1.BorderWidth = 1;
                // Create table headers
                TableRow newRow = new TableRow();
                TableCell newCell = new TableCell();
                newRow.Cells.Add(newCell);
                Label lblHeader = new Label();
                lblHeader.Text = "Serial Numbers";
                lblHeader.Font.Bold = true;
                newRow.CssClass = "header";
                newCell.Controls.Add(lblHeader);
                newCell.ColumnSpan = 5;
                Table1.Rows.Add(newRow);
                // Populate the table
                if (listName.StartsWith("S"))
                {
                    SendListScanDetails scanDetails = SendList.GetScan(scanName);
                    this.levelTwo = LevelTwoNav.Shipping;
                    if (scanDetails != null)
                    {
                        this.ViewSendCompareFile(scanDetails);
                    }
                    else
                    {
                        this.CreateNotFoundRow();
                    }
                }
                else
                {
                    ReceiveListScanDetails scanDetails = ReceiveList.GetScan(scanName);
                    this.levelTwo = LevelTwoNav.Receiving;
                    if (scanDetails != null)
                    {
                        this.ViewReceiveCompareFile(scanDetails);
                    }
                    else
                    {
                        this.CreateNotFoundRow();
                    }
                }
            }
        }
        /// <summary>
        /// Create a row informing the user that the compare file was not found
        /// </summary>
        private void CreateNotFoundRow()
        {
            TableRow newRow = new TableRow();
            Table1.Rows.Add(newRow);
            TableCell newCell = new TableCell();
            newRow.Cells.Add(newCell);
            newCell.ForeColor = System.Drawing.Color.Red;
            newCell.Text = "Compare file not found";
        }
        /// <summary>
        /// Retrieves the compare file for a send list
        /// </summary>
        private void ViewSendCompareFile(SendListScanDetails compareFile)
        {
            // Create rows of serial numbers
            for (int rowNo = 0; rowNo < Math.Ceiling((double)compareFile.ScanItems.Length / 5); rowNo++)
            {
                TableRow newRow = new TableRow();
                Table1.Rows.Add(newRow);
                // Alernate the rows
                if (rowNo % 2 != 0)
                {
                    newRow.CssClass = "alternate";
                }
                // Five serial numbers per row
                for (int itemNo = 0; itemNo < 5 && rowNo * 5 + itemNo < compareFile.ScanItems.Length; itemNo++)
                {
                    TableCell newCell = new TableCell();
                    newRow.Cells.Add(newCell);
                    newCell.Text = compareFile.ScanItems[rowNo * 5 + itemNo].SerialNo;
                }
            }
        }
        /// <summary>
        /// Retrieves the compare file for a send list
        /// </summary>
        private void ViewReceiveCompareFile(ReceiveListScanDetails compareFile)
        {
            // Create rows of serial numbers
            for (int rowNo = 0; rowNo < Math.Ceiling((double)compareFile.ScanItems.Length / 5); rowNo++)
            {
                TableRow newRow = new TableRow();
                Table1.Rows.Add(newRow);
                // Alernate the rows
                if (rowNo % 2 != 0)
                {
                    newRow.CssClass = "alternate";
                }
                // Five serial numbers per row
                for (int itemNo = 0; itemNo < 5 && rowNo * 5 + itemNo < compareFile.ScanItems.Length; itemNo++)
                {
                    TableCell newCell = new TableCell();
                    newRow.Cells.Add(newCell);
                    newCell.Text = compareFile.ScanItems[rowNo * 5 + itemNo].SerialNo;
                }
            }
        }
        /// <summary>
        /// Redirects back to compare file browse page
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="e"></param>
        private void listLink_Click(object sender, EventArgs e)
        {
            bool s = listName.StartsWith("SD") ? true : false;
            Response.Redirect(String.Format("{0}-list-reconcile.aspx?listNumber={1}", s ? "shipping" : "receiving", listName), false);
        }
    }
}
