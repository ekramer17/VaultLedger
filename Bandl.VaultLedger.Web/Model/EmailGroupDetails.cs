using System;
using System.Data;
using Bandl.Library.VaultLedger.Exceptions;

namespace Bandl.Library.VaultLedger.Model
{
	/// <summary>
	/// Summary description for EmailGroupDetails.
	/// </summary>
    [Serializable]
    public class EmailGroupDetails : Details
	{
        int id;
        string name;

        #region Constructors
		public EmailGroupDetails(string _name)
		{
            id = 0;
            name = _name;
		}

        public EmailGroupDetails(IDataReader r)
        {
            // Get the data from the current row
            id = r.GetInt32(0);
            name = r.GetString(1);
        }
        #endregion

        #region Public Properties
        public int Id 
        { 
            get
            { 
                return id;
            } 
        }
        
        public string Name 
        { 
            get
            { 
                return name;
            } 
            set
            {
                if (null == value || 0 == value.Length)
                    throw new ValueRequiredException("Name", "Name is a required field.");
                else if (value.Length > 256 )
                    throw new ValueLengthException("Name", "Name may not be more than 256 characters in length.");
                // Set name
                name = value;
                // Set object state to modified
                this.ObjState = ObjectStates.Modified;
            }
        }
        #endregion
	}
}
