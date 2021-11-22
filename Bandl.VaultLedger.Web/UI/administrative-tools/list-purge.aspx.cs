using System;
using System.Collections;
using System.Web.UI.WebControls;
using Bandl.Library.VaultLedger.Security;
using Bandl.Library.VaultLedger.Collections;
using Bandl.Library.VaultLedger.Exceptions;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.BLL;

namespace Bandl.VaultLedger.Web.UI
{
	/// <summary>
	/// Summary description for list_purge.
	/// </summary>
	public class list_purge : BasePage
	{
        protected System.Web.UI.WebControls.PlaceHolder PlaceHolder1;
        protected System.Web.UI.WebControls.Button btnSave;
        protected System.Web.UI.WebControls.DataGrid DataGrid1;
        protected System.Web.UI.WebControls.Button btnOK;
        protected System.Web.UI.HtmlControls.HtmlGenericControl tab1;
        protected System.Web.UI.HtmlControls.HtmlGenericControl tab2;
        protected System.Web.UI.HtmlControls.HtmlGenericControl tab3;
        protected System.Web.UI.HtmlControls.HtmlGenericControl tabSection;
        protected System.Web.UI.HtmlControls.HtmlGenericControl tab4;
        protected System.Web.UI.HtmlControls.HtmlForm Form1;

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
            this.DataGrid1.PreRender += new System.EventHandler(this.DataGrid1_PreRender);
            this.DataGrid1.ItemDataBound += new System.Web.UI.WebControls.DataGridItemEventHandler(this.DataGrid1_ItemDataBound);
            this.btnSave.Click += new System.EventHandler(this.btnSave_Click);

        }
        #endregion
    
