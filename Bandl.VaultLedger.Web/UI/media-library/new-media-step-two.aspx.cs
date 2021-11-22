using System;
using System.Text;
using System.Web.UI;
using System.Collections;
using System.Web.UI.WebControls;
using Bandl.Library.VaultLedger.BLL;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.Collections;
using Bandl.Library.VaultLedger.Security;

namespace Bandl.VaultLedger.Web.UI
{
	/// <summary>
	/// Summary description for new_media_step_two.
	/// </summary>
	public class new_media_step_two : BasePage
	{
		protected System.Web.UI.HtmlControls.HtmlForm Form1;
		protected System.Web.UI.WebControls.Label lblMediumType;
		protected System.Web.UI.WebControls.Label lblAccount;
        protected System.Web.UI.WebControls.DataGrid DataGrid1;
        protected System.Web.UI.WebControls.Button btnAdd;
        protected System.Web.UI.WebControls.PlaceHolder PlaceHolder1;

        private string startNo;
        private string endNo;

        public string StartNo { get {return startNo;} }
        public string EndNo { get {return endNo;} }

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
            this.btnAdd.Click += new System.EventHandler(this.btnAdd_Click);
        }
        #endregion

        /// <summary>
        /// Page initialization event handler (thrown by page master)
        /// </summary>
        protected override void Event_PageInit(object sender, System.EventArgs e)
        {
            this.pageTitle = "New Media";
            this.levelTwo = LevelTwoNav.New;
            this.helpId = 7;
            // Auditors and viewers should not be able to access this page;
            // redirect them to the main menu
            DoSecurity(Role.Operator, "default.aspx");
        }
        /// <summary>
        /// Page load event handler (thrown by page master)
        /// </summary>
        protected override void Event_PageLoad(object sender, System.EventArgs e)
        {
            if (Page.IsPostBack)
            {
                endNo = (string)this.ViewState["EndNo"];
                startNo = (string)this.ViewState["StartNo"];
            }
            else
            {
                // Verify that we came from step one
                if (Context.Handler is new_media_step_one)
                {
                    try
                    {
                        endNo = ((new_media_step_one)Context.Handler).EndNo;
                        startNo = ((new_media_step_one)Context.Handler).StartNo;
                        this.ViewState["StartNo"] = startNo;
                        this.ViewState["EndNo"] = endNo;
                        // Preview the serial numbers
                        MediumRange[] ranges = null;
                        Medium.PreviewInsert(startNo, endNo, out ranges);
                        // Bind to the datagrid
                        DataGrid1.DataSource = ranges;
                        DataGrid1.DataBind();
                    }
                    catch (Exception ex)
                    {
                        this.DisplayErrors(this.PlaceHolder1, ex.Message);
                    }
                }
                else
                {
                    Response.Redirect("new_media_step_one.aspx", false);
                }
            }
		}
        /// <summary
        /// Event handler for add button.  Adds media to the database.
        /// </summary>
        private void btnAdd_Click(object sender, System.EventArgs e)
        {
            try
            {
                MediumRange[] ranges = null;
                Medium.Insert(startNo, endNo, Locations.Enterprise, out ranges);
                Server.Transfer("find-media.aspx");
            }
            catch (Exception ex)
            {
                this.DisplayErrors(this.PlaceHolder1, ex.Message);
            }
        }
	}
}
