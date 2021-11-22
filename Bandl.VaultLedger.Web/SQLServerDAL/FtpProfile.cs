using System;
using System.Data;
using System.Collections;
using System.Data.SqlTypes;
using System.Data.SqlClient;
using Bandl.Library.VaultLedger.IDAL;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.Exceptions;
using Bandl.Library.VaultLedger.Collections;

namespace Bandl.Library.VaultLedger.SQLServerDAL
{
	/// <summary>
	/// Summary description for FtpProfile.
	/// </summary>
	public class FtpProfile : SQLServer, IFtpProfile
	{
        #region Get Methods
        /// <summary>
        /// Gets an FTP profile
        /// </summary>
        /// <param name="id">
        /// Id of profile to retrieve
        /// </param>
        public FtpProfileDetails GetProfile(int id)
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    SqlParameter[] ftpParms = new SqlParameter[1];
                    ftpParms[0] = BuildParameter("@id", id);
                    using(SqlDataReader r = ExecuteReader(CommandType.StoredProcedure, "ftpProfile$getById", ftpParms))
                    {
                        if(r.HasRows == false)
                        {
                            return null;
                        }
                        else
                        {
                            r.Read();
                            return new FtpProfileDetails(r);
                        }
                    }
                }
                catch(SqlException e) 
                {
                    PublishException(e);
                    throw new DatabaseException(StripErrorMsg(e.Message), e);
                }
            }
        }

        /// <summary>
        /// Gets an FTP profile
        /// </summary>
        /// <param name="profileName">
        /// Name of profile to retrieve
        /// </param>
        public FtpProfileDetails GetProfile(string profileName)
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    SqlParameter[] ftpParms = new SqlParameter[1];
                    ftpParms[0] = BuildParameter("@profileName", profileName);
                    using(SqlDataReader r = ExecuteReader(CommandType.StoredProcedure, "ftpProfile$getByName", ftpParms))
                    {
                        if(r.HasRows == false)
                        {
                            return null;
                        }
                        else
                        {
                            r.Read();
                            return new FtpProfileDetails(r);
                        }
                    }
                }
                catch(SqlException e) 
                {
                    PublishException(e);
                    throw new DatabaseException(StripErrorMsg(e.Message), e);
                }
            }
        }

		/// <summary>
		/// Gets an FTP profile using an account name
		/// </summary>
		/// <param name="accountName">
		/// Account name whose FTP profile to retrieve
		/// </param>
		public FtpProfileDetails GetProfileByAccount(string accountName)
		{
			using (IConnection dbc = dataBase.Open())
			{
				try
				{
					SqlParameter[] ftpParms = new SqlParameter[1];
					ftpParms[0] = BuildParameter("@accountName", accountName);
					using(SqlDataReader r = ExecuteReader(CommandType.StoredProcedure, "ftpProfile$getByAccount", ftpParms))
					{
						if(r.HasRows == false)
						{
							return null;
						}
						else
						{
							r.Read();
							return new FtpProfileDetails(r);
						}
					}
				}
				catch(SqlException e) 
				{
					PublishException(e);
					throw new DatabaseException(StripErrorMsg(e.Message), e);
				}
			}
		}

        /// <summary>
        /// Gets all the profiles for all the accounts in the system
        /// </summary>
        /// <returns>
        /// All the FTP profiles in the database
        /// </returns>
        public FtpProfileCollection GetProfiles()
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    using(SqlDataReader r = ExecuteReader(CommandType.StoredProcedure, "ftpProfile$getTable"))
                    {
                        if(r.HasRows == false)
                        {
                            return new FtpProfileCollection();
                        }
                        else
                        {
                            return new FtpProfileCollection(r);
                        }
                    }
                }
                catch(SqlException e) 
                {
                    PublishException(e);
                    throw new DatabaseException(StripErrorMsg(e.Message), e);
                }
            }
        }
        #endregion

        /// <summary>
        /// Inserts an FTP profile into the system
        /// </summary>
        /// <param name="ftp">
        /// FTP profile to insert
        /// </param>
        public void Insert(FtpProfileDetails ftp)
        {
            // Delete the operator
            using(IConnection dbc = dataBase.Open())
            {
                try
                {
                    dbc.BeginTran("insert FTP profile");
                    // Build parameters
                    SqlParameter[] ftpParms = new SqlParameter[9];
                    ftpParms[0] = BuildParameter("@name", ftp.Name);
                    ftpParms[1] = BuildParameter("@server", ftp.Server);
                    ftpParms[2] = BuildParameter("@login", ftp.Login);
                    ftpParms[3] = BuildParameter("@password", ftp.EncryptedPassword);
                    ftpParms[4] = BuildParameter("@filePath", ftp.FilePath);
                    ftpParms[5] = BuildParameter("@fileFormat", (short)ftp.Format);
                    ftpParms[6] = BuildParameter("@passive", ftp.Passive);
                    ftpParms[7] = BuildParameter("@secure", ftp.Secure);
                    ftpParms[8] = BuildParameter("@newId", SqlDbType.Int, ParameterDirection.Output);
                    // Insert the new pattern
                    ExecuteNonQuery(CommandType.StoredProcedure, "ftpProfile$ins", ftpParms);
                    // Commit the transaction
                    dbc.CommitTran();
                }
                catch(SqlException e)
                {
                    // Rollback the transaction
                    dbc.RollbackTran();
                    // Issue exception
                    if (e.Message.IndexOf("akFtpProfile$ProfileName") != -1)
                    {
                        ftp.RowError = "An ftp profile with the name '" + ftp.Name + "' already exists.";
                        throw new DatabaseException(ftp.RowError, e);
                    }
                    else
                    {
                        PublishException(e);
                        ftp.RowError = StripErrorMsg(e.Message);
                        throw new DatabaseException(StripErrorMsg(e.Message), e);
                    }
                }
            }
        }
        /// <summary>
        /// Updates an FTP profile
        /// </summary>
        /// <param name="ftp">
        /// FTP profile to update
        /// </param>
        public void Update(FtpProfileDetails ftp)
        {
            // Delete the operator
            using(IConnection dbc = dataBase.Open())
            {
                try
                {
                    dbc.BeginTran("update FTP profile");
                    // Build parameters
                    SqlParameter[] ftpParms = new SqlParameter[10];
                    ftpParms[0] = BuildParameter("@id", ftp.Id);
                    ftpParms[1] = BuildParameter("@name", ftp.Name);
                    ftpParms[2] = BuildParameter("@server", ftp.Server);
                    ftpParms[3] = BuildParameter("@login", ftp.Login);
                    ftpParms[4] = BuildParameter("@password", ftp.EncryptedPassword);
                    ftpParms[5] = BuildParameter("@filePath", ftp.FilePath);
                    ftpParms[6] = BuildParameter("@fileFormat", (short)ftp.Format);
                    ftpParms[7] = BuildParameter("@passive", ftp.Passive);
                    ftpParms[8] = BuildParameter("@secure", ftp.Secure);
                    ftpParms[9] = BuildParameter("@rowVersion", ftp.RowVersion);
                    // Insert the new pattern
                    ExecuteNonQuery(CommandType.StoredProcedure, "ftpProfile$upd", ftpParms);
                    // Commit the transaction
                    dbc.CommitTran();
                }
                catch(SqlException e)
                {
                    dbc.RollbackTran();
                    PublishException(e);
                    // Throw exception
                    throw new DatabaseException(StripErrorMsg(e.Message), e);
                }
            }
        }

        /// <summary>
        /// Deletes an FTP profile from the system
        /// </summary>
        /// <param name="ftp">
        /// FTP profile to delete
        /// </param>
        public void Delete(FtpProfileDetails ftp)
        {
            // Delete the operator
            using(IConnection dbc = dataBase.Open())
            {
                try
                {
                    dbc.BeginTran("delete FTP profile");
                    // Build parameters
                    SqlParameter[] ftpParms = new SqlParameter[2];
                    ftpParms[0] = BuildParameter("@id", ftp.Id);
                    ftpParms[1] = BuildParameter("@rowVersion", ftp.RowVersion);
                    // Delete the operator
                    ExecuteNonQuery(CommandType.StoredProcedure, "ftpProfile$del", ftpParms);
                    // Commit the transaction
                    dbc.CommitTran();
                }
                catch(SqlException e)
                {
                    dbc.RollbackTran();
                    PublishException(e);
                    // Throw exception
                    throw new DatabaseException(StripErrorMsg(e.Message), e);
                }
            }
        }
        /// <summary>
        /// Gets the recall next list numbers
        /// </summary>
        /// <param name="accountName">Account name</param>
        /// <param name="sendNo">Send list number</param>
        /// <param name="receiveNo">Receive list number</param>
        /// <param name="disasterNo">Disaster list number</param>
        public void GetRecallNumbers(string accountName, out int sendNo, out int receiveNo, out int disasterNo)
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    SqlParameter[] p = new SqlParameter[1];
                    p[0] = BuildParameter("@accountName", accountName);
                    using(SqlDataReader r = ExecuteReader(CommandType.StoredProcedure, "ftpRecall$get", p))
                    {
                        if(r.HasRows == false)
                        {
                            sendNo = receiveNo = disasterNo = 0;
                        }
                        else
                        {
                            r.Read();
                            sendNo = r.GetInt32(0);
                            receiveNo = r.GetInt32(1);
                            disasterNo = r.GetInt32(2);
                        }
                    }
                }
                catch(SqlException e) 
                {
                    PublishException(e);
                    throw new DatabaseException(StripErrorMsg(e.Message), e);
                }
            }
        }
        /// <summary>
        /// Sets the recall next list numbers
        /// </summary>
        /// <param name="accountName">Account name</param>
        /// <param name="sendNo">Send list number</param>
        /// <param name="receiveNo">Receive list number</param>
        /// <param name="disasterNo">Disaster list number</param>
        public void SetRecallNumbers(string accountName, int sendNo, int receiveNo, int disasterNo)
        {
            using(IConnection dbc = dataBase.Open())
            {
                try
                {
                    dbc.BeginTran("");
                    // Build parameters
                    SqlParameter[] p = new SqlParameter[4];
                    p[0] = BuildParameter("@accountName", accountName);
                    p[1] = BuildParameter("@sendNo", sendNo);
                    p[2] = BuildParameter("@receiveNo", receiveNo);
                    p[3] = BuildParameter("@disasterNo", disasterNo);
                    // Insert the new pattern
                    ExecuteNonQuery(CommandType.StoredProcedure, "ftpRecall$ins", p);
                    // Commit the transaction
                    dbc.CommitTran();
                }
                catch(SqlException e)
                {
                    dbc.RollbackTran();
                    PublishException(e);
                    // Throw exception
                    throw new DatabaseException(StripErrorMsg(e.Message), e);
                }
            }
        }
    }
}
