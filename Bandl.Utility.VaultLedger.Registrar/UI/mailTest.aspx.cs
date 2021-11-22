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
using Bandl.Utility.VaultLedger.Registrar.BLL;
using Bandl.Utility.VaultLedger.Registrar.Model;

namespace Bandl.Utility.VaultLedger.Registrar.UI
{
	/// <summary>
	/// Summary description for mailTest.
	/// </summary>
	public class mailTest : masterPage
	{
        protected System.Web.UI.WebControls.TextBox txtTo;
        protected System.Web.UI.WebControls.RequiredFieldValidator rfvTo;
        protected System.Web.UI.WebControls.TextBox txtBody;
        protected System.Web.UI.HtmlControls.HtmlForm Form1;
        protected System.Web.UI.WebControls.PlaceHolder msgHolder;
        protected System.Web.UI.WebControls.Button btnSend;
    
        /// <summary>
        /// Page load event handler
        /// </summary>
        protected override void Event_PageLoad(object sender, System.EventArgs e) 
        {
            if (!this.IsPostBack)
            {
                txtBody.Text = "This is a test message from the " + Configurator.ProductName + " registrar.";
            }
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
            this.btnSend.Click += new System.EventHandler(this.btnSend_Click);

        }
		#endregion

        private void btnSend_Click(object sender, System.EventArgs e)
        {
            msgHolder.Controls.Clear();
            Label errorLabel = new Label();

            try
            {
                errorLabel.ForeColor = Color.Blue;
                Email.TestMail(txtTo.Text, txtBody.Text);
                errorLabel.Text = "Message was sent successfully.  Check the inbox of " + txtTo.Text + " to verify that the email was received.";
            }
            catch (Exception ex)
            {
                errorLabel.Text = ex.Message;
                errorLabel.ForeColor = Color.Red;
            }
            finally
            {
                msgHolder.Controls.Add(errorLabel);
            }
        }
	}
}
