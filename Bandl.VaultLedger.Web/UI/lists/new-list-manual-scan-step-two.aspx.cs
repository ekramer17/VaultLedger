using System;
using System.Web.UI.WebControls;
using System.Web.UI.HtmlControls;
using Bandl.Library.VaultLedger.BLL;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.Exceptions;
using Bandl.Library.VaultLedger.Collections;
using Bandl.Library.VaultLedger.Common.Knock;

namespace Bandl.VaultLedger.Web.UI
{
	/// <summary>
	/// Summary description for new_list_manual_scan_step_two.
	/// </summary>
	public class new_list_manual_scan_step_two : BasePage
	{
        private SendListCaseCollection listCases;
        private int controlSuffix = 0;

        protected System.Web.UI.WebControls.Button btnBack;
        protected System.Web.UI.WebControls.Button btnSave;
        protected System.Web.UI.WebControls.Button btnCancel;
		protected System.Web.UI.WebControls.PlaceHolder PlaceHolder1;
		protected System.Web.UI.WebControls.Label lblCaseNo;
		protected System.Web.UI.WebControls.TextBox txtReturnDate;
		protected System.Web.UI.WebControls.RadioButton rbYes;
		protected System.Web.UI.WebControls.Repeater Repeater1;
        protected System.Web.UI.WebControls.Label lblCaption;

        // Public properties for server transfer
        public string CancelUrl
        {
            get {return (string)this.ViewState["CancelUrl"];}
        }

        public bool DisplayTabs
        {
            get {return (bool)this.ViewState["DisplayTabs"];}
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
            this.btnBack.Click += new System.EventHandler(this.btnBack_Click);
            this.btnSave.Click += new System.EventHandler(this.btnSave_Click);
            this.btnCancel.Click += new System.EventHandler(this.btnCancel_Click);
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
            if (Page.IsPostBack)
            {
                listCases = (SendListCaseCollection)this.ViewState["ListCases"];
            }
            else
            {
                // Should only be able to get here by a server transfer from 
                // new-list-manual-scan-step-one.aspx
                if (Context.Handler is new_list_manual_scan_step_one)
                {
                    string listName = Request.QueryString["listNumber"];
                    string cancelUrl = ((new_list_manual_scan_step_one)Context.Handler).CancelUrl;
                    bool displayTabs = ((new_list_manual_scan_step_one)Context.Handler).DisplayTabs;
                    listCases = SendList.GetSendListCases(SendList.GetSendList(listName,false).Id);
                    // Page title depends on displayTabs
                    if (displayTabs == true)
                    {
                        this.pageTitle = "New Shipping List";
                    }
                    else
                    {
                        this.pageTitle = "Edit Shipping List  :  " + listName;
                    }
                    // Caption
                    this.lblCaption.Text = this.pageTitle;
                    // Insert into viewstate
                    this.ViewState["ListName"] = listName;
                    this.ViewState["ListCases"] = listCases;
                    this.ViewState["DisplayTabs"] = displayTabs;
                    this.ViewState["CancelUrl"] = cancelUrl;
                    // Bind the repeater
                    Repeater1.DataSource = listCases;
                    Repeater1.DataBind();
                }
                else
                {
                    Response.Redirect("send-lists.aspx", true);
                }
            }
		}
        /// <summary>
        /// Page prerender event handler (thrown by page master)
        /// </summary>
        protected override void Event_PagePreRender(object sender, System.EventArgs e)
        {
            // Add attributes for repeater controls
            for (int i = 0; i < Repeater1.Items.Count; i++)
            {
                System.Web.UI.Control ctrlNo    = Repeater1.Items[i].FindControl("rbNo");
                System.Web.UI.Control ctrlYes   = Repeater1.Items[i].FindControl("rbYes");
                System.Web.UI.Control ctrlText  = Repeater1.Items[i].FindControl("txtReturnDate");
                System.Web.UI.Control ctrlLink  = Repeater1.Items[i].FindControl("calendarLink");
                System.Web.UI.Control ctrlLabel = Repeater1.Items[i].FindControl("lblReturnDate");
                // Calendar click
                ((HtmlAnchor)ctrlLink).HRef = String.Format("javascript:openCalendar('{0}');", ctrlText.ClientID);
                // Radio buttons - javascript click events
                this.SetControlAttr(ctrlYes, "onclick", String.Format("makeVisible('{0}', this.checked);", ctrlLink.ClientID));
                this.SetControlAttr(ctrlYes, "onclick", String.Format("makeVisible('{0}', this.checked);", ctrlText.ClientID));
                this.SetControlAttr(ctrlYes, "onclick", String.Format("makeVisible('{0}', this.checked);", ctrlLabel.ClientID));
                this.SetControlAttr(ctrlNo,  "onclick", String.Format("makeVisible('{0}', !this.checked);", ctrlLink.ClientID));
                this.SetControlAttr(ctrlNo,  "onclick", String.Format("makeVisible('{0}', !this.checked);", ctrlText.ClientID));
                this.SetControlAttr(ctrlNo,  "onclick", String.Format("makeVisible('{0}', !this.checked);", ctrlLabel.ClientID));
                // Initial state
                if (!Page.IsPostBack)
                {
                    this.RegisterStartupScript(String.Format("rbload1{0}",i), String.Format("<script>initialVisible('{0}', '{1}')</script>", ctrlYes.ClientID, ctrlLink.ClientID));
                    this.RegisterStartupScript(String.Format("rbload2{0}",i), String.Format("<script>initialVisible('{0}', '{1}')</script>", ctrlYes.ClientID, ctrlText.ClientID));
                    this.RegisterStartupScript(String.Format("rbload3{0}",i), String.Format("<script>initialVisible('{0}', '{1}')</script>", ctrlYes.ClientID, ctrlLabel.ClientID));
                }
            }
        }
        /// <summary>
        /// Appends suffixes to repeater controls for openCalendar javascript function
        /// </summary>
        public string GetControlSuffix()
        {
            controlSuffix += 1;
            return controlSuffix.ToString();
        }
        /// <summary>
        /// Event handler for save button
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="e"></param>
        private void btnSave_Click(object sender, System.EventArgs e)
        {
            // Repeater items mirror the case collection
            for (int i = 0; i < Repeater1.Items.Count; i++)
            {
                listCases[i].Sealed = ((RadioButton)Repeater1.Items[i].FindControl("rbYes")).Checked;
                // Return date only when case is sealed
                if (!listCases[i].Sealed)
                {
                    listCases[i].ReturnDate = String.Empty;
                }
                else 
                {
                    listCases[i].ReturnDate = ((TextBox)Repeater1.Items[i].FindControl("txtReturnDate")).Text;
                }
            }
            // Update the cases			
            try
            {
                SendList.UpdateCases(ref listCases);
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
        /// Back button event handler
        /// </summary>
        private void btnBack_Click(object sender, System.EventArgs e)
        {
            Server.Transfer(String.Format("new-list-manual-scan-step-one.aspx?listNumber={0}", (string)this.ViewState["ListName"]));
        }
        /// <summary>
        /// Cancel button event handler
        /// </summary>
        private void btnCancel_Click(object sender, System.EventArgs e)
        {
            try
            {
                // If we created a new list, delete it.
                if (0 == this.pageTitle.ToUpper().IndexOf("NEW"))
                {
                    SendList.Delete(SendList.GetSendList((string)this.ViewState["ListName"], false));
                }
            }
            catch
            {
                ;
            }
            finally
            {
                Response.Redirect(this.CancelUrl, true);
            }
        }
	}
}
