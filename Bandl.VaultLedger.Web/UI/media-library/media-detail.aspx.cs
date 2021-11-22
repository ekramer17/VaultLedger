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
	/// Summary description for media_detail.
	/// </summary>
	public class media_detail : BasePage
	{
        private MediumDetails m = null;
        protected System.Web.UI.WebControls.LinkButton printLink;
        protected System.Web.UI.WebControls.PlaceHolder PlaceHolder1;
        protected System.Web.UI.WebControls.TextBox txtCountry;
        protected System.Web.UI.WebControls.Label lblSerialNo;
        protected System.Web.UI.WebControls.Label lblLocation;
        protected System.Web.UI.WebControls.Label lblAccount;
        protected System.Web.UI.WebControls.Label lblMediumType;
        protected System.Web.UI.WebControls.Label lblMissing;
        protected System.Web.UI.WebControls.Label lblReturnDate;
        protected System.Web.UI.WebControls.Label lblCaseNo;
        protected System.Web.UI.WebControls.Label lblNotes;
        protected System.Web.UI.WebControls.DataGrid DataGrid1;
        protected System.Web.UI.WebControls.Label lblPageHeader;
        protected System.Web.UI.WebControls.LinkButton arrow;
        protected System.Web.UI.WebControls.Label lblListName;
        protected System.Web.UI.WebControls.Label lblListStatus;
        protected System.Web.UI.HtmlControls.HtmlAnchor listAnchor;
        protected System.Web.UI.HtmlControls.HtmlGenericControl todaysList;

        #region Public Properties
        public MediumFilter SearchFilter 
        {
            get 
            {
                if (ViewState["SearchFilter"] != null)
                    return (MediumFilter)ViewState["SearchFilter"];
                else
                    return null;
            } 
        }
        public int BrowsePage
        {
            get 
            {
                if (ViewState["BrowsePage"] != null)
                    return (int)ViewState["BrowsePage"];
                else
                    return 1;
            } 
        }
        #endregion

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
            this.arrow.Click += new System.EventHandler(this.LinkBrowse_Click);
            this.printLink.Click += new System.EventHandler(this.printLink_Click);

        }
		#endregion

        /// <summary>
        /// Page initialization event handler (thrown by page master)
        /// </summary>
        protected override void Event_PageInit(object sender, System.EventArgs e)
        {
            this.helpId = 47;
            this.levelTwo = LevelTwoNav.Find;
            // Security - auditors and viewers cannot create or save media types.  Operators
            // can only create medium types; they cannot edit them.
            switch (CustomPermission.CurrentOperatorRole())
            {
                case Role.Viewer:
                    DoSecurity(new Role[] {Role.Operator, Role.Auditor}, "default.aspx");
                    break;
                default:
                    break;
            }
        }
        /// <summary>
        /// Page load event handler (thrown by page master)
        /// </summary>
        protected override void Event_PageLoad(object sender, System.EventArgs e)
        {
            if (Page.IsPostBack)
            {
                m = (MediumDetails)this.ViewState["Medium"];
            }
            else if (Request.QueryString["serialNo"] == null)
            {
                Response.Redirect("../default.aspx", false);
            }
            else if ((m = Medium.GetMedium((string)Request.QueryString["serialNo"])) == null)
            {
                Response.Redirect("../default.aspx", false);
            }
            else
            {
                SendListDetails sendList = null;
                ReceiveListDetails receiveList = null;
                this.ViewState["Medium"] = m;
                // Page header
                this.lblPageHeader.Text = "Medium Detail (" + m.SerialNo + ")";
                // Fill the labels
                this.lblAccount.Text = m.Account;
                this.lblCaseNo.Text = m.CaseName;
                this.lblLocation.Text = m.Location.ToString();
                this.lblMediumType.Text = m.MediumType;
                this.lblMissing.Text = m.Missing ? "Yes" : "No";
                this.lblNotes.Text = this.WordWrap(m.Notes, 85);
                this.lblReturnDate.Text = m.Location != Locations.Vault ? "N/A" : DisplayDate(m.ReturnDate, false, false);
                this.lblSerialNo.Text = m.SerialNo;
                // Get the list information
                switch (m.Location)
                {
                    case Locations.Enterprise:
                        sendList = SendList.GetSendListByMedium(m.SerialNo, false);
                        this.lblListName.Text = sendList != null ? sendList.Name : "None";
                        this.lblListStatus.Text = sendList != null ? ListStatus.ToUpper(sendList.Status) : "N/A";
                        if (sendList != null)
                            this.listAnchor.HRef = String.Format("{0}/lists/shipping-list-detail.aspx?listNumber={1}", HttpRuntime.AppDomainAppVirtualPath, sendList.Name);
                        break;
                    case Locations.Vault:
                        receiveList = ReceiveList.GetReceiveListByMedium(m.SerialNo, false);
                        this.lblListName.Text = receiveList != null ? receiveList.Name : "None";
                        this.lblListStatus.Text = receiveList != null ? ListStatus.ToUpper(receiveList.Status) : "N/A";
                        if (receiveList != null)
                            this.listAnchor.HRef = String.Format("{0}/lists/receiving-list-detail.aspx?listNumber={1}", HttpRuntime.AppDomainAppVirtualPath, receiveList.Name);
                        break;
                }
                // Get the audit information
                AuditTrailCollection auditTrail = new AuditTrailCollection();
                auditTrail.Add(AuditTrail.GetMediumTrail(m.SerialNo));
                this.DataGrid1.DataSource = auditTrail;
                this.DataGrid1.DataBind();
                // If we're coming from find-media.aspx, save the filter for when we go back
                if (Context.Handler is find_media)
                {
                    this.ViewState["SearchFilter"] = ((find_media)Context.Handler).SearchFilter;
                    this.ViewState["BrowsePage"] = ((find_media)Context.Handler).PageNo;
                }
            }
        }
        /// <summary>
        /// Browse link click event handler.  Transfer to the find-media page so that we can reuse
        /// the search filter.
        /// </summary>
        private void LinkBrowse_Click(object sender, System.EventArgs e)
        {
            Server.Transfer("find-media.aspx");        
        }
        /// <summary>
        /// Print function to be called asynchronously
        /// </summary>
        private void printLink_Click(object sender, System.EventArgs e)
        {
            Session[CacheKeys.PrintSource] = PrintSources.MediumDetailPage;
            Session[CacheKeys.WaitRequest] = RequestTypes.PrintMediumDetail;
            Session[CacheKeys.PrintObjects] = new object[] {m, lblListName.Text, lblListStatus.Text};
            ClientScript.RegisterStartupScript(GetType(), "printWindow", "<script>openBrowser('../waitPage.aspx?redirectPage=print.aspx&x=" + Guid.NewGuid().ToString("N") + "&s=" + m.SerialNo + "')</script>");
        }
    }
}
