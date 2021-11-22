using System;
using System.IO;
using System.Web.UI.WebControls;
using Bandl.Library.VaultLedger.BLL;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.Exceptions;
using Bandl.Library.VaultLedger.Collections;
using Bandl.Library.VaultLedger.Common.Knock;
using System.Runtime.Serialization.Formatters.Binary;

namespace Bandl.VaultLedger.Web.UI
{
	/// <summary>
	/// Summary description for new_case_format.
	/// </summary>
	public class new_case_format : BasePage
	{
		protected System.Web.UI.WebControls.Label lblCaption;
		protected System.Web.UI.WebControls.PlaceHolder PlaceHolder1;
		protected System.Web.UI.WebControls.TextBox txtCaseFormat;
		protected System.Web.UI.WebControls.Button btnSave;
		protected System.Web.UI.WebControls.DropDownList ddlCaseType;
        protected System.Web.UI.WebControls.RequiredFieldValidator rfvFormat;
        protected System.Web.UI.WebControls.RegularExpressionValidator revCaseType;
	
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
            this.btnSave.Click += new System.EventHandler(this.btnSave_Click);

        }
        #endregion

        /// <summary>
        /// Page initialization event handler (thrown by page master)
        /// </summary>
        protected override void Event_PageInit(object sender, System.EventArgs e)
        {
            this.helpId = 24;
            this.levelTwo = LevelTwoNav.CaseFormats;
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
                // Add the medium types to the dropdown
                foreach (MediumTypeDetails caseType in MediumType.GetMediumTypes(true))
                {
                    this.ddlCaseType.Items.Add(new ListItem(caseType.Name, caseType.Name));
                }
                // Fill in the fields if editing
                if (Request.QueryString["Pattern"] == null)
                {
                    this.lblCaption.Text = "New Case Format";
                }
                else
                {
                    this.lblCaption.Text = "Case Format - Edit";
                    this.ViewState["Pattern"] = Request.QueryString["Pattern"];
                    PatternDefaultCaseDetails barCode = PatternDefaultCase.GetPatternDefaultCases().Find(Request.QueryString["Pattern"]);
                    if (barCode == null)
                    {
                        throw new ApplicationException("Pattern not found");
                    }
                    else
                    {
                        this.ddlCaseType.SelectedValue = barCode.CaseType;
                        this.txtCaseFormat.Text = barCode.Pattern;
                    }
                }
                // Set focus to the text box
                this.SetFocus(this.txtCaseFormat);
            }
            // Set the page title
            this.pageTitle = this.lblCaption.Text;
            // Force bar code formats to uppercase
            this.SetControlAttr(this.txtCaseFormat, "onkeyup", "upperOnly(this);");
        }
        /// <summary>
        /// Event handler for save button
        /// </summary>
        private void btnSave_Click(object sender, System.EventArgs e)
        {
            PatternDefaultCaseDetails p = null;
            PatternDefaultCaseCollection c = PatternDefaultCase.GetPatternDefaultCases();
            // If we are editing an existing bar code format, make sure we can find it in the collection.
            if (this.ViewState["Pattern"] == null)
            {
                c.Insert(0, new PatternDefaultCaseDetails(txtCaseFormat.Text, ddlCaseType.SelectedValue, String.Empty));
            }
            else if ((p = c.Find((string)this.ViewState["Pattern"])) == null)
            {
                throw new ApplicationException("Case format cannot be updated because the original pattern cannot be found");
            }
            else
            {
                p.CaseType = ddlCaseType.SelectedValue;
                p.Pattern = txtCaseFormat.Text;
            }
            // Add to the session
            Session[CacheKeys.Object] = c;
            Session[CacheKeys.WaitRequest] = RequestTypes.BarCodeCaseUpdate;
            // Redirect to wait page
            Response.Redirect("../waitPage.aspx?redirectPage=administrative-tools/case-formats.aspx&x=" + Guid.NewGuid().ToString("N"));
        }
    }
}
