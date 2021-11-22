using System;
using System.Data;
using System.Web.UI.WebControls;
using System.Web.UI.HtmlControls;
using Bandl.Library.VaultLedger.BLL;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.Collections;
using Bandl.Library.VaultLedger.Security;

namespace Bandl.VaultLedger.Web.UI
{
	/// <summary>
	/// Summary description for ftp_profiles.
	/// </summary>
	public class ftp_profiles : BasePage
	{
        protected System.Web.UI.WebControls.DataGrid DataGrid1;
        protected System.Web.UI.WebControls.PlaceHolder PlaceHolder1;
        protected System.Web.UI.WebControls.Button btnDelete;
        protected System.Web.UI.WebControls.Button btnNew;
        protected System.Web.UI.WebControls.Button btnYes;
        protected System.Web.UI.WebControls.Button btnNo;
        private FtpProfileCollection profileCollection;
    
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
            this.btnDelete.Click += new System.EventHandler(this.btnDelete_Click);
            this.btnNew.Click += new System.EventHandler(this.btnNew_Click);
            this.btnYes.Click += new System.EventHandler(this.btnYes_Click);

        }
		#endregion

        /// <summary>
        /// Page initialization event handler (thrown by page master)
        /// </summary>
        protected override void Event_PageInit(object sender, System.EventArgs e)
        {
            this.helpId = 51;
            this.pageTitle = "FTP Profiles";
            this.levelTwo = LevelTwoNav.FtpProfiles;
            // Click events for message box buttons
            this.SetControlAttr(btnYes, "onclick", "hideMsgBox('msgBoxDel');");
            this.SetControlAttr(btnNo,  "onclick", "hideMsgBox('msgBoxDel');");
            // Security permission only for administrators.  If we are one,
            // go ahead and set up the page.
            DoSecurity(Role.Administrator, "default.aspx");
        }
        /// <summary>
        /// Page load event handler
        /// </summary>
        protected override void Event_PageLoad(object sender, System.EventArgs e) 
        {
            // If not postback, collect the data from the database into a datatable.
            if (this.IsPostBack)
            {
                profileCollection = (FtpProfileCollection)this.ViewState["Profiles"];
            }
            else
            {
                this.FetchCollection();
            }
        }
        /// <summary>
        /// Page prerender event handler
        /// </summary>
        protected override void Event_PagePreRender(object sender, System.EventArgs e) 
        {
            // If we have no lists for the datagrid, then create an empty table
            // with one row so that we may display a message to the user.
            if (profileCollection.Count == 0)
            {
                DataTable dataTable = new DataTable();
                dataTable.Columns.Add("Id", typeof(int));
                dataTable.Columns.Add("Name", typeof(string));
                dataTable.Columns.Add("Server", typeof(string));
                dataTable.Columns.Add("Login", typeof(string));
                dataTable.Columns.Add("Passive", typeof(bool));
                dataTable.Columns.Add("Secure", typeof(bool));
                dataTable.Columns.Add("FilePath", typeof(string));
                dataTable.Rows.Add(new object[] {0, "", "", "", false, false, ""});
                // Bind the datagrid to the empty table
                this.DataGrid1.DataSource = dataTable;
                this.DataGrid1.DataBind();
                // Create the text in the first column and render the
                // checkbox column invisible
                this.DataGrid1.Columns[0].Visible = false;
                this.DataGrid1.Items[0].Cells[1].Text = "No profiles exist";
                // Must blank out the boolean cells
                this.DataGrid1.Items[0].Cells[4].Text = String.Empty;
                this.DataGrid1.Items[0].Cells[5].Text = String.Empty;
            }
        }
        /// <summary>
        /// Fetches the FTP profiles from the database and binds them to the datagrid
        /// </summary>
        private void FetchCollection()
        {
            profileCollection = FtpProfile.GetProfiles();
            this.ViewState["Profiles"] = profileCollection;
            // Bind table to the datagrid
            DataGrid1.DataSource = profileCollection;
            DataGrid1.DataBind();
        }
        /// <summary>
        /// Create a new profile
        /// </summary>
        private void btnNew_Click(object sender, System.EventArgs e)
        {
            Server.Transfer("ftp-detail.aspx");        
        }
        /// <summary>
        /// Deletes selected profiles
        /// </summary>
        private void btnDelete_Click(object sender, System.EventArgs e)
        {
            this.ShowMessageBox("msgBoxDel");
        }
        /// <summary>
        /// Event handler for Delete Confirmation button
        /// </summary>
        private void btnYes_Click(object sender, System.EventArgs e)
        {
            // Delete each of the checked operators
            foreach (DataGridItem dgi in this.CollectCheckedItems(this.DataGrid1))
            {
                if (((HtmlInputCheckBox)dgi.Cells[0].Controls[1]).Checked)
                {
                    try
                    {
                        FtpProfile.Delete(profileCollection[dgi.ItemIndex]);
                    }
                    catch (Exception ex)
                    {
                        this.DisplayErrors(this.PlaceHolder1, ex.Message);
                    }
                }
            }
            // Refetch the profiles
            this.FetchCollection();
        }
    }
}
