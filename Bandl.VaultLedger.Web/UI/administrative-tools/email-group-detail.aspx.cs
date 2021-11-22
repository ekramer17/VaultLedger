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

namespace Bandl.VaultLedger.Web.UI
{
	/// <summary>
	/// Summary description for email_group_detal.
	/// </summary>
	public class email_group_detal : BasePage
	{
        private EmailGroupDetails eGroup = null;
        private OperatorCollection oCollection = null;
        private string redirectPage = "email-groups.aspx";

        protected System.Web.UI.WebControls.PlaceHolder PlaceHolder1;
        protected System.Web.UI.WebControls.DataGrid DataGrid1;
        protected System.Web.UI.WebControls.Button btnSave;
        protected System.Web.UI.WebControls.Label lblTitle;
        protected System.Web.UI.WebControls.Label lblDesc;
        protected System.Web.UI.WebControls.TextBox txtGroupName;

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
            this.helpId = 57;
            this.levelTwo = LevelTwoNav.EmailGroups;
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
                oCollection = (OperatorCollection)this.ViewState["Operators"];
                if (this.ViewState["EmailGroup"] != null)
                    eGroup = (EmailGroupDetails)this.ViewState["EmailGroup"];
                if (this.ViewState["RedirectPage"] != null)
                    redirectPage = (string)this.ViewState["RedirectPage"];
            }
            else
            {
                try
                {
                    // Get the email group if we have one in the querystring
                    if (Request.QueryString["name"] != null)
                        if ((eGroup = EmailGroup.GetEmailGroup(Request.QueryString["name"])) == null)
                            Server.Transfer("email-groups.aspx");
                    // If we have a redirect page, get it
                    if (Request.QueryString["redirectPage"] != null)
                    {
                        redirectPage = Request.QueryString["redirectPage"];
                        switch (redirectPage)
                        {
                            case "list-email-detail.aspx":
                                redirectPage += String.Format("?listType={0}&listStatus={1}", Int32.Parse(Request.QueryString["listType"]), Int32.Parse(Request.QueryString["listStatus"]));
                                break;
                            case "list-email-status.aspx":
                                redirectPage += String.Format("?listType={0}", Int32.Parse(Request.QueryString["listType"]));
                                break;
                            default:
                                break;
                        }
                        // Place the redirect page in the view state
                        this.ViewState["RedirectPage"] = redirectPage;
                    }
                    // If we have a name, populate the textbox
                    if (eGroup != null)
                    {
                        txtGroupName.Text = eGroup.Name;
                        this.ViewState["EmailGroup"] = eGroup;
                    }
                    // Obtain the redirect page
                    if (Context.Handler is list_email_status)
                    {
                        redirectPage = "list-email-status.aspx";
                        this.ViewState["RedirectPage"] = redirectPage;
                    }
                    else if (Context.Handler is list_email_alert)
                    {
                        redirectPage = "list-email-alert.aspx";
                        this.ViewState["RedirectPage"] = redirectPage;
                    }
                    // Get the operators
                    this.ObtainOperators();
                }
                catch
                {
                    Server.Transfer("email-groups.aspx");
                }
                    
            }
            // Set focus to the text box
            this.DoFocus(txtGroupName);
        }
        /// <summary>
        /// Page prerender event handler (thrown by page master)
        /// </summary>
        protected override void Event_PagePreRender(object sender, System.EventArgs e)
        {
            if (eGroup != null)
            {
                lblTitle.Text = "Email Group Detail&nbsp;&nbsp; - &nbsp;&nbsp;" + eGroup.Name;
                lblDesc.Text = "Select the operators to include in this email group.";
            }
            else
            {
                lblTitle.Text = "Add Email Group";
                lblDesc.Text = "Create new email group.";
            }
        }
        #endregion
        
        /// <summary>
        /// Obtains the operators and binds thtm to the datagrid
        /// </summary>
        private void ObtainOperators()
        {
            oCollection = Operator.GetOperators();
            // Remove any operators that do not have email addresses
            for (int i = oCollection.Count - 1; i > -1; i--)
                if (oCollection[i].Email == String.Empty)
                    oCollection.RemoveAt(i);
            // If no operators, then insert a dummy row and display message
            if (oCollection.Count == 0)
            {
                DataTable dataTable = new DataTable();
                dataTable.Columns.Add("Name", typeof(string));
                dataTable.Columns.Add("Login", typeof(string));
                dataTable.Columns.Add("Email", typeof(string));
                dataTable.Rows.Add(new object[] {String.Empty, String.Empty, String.Empty});
                DataGrid1.DataSource = dataTable;
                DataGrid1.DataBind();
                // Render checkbox column invisible and insert message in first cell
                this.btnSave.Visible = false;
                DataGrid1.Columns[0].Visible = false;
                DataGrid1.Items[0].Cells[1].Text = "No operators have email addresses";
            }
            else
            {
                // Insert operators into the viewstate
                this.ViewState["Operators"] = oCollection;
                // Bind the remianing operators to the datagrid
                DataGrid1.DataSource = oCollection;
                DataGrid1.DataBind();
                // Check off any operators that currently belong to the email group
                if (eGroup != null)
                {
                    OperatorCollection emailOperators = EmailGroup.GetOperators(eGroup);
                    for (int i = 0; i < DataGrid1.Items.Count; i++)
                        ((HtmlInputCheckBox)DataGrid1.Items[i].FindControl("cbItemChecked")).Checked = emailOperators.Find(oCollection[i].Id) != null;
                }
            }
        }
        /// <summary>
        /// Save button even handler.  Saves group to database.
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="e"></param>
        private void btnSave_Click(object sender, System.EventArgs e)
        {
            try
            {
                if (eGroup == null)
                {
                    OperatorCollection insertThese = new OperatorCollection();
                    EmailGroupDetails x = new EmailGroupDetails(txtGroupName.Text);
                    // Collect all the operators to insert
                    foreach (DataGridItem i in CollectCheckedItems(DataGrid1))
                        insertThese.Add(oCollection[i.ItemIndex]);
                    // Create the email group
                    EmailGroup.Create(x, insertThese);
                    // Return to the browse page
                    Response.Redirect("email-groups.aspx", false);
                }
                else
                {
                    bool[] m = new bool[oCollection.Count];
                    // Create boolean array to determine which operators are members of the group
                    for (int i = 0; i < m.Length; i++)
                        m[i] = ((HtmlInputCheckBox)DataGrid1.Items[i].FindControl("cbItemChecked")).Checked;
                    // Edit the collection
                    EmailGroup.EditOperators(eGroup, oCollection, m);
                    // Display the message box
                    Response.Redirect(redirectPage, false);
                }
            }
            catch (Exception ex)
            {
                DisplayErrors(this.PlaceHolder1, ex.Message);
            }
        }
    }
}
