using System;
using Bandl.Library.VaultLedger.BLL;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.Exceptions;
using Bandl.Library.VaultLedger.Collections;
using Bandl.Library.VaultLedger.Security;

namespace Bandl.VaultLedger.Web.UI
{
	/// <summary>
	/// Summary description for disaster_recovery_list_edit.
	/// </summary>
	public class disaster_recovery_list_edit : BasePage
	{
        private DisasterCodeListDetails pageList = null;
        private DisasterCodeListItemCollection di = null;
        protected System.Web.UI.WebControls.Label lblCaption;
        protected System.Web.UI.WebControls.TextBox txtDisasterCode;
        protected System.Web.UI.HtmlControls.HtmlInputButton btnSave;
        protected System.Web.UI.WebControls.Button btnCancel;
        protected System.Web.UI.WebControls.PlaceHolder PlaceHolder1;
        protected System.Web.UI.WebControls.Button btnSave1;
        protected System.Web.UI.HtmlControls.HtmlGenericControl contentBorderTop;

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
            this.btnSave1.Click += new System.EventHandler(this.btnSave_Click);
            this.btnCancel.Click += new System.EventHandler(this.btnCancel_Click);

        }
        #endregion

        /// <summary>
        /// Page initialization event handler (thrown by page master)
        /// </summary>
        protected override void Event_PageInit(object sender, System.EventArgs e)
        {
            this.helpId = 39;
            this.levelTwo = LevelTwoNav.DisasterRecovery;
            // Viewers and auditors shouldn't be able to access this page
            DoSecurity(Role.Operator, "default.aspx");
        }
        /// <summary>
        /// Page load event handler (thrown by page master)
        /// </summary>
        protected override void Event_PageLoad(object sender, System.EventArgs e)
        {
            if (Page.IsPostBack)
            {
                pageList = (DisasterCodeListDetails)this.ViewState["PageList"];
                di = (DisasterCodeListItemCollection)this.ViewState["Items"];
            }
            else
            {
                if (Context.Handler is disaster_recovery_list_detail)
                {
                    pageList = DisasterCodeList.GetDisasterCodeList(((disaster_recovery_list_detail)Context.Handler).ListId, false);
                    di = ((disaster_recovery_list_detail)Context.Handler).EditableItems;
                    this.ViewState["Items"] = di;
                    // Form the page caption
                    this.lblCaption.Text = "Edit Disaster Recovery List&nbsp;&nbsp;:&nbsp;&nbsp;" + pageList.Name;
                    // Insert list into viewstate
                    this.ViewState["PageList"] = pageList;
                }
                else
                {
                    Server.Transfer("disaster-recovery-list-browse.aspx");
                }
            }
        }
        /// <summary>
        /// Page prerender event handler (thrown by page master)
        /// </summary>
        protected override void Event_PagePreRender(object sender, System.EventArgs e)
        {
            this.pageTitle = this.lblCaption.Text;
            // Set the default button
            this.SetDefaultButton(this.contentBorderTop, "btnSave");
            // Set the focus to the disaster recovery code box
            this.DoFocus(this.txtDisasterCode);
            // Limit disaster code to three characters if ReQuest
            if (Configurator.ProductType == "RECALL")
                this.txtDisasterCode.MaxLength = 3;
        }
        /// <summary>
        /// Event handler for save button
        /// </summary>
        private void btnSave_Click(object sender, System.EventArgs e)
        {
            // Make sure that we have a disaster code
            if (0 == this.txtDisasterCode.Text.Trim().Length)
            {
                this.DisplayErrors(this.PlaceHolder1, "You must enter a disaster recovery code");
            }
            else
            {
                // Edit the items with the entered fields
                for (int i = 0; i < di.Count; i++)
                    di[i].Code = this.txtDisasterCode.Text.Trim();
                // Update the items
                try
                {
                    DisasterCodeList.UpdateItems(ref di);
                    Server.Transfer(String.Format("disaster-recovery-list-detail.aspx?listNumber={0}", pageList.Name));
                }
                catch (CollectionErrorException ex)
                {
                    this.DisplayErrors(this.PlaceHolder1, ex.Collection);
                }
                catch (Exception ex)
                {
                    this.DisplayErrors(this.PlaceHolder1, ex.Message);
                }
            }
        }
        /// <summary>
        /// Event handler for cancel button
        /// </summary>
        private void btnCancel_Click(object sender, System.EventArgs e)
        {
            Server.Transfer(String.Format("disaster-recovery-list-detail.aspx?listNumber={0}", pageList.Name));
        }
    }
}
