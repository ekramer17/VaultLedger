using System;

namespace Bandl.Library.VaultLedger.Model
{
	/// <summary>
	/// Summary description for MediumRange.
	/// </summary>
    [Serializable]
    public class MediumRange
	{
        private string serialStart;
        private string serialEnd;
        private string mediumType;
        private string accountName;

        public MediumRange() {}

        public MediumRange(string _serialStart, string _serialEnd, string _mediumType, string _accountName) 
        {
            serialStart = _serialStart;
            serialEnd = _serialEnd;
            mediumType = _mediumType;
            accountName = _accountName;
        }

        public string SerialStart
        {
            get
            {
                return serialStart;
            }
            set
            {
                serialStart = value;
            }
        }

        public string SerialEnd
        {
            get
            {
                return serialEnd;
            }
            set
            {
                serialEnd = value;
            }
        }

        public string MediumType
        {
            get
            {
                return mediumType;
            }
            set
            {
                mediumType = value;
            }
        }

        public string AccountName
        {
            get
            {
                return accountName;
            }
            set
            {
                accountName = value;
            }
        }
    }
}
