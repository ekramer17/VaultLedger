using System;
using System.Web.UI.WebControls;
using System.Web.UI.HtmlControls;
using System.Collections.Specialized;
using Bandl.Library.VaultLedger.BLL;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.Exceptions;
using Bandl.Library.VaultLedger.Collections;
using Bandl.Library.VaultLedger.Security;

namespace Bandl.VaultLedger.Web.UI
{
	/// <summary>
	/// Summary description for medium_types.
	/// </summary>
	public class media_types : BasePage
	{
        MediumTypeCollection typeCollection;
        protected System.Web.UI.WebControls.PlaceHolder PlaceHolder1;
        protected System.Web.UI.WebControls.Button btnDelete;
        protected System.Web.UI.WebControls.Button btnNew;
        protected System.Web.UI.WebControls.DataGrid DataGrid1;
        protected System.Web.UI.WebControls.Button btnYes;
        protected System.Web.UI.HtmlControls.HtmlGenericControl actionTable;
        protected System.Web.UI.WebControls.Button btnNo;

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
            this.btnYes.Click += new System.EventHandler(this.btnYes_Click);

        }
		#endregion

        /// <summary>
        /// Page initialization event handler (thrown by page master)
        /// </summary>
        protected override void Event_PageInit(object sender, System.EventArgs e)
        {
            this.helpId = 48;
            this.pageTitle = "Media Types";
            this.levelTwo = LevelTwoNav.Types;
            // Click events for message box buttons
            this.SetControlAttr(btnYes, "onclick", "hideMsgBox('msgBoxDelete');");
            this.SetControlAttr(btnNo,  "onclick", "hideMsgBox('msgBoxDelete');");
        }
        /// <summary>
        /// Page load event handler (thrown by page master)
        /// </summary>
        protected override void Event_PageLoad(object sender, System.EventArgs e)
        {
            if (!Page.IsPostBack)
            {
                this.FetchMediumTypes();
            }
            else
            {
                typeCollection = (MediumTypeCollection)this.ViewState["Types"];
            }
            // Only an administrator may delete medium types
            if (CustomPermission.CurrentOperatorRole() != Role.Administrator)
                this.DataGrid1.Columns[0].Visible = false;
            // Make the two-sided column invisible; the attribute isn't used
            this.DataGrid1.Columns[DataGrid1.Columns.Count-1].Visible = false;
        }
        /// <summary>
        /// Fetch the media types and bind them to the datagrid
        /// </summary>
        private void FetchMediumTypes()
        {
            typeCollection = MediumType.GetMediumTypes();
            this.ViewState["Types"] = typeCollection;
            // Bind to the datagrid
            this.DataGrid1.DataSource = typeCollection;
            this.DataGrid1.DataBind();
        }
        /// <summary>
        /// Event handler for New User button
        /// </summary>
        private void btnNew_Click(object sender, System.EventArgs e)
        {
            Server.Transfer("media-type-detail.aspx");
        }
        /// <summary>
        /// Event handler for Delete button
        /// </summary>
        private void btnDelete_Click(object sender, System.EventArgs e)
        {
            this.ShowMessageBox("msgBoxDelete");
        }
        /// <summary>
        /// Event handler for Delete Confirmation button
        /// </summary>
        private void btnYes_Click(object sender, System.EventArgs e)
        {
			int i;
            bool doFetch = true;
			StringCollection errorList = new StringCollection();
			StringCollection errorTypes = new StringCollection();
			MediumTypeCollection deleteCollection = new MediumTypeCollection();
            // Delete each of the checked operators
            foreach (DataGridItem item in this.CollectCheckedItems(this.DataGrid1))
				deleteCollection.Add(typeCollection[item.ItemIndex]);
			// Delete the media types
            try
            {
                MediumType.Delete(deleteCollection);
            }
            catch (CollectionErrorException ex)
            {
                foreach (MediumTypeDetails m in (MediumTypeCollection)ex.Collection)
                {
                    if (m.RowError.Length != 0)
                    {
                        errorList.Add(m.RowError);
                        errorTypes.Add(m.Name);
                    }
                }
            }
            catch (Exception ex)
            {
                doFetch = false;
                this.DisplayErrors(this.PlaceHolder1, ex.Message);
            }
            // Refetch the medium types if requested
            if (doFetch == true)
            {
                this.FetchMediumTypes();
                // If no errors then just return
                if (errorList.Count == 0) return;
                // Display errors
                this.DisplayErrors(this.PlaceHolder1, errorList);
                // Check any medium type that had errors
                foreach (string typeName in errorTypes)
                    if ((i = typeCollection.IndexOf(typeName)) != -1)
                        ((HtmlInputCheckBox)DataGrid1.Items[i].Cells[0].Controls[1]).Checked = true;
            }
        }
    }
}
