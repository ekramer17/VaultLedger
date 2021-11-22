using System;
using System.Web;
using System.Text;
using System.Threading;
using System.Web.Security;
using System.Web.UI.WebControls;
using System.Web.UI.HtmlControls;
using Bandl.Library.VaultLedger.BLL;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.Collections;
using Bandl.Library.VaultLedger.Security;

namespace Bandl.VaultLedger.Web.UI
{
	/// <summary>
	/// Summary description for user_detail.
	/// </summary>
	public class user_detail : BasePage
	{
		private OperatorDetails pageOperator;
        private bool currentOperator = false;
        private string samePwd = "f6HeTk";
		protected System.Web.UI.WebControls.DropDownList ddlRole;
		protected System.Web.UI.WebControls.TextBox txtName;
		protected System.Web.UI.WebControls.TextBox txtLogin;
		protected System.Web.UI.WebControls.TextBox txtPhoneNo;
		protected System.Web.UI.WebControls.TextBox txtEmail;
		protected System.Web.UI.WebControls.TextBox txtNotes;
        protected System.Web.UI.WebControls.TextBox txtPassword1;
        protected System.Web.UI.WebControls.TextBox txtPassword2;
        protected System.Web.UI.WebControls.Label lblName;
        protected System.Web.UI.WebControls.Label lblRole;
        protected System.Web.UI.WebControls.Label lblLogin;
        protected System.Web.UI.WebControls.Label lblPhoneNo;
        protected System.Web.UI.WebControls.Label lblEmail;
        protected System.Web.UI.WebControls.PlaceHolder PlaceHolder1;
        protected System.Web.UI.HtmlControls.HtmlInputButton btnDelete;
        protected System.Web.UI.HtmlControls.HtmlInputButton btnOK;
        protected System.Web.UI.HtmlControls.HtmlInputButton btnYes;
        protected System.Web.UI.HtmlControls.HtmlInputButton btnNo;
        protected System.Web.UI.WebControls.RequiredFieldValidator rfvName;
        protected System.Web.UI.WebControls.RequiredFieldValidator rfvLogin;
        protected System.Web.UI.WebControls.RegularExpressionValidator revRole;
        protected System.Web.UI.WebControls.Label lblPwdError;
        protected System.Web.UI.WebControls.LinkButton printLink;
        protected System.Web.UI.HtmlControls.HtmlInputButton btnCancel;
        protected System.Web.UI.WebControls.Label lastLogin;
        protected System.Web.UI.HtmlControls.HtmlTableRow lastLogSpacer;
        protected System.Web.UI.HtmlControls.HtmlTableRow lastLogRow;
        protected System.Web.UI.HtmlControls.HtmlTableRow passwordRow1;
        protected System.Web.UI.HtmlControls.HtmlTableRow passwordRow2;
		protected System.Web.UI.WebControls.Panel Panel1;
		protected System.Web.UI.WebControls.DataGrid GridView3;
		protected System.Web.UI.WebControls.Panel GridWrapper3;
		protected System.Web.UI.WebControls.Panel Panel3_Header;
		protected System.Web.UI.WebControls.Panel Panel3_Content;
		protected System.Web.UI.WebControls.Panel Panel3_Wrapper;
        protected System.Web.UI.HtmlControls.HtmlInputButton btnSave;
        protected System.Web.UI.HtmlControls.HtmlGenericControl contentBorderTop;
		protected System.Web.UI.WebControls.Panel Panel3_None;
	
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
            this.printLink.Click += new System.EventHandler(this.printLink_Click);
            this.btnDelete.ServerClick += new System.EventHandler(this.btnDelete_Click);
            this.btnSave.ServerClick += new System.EventHandler(this.btnSave_ServerClick);
            this.btnCancel.ServerClick += new System.EventHandler(this.btnCancel_ServerClick);
            this.btnOK.ServerClick += new System.EventHandler(this.btnOK_Click);
            this.btnYes.ServerClick += new System.EventHandler(this.btnYes_Click);

        }
        #endregion

