using System;
using System.Data;

namespace Bandl.Library.VaultLedger.Model
{
	/// <summary>
	/// Summary description for AuditTrailDetails.
	/// </summary>
    [Serializable]
    public class AuditTrailDetails
	{
        AuditTypes auditType;
        private DateTime recordDate;
        private string objectName;
        private int action;
        private string detail;
        private string login;

        public AuditTrailDetails() {}

        /// <summary>
        /// Constructor initializes new audit details object using the data 
        /// in an object with IDataReader interface
        /// </summary>
        public AuditTrailDetails(IDataReader reader)
        {
            recordDate = reader.GetDateTime(1);
            objectName = reader.GetString(2);
            action = reader.GetInt32(3);
            detail = reader.GetString(4);
            login = reader.GetString(5);
            auditType = (AuditTypes)Enum.ToObject(typeof(AuditTypes), reader.GetInt32(6));
        }

        public DateTime RecordDate
        {
            get {return recordDate;}
        }

        public string ObjectName
        {
            get {return objectName;}
        }

        public string Detail
        {
            get {return detail;}
        }

        public string Login
        {
            get {return login;}
        }

        public AuditTypes AuditType
        {
            get {return auditType;}
        }
    }
}
