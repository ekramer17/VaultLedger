using System;
using System.Drawing;
using System.Collections;
using System.ComponentModel;
using DevExpress.XtraReports.UI;

namespace Bandl.VaultLedger.Web.Printing
{
	/// <summary>
	/// Summary description for XRAuditor.
	/// </summary>
	public class XRFindMedia : XRTemplate
	{
		/// <summary>
		/// Required designer variable.
		/// </summary>
		private System.ComponentModel.Container components = null;
		private DevExpress.XtraReports.UI.XRLabel xrLabel2;
		private DevExpress.XtraReports.UI.XRPictureBox xrPictureBox1;
		private DevExpress.XtraReports.UI.XRPictureBox xrPictureBox2;
		private DevExpress.XtraReports.UI.XRPageInfo xrPageInfo2;
		private DevExpress.XtraReports.UI.XRLabel xrLabel1;
		private DevExpress.XtraReports.UI.XRLabel xrLabel3;
		private DevExpress.XtraReports.UI.XRLabel xrLabel4;
		private DevExpress.XtraReports.UI.XRLabel xrLabel5;
		private DevExpress.XtraReports.UI.XRLabel xrLabel6;
		private DevExpress.XtraReports.UI.XRLabel xrLabel8;
		private DevExpress.XtraReports.UI.XRLabel xrLabel9;
		private DevExpress.XtraReports.UI.DetailReportBand DetailReport;
		private DevExpress.XtraReports.UI.DetailBand Detail1;
		private DevExpress.XtraReports.UI.XRLabel xrLabel11;
		private DevExpress.XtraReports.UI.XRLabel xrLabel12;
		private DevExpress.XtraReports.UI.XRLabel xrLabel13;
		private DevExpress.XtraReports.UI.XRLabel xrLabel14;
		private DevExpress.XtraReports.UI.XRLabel xrLabel15;
		private DevExpress.XtraReports.UI.XRLabel xrLabel16;
		private DevExpress.XtraReports.UI.XRLabel xrLabel17;
		private DevExpress.XtraReports.UI.XRLabel xrLabel10;
		private DevExpress.XtraReports.UI.XRLabel xrLabel19;
		private DevExpress.XtraReports.UI.XRLabel xrLabel20;
		private DevExpress.XtraReports.UI.XRLabel xrLabel21;
		private DevExpress.XtraReports.UI.XRLabel xrLabel22;
		private DevExpress.XtraReports.UI.XRLabel xrLabel23;
		private DevExpress.XtraReports.UI.XRLabel xrLabel24;
		private DevExpress.XtraReports.UI.XRLabel xrLabel25;
		private DevExpress.XtraReports.UI.XRLabel xrLabel26;
		private DevExpress.XtraReports.UI.XRLabel xrLabel27;
		private DevExpress.XtraReports.UI.XRLabel xrLabel29;
		private DevExpress.XtraReports.UI.XRLabel xrLabel30;
		private DevExpress.XtraReports.UI.XRLabel xrLabel31;
		private DevExpress.XtraReports.UI.XRLabel xrLabel32;
		private DevExpress.XtraReports.UI.XRLabel xrLabel18;
		private DevExpress.XtraReports.UI.XRLabel xrLabel28;

		private int iRowCount = 0;

