using System;
using System.IO;
using System.Xml;
using System.Text;
using System.Collections;
using System.Windows.Forms;

namespace Bandl.Utility.VaultLedger.ConfigReplacer
{
	/// <summary>
	/// Summary description for Class1.
	/// </summary>
	class Program
	{
		static string temp1 = null; // temp file
		static string config1 = null; // config file
		static bool write = false;
		static string app1 = "VaultLedger";

		[STAThread]
		static int Main()
		{
			try
			{
				XmlDocument x1 = new XmlDocument();
				// Process command line
				ProcessCommandLine(Environment.GetCommandLineArgs());
				// Load the document
				x1.Load(config1);
				// Read or write?
				if (write)
				{
					DoWrite(x1);
				}
				else
				{
					DoRead(x1);
				}
				// Return
				return 0;
			}
			catch (Exception ex)
			{
				MessageBox.Show(ex.Message, app1, MessageBoxButtons.OK, MessageBoxIcon.Exclamation);
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
			try
			{
				for (int i = 1; i < args.Length; i++)
				{
					int x1 = args[i].IndexOf(':');
					// Split the field on the colon
					string y1 = x1 != -1 ? args[i].Substring(x1 + 1).Trim() : null;
					// Get the value based on the first half
					switch (args[i].Substring(0, 2).ToLower())
					{
						case "/w":
							write = true;
							break;
						case "/t":
							temp1 = y1;
							break;
						case "/c":
							config1 = y1;
							break;
						case "/a":
							app1 = y1 == "BANDL" ? "VaultLedger" : "ReQuest Media Manager";
							break;
						default:
							throw new ApplicationException(String.Format("Unknown flag ({0})", args[i].Substring(0, 2)));
					}
				}
			}
			catch (Exception ex)
			{
				throw new ApplicationException("Error in command line: " + ex.Message);
			}
		}

		private static void DoRead(XmlDocument x1)
		{
			using (StreamWriter w1 = new StreamWriter(temp1, false))
			{
				foreach (XmlNode n1 in x1.SelectSingleNode("/configuration/appSettings").ChildNodes)
				{
					w1.WriteLine(String.Format("{0}|{1}", n1.Attributes["key"].Value, n1.Attributes["value"].Value));
				}
			}
		}

		private static void DoWrite(XmlDocument x1)
		{
			String a1 = null;

			Hashtable s1 = new Hashtable();
			Hashtable s2 = new Hashtable();
			// Create list of defaults
			s1.Add("Idle", "20");
			s1.Add("DBMS", "SQLServer");
			s1.Add("ConnString", String.Empty);
			s1.Add("ConnVector", String.Empty);
			s1.Add("Router", "false");
			s1.Add("WebProxy", "http://address:port");
			s1.Add("GlobalAccount", String.Empty);
			s1.Add("SupportAccess", "false");
			s1.Add("DbCmdTimeout", "180");
			// Product dependent defaults
			if (a1 == "VaultLedger")
			{
				s1.Add("ProductType", "BANDL");
				s1.Add("XmitMethod", "FTP");
			    s1.Add("Bandl.Library.VaultLedger.Gateway.Bandl.Bandl.BandlService", "https://na1.vaultledger.com/service/vaultledger.asmx");
			}
			else
			{
				s1.Add("ProductType", "RECALL");
				s1.Add("XmitMethod", "RECALLSERVICE");
			}
			// Read the temp file
			using (StreamReader r1 = new StreamReader(temp1))
			{
				while ((a1 = r1.ReadLine()) != null)
				{
					s2.Add(a1.Substring(0, a1.IndexOf('|')), a1.Substring(a1.IndexOf('|') + 1));
				}
			}
			// Get the appSettings node
			XmlNode n1 = x1.SelectSingleNode("/configuration/appSettings");
			// Remove all the child nodes
			for (int i = n1.ChildNodes.Count - 1; i > -1; i -= 1)
			{
				n1.RemoveChild(n1.ChildNodes[i]);
			}
			// Add all the keys using default if nothing present
			foreach (String k1 in s1.Keys)
			{
				XmlElement e1 = x1.CreateElement("add");
				e1.SetAttribute("key", k1);
				e1.SetAttribute("value", s2.ContainsKey(k1) ? (string)s2[k1] : (string)s1[k1]);
				n1.AppendChild(e1);
			}
			// Replace the appSettings node
			XmlNode o1 = x1.SelectSingleNode("/configuration/appSettings");
			o1.ParentNode.ReplaceChild(n1, o1);
			// Get the file information
			FileInfo i1 = new FileInfo(config1);
			bool b1 = (i1.Attributes & FileAttributes.ReadOnly) != 0;
			// Alter from read-only?
			if (b1) i1.Attributes &= ~FileAttributes.ReadOnly;
			// Save the document
			x1.Save(config1);
			// Restore read-only?
			if (b1) i1.Attributes |= FileAttributes.ReadOnly;
			// Delete the temp file
			File.Delete(temp1);
		}
	}
}
