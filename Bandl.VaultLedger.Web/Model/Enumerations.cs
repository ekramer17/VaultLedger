using System;

namespace Bandl.Library.VaultLedger.Model
{
    [Serializable]
    public enum Locations {Vault = 0, Enterprise = 1};

    [Flags]
    public enum ListTypes {Send = 1, Receive = 2, DisasterCode = 4}

    [Serializable]
    public enum ParserTypes {Movement = 0, Disaster, Inventory}

    [Serializable]
    public enum SerialEditFormatTypes {None = 0, UpperOnly, RecallStandard}

    [Serializable]
    public enum InventoryConflictSorts {SerialNo = 1, RecordedDate, ConflictType}

    [Flags]
    [Serializable]
    public enum InventoryConflictTypes {Location = 1, ObjectType = 2, UnknownSerial = 4, Account = 8}

    [Serializable]
    public enum MediumSorts {Serial = 1, Location, ReturnDate, Missing, LastMoveDate, Account, MediumType, CaseName, Notes}

    [Serializable]
    public enum LicenseTypes {Operators = 1, Media, Days, Bandl, Recall, Failure, RFID, Autoloader}

    [Serializable]
    public enum TabPageDefaults {TodaysList = 1, NewSendList, SendReconcileMethod, SendReconcileNewFile, NewReceiveList, ReceiveReconcileMethod, ReceiveReconcileNewFile, NewDisasterCodeList, InventoryFile, ReportCategory, ListPreferences}

    #region Disaster Code List Enumerations
    [Flags]
    public enum DLStatus {None = 0, Submitted = 2, Xmitted = 4, Processed = 512, AllValues = 518}

    [Flags]
    public enum DLIStatus {Removed = 1, Submitted = 2, Xmitted = 4, Processed = 512, AllValues = 519}

    [Serializable]
    public enum DLSorts {ListName = 1, CreateDate, Status, Account}

    [Serializable]
    public enum DLISorts {SerialNo = 1, Account, Code}
    #endregion

    #region Receive List Enumerations
    [Flags]
    public enum RLStatus
    {
        None = 0,
        Submitted = 2,
        Xmitted = 4,
        PartiallyVerifiedI = 8,
        FullyVerifiedI = 16,
        Transit = 32,
        Arrived = 64,
        PartiallyVerifiedII = 128,
        FullyVerifiedII = 256,
        Processed = 512,
        AllValues = 1022
    }

    [Flags]
    public enum RLIStatus
    {
        Removed = 1,
        Submitted = 2,
        Xmitted = 4,
        VerifiedI = 16,
        Transit = 32,
        Arrived = 64,
        VerifiedII = 256,
        Processed = 512,
        AllValues = 887
    }

    [Serializable]
    public enum RLSorts {ListName = 1, CreateDate, Status, Account}

    [Serializable]
    public enum RLISorts {SerialNo = 1, Account, Status, CaseName}
    #endregion

    #region Send List Enumerations
    [Flags]
    public enum SLStatus
    {
        None = 0,
        Submitted = 2,
        PartiallyVerifiedI = 4,
        FullyVerifiedI = 8,
        Xmitted = 16,
        Transit = 32,
        Arrived = 64,
        PartiallyVerifiedII = 128,
        FullyVerifiedII = 256,
        Processed = 512,
        AllValues = 1022
    }

    [Flags]
    public enum SLIStatus
    {
        Removed = 1,
        Submitted = 2,
        VerifiedI = 8,
        Xmitted = 16,
        Transit = 32,
        Arrived = 64,
        VerifiedII = 256,
        Processed = 512,
        AllValues = 891
    }

    [Serializable]
    public enum SLSorts {ListName = 1, CreateDate, Status, Account}

    [Serializable]
    public enum SLISorts {SerialNo = 1, Account, ReturnDate, Status, CaseName}
    #endregion

