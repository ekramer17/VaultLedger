using System;
using System.IO;
using System.Web;
using System.Text;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.Exceptions;
using Bandl.Library.VaultLedger.Collections;
using Bandl.Library.VaultLedger.DALFactory;
using Bandl.Library.VaultLedger.IDAL;

namespace Bandl.Library.VaultLedger.BLL
{
	/// <summary>
	/// Summary description for AuditTrail.
	/// </summary>
	public class AuditTrail
	{
        private delegate void CleanDelegate();

        /// Returns a collection of audit trail records.  Implements paging.
        /// </summary>
        /// <param name="pageNo">
        /// Page number to retrieve
        /// </param>
        /// <param name="pageSize">
        /// Size of (i.e., number of records on) each page
        /// </param>
        /// <param name="auditTypes">
        /// Types of audit records to retrieve
        /// </param>
        /// <param name="totalRecords">
        /// Returns the total number of records that would be retrieved without page restrictions
        /// </param>
        /// <returns>
        /// Collection of audit trail records
        /// </returns>
        public static AuditTrailCollection GetAuditTrailPage(int pageNo, int pageSize, AuditTypes auditTypes, out int totalRecords) 
        {
            return GetAuditTrailPage(pageNo, pageSize, auditTypes, new DateTime(1900,1,2), new DateTime(2999,1,2), String.Empty, String.Empty, out totalRecords);
        }

        /// <summary>
        /// Returns a collection of audit trail records.  Implements paging.
        /// </summary>
        /// <param name="pageNo">
        /// Page number to retrieve
        /// </param>
        /// <param name="pageSize">
        /// Size of (i.e., number of records on) each page
        /// </param>
        /// <param name="auditTypes">
        /// Types of audit records to retrieve
        /// </param>
        /// <param name="startDate">
        /// Start date of range for audit records to qualify
        /// </param>
        /// <param name="endDate">
        /// End date of range for audit records to qualify
        /// </param>
        /// <param name="totalRecords">
        /// Returns the total number of records that would be retrieved without page restrictions
        /// </param>
        /// <returns>
        /// Collection of audit trail records
        /// </returns>
        public static AuditTrailCollection GetAuditTrailPage(int pageNo, int pageSize, AuditTypes auditTypes, DateTime startDate, DateTime endDate, String obj, String login, out int totalRecords)
        {
            if (pageNo <= 0)
            {
                throw new ArgumentException("Page number must be greater than zero.");
            }
            else if (pageSize <= 0)
            {
                throw new ArgumentException("Page size must be greater than zero.");
            }
            // Manipulate dates
            if (startDate > endDate)
            {
                DateTime tempDate = startDate;
                startDate = endDate;
                endDate = tempDate;
            }
            // Get the page
            return AuditTrailFactory.Create().GetAuditTrailPage(pageNo, pageSize, auditTypes, startDate, endDate, obj, login, out totalRecords);
        }

        /// <summary>
        /// Returns a collection of audit trail records for a particular medium.
        /// </summary>
        /// <param name="serialNo">
        /// Serial number of tape
        /// </param>
        /// <returns>
        /// Collection of audit trail records
        /// </returns>
        public static AuditTrailCollection GetMediumTrail(string serialNo)
        {
            return AuditTrailFactory.Create().GetMediumTrail(serialNo);
        }

        /// <summary>
        /// Archive records
        /// </summary>
        /// <param name="auditType"></param>
        /// <param name="auditRecords"></param>
        private static void ArchiveRecords(AuditTypes auditType, AuditTrailCollection auditRecords)
        {
/*
            if (auditRecords == null || auditRecords.Count == 0)
            {
                return;
            }
            // Get the application directory path
            string filePath = HttpRuntime.AppDomainAppPath;
            if (!filePath.EndsWith(Path.DirectorySeparatorChar.ToString()))
            {
                filePath += Path.DirectorySeparatorChar.ToString();
            }
            // Add the audits subdirectory and verify that it exists
            filePath += "Audits" + Path.DirectorySeparatorChar.ToString();
            if (!Directory.Exists(filePath))
            {
                Directory.CreateDirectory(filePath);
            }
            // Get the path of the file to which we should write
            switch (auditType)
            {
                case AuditTypes.Account:
                    filePath += "Accounts";
                    break;
                case AuditTypes.BarCodePattern:
                    filePath += "BarCodePatterns";
                    break;
                case AuditTypes.DisasterCodeList:
                    filePath += "DisasterCodeLists";
                    break;
                case AuditTypes.ExternalSite:
                    filePath += "ExternalSiteMaps";
                    break;
                case AuditTypes.IgnoredBarCodePattern:
                    filePath += "TmsIgnorePatterns";
                    break;
                case AuditTypes.Medium:
                    filePath += "Media";
                    break;
                case AuditTypes.MediumMovement:
                    filePath += "Movements";
                    break;
                case AuditTypes.Operator:
                    filePath += "Operators";
                    break;
                case AuditTypes.ReceiveList:
                    filePath += "ReceiveLists";
                    break;
                case AuditTypes.SealedCase:
                    filePath += "SealedCases";
                    break;
                case AuditTypes.SendList:
                    filePath += "ShipLists";
                    break;
                case AuditTypes.SystemAction:
                    filePath += "General";
                    break;
                case AuditTypes.VaultDiscrepancy:
                    filePath += "VaultDiscrepancies";
                    break;
                case AuditTypes.VaultInventory:
                    filePath += "VaultInventories";
                    break;
                default:
                    return;
            }
            // If the directory does not exist, create it
            if (!filePath.EndsWith(Path.DirectorySeparatorChar.ToString()))
            {
                filePath += Path.DirectorySeparatorChar.ToString();
            }
            // Add the audits subdirectory and verify that it exists
            if (!Directory.Exists(filePath))
            {
                Directory.CreateDirectory(filePath);
            }
            // Determine the name of the file
            filePath += auditRecords[0].RecordDate.ToString("yyyyMMdd");
            if (File.Exists(filePath))
            {
                for (int i = 1; i < Int32.MaxValue; i++)
                {
                    if (!File.Exists(String.Format("{0}({1})", filePath, i)))
                    {
                        filePath = String.Format("{0}({1})", filePath, i);
                        break;
                    }
                }
            }
            // Write the records to the file
            using (StreamWriter fileWriter = new StreamWriter(filePath))
            {
                foreach (AuditTrailDetails auditRecord in auditRecords)
                {
                    StringBuilder fileLine = new StringBuilder();
                    fileLine.Append(auditRecord.RecordDate.ToString("yyyy-MM-dd HH:mm:ss"));
                    fileLine.Append("\t");
                    fileLine.Append(auditRecord.Login);
                    fileLine.Append("\t");
                    fileLine.Append(auditRecord.ObjectName);
                    fileLine.Append("\t");
                    fileLine.Append(auditRecord.Detail);
                    fileWriter.WriteLine(fileLine.ToString());
                    
                }
            }
*/            
        }

