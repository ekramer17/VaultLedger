using System;
using System.Drawing;
using System.Collections;
using System.ComponentModel;
using DevExpress.XtraReports.UI;

namespace Bandl.VaultLedger.Web.Printing
{
	/// <summary>
	/// Summary description for XRFindMedium.
	/// </summary>
	public class XRFindMedium : XRTemplate
	{
		private DevExpress.XtraReports.UI.XRLabel xrLabel31;
		private DevExpress.XtraReports.UI.XRLabel xrLabel26;
		private DevExpress.XtraReports.UI.XRLabel xrLabel29;
		private DevExpress.XtraReports.UI.XRLabel xrLabel25;
		private DevExpress.XtraReports.UI.XRLabel xrLabel32;
		private DevExpress.XtraReports.UI.XRLabel xrLabel30;
		private DevExpress.XtraReports.UI.XRLabel xrLabel27;
		private DevExpress.XtraReports.UI.XRLabel xrLabel28;
		private DevExpress.XtraReports.UI.DetailReportBand DetailReport;
		private DevExpress.XtraReports.UI.DetailBand Detail1;
		private DevExpress.XtraReports.UI.XRLabel xrLabel3;
		private DevExpress.XtraReports.UI.XRLabel xrLabel4;
		private DevExpress.XtraReports.UI.XRLabel xrLabel5;
		private DevExpress.XtraReports.UI.XRLabel xrLabel6;
		private DevExpress.XtraReports.UI.XRLabel xrLabel8;
		private DevExpress.XtraReports.UI.XRLabel xrLabel9;
		private DevExpress.XtraReports.UI.XRLabel xrLabel10;
		private DevExpress.XtraReports.UI.XRLabel xrLabel11;
		/// <summary>
		/// Required designer variable.
		/// </summary>
		private System.ComponentModel.Container components = null;

