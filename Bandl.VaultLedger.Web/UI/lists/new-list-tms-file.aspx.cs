using System;
using System.Web;
using System.Text;
using System.Collections.Generic;
using Bandl.Library.VaultLedger.BLL;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.Collections;
using Bandl.Library.VaultLedger.Security;

namespace Bandl.VaultLedger.Web.UI
{
	/// <summary>
	/// Summary description for new_list_tms_file.
	/// </summary>
	public class new_list_tms_file : BasePage
	{
        private SendListCollection sl = null;
        private ReceiveListCollection rl = null;
        private List<String> excludedSerials = null;
        private const string REPORTDICTATED = "(Report-Dictated)";

        protected System.Web.UI.HtmlControls.HtmlForm Form1;
		protected System.Web.UI.HtmlControls.HtmlInputFile File1;
		protected System.Web.UI.WebControls.PlaceHolder PlaceHolder1;
        protected System.Web.UI.WebControls.DropDownList ddlAccount;
        protected System.Web.UI.HtmlControls.HtmlTableRow rowAccount;
        protected System.Web.UI.HtmlControls.HtmlGenericControl tabControls1;
        protected System.Web.UI.HtmlControls.HtmlGenericControl tabControls2;
        protected System.Web.UI.WebControls.Button btnOK;

        public SendListCollection SendLists
        {
            get {return sl;}
        }

        public ReceiveListCollection ReceiveLists
        {
            get {return rl;}
        }

        public List<String> ExcludedSerials
        {
            get { return excludedSerials; }
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
            this.btnOK.Click += new System.EventHandler(this.btnOK_Click);

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
        /// Page prerender event handler (thrown by page master)
        /// </summary>
        protected override void Event_PagePreRender(object sender, System.EventArgs e)
        {
            if (!this.IsPostBack)
            {
                string x1 = Request.QueryString["src"];
                // Account?
                rowAccount.Visible = (x1 == null || x1 != "auto") && Preference.GetPreference(PreferenceKeys.DeclareListAccounts).Value != "NO";
                // If the row account is visible then we need to fill the dropdown
                if (rowAccount.Visible)
                {
                    ddlAccount.Items.Add("-Select Account-");
                    foreach (AccountDetails a in Account.GetAccounts())
                        ddlAccount.Items.Add(a.Name);
                    // Add line for report dictated accounts
                    ddlAccount.Items.Add(REPORTDICTATED);
                }
                // Set the tab page preference
                TabPageDefault.Update(TabPageDefaults.NewSendList, Context.Items[CacheKeys.Login], 3);
            }
            // Tab controls?
            ProductLicenseDetails p = ProductLicense.GetProductLicense(LicenseTypes.RFID);
            this.tabControls1.Visible = p.Units != 1;
            this.tabControls2.Visible = p.Units == 1;
        }
        /// <summary>
        /// Event handler for OK button
        /// </summary>
        private void btnOK_Click(object sender, System.EventArgs e)
        {
            byte[] inputFile;
            HttpPostedFile postedFile;

            if (File1.Value.Trim().Length != 0)
            {
                if ((postedFile = File1.PostedFile) == null || postedFile.ContentLength == 0)
                {
                    this.DisplayErrors(this.PlaceHolder1, "Unable to find or access '" + File1.Value + "'");
                }
                else if (rowAccount.Visible && ddlAccount.SelectedIndex == 0)
                {
                    this.DoFocus(this.ddlAccount);
                    this.DisplayErrors(this.PlaceHolder1, "Please select an account for any shipping lists that may be generated.");
                }
                else
                {
                    try
                    {
                        // Initialize
                        sl = new SendListCollection();
                        rl = new ReceiveListCollection();
                        excludedSerials = new List<String>();
                        string accountName = String.Empty;
                        // Read the file
                        inputFile = new byte[postedFile.ContentLength];
                        postedFile.InputStream.Read(inputFile, 0, postedFile.ContentLength);
                        // Create the lists from items on the uploaded list
                        if (rowAccount.Visible == true)
                        {
                            if (ddlAccount.SelectedItem.Text != REPORTDICTATED)
                            {
                                accountName = ddlAccount.SelectedItem.Text;
                            }
                            else
                            {
                                accountName = TMSReport.DictateString;
                            }
                        }
                        //
                        // 2007-05-07 ERIC
                        //
                        // Test the file.  If it is an imation file, call the Imation object.  Otherwise use the
                        // TMS functionality.  Implementing the imation functionality here will allow users to
                        // use the RFID whether they want to use the applet or not.
                        //
                        if (Encoding.UTF8.GetString(inputFile).StartsWith("VAULTLEDGER IMATION RFID ENCRYPTED XML DOCUMENT"))
                        {
                            // Transfer to shipping list detail or display error
                            if ((sl = Imation.CreateSendList(inputFile, accountName)).Count != 0)
                            {
                                Server.Transfer("shipping-list-detail.aspx?listNumber=" + sl[0].Name);
                            }
                            else
                            {
                                DisplayErrors(PlaceHolder1, "No list was produced");
                            }
                        }
                        else
                        {
                            // Source?
                            string x1 = Request.QueryString["src"];
                            bool a1 = x1 != null && x1 == "auto";
                            // Auto transmit?
                            string x2 = Request.QueryString["xmit"];
                            if (x2 == null) x2 = String.Empty;
                            // Create the lists
                            TMSReport.CreateLists(a1, inputFile, postedFile.FileName, accountName, ref sl, ref rl, ref excludedSerials);
                            // Transmit shipping lists?
                            if (x2 == "S" || x2 == "B")
                            {
                                foreach (SendListDetails y1 in sl)
                                {
                                    try
                                    {
                                        // Verify?
                                        if (0 != (SendList.Statuses & SLStatus.FullyVerifiedI))
                                        {
                                            SendList.Verify(SendList.GetSendList(y1.Name, false));
                                        }
                                        // Transmit
                                        SendList.Transmit(SendList.GetSendList(y1.Name, false));
                                    }
                                    catch (Exception x)
                                    {
                                        if (x1 == "auto")
                                            Tracer.Trace(x);
                                    }
                                }
                            }
                            // Trasmit receive lists?
                            if (x2 == "R" || x2 == "B")
                            {
                                foreach (ReceiveListDetails y1 in rl)
                                {
                                    try
                                    {
                                        // Verify?
                                        if (0 != (ReceiveList.Statuses & RLStatus.FullyVerifiedI))
                                        {
                                            ReceiveList.Verify(ReceiveList.GetReceiveList(y1.Name, false));
                                        }
                                        // Transmit
                                        ReceiveList.Transmit(ReceiveList.GetReceiveList(y1.Name, true));
                                    }
                                    catch (Exception x)
                                    {
                                        if (x1 == "auto")
                                            Tracer.Trace(x);
                                    }
                                }
                            }
                            // Transfer to the tms list page
                            if (sl.Count != 0 || rl.Count == 0)
                            {
                                Server.Transfer("tms-lists-shipping.aspx");
                            }
                            else
                            {
                                Server.Transfer("tms-lists-receiving.aspx");
                            }
                        }
                    }
                    catch (Exception ex)
                    {
                        this.DisplayErrors(this.PlaceHolder1, ex.Message);
                    }
                }
            }
        }
	}
}
