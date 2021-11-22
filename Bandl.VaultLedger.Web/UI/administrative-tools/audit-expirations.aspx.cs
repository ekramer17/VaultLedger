using System;
using System.Collections;
using System.Web.UI.WebControls;
using Bandl.Library.VaultLedger.Security;
using Bandl.Library.VaultLedger.Collections;
using Bandl.Library.VaultLedger.Exceptions;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.BLL;

namespace Bandl.VaultLedger.Web.UI
{
	/// <summary>
	/// Summary description for audit_expirations.
	/// </summary>
	public class audit_expirations : BasePage
	{
        protected System.Web.UI.HtmlControls.HtmlForm Form1;
        protected System.Web.UI.WebControls.PlaceHolder PlaceHolder1;
        protected System.Web.UI.HtmlControls.HtmlInputButton btnPrune;
        protected System.Web.UI.WebControls.DataGrid DataGrid1;
        protected System.Web.UI.WebControls.Button btnOK1;
		protected System.Web.UI.WebControls.Button btnYes;
		protected System.Web.UI.WebControls.Button btnNo;
        protected System.Web.UI.WebControls.Button btnSave1;
        protected System.Web.UI.HtmlControls.HtmlGenericControl contentBorderTop;
        protected System.Web.UI.HtmlControls.HtmlInputButton btnSave;
        protected System.Web.UI.WebControls.Button btnOK2;
    
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
            this.DataGrid1.PreRender += new System.EventHandler(this.DataGrid1_PreRender);
            this.DataGrid1.ItemDataBound += new System.Web.UI.WebControls.DataGridItemEventHandler(this.DataGrid1_ItemDataBound);
            this.btnYes.Click += new System.EventHandler(this.btnYes_Click);
            this.btnPrune.ServerClick += new System.EventHandler(this.btnPrune_ServerClick);
            this.btnSave.ServerClick += new System.EventHandler(this.btnSave_ServerClick);

        }
        #endregion

