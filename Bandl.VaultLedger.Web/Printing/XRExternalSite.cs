using System;
using System.Drawing;
using System.Collections;
using System.ComponentModel;
using DevExpress.XtraReports.UI;

namespace Bandl.VaultLedger.Web.Printing
{
	/// <summary>
	/// Summary description for XRExternalSite.
	/// </summary>
	public class XRExternalSite : XRTemplate
	{
		private DevExpress.XtraReports.UI.XRLabel xrLabel1;
		private DevExpress.XtraReports.UI.XRLabel xrLabel2;
		private DevExpress.XtraReports.UI.XRLabel xrLabel3;
		private DevExpress.XtraReports.UI.DetailReportBand DetailReport;
		private DevExpress.XtraReports.UI.DetailBand Detail1;
		private DevExpress.XtraReports.UI.XRLabel xrLabel4;
		private DevExpress.XtraReports.UI.XRLabel xrLabel5;
		/// <summary>
		/// Required designer variable.
		/// </summary>
		private System.ComponentModel.Container components = null;

		private int iRowCount;

		public XRExternalSite()
		{
			//
			// Required for Designer support
			//
			InitializeComponent();

			//
			// TODO: Add any constructor code after InitializeComponent call
			//
		}

		/// <summary>
		/// Clean up any resources being used.
		/// </summary>
		protected override void Dispose( bool disposing )
		{
			if( disposing )
			{
				if(components != null)
				{
					components.Dispose();
				}
			}
			base.Dispose( disposing );
		}

