using System;
using System.Data;
using System.Collections;
using System.Configuration;
using System.Data.SqlClient;
using Bandl.Utility.VaultLedger.Registrar.Model;

namespace Bandl.Utility.VaultLedger.Registrar.SQLServer
{
	/// <summary>
	/// The registrar (i.e. hosting) database.  Keeps track of which logins
	/// correspond to which VaultLedger system databases.
	/// </summary>
	public class RouterDb
	{
        public RouterDb() {}

        /// <summary>
        /// Connects to the registrar database
        /// </summary>
        /// <returns>
        /// SqlConnection object
        /// </returns>
        private SqlConnection Connect()
        {
            try
            {
                SqlConnection c = new SqlConnection();
                c.ConnectionString = Configurator.RouterDbConnectString;
                c.Open();
                return c;
            }
            catch (Exception e)
            {
                throw new ApplicationException("Error encountered while connecting to router database. " + e.Message, e);
            }
        }

        public CatalogDetails GetCatalog(string catalogName)
        {
            using (SqlConnection c = Connect())
            {
                try
                {
                    SqlCommand cmd = c.CreateCommand();
                    cmd.CommandText = "catalog$getByName";
                    cmd.CommandType = CommandType.StoredProcedure;
                    cmd.Parameters.Add("@catalogName", catalogName);
                    using (SqlDataReader r = cmd.ExecuteReader(CommandBehavior.SingleRow))
                    {
                        if (r.HasRows == false)
                            return null;
                        else
                        {
                            r.Read();
                            return new CatalogDetails(r);
                        }
                    }
                }
                catch (Exception e)
                {
                    throw new ApplicationException(e.Message, e);
                }
            }
        }

        public void InsertCatalog(string catalogName, ServerDetails server, OwnerDetails owner)
        {
            using (SqlConnection c = Connect())
            {
                SqlCommand cmd = c.CreateCommand();
                cmd.CommandType = CommandType.StoredProcedure;
                cmd.CommandText = "catalog$ins";
                cmd.Parameters.Add("@catName", catalogName);
                cmd.Parameters.Add("@ownerId", owner.Id);
                cmd.Parameters.Add("@serverId", server.Id);
                cmd.Parameters.Add("@newId", SqlDbType.Int);
                cmd.Parameters["@newId"].Direction = ParameterDirection.Output;
                cmd.ExecuteNonQuery();
            }
        }

        public OwnerDetails GetOwner(int id)
        {
            using (SqlConnection c = Connect())
            {
                try
                {
                    SqlCommand cmd = c.CreateCommand();
                    cmd.CommandText = "owner$getById";
                    cmd.CommandType = CommandType.StoredProcedure;
                    cmd.Parameters.Add("@ownerId", id);
                    using (SqlDataReader r = cmd.ExecuteReader(CommandBehavior.SingleRow))
                    {
                        if (r.HasRows == false)
                            return null;
                        else
                        {
                            r.Read();
                            return new OwnerDetails(r);
                        }
                    }
                }
                catch (Exception e)
                {
                    throw new ApplicationException(e.Message, e);
                }
            }
        }

        public OwnerDetails GetOwner(AccountTypes accountType, string accountNo)
        {
            using (SqlConnection c = Connect())
            {
                try
                {
                    SqlCommand cmd = c.CreateCommand();
                    cmd.CommandText = "owner$getByAccount";
                    cmd.CommandType = CommandType.StoredProcedure;
                    cmd.Parameters.Add("@accountType", (int)accountType);
                    cmd.Parameters.Add("@accountNo", accountNo);
                    using (SqlDataReader r = cmd.ExecuteReader(CommandBehavior.SingleRow))
                    {
                        if (r.HasRows == false)
                            return null;
                        else
                        {
                            r.Read();
                            return new OwnerDetails(r);
                        }
                    }
                }
                catch (Exception e)
                {
                    throw new ApplicationException(e.Message, e);
                }
            }
        }

        public int InsertOwner(OwnerDetails o)
        {
            using (SqlConnection c = Connect())
            {
                SqlCommand cmd = c.CreateCommand();
                cmd.CommandType = CommandType.StoredProcedure;
                cmd.CommandText = "owner$ins";
                cmd.Parameters.Add("@company", o.Company);
                cmd.Parameters.Add("@address1", o.Address1);
                cmd.Parameters.Add("@address2", o.Address2);
                cmd.Parameters.Add("@city", o.City);
                cmd.Parameters.Add("@state", o.State);
                cmd.Parameters.Add("@zipCode", o.ZipCode);
                cmd.Parameters.Add("@country", o.Country);
                cmd.Parameters.Add("@contact", o.Contact);
                cmd.Parameters.Add("@phoneNo", o.PhoneNo);
                cmd.Parameters.Add("@email", o.Email);
                cmd.Parameters.Add("@accountNo", o.AccountNo);
                cmd.Parameters.Add("@accountType", (int)o.AccountType);
                cmd.Parameters.Add("@subscription", o.Subscription);
                cmd.Parameters.Add("@newId", SqlDbType.Int);
                cmd.Parameters["@newId"].Direction = ParameterDirection.Output;
                cmd.ExecuteNonQuery();
                // Return the owner id
                return (int)cmd.Parameters["@newId"].Value;
            }
        }

