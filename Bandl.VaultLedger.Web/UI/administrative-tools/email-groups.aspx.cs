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
using Bandl.Library.VaultLedger.Exceptions;
using Bandl.Library.VaultLedger.Collections;
using Bandl.Library.VaultLedger.Security;

namespace Bandl.VaultLedger.Web.UI
{
	/// <summary>
	/// Summary description for email_groups.
	/// </summary>
	public class email_groups : BasePage
	{
        private EmailGroupCollection eGroups = null;

        protected System.Web.UI.WebControls.PlaceHolder PlaceHolder1;
        protected System.Web.UI.WebControls.Button btnDelete;
        protected System.Web.UI.WebControls.Button btnNew;
        protected System.Web.UI.WebControls.Button btnYes;
        protected System.Web.UI.WebControls.Button btnNo;
        protected System.Web.UI.WebControls.Button btnEmail;
        protected System.Web.UI.WebControls.DataGrid DataGrid1;

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
            this.btnDelete.Click += new System.EventHandler(this.btnDelete_Click);
            this.btnNew.Click += new System.EventHandler(this.btnNew_Click);
            this.btnEmail.Click += new System.EventHandler(this.btnEmail_Click);
            this.btnYes.Click += new System.EventHandler(this.btnYes_Click);

        }
		#endregion

        #region BasePage Events
        /// <summary>
        /// Page initialization event handler (thrown by page master)
        /// </summary>
        protected override void Event_PageInit(object sender, System.EventArgs e)
        {
            this.helpId = 56;
            this.levelTwo = LevelTwoNav.EmailGroups;
            this.pageTitle = "Email Groups";
            // Click events for message box buttons
            this.SetControlAttr(btnYes, "onclick", "hideMsgBox('msgBoxDel');");
            this.SetControlAttr(btnNo,  "onclick", "hideMsgBox('msgBoxDel');");
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
                eGroups = (EmailGroupCollection)this.ViewState["EmailGroups"];
            }
            else
            {
                try
                {
                    this.ObtainGroups();
                }
                catch
                {
                    Response.Redirect("default.aspx", false);
                }
            }
        }
        /// <summary>
        /// Page load event handler (thrown by page master)
        /// </summary>
        protected override void Event_PagePreRender(object sender, System.EventArgs e)
        {
            this.btnEmail.Visible = !Configurator.Router;
        }
        #endregion
        
        /// <summary>
        /// Obtains and binds data to the datagrid
        /// </summary>
        private void ObtainGroups()
        {
            // Reset the datagrid
            DataTable dataTable = new DataTable();
            // Create data table
            dataTable.Columns.Add("Name", typeof(string));
            dataTable.Columns.Add("Operators", typeof(string));
            // Retrieve the email groups
            eGroups = EmailGroup.GetEmailGroups();
            this.ViewState["EmailGroups"] = eGroups;
            // If no groups, create dummy row
            if (eGroups.Count == 0)
            {
                dataTable.Rows.Add(new object[] {String.Empty, String.Empty});
                DataGrid1.Columns[0].Visible = false;
            }
            else
            {
                foreach (EmailGroupDetails e in eGroups)
                {
                    string operatorNames = String.Empty;
                    // Consolidate the operators into a string
                    foreach (OperatorDetails o in EmailGroup.GetOperators(e))
                        if (o.Email.Length != 0)
                            operatorNames += String.Format("{0}{1} ({2})", operatorNames.Length != 0 ? ", " : String.Empty, o.Name, o.Email);
                    // Add the row
                    dataTable.Rows.Add(new object[] {e.Name, operatorNames});
                }
            }
            // Bind table to grid
            this.DataGrid1.DataSource = dataTable;
            this.DataGrid1.DataBind();
            // If no groups, put a text message in the second cell of the firrt row
            if (eGroups.Count == 0)
                this.DataGrid1.Items[0].Cells[1].Text = "No groups defined";
        }
        /// <summary>
        /// Shows confirmation text box
        /// </summary>
        private void btnDelete_Click(object sender, System.EventArgs e)
        {
            if (this.CollectCheckedItems(this.DataGrid1).Length != 0)
            {
                this.ShowMessageBox("msgBoxDel");
            }
        }
        /// <summary>
        /// Deletes email groups from the database
        /// </summary>
        private void btnYes_Click(object sender, System.EventArgs e)
        {
            EmailGroupCollection deleteThese = new EmailGroupCollection();
            // Get the email groups
            foreach (DataGridItem i in this.CollectCheckedItems(DataGrid1))
                deleteThese.Add(eGroups[i.ItemIndex]);
            // Delete the groups
            try
            {
                EmailGroup.Delete(deleteThese);
                this.ObtainGroups();
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
        /// Transfers control to group detail page to create a new group
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="e"></param>
        private void btnNew_Click(object sender, System.EventArgs e)
        {
            Server.Transfer("email-group-detail.aspx");
        }
        /// <summary>
        /// Send user to the email server configuration page
        /// </summary>
        private void btnEmail_Click(object sender, System.EventArgs e)
        {
            Response.Redirect("email-configure.aspx");        
        }
    }
}
