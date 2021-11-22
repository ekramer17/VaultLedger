using System;
using System.Drawing;
using System.Collections;
using System.ComponentModel;
using DevExpress.XtraReports.UI;
using Bandl.Library.VaultLedger.Model;

namespace Bandl.VaultLedger.Web.Printing
{
	/// <summary>
	/// Summary description for XRAuditor.
	/// </summary>
	public class XRTemplate : DevExpress.XtraReports.UI.XtraReport
	{
		protected DevExpress.XtraReports.UI.DetailBand Detail;
		protected DevExpress.XtraReports.UI.PageHeaderBand PageHeader;
		protected DevExpress.XtraReports.UI.PageFooterBand PageFooter;
		protected DevExpress.XtraReports.UI.XRLabel xrLabel7;
		protected DevExpress.XtraReports.UI.XRPageInfo xrPageInfo1;
		protected DevExpress.XtraReports.UI.XRLine xrLine1;
		protected DevExpress.XtraReports.UI.XRLine xrLine2;
		protected DevExpress.XtraReports.UI.ReportFooterBand ReportFooter;
		/// <summary>
		/// Required designer variable.
		/// </summary>
		private System.ComponentModel.Container components = null;
		private DevExpress.XtraReports.UI.XRPictureBox xrPictureBox1;
		private DevExpress.XtraReports.UI.XRPictureBox xrPictureBox2;
		private DevExpress.XtraReports.UI.XRLabel xrLabel1;
		private DevExpress.XtraReports.UI.XRLabel xrLabel2;
		private DevExpress.XtraReports.UI.XRPageInfo xrPageInfo2;

