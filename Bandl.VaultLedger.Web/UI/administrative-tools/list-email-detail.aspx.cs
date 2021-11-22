using System;
using System.Collections;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Web;
using System.Web.SessionState;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Web.UI.HtmlControls;
using Bandl.Library.VaultLedger.BLL;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.Collections;
using Bandl.Library.VaultLedger.Security;
using Bandl.Library.VaultLedger.Exceptions;

namespace Bandl.VaultLedger.Web.UI
{
	/// <summary>
	/// Summary description for list_email_detail.
	/// </summary>
	public class list_email_detail : BasePage
	{
        private int listStatus = -1;
        private string mode = "status"; // Status or alert
        private ListTypes listType = ListTypes.Send;
        private EmailGroupCollection emailGroups = null;
        private EmailGroupCollection alertGroups = null;
        private EmailGroupCollection statusGroups = null;

        protected System.Web.UI.WebControls.PlaceHolder PlaceHolder1;
        protected System.Web.UI.WebControls.Label lblTitle;
        protected System.Web.UI.WebControls.Label lblDesc;
        protected System.Web.UI.WebControls.Button btnSave;
        protected System.Web.UI.WebControls.DataGrid DataGrid1;

        public string linkUrl = null;

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
            this.btnSave.Click += new System.EventHandler(this.btnSave_Click);

        }
		#endregion

