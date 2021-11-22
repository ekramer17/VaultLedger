using System;
using System.Web;
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
    /// Summary description for case_browse.
    /// </summary>
    public class case_browse : BasePage
    {
        private SendListCaseCollection sendCases = null;
        private SealedCaseCollection sealedCases = null;
        protected System.Web.UI.WebControls.Label lblCaption;
        protected System.Web.UI.WebControls.PlaceHolder PlaceHolder1;
        protected System.Web.UI.WebControls.Button btnAdd;
        protected System.Web.UI.WebControls.DropDownList ddlSelectAction;
        protected System.Web.UI.WebControls.Button btnGo;
        protected System.Web.UI.WebControls.DataGrid DataGrid1;
        protected System.Web.UI.WebControls.Button btnYes;
        protected System.Web.UI.WebControls.Button btnSerialOK;
        protected System.Web.UI.HtmlControls.HtmlInputButton btnOK;
        protected System.Web.UI.WebControls.TextBox txtReturnDate;
        protected System.Web.UI.WebControls.TextBox txtNewSerial;

        private void InitializeComponent()
        {
            this.btnGo.Click += new System.EventHandler(this.btnGo_Click);
            this.DataGrid1.ItemCommand += new System.Web.UI.WebControls.DataGridCommandEventHandler(this.DataGrid1_ItemCommand);
            this.btnYes.Click += new System.EventHandler(this.btnYes_Click);
            this.btnSerialOK.Click += new System.EventHandler(this.btnSerialOK_Click);
            this.btnOK.ServerClick += new System.EventHandler(this.btnOK_ServerClick);
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
            // Click events for message box buttons
            this.SetControlAttr(this.btnYes, "onclick", "hideMsgBox('msgBoxDelete');");
            this.SetControlAttr(this.btnOK, "onclick", "hideMsgBox('msgBoxReturnDate');");
            this.SetControlAttr(this.btnSerialOK, "onclick", "hideMsgBox('msgBoxSerial');");
            // Load the page
            if (Page.IsPostBack)
            {
                sendCases = (SendListCaseCollection)this.ViewState["SendCases"];
                sealedCases = (SealedCaseCollection)this.ViewState["SealedCases"];
            }
            else
            {
                try
                {
                    this.ObtainItems();
                }
                catch
                {
                    Response.Redirect(@"..\default.aspx", false);
                }
            }
            // Security
            if (CustomPermission.CurrentOperatorRole() != Role.Administrator)
                ddlSelectAction.Items.Remove(ddlSelectAction.Items.FindByValue("EditSerial"));
        }
        /// <summary>
        /// Page load event handler (thrown by page master)
        /// </summary>
        private void ObtainItems()
        {
            DataTable d = new DataTable();
            d.Columns.Add("CaseName", typeof(string));
            d.Columns.Add("CaseType", typeof(string));
            d.Columns.Add("NumTapes", typeof(string));
            d.Columns.Add("Sealed", typeof(string));
            d.Columns.Add("Location", typeof(string));
            d.Columns.Add("ReturnDate", typeof(string));
            d.Columns.Add("ListName", typeof(string));
            // Get the data
            sendCases = SendList.GetSendListCases();
            sealedCases = SealedCase.GetSealedCases();
            ViewState["SealedCases"] = sealedCases;
            ViewState["SendCases"] = sendCases;
            // If no data, display none found
            if (sendCases.Count == 0 && sealedCases.Count == 0)
            {
                DataGrid1.Columns[2].Visible = false;
                d.Rows.Add(new object[] { "No cases found", "", "", "", "", "", "" });
            }
            else
            {
                DataGrid1.Columns[1].Visible = false;
                // Add the send list cases
                foreach (SendListCaseDetails c in sendCases)
                    d.Rows.Add(new object[] { c.Name, c.Type, c.NumTapes.ToString(), c.Sealed ? "Yes" : "No", Locations.Enterprise.ToString(), c.ReturnDate, c.ListName });
                // Add the sealed cases
                foreach (SealedCaseDetails c in sealedCases)
                    d.Rows.Add(new object[] { c.CaseName, c.CaseType, c.NumTapes.ToString(), "Yes", Locations.Vault.ToString(), c.ReturnDate, c.ListName });
            }
            // Bind to the datagrid
            DataView v = new DataView(d);
            v.Sort = "CaseName ASC";
            DataGrid1.DataSource = v;
            DataGrid1.DataBind();
        }
        /// <summary>
        /// Event handler for the Go button
        /// </summary>
        private void btnGo_Click(object sender, System.EventArgs e)
        {
            if (this.CollectCheckedItems(this.DataGrid1).Length != 0)
            {
                switch (this.ddlSelectAction.SelectedValue)
                {
                    case "Delete":
                        this.ShowMessageBox("msgBoxDelete");
                        break;
                    case "EditReturn":
                        this.ShowMessageBox("msgBoxReturnDate");
                        ClientScript.RegisterStartupScript(GetType(), "enableCalendar", "<script language=javascript>getObjectById('calendar').onclick = Function(\"return true;\")</script>");
                        break;
                    case "EditSerial":
                        this.ShowMessageBox("msgBoxSerial");
                        break;
                    default:
                        break;
                }
            }
        }
        /// <summary>
        /// Deletes empty sealed cases from the database
        /// </summary>
        private void btnYes_Click(object sender, System.EventArgs e)
        {
            SealedCaseCollection c = new SealedCaseCollection();
            // Only empty sealed cases may be deleted
            foreach (DataGridItem i in this.CollectCheckedItems(this.DataGrid1))
            {
                SealedCaseDetails d = null;
                // Get the case name
                string caseName = i.Cells[1].Text;
                // If case is not an empty sealed case, raise error
                if ((d = sealedCases.Find(caseName)) == null || d.NumTapes != 0)
                {
                    DisplayErrors(PlaceHolder1, "Only empty sealed cases may be deleted.  Case " + caseName + " is not an empty sealed case.");
                    return;
                }
                else
                {
                    c.Add(d);
                }
            }
            // Delete the cases
            try
            {
                foreach (SealedCaseDetails d1 in c)
                    SealedCase.Delete(d1);
                // Obtain cases
                this.ObtainItems();
            }
            catch (Exception ex)
            {
                DisplayErrors(PlaceHolder1, ex.Message);
            }
        }
        /// <summary>
        /// Changes a case serial number
        /// </summary>
        private void btnSerialOK_Click(object sender, System.EventArgs e)
        {
            DataGridItem[] i = this.CollectCheckedItems(this.DataGrid1);
            // Should only be one
            if (i.Length > 1)
            {
                DisplayErrors(PlaceHolder1, "Please only select one case when changing a serial number");
            }
            else
            {
                string caseName = i[0].Cells[1].Text;
                SealedCaseDetails d = SealedCase.GetSealedCase(caseName);

                if (d == null)
                {
                    DisplayErrors(PlaceHolder1, "Only sealed cases at the vault may have their serial numbers changed");
                }
                else
                {
                    SealedCaseCollection c = new SealedCaseCollection();
                    d.CaseName = txtNewSerial.Text.Trim();
                    c.Add(d);
                    // Update the case
                    try
                    {
                        SealedCase.Update(ref c);
                        this.ObtainItems();
                    }
                    catch (Exception ex)
                    {
                        DisplayErrors(PlaceHolder1, ex.Message);
                    }
                }
            }
        }
        /// <summary>
        /// Changes the return date of selected cases
        /// </summary>
        private void btnOK_ServerClick(object sender, System.EventArgs e)
        {
            SealedCaseDetails d1 = null;
            SendListCaseDetails d2 = null;
            SealedCaseCollection c1 = new SealedCaseCollection();
            SendListCaseCollection c2 = new SendListCaseCollection();
            // Get all the cases from the list.  To be eligible for return date change, sealed cases cannot be on a receive list,
            // and send list cases cannot have already been transmitted.
            try
            {
                foreach (DataGridItem i in this.CollectCheckedItems(this.DataGrid1))
                {
                    // Get the case name
                    string caseName = i.Cells[1].Text;
                    // Get the case
                    if ((d1 = sealedCases.Find(caseName)) != null)
                    {
                        if (d1.ListName.Length != 0)
                        {
                            DisplayErrors(PlaceHolder1, "Case " + caseName + " is on receiving list " + d1.ListName + " and cannot have its return date changed.");
                            return;
                        }
                        // Add to the collection
                        d1.ReturnDate = txtReturnDate.Text;
                        c1.Add(d1);
                    }
                    else if ((d2 = sendCases.Find(caseName)) != null)
                    {
                        // Make sure the case is sealed
                        if (d2.Sealed == false)
                        {
                            DisplayErrors(PlaceHolder1, "Case " + caseName + " is not marked as sealed.  Only sealed cases may have a return date.");
                            return;
                        }
                        else
                        {
                            SendListDetails s = SendList.GetSendList(d2.ListName, false);
                            if (s != null & s.Status >= SLStatus.Xmitted)
                            {
                                DisplayErrors(PlaceHolder1, "Case " + caseName + " may not have its return date changed due to the status of list " + d2.ListName + " (too late).");
                                return;
                            }
                            else
                            {
                                // Add to the collection
                                d2.ReturnDate = txtReturnDate.Text;
                                c2.Add(d2);
                            }
                        }
                    }
                    // Change the return date for all the sealed cases, then all the send list cases
                    if (c1.Count != 0) SealedCase.Update(ref c1);
                    if (c2.Count != 0) SendList.UpdateCases(ref c2);
                    // Refetch
                    this.ObtainItems();
                }
            }
            catch (Exception ex)
            {
                DisplayErrors(PlaceHolder1, ex.Message);
            }
        }
        /// <summary>
        /// Event handler used to transfer to media detail page on linkbutton click
        /// </summary>
        private void DataGrid1_ItemCommand(object source, DataGridCommandEventArgs e)
        {
            if (e.CommandSource.GetType() == typeof(LinkButton))
            {
                if (e.CommandName == "casePage")
                {
                    // Is the case a sealed case or send list case?
                    string x = sealedCases.Find(e.CommandArgument.ToString()) != null ? "1" : "0";
                    Response.Redirect(@"case-detail.aspx?caseName=" + e.CommandArgument.ToString() + "&sealed=" + x);
                }
                else
                {
                    if (e.CommandArgument.ToString().StartsWith("SD"))
                    {
                        string url = String.Format(@"{0}\media-library\case-browse.aspx", HttpRuntime.AppDomainAppVirtualPath);
                        Response.Redirect(@"..\lists\shipping-list-detail.aspx?listNumber=" + e.CommandArgument + "&backUrl=" + url + "&backCaption=Cases&backLeft=545", false);
                    }
                    else
                    {
                        string url = String.Format(@"{0}\media-library\case-browse.aspx", HttpRuntime.AppDomainAppVirtualPath);
                        Response.Redirect(@"..\lists\receiving-list-detail.aspx?listNumber=" + e.CommandArgument + "&backUrl=" + url + "&backCaption=Cases&backLeft=545", false);
                    }
                }
            }
        }
    }
}
