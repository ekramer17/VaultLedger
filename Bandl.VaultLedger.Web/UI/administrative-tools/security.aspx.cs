using System;
using System.Web.UI.WebControls;
using System.Web.UI.HtmlControls;
using Bandl.Library.VaultLedger.BLL;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.Collections;
using Bandl.Library.VaultLedger.Security;

namespace Bandl.VaultLedger.Web.UI
{
	/// <summary>
	/// Summary description for security_template.
	/// </summary>
	public class security : BasePage
	{
        private OperatorCollection operatorCollection;
		protected System.Web.UI.WebControls.Button btnNewUser;
		protected System.Web.UI.HtmlControls.HtmlForm Form1;
		protected System.Web.UI.WebControls.PlaceHolder PlaceHolder1;
		protected System.Web.UI.WebControls.Button btnYes;
		protected System.Web.UI.WebControls.Button btnNo;
        protected System.Web.UI.WebControls.Button btnDelete;
        protected System.Web.UI.WebControls.Button btnNew;
        protected System.Web.UI.WebControls.LinkButton printLink;
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
            this.btnYes.Click += new System.EventHandler(this.btnYes_Click);

        }
        #endregion

        /// <summary>
        /// Page initialization event handler (thrown by page master)
        /// </summary>
        protected override void Event_PageInit(object sender, System.EventArgs e)
        {
            this.helpId = 27;
            this.pageTitle = "Users";
            this.levelTwo = LevelTwoNav.Users;
            // Click events for message box buttons
            this.SetControlAttr(btnYes, "onclick", "hideMsgBox('msgBoxDelete');");
            this.SetControlAttr(btnNo,  "onclick", "hideMsgBox('msgBoxDelete');");
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
            {
                this.FetchOperators();
            }
            else
            {
                operatorCollection = (OperatorCollection)this.ViewState["Operators"];
            }
		}
		/// <summary>
		/// Fetch the operators and bind them to the datagrid
		/// </summary>
        private void FetchOperators()
        {
            operatorCollection = Operator.GetOperators();
            this.ViewState["Operators"] = operatorCollection;
            // Bind to the datagrid
            this.DataGrid1.DataSource = operatorCollection;
            this.DataGrid1.DataBind();
        }
        /// <summary>
        /// Event handler for New User button
        /// </summary>
		private void btnNew_Click(object sender, System.EventArgs e)
		{
			Response.Redirect("user-detail.aspx", false);
		}
        /// <summary>
        /// Event handler for Delete button
        /// </summary>
        private void btnDelete_Click(object sender, System.EventArgs e)
		{
            this.ShowMessageBox("msgBoxDelete");
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
                        OperatorDetails o = operatorCollection.Find(dgi.Cells[2].Text);
                        Operator.Delete(ref o);
                    }
                    catch (Exception ex)
                    {
                        this.DisplayErrors(this.PlaceHolder1, ex.Message);
                    }
                }
            }
            // Refetch the operators
            this.FetchOperators();
		}
        /// <summary>
        /// Print function to be called asynchronously
        /// </summary>
        private void printLink_Click(object sender, System.EventArgs e)
        {
            Session[CacheKeys.PrintSource] = PrintSources.UserSecurityPage;
            Session[CacheKeys.PrintObjects] = new object[] {this.operatorCollection};
            ClientScript.RegisterStartupScript(GetType(), "printWindow", "<script>openBrowser('../waitPage.aspx?redirectPage=print.aspx&x=" + Guid.NewGuid().ToString("N") + "')</script>");
        }
        /// <summary>
        /// Gets th role name to display.  Necessary due to VaultOps role.
        /// </summary>
        public string GetRoleName(string roleName)
        {
            return roleName != "VaultOps" ? roleName : "Vault Operator";
        }
    }
}
