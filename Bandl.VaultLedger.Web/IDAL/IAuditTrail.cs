using System;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.Collections;

namespace Bandl.Library.VaultLedger.IDAL
{
	/// <summary>
	/// Summary description for IAuditTrail.
	/// </summary>
    public interface IAuditTrail
    {
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
        /// <param name="totalRecords">
        /// Returns the total number of records that would be retrieved without page restrictions
        /// </param>
        /// <returns>
        /// Collection of audit trail records
        /// </returns>
        AuditTrailCollection GetAuditTrailPage(int pageNo, int pageSize, AuditTypes auditTypes, out int totalRecords);

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
        AuditTrailCollection GetAuditTrailPage(int pageNo, int pageSize, AuditTypes auditTypes, DateTime startDate, DateTime endDate, String obj, String login, out int totalRecords);
            
        /// <summary>
        /// Returns a collection of audit trail records for a particular medium.
        /// </summary>
        /// <param name="serialNo">
        /// Serial number of tape
        /// </param>
        /// <returns>
        /// Collection of audit trail records
        /// </returns>
        AuditTrailCollection GetMediumTrail(string serialNo);
            
        /// <summary>
        /// Cleans the audit trails
        /// </summary>
        void CleanAuditTrail(AuditTypes auditType, DateTime cleanDate);

        /// <summary>
        /// Gets the set of audit expirations from the database
        /// </summary>
        /// <returns>
        /// Collection of AuditExpirationDetails objects</returns>
        AuditExpirationCollection GetExpirations();

        /// <summary>
        /// Updates the audit trail expirations in the database
        /// </summary>
        /// <param name="c">
        /// Collection of audit expirations
        /// </param>
        void UpdateExpiration(AuditExpirationDetails auditExpiration);
    }
}
