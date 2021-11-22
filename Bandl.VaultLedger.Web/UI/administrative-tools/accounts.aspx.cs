using System;
using System.Web;
using System.Text;
using System.Collections;
using System.Web.UI.WebControls;
using System.Web.UI.HtmlControls;
using Bandl.Library.VaultLedger.BLL;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.Exceptions;
using Bandl.Library.VaultLedger.Collections;
using Bandl.Library.VaultLedger.Security;
using System.Collections.Specialized;

namespace Bandl.VaultLedger.Web.UI
{
	/// <summary>
	/// Summary description for accounts_template.
	/// </summary>
	public class accounts : BasePage
	{
        private AccountCollection accountCollection = null;
        protected System.Web.UI.WebControls.Button btnUpdate;
        protected System.Web.UI.WebControls.PlaceHolder PlaceHolder1;
        protected System.Web.UI.WebControls.LinkButton printLink;
        protected System.Web.UI.HtmlControls.HtmlGenericControl contentBottom;
        protected System.Web.UI.WebControls.Label lblPageCaption;
		protected System.Web.UI.WebControls.Button btnDelete;
		protected System.Web.UI.WebControls.Button btnNew;
		protected System.Web.UI.WebControls.Button btnYes;
		protected System.Web.UI.WebControls.Button btnNo;
        protected System.Web.UI.WebControls.Image smallGlobe;
        protected System.Web.UI.WebControls.DataGrid DataGrid1;

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
            this.btnUpdate.Click += new System.EventHandler(this.btnUpdate_Click);
            this.DataGrid1.ItemDataBound += new System.Web.UI.WebControls.DataGridItemEventHandler(this.DataGrid1_ItemDataBound);
            this.btnYes.Click += new System.EventHandler(this.btnYes_Click);

        }
        #endregion

