using System;
using System.Web;
using System.Text;
using System.Threading;
using System.Web.Security;
using System.Web.UI.WebControls;
using Bandl.Library.VaultLedger.BLL;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.Security;

namespace Bandl.VaultLedger.Web.UI
{
	/// <summary>
	/// Summary description for rfid_tag_initialize.
	/// </summary>
	public class rfid_tag_initialize : BasePage
	{
        protected System.Web.UI.WebControls.PlaceHolder PlaceHolder1;
        protected System.Web.UI.WebControls.TextBox txtSerial;
        protected System.Web.UI.WebControls.DropDownList ddlType;
        protected System.Web.UI.WebControls.Label lblMessage;
        protected System.Web.UI.WebControls.DropDownList ddlIncrement;
        protected System.Web.UI.WebControls.Label lblStatus;
        protected System.Web.UI.WebControls.Label lblLastSerial;
        protected System.Web.UI.HtmlControls.HtmlInputHidden maxSerialLength;
        protected System.Web.UI.WebControls.Label lblCurrentSerial;
        protected System.Web.UI.WebControls.Label lblCurrentType;
        protected System.Web.UI.WebControls.Label Label1;
        protected System.Web.UI.WebControls.Label lblLastType;
    
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

        }
		#endregion

        #region BasePage Overloads
        /// <summary>
        /// Page initialization event handler (thrown by page master)
        /// </summary>
        protected override void Event_PageInit(object sender, System.EventArgs e)
        {
            this.helpId = 59;
            this.levelTwo = LevelTwoNav.RFIDInitialize;
            this.pageTitle = "RFID Initialize";
            // Viewers and auditors shouldn't be able to access this page
            DoSecurity(Role.Operator, "default.aspx");
        }
        /// <summary>
        /// Page prerender event handler (thrown by page master)
        /// </summary>
        protected override void Event_PagePreRender(object sender, System.EventArgs e)
        {
            // Set the max serial length variable
            ClientScript.RegisterStartupScript(GetType(), "MAXSERIAL", String.Format("<script>maxSerial={0};</script>", Int32.Parse(Preference.GetPreference(PreferenceKeys.MaxRfidSerialLength).Value)));
            // Format the serial number field
            this.BarCodeFormat(this.txtSerial);
            // Embed the beep
            this.RegisterBeep(false);
        }
        #endregion

	}
}
