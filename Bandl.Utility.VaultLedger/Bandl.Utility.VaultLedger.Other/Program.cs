using System;
using System.IO;
using System.Net;
using System.Windows.Forms;
using System.DirectoryServices;
using System.Runtime.InteropServices;
using Microsoft.Win32;
using System.Xml.XPath;
using System.Xml;
using System.Text.RegularExpressions;
using System.Collections;
using Microsoft.Web.Administration;
using System.Security.AccessControl;
using System.Security.Principal;

namespace Bandl.Utility.VaultLedger.Other
{
    static class Program
    {
        private enum Modes { GetDns = 1, Framework, Launch, Permissions }

        private static Int64 index = -1;
        private static String outfile = null;
        private static String url = null;
        private static Modes mode = Modes.GetDns;

        /// <summary>
        /// The main entry point for the application.
        /// </summary>
        [STAThread]
        static int Main()
        {
            Int32 r1 = 0;
            // Process the command line
            ProcessCommandLine(Environment.GetCommandLineArgs());

            try
            {
                switch (mode)
                {
                    case Modes.GetDns:
                        GetDns(index);
                        break;
                    case Modes.Framework:
                        GetFrameworkHome(outfile);
                        break;
                    case Modes.Launch:
                        DoLaunch(url);
                        break;
                    case Modes.Permissions:
                        DoPermissions("S-1-5-20");  // network service sid
                        break;
                    default:
                        throw new ApplicationException("Inappropriate use of utility");
                }
                // Return
                return r1;
            }
            catch (Exception e)
            {
                MessageBox.Show(e.Message, "VaultLedger", MessageBoxButtons.OK, MessageBoxIcon.Stop);
                return -100;
            }
        }
        /// <summary>
        /// Processes the command line arguments and write the connection string to the web.config
        /// file in the parent directory
        /// </summary>
        /// <param name="commandLine">
        /// Array of command line arguments
        /// </param>
        private static void ProcessCommandLine(string[] args)
        {
            String key = null;

            try
            {
                for (int i = 1; i < args.Length; i++)
                {
                    switch (key = GetKey(args[i]))
                    {
                        case "/s":
                            index = Int64.Parse(GetValue(args[i]));
                            mode = Modes.GetDns;
                            break;
                        case "/o":
                            outfile = GetValue(args[i]);
                            break;
                        case "/h":
                            mode = Modes.Framework;
                            break;
                        case "/u":
                            url = GetValue(args[i]);
                            mode = Modes.Launch;
                            break;
                        case "/p":
                            mode = Modes.Permissions;
                            outfile = GetValue(args[i]);
                            break;
                        default:
                            throw new ApplicationException("Unrecognized flag [" + key + "]");
                    }
                }
            }
            catch (Exception e)
            {
                throw new ApplicationException("Error in command line: " + e.Message);
            }
        }
        /// <summary>
        /// Processes the command line arguments and write the connection string to the web.config
        /// file in the parent directory
        /// </summary>
        /// <param name="commandLine">
        /// Array of command line arguments
        /// </param>
        private static string GetKey(string arg)
        {
            // Colon position
            int x1 = arg.IndexOf(':');
            // Get key and value
            if (x1 != -1)
            {
                return arg.Substring(0, x1).Trim();
            }
            else
            {
                return arg.Trim();
            }
        }
        /// <summary>
        /// Processes the command line arguments and write the connection string to the web.config
        /// file in the parent directory
        /// </summary>
        /// <param name="commandLine">
        /// Array of command line arguments
        /// </param>
        private static string GetValue(string arg)
        {
            // Colon position
            int x1 = arg.IndexOf(':');
            // Need colon?
            if (x1 == -1)
            {
                throw new ApplicationException("Incorrect syntax [" + arg + "]");
            }
            else
            {
                return x1 != -1 ? arg.Substring(x1 + 1).Trim() : String.Empty;
            }
        }

