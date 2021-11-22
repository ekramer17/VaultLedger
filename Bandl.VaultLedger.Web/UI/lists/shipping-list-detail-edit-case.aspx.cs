using System;
using System.Collections;
using System.Web.UI.WebControls;
using System.Web.UI.HtmlControls;
using Bandl.Library.VaultLedger.BLL;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.Exceptions;
using Bandl.Library.VaultLedger.Collections;
using Bandl.Library.VaultLedger.Security;

namespace Bandl.VaultLedger.Web.UI
{
	/// <summary>
	/// Summary description for caseTest.
	/// </summary>
	public class shipping_list_detail_edit_case : BasePage
	{
        #region Private Fields
        private SendListCaseCollection lc;
        #endregion

        #region Public Properties
        public string CancelUrl {get {return (string)this.ViewState["CancelUrl"];}}
        public bool DisplayTabs {get {return (bool)this.ViewState["DisplayTabs"];}}
        #endregion

        protected System.Web.UI.WebControls.Label lblCaption;
        protected System.Web.UI.WebControls.PlaceHolder PlaceHolder1;
        protected System.Web.UI.WebControls.DropDownList ddlSelectAction;
        protected System.Web.UI.WebControls.Button btnGo;
        protected System.Web.UI.WebControls.DataGrid DataGrid1;
        protected System.Web.UI.WebControls.Button btnSave;
        protected System.Web.UI.WebControls.Button btnCancel;
        protected System.Web.UI.WebControls.TextBox txtReturnDate;
        protected System.Web.UI.HtmlControls.HtmlInputButton btnCancel2;
        protected System.Web.UI.WebControls.Label lblDesc;
        protected System.Web.UI.HtmlControls.HtmlGenericControl titleBar1;
        protected System.Web.UI.HtmlControls.HtmlGenericControl titleBar2;
        protected System.Web.UI.HtmlControls.HtmlInputButton btnOK;
    
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
            this.btnGo.Click += new System.EventHandler(this.btnGo_Click);
            this.btnSave.Click += new System.EventHandler(this.btnSave_Click);
            this.btnCancel.Click += new System.EventHandler(this.btnCancel_Click);
            this.btnOK.ServerClick += new System.EventHandler(this.btnOK_ServerClick);

        }
		#endregion
	
