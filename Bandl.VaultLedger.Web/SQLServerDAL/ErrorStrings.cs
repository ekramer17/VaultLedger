using System;
using System.Web;
using System.Collections;
using Bandl.Library.VaultLedger.Model;

namespace Bandl.Library.VaultLedger.SQLServerDAL
{
	/// <summary>
	/// Summary description for ErrorStrings
	/// </summary>
	public class ErrorStrings
	{
        #region Private Properties
        private static SortedList Constraints
        {
            get
            {
                if (HttpRuntime.Cache[CacheKeys.SqlConstraints] != null)
                {
                    return (SortedList)HttpRuntime.Cache[CacheKeys.SqlConstraints];
                }
                else
                {
                    SortedList x = CreateConstraintList();
                    CacheKeys.Insert(CacheKeys.SqlConstraints, x, new TimeSpan(1,0,0));
                    return x;
                }
            }
        }
        #endregion

        #region Private Methods
        private static SortedList CreateConstraintList()
        {
            SortedList x = new SortedList(100);
            string serialNo = "Serial numbers may only contain alphanumerics, periods, hyphens, dollar signs, pluses, and square brackets.";
            // Check constraints
            x.Add("chkAccount$AccountName", "Account names may not contain pipes, ampersands, questions marks, percent signs, asterisks, or carets.");
            x.Add("chkAccount$Address1", "Address1 is a required field.");
            x.Add("chkAccount$City", "City is a required field.");
            x.Add("chkAccount$Contact", "Contact names may consist only of alphanumerics and commas.");
            x.Add("chkAccount$Country", "Country is a required field.");
            x.Add("chkAccount$Email", "Email address is invalid.");
            x.Add("chkBarCodePattern$Pattern", "Bar code formats may only consist of alphanumerics, square brackets, braces, commas, and hyphens.");
            x.Add("chkBarCodePattern$Position", "Bar code format position must be greater than zero.");
            x.Add("chkBarCodePatternCase$Pattern", "Case formats may only consist of alphanumerics, square brackets, braces, commas, and hyphens.");
            x.Add("chkBarCodePatternCase$Position", "Case format position must be greater than zero.");
            x.Add("chkDatabaseVersion$Major", "Database version major number must be greater than or equal to 1.");
            x.Add("chkDatabaseVersion$Minor", "Database version minor number must be greater than or equal to 0.");
            x.Add("chkDisasterCode$Code", "Disaster recovery codes may only consist of alphanumerics.");
            x.Add("chkDisasterCodeList$ListName", "Invalid disaster recovery list name.");
            x.Add("chkDisasterCodeList$Status", "Invalid disaster recovery list status value.");
            x.Add("chkDisasterCodeListItem$Code", "Disaster recovery codes may only consist of alphanumerics.");
            x.Add("chkDisasterCodeListItem$Status", "Invalid disaster recovery list item status value.");
            x.Add("chkEmailGroup$GroupName", "Email group name is a required field and may not contain percent signs, asterisks, question marks, pipes, ampersands, or carets.");
            x.Add("chkEmailServer$FromAddress", "Email address is invalid.");
            x.Add("chkFtpProfile$FileFormat", "Invalid ftp file format.");
            x.Add("chkFtpProfile$FilePath", "File path is a required field.");
            x.Add("chkFtpProfile$Login", "Login is a required field.");
            x.Add("chkFtpProfile$Name", "Profile name is a required field and may not contain percent signs, asterisks, question marks, pipes, ampersands, or carets.");
            x.Add("chkFtpProfile$Server", "Server is a required field.");
            x.Add("chkIgnoredBarCodePattern$Pattern", "Bar code formats may only consist of alphanumerics, square brackets, braces, commas, and hyphens.");
            x.Add("chkMedium$BSide", serialNo.Replace("Serial numbers", "B-sides"));
            x.Add("chkMedium$Location", "Media at the enterprise may not be designated as hot and may not have return dates.");
            x.Add("chkMedium$SerialNo", serialNo);
            x.Add("chkMediumType$Name", "Type name is a required field.");
            x.Add("chkMediumType$TypeCode", "Type code may only consist of alphanumerics.");
            x.Add("chkNextListNumber$ListType", "Invalid next list number type.");
            x.Add("chkNextListNumber$Numeral", "Next list number must be greater than zero.");
            x.Add("chkOperator$Admin", "Operator with key = 1 must be an administrator.");
            x.Add("chkOperator$Email", "Email address is invalid.");
            x.Add("chkOperator$Login", "Login is a required field and and may not contain percent signs, asterisks, question marks, pipes, ampersands, carets, or exclamation points.");
            x.Add("chkOperator$Name", "Operator name may not contain percent signs, asterisks, question marks, pipes, ampersands, carets, or exclamation points.");
            x.Add("chkOperator$Role", "Invalid role value.");
            x.Add("chkOperator$System", "Login reserved by system.");
            x.Add("chkReceiveList$ListName", "Invalid receiving list name.");
            x.Add("chkReceiveList$Status", "Invalid receiving list status value.");
            x.Add("chkReceiveListItem$Status", "Invalid receiving list item status value.");
            x.Add("chkReceiveListScan$Name", "Compare file names may not contain percent signs, ampersands, question marks, asterisks, or carets.");
            x.Add("chkReceiveListScanItem$SerialNo", serialNo);
            x.Add("chkSealedCase$SerialNo", serialNo.Replace("Serial numbers", "Sealed case serial numbers"));
            x.Add("chkSendList$ListName", "Invalid shipping list name.");
            x.Add("chkSendList$ListName$Format", "Invalid shipping list name.");
            x.Add("chkSendList$Status", "Invalid shipping list status value.");
            x.Add("chkSendListCase$SerialNo", serialNo);
            x.Add("chkSendListItem$Status", "Invalid shipping list item status value.");
            x.Add("chkSendListScan$Name", "Compare file names may not contain percent signs, ampersands, question marks, asterisks, or carets.");
            x.Add("chkSendListScanItem$CaseName", serialNo.Replace("Serial numbers", "Compare file case serial numbers"));
            x.Add("chkSendListScanItem$SerialNo", serialNo);
            x.Add("chkVaultDiscrepancyAccount$SerialNo", serialNo.Replace("Serial numbers", "Account discrepancy serial numbers"));
            x.Add("chkVaultDiscrepancyCaseType$SerialNo", serialNo.Replace("Serial numbers", "Case type discrepancy serial numbers"));
            x.Add("chkVaultDiscrepancyMediumType$SerialNo", serialNo.Replace("Serial numbers", "Medium type discrepancy serial numbers"));
            x.Add("chkVaultDiscrepancyResidency$SerialNo", serialNo.Replace("Serial numbers", "Residency discrepancy serial numbers"));
            x.Add("chkVaultDiscrepancyUnknownCase$SerialNo", serialNo.Replace("Serial numbers", "Unknown case serial numbers"));
            x.Add("chkVaultInventoryItem$ReturnDate", "Return date is in an invalid format.");
            x.Add("chkVaultInventoryItem$SerialNo", serialNo.Replace("Serial numbers", "Vault inventory item serial numbers"));
            x.Add("chkXCategoryExpiration$Category", "Audit trail category value is invalid.");
            x.Add("chkXCategoryExpiration$Days", "Expiration days must be greater than or equal to zero.");
            // Unique constraints
            x.Add("akAccount$AccountName", "An account with that name already exists in system.");
            x.Add("akBarCodePattern$Pattern", "Bar code format already exists.");
            x.Add("akBarCodePattern$Position", "Bar code format positions must be unique.");
            x.Add("akBarCodePatternCase$Pattern", "Case format already exists.");
            x.Add("akBarCodePatternCase$Position", "Case format positions must be unique.");
            x.Add("akDatabaseVersion$Version", "Database version number already exists in system.");
            x.Add("akDisasterCode$Code", "Disaster recovery code already exists in system.");
            x.Add("akDisasterCodeCase$Case", "Disaster recovery code already attached to sealed case.");
            x.Add("akDisasterCodeList$ListName", "Disaster recovery list name already exists in system.");
            x.Add("akDisasterCodeMedium$Medium", "Disaster recovery code already attached to medium.");
            x.Add("akEmailGroup$Name", "An email group with that name already exists in system.");
            x.Add("akExternalSiteLocation$SiteName", "There may only be one map per site name.");
            x.Add("akFtpProfile$ProfileName", "An ftp profile with that name already exists in system.");
            x.Add("akIgnoredBarCodePattern$String", "Formats of bar codes to be ignored must be unique.");
            x.Add("akMedium$SerialNo", "Serial number already exists in system.");
            x.Add("akOperator$Login", "Login already belongs to another user.");
            x.Add("akReceiveList$ListName", "Receiving list name already exists in system.");
            x.Add("akReceiveListItem$ListMedium", "Medium already exists on list.");
            x.Add("akReceiveListScan$Name", "A compare file with that name already exists.");
            x.Add("akReceiveListScanItem$SerialNo", "Serial number already appears in compare file.");
            x.Add("akSealedCase$SerialNo", "Sealed case name already exists in system.");
            x.Add("akSendList$ListName", "Shipping list name already exists in system.");
            x.Add("akSendListItem$ListMedium", "Medium already exists on list.");
            x.Add("akSendListScan$Name", "A compare file with that name already exists.");
            x.Add("akSendListScanItem$SerialNo", "Serial number already appears in compare file.");
            x.Add("akVaultDiscrepancyAccount$Medium", "Account discrepancy for medium already exists.");
            x.Add("akVaultDiscrepancyCaseType$Case", "Case type discrepancy for sealed case already exists.");
            x.Add("akVaultDiscrepancyMediumType$Medium", "Medium type discrepancy for medium already exists.");
            x.Add("akVaultDiscrepancyResidency$Medium", "Residency discrepancy for medium already exists.");
            x.Add("akVaultDiscrepancyUnknownCase$SerialNo", "Unknown case discrepancy for case already exists.");
            // Return the list
            return x;
        }
        #endregion

        #region Public Methods
        public static string Substitute(string m)
        {
            // If the key appears in the message, substitute the message
            foreach (string key in Constraints.Keys)
                if (m.IndexOf(key) != -1)
                    return (string)Constraints[key];
            // Otherwise return the original message
            return m;
        }
        #endregion
    }
}
