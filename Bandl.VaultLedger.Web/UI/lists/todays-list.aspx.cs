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
	/// Summary description for todays_list_template.
	/// </summary>
	public class todays_list : BasePage
	{
        private SendListCollection sendLists;
		protected System.Web.UI.WebControls.DropDownList ddlSelectAction;
		protected System.Web.UI.WebControls.Button btnGo;
		protected System.Web.UI.WebControls.DataGrid DataGrid1;
		protected System.Web.UI.WebControls.PlaceHolder PlaceHolder1;		
		protected System.Web.UI.WebControls.Button btnYes;
		protected System.Web.UI.WebControls.Button btnNo;
        protected System.Web.UI.WebControls.LinkButton printLink;
        protected System.Web.UI.WebControls.Button btnNew;

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
            this.printLink.Click += new System.EventHandler(this.printLink_Click);
            this.btnNew.Click += new System.EventHandler(this.btnNew_Click);
            this.btnGo.Click += new System.EventHandler(this.btnGo_Click);
            this.btnYes.Click += new System.EventHandler(this.btnYes_Click);
            this.DataGrid1.PreRender += new EventHandler(DataGrid1_PreRender);
        }
        #endregion

        /// <summary>
        /// Page initialization event handler (thrown by page master)
        /// </summary>
        protected override void Event_PageInit(object sender, System.EventArgs e)
        {
            this.pageTitle = "Shipping Lists";
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
            this.SetControlAttr(btnNo, "onclick", "hideMsgBox('msgBoxDelete');");
            // If this isn't a postback, fetch the lists
            if (!Page.IsPostBack)
                this.ObtainLists();
            else
                sendLists = (SendListCollection)this.ViewState["Lists"];
            // Update the tab page default
            if (!Page.IsPostBack)
                TabPageDefault.Update(TabPageDefaults.TodaysList, Context.Items[CacheKeys.Login], 1);
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
			ListItem lia = this.ddlSelectAction.Items.FindByValue("Arrive");
            ListItem lix = this.ddlSelectAction.Items.FindByValue("Xmit");
			ListItem liv = this.ddlSelectAction.Items.FindByValue("Verify");
			ListItem lit = this.ddlSelectAction.Items.FindByValue("Transit");
            bool xe = SendList.StatusEligible(sendLists, SLStatus.Xmitted);
            bool ve = SendList.StatusEligible(sendLists, SLStatus.FullyVerifiedI | SLStatus.FullyVerifiedII);
            bool xt = SendList.StatusEligible(sendLists, SLStatus.Transit);
            bool xa = SendList.StatusEligible(sendLists, SLStatus.Arrived);
            // If not allowing one-click verification, set ve to false
            if (Preference.GetPreference(PreferenceKeys.AllowOneClickVerify).Value == "NO") ve = false;

			// VaultOps can only have the 'Mark as Arrived' option
			if (CustomPermission.CurrentOperatorRole() == Role.VaultOps)
			{
				ListItem lid = this.ddlSelectAction.Items.FindByValue("Delete");
				ListItem lim = this.ddlSelectAction.Items.FindByValue("Merge");
				ListItem lie = this.ddlSelectAction.Items.FindByValue("Extract");
				ddlSelectAction.Items.Remove(lid);
				ddlSelectAction.Items.Remove(lim);
				ddlSelectAction.Items.Remove(lie);
				ddlSelectAction.Items.Remove(lix);
				ddlSelectAction.Items.Remove(liv);
				ddlSelectAction.Items.Remove(lit);

				if (xa && lia == null)
					ddlSelectAction.Items.Add(new ListItem("Mark 'Arrived'", "Arrive"));
				else if (!xa && lia != null)
					ddlSelectAction.Items.Remove(lia);

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
            for (int i = 0; i < sendLists.Count; i++)
                if (sendLists[i].Status == SLStatus.Processed)
                    this.DataGrid1.Items[i].Cells[0].Controls[1].Visible = false;
            // If we have no lists for the datagrid, then create an empty table
            // with one row so that we may display a message to the user.
            if (sendLists.Count == 0)
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
			// VaultOps can only view those lists eligible for Arrived or Verified Stage II
			if (CustomPermission.CurrentOperatorRole() == Role.VaultOps)
				sendLists = SendList.GetListsByEligibleStatusAndDate((SLStatus.Arrived | SLStatus.FullyVerifiedII),Time.UtcToday);
			else  // Get lists regardless of status
				sendLists = SendList.GetListsByDate(Time.UtcToday);
			
            this.ViewState["Lists"] = sendLists;
            // Bind the datagrid
            this.DataGrid1.DataSource = sendLists;
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
                        this.DoAction((int)SLStatus.FullyVerifiedI);
                        break;
                    case "Xmit":
                        this.DoAction((int)SLStatus.Xmitted);
                        break;
                    case "Transit":
                        this.DoAction((int)SLStatus.Transit);
                        break;
                    case "Arrive":
                        this.DoAction((int)SLStatus.Arrived);
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
            SendListCollection mergeThese = new SendListCollection();
            // Add the checked send lists to the merge collection
            foreach (DataGridItem d in this.CollectCheckedItems(this.DataGrid1))
                mergeThese.Add(sendLists[d.ItemIndex]);
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
                    SendList.Merge(mergeThese);
                    this.ObtainLists();
                }
                catch (Exception ex)
                {
                    this.DisplayErrors(this.PlaceHolder1, ex.Message);
                }
            }
        }
        /// <summary>
        /// Marks lists as in transit
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
                        case (int)SLStatus.FullyVerifiedI:
                            SendList.Verify(sendLists[d.ItemIndex]);
                            break;
                        case (int)SLStatus.Xmitted:
                            SendList.Transmit(sendLists[d.ItemIndex]);
                            break;
                        case (int)SLStatus.Arrived:
                            SendList.MarkArrived(sendLists[d.ItemIndex]);
                            break;
                        case (int)SLStatus.Transit:
                            SendList.MarkTransit(sendLists[d.ItemIndex]);
                            break;
                        case -1:
                            SendList.Delete(sendLists[d.ItemIndex]);
                            break;
                        case -2:
                            SendList.Dissolve(sendLists[d.ItemIndex]);
                            break;
                    }
                    // Record the fact that we had at least one success
                    oneSuccess = true;
                }
                catch (CollectionErrorException ex)
                {
                    this.DisplayErrors(this.PlaceHolder1, ex.Collection);
                    checkThese.Add(sendLists[d.ItemIndex].Name);
                }
                catch (Exception ex)
                {
                    this.DisplayErrors(this.PlaceHolder1, ex.Message);
                    checkThese.Add(sendLists[d.ItemIndex].Name);
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
                if ((i = sendLists.IndexOf(listName)) != -1)
                    ((HtmlInputCheckBox)this.DataGrid1.Items[i].Cells[0].Controls[1]).Checked = true;
        }
        /// <summary>
        /// Event handler for the Delete Confirmation button
        /// </summary>
        private void btnYes_Click(object sender, System.EventArgs e)
        {
            this.DoAction(-1);
        }
        /// <summary>
        /// Event handler for the New List button
        /// </summary>
        private void btnNew_Click(object sender, System.EventArgs e)
        {
            switch (TabPageDefault.GetDefault(TabPageDefaults.NewSendList, Context.Items[CacheKeys.Login]))
            {
                case 1:
                    Server.Transfer("new-list-manual-scan-step-one.aspx");
                    break;
                case 2:
                    Server.Transfer("new-list-batch-file-step-one.aspx");
                    break;
                case 3:
                    Server.Transfer("new-list-tms-file.aspx");
                    break;
                case 4:
                    Server.Transfer(ProductLicense.CheckLicense(LicenseTypes.RFID) ? "new-list-rfid-file.aspx" : "new-list-manual-scan-step-one.aspx");
                    break;
            }
        }
        /// <summary>
        /// Print function to be called asynchronously
        /// </summary>
        private void printLink_Click(object sender, System.EventArgs e)
        {
            Session[CacheKeys.PrintSource] = PrintSources.SendListsPage;
            Session[CacheKeys.PrintObjects] = new object[] {(SendListCollection)this.ViewState["Lists"]};
            ClientScript.RegisterStartupScript(GetType(), "printWindow", "<script>openBrowser('../waitPage.aspx?redirectPage=print.aspx&x=" + Guid.NewGuid().ToString("N") + "')</script>");
        }
    }
}
