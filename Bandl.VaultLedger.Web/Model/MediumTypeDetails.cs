using System;
using System.Data;
using System.Text.RegularExpressions;
using Bandl.Library.VaultLedger.Exceptions;

namespace Bandl.Library.VaultLedger.Model
{
    /// <summary>
    /// Business entity used to model a medium type
    /// </summary>
    [Serializable]
    public class MediumTypeDetails : Details
    {

        // Internal member variables
        private int id;
        private string name;
        private bool twoSided;
        private bool container;
        private string recallCode;
        private byte[] rowVersion = new byte[8];
        
        /// <summary>
        /// Constructor initializes new medium type manually
        /// </summary>
        public MediumTypeDetails(string _name, bool _twoSided, bool _container) : this(_name,_twoSided,_container,String.Empty) {}
        /// <summary>
        /// Constructor initializes new medium type manually
        /// </summary>
        public MediumTypeDetails(string _name, bool _twoSided, bool _container, string _recallCode)
        {
            Name = _name;
            TwoSided = _twoSided;
            Container = _container;
            RecallCode = _recallCode;
            // Mark the object as newly created
            this.ObjState = ObjectStates.New;
        }
        /// <summary>
        /// Constructor initializes new operator using the data in a IDataReader
        /// </summary>
        public MediumTypeDetails(IDataReader reader)
        {
            // Get the data from the current row
            id = reader.GetInt32(reader.GetOrdinal("TypeId"));
            name = reader.GetString(reader.GetOrdinal("TypeName"));
            twoSided = reader.GetBoolean(reader.GetOrdinal("TwoSided"));
            container = reader.GetBoolean(reader.GetOrdinal("Container"));
            recallCode = reader.GetString(reader.GetOrdinal("Code"));
            reader.GetBytes(reader.GetOrdinal("RowVersion"),0,rowVersion,0,8);
            // Set row state to unmodified and close the reader
            this.ObjState = ObjectStates.Unmodified;
        }

        // Properties
        public int Id
        {
            get { return id; }
        }
        public string Name
        {
            get { return name; }
            set 
            { 
                if (null == value || 0 == value.Length)
                    throw new ValueRequiredException("Name", "Medium type name is a required field.");
                else if (value.Length > 256 )
                    throw new ValueLengthException("Name", "Name of medium type may not be more than 128 characters in length.");
                // Set account name
                name = value;
                // Set object state to modified
                this.ObjState = ObjectStates.Modified;
            }
        }
        public bool TwoSided
        {
            get { return twoSided; }
            set 
            { 
                twoSided = value; 
                this.ObjState = ObjectStates.Modified;
            }
        }
        public bool Container
        {
            get { return container; }
            set 
            { 
                container = value; 
                this.ObjState = ObjectStates.Modified;
            }
        }
        public string RecallCode
        {
            get { return recallCode; }
            set 
            { 
                switch (Configurator.ProductType)
                {
                    case "RECALL":
                        if (null == value)
                            throw new ValueNullException("RecallCode", "Recall code cannot be null.");
                        else if (false == new Regex(@"[A-Z]*").IsMatch(value))
                            throw new ValueFormatException("RecallCode", "Recall code may only consist of uppercase characters.");
                        break;
                    case "B&L":
                    case "BANDL":
                    case "IMATION":
                    default:
                        if (null == value)
                            value = String.Empty;
                        else if (false == new Regex(@"[a-zA-Z0-9]*").IsMatch(value))
                            throw new ValueFormatException("RecallCode", "Medium type xmit code may only consist of alphanumerics.");
                        break;
                }
                // Set the recall code
                recallCode = value.Trim();
                // Set the object to modified
                this.ObjState = ObjectStates.Modified;
            }
        }
        public byte[] RowVersion
        {
            get { return rowVersion; }
        }
    }
}
