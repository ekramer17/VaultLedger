using System;
using System.Data;
using System.Text;
using System.Web.UI.WebControls;
using Bandl.Library.VaultLedger.BLL;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.Security;
using Bandl.Library.VaultLedger.Collections;
using Bandl.Library.VaultLedger.Exceptions;

namespace Bandl.VaultLedger.Web.UI
{
	/// <summary>
	/// Summary description for shipping_list_reconcile.
	/// </summary>
	public class shipping_list_reconcile : BasePage
	{
        private SendListDetails sendList;
        private SendListScanCollection compareFiles;
        private SendListCompareResult compareResult;
        
		protected System.Web.UI.WebControls.Label lblListNo;
		protected System.Web.UI.WebControls.Label lblStatus;
		protected System.Web.UI.WebControls.Label lblCreateDate;
		protected System.Web.UI.HtmlControls.HtmlInputCheckBox cbAllItems;
		protected System.Web.UI.HtmlControls.HtmlInputCheckBox cbItemChecked;
        protected System.Web.UI.WebControls.Button btnYes;
        protected System.Web.UI.WebControls.Button btnNo;
        protected System.Web.UI.WebControls.Button btnNewFile;
        protected System.Web.UI.WebControls.DataGrid DataGrid1;
        protected System.Web.UI.WebControls.Button btnCompare;
        protected System.Web.UI.WebControls.Button btnCancel;
        protected System.Web.UI.WebControls.PlaceHolder PlaceHolder1;
        protected System.Web.UI.WebControls.Button btnOther;
        protected System.Web.UI.WebControls.Button btnOK;
        protected System.Web.UI.WebControls.LinkButton listLink;
        protected System.Web.UI.HtmlControls.HtmlGenericControl twoTabs;
        protected System.Web.UI.HtmlControls.HtmlGenericControl threeTabs;
		protected System.Web.UI.WebControls.DropDownList ddlSelectAction;
		protected System.Web.UI.WebControls.Button btnGo;
		protected System.Web.UI.HtmlControls.HtmlGenericControl AppletHolder;
		protected System.Web.UI.HtmlControls.HtmlInputHidden Hidden1;
		protected System.Web.UI.WebControls.Label lblAccount;

        // Properties used in page transfer
        public SendListCompareResult CompareResult
        {
            get {return this.compareResult;}
        }

        public SendListDetails ListObject
        {
            get {return this.sendList;}
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
			this.listLink.Click += new System.EventHandler(this.listLink_Click);
			this.btnNewFile.Click += new System.EventHandler(this.btnNewFile_Click);
			this.btnGo.Click += new System.EventHandler(this.btnGo_Click);
			this.DataGrid1.PreRender += new System.EventHandler(this.DataGrid1_PreRender);
			this.btnCompare.Click += new System.EventHandler(this.btnCompare_Click);
			this.btnCancel.Click += new System.EventHandler(this.btnCancel_Click);
			this.btnYes.Click += new System.EventHandler(this.btnYes_Click);
			this.btnNo.Click += new System.EventHandler(this.btnNo_Click);
			this.btnOK.Click += new System.EventHandler(this.btnOK_Click);
			this.btnOther.Click += new System.EventHandler(this.btnOther_Click);

		}
        #endregion
	
