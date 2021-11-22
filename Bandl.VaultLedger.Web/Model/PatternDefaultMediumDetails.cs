using System;
using System.Data;
using Bandl.Library.VaultLedger.Exceptions;

namespace Bandl.Library.VaultLedger.Model
{
    /// <summary>
    /// Summary description for PatternDefaultMediumDetails.
    /// </summary>
    [Serializable]
    public class PatternDefaultMediumDetails : PatternDetails
    {
        // Internal member variables
        private string notes;
        private string account;
        private string mediumType;
        
        /// <summary>
        /// Constructor initializes new bar code pattern for medium manually
        /// </summary>
        public PatternDefaultMediumDetails(string _pattern, string _account, string _mediumType, string _notes)
        {
            MediumType = _mediumType;
            Pattern = _pattern;
            Account = _account;
            Notes = _notes;
        }

        /// <summary>
        /// Constructor initializes new external site using the 
        /// data in a IDataReader
        /// </summary>
        public PatternDefaultMediumDetails(IDataReader reader)
        {
            // Get the data from the current row
            pattern = reader.GetString(reader.GetOrdinal("Pattern"));
            notes = reader.GetString(reader.GetOrdinal("Notes"));
            account = reader.GetString(reader.GetOrdinal("AccountName"));
            mediumType = reader.GetString(reader.GetOrdinal("TypeName"));
        }

        // Properties
        public string Account
        {
            get {return account;}
            set 
            {
                if (null == value || 0 == value.Length)
                    throw new ValueRequiredException("Account", "Account name is a required field.");
                else if (value.Length > 256 )
                    throw new ValueLengthException("Account", "Account name may not be more than 256 characters in length.");
                // Set account name
                account = value;
            }
        }
        public string MediumType
        {
            get {return mediumType;}
            set 
            {
                if (null == value || 0 == value.Length)
                    throw new ValueRequiredException("MediumType", "Medium type is a required field.");
                else if (value.Length > 128)
                    throw new ValueLengthException("MediumType", "Medium type may not be more than 128 characters in length.");
                // Set medium type
                mediumType = value;
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
            }
        }
    }
}
