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
	public class XRAuditor : XRTemplate
	{
		private DevExpress.XtraReports.UI.XRLabel xrLabel5;
		private DevExpress.XtraReports.UI.XRLabel xrLabel8;
		private DevExpress.XtraReports.UI.XRLabel xrLabel9;
		private DevExpress.XtraReports.UI.XRLabel xrLabel10;
		private DevExpress.XtraReports.UI.XRLabel xrLabel11;
		private DevExpress.XtraReports.UI.XRLabel xrLabel12;
		/// <summary>
		/// Required designer variable.
		/// </summary>
		private System.ComponentModel.Container components = null;
		private DevExpress.XtraReports.UI.DetailBand Detail1;
		private DevExpress.XtraReports.UI.XRLabel xrLabel3;
		private DevExpress.XtraReports.UI.XRPictureBox xrPictureBox1;
		private DevExpress.XtraReports.UI.XRPictureBox xrPictureBox2;
		private DevExpress.XtraReports.UI.XRLabel xrLabel6;
		private DevExpress.XtraReports.UI.DetailReportBand DetailReport1;
		private DevExpress.XtraReports.UI.DetailBand Detail2;
		private DevExpress.XtraReports.UI.XRLabel xrLabel1;
		private DevExpress.XtraReports.UI.XRLabel xrLabel4;
		private DevExpress.XtraReports.UI.XRLabel xrLabel13;
		private DevExpress.XtraReports.UI.XRLabel xrLabel14;
		private DevExpress.XtraReports.UI.XRLabel xrLabel2;

		private int iRowCount = 0;

		public XRAuditor()
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
            this.xrLabel12 = new DevExpress.XtraReports.UI.XRLabel();
            this.xrLabel5 = new DevExpress.XtraReports.UI.XRLabel();
            this.xrPictureBox2 = new DevExpress.XtraReports.UI.XRPictureBox();
            this.xrPictureBox1 = new DevExpress.XtraReports.UI.XRPictureBox();
            this.xrLabel11 = new DevExpress.XtraReports.UI.XRLabel();
            this.xrLabel10 = new DevExpress.XtraReports.UI.XRLabel();
            this.xrLabel9 = new DevExpress.XtraReports.UI.XRLabel();
            this.xrLabel8 = new DevExpress.XtraReports.UI.XRLabel();
            this.Detail1 = new DevExpress.XtraReports.UI.DetailBand();
            this.xrLabel6 = new DevExpress.XtraReports.UI.XRLabel();
            this.xrLabel3 = new DevExpress.XtraReports.UI.XRLabel();
            this.DetailReport1 = new DevExpress.XtraReports.UI.DetailReportBand();
            this.Detail2 = new DevExpress.XtraReports.UI.DetailBand();
            this.xrLabel14 = new DevExpress.XtraReports.UI.XRLabel();
            this.xrLabel13 = new DevExpress.XtraReports.UI.XRLabel();
            this.xrLabel4 = new DevExpress.XtraReports.UI.XRLabel();
            this.xrLabel1 = new DevExpress.XtraReports.UI.XRLabel();
            this.xrLabel2 = new DevExpress.XtraReports.UI.XRLabel();
            ((System.ComponentModel.ISupportInitialize)(this)).BeginInit();
            // 
            // Detail
            // 
            this.Detail.ParentStyleUsing.UseFont = false;
            // 
            // PageHeader
            // 
            this.PageHeader.Controls.AddRange(new DevExpress.XtraReports.UI.XRControl[] {
                                                                                            this.xrPictureBox2,
                                                                                            this.xrPictureBox1,
                                                                                            this.xrLabel11,
                                                                                            this.xrLabel10,
                                                                                            this.xrLabel9,
                                                                                            this.xrLabel8});
            this.PageHeader.Font = new System.Drawing.Font("Arial", 10.2F, System.Drawing.FontStyle.Bold, System.Drawing.GraphicsUnit.Point, ((System.Byte)(0)));
            this.PageHeader.Height = 113;
            this.PageHeader.ParentStyleUsing.UseFont = false;
            // 
            // PageFooter
            // 
            this.PageFooter.Font = new System.Drawing.Font("Arial", 10.2F, System.Drawing.FontStyle.Bold, System.Drawing.GraphicsUnit.Point, ((System.Byte)(0)));
            this.PageFooter.ParentStyleUsing.UseFont = false;
            // 
            // xrLabel7
            // 
            this.xrLabel7.DataBindings.AddRange(new DevExpress.XtraReports.UI.XRBinding[] {
                                                                                              new DevExpress.XtraReports.UI.XRBinding("Text", null, "HeaderLogo.ReportTitle", "")});
            this.xrLabel7.ParentStyleUsing.UseFont = false;
            this.xrLabel7.Size = new System.Drawing.Size(1066, 27);
            this.xrLabel7.BeforePrint += new System.Drawing.Printing.PrintEventHandler(this.xrLabel7_BeforePrint);
            // 
            // xrPageInfo1
            // 
            this.xrPageInfo1.ParentStyleUsing.UseFont = false;
            // 
            // xrLine1
            // 
            this.xrLine1.Location = new System.Drawing.Point(8, 67);
            this.xrLine1.Size = new System.Drawing.Size(1066, 20);
            // 
            // xrLine2
            // 
            this.xrLine2.Size = new System.Drawing.Size(1066, 20);
            // 
            // ReportFooter
            // 
            this.ReportFooter.Controls.AddRange(new DevExpress.XtraReports.UI.XRControl[] {
                                                                                              this.xrLabel2});
            this.ReportFooter.Font = new System.Drawing.Font("Arial", 10.2F, System.Drawing.FontStyle.Bold, System.Drawing.GraphicsUnit.Point, ((System.Byte)(0)));
            this.ReportFooter.Height = 34;
            this.ReportFooter.ParentStyleUsing.UseFont = false;
            this.ReportFooter.AfterPrint += new System.EventHandler(this.Detail1_AfterPrint);
            this.ReportFooter.BeforePrint += new System.Drawing.Printing.PrintEventHandler(this.ReportFooter_BeforePrint);
            // 
            // xrLabel12
            // 
            this.xrLabel12.Location = new System.Drawing.Point(0, 0);
            this.xrLabel12.Name = "xrLabel12";
            this.xrLabel12.Size = new System.Drawing.Size(100, 23);
            // 
            // xrLabel5
            // 
            this.xrLabel5.DataBindings.AddRange(new DevExpress.XtraReports.UI.XRBinding[] {
                                                                                              new DevExpress.XtraReports.UI.XRBinding("Text", null, "AuditTrail.Login", "")});
            this.xrLabel5.Location = new System.Drawing.Point(513, 0);
            this.xrLabel5.Name = "xrLabel5";
            this.xrLabel5.Size = new System.Drawing.Size(100, 27);
            this.xrLabel5.Text = "xrLabel5";
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
            // xrLabel11
            // 
            this.xrLabel11.Font = new System.Drawing.Font("Arial", 10.2F, ((System.Drawing.FontStyle)((System.Drawing.FontStyle.Bold | System.Drawing.FontStyle.Underline))), System.Drawing.GraphicsUnit.Point, ((System.Byte)(0)));
            this.xrLabel11.Location = new System.Drawing.Point(188, 93);
            this.xrLabel11.Name = "xrLabel11";
            this.xrLabel11.ParentStyleUsing.UseFont = false;
            this.xrLabel11.Size = new System.Drawing.Size(100, 19);
            this.xrLabel11.Text = "Login ID";
            // 
            // xrLabel10
            // 
            this.xrLabel10.Font = new System.Drawing.Font("Arial", 10.2F, ((System.Drawing.FontStyle)((System.Drawing.FontStyle.Bold | System.Drawing.FontStyle.Underline))), System.Drawing.GraphicsUnit.Point, ((System.Byte)(0)));
            this.xrLabel10.Location = new System.Drawing.Point(433, 92);
            this.xrLabel10.Name = "xrLabel10";
            this.xrLabel10.ParentStyleUsing.UseFont = false;
            this.xrLabel10.Size = new System.Drawing.Size(553, 20);
            this.xrLabel10.Text = "Detail";
            // 
            // xrLabel9
            // 
            this.xrLabel9.DataBindings.AddRange(new DevExpress.XtraReports.UI.XRBinding[] {
                                                                                              new DevExpress.XtraReports.UI.XRBinding("Text", null, "HeaderLogo.ObjectTitle", "")});
            this.xrLabel9.Font = new System.Drawing.Font("Arial", 10.2F, ((System.Drawing.FontStyle)((System.Drawing.FontStyle.Bold | System.Drawing.FontStyle.Underline))), System.Drawing.GraphicsUnit.Point, ((System.Byte)(0)));
            this.xrLabel9.Location = new System.Drawing.Point(301, 92);
            this.xrLabel9.Name = "xrLabel9";
            this.xrLabel9.ParentStyleUsing.UseFont = false;
            this.xrLabel9.Size = new System.Drawing.Size(120, 20);
            // 
            // xrLabel8
            // 
            this.xrLabel8.Font = new System.Drawing.Font("Arial", 10.2F, ((System.Drawing.FontStyle)((System.Drawing.FontStyle.Bold | System.Drawing.FontStyle.Underline))), System.Drawing.GraphicsUnit.Point, ((System.Byte)(0)));
            this.xrLabel8.Location = new System.Drawing.Point(7, 93);
            this.xrLabel8.Name = "xrLabel8";
            this.xrLabel8.ParentStyleUsing.UseFont = false;
            this.xrLabel8.Size = new System.Drawing.Size(160, 20);
            this.xrLabel8.Text = "Recorded Date & Time";
            // 
            // Detail1
            // 
            this.Detail1.Controls.AddRange(new DevExpress.XtraReports.UI.XRControl[] {
                                                                                         this.xrLabel6,
                                                                                         this.xrLabel3,
                                                                                         this.xrLabel5,
                                                                                         this.xrLabel12});
            this.Detail1.Font = new System.Drawing.Font("Arial", 10.2F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((System.Byte)(0)));
            this.Detail1.Height = 30;
            this.Detail1.Name = "Detail1";
            this.Detail1.ParentStyleUsing.UseFont = false;
            this.Detail1.AfterPrint += new System.EventHandler(this.Detail1_AfterPrint);
            // 
            // xrLabel6
            // 
            this.xrLabel6.DataBindings.AddRange(new DevExpress.XtraReports.UI.XRBinding[] {
                                                                                              new DevExpress.XtraReports.UI.XRBinding("Text", null, "AuditTrail.ObjectName", "")});
            this.xrLabel6.Location = new System.Drawing.Point(160, 0);
            this.xrLabel6.Name = "xrLabel6";
            this.xrLabel6.Size = new System.Drawing.Size(100, 27);
            this.xrLabel6.Text = "xrLabel4";
            // 
            // xrLabel3
            // 
            this.xrLabel3.DataBindings.AddRange(new DevExpress.XtraReports.UI.XRBinding[] {
                                                                                              new DevExpress.XtraReports.UI.XRBinding("Text", null, "AuditTrail.RecordDate", "")});
            this.xrLabel3.Location = new System.Drawing.Point(7, 0);
            this.xrLabel3.Name = "xrLabel3";
            this.xrLabel3.Size = new System.Drawing.Size(140, 27);
            this.xrLabel3.Text = "xrLabel3";
            // 
            // DetailReport1
            // 
            this.DetailReport1.Bands.AddRange(new DevExpress.XtraReports.UI.Band[] {
                                                                                       this.Detail2});
            this.DetailReport1.DataMember = "AuditTrail";
            this.DetailReport1.Name = "DetailReport1";
            // 
            // Detail2
            // 
            this.Detail2.Controls.AddRange(new DevExpress.XtraReports.UI.XRControl[] {
                                                                                         this.xrLabel14,
                                                                                         this.xrLabel13,
                                                                                         this.xrLabel4,
                                                                                         this.xrLabel1});
            this.Detail2.Font = new System.Drawing.Font("Arial", 10.2F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((System.Byte)(0)));
            this.Detail2.Height = 16;
            this.Detail2.KeepTogether = true;
            this.Detail2.Name = "Detail2";
            this.Detail2.ParentStyleUsing.UseFont = false;
            this.Detail2.AfterPrint += new System.EventHandler(this.Detail2_AfterPrint);
            // 
            // xrLabel14
            // 
            this.xrLabel14.DataBindings.AddRange(new DevExpress.XtraReports.UI.XRBinding[] {
                                                                                               new DevExpress.XtraReports.UI.XRBinding("Text", null, "AuditTrail.Login", "")});
            this.xrLabel14.Location = new System.Drawing.Point(188, 0);
            this.xrLabel14.Name = "xrLabel14";
            this.xrLabel14.Size = new System.Drawing.Size(100, 16);
            this.xrLabel14.Text = "xrLabel14";
            // 
            // xrLabel13
            // 
            this.xrLabel13.DataBindings.AddRange(new DevExpress.XtraReports.UI.XRBinding[] {
                                                                                               new DevExpress.XtraReports.UI.XRBinding("Text", null, "AuditTrail.Detail", "")});
            this.xrLabel13.Location = new System.Drawing.Point(433, 0);
            this.xrLabel13.Name = "xrLabel13";
            this.xrLabel13.Size = new System.Drawing.Size(634, 16);
            this.xrLabel13.Text = "xrLabel13";
            // 
            // xrLabel4
            // 
            this.xrLabel4.DataBindings.AddRange(new DevExpress.XtraReports.UI.XRBinding[] {
                                                                                              new DevExpress.XtraReports.UI.XRBinding("Text", null, "AuditTrail.ObjectName", "")});
            this.xrLabel4.Location = new System.Drawing.Point(301, 0);
            this.xrLabel4.Name = "xrLabel4";
            this.xrLabel4.Size = new System.Drawing.Size(200, 16);
            this.xrLabel4.Text = "xrLabel4";
            // 
            // xrLabel1
            // 
            this.xrLabel1.DataBindings.AddRange(new DevExpress.XtraReports.UI.XRBinding[] {
                                                                                              new DevExpress.XtraReports.UI.XRBinding("Text", null, "AuditTrail.RecordDate", "")});
            this.xrLabel1.Location = new System.Drawing.Point(7, 0);
            this.xrLabel1.Name = "xrLabel1";
            this.xrLabel1.Size = new System.Drawing.Size(160, 16);
            this.xrLabel1.Text = "xrLabel1";
            // 
            // xrLabel2
            // 
            this.xrLabel2.Font = new System.Drawing.Font("Arial", 10.2F, System.Drawing.FontStyle.Bold, System.Drawing.GraphicsUnit.Point, ((System.Byte)(0)));
            this.xrLabel2.Location = new System.Drawing.Point(20, 7);
            this.xrLabel2.Name = "xrLabel2";
            this.xrLabel2.ParentStyleUsing.UseFont = false;
            this.xrLabel2.Size = new System.Drawing.Size(240, 27);
            this.xrLabel2.Text = "xrLabel2";
            this.xrLabel2.BeforePrint += new System.Drawing.Printing.PrintEventHandler(this.xrLabel2_BeforePrint);
            // 
            // XRAuditor
            // 
            this.Bands.AddRange(new DevExpress.XtraReports.UI.Band[] {
                                                                         this.DetailReport1});
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

		protected void xrLabel2_BeforePrint(object sender, System.Drawing.Printing.PrintEventArgs e)
		{
			XRLabel label = sender as XRLabel;
			label.Text = "Total Audit Records: " + iRowCount.ToString();

		}

		private void Detail1_AfterPrint(object sender, System.EventArgs e)
		{
		
		}

		private void ReportFooter_BeforePrint(object sender, System.Drawing.Printing.PrintEventArgs e)
		{
		
		}

		private void Detail2_AfterPrint(object sender, System.EventArgs e)
		{
			iRowCount++;		
		}

	}
}

