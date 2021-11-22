using System;
using Bandl.Library.VaultLedger.BLL;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.Security;

namespace Bandl.VaultLedger.Web.UI
{
	/// <summary>
	/// Summary description for list_statuses.
	/// </summary>
	public class list_statuses : BasePage
	{
        private SLStatus sl;
        private RLStatus rl;
        private DLStatus dl;

        protected System.Web.UI.WebControls.PlaceHolder PlaceHolder1;
        protected System.Web.UI.HtmlControls.HtmlTable tblReceive;
        protected System.Web.UI.WebControls.DropDownList ddlAccess;
        protected System.Web.UI.HtmlControls.HtmlGenericControl tabSection;
        protected System.Web.UI.HtmlControls.HtmlGenericControl statusLink;
        protected System.Web.UI.HtmlControls.HtmlGenericControl purgeLink;
        protected System.Web.UI.HtmlControls.HtmlGenericControl emailLink;
        protected System.Web.UI.WebControls.Label lblXmitYes;
        protected System.Web.UI.WebControls.Label topQues;
        protected System.Web.UI.WebControls.DropDownList ddlShip1;  // transmit
        protected System.Web.UI.WebControls.DropDownList ddlShip2;  // verify(i)
        protected System.Web.UI.WebControls.DropDownList ddlShip3;  // transit
        protected System.Web.UI.WebControls.DropDownList ddlShip4;  // arrived
        protected System.Web.UI.WebControls.DropDownList ddlShip5;  // verify (ii)
        protected System.Web.UI.WebControls.DropDownList ddlRecv1;  // transmit
        protected System.Web.UI.WebControls.DropDownList ddlRecv2;  // verify(i)
        protected System.Web.UI.WebControls.DropDownList ddlRecv3;  // transit
        protected System.Web.UI.WebControls.DropDownList ddlRecv4;  // arrived
        protected System.Web.UI.WebControls.DropDownList ddlRecv5;  // verify (ii)
        protected System.Web.UI.HtmlControls.HtmlTableRow rowShip1;
        protected System.Web.UI.HtmlControls.HtmlTableRow rowShip2;
        protected System.Web.UI.HtmlControls.HtmlTableRow rowShip3;
        protected System.Web.UI.HtmlControls.HtmlTableRow rowShip5;
        protected System.Web.UI.HtmlControls.HtmlTableRow rowShip4;
        protected System.Web.UI.HtmlControls.HtmlTableRow rowRecv1;
        protected System.Web.UI.HtmlControls.HtmlTableRow rowRecv2;
        protected System.Web.UI.HtmlControls.HtmlTableRow rowRecv3;
        protected System.Web.UI.HtmlControls.HtmlTableRow rowRecv4;
        protected System.Web.UI.HtmlControls.HtmlTableRow rowRecv5;
        protected System.Web.UI.WebControls.DropDownList ddlDis1;
        protected System.Web.UI.HtmlControls.HtmlTable tblDisaster;
        protected System.Web.UI.WebControls.Button btnDefaults2;
        protected System.Web.UI.WebControls.Button btnSave2;
        protected System.Web.UI.WebControls.Button btnDefaults1;
        protected System.Web.UI.WebControls.Button btnSave1;
        protected System.Web.UI.HtmlControls.HtmlGenericControl disasterSection;
        protected System.Web.UI.HtmlControls.HtmlGenericControl bottom1;
        protected System.Web.UI.HtmlControls.HtmlGenericControl alertLink;
        protected System.Web.UI.WebControls.Button btnOK;

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
            this.ddlAccess.SelectedIndexChanged += new System.EventHandler(this.ddlAccess_SelectedIndexChanged);
            this.btnDefaults1.Click += new System.EventHandler(this.btnDefaults_Click);
            this.btnSave1.Click += new System.EventHandler(this.btnSave_Click);
            this.btnDefaults2.Click += new System.EventHandler(this.btnDefaults_Click);
            this.btnSave2.Click += new System.EventHandler(this.btnSave_Click);

        }
		#endregion

