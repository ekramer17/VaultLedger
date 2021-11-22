using System;
using System.Data;
using System.Collections;
using System.Web.UI.WebControls;
using System.Collections.Specialized;
using Bandl.Library.VaultLedger.BLL;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.Security;
using Bandl.Library.VaultLedger.Exceptions;
using Bandl.Library.VaultLedger.Collections;

namespace Bandl.VaultLedger.Web.UI
{
	/// <summary>
	/// Summary description for compare_discrepancy_two.
	/// </summary>
	public class compare_discrepancy_two : BasePage
	{
        private int listId;
        private DataTable dataTable;
        private DataGridItem[] dataItems;
        private ListCompareResult receiveResult;
        private SendListCompareResult sendResult;

        protected System.Web.UI.WebControls.DropDownList ddlSelectAction;
        protected System.Web.UI.WebControls.Button btnGo;
        protected System.Web.UI.WebControls.PlaceHolder PlaceHolder1;
        protected System.Web.UI.WebControls.DataGrid DataGrid1;
        protected System.Web.UI.HtmlControls.HtmlGenericControl divTabsTwo;
        protected System.Web.UI.HtmlControls.HtmlGenericControl divTabsThree;
        protected System.Web.UI.HtmlControls.HtmlAnchor threeTabOneLink;
        protected System.Web.UI.HtmlControls.HtmlGenericControl threeTabThree;
        protected System.Web.UI.HtmlControls.HtmlAnchor twoTabOneLink;
        protected System.Web.UI.WebControls.Button btnOK1;
        protected System.Web.UI.WebControls.Button btnOK2;
		protected System.Web.UI.WebControls.LinkButton listLink;
        protected System.Web.UI.HtmlControls.HtmlAnchor threeTabThreeLink;
		
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
			this.twoTabOneLink.ServerClick += new System.EventHandler(this.twoTabOneLink_ServerClick);
			this.threeTabOneLink.ServerClick += new System.EventHandler(this.threeTabOneLink_ServerClick);
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
                // We should only be able to get here by transfer from the
                // other two discrepancy pages.  How we get the objects we 
                // need depends on from where we originated.
                if (Context.Handler is shipping_list_reconcile)
                {
                    this.sendResult = ((shipping_list_reconcile)Context.Handler).CompareResult;
                    this.listId = ((shipping_list_reconcile)Context.Handler).ListObject.Id;
                }
                else if (Context.Handler is receiving_list_reconcile)
                {
                    this.listId = ((receiving_list_reconcile)Context.Handler).ListObject.Id;
                    this.receiveResult = ((receiving_list_reconcile)Context.Handler).CompareResult;
                }
                else if (Context.Handler is compare_discrepancy_one)
                {
                    this.listId = ((compare_discrepancy_one)Context.Handler).ListId;
                    if (((compare_discrepancy_one)Context.Handler).SendResult != null)
                        this.sendResult = ((compare_discrepancy_one)Context.Handler).SendResult;
                    else
                        this.receiveResult = ((compare_discrepancy_one)Context.Handler).ReceiveResult;
                }
                else if (Context.Handler is compare_discrepancy_three)
                {
                    this.listId = ((compare_discrepancy_three)Context.Handler).ListId;
                    this.sendResult = ((compare_discrepancy_three)Context.Handler).SendResult;
                }
                else
                {
                    Response.Redirect("../default.aspx", false);
                }
                // Place objects in the viewstate.  Also, if the list is greater than
                // or equal to fully verified (I), then the user should not be able to
                // add media to the list.
                this.ViewState["ListId"] = this.listId;
                if (this.sendResult != null)
                {
                    this.ViewState["SendResult"] = this.sendResult;
                    if (SendList.GetSendList(listId, false).Status > SLStatus.FullyVerifiedI)
                    {
//                        this.ddlSelectAction.Items.Remove(ddlSelectAction.Items.FindByValue("Add"));
                        ddlSelectAction.Items.Add(new ListItem("Move to Vault", "Move"));
                    }
                }
                else
                {
                    this.ViewState["ReceiveResult"] = this.receiveResult;
					if (ReceiveList.GetReceiveList(listId, false).Status != RLStatus.Submitted)
					{
						this.ddlSelectAction.Items.Remove(ddlSelectAction.Items.FindByValue("Add"));    // Never allowed to add with a receive list
						ddlSelectAction.Items.Add(new ListItem("Move to Enterprise", "Move"));
					}
                }
                // If the list is greater than or equal to fully verified (I), then 
                // the user should not be able to add media to the list.
                // Bind to the datagrid;
                this.BindObject();
            }
        }
        /// <summary>
        /// Page prerender event handler (thrown by page master)
        /// </summary>
        protected override void Event_PagePreRender(object sender, System.EventArgs e)
        {
            // Click events for message box buttons
            this.SetControlAttr(this.btnOK1,  "onclick", "hideMsgBox('msgBoxMove');");
            this.SetControlAttr(this.btnOK2,  "onclick", "hideMsgBox('msgBoxAdd');");
            // Whether or not third tab is visible depends on whether or
            // not we are dealing with a send list or a receive list.
            this.divTabsTwo.Visible = receiveResult != null;
            this.divTabsThree.Visible = sendResult != null;
        }
        /// <summary>
        /// Places the compare results in a datatable and binds it to the datagrid
        /// </summary>
        private void BindObject()
        {
            ListCompareResult compareResult;
            this.dataTable = new DataTable();
            dataTable.Columns.Add("SerialNo", typeof(string));
			dataTable.Columns.Add("CaseName", typeof(string));
			// Get the correct object
            compareResult = sendResult != null ? sendResult : receiveResult;
            // Add the serial numbers to the table, one in each row
            if (compareResult.ScanNotList.Length == 0)
            {
                dataTable.Rows.Add(new object[] {"There are no discrepancies of this type", ""});
            }
            else
            {
                foreach (string serialNo in compareResult.ScanNotList)
                {
                    DataRow newRow = dataTable.NewRow();
                    newRow[0] = serialNo;
					newRow[1] = SendList.GetScanItemCase(this.listId, serialNo);
                    dataTable.Rows.Add(newRow);
                }
            }
            // Add the table to the viewstate
            this.ViewState["DataTable"] = this.dataTable;
            // Bind the datatable to the datagrid
            this.DataGrid1.DataSource = dataTable;
            this.DataGrid1.DataBind();
            // If there was no discrepancy data, adjust the datagrid cell
            if (compareResult.ScanNotList.Length == 0)
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
                    case "Add":
                        if (this.sendResult != null) this.AddItemsSend(); else this.AddItemsReceive();
                        break;
                    case "Move":
                        this.MoveMedia(this.sendResult != null ? Locations.Vault : Locations.Enterprise);
                        break;
                    default:
                        break;
                }
            }
        }
        /// <summary>
        /// Add items to the send list
        /// </summary>
        private void AddItemsSend()
        {
            // Create an empty item collection
            SendListItemCollection si = new SendListItemCollection();
            // Add the checked items to it - create a new list item for each
            foreach (DataGridItem i in dataItems)
			{
				si.Add(new SendListItemDetails(i.Cells[1].Text, String.Empty, String.Empty, i.Cells[2].Text));
			}
            // Add the items to the list
            try
            {
                SendListDetails sl = SendList.GetSendList(this.listId, false);
                SendList.AddItems(ref sl, ref si, SLIStatus.Submitted);   // Will be verified during comparison
                // Recompare
                this.sendResult = SendList.CompareListToScans(this.listId);
                this.ViewState["SendResult"] = this.sendResult;
                // Bind to the datagrid
                this.BindObject();
                // Display message box
                ClientScript.RegisterStartupScript(GetType(), "msgBoxAdd", "<script language=javascript>showMsgBox('msgBoxAdd')</script>");
                ClientScript.RegisterStartupScript(GetType(), "playSound", "<embed src=\"../sounds/msgBox.wav\" hidden=\"true\" autostart=\"true\">");
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
        /// Add items to the receive list
        /// </summary>
        private void AddItemsReceive()
        {
            // Create an empty item collection
            ReceiveListItemCollection ri = new ReceiveListItemCollection();
            // Add the checked items to it - create a new list item for each
            foreach (DataGridItem i in dataItems)
                ri.Add(new ReceiveListItemDetails(i.Cells[1].Text, String.Empty));
            // Add the items to the list
            try
            {
                ReceiveListDetails rl = ReceiveList.GetReceiveList(this.listId, false);
                ReceiveList.AddItems(ref rl, ref ri);   // Will be verified during comparison
                // Recompare
                this.receiveResult = ReceiveList.CompareListToScans(this.listId);
                this.ViewState["ReceiveResult"] = this.receiveResult;
                // Bind to the datagrid
                this.BindObject();
                // Display message box
                ClientScript.RegisterStartupScript(GetType(), "msgBoxAdd", "<script language=javascript>showMsgBox('msgBoxAdd')</script>");
                ClientScript.RegisterStartupScript(GetType(), "playSound", "<embed src=\"../sounds/msgBox.wav\" hidden=\"true\" autostart=\"true\">");
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
        /// Move the checked media to the enterprise, or add them if they do not exist
        /// </summary>
        private void MoveMedia(Locations loc)
        {
            MediumDetails m = null;
            StringCollection mi = new StringCollection();
            MediumCollection mu = new MediumCollection();
            // For each checked item, get the medium.  If it doesn't exist, create it.
            foreach (DataGridItem i in dataItems)
            {
                if ((m = Medium.GetMedium(i.Cells[1].Text)) == null)
                {
                    if (loc == Locations.Vault || SealedCase.GetSealedCase(i.Cells[1].Text) == null)
                    {
                        mi.Add(i.Cells[1].Text);
                    }
                    else
                    {
                        foreach (MediumDetails m1 in SealedCase.GetResidentMedia(i.Cells[1].Text))
                        {
                            if (mu.Find(m1.SerialNo) == null)
                            {
                                m.Location = loc;
                                mu.Add(m);
                            }
                        }
                    }
                }
                else if (m.Location != loc && mu.Find(i.Cells[1].Text) == null)
                {
                    m.Location = loc;
                    mu.Add(m);
                }
            }
            // Add the new media
            if (mi.Count != 0)
            {
                foreach (string serialNo in mi)
                {
                    try
                    {
                        MediumRange[] mr = null;   // needed only for method call
                        Medium.Insert(serialNo, serialNo, loc, out mr);
                    }
                    catch (Exception ex)
                    {
                        this.DisplayErrors(this.PlaceHolder1, ex.Message);
                        return;
                    }
                }
            }
            // Update the existing media
            if (mu.Count != 0)
            {
                try
                {
                    Medium.Update(ref mu, 1);
                    // Get the current array from the compare result
                    ArrayList modifiedArray = new ArrayList(sendResult != null ? sendResult.ScanNotList : receiveResult.ScanNotList);
                    // Remove all the updated serial number from the array
                    foreach (MediumDetails m1 in mu)
                        modifiedArray.RemoveAt(modifiedArray.BinarySearch(m1.SerialNo));
                    // Replace with modifed array
                    if (sendResult != null)
                        sendResult.ScanNotList = (string[])modifiedArray.ToArray(typeof(string));
                    else
                        receiveResult.ScanNotList = (string[])modifiedArray.ToArray(typeof(string));
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
            // Display message box
            ClientScript.RegisterStartupScript(GetType(), "msgBoxMove", "<script language=javascript>showMsgBox('msgBoxMove')</script>");
            ClientScript.RegisterStartupScript(GetType(), "playSound", "<embed src=\"../sounds/msgBox.wav\" hidden=\"true\" autostart=\"true\">");
        }
        /// <summary>
        /// Click event for tab one anchor.  We use this rather than an href so that
        /// we can use server.transfer.
        /// </summary>
        private void twoTabOneLink_ServerClick(Object sender, EventArgs e)
        {
            Server.Transfer("compare-discrepancy-one.aspx");
        }
        /// <summary>
        /// Click event for tab one anchor.  We use this rather than an href so that
        /// we can use server.transfer.
        /// </summary>
        private void threeTabOneLink_ServerClick(Object sender, EventArgs e)
        {
            Server.Transfer("compare-discrepancy-one.aspx");
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