		public XRFindMedia()
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
			this.xrLabel10 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel9 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel8 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel6 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel5 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel4 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel3 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel1 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrPictureBox2 = new DevExpress.XtraReports.UI.XRPictureBox();
			this.xrPictureBox1 = new DevExpress.XtraReports.UI.XRPictureBox();
			this.xrPageInfo2 = new DevExpress.XtraReports.UI.XRPageInfo();
			this.xrLabel2 = new DevExpress.XtraReports.UI.XRLabel();
			this.DetailReport = new DevExpress.XtraReports.UI.DetailReportBand();
			this.Detail1 = new DevExpress.XtraReports.UI.DetailBand();
			this.xrLabel18 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel17 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel16 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel15 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel14 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel13 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel12 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel11 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel19 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel20 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel21 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel22 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel23 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel24 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel25 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel26 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel27 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel29 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel30 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel31 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel32 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel28 = new DevExpress.XtraReports.UI.XRLabel();
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
																							this.xrLabel32,
																							this.xrLabel31,
																							this.xrLabel30,
																							this.xrLabel29,
																							this.xrLabel27,
																							this.xrLabel26,
																							this.xrLabel25});
			this.PageHeader.Height = 120;
			this.PageHeader.ParentStyleUsing.UseFont = false;
			// 
			// PageFooter
			// 
			this.PageFooter.ParentStyleUsing.UseFont = false;
			// 
			// xrLabel7
			// 
			this.xrLabel7.CanGrow = false;
			this.xrLabel7.ParentStyleUsing.UseFont = false;
			this.xrLabel7.Size = new System.Drawing.Size(1066, 27);
			// 
			// xrPageInfo1
			// 
			this.xrPageInfo1.ParentStyleUsing.UseFont = false;
			this.xrPageInfo1.Size = new System.Drawing.Size(246, 20);
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
			this.ReportFooter.BorderWidth = 0;
			this.ReportFooter.Height = 0;
			this.ReportFooter.ParentStyleUsing.UseBorderWidth = false;
			this.ReportFooter.ParentStyleUsing.UseFont = false;
			// 
			// xrLabel10
			// 
			this.xrLabel10.Location = new System.Drawing.Point(633, 93);
			this.xrLabel10.Name = "xrLabel10";
			this.xrLabel10.Size = new System.Drawing.Size(440, 20);
			this.xrLabel10.Text = "Notes";
			// 
			// xrLabel9
			// 
			this.xrLabel9.Location = new System.Drawing.Point(533, 93);
			this.xrLabel9.Name = "xrLabel9";
			this.xrLabel9.Size = new System.Drawing.Size(100, 20);
			this.xrLabel9.Text = "Media Type";
			// 
			// xrLabel8
			// 
			this.xrLabel8.Location = new System.Drawing.Point(433, 93);
			this.xrLabel8.Name = "xrLabel8";
			this.xrLabel8.Size = new System.Drawing.Size(100, 20);
			this.xrLabel8.Text = "Case Number";
			// 
			// xrLabel6
			// 
			this.xrLabel6.Location = new System.Drawing.Point(353, 93);
			this.xrLabel6.Name = "xrLabel6";
			this.xrLabel6.Size = new System.Drawing.Size(74, 20);
			this.xrLabel6.Text = "Account";
			// 
			// xrLabel5
			// 
			this.xrLabel5.Location = new System.Drawing.Point(287, 93);
			this.xrLabel5.Name = "xrLabel5";
			this.xrLabel5.Size = new System.Drawing.Size(60, 20);
			this.xrLabel5.Text = "Missing";
			// 
			// xrLabel4
			// 
			this.xrLabel4.Location = new System.Drawing.Point(187, 93);
			this.xrLabel4.Name = "xrLabel4";
			this.xrLabel4.Size = new System.Drawing.Size(100, 20);
			this.xrLabel4.Text = "Return";
			// 
			// xrLabel3
			// 
			this.xrLabel3.Location = new System.Drawing.Point(113, 93);
			this.xrLabel3.Name = "xrLabel3";
			this.xrLabel3.Size = new System.Drawing.Size(67, 20);
			this.xrLabel3.Text = "Location";
			// 
			// xrLabel1
			// 
			this.xrLabel1.Location = new System.Drawing.Point(7, 93);
			this.xrLabel1.Name = "xrLabel1";
			this.xrLabel1.Size = new System.Drawing.Size(100, 20);
			this.xrLabel1.Text = "Serial Number";
			// 
			// xrPictureBox2
			// 
			this.xrPictureBox2.DataBindings.AddRange(new DevExpress.XtraReports.UI.XRBinding[] {
																								   new DevExpress.XtraReports.UI.XRBinding("Image", null, "HeaderLogo.ProductLogo", "")});
			this.xrPictureBox2.Location = new System.Drawing.Point(107, 7);
			this.xrPictureBox2.Name = "xrPictureBox2";
			this.xrPictureBox2.Size = new System.Drawing.Size(100, 27);
			// 
			// xrPictureBox1
			// 
			this.xrPictureBox1.DataBindings.AddRange(new DevExpress.XtraReports.UI.XRBinding[] {
																								   new DevExpress.XtraReports.UI.XRBinding("Image", null, "HeaderLogo.CompanyLogo", "")});
			this.xrPictureBox1.Location = new System.Drawing.Point(7, 7);
			this.xrPictureBox1.Name = "xrPictureBox1";
			this.xrPictureBox1.Size = new System.Drawing.Size(100, 27);
			// 
			// xrPageInfo2
			// 
			this.xrPageInfo2.Format = "Page {0} of {1}";
			this.xrPageInfo2.Location = new System.Drawing.Point(493, 33);
			this.xrPageInfo2.Name = "xrPageInfo2";
			this.xrPageInfo2.Size = new System.Drawing.Size(107, 20);
			// 
			// xrLabel2
			// 
			this.xrLabel2.Location = new System.Drawing.Point(27, 7);
			this.xrLabel2.Name = "xrLabel2";
			this.xrLabel2.Size = new System.Drawing.Size(194, 27);
			this.xrLabel2.Text = "Total Records";
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
																						 this.xrLabel18,
																						 this.xrLabel17,
																						 this.xrLabel16,
																						 this.xrLabel15,
																						 this.xrLabel14,
																						 this.xrLabel13,
																						 this.xrLabel12,
																						 this.xrLabel11});
			this.Detail1.Height = 16;
			this.Detail1.KeepTogether = true;
			this.Detail1.Name = "Detail1";
			this.Detail1.AfterPrint += new System.EventHandler(this.Detail1_AfterPrint);
			this.Detail1.BeforePrint += new System.Drawing.Printing.PrintEventHandler(this.Detail1_BeforePrint);
			// 
			// xrLabel18
			// 
			this.xrLabel18.CanGrow = false;
			this.xrLabel18.DataBindings.AddRange(new DevExpress.XtraReports.UI.XRBinding[] {
																							   new DevExpress.XtraReports.UI.XRBinding("Text", null, "Medium.Notes", "")});
			this.xrLabel18.Font = new System.Drawing.Font("Arial", 10.2F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((System.Byte)(0)));
			this.xrLabel18.Location = new System.Drawing.Point(633, 0);
			this.xrLabel18.Name = "xrLabel18";
			this.xrLabel18.ParentStyleUsing.UseFont = false;
			this.xrLabel18.Size = new System.Drawing.Size(440, 16);
			this.xrLabel18.Text = "xrLabel18";
			// 
			// xrLabel17
			// 
			this.xrLabel17.CanGrow = false;
			this.xrLabel17.DataBindings.AddRange(new DevExpress.XtraReports.UI.XRBinding[] {
																							   new DevExpress.XtraReports.UI.XRBinding("Text", null, "Medium.MediumType", "")});
			this.xrLabel17.Font = new System.Drawing.Font("Arial", 10.2F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((System.Byte)(0)));
			this.xrLabel17.Location = new System.Drawing.Point(533, 0);
			this.xrLabel17.Name = "xrLabel17";
			this.xrLabel17.ParentStyleUsing.UseFont = false;
			this.xrLabel17.Size = new System.Drawing.Size(100, 16);
			this.xrLabel17.Text = "xrLabel17";
			// 
			// xrLabel16
			// 
			this.xrLabel16.CanGrow = false;
			this.xrLabel16.DataBindings.AddRange(new DevExpress.XtraReports.UI.XRBinding[] {
																							   new DevExpress.XtraReports.UI.XRBinding("Text", null, "Medium.CaseName", "")});
			this.xrLabel16.Font = new System.Drawing.Font("Arial", 10.2F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((System.Byte)(0)));
			this.xrLabel16.Location = new System.Drawing.Point(433, 0);
			this.xrLabel16.Name = "xrLabel16";
			this.xrLabel16.ParentStyleUsing.UseFont = false;
			this.xrLabel16.Size = new System.Drawing.Size(100, 16);
			this.xrLabel16.Text = "xrLabel16";
			// 
			// xrLabel15
			// 
			this.xrLabel15.CanGrow = false;
			this.xrLabel15.DataBindings.AddRange(new DevExpress.XtraReports.UI.XRBinding[] {
																							   new DevExpress.XtraReports.UI.XRBinding("Text", null, "Medium.Account", "")});
			this.xrLabel15.Font = new System.Drawing.Font("Arial", 10.2F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((System.Byte)(0)));
			this.xrLabel15.Location = new System.Drawing.Point(353, 0);
			this.xrLabel15.Name = "xrLabel15";
			this.xrLabel15.ParentStyleUsing.UseFont = false;
			this.xrLabel15.Size = new System.Drawing.Size(74, 16);
			this.xrLabel15.Text = "xrLabel15";
			// 
			// xrLabel14
			// 
			this.xrLabel14.CanGrow = false;
			this.xrLabel14.DataBindings.AddRange(new DevExpress.XtraReports.UI.XRBinding[] {
																							   new DevExpress.XtraReports.UI.XRBinding("Text", null, "Medium.Missing", "")});
			this.xrLabel14.Font = new System.Drawing.Font("Arial", 10.2F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((System.Byte)(0)));
			this.xrLabel14.Location = new System.Drawing.Point(287, 0);
			this.xrLabel14.Name = "xrLabel14";
			this.xrLabel14.ParentStyleUsing.UseFont = false;
			this.xrLabel14.Size = new System.Drawing.Size(60, 16);
			this.xrLabel14.Text = "xrLabel14";
			// 
			// xrLabel13
			// 
			this.xrLabel13.CanGrow = false;
			this.xrLabel13.DataBindings.AddRange(new DevExpress.XtraReports.UI.XRBinding[] {
																							   new DevExpress.XtraReports.UI.XRBinding("Text", null, "Medium.ReturnDate", "")});
			this.xrLabel13.Font = new System.Drawing.Font("Arial", 10.2F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((System.Byte)(0)));
			this.xrLabel13.Location = new System.Drawing.Point(187, 0);
			this.xrLabel13.Name = "xrLabel13";
			this.xrLabel13.ParentStyleUsing.UseFont = false;
			this.xrLabel13.Size = new System.Drawing.Size(100, 16);
			this.xrLabel13.Text = "xrLabel13";
			// 
			// xrLabel12
			// 
			this.xrLabel12.CanGrow = false;
			this.xrLabel12.DataBindings.AddRange(new DevExpress.XtraReports.UI.XRBinding[] {
																							   new DevExpress.XtraReports.UI.XRBinding("Text", null, "Medium.Location", "")});
			this.xrLabel12.Font = new System.Drawing.Font("Arial", 10.2F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((System.Byte)(0)));
			this.xrLabel12.Location = new System.Drawing.Point(113, 0);
			this.xrLabel12.Name = "xrLabel12";
			this.xrLabel12.ParentStyleUsing.UseFont = false;
			this.xrLabel12.Size = new System.Drawing.Size(74, 16);
			this.xrLabel12.Text = "f";
			// 
			// xrLabel11
			// 
			this.xrLabel11.CanGrow = false;
			this.xrLabel11.DataBindings.AddRange(new DevExpress.XtraReports.UI.XRBinding[] {
																							   new DevExpress.XtraReports.UI.XRBinding("Text", null, "Medium.SerialNo", "")});
			this.xrLabel11.Font = new System.Drawing.Font("Arial", 10.2F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((System.Byte)(0)));
			this.xrLabel11.Location = new System.Drawing.Point(7, 0);
			this.xrLabel11.Name = "xrLabel11";
			this.xrLabel11.ParentStyleUsing.UseFont = false;
			this.xrLabel11.Size = new System.Drawing.Size(100, 16);
			this.xrLabel11.Text = "xrLabel11";
			// 
			// xrLabel19
			// 
			this.xrLabel19.Location = new System.Drawing.Point(187, 93);
			this.xrLabel19.Name = "xrLabel19";
			this.xrLabel19.Size = new System.Drawing.Size(100, 20);
			this.xrLabel19.Text = "Return";
			// 
			// xrLabel20
			// 
			this.xrLabel20.Location = new System.Drawing.Point(287, 93);
			this.xrLabel20.Name = "xrLabel20";
			this.xrLabel20.Size = new System.Drawing.Size(60, 20);
			this.xrLabel20.Text = "Missing";
			// 
			// xrLabel21
			// 
			this.xrLabel21.Location = new System.Drawing.Point(353, 93);
			this.xrLabel21.Name = "xrLabel21";
			this.xrLabel21.Size = new System.Drawing.Size(74, 20);
			this.xrLabel21.Text = "Account";
			// 
			// xrLabel22
			// 
			this.xrLabel22.Location = new System.Drawing.Point(433, 93);
			this.xrLabel22.Name = "xrLabel22";
			this.xrLabel22.Size = new System.Drawing.Size(100, 20);
			this.xrLabel22.Text = "Case Number";
			// 
			// xrLabel23
			// 
			this.xrLabel23.Location = new System.Drawing.Point(533, 93);
			this.xrLabel23.Name = "xrLabel23";
			this.xrLabel23.Size = new System.Drawing.Size(100, 20);
			this.xrLabel23.Text = "Media Type";
			// 
			// xrLabel24
			// 
			this.xrLabel24.Location = new System.Drawing.Point(633, 93);
			this.xrLabel24.Name = "xrLabel24";
			this.xrLabel24.Size = new System.Drawing.Size(440, 20);
			this.xrLabel24.Text = "Notes";
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
			// xrLabel27
			// 
			this.xrLabel27.CanGrow = false;
			this.xrLabel27.Font = new System.Drawing.Font("Arial", 10.2F, ((System.Drawing.FontStyle)((System.Drawing.FontStyle.Bold | System.Drawing.FontStyle.Underline))), System.Drawing.GraphicsUnit.Point, ((System.Byte)(0)));
			this.xrLabel27.Location = new System.Drawing.Point(533, 93);
			this.xrLabel27.Name = "xrLabel27";
			this.xrLabel27.ParentStyleUsing.UseFont = false;
			this.xrLabel27.Size = new System.Drawing.Size(100, 20);
			this.xrLabel27.Text = "Media Type";
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
			// xrLabel30
			// 
			this.xrLabel30.CanGrow = false;
			this.xrLabel30.Font = new System.Drawing.Font("Arial", 10.2F, ((System.Drawing.FontStyle)((System.Drawing.FontStyle.Bold | System.Drawing.FontStyle.Underline))), System.Drawing.GraphicsUnit.Point, ((System.Byte)(0)));
			this.xrLabel30.Location = new System.Drawing.Point(433, 93);
			this.xrLabel30.Name = "xrLabel30";
			this.xrLabel30.ParentStyleUsing.UseFont = false;
			this.xrLabel30.Size = new System.Drawing.Size(100, 20);
			this.xrLabel30.Text = "Case Number";
			// 
			// xrLabel31
			// 
			this.xrLabel31.CanGrow = false;
			this.xrLabel31.Font = new System.Drawing.Font("Arial", 10.2F, ((System.Drawing.FontStyle)((System.Drawing.FontStyle.Bold | System.Drawing.FontStyle.Underline))), System.Drawing.GraphicsUnit.Point, ((System.Byte)(0)));
			this.xrLabel31.Location = new System.Drawing.Point(7, 93);
			this.xrLabel31.Name = "xrLabel31";
			this.xrLabel31.ParentStyleUsing.UseFont = false;
			this.xrLabel31.Size = new System.Drawing.Size(100, 20);
			this.xrLabel31.Text = "Serial Number";
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
			// xrLabel28
			// 
			this.xrLabel28.CanGrow = false;
			this.xrLabel28.Font = new System.Drawing.Font("Arial", 10.2F, ((System.Drawing.FontStyle)((System.Drawing.FontStyle.Bold | System.Drawing.FontStyle.Underline))), System.Drawing.GraphicsUnit.Point, ((System.Byte)(0)));
			this.xrLabel28.Location = new System.Drawing.Point(633, 93);
			this.xrLabel28.Name = "xrLabel28";
			this.xrLabel28.ParentStyleUsing.UseFont = false;
			this.xrLabel28.Size = new System.Drawing.Size(440, 20);
			this.xrLabel28.Text = "Notes";
			// 
			// XRFindMedia
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

		private void xrLabel7_BeforePrint(object sender, System.Drawing.Printing.PrintEventArgs e)
		{
			XRLabel label = sender as XRLabel; 

			// incrementing the counter and setting a correct number to the Text property 
			label.Lines[0].ToUpper();
		}

		private void Detail1_AfterPrint(object sender, System.EventArgs e)
		{
			iRowCount++;		
		}

		private void xrLabel33_BeforePrint(object sender, System.Drawing.Printing.PrintEventArgs e)
		{
			XRLabel label = sender as XRLabel;
			label.Text = "Total Media: " + iRowCount.ToString();		
		}

		private void Detail1_BeforePrint(object sender, System.Drawing.Printing.PrintEventArgs e)
		{
			if ( iRowCount % 35 == 0 && iRowCount > 0 )// page break after every 25 records
				Detail1.PageBreak = PageBreak.BeforeBand;
			else
				Detail1.PageBreak = PageBreak.None; 
	
		}

	}
}

