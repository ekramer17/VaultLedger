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
	/// Summary description for pageTest.
	/// </summary>
	public class pageTest : masterPage
	{
        protected System.Web.UI.HtmlControls.HtmlForm Form1;
        protected System.Web.UI.WebControls.TextBox txtCompany;
        protected System.Web.UI.WebControls.TextBox txtAddress1;
        protected System.Web.UI.WebControls.TextBox txtAddress2;
        protected System.Web.UI.WebControls.TextBox txtCity;
        protected System.Web.UI.WebControls.TextBox txtZipCode;
        protected System.Web.UI.WebControls.TextBox txtCountry;
        protected System.Web.UI.WebControls.TextBox txtAccount;
        protected System.Web.UI.WebControls.Button btnOK;
        protected System.Web.UI.WebControls.Button btnNext;
        protected System.Web.UI.WebControls.RequiredFieldValidator rfvCompany;
        protected System.Web.UI.WebControls.RequiredFieldValidator rfvAddress1;
        protected System.Web.UI.WebControls.RequiredFieldValidator rfvCity;
        protected System.Web.UI.WebControls.RequiredFieldValidator rfvZipCode;
        protected System.Web.UI.WebControls.DropDownList ddlbCountry;
        protected System.Web.UI.WebControls.DropDownList ddlbState;
        protected System.Web.UI.WebControls.CustomValidator cvState;
        protected System.Web.UI.WebControls.RequiredFieldValidator rfvCountry;
        protected System.Web.UI.HtmlControls.HtmlTable Table1;
        protected System.Web.UI.WebControls.CustomValidator cvAccount;
    
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
            this.cvState.ServerValidate += new System.Web.UI.WebControls.ServerValidateEventHandler(this.cvState_ServerValidate);
            this.cvAccount.ServerValidate += new System.Web.UI.WebControls.ServerValidateEventHandler(this.cvAccount_ServerValidate);
            this.btnNext.Click += new System.EventHandler(this.btnNext_Click);

        }
		#endregion

        /// <summary>
        /// Page load event handler
        /// </summary>
        protected override void Event_PageLoad(object sender, System.EventArgs e) 
        {
            OwnerDetails o = null;
            // Get the new owner in the cache if not postback
            if (!this.IsPostBack)
            {
                if (EmptyNull(Request.QueryString["passThru"]) == "1")
                {
                    Server.Transfer("create.aspx?" + Request.QueryString);
                }
                else if ((o = (OwnerDetails)Session[CacheKeys.Owner]) != null)
                {
                    this.txtCompany.Text = o.Company;
                    this.txtAddress1.Text = o.Address1;
                    this.txtAddress2.Text = o.Address2;
                    this.txtCity.Text = o.City;
                    this.ddlbState.SelectedValue = o.State;
                    this.txtZipCode.Text = o.ZipCode;
                    this.ddlbCountry.SelectedValue = o.Country;
                    this.txtAccount.Text = o.AccountNo;
                }
            }
        }
        
        /// <summary>
        /// Page prerender event handler
        /// </summary>
        protected override void Event_PagePreRender(object sender, System.EventArgs e) 
        {
            // If not Recall, remove the account row
            if (Configurator.ProductType != "RECALL")
                Table1.Rows.RemoveAt(Table1.Rows.Count-1);
            // Pad the bottom row
            foreach (HtmlTableCell c in Table1.Rows[Table1.Rows.Count-1].Cells)
                c.Attributes["style"] = "PADDING-BOTTOM:12px";
            // Set the focus
            SetFocus(this.txtCompany);
        }

        private void btnNext_Click(object sender, System.EventArgs e)
        {
            if (Page.IsValid == true)
            {
                OwnerDetails o = (OwnerDetails)Session[CacheKeys.Owner];
                AccountTypes accountType = Configurator.ProductType != "RECALL" ? AccountTypes.Bandl : AccountTypes.Recall;
                // If we have no owner in the cache, create it.  Otherwise, modify
                // the object and overwrite it in the cache.
                if (o == null)
                {
                    o = new OwnerDetails(this.txtCompany.Text, this.txtAddress1.Text,
                        this.txtAddress2.Text, this.txtCity.Text, this.ddlbState.SelectedValue,
                        this.txtZipCode.Text, this.ddlbCountry.SelectedValue, String.Empty,
                        String.Empty, String.Empty, this.txtAccount.Text, accountType);
                }
                else
                {
                    o.Company = this.txtCompany.Text;
                    o.Address1 = this.txtAddress1.Text;
                    o.Address2 = this.txtAddress2.Text;
                    o.City = this.txtCity.Text;
                    o.State = this.ddlbState.SelectedValue;
                    o.ZipCode = this.txtZipCode.Text;
                    o.Country = this.ddlbCountry.SelectedValue;
                    o.AccountNo = this.txtAccount.Text;
                    o.AccountType = accountType;
                }
                // Insert into the cache
                Session[CacheKeys.Owner] = o;
                // Redirect to the next page
                Response.Redirect("pageTwo.aspx");
            }
        }

        #region Validation Methods

        private void cvState_ServerValidate(object source, System.Web.UI.WebControls.ServerValidateEventArgs args)
        {
            // Initialize
            args.IsValid = true;
            // Make sure that the state and the country jive
            if (this.ddlbState.SelectedItem == null)
            {
                cvState.ErrorMessage = "Entry required";
                args.IsValid = false;
            }
            else if (this.ddlbCountry.SelectedItem != null)
            {
                switch (this.ddlbState.SelectedItem.Text)
                {
                    case "Alberta":
                    case "British Columbia":
                    case "Manitoba":
                    case "New Brunswick":
                    case "Newfoundland":
                    case "Nova Scotia":
                    case "Ontario":
                    case "Prince Edward Island":
                    case "Quebec":
                    case "Saskatchewan":
                        if (this.ddlbCountry.SelectedItem.Text == "Canada")
                        {
                            break;
                        }
                        else
                        {
                            cvState.ErrorMessage = " " + this.ddlbState.SelectedItem.Text + " is not a member of the United States";
                            args.IsValid = false;
                            break;
                        }
                    default:
                        if (this.ddlbCountry.SelectedItem.Text == "United States")
                        {
                            break;
                        }
                        else
                        {
                            cvState.ErrorMessage = " " + this.ddlbState.SelectedItem.Text + " is not a Canadian province";
                            args.IsValid = false;
                            break;
                        }
                }
            }
        }

        private void cvAccount_ServerValidate(object source, System.Web.UI.WebControls.ServerValidateEventArgs args)
        {
            // Initialize
            args.IsValid = true;
            // Only perform account check if Recall system
            if (Configurator.ProductType != "RECALL") return;
            // Text for valid Recall account
            if (this.txtAccount.Text.Trim() == String.Empty)
            {
                cvAccount.ErrorMessage = " Entry required";
                args.IsValid = false;
            }
            else if (new Regex("^[A-Z0-9]{4,5}$").IsMatch(this.txtAccount.Text) == false)
            {
                cvAccount.ErrorMessage = " Invalid Recall account number";
                args.IsValid = false;
            }
            else if (AccountFile.FindAccount(this.txtAccount.Text) == false)
            {
                cvAccount.ErrorMessage = " Account could not be confirmed";
                args.IsValid = false;
            }
        }

        #endregion
	}
}
