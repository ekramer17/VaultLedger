using System;
using System.Web;
using System.Data;
using Bandl.Library.VaultLedger.BLL;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.Collections;
using Bandl.Library.VaultLedger.Exceptions;
using Bandl.Library.VaultLedger.Security;

namespace Bandl.VaultLedger.Web.UI
{
    /// <summary>
    /// Summary description for new_list_rfid_file.
    /// </summary>
    public class new_list_rfid_file : BasePage
    {
        private SendListDetails sl = null;
        private string cancelUrl;
        private bool displayTabs;
        private int maxSerial = 0;   // max serial length
        private int formatType = 0;  // serial number editing format
        private const string REPORTDICTATED = "(Report-Dictated)";
        protected System.Web.UI.WebControls.PlaceHolder PlaceHolder1;
        protected System.Web.UI.WebControls.Label lblAccount;
        protected System.Web.UI.WebControls.DataGrid DataGrid1;
        protected System.Web.UI.HtmlControls.HtmlInputButton btnNext;
        protected System.Web.UI.HtmlControls.HtmlInputButton btnCancel;
        protected System.Web.UI.HtmlControls.HtmlInputHidden tableContents;
        protected System.Web.UI.WebControls.TextBox txtReturnDate;
        protected System.Web.UI.WebControls.TextBox txtDescription;
        protected System.Web.UI.WebControls.DropDownList ddlSelectAction;
        protected System.Web.UI.HtmlControls.HtmlInputHidden missingTapes;
        protected System.Web.UI.WebControls.Table Table1;
        protected System.Web.UI.WebControls.TextBox txtExpected;
    

        // Public properties for server transfer
        public string CancelUrl
        {
            get {return cancelUrl;}
        }

        public bool DisplayTabs
        {
            get {return displayTabs;}
        }

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
            this.btnCancel.ServerClick += new EventHandler(btnCancel_ServerClick);
            this.btnNext.ServerClick += new EventHandler(btnNext_ServerClick);
        }
        #endregion

