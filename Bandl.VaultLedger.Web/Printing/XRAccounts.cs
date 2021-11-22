using System;
using System.Drawing;
using System.Collections;
using System.ComponentModel;
using DevExpress.XtraReports.UI;

namespace Bandl.VaultLedger.Web.Printing
{
	/// <summary>
	/// Summary description for XRAccounts.
	/// </summary>
	public class XRAccounts : XRTemplate
	{
		private DevExpress.XtraReports.UI.XRLabel xrLabel1;
		private DevExpress.XtraReports.UI.XRLabel xrLabel2;
		private DevExpress.XtraReports.UI.XRLabel xrLabel3;
		private DevExpress.XtraReports.UI.XRLabel xrLabel4;
		private DevExpress.XtraReports.UI.XRLabel xrLabel5;
		private DevExpress.XtraReports.UI.DetailReportBand DetailReport;
		private DevExpress.XtraReports.UI.DetailBand Detail1;
		private DevExpress.XtraReports.UI.XRLabel xrLabel6;
		private DevExpress.XtraReports.UI.XRLabel xrLabel8;
		private DevExpress.XtraReports.UI.XRLabel xrLabel9;
		private DevExpress.XtraReports.UI.XRLabel xrLabel10;

		/// <summary>
		/// Required designer variable.
		/// </summary>
		private System.ComponentModel.Container components = null;

		private int iRowCount;

