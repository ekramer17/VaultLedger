using System;
using System.Web;
using System.Collections.Generic;
using Bandl.Library.VaultLedger.BLL;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.Collections;
using Bandl.Library.VaultLedger.Security;

namespace Bandl.VaultLedger.Web.UI
{
	/// <summary>
	/// Summary description for new_receive_list_tms_file.
	/// </summary>
	public class new_receive_list_tms_file : BasePage
	{
        private SendListCollection sendLists = null;
        private ReceiveListCollection receiveLists = null;
        private List<String> excludedSerials = null;
        private const string REPORTDICTATED = "(Report-Dictated)";

        protected System.Web.UI.HtmlControls.HtmlForm Form1;
        protected System.Web.UI.HtmlControls.HtmlInputFile File1;
        protected System.Web.UI.WebControls.PlaceHolder PlaceHolder1;
        protected System.Web.UI.WebControls.DropDownList ddlAccount;
        protected System.Web.UI.HtmlControls.HtmlTableRow rowAccount;
        protected System.Web.UI.HtmlControls.HtmlGenericControl accountNotice;
        protected System.Web.UI.WebControls.Button btnOK;

        public SendListCollection SendLists
        {
            get {return sendLists;}
        }

        public ReceiveListCollection ReceiveLists
        {
            get {return receiveLists;}
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
            this.pageTitle = "New Receiving List";
            this.levelTwo = LevelTwoNav.Receiving;
            this.helpId = 16;
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
                rowAccount.Visible = Preference.GetPreference(PreferenceKeys.DeclareListAccounts).Value != "NO";
                accountNotice.Visible = rowAccount.Visible;
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
                TabPageDefault.Update(TabPageDefaults.NewReceiveList, Context.Items[CacheKeys.Login], 2);
            }
        }
        /// <summary>
        /// Event handler for OK button
        /// </summary>
        private void btnOK_Click(object sender, System.EventArgs e)
        {
            string fileName = File1.Value;
            HttpPostedFile postedFile = File1.PostedFile;
 
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
                        string accountName = String.Empty;
                        sendLists = new SendListCollection();
                        receiveLists = new ReceiveListCollection();
                        excludedSerials = new List<String>();
                        // Read the file
                        byte[] inputFile = new byte[postedFile.ContentLength];
                        postedFile.InputStream.Read(inputFile, 0, postedFile.ContentLength);
                        // Do we have an explicit account?
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
                        // Create the lists
                        TMSReport.CreateLists(inputFile, postedFile.FileName, accountName, ref sendLists, ref receiveLists, ref excludedSerials);
                        // Transfer to the tms list page
                        if (receiveLists.Count != 0 || sendLists.Count == 0)
                        {
                            Server.Transfer("tms-lists-receiving.aspx");
                        }
                        else
                        {
                            Server.Transfer("tms-lists-shipping.aspx");
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
