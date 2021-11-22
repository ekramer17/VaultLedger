using System;
using System.IO;
using System.Data;
using System.Collections;
using System.Windows.Forms;
using Microsoft.Win32;

namespace Bandl.Utility.VaultLedger.Installation.SqlEnumerator
{
	class MainObject
	{
		private static String o1 = null;

		static int Main(string[] args)
		{
			try
			{
				ProcessCommandLine(Environment.GetCommandLineArgs());
				// If no output directory or directory does not exist, throw exception
				if (o1 == null || o1.Length == 0) throw new ApplicationException("No output file specified");
				// Write
				DoWrite();
				// Return
				return 0;
			}
			catch (Exception ex)
			{
				MessageBox.Show(ex.Message, "ADM - SQL Server Enumerator", MessageBoxButtons.OK, MessageBoxIcon.Stop);
				return -100;
			}
		}

		private static void ProcessCommandLine(string[] args)
		{
			Int32 x1 = -1;

			try
			{
				for (int i = 1; i < args.Length; i++)
				{
					// Make sure we have a colon
					if ((x1 = args[i].IndexOf(':')) == -1)
					{
						throw new ApplicationException("Incorrect syntax (" + args[i] + ")");
					}
					else
					{
						// Split the field on the colon
						string s1 = args[i].Substring(x1 + 1).Trim();
						// Get the value based on the first half
						switch (args[i].Substring(0, x1).ToLower())
						{
							case "/o":
								o1 = s1;
								break;
							default:
								throw new ApplicationException(String.Format("Unknown flag ({0})", s1[0]));
						}
					}
				}
			}
			catch (Exception e)
			{
				throw new ApplicationException("Error in command line: " + e.Message);
			}
		}

		private static void DoWrite()
		{
			ArrayList x1 = new ArrayList();
			String m1 = Environment.MachineName;
			// Get the sql servers
			foreach (SqlServerInfo i in SqlServerInfo.Seek())
			{
				String s1 = i.InstanceName.Length != 0 && i.InstanceName != "MSSQLSERVER" ? i.ServerName + "\\" + i.InstanceName : i.ServerName;

				if (x1.Count == 0)
				{
					x1.Add(s1);
				}
				else if (!x1.Contains(s1))
				{
					x1.Add(s1);
				}
			}
			// Get the locals
//			x1 = GetLocal(x1);
			// Sort the array
			String[] x2 = (String[])x1.ToArray(typeof(String));
			Array.Sort(x2);
			// Write to file
			using (StreamWriter w = new StreamWriter(o1))
			{
				for (int i = 0; i < x2.Length; i += 1)
				{
					w.Write(String.Format("{0}{1}", i != 0 ? "$NEWLINE$" : String.Empty, x2[i]));
				}
			}
		}

//		private static ArrayList GetLocal(ArrayList a1)
//		{
//			RegistryKey k1 = null;
//			String[] s1 = null;
//			String x1 = "SOFTWARE\\Microsoft\\Microsoft SQL Server";
//
//			if ((k1 = Registry.LocalMachine.OpenSubKey(x1)) == null)
//			{
//				return a1;
//			}
//			else
//			{
//				s1 = k1.GetSubKeyNames();
//				k1.Close();
//			}
//
//			foreach (String s2 in s1)
//			{
//				if ((k1 = Registry.LocalMachine.OpenSubKey(x1 + "\\" + s2)) != null)
//				{
//					String y1 = (String)k1.GetValue(null);
//					k1.Close();
//					// Only proceed if we do not have a default value
//					if (y1 == null || y1.Length == 0)
//					{
//						if ((k1 = Registry.LocalMachine.OpenSubKey(x1 + "\\" + s2 + "\\MSSQLSERVER\\CurrentVersion")) != null)
//						{
//							String s3 = (String)k1.GetValue("CurrentVersion");
//							k1.Close();
//							if (s3 != null && s3.Length != 0 && Int32.Parse(s3.Substring(0, s3.IndexOf('.'))) > 7)
//							{
//								String a2 = s2.Length != 0 && s2 != "MSSQLSERVER" ? Environment.MachineName + "\\" + s2 : Environment.MachineName;
//MessageBox.Show("A2", a2);
//								for (int i = 0; i < a1.Count; i += 1)
//								{
//									if (((String)a1[i]) == a2)
//									{
//										break;
//									}
//									else if (i == a1.Count - 1)
//									{
//										a1.Add(a2);
//									}
//								}
////								if (s2.Length != 0 && s2 != "MSSQLSERVER")
////								{
////
////									a1.Add(Environment.MachineName + "\\" + s2);
////								}
////								else
////								{
////									a1.Add(Environment.MachineName);
////								}
//							}
//						}
//					}
//				}
//			}
//
//			return a1;
//		}
	}
}
