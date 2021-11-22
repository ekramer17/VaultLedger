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
	/// Summary description for list_email_status.
	/// </summary>
	public class list_email_status : BasePage
	{
        private ListTypes listType = ListTypes.Send;

        protected System.Web.UI.WebControls.PlaceHolder PlaceHolder1;
        protected System.Web.UI.WebControls.DropDownList ddlListType;
        protected System.Web.UI.WebControls.Button btnGo;
        protected System.Web.UI.WebControls.Table Table1;
        protected System.Web.UI.WebControls.Label lblTitle;
        protected System.Web.UI.WebControls.Button btnEmail;

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
            this.btnGo.Click += new System.EventHandler(this.btnGo_Click);

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
            this.pageTitle = "List Email Notifications";
            // Security permission only for administrators.  If we are one,
            // go ahead and set up the page.
            DoSecurity(Role.Administrator, "../default.aspx");
        }
        /// <summary>
        /// Page load event handler (thrown by page master)
        /// </summary>
        protected override void Event_PageLoad(object sender, System.EventArgs e)
        {
            if (Page.IsPostBack)
            {
                listType = (ListTypes)this.ViewState["ListType"];
            }
            else
            {
                if (Request.QueryString["listType"] != null)
                {
                    try
                    {
                        listType = (ListTypes)Enum.ToObject(typeof(ListTypes), Int32.Parse(Request.QueryString["listType"]));
                    }
                    catch
                    {
                        Response.Redirect("default.aspx", false);
                    }
                }
                // Place the list type in the viewstate
                this.ViewState["ListType"] = listType;
                // Update the tab page default
                TabPageDefault.Update(TabPageDefaults.ListPreferences, Context.Items[CacheKeys.Login], 2);
            }
        }
        /// <summary>
        /// Page prerender event handler (thrown by page master)
        /// </summary>
        protected override void Event_PagePreRender(object sender, System.EventArgs e)
        {
            // Create the table
            this.CreateTable();
            // Configure button should not be visible if router is true
            btnEmail.Visible = !Configurator.Router;
            // Page title
            switch (listType)
            {
                case ListTypes.Send:
                    this.lblTitle.Text = "Email Status Notifications&nbsp;&nbsp;-&nbsp;&nbsp;Shipping";
                    break;
                case ListTypes.Receive:
                    this.lblTitle.Text = "Email Status Notifications&nbsp;&nbsp;-&nbsp;&nbsp;Receiving";
                    break;
                case ListTypes.DisasterCode:
                    this.lblTitle.Text = "Email Status Notifications&nbsp;&nbsp;-&nbsp;&nbsp;Disaster Recovery";
                    break;
            }
        }
        #endregion

        #region Table Creation Methods
        /// <summary>
        /// Gets the status and email group information from the database and
        /// creates the table using that information.
        /// </summary>
        private void CreateTable()
        {
            switch (listType)
            {
                case ListTypes.Send:
                    this.CreateTableSend();
                    break;
                case ListTypes.Receive:
                    this.CreateTableReceive();
                    break;
                case ListTypes.DisasterCode:
                    this.CreateTableDisaster();
                    break;
            }
        }
        /// <summary>
        /// Gets the status and email group information from the database and
        /// creates the table using that information.
        /// </summary>
        private void CreateTableSend()
        {
            EmailGroupCollection ec = null;
            // Submitted is always included
            ec = SendList.GetEmailGroups(SLStatus.Submitted);
            Table1.Rows.Add(CreateTableRow(SLStatus.Submitted, ec));
            // For each status, if it isn't used, ignore it.  Otherwise, get the email groups
            // from the database.  Create hyperlinks for the status and each of the email groups.
            foreach (int i in Enum.GetValues(typeof(SLStatus)))
            {
                SLStatus sl = (SLStatus)Enum.ToObject(typeof(SLStatus), i);
                // Ignore certain values
                switch (sl)
                {
                    case SLStatus.AllValues:
                    case SLStatus.Submitted:
                    case SLStatus.Processed:
                    case SLStatus.None:
                    case SLStatus.PartiallyVerifiedI:
                    case SLStatus.PartiallyVerifiedII:
                        continue;
                    default:
                        break;
                }
                // If the status is not being used, ignore it
                if (((int)SendList.Statuses & (int)sl) != 0)
                {
                    ec = SendList.GetEmailGroups(sl);
                    Table1.Rows.Add(CreateTableRow(sl, ec));
                }
            }
            // Processed is always included
            ec = SendList.GetEmailGroups(SLStatus.Processed);
            Table1.Rows.Add(CreateTableRow(SLStatus.Processed, ec));
        }
        /// <summary>
        /// Gets the status and email group information from the database and
        /// creates the table using that information.
        /// </summary>
        private void CreateTableReceive()
        {
            EmailGroupCollection ec = null;
            // Submitted is always included
            ec = ReceiveList.GetEmailGroups(RLStatus.Submitted);
            Table1.Rows.Add(CreateTableRow(RLStatus.Submitted, ec));
            // For each status, if it isn't used, ignore it.  Otherwise, get the email groups
            // from the database.  Create hyperlinks for the status and each of the email groups.
            foreach (int i in Enum.GetValues(typeof(RLStatus)))
            {
                RLStatus rl = (RLStatus)Enum.ToObject(typeof(RLStatus), i);
                // Ignore certain values
                switch (rl)
                {
                    case RLStatus.AllValues:
                    case RLStatus.Submitted:
                    case RLStatus.Processed:
                    case RLStatus.None:
                    case RLStatus.PartiallyVerifiedI:
                    case RLStatus.PartiallyVerifiedII:
                        continue;
                    default:
                        break;
                }
                // If the status is not being used, ignore it
                if (((int)ReceiveList.Statuses & (int)rl) != 0)
                {
                    ec = ReceiveList.GetEmailGroups(rl);
                    Table1.Rows.Add(CreateTableRow(rl, ec));
                }
            }
            // Processed is always included
            ec = ReceiveList.GetEmailGroups(RLStatus.Processed);
            Table1.Rows.Add(CreateTableRow(RLStatus.Processed, ec));
        }
        /// <summary>
        /// Gets the status and email group information from the database and
        /// creates the table using that information.
        /// </summary>
        private void CreateTableDisaster()
        {
            EmailGroupCollection ec = null;
            // Submitted is always included
            ec = DisasterCodeList.GetEmailGroups(DLStatus.Submitted);
            Table1.Rows.Add(CreateTableRow(DLStatus.Submitted, ec));
            // For each status, if it isn't used, ignore it.  Otherwise, get the email groups
            // from the database.  Create hyperlinks for the status and each of the email groups.
            foreach (int i in Enum.GetValues(typeof(DLStatus)))
            {
                DLStatus dl = (DLStatus)Enum.ToObject(typeof(DLStatus), i);
                // Ignore certain values
                switch (dl)
                {
                    case DLStatus.AllValues:
                    case DLStatus.Submitted:
                    case DLStatus.Processed:
                    case DLStatus.None:
                        continue;
                    default:
                        break;
                }
                // If the status is not being used, ignore it
                if (((int)DisasterCodeList.Statuses & (int)dl) != 0)
                {
                    ec = DisasterCodeList.GetEmailGroups(dl);
                    Table1.Rows.Add(CreateTableRow(dl, ec));
                }
            }
            // Processed is always included
            ec = DisasterCodeList.GetEmailGroups(DLStatus.Processed);
            Table1.Rows.Add(CreateTableRow(DLStatus.Processed, ec));
        }
        /// <summary>
        /// Creates a table row
        /// </summary>
        private TableRow CreateTableRow(object listStatus, EmailGroupCollection ec)
        {
            int statusValue = -1;
            if (listStatus is SLStatus)
                statusValue = (int)((SLStatus)listStatus);
            else if (listStatus is RLStatus)
                statusValue = (int)((RLStatus)listStatus);
            else
                statusValue = (int)((DLStatus)listStatus);
            // Create the row
            TableRow tr = new TableRow();
            tr.Height = Unit.Pixel(40);
            // Alternate row?
            if (Table1.Rows.Count % 2 == 0)
                tr.CssClass = "alternate";
            // Create the status cell
            TableCell tc = new TableCell();
            HtmlAnchor link = new HtmlAnchor();
            link.InnerHtml = StatusString(listStatus);
            link.HRef = String.Format("list-email-detail.aspx?listType={0}&listStatus={1}", (int)listType, statusValue);
            tc.Controls.Add(link);
            tr.Cells.Add(tc);
            // Create the group cell
            tc = new TableCell();
            if (ec.Count != 0)
            {
                StringBuilder x = new StringBuilder(ec[0].Name);
                for (int i = 1; i < ec.Count; i++)
                    x.AppendFormat(", {0}", ec[i].Name);
                tc.Controls.Add(new LiteralControl(x.ToString()));
            }
            tr.Cells.Add(tc);
            // Return the row
            return tr;
        }
        #endregion

        /// <summary>
        /// Event handler for the Go button
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="e"></param>
        private void btnGo_Click(object sender, System.EventArgs e)
        {
            switch (ddlListType.SelectedValue)
            {
                case "Shipping":
                    listType = ListTypes.Send;
                    this.ViewState["ListType"] = listType;
                    break;
                case "Receiving":
                    listType = ListTypes.Receive;
                    this.ViewState["ListType"] = listType;
                    break;
                case "Disaster":
                    listType = ListTypes.DisasterCode;
                    this.ViewState["ListType"] = listType;
                    break;
            }
        }
        /// <summary>
        /// Send user to the email server configuration page
        /// </summary>
        private void btnEmail_Click(object sender, System.EventArgs e)
        {
            Server.Transfer("email-configure.aspx?redirectPage=list-email_status.aspx&listType=" + ((int)listType).ToString());        
        }
    }
}
