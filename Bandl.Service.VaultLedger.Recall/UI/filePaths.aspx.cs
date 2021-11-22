using System;
using System.IO;
using System.Web.UI.WebControls;
using Bandl.Service.VaultLedger.Recall.DAL;
using Bandl.Service.VaultLedger.Recall.Model;
using Bandl.Service.VaultLedger.Recall.Collections;

namespace Bandl.Service.VaultLedger.Recall.UI
{
	/// <summary>
	/// Summary description for accounts.
	/// </summary>
	public class filePaths : masterPage
	{
        protected System.Web.UI.WebControls.PlaceHolder PlaceHolder1;
        protected System.Web.UI.WebControls.DataGrid DataGrid1;
        protected System.Web.UI.HtmlControls.HtmlForm Form1;
        private LocalAccountCollection accountCollection;
    
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
            DataGrid1.EditCommand += new DataGridCommandEventHandler(DataGrid1_EditCommand);
            DataGrid1.CancelCommand += new DataGridCommandEventHandler(DataGrid1_CancelCommand);
            DataGrid1.UpdateCommand += new DataGridCommandEventHandler(DataGrid1_UpdateCommand);
        }
		#endregion

        /// <summary>
        /// Page load event handler
        /// </summary>
        protected override void Event_PageLoad(object sender, System.EventArgs e) 
        {
            if (this.IsPostBack)
            {
                accountCollection = (LocalAccountCollection)this.ViewState["AccountCollection"];
            }
            else
            {
                // Get the accounts from the database
                accountCollection = SQLServer.RetrieveGlobalAccounts();
                this.ViewState["AccountCollection"] = accountCollection;
                // Bind them to the datagrid
                DataGrid1.DataSource = accountCollection;
                DataGrid1.DataBind();
            }
        }

        private void DataGrid1_CancelCommand(object source, DataGridCommandEventArgs e)
        {
            DataGrid1.EditItemIndex = -1;
            DataGrid1.DataSource = accountCollection;
            DataGrid1.DataBind();
        }

        private void DataGrid1_EditCommand(object source, DataGridCommandEventArgs e)
        {
            DataGrid1.EditItemIndex = e.Item.ItemIndex;
            DataGrid1.DataSource = accountCollection;
            DataGrid1.DataBind();
        }

        private void DataGrid1_UpdateCommand(object source, DataGridCommandEventArgs e) 
        {
            LocalAccountDetails lad;
            // Retrieve the text boxes that contain the values to update.
            // For bound columns, the edited value is stored in a TextBox.
            // The TextBox is the 0th control in a cell's Controls collection.
            // Each cell in the Cells collection of a DataGrid item represents
            // a column in the DataGrid control.
            string accountNo = e.Item.Cells[0].Text;
            string filePath = ((TextBox)e.Item.Cells[1].Controls[0]).Text;
            // Make sure that the directory exists.  If it does, then update
            // the account.
            if (Directory.Exists(filePath) == false)
            {
                this.DisplayErrors(this.PlaceHolder1, "Path does not exist or is inaccessible to service");
            }
            else if ((lad = accountCollection.Find(accountNo)) == null)
            {
                this.DisplayErrors(this.PlaceHolder1, "Account not found within collection");
            }
            else
            {
                try
                {
                    lad.FilePath = filePath;
                    SQLServer.UpdateGlobalAccount(lad);
                    lad = SQLServer.RetrieveGlobalAccount(lad.Name);
                    this.ViewState["AccountCollection"] = accountCollection;
                    // Set the EditItemIndex property to -1 to exit editing mode. 
                    // Be sure to rebind the DateGrid to the data source to refresh
                    // the control.
                    DataGrid1.EditItemIndex = -1;
                    DataGrid1.DataSource = accountCollection;
                    DataGrid1.DataBind();
                }
                catch (Exception ex)
                {
                    this.DisplayErrors(this.PlaceHolder1, ex.Message);
                }
            }
        }
    }
}
