using System;
using System.Web.UI.WebControls;
using Bandl.Library.VaultLedger.BLL;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.Exceptions;
using Bandl.Library.VaultLedger.Collections;
using Bandl.Library.VaultLedger.Security;

namespace Bandl.VaultLedger.Web.UI
{
	/// <summary>
	/// Summary description for media_edit.
	/// </summary>
	public class media_edit : BasePage
	{
        private const string multipleString = "(Multiple Media)";
        private string originalReturn = String.Empty; // Original value of the return date text box
        private MediumCollection myMedia;
	
        protected System.Web.UI.WebControls.TextBox txtReturnDate;
		protected System.Web.UI.WebControls.Button btnSave;
		protected System.Web.UI.WebControls.DropDownList ddlLocation;
		protected System.Web.UI.WebControls.PlaceHolder PlaceHolder1;
        protected System.Web.UI.WebControls.Label lblPageTitle;
        protected System.Web.UI.WebControls.Button btnSolo;
        protected System.Web.UI.WebControls.Button btnCase;
        protected System.Web.UI.WebControls.Label lblCaption;
        protected System.Web.UI.WebControls.TextBox txtNotes;
        protected System.Web.UI.WebControls.DropDownList ddlMissing;
        protected System.Web.UI.WebControls.Label lblMsgMissing;
        protected System.Web.UI.WebControls.DropDownList ddlType;
        protected System.Web.UI.WebControls.DropDownList ddlAccount;
        protected System.Web.UI.WebControls.Button btnCancel2;

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
            this.btnSolo.Click += new System.EventHandler(this.btnSolo_Click);
            this.btnCase.Click += new System.EventHandler(this.btnCase_Click);

        }
        #endregion

