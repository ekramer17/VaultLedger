using System;
using System.IO;
using System.Web;
using System.Text;
using System.Web.UI;
using System.Drawing;
using System.Web.UI.WebControls;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.BLL;
using Bandl.Library.VaultLedger.Security;
using Bandl.Library.VaultLedger.Collections;
using Bandl.Library.VaultLedger.Exceptions;

namespace Bandl.VaultLedger.Web.UI
{
	/// <summary>
	/// Summary description for find_media_template.
	/// </summary>
    public class find_media : BasePage
    {
        // Enumerations
        private enum NotesColumn {Narrow = 0, Wide = 1}
        // Private fields
        private int pageNo = 1;
        private int pageTotal = 1;
        private MediumFilter mediumFilter;
        private MediumCollection editCollection;
        private NotesColumn notesColumn = NotesColumn.Narrow;
        private bool scriptFlag = false;
        // Public properties
        public int PageNo {get {return pageNo;}}
        public MediumFilter SearchFilter {get {return mediumFilter;}}
        public MediumCollection EditCollection {get {return editCollection;}}
        // Controls
        protected System.Web.UI.WebControls.TextBox txtEndSerialNum;
        protected System.Web.UI.WebControls.DropDownList ddlAccount;
        protected System.Web.UI.WebControls.DropDownList ddlLocation;
        protected System.Web.UI.WebControls.TextBox txtCaseNum;
        protected System.Web.UI.WebControls.DropDownList ddlMediaType;
        protected System.Web.UI.HtmlControls.HtmlInputButton btnSearch;
        protected System.Web.UI.WebControls.Button btnDeleteSel;
        protected System.Web.UI.WebControls.TextBox txtReturnDate;
        protected System.Web.UI.WebControls.DataGrid DataGrid1;
        protected System.Web.UI.WebControls.DropDownList ddlSelectAction;
        protected System.Web.UI.WebControls.Button btnGo;
        protected System.Web.UI.WebControls.TextBox txtStartSerialNum;
        protected System.Web.UI.WebControls.Label lblPage;
		protected System.Web.UI.WebControls.TextBox txtNote;
		protected System.Web.UI.WebControls.Button btnYes;
        protected System.Web.UI.WebControls.LinkButton lnkPageFirst;
        protected System.Web.UI.WebControls.LinkButton lnkPagePrev;
        protected System.Web.UI.WebControls.TextBox txtPageGoto;
        protected System.Web.UI.WebControls.LinkButton lnkPageNext;
        protected System.Web.UI.WebControls.LinkButton lnkPageLast;
        protected System.Web.UI.HtmlControls.HtmlGenericControl divResultArea;
        protected System.Web.UI.HtmlControls.HtmlGenericControl divPageLinks;
        protected System.Web.UI.HtmlControls.HtmlGenericControl divAction;
        protected System.Web.UI.WebControls.LinkButton printLink;
        protected System.Web.UI.WebControls.PlaceHolder PlaceHolder2;
        protected System.Web.UI.WebControls.PlaceHolder PlaceHolder1;
        protected System.Web.UI.WebControls.LinkButton exportLink;
        protected System.Web.UI.WebControls.TextBox txtDisaster;
        protected System.Web.UI.HtmlControls.HtmlTableCell DisasterCell1;
        protected System.Web.UI.HtmlControls.HtmlTableCell DisasterCell2;
        protected System.Web.UI.WebControls.Button btnDestroy;
        protected System.Web.UI.WebControls.CheckBox chkDestroyed;
        protected System.Web.UI.WebControls.CheckBox chkMissing;
        protected System.Web.UI.WebControls.LinkButton arrow;
        protected System.Web.UI.WebControls.LinkButton arrowRight;
        protected System.Web.UI.WebControls.Button btnSearch1;
        protected System.Web.UI.HtmlControls.HtmlGenericControl contentBorderTop;
        protected System.Web.UI.WebControls.Label numItems;

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
            this.exportLink.Click += new System.EventHandler(this.exportLink_Click);
            this.arrow.Click += new System.EventHandler(this.arrow_Click);
            this.arrowRight.Click += new System.EventHandler(this.arrowRight_Click);
            this.btnGo.Click += new System.EventHandler(this.btnGo_Click);
            this.DataGrid1.ItemCommand += new System.Web.UI.WebControls.DataGridCommandEventHandler(this.DataGrid1_ItemCommand);
            this.DataGrid1.PreRender += new System.EventHandler(this.DataGrid1_PreRender);
            this.btnYes.Click += new System.EventHandler(this.btnYes_Click);
            this.btnDestroy.Click += new System.EventHandler(this.btnDestroy_Click);
            this.btnSearch.ServerClick += new System.EventHandler(this.btnSearch_ServerClick);

        }
        #endregion