        /// <summary>
        /// Page initialization event handler (thrown by page master)
        /// </summary>
        protected override void Event_PageInit(object sender, System.EventArgs e)
        {
            this.helpId = 10;
            this.levelTwo = LevelTwoNav.Shipping;
            // Viewers and auditors shouldn't be able to access this page
            DoSecurity(Role.Operator, "default.aspx");
        }
        /// <summary>
        /// Page load event handler (thrown by page master)
        /// </summary>
        protected override void Event_PageLoad(object sender, System.EventArgs e)
        {
            // Click events for message box buttons
            this.SetControlAttr(this.btnOK, "onclick", "hideMsgBox('msgBoxReturnDate');");
            this.SetControlAttr(this.btnCancel2, "onclick", "hideMsgBox('msgBoxReturnDate');");

            if (Page.IsPostBack)
            {
                lc = (SendListCaseCollection)this.ViewState["lc"];
            }
            else
            {
                bool displayTabs = false;
                string cancelUrl = String.Empty;
                string listName = Request.QueryString["listNumber"];
                // Should only be able to get here by a server transfer from new-list-manual-scan-step-one.aspx or shipping-list-detail.aspx
                if (Context.Handler is new_list_manual_scan_step_one)
                {
                    cancelUrl = ((new_list_manual_scan_step_one)Context.Handler).CancelUrl;
                    displayTabs = ((new_list_manual_scan_step_one)Context.Handler).DisplayTabs;
                    lc = SendList.GetSendListCases(SendList.GetSendList(listName,false).Id);
                    // Title bar
                    this.titleBar2.Visible = true;
                    this.SetControlAttr(titleBar1, "class", "contentArea");
                    // Page title depends on displayTabs
                    if (displayTabs == true)
                    {
                        this.lblCaption.Text = "New Shipping List&nbsp;&nbsp;-&nbsp;&nbsp;Step 2";
                        this.lblDesc.Text = "Your shipping list has been created. In this step, you may edit the cases that appear on the list by marking cases as sealed or unsealed and by assigning return dates. When you are finished, click Save.";
                    }
                    else
                    {
                        lblCaption.Text = "Edit Shipping List&nbsp;&nbsp;-&nbsp;&nbsp;" + listName;
                        this.lblDesc.Text = "Edit the cases that appear on the list by marking cases as sealed or unsealed and by assigning return dates. When you are finished, click Save.";
                    }
                    // Insert into viewstate
                    this.ViewState["lc"] = lc;
                    this.ViewState["ListName"] = listName;
                    this.ViewState["DisplayTabs"] = displayTabs;
                    this.ViewState["CancelUrl"] = cancelUrl;
                }
                else if (Context.Handler is new_list_rfid_file)
                {
                    displayTabs = false;
                    cancelUrl = "shipping-list-detail.aspx?listNumber=" + listName;
                    // Get the send list cases
                    lc = SendList.GetSendListCases(SendList.GetSendList(listName,false).Id);
                    // Title bar
                    this.titleBar2.Visible = true;
                    this.SetControlAttr(titleBar1, "class", "contentArea");
                    // Caption and description
                    this.lblCaption.Text = "New Shipping List&nbsp;&nbsp;-&nbsp;&nbsp;Step 2";
                    this.lblDesc.Text = "Your shipping list has been created. In this step, you may edit the cases that appear on the list by marking cases as sealed or unsealed and by assigning return dates. When you are finished, click Save.";
                }
                else if (Context.Handler is shipping_list_detail)
                {
                    // Get the send list cases
                    lc = SendList.GetSendListCases(SendList.GetSendList(listName,false).Id);
                    // Title bar
                    this.titleBar2.Visible = false;
                    this.SetControlAttr(titleBar1, "class", "contentArea contentBorderTop");
                    // Caption and description
                    lblCaption.Text = "Edit Shipping List&nbsp;&nbsp;-&nbsp;&nbsp;" + listName;
                    this.lblDesc.Text = "Edit the cases that appear on the list by marking cases as sealed or unsealed and by assigning return dates. When you are finished, click Save.";
                    // Other variables
                    displayTabs = false;
                    listName = Request.QueryString["listNumber"];
                    cancelUrl = "shipping-list-detail.aspx?listNumber=" + listName;
                }
                else
                {
                    Response.Redirect("send-lists.aspx", false);
                }
                // Insert into viewstate
                this.ViewState["lc"] = lc;
                this.ViewState["ListName"] = listName;
                this.ViewState["DisplayTabs"] = displayTabs;
                this.ViewState["CancelUrl"] = cancelUrl;
                // Set checks to zero
                ArrayList checkThese = new ArrayList();
                for (int i = 0; i < lc.Count; i++) checkThese.Add(false);
                ViewState["checkThese"] = checkThese;
                // Bind the datagrid
                DataGrid1.DataSource = lc;
                DataGrid1.DataBind();
            }
        }
        /// <summary>
        /// Page prerender event handler (thrown by page master)
        /// </summary>
        protected override void Event_PagePreRender(object sender, System.EventArgs e)
        {
            bool b = true;
            // Check the datagrid items as necessary
            for (int i = 0; i < ((ArrayList)ViewState["checkThese"]).Count; i++)
            {
                ((HtmlInputCheckBox)DataGrid1.Items[i].Cells[0].Controls[1]).Checked = (bool)((ArrayList)ViewState["checkThese"])[i];
                if ((bool)((ArrayList)ViewState["checkThese"])[i] == false) b = false;
            }
            // If all checked, check the first box
            if (b) ClientScript.RegisterStartupScript(GetType(), "checkTop", "<script language=javascript>getObjectById('DataGrid1').getElementsByTagName('input')[0].checked = true</script>");
        }
        /// <summary>
        /// Event handler for the cancel button
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="e"></param>
        private void btnCancel_Click(object sender, System.EventArgs e)
        {
            try
            {
                // If we created a new list, delete it.
                if (lblCaption.Text.ToLower().IndexOf("new") == 0)
                {
                    SendListItemCollection c = new SendListItemCollection();
                    SendListDetails d = SendList.GetSendList((string)this.ViewState["ListName"], true);
                    // If list is a composite, we have to remove all items from cases
                    if (d.IsComposite)
                        foreach (SendListDetails cl in d.ChildLists)
                            foreach (SendListItemDetails i in cl.ListItems)
                                if (i.CaseName.Length != 0)
                                    c.Add(i);
                    // Remove from cases
                    if (c.Count != 0) SendList.RemoveFromCases(c);
                    // Delete the list
                    SendList.Delete(d);
                }
            }
            catch
            {
                ;
            }
            finally
            {
                Response.Redirect(this.CancelUrl, false);
            }
        }
        /// <summary>
        /// Event handler for the save button
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="e"></param>
        private void btnSave_Click(object sender, System.EventArgs e)
        {
            SendListCaseCollection c = new SendListCaseCollection();
            // If the case is modified, add it to the collection
            for (int i = 0; i < DataGrid1.Items.Count; i++)
                if (lc[i].ObjState == ObjectStates.Modified) c.Add(lc[i]);
            // Update the cases			
            try
            {
                // Update the cases
                if (c.Count != 0) SendList.UpdateCases(ref c);
                // Go to the detail page
                Server.Transfer(String.Format("shipping-list-detail.aspx?listNumber={0}",(string)this.ViewState["ListName"]));
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
        /// Event handler for the 'Go' button
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="e"></param>
        private void btnGo_Click(object sender, System.EventArgs e)
        {
            // Remeber the checked items
            foreach(DataGridItem i in DataGrid1.Items)
                ((ArrayList)ViewState["checkThese"])[i.ItemIndex] = ((HtmlInputCheckBox)i.Cells[0].Controls[1]).Checked;
            // Carry out the correct action
            if (this.CollectCheckedItems(this.DataGrid1).Length != 0)
            {
                switch (this.ddlSelectAction.SelectedValue)
                {
                    case "Seal":
                        this.SealedStatus(true);
                        break;
                    case "Unseal":
                        this.SealedStatus(false);
                        break;
                    case "ReturnDate":
                        this.ShowMessageBox("msgBoxReturnDate");
                        break;
                }
            }
        }
        /// <summary>
        /// Sets the sealed or unsealed status of each checked item
        /// </summary>
        /// <param name="seal"></param>
        private void SealedStatus(bool seal)
        {
            // Set the attributes
            foreach (DataGridItem i in CollectCheckedItems(DataGrid1))
            {
                if (lc[i.ItemIndex].Sealed != seal) lc[i.ItemIndex].Sealed = seal;
                if (!seal && lc[i.ItemIndex].ReturnDate.Length != 0) lc[i.ItemIndex].ReturnDate = String.Empty;
            }
            // Bind to the datagrid
            DataGrid1.DataSource = lc;
            DataGrid1.DataBind();
        }
        /// <summary>
        /// Event handler for the 'OK' button
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="e"></param>
        private void btnOK_ServerClick(object sender, System.EventArgs e)
        {
            if (AssignReturnDate() == false)
                DisplayErrors(PlaceHolder1, "No sealed cases selected.  Return dates may only be assigned to sealed cases.");
        }
        /// <summary>
        /// Assigns the return date
        /// </summary>
        /// <param name="seal"></param>
        private bool AssignReturnDate()
        {
            bool b = false;
            // Get the return date from the text box
            string r = DisplayDate(txtReturnDate.Text,false,false);
            // Assign it to any sealed cases that have been checked
            foreach (DataGridItem i in CollectCheckedItems(DataGrid1))
            {
                if (lc[i.ItemIndex].Sealed)
                {
                    lc[i.ItemIndex].ReturnDate = r;
                    b = true;
                }
            }
            // Bind to the datagrid
            DataGrid1.DataSource = lc;
            DataGrid1.DataBind();
            // Return
            return b;
        }
    }
}