        /// <summary>
        /// Page initialization event handler (thrown by page master)
        /// </summary>
        protected override void Event_PageInit(object sender, System.EventArgs e)
        {
            this.helpId = 45;
            this.levelTwo = LevelTwoNav.Preferences;
            this.pageTitle = "List Purge Preferences";
            // Click events for message box buttons
            this.SetControlAttr(btnOK, "onclick", "hideMsgBox('msgBoxSave')");
            // Security permission only for administrators.  If we are one,
            // go ahead and set up the page.
            DoSecurity(Role.Administrator, "default.aspx");
        }
        /// <summary>
        /// Page load event handler (thrown by page master)
        /// </summary>
        protected override void Event_PageLoad(object sender, System.EventArgs e)
        {
            // If not a postback, then initialize viewstate
            if (!this.Page.IsPostBack)
            {
                this.ViewState["Hashtable"] = CreateHashtable();
                this.ViewState["PurgeDetails"] = ActionList.GetPurgeParameters();
                // Bind the purge parameters to the datagrid
                this.DataGrid1.DataSource = (ListPurgeCollection)this.ViewState["PurgeDetails"];
                this.DataGrid1.DataBind();
                // Update the tab page default
                TabPageDefault.Update(TabPageDefaults.ListPreferences, Context.Items[CacheKeys.Login], 4);
            }
        }
        /// <summary>
        /// Page prerender event handler (thrown by page master)
        /// </summary>
        protected override void Event_PagePreRender(object sender, System.EventArgs e)
        {
            // At this time, we don't have any archive capability, so we'll
            // make the datagrid archive column invisible.
            this.DataGrid1.Columns[2].Visible = false;
            // Tab setup
            switch (Configurator.ProductType)
            {
//                case "RECALL":
//                    tab2.Visible = false;
//                    tab3.Visible = false;
//                    // Select the correct tab
//                    SetControlAttr(tab1, "class", "tabs twoTabOne", false);
//                    SetControlAttr(tab4, "class", "tabs twoTabTwoSelected", false);
//                    SetControlAttr(tabSection, "class", "tabNavigation twoTabs", false);
//                    break;
                default:
                    // Select the correct tab
                    SetControlAttr(tab1, "class", "tabs fourTabOne", false);
                    SetControlAttr(tab2, "class", "tabs fourTabTwo", false);
                    SetControlAttr(tab3, "class", "tabs fourTabThree", false);
                    SetControlAttr(tab4, "class", "tabs fourTabFourSelected", false);
                    SetControlAttr(tabSection, "class", "tabNavigation fourTabs", false);
                    break;
            }
        }
        /// <summary>
        /// Page prerender event handler (thrown by page master)
        /// </summary>
        private void DataGrid1_PreRender(object sender, EventArgs e)
        {
            // The archive dropdown should be invisible if the message box is displayed
            DataGrid1.Items[0].FindControl("ddlArchive").Visible = !ClientScript.IsStartupScriptRegistered("saveBox");
        }
        /// <summary>
        /// Occurs when an item is databound to the datagrid
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="e"></param>
        private void DataGrid1_ItemDataBound(object sender, DataGridItemEventArgs e)
        {
            this.SetControlAttr(e.Item.FindControl("txtDays"), "onkeyup", "digitsOnly(this);");
        }
        /// <summary>
        /// Creates a hash table with the list type enumeration names and their
        /// corresponding display values.
        /// </summary>
        private Hashtable CreateHashtable()
        {
            Hashtable hashTable = new Hashtable();
            string tableValue;

            foreach (string listType in Enum.GetNames(typeof(ListTypes)))
            {
                switch((ListTypes)Enum.Parse(typeof(ListTypes),listType))
                {
                    case ListTypes.Send:
                        tableValue = "Shipping";
                        break;
                    case ListTypes.Receive:
                        tableValue = "Receiving";
                        break;
                    case ListTypes.DisasterCode:
                        tableValue = "Disaster recovery";
                        break;
                    default:
                        tableValue = String.Empty;
                        break;
                }

                if (tableValue.Length != 0)
                {
                    hashTable.Add(listType, tableValue);
                }
            }

            return hashTable;
        }
        /// <summary>
        /// Given a list type enumeration name, gets the category display text
        /// </summary>
        public string GetListTypeName(string typeString)
        {
            Hashtable hashTable = (Hashtable)this.ViewState["Hashtable"];

            foreach (string key in hashTable.Keys)
            {
                if (typeString == key)
                {
                    return (string)hashTable[key];
                }
            }
            // Key not found - shouldn't happen
            return "An error has occurred during category parsing";
        }
        /// <summary>
        /// Saves list purge changes to database
        /// </summary>
        private void btnSave_Click(object sender, System.EventArgs e)
        {
            ListPurgeCollection listPurges = (ListPurgeCollection)this.ViewState["PurgeDetails"];
            Hashtable hashTable = (Hashtable)this.ViewState["Hashtable"];
            string[] listTypes = Enum.GetNames(typeof(ListTypes));
            // Run through the datagrid
            foreach(DataGridItem dgi in this.DataGrid1.Items)
            {
                ListPurgeDetails purgeDetails = null;
                // Find the correct list purge object
                foreach (string listType in listTypes)
                {
                    if (((Label)dgi.FindControl("lblCategory")).Text == (string)hashTable[listType])
                    {
                        ListTypes lt = (ListTypes)Enum.Parse(typeof(ListTypes), listType);
                        purgeDetails = listPurges.Find(lt);
                        break;
                    }
                }
                // If we found it, do comparison
                if (purgeDetails != null)
                {
                    // Get the days and archive values
                    int days = Convert.ToInt32(((TextBox)dgi.FindControl("txtDays")).Text);
                    bool archive = ((DropDownList)dgi.FindControl("ddlArchive")).SelectedItem.Text[0] == 'Y';
                    // If either is different, modify the purge details
                    if (days != purgeDetails.Days || archive != purgeDetails.Archive)
                    {
                        purgeDetails.Days = days;
                        purgeDetails.Archive = archive;
                    }
                }
            }
            // Update the collection
            try
            {
                ActionList.UpdatePurgeParameters(ref listPurges);
                // Replace in the viewstate
                this.ViewState["PurgeDetails"] = listPurges;
                // Purge lists from the database
                ActionList.BeginPurgeClearedLists();
                // Set the startup script
                this.ShowMessageBox("saveBox", "msgBoxSave");
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
