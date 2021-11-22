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
	/// Summary description for new_bar_code_format_template.
	/// </summary>
	public class new_bar_code_format : BasePage
	{
		protected System.Web.UI.WebControls.TextBox txtBarCodeFormat;
		protected System.Web.UI.WebControls.DropDownList ddlMediaType;
		protected System.Web.UI.WebControls.DropDownList ddlAccount;
		protected System.Web.UI.WebControls.Button btnSave;
		protected System.Web.UI.WebControls.Label lblCaption;
        protected System.Web.UI.WebControls.RequiredFieldValidator rfvFormat;
        protected System.Web.UI.WebControls.RegularExpressionValidator revAccount;
        protected System.Web.UI.WebControls.RegularExpressionValidator revMediaType;
        protected System.Web.UI.WebControls.Button btnCancel;
		protected System.Web.UI.WebControls.PlaceHolder PlaceHolder1;				

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
            this.helpId = 22;
            this.levelTwo = LevelTwoNav.BarCodeFormats;
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
                foreach (MediumTypeDetails mediumType in MediumType.GetMediumTypes(false))
                {
                    this.ddlMediaType.Items.Add(new ListItem(mediumType.Name, mediumType.Name));
                }
                // Add the accounts to the dropdown
                foreach (AccountDetails account in Account.GetAccounts())
                {
                    this.ddlAccount.Items.Add(new ListItem(account.Name, account.Name));
                }
                // Fill in the fields if editing
                if (Request.QueryString["Pattern"] == null)
                {
                    this.lblCaption.Text = "New Bar Code Format";
                }
                else
                {
                    this.lblCaption.Text = "Bar Code Format - Edit";
                    this.ViewState["Pattern"] = Request.QueryString["Pattern"];
                    PatternDefaultMediumDetails barCode = PatternDefaultMedium.GetPatternDefaults().Find(Request.QueryString["Pattern"]);
                    if (barCode == null)
                    {
                        throw new ApplicationException("Pattern not found");
                    }
                    else
                    {
                        this.ddlMediaType.SelectedValue = barCode.MediumType;
                        this.ddlAccount.SelectedValue = barCode.Account;
                        this.txtBarCodeFormat.Text = barCode.Pattern;
                    }
                }
                // Set focus to the text box
                this.SetFocus(this.txtBarCodeFormat);
            }
            // Set the page title
            this.pageTitle = this.lblCaption.Text;
            // Force bar code formats to uppercase
            this.SetControlAttr(this.txtBarCodeFormat, "onkeyup", "upperOnly(this);");
        }
        /// <summary>
        /// Event handler for save button
        /// </summary>
		private void btnSave_Click(object sender, System.EventArgs e)
		{
            // Add or replace the bar code format
            PatternDefaultMediumDetails p = null;
            PatternDefaultMediumCollection c = PatternDefaultMedium.GetPatternDefaults();
            // If we are editing an existing bar code format, make sure we can find it in the collection.
            if (this.ViewState["Pattern"] == null)
            {
                c.Insert(0, new PatternDefaultMediumDetails(txtBarCodeFormat.Text, ddlAccount.SelectedValue, ddlMediaType.SelectedValue, String.Empty));
            }
            else if ((p = c.Find((string)this.ViewState["Pattern"])) == null)
            {
                throw new ApplicationException("Bar code format cannot be updated because the original pattern cannot be found");
            }
            else
            {
                p.Pattern = txtBarCodeFormat.Text;
                p.Account = ddlAccount.SelectedValue;
                p.MediumType = ddlMediaType.SelectedValue;
            }
            // Add to the session
            Session[CacheKeys.Object] = c;
            Session[CacheKeys.WaitRequest] = RequestTypes.BarCodeMediumUpdate;
            // Redirect to the wait page
            Response.Redirect("../waitPage.aspx?redirectPage=administrative-tools/bar-code-formats.aspx&x=" + Guid.NewGuid().ToString("N"));
		}
	}
}
