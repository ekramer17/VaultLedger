using System;
using System.Text;
using System.Data;
using System.Configuration;
using System.Data.SqlClient;
using Bandl.Library.VaultLedger.Common.Knock;
using Bandl.Utility.VaultLedger.Registrar.Model;

namespace Bandl.Utility.VaultLedger.Registrar.SQLServer
{
	/// <summary>
	/// This class represents the master database on the server that is to host
	/// the new client application database.
	/// </summary>
	public class MasterDb
	{
        private string ConnectString(bool sspi, string uid, string pwd)
        {
            // Initialize the string
            string c = String.Format("Server={0};Database=master;Pooling=false;", Configurator.ClientDbServer);
            // Append appropriate ending
            if (sspi == true)
            {
                return c + "Trusted_Connection=sspi";
            }
            else if (pwd.Trim().Length == 0)
            {
                return c + String.Format("User Id={0}", uid);
            }
            else
            {
                return c + String.Format("User Id={0};Password={1}", uid, pwd);
            }
        }
        /// <summary>
        /// Connects to the the master database on the current VaultLedger server
        /// </summary>
        /// <returns>
        /// SqlConnection object
        /// </returns>
        public SqlConnection Connect()
        {
            // If no server then throw exception
            if (0 == Configurator.ClientDbServer.Length)
            {
                throw new ApplicationException("Current client application database server not supplied");
            }
            // Connect to the database
            try
            {
                bool sspi = Configurator.SAPassword.Length != 0 ? false : true;
                SqlConnection c = new SqlConnection(ConnectString(sspi, "sa", Configurator.SAPassword));
                c.Open();
                return c;
            }
            catch (Exception e)
            {
                throw new ApplicationException("Error encountered while connecting to master database on " + Configurator.ClientDbServer + ".  " + e.Message,  e); 
            }
        }

        /// <summary>
        /// Creates a new application database on the application server
        /// </summary>
        public void CreateDatabase(string dbName)
        {
            // Create the database
            try
            {
                using (SqlConnection c = this.Connect())
                {
                    // Build the database
                    StringBuilder s = new StringBuilder();
                    s.AppendFormat("CREATE DATABASE {0}", dbName);
                    s.AppendFormat(" ON PRIMARY (");
                    s.AppendFormat(" NAME = '{0}_Data',", dbName);
                    s.AppendFormat(" FILENAME = '{0}{1}.MDF',", Configurator.DbDataFileLocation, dbName);
                    s.AppendFormat(" FILEGROWTH = {0} )", Configurator.DbDataFileGrowth);
                    s.AppendFormat(" LOG ON (");
                    s.AppendFormat(" NAME = '{0}_Log',", dbName);
                    s.AppendFormat(" FILENAME = '{0}{1}.LDF',", Configurator.DbLogFileLocation, dbName);
                    s.AppendFormat(" FILEGROWTH = {0} )", Configurator.DbLogFileGrowth);
                    SqlCommand cmd = c.CreateCommand();
                    cmd.CommandType = CommandType.Text;
                    cmd.CommandText = s.ToString();
                    cmd.ExecuteNonQuery();
                    // Alter the database to employ recursive triggers
                    try
                    {
                        cmd = c.CreateCommand();
                        cmd.CommandType = CommandType.Text;
                        cmd.CommandText = String.Format("ALTER DATABASE {0} SET RECURSIVE_TRIGGERS ON", dbName);
                        cmd.ExecuteNonQuery();
                    }
                    catch
                    {
                        this.DropDatabase(dbName);
                        throw;
                    }
                    // Build and execute a command to register the extended stored
                    // procedure for regular expression matching
                    try
                    {
                        cmd = c.CreateCommand();
                        cmd.CommandType = CommandType.Text;
                        cmd.CommandText = "IF NOT EXISTS(SELECT 1 FROM dbo.sysobjects WHERE name = 'xp_pcre_match' and objectproperty(id, 'IsExtendedProc') = 1) EXECUTE sp_addextendedproc xp_pcre_match, 'xp_pcre.dll'";
                        cmd.ExecuteNonQuery();
                        cmd = c.CreateCommand();
                        cmd.CommandType = CommandType.Text;
                        cmd.CommandText = "GRANT EXECUTE ON xp_pcre_match TO public";
                        cmd.ExecuteNonQuery();
                    }
                    catch
                    {
                        this.DropDatabase(dbName);
                        throw;
                    }
                }
            }
            catch (Exception e)
            {
                throw new ApplicationException("Error encountered while creating new database: " + e.Message, e);
            }
        }

