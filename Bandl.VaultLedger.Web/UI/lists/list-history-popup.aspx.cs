using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using Bandl.Library.VaultLedger.BLL;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.Collections;

namespace Bandl.VaultLedger.Web.UI.lists
{
	public partial class list_history_popup : BasePage
	{
        private int pageNo = 1;
        private int pageTotal = -100;
        private AuditTrailCollection atc = null;

        private void InitializeComponent()
        {
            this.enterGoto.ServerChange += new System.EventHandler(enterGoto_ServerChange);
        }

        protected override void Event_PageLoad(object sender, System.EventArgs e)
        {
            this.SetControlAttr(this.txtPageGoto, "onkeyup", "digitsOnly(this);");
            this.SetControlAttr(this.txtPageGoto, "onkeypress", "if (keyCode() == 13) document.getElementById('enterGoto').value = this.value;");

            if (Page.IsPostBack)
            {
                pageNo = (int)this.ViewState["PageNo"];
                pageTotal = (int)this.ViewState["PageTotal"];
                atc = (AuditTrailCollection)this.ViewState["AuditTrail"];
            }
            else
            {
                String listName = Request.QueryString["listName"];
                this.pageTitle = "List History | " + listName;

                if (listName.StartsWith("R"))
                    atc = ReceiveList.GetHistory(listName);
                else
                    atc = SendList.GetHistory(listName);
                this.ViewState["AuditTrail"] = atc;
            }

            Fetch(pageNo);
        }

        /// <summary>
        /// Fetches the search results from the database
        /// </summary>
        private void Fetch(int pageNo)
        {
            AuditTrailCollection resultSet = new AuditTrailCollection();

            int pageSize = 50;
            int totalItems = atc.Count;

            if (pageTotal == -100) 
                pageTotal = (totalItems / pageSize) + (totalItems % pageSize != 0 ? 1 : 0);


            if (totalItems <= (pageNo - 1) * pageSize)
                pageNo = pageTotal == 0 ? 1 : pageTotal;

            for (int i = 0; i < pageSize; ++i)
            {
                int index = (pageNo - 1) * pageSize + i;
                if (index >= totalItems)
                    break;
                else
                    resultSet.Add(atc[(pageNo - 1) * pageSize + i]);
            }

            this.ViewState["PageNo"] = pageNo;
            this.ViewState["PageTotal"] = pageTotal;

            DataGrid1.DataSource = resultSet;
            DataGrid1.DataBind();

            this.lnkPagePrev.Enabled = pageNo != 1;
            this.lnkPageFirst.Enabled = pageNo != 1;
            this.lnkPageNext.Enabled = pageNo != pageTotal;
            this.lnkPageLast.Enabled = pageNo != pageTotal;
            this.lblPage.Text = String.Format("Page {0} of {1}", pageNo, pageTotal);
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
            // Fetch
            this.Fetch(pageNo);
        }

        /// <summary>
        /// Event handler for the hidden control field change, which tells us that we
        /// should get a new page of items.
        /// </summary>
        private void enterGoto_ServerChange(object sender, System.EventArgs e)
        {
            if (this.txtPageGoto.Text.Length != 0)
            {
                pageNo = Int32.Parse(this.txtPageGoto.Text);
                this.txtPageGoto.Text = String.Empty;
                this.Fetch(pageNo);
            }
        }

    }
}