using System;
using System.IO;
using Bandl.Library.VaultLedger.BLL;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.Exceptions;
using Bandl.Library.VaultLedger.Collections;
using Bandl.VaultLedger.Web.Printing;
using DevExpress.XtraPrinting;
using DevExpress.XtraReports.UI;
using DevExpress.XtraReports.Web;

namespace Bandl.VaultLedger.Web.UI
{
	/// <summary>
	/// Summary description for Print.
	/// </summary>
	public class printPage : BasePage
	{
        private string CompanyLogo;
        protected DevExpress.XtraReports.Web.ReportViewer ReportViewer1;
        private string ProductLogo;

        #region Web Form Designer generated code
        override protected void OnInit(EventArgs e)
        {
            //
            // CODEGEN: This call is required by the ASP.NET Web Form Designer.
            //
            InitializeComponent();
            base.OnInit(e);
        }
		
        /// <summary>
        /// Required method for Designer support - do not modify
        /// the contents of this method with the code editor.
        /// </summary>
        private void InitializeComponent()
        {    

        }
        #endregion

        protected override void Event_PageInit(object sender, System.EventArgs e)
        {
            this.createHeader = false;
            this.createNavigation = false;
            this.pageTitle = "Print Page";
            this.helpId = 0;
            // If we have an error, redirect to the error page
            if (Session[CacheKeys.Exception] != null) Server.Transfer("errorPage.aspx");
        }

        protected override void Event_PageLoad(object sender, System.EventArgs e)
        {
            if (!Page.IsPostBack)
            {
                try
                {
                    PrintSources printSource = 0;
                    object[] printObjects = null;
                    // Get the print source and remove it from the session cache.  If
                    // there is no print source, just leave the page.
                    if (Session[CacheKeys.PrintSource] != null)
                    {
                        // Get the print source
                        printSource = (PrintSources)Session[CacheKeys.PrintSource];
//                        Session.Remove(CacheKeys.PrintSource);
                        // Get the print object if there is one
                        if (Session[CacheKeys.PrintObjects] != null)
                        {
                            printObjects = (object[])Session[CacheKeys.PrintObjects];
//                            Session.Remove(CacheKeys.PrintObjects);
                        }
                        // Set Company and Product Logo image file paths
                        CompanyLogo = Path.Combine(Path.Combine(ImagePathDirectory,"interface"), "logoNoBack.jpg");
                        ProductLogo = Path.Combine(Path.Combine(ImagePathDirectory,"interface"), "logoHeaderNoBack.jpg");
                        // Display the page
                        ShowPrintDisplay(printSource, printObjects);
                    }
                }
                catch (System.Threading.ThreadAbortException)
                {
                    ;
                }
                catch (Exception ex)
                {
                    throw new NoPrintDataException(ex.Message);
                }
            }
        }
        /// <summary>
        /// Creates and displays the report
        /// </summary>
        private void ShowPrintDisplay(PrintSources printSource, object[] printObjects)
        {
            // Create the report
            XtraReport oReport = CreateReport(printSource, printObjects);
            // Set printer settings
            PrinterSettingsUsing oExport = new PrinterSettingsUsing();
            oExport.UseLandscape = true;
            // Set page settings
            //oReport.PrintingSystem.PageSettings.AssignDefaultPrinterSettings(oExport);
            // Write report to response
            ReportViewer1.Report = oReport;
            ReportViewer1.WritePdfTo(Response);
        }
        /// <summary>
        /// Gets the image data from a file name
        /// </summary>
        /// <param name="fileName"></param>
        /// <returns></returns>
        private byte[] GetImageData(string fileName)
        {
            // Method to load an image from disk and return it as a bytestream
            FileStream fs = new FileStream(fileName, FileMode.Open, FileAccess.Read);
            BinaryReader br = new BinaryReader(fs);
            return br.ReadBytes(Convert.ToInt32(br.BaseStream.Length));
        }