		/// <summary>
        /// Page initialization event handler (thrown by page master)
        /// </summary>
        protected override void Event_PageInit(object sender, System.EventArgs e)
        {
			Role[] allowedRoles = new Role[2];

            this.helpId = 13;
            this.levelTwo = LevelTwoNav.Shipping;
            this.pageTitle = "Shipping List Batch Reconcile";

            // Viewers and auditors shouldn't be able to access this page
			allowedRoles[0] = Role.Operator;
			allowedRoles[1] = Role.VaultOps;
            DoSecurity(allowedRoles, "default.aspx");
        }
        /// <summary>
        /// Page load event handler (thrown by page master)
        /// </summary>
        protected override void Event_PageLoad(object sender, System.EventArgs e)
		{
            // Click events for message box buttons
            this.SetControlAttr(this.btnYes, "onclick", "hideMsgBox('msgBoxTransmit');");
            this.SetControlAttr(this.btnNo, "onclick", "hideMsgBox('msgBoxTransmit');");
            this.SetControlAttr(this.btnOK, "onclick", "hideMsgBox('msgBoxDone');");
            this.SetControlAttr(this.btnOther, "onclick", "hideMsgBox('msgBoxOther');");

            if (Page.IsPostBack)
            {
                sendList = (SendListDetails)this.ViewState["SendList"];
                compareFiles = (SendListScanCollection)this.ViewState["CompareFiles"];
                if (this.ViewState["CompareResult"] != null)
                    compareResult = (SendListCompareResult)this.ViewState["CompareResult"];
            }
            else
            {
                if (Request.QueryString["listNumber"] == null)
                {
                    Response.Redirect("send-lists.aspx", false);
                }
                else
                {
                    try
                    {
                        // Retrieve the list and place it in the viewstate
                        try
                        {
                            sendList = SendList.GetSendList(Request.QueryString["listNumber"], false);
                            this.ViewState["SendList"] = sendList;
                        }
                        catch (Exception e1)
                        {
                            throw new ApplicationException("A: " + e1.Message);
                        }
                        // Set the text for the page label
                        try
                        {
                            this.lblListNo.Text = sendList.Name;
                            this.lblCreateDate.Text = DisplayDate(sendList.CreateDate, true, false);
                            this.lblAccount.Text = sendList.Account != String.Empty ? sendList.Account : "(Composite List)";
                        }
                        catch (Exception e1)
                        {
                            throw new ApplicationException("B: " + e1.Message);
                        }
                        // Set the hyperlink in the datagrid
                        try
                        {
                            ((HyperLinkColumn)this.DataGrid1.Columns[1]).DataNavigateUrlFormatString = "compare-file-view.aspx?listNumber=" + sendList.Name + "&fileName={0}";
                        }
                        catch (Exception e1)
                        {
                            throw new ApplicationException("C: " + e1.Message);
                        }
                        // Set the tab page preference
                        try
                        {
                            TabPageDefault.Update(TabPageDefaults.SendReconcileMethod, Context.Items[CacheKeys.Login], 2);
                        }
                        catch (Exception e1)
                        {
                            throw new ApplicationException("D: " + e1.Message);
                        }
                        // Fetch and bind
                        this.ObtainCompareFiles();
                    }
                    catch (Exception e1)
                    {
Session["MainMenuMessage"] = e1.Message;
Response.Redirect("../default.aspx", true);
                    }
                }
            }
		}
        /// <summary>
        /// Page load event handler (thrown by page master)
        /// </summary>
        protected override void Event_PagePreRender(object sender, System.EventArgs e)
        {   
            // Which tabs to we show?
            if (ProductLicense.GetProductLicense(LicenseTypes.RFID).Units == 1) 
            {
                this.twoTabs.Visible = false;
                this.threeTabs.Visible = true;
            }
            else
            {
                this.threeTabs.Visible = false;
                this.twoTabs.Visible = true;
            }
        }
        
		/// <summary>
		/// Alter drop down list items as needed
		/// </summary>
		private void AlterDropdownItems()
		{
//			ListItem liv = ddlChooseAction.Items.FindByValue("Verify");

			// VaultOps can only have the 'Mark Missing' option, remove other options
//			if (CustomPermission.CurrentOperatorRole() == Role.VaultOps)
//			{
//				ddlSelectAction.Items.Remove(liv);
//
//				return;
//			}   

			// Allow one-click verification?
//			bool ve = Preference.GetPreference(PreferenceKeys.AllowOneClickVerify).Value == "YES";
//
//			if (ve && liv == null)
//				ddlChooseAction.Items.Add(new ListItem("Verify Selected", "Verify"));
//			else if (!ve && liv != null)
//				ddlChooseAction.Items.Remove(liv);
		}

