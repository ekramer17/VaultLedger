using System;
using System.Runtime.Remoting.Messaging;
using Bandl.Utility.VaultLedger.Registrar.Model;

namespace Bandl.Utility.VaultLedger.Registrar.UI
{
	/// <summary>
	/// Summary description for status.
	/// </summary>
	public class status : System.Web.UI.Page
	{
		private void Page_Load(object sender, System.EventArgs e)
		{
            // Make sure this page does not get cached
            Response.Cache.SetCacheability(System.Web.HttpCacheability.NoCache);
            // Clear the buffer
            Response.Clear();
            // Get the result from the cache
            AsyncResult r = (AsyncResult)Session[CacheKeys.AsyncResult];
            // If not yet complete, write zero to the response stream.  Otherwise
            // write one and remove the result from the session cache.
            if(!r.IsCompleted)
            {
                Response.Write("0");
            }
            else
            {
                Session.Remove(CacheKeys.AsyncResult);
                Response.Write(Session[CacheKeys.Exception] != null ? "E" : "1");
            }
            // End the response
            Response.End();
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