        private static void GetDns(Int64 i)
        {
            String[] y1 = null;
            Boolean https = i < 0;
            String h1 = https ? "https" : "http";

            try
            {
                // Set absolute value?
                if (i < 0) i = Math.Abs(i);
                // Get directory entry for index
                DirectoryEntry x1 = new DirectoryEntry(String.Format("IIS://localhost/W3SVC/{0}", i));
                PropertyValueCollection c1 = x1.Properties[https ? "SecureBindings" : "ServerBindings"];
                // Format is IPAddress:Port:HostHeader
                y1 = c1[0].ToString().Split(':');
            }
            catch
            {
                try
                {
                    foreach (Site s1 in new ServerManager().Sites)
                    {
                        if (i == s1.Id)
                        {
                            foreach (Microsoft.Web.Administration.Binding b1 in s1.Bindings)
                            {
                                if (b1.Protocol == h1)
                                {
                                    y1 = b1.BindingInformation.Split(':');
                                    break;
                                }
                            }
                        }
                    }
                }
                finally
                {
                    if (y1 == null)
                    {
                        throw new ApplicationException("Unable to discover " + h1 + " port for web site");
                    }
                }
            }
            // Get address and port
            String a1 = y1[0];
            String p1 = y1[1];
            // Do we have an ip address?
            if (a1.IndexOf('.') == -1 || a1.LastIndexOf('.') == a1.IndexOf('.'))
            {
                a1 = Dns.GetHostName();
            }
            // Output to file?
            if (outfile != null)
            {
                using (StreamWriter w1 = new StreamWriter(outfile, false))
                {
                    w1.Write(String.Format("{0}://{1}:{2}", h1, a1, p1).ToLower());
                }
            }
            else
            {
                Console.WriteLine(String.Format("{0}://{1}:{2}", h1, a1, p1).ToLower());
                Console.ReadLine();
            }
        }

        private static void GetFrameworkHome(String o1)
        {
            StreamWriter w1 = new StreamWriter(o1);
            String r1 = RuntimeEnvironment.GetRuntimeDirectory();
            w1.Write(r1.EndsWith("\\") ? r1.Substring(0, r1.Length - 1) : r1);
            w1.Close();
        }

        private static void DoLaunch(String url)
        {
            try
            {
                // Delete the receive timeout value if it exists
                String n1 = @"software\microsoft\windows\currentversion\internet settings";
                // Modify the receivetimeout key
                using (RegistryKey k1 = Registry.CurrentUser.OpenSubKey(n1, true))
                {
                    k1.SetValue("ReceiveTimeout", (Int32)300000, RegistryValueKind.DWord);  // five minutes
                }

            }
            catch
            {
                ;
            }
            // Launch the URL
            System.Diagnostics.Process.Start(url);
        }

        private static void DoPermissions(String u1)
        {
            try
            {
                bool b1 = false;
                FileSystemRights r1 = FileSystemRights.ReadAndExecute | FileSystemRights.ListDirectory;
                // Get reference to Network Service identity
                IdentityReference i1 = new SecurityIdentifier(u1).Translate(typeof(NTAccount));
                // Set the acess rule
                FileSystemAccessRule a1 = new FileSystemAccessRule(i1, r1, InheritanceFlags.None, PropagationFlags.NoPropagateInherit, AccessControlType.Allow);
                DirectoryInfo d1 = new DirectoryInfo(outfile.TrimEnd(new char[] { '\\' }));
                DirectorySecurity s1 = d1.GetAccessControl(AccessControlSections.Access);
                s1.ModifyAccessRule(AccessControlModification.Set, a1, out b1);
                // Always allow objects to inherit on a directory
                InheritanceFlags f1 = InheritanceFlags.ContainerInherit | InheritanceFlags.ObjectInherit;
                a1 = new FileSystemAccessRule(i1, r1, f1, PropagationFlags.InheritOnly, AccessControlType.Allow);
                s1.ModifyAccessRule(AccessControlModification.Add, a1, out b1);
                d1.SetAccessControl(s1);
            }
            catch
            {
                ;
            }
        }
    }
}