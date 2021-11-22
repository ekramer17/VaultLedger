using System;

namespace Bandl.Service.VaultLedger.Bandl.Model
{
    /// <summary>
    /// Summary description for ListAuditDetails.
    /// </summary>
    public class AuditListXmitDetails
    {
        public enum Actions {Send, Receive}
        public enum Status {Failed = 0, Success = 1}

        private Actions actionType;
        private string accountNo;
        private AccountTypes accountType;
        private DateTime actionTime;
        private string listName;
        private int numItems;
        private string fileName;    // Exception if send or if receive but file write was unsuccessful
        private Status result;

        #region Constructors

        public AuditListXmitDetails(Actions _actionType, string _accountNo, AccountTypes _accountType, DateTime _actionTime, string _listName, int _numItems, string _fileName, Status _result)
        {
            actionType = _actionType;
            accountNo = _accountNo;
            accountType = _accountType;
            actionTime = _actionTime;
            listName = _listName;
            numItems = _numItems;
            fileName = _fileName;
            result = _result;
        }

        #endregion

        #region Public Properties

        public Actions ActionType { get {return actionType;} }
        public string AccountNo{ get {return accountNo;} }
        public AccountTypes AccountType{ get {return accountType;} }
        public DateTime ActionTime{ get {return actionTime;} }
        public string ListName{ get {return listName;} }
        public int NumItems{ get {return numItems;} }
        public string FileName{ get {return fileName;} }
        public Status Result { get {return result;} }

        #endregion
	}
}