		public XRFindMedium()
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
			this.xrLabel31 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel26 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel29 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel25 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel32 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel30 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel27 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel28 = new DevExpress.XtraReports.UI.XRLabel();
			this.DetailReport = new DevExpress.XtraReports.UI.DetailReportBand();
			this.Detail1 = new DevExpress.XtraReports.UI.DetailBand();
			this.xrLabel11 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel10 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel9 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel8 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel6 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel5 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel4 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel3 = new DevExpress.XtraReports.UI.XRLabel();
			((System.ComponentModel.ISupportInitialize)(this)).BeginInit();
			// 
			// Detail
			// 
			this.Detail.ParentStyleUsing.UseFont = false;
			// 
			// PageHeader
			// 
			this.PageHeader.Controls.AddRange(new DevExpress.XtraReports.UI.XRControl[] {
																							this.xrLabel28,
																							this.xrLabel27,
																							this.xrLabel30,
																							this.xrLabel32,
																							this.xrLabel25,
																							this.xrLabel29,
																							this.xrLabel26,
																							this.xrLabel31});
			this.PageHeader.Height = 113;
			this.PageHeader.ParentStyleUsing.UseFont = false;
			// 
			// PageFooter
			// 
			this.PageFooter.Height = 53;
			this.PageFooter.ParentStyleUsing.UseFont = false;
			// 
			// xrLabel7
			// 
			this.xrLabel7.ParentStyleUsing.UseFont = false;
			this.xrLabel7.Size = new System.Drawing.Size(1066, 27);
			// 
			// xrPageInfo1
			// 
			this.xrPageInfo1.ParentStyleUsing.UseFont = false;
			// 
			// xrLine1
			// 
			this.xrLine1.Size = new System.Drawing.Size(1066, 20);
			// 
			// xrLine2
			// 
			this.xrLine2.Size = new System.Drawing.Size(1066, 20);
			// 
			// ReportFooter
			// 
			this.ReportFooter.Height = 0;
			this.ReportFooter.ParentStyleUsing.UseFont = false;
			// 
			// xrLabel31
			// 
			this.xrLabel31.CanGrow = false;
			this.xrLabel31.Font = new System.Drawing.Font("Arial", 10.2F, ((System.Drawing.FontStyle)((System.Drawing.FontStyle.Bold | System.Drawing.FontStyle.Underline))), System.Drawing.GraphicsUnit.Point, ((System.Byte)(0)));
			this.xrLabel31.Location = new System.Drawing.Point(7, 93);
			this.xrLabel31.Name = "xrLabel31";
			this.xrLabel31.ParentStyleUsing.UseFont = false;
			this.xrLabel31.Size = new System.Drawing.Size(106, 20);
			this.xrLabel31.Text = "Serial Number";
			// 
			// xrLabel26
			// 
			this.xrLabel26.CanGrow = false;
			this.xrLabel26.Font = new System.Drawing.Font("Arial", 10.2F, ((System.Drawing.FontStyle)((System.Drawing.FontStyle.Bold | System.Drawing.FontStyle.Underline))), System.Drawing.GraphicsUnit.Point, ((System.Byte)(0)));
			this.xrLabel26.Location = new System.Drawing.Point(113, 93);
			this.xrLabel26.Name = "xrLabel26";
			this.xrLabel26.ParentStyleUsing.UseFont = false;
			this.xrLabel26.Size = new System.Drawing.Size(67, 20);
			this.xrLabel26.Text = "Location";
			// 
			// xrLabel29
			// 
			this.xrLabel29.CanGrow = false;
			this.xrLabel29.Font = new System.Drawing.Font("Arial", 10.2F, ((System.Drawing.FontStyle)((System.Drawing.FontStyle.Bold | System.Drawing.FontStyle.Underline))), System.Drawing.GraphicsUnit.Point, ((System.Byte)(0)));
			this.xrLabel29.Location = new System.Drawing.Point(187, 93);
			this.xrLabel29.Name = "xrLabel29";
			this.xrLabel29.ParentStyleUsing.UseFont = false;
			this.xrLabel29.Size = new System.Drawing.Size(100, 20);
			this.xrLabel29.Text = "Return";
			// 
			// xrLabel25
			// 
			this.xrLabel25.CanGrow = false;
			this.xrLabel25.Font = new System.Drawing.Font("Arial", 10.2F, ((System.Drawing.FontStyle)((System.Drawing.FontStyle.Bold | System.Drawing.FontStyle.Underline))), System.Drawing.GraphicsUnit.Point, ((System.Byte)(0)));
			this.xrLabel25.Location = new System.Drawing.Point(287, 93);
			this.xrLabel25.Name = "xrLabel25";
			this.xrLabel25.ParentStyleUsing.UseFont = false;
			this.xrLabel25.Size = new System.Drawing.Size(60, 20);
			this.xrLabel25.Text = "Missing";
			// 
			// xrLabel32
			// 
			this.xrLabel32.CanGrow = false;
			this.xrLabel32.Font = new System.Drawing.Font("Arial", 10.2F, ((System.Drawing.FontStyle)((System.Drawing.FontStyle.Bold | System.Drawing.FontStyle.Underline))), System.Drawing.GraphicsUnit.Point, ((System.Byte)(0)));
			this.xrLabel32.Location = new System.Drawing.Point(353, 93);
			this.xrLabel32.Name = "xrLabel32";
			this.xrLabel32.ParentStyleUsing.UseFont = false;
			this.xrLabel32.Size = new System.Drawing.Size(74, 20);
			this.xrLabel32.Text = "Account";
			// 
			// xrLabel30
			// 
			this.xrLabel30.CanGrow = false;
			this.xrLabel30.Font = new System.Drawing.Font("Arial", 10.2F, ((System.Drawing.FontStyle)((System.Drawing.FontStyle.Bold | System.Drawing.FontStyle.Underline))), System.Drawing.GraphicsUnit.Point, ((System.Byte)(0)));
			this.xrLabel30.Location = new System.Drawing.Point(433, 93);
			this.xrLabel30.Name = "xrLabel30";
			this.xrLabel30.ParentStyleUsing.UseFont = false;
			this.xrLabel30.Size = new System.Drawing.Size(120, 20);
			this.xrLabel30.Text = "Case Number";
			// 
			// xrLabel27
			// 
			this.xrLabel27.CanGrow = false;
			this.xrLabel27.Font = new System.Drawing.Font("Arial", 10.2F, ((System.Drawing.FontStyle)((System.Drawing.FontStyle.Bold | System.Drawing.FontStyle.Underline))), System.Drawing.GraphicsUnit.Point, ((System.Byte)(0)));
			this.xrLabel27.Location = new System.Drawing.Point(560, 93);
			this.xrLabel27.Name = "xrLabel27";
			this.xrLabel27.ParentStyleUsing.UseFont = false;
			this.xrLabel27.Size = new System.Drawing.Size(127, 20);
			this.xrLabel27.Text = "Media Type";
			// 
			// xrLabel28
			// 
			this.xrLabel28.CanGrow = false;
			this.xrLabel28.Font = new System.Drawing.Font("Arial", 10.2F, ((System.Drawing.FontStyle)((System.Drawing.FontStyle.Bold | System.Drawing.FontStyle.Underline))), System.Drawing.GraphicsUnit.Point, ((System.Byte)(0)));
			this.xrLabel28.Location = new System.Drawing.Point(687, 93);
			this.xrLabel28.Name = "xrLabel28";
			this.xrLabel28.ParentStyleUsing.UseFont = false;
			this.xrLabel28.Size = new System.Drawing.Size(387, 20);
			this.xrLabel28.Text = "Notes";
			// 
			// DetailReport
			// 
			this.DetailReport.Bands.AddRange(new DevExpress.XtraReports.UI.Band[] {
																					  this.Detail1});
			this.DetailReport.DataMember = "Medium";
			this.DetailReport.Name = "DetailReport";
			// 
			// Detail1
			// 
			this.Detail1.Controls.AddRange(new DevExpress.XtraReports.UI.XRControl[] {
																						 this.xrLabel11,
																						 this.xrLabel10,
																						 this.xrLabel9,
																						 this.xrLabel8,
																						 this.xrLabel6,
																						 this.xrLabel5,
																						 this.xrLabel4,
																						 this.xrLabel3});
			this.Detail1.Height = 16;
			this.Detail1.Name = "Detail1";
			// 
			// xrLabel11
			// 
			this.xrLabel11.CanShrink = true;
			this.xrLabel11.DataBindings.AddRange(new DevExpress.XtraReports.UI.XRBinding[] {
																							   new DevExpress.XtraReports.UI.XRBinding("Text", null, "Medium.Notes", "")});
			this.xrLabel11.Location = new System.Drawing.Point(687, 0);
			this.xrLabel11.Name = "xrLabel11";
			this.xrLabel11.Size = new System.Drawing.Size(387, 16);
			this.xrLabel11.Text = "xrLabel11";
			// 
			// xrLabel10
			// 
			this.xrLabel10.CanShrink = true;
			this.xrLabel10.DataBindings.AddRange(new DevExpress.XtraReports.UI.XRBinding[] {
																							   new DevExpress.XtraReports.UI.XRBinding("Text", null, "Medium.MediumType", "")});
			this.xrLabel10.Location = new System.Drawing.Point(560, 0);
			this.xrLabel10.Name = "xrLabel10";
			this.xrLabel10.Size = new System.Drawing.Size(127, 16);
			this.xrLabel10.Text = "xrLabel10";
			// 
			// xrLabel9
			// 
			this.xrLabel9.CanShrink = true;
			this.xrLabel9.DataBindings.AddRange(new DevExpress.XtraReports.UI.XRBinding[] {
																							  new DevExpress.XtraReports.UI.XRBinding("Text", null, "Medium.CaseName", "")});
			this.xrLabel9.Location = new System.Drawing.Point(433, 0);
			this.xrLabel9.Name = "xrLabel9";
			this.xrLabel9.Size = new System.Drawing.Size(120, 16);
			this.xrLabel9.Text = "xrLabel9";
			// 
			// xrLabel8
			// 
			this.xrLabel8.CanShrink = true;
			this.xrLabel8.DataBindings.AddRange(new DevExpress.XtraReports.UI.XRBinding[] {
																							  new DevExpress.XtraReports.UI.XRBinding("Text", null, "Medium.Account", "")});
			this.xrLabel8.Location = new System.Drawing.Point(353, 0);
			this.xrLabel8.Name = "xrLabel8";
			this.xrLabel8.Size = new System.Drawing.Size(74, 16);
			this.xrLabel8.Text = "xrLabel8";
			// 
			// xrLabel6
			// 
			this.xrLabel6.CanShrink = true;
			this.xrLabel6.DataBindings.AddRange(new DevExpress.XtraReports.UI.XRBinding[] {
																							  new DevExpress.XtraReports.UI.XRBinding("Text", null, "Medium.Missing", "")});
			this.xrLabel6.Location = new System.Drawing.Point(287, 0);
			this.xrLabel6.Name = "xrLabel6";
			this.xrLabel6.Size = new System.Drawing.Size(60, 16);
			this.xrLabel6.Text = "xrLabel6";
			// 
			// xrLabel5
			// 
			this.xrLabel5.CanShrink = true;
			this.xrLabel5.DataBindings.AddRange(new DevExpress.XtraReports.UI.XRBinding[] {
																							  new DevExpress.XtraReports.UI.XRBinding("Text", null, "Medium.ReturnDate", "")});
			this.xrLabel5.Location = new System.Drawing.Point(187, 0);
			this.xrLabel5.Name = "xrLabel5";
			this.xrLabel5.Size = new System.Drawing.Size(100, 16);
			this.xrLabel5.Text = "xrLabel5";
			// 
			// xrLabel4
			// 
			this.xrLabel4.CanShrink = true;
			this.xrLabel4.DataBindings.AddRange(new DevExpress.XtraReports.UI.XRBinding[] {
																							  new DevExpress.XtraReports.UI.XRBinding("Text", null, "Medium.Location", "")});
			this.xrLabel4.Location = new System.Drawing.Point(113, 0);
			this.xrLabel4.Name = "xrLabel4";
			this.xrLabel4.Size = new System.Drawing.Size(74, 16);
			this.xrLabel4.Text = "xrLabel4";
			// 
			// xrLabel3
			// 
			this.xrLabel3.CanShrink = true;
			this.xrLabel3.DataBindings.AddRange(new DevExpress.XtraReports.UI.XRBinding[] {
																							  new DevExpress.XtraReports.UI.XRBinding("Text", null, "Medium.SerialNo", "")});
			this.xrLabel3.Location = new System.Drawing.Point(7, 0);
			this.xrLabel3.Name = "xrLabel3";
			this.xrLabel3.Size = new System.Drawing.Size(100, 16);
			this.xrLabel3.Text = "xrLabel3";
			// 
			// XRFindMedium
			// 
			this.Bands.AddRange(new DevExpress.XtraReports.UI.Band[] {
																		 this.DetailReport});
			this.Font = new System.Drawing.Font("Arial", 10.2F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((System.Byte)(0)));
			this.PageHeight = 850;
			this.PageWidth = 1100;
			this.PaperKind = System.Drawing.Printing.PaperKind.LetterRotated;
			((System.ComponentModel.ISupportInitialize)(this)).EndInit();

		}
		#endregion
	}
}