		public XRTemplate()
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
            this.Detail = new DevExpress.XtraReports.UI.DetailBand();
            this.PageHeader = new DevExpress.XtraReports.UI.PageHeaderBand();
            this.xrPictureBox2 = new DevExpress.XtraReports.UI.XRPictureBox();
            this.xrPictureBox1 = new DevExpress.XtraReports.UI.XRPictureBox();
            this.xrLine1 = new DevExpress.XtraReports.UI.XRLine();
            this.xrLabel7 = new DevExpress.XtraReports.UI.XRLabel();
            this.PageFooter = new DevExpress.XtraReports.UI.PageFooterBand();
            this.xrLabel2 = new DevExpress.XtraReports.UI.XRLabel();
            this.xrLabel1 = new DevExpress.XtraReports.UI.XRLabel();
            this.xrPageInfo2 = new DevExpress.XtraReports.UI.XRPageInfo();
            this.xrLine2 = new DevExpress.XtraReports.UI.XRLine();
            this.xrPageInfo1 = new DevExpress.XtraReports.UI.XRPageInfo();
            this.ReportFooter = new DevExpress.XtraReports.UI.ReportFooterBand();
            ((System.ComponentModel.ISupportInitialize)(this)).BeginInit();
            // 
            // Detail
            // 
            this.Detail.Font = new System.Drawing.Font("Arial", 10.2F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((System.Byte)(0)));
            this.Detail.Height = 0;
            this.Detail.Name = "Detail";
            this.Detail.ParentStyleUsing.UseFont = false;
            // 
            // PageHeader
            // 
            this.PageHeader.Controls.AddRange(new DevExpress.XtraReports.UI.XRControl[] {
                                                                                            this.xrPictureBox2,
                                                                                            this.xrPictureBox1,
                                                                                            this.xrLine1,
                                                                                            this.xrLabel7});
            this.PageHeader.Font = new System.Drawing.Font("Arial", 10.2F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((System.Byte)(0)));
            this.PageHeader.Height = 131;
            this.PageHeader.Name = "PageHeader";
            this.PageHeader.ParentStyleUsing.UseFont = false;
            // 
            // xrPictureBox2
            // 
            this.xrPictureBox2.DataBindings.AddRange(new DevExpress.XtraReports.UI.XRBinding[] {
                                                                                                   new DevExpress.XtraReports.UI.XRBinding("Image", null, "HeaderLogo.ProductLogo", "")});
            this.xrPictureBox2.Location = new System.Drawing.Point(107, 7);
            this.xrPictureBox2.Name = "xrPictureBox2";
            this.xrPictureBox2.Size = new System.Drawing.Size(160, 27);
            this.xrPictureBox2.Sizing = DevExpress.XtraPrinting.ImageSizeMode.AutoSize;
            // 
            // xrPictureBox1
            // 
            this.xrPictureBox1.DataBindings.AddRange(new DevExpress.XtraReports.UI.XRBinding[] {
                                                                                                   new DevExpress.XtraReports.UI.XRBinding("Image", null, "HeaderLogo.CompanyLogo", "")});
            this.xrPictureBox1.Location = new System.Drawing.Point(7, 7);
            this.xrPictureBox1.Name = "xrPictureBox1";
            this.xrPictureBox1.Size = new System.Drawing.Size(100, 27);
            this.xrPictureBox1.Sizing = DevExpress.XtraPrinting.ImageSizeMode.AutoSize;
            // 
            // xrLine1
            // 
            this.xrLine1.LineWidth = 4;
            this.xrLine1.Location = new System.Drawing.Point(7, 67);
            this.xrLine1.Name = "xrLine1";
            this.xrLine1.Size = new System.Drawing.Size(813, 20);
            // 
            // xrLabel7
            // 
            this.xrLabel7.DataBindings.AddRange(new DevExpress.XtraReports.UI.XRBinding[] {
                                                                                              new DevExpress.XtraReports.UI.XRBinding("Text", null, "HeaderLogo.ReportTitle", "")});
            this.xrLabel7.Font = new System.Drawing.Font("Arial", 12F, System.Drawing.FontStyle.Bold, System.Drawing.GraphicsUnit.Point, ((System.Byte)(0)));
            this.xrLabel7.Location = new System.Drawing.Point(7, 40);
            this.xrLabel7.Name = "xrLabel7";
            this.xrLabel7.ParentStyleUsing.UseFont = false;
            this.xrLabel7.Size = new System.Drawing.Size(813, 27);
            this.xrLabel7.TextAlignment = DevExpress.XtraPrinting.TextAlignment.MiddleCenter;
            this.xrLabel7.BeforePrint += new System.Drawing.Printing.PrintEventHandler(this.xrLabel7_BeforePrint);
            // 
            // PageFooter
            // 
            this.PageFooter.Controls.AddRange(new DevExpress.XtraReports.UI.XRControl[] {
                                                                                            this.xrLabel2,
                                                                                            this.xrLabel1,
                                                                                            this.xrPageInfo2,
                                                                                            this.xrLine2,
                                                                                            this.xrPageInfo1});
            this.PageFooter.Font = new System.Drawing.Font("Arial", 10.2F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((System.Byte)(0)));
            this.PageFooter.Height = 80;
            this.PageFooter.Name = "PageFooter";
            this.PageFooter.ParentStyleUsing.UseFont = false;
            this.PageFooter.TextAlignment = DevExpress.XtraPrinting.TextAlignment.BottomLeft;
            // 
            // xrLabel2
            // 
            this.xrLabel2.Font = new System.Drawing.Font("Arial", 10.2F, System.Drawing.FontStyle.Bold, System.Drawing.GraphicsUnit.Point, ((System.Byte)(0)));
            this.xrLabel2.Location = new System.Drawing.Point(673, 33);
            this.xrLabel2.Name = "xrLabel2";
            this.xrLabel2.ParentStyleUsing.UseFont = false;
            this.xrLabel2.Size = new System.Drawing.Size(47, 20);
            this.xrLabel2.Text = "Page: ";
            this.xrLabel2.TextAlignment = DevExpress.XtraPrinting.TextAlignment.TopRight;
            // 
            // xrLabel1
            // 
            this.xrLabel1.Font = new System.Drawing.Font("Arial", 10.2F, System.Drawing.FontStyle.Bold, System.Drawing.GraphicsUnit.Point, ((System.Byte)(0)));
            this.xrLabel1.Location = new System.Drawing.Point(13, 33);
            this.xrLabel1.Name = "xrLabel1";
            this.xrLabel1.ParentStyleUsing.UseFont = false;
            this.xrLabel1.Size = new System.Drawing.Size(134, 20);
            this.xrLabel1.Text = "Run Date & Time: ";
            this.xrLabel1.TextAlignment = DevExpress.XtraPrinting.TextAlignment.TopRight;
            // 
            // xrPageInfo2
            // 
            this.xrPageInfo2.Font = new System.Drawing.Font("Arial", 10.2F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((System.Byte)(0)));
            this.xrPageInfo2.Format = "{0} of {1}";
            this.xrPageInfo2.Location = new System.Drawing.Point(720, 33);
            this.xrPageInfo2.Name = "xrPageInfo2";
            this.xrPageInfo2.ParentStyleUsing.UseFont = false;
            this.xrPageInfo2.Size = new System.Drawing.Size(80, 20);
            // 
            // xrLine2
            // 
            this.xrLine2.LineWidth = 4;
            this.xrLine2.Location = new System.Drawing.Point(7, 7);
            this.xrLine2.Name = "xrLine2";
            this.xrLine2.Size = new System.Drawing.Size(813, 20);
            // 
            // xrPageInfo1
            // 
            this.xrPageInfo1.Font = new System.Drawing.Font("Arial", 10.2F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((System.Byte)(0)));
//            this.xrPageInfo1.Format = "{0:MM/dd/yyyy    hh:mm:ss tt}";
            this.xrPageInfo1.Format = "{0:" + GetDateTimeFormat() + "}";
            this.xrPageInfo1.Location = new System.Drawing.Point(153, 33);
            this.xrPageInfo1.Name = "xrPageInfo1";
            this.xrPageInfo1.PageInfo = DevExpress.XtraPrinting.PageInfo.DateTime;
            this.xrPageInfo1.ParentStyleUsing.UseFont = false;
            this.xrPageInfo1.Size = new System.Drawing.Size(294, 20);
            // 
            // ReportFooter
            // 
            this.ReportFooter.Font = new System.Drawing.Font("Arial", 10.2F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((System.Byte)(0)));
            this.ReportFooter.Height = 186;
            this.ReportFooter.KeepTogether = true;
            this.ReportFooter.Name = "ReportFooter";
            this.ReportFooter.ParentStyleUsing.UseFont = false;
            // 
            // XRTemplate
            // 
            this.Bands.AddRange(new DevExpress.XtraReports.UI.Band[] {
                                                                         this.Detail,
                                                                         this.PageHeader,
                                                                         this.PageFooter,
                                                                         this.ReportFooter});
            this.Margins = new System.Drawing.Printing.Margins(15, 5, 10, 1);
            ((System.ComponentModel.ISupportInitialize)(this)).EndInit();

        }
		#endregion

		private void xrLabel7_BeforePrint(object sender, System.Drawing.Printing.PrintEventArgs e)
		{
			XRLabel label = sender as XRLabel; 

			// incrementing the counter and setting a correct number to the Text property 
			label.Lines[0].ToUpper();
		}

        private string GetDateTimeFormat()
        {
            System.Web.HttpContext c = System.Web.HttpContext.Current;
            // Have?
            if (c == null)
            {
                return "yyyy/MM/dd    hh:mm:ss tt";
            }
            else
            {
                return String.Format("{0}    {1}", (string)c.Items[CacheKeys.DateMask], (string)c.Items[CacheKeys.TimeMask]);
            }
        }
	}
}

