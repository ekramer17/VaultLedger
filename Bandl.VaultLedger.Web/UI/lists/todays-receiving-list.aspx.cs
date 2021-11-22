using System;
using System.Data;
using System.Collections;
using System.Web.UI.WebControls;
using System.Web.UI.HtmlControls;
using System.Collections.Specialized;
using Bandl.Library.VaultLedger.BLL;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.Collections;
using Bandl.Library.VaultLedger.Exceptions;
using Bandl.Library.VaultLedger.Security;

namespace Bandl.VaultLedger.Web.UI
{
	/// <summary>
	/// Summary description for todays_receiving_list.
	/// </summary>
	public class todays_receiving_list : BasePage
	{
        private ReceiveListCollection receiveLists;
		protected System.Web.UI.WebControls.PlaceHolder PlaceHolder1;
		protected System.Web.UI.WebControls.DropDownList ddlSelectAction;
		protected System.Web.UI.WebControls.Button btnGo;
		protected System.Web.UI.WebControls.Button btnYes;
		protected System.Web.UI.WebControls.Button btnNo;
        protected System.Web.UI.WebControls.Button btnNew;
        protected System.Web.UI.WebControls.LinkButton printLink;
		protected System.Web.UI.WebControls.DataGrid DataGrid1;
	
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
            this.btnNew.Click += new System.EventHandler(this.btnNew_Click);
            this.btnGo.Click += new System.EventHandler(this.btnGo_Click);
            this.btnYes.Click += new System.EventHandler(this.btnYes_Click);
            this.DataGrid1.PreRender += new EventHandler(DataGrid1_PreRender);
            this.printLink.Click += new System.EventHandler(this.printLink_Click);
        }
        #endregion

