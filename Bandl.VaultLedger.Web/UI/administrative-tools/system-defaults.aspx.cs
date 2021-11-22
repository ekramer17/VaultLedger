using System;
using System.Web.UI;
using System.Collections;
using System.Web.UI.WebControls;
using Bandl.Library.VaultLedger.BLL;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.Collections;
using Bandl.Library.VaultLedger.Security;
using Bandl.Library.VaultLedger.Exceptions;

namespace Bandl.VaultLedger.Web.UI
{
	/// <summary>
	/// Summary description for system_defaults.
	/// </summary>
	public class system_defaults : BasePage
	{
        protected System.Web.UI.WebControls.Button btnOK;
        protected System.Web.UI.HtmlControls.HtmlInputButton btnSave;
        protected System.Web.UI.HtmlControls.HtmlTable tblOptions;
        protected System.Web.UI.WebControls.DropDownList d1;
        protected System.Web.UI.WebControls.DropDownList d2;
        protected System.Web.UI.WebControls.DropDownList d3;
        protected System.Web.UI.WebControls.DropDownList d4;
        protected System.Web.UI.WebControls.DropDownList d5;
        protected System.Web.UI.WebControls.DropDownList d6;
        protected System.Web.UI.WebControls.DropDownList d7;
        protected System.Web.UI.WebControls.DropDownList d8;
        protected System.Web.UI.WebControls.DropDownList d9;
        protected System.Web.UI.WebControls.DropDownList d10;
        protected System.Web.UI.WebControls.DropDownList d11;
        protected System.Web.UI.WebControls.DropDownList d12;
        protected System.Web.UI.WebControls.DropDownList d13;
        protected System.Web.UI.WebControls.DropDownList d14;
        protected System.Web.UI.WebControls.DropDownList d15;
        protected System.Web.UI.WebControls.DropDownList d16;
		protected System.Web.UI.WebControls.DropDownList d17;
        protected System.Web.UI.WebControls.DropDownList d18;
        protected System.Web.UI.WebControls.DropDownList d19;
        protected System.Web.UI.WebControls.DropDownList d20;
        protected System.Web.UI.WebControls.DropDownList d21;
        protected System.Web.UI.WebControls.DropDownList d22;
        protected System.Web.UI.WebControls.DropDownList d23;
        protected System.Web.UI.WebControls.DropDownList d24;
        protected System.Web.UI.WebControls.DropDownList d25;
        protected System.Web.UI.WebControls.Button btnSave1;
        protected System.Web.UI.HtmlControls.HtmlGenericControl contentBorderTop;
        protected System.Web.UI.WebControls.PlaceHolder PlaceHolder1;

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
            this.btnSave.ServerClick += new System.EventHandler(this.btnSave_ServerClick);

        }
        #endregion

        /// <summary>
        /// Page initialization event handler (thrown by page master)
        /// </summary>
        protected override void Event_PageInit(object sender, System.EventArgs e)
        {
            this.levelTwo = LevelTwoNav.Preferences;
            this.pageTitle = "General Preferences";
            this.helpId = 43;
            // Security permission only for administrators.  If we are one,
            // go ahead and set up the page.
            DoSecurity(Role.Administrator, "default.aspx");
        }
        /// <summary>
        /// Page load event handler (thrown by page master)
        /// </summary>
        protected override void Event_PageLoad(object sender, System.EventArgs e)
        {
            this.SetControlAttr(btnOK, "onclick", "hideMsgBox('msgBoxSave');");
            // Set the default button
            this.SetDefaultButton(this.contentBorderTop, "btnSave");
            // Create the table
            if (!this.IsPostBack) this.CreateTable();
        }
        /// <summary>
        /// Creates the main table
        /// </summary>
        private void CreateTable()
        {
            // Retrieve the preferences
            PreferenceCollection x = OrderPreferences(Preference.GetPreferences());
            // Fill the table rows
            for (int r = 0; r < x.Count; r++)
            {
                DropDownList ddlc = (DropDownList)tblOptions.Rows[r].Cells[1].Controls[0];
                tblOptions.Rows[r].Cells[0].InnerHtml = OptionDescription(x[r].Key);
                PopulateListBox(x[r].Key, ddlc);
                // Set the dropdown width
                ddlc.Width = 90;
                // Select the correct value in the dropdown
                for (int i = 0; i < ddlc.Items.Count; i++)
                    if (ddlc.Items[i].Value.ToUpper() == x[r].Value.ToUpper())
                        ddlc.SelectedIndex = i;
            }
        }

