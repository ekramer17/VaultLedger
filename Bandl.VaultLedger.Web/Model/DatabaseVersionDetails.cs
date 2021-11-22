using System;
using System.Data;
using Bandl.Library.VaultLedger.Exceptions;

namespace Bandl.Library.VaultLedger.Model
{
	/// <summary>
	/// Summary description for DatabaseVersion.
	/// </summary>
    [Serializable]
    public class DatabaseVersionDetails
    {
        private int major;
        private int minor;
        private int revision;

        /// <summary>
        /// Constructor initializes new operator manually
        /// </summary>
        public DatabaseVersionDetails(int _major, int _minor, int _revision)
        {
            if (_major < 1)
                throw new ValueException("_major", "Major must be greater than or equal to one.");
            else if (_minor < 0)
                throw new ValueException("_minor", "Minor must be greater than or equal to zero.");
            else if (_revision < 0)
                throw new ValueException("_revision", "Revision must be greater than or equal to zero.");
            // Populate fields
            major = _major;
            minor = _minor;
            revision = _revision;
        }

        /// <summary>
        /// Constructor initializes new operator using the data in a IDataReader
        /// </summary>
        public DatabaseVersionDetails(IDataReader reader)
        {
            // Get the data from the current row
            major = reader.GetInt32(reader.GetOrdinal("Major"));
            minor = reader.GetInt32(reader.GetOrdinal("Minor"));
            revision = reader.GetInt32(reader.GetOrdinal("Revision"));
        }

        public int Major
        {
            get {return major;}
        }
        public int Minor
        {
            get {return minor;}
        }
        public int Revision
        {
            get {return revision;}
        }
        public string String
        {
            get {return String.Format("{0}.{1}.{2}", Major, Minor, Revision);}
        }
    }
}
