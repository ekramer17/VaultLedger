using System;
using System.Drawing;
using System.Collections;
using System.ComponentModel;
using DevExpress.XtraReports.UI;

namespace Bandl.VaultLedger.Web.Printing
{
	/// <summary>
	/// Summary description for XRMedia.
	/// </summary>
	public class XRMedia : XRTemplate
	{
		private DevExpress.XtraReports.UI.XRLabel xrLabel26;
		private DevExpress.XtraReports.UI.XRLabel xrLabel27;
		private DevExpress.XtraReports.UI.XRLabel xrLabel25;
		private DevExpress.XtraReports.UI.XRLabel xrLabel32;
		private DevExpress.XtraReports.UI.XRLabel xrLabel29;
		private DevExpress.XtraReports.UI.XRLabel xrLabel30;
		private DevExpress.XtraReports.UI.XRLabel xrLabel31;
		private DevExpress.XtraReports.UI.XRLabel xrLabel1;
		private DevExpress.XtraReports.UI.XRLabel xrLabel2;
		private DevExpress.XtraReports.UI.XRLine xrLine3;
		private DevExpress.XtraReports.UI.XRLabel xrLabel3;
		private DevExpress.XtraReports.UI.XRLabel xrLabel4;
		private DevExpress.XtraReports.UI.XRLine xrLine4;
		private DevExpress.XtraReports.UI.XRLabel xrLabel5;
		private DevExpress.XtraReports.UI.XRLine xrLine5;
		private DevExpress.XtraReports.UI.XRLabel xrLabel6;
		private DevExpress.XtraReports.UI.XRLabel xrLabel9;
		private DevExpress.XtraReports.UI.XRLabel xrLabel10;
		private DevExpress.XtraReports.UI.XRLabel xrLabel11;
		private DevExpress.XtraReports.UI.XRLabel xrLabel12;
		private DevExpress.XtraReports.UI.XRLabel xrLabel13;
		private DevExpress.XtraReports.UI.XRLabel xrLabel8;
		private DevExpress.XtraReports.UI.XRLabel xrLabel14;
		private DevExpress.XtraReports.UI.XRLabel xrLabel15;
		private DevExpress.XtraReports.UI.XRLabel xrLabel16;
		private DevExpress.XtraReports.UI.XRLabel xrLabel17;
		private DevExpress.XtraReports.UI.XRLabel xrLabel18;
		private DevExpress.XtraReports.UI.XRLabel xrLabel19;
		private DevExpress.XtraReports.UI.XRLabel xrLabel20;
		private DevExpress.XtraReports.UI.XRLabel xrLabel21;
		private DevExpress.XtraReports.UI.DetailReportBand DetailReport;
		private DevExpress.XtraReports.UI.DetailBand Detail1;
		private DevExpress.XtraReports.UI.XRLabel xrLabel22;
		private DevExpress.XtraReports.UI.XRLabel xrLabel23;
		private DevExpress.XtraReports.UI.XRLabel xrLabel24;
		private DevExpress.XtraReports.UI.XRLabel xrLabel28;
		private DevExpress.XtraReports.UI.XRLabel xrLabel33;
		private DevExpress.XtraReports.UI.XRLabel xrLabel34;
		private DevExpress.XtraReports.UI.XRLabel xrLabel35;
		//private DevExpress.XtraReports.UI.DetailBand Detail;
		//private DevExpress.XtraReports.UI.PageHeaderBand PageHeader;
		//private DevExpress.XtraReports.UI.PageFooterBand PageFooter;
		/// <summary>
		/// Required designer variable.
		/// </summary>
		private System.ComponentModel.Container components = null;

