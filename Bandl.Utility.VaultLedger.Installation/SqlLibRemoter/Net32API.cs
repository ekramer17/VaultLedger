using System;
using System.IO;
using System.Text;
using System.Diagnostics;
using System.Collections;
using Microsoft.Win32.Security;
using System.Runtime.InteropServices;

namespace Bandl.Utility.VaultLedger.Installation.SqlLibRemoter
{
    class Net32API
    {
        public Net32API () {}

        #region Net Errors
        public enum NetError
        {
            NERR_Success = 0,
            NERR_BASE = 2100,
            NERR_NetNotStarted = NERR_BASE+2,
            NERR_UnknownServer = NERR_BASE+3,
            NERR_ShareMem = NERR_BASE+4,
            NERR_NoNetworkResource = NERR_BASE+5,
            NERR_RemoteOnly = NERR_BASE+6,
            NERR_DevNotRedirected = NERR_BASE+7,
            NERR_ServerNotStarted = NERR_BASE+14,
            NERR_ItemNotFound = NERR_BASE+15,
            NERR_UnknownDevDir = NERR_BASE+16,
            NERR_RedirectedPath = NERR_BASE+17,
            NERR_DuplicateShare = NERR_BASE+18,
            NERR_NoRoom = NERR_BASE+19,
            NERR_TooManyItems = NERR_BASE+21,
            NERR_InvalidMaxUsers = NERR_BASE+22,
            NERR_BufTooSmall = NERR_BASE+23,
            NERR_RemoteErr = NERR_BASE+27,
            NERR_LanmanIniError = NERR_BASE+31,
            NERR_NetworkError = NERR_BASE+36,
            NERR_WkstaInconsistentState = NERR_BASE+37,
            NERR_WkstaNotStarted = NERR_BASE+38,
            NERR_BrowserNotStarted = NERR_BASE+39,
            NERR_InternalError = NERR_BASE+40,
            NERR_BadTransactConfig = NERR_BASE+41,
            NERR_InvalidAPI = NERR_BASE+42,
            NERR_BadEventName = NERR_BASE+43,
            NERR_DupNameReboot = NERR_BASE+44,
            NERR_CfgCompNotFound = NERR_BASE+46,
            NERR_CfgParamNotFound = NERR_BASE+47,
            NERR_LineTooLong = NERR_BASE+49,
            NERR_QNotFound = NERR_BASE+50,
            NERR_JobNotFound = NERR_BASE+51,
            NERR_DestNotFound = NERR_BASE+52,
            NERR_DestExists = NERR_BASE+53,
            NERR_QExists = NERR_BASE+54,
            NERR_QNoRoom = NERR_BASE+55,
            NERR_JobNoRoom = NERR_BASE+56,
            NERR_DestNoRoom = NERR_BASE+57,
            NERR_DestIdle = NERR_BASE+58,
            NERR_DestInvalidOp = NERR_BASE+59,
            NERR_ProcNoRespond = NERR_BASE+60,
            NERR_SpoolerNotLoaded = NERR_BASE+61,
            NERR_DestInvalidState = NERR_BASE+62,
            NERR_QInvalidState = NERR_BASE+63,
            NERR_JobInvalidState = NERR_BASE+64,
            NERR_SpoolNoMemory = NERR_BASE+65,
            NERR_DriverNotFound = NERR_BASE+66,
            NERR_DataTypeInvalid = NERR_BASE+67,
            NERR_ProcNotFound = NERR_BASE+68,
            NERR_ServiceTableLocked = NERR_BASE+80,
            NERR_ServiceTableFull = NERR_BASE+81,
            NERR_ServiceInstalled = NERR_BASE+82,
            NERR_ServiceEntryLocked = NERR_BASE+83,
            NERR_ServiceNotInstalled = NERR_BASE+84,
            NERR_BadServiceName = NERR_BASE+85,
            NERR_ServiceCtlTimeout = NERR_BASE+86,
            NERR_ServiceCtlBusy = NERR_BASE+87,
            NERR_BadServiceProgName = NERR_BASE+88,
            NERR_ServiceNotCtrl = NERR_BASE+89,
            NERR_ServiceKillProc = NERR_BASE+90,
            NERR_ServiceCtlNotValid = NERR_BASE+91,
            NERR_NotInDispatchTbl = NERR_BASE+92,
            NERR_BadControlRecv = NERR_BASE+93,
            NERR_ServiceNotStarting = NERR_BASE+94,
            NERR_AlreadyLoggedOn = NERR_BASE+100,
            NERR_NotLoggedOn = NERR_BASE+101,
            NERR_BadUsername = NERR_BASE+102,
            NERR_BadPassword = NERR_BASE+103,
            NERR_UnableToAddName_W = NERR_BASE+104,
            NERR_UnableToAddName_F = NERR_BASE+105,
            NERR_UnableToDelName_W = NERR_BASE+106,
            NERR_UnableToDelName_F = NERR_BASE+107,
            NERR_LogonsPaused = NERR_BASE+109,
            NERR_LogonServerConflict = NERR_BASE+110,
            NERR_LogonNoUserPath = NERR_BASE+111,
            NERR_LogonScriptError = NERR_BASE+112,
            NERR_StandaloneLogon = NERR_BASE+114,
            NERR_LogonServerNotFound = NERR_BASE+115,
            NERR_LogonDomainExists = NERR_BASE+116,
            NERR_NonValidatedLogon = NERR_BASE+117,
            NERR_ACFNotFound = NERR_BASE+119,
            NERR_GroupNotFound = NERR_BASE+120,
            NERR_UserNotFound = NERR_BASE+121,
            NERR_ResourceNotFound = NERR_BASE+122,
            NERR_GroupExists = NERR_BASE+123,
            NERR_UserExists = NERR_BASE+124,
            NERR_ResourceExists = NERR_BASE+125,
            NERR_NotPrimary = NERR_BASE+126,
            NERR_ACFNotLoaded = NERR_BASE+127,
            NERR_ACFNoRoom = NERR_BASE+128,
            NERR_ACFFileIOFail = NERR_BASE+129,
            NERR_ACFTooManyLists = NERR_BASE+130,
            NERR_UserLogon = NERR_BASE+131,
            NERR_ACFNoParent = NERR_BASE+132,
            NERR_CanNotGrowSegment = NERR_BASE+133,
            NERR_SpeGroupOp = NERR_BASE+134,
            NERR_NotInCache = NERR_BASE+135,
            NERR_UserInGroup = NERR_BASE+136,
            NERR_UserNotInGroup = NERR_BASE+137,
            NERR_AccountUndefined = NERR_BASE+138,
            NERR_AccountExpired = NERR_BASE+139,
            NERR_InvalidWorkstation = NERR_BASE+140,
            NERR_InvalidLogonHours = NERR_BASE+141,
            NERR_PasswordExpired = NERR_BASE+142,
            NERR_PasswordCantChange = NERR_BASE+143,
            NERR_PasswordHistConflict = NERR_BASE+144,
            NERR_PasswordTooShort = NERR_BASE+145,
            NERR_PasswordTooRecent = NERR_BASE+146,
            NERR_InvalidDatabase = NERR_BASE+147,
            NERR_DatabaseUpToDate = NERR_BASE+148,
            NERR_SyncRequired = NERR_BASE+149,
            NERR_UseNotFound = NERR_BASE+150,
            NERR_BadAsgType = NERR_BASE+151,
            NERR_DeviceIsShared = NERR_BASE+152,
            NERR_NoComputerName = NERR_BASE+170,
            NERR_MsgAlreadyStarted = NERR_BASE+171,
            NERR_MsgInitFailed = NERR_BASE+172,
            NERR_NameNotFound = NERR_BASE+173,
            NERR_AlreadyForwarded = NERR_BASE+174,
            NERR_AddForwarded = NERR_BASE+175,
            NERR_AlreadyExists = NERR_BASE+176,
            NERR_TooManyNames = NERR_BASE+177,
            NERR_DelComputerName = NERR_BASE+178,
            NERR_LocalForward = NERR_BASE+179,
            NERR_GrpMsgProcessor = NERR_BASE+180,
            NERR_PausedRemote = NERR_BASE+181,
            NERR_BadReceive = NERR_BASE+182,
            NERR_NameInUse = NERR_BASE+183,
            NERR_MsgNotStarted = NERR_BASE+184,
            NERR_NotLocalName = NERR_BASE+185,
            NERR_NoForwardName = NERR_BASE+186,
            NERR_RemoteFull = NERR_BASE+187,
            NERR_NameNotForwarded = NERR_BASE+188,
            NERR_TruncatedBroadcast = NERR_BASE+189,
            NERR_InvalidDevice = NERR_BASE+194,
            NERR_WriteFault = NERR_BASE+195,
            NERR_DuplicateName = NERR_BASE+197,
            NERR_DeleteLater = NERR_BASE+198,
            NERR_IncompleteDel = NERR_BASE+199,
            NERR_MultipleNets = NERR_BASE+200,
            NERR_NetNameNotFound = NERR_BASE+210,
            NERR_DeviceNotShared = NERR_BASE+211,
            NERR_ClientNameNotFound = NERR_BASE+212,
            NERR_FileIdNotFound = NERR_BASE+214,
            NERR_ExecFailure = NERR_BASE+215,
            NERR_TmpFile = NERR_BASE+216,
            NERR_TooMuchData = NERR_BASE+217,
            NERR_DeviceShareConflict = NERR_BASE+218,
            NERR_BrowserTableIncomplete = NERR_BASE+219,
            NERR_NotLocalDomain = NERR_BASE+220,
            NERR_DevInvalidOpCode = NERR_BASE+231,
            NERR_DevNotFound = NERR_BASE+232,
            NERR_DevNotOpen = NERR_BASE+233,
            NERR_BadQueueDevString = NERR_BASE+234,
            NERR_BadQueuePriority = NERR_BASE+235,
            NERR_NoCommDevs = NERR_BASE+237,
            NERR_QueueNotFound = NERR_BASE+238,
            NERR_BadDevString = NERR_BASE+240,
            NERR_BadDev = NERR_BASE+241,
            NERR_InUseBySpooler = NERR_BASE+242,
            NERR_CommDevInUse = NERR_BASE+243,
            NERR_InvalidComputer = NERR_BASE+251,
            NERR_MaxLenExceeded = NERR_BASE+254,
            NERR_BadComponent = NERR_BASE+256,
            NERR_CantType = NERR_BASE+257,
            NERR_TooManyEntries = NERR_BASE+262,
            NERR_ProfileFileTooBig = NERR_BASE+270,
            NERR_ProfileOffset = NERR_BASE+271,
            NERR_ProfileCleanup = NERR_BASE+272,
            NERR_ProfileUnknownCmd = NERR_BASE+273,
            NERR_ProfileLoadErr = NERR_BASE+274,
            NERR_ProfileSaveErr = NERR_BASE+275,
            NERR_LogOverflow = NERR_BASE+277,
            NERR_LogFileChanged = NERR_BASE+278,
            NERR_LogFileCorrupt = NERR_BASE+279,
            NERR_SourceIsDir = NERR_BASE+280,
            NERR_BadSource = NERR_BASE+281,
            NERR_BadDest = NERR_BASE+282,
            NERR_DifferentServers = NERR_BASE+283,
            NERR_RunSrvPaused = NERR_BASE+285,
            NERR_ErrCommRunSrv = NERR_BASE+289,
            NERR_ErrorExecingGhost = NERR_BASE+291,
            NERR_ShareNotFound = NERR_BASE+292,
            NERR_InvalidLana = NERR_BASE+300,
            NERR_OpenFiles = NERR_BASE+301,
            NERR_ActiveConns = NERR_BASE+302,
            NERR_BadPasswordCore = NERR_BASE+303,
            NERR_DevInUse = NERR_BASE+304,
            NERR_LocalDrive = NERR_BASE+305,
            NERR_AlertExists = NERR_BASE+330,
            NERR_TooManyAlerts = NERR_BASE+331,
            NERR_NoSuchAlert = NERR_BASE+332,
            NERR_BadRecipient = NERR_BASE+333,
            NERR_AcctLimitExceeded = NERR_BASE+334,
            NERR_InvalidLogSeek = NERR_BASE+340,
            NERR_BadUasConfig = NERR_BASE+350,
            NERR_InvalidUASOp = NERR_BASE+351,
            NERR_LastAdmin = NERR_BASE+352,
            NERR_DCNotFound = NERR_BASE+353,
            NERR_LogonTrackingError = NERR_BASE+354,
            NERR_NetlogonNotStarted = NERR_BASE+355,
            NERR_CanNotGrowUASFile = NERR_BASE+356,
            NERR_TimeDiffAtDC = NERR_BASE+357,
            NERR_PasswordMismatch = NERR_BASE+358,
            NERR_NoSuchServer = NERR_BASE+360,
            NERR_NoSuchSession = NERR_BASE+361,
            NERR_NoSuchConnection = NERR_BASE+362,
            NERR_TooManyServers = NERR_BASE+363,
            NERR_TooManySessions = NERR_BASE+364,
            NERR_TooManyConnections = NERR_BASE+365,
            NERR_TooManyFiles = NERR_BASE+366,
            NERR_NoAlternateServers = NERR_BASE+367,
            NERR_TryDownLevel = NERR_BASE+370,
            NERR_UPSDriverNotStarted = NERR_BASE+380,
            NERR_UPSInvalidConfig = NERR_BASE+381,
            NERR_UPSInvalidCommPort = NERR_BASE+382,
            NERR_UPSSignalAsserted = NERR_BASE+383,
            NERR_UPSShutdownFailed = NERR_BASE+384,
            NERR_BadDosRetCode = NERR_BASE+400,
            NERR_ProgNeedsExtraMem = NERR_BASE+401,
            NERR_BadDosFunction = NERR_BASE+402,
            NERR_RemoteBootFailed = NERR_BASE+403,
            NERR_BadFileCheckSum = NERR_BASE+404,
            NERR_NoRplBootSystem = NERR_BASE+405,
            NERR_RplLoadrNetBiosErr = NERR_BASE+406,
            NERR_RplLoadrDiskErr = NERR_BASE+407,
            NERR_ImageParamErr = NERR_BASE+408,
            NERR_TooManyImageParams = NERR_BASE+409,
            NERR_NonDosFloppyUsed = NERR_BASE+410,
            NERR_RplBootRestart = NERR_BASE+411,
            NERR_RplSrvrCallFailed = NERR_BASE+412,
            NERR_CantConnectRplSrvr = NERR_BASE+413,
            NERR_CantOpenImageFile = NERR_BASE+414,
            NERR_CallingRplSrvr = NERR_BASE+415,
            NERR_StartingRplBoot = NERR_BASE+416,
            NERR_RplBootServiceTerm = NERR_BASE+417,
            NERR_RplBootStartFailed = NERR_BASE+418,
            NERR_RPL_CONNECTED = NERR_BASE+419,
            NERR_BrowserConfiguredToNotRun = NERR_BASE+450,
            NERR_RplNoAdaptersStarted = NERR_BASE+510,
            NERR_RplBadRegistry = NERR_BASE+511,
            NERR_RplBadDatabase = NERR_BASE+512,
            NERR_RplRplfilesShare = NERR_BASE+513,
            NERR_RplNotRplServer = NERR_BASE+514,
            NERR_RplCannotEnum = NERR_BASE+515,
            NERR_RplWkstaInfoCorrupted = NERR_BASE+516,
            NERR_RplWkstaNotFound = NERR_BASE+517,
            NERR_RplWkstaNameUnavailable = NERR_BASE+518,
            NERR_RplProfileInfoCorrupted = NERR_BASE+519,
            NERR_RplProfileNotFound = NERR_BASE+520,
            NERR_RplProfileNameUnavailable = NERR_BASE+521,
            NERR_RplProfileNotEmpty = NERR_BASE+522,
            NERR_RplConfigInfoCorrupted = NERR_BASE+523,
            NERR_RplConfigNotFound = NERR_BASE+524,
            NERR_RplAdapterInfoCorrupted = NERR_BASE+525,
            NERR_RplInternal = NERR_BASE+526,
            NERR_RplVendorInfoCorrupted = NERR_BASE+527,
            NERR_RplBootInfoCorrupted = NERR_BASE+528,
            NERR_RplWkstaNeedsUserAcct = NERR_BASE+529,
            NERR_RplNeedsRPLUSERAcct = NERR_BASE+530,
            NERR_RplBootNotFound = NERR_BASE+531,
            NERR_RplIncompatibleProfile = NERR_BASE+532,
            NERR_RplAdapterNameUnavailable = NERR_BASE+533,
            NERR_RplConfigNotEmpty = NERR_BASE+534,
            NERR_RplBootInUse = NERR_BASE+535,
            NERR_RplBackupDatabase = NERR_BASE+536,
            NERR_RplAdapterNotFound = NERR_BASE+537,
            NERR_RplVendorNotFound = NERR_BASE+538,
            NERR_RplVendorNameUnavailable = NERR_BASE+539,
            NERR_RplBootNameUnavailable = NERR_BASE+540,
            NERR_RplConfigNameUnavailable = NERR_BASE+541,
            NERR_DfsInternalCorruption = NERR_BASE+560,
            NERR_DfsVolumeDataCorrupt = NERR_BASE+561,
            NERR_DfsNoSuchVolume = NERR_BASE+562,
            NERR_DfsVolumeAlreadyExists = NERR_BASE+563,
            NERR_DfsAlreadyShared = NERR_BASE+564,
            NERR_DfsNoSuchShare = NERR_BASE+565,
            NERR_DfsNotALeafVolume = NERR_BASE+566,
            NERR_DfsLeafVolume = NERR_BASE+567,
            NERR_DfsVolumeHasMultipleServers = NERR_BASE+568,
            NERR_DfsCantCreateJunctionPoint = NERR_BASE+569,
            NERR_DfsServerNotDfsAware = NERR_BASE+570,
            NERR_DfsBadRenamePath = NERR_BASE+571,
            NERR_DfsVolumeIsOffline = NERR_BASE+572,
            NERR_DfsNoSuchServer = NERR_BASE+573,
            NERR_DfsCyclicalName = NERR_BASE+574,
            NERR_DfsNotSupportedInServerDfs = NERR_BASE+575,
            NERR_DfsDuplicateService = NERR_BASE+576,
            NERR_DfsCantRemoveLastServerShare = NERR_BASE+577,
            NERR_DfsVolumeIsInterDfs  = NERR_BASE+578,
            NERR_DfsInconsistent = NERR_BASE+579,
            NERR_DfsServerUpgraded = NERR_BASE+580,
            NERR_DfsDataIsIdentical = NERR_BASE+581,
            NERR_DfsCantRemoveDfsRoot = NERR_BASE+582,
            NERR_DfsChildOrParentInDfs = NERR_BASE+583,
            NERR_DfsInternalError = NERR_BASE+590
        }
        #endregion

