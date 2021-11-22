using System;
using System.Data;
using Bandl.Library.VaultLedger.Exceptions;


namespace Bandl.Library.VaultLedger.Model
{
    /// <summary>
    /// Summary description for PatternDefaultCaseDetails.
    /// </summary>
    [Serializable]
    public class PatternDefaultCaseDetails : PatternDetails
    {
        // Internal member variables
        private string notes;
        private string caseType;
        
        /// <summary>
        /// Constructor initializes new bar code pattern for medium manually
        /// </summary>
        public PatternDefaultCaseDetails(string _pattern, string _caseType, string _notes)
        {
            CaseType = _caseType;
            Pattern = _pattern;
            Notes = _notes;
        }

        /// <summary>
        /// Constructor initializes new external site using the 
        /// data in a IDataReader
        /// </summary>
        public PatternDefaultCaseDetails(IDataReader reader)
        {
            // Get the data from the current row
            pattern = reader.GetString(reader.GetOrdinal("Pattern"));
            caseType = reader.GetString(reader.GetOrdinal("TypeName"));
            notes = reader.GetString(reader.GetOrdinal("Notes"));
        }

        // Properties
        public string CaseType
        {
            get {return caseType;}
            set 
            {
                if (null == value || 0 == value.Length)
                    throw new ValueRequiredException("CaseType", "Case type is a required field.");
                else if (value.Length > 128)
                    throw new ValueLengthException("CaseType", "Case type may not be more than 128 characters in length.");
                // Set case type
                caseType = value;
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
