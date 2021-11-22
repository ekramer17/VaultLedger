using System;
using System.IO;
using System.Net;
using System.Drawing;
using System.Collections;
using System.ComponentModel;
using System.Windows.Forms;
using System.Data;
using System.Data.SqlClient;
using System.Text;

namespace Bandl.Utility.VaultLedger.Installation.ConnectionTester
{
    /// <summary>
    /// Summary description for Class1.
    /// </summary>
    class MainObject
    {
		[Flags]
		enum Role {NONE = 0, SYSADMIN = 1, DBOWNER = 2}

		private static string s1 = String.Empty;        // server
		private static string c1 = String.Empty;        // catalog
		private static string t1 = "FALSE";             // trusted
		private static string u1 = String.Empty;        // user id
		private static string p1 = String.Empty;        // password
		private static string a1 = String.Empty;        // application name
		private static string f1 = String.Empty;        // output file - for getting binary path
		private static bool q1 = false;					// quiet
		private static Role r1 = Role.NONE;				// security role
		/// <summary>
		/// The main entry point for the application.
		/// </summary>
		static int Main()
		{
			try
			{
				String y1 = ProcessCommandLine(Environment.GetCommandLineArgs());
				// Test only or write file?
				if (f1.Length != 0)
				{
					GetBinary(y1);
				}
				else
				{
					DoTest(y1);
				}
				// Return
				return 0;
			}
			catch (Exception ex)
			{
				if (q1 != true) MessageBox.Show(ex.Message, a1, MessageBoxButtons.OK, MessageBoxIcon.Exclamation);
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
		private static string ProcessCommandLine(string[] args)
		{
			try
			{
				for (int i = 1; i < args.Length; i++)
				{
					int x1 = args[i].IndexOf(':');
					// Split the field on the colon
					string y1 = args[i].Substring(x1 + 1).Trim();
					// Get the value based on the first half
					switch (args[i].Substring(0, 2).ToLower())
					{
						case "/s":
							s1 = y1;
							break;
						case "/d":
							c1 = y1;
							break;
						case "/u":
							u1 = y1;
							break;
						case "/p":
							p1 = y1;
							break;
						case "/a":
							a1 = (y1 == "BANDL" ? "VaultLedger" : "ReQuest Media Manager");
							break;
						case "/f":
							f1 = y1;
							break;
						case "/t":
							t1 = (y1.ToUpper() == "FALSE" || y1.ToUpper() == "NO") ? "FALSE" : "TRUE";
							break;
						case "/q":
							q1 = true;
							break;
						case "/r":
							y1 = y1.ToUpper();
							if (y1 == "SYSADMIN")
							{
								r1 = Role.SYSADMIN;
							}
							else if (y1.IndexOf("OWNER") != -1)
							{
								r1 = Role.DBOWNER;
							}
							else
							{
								try
								{
									switch (Int32.Parse(y1))
									{
										case (Int32)Role.SYSADMIN:
											r1 = Role.SYSADMIN;
											break;
										case (Int32)Role.DBOWNER:
											r1 = Role.DBOWNER;
											break;
										case (Int32)(Role.DBOWNER | Role.SYSADMIN):
											r1 = Role.DBOWNER | Role.SYSADMIN;
											break;
										default:
											throw new ApplicationException();
									}
								}
								catch
								{
									throw new ApplicationException("Invalid security check type");
								}
							}
							break;
						default:
							throw new ApplicationException(String.Format("Unknown flag ({0})", y1[0]));
					}
				}
			}
			catch (Exception ex)
			{
				throw new ApplicationException("Error in command line: " + ex.Message);
			}
			// Create the connection string
			String y2 = String.Format("Server={0}", s1);
			if (c1.Length != 0) y2 += ";Database=" + c1;
			if (t1 == "TRUE")
			{
				y2 += ";Trusted_Connection=TRUE";
			}
			else
			{
				y2 += ";User Id=" + u1;
				if (p1.Length != 0) y2 += ";Password=" + p1;
			}
			// Return the string
			return y2 + ";Pooling=False";
		}
		/// <summary>
		/// Executes the script
		/// </summary>
		/// <param name="connectString">
		/// Connection string to use
		/// </param>
		/// <param name="fileName">
		/// Name of script file to execute
		/// </param>
		private static void DoTest(string x1)
		{
			using (SqlConnection c = new SqlConnection(x1))
			{
				try
				{
					c.Open();
				}
				catch
				{
					if (c1.Length != 0)
					{
						throw new ApplicationException("Unable to connect to server " + s1 + ", database " + c1 + " using login " + u1);
					}
					else
					{
						throw new ApplicationException("Unable to connect to server " + s1 + " using login " + u1);
					}
				}
				// Make sure it is Sql Server 2000 or above
				SqlCommand x2 = c.CreateCommand();
				x2.CommandType = CommandType.Text;
				x2.CommandText = "SELECT CAST(SERVERPROPERTY('PRODUCTVERSION') AS NVARCHAR(50))";
				String y1 = (String)x2.ExecuteScalar();
				if (Int32.Parse(y1.Substring(0, y1.IndexOf('.'))) < 8)
				{
					throw new ApplicationException("Specified SQL Server instance is not SQL Server 2000 or above.");
				}
				// Privileges?
				if (r1 == Role.SYSADMIN)
				{
					if (CheckRole(r1, c) == false)
					{
						throw new ApplicationException(u1 + " is not a member of the sysadmin role.  Please use a login with sysadmin privileges.");
					}
				}
				else if (r1 == Role.DBOWNER)
				{
					if (CheckRole(r1, c) == false)
					{
						throw new ApplicationException(u1 + " is not a member of the db_owner role.  Please use a login with db_owner privileges.");
					}
				}
				else if (r1 == (Role.DBOWNER | Role.SYSADMIN))
				{
					if (CheckRole(Role.DBOWNER, c) == false && CheckRole(Role.SYSADMIN, c) == false)
					{
						throw new ApplicationException(u1 + " does not have sufficient rights.  A db_owner or sysadmin role is required.");
					}
				}
			}
		}

		private static bool CheckRole(Role r1, SqlConnection c1)
		{
			if (r1 == Role.SYSADMIN)
			{
				SqlCommand x2 = c1.CreateCommand();
				x2.CommandType = CommandType.Text;
				x2.CommandText = "SELECT coalesce(IS_SRVROLEMEMBER('sysadmin' , '" + u1 + "'), 0)";
				if ((Int32)x2.ExecuteScalar() != 1)
				{
					return false;
				}
			}
			else if (r1 == Role.DBOWNER)
			{
				SqlCommand x2 = c1.CreateCommand();
				x2.CommandType  = CommandType.Text;
				x2.CommandText  = "SELECT 1";
				x2.CommandText += "FROM   sysusers u ";
				x2.CommandText += "JOIN   sysmembers m ";
				x2.CommandText += "  ON   m.memberuid = u.uid ";
				x2.CommandText += "WHERE  u.name = '" + u1 + "' AND m.groupuid = (SELECT uid FROM sysusers WHERE name = 'db_owner')";
				if (x2.ExecuteScalar() == null)
				{
					return false;
				}
			}
			// Return
			return true;
		}

		/// <summary>
		/// Executes the script
		/// </summary>
		/// <param name="connectString">
		/// Connection string to use
		/// </param>
		/// <param name="fileName">
		/// Name of script file to execute
		/// </param>
		private static void GetBinary(string x1)
		{
			String x2 = null;

			using (SqlConnection c1 = new SqlConnection(x1))
			{
				// Open
				c1.Open();
				// Get the version
				SqlCommand c2 = c1.CreateCommand();
				c2.CommandType = CommandType.Text;
				c2.CommandText = "SELECT CAST(SERVERPROPERTY('PRODUCTVERSION') AS NVARCHAR(50))";
				String y1 = (String)c2.ExecuteScalar();
				Int32 v1 = Int32.Parse(y1.Substring(0, y1.IndexOf('.')));
				// SQL2000 or SQL2005?
				if (v1 > 8)
				{
					c2 = c1.CreateCommand();
					c2.CommandType = CommandType.Text;
					c2.CommandText = "EXECUTE master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE', N'SOFTWARE\\MICROSOFT\\MSSQLSERVER\\SETUP', N'SQLBINROOT'";
					// Execute
					SqlDataReader r1 = c2.ExecuteReader();
					r1.Read();
					x2 = r1.GetString(1);
					r1.Close();
				}
				else
				{
					c2 = c1.CreateCommand();
					c2.CommandType = CommandType.Text;
					c2.CommandText = "EXECUTE master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE', N'SOFTWARE\\MICROSOFT\\MSSQLSERVER\\SETUP', N'SQLPATH'";
					// Execute
					SqlDataReader r1 = c2.ExecuteReader();
					r1.Read();
					x2 = r1.GetString(1) + "\\BINN";
					r1.Close();
				}
			}
			// Write
			StreamWriter w1 = new StreamWriter(f1, false);
			w1.Write(x2);
			w1.Close();
		}
	}
}
