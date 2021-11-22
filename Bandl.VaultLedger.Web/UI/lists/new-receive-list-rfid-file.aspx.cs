using System;
using System.Web;
using Bandl.Library.VaultLedger.BLL;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.Collections;
using Bandl.Library.VaultLedger.Common.Knock;

namespace Bandl.VaultLedger.Web.UI
{
	/// <summary>
	/// Summary description for new_receive_list_rfid_file.
	/// </summary>
	public class new_receive_list_rfid_file : BasePage
	{
        protected System.Web.UI.WebControls.PlaceHolder PlaceHolder1;
        protected System.Web.UI.WebControls.Button btnOK;
        protected System.Web.UI.HtmlControls.HtmlInputFile File1;

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
            this.btnOK.Click += new System.EventHandler(this.btnOK_Click);

        }
		#endregion
	
        /// <summary>
        /// Page initialization event handler (thrown by page master)
        /// </summary>
        protected override void Event_PageInit(object sender, System.EventArgs e)
        {
            this.pageTitle = "New Receiving List";
            this.levelTwo = LevelTwoNav.Receiving;
            this.helpId = 16;
            // Viewers and auditors shouldn't be able to access this page
            DoSecurity(Role.Operator, "default.aspx");
        }
        /// <summary>
        /// Page prerender event handler (thrown by page master)
        /// </summary>
        protected override void Event_PagePreRender(object sender, System.EventArgs e)
        {
            // Set the tab page preference
            TabPageDefault.Update(TabPageDefaults.NewReceiveList, Session[CacheKeys.CurrentLogin], 3);
        }
        /// <summary>
        /// Event handler for OK button
        /// </summary>
        private void btnOK_Click(object sender, System.EventArgs e)
        {
            string fileName = File1.Value;
            HttpPostedFile postedFile = File1.PostedFile;
 
            if (File1.Value.Trim().Length != 0)
            {
                if ((postedFile = File1.PostedFile) == null || postedFile.ContentLength == 0)
                {
                    this.DisplayErrors(this.PlaceHolder1, "Unable to find or access '" + File1.Value + "'");
                }
                else
                {
                    try 
                    {
                        // Read the file
                        byte[] inputFile = new byte[postedFile.ContentLength];
                        postedFile.InputStream.Read(inputFile, 0, postedFile.ContentLength);
                        // Create the lists
                        ReceiveListCollection r = Imation.CreateReceiveList(inputFile);
                        // Transfer to the correct page
                        if (r.Count != 0)
                            Server.Transfer("receiving-list-detail.aspx?listNumber=" + r[0].Name);
                        else
                            DisplayErrors(PlaceHolder1, "No list was produced");
                    }
                    catch (Exception ex)
                    {
                        this.DisplayErrors(this.PlaceHolder1, ex.Message);
                    }
                }
            }    
        }
    }
}