        /// <summary>
        /// Page initialization event handler (thrown by page master)
        /// </summary>
        protected override void Event_PageInit(object sender, System.EventArgs e)
        {
            this.pageTitle = "Find Media";
            this.levelTwo = LevelTwoNav.Find;
        }
        /// <summary>
        /// Page load event handler (thrown by page master)
        /// </summary>
        protected override void Event_PageLoad(object sender, System.EventArgs e)
        {
            // Click events for message box buttons
            this.SetControlAttr(btnYes, "onclick", "hideMsgBox('msgBoxDelete');");
            this.SetControlAttr(btnDestroy, "onclick", "hideMsgBox('msgBoxDestroy');");
            
            if (Page.IsPostBack)
            {
                pageNo = (int)this.ViewState["PageNo"];
                pageTotal = (int)this.ViewState["PageTotal"];
                if (this.ViewState["MediumFilter"] != null)
                    mediumFilter = (MediumFilter)this.ViewState["MediumFilter"];
            }
            else 
            {
                // Initialize
                pageNo = 1;
                this.ViewState["PageNo"] = pageNo;
                this.divResultArea.Visible = false;
                this.ViewState["PageTotal"] = pageTotal;
                // Set the focus to the starting serial number text box
                this.DoFocus(this.txtStartSerialNum);
                // Populate drop down lists
                foreach (MediumTypeDetails mediumType in MediumType.GetMediumTypes(false))
                {
                    this.ddlMediaType.Items.Add(mediumType.Name);
                }
                foreach (AccountDetails a in Account.GetAccounts())
                {
                    this.ddlAccount.Items.Add(a.Name);
                }
                // If the request came from the media-edit page, then we should
                // set the filter search fields and perform a search.  The edit
                // page should have placed the filter in the cache.  If we came
                // from the new_media_step_two page, then we should have the
                // starting and ending serial number in the page class from
                // which control was transferred.f
                if (Session[CacheKeys.MediumFilter] != null)
                {
                    this.InitializeFields((MediumFilter)Session[CacheKeys.MediumFilter]);
                    Session.Remove(CacheKeys.MediumFilter);
                    this.FetchGridResults();
                }
                else if (Context.Handler is new_media_step_two)
                {
                    this.txtStartSerialNum.Text = ((new_media_step_two)Context.Handler).StartNo;
                    if (((new_media_step_two)Context.Handler).EndNo != this.txtStartSerialNum.Text)
                        this.txtEndSerialNum.Text = ((new_media_step_two)Context.Handler).EndNo;
                    // Fetch the grid results
                    this.FetchGridResults();
                }
                else if (Context.Handler is media_detail)
                {
                    // Page number
                    pageNo = ((media_detail)Context.Handler).BrowsePage;
                    this.ViewState["PageNo"] = pageNo;
                    // Filter, if any
                    if ((mediumFilter = ((media_detail)Context.Handler).SearchFilter) != null)
                    {
                        this.InitializeFields(mediumFilter);
                        this.ViewState["MediumFilter"] = mediumFilter;
                    }
                    // Fetch the grid
                    this.FetchGridResults();
                }
            }
            // Apply bar code format editing
            this.BarCodeFormat(new Control[] {txtStartSerialNum, txtEndSerialNum, txtCaseNum}, this.btnSearch);
            // Make sure that the record number text box can only contain digits
            this.SetControlAttr(this.txtPageGoto, "onkeyup", "digitsOnly(this);");
        }

