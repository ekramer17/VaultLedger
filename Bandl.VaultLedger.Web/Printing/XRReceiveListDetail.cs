using System;
using System.Drawing;
using System.Collections;
using System.ComponentModel;
using DevExpress.XtraReports.UI;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.BLL;

namespace Bandl.VaultLedger.Web.Printing
{
	/// <summary>
	/// Summary description for XRAuditor.
	/// </summary>
	public class XRReceiveListDetail : XRTemplate
	{
		/// <summary>
		/// Required designer variable.
		/// </summary>
		private System.ComponentModel.Container components = null;
		private DevExpress.XtraReports.UI.XRPictureBox xrPictureBox1;
		private DevExpress.XtraReports.UI.XRPictureBox xrPictureBox2;
		private DevExpress.XtraReports.UI.XRPageInfo xrPageInfo2;
		private DevExpress.XtraReports.UI.DetailReportBand DetailReport;
		private DevExpress.XtraReports.UI.DetailBand Detail1;
		private DevExpress.XtraReports.UI.XRLabel xrLabel1;
		private DevExpress.XtraReports.UI.XRLabel xrLabel4;
		private DevExpress.XtraReports.UI.XRLabel xrLabel5;
		private DevExpress.XtraReports.UI.XRLabel xrLabel6;
		private DevExpress.XtraReports.UI.XRLabel xrLabel8;
		private DevExpress.XtraReports.UI.XRLabel xrLabel9;
		private DevExpress.XtraReports.UI.XRLabel xrLabel10;
		private DevExpress.XtraReports.UI.XRLabel xrLabel12;
		private DevExpress.XtraReports.UI.XRLabel xrLabel14;
		private DevExpress.XtraReports.UI.XRLabel xrLabel16;
		private DevExpress.XtraReports.UI.XRLabel xrLabel11;
		private DevExpress.XtraReports.UI.XRLabel xrLabel13;
		private DevExpress.XtraReports.UI.XRLabel xrLabel15;
		private DevExpress.XtraReports.UI.XRLabel xrLabel17;
		private DevExpress.XtraReports.UI.XRLabel xrLabel30;
		private DevExpress.XtraReports.UI.XRLabel xrLabel26;
		private DevExpress.XtraReports.UI.XRLabel xrLabel27;
		private DevExpress.XtraReports.UI.XRLabel xrLabel29;
		private DevExpress.XtraReports.UI.XRLabel xrLabel28;
		private DevExpress.XtraReports.UI.XRLabel xrLabel2;
		private DevExpress.XtraReports.UI.XRTable xrTable4;
		private DevExpress.XtraReports.UI.XRTableRow xrTableRow4;
		private DevExpress.XtraReports.UI.XRTableCell xrTableCell7;
		private DevExpress.XtraReports.UI.XRTableCell xrTableCell8;
		private DevExpress.XtraReports.UI.XRTable xrTable3;
		private DevExpress.XtraReports.UI.XRTableRow xrTableRow3;
		private DevExpress.XtraReports.UI.XRTableCell xrTableCell5;
		private DevExpress.XtraReports.UI.XRTableCell xrTableCell6;
		private DevExpress.XtraReports.UI.XRTable xrTable1;
		private DevExpress.XtraReports.UI.XRTableRow xrTableRow1;
		private DevExpress.XtraReports.UI.XRTableCell xrTableCell1;
		private DevExpress.XtraReports.UI.XRTableCell xrTableCell2;
		private DevExpress.XtraReports.UI.XRTable xrTable2;
		private DevExpress.XtraReports.UI.XRTableRow xrTableRow2;
		private DevExpress.XtraReports.UI.XRTableCell xrTableCell3;
		private DevExpress.XtraReports.UI.XRTableCell xrTableCell4;
		private DevExpress.XtraReports.UI.XRPanel xrPanel1;
		private DevExpress.XtraReports.UI.XRLine xrLine3;
		private DevExpress.XtraReports.UI.XRLabel xrLabel38;
		private DevExpress.XtraReports.UI.XRLine xrLine9;
		private DevExpress.XtraReports.UI.XRLabel xrLabel40;
		private DevExpress.XtraReports.UI.XRLabel xrLabel39;
		private DevExpress.XtraReports.UI.XRLine xrLine4;
		private DevExpress.XtraReports.UI.XRLabel xrLabel37;
		private DevExpress.XtraReports.UI.XRLine xrLine8;
		private DevExpress.XtraReports.UI.XRLabel xrLabel3;

		private int iRowCount = 0;