        /// <summary>
        /// Returns the text description for the given option
        /// </summary>
        /// <param name="key">
        /// Option for which to return description
        /// </param>
        /// <returns>
        /// Description of given option
        /// </returns>
        private string OptionDescription(PreferenceKeys key)
        {
            switch (key)
            {
                case PreferenceKeys.EmploySerialEditFormat:
                    return "Employ standard vault bar code editing";
                case PreferenceKeys.SendListCaseVerify:
                    return "Consider cases on shipping list verification";
                case PreferenceKeys.TmsDataSetNotes:
                    return "Write data set name to Notes field of medium when parsing a TMS report";
                case PreferenceKeys.TmsReturnDates:
                    return "Employ return dates from TMS reports when using reports to create shipping lists";
                case PreferenceKeys.TmsUnknownSite:
                    return "Ignore unrecognized external site (i.e. site map) when parsing a TMS report";
                case PreferenceKeys.InventoryExcludeActiveLists:
                    return "Exclude media on all active shipping and receiving lists from comparison when reconciling inventory";
                case PreferenceKeys.InventoryExcludeTodaysLists:
                    return "Exclude media on today's shipping and receiving lists from comparison when reconciling inventory";
                case PreferenceKeys.DeclareListAccounts:
                    return "Actively declare accounts upon shipping list submission";
                case PreferenceKeys.AllowTMSAccountAssigns:
                    return "Allow TMS reports to declare accounts according to site maps upon movement list submission";
                case PreferenceKeys.NumberOfItemsPerPage:
                    return "Number of line items to display per page (where applicable)";
                case PreferenceKeys.DateDisplayFormat:
                    return "Format to use when displaying or accepting dates";
                case PreferenceKeys.TimeDisplayFormat:
                    return "Format to use when displaying times";
                case PreferenceKeys.AllowOneClickVerify:
                    return "Allow one-click shipping and receiving list verification";
                case PreferenceKeys.AllowAddsOnReconcile:
                    return "Allow dynamic addition of unknown media during inventory reconciliation";
                case PreferenceKeys.ExportWithTabDelimiters:
                    return "Delimiter to use when exporting text files";
                case PreferenceKeys.MaxRfidSerialLength:
                    return "Maximum length of RFID scanned serial numbers (characters will be stripped from right)";
				case PreferenceKeys.ReceiveListAdminOnly:
					return "Allow only administrators to manually generate receiving lists";
                case PreferenceKeys.DestroyTapesAdminOnly:
                    return "Allow only administrators to mark media as destroyed";
                case PreferenceKeys.DissolveCompositeOnClear:
                    return "Extract discrete lists from composite lists when composite lists are processed";
                case PreferenceKeys.DisplayNotesOnManifests:
                    return "Display notes field on shipping and receiving manifests";
                case PreferenceKeys.TmsSkipTapesNotResident:
                    return "Skip media on TMS reports for which required residence is unsatisfied";
                case PreferenceKeys.AllowAddsOnTMSListCreation:
                    return "Allow dynamic addition of media during list creation via TMS report";
                case PreferenceKeys.AllowDynamicListReplacement:
                    return "Allow dynamic replacement of media on shipping and receiving lists";
                case PreferenceKeys.CreateTapesAdminOnly:
                    return "Allow only administrators to add tapes";
                case PreferenceKeys.AssignAccountsOnReceiveListClear:
                    return "Assign medium accounts via bar code format upon receiving list clear";
            }
            // Return empty string if not found
            return String.Empty;
        }

