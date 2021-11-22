using System;
using System.Text;
using System.Data;
using System.Threading;
using System.Collections;
using System.Collections.Generic;
using System.Web.UI.WebControls;
using System.Web.UI.HtmlControls;
using Bandl.Library.VaultLedger.Exceptions;
using Bandl.Library.VaultLedger.Collections;
using Bandl.Library.VaultLedger.Security;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.BLL;

namespace Bandl.VaultLedger.Web.UI
{
	/// <summary>
	/// Summary description for tms_lists_receiving.
	/// </summary>
	public class tms_lists_receiving : BasePage
	{
		protected System.Web.UI.WebControls.LinkButton printLink;
		protected System.Web.UI.WebControls.PlaceHolder PlaceHolder1;
		protected System.Web.UI.WebControls.DropDownList ddlSelectAction;
		protected System.Web.UI.WebControls.Button btnGo;
		protected System.Web.UI.WebControls.DataGrid DataGrid1;
		protected System.Web.UI.WebControls.LinkButton tabOne;
        protected System.Web.UI.WebControls.HyperLink tabTwo;
        protected System.Web.UI.WebControls.Button btnYes;
		protected System.Web.UI.WebControls.Button btnNo;
        protected System.Web.UI.WebControls.Button btnExport;
        protected System.Web.UI.HtmlControls.HtmlInputButton btnNoExport;
        protected System.Web.UI.HtmlControls.HtmlGenericControl excludedMessage;

		private SendListCollection sendLists = null;
		private ReceiveListCollection receiveLists = null;
		public SendListCollection SendLists { get{return sendLists;} }
		public ReceiveListCollection ReceiveLists { get{return receiveLists;} }

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
            this.tabOne.Click += new System.EventHandler(this.tabOne_Click);
            this.btnGo.Click += new System.EventHandler(this.btnGo_Click);
            this.DataGrid1.PreRender += new System.EventHandler(this.DataGrid1_PreRender);
            this.btnYes.Click += new System.EventHandler(this.btnYes_Click);
            this.btnExport.Click += new System.EventHandler(this.btnExport_Click);
        }
		#endregion