		#region Designer generated code
		/// <summary>
		/// Required method for Designer support - do not modify
		/// the contents of this method with the code editor.
		/// </summary>
		private void InitializeComponent()
		{
			this.xrLabel1 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel2 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel3 = new DevExpress.XtraReports.UI.XRLabel();
			this.DetailReport = new DevExpress.XtraReports.UI.DetailReportBand();
			this.Detail1 = new DevExpress.XtraReports.UI.DetailBand();
			this.xrLabel5 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel4 = new DevExpress.XtraReports.UI.XRLabel();
			((System.ComponentModel.ISupportInitialize)(this)).BeginInit();
			// 
			// Detail
			// 
			this.Detail.ParentStyleUsing.UseFont = false;
			// 
			// PageHeader
			// 
			this.PageHeader.Controls.AddRange(new DevExpress.XtraReports.UI.XRControl[] {
																							this.xrLabel2,
																							this.xrLabel1});
			this.PageHeader.Height = 113;
			this.PageHeader.ParentStyleUsing.UseFont = false;
			// 
			// PageFooter
			// 
			this.PageFooter.ParentStyleUsing.UseFont = false;
			// 
			// xrLabel7
			// 
			this.xrLabel7.ParentStyleUsing.UseFont = false;
			// 
			// xrPageInfo1
			// 
			this.xrPageInfo1.ParentStyleUsing.UseFont = false;
			// 
			// ReportFooter
			// 
			this.ReportFooter.Controls.AddRange(new DevExpress.XtraReports.UI.XRControl[] {
																							  this.xrLabel3});
			this.ReportFooter.ParentStyleUsing.UseFont = false;
			// 
			// xrLabel1
			// 
			this.xrLabel1.Font = new System.Drawing.Font("Arial", 10.2F, ((System.Drawing.FontStyle)((System.Drawing.FontStyle.Bold | System.Drawing.FontStyle.Underline))), System.Drawing.GraphicsUnit.Point, ((System.Byte)(0)));
			this.xrLabel1.Location = new System.Drawing.Point(7, 93);
			this.xrLabel1.Name = "xrLabel1";
			this.xrLabel1.ParentStyleUsing.UseFont = false;
			this.xrLabel1.Size = new System.Drawing.Size(100, 20);
			this.xrLabel1.Text = "Site Name";
			// 
			// xrLabel2
			// 
			this.xrLabel2.Font = new System.Drawing.Font("Arial", 10.2F, ((System.Drawing.FontStyle)((System.Drawing.FontStyle.Bold | System.Drawing.FontStyle.Underline))), System.Drawing.GraphicsUnit.Point, ((System.Byte)(0)));
			this.xrLabel2.Location = new System.Drawing.Point(180, 93);
			this.xrLabel2.Name = "xrLabel2";
			this.xrLabel2.ParentStyleUsing.UseFont = false;
			this.xrLabel2.Size = new System.Drawing.Size(100, 20);
			this.xrLabel2.Text = "Location";
			// 
			// xrLabel3
			// 
			this.xrLabel3.Font = new System.Drawing.Font("Arial", 10.2F, System.Drawing.FontStyle.Bold, System.Drawing.GraphicsUnit.Point, ((System.Byte)(0)));
			this.xrLabel3.Location = new System.Drawing.Point(20, 7);
			this.xrLabel3.Name = "xrLabel3";
			this.xrLabel3.ParentStyleUsing.UseFont = false;
			this.xrLabel3.Size = new System.Drawing.Size(260, 26);
			this.xrLabel3.Text = "xrLabel3";
			this.xrLabel3.BeforePrint += new System.Drawing.Printing.PrintEventHandler(this.xrLabel3_BeforePrint);
			// 
			// DetailReport
			// 
			this.DetailReport.Bands.AddRange(new DevExpress.XtraReports.UI.Band[] {
																					  this.Detail1});
			this.DetailReport.DataMember = "ExternalSite";
			this.DetailReport.Name = "DetailReport";
			// 
			// Detail1
			// 
			this.Detail1.Controls.AddRange(new DevExpress.XtraReports.UI.XRControl[] {
																						 this.xrLabel5,
																						 this.xrLabel4});
			this.Detail1.Height = 16;
			this.Detail1.Name = "Detail1";
			this.Detail1.AfterPrint += new System.EventHandler(this.Detail1_AfterPrint);
			// 
			// xrLabel5
			// 
			this.xrLabel5.DataBindings.AddRange(new DevExpress.XtraReports.UI.XRBinding[] {
																							  new DevExpress.XtraReports.UI.XRBinding("Text", null, "ExternalSite.Location", "")});
			this.xrLabel5.Font = new System.Drawing.Font("Arial", 10.2F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((System.Byte)(0)));
			this.xrLabel5.Location = new System.Drawing.Point(180, 0);
			this.xrLabel5.Name = "xrLabel5";
			this.xrLabel5.ParentStyleUsing.UseFont = false;
			this.xrLabel5.Size = new System.Drawing.Size(100, 16);
			this.xrLabel5.Text = "xrLabel5";
			// 
			// xrLabel4
			// 
			this.xrLabel4.DataBindings.AddRange(new DevExpress.XtraReports.UI.XRBinding[] {
																							  new DevExpress.XtraReports.UI.XRBinding("Text", null, "ExternalSite.SiteName", "")});
			this.xrLabel4.Font = new System.Drawing.Font("Arial", 10.2F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((System.Byte)(0)));
			this.xrLabel4.Location = new System.Drawing.Point(7, 0);
			this.xrLabel4.Name = "xrLabel4";
			this.xrLabel4.ParentStyleUsing.UseFont = false;
			this.xrLabel4.Size = new System.Drawing.Size(100, 16);
			this.xrLabel4.Text = "xrLabel4";
			// 
			// XRExternalSite
			// 
			this.Bands.AddRange(new DevExpress.XtraReports.UI.Band[] {
																		 this.DetailReport});
			this.Font = new System.Drawing.Font("Arial", 10.2F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((System.Byte)(0)));
			((System.ComponentModel.ISupportInitialize)(this)).EndInit();

		}
		#endregion

		private void xrLabel3_BeforePrint(object sender, System.Drawing.Printing.PrintEventArgs e)
		{
			XRLabel label = sender as XRLabel;
			label.Text = "Total Site Map Records: " + iRowCount.ToString();		
		}

		private void Detail1_AfterPrint(object sender, System.EventArgs e)
		{
			iRowCount++;
		}
	}
}