        /// <summary>
        /// Returns the text description for the given option
        /// </summary>
        /// <param name="key">
        /// Option for which to return description
        /// </param>
        private void PopulateListBox(PreferenceKeys key, DropDownList ddl)
        {
            ListItemCollection lic = ddl.Items;

            switch (key)
            {
                case PreferenceKeys.SendListCaseVerify:
                    lic.Add(new ListItem("Yes", "YES"));
                    lic.Add(new ListItem("No", "NO"));
                    lic.Add(new ListItem("Sealed Only", "SEALED ONLY"));
                    break;
                case PreferenceKeys.TmsDataSetNotes:
                    lic.Add(new ListItem("No Action", "NO ACTION"));
                    lic.Add(new ListItem("Replace", "REPLACE"));
                    lic.Add(new ListItem("Append", "APPEND"));
                    break;
                case PreferenceKeys.NumberOfItemsPerPage:
                    lic.Add(new ListItem("20", "20"));
                    lic.Add(new ListItem("50", "50"));
                    lic.Add(new ListItem("100", "100"));
                    lic.Add(new ListItem("250", "250"));
                    lic.Add(new ListItem("500", "500"));
                    lic.Add(new ListItem("1000", "1000"));
                    break;
                case PreferenceKeys.DateDisplayFormat:
                    lic.Add(new ListItem("M/d/yyyy", "M/d/yyyy"));
                    lic.Add(new ListItem("M-d-yyyy", "M-d-yyyy"));
                    lic.Add(new ListItem("M.d.yyyy", "M.d.yyyy"));
                    lic.Add(new ListItem("M/d/yy", "M/d/yy"));
                    lic.Add(new ListItem("M-d-yy", "M-d-yy"));
                    lic.Add(new ListItem("M.d.yy", "M.d.yy"));
                    lic.Add(new ListItem("d/M/yyyy", "d/M/yyyy"));
                    lic.Add(new ListItem("d-M-yyyy", "d-M-yyyy"));
                    lic.Add(new ListItem("d.M.yyyy", "d.M.yyyy"));
                    lic.Add(new ListItem("d/M/yy", "d/M/yy"));
                    lic.Add(new ListItem("d-M-yy", "d-M-yy"));
                    lic.Add(new ListItem("d.M.yy", "d.M.yy"));
                    lic.Add(new ListItem("yyyy/M/d", "yyyy/M/d"));
                    lic.Add(new ListItem("yyyy-M-d", "yyyy-M-d"));
                    lic.Add(new ListItem("yyyy.M.d", "yyyy.M.d"));
                    lic.Add(new ListItem("MM/dd/yyyy", "MM/dd/yyyy"));
                    lic.Add(new ListItem("MM-dd-yyyy", "MM-dd-yyyy"));
                    lic.Add(new ListItem("MM.dd.yyyy", "MM.dd.yyyy"));
                    lic.Add(new ListItem("MM/dd/yy", "MM/dd/yy"));
                    lic.Add(new ListItem("MM-dd-yy", "MM-dd-yy"));
                    lic.Add(new ListItem("MM.dd.yy", "MM.dd.yy"));
                    lic.Add(new ListItem("dd/MM/yyyy", "dd/MM/yyyy"));
                    lic.Add(new ListItem("dd-MM-yyyy", "dd-MM-yyyy"));
                    lic.Add(new ListItem("dd.MM.yyyy", "dd.MM.yyyy"));
                    lic.Add(new ListItem("dd/MM/yy", "dd/MM/yy"));
                    lic.Add(new ListItem("dd-MM-yy", "dd-MM-yy"));
                    lic.Add(new ListItem("dd.MM.yy", "dd.MM.yy"));
                    lic.Add(new ListItem("yyyy/MM/dd", "yyyy/MM/dd"));
                    lic.Add(new ListItem("yyyy-MM-dd", "yyyy-MM-dd"));
                    lic.Add(new ListItem("yyyy.MM.dd", "yyyy.MM.dd"));
                    break;
                case PreferenceKeys.TimeDisplayFormat:
                    lic.Add(new ListItem("H:mm:ss", "H:mm:ss"));
                    lic.Add(new ListItem("HH:mm:ss", "HH:mm:ss"));
                    lic.Add(new ListItem("h:mm:ss A/P", "h:mm:ss tt"));
                    break;
                case PreferenceKeys.ExportWithTabDelimiters:
                    lic.Add(new ListItem("Tabs", "YES"));
                    lic.Add(new ListItem("Spaces", "NO"));
                    break;
                case PreferenceKeys.MaxRfidSerialLength:
                    lic.Add(new ListItem("4", "4"));
                    lic.Add(new ListItem("5", "5"));
                    lic.Add(new ListItem("6", "6"));
                    lic.Add(new ListItem("7", "7"));
                    lic.Add(new ListItem("8", "8"));
                    lic.Add(new ListItem("9", "9"));
                    lic.Add(new ListItem("10", "10"));
                    lic.Add(new ListItem("11", "11"));
                    lic.Add(new ListItem("12", "12"));
                    lic.Add(new ListItem("13", "13"));
                    lic.Add(new ListItem("14", "14"));
                    lic.Add(new ListItem("15", "15"));
                    lic.Add(new ListItem("16", "16"));
                    break;
                default:
                    lic.Add(new ListItem("Yes", "YES"));
                    lic.Add(new ListItem("No", "NO"));
                    break;
            }
        }
        /// <summary>
        /// Makes sure that the preferences are in order
        /// </summary>
        private PreferenceCollection OrderPreferences(PreferenceCollection x)
        {
            PreferenceDetails p;
            PreferenceCollection c = new PreferenceCollection();
            // Get preferences keys in order
            ArrayList al = new ArrayList();
            al.Add(PreferenceKeys.TmsReturnDates);
            al.Add(PreferenceKeys.TmsUnknownSite);
            al.Add(PreferenceKeys.TmsDataSetNotes);
            al.Add(PreferenceKeys.TmsSkipTapesNotResident);
            al.Add(PreferenceKeys.SendListCaseVerify);
            al.Add(PreferenceKeys.EmploySerialEditFormat);
            al.Add(PreferenceKeys.AllowAddsOnReconcile);
            al.Add(PreferenceKeys.InventoryExcludeActiveLists);
            al.Add(PreferenceKeys.InventoryExcludeTodaysLists);
            al.Add(PreferenceKeys.DeclareListAccounts);
            al.Add(PreferenceKeys.AllowTMSAccountAssigns);
            al.Add(PreferenceKeys.AllowAddsOnTMSListCreation);
            al.Add(PreferenceKeys.AllowDynamicListReplacement);
            al.Add(PreferenceKeys.ReceiveListAdminOnly);
            al.Add(PreferenceKeys.DestroyTapesAdminOnly);
            al.Add(PreferenceKeys.CreateTapesAdminOnly);
            al.Add(PreferenceKeys.DissolveCompositeOnClear);
            al.Add(PreferenceKeys.DisplayNotesOnManifests);
            al.Add(PreferenceKeys.AllowOneClickVerify);
            al.Add(PreferenceKeys.NumberOfItemsPerPage);
            al.Add(PreferenceKeys.MaxRfidSerialLength);
            al.Add(PreferenceKeys.ExportWithTabDelimiters);
            al.Add(PreferenceKeys.DateDisplayFormat);
            al.Add(PreferenceKeys.TimeDisplayFormat);
            al.Add(PreferenceKeys.AssignAccountsOnReceiveListClear);
            // Add the preferences in order
            foreach (PreferenceKeys k in al)
                c.Add((p = x.Find(k)) != null ? p : PreferenceDetails.CreateDefault(k));
            // Return the collection
            return c;
        }