        /// <summary>
        /// Page initialization event handler (thrown by page master)
        /// </summary>
        protected override void Event_PageInit(object sender, System.EventArgs e)
        {
            this.pageTitle = "New Shipping List";
            this.levelTwo = LevelTwoNav.Shipping;
            this.helpId = 10;
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
                // Viewstate objects
                cancelUrl = (string)this.ViewState["CancelUrl"];
                displayTabs = (bool)this.ViewState["DisplayTabs"];
                maxSerial = (int)this.ViewState["Length"];
                formatType = (int)this.ViewState["Format"];
                // If we have a url in the viewstate, transfer over there.  Otherwise get the list object.
                if (this.ViewState["URL"] != null)
                {
                    Server.Transfer((string)this.ViewState["URL"]);
                }
                else if (this.ViewState["ListObject"] != null)
                {
                    sl = (SendListDetails)this.ViewState["ListObject"];
                }
            }
            else 
            {
                if (Context.Handler is shipping_list_detail)
                {
                    displayTabs = false;
                    cancelUrl = String.Format("shipping-list-detail.aspx?listNumber={0}", sl.Name);
                }
                else if (Context.Handler is todays_list)
                {
                    displayTabs = true;
                    cancelUrl = "todays-list.aspx";
                }
                else if (Context.Handler is shipping_list_detail_edit_case)
                {
                    cancelUrl = ((shipping_list_detail_edit_case)Context.Handler).CancelUrl;
                    displayTabs = ((shipping_list_detail_edit_case)Context.Handler).DisplayTabs;
                }
                else
                {
                    displayTabs = true;
                    cancelUrl = "send-lists.aspx";
                }
                // Insert page fields into the viewstate
                this.ViewState["CancelUrl"] = cancelUrl;
                this.ViewState["DisplayTabs"] = displayTabs;
                if (displayTabs) TabPageDefault.Update(TabPageDefaults.NewSendList, Context.Items[CacheKeys.Login], 4); 
                // Set the rfid max serial length, and serial number format edit type
                this.maxSerial = Int32.Parse(Preference.GetPreference(PreferenceKeys.MaxRfidSerialLength).Value);
                this.formatType = (int)Preference.GetSerialEditFormat();
                // Place information in viewstate
                this.ViewState["Length"] = maxSerial;
                this.ViewState["Format"] = formatType;
            }
        }
        /// <summary>
        /// Page prerender event handler (thrown by page master)
        /// </summary>
        protected override void Event_PagePreRender(object sender, System.EventArgs e)
        {
            // Make sure that the expected count text box can only contain digits
            this.SetControlAttr(this.txtExpected, "onkeyup", "digitsOnly(this);");
            // Create a table and bind an empty object to it so that it will show up
            DataTable dataTable = new DataTable();
            dataTable.Columns.Add("SerialNo", typeof(string));
            dataTable.Columns.Add("ReturnDate", typeof(string));
            dataTable.Columns.Add("CaseName", typeof(string));
            dataTable.Columns.Add("Notes", typeof(string));
            dataTable.Rows.Add(new object[] {String.Empty, String.Empty, String.Empty, String.Empty});
            this.DataGrid1.DataSource = dataTable;
            this.DataGrid1.DataBind();
            // Register the javascript ariables
            ClientScript.RegisterStartupScript(GetType(), "VARIABLES", String.Format("<script>maxSerial={0};formatType={1};</script>", maxSerial, formatType));
            // Register the startup script
            ClientScript.RegisterStartupScript(GetType(), "STARTUP", "<script language=javascript>doStartup(0)</script>");
            // Embed the beep
            this.RegisterBeep(false);
        }
       
        // Event handler for cancel button
        private void btnCancel_ServerClick(object sender, System.EventArgs e)
        {
            Response.Redirect((string)this.ViewState["CancelUrl"], false);
        }
        /// <summary>
        /// Event handler for the Next button
        /// </summary>
        private void btnNext_ServerClick(object sender, System.EventArgs e)
        {
            MediumDetails m = null;
            string url = String.Empty;
            string s = tableContents.Value;
            SendListItemCollection items = new SendListItemCollection();
// Check that an account has been assigned it we need it
//			if (ddlAccount.Visible && ddlAccount.SelectedIndex == 0)
//			{
//				this.DisplayErrors(this.PlaceHolder1, "Please select an account for this list.");
//				this.SetFocus(this.ddlAccount);
//				return;
//            
//			}
            // Create or append to the list
            try
            {
                // Create the collection of items
                while (s.Length != 0)
                {
                    // Get the delimiter position
                    int d1 = s.IndexOf("`0;");
                    int d2 = s.IndexOf("`1;");
                    // Break if neither string found
                    if (d1 == -1 && d2 == -1) break;
                    // Get the smaller of the two (but must be positive)
                    if (d1 == -1 || (d2 != -1 && d2 < d1)) d1 = d2;
                    // Use d1 as the position from here on out               
                    string x = s.Substring(0, d1 + 2);
                    // Serial number
                    string serial = x.Substring(0, x.IndexOf('`'));
                    x = x.Substring(x.IndexOf('`') + 1);
                    // Return date
                    string rdate = x.Substring(0, x.IndexOf('`'));
                    x = x.Substring(x.IndexOf('`') + 1);
                    // Case name
                    string caseName = x.Substring(0, x.IndexOf('`'));
                    x = x.Substring(x.IndexOf('`') + 1);
                    // Note
                    string itemNote = x.Substring(0, x.LastIndexOf('`'));
                    // Get the medium.  If it is missing, place the serial number in the missing
                    // control.  If the location is at the vault, move it to the enterprise.
                    if ((m = Medium.GetMedium(serial)) != null)
                    {
                        // Missing?
                        if (m.Missing == true)
                        {
                            this.missingTapes.Value += serial + ";";
                            m.Missing = false;
                        }
                        // Location?
                        if (m.Location != Locations.Enterprise)
                        {
                            m.Location = Locations.Enterprise;
                        }
                        // Update?
                        if (m.ObjState == ObjectStates.Modified)
                        {
                            Medium.Update(ref m, 1);
                        }
                    }
                    // Add the item to the collection
                    items.Add(new SendListItemDetails(serial, rdate, itemNote, caseName));
                    // Truncate the data string
                    s = s.Length > d1 + 3 ? s.Substring(d1 + 3) : String.Empty;
                    // If we have no url yet but we have a case name, then set url to the edit case page
                    if (url == String.Empty && caseName.Length != 0)
                    {
                        url = "shipping-list-detail-edit-case.aspx";
                    }
                }
                // If we have no url, set it to the detail page
                if (url == String.Empty)
                {
                    url = "shipping-list-detail.aspx";
                }
                // Create the list
                sl = SendList.Create(items, SLIStatus.Submitted);
                // Append the list number to the url
                url += "?listNumber=" + sl.Name;
                // If we have no missing tapes, redirect now.  Otherwise, set the url in the viewstate.  We have
                // to do this because the page, after displaying the missing tapes, will have to post back, since
                // we have to do a Server.Transfer.
                if (this.missingTapes.Value.Length != 0)
                {
                    this.ViewState["URL"] = url;
                }
                else
                {
                    Server.Transfer(url);
                }
            }
            catch (CollectionErrorException ex)
            {
                this.DisplayErrors(this.PlaceHolder1, ex.Collection);
                return;
            }
            catch (Exception ex)
            {
                this.DisplayErrors(this.PlaceHolder1, ex.Message);
                return;
            }
        }
    }
}