        /// <summary>
        /// Page initialization event handler (thrown by page master)
        /// </summary>
        protected override void Event_PageInit(object sender, System.EventArgs e)
        {
            this.pageTitle = "Audit Category Expirations";
            this.levelTwo = LevelTwoNav.Preferences;
            this.helpId = 44;
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
            this.SetControlAttr(btnOK1, "onclick", "hideMsgBox('msgBoxSave');");
            this.SetControlAttr(btnOK2, "onclick", "hideMsgBox('msgBoxPrune');");
			this.SetControlAttr(btnYes, "onclick", "hideMsgBox('msgBoxConfirm');");
			this.SetControlAttr(btnNo,  "onclick", "hideMsgBox('msgBoxConfirm');");
			// If not a postback, then initialize viewstate
            if (!this.Page.IsPostBack)
            {
                // Get the audit trail expirations and place in viewstate
                this.ViewState["Hashtable"] = CreateHashtable();
                this.ViewState["Expirations"] = OrderExpirations(AuditTrail.GetExpirations());
                // Bind the expirations to the datagrid
                this.DataGrid1.DataSource = (AuditExpirationCollection)this.ViewState["Expirations"];
                this.DataGrid1.DataBind();
                // If we're supposed to prune the audit trails, do it here.
                if ("true".CompareTo(Request.QueryString["prune"]) == 0)
                {
                    if (Session[CacheKeys.Exception] == null)
                    {
                        this.ShowMessageBox("msgBoxPrune");
                    }
                    else
                    {
                        this.DisplayErrors(this.PlaceHolder1, ((Exception)Session[CacheKeys.Exception]).Message);
                        Session.Remove(CacheKeys.Exception);
                    }
                }
            }
        }
        /// <summary>
        /// Page prerender event handler (thrown by page master)
        /// </summary>
        protected override void Event_PagePreRender(object sender, System.EventArgs e)
        {
            // At this time, we don't have any archive capability, so we'll
            // make the datagrid archive column invisible.
            this.DataGrid1.Columns[2].Visible = false;
            // Set the default button
            this.SetDefaultButton(this.contentBorderTop, "btnSave");
        }
        /// <summary>
        /// Page prerender event handler (thrown by page master)
        /// </summary>
        private void DataGrid1_PreRender(object sender, EventArgs e)
        {
            // The archive dropdown should be invisible if the message box is displayed
            DataGrid1.Items[0].FindControl("ddlArchive").Visible = !ClientScript.IsStartupScriptRegistered("saveBox");
        }
        /// <summary>
        /// Occurs when an item is databound to the datagrid
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="e"></param>
        private void DataGrid1_ItemDataBound(object sender, DataGridItemEventArgs e)
        {
            this.SetControlAttr(e.Item.FindControl("txtDays"), "onkeyup", "digitsOnly(this);");
        }
        /// <summary>
        /// Creates a hash table with the audit type enumertion names and their
        /// corresponding display values.
        /// </summary>
        private Hashtable CreateHashtable()
        {
            Hashtable hashTable = new Hashtable();
            string tableValue;

            // We're not going to deal with the 'General Action' audit type explicitly.  It
            // will take the same value as the System Action audit type.  They will both
            // belong to the heading 'Miscellaneous'.
            foreach (string auditType in Enum.GetNames(typeof(AuditTypes)))
            {
                switch((AuditTypes)Enum.Parse(typeof(AuditTypes),auditType))
                {
                    case AuditTypes.Account:
                        tableValue = "Account";
                        break;
                    case AuditTypes.BarCodePattern:
                        tableValue = "Bar code pattern";
                        break;
                    case AuditTypes.DisasterCodeList:
                        tableValue = "Disaster code list";
                        break;
                    case AuditTypes.ExternalSite:
                        tableValue = "External TMS site map";
                        break;
                    case AuditTypes.IgnoredBarCodePattern:
                        tableValue = "Ignored TMS bar code";
                        break;
                    case AuditTypes.Medium:
                        tableValue = "Medium";
                        break;
                    case AuditTypes.MediumMovement:
                        tableValue = "Movement";
                        break;
                    case AuditTypes.Operator:
                        tableValue = "Operator";
                        break;
                    case AuditTypes.ReceiveList:
                        tableValue = "Receiving list";
                        break;
                    case AuditTypes.SealedCase:
                        tableValue = "Sealed case";
                        break;
                    case AuditTypes.SendList:
                        tableValue = "Shipping list";
                        break;
                    case AuditTypes.SystemAction:
                        tableValue = "Miscellaneous";
                        break;
                    case AuditTypes.InventoryConflict:
                        tableValue = "Inventory discrepancies";
                        break;
                    case AuditTypes.Inventory:
                        tableValue = "Inventory";
                        break;
                    default:
                        tableValue = String.Empty;
                        break;
                }

                if (tableValue.Length != 0)
                {
                    hashTable.Add(auditType, tableValue);
                }
            }

            return hashTable;
        }
        /// <summary>
        /// Places the audit expirations in alphabetical order according to their
        /// text descriptions.
        /// </summary>
        private AuditExpirationCollection OrderExpirations(AuditExpirationCollection auditExpirations)
        {
            AuditExpirationCollection returnCollection = new AuditExpirationCollection();
            // Account
            returnCollection.Add(auditExpirations.Find(AuditTypes.Account));
            // Bar code pattern
            returnCollection.Add(auditExpirations.Find(AuditTypes.BarCodePattern));
            // Disaster code list
            returnCollection.Add(auditExpirations.Find(AuditTypes.DisasterCodeList));
            // External site map
            returnCollection.Add(auditExpirations.Find(AuditTypes.ExternalSite));
            // Medium
            returnCollection.Add(auditExpirations.Find(AuditTypes.Medium));
            // Medium movement
            returnCollection.Add(auditExpirations.Find(AuditTypes.MediumMovement));
            // Miscellaneous action
            returnCollection.Add(auditExpirations.Find(AuditTypes.SystemAction));
            // Operator
            returnCollection.Add(auditExpirations.Find(AuditTypes.Operator));
            // Receiving list
            returnCollection.Add(auditExpirations.Find(AuditTypes.ReceiveList));
            // Sealed case
            returnCollection.Add(auditExpirations.Find(AuditTypes.SealedCase));
            // Send list
            returnCollection.Add(auditExpirations.Find(AuditTypes.SendList));
            // Vault discrepancy
            returnCollection.Add(auditExpirations.Find(AuditTypes.Inventory));
            // Vault inventory
            returnCollection.Add(auditExpirations.Find(AuditTypes.InventoryConflict));
            // Return the collection
            return returnCollection;
        }

