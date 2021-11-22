using System;
using System.Data;
using System.Collections;
using System.Web.UI.WebControls;
using Bandl.Library.VaultLedger.BLL;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.Exceptions;
using Bandl.Library.VaultLedger.Collections;
using Bandl.Library.VaultLedger.Security;

namespace Bandl.VaultLedger.Web.UI
{
	/// <summary>
	/// Summary description for compare_discrepancy_three.
	/// </summary>
	public class compare_discrepancy_three : BasePage
	{
        private int listId;
        private DataGridItem[] di;
        private SendListCompareResult sendResult;
        protected System.Web.UI.WebControls.DataGrid DataGrid1;
        protected System.Web.UI.HtmlControls.HtmlAnchor threeTabOneLink;
        protected System.Web.UI.WebControls.DropDownList ddlSelectAction;
        protected System.Web.UI.WebControls.Button btnGo;
        protected System.Web.UI.WebControls.PlaceHolder PlaceHolder1;
		protected System.Web.UI.WebControls.LinkButton listLink;
        protected System.Web.UI.HtmlControls.HtmlAnchor threeTabTwoLink;

        // Variables used for server transfer
        public int ListId
        {
            get {return this.listId;}
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
			this.threeTabOneLink.ServerClick += new System.EventHandler(this.threeTabOneLink_ServerClick);
			this.threeTabTwoLink.ServerClick += new System.EventHandler(this.threeTabTwoLink_ServerClick);

		}
        #endregion