        #region Specific Report Creation Methods
        /// <summary>
        /// Creates an account detail report
        /// </summary>
        /// <param name="printObjects"></param>
        /// <returns></returns>
        private XtraReport CreateAccountDetailPage(object[] printObjects)
        {
            dsAccount ds = new dsAccount();
            // Header
            dsAccount.HeaderLogoRow dh = ds.HeaderLogo.NewHeaderLogoRow();
            dh.CompanyLogo = GetImageData(CompanyLogo);
            dh.ProductLogo = GetImageData(ProductLogo);
            dh.ReportTitle = "Account Detail";
            ds.HeaderLogo.Rows.Add(dh);
            // Data
            AccountDetails a = (AccountDetails)printObjects[0];
            dsAccount.AccountRow dr = ds.Account.NewAccountRow();
            dr.Name = a.Name;
            dr.Primary = a.Primary ? "Yes" : "No";
            dr.Address1 = a.Address1;
            dr.Address2 = a.Address2;
            dr.City = a.City;
            dr.State = a.State;
            dr.ZipCode = a.ZipCode;
            dr.Country = a.Country;
            dr.Contact = a.Contact;
            dr.PhoneNo = a.PhoneNo;
            dr.Email = a.Email;
            dr.Notes = a.Notes;
            ds.Account.Rows.Add(dr);
            // Create the report class
            XRAccountDetail oReport = new XRAccountDetail();
            oReport.DataSource = ds;
            // Return the report
            return oReport;
        }
        /// <summary>
        /// Creates an account report
        /// </summary>
        /// <param name="printObjects"></param>
        /// <returns></returns>
        private XtraReport CreateAccountsReport(object[] printObjects)
        {
            dsAccount ds = new dsAccount();
            // Header
            dsAccount.HeaderLogoRow dh = ds.HeaderLogo.NewHeaderLogoRow();
            dh.CompanyLogo = GetImageData(CompanyLogo);
            dh.ProductLogo = GetImageData(ProductLogo);
            dh.ReportTitle = "Accounts Report";
            ds.HeaderLogo.Rows.Add(dh);
            // Data
            foreach (AccountDetails a in (AccountCollection)printObjects[0])
            {
                dsAccount.AccountRow dr = ds.Account.NewAccountRow();
                dr.Name = a.Name;
                dr.Primary = "ND";
                dr.Address1 = "ND";
                dr.Address2 = "ND";
                dr.City = a.City;
                dr.State = a.State;
                dr.ZipCode = "ND";
                dr.Country = "ND";
                dr.Contact = "ND";
                dr.PhoneNo = a.PhoneNo;
                dr.Email = "ND";
                dr.Notes = "ND";
                ds.Account.Rows.Add(dr);
            }
            // Create the report class
            XRAccounts oReport = new XRAccounts();
            oReport.DataSource = ds;
            // Return the report
            return oReport;
        }
        /// <summary>
        /// Creates a data set for loading into report document out of print
        /// input from an auditor report page.
        /// </summary>
        private XtraReport CreateAuditorReport(PrintSources printSource, object[] printObjects)
        {
            if (((AuditTrailCollection)printObjects[0]).Count == 0)
            {
                throw new NoPrintDataException("Using the given search parameters, no audit trail data was found.");
            }
            else
            {
                dsAuditTrail ds = new dsAuditTrail();
                // Header
                dsAuditTrail.HeaderLogoRow dh = ds.HeaderLogo.NewHeaderLogoRow();
                dh.CompanyLogo = GetImageData(CompanyLogo);
                dh.ProductLogo = GetImageData(ProductLogo);
                // Title and headers
                switch (printSource)
                {
                    case PrintSources.AuditorReportExternalSite:
                        dh.ReportTitle = "Site Maps Auditor Report";
                        dh.ObjectTitle = "Site Name";
                        break;
                    case PrintSources.AuditorReportAccount:
                        dh.ReportTitle = "Accounts Auditor Report";
                        dh.ObjectTitle = "Account Number";
                        break;
                    case PrintSources.AuditorReportMedium:
                        dh.ReportTitle = "Media History Auditor Report";
                        dh.ObjectTitle = "Serial Number";
                        break;
                    case PrintSources.AuditorReportMediumMovement:
                        dh.ReportTitle = "Media Movement History Auditor Report";
                        dh.ObjectTitle = "Serial Number";
                        break;
                    case PrintSources.AuditorReportSendList:
                        dh.ReportTitle = "Shipping List Auditor Report";
                        dh.ObjectTitle = "List Number";
                        break;
                    case PrintSources.AuditorReportReceiveList:
                        dh.ReportTitle = "Receiving List Auditor Report";
                        dh.ObjectTitle = "List Number";
                        break;
                    case PrintSources.AuditorReportDisasterCodeList:
                        dh.ReportTitle = "Disaster Recovery List Auditor Report";
                        dh.ObjectTitle = "List Number";
                        break;
                    case PrintSources.AuditorReportBarCodePattern:
                        dh.ReportTitle = "Bar Code Formats Auditor Report";
                        dh.ObjectTitle = "Format Pattern";
                        break;
                    case PrintSources.AuditorReportSealedCase:
                        dh.ReportTitle = "Sealed Cases Auditor Report";
                        dh.ObjectTitle = "Case Number";
                        break;
                    case PrintSources.AuditorReportInventory:
                        dh.ReportTitle = "Inventory Auditor Report";
                        dh.ObjectTitle = "Account Number";
                        break;
                    case PrintSources.AuditorReportOperator:
                        dh.ReportTitle = "Users Auditor Report";
                        dh.ObjectTitle = "";
                        break;
                    case PrintSources.AuditorReportInventoryConflict:
                        dh.ReportTitle = "Inventory Discrepancy Auditor Report";
                        dh.ObjectTitle = "Serial Number";
                        break;
                    case PrintSources.AuditorReportSystemAction:
                        dh.ReportTitle = "Miscellaneous Auditor Report";
                        dh.ObjectTitle = "";
                        break;
                    case PrintSources.AuditorReportAllValues:
                        dh.ReportTitle = "Complete Auditor Report";
                        dh.ObjectTitle = "Object";
                        break;
                    default:
                        break;
                }
                // Add the header row
                ds.HeaderLogo.Rows.Add(dh);
                // Data
                foreach (AuditTrailDetails ar in (AuditTrailCollection)printObjects[0])
                {
                    dsAuditTrail.AuditTrailRow dr = ds.AuditTrail.NewAuditTrailRow();
                    dr.AuditType  = ar.AuditType.ToString();
                    dr.RecordDate = DisplayDate(ar.RecordDate);
                    dr.ObjectName = ar.ObjectName;
                    dr.Detail     = ar.Detail;
                    dr.Login      = ar.Login;
                    ds.AuditTrail.Rows.Add(dr);
                }
                // Create the report class
                XtraReport oReport;
                switch (printSource)
                {
                    case PrintSources.AuditorReportSystemAction:
                    case PrintSources.AuditorReportOperator:
                        oReport = new XRAuditorOperator();  // 3 column report
                        break;
                    default:
                        oReport = new XRAuditor();          // 4 column report
                        break;
                }
                oReport.DataSource = ds;
                // Return report class
                return oReport;
            }
        }
        /// <summary>
        /// Creates a bar code case report
        /// </summary>
        /// <param name="printObjects"></param>
        /// <returns></returns>
        private XtraReport CreateBarCodeCaseReport(object[] printObjects)
        {
            dsBarCodeCase ds = new dsBarCodeCase();
            // Header
            dsBarCodeCase.HeaderLogoRow dh = ds.HeaderLogo.NewHeaderLogoRow();
            dh.CompanyLogo = GetImageData(CompanyLogo);
            dh.ProductLogo = GetImageData(ProductLogo);
            dh.ReportTitle = "Case Formats Report";
            ds.HeaderLogo.Rows.Add(dh);
            // Data
            foreach (PatternDefaultCaseDetails p in (PatternDefaultCaseCollection)printObjects[0])
            {
                dsBarCodeCase.BarCodeCaseRow dr = ds.BarCodeCase.NewBarCodeCaseRow();
                dr.Pattern = p.Pattern;
                dr.CaseType = p.CaseType;
                ds.BarCodeCase.Rows.Add(dr);
            }
            // Create the report class
            XRBarCodeCase oReport = new XRBarCodeCase();
            oReport.DataSource = ds;
            // Return the report
            return oReport;
        }
        /// <summary>
        /// Creates a bar code medium report
        /// </summary>
        /// <param name="printObjects"></param>
        /// <returns></returns>
        private XtraReport CreateBarCodeMediumReport(object[] printObjects)
        {
            dsBarCodeMedium ds = new dsBarCodeMedium();
            // Header
            dsBarCodeMedium.HeaderLogoRow dh = ds.HeaderLogo.NewHeaderLogoRow();
            dh.CompanyLogo = GetImageData(CompanyLogo);
            dh.ProductLogo = GetImageData(ProductLogo);
            dh.ReportTitle = "Bar Code Formats Report";
            ds.HeaderLogo.Rows.Add(dh);
            // Data
            foreach (PatternDefaultMediumDetails p in (PatternDefaultMediumCollection)printObjects[0])
            {
                dsBarCodeMedium.BarCodeMediumRow dr = ds.BarCodeMedium.NewBarCodeMediumRow();
                dr.Pattern = p.Pattern;
                dr.MediumType = p.MediumType;
                dr.Account = p.Account;
                ds.BarCodeMedium.Rows.Add(dr);
            }
            // Create the report class
            XRBarCodeMedium oReport = new XRBarCodeMedium();
            oReport.DataSource = ds;
            // Return the report
            return oReport;
        }
        /// <summary>
        /// Creates an disaster code list detail page report
        /// </summary>
        /// <param name="printObjects"></param>
        /// <returns></returns>
        private XtraReport CreateDisasterCodeListDetailPage(object[] printObjects)
        {
            dsDisasterCodeListItem ds = new dsDisasterCodeListItem();
            DisasterCodeListDetails d = (DisasterCodeListDetails)printObjects[0];
            // Header
            dsDisasterCodeListItem.HeaderLogoRow dh = ds.HeaderLogo.NewHeaderLogoRow();
            dh.CompanyLogo = GetImageData(CompanyLogo);
            dh.ProductLogo = GetImageData(ProductLogo);
            dh.ReportTitle = "Disaster Recovery List Detail";
            dh.ListNumber = d.Name;
            dh.Status = ListStatus.ToUpper(d.Status);
            dh.CreateDate = DisplayDate(d.CreateDate);
            dh.Account = d.Account;
            ds.HeaderLogo.Rows.Add(dh);
            // Data
            foreach (DisasterCodeListItemDetails i in (DisasterCodeListItemCollection)printObjects[1])
            {
                dsDisasterCodeListItem.DisasterCodeListItemRow dr = ds.DisasterCodeListItem.NewDisasterCodeListItemRow();
                dr.SerialNo = i.SerialNo;
                dr.Code = i.Code;
                dr.Status = ListStatus.ToUpper(i.Status);
                dr.Notes = i.Notes;
                ds.DisasterCodeListItem.Rows.Add(dr);
            }
            // Create the report class
            XRDRListDetail oReport = new XRDRListDetail();
            oReport.DataSource = ds;
            // Return the report
            return oReport;
        }
        /// <summary>
        /// Creates a disaster code list report
        /// </summary>
        /// <param name="printObjects"></param>
        /// <returns></returns>
        private XtraReport CreateDisasterCodeListReport(object[] printObjects)
        {
            dsSRDCList ds = new dsSRDCList();
            // Header
            dsSRDCList.HeaderLogoRow dh = ds.HeaderLogo.NewHeaderLogoRow();
            dh.CompanyLogo = GetImageData(CompanyLogo);
            dh.ProductLogo = GetImageData(ProductLogo);
            dh.ReportTitle = "Disaster Recovery Lists Report";
            ds.HeaderLogo.Rows.Add(dh);
            // Data
            foreach (DisasterCodeListDetails d in (DisasterCodeListCollection)printObjects[0])
            {
                dsSRDCList.SRDCListRow dr = ds.SRDCList.NewSRDCListRow();
                dr.ListName = d.Name;
                dr.CreateDate = DisplayDate(d.CreateDate);
                dr.Status = ListStatus.ToUpper(d.Status);
                dr.Account = d.Account;
                ds.SRDCList.Rows.Add(dr);
            }
            // Create the report class
            XRSendReceiveDCList oReport = new XRSendReceiveDCList();
            oReport.DataSource = ds;
            // Return the report
            return oReport;
        }
        /// <summary>
        /// Creates an external site report
        /// </summary>
        /// <param name="printObjects"></param>
        /// <returns></returns>
        private XtraReport CreateExternalSiteReport(object[] printObjects)
        {
            dsExternalSite ds = new dsExternalSite();
            // Header
            dsExternalSite.HeaderLogoRow dh = ds.HeaderLogo.NewHeaderLogoRow();
            dh.CompanyLogo = GetImageData(CompanyLogo);
            dh.ProductLogo = GetImageData(ProductLogo);
            dh.ReportTitle = "Site Maps Report";
            ds.HeaderLogo.Rows.Add(dh);
            // Data
            foreach (ExternalSiteDetails e in (ExternalSiteCollection)printObjects[0])
            {
                dsExternalSite.ExternalSiteRow dr = ds.ExternalSite.NewExternalSiteRow();
                dr.SiteName = e.Name;
                dr.Location = e.Location.ToString();
                ds.ExternalSite.Rows.Add(dr);
            }
            // Create the report class
            XRExternalSite oReport = new XRExternalSite();
            oReport.DataSource = ds;
            // Return the report
            return oReport;
        }
        /// <summary>
        /// Creates a medium report
        /// </summary>
        /// <param name="printObjects"></param>
        /// <returns></returns>
        private XtraReport CreateMediumReport(object[] printObjects)
        {
            dsFindMedium ds = new  dsFindMedium();
            // Header
            dsFindMedium.HeaderLogoRow dh = ds.HeaderLogo.NewHeaderLogoRow();
            dh.CompanyLogo = GetImageData(CompanyLogo);
            dh.ProductLogo = GetImageData(ProductLogo);
            dh.ReportTitle = "Media Report";
            ds.HeaderLogo.Rows.Add(dh);
            // Data
            foreach (MediumDetails m in (MediumCollection)printObjects[0])
            {
                dsFindMedium.MediumRow dr = ds.Medium.NewMediumRow();
                dr.Account = m.Account;
                dr.SerialNo = m.SerialNo;
                dr.CaseName = m.CaseName;
                dr.Location = m.Location.ToString();
                dr.MediumType = m.MediumType;
                dr.Missing = m.Missing ? "Yes" : "No";
                dr.Notes = m.Notes;
                dr.ReturnDate = m.ReturnDate.Length != 0 ? DisplayDate(m.ReturnDate, false, false) : String.Empty;
                ds.Medium.Rows.Add(dr);
            }
            // Create the report class
            XRFindMedium oReport = new XRFindMedium();
            oReport.DataSource = ds;
            // Return the report
            return oReport;
        }
        /// <summary>
        /// Creates a medium report
        /// </summary>
        /// <param name="printObjects"></param>
        /// <returns></returns>
        private XtraReport CreateMediumDetailPage(object[] printObjects)
        {
            dsMedium ds = new dsMedium();
            // Header
            dsMedium.HeaderLogoRow dh = ds.HeaderLogo.NewHeaderLogoRow();
            dh.CompanyLogo = GetImageData(CompanyLogo);
            dh.ProductLogo = GetImageData(ProductLogo);
            dh.ReportTitle = "Medium Information";
            ds.HeaderLogo.Rows.Add(dh);
            // Data
            MediumDetails m = (MediumDetails)printObjects[0];
            dsMedium.MediumRow dr = ds.Medium.NewMediumRow();
            dr.Account = m.Account;
            dr.SerialNo = m.SerialNo;
            dr.CaseName = m.CaseName;
            dr.Location = m.Location.ToString();
            dr.MediumType = m.MediumType;
            dr.Missing = m.Missing ? "Yes" : "No";
            dr.Notes = m.Notes;
            dr.BSide = (string)printObjects[1]; // Active list
            dr.HotStatus = (string)printObjects[2]; // Active list status
            dr.ReturnDate = m.ReturnDate.Length != 0 ? DisplayDate(m.ReturnDate, false, false) : String.Empty;
            ds.Medium.Rows.Add(dr);
            foreach (AuditTrailDetails ar in (AuditTrailCollection)printObjects[3])
            {
                dsMedium.AuditTrailRow dma = ds.AuditTrail.NewAuditTrailRow();
                dma.AuditType  = ar.AuditType.ToString();
                dma.RecordDate = DisplayDate(ar.RecordDate);
                dma.ObjectName = ar.ObjectName;
                dma.Detail = ar.Detail;
                dma.Login = ar.Login;
                ds.AuditTrail.Rows.Add(dma);
            }
            // Create the report class
            XRMedia oReport = new XRMedia();
            oReport.DataSource = ds;
            // Return the report
            return oReport;
        }
        /// <summary>
        /// Creates an receive list detail page report
        /// </summary>
        /// <param name="printObjects"></param>
        /// <returns></returns>
        private XtraReport CreateReceiveListDetailPage(object[] printObjects)
        {
            dsReceiveListItem ds = new dsReceiveListItem();
            // Header
            dsReceiveListItem.HeaderLogoRow dh = ds.HeaderLogo.NewHeaderLogoRow();
            dh.CompanyLogo = GetImageData(CompanyLogo);
            dh.ProductLogo = GetImageData(ProductLogo);
            dh.ReportTitle = "Receiving List Detail";
            ReceiveListDetails r = (ReceiveListDetails)printObjects[0];
            dh.ListNumber     = r.Name;
            dh.Status         = ListStatus.ToUpper(r.Status);
            dh.CreateDate     = DisplayDate(r.CreateDate);
            dh.Account        = r.Account;
            ds.HeaderLogo.Rows.Add(dh);
            // Data
            foreach (ReceiveListItemDetails i in (ReceiveListItemCollection)printObjects[1])
            {
                dsReceiveListItem.ReceiveListItemRow dr = ds.ReceiveListItem.NewReceiveListItemRow();
                dr.SerialNo = i.SerialNo;
				dr.MediaType = i.MediumType;
                dr.Status = ListStatus.ToUpper(i.Status);
                dr.CaseName = i.CaseName;
                dr.Notes = i.Notes;
                ds.ReceiveListItem.Rows.Add(dr);
            }
            // Create the report class
            XRReceiveListDetail oReport = new XRReceiveListDetail();
            oReport.DataSource = ds;
            // Return the report
            return oReport;
        }
        /// <summary>
        /// Creates a receive list report
        /// </summary>
        /// <param name="printObjects"></param>
        /// <returns></returns>
        private XtraReport CreateReceiveListReport(object[] printObjects)
        {
            dsSRDCList ds = new dsSRDCList();
            // Header
            dsSRDCList.HeaderLogoRow dh = ds.HeaderLogo.NewHeaderLogoRow();
            dh.CompanyLogo = GetImageData(CompanyLogo);
            dh.ProductLogo = GetImageData(ProductLogo);
            dh.ReportTitle = "Receiving Lists Report";
            ds.HeaderLogo.Rows.Add(dh);
            // Data
            foreach (ReceiveListDetails r in (ReceiveListCollection)printObjects[0])
            {
                dsSRDCList.SRDCListRow dr = ds.SRDCList.NewSRDCListRow();
                dr.ListName = r.Name;
                dr.CreateDate = DisplayDate(r.CreateDate);
                dr.Status = ListStatus.ToUpper(r.Status);
                dr.Account = r.Account;
                ds.SRDCList.Rows.Add(dr);
            }
            // Create the report class
            XRSendReceiveDCList oReport = new XRSendReceiveDCList();
            oReport.DataSource = ds;
            // Return the report
            return oReport;
        }
        /// <summary>
        /// Creates a send list detail page report
        /// </summary>
        /// <param name="printObjects"></param>
        /// <returns></returns>
        private XtraReport CreateSendListDetailPage(object[] printObjects)
        {

            dsSendListItem ds = new dsSendListItem();
            // Header
            dsSendListItem.HeaderLogoRow dh = ds.HeaderLogo.NewHeaderLogoRow();
            dh.CompanyLogo = GetImageData(CompanyLogo);
            dh.ProductLogo = GetImageData(ProductLogo);
            dh.ReportTitle = "Shipping List Detail Information";
            SendListDetails s = (SendListDetails)printObjects[0];
            dh.ListNumber = s.Name;
            dh.Status = ListStatus.ToUpper(s.Status);
            dh.CreateDate = DisplayDate(s.CreateDate);
            dh.Account = s.Account;
            ds.HeaderLogo.Rows.Add(dh);
            // Data
            foreach (SendListItemDetails i in (SendListItemCollection)printObjects[1])
            {
                dsSendListItem.SendListItemRow dr = ds.SendListItem.NewSendListItemRow();
                dr.SerialNo = i.SerialNo;
				dr.MediaType = i.MediumType;
                dr.Status = ListStatus.ToUpper(i.Status);
                dr.ReturnDate = i.ReturnDate.Length != 0 ? DisplayDate(i.ReturnDate,false,false) : String.Empty;
                dr.CaseName = i.CaseName;
                dr.Notes = i.Notes;
                ds.SendListItem.Rows.Add(dr);
            }
            // Create the report class
            XRSendListDetail oReport = new XRSendListDetail();
            oReport.DataSource = ds;
            // Return the report
            return oReport;
        }
        /// <summary>
        /// Creates a send list report
        /// </summary>
        /// <param name="printObjects"></param>
        /// <returns></returns>
        private XtraReport CreateSendListReport(object[] printObjects)
        {
            dsSRDCList ds = new  dsSRDCList();
            // Header
            dsSRDCList.HeaderLogoRow dh = ds.HeaderLogo.NewHeaderLogoRow();
            dh.CompanyLogo = GetImageData(CompanyLogo);
            dh.ProductLogo = GetImageData(ProductLogo);
            dh.ReportTitle = "Shipping Lists Report";
            ds.HeaderLogo.Rows.Add(dh);
            // Data
            foreach (SendListDetails s in (SendListCollection)printObjects[0])
            {
                dsSRDCList.SRDCListRow dr = ds.SRDCList.NewSRDCListRow();
                dr.ListName = s.Name;
                dr.CreateDate = DisplayDate(s.CreateDate);
                dr.Status = ListStatus.ToUpper(s.Status);
                dr.Account = s.Account;
                ds.SRDCList.Rows.Add(dr);
            }
            // Create the report class
            XRSendReceiveDCList oReport = new XRSendReceiveDCList();
            oReport.DataSource = ds;
            // Return the report
            return oReport;
        }
        /// <summary>
        /// Creates a user detail page report
        /// </summary>
        /// <param name="printObjects"></param>
        /// <returns></returns>
        private XtraReport CreateUserDetailPage(object[] printObjects)
        {
            dsOperator ds = new dsOperator();
            // Header
            dsOperator.HeaderLogoRow dh = ds.HeaderLogo.NewHeaderLogoRow();
            dh.CompanyLogo = GetImageData(CompanyLogo);
            dh.ProductLogo = GetImageData(ProductLogo);
            ds.HeaderLogo.Rows.Add(dh);
            // Data
            OperatorDetails o = (OperatorDetails)printObjects[0];
            dsOperator.OperatorRow dr = ds.Operator.NewOperatorRow();
            dr.Email = o.Email;                
            dr.Login = o.Login;
            dr.Notes = o.Notes;
            dr.OperatorName = o.Name;
            dr.PhoneNo = o.PhoneNo;
            dr.Role = o.Role != "VaultOps" ? o.Role : "Vault Operator";
			dr.Accounts = LoadAccounts( o.Id );
            ds.Operator.Rows.Add(dr);
            // Create the report class
            XRUserDetail oReport = new XRUserDetail();
            oReport.DataSource = ds;
            // Return the report
            return oReport;
        }
        /// <summary>
        /// Creates a user report
        /// </summary>
        /// <param name="printObjects"></param>
        /// <returns></returns>
        private XtraReport CreateUserReport(object[] printObjects)
        {
            dsOperator ds = new dsOperator();
            // Header
            dsOperator.HeaderLogoRow dh = ds.HeaderLogo.NewHeaderLogoRow();
            dh.CompanyLogo = GetImageData(CompanyLogo);
            dh.ProductLogo = GetImageData(ProductLogo);
            dh.ReportTitle = "Users Report";
            ds.HeaderLogo.Rows.Add(dh);
            // Data
            foreach (OperatorDetails o in (OperatorCollection)printObjects[0])
            {
                dsOperator.OperatorRow dr = ds.Operator.NewOperatorRow();
                dr.Login = o.Login;
                dr.OperatorName = o.Name;
                dr.Role = o.Role != "VaultOps" ? o.Role : "Vault Operator";
                ds.Operator.Rows.Add(dr);
            }
            // Create the report class
            XRUser oReport = new XRUser();
            oReport.DataSource = ds;
            // Return report
            return oReport;
        }
        /// <summary>
        /// Creates a vault discrepancy report
        /// </summary>
        /// <param name="printObjects"></param>
        /// <returns></returns>
        private XtraReport CreateInventoryDiscrepancyReport(object[] printObjects)
        {
            dsVaultDiscrepancy ds = new dsVaultDiscrepancy();
            // Header
            dsVaultDiscrepancy.HeaderLogoRow dh = ds.HeaderLogo.NewHeaderLogoRow();
            dh.CompanyLogo = GetImageData(CompanyLogo);
            dh.ProductLogo = GetImageData(ProductLogo);
            dh.ReportTitle = "Inventory Discrepancy Report";
            ds.HeaderLogo.Rows.Add(dh);
            // Data
            foreach (InventoryConflictDetails c in (InventoryConflictCollection)printObjects[0])
            {
                dsVaultDiscrepancy.VaultDiscrepancyRow dr = ds.VaultDiscrepancy.NewVaultDiscrepancyRow();
                dr.SerialNo = c.SerialNo;
                dr.Details = c.Details;
                dr.RecordedDate = DisplayDate(c.RecordedDate);
                ds.VaultDiscrepancy.Rows.Add(dr);
            }
            // Create the report class
            XRVaultDiscrepancy oReport = new XRVaultDiscrepancy();
            oReport.DataSource = ds;
            // Return the report
            return oReport;
        }
        #endregion
        
