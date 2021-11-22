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
	public class XRUserDetail : XRTemplate
	{
		/// <summary>
		/// Required designer variable.
		/// </summary>
		private System.ComponentModel.Container components = null;
		private DevExpress.XtraReports.UI.XRPictureBox xrPictureBox1;
		private DevExpress.XtraReports.UI.XRPictureBox xrPictureBox2;
		private DevExpress.XtraReports.UI.DetailReportBand DetailReport;
		private DevExpress.XtraReports.UI.DetailBand Detail1;
		private DevExpress.XtraReports.UI.XRLabel xrLabel1;
		private DevExpress.XtraReports.UI.XRLabel xrLabel2;
		private DevExpress.XtraReports.UI.XRLine xrLine3;
		private DevExpress.XtraReports.UI.XRLine xrLine4;
		private DevExpress.XtraReports.UI.XRLabel xrLabel4;
		private DevExpress.XtraReports.UI.XRLabel xrLabel5;
		private DevExpress.XtraReports.UI.XRLabel xrLabel6;
		private DevExpress.XtraReports.UI.XRLabel xrLabel8;
		private DevExpress.XtraReports.UI.XRLabel xrLabel9;
		private DevExpress.XtraReports.UI.XRLabel xrLabel10;
		private DevExpress.XtraReports.UI.XRLabel xrLabel11;
		private DevExpress.XtraReports.UI.XRLabel xrLabel12;
		private DevExpress.XtraReports.UI.XRLabel xrLabel13;
		private DevExpress.XtraReports.UI.XRLabel xrLabel3;
		private DevExpress.XtraReports.UI.XRLine xrLine5;
		private DevExpress.XtraReports.UI.XRLabel xrLabel14;
		private DevExpress.XtraReports.UI.XRLabel xrLabel15;
		private DevExpress.XtraReports.UI.XRPageInfo xrPageInfo2;

		public XRUserDetail()
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
			this.xrPictureBox2 = new DevExpress.XtraReports.UI.XRPictureBox();
			this.xrPictureBox1 = new DevExpress.XtraReports.UI.XRPictureBox();
			this.xrPageInfo2 = new DevExpress.XtraReports.UI.XRPageInfo();
			this.DetailReport = new DevExpress.XtraReports.UI.DetailReportBand();
			this.Detail1 = new DevExpress.XtraReports.UI.DetailBand();
			this.xrLabel15 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel14 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLine5 = new DevExpress.XtraReports.UI.XRLine();
			this.xrLabel3 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel13 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel12 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel11 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel10 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel9 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel8 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel6 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel5 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel4 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLine4 = new DevExpress.XtraReports.UI.XRLine();
			this.xrLine3 = new DevExpress.XtraReports.UI.XRLine();
			this.xrLabel2 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel1 = new DevExpress.XtraReports.UI.XRLabel();
			((System.ComponentModel.ISupportInitialize)(this)).BeginInit();
			// 
			// Detail
			// 
			this.Detail.ParentStyleUsing.UseFont = false;
			// 
			// PageHeader
			// 
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
			this.ReportFooter.ParentStyleUsing.UseFont = false;
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
			// DetailReport
			// 
			this.DetailReport.Bands.AddRange(new DevExpress.XtraReports.UI.Band[] {
																					  this.Detail1});
			this.DetailReport.DataMember = "Operator";
			this.DetailReport.Name = "DetailReport";
			// 
			// Detail1
			// 
			this.Detail1.Controls.AddRange(new DevExpress.XtraReports.UI.XRControl[] {
																						 this.xrLabel15,
																						 this.xrLabel14,
																						 this.xrLine5,
																						 this.xrLabel3,
																						 this.xrLabel13,
																						 this.xrLabel12,
																						 this.xrLabel11,
																						 this.xrLabel10,
																						 this.xrLabel9,
																						 this.xrLabel8,
																						 this.xrLabel6,
																						 this.xrLabel5,
																						 this.xrLabel4,
																						 this.xrLine4,
																						 this.xrLine3,
																						 this.xrLabel2,
																						 this.xrLabel1});
			this.Detail1.Height = 559;
			this.Detail1.Name = "Detail1";
			// 
			// xrLabel15
			// 
			this.xrLabel15.DataBindings.AddRange(new DevExpress.XtraReports.UI.XRBinding[] {
																							   new DevExpress.XtraReports.UI.XRBinding("Text", null, "Operator.Accounts", "")});
			this.xrLabel15.Location = new System.Drawing.Point(160, 317);
			this.xrLabel15.Multiline = true;
			this.xrLabel15.Name = "xrLabel15";
			this.xrLabel15.Size = new System.Drawing.Size(475, 16);
			this.xrLabel15.Text = "xrLabel15";
			// 
			// xrLabel14
			// 
			this.xrLabel14.Location = new System.Drawing.Point(8, 317);
			this.xrLabel14.Name = "xrLabel14";
			this.xrLabel14.Size = new System.Drawing.Size(113, 16);
			this.xrLabel14.Text = "Account(s):";
			// 
			// xrLine5
			// 
			this.xrLine5.Location = new System.Drawing.Point(7, 283);
			this.xrLine5.Name = "xrLine5";
			this.xrLine5.Size = new System.Drawing.Size(626, 13);
			// 
			// xrLabel3
			// 
			this.xrLabel3.Location = new System.Drawing.Point(7, 113);
			this.xrLabel3.Name = "xrLabel3";
			this.xrLabel3.Size = new System.Drawing.Size(113, 16);
			this.xrLabel3.Text = "Login ID:";
			// 
			// xrLabel13
			// 
			this.xrLabel13.DataBindings.AddRange(new DevExpress.XtraReports.UI.XRBinding[] {
																							   new DevExpress.XtraReports.UI.XRBinding("Text", null, "Operator.Notes", "")});
			this.xrLabel13.Location = new System.Drawing.Point(160, 247);
			this.xrLabel13.Name = "xrLabel13";
			this.xrLabel13.Size = new System.Drawing.Size(173, 16);
			this.xrLabel13.Text = "xrLabel13";
			// 
			// xrLabel12
			// 
			this.xrLabel12.DataBindings.AddRange(new DevExpress.XtraReports.UI.XRBinding[] {
																							   new DevExpress.XtraReports.UI.XRBinding("Text", null, "Operator.Email", "")});
			this.xrLabel12.Location = new System.Drawing.Point(160, 213);
			this.xrLabel12.Name = "xrLabel12";
			this.xrLabel12.Size = new System.Drawing.Size(173, 16);
			this.xrLabel12.Text = "xrLabel12";
			// 
			// xrLabel11
			// 
			this.xrLabel11.DataBindings.AddRange(new DevExpress.XtraReports.UI.XRBinding[] {
																							   new DevExpress.XtraReports.UI.XRBinding("Text", null, "Operator.PhoneNo", "")});
			this.xrLabel11.Location = new System.Drawing.Point(160, 180);
			this.xrLabel11.Name = "xrLabel11";
			this.xrLabel11.Size = new System.Drawing.Size(173, 16);
			this.xrLabel11.Text = "xrLabel11";
			// 
			// xrLabel10
			// 
			this.xrLabel10.DataBindings.AddRange(new DevExpress.XtraReports.UI.XRBinding[] {
																							   new DevExpress.XtraReports.UI.XRBinding("Text", null, "Operator.Login", "")});
			this.xrLabel10.Location = new System.Drawing.Point(160, 113);
			this.xrLabel10.Name = "xrLabel10";
			this.xrLabel10.Size = new System.Drawing.Size(173, 16);
			this.xrLabel10.Text = "xrLabel10";
			// 
			// xrLabel9
			// 
			this.xrLabel9.DataBindings.AddRange(new DevExpress.XtraReports.UI.XRBinding[] {
																							  new DevExpress.XtraReports.UI.XRBinding("Text", null, "Operator.Role", "")});
			this.xrLabel9.Location = new System.Drawing.Point(160, 47);
			this.xrLabel9.Name = "xrLabel9";
			this.xrLabel9.Size = new System.Drawing.Size(173, 16);
			this.xrLabel9.Text = "xrLabel9";
			// 
			// xrLabel8
			// 
			this.xrLabel8.DataBindings.AddRange(new DevExpress.XtraReports.UI.XRBinding[] {
																							  new DevExpress.XtraReports.UI.XRBinding("Text", null, "Operator.OperatorName", "")});
			this.xrLabel8.Location = new System.Drawing.Point(160, 7);
			this.xrLabel8.Name = "xrLabel8";
			this.xrLabel8.Size = new System.Drawing.Size(173, 16);
			this.xrLabel8.Text = "xrLabel8";
			// 
			// xrLabel6
			// 
			this.xrLabel6.Location = new System.Drawing.Point(7, 247);
			this.xrLabel6.Name = "xrLabel6";
			this.xrLabel6.Size = new System.Drawing.Size(113, 16);
			this.xrLabel6.Text = "Notes:";
			// 
			// xrLabel5
			// 
			this.xrLabel5.Location = new System.Drawing.Point(7, 213);
			this.xrLabel5.Name = "xrLabel5";
			this.xrLabel5.Size = new System.Drawing.Size(113, 16);
			this.xrLabel5.Text = "EMail:";
			// 
			// xrLabel4
			// 
			this.xrLabel4.Location = new System.Drawing.Point(7, 180);
			this.xrLabel4.Name = "xrLabel4";
			this.xrLabel4.Size = new System.Drawing.Size(113, 16);
			this.xrLabel4.Text = "Telephone:";
			// 
			// xrLine4
			// 
			this.xrLine4.Location = new System.Drawing.Point(7, 147);
			this.xrLine4.Name = "xrLine4";
			this.xrLine4.Size = new System.Drawing.Size(626, 13);
			// 
			// xrLine3
			// 
			this.xrLine3.Location = new System.Drawing.Point(7, 80);
			this.xrLine3.Name = "xrLine3";
			this.xrLine3.Size = new System.Drawing.Size(626, 13);
			// 
			// xrLabel2
			// 
			this.xrLabel2.Location = new System.Drawing.Point(7, 47);
			this.xrLabel2.Name = "xrLabel2";
			this.xrLabel2.Size = new System.Drawing.Size(113, 16);
			this.xrLabel2.Text = "Role:";
			// 
			// xrLabel1
			// 
			this.xrLabel1.Location = new System.Drawing.Point(7, 7);
			this.xrLabel1.Name = "xrLabel1";
			this.xrLabel1.Size = new System.Drawing.Size(113, 16);
			this.xrLabel1.Text = "Operator Name:";
			// 
			// XRUserDetail
			// 
			this.Bands.AddRange(new DevExpress.XtraReports.UI.Band[] {
																		 this.DetailReport});
			this.Font = new System.Drawing.Font("Arial", 10.2F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((System.Byte)(0)));
			this.Margins = new System.Drawing.Printing.Margins(10, 10, 10, 10);
			((System.ComponentModel.ISupportInitialize)(this)).EndInit();

		}
		#endregion



	}
}