        /// <summary>
        /// Prerender event handler for datagrid
        /// </summary>
        private void DataGrid1_PreRender(object sender, EventArgs e)
        {
            // If we have no lists for the datagrid, then create an empty table
            // with one row so that we may display a message to the user.
            if (compareFiles.Count == 0)
            {
                DataTable dataTable = new DataTable();
                dataTable.Columns.Add("Name", typeof(string));
                dataTable.Columns.Add("CreateDate", typeof(string));
				dataTable.Columns.Add("LastCompared", typeof(string));
				dataTable.Rows.Add(new object[] {"", "", ""});
                // Bind the datagrid to the empty table
                this.DataGrid1.DataSource = dataTable;
                this.DataGrid1.DataBind();
                // Create the text in the first column and render the
                // checkbox column invisible
                this.DataGrid1.Columns[0].Visible = false;
                if (sendList != null)
                {
                    this.DataGrid1.Items[0].Cells[1].Text = String.Format("None yet created for list {0}", sendList.Name);
                }
                else
                {
                    this.DataGrid1.Items[0].Cells[1].Text = "None yet created";
                }
            }
        }
        /// <summary>
        /// Fetches the compare files from the database and binds them to the datagrid
        /// </summary>
        private void ObtainCompareFiles()
        {
            try
            {
                compareFiles = SendList.GetScansForList(sendList.Name);
                this.ViewState["CompareFiles"] = compareFiles;
            }
            catch (Exception e1)
            {
                throw new ApplicationException("E: " + e1.Message);
            }
            // Refetch the list, in case status has changed
            try
            {
                sendList = SendList.GetSendList(sendList.Id, false);
                this.ViewState["SendList"] = sendList;
            }
            catch (Exception e1)
            {
                throw new ApplicationException("F: " + e1.Message);
            }
            // Set the status label
            try
            {
                this.lblStatus.Text = StatusString(sendList.Status);
            }
            catch (Exception e1)
            {
                throw new ApplicationException("G: " + e1.Message);
            }
            // Bind to the datagrid
            try
            {
                this.DataGrid1.DataSource = compareFiles;
                this.DataGrid1.DataBind();
            }
            catch (Exception e1)
            {
                throw new ApplicationException("H: " + e1.Message);
            }
        }
        /// <summary>
        /// Cancel button event handler
        /// </summary>
		private void btnCancel_Click(object sender, System.EventArgs e)
		{
			Response.Redirect(String.Format("shipping-list-detail.aspx?listNumber={0}", sendList.Name), false);
		}
        /// <summary>
        /// New button event handler
        /// </summary>
        private void btnNewFile_Click(object sender, System.EventArgs e)
        {
            switch (TabPageDefault.GetDefault(TabPageDefaults.SendReconcileNewFile, Context.Items[CacheKeys.Login]))
            {
                case 1:
                    Server.Transfer("new-compare-list-manual-scan.aspx");
                    break;
                case 2:
                    Server.Transfer("new-compare-list-batch-file-step-one.aspx");
                    break;
                case 3:
                    Server.Transfer("new-compare-list-rfid-file-step-one.aspx");
                    break;
            }
        }
        /// <summary>
        /// Compare button event handler
        /// </summary>
		private void btnCompare_Click(object sender, System.EventArgs e)
		{
            if (0 == compareFiles.Count)
            {
                this.DisplayErrors(this.PlaceHolder1, "No compare files have been created against this list.");
            }
            else
            {
			    try
			    {
                    // Set the page level result
                    compareResult = SendList.CompareListToScans(sendList.Name);
                    this.ViewState["CompareResult"] = compareResult;
                    // If we have at least one item not accounted for, transfer to the results page
                    if (compareResult.ListNotScan.Length != 0)
                    {
                        Server.Transfer("compare-discrepancy-one.aspx");
                    }
                    else
                    {
                        // Refetch the list in case of status change
                        sendList = SendList.GetSendList(sendList.Id, false);
                        this.ViewState["SendList"] = sendList;
                        // If there were no entries in the scans that were not on the list, 
                        // as well as no case discrepancies, then just display the transmit message box.
                        // If the list no longer exists, then it was a composite that has been fully verified and automatically cleared.
                        if (compareResult.ScanNotList.Length != 0 || compareResult.CaseDifferences.Length != 0)
                        {
                            ClientScript.RegisterStartupScript(GetType(), "msgBoxOther", "<script language=javascript>showMsgBox('msgBoxOther')</script>");
                            ClientScript.RegisterStartupScript(GetType(), "playSound", "<embed src=\"../sounds/msgBox.wav\" hidden=\"true\" autostart=\"true\">");
                        }
                        else if (sendList != null && sendList.Status == SLStatus.FullyVerifiedI && SendList.StatusEligible(sendList, SLStatus.Xmitted))
                        {
                            ClientScript.RegisterStartupScript(GetType(), "msgBoxTransmit", "<script language=javascript>showMsgBox('msgBoxTransmit')</script>");
                            ClientScript.RegisterStartupScript(GetType(), "playSound", "<embed src=\"../sounds/msgBox.wav\" hidden=\"true\" autostart=\"true\">");
                        }
                        else
                        {
                            ClientScript.RegisterStartupScript(GetType(), "msgBoxDone", "<script language=javascript>showMsgBox('msgBoxDone')</script>");
                            ClientScript.RegisterStartupScript(GetType(), "playSound", "<embed src=\"../sounds/msgBox.wav\" hidden=\"true\" autostart=\"true\">");
                        }
                    }
			    }
			    catch (Exception ex)
			    {
                    this.DisplayErrors(this.PlaceHolder1, ex.Message);
			    }
            }
        }
        /// <summary>
        /// No button event handler
        /// </summary>
		private void btnNo_Click(object sender, System.EventArgs e)
		{
            Response.Redirect(String.Format("shipping-list-detail.aspx?listNumber={0}", sendList.Name), false);
        }
        /// <summary>
        /// Yes button event handler
        /// </summary>
        private void btnYes_Click(object sender, System.EventArgs e)
        {
            try
            {
                // Transmit the list
                SendList.Transmit(sendList);
                // Redirect to the detail page
                Response.Redirect(String.Format("shipping-list-detail.aspx?listNumber={0}", sendList.Name), false);
            }
            catch (Exception ex)
            {
                this.DisplayErrors(this.PlaceHolder1, ex.Message);
            }
        }
        /// <summary>
        /// Other button event handler
        /// </summary>
        private void btnOther_Click(object sender, System.EventArgs e)
        {
            Server.Transfer("compare-discrepancy-one.aspx");
        }
        /// <summary>
        /// Click event handler for btnOK
        /// </summary>
        private void btnOK_Click(object sender, System.EventArgs e)
        {
            Response.Redirect(String.Format("shipping-list-detail.aspx?listNumber={0}", sendList.Name), false);
        }
        /// <summary>
        /// Click event handler for list link
        /// </summary>
        private void listLink_Click(object sender, EventArgs e)
        {
            Response.Redirect(String.Format("shipping-list-detail.aspx?listNumber={0}", sendList.Name), false);
        }