        /// <summary>
        /// Cleans the audit trail
        /// </summary>
        public static void CleanAuditTrail()
        {
            // Get the expirations from the database
            AuditExpirationCollection auditExpirations = GetExpirations();
            // For each of the expirations, retrieve the records.  If that
            // category is to be archived, archive it.  Then delete the
            // records from the database.
            foreach (AuditExpirationDetails e in auditExpirations)
            {
                IAuditTrail dal = AuditTrailFactory.Create();

                try
                {
                    // We don't need local time b/c audit trail records are kept in UTC time.  As
                    // a result, the comparsion will be totally UTC time.
                    DateTime startDate = new DateTime(1900,1,2);
                    DateTime expireDate = Time.UtcToday.AddDays(-e.Days);
                    // Archive if necessary
                    if (e.Archive == true)
                    {
                        int pageNo = 1;
                        int totalRecords = 1;
                        AuditTrailCollection auditRecords = new AuditTrailCollection();
                        // Get all the qualifying records 
                        while (totalRecords > auditRecords.Count)
                            auditRecords.Add(GetAuditTrailPage(pageNo++, 32767, e.AuditType, startDate, expireDate, String.Empty, String.Empty, out totalRecords));
                        // Archive the records
                        ArchiveRecords(e.AuditType, auditRecords);
                    }
                    // Clean the records
                    dal.CleanAuditTrail(e.AuditType, expireDate);
                }
                catch
                {
                    ;
                }
            }
        }

        /// <summary>
        /// Asynchronous method to clean the audit trail
        /// </summary>
        public static void BeginCleanAuditTrail()
        {
            CleanDelegate cleanDelegate = new CleanDelegate(CleanAuditTrail);
            cleanDelegate.BeginInvoke(null, null);
        }

        /// <summary>
        /// Gets the set of audit expirations from the database
        /// </summary>
        /// <returns>
        /// Collection of AuditExpirationDetails objects
        /// </returns>
        public static AuditExpirationCollection GetExpirations()
        {
            return AuditTrailFactory.Create().GetExpirations();
        }

        /// <summary>
        /// Updates the audit trail expirations in the database
        /// </summary>
        /// <param name="c">
        /// Collection of audit expirations
        /// </param>
        public static void UpdateExpirationCollection(ref AuditExpirationCollection expirationCollection)
        {
            if (expirationCollection == null)
            {
                throw new ArgumentNullException("Reference must be set to an instance of an audit trail expiration collection object.");
            }
            else if (expirationCollection.Count == 0)
            {
                throw new ArgumentException("Audit trail expiration collection must contain at least one audit trail expiration object.");
            }
            // Reset the error flag
            expirationCollection.HasErrors = false;
            // Perform the updates
            using (IConnection c = ConnectionFactory.Create().Open())
            {
                // Begin a transaction
                c.BeginTran();
                // Reset the collection error flag
                expirationCollection.HasErrors = false;
                // Create a DAL object
                IAuditTrail dal = AuditTrailFactory.Create(c);
                // Loop through the audit trail expirations
                foreach (AuditExpirationDetails auditExpiration in expirationCollection)
                {
                    if (auditExpiration.ObjState == ObjectStates.Modified)
                    {
                        try
                        {
                            dal.UpdateExpiration(auditExpiration);
                            auditExpiration.RowError = String.Empty;
                        }
                        catch (Exception e)
                        {
                            auditExpiration.RowError = e.Message;
                            expirationCollection.HasErrors = true;
                        }
                    }
                }
                // If the collection has errors, roll back the transaction and
                // throw a collection exception.
                if (expirationCollection.HasErrors)
                {
                    c.RollbackTran();
                    throw new CollectionErrorException(expirationCollection);
                }
                else
                {
                    c.CommitTran();
                    // Get the current exceptions and create an empty collection
                    AuditExpirationCollection currentExpirations = GetExpirations();
                    AuditExpirationCollection returnCollection = new AuditExpirationCollection();
                    // Fill the empty collection with the updated versions of those
                    // expirations that were modified.  Simply add those that were not.
                    foreach (AuditExpirationDetails auditExpiration in currentExpirations)
                    {
                        if (auditExpiration.ObjState != ObjectStates.Modified)
                        {
                            returnCollection.Add(auditExpiration);
                        }
                        else
                        {
                            returnCollection.Add(currentExpirations.Find(auditExpiration.AuditType));
                        }
                    
                    }
                    // Return the updated collection by reference
                    expirationCollection = returnCollection;
                }
            }
        }
    }
}