		/// <summary>
		/// Page initialization event handler (thrown by page master)
		/// </summary>
		protected override void Event_PageInit(object sender, System.EventArgs e)
		{
			this.pageTitle = "TMS Receiving Lists";
			this.levelTwo = LevelTwoNav.None;
			this.helpId = 11;
		}
		/// <summary>
		/// Page load event handler (thrown by page master)
		/// </summary>
		protected override void Event_PageLoad(object sender, System.EventArgs e)
		{
			// Click events for message box buttons
            this.SetControlAttr(this.btnExport, "onclick", "hideMsgBox('msgBoxExcluded');");
            this.SetControlAttr(this.btnNoExport, "onclick", "hideMsgBox('msgBoxExcluded');");
            this.SetControlAttr(this.btnYes, "onclick", "hideMsgBox('msgBoxDelete');");
			this.SetControlAttr(this.btnNo,  "onclick", "hideMsgBox('msgBoxDelete');");

			if (Page.IsPostBack)
			{
				sendLists = (SendListCollection)this.ViewState["SendLists"];
				receiveLists = (ReceiveListCollection)this.ViewState["ReceiveLists"];
			}
			else
			{
                List<String> excludedSerials = null;
                
                if (Context.Handler is new_list_tms_file)
				{
					new_list_tms_file lastPage = (new_list_tms_file)Context.Handler;
					sendLists = lastPage.SendLists != null ? (SendListCollection)lastPage.SendLists : new SendListCollection();
					receiveLists = lastPage.ReceiveLists != null ? (ReceiveListCollection)lastPage.ReceiveLists : new ReceiveListCollection();
                    excludedSerials = lastPage.ExcludedSerials;
                }
				else if (Context.Handler is new_receive_list_tms_file)
				{
					new_receive_list_tms_file lastPage = (new_receive_list_tms_file)Context.Handler;
					sendLists = lastPage.SendLists != null ? (SendListCollection)lastPage.SendLists : new SendListCollection();
					receiveLists = lastPage.ReceiveLists != null ? (ReceiveListCollection)lastPage.ReceiveLists : new ReceiveListCollection();
                    excludedSerials = lastPage.ExcludedSerials;
                }
				else if (Context.Handler is tms_lists_shipping)
				{
					tms_lists_shipping lastPage = (tms_lists_shipping)Context.Handler;
					sendLists = lastPage.SendLists != null ? (SendListCollection)lastPage.SendLists : new SendListCollection();
					receiveLists = lastPage.ReceiveLists != null ? (ReceiveListCollection)lastPage.ReceiveLists : new ReceiveListCollection();
				}
				else
				{
					Server.Transfer("todays-receiving-list.aspx");
				}
                // Place objects in the viewstate
                this.ViewState["SendLists"] = sendLists;
                this.ViewState["ReceiveLists"] = receiveLists;
                // Bind the lists to the grid
				this.BindListCollection();
                // Excluded serial numbers?
                if (excludedSerials != null && excludedSerials.Count != 0)
                {
                    if (excludedSerials.Count == 1)
                    {
                        btnNoExport.Value = "OK";
                        btnExport.Visible = false;
                        excludedMessage.InnerHtml = "There was one unrecognized serial number in the given TMS report:<br /><br/>" + excludedSerials[0];
                    }
                    else
                    {
                        this.ViewState["ExcludedSerials"] = excludedSerials;
                        excludedMessage.InnerHtml = String.Format("There were {0} unrecognized serial numbers in the given TMS report.  Would you like to view a listing?", excludedSerials.Count);
                    }

                    this.ShowMessageBox("msgBoxExcluded");
                }
            }
		}
		/// <summary>
		/// Page prerender event handler (thrown by page master)
		/// </summary>
		protected override void Event_PagePreRender(object sender, System.EventArgs e)
		{
            this.CreateDropdownItems();
			// Restrict roles other than administrators and operators from seeing
			// top controls or checkboxes in the datagrid.  For administrators
			// and operators, render check box invisible for any cleared list.
			switch (CustomPermission.CurrentOperatorRole())
			{
				case Role.Administrator:
				case Role.Operator:
					break;  // All functions enabled
				case Role.Auditor:
				case Role.Viewer:
				default:
					this.DataGrid1.Columns[0].Visible = false;
					break;
			}
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
				this.DataGrid1.Items[0].Cells[1].Text = "No receive lists created";
			}
        }
        /// <summary>
        /// Creates list items in the select action dropdown as needed
        /// </summary>
        private void CreateDropdownItems()
        {
            ListItem lix = this.ddlSelectAction.Items.FindByValue("Xmit");
            ListItem liv = this.ddlSelectAction.Items.FindByValue("Verify");
            bool xe = ReceiveList.StatusEligible(receiveLists, RLStatus.Xmitted);
            bool ve = ReceiveList.StatusEligible(receiveLists, RLStatus.FullyVerifiedI | RLStatus.FullyVerifiedII);
            // If not allowing one-click verification, set ve to false
            if (Preference.GetPreference(PreferenceKeys.AllowOneClickVerify).Value == "NO") ve = false;
            // Add and delete as necessary
            if (xe && lix == null)
                ddlSelectAction.Items.Add(new ListItem("Transmit Selected", "Xmit"));
            else if (!xe && lix != null)
                ddlSelectAction.Items.Remove(lix);
            if (ve && liv == null)
                ddlSelectAction.Items.Add(new ListItem("Verify Selected", "Verify"));
            else if (!ve && liv != null)
                ddlSelectAction.Items.Remove(liv);
        }
        /// <summary>
		/// Binds list collection to grid
		/// </summary>
		private void BindListCollection()
		{
            // Place collection in viewstate
            this.ViewState["ReceiveLists"] = receiveLists;
            // Bind data to grid
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
					case "Extract":
                        this.DoAction(-2);
                        break; 
					case "Xmit":
						this.DoAction((int)RLStatus.Xmitted);
						break;  
                    case "Verify":
                        this.DoAction((int)RLStatus.FullyVerifiedI);
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
		/// Transmits selected lists
		/// </summary>
		private void DoAction(int actionNo)
		{
            bool oneSuccess = false;
            ReceiveListDetails rl = null;
            ArrayList checkThese = new ArrayList();
            DataGridItem[] d = this.CollectCheckedItems(this.DataGrid1);
            // Dissolve the lists
            for (int i = d.Length - 1; i >= 0; i--)
            {
                try
                {
                    rl = receiveLists[d[i].ItemIndex];
                    // Do action
                    switch (actionNo)
                    {
                        case (int)RLStatus.Xmitted:
                            ReceiveList.Transmit(rl);
                            // Replace the list in the collection
                            receiveLists[d[i].ItemIndex] = ReceiveList.GetReceiveList(rl.Id, false);
                            break;
                        case (int)RLStatus.FullyVerifiedI:
                            ReceiveList.Verify(rl);
                            // Replace the list in the collection
                            receiveLists[d[i].ItemIndex] = ReceiveList.GetReceiveList(rl.Id, false);
                            break;
                        case -1:
                            ReceiveList.Delete(rl);
                            receiveLists.RemoveAt(d[i].ItemIndex);
                            break;
                        case -2:
                            ReceiveList.Dissolve(rl);
                            receiveLists.RemoveAt(d[i].ItemIndex);
                            // Add the children to the page collection
                            foreach (ReceiveListDetails cl in rl.ChildLists)
                                receiveLists.Add(ReceiveList.GetReceiveList(cl.Id, false));
                            // Alphabetize the lists
                            receiveLists.Sort(new ObjectComparer("Name"));
                            break;
                    }
                    // Record the fact that we had at least one success
                    oneSuccess = true;
                }
                catch (CollectionErrorException ex)
                {
                    this.DisplayErrors(this.PlaceHolder1, ex.Collection);
                    checkThese.Add(receiveLists[d[i].ItemIndex].Name);
                }
                catch (Exception ex)
                {
                    this.DisplayErrors(this.PlaceHolder1, ex.Message);
                    checkThese.Add(receiveLists[d[i].ItemIndex].Name);
                }
            }
            // If nothing succeeded, just return
            if (oneSuccess == false) return;
            // Bind the list collection
            this.BindListCollection();
            // Check any grid items with errors
            this.CheckGridItems(checkThese);
		}
		/// <summary>
		/// Event handler for confirmation button
		/// </summary>
		private void btnYes_Click(object sender, System.EventArgs e)
		{
			this.DoAction(-1);
		}
        /// <summary>
        /// Event handler for confirmation button
        /// </summary>
        private void btnExport_Click(object sender, System.EventArgs e)
        {
            List<String> s1 = (List<String>)this.ViewState["ExcludedSerials"];
            this.ViewState.Remove("ExcludedSerials");

            StringBuilder b1 = new StringBuilder();
            b1.AppendFormat("The following {0} serial numbers were unrecognized:", s1.Count);
            b1.AppendLine();
            b1.AppendLine();
            foreach (String s in s1)
                b1.AppendLine(s);

            DoExport("unrecognized.serial.numbers.txt", b1.ToString());
        }
        /// <summary>
		/// Transfers to the shipping TMS list page
		/// </summary>
		private void tabOne_Click(object sender, System.EventArgs e)
		{
			Server.Transfer("tms-lists-shipping.aspx");
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
        /// Print function to be called asynchronously
        /// </summary>
        private void printLink_Click(object sender, System.EventArgs e)
        {
            Session[CacheKeys.PrintSource] = PrintSources.ReceiveListsPage;
            Session[CacheKeys.PrintObjects] = new object[] {this.receiveLists};
            ClientScript.RegisterStartupScript(GetType(), "printWindow", "<script>openBrowser('../waitPage.aspx?redirectPage=print.aspx&x=" + Guid.NewGuid().ToString("N") + "')</script>");
        }
    }
}