        #region Imported API Functions
        
        [DllImport("Netapi32.dll")]
        public static extern int NetShareAdd([MarshalAs(UnmanagedType.LPWStr)]string serverName, Int32 level, IntPtr shareInfo, IntPtr errParm);

        [DllImport("Netapi32.dll")]
        public static extern int NetShareDel([MarshalAs(UnmanagedType.LPWStr)] string serverName, [MarshalAs(UnmanagedType.LPWStr)] string shareName, Int32 reserved); 
        
        #endregion

        public enum SHARE_TYPE : ulong
        {
            STYPE_DISKTREE = 0,
            STYPE_PRINTQ = 1,
            STYPE_DEVICE = 2,
            STYPE_IPC = 3,
            STYPE_SPECIAL = 0x80000000,
        }

        [StructLayout(LayoutKind.Sequential)]
            public struct SHARE_INFO_502
        {
            [MarshalAs(UnmanagedType.LPWStr)]
            public string shi502_netname;
            public uint shi502_type;
            [MarshalAs(UnmanagedType.LPWStr)]
            public string shi502_remark;
            public Int32 shi502_permissions;
            public Int32 shi502_max_uses;
            public Int32 shi502_current_uses;
            [MarshalAs(UnmanagedType.LPWStr)]
            public string shi502_path;
            public IntPtr shi502_passwd;
            public Int32 shi502_reserved;
            public IntPtr shi502_security_descriptor;
        }

