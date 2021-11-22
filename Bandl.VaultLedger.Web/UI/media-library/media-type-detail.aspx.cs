using System;
using Bandl.Library.VaultLedger.BLL;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.Security;

namespace Bandl.VaultLedger.Web.UI
{
	/// <summary>
	/// Summary description for media_type_detail.
	/// </summary>
	public class media_type_detail : BasePage
	{
        protected System.Web.UI.WebControls.Label lblPageHeader;
        protected System.Web.UI.WebControls.Label lblPageCaption;
        protected System.Web.UI.WebControls.PlaceHolder PlaceHolder1;
        protected System.Web.UI.WebControls.TextBox txtTypeName;
        protected System.Web.UI.WebControls.DropDownList ddlContainer;
        protected System.Web.UI.WebControls.Label lblContainer;
        protected System.Web.UI.WebControls.DropDownList ddlTwoSided;
        protected System.Web.UI.WebControls.Label lblTwoSided;
        protected System.Web.UI.WebControls.Button btnSave;
        protected System.Web.UI.WebControls.RequiredFieldValidator rfvTypeName;
        protected System.Web.UI.WebControls.TextBox txtXmitCode;
        protected System.Web.UI.WebControls.RegularExpressionValidator revXmitCode;
        protected System.Web.UI.HtmlControls.HtmlTableRow twoSided;

        protected MediumTypeDetails mediumType;

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
            this.levelTwo = LevelTwoNav.Types;
        }
        /// <summary>
        /// Page load event handler (thrown by page master)
        /// </summary>
        protected override void Event_PageLoad(object sender, System.EventArgs e)
        {
            if (this.ViewState["MediumType"] != null)
            {
                mediumType = (MediumTypeDetails)this.ViewState["MediumType"];
            }
            else if (!Page.IsPostBack && Request.QueryString["typeName"] != null)
            {
                mediumType = MediumType.GetMediumType(Request.QueryString["typeName"]);
                this.ViewState["MediumType"] = mediumType;
            }
        }
        /// <summary>
        /// Page prerender event handler (thrown by page master)
        /// </summary>
        protected override void Event_PagePreRender(object sender, System.EventArgs e)
        {
            if (!Page.IsPostBack)
            {
                if (mediumType!= null)
                {
                    this.pageTitle = "Media Type Detail";
                    this.lblPageHeader.Text = "Media Type Detail : " + mediumType.Name;
                    // We cannot allow change of container type or two-sided capability,
                    // as this has potentially major ramifications for existing data.
                    // For example, what do we do if there are tapes in a container,
                    // and the operator decided that the container is now a cassette?
                    this.ddlTwoSided.Visible = false;
                    this.ddlContainer.Visible = false;
                    this.txtTypeName.Text = mediumType.Name;
                    this.txtXmitCode.Text = mediumType.RecallCode;
                    this.lblTwoSided.Text = mediumType.TwoSided ? "Yes" : "No";
                    this.lblContainer.Text = mediumType.Container ? "Yes" : "No";
                }
                else
                {
                    this.pageTitle = "New Media Type";
                    this.lblPageHeader.Text = "New Media Type";
                    this.lblPageCaption.Text = "Create a new media type.  When finished, click Save.";
                    // Add onchange event for dropdown controls
                    this.SetControlAttr(this.ddlTwoSided, "onchange", "sidedChange(this);");
                    this.SetControlAttr(this.ddlContainer, "onchange", "containerChange(this);");
                }
            }
            // Security - auditors and viewers cannot create or save media types.  Operators
            // can only create medium types; they cannot edit them.
            switch (CustomPermission.CurrentOperatorRole())
            {
                case Role.Auditor:
                case Role.Viewer:
                    if (mediumType == null)
                        Server.Transfer("../default.aspx");
                    else
                        this.btnSave.Visible = false;
                    break;
                case Role.Operator:
                    if (mediumType != null)
                        this.btnSave.Visible = false;
                    break;
                default:
                    break;
            }
            // Set control focus to name text box
            this.DoFocus(this.txtTypeName);
            // Help id depends on page mode
            this.helpId = mediumType != null ? 49 : 50;
            // Make the two sided row false; it doesn't really do anything anyway
            this.twoSided.Visible = false;
        }
        /// <summary>
        /// Saves medium type to database
        /// </summary>
        private void btnSave_Click(object sender, System.EventArgs e)
        {
            try
            {
                if (mediumType != null)
                {
                    mediumType.Name = this.txtTypeName.Text;
                    mediumType.RecallCode = this.txtXmitCode.Text;
                    MediumType.Update(ref mediumType);
                }
                else
                {
                    string typeName = this.txtTypeName.Text;
                    string xmitCode = this.txtXmitCode.Text;
                    bool twoSided = Convert.ToBoolean(this.ddlTwoSided.SelectedValue);
                    bool container = Convert.ToBoolean(this.ddlContainer.SelectedValue);
                    MediumTypeDetails newType = new MediumTypeDetails(typeName, twoSided, container, xmitCode);
                    MediumType.Insert(ref newType);
                }
                // Back to types page
                Server.Transfer("media-types.aspx");
            }
            catch (Exception ex)
            {
                this.DisplayErrors(this.PlaceHolder1, ex.Message);
            }
        }
    }
}
