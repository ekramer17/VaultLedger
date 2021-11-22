using System;
using System.Collections;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Web;
using System.Web.Caching;
using System.Web.SessionState;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Web.UI.HtmlControls;
using System.Text.RegularExpressions;
using Bandl.Utility.VaultLedger.Registrar.Model;

namespace Bandl.Utility.VaultLedger.Registrar.UI
{
	/// <summary>
	/// Summary description for pageTwo.
	/// </summary>
	public class pageTwo : masterPage
	{
        protected System.Web.UI.WebControls.TextBox txtContact;
        protected System.Web.UI.WebControls.TextBox txtPhone;
        protected System.Web.UI.WebControls.TextBox txtEmail;
        protected System.Web.UI.HtmlControls.HtmlInputButton btnBack;
        protected System.Web.UI.WebControls.Button btnNext;
        protected System.Web.UI.WebControls.Button btnRetry;
        protected System.Web.UI.WebControls.RequiredFieldValidator rfvContact;
        protected System.Web.UI.WebControls.RequiredFieldValidator rfvEmail;
        protected System.Web.UI.WebControls.CustomValidator cvEmail;
        protected System.Web.UI.HtmlControls.HtmlForm Form1;
        protected System.Web.UI.WebControls.CustomValidator cvPhone;
        private bool oneClick = false;
    
        protected override void Event_PageLoad(object sender, System.EventArgs e) 
        {
            if (!this.IsPostBack)
            {
                OwnerDetails o = (OwnerDetails)Session[CacheKeys.Owner];
                // If the owner has been lost, go back to pageOne
                if (o == null)
                {
                    Response.Redirect("pageOne.aspx", true);
                }
                else
                {
                    // Since email is a required field, we know that if
                    // we have an email address in the newOwner object
                    // then we can populate the text boxes.
                    if (o.Email != String.Empty)
                    {
                        this.txtContact.Text = o.Contact;
                        this.txtPhone.Text = o.PhoneNo;
                        this.txtEmail.Text = o.Email;
                    }
                }
            }
            // Set the focus
            SetFocus(this.txtContact);
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
            this.cvEmail.ServerValidate += new System.Web.UI.WebControls.ServerValidateEventHandler(this.cvEmail_ServerValidate);
            this.cvPhone.ServerValidate += new System.Web.UI.WebControls.ServerValidateEventHandler(this.cvPhone_ServerValidate);
            this.btnBack.ServerClick += new System.EventHandler(this.btnBack_ServerClick);
            this.btnNext.Click += new System.EventHandler(this.btnNext_Click);
        }
		#endregion

        private void btnBack_ServerClick(object sender, System.EventArgs e)
        {
            Response.Redirect("pageOne.aspx");
        }

        private void btnNext_Click(object sender, System.EventArgs e)
        {
            if (Page.IsValid && !oneClick)
            {
                // Set the click flag
                oneClick = true;
                // Modify the object in the cache
                OwnerDetails o = (OwnerDetails)Session[CacheKeys.Owner];
                o.Contact = this.txtContact.Text;
                o.PhoneNo = this.txtPhone.Text;
                o.Email = this.txtEmail.Text;
                // Overwrite the object in the cache
                Session[CacheKeys.Owner] = o;
                // Redirect or register
                if (Configurator.AllowDownload)
                    Response.Redirect("pageThree.aspx");
                else
                    this.Register(o);
            }
        }

        #region Validation Routines

        private void cvEmail_ServerValidate(object source, System.Web.UI.WebControls.ServerValidateEventArgs args)
        {
            // Initialize
            args.IsValid = true;
            // Text for valid Recall account
            if (this.txtEmail.Text.Trim() == String.Empty)
            {
                cvEmail.ErrorMessage = " Entry required";
                args.IsValid = false;
            }
            else if (new Regex(@"^([a-zA-Z0-9_\-\.]+)@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.)|(([a-zA-Z0-9\-]+\.)+))([a-zA-Z]{2,4}|[0-9]{1,3})(\]?)$").IsMatch(this.txtEmail.Text) == false)
            {
                cvEmail.ErrorMessage = " Invalid email address";
                args.IsValid = false;
            }
        }

