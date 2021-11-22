using System;
using System.Data;
using System.Web.UI.WebControls;
using Bandl.Library.VaultLedger.BLL;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.Exceptions;
using Bandl.Library.VaultLedger.Collections;
using Bandl.Library.VaultLedger.Security;

namespace Bandl.VaultLedger.Web.UI
{
	/// <summary>
	/// Summary description for case_detail.
	/// </summary>
	public class case_detail : BasePage
	{
        protected System.Web.UI.WebControls.Label lblCaption;
        protected System.Web.UI.WebControls.PlaceHolder PlaceHolder1;
        protected System.Web.UI.WebControls.DataGrid DataGrid1;

        private string caseName = String.Empty;

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
            this.DataGrid1.ItemCommand += new DataGridCommandEventHandler(DataGrid1_ItemCommand);
        }
		#endregion

        /// Page initialization event handler (thrown by page master)
        /// </summary>
        protected override void Event_PageInit(object sender, System.EventArgs e)
        {
            this.helpId = 0;
            this.pageTitle = "Cases";
            this.levelTwo = LevelTwoNav.Cases;
        }
        /// <summary>
        /// Page load event handler (thrown by page master)
        /// </summary>
        protected override void Event_PageLoad(object sender, System.EventArgs e)
        {
            try
            {
                caseName = Request.QueryString["caseName"];
                ObtainItems(Request.QueryString["sealed"] == "1");
                this.lblCaption.Text = caseName;
            }
            catch
            {
                Response.Redirect(@"..\default.aspx", false);
            }
        }
        /// <summary>
        /// Gets the media in the case and binds them to the datagrid
        /// </summary>
        /// <param name="caseSealed">
        /// Whether or not the case is a sealed case
        /// </param>
        private void ObtainItems(bool caseSealed)
        {
            MediumCollection m = null;
            // Get the media within the case
            if (caseSealed == true)
            {
                m = SealedCase.GetResidentMedia(caseName);
            }
            else
            {
                m = SendList.GetCaseMedia(caseName);
            }
            // Bind the collection to the datagrid if we have contents
            if (m.Count != 0)
            {
                // Serial number column depends on role
                if (CustomPermission.CurrentOperatorRole() == Role.Viewer)
                {
                    DataGrid1.Columns[1].Visible = false;
                }
                else
                {
                    DataGrid1.Columns[0].Visible = false;
                }
                // Do binding
                DataGrid1.DataSource = m;
                DataGrid1.DataBind();
            }
            else
            {
                // Make the hyperlink column invisible
                DataGrid1.Columns[1].Visible = false;
                // Add single empty row
                DataTable d = new DataTable();
                d.Columns.Add("SerialNo", typeof(string));
                d.Columns.Add("Location", typeof(string));
                d.Columns.Add("ReturnDate", typeof(string));
                d.Columns.Add("Missing", typeof(bool));
                d.Columns.Add("Account", typeof(string));
                d.Columns.Add("MediumType", typeof(string));
                d.Rows.Add(new object[] {"Case is empty", "", "", false, "", ""});
                DataGrid1.DataSource = d;
                DataGrid1.DataBind();
                // Blank the boolean column
                DataGrid1.Items[0].Cells[3].Text = String.Empty;
            }
        }
        /// <summary>
        /// Event handler used to transfer to media detail page on linkbutton click
        /// </summary>
        private void DataGrid1_ItemCommand(object source, DataGridCommandEventArgs e)
        {
            if (e.CommandSource.GetType() == typeof(LinkButton))
                Server.Transfer("media-detail.aspx?serialNo=" + e.Item.Cells[0].Text);
        }
    }
}