        /// <summary>
        /// Drops the database in the event that something goes wrong during creation
        /// </summary>
        /// <param name="dbName">
        /// Name of databasse to drop
        /// </param>
        public void DropDatabase(string dbName)
        {
            using (SqlConnection c = this.Connect())
            {
                try
                {
                    SqlCommand cmd = c.CreateCommand();
                    cmd.CommandType = CommandType.Text;
                    cmd.CommandText = String.Format("IF EXISTS (SELECT 1 FROM master.dbo.sysdatabases WHERE name = '{0}') DROP DATABASE {0}", dbName); 
                    cmd.ExecuteNonQuery();
                }
                catch
                {
                    // Do nothing
                }
            }
        }

        public bool LoginExists(ServerLogin serverLogin)
        {
            StringBuilder connectString = new StringBuilder();

            try
            {
                connectString.Append("Pooling=false");
                connectString.AppendFormat(";Server={0}", Configurator.ClientDbServer);
                if (serverLogin.Trusted)
                {
                    connectString.Append(";Integrated Security=SSPI");
                }
                else
                {
                    connectString.AppendFormat(";User Id={0}", serverLogin.Login);
                    if (serverLogin.Password.Length > 0)
                    {
                        connectString.AppendFormat(";Password={0}", serverLogin.DecryptPassword());
                    }
                }

                SqlConnection c = new SqlConnection();
                c.ConnectionString = connectString.ToString();
                c.Open();
                c.Close();
                return true;
            }
            catch
            {
                return false;
            }
        }

        public void CreateLogin(ServerLogin sl)
        {
            try
            {
                using (SqlConnection c = this.Connect())
                {
                    // Determine if the login exists.  If it does, throw an exception.
                    SqlCommand cmd = c.CreateCommand();
                    cmd.CommandType = CommandType.Text;
                    cmd.CommandText = String.Format("IF EXISTS (SELECT 1 FROM syslogins WHERE name = '{0}') SELECT 1 ELSE SELECT 0", sl.Login);
                    if ((int)cmd.ExecuteScalar() == 1)
                    {
                        // Attempt to connect using the default password.  If able to connect, just return.  Otherwise, throw exception.
                        using (SqlConnection c1 = new SqlConnection(ConnectString(false, sl.Login, sl.DecryptPassword())))
                        {
                            try
                            {
                                c1.Open();
                                return;
                            }
                            catch
                            {
                                throw new ApplicationException ("Cannot add server when login '" + sl.Login + "' already exists in system.  Password unknown.");
                            }
                        }
                    }
                    // Create the application login
                    cmd = c.CreateCommand();
                    cmd.CommandType = CommandType.Text;
                    if (sl.Trusted == false)
                    {
                        cmd.CommandText = String.Format("EXECUTE sp_addlogin @loginame = '{0}', @passwd = '{1}'", sl.Login, sl.DecryptPassword());
                    }
                    else
                    {
                        cmd.CommandText = String.Format("EXECUTE sp_grantlogin @loginame = '{0}'", sl.Login);
                    }
                    cmd.ExecuteNonQuery();
                }
            }
            catch (Exception e)
            {
                throw new ApplicationException("Error encountered while inserting server login: " + e.Message, e);
            }
        }

        public void DeleteLogin(ServerLogin login)
        {
            try
            {
                using (SqlConnection c = this.Connect())
                {
                    SqlCommand cmd = c.CreateCommand();
                    cmd.CommandType = CommandType.Text;
                    if (login.Trusted == false)
                    {
                        cmd.CommandText = String.Format("EXECUTE sp_droplogin @loginame = '{0}'", login.Login);
                    }
                    else
                    {
                        cmd.CommandText = String.Format("EXECUTE sp_revokelogin @loginame = '{0}'", login.Login);
                    }
                    cmd.ExecuteNonQuery();
                }
            }
            catch (Exception e)
            {
                throw new ApplicationException("Error encountered while deleting server login: " + e.Message, e);
            }
        }
    }
}