        #region Base Page Events
        /// <summary>
        /// Page initialization event handler (thrown by page master)
        /// </summary>
        protected override void Event_PageInit(object sender, System.EventArgs e)
        {
            this.helpId = 28;
            this.levelTwo = LevelTwoNav.Users;
            this.pageTitle = "User Detail";
            // Click events for message box buttons
            this.SetControlAttr(btnOK, "onclick", "hideMsgBox('msgBoxSave');");
            this.SetControlAttr(btnYes, "onclick", "hideMsgBox('msgBoxDelete');");
            this.SetControlAttr(btnNo, "onclick", "hideMsgBox('msgBoxDelete');");
			this.SetControlAttr(ddlRole, "onchange", "onRoleChange(this);");
        }
        /// <summary>
        /// Page load event handler (thrown by page master)
        /// </summary>
        protected override void Event_PageLoad(object sender, System.EventArgs e)
        {
            if (Page.IsPostBack)
            {
                // Get current operator status
                this.currentOperator = (bool)this.ViewState["CurrentOperator"];
                // Get original operator
                if (this.ViewState["Operator"] != null)
                {
                    pageOperator = (OperatorDetails)this.ViewState["Operator"];
                }
            }
            else
            {
                // Retrieve the user from the database.  If it cannot be found,
                // redirect to the user browse page.
                if (this.Request.QueryString["login"] != null)
                {
                    if ((pageOperator = Operator.GetOperator(this.Request.QueryString["login"])) == null)
                    {
                        throw new ApplicationException("User '" + this.Request.QueryString["login"] + "' not found");
                    }
                    else
                    {
                        this.ViewState["Operator"] = pageOperator;
                    }
                }
                // Populate the role dropdown
                foreach (string roleName in Enum.GetNames(typeof(Role)))
                {
                    if (roleName != "VaultOps")
                    {
                        this.ddlRole.Items.Add(new ListItem(roleName, roleName));
                    }
                    else
                    {
                        ; //this.ddlRole.Items.Add(new ListItem("Vault Operator", roleName));
                    }
                }
                // If the user is null or the current user, then hide the delete button
                if (pageOperator == null)
                {
                    this.btnDelete.Visible = false;
					GetAccounts((int)Role.Viewer);
                }
                else if (pageOperator.Login == Thread.CurrentPrincipal.Identity.Name)
                {
                    this.btnDelete.Visible = false;
                    this.currentOperator = true;
                }
                // Place current operator status in the viewstate
                this.ViewState["CurrentOperator"] = this.currentOperator;
                // Fill the fields
                if (pageOperator != null)
                {
                    this.txtName.Text = pageOperator.Name;
                    this.lblName.Text = pageOperator.Name;
                    this.ddlRole.SelectedValue = pageOperator.Role;
                    this.lblRole.Text = pageOperator.Role != "VaultOps" ? pageOperator.Role : "Vaulter";
                    this.txtLogin.Text = pageOperator.Login;
                    this.lblLogin.Text = pageOperator.Login;
                    this.txtPhoneNo.Text = pageOperator.PhoneNo;
                    this.lblPhoneNo.Text = pageOperator.PhoneNo;
                    this.txtEmail.Text = pageOperator.Email;
                    this.lblEmail.Text = pageOperator.Email;
                    this.txtNotes.Text = pageOperator.Notes;
                    if (pageOperator.LastLogin.Year > 2000) lastLogin.Text = Time.UtcToLocal(pageOperator.LastLogin).ToString("F");
                    // We have to use a startup script because password fields won't initialize by setting text
                    ClientScript.RegisterStartupScript(GetType(), "Pwd1", "<script language=javascript>getObjectById('txtPassword1').value = '" + samePwd + "'</script>");
                    ClientScript.RegisterStartupScript(GetType(), "Pwd2", "<script language=javascript>getObjectById('txtPassword2').value = '" + samePwd + "'</script>");
					// Get accounts
					GetAccounts((int)((Role)Enum.Parse(typeof(Role), pageOperator.Role)));
				}
                else
                {
                    this.lastLogSpacer.Visible = false;
                    this.lastLogRow.Visible = false;
                }
            }
            // Set the save button as the default
            this.SetDefaultButton(this.contentBorderTop, "btnSave");
        }
        /// <summary>
        /// Page prerender event handler (thrown by page master)
        /// </summary>
        protected override void Event_PagePreRender(object sender, System.EventArgs e)
        {
            // Hide the role dropdown if message box is displayed
            this.ddlRole.Visible = !ClientScript.IsStartupScriptRegistered("msgBoxSave") && !ClientScript.IsStartupScriptRegistered("msgBoxDelete");
            // If we are an administrator, all the text fields should be visible.
            if (!Page.IsPostBack)
            {
                if (CustomPermission.CurrentOperatorRole() == Role.Administrator)
                {
                    this.lblName.Visible = false;
                    this.lblRole.Visible = false;
                    this.lblLogin.Visible = false;
                    this.lblPhoneNo.Visible = false;
                    this.lblEmail.Visible = false;
                }
                else if (this.currentOperator == false)
                {
                    Response.Redirect("../default.aspx", false);
                }
                else
                {
                    this.txtName.Visible = false;
                    this.ddlRole.Visible = false;
                    this.txtLogin.Visible = false;
                    this.txtPhoneNo.Visible = false;
                    this.txtEmail.Visible = false;
                    this.txtNotes.Visible = false;
                }
            }
            // If Recall and router and page operator is not null, we should disable the password and login fields
            if (pageOperator != null && Configurator.ProductType == "RECALL" && Configurator.Router && CustomPermission.CurrentOperatorRole() != Role.Administrator)
            {
                this.lblLogin.Visible = true;
                this.txtLogin.Visible = false;
                this.passwordRow1.Visible = false;
                this.passwordRow2.Visible = false;
            }
            // Links
            if (CustomPermission.CurrentOperatorRole() != Role.Administrator)
            {
                ClientScript.RegisterStartupScript(GetType(), "linkDisabler", "<script language='javascript'>disableTopLinks();</script>");
            }
        }

