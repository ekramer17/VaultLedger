using System;
using System.Text;

namespace Bandl.Library.VaultLedger.Model
{
	/// <summary>
	/// This class holds the information used to filter the search results
	/// when a user is searching for media.
	/// </summary>
    [Serializable]
    public class MediumFilter
    {
        [Flags]
        public enum FilterKeys
        {
            None = 0,
            SerialStart = 1,
            SerialEnd = 2,
            Location = 4,
            ReturnDate = 8,
            Missing = 16,
            Account = 32,
            MediumType = 64,
            CaseName = 128,
            Notes = 256,
            DisasterCode = 512,
            Destroyed = 1024
        }

        private FilterKeys filter = FilterKeys.None;

        // Field values
        private string serialStart;
        private string serialEnd;
        private Locations location;
        private DateTime returnDate;
        private bool missing;
        private string account;
        private string mediumType;
        private string caseName;
        private string notes;
        private string disaster;
        private bool destroyed;

        // Default constructor
        public MediumFilter() {}

        // Field value properties
        public string StartingSerialNo
        {
            get {return serialStart;}
            set 
            {
                serialStart = value;
                filter |= FilterKeys.SerialStart; 
            }
        }
        public string EndingSerialNo
        {
            get {return serialEnd;}
            set 
            {
                serialEnd = value;
                filter |= FilterKeys.SerialEnd; 
            }
        }
        public Locations Location
        {
            get {return location;}
            set 
            {
                location = value;
                filter |= FilterKeys.Location; 
            }
        }
        public DateTime ReturnDate
        {
            get {return returnDate;}
            set 
            {
                returnDate = value;
                filter |= FilterKeys.ReturnDate; 
            }
        }
        public bool Missing
        {
            get {return missing;}
            set 
            {
                missing = value;
                filter |= FilterKeys.Missing; 
            }
        }
        public string Account
        {
            get {return account;}
            set 
            {
                account = value;
                filter |= FilterKeys.Account; 
            }
        }
        public string MediumType
        {
            get {return mediumType;}
            set 
            {
                mediumType = value;
                filter |= FilterKeys.MediumType; 
            }
        }
        public string CaseName
        {
            get {return caseName;}
            set 
            {
                caseName = value;
                filter |= FilterKeys.CaseName; 
            }
        }
        public string Notes
        {
            get {return notes;}
            set 
            {
                notes = value;
                filter |= FilterKeys.Notes; 
            }
        }
        public string DisasterCode
        {
            get {return disaster;}
            set 
            {
                disaster = value;
                filter |= FilterKeys.DisasterCode; 
            }
        }
        public bool Destroyed
        {
            get {return destroyed;}
            set 
            {
                destroyed = value;
                filter |= FilterKeys.Destroyed; 
            }
        }
        public FilterKeys Filter
        {
            get {return filter;}
        }
    }
}