        /// <summary>
        /// Given an audit type enumeration name, gets the category display text
        /// </summary>
        public string GetCategoryName(string typeString)
        {
            Hashtable hashTable = (Hashtable)this.ViewState["Hashtable"];

            foreach (string key in hashTable.Keys)
            {
                if (typeString == key)
                {
                    return (string)hashTable[key];
                }
            }
            // Key not found - shouldn't happen
            return "An error has occurred during category parsing";
        }
        /// <summary>
        /// Instructs system to prune audit trails
        /// </summary>
        private void btnPrune_ServerClick(object sender, System.EventArgs e)
        {
            this.ShowMessageBox("msgBoxConfirm");
		}
		/// <summary>
		/// Instructs system to prune audit trails
		/// </summary>
		private void btnYes_Click(object sender, System.EventArgs e)
		{
            // Add to the session
            Session[CacheKeys.WaitRequest] = RequestTypes.AuditTrailPrune;
            // Redirect to the wait page
            Response.Redirect(@"../waitPage.aspx?redirectPage=administrative-tools/audit-expirations.aspx&x=" + Guid.NewGuid().ToString("N"), false);
        }

        private void btnSave_ServerClick(object sender, System.EventArgs e)
        {
            AuditExpirationCollection auditExpirations = (AuditExpirationCollection)this.ViewState["Expirations"];
            Hashtable hashTable = (Hashtable)this.ViewState["Hashtable"];
            string[] auditNames = Enum.GetNames(typeof(AuditTypes));
            // Run through the datagrid
            foreach(DataGridItem dgi in this.DataGrid1.Items)
            {
                AuditExpirationDetails auditDetails = null;
                // Find the correct audit expiration object
                foreach (string auditName in auditNames)
                {
                    if (((Label)dgi.FindControl("lblCategory")).Text == (string)hashTable[auditName])
                    {
                        AuditTypes auditType = (AuditTypes)Enum.Parse(typeof(AuditTypes), auditName);
                        auditDetails = auditExpirations.Find(auditType);
                        break;
                    }
                }
                // If we found it, do comparison
                if (auditDetails != null)
                {
                    // Get the days and archive values
                    int days = Convert.ToInt32(((TextBox)dgi.FindControl("txtDays")).Text);
                    bool archive = ((DropDownList)dgi.FindControl("ddlArchive")).SelectedItem.Text[0] == 'Y';
                    // If either is different, modify the expiration
                    if (days != auditDetails.Days || archive != auditDetails.Archive)
                    {
                        auditDetails.Days = days;
                        auditDetails.Archive = archive;
                        // If the audit type is system action, similarly alter general action audit details object
                        if (auditDetails.AuditType == AuditTypes.SystemAction)
                        {
                            if (null != (auditDetails = auditExpirations.Find(AuditTypes.GeneralAction)))
                            {
                                auditDetails.Days = days;
                                auditDetails.Archive = archive;
                            }
                        }
                    }
                }
            }
            // Update the collection
            try
            {
                AuditTrail.UpdateExpirationCollection(ref auditExpirations);
                // We have to order the expirations again because the update
                // function fetches them anew, which throws the order off.
                auditExpirations = this.OrderExpirations(auditExpirations);
                // Replace in the viewstate
                this.ViewState["Expirations"] = auditExpirations;
                // Set the startup script
                this.ShowMessageBox("msgBoxSave");
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
}