		public XRAccounts()
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
			this.xrLabel4 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel5 = new DevExpress.XtraReports.UI.XRLabel();
			this.DetailReport = new DevExpress.XtraReports.UI.DetailReportBand();
			this.Detail1 = new DevExpress.XtraReports.UI.DetailBand();
			this.xrLabel10 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel9 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel8 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel6 = new DevExpress.XtraReports.UI.XRLabel();
			((System.ComponentModel.ISupportInitialize)(this)).BeginInit();
			// 
			// Detail
			// 
			this.Detail.ParentStyleUsing.UseFont = false;
			// 
			// PageHeader
			// 
			this.PageHeader.Controls.AddRange(new DevExpress.XtraReports.UI.XRControl[] {
																							this.xrLabel4,
																							this.xrLabel3,
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
																							  this.xrLabel5});
			this.ReportFooter.ParentStyleUsing.UseFont = false;
			// 
			// xrLabel1
			// 
			this.xrLabel1.Font = new System.Drawing.Font("Arial", 10.2F, ((System.Drawing.FontStyle)((System.Drawing.FontStyle.Bold | System.Drawing.FontStyle.Underline))), System.Drawing.GraphicsUnit.Point, ((System.Byte)(0)));
			this.xrLabel1.Location = new System.Drawing.Point(7, 93);
			this.xrLabel1.Name = "xrLabel1";
			this.xrLabel1.ParentStyleUsing.UseFont = false;
			this.xrLabel1.Size = new System.Drawing.Size(133, 20);
			this.xrLabel1.Text = "Account Number";
			// 
			// xrLabel2
			// 
			this.xrLabel2.Font = new System.Drawing.Font("Arial", 10.2F, ((System.Drawing.FontStyle)((System.Drawing.FontStyle.Bold | System.Drawing.FontStyle.Underline))), System.Drawing.GraphicsUnit.Point, ((System.Byte)(0)));
			this.xrLabel2.Location = new System.Drawing.Point(187, 93);
			this.xrLabel2.Name = "xrLabel2";
			this.xrLabel2.ParentStyleUsing.UseFont = false;
			this.xrLabel2.Size = new System.Drawing.Size(100, 20);
			this.xrLabel2.Text = "City";
			// 
			// xrLabel3
			// 
			this.xrLabel3.Font = new System.Drawing.Font("Arial", 10.2F, ((System.Drawing.FontStyle)((System.Drawing.FontStyle.Bold | System.Drawing.FontStyle.Underline))), System.Drawing.GraphicsUnit.Point, ((System.Byte)(0)));
			this.xrLabel3.Location = new System.Drawing.Point(340, 93);
			this.xrLabel3.Name = "xrLabel3";
			this.xrLabel3.ParentStyleUsing.UseFont = false;
			this.xrLabel3.Size = new System.Drawing.Size(113, 20);
			this.xrLabel3.Text = "State/Province";
			// 
			// xrLabel4
			// 
			this.xrLabel4.Font = new System.Drawing.Font("Arial", 10.2F, ((System.Drawing.FontStyle)((System.Drawing.FontStyle.Bold | System.Drawing.FontStyle.Underline))), System.Drawing.GraphicsUnit.Point, ((System.Byte)(0)));
			this.xrLabel4.Location = new System.Drawing.Point(500, 93);
			this.xrLabel4.Name = "xrLabel4";
			this.xrLabel4.ParentStyleUsing.UseFont = false;
			this.xrLabel4.Size = new System.Drawing.Size(100, 20);
			this.xrLabel4.Text = "Telephone";
			// 
			// xrLabel5
			// 
			this.xrLabel5.Font = new System.Drawing.Font("Arial", 10.2F, System.Drawing.FontStyle.Bold, System.Drawing.GraphicsUnit.Point, ((System.Byte)(0)));
			this.xrLabel5.Location = new System.Drawing.Point(20, 7);
			this.xrLabel5.Name = "xrLabel5";
			this.xrLabel5.ParentStyleUsing.UseFont = false;
			this.xrLabel5.Size = new System.Drawing.Size(260, 20);
			this.xrLabel5.Text = "xrLabel5";
			this.xrLabel5.BeforePrint += new System.Drawing.Printing.PrintEventHandler(this.xrLabel5_BeforePrint);
			// 
			// DetailReport
			// 
			this.DetailReport.Bands.AddRange(new DevExpress.XtraReports.UI.Band[] {
																					  this.Detail1});
			this.DetailReport.DataMember = "Account";
			this.DetailReport.Name = "DetailReport";
			// 
			// Detail1
			// 
			this.Detail1.Controls.AddRange(new DevExpress.XtraReports.UI.XRControl[] {
																						 this.xrLabel10,
																						 this.xrLabel9,
																						 this.xrLabel8,
																						 this.xrLabel6});
			this.Detail1.Height = 16;
			this.Detail1.Name = "Detail1";
			this.Detail1.AfterPrint += new System.EventHandler(this.Detail1_AfterPrint);
			// 
			// xrLabel10
			// 
			this.xrLabel10.DataBindings.AddRange(new DevExpress.XtraReports.UI.XRBinding[] {
																							   new DevExpress.XtraReports.UI.XRBinding("Text", null, "Account.Name", "")});
			this.xrLabel10.Font = new System.Drawing.Font("Arial", 10.2F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((System.Byte)(0)));
			this.xrLabel10.Location = new System.Drawing.Point(7, 0);
			this.xrLabel10.Name = "xrLabel10";
			this.xrLabel10.ParentStyleUsing.UseFont = false;
			this.xrLabel10.Size = new System.Drawing.Size(100, 16);
			this.xrLabel10.Text = "xrLabel10";
			// 
			// xrLabel9
			// 
			this.xrLabel9.DataBindings.AddRange(new DevExpress.XtraReports.UI.XRBinding[] {
																							  new DevExpress.XtraReports.UI.XRBinding("Text", null, "Account.PhoneNo", "")});
			this.xrLabel9.Font = new System.Drawing.Font("Arial", 10.2F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((System.Byte)(0)));
			this.xrLabel9.Location = new System.Drawing.Point(500, 0);
			this.xrLabel9.Name = "xrLabel9";
			this.xrLabel9.ParentStyleUsing.UseFont = false;
			this.xrLabel9.Size = new System.Drawing.Size(100, 16);
			this.xrLabel9.Text = "xrLabel9";
			// 
			// xrLabel8
			// 
			this.xrLabel8.DataBindings.AddRange(new DevExpress.XtraReports.UI.XRBinding[] {
																							  new DevExpress.XtraReports.UI.XRBinding("Text", null, "Account.State", "")});
			this.xrLabel8.Font = new System.Drawing.Font("Arial", 10.2F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((System.Byte)(0)));
			this.xrLabel8.Location = new System.Drawing.Point(340, 0);
			this.xrLabel8.Name = "xrLabel8";
			this.xrLabel8.ParentStyleUsing.UseFont = false;
			this.xrLabel8.Size = new System.Drawing.Size(100, 16);
			this.xrLabel8.Text = "xrLabel8";
			// 
			// xrLabel6
			// 
			this.xrLabel6.DataBindings.AddRange(new DevExpress.XtraReports.UI.XRBinding[] {
																							  new DevExpress.XtraReports.UI.XRBinding("Text", null, "Account.City", "")});
			this.xrLabel6.Font = new System.Drawing.Font("Arial", 10.2F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((System.Byte)(0)));
			this.xrLabel6.Location = new System.Drawing.Point(187, 0);
			this.xrLabel6.Name = "xrLabel6";
			this.xrLabel6.ParentStyleUsing.UseFont = false;
			this.xrLabel6.Size = new System.Drawing.Size(100, 16);
			this.xrLabel6.Text = "xrLabel6";
			// 
			// XRAccounts
			// 
			this.Bands.AddRange(new DevExpress.XtraReports.UI.Band[] {
																		 this.DetailReport});
			((System.ComponentModel.ISupportInitialize)(this)).EndInit();

		}
		#endregion

		private void Detail1_AfterPrint(object sender, System.EventArgs e)
		{
			iRowCount++;
		}

		private void xrLabel5_BeforePrint(object sender, System.Drawing.Printing.PrintEventArgs e)
		{
			XRLabel label = sender as XRLabel;
			label.Text = "Total Account Records: " + iRowCount.ToString();		
		}
	}
}