		public XRMedia()
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
			this.xrLabel26 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel27 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel25 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel32 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel29 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel30 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel31 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel1 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel2 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLine3 = new DevExpress.XtraReports.UI.XRLine();
			this.xrLabel3 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel4 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLine4 = new DevExpress.XtraReports.UI.XRLine();
			this.xrLabel5 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLine5 = new DevExpress.XtraReports.UI.XRLine();
			this.xrLabel6 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel9 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel10 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel11 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel12 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel13 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel8 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel14 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel15 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel16 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel17 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel18 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel19 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel20 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel21 = new DevExpress.XtraReports.UI.XRLabel();
			this.DetailReport = new DevExpress.XtraReports.UI.DetailReportBand();
			this.Detail1 = new DevExpress.XtraReports.UI.DetailBand();
			this.xrLabel24 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel23 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel22 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel28 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel33 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel34 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel35 = new DevExpress.XtraReports.UI.XRLabel();
			((System.ComponentModel.ISupportInitialize)(this)).BeginInit();
			// 
			// Detail
			// 
			this.Detail.Controls.AddRange(new DevExpress.XtraReports.UI.XRControl[] {
																						this.xrLabel35,
																						this.xrLabel34,
																						this.xrLabel33,
																						this.xrLabel28,
																						this.xrLabel9,
																						this.xrLabel6,
																						this.xrLine5,
																						this.xrLabel5,
																						this.xrLine4,
																						this.xrLabel4,
																						this.xrLabel3,
																						this.xrLine3,
																						this.xrLabel2,
																						this.xrLabel1,
																						this.xrLabel21,
																						this.xrLabel20,
																						this.xrLabel19,
																						this.xrLabel18,
																						this.xrLabel17,
																						this.xrLabel16,
																						this.xrLabel15,
																						this.xrLabel14,
																						this.xrLabel8,
																						this.xrLabel13,
																						this.xrLabel12,
																						this.xrLabel11,
																						this.xrLabel10});
			this.Detail.Height = 333;
			this.Detail.ParentStyleUsing.UseFont = false;
			// 
			// PageHeader
			// 
			this.PageHeader.Height = 93;
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
			// xrLine1
			// 
			this.xrLine1.Location = new System.Drawing.Point(7, 73);
			// 
			// ReportFooter
			// 
			this.ReportFooter.Height = 0;
			this.ReportFooter.ParentStyleUsing.UseFont = false;
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
			this.xrLabel27.Location = new System.Drawing.Point(527, 93);
			this.xrLabel27.Name = "xrLabel27";
			this.xrLabel27.ParentStyleUsing.UseFont = false;
			this.xrLabel27.Size = new System.Drawing.Size(100, 20);
			this.xrLabel27.Text = "Media Type";
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
			// xrLabel29
			// 
			this.xrLabel29.CanGrow = false;
			this.xrLabel29.Font = new System.Drawing.Font("Arial", 10.2F, ((System.Drawing.FontStyle)((System.Drawing.FontStyle.Bold | System.Drawing.FontStyle.Underline))), System.Drawing.GraphicsUnit.Point, ((System.Byte)(0)));
			this.xrLabel29.Location = new System.Drawing.Point(180, 93);
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
			// xrLabel1
			// 
			this.xrLabel1.Font = new System.Drawing.Font("Arial", 10.2F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((System.Byte)(0)));
			this.xrLabel1.Location = new System.Drawing.Point(7, 7);
			this.xrLabel1.Name = "xrLabel1";
			this.xrLabel1.ParentStyleUsing.UseFont = false;
			this.xrLabel1.Size = new System.Drawing.Size(100, 27);
			this.xrLabel1.Text = "Serial Number:";
			// 
			// xrLabel2
			// 
			this.xrLabel2.Font = new System.Drawing.Font("Arial", 10.2F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((System.Byte)(0)));
			this.xrLabel2.Location = new System.Drawing.Point(7, 40);
			this.xrLabel2.Name = "xrLabel2";
			this.xrLabel2.ParentStyleUsing.UseFont = false;
			this.xrLabel2.Size = new System.Drawing.Size(100, 26);
			this.xrLabel2.Text = "Location:";
			// 
			// xrLine3
			// 
			this.xrLine3.Location = new System.Drawing.Point(7, 73);
			this.xrLine3.Name = "xrLine3";
			this.xrLine3.Size = new System.Drawing.Size(640, 13);
			// 
			// xrLabel3
			// 
			this.xrLabel3.Font = new System.Drawing.Font("Arial", 10.2F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((System.Byte)(0)));
			this.xrLabel3.Location = new System.Drawing.Point(7, 93);
			this.xrLabel3.Name = "xrLabel3";
			this.xrLabel3.ParentStyleUsing.UseFont = false;
			this.xrLabel3.Size = new System.Drawing.Size(100, 27);
			this.xrLabel3.Text = "Account:";
			// 
			// xrLabel4
			// 
			this.xrLabel4.Font = new System.Drawing.Font("Arial", 10.2F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((System.Byte)(0)));
			this.xrLabel4.Location = new System.Drawing.Point(7, 127);
			this.xrLabel4.Name = "xrLabel4";
			this.xrLabel4.ParentStyleUsing.UseFont = false;
			this.xrLabel4.Size = new System.Drawing.Size(100, 26);
			this.xrLabel4.Text = "Medium Type:";
			// 
			// xrLine4
			// 
			this.xrLine4.Location = new System.Drawing.Point(7, 160);
			this.xrLine4.Name = "xrLine4";
			this.xrLine4.Size = new System.Drawing.Size(640, 6);
			// 
			// xrLabel5
			// 
			this.xrLabel5.Font = new System.Drawing.Font("Arial", 10.2F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((System.Byte)(0)));
			this.xrLabel5.Location = new System.Drawing.Point(7, 173);
			this.xrLabel5.Name = "xrLabel5";
			this.xrLabel5.ParentStyleUsing.UseFont = false;
			this.xrLabel5.Size = new System.Drawing.Size(100, 27);
			this.xrLabel5.Text = "Active List:";
			// 
			// xrLine5
			// 
			this.xrLine5.Location = new System.Drawing.Point(7, 213);
			this.xrLine5.Name = "xrLine5";
			this.xrLine5.Size = new System.Drawing.Size(640, 7);
			// 
			// xrLabel6
			// 
			this.xrLabel6.Font = new System.Drawing.Font("Arial", 10.2F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((System.Byte)(0)));
			this.xrLabel6.Location = new System.Drawing.Point(7, 233);
			this.xrLabel6.Name = "xrLabel6";
			this.xrLabel6.ParentStyleUsing.UseFont = false;
			this.xrLabel6.Size = new System.Drawing.Size(100, 27);
			this.xrLabel6.Text = "Notes:";
			// 
			// xrLabel9
			// 
			this.xrLabel9.DataBindings.AddRange(new DevExpress.XtraReports.UI.XRBinding[] {
																							  new DevExpress.XtraReports.UI.XRBinding("Text", null, "Medium.Location", "")});
			this.xrLabel9.Font = new System.Drawing.Font("Arial", 10.2F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((System.Byte)(0)));
			this.xrLabel9.Location = new System.Drawing.Point(107, 40);
			this.xrLabel9.Name = "xrLabel9";
			this.xrLabel9.ParentStyleUsing.UseFont = false;
			this.xrLabel9.Size = new System.Drawing.Size(100, 27);
			this.xrLabel9.Text = "xrLabel9";
			// 
			// xrLabel10
			// 
			this.xrLabel10.DataBindings.AddRange(new DevExpress.XtraReports.UI.XRBinding[] {
																							   new DevExpress.XtraReports.UI.XRBinding("Text", null, "Medium.Account", "")});
			this.xrLabel10.Font = new System.Drawing.Font("Arial", 10.2F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((System.Byte)(0)));
			this.xrLabel10.Location = new System.Drawing.Point(107, 93);
			this.xrLabel10.Name = "xrLabel10";
			this.xrLabel10.ParentStyleUsing.UseFont = false;
			this.xrLabel10.Size = new System.Drawing.Size(100, 27);
			this.xrLabel10.Text = "xrLabel10";
			// 
			// xrLabel11
			// 
			this.xrLabel11.DataBindings.AddRange(new DevExpress.XtraReports.UI.XRBinding[] {
																							   new DevExpress.XtraReports.UI.XRBinding("Text", null, "Medium.MediumType", "")});
			this.xrLabel11.Font = new System.Drawing.Font("Arial", 10.2F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((System.Byte)(0)));
			this.xrLabel11.Location = new System.Drawing.Point(107, 127);
			this.xrLabel11.Name = "xrLabel11";
			this.xrLabel11.ParentStyleUsing.UseFont = false;
			this.xrLabel11.Size = new System.Drawing.Size(100, 27);
			this.xrLabel11.Text = "xrLabel11";
			// 
			// xrLabel12
			// 
			this.xrLabel12.DataBindings.AddRange(new DevExpress.XtraReports.UI.XRBinding[] {
																							   new DevExpress.XtraReports.UI.XRBinding("Text", null, "Medium.BSide", "")});
			this.xrLabel12.Font = new System.Drawing.Font("Arial", 10.2F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((System.Byte)(0)));
			this.xrLabel12.Location = new System.Drawing.Point(107, 173);
			this.xrLabel12.Name = "xrLabel12";
			this.xrLabel12.ParentStyleUsing.UseFont = false;
			this.xrLabel12.Size = new System.Drawing.Size(100, 27);
			this.xrLabel12.Text = "xrLabel12";
			// 
			// xrLabel13
			// 
			this.xrLabel13.DataBindings.AddRange(new DevExpress.XtraReports.UI.XRBinding[] {
																							   new DevExpress.XtraReports.UI.XRBinding("Text", null, "Medium.Notes", "")});
			this.xrLabel13.Font = new System.Drawing.Font("Arial", 10.2F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((System.Byte)(0)));
			this.xrLabel13.Location = new System.Drawing.Point(107, 233);
			this.xrLabel13.Name = "xrLabel13";
			this.xrLabel13.ParentStyleUsing.UseFont = false;
			this.xrLabel13.Size = new System.Drawing.Size(540, 27);
			this.xrLabel13.Text = "xrLabel13";
			// 
			// xrLabel8
			// 
			this.xrLabel8.DataBindings.AddRange(new DevExpress.XtraReports.UI.XRBinding[] {
																							  new DevExpress.XtraReports.UI.XRBinding("Text", null, "Medium.SerialNo", "")});
			this.xrLabel8.Font = new System.Drawing.Font("Arial", 10.2F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((System.Byte)(0)));
			this.xrLabel8.Location = new System.Drawing.Point(107, 7);
			this.xrLabel8.Name = "xrLabel8";
			this.xrLabel8.ParentStyleUsing.UseFont = false;
			this.xrLabel8.Size = new System.Drawing.Size(526, 27);
			this.xrLabel8.Text = "xrLabel8";
			// 
			// xrLabel14
			// 
			this.xrLabel14.Font = new System.Drawing.Font("Arial", 10.2F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((System.Byte)(0)));
			this.xrLabel14.Location = new System.Drawing.Point(320, 40);
			this.xrLabel14.Name = "xrLabel14";
			this.xrLabel14.ParentStyleUsing.UseFont = false;
			this.xrLabel14.Size = new System.Drawing.Size(100, 27);
			this.xrLabel14.Text = "Missing:";
			// 
			// xrLabel15
			// 
			this.xrLabel15.Font = new System.Drawing.Font("Arial", 10.2F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((System.Byte)(0)));
			this.xrLabel15.Location = new System.Drawing.Point(320, 93);
			this.xrLabel15.Name = "xrLabel15";
			this.xrLabel15.ParentStyleUsing.UseFont = false;
			this.xrLabel15.Size = new System.Drawing.Size(100, 27);
			this.xrLabel15.Text = "Return Date:";
			// 
			// xrLabel16
			// 
			this.xrLabel16.Font = new System.Drawing.Font("Arial", 10.2F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((System.Byte)(0)));
			this.xrLabel16.Location = new System.Drawing.Point(320, 127);
			this.xrLabel16.Name = "xrLabel16";
			this.xrLabel16.ParentStyleUsing.UseFont = false;
			this.xrLabel16.Size = new System.Drawing.Size(100, 27);
			this.xrLabel16.Text = "Case Number:";
			// 
			// xrLabel17
			// 
			this.xrLabel17.Font = new System.Drawing.Font("Arial", 10.2F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((System.Byte)(0)));
			this.xrLabel17.Location = new System.Drawing.Point(320, 173);
			this.xrLabel17.Name = "xrLabel17";
			this.xrLabel17.ParentStyleUsing.UseFont = false;
			this.xrLabel17.Size = new System.Drawing.Size(100, 26);
			this.xrLabel17.Text = "List Status:";
			// 
			// xrLabel18
			// 
			this.xrLabel18.DataBindings.AddRange(new DevExpress.XtraReports.UI.XRBinding[] {
																							   new DevExpress.XtraReports.UI.XRBinding("Text", null, "Medium.Missing", "")});
			this.xrLabel18.Font = new System.Drawing.Font("Arial", 10.2F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((System.Byte)(0)));
			this.xrLabel18.Location = new System.Drawing.Point(420, 40);
			this.xrLabel18.Name = "xrLabel18";
			this.xrLabel18.ParentStyleUsing.UseFont = false;
			this.xrLabel18.Size = new System.Drawing.Size(100, 27);
			this.xrLabel18.Text = "xrLabel18";
			// 
			// xrLabel19
			// 
			this.xrLabel19.DataBindings.AddRange(new DevExpress.XtraReports.UI.XRBinding[] {
																							   new DevExpress.XtraReports.UI.XRBinding("Text", null, "Medium.ReturnDate", "")});
			this.xrLabel19.Font = new System.Drawing.Font("Arial", 10.2F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((System.Byte)(0)));
			this.xrLabel19.Location = new System.Drawing.Point(420, 93);
			this.xrLabel19.Name = "xrLabel19";
			this.xrLabel19.ParentStyleUsing.UseFont = false;
			this.xrLabel19.Size = new System.Drawing.Size(100, 27);
			this.xrLabel19.Text = "xrLabel19";
			// 
			// xrLabel20
			// 
			this.xrLabel20.DataBindings.AddRange(new DevExpress.XtraReports.UI.XRBinding[] {
																							   new DevExpress.XtraReports.UI.XRBinding("Text", null, "Medium.CaseName", "")});
			this.xrLabel20.Font = new System.Drawing.Font("Arial", 10.2F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((System.Byte)(0)));
			this.xrLabel20.Location = new System.Drawing.Point(420, 127);
			this.xrLabel20.Name = "xrLabel20";
			this.xrLabel20.ParentStyleUsing.UseFont = false;
			this.xrLabel20.Size = new System.Drawing.Size(100, 27);
			this.xrLabel20.Text = "xrLabel20";
			// 
			// xrLabel21
			// 
			this.xrLabel21.DataBindings.AddRange(new DevExpress.XtraReports.UI.XRBinding[] {
																							   new DevExpress.XtraReports.UI.XRBinding("Text", null, "Medium.HotStatus", "")});
			this.xrLabel21.Font = new System.Drawing.Font("Arial", 10.2F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((System.Byte)(0)));
			this.xrLabel21.Location = new System.Drawing.Point(420, 173);
			this.xrLabel21.Name = "xrLabel21";
			this.xrLabel21.ParentStyleUsing.UseFont = false;
			this.xrLabel21.Size = new System.Drawing.Size(100, 27);
			this.xrLabel21.Text = "xrLabel21";
			// 
			// DetailReport
			// 
			this.DetailReport.Bands.AddRange(new DevExpress.XtraReports.UI.Band[] {
																					  this.Detail1});
			this.DetailReport.DataMember = "AuditTrail";
			this.DetailReport.Name = "DetailReport";
			// 
			// Detail1
			// 
			this.Detail1.Controls.AddRange(new DevExpress.XtraReports.UI.XRControl[] {
																						 this.xrLabel24,
																						 this.xrLabel23,
																						 this.xrLabel22});
			this.Detail1.Height = 20;
			this.Detail1.Name = "Detail1";
			// 
			// xrLabel24
			// 
			this.xrLabel24.DataBindings.AddRange(new DevExpress.XtraReports.UI.XRBinding[] {
																							   new DevExpress.XtraReports.UI.XRBinding("Text", null, "AuditTrail.Detail", "")});
			this.xrLabel24.Font = new System.Drawing.Font("Arial", 10.2F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((System.Byte)(0)));
			this.xrLabel24.Location = new System.Drawing.Point(287, 0);
			this.xrLabel24.Multiline = true;
			this.xrLabel24.Name = "xrLabel24";
			this.xrLabel24.ParentStyleUsing.UseFont = false;
			this.xrLabel24.Size = new System.Drawing.Size(540, 20);
			this.xrLabel24.Text = "xrLabel24";
			// 
			// xrLabel23
			// 
			this.xrLabel23.CanGrow = false;
			this.xrLabel23.DataBindings.AddRange(new DevExpress.XtraReports.UI.XRBinding[] {
																							   new DevExpress.XtraReports.UI.XRBinding("Text", null, "AuditTrail.Login", "")});
			this.xrLabel23.Font = new System.Drawing.Font("Arial", 10.2F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((System.Byte)(0)));
			this.xrLabel23.Location = new System.Drawing.Point(180, 0);
			this.xrLabel23.Name = "xrLabel23";
			this.xrLabel23.ParentStyleUsing.UseFont = false;
			this.xrLabel23.Size = new System.Drawing.Size(100, 20);
			this.xrLabel23.Text = "xrLabel23";
			// 
			// xrLabel22
			// 
			this.xrLabel22.CanGrow = false;
			this.xrLabel22.DataBindings.AddRange(new DevExpress.XtraReports.UI.XRBinding[] {
																							   new DevExpress.XtraReports.UI.XRBinding("Text", null, "AuditTrail.RecordDate", "")});
			this.xrLabel22.Font = new System.Drawing.Font("Arial", 10.2F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((System.Byte)(0)));
			this.xrLabel22.Location = new System.Drawing.Point(13, 0);
			this.xrLabel22.Name = "xrLabel22";
			this.xrLabel22.ParentStyleUsing.UseFont = false;
			this.xrLabel22.Size = new System.Drawing.Size(153, 20);
			this.xrLabel22.Text = "xrLabel22";
			// 
			// xrLabel28
			// 
			this.xrLabel28.Font = new System.Drawing.Font("Arial", 10.8F, System.Drawing.FontStyle.Bold, System.Drawing.GraphicsUnit.Point, ((System.Byte)(0)));
			this.xrLabel28.Location = new System.Drawing.Point(7, 273);
			this.xrLabel28.Name = "xrLabel28";
			this.xrLabel28.ParentStyleUsing.UseFont = false;
			this.xrLabel28.Size = new System.Drawing.Size(140, 27);
			this.xrLabel28.Text = "Medium History";
			// 
			// xrLabel33
			// 
			this.xrLabel33.CanGrow = false;
			this.xrLabel33.Font = new System.Drawing.Font("Arial", 10.2F, ((System.Drawing.FontStyle)((System.Drawing.FontStyle.Bold | System.Drawing.FontStyle.Underline))), System.Drawing.GraphicsUnit.Point, ((System.Byte)(0)));
			this.xrLabel33.Location = new System.Drawing.Point(13, 313);
			this.xrLabel33.Name = "xrLabel33";
			this.xrLabel33.ParentStyleUsing.UseFont = false;
			this.xrLabel33.Size = new System.Drawing.Size(160, 20);
			this.xrLabel33.Text = "Recorded Date & Time";
			// 
			// xrLabel34
			// 
			this.xrLabel34.CanGrow = false;
			this.xrLabel34.Font = new System.Drawing.Font("Arial", 10.2F, ((System.Drawing.FontStyle)((System.Drawing.FontStyle.Bold | System.Drawing.FontStyle.Underline))), System.Drawing.GraphicsUnit.Point, ((System.Byte)(0)));
			this.xrLabel34.Location = new System.Drawing.Point(180, 313);
			this.xrLabel34.Name = "xrLabel34";
			this.xrLabel34.ParentStyleUsing.UseFont = false;
			this.xrLabel34.Size = new System.Drawing.Size(100, 20);
			this.xrLabel34.Text = "Login ID";
			// 
			// xrLabel35
			// 
			this.xrLabel35.CanGrow = false;
			this.xrLabel35.Font = new System.Drawing.Font("Arial", 10.2F, ((System.Drawing.FontStyle)((System.Drawing.FontStyle.Bold | System.Drawing.FontStyle.Underline))), System.Drawing.GraphicsUnit.Point, ((System.Byte)(0)));
			this.xrLabel35.Location = new System.Drawing.Point(287, 313);
			this.xrLabel35.Name = "xrLabel35";
			this.xrLabel35.ParentStyleUsing.UseFont = false;
			this.xrLabel35.Size = new System.Drawing.Size(540, 20);
			this.xrLabel35.Text = "Detail";
			// 
			// XRMedia
			// 
			this.Bands.AddRange(new DevExpress.XtraReports.UI.Band[] {
																		 this.DetailReport});
			((System.ComponentModel.ISupportInitialize)(this)).EndInit();

		}
		#endregion
	}
}

