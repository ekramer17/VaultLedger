using System;
using System.Web;
using System.Text;
using System.Drawing;
using System.Web.UI.WebControls;
using Bandl.Library.VaultLedger.Model;

namespace Bandl.VaultLedger.Web.UI
{
	/// <summary>
	/// Summary description for calendar.
	/// </summary>
	public class calendarPage : System.Web.UI.Page
	{
        protected Bandl.Web.UI.WebControls.BandlCalendar Calendar1;

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
            this.Calendar1.DayRender += new System.Web.UI.WebControls.DayRenderEventHandler(this.Calendar1_DayRender);
            this.Calendar1.SelectionChanged += new System.EventHandler(this.Calendar1_SelectionChanged);
            this.PreRender += new System.EventHandler(this.Page_PreRender);

        }
		#endregion

        private void Page_PreRender(object sender, EventArgs e)
        {
            switch (Configurator.ProductType)
            {
                case "B&L":
                case "BANDL":
                case "IMATION":
                    Calendar1.TitleStyle.BackColor = Color.Maroon;
                    Calendar1.DayHeaderStyle.ForeColor = Color.Black;
                    Calendar1.DayHeaderStyle.BackColor = Color.FromArgb(242,217,157);
                    break;
                default:
                    break;
            }
        }

        private void Calendar1_DayRender(object sender, DayRenderEventArgs e)
        {
            if (e.Day.Date.ToString("yyyyMMdd") == Time.Local.ToString("yyyyMMdd"))
                e.Cell.BackColor = Color.LightGray;
        }

        private void Calendar1_SelectionChanged(object sender, System.EventArgs e)
        {
            StringBuilder scriptText = new StringBuilder();
            scriptText.Append("<script language=\"javascript\">");
            scriptText.Append("window.opener.getObjectById('");
            scriptText.Append(HttpContext.Current.Request.QueryString["controlName"]);
            scriptText.Append("').value = '");
            scriptText.Append(Date.Display(Calendar1.SelectedDate, false));
            scriptText.Append("';window.close()");
            scriptText.Append("</script>");
            ClientScript.RegisterStartupScript(GetType(), "DatePicked", scriptText.ToString());

        }
    }
}
