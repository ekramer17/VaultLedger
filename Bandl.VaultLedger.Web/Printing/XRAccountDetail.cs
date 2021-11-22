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
	public class XRAccountDetail : XRTemplate
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
		private DevExpress.XtraReports.UI.XRLabel xrLabel3;
		private DevExpress.XtraReports.UI.XRLabel xrLabel4;
		private DevExpress.XtraReports.UI.XRLabel xrLabel5;
		private DevExpress.XtraReports.UI.XRLabel xrLabel6;
		private DevExpress.XtraReports.UI.XRLabel xrLabel8;
		private DevExpress.XtraReports.UI.XRLabel xrLabel9;
		private DevExpress.XtraReports.UI.XRLabel xrLabel10;
		private DevExpress.XtraReports.UI.XRLabel xrLabel11;
		private DevExpress.XtraReports.UI.XRLabel xrLabel12;
		private DevExpress.XtraReports.UI.XRLabel xrLabel13;
		private DevExpress.XtraReports.UI.XRLabel xrLabel14;
		private DevExpress.XtraReports.UI.XRLabel xrLabel15;
		private DevExpress.XtraReports.UI.XRLabel xrLabel16;
		private DevExpress.XtraReports.UI.XRLabel xrLabel17;
		private DevExpress.XtraReports.UI.XRLabel xrLabel18;
		private DevExpress.XtraReports.UI.XRLabel xrLabel19;
		private DevExpress.XtraReports.UI.XRLabel xrLabel20;
		private DevExpress.XtraReports.UI.XRLabel xrLabel21;
		private DevExpress.XtraReports.UI.XRLabel xrLabel22;
		private DevExpress.XtraReports.UI.XRLabel xrLabel23;
		private DevExpress.XtraReports.UI.XRLabel xrLabel24;
		private DevExpress.XtraReports.UI.XRLabel xrLabel25;
		private DevExpress.XtraReports.UI.XRLine xrLine3;
		private DevExpress.XtraReports.UI.XRLine xrLine4;
		private DevExpress.XtraReports.UI.XRPageInfo xrPageInfo2;

		public XRAccountDetail()
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
			this.xrLine4 = new DevExpress.XtraReports.UI.XRLine();
			this.xrLine3 = new DevExpress.XtraReports.UI.XRLine();
			this.xrLabel25 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel24 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel23 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel22 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel21 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel20 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel19 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel18 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel17 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel16 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel15 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel14 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel13 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel12 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel11 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel10 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel9 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel8 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel6 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel5 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel4 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel3 = new DevExpress.XtraReports.UI.XRLabel();
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
			this.DetailReport.DataMember = "Account";
			this.DetailReport.Name = "DetailReport";
			// 
			// Detail1
			// 
			this.Detail1.Controls.AddRange(new DevExpress.XtraReports.UI.XRControl[] {
																						 this.xrLine4,
																						 this.xrLine3,
																						 this.xrLabel25,
																						 this.xrLabel24,
																						 this.xrLabel23,
																						 this.xrLabel22,
																						 this.xrLabel21,
																						 this.xrLabel20,
																						 this.xrLabel19,
																						 this.xrLabel18,
																						 this.xrLabel17,
																						 this.xrLabel16,
																						 this.xrLabel15,
																						 this.xrLabel14,
																						 this.xrLabel13,
																						 this.xrLabel12,
																						 this.xrLabel11,
																						 this.xrLabel10,
																						 this.xrLabel9,
																						 this.xrLabel8,
																						 this.xrLabel6,
																						 this.xrLabel5,
																						 this.xrLabel4,
																						 this.xrLabel3,
																						 this.xrLabel2,
																						 this.xrLabel1});
			this.Detail1.Height = 379;
			this.Detail1.Name = "Detail1";
			// 
			// xrLine4
			// 
			this.xrLine4.Location = new System.Drawing.Point(7, 180);
			this.xrLine4.Name = "xrLine4";
			this.xrLine4.Size = new System.Drawing.Size(626, 13);
			// 
			// xrLine3
			// 
			this.xrLine3.Location = new System.Drawing.Point(7, 53);
			this.xrLine3.Name = "xrLine3";
			this.xrLine3.Size = new System.Drawing.Size(626, 13);
			// 
			// xrLabel25
			// 
			this.xrLabel25.DataBindings.AddRange(new DevExpress.XtraReports.UI.XRBinding[] {
																							   new DevExpress.XtraReports.UI.XRBinding("Text", null, "Account.ZipCode", "")});
			this.xrLabel25.Location = new System.Drawing.Point(427, 131);
			this.xrLabel25.Name = "xrLabel25";
			this.xrLabel25.Size = new System.Drawing.Size(147, 16);
			this.xrLabel25.Text = "xrLabel25";
			// 
			// xrLabel24
			// 
			this.xrLabel24.DataBindings.AddRange(new DevExpress.XtraReports.UI.XRBinding[] {
																							   new DevExpress.XtraReports.UI.XRBinding("Text", null, "Account.Country", "")});
			this.xrLabel24.Location = new System.Drawing.Point(427, 162);
			this.xrLabel24.Name = "xrLabel24";
			this.xrLabel24.Size = new System.Drawing.Size(147, 16);
			this.xrLabel24.Text = "xrLabel24";
			// 
			// xrLabel23
			// 
			this.xrLabel23.DataBindings.AddRange(new DevExpress.XtraReports.UI.XRBinding[] {
																							   new DevExpress.XtraReports.UI.XRBinding("Text", null, "Account.Notes", "")});
			this.xrLabel23.Location = new System.Drawing.Point(133, 286);
			this.xrLabel23.Name = "xrLabel23";
			this.xrLabel23.Size = new System.Drawing.Size(134, 16);
			this.xrLabel23.Text = "xrLabel23";
			// 
			// xrLabel22
			// 
			this.xrLabel22.DataBindings.AddRange(new DevExpress.XtraReports.UI.XRBinding[] {
																							   new DevExpress.XtraReports.UI.XRBinding("Text", null, "Account.Email", "")});
			this.xrLabel22.Location = new System.Drawing.Point(133, 255);
			this.xrLabel22.Name = "xrLabel22";
			this.xrLabel22.Size = new System.Drawing.Size(134, 16);
			this.xrLabel22.Text = "xrLabel22";
			// 
			// xrLabel21
			// 
			this.xrLabel21.DataBindings.AddRange(new DevExpress.XtraReports.UI.XRBinding[] {
																							   new DevExpress.XtraReports.UI.XRBinding("Text", null, "Account.PhoneNo", "")});
			this.xrLabel21.Location = new System.Drawing.Point(133, 224);
			this.xrLabel21.Name = "xrLabel21";
			this.xrLabel21.Size = new System.Drawing.Size(134, 16);
			this.xrLabel21.Text = "xrLabel21";
			// 
			// xrLabel20
			// 
			this.xrLabel20.DataBindings.AddRange(new DevExpress.XtraReports.UI.XRBinding[] {
																							   new DevExpress.XtraReports.UI.XRBinding("Text", null, "Account.Contact", "")});
			this.xrLabel20.Location = new System.Drawing.Point(133, 200);
			this.xrLabel20.Name = "xrLabel20";
			this.xrLabel20.Size = new System.Drawing.Size(134, 16);
			this.xrLabel20.Text = "xrLabel20";
			// 
			// xrLabel19
			// 
			this.xrLabel19.DataBindings.AddRange(new DevExpress.XtraReports.UI.XRBinding[] {
																							   new DevExpress.XtraReports.UI.XRBinding("Text", null, "Account.State", "")});
			this.xrLabel19.Location = new System.Drawing.Point(133, 162);
			this.xrLabel19.Name = "xrLabel19";
			this.xrLabel19.Size = new System.Drawing.Size(134, 16);
			this.xrLabel19.Text = "xrLabel19";
			// 
			// xrLabel18
			// 
			this.xrLabel18.DataBindings.AddRange(new DevExpress.XtraReports.UI.XRBinding[] {
																							   new DevExpress.XtraReports.UI.XRBinding("Text", null, "Account.City", "")});
			this.xrLabel18.Location = new System.Drawing.Point(133, 131);
			this.xrLabel18.Name = "xrLabel18";
			this.xrLabel18.Size = new System.Drawing.Size(134, 16);
			this.xrLabel18.Text = "xrLabel18";
			// 
			// xrLabel17
			// 
			this.xrLabel17.DataBindings.AddRange(new DevExpress.XtraReports.UI.XRBinding[] {
																							   new DevExpress.XtraReports.UI.XRBinding("Text", null, "Account.Address2", "")});
			this.xrLabel17.Location = new System.Drawing.Point(133, 100);
			this.xrLabel17.Name = "xrLabel17";
			this.xrLabel17.Size = new System.Drawing.Size(134, 16);
			this.xrLabel17.Text = "xrLabel17";
			// 
			// xrLabel16
			// 
			this.xrLabel16.DataBindings.AddRange(new DevExpress.XtraReports.UI.XRBinding[] {
																							   new DevExpress.XtraReports.UI.XRBinding("Text", null, "Account.Address1", "")});
			this.xrLabel16.Location = new System.Drawing.Point(133, 69);
			this.xrLabel16.Name = "xrLabel16";
			this.xrLabel16.Size = new System.Drawing.Size(134, 16);
			this.xrLabel16.Text = "xrLabel16";
			// 
			// xrLabel15
			// 
			this.xrLabel15.DataBindings.AddRange(new DevExpress.XtraReports.UI.XRBinding[] {
																							   new DevExpress.XtraReports.UI.XRBinding("Text", null, "Account.Primary", "")});
			this.xrLabel15.Location = new System.Drawing.Point(133, 33);
			this.xrLabel15.Name = "xrLabel15";
			this.xrLabel15.Size = new System.Drawing.Size(134, 16);
			this.xrLabel15.Text = "xrLabel15";
			// 
			// xrLabel14
			// 
			this.xrLabel14.DataBindings.AddRange(new DevExpress.XtraReports.UI.XRBinding[] {
																							   new DevExpress.XtraReports.UI.XRBinding("Text", null, "Account.Name", "")});
			this.xrLabel14.Location = new System.Drawing.Point(133, 7);
			this.xrLabel14.Name = "xrLabel14";
			this.xrLabel14.Size = new System.Drawing.Size(134, 16);
			this.xrLabel14.Text = "xrLabel14";
			// 
			// xrLabel13
			// 
			this.xrLabel13.Location = new System.Drawing.Point(340, 162);
			this.xrLabel13.Name = "xrLabel13";
			this.xrLabel13.Size = new System.Drawing.Size(80, 16);
			this.xrLabel13.Text = "Country:";
			// 
			// xrLabel12
			// 
			this.xrLabel12.Location = new System.Drawing.Point(340, 131);
			this.xrLabel12.Name = "xrLabel12";
			this.xrLabel12.Size = new System.Drawing.Size(80, 16);
			this.xrLabel12.Text = "Zip/Postal:";
			// 
			// xrLabel11
			// 
			this.xrLabel11.Location = new System.Drawing.Point(7, 286);
			this.xrLabel11.Name = "xrLabel11";
			this.xrLabel11.Size = new System.Drawing.Size(113, 16);
			this.xrLabel11.Text = "Notes:";
			// 
			// xrLabel10
			// 
			this.xrLabel10.Location = new System.Drawing.Point(7, 255);
			this.xrLabel10.Name = "xrLabel10";
			this.xrLabel10.Size = new System.Drawing.Size(113, 16);
			this.xrLabel10.Text = "Email:";
			// 
			// xrLabel9
			// 
			this.xrLabel9.Location = new System.Drawing.Point(7, 224);
			this.xrLabel9.Name = "xrLabel9";
			this.xrLabel9.Size = new System.Drawing.Size(113, 16);
			this.xrLabel9.Text = "Telephone:";
			// 
			// xrLabel8
			// 
			this.xrLabel8.Location = new System.Drawing.Point(7, 200);
			this.xrLabel8.Name = "xrLabel8";
			this.xrLabel8.Size = new System.Drawing.Size(113, 16);
			this.xrLabel8.Text = "Contact:";
			// 
			// xrLabel6
			// 
			this.xrLabel6.Location = new System.Drawing.Point(7, 162);
			this.xrLabel6.Name = "xrLabel6";
			this.xrLabel6.Size = new System.Drawing.Size(113, 16);
			this.xrLabel6.Text = "State/Province:";
			// 
			// xrLabel5
			// 
			this.xrLabel5.Location = new System.Drawing.Point(7, 131);
			this.xrLabel5.Name = "xrLabel5";
			this.xrLabel5.Size = new System.Drawing.Size(113, 16);
			this.xrLabel5.Text = "City:";
			// 
			// xrLabel4
			// 
			this.xrLabel4.Location = new System.Drawing.Point(7, 100);
			this.xrLabel4.Name = "xrLabel4";
			this.xrLabel4.Size = new System.Drawing.Size(113, 16);
			this.xrLabel4.Text = "Address (Line 2):";
			// 
			// xrLabel3
			// 
			this.xrLabel3.Location = new System.Drawing.Point(7, 69);
			this.xrLabel3.Name = "xrLabel3";
			this.xrLabel3.Size = new System.Drawing.Size(113, 16);
			this.xrLabel3.Text = "Address (Line 1):";
			// 
			// xrLabel2
			// 
			this.xrLabel2.Location = new System.Drawing.Point(7, 33);
			this.xrLabel2.Name = "xrLabel2";
			this.xrLabel2.Size = new System.Drawing.Size(113, 16);
			this.xrLabel2.Text = "Global Account:";
			// 
			// xrLabel1
			// 
			this.xrLabel1.Location = new System.Drawing.Point(7, 7);
			this.xrLabel1.Name = "xrLabel1";
			this.xrLabel1.Size = new System.Drawing.Size(113, 16);
			this.xrLabel1.Text = "Account Number:";
			// 
			// XRAccountDetail
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