        /// <summary>
        /// Page initialization event handler (thrown by page master)
        /// </summary>
        protected override void Event_PageInit(object sender, System.EventArgs e)
        {
            this.helpId = 13;
            this.levelTwo = LevelTwoNav.Shipping;
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
                this.listId = (int)this.ViewState["ListId"];
                this.sendResult = (SendListCompareResult)this.ViewState["SendResult"];
            }
            else
            {
                // We should only be able to get here by transfer from the
                // other two discrepancy pages.  How we get the objects we 
                // need depends on from where we originated.  Also, this
                // page is only visible when the list is a send list, so
                // we don't have to bother with receive list logic.
                if (Context.Handler is shipping_list_reconcile)
                {
                    this.sendResult = ((shipping_list_reconcile)Context.Handler).CompareResult;
                    this.listId = ((shipping_list_reconcile)Context.Handler).ListObject.Id;
                }
                else if (Context.Handler is compare_discrepancy_one)
                {
                    this.listId = ((compare_discrepancy_one)Context.Handler).ListId;
                    this.sendResult = ((compare_discrepancy_one)Context.Handler).SendResult;
                }
                else if (Context.Handler is compare_discrepancy_two)
                {
                    this.listId = ((compare_discrepancy_two)Context.Handler).ListId;
                    this.sendResult = ((compare_discrepancy_two)Context.Handler).SendResult;
                }
                else
                {
                    Response.Redirect("../default.aspx", false);
                }
                // Place objects in the viewstate
                this.ViewState["ListId"] = this.listId;
                this.ViewState["SendResult"] = this.sendResult;
                // Bind to the datagrid;
                this.BindObject();
            }
        }
        /// <summary>
        /// Places the compare results in a datatable and binds it to the datagrid
        /// </summary>
        private void BindObject()
        {
            if (this.sendResult.CaseDifferences.Length != 0)
            {
                this.DataGrid1.DataSource = this.sendResult.CaseDifferences;
                this.DataGrid1.Columns[0].Visible = true;
                this.DataGrid1.DataBind();
            }
            else
            {
                DataTable dataTable = new DataTable();
                dataTable.Columns.Add("SerialNo", typeof(string));
                dataTable.Columns.Add("ListCase", typeof(string));
                dataTable.Columns.Add("ScanCase", typeof(string));
                dataTable.Rows.Add(new object[] {"There are no discrepancies of this type", "", ""});
                // Bind the datatable
                this.DataGrid1.Columns[0].Visible = false;
                this.DataGrid1.DataSource = dataTable;
                this.DataGrid1.DataBind();
            }
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
        /// Click event for tab two anchor.  We use this rather than an href so that
        /// we can use server.transfer.
        /// </summary>
        private void threeTabTwoLink_ServerClick(Object sender, EventArgs e)
        {
            Server.Transfer("compare-discrepancy-two.aspx");
        }
        /// <summary>
        /// Go button event handler
        /// </summary>
        private void btnGo_Click(object sender, System.EventArgs e)
        {
            if ((di = this.CollectCheckedItems(this.DataGrid1)).Length != 0)
            {
                switch (this.ddlSelectAction.SelectedValue)
                {
                    case "Remove":
                        RemoveFromCases();
                        break;
                    case "Insert":
                        InsertIntoCases();
                        break;
                    default:
                        break;
                }
            }
        }
        /// <summary>
        /// Removes selected tapes from cases
        /// </summary>
        private void RemoveFromCases()
        {
            try
            {
                // Create a collection to hold the tapes to be removed from cases
                SendListItemCollection c = new SendListItemCollection();
                // Get all the items that must be removed from cases
                foreach (DataGridItem i in CollectCheckedItems(this.DataGrid1))
                {
                    // Get the send list item
                    string serialNo = sendResult.CaseDifferences[i.ItemIndex].SerialNo;
                    SendListItemDetails si = SendList.GetSendListItem(serialNo);
                    // If we have one and it is currently in a case, add it to the collection
                    if (si != null && si.CaseName.Length != 0)
                    {
                        c.Add(si);
                    }
                }
                // If we have no objects in the collection, then raise error
                if (c.Count == 0)
                {
                    DisplayErrors(PlaceHolder1, "No media selected are currently in cases.");
                }
                else
                {
                    SendList.RemoveFromCases(c);
                    // If we were successful in removing from cases, then we have to 
                    // adjust the case conflicts.
                    ArrayList adjustedConflicts = new ArrayList(sendResult.CaseDifferences);
                    // If the item removed from a case has no compare case, then remove it
                    // from the collection.  Otherwise, adjust the item to reflect an empty
                    // string in the current case column.
                    for (int i = 0; i < c.Count; i++)
                    {
                        for (int j = adjustedConflicts.Count - 1; j >= 0; j -= 1)
                        {
                            // Get a reference to the case disparity
                            SendListCompareResult.CaseDisparity d = (SendListCompareResult.CaseDisparity)adjustedConflicts[j];
                            // If we have a scan case, then blank the list case and leave the conflict.  Otherwise
                            // remove the conflict
                            if (d.SerialNo == c[i].SerialNo)
                            {
                                if (d.ScanCase.Length != 0)
                                {
                                    d.ListCase = String.Empty;
                                }
                                else
                                {
                                    adjustedConflicts.RemoveAt(j);
                                }
                            }
                        }
                    }
                    // Replace the case differences in the page send result object
                    sendResult.CaseDifferences = (SendListCompareResult.CaseDisparity[])adjustedConflicts.ToArray(typeof(SendListCompareResult.CaseDisparity));
                    // Place the result back in the viewstate
                    ViewState["SendResult"] = sendResult;
                    // Bind the object to the grid
                    BindObject();
                }
            }
            catch (CollectionErrorException ex)
            {
                DisplayErrors(PlaceHolder1, ex.Collection);
            }
            catch (Exception ex)
            {
                DisplayErrors(PlaceHolder1, ex.Message);
            }
        }
        /// <summary>
        /// Removes selected tapes from cases
        /// </summary>
        private void InsertIntoCases()
        {
            try
            {
                // Place all the case differences in an array list
                ArrayList caseConflicts = new ArrayList(sendResult.CaseDifferences);
                // Create a collection to hold the tapes to be removed from cases
                SendListItemCollection c = new SendListItemCollection();
                // Get all the items that must be inserted into compare cases cases
                foreach (DataGridItem i in CollectCheckedItems(this.DataGrid1))
                {
                    // Make sure we have a case into which to insert item
                    string fileCase = sendResult.CaseDifferences[i.ItemIndex].ScanCase;
                    if (fileCase.Length == 0) continue;
                    // Get the send list item
                    string serialNo = sendResult.CaseDifferences[i.ItemIndex].SerialNo;
                    SendListItemDetails si = SendList.GetSendListItem(serialNo);
                    // If we have the item, then update the item with the 
                    // new case name and add it to the collection
                    if (si != null)
                    {
                        si.CaseName = fileCase;
                        c.Add(si);
                    }
                }
                // If we have no objects in the collection, then raise error
                if (c.Count == 0)
                {
                    DisplayErrors(PlaceHolder1, "The compare files have no case listed for any of the media selected.");
                }
                else
                {
                    // Update the send list items
                    SendList.UpdateItems(ref c);
                    // If we were successful in removing from cases, then we have to 
                    // adjust the case conflicts.
                    ArrayList adjustedConflicts = new ArrayList(sendResult.CaseDifferences);
                    // Remove the updated items from the collection
                    for (int i = 0; i < c.Count; i++)
                    {
                        for (int j = adjustedConflicts.Count - 1; j >= 0; j -= 1)
                        {
                            // Get a reference to the case disparity
                            SendListCompareResult.CaseDisparity d = (SendListCompareResult.CaseDisparity)adjustedConflicts[j];
                            // Run through the items in the collection
                            if (d.SerialNo == c[i].SerialNo)
                            {
                                adjustedConflicts.RemoveAt(j);
                            }
                        }
                    }
                    // Replace the case differences in the page send result object
                    sendResult.CaseDifferences = (SendListCompareResult.CaseDisparity[])adjustedConflicts.ToArray(typeof(SendListCompareResult.CaseDisparity));
                    // Place the result back in the viewstate
                    ViewState["SendResult"] = sendResult;
                    // Bind the object to the grid
                    BindObject();
                }
            }
            catch (CollectionErrorException ex)
            {
                DisplayErrors(PlaceHolder1, ex.Collection);
            }
            catch (Exception ex)
            {
                DisplayErrors(PlaceHolder1, ex.Message);
            }
        }
		/// <summary>
		/// Redirect to detail page
		/// </summary>
		private void listLink_Click(object sender, System.EventArgs e)
		{
			Response.Redirect(String.Format("shipping-list-detail.aspx?listNumber={0}", this.sendResult.ListName), false);		
		}
    }
}