        /// <summary>
        /// Page initialization event handler (thrown by page master)
        /// </summary>
        protected override void Event_PageInit(object sender, System.EventArgs e)
        {
            this.helpId = 45;
            this.levelTwo = LevelTwoNav.Preferences;
            this.pageTitle = "List Statuses";
            // Click events for message box buttons
            this.SetControlAttr(btnSave1, "onclick", "hideMsgBox('msgBoxSave')");
            this.SetControlAttr(btnSave2, "onclick", "hideMsgBox('msgBoxSave')");
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
                sl = (SLStatus)this.ViewState["SLStatus"];
                rl = (RLStatus)this.ViewState["RLStatus"];
                dl = (DLStatus)this.ViewState["DLStatus"];
            }
            else
            {
                sl = SendList.Statuses;
                rl = ReceiveList.Statuses;
                dl = DisasterCodeList.Statuses;
                this.ViewState["SLStatus"] = sl;
                this.ViewState["RLStatus"] = rl;
                this.ViewState["DLStatus"] = dl;
                // Does the vault have access?
                this.ViewState["AccessVault"] = (sl & SLStatus.Arrived) != 0 || (sl & SLStatus.FullyVerifiedII) != 0 || (rl & RLStatus.FullyVerifiedI) != 0 || (rl & RLStatus.Transit) != 0;
                // Initial values
                ddlShip1.SelectedIndex = (sl & SLStatus.Xmitted) != 0 ? 0 : 1;
                ddlShip2.SelectedIndex = (sl & SLStatus.FullyVerifiedI) != 0 ? 0 : 1;
                ddlShip3.SelectedIndex = (sl & SLStatus.Transit) != 0 ? 0 : 1;
                ddlShip4.SelectedIndex = (sl & SLStatus.Arrived) != 0 ? 0 : 1;
                ddlShip5.SelectedIndex = (sl & SLStatus.FullyVerifiedII) != 0 ? 0 : 1;
                // Receiving table
                ddlRecv1.SelectedIndex = (rl & RLStatus.Xmitted) != 0 ? 0 : 1;
                ddlRecv2.SelectedIndex = (rl & RLStatus.FullyVerifiedI) != 0 ? 0 : 1;
                ddlRecv3.SelectedIndex = (rl & RLStatus.Transit) != 0 ? 0 : 1;
                ddlRecv4.SelectedIndex = (rl & RLStatus.Arrived) != 0 ? 0 : 1;
                ddlRecv5.SelectedIndex = (rl & RLStatus.FullyVerifiedII) != 0 ? 0 : 1;
                // Disaster recovery table
                ddlDis1.SelectedIndex = (dl & DLStatus.Xmitted) != 0 ? 0 : 1;
                // Update the tab page default
                TabPageDefault.Update(TabPageDefaults.ListPreferences, Context.Items[CacheKeys.Login], 1);
            }
        }
        /// <summary>
        /// Page load event handler (thrown by page master)
        /// </summary>
        protected override void Event_PagePreRender(object sender, System.EventArgs e)
        {
            // Set the access value
            ddlAccess.SelectedIndex = ((bool)this.ViewState["AccessVault"] == true) ? 0 : 1;
            // Set the row visibility
            SetRowVisibility();
            // Turn off first dropdown if message box visible
            ddlAccess.Visible = !ClientScript.IsStartupScriptRegistered("saveBox");
            // Two tabs or three?
            if (Configurator.ProductType == "RECALL")
            {
                SetControlAttr(tabSection, "class", "tabNavigation fourTabs", false);
                SetControlAttr(statusLink, "class", "tabs fourTabOneSelected", false);
                SetControlAttr(purgeLink, "class", "tabs fourTabFour", false);
//                SetControlAttr(tabSection, "class", "tabNavigation twoTabs", false);
//                SetControlAttr(statusLink, "class", "tabs twoTabOneSelected", false);
//                SetControlAttr(purgeLink, "class", "tabs twoTabTwo", false);
//                alertLink.Visible = false;
//                emailLink.Visible = false;
                // Vault access dropdown should be hidden
                ddlAccess.Visible = false;
                topQues.Text = "Please answer the questions below to determine list statuses used by your ReQuest Media Manager:";
            }
            else
            {
                SetControlAttr(tabSection, "class", "tabNavigation fourTabs", false);
                SetControlAttr(statusLink, "class", "tabs fourTabOneSelected", false);
                SetControlAttr(purgeLink, "class", "tabs fourTabFour", false);
                topQues.Text = "Do the people at the vault have access to your " + Configurator.ProductName + "?";
            }
        }
        /// <summary>
        /// Sets row visibility
        /// </summary>
        private void SetRowVisibility()
        {
            bool doVisible = (bool)this.ViewState["AccessVault"];
            rowShip4.Visible = doVisible;
            rowShip5.Visible = doVisible;
            rowRecv2.Visible = doVisible;
            rowRecv3.Visible = doVisible;
            // Some row visibility and alternate class designation depend on whether product is RECALL or not
            if (Configurator.ProductType == "RECALL")
            {
                rowShip1.Visible = false;
                rowShip3.Visible = false;
                rowRecv1.Visible = false;
                rowRecv3.Visible = false;
                SetControlAttr(rowShip4, "class", "alternate", false);
                SetControlAttr(rowRecv4, "class", "alternate", false);
                this.bottom1.Visible = true;
                this.disasterSection.Visible = false;
            }
            else
            {
                rowShip1.Visible = true;
                rowShip3.Visible = true;
                rowRecv1.Visible = true;
                SetControlAttr(rowShip2, "class", "alternate", false);
                SetControlAttr(rowShip4, "class", "alternate", false);
                SetControlAttr(rowRecv2, "class", "alternate", false);
                SetControlAttr(rowRecv4, "class", "alternate", false);
                this.bottom1.Visible = false;
                this.disasterSection.Visible = true;
            }

        }
        /// <summary>
        /// If selection of access dropdown changes, the tables will changes.  Collect the values
        /// here.  Table changes will be taken care of when page is rendered.
        /// </summary>
        private void ddlAccess_SelectedIndexChanged(object sender, System.EventArgs e)
        {
            this.ViewState["AccessVault"] = ddlAccess.SelectedIndex != 1;
        }
        /// <summary>
        /// Click event handler for all save buttons
        /// </summary>
        private void btnSave_Click(object sender, System.EventArgs e)
        {
            bool va = (bool)this.ViewState["AccessVault"];
            // Shipping specific
            sl = ddlShip1.SelectedIndex != 1 ? sl | SLStatus.Xmitted : sl & (SLStatus.AllValues ^ SLStatus.Xmitted);
            sl = ddlShip2.SelectedIndex != 1 ? sl | SLStatus.FullyVerifiedI : sl & (SLStatus.AllValues ^ SLStatus.FullyVerifiedI);
            sl = ddlShip3.SelectedIndex != 1 ? sl | SLStatus.Transit : sl & (SLStatus.AllValues ^ SLStatus.Transit);
            sl = ddlShip4.SelectedIndex != 1 && va ? sl | SLStatus.Arrived : sl & (SLStatus.AllValues ^ SLStatus.Arrived);
            sl = ddlShip5.SelectedIndex != 1 && va ? sl | SLStatus.FullyVerifiedII : sl & (SLStatus.AllValues ^ SLStatus.FullyVerifiedII);
            // Receiving specific
            rl = ddlRecv1.SelectedIndex != 1 ? rl | RLStatus.Xmitted : rl & (RLStatus.AllValues ^ RLStatus.Xmitted);
            rl = ddlRecv2.SelectedIndex != 1 && va ? rl | RLStatus.FullyVerifiedI : rl & (RLStatus.AllValues ^ RLStatus.FullyVerifiedI);
            rl = ddlRecv3.SelectedIndex != 1 && va ? rl | RLStatus.Transit : rl & (RLStatus.AllValues ^ RLStatus.Transit);
            rl = ddlRecv4.SelectedIndex != 1 ? rl | RLStatus.Arrived : rl & (RLStatus.AllValues ^ RLStatus.Arrived);
            rl = ddlRecv5.SelectedIndex != 1 ? rl | RLStatus.FullyVerifiedII : rl & (RLStatus.AllValues ^ RLStatus.FullyVerifiedII);
            // Disaster specific
            dl = ddlDis1.SelectedIndex != 1 ? dl | DLStatus.Xmitted : dl & (DLStatus.AllValues ^ DLStatus.Xmitted);
            // Make sure that the status values do not contain submitted or processed
            sl &= SLStatus.AllValues ^ (SLStatus.Submitted | SLStatus.Processed);
            rl &= RLStatus.AllValues ^ (RLStatus.Submitted | RLStatus.Processed);
            dl &= DLStatus.AllValues ^ (DLStatus.Submitted | DLStatus.Processed);
            // Update the statuses
            try
            {
                SendList.UpdateStatuses(sl);
                ReceiveList.UpdateStatuses(rl);
                DisasterCodeList.UpdateStatuses(dl);
                // Update page variables and viewstate
                this.ViewState["SLStatus"] = sl;
                this.ViewState["RLStatus"] = rl;
                this.ViewState["DLStatus"] = dl;
                //// Remove statuses from the cache so that it will be refreshed on next access
                //CacheKeys.Remove(CacheKeys.SLStatuses);
                //CacheKeys.Remove(CacheKeys.RLStatuses);
                //CacheKeys.Remove(CacheKeys.DLStatuses);
                // Message box
                this.ShowMessageBox("saveBox", "msgBoxSave");
            }
            catch (Exception ex)
            {
                this.DisplayErrors(this.PlaceHolder1, ex.Message);
            }
        }
        /// <summary>
        /// Restore the defaults
        /// </summary>
        private void btnDefaults_Click(object sender, System.EventArgs e)
        {
            this.ddlShip1.SelectedValue = "Yes";
            this.ddlShip2.SelectedValue = "Yes";
            this.ddlShip3.SelectedValue = "No";
            this.ddlShip4.SelectedValue = "No";
            this.ddlShip5.SelectedValue = "No";
            this.ddlRecv1.SelectedValue = "No";
            this.ddlRecv2.SelectedValue = "No";
            this.ddlRecv3.SelectedValue = "No";
            this.ddlRecv4.SelectedValue = "Yes";
            this.ddlRecv5.SelectedValue = "Yes";
            this.ddlDis1.SelectedValue = "Yes";
            // Set the vault access to false
            this.ddlAccess.SelectedValue = "No";
            this.ViewState["AccessVault"] = false;
        }
    }
}
