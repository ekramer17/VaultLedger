using System;
using System.Web;
using System.Text;
using Bandl.Library.VaultLedger.BLL;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.Collections;
using Bandl.Library.VaultLedger.Security;

namespace Bandl.VaultLedger.Web.UI
{
    /// <summary>
    /// Summary description for new_list_batch_batch_file_step_one.
    /// </summary>
    public class new_list_batch_batch_file_step_one : BasePage
    {
        protected System.Web.UI.HtmlControls.HtmlInputFile File1;
        protected System.Web.UI.HtmlControls.HtmlForm Form1;
        protected System.Web.UI.HtmlControls.HtmlInputButton btnCancel;
        protected System.Web.UI.WebControls.Button btnOK;
        protected System.Web.UI.WebControls.DropDownList ddlAccount;
        protected System.Web.UI.HtmlControls.HtmlTableRow rowAccount;
        protected System.Web.UI.HtmlControls.HtmlGenericControl tabControls1;
        protected System.Web.UI.HtmlControls.HtmlGenericControl tabControls2;
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
                if (Preference.GetPreference(PreferenceKeys.DeclareListAccounts).Value != "YES")
                {
                    rowAccount.Visible = false;
                }
                else
                {
                    rowAccount.Visible = true;
                    ddlAccount.Items.Add("-Select Account-");
                    foreach (AccountDetails a in Account.GetAccounts())
                        ddlAccount.Items.Add(a.Name);
                }
                // Set the tab page preference
                TabPageDefault.Update(TabPageDefaults.NewSendList, Context.Items[CacheKeys.Login], 2);
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
                    this.DisplayErrors(this.PlaceHolder1, "Please select an account for this list.");
                }
                else
                {
                    try
                    {
                        // Read the file
                        string accountName = String.Empty;
                        inputFile = new byte[postedFile.ContentLength];
                        postedFile.InputStream.Read(inputFile, 0, postedFile.ContentLength);
                        // Create the lists from items on the uploaded list
                        if (rowAccount.Visible == true)
                        {
                            accountName = ddlAccount.SelectedItem.Text;
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
                            SendListCollection sl = Imation.CreateSendList(inputFile, accountName);
                            // Redirect to shipping list detail
                            Server.Transfer(String.Format("shipping-list-detail.aspx?listNumber={0}", sl[0].Name));
                        }
                        else
                        {
                            SendListDetails sl = SendList.Create(inputFile, SLIStatus.Submitted, accountName);
                            // Redirect to shipping list detail
                            Server.Transfer(String.Format("shipping-list-detail.aspx?listNumber={0}", sl.Name));
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

