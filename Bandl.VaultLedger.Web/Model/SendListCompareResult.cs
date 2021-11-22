using System;
using System.Collections;

namespace Bandl.Library.VaultLedger.Model
{
	/// <summary>
	/// Summary description for SendListCompareResult.
	/// </summary>
    [Serializable]
    public class SendListCompareResult : ListCompareResult
	{
        // Embedded class for case disparities
        [Serializable]
        public class CaseDisparity
        {
            private string serialNo;
            private string listCase;
            private string scanCase;
            public string SerialNo
            {
                get {return serialNo;}
            }
            public string ListCase
            {
                get {return listCase;}
                set {listCase = value;}
            }
            public string ScanCase
            {
                get {return scanCase;}
                set {scanCase = value;}
            }
            public CaseDisparity(string _serialNo, string _listCase, string _scanCase)
            {
                serialNo = _serialNo;
                listCase = _listCase;
                scanCase = _scanCase;
            }
        }

        private CaseDisparity[] caseDifferences = new CaseDisparity[0];

        public SendListCompareResult(string _listName, params string[] _scanNames) : base(_listName,_scanNames) {}

        public CaseDisparity[] CaseDifferences
        {
            get {return (CaseDisparity[])new ArrayList(caseDifferences).ToArray(typeof(CaseDisparity));}
            set {caseDifferences = value;}
        }
	}
}
