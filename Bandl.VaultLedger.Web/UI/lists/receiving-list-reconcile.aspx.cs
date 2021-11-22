using System;
using System.Data;
using System.Text;
using System.Web.UI.WebControls;
using Bandl.Library.VaultLedger.BLL;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.Security;
using Bandl.Library.VaultLedger.Exceptions;
using Bandl.Library.VaultLedger.Collections;

namespace Bandl.VaultLedger.Web.UI
{
	/// <summary>
	/// Summary description for receiving_list_reconcile.
	/// </summary>
	public class receiving_list_reconcile : BasePage
	{
        private ReceiveListDetails receiveList;
        private ListCompareResult compareResult;
        private ReceiveListScanCollection compareFiles;

        protected System.Web.UI.WebControls.Label lblListNo;
        protected System.Web.UI.WebControls.Label lblCreateDate;
        protected System.Web.UI.HtmlControls.HtmlInputCheckBox cbAllItems;
        protected System.Web.UI.HtmlControls.HtmlInputCheckBox cbItemChecked;
        protected System.Web.UI.HtmlControls.HtmlInputButton btnNewFile;
        protected System.Web.UI.WebControls.DataGrid DataGrid1;
        protected System.Web.UI.HtmlControls.HtmlInputButton btnCompare;
        protected System.Web.UI.HtmlControls.HtmlInputButton btnCancel;
        protected System.Web.UI.WebControls.PlaceHolder PlaceHolder1;
        protected System.Web.UI.HtmlControls.HtmlInputButton btnOK;
        protected System.Web.UI.WebControls.Label lblStatus;
        protected System.Web.UI.HtmlControls.HtmlInputButton btnOther;
        protected System.Web.UI.HtmlControls.HtmlGenericControl msgBoxOther;
        protected System.Web.UI.WebControls.LinkButton listLink;
        protected System.Web.UI.HtmlControls.HtmlGenericControl twoTabs;
        protected System.Web.UI.HtmlControls.HtmlGenericControl threeTabs;
		protected System.Web.UI.WebControls.DropDownList ddlSelectAction;
		protected System.Web.UI.WebControls.Button btnGo;
		protected System.Web.UI.HtmlControls.HtmlGenericControl AppletHolder;
		protected System.Web.UI.HtmlControls.HtmlInputHidden Hidden1;
        protected System.Web.UI.WebControls.Label lblAccount;

        // Properties used in page transfer
        public ListCompareResult CompareResult
        {
            get {return this.compareResult;}
        }

        public ReceiveListDetails ListObject
        {
            get {return this.receiveList;}
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
			this.btnGo.Click += new System.EventHandler(this.btnGo_Click);
			this.DataGrid1.PreRender += new System.EventHandler(this.DataGrid1_PreRender);
			this.btnNewFile.ServerClick += new System.EventHandler(this.btnNewFile_Click);
			this.btnCompare.ServerClick += new System.EventHandler(this.btnCompare_Click);
			this.btnCancel.ServerClick += new System.EventHandler(this.btnCancel_Click);
			this.btnOther.ServerClick += new System.EventHandler(this.btnOther_Click);

		}
        #endregion
	
