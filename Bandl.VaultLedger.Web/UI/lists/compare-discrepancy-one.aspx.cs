using System;
using System.Data;
using System.Collections;
using System.Web.UI.WebControls;
using Bandl.Library.VaultLedger.BLL;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.Security;
using Bandl.Library.VaultLedger.Exceptions;
using Bandl.Library.VaultLedger.Collections;

namespace Bandl.VaultLedger.Web.UI
{
	/// <summary>
	/// Summary description for compare_discrepancy_one.
	/// </summary>
	public class compare_discrepancy_one : BasePage
	{
        private int listId;
        private string listName;
        private DataTable dataTable;
        private ListCompareResult receiveResult;
        private DataGridItem[] dataItems = null;
        private SendListCompareResult sendResult;
        protected System.Web.UI.WebControls.Button btnGo;
        protected System.Web.UI.WebControls.DataGrid DataGrid1;
        protected System.Web.UI.WebControls.DropDownList ddlSelectAction;
        protected System.Web.UI.HtmlControls.HtmlGenericControl divTabsThree;
        protected System.Web.UI.HtmlControls.HtmlAnchor threeTabTwoLink;
        protected System.Web.UI.HtmlControls.HtmlGenericControl threeTabThree;
        protected System.Web.UI.HtmlControls.HtmlAnchor threeTabThreeLink;
        protected System.Web.UI.HtmlControls.HtmlGenericControl divTabsTwo;
        protected System.Web.UI.HtmlControls.HtmlAnchor twoTabTwoLink;
        protected System.Web.UI.HtmlControls.HtmlInputButton btnOK;
		protected System.Web.UI.WebControls.Button btnOther;
		protected System.Web.UI.WebControls.LinkButton listLink;
		protected System.Web.UI.WebControls.PlaceHolder PlaceHolder1;

        public string ListName { get { return listName; } }

        // Variables used for server transfer
        public int ListId
        {
            get {return this.listId;}
        }
		
        public ListCompareResult ReceiveResult
        {
            get {return this.receiveResult;}
        }

