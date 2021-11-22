using System;
using System.Data;
using System.Web.UI.WebControls;
using System.Web.UI.HtmlControls;
using Bandl.Library.VaultLedger.Security;
using Bandl.Library.VaultLedger.Collections;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.BLL;

namespace Bandl.VaultLedger.Web.UI
{
	/// <summary>
	/// Summary description for view_sites.
	/// </summary>
	public class view_sites : BasePage
	{
		protected System.Web.UI.WebControls.DataGrid DataGrid1;
		protected System.Web.UI.WebControls.PlaceHolder PlaceHolder1;
		protected System.Web.UI.WebControls.Button btnYes;
		protected System.Web.UI.WebControls.Button btnNo;
        protected System.Web.UI.WebControls.Button btnDelete;
        protected System.Web.UI.WebControls.Button btnNew;
        protected System.Web.UI.WebControls.LinkButton printLink;
		protected System.Web.UI.HtmlControls.HtmlForm Form1;

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
            this.printLink.Click += new System.EventHandler(this.printLink_Click);
            this.btnDelete.Click += new System.EventHandler(this.btnDelete_Click);
            this.btnNew.Click += new System.EventHandler(this.btnNew_Click);
            this.btnYes.Click += new System.EventHandler(this.btnYes_Click);
            this.DataGrid1.PreRender += new EventHandler(DataGrid1_PreRender);

        }
        #endregion

        /// <summary>
        /// Page initialization event handler (thrown by page master)
        /// </summary>
        protected override void Event_PageInit(object sender, System.EventArgs e)
        {
            this.helpId = 25;
            this.pageTitle = "Site Maps";
            this.levelTwo = LevelTwoNav.SiteMaps;
            // Click events for message box buttons
            this.SetControlAttr(btnYes, "onclick", "hideMsgBox('msgBoxDelete');");
            this.SetControlAttr(btnNo, "onclick", "hideMsgBox('msgBoxDelete');");
            // Security permission only for administrators.  If we are one,
            // go ahead and set up the page.
            DoSecurity(Role.Administrator, "default.aspx");
        }
        /// <summary>
        /// Page load event handler (thrown by page master)
        /// </summary>
        protected override void Event_PageLoad(object sender, System.EventArgs e)
		{
            if (!Page.IsPostBack)
                this.FetchExternalSiteMaps();
		}
        /// <summary>
        /// Fetches the external site maps and binds them to the database
        /// </summary>
        private void FetchExternalSiteMaps()
        {
            ExternalSiteCollection externalSites = ExternalSite.GetExternalSites();
            DataGrid1.DataSource = externalSites;
            DataGrid1.DataBind();
            // Add to the viewstate
            this.ViewState["ExternalSites"] = externalSites;
        }
        /// <summary>
        /// If there is no data, create a datatable and fill it with a dummy row
        /// </summary>
        private void DataGrid1_PreRender(object sender, EventArgs e)
        {
            if (((ExternalSiteCollection)this.ViewState["ExternalSites"]).Count == 0)
            {
                DataTable dataTable = new DataTable();
                dataTable.Columns.Add("Id", typeof(int));
                dataTable.Columns.Add("Name", typeof(string));
                dataTable.Columns.Add("Location", typeof(string));
                dataTable.Columns.Add("Account", typeof(string));
                dataTable.Rows.Add(new object[] {0, String.Empty, String.Empty});
                // Bind the datagrid to the empty table
                this.DataGrid1.DataSource = dataTable;
                this.DataGrid1.DataBind();
                // Create the text in the first column and render the
                // checkbox column invisible
                this.DataGrid1.Columns[0].Visible = false;
                this.DataGrid1.Items[0].Cells[1].Text = "No site maps defined";
            }
            // If not a postback, check license to see whether or not we should display the account column
            if (!Page.IsPostBack)
                this.DataGrid1.Columns[3].Visible = Preference.GetPreference(PreferenceKeys.AllowTMSAccountAssigns).Value == "YES";
        }
        /// <summary>
        /// Event handler for the delete button.  Pops up the delete confirmation box.
        /// </summary>
		private void btnDelete_Click(object sender, System.EventArgs e)
		{
            if (this.CollectCheckedItems(this.DataGrid1).Length != 0)
            {
                this.ShowMessageBox("msgBoxDelete");
            }
		}
        /// <summary>
        /// Event handler for delete confirmation button
        /// </summary>
		private void btnYes_Click(object sender, System.EventArgs e)
		{
            ExternalSiteCollection deletedSites = new ExternalSiteCollection();
            ExternalSiteCollection currentSites = (ExternalSiteCollection)this.ViewState["ExternalSites"];
            // Remove the checked site maps from the collection
            foreach (DataGridItem dgi in this.CollectCheckedItems(this.DataGrid1))
            {
                if (((HtmlInputCheckBox)dgi.Cells[0].Controls[1]).Checked)
                {
                    ExternalSiteDetails siteMap = currentSites.Find(dgi.Cells[1].Text);
                    if (siteMap != null) deletedSites.Add(siteMap);
                }
            }
            // Update all items in the collection
            foreach (ExternalSiteDetails externalSite in deletedSites)
            {
                try
                {
                    ExternalSiteDetails tempSite = externalSite;
                    ExternalSite.Delete(ref tempSite);
                }
                catch (Exception ex)
                {
                    this.DisplayErrors(this.PlaceHolder1, ex.Message);
                    break;
                }
            }
            // Retrieve the external sites again
            this.FetchExternalSiteMaps();
		}
        /// <summary>
        /// Event handler for new site button
        /// </summary>
        private void btnNew_Click(object sender, System.EventArgs e)
        {
            Response.Redirect("add-sites.aspx", false);
        }
        /// <summary>
        /// Print function to be called asynchronously
        /// </summary>
        private void printLink_Click(object sender, System.EventArgs e)
        {
            Session[CacheKeys.PrintSource] = PrintSources.ExternalSitePage;
            Session[CacheKeys.PrintObjects] = new object[] {(ExternalSiteCollection)this.ViewState["ExternalSites"]};
            ClientScript.RegisterStartupScript(GetType(), "printWindow", "<script>openBrowser('../waitPage.aspx?redirectPage=print.aspx&x=" + Guid.NewGuid().ToString("N") + "')</script>");
        }
    }
}