        private void cvPhone_ServerValidate(object source, System.Web.UI.WebControls.ServerValidateEventArgs args)
        {
            args.IsValid = true;
            string phoneNo = this.txtPhone.Text;
            // Empty phone number is allowed.  Otherwise, check its validity.
            if (phoneNo != String.Empty)
            {
                if (false == new Regex(@"[0-9( )+\-xX\.]*").IsMatch(phoneNo))
                {
                    args.IsValid = false;
                }
                else if (phoneNo[0] != '(' && phoneNo[0] != '+' && (phoneNo[0] < '0' || phoneNo[0] > '9'))
                {
                    args.IsValid = false;    // Must start with left parenthesis, plus symbol, or digit
                }
                else if (phoneNo[phoneNo.Length-1] < '0' || phoneNo[phoneNo.Length-1] > '9')
                {
                    args.IsValid = false;    // Must end with a digit
                }
                else if (phoneNo.Length - phoneNo.Replace("(", "").Length > 2)
                {
                    args.IsValid = false;    // Cannot have more than two sets of parentheses
                }
                else if (phoneNo.Length - phoneNo.Replace("-", "").Length > 2)
                {
                    args.IsValid = false;    // Cannot have more than two hyphens
                }
                else if (phoneNo.Length - phoneNo.Replace(".", "").Length > 2)
                {
                    args.IsValid = false;    // Cannot have more than two periods
                }
                else if (phoneNo.IndexOf("-") != -1 && phoneNo.IndexOf(".") != -1)
                {
                    args.IsValid = false;    // Cannot have both hyphens and periods
                }
                else
                {
                    for(int i = 0; i < phoneNo.Length; i++)
                    {
                        try
                        {
                            switch (phoneNo[i])
                            {
                                case '(':
                                    // 1. Right parenthesis must occur after left
                                    // 2. Value between parentheses must be numeric, positive, and no more than three digits in length
                                    string s = phoneNo.Substring(i + 1, phoneNo.IndexOf(")", i) - i - 1);
                                    if (Convert.ToInt32(s) < 0 || Convert.ToInt32(s) > 999) throw new Exception();
                                    break;
                                case ')':
                                    // A left parenthesis must appear before a right parenthesis
                                    if (phoneNo.IndexOf("(") == -1 || phoneNo.IndexOf("(") > i) throw new Exception();
                                    break;
                                case '+':
                                    // 1. Character after plus must be a digit
                                    // 2. Plus may be either first ot second character.  If second, first must be left parenthesis.
                                    if (phoneNo[i+1] < '0' || phoneNo[i+1] > '9') throw new Exception();
                                    if (i > 1 || (i == 1 && phoneNo[0] != '(')) throw new Exception();
                                    break;
                                case '-':
                                case '.':
                                    // 1. No parenthesis may occur after the first hyphen or period
                                    // 2. Hyphen must have a digit on either side
                                    if (phoneNo.IndexOf("(", i) != -1) throw new Exception();
                                    if (phoneNo[i-1] < '0' || phoneNo[i-1] > '9') throw new Exception();
                                    if (phoneNo[i+1] < '0' || phoneNo[i+1] > '9') throw new Exception();
                                    break;
                                case ' ':
                                    // Whitespace must be followed be left parenthesis or digit
                                    if (phoneNo[i+1] != '(' && (phoneNo[i+1] < '0' || phoneNo[i+1] > '9')) throw new Exception();
                                    break;
                                case 'x':
                                case 'X':
                                    // Only digits may follow an extension character
                                    if (Convert.ToInt32(phoneNo.Substring(i+1)) < 1) throw new Exception();
                                    break;
                                default:
                                    break;
                            }
                        }
                        catch
                        {
                            args.IsValid = false;
                        }
                    }
                }
            }
        }

        #endregion
	}
}