        public void DeleteOwner(int id)
        {
            using (SqlConnection c = Connect())
            {
                SqlCommand cmd = c.CreateCommand();
                cmd.CommandType = CommandType.StoredProcedure;
                cmd.CommandText = "owner$del";
                cmd.Parameters.Add("@ownerId", id);
                cmd.ExecuteNonQuery();
            }
        }

        #region Server Methods

        public int CreateServer(ServerDetails s)
        {
            string serverName = s.Name;
            // Strip the port name
            if (serverName.IndexOf(",") != -1)
                serverName = serverName.Substring(0, serverName.IndexOf(","));
            // Insert the server
            using (SqlConnection c = Connect())
            {
                try
                {
                    SqlCommand cmd = c.CreateCommand();
                    cmd.CommandText = "server$ins";
                    cmd.CommandType = CommandType.StoredProcedure;
                    cmd.Parameters.Add("@serverName", serverName);
                    cmd.Parameters.Add("@login", s.Operator.Login);
                    cmd.Parameters.Add("@security", s.Operator.Trusted ? 0 : 1);
                    cmd.Parameters.Add("@password", s.Operator.Password);
                    cmd.Parameters.Add("@pwdVector", s.Operator.PwdVector);
                    cmd.Parameters.Add("@xlogin", String.Empty); //s.Updater.Login);
                    cmd.Parameters.Add("@xsecurity", String.Empty); //s.Updater.Trusted ? 0 : 1);
                    cmd.Parameters.Add("@xpassword", String.Empty); //s.Updater.Password);
                    cmd.Parameters.Add("@xpwdVector", String.Empty); //s.Updater.PwdVector);
                    cmd.Parameters.Add("@newId", SqlDbType.Int);
                    cmd.Parameters["@newId"].Direction = ParameterDirection.Output;
                    cmd.ExecuteNonQuery();
                    // return the new id
                    return Convert.ToInt32(cmd.Parameters["@newId"].Value);
                }
                catch (Exception e)
                {
                    throw new ApplicationException(e.Message, e);
                }
            }
        }

        public void DeleteServer(int id)
        {
            using (SqlConnection c = Connect())
            {
                try
                {
                    SqlCommand cmd = c.CreateCommand();
                    cmd.CommandText = "server$del";
                    cmd.CommandType = CommandType.StoredProcedure;
                    cmd.Parameters.Add("@serverId", id);
                    cmd.ExecuteNonQuery();
                }
                catch (Exception e)
                {
                    throw new ApplicationException(e.Message, e);
                }
            }
        }

        public ServerDetails GetServer(string serverName)
        {
            // Strip the port name
            if (serverName.IndexOf(",") != -1)
                serverName = serverName.Substring(0, serverName.IndexOf(","));
            // Connect to find the server
            using (SqlConnection c = Connect())
            {
                try
                {
                    SqlCommand cmd = c.CreateCommand();
                    cmd.CommandText = "server$getByName";
                    cmd.CommandType = CommandType.StoredProcedure;
                    cmd.Parameters.Add("@serverName", serverName);
                    using (SqlDataReader r = cmd.ExecuteReader(CommandBehavior.SingleRow))
                    {
                        if (r.HasRows == false)
                        {
                            return null;
                        }
                        else
                        {
                            r.Read();
                            return new ServerDetails(r);
                        }
                    }
                }
                catch (Exception e)
                {
                    throw new ApplicationException(e.Message, e);
                }
            }
        }

        #endregion

        #region Login Methods

        public LoginDetails GetLogin(string login)
        {
            using (SqlConnection c = Connect())
            {
                try
                {
                    SqlCommand cmd = c.CreateCommand();
                    cmd.CommandText = "login$getByName";
                    cmd.CommandType = CommandType.StoredProcedure;
                    cmd.Parameters.Add("@loginName", login);
                    using (SqlDataReader r = cmd.ExecuteReader(CommandBehavior.SingleRow))
                    {
                        if (r.HasRows == false)
                        {
                            return null;
                        }
                        else
                        {
                            r.Read();
                            return new LoginDetails(r);
                        }
                    }
                }
                catch (Exception e)
                {
                    throw new ApplicationException(e.Message, e);
                }
            }
        }

        public void InsertLogin(CatalogDetails catalog, string login)
        {
            using (SqlConnection c = Connect())
            {

                try
                {
                    SqlCommand cmd = c.CreateCommand();
                    cmd.CommandText = "login$ins";
                    cmd.CommandType = CommandType.StoredProcedure;
                    cmd.Parameters.Add("@loginName", login);
                    cmd.Parameters.Add("@catalogId", catalog.Id);
                    cmd.Parameters.Add("@newId", SqlDbType.Int);
                    cmd.Parameters["@newId"].Direction = ParameterDirection.Output;
                    cmd.ExecuteNonQuery();
                }
                catch (Exception e)
                {
                    throw new ApplicationException(e.Message, e);
                }
            }
        }

        public void DeleteLogin(int id)
        {
            using (SqlConnection c = Connect())
            {
                try
                {
                    SqlCommand cmd = c.CreateCommand();
                    cmd.CommandText = "login$del";
                    cmd.CommandType = CommandType.StoredProcedure;
                    cmd.Parameters.Add("@loginId", id);
                    cmd.ExecuteNonQuery();
                }
                catch (Exception e)
                {
                    throw new ApplicationException(e.Message, e);
                }
            }
        }

        #endregion
	}
}