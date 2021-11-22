using System;
using System.Data;
using Bandl.Library.VaultLedger.Exceptions;

namespace Bandl.Library.VaultLedger.Model
{
	/// <summary>
	/// Summary description for AuditExpirationDetails.
	/// </summary>
    [Serializable]
    public class AuditExpirationDetails : Details
	{
        AuditTypes auditType;
        bool archive;
        int days;
        private byte[] rowVersion = new byte[8];

        public AuditExpirationDetails(IDataReader r) 
        {
            auditType = (AuditTypes)Enum.ToObject(typeof(AuditTypes), r.GetInt32(0));
            archive = r.GetBoolean(1);
            days = r.GetInt32(2);
            r.GetBytes(3,0,rowVersion,0,8);
            this.ObjState = ObjectStates.Unmodified;
        }

        public AuditTypes AuditType
        {
            get {return auditType;}
        }

        public bool Archive
        {
            get {return archive;}
            set 
            {
                archive = value;
                this.ObjState = ObjectStates.Modified;
            }
        }

        public int Days
        {
            get {return days;}
            set
            {
                if (days < 0)
                {
                    throw new ValueException("Days", "Days must be greater than or equal to zero");
                }
                else
                {
                    days = value;
                    this.ObjState = ObjectStates.Modified;
                }
            }
        }

        public byte[] RowVersion
        {
            get {return rowVersion;}
        }
    }
}
