using System;
using Microsoft.Win32;
using System.Windows.Forms;

namespace Bandl.Utility.VaultLedger.Installation.BrowserStarter
{
    /// <summary>
    /// Summary description for MainObject.
    /// </summary>
    class MainObject
    {
        /// <summary>
        /// The main entry point for the application.
        /// </summary>
		static void Main(string[] args)
		{
			try
			{
				String n1 = @"htmlfile\shell\open\command";
				// Open the default internet browser subkey
				RegistryKey k1 = Registry.ClassesRoot.OpenSubKey(n1);
				// Get the name of the correct subkey
				string e1 = ((String)k1.GetValue(null));
				// Close the key
				k1.Close();
				// Have browser?
				if (e1 == null || e1.Length == 0)
				{
					throw new ApplicationException();
				}
				else if (args[0] == null || args[0].Length == 0)
				{
					throw new ApplicationException();
				}
				else if (e1.IndexOf('"') != 0)
				{
					System.Diagnostics.Process.Start(e1, args[0]);
				}
				else
				{
					string p1 = e1.Substring(e1.IndexOf('"', 1) + 1);
					string e2 = e1.Substring(1, e1.IndexOf('"', 1) - 1);
					System.Diagnostics.Process.Start(e2, p1 + " " + args[0]);
				}
			}
			catch
			{
				String x1 = "Unable to launch browser.  Please open your browser manually and navigate to ";
				MessageBox.Show(x1 + Environment.NewLine + Environment.NewLine + args[0], "Launcher", MessageBoxButtons.OK, MessageBoxIcon.Exclamation);
			}
		}

    }
}
