using System;
using System.Data;
using Bandl.Library.VaultLedger.Exceptions;

namespace Bandl.Library.VaultLedger.Model
{
	/// <summary>
	/// Summary description for ListPurgeDetails.
	/// </summary>
    [Serializable]
    public class ListPurgeDetails : Details
	{
        int days;
        bool archive;
        ListTypes listType;
        private byte[] rowVersion = new byte[8];
        
        public ListPurgeDetails(IDataReader r) 
        {
            listType = (ListTypes)Enum.ToObject(typeof(ListTypes), r.GetInt32(0));
            archive = r.GetBoolean(1);
            days = r.GetInt32(2);
            r.GetBytes(3,0,rowVersion,0,8);
            this.ObjState = ObjectStates.Unmodified;
        }

        public ListTypes ListType
        {
            get {return listType;}
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