        #region BasePage Events
        /// <summary>
        /// Page initialization event handler (thrown by page master)
        /// </summary>
        protected override void Event_PageInit(object sender, System.EventArgs e)
        {
            this.helpId = 0;
            this.levelTwo = LevelTwoNav.Preferences;
            this.pageTitle = "Status Email Notifications";
            // Security permission only for administrators.  If we are one,
            // go ahead and set up the page.
            DoSecurity(Role.Administrator, "default.aspx");
        }
        /// <summary>
        /// Page load event handler (thrown by page master)
        /// </summary>
        protected override void Event_PageLoad(object sender, System.EventArgs e)
        {
            if (Page.IsPostBack)
            {
                mode = (string)ViewState["Mode"];
                listStatus = (int)this.ViewState["ListStatus"];
                listType = (ListTypes)this.ViewState["ListType"];
                emailGroups = (EmailGroupCollection)this.ViewState["EmailGroups"];
                alertGroups = (EmailGroupCollection)this.ViewState["AlertGroups"];
                statusGroups = (EmailGroupCollection)this.ViewState["StatusGroups"];
            }
            else if (Request.QueryString["listType"] == null)
            {
                Response.Redirect("../default.aspx", false);
            }
            else
            {
                // Get the page mode and place it in the viewstate
                mode = Request.QueryString["alert"] != null ? "alert" : "status";
                ViewState["Mode"] = mode;
                // Get the email group information
                try
                {
                    emailGroups = EmailGroup.GetEmailGroups();
                    int x = (mode == "status") ? Int32.Parse(Request.QueryString["listStatus"]) : -1;
                    listType = (ListTypes)Enum.ToObject(typeof(ListTypes), Int32.Parse(Request.QueryString["listType"]));
                    // Get the list status or alert groups
                    if (mode == "status")
                    {
                        switch (listType)
                        {
                            case ListTypes.Send:
                                listStatus = (int)((SLStatus)Enum.ToObject(typeof(SLStatus), x));
                                statusGroups = SendList.GetEmailGroups((SLStatus)Enum.ToObject(typeof(SLStatus),listStatus));
                                break;
                            case ListTypes.Receive:
                                listStatus = (int)((RLStatus)Enum.ToObject(typeof(RLStatus), x));
                                statusGroups = ReceiveList.GetEmailGroups((RLStatus)Enum.ToObject(typeof(RLStatus),listStatus));
                                break;
                            case ListTypes.DisasterCode:
                                listStatus = (int)((DLStatus)Enum.ToObject(typeof(DLStatus), x));
                                statusGroups = DisasterCodeList.GetEmailGroups((DLStatus)Enum.ToObject(typeof(DLStatus),listStatus));
                                break;
                        }
                    }
                    else
                    {
                        switch (listType)
                        {
                            case ListTypes.Send:
                                alertGroups = SendList.GetEmailGroups();
                                break;
                            case ListTypes.Receive:
                                alertGroups = ReceiveList.GetEmailGroups();
                                break;
                            case ListTypes.DisasterCode:
                                alertGroups = DisasterCodeList.GetEmailGroups();
                                break;
                        }
                    }
                    // Create the datagrid
                    this.ObtainGroups();
                }
                catch
                {
                    Response.Redirect("../default.aspx", false);
                }
                // Place the list type and status in the viewstate
                this.ViewState["ListType"] = listType;
                this.ViewState["ListStatus"] = listStatus;
                this.ViewState["EmailGroups"] = emailGroups;
                this.ViewState["AlertGroups"] = alertGroups;
                this.ViewState["StatusGroups"] = statusGroups;
            }
        }
        /// <summary>
        /// Page prerender event handler (thrown by page master)
        /// </summary>
        protected override void Event_PagePreRender(object sender, System.EventArgs e)
        {
            if (mode == "status")
            {
                switch (listType)
                {
                    case ListTypes.Send:
                        SLStatus sl = (SLStatus)Enum.ToObject(typeof(SLStatus), listStatus);
                        lblTitle.Text = String.Format("List Email Status Notifications&nbsp;&nbsp;-&nbsp;&nbsp;Shipping, {0}", StatusString(sl));
                        lblDesc.Text = String.Format("Assign groups to receive an email alert when a shipping list attains {0} status.", StatusString(sl, false));
                        break;
                    case ListTypes.Receive:
                        RLStatus rl = (RLStatus)Enum.ToObject(typeof(RLStatus), listStatus);
                        lblTitle.Text = String.Format("List Email Status Notifications&nbsp;&nbsp;-&nbsp;&nbsp;Receiving, {0}", StatusString(rl));
                        lblDesc.Text = String.Format("Assign groups to receive an email alert when a receiving list attains {0} status.", StatusString(rl, false));
                        break;
                    case ListTypes.DisasterCode:
                        DLStatus dl = (DLStatus)Enum.ToObject(typeof(DLStatus), listStatus);
                        lblTitle.Text = String.Format("List Email Status Notifications&nbsp;&nbsp;-&nbsp;&nbsp;Disaster Recovery, {0}", StatusString(dl));
                        lblDesc.Text = String.Format("Assign groups to receive an email alert when a disaster recovery list attains {0} status.", StatusString(dl, false));
                        break;
                }
            }
            else
            {
                switch (listType)
                {
                    case ListTypes.Send:
                        lblTitle.Text = "List Email Overdue Alerts&nbsp;&nbsp;-&nbsp;&nbsp;Shipping";
                        lblDesc.Text = "Assign groups to receive an email alert when a shipping list is overdue for processing.";
                        break;
                    case ListTypes.Receive:
                        lblTitle.Text = "List Email Overdue Alerts&nbsp;&nbsp;-&nbsp;&nbsp;Receiving";
                        lblDesc.Text = "Assign groups to receive an email alert when a receiving list is overdue for processing.";
                        break;
                    case ListTypes.DisasterCode:
                        lblTitle.Text = "List Email Overdue Alerts&nbsp;&nbsp;-&nbsp;&nbsp;Disaster Recovery";
                        lblDesc.Text = "Assign groups to receive an email alert when a disaster recovery list is overdue for processing.";
                        break;
                }
            }
        }
        #endregion
        