        /// <summary>
        /// Creates a new network share
        /// </summary>
        /// <param name="serverName"></param>
        /// <param name="sharePath"></param>
        /// <param name="shareName"></param>
        /// <param name="description"></param>
        /// <param name="bAdmin"></param>
        /// <returns></returns>
        public void CreateShare(string serverName, string sharePath, string shareName, string description, bool admin)
        {
            // Create share info structure
            SHARE_INFO_502 shInfo = new SHARE_INFO_502();
            shInfo.shi502_netname = shareName;
            shInfo.shi502_type = (uint)SHARE_TYPE.STYPE_DISKTREE;
            if (admin == true)
            {
                shInfo.shi502_type = (uint)SHARE_TYPE.STYPE_SPECIAL;
                shInfo.shi502_netname += "$";
            }
            shInfo.shi502_permissions = 0;
            shInfo.shi502_path = sharePath;
            shInfo.shi502_passwd = IntPtr.Zero;
            shInfo.shi502_remark = description;
            shInfo.shi502_max_uses = -1;
            shInfo.shi502_security_descriptor = IntPtr.Zero;
            // Manipulate the server name if necessary
            serverName = String.Format("{0}{1}", serverName.Length != 0 && serverName[0] != '\\' ? @"\\" : String.Empty, serverName);
            // Call Net API to add the share..
            int nStSize = Marshal.SizeOf(shInfo);
            IntPtr buffer = Marshal.AllocCoTaskMem(nStSize);
            Marshal.StructureToPtr(shInfo, buffer, false);
            NetError errorValue = (NetError)NetShareAdd(serverName, 502, buffer, IntPtr.Zero);
            Marshal.FreeCoTaskMem( buffer );
            // Evaluate result
            switch (errorValue)
            {
                case NetError.NERR_Success:
                case NetError.NERR_DuplicateShare:
                    break;
                default:
                    string s = GetMessageWithException((int)errorValue);
                    throw new ApplicationException("Error encoutered while creating network share for transferring SQL Server binaries.  " + String.Format("{0} [{1}]", s, (int)errorValue));
            }

            // Add security descriptor
            try
            {
                Dacl dacl;
                shareName = String.Format(@"{0}\{1}", serverName, shareName);
                // Create security descriptor
                SecurityDescriptor sd = SecurityDescriptor.GetNamedSecurityInfo(shareName, SE_OBJECT_TYPE.SE_LMSHARE, SECURITY_INFORMATION.DACL_SECURITY_INFORMATION);
                // Create Dacl
                if (sd != null)
                {
                    dacl = sd.Dacl;
                }
                else
                {
                    dacl = new Dacl();
                    sd = new SecurityDescriptor();
                    sd.AllocateAndInitializeSecurityDescriptor();
                }
                // Make it accessible to everyone
                dacl.SetEmpty();
                dacl.AddAce(new AceAccessAllowed(new Sid("Everyone"), AccessType.GENERIC_ALL));
                // Add dacl to sd
                sd.SetDacl(dacl);
                // Set the security descriptor
                sd.SetNamedSecurityInfo(shareName, SE_OBJECT_TYPE.SE_LMSHARE, SECURITY_INFORMATION.DACL_SECURITY_INFORMATION);
            }
            catch (Exception ex)
            {
                ex = ex;
            }
        }
        /// <summary>
        /// Creates a new network share
        /// </summary>
        /// <param name="serverName"></param>
        /// <param name="sharePath"></param>
        /// <param name="shareName"></param>
        /// <param name="description"></param>
        /// <param name="bAdmin"></param>
        /// <returns></returns>
        public void DeleteShare(string serverName, string shareName)
        {
            // Manipulate the server name if necessary
            serverName = String.Format("{0}{1}", serverName.Length != 0 && serverName[0] != '\\' ? @"\\" : String.Empty, serverName);
            // Delete it
            NetError errorValue = (NetError)NetShareDel(serverName, shareName, 0);
        }
        /// <summary>
        /// Gets message for last error.  Creates an exception with the string.
        /// </summary>
        /// <param name="errorCode">Error code to translate</param>
        /// <returns>Error message</returns>
        private string GetMessageWithException(int errorCode)
        {
            try 
            {
                Marshal.ThrowExceptionForHR(unchecked((int)0x80070000 | errorCode));
                return String.Empty;
            }
            catch (Exception ex) 
            {
                return ex.Message;
            }
        }
    }
}                       
         