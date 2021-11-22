using System;
using System.IO;
using System.Web;
using System.Data;
using System.Text;
using System.Collections;
using System.Configuration;
using System.Data.SqlClient;
using Bandl.Library.VaultLedger.Common.Knock;
using Bandl.Utility.VaultLedger.Registrar.Model;
using System.Diagnostics;

namespace Bandl.Utility.VaultLedger.Registrar.SQLServer
{
    /// <summary>
    /// Summary description for VaultLedgerDb.
    /// </summary>
    public class VaultLedgerDb
    {
        private string dbName;
        private MasterDb masterDb;

        // Constructor
        public VaultLedgerDb(string _dbName) 
        {
            if (_dbName == null || _dbName == String.Empty)
            {
                throw new ApplicationException("Name of database not supplied.");
            }
            else
            {
                dbName = _dbName;
                masterDb = new MasterDb();
            }
        }

        private string RoleName
        {
            get
            {
                switch (Configurator.ProductType)
                {
                    case "BANDL":
                        return "BLRole";
                    case "RECALL":
                    default:
                        return "RMMRole";
                }
            }
        }

        private SqlConnection Connect()
        {
            SqlConnection c = masterDb.Connect();
            c.ChangeDatabase(dbName);
            return c;
        }

        /// <summary>
        /// Reads the table and procedure information from 1_0_0.sqe and 
        /// executes the commands within against the new database
        /// </summary>
        public void InitializeDatabase(OwnerDetails o, string login, string pwd)
        {
            string sql = null;
            // Get a sql script object
            SqlScript sqlObj = new SqlScript();
            // Run through the scripts
            while ((sql = sqlObj.NextFileContent()).Length != 0)
            {
                // Insert a space in the GOTO commands so that they will not be used
                // to truncate where a GO command is used to truncate.
                sql = sql.Replace("\nGOTO", "\n GOTO");
                // Execute the commands
                using (SqlConnection c = this.Connect())
                {
                    int i, pi = 0; // index, previous index
                    string commandText = String.Empty;
                    while ((i = sql.IndexOf("\nGO", pi)) != -1 && pi < sql.Length )
                    {
                        // Get the command text
                        commandText = sql.Substring(pi, i - pi).Trim();
                        // Move the prior index forward
                        pi = i + 3;
                        // Execute the command
                        SqlCommand cmd = c.CreateCommand();
                        cmd.CommandType = CommandType.Text;
                        cmd.CommandText = commandText;
                        cmd.CommandTimeout = 600;
                        cmd.ExecuteNonQuery();
                    }
                }
                // If this is the first file, then create the administrator and insert the subscription
                if (sqlObj.CurrentFile == sqlObj.FirstFile)
                {
                    // Update the administrator usercode and password with the given
                    this.CreateAdministrator(o, login, pwd);
                    // Insert the subscription
                    this.InsertSubscription(o);
                }
            }
        }
        /// <summary>
        /// Grants and revokes permissions on objects and procedures
        /// </summary>
		public void GrantPermissions(string userLogin)
//		public void GrantPermissions(string userLogin, string adminLogin)
        {
            using (SqlConnection c = this.Connect())
            {
                // Grant access to the user login
                SqlCommand cmd = c.CreateCommand();
                cmd.CommandType = CommandType.Text;
                cmd.CommandText = String.Format("EXECUTE sp_grantdbaccess @loginame = '{0}'", userLogin);
                cmd.ExecuteNonQuery();
				// Assign the update login to the db_owner role
				cmd = c.CreateCommand();
				cmd.CommandType = CommandType.Text;
				cmd.CommandText = String.Format("EXECUTE sp_addrolemember 'db_owner', '{0}'", userLogin);
				cmd.ExecuteNonQuery();

//
//                // Add a standard role
//                cmd = c.CreateCommand();
//                cmd.CommandType = CommandType.Text;
//                cmd.CommandText = String.Format("EXECUTE sp_addrole '{0}', 'dbo'", this.RoleName);
//                cmd.ExecuteNonQuery();
//                // Add the user login to the role
//                cmd = c.CreateCommand();
//                cmd.CommandType = CommandType.Text;
//                cmd.CommandText = String.Format("EXECUTE sp_addrolemember '{0}', '{1}'", this.RoleName, userLogin);
//                cmd.ExecuteNonQuery();
//                // Grant SELECT permissions on all tables to the role.  Revoke 
//                // all permissions from the public role and the Librarian user.
//                StringBuilder s = null;
//                cmd = c.CreateCommand();
//                cmd.CommandType = CommandType.Text;
//                ArrayList tableNames = new ArrayList();
//                cmd.CommandText = "SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE' AND TABLE_NAME != 'dtproperties'";
//                using (SqlDataReader r = cmd.ExecuteReader())
//                {
//                    while (r.Read()) 
//                    {
//                        tableNames.Add(r.GetString(0));
//                    }
//                }
//                foreach (string table in tableNames)
//                {
//                    s = new StringBuilder();
//                    cmd = c.CreateCommand();
//                    cmd.CommandType = CommandType.Text;
//                    s.AppendFormat("REVOKE ALL ON {0} FROM public\r\n", table);
//                    s.AppendFormat("REVOKE ALL ON {0} FROM {1}\r\n", table, userLogin);
//                    s.AppendFormat("GRANT SELECT ON {0} TO {1}", table, this.RoleName);
//                    cmd.CommandText = s.ToString();
//                    cmd.ExecuteNonQuery();
//                }
//                // Grant EXECUTE permissions on all stored procedures to the 
//                // role.  Revoke all permissions from the public role and 
//                // the Librarian user.
//                cmd = c.CreateCommand();
//                cmd.CommandType = CommandType.Text;
//                ArrayList routineNames = new ArrayList();
//                cmd.CommandText = "SELECT ROUTINE_NAME FROM INFORMATION_SCHEMA.ROUTINES WHERE charindex('$', ROUTINE_NAME) > 0 AND substring(ROUTINE_NAME, 1, 3) NOT IN ('dt_', 'sp_')";
//                using (SqlDataReader r = cmd.ExecuteReader())
//                {
//                    while (r.Read()) 
//                    {
//                        routineNames.Add(r.GetString(0));
//                    }
//                }
//                foreach (string routine in routineNames)
//                {
//                    s = new StringBuilder();
//                    cmd = c.CreateCommand();
//                    cmd.CommandType = CommandType.Text;
//                    s.AppendFormat("REVOKE ALL ON {0} FROM public\r\n", routine);
//                    s.AppendFormat("REVOKE ALL ON {0} FROM {1}\r\n", routine, userLogin);
//                    s.AppendFormat("GRANT EXECUTE ON {0} TO {1}", routine, this.RoleName);
//                    cmd.CommandText = s.ToString();
//                    cmd.ExecuteNonQuery();
//                }
//                // Grant admin (db_owner) database access
//                cmd = c.CreateCommand();
//                cmd.CommandType = CommandType.Text;
//                cmd.CommandText = String.Format("EXECUTE sp_grantdbaccess @loginame = '{0}'", adminLogin);
//                cmd.ExecuteNonQuery();
//                // Assign the update login to the db_owner role
//                cmd = c.CreateCommand();
//                cmd.CommandType = CommandType.Text;
//                cmd.CommandText = String.Format("EXECUTE sp_addrolemember 'db_owner', '{0}'", adminLogin);
//                cmd.ExecuteNonQuery();
            }
        }
        /// <summary>
        /// Updates the administrator login in the VaultLedger database
        /// </summary>
        /// <param name="o">
        /// Owner of the catalog (database)
        /// </param>
        /// <param name="dbName">
        /// Name of the VaultLedger database
        /// </param>
        /// <param name="login">
        /// New VaultLedger login for the administrator operator
        /// </param>
        /// <param name="pwd">
        /// Password for the administrator operator
        /// </param>
        private void CreateAdministrator(OwnerDetails o, string login, string pwd)
        {
            // Connect to the database (connect to master and change database)
            using (SqlConnection c = this.Connect())
            {
                // Get a salt value and hash the password with it
                string salt = PwordHasher.CreateSalt(5);
                pwd = PwordHasher.HashPasswordAndSalt(pwd, salt);
                // At this point there should be one operator record in the 
                // database.  So all we have to do is update that record.  We
                // should, as a matter of caution, verify that there is only
                // one operator in the database, and that its id value is 1.
                SqlCommand cmd = c.CreateCommand();
                cmd.CommandType = CommandType.Text;
                cmd.CommandText = "SELECT count(*) FROM Operator";
                int operatorCount = (int)cmd.ExecuteScalar();
                if (operatorCount != 1) 
                {
                    throw new ApplicationException(operatorCount.ToString() + " operators found in database.");
                }
                else
                {
                    cmd = c.CreateCommand();
                    cmd.CommandType = CommandType.Text;
                    cmd.CommandText = "SELECT min(OperatorId) FROM Operator";
                    int operatorId = (int)cmd.ExecuteScalar();
                    if (operatorId != 1) 
                        throw new ApplicationException("Single operator found in database with id: " + operatorId.ToString() + ".");
                }
                // Begin a transaction
                SqlTransaction sqlTran = c.BeginTransaction();
                // Update the operator
                try
                {
                    // Insert the spid login for auditing to avoid error
                    cmd = c.CreateCommand();
                    cmd.CommandType = CommandType.StoredProcedure;
                    cmd.CommandText = "spidLogin$ins";
                    cmd.Parameters.Add("@login", "System");
                    cmd.Parameters.Add("@newTag", String.Empty);
                    cmd.Parameters.Add("@oldTag", SqlDbType.NVarChar, 1000);
                    cmd.Parameters["@oldTag"].Direction = ParameterDirection.Output;
                    cmd.Transaction = sqlTran;
                    cmd.ExecuteNonQuery();
                    // Since we're logged in as system admin, we can use SQL 
                    // statements instead of going through sprocs to do the update.
                    cmd = c.CreateCommand();
                    cmd.CommandType = CommandType.Text;
                    cmd.CommandText = String.Format("UPDATE Operator SET OperatorName = '{0}', Login = '{1}', Password = '{2}', Salt = '{3}', PhoneNo = '{4}', Email = '{5}'", o.Contact, login, pwd, salt, o.PhoneNo, o.Email);
                    cmd.Transaction = sqlTran;
                    cmd.ExecuteNonQuery();
                    // Delete the spid login
                    cmd = c.CreateCommand();
                    cmd.CommandType = CommandType.StoredProcedure;
                    cmd.CommandText = "spidLogin$del";
                    cmd.Parameters.Add("@login", "System");
                    cmd.Transaction = sqlTran;
                    cmd.ExecuteNonQuery();
                    // Commit
                    sqlTran.Commit();
                }
                catch (Exception e)
                {
                    sqlTran.Rollback();
                    throw new ApplicationException("Error encountered while updating administrator: " + e.Message);
                }
            }
        }

        /// <summary>
        /// Inserts the subscription number into the database
        /// </summary>
        /// <param name="o">
        /// Owner of the catalog (database)
        /// </param>
        /// <param name="dbName">
        /// Name of the VaultLedger database
        /// </param>
        /// <param name="login">
        /// New VaultLedger login for the administrator operator
        /// </param>
        /// <param name="pwd">
        /// Password for the administrator operator
        /// </param>
        private void InsertSubscription(OwnerDetails o)
        {
            try
            {
                using (SqlConnection c = this.Connect())
                {
                    SqlCommand cmd = c.CreateCommand();
                    cmd.CommandType = CommandType.Text;
                    cmd.CommandText = String.Format("INSERT Subscription (Number) VALUES ('{0}')", o.Subscription);
                    cmd.ExecuteNonQuery();
                }
            }
            catch (Exception e)
            {
                throw new ApplicationException("Error encountered while inserting subscription: " + e.Message);
            }
        }
    }
}