        /// <summary>
        /// Page prerender event handler (thrown by page master)
        /// </summary>
        protected override void Event_PagePreRender(object sender, System.EventArgs e)
        {
            // Help map id depends on whether or nor we have items in the datagrid
			this.helpId = this.DataGrid1.Items.Count != 0 ? 4 : 3;
            // If we have results and the delete box is not showing, scroll to 
            // the results pane.
            if (this.DataGrid1.Items.Count != 0 && !scriptFlag)
            {
                this.ScrollOnLoad("resultArea");
            }
            // If the delete box is showing, then we must hide the account and
            // lcoation dropdowns.  Otherwise they'll show through the box.
            this.ddlAccount.Visible = !scriptFlag;
            this.ddlLocation.Visible = !scriptFlag;
            // Set the page default button
			this.SetDefaultButton(this.contentBorderTop, "btnSearch");
            // Remove destroy item from dropdown?
            if (CustomPermission.CurrentOperatorRole() != Role.Administrator)
            {
                if (Preference.GetPreference(PreferenceKeys.DestroyTapesAdminOnly).Value.ToUpper() == "YES")
                {
                    ListItem i1 = this.ddlSelectAction.Items.FindByValue("destroy");
                    if (i1 != null) this.ddlSelectAction.Items.Remove(i1);
                }
            }
        }

        /// <summary>
        /// Datagrid prerender event handler (thrown by page master)
        /// </summary>
        private void DataGrid1_PreRender(object sender, EventArgs e)
        {
            switch (CustomPermission.CurrentOperatorRole())
            {
                case Role.Administrator:
                case Role.Operator:
                    this.DataGrid1.Columns[1].Visible = false;
                    break;  // All functions enabled
                case Role.Auditor:
                    this.ddlSelectAction.Enabled = false;
                    this.DataGrid1.Columns[0].Visible = false;
                    this.DataGrid1.Columns[2].Visible = false;
                    break;
                case Role.Viewer:
                    this.ddlSelectAction.Enabled = false;
                    this.DataGrid1.Columns[0].Visible = false;
                    this.DataGrid1.Columns[2].Visible = false;
                    this.HideExportLink();
                    break;
            }
            // Notes column adjustments?
            for (int i = 1; i < 11; i += 1)
            {
                if (i > 3)
                {
                    this.DataGrid1.Columns[i].Visible = (this.notesColumn!= NotesColumn.Wide);
                }
                else if (this.notesColumn == NotesColumn.Wide && this.DataGrid1.Columns[i].Visible)
                {
                    this.DataGrid1.Columns[i].ItemStyle.Width = Unit.Pixel(10);
                }
            }
        }
        