        /// <summary>
        /// Creates a data set for loading into report document out of print
        /// input from an operational page.
        /// </summary>
        private XtraReport CreateReport(PrintSources printSource, object[] printObjects)
        {
            XtraReport oReport = null;

            if (printSource.ToString().StartsWith("AuditorReport"))
            {
                return CreateAuditorReport(printSource, printObjects);
            }
            else
            {
                switch (printSource)
                {
                    case PrintSources.AccountDetailPage:
                        oReport = CreateAccountDetailPage(printObjects);
                        break;
                    case PrintSources.AccountsPage:
                    case PrintSources.AccountsReport:
                        oReport = CreateAccountsReport(printObjects);
                        break;
                    case PrintSources.BarCodeCasePage:
                    case PrintSources.BarCodeCaseReport:
                        oReport = CreateBarCodeCaseReport(printObjects);
                        break;
                    case PrintSources.BarCodeMediumPage:
                    case PrintSources.BarCodeMediumReport:
                        oReport = CreateBarCodeMediumReport(printObjects);
                        break;
                    case PrintSources.ExternalSitePage:
                    case PrintSources.ExternalSiteReport:
                        oReport = CreateExternalSiteReport(printObjects);
                        break;
                    case PrintSources.DisasterCodeListDetailPage:
                        oReport = CreateDisasterCodeListDetailPage(printObjects);
                        break;
                    case PrintSources.DisasterCodeListsPage:
                    case PrintSources.DisasterCodeListsReport:
                        oReport = CreateDisasterCodeListReport(printObjects);
                        break;
                    case PrintSources.FindMediaPage:
                    case PrintSources.FindMediaReport:
                        oReport = CreateMediumReport(printObjects);
                        break;
                    case PrintSources.MediumDetailPage:
                        oReport = CreateMediumDetailPage(printObjects);
                        break;
                    case PrintSources.ReceiveListDetailPage:
                        oReport = CreateReceiveListDetailPage(printObjects);
                        break;
                    case PrintSources.ReceiveListsPage:
                    case PrintSources.ReceiveListsReport:
                        oReport = CreateReceiveListReport(printObjects);
                        break;
                    case PrintSources.SendListDetailPage:
                        oReport = CreateSendListDetailPage(printObjects);
                        break;
                    case PrintSources.SendListsPage:
                    case PrintSources.SendListsReport:
                        oReport = CreateSendListReport(printObjects);
                        break;
                    case PrintSources.UserDetailPage:
                        oReport = CreateUserDetailPage(printObjects);
                        break;
                    case PrintSources.UserSecurityPage:
                    case PrintSources.UserSecurityReport:
                        oReport = CreateUserReport(printObjects);
                        break;
                    case PrintSources.InventoryReconcilePage:
                        oReport = CreateInventoryDiscrepancyReport(printObjects);
                        break;
                }
            }
            // Return the report class
            return oReport;
        }

		private string LoadAccounts( int _iID )
		{
			string szReturnAccounts = string.Empty;
			AccountCollection accountCollection = Operator.GetAccounts(_iID);
			if ( accountCollection.Count > 0 )
			{
				foreach (AccountDetails a in accountCollection)
					szReturnAccounts+= a.Name + ", ";
				szReturnAccounts = szReturnAccounts.Substring( 0, szReturnAccounts.Length -2);
			}

			return( szReturnAccounts );
		}

    }
}