        /// <summary>
        /// Obtains and binds data to the datagrid
        /// </summary>
        private void ObtainGroups()
        {
            DataTable dataTable = new DataTable();
            ArrayList checkThese = new ArrayList();
            // Create data table
            dataTable.Columns.Add("Name", typeof(string));
            dataTable.Columns.Add("Operators", typeof(string));
            // If no groups, create dummy row
            if (emailGroups.Count == 0)
            {
                dataTable.Rows.Add(new object[] {String.Empty, String.Empty});
                DataGrid1.Columns[0].Visible = false;
            }
            else
            {
                foreach (EmailGroupDetails e in emailGroups)
                {
                    string operatorNames = String.Empty;
                    // Consolidate the operators into a string
                    foreach (OperatorDetails o in EmailGroup.GetOperators(e))
                        if (o.Email.Length != 0)
                            operatorNames += String.Format("{0}{1} ({2})", operatorNames.Length != 0 ? ", " : String.Empty, o.Name, o.Email);
                    // Add the row
                    dataTable.Rows.Add(new object[] {e.Name, operatorNames});
                    // Should the row be checked?
                    checkThese.Add((mode == "status" ? statusGroups : alertGroups).Find(e.Name) != null);
                }
            }
            // Set the hyperlink column for the datagrid
            if (mode == "status")
                ((HyperLinkColumn)DataGrid1.Columns[1]).DataNavigateUrlFormatString = String.Format("email-group-detail.aspx?name={{0}}&redirectPage=list-email-detail.aspx&listType={0}&listStatus={1}", (int)listType, listStatus);
            else
                ((HyperLinkColumn)DataGrid1.Columns[1]).DataNavigateUrlFormatString = "email-group-detail.aspx?name={{0}}&redirectPage=list-email-detail.aspx&alert=1";
            // Bind table to grid
            this.DataGrid1.DataSource = dataTable;
            this.DataGrid1.DataBind();
            // Check rows as necessary
            for (int i = 0; i < checkThese.Count; i++)
                if ((bool)checkThese[i])
                    ((HtmlInputCheckBox)DataGrid1.Items[i].FindControl("cbItemChecked")).Checked = true;
            // If no groups, put a text message in the second cell of the firrt row
            if (emailGroups.Count == 0) DataGrid1.Items[0].Cells[1].Text = "No groups defined";
        }
        /// <summary>
        /// Event handler for the save button
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="e"></param>
        private void btnSave_Click(object sender, System.EventArgs e)
        {
            try
            {
                EmailGroupCollection x = new EmailGroupCollection();
                EmailGroupCollection y = new EmailGroupCollection();
                EmailGroupCollection p = mode == "status" ? statusGroups : alertGroups;
                // Get groups to add, groups to deleter
                foreach (DataGridItem i in DataGrid1.Items)
                {
                    if (((HtmlInputCheckBox)i.Cells[0].Controls[1]).Checked)
                    {
                        if (p.Find(emailGroups[i.ItemIndex].Name) == null)
                        {
                            x.Add(emailGroups[i.ItemIndex]);
                        }
                    }
                    else if (i.ItemIndex < emailGroups.Count)
                    {
                        if (p.Find(emailGroups[i.ItemIndex].Name) != null)
                        {
                            y.Add(emailGroups[i.ItemIndex]);
                        }
                    }
                }
                // Manipulate groups
                if (x.Count != 0 || y.Count != 0)
                {
                    if (mode == "status")
                    {
                        switch (listType)
                        {
                            case ListTypes.Send:
                                SendList.ManipulateEmailGroups(x, y, (SLStatus)Enum.ToObject(typeof(SLStatus),listStatus));
                                break;
                            case ListTypes.Receive:
                                ReceiveList.ManipulateEmailGroups(x, y, (RLStatus)Enum.ToObject(typeof(RLStatus),listStatus));
                                break;
                            case ListTypes.DisasterCode:
                                DisasterCodeList.ManipulateEmailGroups(x, y, (DLStatus)Enum.ToObject(typeof(DLStatus),listStatus));
                                break;
                        }
                    }
                    else
                    {
                        switch (listType)
                        {
                            case ListTypes.Send:
                                SendList.ManipulateEmailGroups(x, y);
                                break;
                            case ListTypes.Receive:
                                ReceiveList.ManipulateEmailGroups(x, y);
                                break;
                            case ListTypes.DisasterCode:
                                DisasterCodeList.ManipulateEmailGroups(x, y);
                                break;
                        }
                    }
                }
                // Redirect to the browse page
                Response.Redirect(mode == "status" ? String.Format("list-email-status.aspx?listType={0}", (int)listType) : "list-email-alert.aspx", false);
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
}