        /// <summary>
        /// Page initialization event handler (thrown by page master)
        /// </summary>
        protected override void Event_PageInit(object sender, System.EventArgs e)
        {
            this.pageTitle = "Medium Detail - Edit";
            this.levelTwo = LevelTwoNav.Find;
            this.helpId = 5;
            // Security
            DoSecurity(new Role[] {Role.Administrator, Role.Operator}, "default.aspx");
        }
        /// <summary>
        /// Page load event handler (thrown by page master)
        /// </summary>
        protected override void Event_PageLoad(object sender, System.EventArgs e)
        {
            // Click events for message box buttons
            this.SetControlAttr(this.btnSolo, "onclick", "hideMsgBox('msgBoxMissing');");
            this.SetControlAttr(this.btnCase, "onclick", "hideMsgBox('msgBoxMissing');");
            this.SetControlAttr(this.btnCancel2, "onclick", "hideMsgBox('msgBoxMissing');");

            if (Page.IsPostBack)
            {
                myMedia = (MediumCollection)this.ViewState["MediumCollection"];
                originalReturn = (string)this.ViewState["OriginalReturn"];
            }
            else if (false == (Context.Handler is find_media))
            {
                Response.Redirect("find-media.aspx", false);
            }
            else
            {
                myMedia = ((find_media)Context.Handler).EditCollection;
                // If we only have one record, then we can show the record details
                if (myMedia.Count != 1)
                {
                    this.lblPageTitle.Text = "&nbsp;&nbsp;:&nbsp;&nbsp;Multiple Media";
                    this.lblCaption.Text = "Specify the attributes of the selected media";
                }
                else
                {
                    this.lblPageTitle.Text = "&nbsp;&nbsp;:&nbsp;&nbsp;" + myMedia[0].SerialNo;
                    this.lblCaption.Text = "Specify the attributes of medium " + myMedia[0].SerialNo;
                }
                // Initialize controls
                this.InitializeControls();
                // Record the original value of the return date text box
                originalReturn = this.txtReturnDate.Text;
                // Edit the viewstate
                this.ViewState["MediumCollection"] = myMedia;
                this.ViewState["OriginalReturn"] = originalReturn;
                this.ViewState["Filter"] = ((find_media)Context.Handler).SearchFilter;
            }
		}
        /// <summary>
        /// Initializes the value and status of each control
        /// </summary>
        private void InitializeControls()
        {
            // Populate the account dropdown
            foreach (AccountDetails a1 in Account.GetAccounts())
            {
                this.ddlAccount.Items.Add(new ListItem(a1.Name, a1.Name));
            }
            // Populate the medium type dropdown
            foreach (MediumTypeDetails m1 in MediumType.GetMediumTypes(false))
            {
                this.ddlType.Items.Add(new ListItem(m1.Name, m1.Name));
            }
            // Fill in attribute values for the first medium in the collection
            this.ddlType.SelectedValue = myMedia[0].MediumType;
            this.ddlAccount.SelectedValue = myMedia[0].Account;
            this.ddlMissing.SelectedValue = myMedia[0].Missing.ToString();
            this.ddlLocation.SelectedValue = ((int)myMedia[0].Location).ToString();
            // Return date and notes only if single medium
            if (myMedia.Count == 1)
            {
                this.txtNotes.Text = myMedia[0].Notes;
                this.txtReturnDate.Text = myMedia[0].ReturnDate.Length != 0 ? DisplayDate(myMedia[0].ReturnDate, false, false) : String.Empty;
            }
            else
            {
                this.txtNotes.Text = multipleString;
                this.txtReturnDate.Text = multipleString;
                // Run through the rest of the media in the collection
                foreach (MediumDetails m in myMedia)
                {
                    if (m.MediumType != myMedia[0].MediumType)
                    {
                        this.ddlType.SelectedIndex = 0;
                    }
                    if (m.Account != myMedia[0].Account)
                    {
                        this.ddlAccount.SelectedIndex = 0;
                    }
                    if (m.Location != myMedia[0].Location)
                    {
                        this.ddlLocation.SelectedIndex = 0;
                    }
                    if (m.Missing != myMedia[0].Missing)
                    {
                        this.ddlMissing.SelectedIndex = 0;
                    }
                }
            }
        }
        /// <summary>
        /// Modifies the medium details object in the collection
        /// </summary>
        private bool ModifyMediumObjects()
        {
            string notes = null;
            string returnDate = null;
            // Only modify the notes if multiple string does not appear
            if (txtNotes.Text != multipleString)
            {
                notes = txtNotes.Text;
            }
            // Only modify the return date if it has been changed
            if (txtReturnDate.Text != originalReturn)
            {
                if (txtReturnDate.Text.Trim().Length == 0)
                {
                    returnDate = String.Empty;
                }
                else
                {
                    try
                    {
                        returnDate = Date.ParseExact(txtReturnDate.Text).ToString("yyyy-MM-dd");
                    }
                    catch
                    {
                        return this.DisplayErrors(this.PlaceHolder1, "Return date is invalid");
                    }
                    // If we have a return date and the location is specified as
                    // enterprise, display an error.
                    if (this.ddlLocation.SelectedValue == ((int)Locations.Enterprise).ToString())
                    {
                        return this.DisplayErrors(this.PlaceHolder1, "Return dates cannot be assigned if media do not reside at vault");
                    }
                }
            }
            // If missing is true, run through the medium collection to verify that no medium is changing location
            if (this.ddlMissing.SelectedValue.ToLower() == "true")
            {
                foreach (MediumDetails m in myMedia)
                {
                    if (this.ddlLocation.SelectedValue != ((int)m.Location).ToString())
                    {
                        return this.DisplayErrors(this.PlaceHolder1, "Location cannot be changed if medium is marked as missing.");
                    }
                }
            }
            // Modify the medium details objects in the collection
            foreach (MediumDetails m in myMedia)
            {
                // Create reference
                MediumDetails oMedium = m;
                // Medium type
                if (this.ddlType.SelectedIndex != 0)
                {
                    oMedium.MediumType = this.ddlType.SelectedValue;
                }
                // Account 
                if (this.ddlAccount.SelectedIndex != 0)
                {
                    oMedium.Account = this.ddlAccount.SelectedValue;
                }
                // Location
                switch (this.ddlLocation.SelectedValue)
                {
                    case "0":
                        oMedium.Location = Locations.Vault;
                        break;
                    case "1":
                        oMedium.Location = Locations.Enterprise;
                        break;
                    default:
                        break;
                }
                // Missing status
                switch (this.ddlMissing.SelectedValue.ToLower())
                {
                    case "true":
                        oMedium.Missing = true;
                        break;
                    case "false":
                        oMedium.Missing = false;
                        break;
                    default:
                        break;
                }
                // Return date
                if (returnDate != null) 
                {
                    oMedium.ReturnDate = returnDate;
                }
                // Notes
                if (notes != null) 
                {
                    oMedium.Notes = this.txtNotes.Text;
                }
            }
            // Return
            return true;
        }

        /// <summary>
        /// Updates the media in the collection according to the paramaters
        /// input by the user
        /// </summary>
        private void UpdateMediaCollection(int caseAction)
        {
            try
            {
                if (Medium.Update(ref myMedia, caseAction))
                {
                    Session[CacheKeys.MediumFilter] = this.ViewState["Filter"];
                    Response.Redirect("find-media.aspx", false);
                }
                else
                {
                    this.ShowMessageBox("msgBoxMissing");
                    // Change the text if medium is to be found rather than missing
                    if (this.ddlMissing.SelectedValue.ToLower() == "false")
                    {
                        this.lblMsgMissing.Text = this.lblMsgMissing.Text.Replace("missing", "found");
                    }
                }
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
        /// <summary>
        /// Triggers the initial media update
        /// </summary>
        private void btnSave_Click(object sender, System.EventArgs e)
        {
            if (this.ModifyMediumObjects())
            {
                this.UpdateMediaCollection(0);
            }
        }
        /// <summary>
        /// Retries the medium update if there was a case integrity exception
        /// and the user selected to remove the individual tape(s) from their
        /// respective sealed cases.
        /// </summary>
        private void btnSolo_Click(object sender, System.EventArgs e)
        {
            if (this.ModifyMediumObjects())
            {
                this.UpdateMediaCollection(1);
            }
        }
        /// <summary>
        /// Retries the medium update if there was a case integrity exception
        /// and the user selected to update all the media within sealed cases.
        /// </summary>
        private void btnCase_Click(object sender, System.EventArgs e)
        {
            if (this.ModifyMediumObjects())
            {
                this.UpdateMediaCollection(2);
            }
        }
	}
}