		private void btnGo_Click(object sender, System.EventArgs e)
		{
			System.Text.StringBuilder b1 = null;

			if (Request["__EVENTARGUMENT"] == "R")
			{
				try
				{
					SendList.CreateScan(sendList.Name, Date.Display(Time.Local, true, true, true), Convert.FromBase64String(Hidden1.Value));
					ObtainCompareFiles();
					ClientScript.RegisterStartupScript(GetType(), Guid.NewGuid().ToString("N"), "<script type=\"text/javascript\">setTimeout('onUpload()',5);</script>");
				}
				catch (Exception e1)
				{
					this.DisplayErrors(this.PlaceHolder1, e1.Message);
				}
			}
			else switch (this.ddlSelectAction.SelectedValue)
			{
				case "R":
					this.ObtainCompareFiles();
					break;
				case "D":
					this.DoDelete();
					break;
				case "U":
					b1 = new System.Text.StringBuilder();
					b1.Append("<applet codebase=\"../applet\" code=\"ScannerSync.class\" archive=\"scansync.jar\" id=\"applet1\" width=\"0\" height=\"0\" MAYSCRIPT>");
					b1.Append("<param name=\"action\" value=\"upload\" />");
					b1.Append("<param name=\"java_arguments\" value=\"-Xmx512m\" />");
					b1.Append("</applet>");
					AppletHolder.InnerHtml = b1.ToString();
					ClientScript.RegisterStartupScript(GetType(), Guid.NewGuid().ToString("N"), "<script type=\"text/javascript\">setTimeout('runapp()',10);</script>");
					break;
				case "S":
					b1 = new System.Text.StringBuilder();
					b1.Append("<applet codebase=\"../applet\" code=\"ScannerSync.class\" archive=\"scansync.jar\" id=\"applet1\" width=\"0\" height=\"0\" MAYSCRIPT>");
					b1.Append("<param name=\"action\" value=\"download\" />");
					b1.Append("<param name=\"content\" value=\"" + GetDownloadContent() + "\" />");
					b1.Append("<param name=\"java_arguments\" value=\"-Xmx512m\" />");
					b1.Append("</applet>");
					AppletHolder.InnerHtml = b1.ToString();
					ClientScript.RegisterStartupScript(GetType(), Guid.NewGuid().ToString("N"), "<script type=\"text/javascript\">setTimeout('runapp()',10);</script>");
					break;
				default:
					break;
			}
		
		}