        /// <summary>
        /// Page initialization event handler (thrown by page master)
        /// </summary>
        protected override void Event_PageInit(object sender, System.EventArgs e)
        {
            this.pageTitle = "Receiving Lists";
            this.levelTwo = LevelTwoNav.Todays;
            this.helpId = 8;
        }
        /// <summary>
        /// Page load event handler (thrown by page master)
        /// </summary>
        protected override void Event_PageLoad(object sender, System.EventArgs e)
        {
            // Click events for message box buttons
            this.SetControlAttr(btnYes, "onclick", "hideMsgBox('msgBoxDelete');");
            this.SetControlAttr(btnNo,  "onclick", "hideMsgBox('msgBoxDelete');");
            // If this isn't a postback, fetch the lists
            if (!Page.IsPostBack)
                this.ObtainLists();
            else
                receiveLists = (ReceiveListCollection)this.ViewState["Lists"];
            // Update the tab page default
            if (!Page.IsPostBack)
                TabPageDefault.Update(TabPageDefaults.TodaysList, Context.Items[CacheKeys.Login], 2);
        }
        /// <summary>
        /// Page initialization event handler (thrown by page master)
        /// </summary>
        protected override void Event_PagePreRender(object sender, System.EventArgs e)
        {
            CreateDropdownItems();
            // Restrict roles other than administrators and operators from seeing
            // top controls or checkboxes in the datagrid.  For administrators
            // and operators, render check box invisible for any cleared list.
            switch (CustomPermission.CurrentOperatorRole())
            {
                case Role.Administrator:
                case Role.Operator:
                    break;
				case Role.VaultOps:
					this.btnNew.Visible = false;
					break;
                default:
                    this.btnNew.Visible = false;
                    this.DataGrid1.Columns[0].Visible = false;
                    break;
            }
        }
        /// <summary>
        /// Creates list items in the select action dropdown as needed
        /// </summary>
        private void CreateDropdownItems()
        {
            ListItem lix = this.ddlSelectAction.Items.FindByValue("Xmit");
            ListItem liv = this.ddlSelectAction.Items.FindByValue("Verify");
            ListItem lit = this.ddlSelectAction.Items.FindByValue("Transit");
            ListItem lia = this.ddlSelectAction.Items.FindByValue("Arrive");
            bool xe = ReceiveList.StatusEligible(receiveLists, RLStatus.Xmitted);
            bool ve = ReceiveList.StatusEligible(receiveLists, RLStatus.FullyVerifiedI | RLStatus.FullyVerifiedII);
            bool xt = ReceiveList.StatusEligible(receiveLists, RLStatus.Transit);
            bool xa = ReceiveList.StatusEligible(receiveLists, RLStatus.Arrived);

            // If not allowing one-click verification, set ve to false
            if (Preference.GetPreference(PreferenceKeys.AllowOneClickVerify).Value == "NO") ve = false;

			// VaultOps can only have the 'Mark in Transit' option
			if (CustomPermission.CurrentOperatorRole() == Role.VaultOps)
			{
				ListItem lid = this.ddlSelectAction.Items.FindByValue("Delete");
				ListItem lim = this.ddlSelectAction.Items.FindByValue("Merge");
				ListItem lie = this.ddlSelectAction.Items.FindByValue("Extract");
				ddlSelectAction.Items.Remove(lid);
				ddlSelectAction.Items.Remove(lim);
				ddlSelectAction.Items.Remove(lie);
				ddlSelectAction.Items.Remove(lix);
				ddlSelectAction.Items.Remove(lia);
				ddlSelectAction.Items.Remove(liv);

				if (xt && lit == null)
					ddlSelectAction.Items.Add(new ListItem("Mark 'In Transit'", "Transit"));
				else if (!xt && lit != null)
					ddlSelectAction.Items.Remove(lit);

				return;
			}   

			// Add and delete as necessary
            if (xe && lix == null)
                ddlSelectAction.Items.Add(new ListItem("Transmit Selected", "Xmit"));
            else if (!xe && lix != null)
                ddlSelectAction.Items.Remove(lix);
            if (ve && liv == null)
                ddlSelectAction.Items.Add(new ListItem("Verify Selected", "Verify"));
            else if (!ve && liv != null)
                ddlSelectAction.Items.Remove(liv);
            if (xt && lit == null)
                ddlSelectAction.Items.Add(new ListItem("Mark 'In Transit'", "Transit"));
            else if (!xt && lit != null)
                ddlSelectAction.Items.Remove(lit);
            if (xa && lia == null)
                ddlSelectAction.Items.Add(new ListItem("Mark 'Arrived'", "Arrive"));
            else if (!xa && lia != null)
                ddlSelectAction.Items.Remove(lia);
        }
        /// <summary>
        /// Prerender event handler for datagrid
        /// </summary>
        private void DataGrid1_PreRender(object sender, EventArgs e)
        {
            // Hide the checkbox for all processed lists
            for (int i = 0; i < receiveLists.Count; i++)
                if (receiveLists[i].Status == RLStatus.Processed)
                    this.DataGrid1.Items[i].Cells[0].Controls[1].Visible = false;
            // If we have no lists for the datagrid, then create an empty table
            // with one row so that we may display a message to the user.
            if (receiveLists.Count == 0)
            {
                DataTable dataTable = new DataTable();
                dataTable.Columns.Add("Id", typeof(int));
                dataTable.Columns.Add("Name", typeof(string));
                dataTable.Columns.Add("CreateDate", typeof(string));
                dataTable.Columns.Add("Status", typeof(string));
                dataTable.Columns.Add("Account", typeof(string));
                dataTable.Rows.Add(new object[] {0, "", "", "", ""});
                // Bind the datagrid to the empty table
                this.DataGrid1.DataSource = dataTable;
                this.DataGrid1.DataBind();
                // Create the text in the first column and render the
                // checkbox column invisible
                this.DataGrid1.Columns[0].Visible = false;
                this.DataGrid1.Items[0].Cells[1].Text = "None created today";
            }
        }
        /// <summary>
        /// Fetches the lists and binds them to the datagrid
        /// </summary>
        private void ObtainLists()
        {
			// VaultOps can only view those lists eligible for In Transit or Verified Stage I
			if (CustomPermission.CurrentOperatorRole() == Role.VaultOps)
				receiveLists = ReceiveList.GetListsByEligibleStatusAndDate((RLStatus.Transit | RLStatus.FullyVerifiedI),Time.UtcToday);
			else  // Get lists regardless of status
				receiveLists = ReceiveList.GetListsByDate(Time.UtcToday);

            this.ViewState["Lists"] = receiveLists;
            // Bind the datasource
            this.DataGrid1.DataSource = receiveLists;
            this.DataGrid1.DataBind();
        }
        /// <summary>
        /// Event handler for the Go button
        /// </summary>
        private void btnGo_Click(object sender, System.EventArgs e)
        {
            if (this.CollectCheckedItems(this.DataGrid1).Length != 0)
            {
                switch (this.ddlSelectAction.SelectedValue)
                {
                    case "Merge":
                        this.MergeLists();
                        break;
                    case "Extract":
                        this.DoAction(-2);
                        break;
                    case "Verify":
                        this.DoAction((int)RLStatus.FullyVerifiedI);
                        break;
                    case "Xmit":
                        this.DoAction((int)RLStatus.Xmitted);
                        break;
                    case "Transit":
                        this.DoAction((int)RLStatus.Transit);
                        break;
                    case "Arrive":
                        this.DoAction((int)RLStatus.Arrived);
                        break;
                    case "Delete":
                        this.ShowMessageBox("msgBoxDelete");
                        break;
                    default:
                        break;
                }
            }
        }
        /// <summary>
        /// Merges lists checked in the datagrid
        /// </summary>
        private void MergeLists()
        {
            ReceiveListCollection mergeThese = new ReceiveListCollection();
            // Add the checked send lists to the merge collection
            foreach (DataGridItem d in this.CollectCheckedItems(this.DataGrid1))
                mergeThese.Add(receiveLists[d.ItemIndex]);
            // If we have one list, display error
            if (mergeThese.Count == 1)
            {
                this.DisplayErrors(this.PlaceHolder1, "More than one list must be selected for merging.");
            }
            else
            {
                // Merge the lists and reobtain data
                try
                {
                    ReceiveList.Merge(mergeThese);
                    this.ObtainLists();
                }
                catch (Exception ex)
                {
                    this.DisplayErrors(this.PlaceHolder1, ex.Message);
                }
            }
        }
        /// <summary>
        /// Performs action on selected lists
        /// </summary>
        private void DoAction(int actionNo)
        {
            bool oneSuccess = false;
            ArrayList checkThese = new ArrayList();
            // Dissolve the lists
            foreach (DataGridItem d in this.CollectCheckedItems(this.DataGrid1))
            {
                try
                {
                    switch (actionNo)
                    {
                        case (int)RLStatus.FullyVerifiedI:
                            ReceiveList.Verify(receiveLists[d.ItemIndex]);
                            break;
                        case (int)RLStatus.Xmitted:
                            ReceiveList.Transmit(receiveLists[d.ItemIndex]);
                            break;
                        case (int)RLStatus.Arrived:
                            ReceiveList.MarkArrived(receiveLists[d.ItemIndex]);
                            break;
                        case (int)RLStatus.Transit:
                            ReceiveList.MarkTransit(receiveLists[d.ItemIndex]);
                            break;
                        case -1:
                            ReceiveList.Delete(receiveLists[d.ItemIndex]);
                            break;
                        case -2:
                            ReceiveList.Dissolve(receiveLists[d.ItemIndex]);
                            break;
                    }
                    // Record the fact that we had at least one success
                    oneSuccess = true;
                }
                catch (CollectionErrorException ex)
                {
                    this.DisplayErrors(this.PlaceHolder1, ex.Collection);
                    checkThese.Add(receiveLists[d.ItemIndex].Name);
                }
                catch (Exception ex)
                {
                    this.DisplayErrors(this.PlaceHolder1, ex.Message);
                    checkThese.Add(receiveLists[d.ItemIndex].Name);
                }
            }
            // If nothing succeeded, just return
            if (oneSuccess == false) return;
            // Reobtain the lists
            this.ObtainLists();
            // Check any grid items with errors
            this.CheckGridItems(checkThese);
        }
        /// <summary>
        /// Checks items in the datagrid
        /// </summary>
        private void CheckGridItems(ArrayList checkThese)
        {
            int i = 0;
            // Look for each list name; if found, check it
            foreach (string listName in checkThese)
                if ((i = receiveLists.IndexOf(listName)) != -1)
                    ((HtmlInputCheckBox)this.DataGrid1.Items[i].Cells[0].Controls[1]).Checked = true;
        }
        /// <summary>
        /// Event handler for the Delete Confirmation button
        /// </summary>
        private void btnYes_Click(object sender, System.EventArgs e)
        {
            DoAction(-1);
        }
        /// <summary>
        /// Event handler for the New List button
        /// </summary>
        private void btnNew_Click(object sender, System.EventArgs e)
        {
            switch (TabPageDefault.GetDefault(TabPageDefaults.NewReceiveList, Context.Items[CacheKeys.Login]))
            {
                case 2:
                    Server.Transfer("new-receive-list-tms-file.aspx");
                    break;
                default:
                    Server.Transfer("new-receive-list-manual-scan-step-one.aspx");
                    break;
            }
        }
        /// <summary>
        /// Print function to be called asynchronously
        /// </summary>
        private void printLink_Click(object sender, System.EventArgs e)
        {
            Session[CacheKeys.PrintSource] = PrintSources.ReceiveListsPage;
            Session[CacheKeys.PrintObjects] = new object[] {(ReceiveListCollection)this.ViewState["Lists"]};
            ClientScript.RegisterStartupScript(GetType(), "printWindow", "<script>openBrowser('../waitPage.aspx?redirectPage=print.aspx&x=" + Guid.NewGuid().ToString("N") + "')</script>");
        }
    }
}
