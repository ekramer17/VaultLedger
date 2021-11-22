using System;
using System.IO;
using System.Text;
using Microsoft.Win32;
using System.Reflection;
using System.Runtime.InteropServices;

namespace Bandl.Service.VaultLedger.Loader
{
    /// <summary>
    /// Summary description for Win32.
    /// </summary>
    public class Win32
    {
        [StructLayout(LayoutKind.Sequential)]
        public struct SERVICE_STATUS
        {
            public int serviceType;
            public int currentState;
            public int controlsAccepted;
            public int win32ExitCode;
            public int serviceSpecificExitCode;
            public int checkPoint;
            public int waitHint;
        }

        [StructLayout(LayoutKind.Sequential)]
        public struct SERVICE_DESCRIPTION
        {
            public string description;
        }

        #region DLLImports
        [DllImport("advapi32.dll")]
        public static extern IntPtr OpenSCManager(string lpMachineName,string lpSCDB, int scParameter);
        [DllImport("advapi32.dll")]
        public static extern IntPtr CreateService(IntPtr SC_HANDLE, string lpSvcName, string lpDisplayName, int dwDesiredAccess,int dwServiceType,int dwStartType,int dwErrorControl,string lpPathName, string lpLoadOrderGroup, int lpdwTagId, string lpDependencies, string lpServiceStartName, string lpPassword);
        [DllImport("advapi32.dll")]
        public static extern void CloseServiceHandle(IntPtr SCHANDLE);
        [DllImport("advapi32.dll")]
        public static extern int QueryServiceStatus(IntPtr SC_HANDLE, out SERVICE_STATUS lpServiceStatus);
        [DllImport("advapi32.dll")]
        public static extern int StartService(IntPtr SVHANDLE, int dwNumServiceArgs, string lpServiceArgVectors);
        [DllImport("advapi32.dll")]
        public static extern int ControlService(IntPtr SVHANDLE, int dwControl, out SERVICE_STATUS lpServiceService);
        [DllImport("advapi32.dll", SetLastError=true)]
        public static extern IntPtr OpenService(IntPtr SCHANDLE,string lpSvcName, int dwNumServiceArgs);
        [DllImport("advapi32.dll")]
        public static extern int DeleteService(IntPtr SVHANDLE);
        [DllImport("advapi32.dll")]
        public static extern int ChangeServiceConfig2(IntPtr SVHANDLE, int dwInfoLevel, ref SERVICE_DESCRIPTION lpInfo);
        [DllImport("kernel32.dll")]
        public static extern int GetLastError();
        [DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError=true)]
        public static extern uint GetShortPathName([MarshalAs(UnmanagedType.LPTStr)]string lpszLongPath, [MarshalAs(UnmanagedType.LPTStr)]StringBuilder lpszShortPath, uint cchBuffer);
        #endregion DLLImport

        #region Constants
        public const int SC_MANAGER_CONNECT = 0x0001;
        public const int SC_MANAGER_CREATE_SERVICE = 0x0002;
        public const int SC_MANAGER_ENUMERATE_SERVICE = 0x0004;
        public const int SC_MANAGER_LOCK = 0x0008;
        public const int SC_MANAGER_QUERY_LOCK_STATUS = 0x0010;
        public const int SC_MANAGER_MODIFY_BOOT_CONFIG = 0x0020;
        public const int SC_MANAGER_ALL_ACCESS = (STANDARD_RIGHTS_REQUIRED |
            SC_MANAGER_CONNECT            |
            SC_MANAGER_CREATE_SERVICE     |
            SC_MANAGER_ENUMERATE_SERVICE  |
            SC_MANAGER_LOCK               |
            SC_MANAGER_QUERY_LOCK_STATUS  |
            SC_MANAGER_MODIFY_BOOT_CONFIG);
        public const int SERVICE_WIN32_OWN_PROCESS = 0x00000010;
        public const int SERVICE_DEMAND_START = 0x00000003;
        public const int SERVICE_ERROR_NORMAL = 0x00000001;
        public const int STANDARD_RIGHTS_REQUIRED = 0xF0000;
        public const int SERVICE_QUERY_CONFIG = 0x0001;
        public const int SERVICE_CHANGE_CONFIG = 0x0002;
        public const int SERVICE_QUERY_STATUS = 0x0004;
        public const int SERVICE_ENUMERATE_DEPENDENTS = 0x0008;
        public const int SERVICE_START = 0x0010;
        public const int SERVICE_STOP = 0x0020;
        public const int SERVICE_PAUSE_CONTINUE = 0x0040;
        public const int SERVICE_INTERROGATE = 0x0080;
        public const int SERVICE_USER_DEFINED_CONTROL = 0x0100;
        public const int SERVICE_ALL_ACCESS = (STANDARD_RIGHTS_REQUIRED |
            SERVICE_QUERY_CONFIG |
            SERVICE_CHANGE_CONFIG |
            SERVICE_QUERY_STATUS |
            SERVICE_ENUMERATE_DEPENDENTS |
            SERVICE_START |
            SERVICE_STOP |
            SERVICE_PAUSE_CONTINUE |
            SERVICE_INTERROGATE |
            SERVICE_USER_DEFINED_CONTROL);
        public const int SERVICE_AUTO_START = 0x00000002;
        public const int ERROR_SERVICE_EXISTS = 1073;
        public const int ERROR_SERVICE_DOES_NOT_EXIST = 1060;
        public const int ERROR_SERVICE_MARKED_FOR_DELETE = 1072;
        public const int SERVICE_STOPPED = 0x0001;
        public const int SERVICE_STOP_PENDING = 0x0003;
        public const int SERVICE_CONTROL_STOP = 0x0001;
        public const int SERVICE_CONFIG_DESCRIPTION = 0x0001;
        public const int SERVICE_INTERACTIVE_PROCESS = 0x0100;
        #endregion
    }
}