		/// <summary>
		/// Delete button event handler
		/// </summary>
		private void DoDelete()
		{
			SendListScanCollection deleteScans = new SendListScanCollection();
			// Collect all the compare files marked for deletion
			foreach (DataGridItem dgi in this.CollectCheckedItems(this.DataGrid1))
				deleteScans.Add(compareFiles[dgi.ItemIndex]);
			// Delete them, then refetch
			if (deleteScans.Count != 0)
			{
				try
				{
					SendList.DeleteScans(ref deleteScans);
					this.ObtainCompareFiles();
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

		private String GetDownloadContent()
		{
			Int32 y1 = -1;
			StringBuilder s1 = new StringBuilder();
            SLIStatus i1 = SLIStatus.AllValues ^ SLIStatus.Removed;
			SendListItemCollection c1 = SendList.GetSendListItemPage(sendList.Id, 1, 1000000, i1, SLISorts.SerialNo, out y1);
			// Headers
			s1.Append("$VAULTLEDGER BATCH FILE");
			s1.Append("\r\n");
			s1.Append("$SEND/RECEIVE LIST - VERIFY");
			s1.Append("\r\n");
			s1.Append("$DATE " + DateTime.Now.ToString("yyyy/MM/dd HH:mm:ss"));
			s1.Append("\r\n");
			s1.Append("$LIST " + sendList.Name);
			s1.Append("\r\n");
			// Data
			foreach (SendListItemDetails x1 in c1)
			{
				s1.Append(x1.Account);
				s1.Append(",");
				s1.Append(x1.SerialNo);
				s1.Append(",");
				s1.Append(x1.CaseName);
				s1.Append(",");
				s1.Append("0");	// case flag
				s1.Append(",");
				s1.Append(x1.Status == SLIStatus.VerifiedI || x1.Status == SLIStatus.VerifiedI ? "1" : "0");
				s1.Append(",");
				s1.Append("0");	// scanned flag
				s1.Append("\r\n");
			}

			return Convert.ToBase64String(Encoding.UTF8.GetBytes(s1.ToString()));
		}
	}
}