        /// <summary>
        /// Page initialization event handler (thrown by page master)
        /// </summary>
        protected override void Event_PageInit(object sender, System.EventArgs e)
        {
			Role[] allowedRoles = new Role[2];

            this.helpId = 13;
            this.levelTwo = LevelTwoNav.Receiving;
            this.pageTitle = "Receiving List Batch Reconcile";

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
            if (this.IsPostBack)
            {
                receiveList = (ReceiveListDetails)this.ViewState["ReceiveList"];
                compareFiles = (ReceiveListScanCollection)this.ViewState["CompareFiles"];
                if (null != this.ViewState["CompareResult"])
                    compareResult = (ListCompareResult)this.ViewState["CompareResult"];
            }
            else
            {
                if (Request.QueryString["listNumber"] == null)
                {
                    Response.Redirect("receive-lists.aspx", false);
                }
                else
                {
                    try
                    {
                        // Retrieve the list and place it in the viewstate
                        receiveList = ReceiveList.GetReceiveList(Request.QueryString["listNumber"], false);
                        this.ViewState["ReceiveList"] = receiveList;
                        // Set the text for the page label
                        this.lblListNo.Text = receiveList.Name;
                        this.lblCreateDate.Text = DisplayDate(receiveList.CreateDate, true, false);
                        this.lblAccount.Text = receiveList.Account != String.Empty ? receiveList.Account : "(Composite List)";
                        // Set the hyperlink in the datagrid
                        ((HyperLinkColumn)this.DataGrid1.Columns[1]).DataNavigateUrlFormatString = "compare-file-view.aspx?listNumber=" + receiveList.Name + "&fileName={0}";
                        // Set the tab page preference
                        TabPageDefault.Update(TabPageDefaults.ReceiveReconcileMethod, Context.Items[CacheKeys.Login], 2);
                        // Fetch and bind
                        this.ObtainCompareFiles();
                    }
                    catch
                    {
                        Response.Redirect("receive-lists.aspx", false);
                    }
                }
            }
        }
        /// <summary>
        /// Page load event handler (thrown by page master)
        /// </summary>
        protected override void Event_PagePreRender(object sender, System.EventArgs e)
        {
            // Click events for message box buttons
            this.SetControlAttr(this.btnOK, "onclick", "hideMsgBox('msgBoxDone');");
            this.SetControlAttr(this.btnOther, "onclick", "hideMsgBox('msgBoxOther');");
            // And on for the OK button
            if (receiveList == null)
            {
;//                this.SetControlAttr(btnOK, "onclick", "location.href='receive-lists.aspx'");
            }
            else
            {
;//                this.SetControlAttr(btnOK, "onclick", String.Format("location.href='receiving-list-detail.aspx?listNumber={0}'", receiveList.Name));
            }
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
                if (receiveList != null)
                {
                    this.DataGrid1.Items[0].Cells[1].Text = String.Format("None yet created for list {0}", receiveList.Name);
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
            compareFiles = ReceiveList.GetScansForList(receiveList.Name);
            this.ViewState["CompareFiles"] = compareFiles;
            // Refetch the list, in case status has changed
            receiveList = ReceiveList.GetReceiveList(receiveList.Id, false);
            this.ViewState["ReceiveList"] = receiveList;
            // Set the status label
            this.lblStatus.Text = StatusString(receiveList.Status);
            // Bind to the datagrid
            this.DataGrid1.DataSource = compareFiles;
            this.DataGrid1.DataBind();
        }
        /// <summary>
        /// Cancel button event handler
        /// </summary>
        private void btnCancel_Click(object sender, System.EventArgs e)
        {
            Response.Redirect(String.Format("receiving-list-detail.aspx?listNumber={0}", receiveList.Name), false);
        }
        /// <summary>
        /// New button event handler
        /// </summary>
        private void btnNewFile_Click(object sender, System.EventArgs e)
        {
            switch (TabPageDefault.GetDefault(TabPageDefaults.ReceiveReconcileNewFile, Context.Items[CacheKeys.Login]))
            {
                case 1:
                    Server.Transfer("new-compare-receive-list-manual-scan.aspx");
                    break;
                case 2:
                    Server.Transfer("new-compare-receive-list-batch-file-step-one.aspx");
                    break;
                case 3:
                    Server.Transfer("new-compare-receive-list-rfid-file-step-one.aspx");
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
                    compareResult = ReceiveList.CompareListToScans(receiveList.Name);
                    // If we have at least one item not accounted for, transfer to the results page
                    if (compareResult.ListNotScan.Length != 0)
                    {
                        Server.Transfer("compare-discrepancy-one.aspx");
                    }
                    else
                    {
                        // Refetch the list in case of status change
                        receiveList = ReceiveList.GetReceiveList(receiveList.Id, false);
                        this.ViewState["ReceiveList"] = receiveList;
                        // If there were no entries in the scans that were not on the list, 
                        // then just display the cleared message box.  If the list no longer exists, then
                        // it was a composite that has been fully verified and automatically cleared.
                        if (compareResult.ScanNotList.Length != 0)
                        {
                            this.ViewState["CompareResult"] = compareResult;
                            ClientScript.RegisterStartupScript(GetType(), "msgBoxOther", "<script language=javascript>showMsgBox('msgBoxOther')</script>");
                            ClientScript.RegisterStartupScript(GetType(), "playSound", "<embed src=\"../sounds/msgBox.wav\" hidden=\"true\" autostart=\"true\" />");
                        }
                        else if (receiveList == null || receiveList.Status == RLStatus.FullyVerifiedI || receiveList.Status >= RLStatus.FullyVerifiedII)
                        {
                            ClientScript.RegisterStartupScript(GetType(), "msgBoxDone", "<script language=javascript>showMsgBox('msgBoxDone')</script>");
                            ClientScript.RegisterStartupScript(GetType(), "playSound", "<embed src=\"../sounds/msgBox.wav\" hidden=\"true\" autostart=\"true\" />");
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
        /// Other button event handler
        /// </summary>
        private void btnOther_Click(object sender, System.EventArgs e)
        {
            Server.Transfer("compare-discrepancy-two.aspx");
        }
        /// <summary>
        /// Click event handler for list link
        /// </summary>
        private void listLink_Click(object sender, EventArgs e)
        {
            Response.Redirect(String.Format("receiving-list-detail.aspx?listNumber={0}", this.receiveList.Name), false);
        }

		private void btnGo_Click(object sender, System.EventArgs e)
		{
			System.Text.StringBuilder b1 = null;

			if (Request["__EVENTARGUMENT"] == "R")
			{
				try
				{
					ReceiveList.CreateScan(receiveList.Name, Date.Display(Time.Local, true, true, true), Convert.FromBase64String(Hidden1.Value));
					this.ObtainCompareFiles();
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
			ReceiveListScanCollection deleteScans = new ReceiveListScanCollection();
			// Collect all the compare files marked for deletion
			foreach (DataGridItem i in this.CollectCheckedItems(this.DataGrid1))
				deleteScans.Add(compareFiles[i.ItemIndex]);
			// Delete them, then refetch
			if (deleteScans.Count != 0)
			{
				try
				{
					ReceiveList.DeleteScans(ref deleteScans);
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
			RLIStatus i1 = RLIStatus.AllValues ^ RLIStatus.Removed;
			ReceiveListItemCollection c1 = ReceiveList.GetReceiveListItemPage(receiveList.Id, 1, 1000000, i1, RLISorts.SerialNo, out y1);
			// Headers
			s1.Append("$VAULTLEDGER BATCH FILE");
			s1.Append("\r\n");
			s1.Append("$SEND/RECEIVE LIST - VERIFY");
			s1.Append("\r\n");
			s1.Append("$DATE " + DateTime.Now.ToString("yyyy/MM/dd HH:mm:ss"));
			s1.Append("\r\n");
			s1.Append("$LIST " + receiveList.Name);
			s1.Append("\r\n");
			// Data
			foreach (ReceiveListItemDetails x1 in c1)
			{
				s1.Append(x1.Account);
				s1.Append(",");
				s1.Append(x1.SerialNo);
				s1.Append(",");
				s1.Append(x1.CaseName);
				s1.Append(",");
				s1.Append("0");	// case flag
				s1.Append(",");
				s1.Append(x1.Status == RLIStatus.VerifiedI || x1.Status == RLIStatus.VerifiedI ? "1" : "0");
				s1.Append(",");
				s1.Append("0");	// scanned flag
				s1.Append("\r\n");
			}

			return Convert.ToBase64String(Encoding.UTF8.GetBytes(s1.ToString()));
		}
	}
}
