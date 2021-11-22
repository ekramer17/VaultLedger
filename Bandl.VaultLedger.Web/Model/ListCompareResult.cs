using System;
using System.Collections;

namespace Bandl.Library.VaultLedger.Model
{
	/// <summary>
	/// This object holds the results of the comparison of a list (send or 
	/// receive) against one or more scan files of the proper type.
	/// </summary>
    [Serializable]
    public class ListCompareResult
	{

        // Fields for main class
        protected string listName;
        protected string[] scanNames;
        protected string[] listNotScan = new string[0];
        protected string[] scanNotList = new string[0];

        // Constructor
		public ListCompareResult(string _listName, params string[] _scanNames)
		{
            listName = _listName;
            scanNames = _scanNames;
		}

        // Properties
        public string ListName
        {
            get {return listName;}
        }
        public string[] ScanNames
        {
            get {return (string[])new ArrayList(scanNames).ToArray(typeof(string));}
        }
        public string[] ListNotScan
        {
            get {return (string[])new ArrayList(listNotScan).ToArray(typeof(string));}
            set {listNotScan = value;}
        }
        public string[] ScanNotList
        {
            get {return (string[])new ArrayList(scanNotList).ToArray(typeof(string));}
            set {scanNotList = value;}
        }
	}
}
