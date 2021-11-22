using System;
using System.Data;
using Bandl.Library.VaultLedger.Exceptions;


namespace Bandl.Library.VaultLedger.Model
{
    /// <summary>
    /// Summary description for PatternIgnoreDetails.
    /// </summary>
    [Serializable]
    public class PatternIgnoreDetails : PatternDetails
    {
        [Flags]
        public enum Systems : long {CA1 = 1}; // UInt64

        // Internal member variables
        private int id;
        private string notes;
        private Systems systems;
        private byte[] rowVersion = new byte[8];
        
        /// <summary>
        /// Constructor initializes new bar code pattern manually
        /// </summary>
        public PatternIgnoreDetails(string _pattern, Systems _systems, string _notes)
        {
            Pattern = _pattern;
            ExternalSystems = _systems;
            Notes = _notes;
            // Mark the object as newly created
            this.ObjState = ObjectStates.New;
        }

        /// <summary>
        /// Constructor initializes new external site using the 
        /// data in a IDataReader
        /// </summary>
        public PatternIgnoreDetails(IDataReader reader)
        {
            byte[] systemBytes = new byte[8];
            // Get the data from the current row
            id = reader.GetInt32(reader.GetOrdinal("Id"));
            pattern = reader.GetString(reader.GetOrdinal("Pattern"));
            notes = reader.GetString(reader.GetOrdinal("Notes"));
            reader.GetBytes(reader.GetOrdinal("Systems"),0,systemBytes,0,8);
            reader.GetBytes(reader.GetOrdinal("RowVersion"),0,rowVersion,0,8);
            // Convert the system bytes to enumeration
            systems = (Systems)BitConverter.ToInt64(systemBytes,0);
            // Set row state to unmodified and close the reader
            this.ObjState = ObjectStates.Unmodified;
        }

        // Properties
        public int Id
        {
            get { return id; }
        }
        public Systems ExternalSystems
        {
            get { return systems; }
            set 
            { 
                systems = value; 
                this.ObjState = ObjectStates.Modified;
            }
        }
        public string Notes
        {
            get { return notes; }
            set 
            { 
                if (null == value)
                    value = String.Empty;
                else if (value.Length > 1000)
                    throw new ValueLengthException("Notes", "Notes may not be more than 1000 characters in length.");
                // Set notes
                notes = value; 
                // Set object state to modified
                this.ObjState = ObjectStates.Modified;
            }
        }
        public byte[] RowVersion
        {
            get { return rowVersion; }
        }
    }
}
