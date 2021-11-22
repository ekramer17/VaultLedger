using System;
using Bandl.Library.VaultLedger.Model;
using System.Runtime.Remoting.Messaging;

namespace Bandl.VaultLedger.Web.UI
{
    /// <summary>
    /// Summary description for status.
    /// </summary>
    public class status : System.Web.UI.Page   // No need to inherit from BasePage; overhead unnecessary
    {
        private void Page_Load(object sender, System.EventArgs e)
        {
            string text = String.Empty;
            // Make sure this page does not get cached
            Response.Cache.SetCacheability(System.Web.HttpCacheability.NoCache);
            // Clear the buffer
            Response.Clear();
            // Get the result from the cache
            try
            {
                if(!((IAsyncResult)Session[CacheKeys.AsyncResult]).IsCompleted)
                {
                    text = "0";
                }
                else
                {
                    text = Session[CacheKeys.Exception] != null ? "E" : "1";
                }
			}
            catch
            {
                ;
            }
            // Write the response
            Response.Write(text);
            // End the response
            Response.End();
            // If we have a completed request, remove the object from the session cache
			if (text == "E" || text == "1") Session.Remove(CacheKeys.AsyncResult);
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
		
        /// <summary>
        /// Required method for Designer support - do not modify
        /// the contents of this method with the code editor.
        /// </summary>
        private void InitializeComponent()
        {    
            this.Load += new System.EventHandler(this.Page_Load);
        }
        #endregion
    }
}