    [Serializable]
    public enum PreferenceKeys
    {
        TmsReturnDates = 1,
        TmsUnknownSite = 2,
        TmsDataSetNotes = 3,
        SendListCaseVerify = 4,
        EmploySerialEditFormat = 5,
        InventoryExcludeActiveLists = 6,
        InventoryExcludeTodaysLists = 7,
        DeclareListAccounts = 8,
        NumberOfItemsPerPage = 9,
        DateDisplayFormat = 10,
        TimeDisplayFormat = 11,
        AllowOneClickVerify = 12,
        AllowAddsOnReconcile = 13,
        AllowTMSAccountAssigns = 14,
        ExportWithTabDelimiters = 15,
        MaxRfidSerialLength = 16,
		ReceiveListAdminOnly = 17,
        DissolveCompositeOnClear = 18,
        DisplayNotesOnManifests = 19,
        TmsSkipTapesNotResident = 20,
        DestroyTapesAdminOnly = 21,
        AllowAddsOnTMSListCreation = 22,
        AllowDynamicListReplacement = 23,
        CreateTapesAdminOnly = 24,
        AssignAccountsOnReceiveListClear = 25
    }

    [Flags]
    public enum AuditTypes
    {
        Account = 1,
        SystemAction = 2,
        BarCodePattern = 4,
        ExternalSite = 8,
        IgnoredBarCodePattern = 16,
        Operator = 32,
        SendList = 64,
        ReceiveList = 128,
        DisasterCodeList = 256,
        Inventory = 512,
        InventoryConflict = 1024,
        SealedCase = 2048,
        Medium = 4096,
        MediumMovement = 8192,  // Mutually exclusive with Medium, but non-fatal if rule broken
        GeneralAction = 16384,
        AllValues = Account | BarCodePattern | SealedCase | Medium | ExternalSite | IgnoredBarCodePattern | Operator | Inventory | InventoryConflict | SendList | ReceiveList | DisasterCodeList | SystemAction | GeneralAction
    }

    [Serializable]
    public enum PrintSources
    {
        AccountsPage = 1,
        AccountDetailPage,
        BarCodeMediumPage,
        BarCodeCasePage,
        ExternalSitePage,
        UserSecurityPage,
        UserDetailPage,
        DisasterCodeListsPage,
        DisasterCodeListDetailPage,
        ReceiveListsPage,
        ReceiveListDetailPage,
        SendListsPage,
        SendListDetailPage,
        FindMediaPage,
        MediumDetailPage,
        InventoryReconcilePage,
        SendListsReport,
        ReceiveListsReport,
        DisasterCodeListsReport,
        BarCodeMediumReport,
        BarCodeCaseReport,
        ExternalSiteReport,
        FindMediaReport,
        UserSecurityReport,
        AccountsReport,
        AuditorReportMedium,
        AuditorReportSendList,
        AuditorReportSystemAction,
        AuditorReportAccount,
        AuditorReportMediumMovement,
        AuditorReportReceiveList,
        AuditorReportBarCodePattern,
        AuditorReportSealedCase,
        AuditorReportDisasterCodeList,
        AuditorReportExternalSite,
        AuditorReportInventory,
        AuditorReportOperator,
        AuditorReportInventoryConflict,
        AuditorReportAllValues
    }

    [Serializable]
    public enum RequestTypes 
    {
        AuditTrailPrune, 
        InventoryReconcile, 
        PrintDLBrowse, 
        PrintDLDetail, 
        PrintRLBrowse, 
        PrintRLDetail, 
        PrintSLBrowse, 
        PrintSLDetail, 
        PrintFindMedia, 
        PrintMediumDetail, 
        PrintInventory, 
        PrintDLReport, 
        PrintRLReport, 
        PrintSLReport, 
        PrintMediumReport, 
        PrintAuditReport, 
        PrintOtherReport
    }

    [Serializable]
    public enum Vendors
    {
        Recall = 1,
        IronMountain = 2,
        VytalRecords = 3,
        DataSafe = 4
    }
}