        public SendListCompareResult SendResult
        {
            get {return this.sendResult;}
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
			this.twoTabTwoLink.ServerClick += new System.EventHandler(this.twoTabTwoLink_ServerClick);
			this.threeTabTwoLink.ServerClick += new System.EventHandler(this.threeTabTwoLink_ServerClick);
			this.threeTabThreeLink.ServerClick += new System.EventHandler(this.threeTabThreeLink_ServerClick);

		}
        #endregion

	
        /// <summary>
        /// Page initialization event handler (thrown by page master)
        /// </summary>
        protected override void Event_PageInit(object sender, System.EventArgs e)
        {
            this.helpId = 13;
            this.pageTitle = "List Compare Discrepancies";
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
                // Get the list id and the datatable
                this.listId = (int)this.ViewState["ListId"];
                this.dataTable = (DataTable)this.ViewState["DataTable"];
                // Get the correct compare result
                if (this.ViewState["SendResult"] != null)
                {
                    this.levelTwo = LevelTwoNav.Shipping;
                    sendResult = (SendListCompareResult)this.ViewState["SendResult"];
                }
                else
                {
                    this.levelTwo = LevelTwoNav.Receiving;
                    receiveResult = (ListCompareResult)this.ViewState["ReceiveResult"];
                }
            }
            else
            {
                // We should only be able to get here by transfer from four pages: shipping
                // list reconcile, receiving list reconcile, and the other two discrepancy
                // pages.  How we get the objects we need depends on from where we originated.
                if (Context.Handler is shipping_list_reconcile)
                {
                    this.sendResult = ((shipping_list_reconcile)Context.Handler).CompareResult;
                    this.listId = ((shipping_list_reconcile)Context.Handler).ListObject.Id;
                    // If there are no discrepancies on this page but there are discrepancies
                    // for another page, go to the other page.
                    if (sendResult.ListNotScan.Length == 0)
                    {
                        if (sendResult.ScanNotList.Length != 0)
                            Server.Transfer("compare-discrepancy-two.aspx");
                        else if (sendResult.CaseDifferences.Length != 0)
                            Server.Transfer("compare-discrepancy-three.aspx");
                    }
                }
                else if (Context.Handler is receiving_list_reconcile)
                {
                    this.receiveResult = ((receiving_list_reconcile)Context.Handler).CompareResult;
                    this.listId = ((receiving_list_reconcile)Context.Handler).ListObject.Id;
                }
                else if (Context.Handler is compare_discrepancy_two)
                {
                    this.listId = ((compare_discrepancy_two)Context.Handler).ListId;
                    if (((compare_discrepancy_two)Context.Handler).SendResult != null)
                        this.sendResult = ((compare_discrepancy_two)Context.Handler).SendResult;
                    else
                        this.receiveResult = ((compare_discrepancy_two)Context.Handler).ReceiveResult;
                }
                else if (Context.Handler is compare_discrepancy_three)  // Only shipping lists use this page
                {
                    this.listId = ((compare_discrepancy_three)Context.Handler).ListId;
                    this.sendResult = ((compare_discrepancy_three)Context.Handler).SendResult;
                }
                else
                {
                    Response.Redirect("../default.aspx", false);
                }
                // Place objects in the viewstate
                this.ViewState["ListId"] = this.listId;
                if (this.sendResult != null)
                    this.ViewState["SendResult"] = this.sendResult;
                else
                    this.ViewState["ReceiveResult"] = this.receiveResult;
                // Should remove option be visible?
                if (sendResult != null && SendList.GetSendList(listId, false).Status >= SLStatus.Xmitted)
                    this.ddlSelectAction.Items.Remove(this.ddlSelectAction.Items.FindByValue("Remove"));
                else if (receiveResult != null && ReceiveList.GetReceiveList(listId, false).Status >= RLStatus.Xmitted)
                    this.ddlSelectAction.Items.Remove(this.ddlSelectAction.Items.FindByValue("Remove"));
                // Bind to the datagrid;
                this.BindObject();
            }
		}
        /// <summary>
        /// Page prerender event handler (thrown by page master)
        /// </summary>
        protected override void Event_PagePreRender(object sender, System.EventArgs e)
        {
            this.divTabsTwo.Visible = receiveResult != null;
            this.divTabsThree.Visible = sendResult != null;
            // Remove the verify item?
            bool ve = Preference.GetPreference(PreferenceKeys.AllowOneClickVerify).Value == "YES";
            ListItem liv = this.ddlSelectAction.Items.FindByValue("Verify");
            if (!ve && liv != null) ddlSelectAction.Items.Remove(liv);
        }
        /// <summary>
        /// Places the compare results in a datatable and binds it to the datagrid
        /// </summary>
        private void BindObject()
        {
            ListCompareResult compareResult;
            this.dataTable = new DataTable();
            dataTable.Columns.Add("SerialNo", typeof(string));
            // Get the correct object
            compareResult = sendResult != null ? sendResult : receiveResult;
            // Add the serial numbers to the table, one in each row
            if (compareResult.ListNotScan.Length == 0)
            {
                dataTable.Rows.Add(new object[] {"There are no discrepancies of this type"});
            }
            else foreach (string serialNo in compareResult.ListNotScan)
            {
                DataRow newRow = dataTable.NewRow();
                newRow[0] = serialNo;
                dataTable.Rows.Add(newRow);
            }
            // Add the table to the viewstate
            this.ViewState["DataTable"] = this.dataTable;
            // Bind the datatable to the datagrid
            this.DataGrid1.DataSource = dataTable;
            this.DataGrid1.DataBind();
            // If there was no discrepancy data, adjust the datagrid cell
            if (compareResult.ListNotScan.Length == 0)
                this.DataGrid1.Columns[0].Visible = false;   // checkbox invisible
        }
        /// <summary>
        /// Go button event handler
        /// </summary>
		private void btnGo_Click(object sender, System.EventArgs e)
		{
            if ((dataItems = this.CollectCheckedItems(this.DataGrid1)).Length != 0)
            {
                switch (this.ddlSelectAction.SelectedValue)
                {
                    case "Verify":
                        if (sendResult != null)
                            this.VerifySend();
                        else
                            this.VerifyReceive();
                        break;
                    case "Missing":
                        this.MakeMissing(0);
                        break;
                    case "Remove":
                        if (sendResult != null)
                            this.RemoveSend();
                        else
                            this.RemoveReceive();
                        break;
                    default:
                        break;
                }
            }
		}
        /// <summary>
        /// Verifies the checked send list items
        /// </summary>
        private void VerifySend()
        {
            SendListItemDetails item = null;
            ArrayList minusSerials = new ArrayList(sendResult.ListNotScan);
            SendListItemCollection vi = new SendListItemCollection();
            // Place its items in a collection
            SendListDetails s = SendList.GetSendList(this.listId, true);
            SendListItemCollection li = new SendListItemCollection(s);
            // Place each of the checked items in a different collection, and remove it
            // from the currentSerials arraylist.  Go backwards so that we don't throw
            // off the indexes of the arraylist.
            for (int i = dataItems.Length - 1; i > -1; i--)
            {
                if ((item = li.Find(dataItems[i].Cells[1].Text)) != null)
                {
                    if (SendList.StatusEligible(item.Status, SLIStatus.VerifiedI | SLIStatus.VerifiedII))
                    {
                        vi.Add(item);
                        minusSerials.Remove(item.SerialNo);
                    }
                }
            }
            // If no items, just return
            if (vi.Count == 0) return;
            // Verify the items if we have any
            try
            {
                // Verify
                SendList.Verify(this.listId, ref vi);
                // Replace the compare result
                sendResult.ListNotScan = (string[])minusSerials.ToArray(typeof(string));
                this.ViewState["SendResult"] = this.sendResult;
                // Bind the object
                this.BindObject();
                // Check for full verification again
                CheckFullyVerified(ListTypes.Send, (int)s.Status);
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
        /// Verifies the checked receive list items
        /// </summary>
        private void VerifyReceive()
        {
            ReceiveListItemDetails item = null;
            ArrayList minusSerials = new ArrayList(receiveResult.ListNotScan);
            ReceiveListItemCollection vi = new ReceiveListItemCollection();
            // Place its items in a collection
            ReceiveListDetails r = ReceiveList.GetReceiveList(this.listId, true);
            ReceiveListItemCollection li = new ReceiveListItemCollection(r);
            // Place each of the checked items in a different collection, and remove it
            // from the currentSerials arraylist.  Go backwards so that we don't throw
            // off the indexes of the arraylist.
            for (int i = dataItems.Length - 1; i > -1; i--)
            {
                if ((item = li.Find(dataItems[i].Cells[1].Text)) != null)
                {
                    if (ReceiveList.StatusEligible(item.Status, RLIStatus.VerifiedI | RLIStatus.VerifiedII))
                    {
                        vi.Add(item);
                        minusSerials.Remove(item.SerialNo);
                    }
                }
            }
            // If no items, just return
            if (vi.Count == 0) return;
            // Verify the items if we have any
            try
            {
                // Verify 
                ReceiveList.Verify(this.listId, ref vi);
                // Replace the compare result
                receiveResult.ListNotScan = (string[])minusSerials.ToArray(typeof(string));
                this.ViewState["ReceiveResult"] = this.receiveResult;
                // Bind the object
                this.BindObject();
                // Check for full verification again
                CheckFullyVerified(ListTypes.Receive, (int)r.Status);
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
        /// Marks the checked media as missing
        /// </summary>
        private void MakeMissing(int caseAction)
        {
            MediumDetails m = null;
            MediumCollection mediumCollection = new MediumCollection();
            // Get the items from the datagrid
            foreach (DataGridItem i in this.dataItems)
            {
                if ((m = Medium.GetMedium(i.Cells[1].Text)).Missing == false) 
                {
                    m.Missing = true;
                    mediumCollection.Add(m);
                }
            }
            // Mark the media as missing
            try
            {
                // Recompare the scans against the list
                if (this.sendResult != null)
                {
                    // Get the original status
                    int x = (int)SendList.GetSendList(listId,false).Status;
                    // Update the media
                    Medium.Update(ref mediumCollection, caseAction);
                    // Check for full verification (if last tape was marked missing list may already be verified)
                    if (false == CheckFullyVerified(ListTypes.Send, x))
                    {
                        // Recompare
                        this.sendResult = SendList.CompareListToScans(this.listId);
                        this.ViewState["SendResult"] = this.sendResult;
                        // Bind to the datagrid
                        this.BindObject();
                        // Check if fully verified
                        CheckFullyVerified(ListTypes.Send, (int)SendList.GetSendList(listId,false).Status);
                    }
                }
                else
                {
                    // Get the original status
                    int x = (int)ReceiveList.GetReceiveList(listId,false).Status;
                    // Update the media
                    Medium.Update(ref mediumCollection, caseAction);
                    // Check for full verification (if last tape was marked missing list may already be verified)
                    if (false == CheckFullyVerified(ListTypes.Receive, x))
                    {
                        // Recompare
                        this.receiveResult = ReceiveList.CompareListToScans(this.listId);
                        this.ViewState["ReceiveResult"] = this.receiveResult;
                        // Bind to the datagrid
                        this.BindObject();
                        // Check if fully verified
                        CheckFullyVerified(ListTypes.Receive, (int)ReceiveList.GetReceiveList(listId, false).Status);
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
        /// Removes send list items from list
        /// </summary>
        private void RemoveSend()
        {
            SendListItemCollection ri = new SendListItemCollection();
            // Get the list items
            SendListDetails sl = SendList.GetSendList(this.listId, true);
            SendListItemCollection li = new SendListItemCollection(sl.ListItems);
            // Add the checked items to the collection
            foreach (DataGridItem i in this.dataItems)
                ri.Add(li.Find(i.Cells[1].Text));
            // Remove the items from the list
            try
            {
                SendList.RemoveItems(sl.Name, ref ri);
                // Recompare
                this.sendResult = SendList.CompareListToScans(this.listId);
                this.ViewState["SendResult"] = this.sendResult;
                // Bind to the datagrid
                this.BindObject();
                // Check if fully verified
                CheckFullyVerified(ListTypes.Send, (int)sl.Status);
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
        /// Removes receive list items from list
        /// </summary>
        private void RemoveReceive()
        {
            ReceiveListItemCollection ri = new ReceiveListItemCollection();
            // Get the list items
            ReceiveListDetails rl = ReceiveList.GetReceiveList(this.listId, true);
            ReceiveListItemCollection li = new ReceiveListItemCollection(rl.ListItems);
            // Add the checked items to the collection
            foreach (DataGridItem i in this.dataItems)
                ri.Add(li.Find(i.Cells[1].Text));
            // Remove the items from the list
            try
            {
                ReceiveList.RemoveItems(rl.Name, ref ri);
                // Recompare
                this.receiveResult = ReceiveList.CompareListToScans(this.listId);
                this.ViewState["ReceiveResult"] = this.receiveResult;
                // Bind to the datagrid
                this.BindObject();
                // Check if fully verified
                CheckFullyVerified(ListTypes.Receive, (int)rl.Status);
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
        /// Checks the status of a send list to determine if the list is fully verified.  If so, displays
        /// a message box and redirects to the shipping list detail page.
        /// </summary>
        private bool CheckFullyVerified(ListTypes listType, int originalStatus)
        {
            if (listType == ListTypes.Send)
            {
				String b1 = "msgBoxVerify";
                // Get the list
                SendListDetails s = SendList.GetSendList(this.listId, false);
                // Check the status
                if ((int)s.Status > originalStatus && (s.Status == SLStatus.FullyVerifiedI || s.Status == SLStatus.FullyVerifiedII || s.Status == SLStatus.Processed))
                {
					if (s.Status == SLStatus.FullyVerifiedI)
					{
						this.SetControlAttr(this.btnOK,  "onclick", "hideMsgBox('" + b1 + "')");
					}
					else
					{
						this.SetControlAttr(this.btnOK,  "onclick", "location.href='send-lists.aspx';");
					}

					ClientScript.RegisterStartupScript(GetType(), "msgBoxVerify", "<script language=javascript>showMsgBox('" + b1 + "')</script>");
					ClientScript.RegisterStartupScript(GetType(), "playSound", "<embed src=\"../sounds/msgBox.wav\" hidden=\"true\" autostart=\"true\">");

                    // Return true
                    return true;
                }
            }
            else
            {
                // Get the list
                ReceiveListDetails r = ReceiveList.GetReceiveList(this.listId, false);
                // Check the status
                if ((int)r.Status > originalStatus && (r.Status == RLStatus.FullyVerifiedI || r.Status == RLStatus.FullyVerifiedII || r.Status == RLStatus.Processed))
                {
                    this.listName = r.Name;
                    ClientScript.RegisterStartupScript(GetType(), "msgBoxVerify", "<script language=javascript>showMsgBox('msgBoxVerify')</script>");
                    ClientScript.RegisterStartupScript(GetType(), "playSound", "<embed src=\"../sounds/msgBox.wav\" hidden=\"true\" autostart=\"true\">");
                    if (r.Status == RLStatus.FullyVerifiedI)
						this.SetControlAttr(this.btnOK,  "onclick", "hideMsgBox('msgBoxVerify')");
//						this.SetControlAttr(this.btnOK,  "onclick", String.Format("location.href='receiving-list-detail.aspx?listNumber={0}';", r.Name));
                    else
                        this.SetControlAttr(this.btnOK,  "onclick", "location.href='receive-lists.aspx';");
                    // Return true
                    return true;
                }
            }
            // Return false
            return false;
        }
        /// <summary>
        /// Click event for tab two anchor.  We use this rather than an href so that
        /// we can use server.transfer.
        /// </summary>
        private void twoTabTwoLink_ServerClick(Object sender, EventArgs e)
        {
            Server.Transfer("compare-discrepancy-two.aspx");
        }
        /// <summary>
        /// Click event for tab two anchor.  We use this rather than an href so that
        /// we can use server.transfer.
        /// </summary>
        private void threeTabTwoLink_ServerClick(Object sender, EventArgs e)
        {
            Server.Transfer("compare-discrepancy-two.aspx");
        }
        /// <summary>
        /// Click event for tab three anchor.  We use this rather than an href so that
        /// we can use server.transfer.
        /// </summary>
        private void threeTabThreeLink_ServerClick(Object sender, EventArgs e)
        {
            Server.Transfer("compare-discrepancy-three.aspx");
        }
		/// <summary>
		/// Redirect to detail page
		/// </summary>
		private void listLink_Click(object sender, System.EventArgs e)
		{
			if (this.levelTwo == LevelTwoNav.Shipping)
			{
				Response.Redirect(String.Format("shipping-list-detail.aspx?listNumber={0}", this.sendResult.ListName), false);		
			}
			else
			{
				Response.Redirect(String.Format("receiving-list-detail.aspx?listNumber={0}", this.receiveResult.ListName), false);		
			}
		}
	}
}