		public XRReceiveListDetail()
		{
			//
			// Required for Designer support
			//
			InitializeComponent();

			//
			// TODO: Add any constructor code after InitializeComponent call
			//

			if (Configurator.ProductType == "RECALL")
			{
				xrLabel27.Location = new Point(145, 127);
				xrLabel3.Location = new Point(145, 0);
				xrLabel3.Width = 86;
				xrLabel29.Location = new Point(267, 127);
				xrLabel30.Location = new Point(267, 0);
				xrLabel28.Location = new Point(392, 127);
				xrLabel4.Location  = new Point(392, 0);
				xrLabel4.Width     = 433;
			}

			if ( Preference.GetPreference(PreferenceKeys.DisplayNotesOnManifests).Value == "NO")
			{
				xrLabel28.Visible = false;
				xrLabel4.Visible  = false;
			}

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
			this.xrLabel16 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel14 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel12 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel10 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel9 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel8 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel6 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel5 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrPictureBox2 = new DevExpress.XtraReports.UI.XRPictureBox();
			this.xrPictureBox1 = new DevExpress.XtraReports.UI.XRPictureBox();
			this.xrPageInfo2 = new DevExpress.XtraReports.UI.XRPageInfo();
			this.DetailReport = new DevExpress.XtraReports.UI.DetailReportBand();
			this.Detail1 = new DevExpress.XtraReports.UI.DetailBand();
			this.xrLabel3 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel30 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel4 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel1 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel11 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel13 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel15 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel17 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel26 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel27 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel29 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel28 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel2 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrTable4 = new DevExpress.XtraReports.UI.XRTable();
			this.xrTableRow4 = new DevExpress.XtraReports.UI.XRTableRow();
			this.xrTableCell7 = new DevExpress.XtraReports.UI.XRTableCell();
			this.xrTableCell8 = new DevExpress.XtraReports.UI.XRTableCell();
			this.xrTable3 = new DevExpress.XtraReports.UI.XRTable();
			this.xrTableRow3 = new DevExpress.XtraReports.UI.XRTableRow();
			this.xrTableCell5 = new DevExpress.XtraReports.UI.XRTableCell();
			this.xrTableCell6 = new DevExpress.XtraReports.UI.XRTableCell();
			this.xrTable1 = new DevExpress.XtraReports.UI.XRTable();
			this.xrTableRow1 = new DevExpress.XtraReports.UI.XRTableRow();
			this.xrTableCell1 = new DevExpress.XtraReports.UI.XRTableCell();
			this.xrTableCell2 = new DevExpress.XtraReports.UI.XRTableCell();
			this.xrTable2 = new DevExpress.XtraReports.UI.XRTable();
			this.xrTableRow2 = new DevExpress.XtraReports.UI.XRTableRow();
			this.xrTableCell3 = new DevExpress.XtraReports.UI.XRTableCell();
			this.xrTableCell4 = new DevExpress.XtraReports.UI.XRTableCell();
			this.xrPanel1 = new DevExpress.XtraReports.UI.XRPanel();
			this.xrLine3 = new DevExpress.XtraReports.UI.XRLine();
			this.xrLabel38 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLine9 = new DevExpress.XtraReports.UI.XRLine();
			this.xrLabel40 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLabel39 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLine4 = new DevExpress.XtraReports.UI.XRLine();
			this.xrLabel37 = new DevExpress.XtraReports.UI.XRLabel();
			this.xrLine8 = new DevExpress.XtraReports.UI.XRLine();
			((System.ComponentModel.ISupportInitialize)(this.xrTable4)).BeginInit();
			((System.ComponentModel.ISupportInitialize)(this.xrTable3)).BeginInit();
			((System.ComponentModel.ISupportInitialize)(this.xrTable1)).BeginInit();
			((System.ComponentModel.ISupportInitialize)(this.xrTable2)).BeginInit();
			((System.ComponentModel.ISupportInitialize)(this)).BeginInit();
			// 
			// Detail
			// 
			this.Detail.ParentStyleUsing.UseFont = false;
			// 
			// PageHeader
			// 
			this.PageHeader.Controls.AddRange(new DevExpress.XtraReports.UI.XRControl[] {
																							this.xrTable2,
																							this.xrTable1,
																							this.xrTable3,
																							this.xrTable4,
																							this.xrLabel28,
																							this.xrLabel29,
																							this.xrLabel27,
																							this.xrLabel26});
			this.PageHeader.Height = 147;
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
			this.xrLine1.Location = new System.Drawing.Point(7, 100);
			// 
			// ReportFooter
			// 
			this.ReportFooter.Controls.AddRange(new DevExpress.XtraReports.UI.XRControl[] {
																							  this.xrPanel1,
																							  this.xrLabel2});
			this.ReportFooter.Height = 280;
			this.ReportFooter.ParentStyleUsing.UseFont = false;
			// 
			// xrLabel16
			// 
			this.xrLabel16.Location = new System.Drawing.Point(540, 87);
			this.xrLabel16.Name = "xrLabel16";
			this.xrLabel16.Size = new System.Drawing.Size(66, 20);
			this.xrLabel16.Text = "Account:";
			this.xrLabel16.TextAlignment = DevExpress.XtraPrinting.TextAlignment.TopRight;
			// 
			// xrLabel14
			// 
			this.xrLabel14.Location = new System.Drawing.Point(313, 87);
			this.xrLabel14.Name = "xrLabel14";
			this.xrLabel14.Size = new System.Drawing.Size(100, 20);
			this.xrLabel14.Text = "Create Date:";
			this.xrLabel14.TextAlignment = DevExpress.XtraPrinting.TextAlignment.TopRight;
			// 
			// xrLabel12
			// 
			this.xrLabel12.Location = new System.Drawing.Point(180, 87);
			this.xrLabel12.Name = "xrLabel12";
			this.xrLabel12.Size = new System.Drawing.Size(53, 20);
			this.xrLabel12.Text = "Status:";
			this.xrLabel12.TextAlignment = DevExpress.XtraPrinting.TextAlignment.TopRight;
			// 
			// xrLabel10
			// 
			this.xrLabel10.Font = new System.Drawing.Font("Arial", 10.2F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((System.Byte)(0)));
			this.xrLabel10.Location = new System.Drawing.Point(7, 87);
			this.xrLabel10.Name = "xrLabel10";
			this.xrLabel10.ParentStyleUsing.UseFont = false;
			this.xrLabel10.Size = new System.Drawing.Size(86, 20);
			this.xrLabel10.Text = "List Number:";
			this.xrLabel10.TextAlignment = DevExpress.XtraPrinting.TextAlignment.TopRight;
			// 
			// xrLabel9
			// 
			this.xrLabel9.Location = new System.Drawing.Point(107, 140);
			this.xrLabel9.Name = "xrLabel9";
			this.xrLabel9.Size = new System.Drawing.Size(100, 20);
			this.xrLabel9.Text = "Status";
			// 
			// xrLabel8
			// 
			this.xrLabel8.Location = new System.Drawing.Point(207, 140);
			this.xrLabel8.Name = "xrLabel8";
			this.xrLabel8.Size = new System.Drawing.Size(613, 20);
			this.xrLabel8.Text = "Notes";
			// 
			// xrLabel6
			// 
			this.xrLabel6.Location = new System.Drawing.Point(107, 140);
			this.xrLabel6.Name = "xrLabel6";
			this.xrLabel6.Size = new System.Drawing.Size(100, 20);
			this.xrLabel6.Text = "Status";
			// 
			// xrLabel5
			// 
			this.xrLabel5.Location = new System.Drawing.Point(7, 140);
			this.xrLabel5.Name = "xrLabel5";
			this.xrLabel5.Size = new System.Drawing.Size(100, 20);
			this.xrLabel5.Text = "Serial Number";
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
			this.DetailReport.DataMember = "ReceiveListItem";
			this.DetailReport.Name = "DetailReport";
			// 
			// Detail1
			// 
			this.Detail1.Controls.AddRange(new DevExpress.XtraReports.UI.XRControl[] {
																						 this.xrLabel3,
																						 this.xrLabel30,
																						 this.xrLabel4,
																						 this.xrLabel1});
			this.Detail1.Height = 19;
			this.Detail1.Name = "Detail1";
			this.Detail1.AfterPrint += new System.EventHandler(this.Detail1_AfterPrint);
			// 
			// xrLabel3
			// 
			this.xrLabel3.DataBindings.AddRange(new DevExpress.XtraReports.UI.XRBinding[] {
																							  new DevExpress.XtraReports.UI.XRBinding("Text", null, "ReceiveListItem.MediaType", "")});
			this.xrLabel3.Location = new System.Drawing.Point(140, 0);
			this.xrLabel3.Name = "xrLabel3";
			this.xrLabel3.Size = new System.Drawing.Size(150, 16);
			this.xrLabel3.Text = "xrLabel3";
			// 
			// xrLabel30
			// 
			this.xrLabel30.DataBindings.AddRange(new DevExpress.XtraReports.UI.XRBinding[] {
																							   new DevExpress.XtraReports.UI.XRBinding("Text", null, "ReceiveListItem.CaseName", "")});
			this.xrLabel30.Location = new System.Drawing.Point(300, 0);
			this.xrLabel30.Name = "xrLabel30";
			this.xrLabel30.Size = new System.Drawing.Size(100, 16);
			this.xrLabel30.Text = "xrLabel30";
			// 
			// xrLabel4
			// 
			this.xrLabel4.DataBindings.AddRange(new DevExpress.XtraReports.UI.XRBinding[] {
																							  new DevExpress.XtraReports.UI.XRBinding("Text", null, "ReceiveListItem.Notes", "")});
			this.xrLabel4.Location = new System.Drawing.Point(413, 0);
			this.xrLabel4.Name = "xrLabel4";
			this.xrLabel4.Size = new System.Drawing.Size(407, 16);
			this.xrLabel4.Text = "xrLabel4";
			// 
			// xrLabel1
			// 
			this.xrLabel1.DataBindings.AddRange(new DevExpress.XtraReports.UI.XRBinding[] {
																							  new DevExpress.XtraReports.UI.XRBinding("Text", null, "ReceiveListItem.SerialNo", "")});
			this.xrLabel1.Location = new System.Drawing.Point(7, 0);
			this.xrLabel1.Name = "xrLabel1";
			this.xrLabel1.Size = new System.Drawing.Size(120, 16);
			this.xrLabel1.Text = "xrLabel1";
			// 
			// xrLabel11
			// 
			this.xrLabel11.DataBindings.AddRange(new DevExpress.XtraReports.UI.XRBinding[] {
																							   new DevExpress.XtraReports.UI.XRBinding("Text", null, "HeaderLogo.ListNumber", "")});
			this.xrLabel11.Location = new System.Drawing.Point(93, 87);
			this.xrLabel11.Name = "xrLabel11";
			this.xrLabel11.Size = new System.Drawing.Size(87, 20);
			this.xrLabel11.Text = "xrLabel11";
			// 
			// xrLabel13
			// 
			this.xrLabel13.DataBindings.AddRange(new DevExpress.XtraReports.UI.XRBinding[] {
																							   new DevExpress.XtraReports.UI.XRBinding("Text", null, "HeaderLogo.Status", "")});
			this.xrLabel13.Location = new System.Drawing.Point(233, 87);
			this.xrLabel13.Name = "xrLabel13";
			this.xrLabel13.Size = new System.Drawing.Size(80, 20);
			this.xrLabel13.Text = "xrLabel13";
			// 
			// xrLabel15
			// 
			this.xrLabel15.DataBindings.AddRange(new DevExpress.XtraReports.UI.XRBinding[] {
																							   new DevExpress.XtraReports.UI.XRBinding("Text", null, "HeaderLogo.CreateDate", "")});
			this.xrLabel15.Location = new System.Drawing.Point(413, 87);
			this.xrLabel15.Name = "xrLabel15";
			this.xrLabel15.Size = new System.Drawing.Size(127, 20);
			this.xrLabel15.Text = "xrLabel15";
			// 
			// xrLabel17
			// 
			this.xrLabel17.DataBindings.AddRange(new DevExpress.XtraReports.UI.XRBinding[] {
																							   new DevExpress.XtraReports.UI.XRBinding("Text", null, "HeaderLogo.Account", "")});
			this.xrLabel17.Location = new System.Drawing.Point(607, 87);
			this.xrLabel17.Name = "xrLabel17";
			this.xrLabel17.Size = new System.Drawing.Size(74, 20);
			this.xrLabel17.Text = "xrLabel17";
			// 
			// xrLabel26
			// 
			this.xrLabel26.Font = new System.Drawing.Font("Arial", 10.2F, ((System.Drawing.FontStyle)((System.Drawing.FontStyle.Bold | System.Drawing.FontStyle.Underline))), System.Drawing.GraphicsUnit.Point, ((System.Byte)(0)));
			this.xrLabel26.Location = new System.Drawing.Point(7, 127);
			this.xrLabel26.Name = "xrLabel26";
			this.xrLabel26.ParentStyleUsing.UseFont = false;
			this.xrLabel26.Size = new System.Drawing.Size(120, 20);
			this.xrLabel26.Text = "Serial Number";
			// 
			// xrLabel27
			// 
			this.xrLabel27.Font = new System.Drawing.Font("Arial", 10.2F, ((System.Drawing.FontStyle)((System.Drawing.FontStyle.Bold | System.Drawing.FontStyle.Underline))), System.Drawing.GraphicsUnit.Point, ((System.Byte)(0)));
			this.xrLabel27.Location = new System.Drawing.Point(140, 127);
			this.xrLabel27.Name = "xrLabel27";
			this.xrLabel27.ParentStyleUsing.UseFont = false;
			this.xrLabel27.Size = new System.Drawing.Size(100, 20);
			this.xrLabel27.Text = "Media Type";
			// 
			// xrLabel29
			// 
			this.xrLabel29.Font = new System.Drawing.Font("Arial", 10.2F, ((System.Drawing.FontStyle)((System.Drawing.FontStyle.Bold | System.Drawing.FontStyle.Underline))), System.Drawing.GraphicsUnit.Point, ((System.Byte)(0)));
			this.xrLabel29.Location = new System.Drawing.Point(300, 127);
			this.xrLabel29.Name = "xrLabel29";
			this.xrLabel29.ParentStyleUsing.UseFont = false;
			this.xrLabel29.Size = new System.Drawing.Size(100, 20);
			this.xrLabel29.Text = "Case Number";
			// 
			// xrLabel28
			// 
			this.xrLabel28.Font = new System.Drawing.Font("Arial", 10.2F, ((System.Drawing.FontStyle)((System.Drawing.FontStyle.Bold | System.Drawing.FontStyle.Underline))), System.Drawing.GraphicsUnit.Point, ((System.Byte)(0)));
			this.xrLabel28.Location = new System.Drawing.Point(413, 127);
			this.xrLabel28.Name = "xrLabel28";
			this.xrLabel28.ParentStyleUsing.UseFont = false;
			this.xrLabel28.Size = new System.Drawing.Size(407, 20);
			this.xrLabel28.Text = "Notes";
			// 
			// xrLabel2
			// 
			this.xrLabel2.Font = new System.Drawing.Font("Arial", 10.2F, System.Drawing.FontStyle.Bold, System.Drawing.GraphicsUnit.Point, ((System.Byte)(0)));
			this.xrLabel2.Location = new System.Drawing.Point(20, 13);
			this.xrLabel2.Name = "xrLabel2";
			this.xrLabel2.ParentStyleUsing.UseFont = false;
			this.xrLabel2.Size = new System.Drawing.Size(187, 20);
			this.xrLabel2.Text = "Total Items:";
			this.xrLabel2.BeforePrint += new System.Drawing.Printing.PrintEventHandler(this.xrLabel2_BeforePrint);
			// 
			// xrTable4
			// 
			this.xrTable4.Font = new System.Drawing.Font("Arial", 10.2F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((System.Byte)(0)));
			this.xrTable4.Location = new System.Drawing.Point(667, 80);
			this.xrTable4.Name = "xrTable4";
			this.xrTable4.ParentStyleUsing.UseFont = false;
			this.xrTable4.Rows.AddRange(new DevExpress.XtraReports.UI.XRTableRow[] {
																					   this.xrTableRow4});
			this.xrTable4.Size = new System.Drawing.Size(150, 20);
			// 
			// xrTableRow4
			// 
			this.xrTableRow4.Cells.AddRange(new DevExpress.XtraReports.UI.XRTableCell[] {
																							this.xrTableCell7,
																							this.xrTableCell8});
			this.xrTableRow4.Name = "xrTableRow4";
			this.xrTableRow4.Size = new System.Drawing.Size(150, 20);
			// 
			// xrTableCell7
			// 
			this.xrTableCell7.Font = new System.Drawing.Font("Arial", 10.2F, System.Drawing.FontStyle.Bold, System.Drawing.GraphicsUnit.Point, ((System.Byte)(0)));
			this.xrTableCell7.Location = new System.Drawing.Point(0, 0);
			this.xrTableCell7.Name = "xrTableCell7";
			this.xrTableCell7.ParentStyleUsing.UseFont = false;
			this.xrTableCell7.Size = new System.Drawing.Size(73, 20);
			this.xrTableCell7.Text = "Account: ";
			this.xrTableCell7.TextAlignment = DevExpress.XtraPrinting.TextAlignment.TopRight;
			// 
			// xrTableCell8
			// 
			this.xrTableCell8.DataBindings.AddRange(new DevExpress.XtraReports.UI.XRBinding[] {
																								  new DevExpress.XtraReports.UI.XRBinding("Text", null, "HeaderLogo.Account", "")});
			this.xrTableCell8.Font = new System.Drawing.Font("Arial", 10.2F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((System.Byte)(0)));
			this.xrTableCell8.Location = new System.Drawing.Point(73, 0);
			this.xrTableCell8.Name = "xrTableCell8";
			this.xrTableCell8.ParentStyleUsing.UseFont = false;
			this.xrTableCell8.Size = new System.Drawing.Size(77, 20);
			this.xrTableCell8.Text = "xrTableCell8";
			// 
			// xrTable3
			// 
			this.xrTable3.Location = new System.Drawing.Point(393, 80);
			this.xrTable3.Name = "xrTable3";
			this.xrTable3.Rows.AddRange(new DevExpress.XtraReports.UI.XRTableRow[] {
																					   this.xrTableRow3});
			this.xrTable3.Size = new System.Drawing.Size(260, 20);
			// 
			// xrTableRow3
			// 
			this.xrTableRow3.Cells.AddRange(new DevExpress.XtraReports.UI.XRTableCell[] {
																							this.xrTableCell5,
																							this.xrTableCell6});
			this.xrTableRow3.Name = "xrTableRow3";
			this.xrTableRow3.Size = new System.Drawing.Size(260, 20);
			// 
			// xrTableCell5
			// 
			this.xrTableCell5.Font = new System.Drawing.Font("Arial", 10.2F, System.Drawing.FontStyle.Bold, System.Drawing.GraphicsUnit.Point, ((System.Byte)(0)));
			this.xrTableCell5.Location = new System.Drawing.Point(0, 0);
			this.xrTableCell5.Name = "xrTableCell5";
			this.xrTableCell5.ParentStyleUsing.UseFont = false;
			this.xrTableCell5.Size = new System.Drawing.Size(93, 20);
			this.xrTableCell5.Text = "Create Date: ";
			this.xrTableCell5.TextAlignment = DevExpress.XtraPrinting.TextAlignment.TopRight;
			// 
			// xrTableCell6
			// 
			this.xrTableCell6.DataBindings.AddRange(new DevExpress.XtraReports.UI.XRBinding[] {
																								  new DevExpress.XtraReports.UI.XRBinding("Text", null, "HeaderLogo.CreateDate", "")});
			this.xrTableCell6.Font = new System.Drawing.Font("Arial", 10.2F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((System.Byte)(0)));
			this.xrTableCell6.Location = new System.Drawing.Point(93, 0);
			this.xrTableCell6.Name = "xrTableCell6";
			this.xrTableCell6.ParentStyleUsing.UseFont = false;
			this.xrTableCell6.Size = new System.Drawing.Size(167, 20);
			this.xrTableCell6.Text = "xrTableCell6";
			// 
			// xrTable1
			// 
			this.xrTable1.Location = new System.Drawing.Point(7, 80);
			this.xrTable1.Name = "xrTable1";
			this.xrTable1.Rows.AddRange(new DevExpress.XtraReports.UI.XRTableRow[] {
																					   this.xrTableRow1});
			this.xrTable1.Size = new System.Drawing.Size(200, 20);
			// 
			// xrTableRow1
			// 
			this.xrTableRow1.Cells.AddRange(new DevExpress.XtraReports.UI.XRTableCell[] {
																							this.xrTableCell1,
																							this.xrTableCell2});
			this.xrTableRow1.Name = "xrTableRow1";
			this.xrTableRow1.Size = new System.Drawing.Size(200, 20);
			// 
			// xrTableCell1
			// 
			this.xrTableCell1.Font = new System.Drawing.Font("Arial", 10.2F, System.Drawing.FontStyle.Bold, System.Drawing.GraphicsUnit.Point, ((System.Byte)(0)));
			this.xrTableCell1.Location = new System.Drawing.Point(0, 0);
			this.xrTableCell1.Name = "xrTableCell1";
			this.xrTableCell1.ParentStyleUsing.UseFont = false;
			this.xrTableCell1.Size = new System.Drawing.Size(93, 20);
			this.xrTableCell1.Text = "List Number: ";
			this.xrTableCell1.TextAlignment = DevExpress.XtraPrinting.TextAlignment.TopRight;
			// 
			// xrTableCell2
			// 
			this.xrTableCell2.DataBindings.AddRange(new DevExpress.XtraReports.UI.XRBinding[] {
																								  new DevExpress.XtraReports.UI.XRBinding("Text", null, "HeaderLogo.ListNumber", "")});
			this.xrTableCell2.Font = new System.Drawing.Font("Arial", 10.2F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((System.Byte)(0)));
			this.xrTableCell2.Location = new System.Drawing.Point(93, 0);
			this.xrTableCell2.Name = "xrTableCell2";
			this.xrTableCell2.ParentStyleUsing.UseFont = false;
			this.xrTableCell2.Size = new System.Drawing.Size(107, 20);
			this.xrTableCell2.Text = "xrTableCell2";
			// 
			// xrTable2
			// 
			this.xrTable2.Location = new System.Drawing.Point(220, 80);
			this.xrTable2.Name = "xrTable2";
			this.xrTable2.Rows.AddRange(new DevExpress.XtraReports.UI.XRTableRow[] {
																					   this.xrTableRow2});
			this.xrTable2.Size = new System.Drawing.Size(167, 20);
			// 
			// xrTableRow2
			// 
			this.xrTableRow2.Cells.AddRange(new DevExpress.XtraReports.UI.XRTableCell[] {
																							this.xrTableCell3,
																							this.xrTableCell4});
			this.xrTableRow2.Name = "xrTableRow2";
			this.xrTableRow2.Size = new System.Drawing.Size(167, 20);
			// 
			// xrTableCell3
			// 
			this.xrTableCell3.Font = new System.Drawing.Font("Arial", 10.2F, System.Drawing.FontStyle.Bold, System.Drawing.GraphicsUnit.Point, ((System.Byte)(0)));
			this.xrTableCell3.Location = new System.Drawing.Point(0, 0);
			this.xrTableCell3.Name = "xrTableCell3";
			this.xrTableCell3.ParentStyleUsing.UseFont = false;
			this.xrTableCell3.Size = new System.Drawing.Size(60, 20);
			this.xrTableCell3.Text = "Status: ";
			this.xrTableCell3.TextAlignment = DevExpress.XtraPrinting.TextAlignment.TopRight;
			// 
			// xrTableCell4
			// 
			this.xrTableCell4.DataBindings.AddRange(new DevExpress.XtraReports.UI.XRBinding[] {
																								  new DevExpress.XtraReports.UI.XRBinding("Text", null, "HeaderLogo.Status", "")});
			this.xrTableCell4.Font = new System.Drawing.Font("Arial", 10.2F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((System.Byte)(0)));
			this.xrTableCell4.Location = new System.Drawing.Point(60, 0);
			this.xrTableCell4.Name = "xrTableCell4";
			this.xrTableCell4.ParentStyleUsing.UseFont = false;
			this.xrTableCell4.Size = new System.Drawing.Size(107, 20);
			this.xrTableCell4.Text = "xrTableCell4";
			// 
			// xrPanel1
			// 
			this.xrPanel1.Borders = DevExpress.XtraPrinting.BorderSide.All;
			this.xrPanel1.BorderWidth = 2;
			this.xrPanel1.Controls.AddRange(new DevExpress.XtraReports.UI.XRControl[] {
																						  this.xrLine3,
																						  this.xrLabel38,
																						  this.xrLine9,
																						  this.xrLabel40,
																						  this.xrLabel39,
																						  this.xrLine4,
																						  this.xrLabel37,
																						  this.xrLine8});
			this.xrPanel1.Location = new System.Drawing.Point(7, 40);
			this.xrPanel1.Name = "xrPanel1";
			this.xrPanel1.ParentStyleUsing.UseBorders = false;
			this.xrPanel1.ParentStyleUsing.UseBorderWidth = false;
			this.xrPanel1.Size = new System.Drawing.Size(793, 240);
			// 
			// xrLine3
			// 
			this.xrLine3.BorderWidth = 0;
			this.xrLine3.LineStyle = System.Drawing.Drawing2D.DashStyle.Dash;
			this.xrLine3.Location = new System.Drawing.Point(153, 147);
			this.xrLine3.Name = "xrLine3";
			this.xrLine3.ParentStyleUsing.UseBorderWidth = false;
			this.xrLine3.Size = new System.Drawing.Size(627, 7);
			// 
			// xrLabel38
			// 
			this.xrLabel38.BorderWidth = 0;
			this.xrLabel38.Font = new System.Drawing.Font("Arial", 10.2F);
			this.xrLabel38.KeepTogether = true;
			this.xrLabel38.Location = new System.Drawing.Point(13, 187);
			this.xrLabel38.Name = "xrLabel38";
			this.xrLabel38.ParentStyleUsing.UseBorderWidth = false;
			this.xrLabel38.ParentStyleUsing.UseFont = false;
			this.xrLabel38.Size = new System.Drawing.Size(120, 20);
			this.xrLabel38.Text = "Tracking Number:";
			this.xrLabel38.TextAlignment = DevExpress.XtraPrinting.TextAlignment.BottomLeft;
			// 
			// xrLine9
			// 
			this.xrLine9.BorderWidth = 0;
			this.xrLine9.LineStyle = System.Drawing.Drawing2D.DashStyle.Dash;
			this.xrLine9.Location = new System.Drawing.Point(147, 100);
			this.xrLine9.Name = "xrLine9";
			this.xrLine9.ParentStyleUsing.UseBorderWidth = false;
			this.xrLine9.Size = new System.Drawing.Size(640, 6);
			// 
			// xrLabel40
			// 
			this.xrLabel40.BorderWidth = 0;
			this.xrLabel40.Font = new System.Drawing.Font("Arial", 10.2F);
			this.xrLabel40.KeepTogether = true;
			this.xrLabel40.Location = new System.Drawing.Point(13, 33);
			this.xrLabel40.Name = "xrLabel40";
			this.xrLabel40.ParentStyleUsing.UseBorderWidth = false;
			this.xrLabel40.ParentStyleUsing.UseFont = false;
			this.xrLabel40.Size = new System.Drawing.Size(67, 20);
			this.xrLabel40.Text = "Remarks:";
			this.xrLabel40.TextAlignment = DevExpress.XtraPrinting.TextAlignment.BottomLeft;
			// 
			// xrLabel39
			// 
			this.xrLabel39.BorderWidth = 0;
			this.xrLabel39.Font = new System.Drawing.Font("Arial", 10.2F);
			this.xrLabel39.KeepTogether = true;
			this.xrLabel39.Location = new System.Drawing.Point(13, 133);
			this.xrLabel39.Name = "xrLabel39";
			this.xrLabel39.ParentStyleUsing.UseBorderWidth = false;
			this.xrLabel39.ParentStyleUsing.UseFont = false;
			this.xrLabel39.Size = new System.Drawing.Size(140, 20);
			this.xrLabel39.Text = "Receiver\'s Signature:";
			this.xrLabel39.TextAlignment = DevExpress.XtraPrinting.TextAlignment.BottomLeft;
			// 
			// xrLine4
			// 
			this.xrLine4.BorderWidth = 0;
			this.xrLine4.LineStyle = System.Drawing.Drawing2D.DashStyle.Dash;
			this.xrLine4.Location = new System.Drawing.Point(80, 47);
			this.xrLine4.Name = "xrLine4";
			this.xrLine4.ParentStyleUsing.UseBorderWidth = false;
			this.xrLine4.Size = new System.Drawing.Size(700, 5);
			// 
			// xrLabel37
			// 
			this.xrLabel37.BorderWidth = 0;
			this.xrLabel37.Font = new System.Drawing.Font("Arial", 10.2F);
			this.xrLabel37.KeepTogether = true;
			this.xrLabel37.Location = new System.Drawing.Point(13, 87);
			this.xrLabel37.Name = "xrLabel37";
			this.xrLabel37.ParentStyleUsing.UseBorderWidth = false;
			this.xrLabel37.ParentStyleUsing.UseFont = false;
			this.xrLabel37.Size = new System.Drawing.Size(133, 20);
			this.xrLabel37.Text = "Shipper\'s Signature:";
			this.xrLabel37.TextAlignment = DevExpress.XtraPrinting.TextAlignment.BottomLeft;
			// 
			// xrLine8
			// 
			this.xrLine8.BorderWidth = 0;
			this.xrLine8.LineStyle = System.Drawing.Drawing2D.DashStyle.Dash;
			this.xrLine8.Location = new System.Drawing.Point(133, 200);
			this.xrLine8.Name = "xrLine8";
			this.xrLine8.ParentStyleUsing.UseBorderWidth = false;
			this.xrLine8.Size = new System.Drawing.Size(653, 10);
			// 
			// XRReceiveListDetail
			// 
			this.Bands.AddRange(new DevExpress.XtraReports.UI.Band[] {
																		 this.DetailReport});
			this.Font = new System.Drawing.Font("Arial", 10.2F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((System.Byte)(0)));
			((System.ComponentModel.ISupportInitialize)(this.xrTable4)).EndInit();
			((System.ComponentModel.ISupportInitialize)(this.xrTable3)).EndInit();
			((System.ComponentModel.ISupportInitialize)(this.xrTable1)).EndInit();
			((System.ComponentModel.ISupportInitialize)(this.xrTable2)).EndInit();
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

		private void xrLabel2_BeforePrint(object sender, System.Drawing.Printing.PrintEventArgs e)
		{
			XRLabel label = sender as XRLabel;
			label.Text = "Total Media:" + iRowCount.ToString();		
		}

	}
}