        /// <summary>
        /// Modifies the page based on product type
        /// </summary>
        private void ProductTypePageSetup()
        {
			if (!this.IsPostBack)
			{
				StringBuilder captionText = new StringBuilder();

				switch (Configurator.ProductType)
				{
					case "RECALL":
                        captionText.Append("&nbsp;&nbsp;To get up-to-date account information, click Update Accounts.");
						this.DataGrid1.Columns[0].Visible = false;
						this.btnDelete.Visible = false;
						this.btnNew.Visible = false;
						break;
                    case "B&L":
                    case "BANDL":
                    case "IMATION":
                        captionText.Append("&nbsp;&nbsp;To delete an account, select it and then click Delete Accounts.");
						captionText.Append("&nbsp;&nbsp;To create a new account, click New Account.");
						this.DataGrid1.Columns[1].Visible = false;
						this.contentBottom.Visible = false;
						this.btnUpdate.Visible = false;
						break;
				}

				this.lblPageCaption.Text = captionText.ToString();
			}
        }
        /// <summary>
        /// Page initialization event handler (thrown by page master)
        /// </summary>
        protected override void Event_PageInit(object sender, System.EventArgs e)
        {
            this.levelTwo = LevelTwoNav.Accounts;
            this.pageTitle = "Accounts";
            this.helpId = 29;
            // Security permission only for administrators.  If we are one,
            // go ahead and set up the page.
            DoSecurity(Role.Administrator, "default.aspx");
        }
        /// <summary>
        /// Page load event handler (thrown by page master)
        /// </summary>
        protected override void Event_PageLoad(object sender, System.EventArgs e)
        {
			// Click events for message box buttons
			this.SetControlAttr(btnYes, "onclick", "hideMsgBox('msgBoxDelete');");
			this.SetControlAttr(btnNo, "onclick", "hideMsgBox('msgBoxDelete');");
			// Get the accounts from the database
			if (!Page.IsPostBack)
            {
				this.FetchAccounts();
            }
            else
            {
                accountCollection = (AccountCollection)this.ViewState["AccountCollection"];
            }
			// Set up the page
			this.ProductTypePageSetup();
            // Globe icon image control
            smallGlobe.AlternateText = String.Empty;
            smallGlobe.ImageUrl = ImageVirtualDirectory + "/misc/globe1.gif";
		}
		/// <summary>
		/// Data binding event handler
		/// </summary>
		private void DataGrid1_ItemDataBound(object sender, DataGridItemEventArgs e)
		{
			if (e.Item.ItemIndex != -1)	// Headers and footers are -1
			{
                Image globeCtrl = (Image)e.Item.FindControl("imgGlobe");
				globeCtrl.Visible = accountCollection[e.Item.ItemIndex].Primary;
                globeCtrl.ImageUrl = ImageVirtualDirectory + "/misc/globe1.gif";
			}
		}
		/// <summary>
		/// Fetches the accounts from the database and binds them to the datagrid
		/// </summary>
		private void FetchAccounts()
		{
			// Fetch the accounts
			accountCollection = Account.GetAccounts();
			this.ViewState["AccountCollection"] = accountCollection;
			// Bind account collection to the datagrid
			DataGrid1.DataSource = accountCollection;
			DataGrid1.DataBind();
		}
		/// <summary>
        /// Event handler for the account update button
        /// </summary>
        private void btnUpdate_Click(object sender, System.EventArgs e)
        {
            try
            {
                Account.SynchronizeAccounts(true);
				this.FetchAccounts();
			}
            catch (Exception ex)
            {
                this.DisplayErrors(this.PlaceHolder1, ex.Message);
            }
        }
        /// <summary>
        /// Print function to be called asynchronously
        /// </summary>
        private void printLink_Click(object sender, System.EventArgs e)
        {
            Session[CacheKeys.PrintSource] = PrintSources.AccountsPage;
            Session[CacheKeys.PrintObjects] = new object[] {this.accountCollection};
            ClientScript.RegisterStartupScript(GetType(), "printWindow", "<script>openBrowser('../waitPage.aspx?redirectPage=print.aspx&x=" + Guid.NewGuid().ToString("N") + "')</script>");
        }
		/// <summary>
		/// Delete button - prompts confirmation
		/// </summary>
		private void btnDelete_Click(object sender, System.EventArgs e)
		{
            this.ShowMessageBox("msgBoxDelete");
		}
		/// <summary>
		/// New account button handler
		/// </summary>
		private void btnNew_Click(object sender, System.EventArgs e)
		{
            Server.Transfer("account-detail.aspx");
		}
		/// <summary>
		/// Delete confirmation
		/// </summary>
		private void btnYes_Click(object sender, System.EventArgs e)
		{
			int i;
            bool doFetch = true;
			StringCollection errorList = new StringCollection();
			StringCollection errorAccounts = new StringCollection();
			AccountCollection deleteCollection = new AccountCollection();
			// Add the accounts to the collection
			foreach (DataGridItem item in this.CollectCheckedItems(this.DataGrid1))
				deleteCollection.Add(accountCollection[item.ItemIndex]);
			// Delete the accounts
            try
            {
                Account.Delete(deleteCollection);
            }
            catch (CollectionErrorException ex)
            {
                foreach (AccountDetails a in (AccountCollection)ex.Collection)
                {
                    if (a.RowError.Length != 0)
                    {
                        errorList.Add(a.RowError);
                        errorAccounts.Add(a.RowError);
                    }
                }
            }
            catch (Exception ex)
            {
                doFetch = false;
                this.DisplayErrors(this.PlaceHolder1, ex.Message);
            }
			// Refetch the account if required
            if (doFetch == true)
            {
                this.FetchAccounts();
                // If no errors, just return
                if (errorList.Count == 0) return;
                // Display errors
                this.DisplayErrors(this.PlaceHolder1, errorList);
                // Check any medium type that had errors
                foreach (string accountName in errorAccounts)
                    if ((i = accountCollection.IndexOf(accountName)) != -1)
                        ((HtmlInputCheckBox)DataGrid1.Items[i].Cells[0].Controls[1]).Checked = true;
            }
		}
	}
}