        #endregion
        
        /// <summary>
        /// Modifies an existing user
        /// </summary>
        private void ModifyExistingUser()
        {
            pageOperator.Name = this.txtName.Text;
            pageOperator.Role = this.ddlRole.SelectedValue;
            pageOperator.Login = this.txtLogin.Text;
            pageOperator.PhoneNo = this.txtPhoneNo.Text;
            pageOperator.Email = this.txtEmail.Text;
            pageOperator.Notes = this.txtNotes.Text;
            if (this.txtPassword1.Text != samePwd)
            {
                pageOperator.Password = this.txtPassword1.Text;
            }
            // Update operator
            Operator.Update(ref pageOperator);
            // If we just changed the current operator, then the login
            // and greeting may need to be changed, along with
            // the forms authentication cookie.
            if (this.currentOperator == true)
            {
                Global.SetCookie(pageOperator.Login, pageOperator.Role, (String)Context.Items[CacheKeys.DateMask], (String)Context.Items[CacheKeys.TimeMask]);
            }
        }
        /// <summary>
        /// Creates a new user
        /// </summary>
        private int CreateNewUser()
        {
            // Insert the user
            OperatorDetails o = new OperatorDetails(this.txtLogin.Text, this.txtPassword1.Text,
                this.txtName.Text, this.ddlRole.SelectedValue, this.txtPhoneNo.Text, 
                this.txtEmail.Text, this.txtNotes.Text);
            Operator.Insert(ref o);
			return o.Id;
        }
        /// <summary>
        /// Event handler for the delete button
        /// </summary>
        private void btnDelete_Click(object sender, System.EventArgs e)
        {
            this.ShowMessageBox("msgBoxDelete");
        }
        /// <summary>
        /// Delete button event handler
        /// </summary>
		private void btnYes_Click(object sender, System.EventArgs e)
		{
			try
			{
				Operator.Delete(ref pageOperator);
				Response.Redirect("security.aspx", false);
			}
			catch (Exception ex)
			{
                this.DisplayErrors(this.PlaceHolder1, ex.Message);
            }
		}
        /// <summary>
        /// Event handler for message box OK button after non-administrator update
        /// </summary>
        private void btnOK_Click(object sender, System.EventArgs e)
        {
            Response.Redirect("../default.aspx", false);
        }
        /// <summary>
        /// Event handler for cancel button
        /// </summary>
        private void btnCancel_ServerClick(object sender, System.EventArgs e)
        {
            if (CustomPermission.CurrentOperatorRole() == Role.Administrator)
                Server.Transfer("security.aspx");
            else
                Server.Transfer("../default.aspx");
        }
        /// <summary>
        /// Print function to be called asynchronously
        /// </summary>
        private void printLink_Click(object sender, System.EventArgs e)
        {
            Session[CacheKeys.PrintSource] = PrintSources.UserDetailPage;
            Session[CacheKeys.PrintObjects] = new object[] {this.pageOperator};
            ClientScript.RegisterStartupScript(GetType(), "printWindow", "<script>openBrowser('../waitPage.aspx?redirectPage=print.aspx&x=" + Guid.NewGuid().ToString("N") + "')</script>");
        }

