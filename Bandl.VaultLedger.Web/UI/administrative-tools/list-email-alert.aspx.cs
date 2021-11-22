using System;
using System.Collections;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Web;
using System.Text;
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
	/// Summary description for list_email_alert.
	/// </summary>
	public class list_email_alert : BasePage
	{
        protected int[] alertDays = new int[] {0, 0, 0};
        protected ArrayList emailGroups = new ArrayList();
        protected System.Web.UI.WebControls.Label lblTitle;
        protected System.Web.UI.WebControls.PlaceHolder PlaceHolder1;
        protected System.Web.UI.WebControls.Button btnEmail;
        protected System.Web.UI.HtmlControls.HtmlGenericControl divConfigure;
        protected System.Web.UI.HtmlControls.HtmlInputButton btnSave;
        protected System.Web.UI.HtmlControls.HtmlInputButton btnOK;
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
            this.btnEmail.Click += new System.EventHandler(this.btnEmail_Click);
            this.DataGrid1.ItemDataBound += new System.Web.UI.WebControls.DataGridItemEventHandler(this.DataGrid1_ItemDataBound);
            this.btnSave.ServerClick += new System.EventHandler(this.btnSave_ServerClick);

        }
		#endregion

        #region BasePage Events
        /// <summary>
        /// Page initialization event handler (thrown by page master)
        /// </summary>
        protected override void Event_PageInit(object sender, System.EventArgs e)
        {
            this.helpId = 45;
            this.levelTwo = LevelTwoNav.Preferences;
            this.pageTitle = "List Alert Notifications";
            // Security permission only for administrators.  If we are one,
            // go ahead and set up the page.
            DoSecurity(Role.Administrator, "default.aspx");
        }
        /// <summary>
        /// Page load event handler (thrown by page master)
        /// </summary>
        protected override void Event_PageLoad(object sender, System.EventArgs e)
        {
            if (!Page.IsPostBack)
//            {
//                alertDays = (int[])ViewState["AlertDays"];
//                emailGroups = (ArrayList)ViewState["EmailGroups"];
//            }
//            else
            {
                // Get the list alert days
                alertDays[0] = SendList.GetListAlertDays();
                alertDays[1] = ReceiveList.GetListAlertDays();
                alertDays[2] = DisasterCodeList.GetListAlertDays();
                // Get the email groups
                emailGroups.Add(SendList.GetEmailGroups());
                emailGroups.Add(ReceiveList.GetEmailGroups());
                emailGroups.Add(DisasterCodeList.GetEmailGroups());
//                // Update the viewstate
//                ViewState["AlertDays"] = alertDays;
//                ViewState["EmailGroups"] = emailGroups;
                // Update the tab page default
                TabPageDefault.Update(TabPageDefaults.ListPreferences, Context.Items[CacheKeys.Login], 3);
            }
        }
        /// <summary>
        /// Page prerender event handler (thrown by page master)
        /// </summary>
        protected override void Event_PagePreRender(object sender, System.EventArgs e)
        {
            if (!Page.IsPostBack) CreateTable();
            // If router, do not show configure button
            divConfigure.Visible = !Configurator.Router;
            // Message box attribute
            SetControlAttr(btnOK, "onclick", "hideMsgBox('msgBoxOK');");
        }
        #endregion

        /// <summary>
        /// Gets the status and email group information from the database and
        /// creates the table using that information.
        /// </summary>
        private void CreateTable()
        {
            DataTable d = new DataTable();
            d.Columns.Add("ListType", typeof(string));
            d.Columns.Add("Days", typeof(int));
            d.Columns.Add("EmailGroups", typeof(string));
            d.Columns.Add("TypeInt", typeof(int));
            // Add the rows
            for (int i = 0; i < 3; i++)
            {
                string listType = String.Empty;
                string e = String.Empty;
                int t = 0;
                // List type
                switch (i)
                {
                    case 0:
                        listType = "Shipping";
                        t = (int)ListTypes.Send;
                        break;
                    case 1:
                        listType = "Receiving";
                        t = (int)ListTypes.Receive;
                        break;
                    case 2:
                        listType = "Disaster Recovery";
                        t = (int)ListTypes.DisasterCode;
                        break;
                }
                // Days
                int days = alertDays[i];
                // Email groups
                foreach (EmailGroupDetails x in (EmailGroupCollection)emailGroups[i])
                    e += e.Length != 0 ? ", " + x.Name : x.Name;
                // Add the row
                d.Rows.Add(new object[] {listType, days, e, t});
            }
            // Bind it
            DataGrid1.DataSource = d;
            DataGrid1.DataBind();
        }
        /// <summary>
        /// Occurs when an item is databound to the datagrid
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="e"></param>
        private void DataGrid1_ItemDataBound(object sender, DataGridItemEventArgs e)
        {
            SetControlAttr(e.Item.FindControl("txtDays"), "onkeyup", "digitsOnly(this);");
        }
        /// <summary>
        /// Send user to the email server configuration page
        /// </summary>
        private void btnEmail_Click(object sender, System.EventArgs e)
        {
            Server.Transfer("email-configure.aspx?redirectPage=list-email-alert.aspx");
        }
        /// <summary>
        /// Updates the alert days
        /// </summary>
        private void btnSave_ServerClick(object sender, System.EventArgs e)
        {
            int[] d = new int[] {0, 0, 0};
            // Get the days from the datagrid.  Make sure that all values are greater than or equal to zero.
            foreach (DataGridItem i in DataGrid1.Items)
            {
                d[i.ItemIndex] = Convert.ToInt32(((TextBox)i.FindControl("txtDays")).Text);
                if (d[i.ItemIndex] < 0) {DisplayErrors(PlaceHolder1, "Days must be greater than or equal to zero."); return;}
            }
            // Update the days
            try
            {
                SendList.UpdateAlertDays(d[0]);
                ReceiveList.UpdateAlertDays(d[1]);
                DisasterCodeList.UpdateAlertDays(d[2]);
                // Show the success message box
                this.ShowMessageBox("msgBoxOK");
            }
            catch (Exception ex)
            {
                DisplayErrors(PlaceHolder1, ex.Message);
            }
        }
    }
}
