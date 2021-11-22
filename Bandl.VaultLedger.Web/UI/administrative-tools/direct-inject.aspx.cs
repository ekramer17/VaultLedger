using System;
using System.Text;
using System.Collections;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Web;
using System.Web.SessionState;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Web.UI.HtmlControls;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.BLL;
using Bandl.Library.VaultLedger.Security;

namespace Bandl.VaultLedger.Web.UI
{
	/// <summary>
	/// Summary description for direct_inject
	/// </summary>
	public class direct_inject : BasePage
	{
        protected System.Web.UI.WebControls.PlaceHolder PlaceHolder1;
        protected System.Web.UI.HtmlControls.HtmlInputFile File1;
        protected System.Web.UI.HtmlControls.HtmlInputButton btnOK;
        protected System.Web.UI.WebControls.TextBox txtResults;
        protected System.Web.UI.HtmlControls.HtmlGenericControl resultSet;
        protected System.Web.UI.WebControls.TextBox txtQuery;
		protected System.Web.UI.WebControls.TextBox txtLogin;
		protected System.Web.UI.WebControls.TextBox txtPassword;
        protected System.Web.UI.WebControls.Button btnExecute;
    
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
			this.btnExecute.Click += new System.EventHandler(this.btnExecute_Click);

		}
		#endregion

        /// <summary>
        /// Page load event handler (thrown by page master)
        /// </summary>
        protected override void Event_PageLoad(object sender, System.EventArgs e)
        {
            // Click events for message box buttons
            this.SetControlAttr(this.btnOK,  "onclick", "hideMsgBox('msgBoxOK');");
            // Security permission only for administrators.  If we are one,
            // go ahead and set up the page.
            DoSecurity(Role.Administrator, "default.aspx");
        }

        /// <summary>
        /// Page prerender event handler (thrown by page master)
        /// </summary>
        protected override void Event_PagePreRender(object sender, System.EventArgs e)
        {
            this.SetControlAttr(this.resultSet, "style", String.Format("display:{0}", txtResults.Text.Length != 0 ? "block" : "none"), false);
        }

        private void btnExecute_Click(object sender, System.EventArgs e)
        {            
            HttpPostedFile postedFile;
			string uid = this.txtLogin.Text;
			string pwd = this.txtPassword.Text;
			string commandText = String.Empty;



//            string uid = String.Empty;
//            string pwd = this.txtOwner.Text;
//            string commandText = String.Empty;
//            // Make sure the guardian password is correct
//            byte[] byteGuard = {115, 110, 49, 99, 107, 51, 114, 115};
//            if (this.txtGuardian.Text != Encoding.UTF8.GetString(byteGuard))
//            {
//                this.DisplayErrors(this.PlaceHolder1, "Guardian password is incorrect");
//                return;
//            }
//            else
//            {
//                // Get the dbo user id based on product type
//                switch (Configurator.ProductType)
//                {
//                    case "RECALL":
//                        uid = "RMMUpdater";
//                        break;
//                    case "B&L":
//                    case "BANDL":
//                    case "IMATION":
//                        uid = "BLUpdater";
//                        break;
//                    default:
//                        this.DisplayErrors(this.PlaceHolder1, "Sql inject not supported for product type");
//                        return;
//                }
//            }
            // Get the command text
            if (this.txtQuery.Text.Length != 0)
            {
                if (this.txtQuery.Text.ToUpper().StartsWith("SELECT ") == false)
                {
                    this.DisplayErrors(this.PlaceHolder1, "Single line query must start with 'select' keyword"); 
                    return;
                }
                else
                {
                    commandText = this.txtQuery.Text;
                }
            }
            else if ((postedFile = File1.PostedFile) == null || postedFile.ContentLength == 0)
            {
                this.DisplayErrors(this.PlaceHolder1, "Unable to find or access '" + commandText + "'"); 
                return;
            }
            else
            {
                try
                {
                    byte[] byteStream  = new byte[postedFile.ContentLength];
                    postedFile.InputStream.Read(byteStream, 0, postedFile.ContentLength);
                    commandText = Encoding.UTF8.GetString(byteStream).Replace("GOTO", " GOTO");
                }
                catch (Exception ex)
                {
                    this.DisplayErrors(this.PlaceHolder1, ex.Message);
                    return;
                }
            }

            try
            {
                // Confirm the connection and execute the script
                if (Database.ConfirmConnection(uid, pwd) != String.Empty)
                {
                    this.DisplayErrors(this.PlaceHolder1, "Update or query failed.  Unable to connect.");
                }
                else
                {
                    try
                    {
                        if (commandText.ToUpper().StartsWith("SELECT "))
                        {
                            this.txtResults.Text = Database.Query(uid, pwd, commandText);
                        }
                        else
                        {
                            this.txtResults.Text = String.Empty;
                            Database.Update(uid, pwd, commandText);
                            this.ShowMessageBox("msgBoxOK");
                        }
                    }
                    catch (Exception ex)
                    {
                        this.DisplayErrors(this.PlaceHolder1, ex.Message);
                    }
                }
            }
            catch (Exception ex)
            {
                this.DisplayErrors(this.PlaceHolder1, ex.Message);
            }
        }
    }
}