        protected void GetAccounts(int role)
        {
            string style = "checkbox";
            AccountCollection x1 = null;
            AccountCollection x2 = new AccountCollection();

            // Get
            if (pageOperator == null)	// new user
            {
                x1 = Account.GetAccounts(false);
            }
            else if (this.currentOperator)	// current user
            {
                style += " invisible";
                x1 = Account.GetAccounts(true);
            }
            else
            {
                x1 = Account.GetAccounts(false);
                
                if (role == (int)Role.Administrator)
                {
                    style += " invisible";
                }
                else
                {
                    x2 = Operator.GetAccounts(pageOperator.Id);
                }
            }
            // Set styles
            GridView3.Columns[0].ItemStyle.CssClass = style;
            GridView3.Columns[0].HeaderStyle.CssClass = style;
            // Display
            if (x1.Count != 0)
            {
                this.GridView3.DataSource = x1;
                this.GridView3.DataBind();
                // Initialize checked state
                foreach (DataGridItem r1 in GridView3.Items)
                {
					if (r1.ItemType == ListItemType.Item || r1.ItemType == ListItemType.AlternatingItem)
                    {
                        if (role == (Int32)Role.Administrator)
                        {
                            ((HtmlInputCheckBox)r1.Cells[0].Controls[1]).Checked = true;
                        }
                        else if (CustomPermission.CurrentOperatorRole() == Role.Administrator)  // only administrators assign accounts to users
                        {
							Int32 i1 = Int32.Parse(r1.Cells[1].Text);

							foreach (AccountDetails m2 in x2)
							{
								if (i1 == m2.Id)
								{
									((HtmlInputCheckBox)r1.Cells[0].Controls[1]).Checked = true;
									break;
								}
							}
                        }
                    }
                }
            }
            else
            {
                this.Panel3_None.Visible = true;
				this.GridView3.Visible = false;
            }
        }

        private void btnSave_ServerClick(object sender, System.EventArgs e)
        {
            Int32 id = -1;
            // If we have an operator in the page operator field, then we are
            // updating an existing user.  Otherwise we are creating a new user.
            try
            {
                if (pageOperator != null)
                {
                    id = pageOperator.Id;
                    this.ModifyExistingUser();
                }
                else
                {
                    id = this.CreateNewUser();
                }
                // Redirect to the browse page if an administrator.  Otherwise display the message box.
                if (CustomPermission.CurrentOperatorRole() == Role.Administrator)
                {
                    // Update the account permissions
                    if (this.ddlRole.SelectedValue != "Administrator")
                    {
                        String s1 = String.Empty;
                        // Get the account id values
                        foreach (DataGridItem r1 in GridView3.Items)
                        {
                            if (r1.ItemType == ListItemType.Item || r1.ItemType == ListItemType.AlternatingItem)
                                if (((HtmlInputCheckBox)r1.Cells[0].Controls[1]).Checked)
                                    s1 += r1.Cells[1].Text + ",";
                        }
                        // Perform update
                        if (s1.Length != 0)
                        {
                            Operator.SetAccounts(id, s1.Substring(0, s1.Length - 1));
                        }
                    }
                    // Redirect
                    DoNavigate("security.aspx");
                }
                else
                {
                    this.ShowMessageBox("msgBoxSave");
                }
            }
            catch (Exception ex)
            {
                this.DisplayErrors(this.PlaceHolder1, ex.Message);
            }
        }
    }
}