        /// <summary>
        /// Handler for page link buttons
        /// </summary>
        protected void LinkButton_Command(Object sender, CommandEventArgs e)
        {
            switch (e.CommandName.ToUpper())
            {
                case "PAGEFIRST":
                    pageNo = 1;
                    break;
                case "PAGELAST":
                    pageNo = pageTotal;
                    break;
                case "PAGENEXT":
                    pageNo += 1;
                    break;
                case "PAGEPREV":
                    pageNo -= 1;
                    break;
            }
            // Store the page number and fetch the grid
            this.ViewState["PageNo"] = pageNo;
            this.FetchGridResults();
        }
        /// <summary>
        /// Initializes the search fields according to a given filter
        /// </summary>
        private void InitializeFields(MediumFilter mf)
        {
            if ((mf.Filter & MediumFilter.FilterKeys.SerialStart) != 0)
                this.txtStartSerialNum.Text = mf.StartingSerialNo;
            if ((mf.Filter & MediumFilter.FilterKeys.SerialEnd) != 0)
                this.txtEndSerialNum.Text = mf.EndingSerialNo;
            if ((mf.Filter & MediumFilter.FilterKeys.ReturnDate) != 0)
                this.txtReturnDate.Text = DisplayDate(mf.ReturnDate, false, false);
            if ((mf.Filter & MediumFilter.FilterKeys.Account) != 0)
                this.ddlAccount.SelectedValue = mf.Account;
            if ((mf.Filter & MediumFilter.FilterKeys.MediumType) != 0)
                this.ddlMediaType.SelectedValue = mf.MediumType;
            if ((mf.Filter & MediumFilter.FilterKeys.CaseName) != 0)
                this.txtCaseNum.Text = mf.CaseName;
            if ((mf.Filter & MediumFilter.FilterKeys.Location) != 0)
                this.ddlLocation.SelectedValue = ((int)mf.Location).ToString();
            if ((mf.Filter & MediumFilter.FilterKeys.Notes) != 0)
                this.txtNote.Text = mf.Notes;
            if ((mf.Filter & MediumFilter.FilterKeys.DisasterCode) != 0)
                this.txtDisaster.Text = mf.DisasterCode;
            // Missing (on = missing, off = everything
            this.chkMissing.Checked = (mf.Filter & MediumFilter.FilterKeys.Missing) != 0;
            // Destroyed always active
            this.chkDestroyed.Checked = mf.Destroyed.ToString().ToLower() == "true";
        }
        /// <summary>
        /// Creates filter for submission to data layer so that only relevant
        /// media are returned from search
        /// </summary>
        private MediumFilter CreateFilter()
        {
		    this.mediumFilter = new MediumFilter();
            // Starting serial number
            if (this.txtStartSerialNum.Text.Length != 0)
                this.mediumFilter.StartingSerialNo = this.txtStartSerialNum.Text;
            // Ending serial number
            if (this.txtEndSerialNum.Text.Length != 0)
                this.mediumFilter.EndingSerialNo = this.txtEndSerialNum.Text;
            // Return date
            if (this.txtReturnDate.Text.Length != 0)
                this.mediumFilter.ReturnDate = Date.ParseExact(this.txtReturnDate.Text); 
            // Account
            if (this.ddlAccount.SelectedIndex != 0)
                this.mediumFilter.Account = this.ddlAccount.SelectedValue;
            // Medium type
            if (this.ddlMediaType.SelectedIndex != 0)
                this.mediumFilter.MediumType = this.ddlMediaType.SelectedValue;
            // Case name
            if (this.txtCaseNum.Text.Length != 0)
                this.mediumFilter.CaseName = this.txtCaseNum.Text;
            // Location
            if (this.ddlLocation.SelectedIndex != 0)
                this.mediumFilter.Location = (Locations)Enum.Parse(typeof(Locations),this.ddlLocation.SelectedValue);
            // Missing status
            if (this.chkMissing.Checked)
                this.mediumFilter.Missing = true;
            // Destroyed status (always active)
            this.mediumFilter.Destroyed = this.chkDestroyed.Checked;
            // Notes
            if (this.txtNote.Text.Length != 0)
                this.mediumFilter.Notes = this.txtNote.Text;
            // Disaster code
            if (this.txtDisaster.Text.Length != 0)
                this.mediumFilter.DisasterCode = this.txtDisaster.Text;
            // Place the filter in the viewstate
            this.ViewState["MediumFilter"] = this.mediumFilter;
            // Return the filter
            return this.mediumFilter;
        }

        /// <summary>
        /// Fetches the search results from the database
        /// </summary>
        private void FetchGridResults()
        {
            try
            {
                int x, pageTotal;
                MediumSorts sortOrder = MediumSorts.Serial;
                MediumFilter resultFilter = this.CreateFilter();
                // Page size
                int pageSize = Preference.GetItemsPerPage();
                // Fetch items
                MediumCollection mc = Medium.GetMediumPage(pageNo, pageSize, resultFilter, sortOrder, out x);
                // Set the page total
                pageTotal = Convert.ToInt32(Math.Ceiling(x / (double)pageSize));
                // If the page is greater than the total number of pages, get the last page
                if (pageTotal != 0 && pageNo > pageTotal)
                {
                    pageNo = pageTotal;
                    mc = Medium.GetMediumPage(pageNo, pageSize, resultFilter, sortOrder, out x);
                }

                numItems.Text = x != 0 ? String.Format("({0} items)", x) : String.Empty;
                DataGrid1.DataSource = mc;
                DataGrid1.DataBind();

                bool resultsObtained = mc.Count != 0;
                this.divResultArea.Visible = true;
                this.DataGrid1.Visible = resultsObtained;
                this.divAction.Visible = resultsObtained;
                this.divPageLinks.Visible = resultsObtained;

                if (resultsObtained)
                {
                    this.lnkPagePrev.Enabled  = pageNo != 1;
                    this.lnkPageFirst.Enabled = pageNo != 1;
                    this.lnkPageNext.Enabled  = pageNo != pageTotal;
                    this.lnkPageLast.Enabled  = pageNo != pageTotal;
                    this.lblPage.Text = String.Format("Page {0} of {1}", pageNo, pageTotal);
                }
                else
                {
                    Label emptyLabel = new Label();
                    emptyLabel.ForeColor = Color.Black;
                    emptyLabel.Text = "No media matched the search criteria";
                    this.PlaceHolder2.Controls.Add(emptyLabel);
                }

                this.ViewState["PageNo"] = pageNo;
                this.ViewState["PageTotal"] = pageTotal;
            }
            catch (Exception ex)
            {
                this.DisplayErrors(this.PlaceHolder1, ex.Message);
                this.divResultArea.Visible = true;
                this.DataGrid1.Visible = false;
                this.DataGrid1.Visible = false;
                this.divAction.Visible = false;
                this.divPageLinks.Visible = false;
                Label errorLabel = new Label();
                errorLabel.ForeColor = Color.Black;
                errorLabel.Text = "Search error occurred";
                this.PlaceHolder2.Controls.Add(errorLabel);
            }
        }
	
