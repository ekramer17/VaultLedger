using System;
using System.IO;
using System.Data;
using System.Text;
using System.Web.UI.WebControls;
using System.Web.UI.HtmlControls;
using Bandl.Library.VaultLedger.BLL;
using System.Text.RegularExpressions;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.Exceptions;
using Bandl.Library.VaultLedger.Collections;
using Bandl.Library.VaultLedger.Security;
using System.Runtime.Serialization.Formatters.Binary;

namespace Bandl.VaultLedger.Web.UI
{
	/// <summary>
	/// Summary description for bar_code_formats_template.
	/// </summary>
	public class bar_code_formats : BasePage
	{
        protected System.Web.UI.WebControls.DataGrid DataGrid1;
        protected System.Web.UI.WebControls.PlaceHolder PlaceHolder1;
        protected System.Web.UI.WebControls.LinkButton printLink;
        protected System.Web.UI.HtmlControls.HtmlInputButton btnSave;
        protected System.Web.UI.WebControls.DropDownList ddlTypes;
        protected System.Web.UI.WebControls.TextBox txtFormat;
        protected System.Web.UI.WebControls.DropDownList ddlAccounts;
        protected System.Web.UI.WebControls.DropDownList ddlSelectAction;
        protected System.Web.UI.HtmlControls.HtmlInputHidden tableContents;

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
           this.btnSave.ServerClick += new System.EventHandler(this.btnSave_ServerClick);

        }
        #endregion

        /// <summary>
        /// Page initialization event handler (thrown by page master)
        /// </summary>
        protected override void Event_PageInit(object sender, System.EventArgs e)
        {
            this.levelTwo = LevelTwoNav.BarCodeFormats;
            this.pageTitle = "Bar Code Formats";
            this.helpId = 21;
            // Security permission only for administrators.  If we are one,
            // go ahead and set up the page.
            DoSecurity(Role.Administrator, "default.aspx");
        }
        /// <summary>
        /// Page load event handler (thrown by page master)
        /// </summary>
        protected override void Event_PageLoad(object sender, System.EventArgs e)
        {
            if (!Page.IsPostBack)
            {
                // If there is an exception, display it
                if (Session[CacheKeys.Exception] != null)
                {
                    this.DisplayErrors(this.PlaceHolder1, ((Exception)Session[CacheKeys.Exception]).Message);
                    Session.Remove(CacheKeys.Exception);
                }
                // Create string builder to hold the formats
                StringBuilder stringBuilder = new StringBuilder();
                // Get the bar code formats from the database
                foreach (PatternDefaultMediumDetails p in PatternDefaultMedium.GetPatternDefaults())
                    stringBuilder.AppendFormat("{0}`{1}`{2}`0;", p.Pattern, p.MediumType, p.Account);
                // Assign the string to the hidden field
                this.tableContents.Value = stringBuilder.ToString();
                // Initialize the message box dropdowns
                foreach (MediumTypeDetails m in MediumType.GetMediumTypes(false)) ddlTypes.Items.Add(m.Name);
                foreach (AccountDetails a in Account.GetAccounts()) ddlAccounts.Items.Add(a.Name);
                // If new format requested, pop up message box
                if (Request.QueryString["new"] != null && Request.QueryString["new"] == "1")
                    ClientScript.RegisterStartupScript(GetType(), "new", "<script language='javascript'>setTimeout('displayNew()',100);</script>");
            }
            // Set up datagrid so that it has one blank row
            DataTable dataTable = new DataTable();
            dataTable.Columns.Add("Pattern", typeof(string));
            dataTable.Columns.Add("MediumType", typeof(string));
            dataTable.Columns.Add("Account", typeof(string));
            dataTable.Rows.Add(new object[] {String.Empty, String.Empty, String.Empty});
            this.DataGrid1.DataSource = dataTable;
            this.DataGrid1.DataBind();
        }
        /// <summary>
        /// Page prerender event handler (thrown by page master)
        /// </summary>
        protected override void Event_PagePreRender(object sender, System.EventArgs e)
        {
            ClientScript.RegisterStartupScript(GetType(), "renderTable", "<script language='javascript'>renderTable();</script>");
        }
        /// Saves the bar code formats to the database
        /// </summary>
        private void btnSave_ServerClick(object sender, System.EventArgs e)
        {
            // Create a new bar code collection
            PatternDefaultMediumCollection c = new PatternDefaultMediumCollection();
            // Parser the contents of the hidden controls
            string[] barCodes = this.tableContents.Value.Split(new char[] {';'});
            // Insert each bar code into the collection
            for (int i = 0; i < barCodes.Length - 1; i++)
            {
                string[] s = barCodes[i].Split(new char[] {'`'});
                c.Add(new PatternDefaultMediumDetails(s[0], s[2], s[1], String.Empty));
            }
            // Add to the session
            PatternDefaultMedium.Update(ref c);
            // Show message box and play sound
            this.ShowMessageBox("msgBoxSave");
        } 
        /// <summary>
        /// Print function to be called asynchronously
        /// </summary>
        private void printLink_Click(object sender, System.EventArgs e)
        {
            // Construct the collection to print
            PatternDefaultMediumCollection printObject = new PatternDefaultMediumCollection();
            string[] pageFormats = this.tableContents.Value.Split(new char[] {';'});
            for (int i = pageFormats.Length - 2; i > -1; i--)   // Last index will be empty
            {
                string[] fieldValues = pageFormats[i].Split(new char[] {'`'});
                printObject.Insert(0, new PatternDefaultMediumDetails(fieldValues[0], fieldValues[2], fieldValues[1], String.Empty));
            }
            // Assign to print session objects
            Session[CacheKeys.PrintSource] = PrintSources.BarCodeMediumPage;
            Session[CacheKeys.PrintObjects] = new object[] {printObject};
            // Redirect to print page
            ClientScript.RegisterStartupScript(GetType(), "printWindow", "<script>openBrowser('../waitPage.aspx?redirectPage=print.aspx&x=" + Guid.NewGuid().ToString("N") + "')</script>");
        }
   }
}