        private void btnSave_ServerClick(object sender, System.EventArgs e)
        {
            // Get the preferences from the database so that we may resolve keys
            PreferenceCollection options = Preference.GetPreferences();
            // Update the preferences
            for (int i = 0; i < options.Count; i++)
            {
                // Get the text description for the preference key
                string desc = this.OptionDescription(options[i].Key);
                // Find the description in the table
                for (int r = 0; r < tblOptions.Rows.Count; r++)
                    if (tblOptions.Rows[r].Cells[0].InnerHtml == desc)
                        options[i].Value = ((DropDownList)tblOptions.Rows[r].Cells[1].Controls[0]).SelectedValue;
            }
            // Update the collection
            try
            {
                String f1 = null;
                String f2 = null;
                Preference.Update(ref options);
                // Startup script
                ClientScript.RegisterStartupScript(GetType(), "d1", "<script language=javascript>getObjectById('d1').style.display='none'</script>");
                ClientScript.RegisterStartupScript(GetType(), "d2", "<script language=javascript>getObjectById('d2').style.display='none'</script>");
                // Show message box
                this.ShowMessageBox("msgBoxSave");
                // Replace date and time formats in session object
                for (int i = 0; i < options.Count; i++)
                {
                    if (options[i].Key == PreferenceKeys.DateDisplayFormat)
                    {
                        f1 = options[i].Value;
                    }
                    else if (options[i].Key == PreferenceKeys.TimeDisplayFormat)
                    {
                        f2 = options[i].Value;
                    }
                }
                // Set context
                Context.Items[CacheKeys.DateMask] = f1;
                Context.Items[CacheKeys.TimeMask] = f2;
                // Set cookie
                Global.SetCookie((String)Context.Items[CacheKeys.Login], (String)Context.Items[CacheKeys.Role], f1, f2);

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
    }
}