        /// <summary>
        /// Handler for the search button click event
        /// </summary>
        private void btnSearch_Click(object sender, System.EventArgs e)
        {
            // If we're going to a new page, adjust the page number.
            // Otherwise it's a new search, so set the page number to 1.
            if (this.txtPageGoto.Text.Length != 0)
            {
                pageNo = Int32.Parse(this.txtPageGoto.Text);
                this.txtPageGoto.Text = String.Empty;
                this.ViewState["PageNo"] = pageNo;
            }
            else
            {
                this.pageNo = 1;
                this.ViewState["PageNo"] = 1;
            }
            // Fetch the grid results
            this.FetchGridResults();
        }
        /// <summary>
        /// Handler for the Go button click event
        /// </summary>
        private void btnGo_Click(object sender, System.EventArgs e)
        {
            if (this.CollectCheckedItems(this.DataGrid1).Length != 0)
            {
                switch (this.ddlSelectAction.SelectedValue.ToUpper())
                {
                    case "EDIT":
                        EditMedia();
                        break;
                    case "DELETE":
                        this.ShowMessageBox("deleteBox", "msgBoxDelete");
                        scriptFlag = true;
                        break;
                    case "DESTROY":
                        this.ShowMessageBox("destroyBox", "msgBoxDestroy");
                        scriptFlag = true;
                        break;
                    default:
                        break;
                }
            }
        }
        /// <summary>
        /// Handler for the Yes button of the delete media message box.  It
        /// transparently called the delete function.
        /// </summary>
        private void btnYes_Click(object sender, System.EventArgs e)
        {
            this.DeleteMedia();
        }
        /// <summary>
        /// Handler for the Yes button of the destroy media message box.  It
        /// transparently called the delete function.
        /// </summary>
        private void btnDestroy_Click(object sender, System.EventArgs e)
        {
            this.DestroyMedia();
        }
        /// <summary>
        /// Deletes the selected media from the database
        /// </summary>
        private void DeleteMedia()
        {
            MediumCollection deleteMedia = new MediumCollection();
            // Loop through grid and add checked items to collection
            foreach (DataGridItem dgi in this.CollectCheckedItems(this.DataGrid1))
            {
                deleteMedia.Add(Medium.GetMedium(dgi.Cells[1].Text));
            }
            // Delete the media from the database
            try
            {
                Medium.Delete(ref deleteMedia);
                this.FetchGridResults();
            }
            catch (CollectionErrorException ex)
            {
                this.DisplayErrors(this.PlaceHolder2, ex.Collection);
            }
            catch (Exception ex)
            {
                this.DisplayErrors(this.PlaceHolder2, ex.Message);
            }
        }
        /// <summary>
        /// Destroys the selected media
        /// </summary>
        private void DestroyMedia()
        {
            MediumCollection c1 = new MediumCollection();
            // Loop through grid and add checked items to collection
            foreach (DataGridItem i1 in this.CollectCheckedItems(this.DataGrid1))
            {
                c1.Add(Medium.GetMedium(i1.Cells[1].Text));
            }
            // Delete the media from the database
            try
            {
                Medium.Destroy(c1);
                this.FetchGridResults();
            }
            catch (Exception e1)
            {
                this.DisplayErrors(this.PlaceHolder2, e1.Message);
            }
        }
        /// <summary>
        /// Places the selected media in a collection, caches the collection,
        /// and redirects to the media-edit.aspx page, where the editing
        /// actually occurs
        /// </summary>
        private void EditMedia()
        {
            editCollection = new MediumCollection();
            // Loop through grid and add checked items to collection
            foreach (DataGridItem dgi in this.CollectCheckedItems(this.DataGrid1))
            {
                editCollection.Add(Medium.GetMedium(dgi.Cells[1].Text));
            }
            // Transfer to media edit page.  We must use Server.Transfer to in order
            // to pass the data.
            if (editCollection.Count != 0)
            {
                Server.Transfer("media-edit.aspx");
            }
        }
        /// <summary>
        /// Event handler used to transfer to media detail page on linkbutton click
        /// </summary>
        private void DataGrid1_ItemCommand(object source, DataGridCommandEventArgs e)
        {
            if (e.CommandSource.GetType() == typeof(LinkButton))
                Server.Transfer("media-detail.aspx?serialNo=" + e.Item.Cells[1].Text);
        }
        /// <summary>
        /// Print function to be called asynchronously
        /// </summary>
        private void printLink_Click(object sender, System.EventArgs e)
        {
            Session[CacheKeys.Object] = this.ViewState["MediumFilter"];
            Session[CacheKeys.WaitRequest] = RequestTypes.PrintFindMedia;
            ClientScript.RegisterStartupScript(GetType(), "printWindow", "<script>openBrowser('../waitPage.aspx?redirectPage=print.aspx&x=" + Guid.NewGuid().ToString("N") + "')</script>");
        }
        /// <summary>
        /// Exports the current list to a file for download
        /// </summary>
        private void exportLink_Click(object sender, System.EventArgs e)
        {
            try
            {
                int f1 = 20, f2 = 10, f3 = 11, f4 = 7, f5 = 9;
                int f6 = 20, f7 = 20, f8 = 30, f9 = 7, x = 0;
                StringBuilder dataString = new StringBuilder();
                bool tabs = Preference.GetPreference(PreferenceKeys.ExportWithTabDelimiters).Value == "YES";
                string header1 = tabs ? "Serial Number" : "Serial Number".PadRight(f1, ' ');
                string header2 = tabs ? "Location" : "Location".PadRight(f2, ' ');
                string header3 = tabs ? "Return Date" : "Return Date".PadRight(f3, ' ');
                string header4 = tabs ? "Missing" : "Missing".PadRight(f4, ' ');
                string header5 = tabs ? "Destroyed" : "Destroyed".PadRight(f5, ' ');
                string header6 = tabs ? "Account" : "Account".PadRight(f6, ' ');
                string header7 = tabs ? "Case Number" : "Case Number".PadRight(f7, ' ');
                string header8 = tabs ? "Media Type" : "Media Type".PadRight(f8, ' ');
                string header9 = tabs ? "DR Code" : "DR Code".PadRight(f9, ' ');
                string header10 = "Notes";
                string dash1 = String.Empty.PadRight(f1, '-');
                string dash2 = String.Empty.PadRight(f2, '-');
                string dash3 = String.Empty.PadRight(f3, '-');
                string dash4 = String.Empty.PadRight(f4, '-');
                string dash5 = String.Empty.PadRight(f5, '-');
                string dash6 = String.Empty.PadRight(f6, '-');
                string dash7 = String.Empty.PadRight(f7, '-');
                string dash8 = String.Empty.PadRight(f8, '-');
                string dash9 = String.Empty.PadRight(f9, '-');
                string dash10 = String.Empty.PadRight(10, '-');
                // Retrieve the items
                MediumCollection mc = Medium.GetMediumPage(1, 1000000, mediumFilter, MediumSorts.Serial, out x);
                // Create the headers
                string title = String.Format("{0} Media Search", Configurator.ProductName);
                dataString.AppendFormat("{0}{1}{2}{1}", title, Environment.NewLine, String.Empty.PadRight(title.Length,'-'));
                dataString.AppendFormat("Total Items: {0}{1}", mc.Count, Environment.NewLine);
                dataString.AppendFormat("Export Time: {0}{1}", DisplayDate(DateTime.UtcNow), Environment.NewLine);
                dataString.Append(Environment.NewLine);
                // Write the data
                dataString.AppendFormat("{0}{11}{1}{11}{2}{11}{3}{11}{4}{11}{5}{11}{6}{11}{7}{11}{8}{11}{9}{11}{10}", header1, header2, header3, header4, header5, header6, header7, header8, header9, header10, Environment.NewLine, tabs ? "\t" : "  ");
                dataString.AppendFormat("{0}{11}{1}{11}{2}{11}{3}{11}{4}{11}{5}{11}{6}{11}{7}{11}{8}{11}{9}{11}{10}", dash1, dash2, dash3, dash4, dash5, dash6, dash7, dash8, dash9, dash10, Environment.NewLine, tabs ? "\t" : "  ");
                // Write the data
                if (tabs == false)
                {
                    foreach (MediumDetails m in mc)
                    {
                        string s1 = m.SerialNo.PadRight(f1, ' ');
                        string s2 = m.Location.ToString().PadRight(f2, ' ');
                        string s3 = DisplayDate(m.ReturnDate,false,false).PadRight(f3, ' ');
                        string s4 = m.Missing ? "Yes".PadRight(f4, ' ') : "No".PadRight(f4, ' ');
                        string s5 = m.Destroyed ? "Yes".PadRight(f5, ' ') : "No".PadRight(f5, ' ');
                        string s6 = m.Account.PadRight(f6, ' ');
                        string s7 = m.CaseName.PadRight(f7, ' ');
                        string s8 = m.MediumType.PadRight(f8, ' ');
                        string s9 = m.Disaster.PadRight(f9, ' ');
                        dataString.AppendFormat("{0}  {1}  {2}  {3}  {4}  {5}  {6}  {7}  {8}  {9}  {10}", s1, s2, s3, s4, s5, s6, s7, s8, s9, m.Notes, Environment.NewLine);
                    }
                }
                else foreach (MediumDetails m in mc)
                {
                         dataString.AppendFormat("{0}\t{1}\t{2}\t{3}\t{4}\t{5}\t{6}\t{7}\t{8}\t{9}\t{10}", m.SerialNo, m.Location, DisplayDate(m.ReturnDate,false,false), m.Missing ? "Yes" : "No", m.Destroyed ? "Yes" : "No", m.Account, m.CaseName, m.MediumType, m.Disaster, m.Notes, Environment.NewLine);
                }
                // Export the data
                DoExport("FindMedia_" + Time.Local.ToString("yyyyMMddHHmm") + ".txt", dataString.ToString());
            }
            catch (Exception ex)
            {
                this.DisplayErrors(this.PlaceHolder1, ex.Message);
            }
        }
        /// <summary>
        /// Hides the export link, used when viewer access
        /// </summary>
        /// <returns></returns>
        private void HideExportLink()
        {
            ClientScript.RegisterStartupScript(GetType(), "exportHide", "<script language='javascript'>getObjectById('exportLink').style.display='none';</script>");
        }
        /// <summary>
        /// Expand the Notes column
        /// </summary>
        private void arrow_Click(object sender, System.EventArgs e)
        {
            notesColumn = NotesColumn.Wide;
            this.arrowRight.Visible = true;
            this.arrow.Visible = false;
        }
        /// <summary>
        /// Contract the Notes column
        /// </summary>
        private void arrowRight_Click(object sender, System.EventArgs e)
        {
            notesColumn = NotesColumn.Narrow;
            this.arrowRight.Visible = false;
            this.arrow.Visible = true;
        }

        private void btnSearch_ServerClick(object sender, System.EventArgs e)
        {
            // If we're going to a new page, adjust the page number.
            // Otherwise it's a new search, so set the page number to 1.
            if (this.txtPageGoto.Text.Length != 0)
            {
                pageNo = Int32.Parse(this.txtPageGoto.Text);
                this.txtPageGoto.Text = String.Empty;
                this.ViewState["PageNo"] = pageNo;
            }
            else
            {
                this.pageNo = 1;
                this.ViewState["PageNo"] = 1;
            }
            // Fetch the grid results
            this.FetchGridResults();        
        }
    }
}
