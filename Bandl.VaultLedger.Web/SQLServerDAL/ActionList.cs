using System;
using System.Text;
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
	/// Summary description for ListPurge.
	/// </summary>
	public class ActionList : SQLServer, IActionList
	{
        #region Constructors
        /// <summary>
        /// Default constructor
        /// </summary>
        public ActionList() {}
        /// <summary>
        /// Creates a new data layer object that will use the given connection
        /// </summary>
        /// <param name="c">
        /// Connection that object should use when connecting to the database
        /// </param>
        public ActionList(IConnection c) : base(c) {}
        /// <summary>
        /// Constructor that will or will not look for a persistent connection before
        /// creating a new one, depending on the value of demandCreate.
        /// </summary>
        /// <param name="demandCreate">
        /// If true, object will create a new connection.  If false, object will first
        /// search for a persistent connection on this thread for this session; if
        /// none is found, then a new connection will be created.
        /// </param>
        public ActionList(bool demandCreate) : base(demandCreate) {}

        #endregion

        /// <summary>
        /// Purges lists created before the given date
        /// </summary>
        /// <param name="listTypes">
        /// Types of lists to purge
        /// </param>
        /// <param name="cleanDate">
        /// Create date prior to which to purge lists
        /// </param>
        public void PurgeLists(ListTypes listTypes, DateTime cleanDate)
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    dbc.BeginTran("purge lists");
                    SqlParameter[] cleanParms = new SqlParameter[2];
                    cleanParms[0] = BuildParameter("@listType", (int)listTypes);
                    cleanParms[1] = BuildParameter("@cleanDate", cleanDate);
                    ExecuteNonQuery(CommandType.StoredProcedure, "lists$purgeCleared", cleanParms);
                    dbc.CommitTran();
                }
                catch(SqlException e)
                {
                    dbc.RollbackTran();
                    PublishException(e);
                    throw new DatabaseException(StripErrorMsg(e.Message), e);
                }
            }
        }

        /// <summary>
        /// Gets the set of list purge parameters from the database
        /// </summary>
        /// <returns>
        /// Collection of ListPurgeDetails objects
        /// </returns>
        public ListPurgeCollection GetPurgeParameters()
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    using (SqlDataReader r = ExecuteReader(CommandType.StoredProcedure, "listPurgeDetail$getTable"))
                    {
                        return new ListPurgeCollection(r);
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
        /// Gets the list purge parameters from the database for a particular type of list
        /// </summary>
        /// <returns>
        /// ListPurgeDetails object
        /// </returns>
        public ListPurgeDetails GetPurgeParameters(ListTypes listType)
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    SqlParameter[] listParms = new SqlParameter[1];
                    listParms[0] = BuildParameter("@listType", (int)listType);
                    using (SqlDataReader r = ExecuteReader(CommandType.StoredProcedure, "listPurgeDetail$get", listParms))
                    {
                        if (!r.HasRows)
                        {
                            return null;
                        }
                        else
                        {
                            r.Read();
                            return new ListPurgeDetails(r);
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
        /// Updates list purge parameters
        /// </summary>
        public void UpdatePurgeParameters(ListPurgeDetails listPurge)
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    dbc.BeginTran("update list purge detail");
                    // Update the expiration
                    SqlParameter[] updateParms = new SqlParameter[4];
                    updateParms[0] = BuildParameter("@listType", (int)listPurge.ListType);
                    updateParms[1] = BuildParameter("@archive", listPurge.Archive);
                    updateParms[2] = BuildParameter("@days", listPurge.Days);
                    updateParms[3] = BuildParameter("@rowVersion", listPurge.RowVersion);
                    ExecuteNonQuery(CommandType.StoredProcedure, "listPurgeDetail$upd", updateParms);
                    // Commit the transaction
                    dbc.CommitTran();
                }
                catch(SqlException e)
                {
                    dbc.RollbackTran();
                    PublishException(e);
                    throw new DatabaseException(StripErrorMsg(e.Message), e);
                }
            }
        }

        /// <summary>
        /// Gets the list file number for DataSafe.  We're going to do some monkeying here so that we don't have to
        /// make any alterations to the database.  The character actually represents a number, and the listtype is actually a date.
        /// </summary>
        public Int32 GetListFileNumber(Vendors vendor)
        {
            if (vendor != Vendors.DataSafe)
            {
                throw new ApplicationException("Improper call to GetListFileNumber");
            }

            using (IConnection c = dataBase.Open())
            {
                try
                {

                    Char c1 = 'A';
                    String q1 = String.Format("SELECT LISTTYPE, CHARACTER FROM LISTFILECHARACTER WHERE VENDOR = {0}", (Int32)vendor);

                    using (SqlDataReader r = ExecuteReader(CommandType.Text, q1))
                    {
                        if (r.HasRows == true)
                        {
                            r.Read();
                            // Date?
                            Int32 i1 = r.GetInt32(0);
                            // Character?
                            c1 = i1 != Int32.Parse(DateTime.Now.ToString("yyyyMMdd")) ? 'A' : r.GetString(1)[0];
                        }
                    }

                    // Decode character
                    if (c1 >= 'A' && c1 <= 'Z')
                    {
                        return c1 - 'A' + 1;
                    }
                    else if (c1 >= 'a' && c1 <= 'z')
                    {
                        return c1 - 'a' + 27;
                    }
                    else if (c1 >= '0' && c1 <= '9')
                    {
                        return c1 - '0' + 53;
                    }
                    else
                    {
                        throw new ApplicationException("Maximum Datasafe file number reached (63)");
                    }
                }
                catch (SqlException e)
                {
                    PublishException(e);
                    throw new DatabaseException(StripErrorMsg(e.Message), e);
                }
            }
        }
        
        /// <summary>
        /// Sets the list file number for DataSafe
        /// </summary>
        public void SetListFileNumber(Vendors vendor, Int32 i1)
        {
            if (vendor != Vendors.DataSafe)
            {
                throw new ApplicationException("Improper call to SetListFileNumber");
            }

            Char c1 = 'A';
            Int32 x1 = Int32.Parse(DateTime.Now.ToString("yyyyMMdd"));
            // Character?
            if (i1 < 27)
            {
                c1 = (Char)('A' + i1 - 1);
            }
            else if (i1 < 53)
            {
                c1 = (Char)('a' + i1 - 1);
            }
            else if (i1 < 63)
            {
                c1 = (Char)('0' + i1 - 1);
            }
            else
            {
                throw new ApplicationException("Maximum Datasafe file number reached (63)");
            }

            using (IConnection c = dataBase.Open())
            {
                try
                {
                    c.BeginTran();
                    
                    StringBuilder q1 = new StringBuilder();
                    q1.AppendFormat("IF EXISTS (SELECT * FROM LISTFILECHARACTER WHERE VENDOR = {0})\n", (Int32)vendor);
                    q1.AppendFormat("   UPDATE LISTFILECHARACTER SET LISTTYPE = @x1, CHARACTER = @c1 WHERE VENDOR = {0}\n", (Int32)vendor);
                    q1.AppendFormat("ELSE\n");
                    q1.AppendFormat("   INSERT LISTFILECHARACTER (LISTTYPE, CHARACTER, VENDOR) VALUES (@x1, @c1, {0})\n", (Int32)vendor);

                    SqlParameter[] p = new SqlParameter[2];
                    p[0] = BuildParameter("@x1", x1);
                    p[1] = BuildParameter("@c1", c1.ToString());
                    ExecuteNonQuery(CommandType.Text, q1.ToString(), p);

                    c.CommitTran();
                }
                catch (SqlException e)
                {
                    c.RollbackTran();
                    PublishException(e);
                    throw new DatabaseException(StripErrorMsg(e.Message), e);
                }
            }
        }
        
        /// <summary>
        /// Gets a list file character
        /// </summary>
        public string GetListFileChar(ListTypes listType, Vendors vendor)
        {
            if (vendor == Vendors.DataSafe)
            {
                throw new ApplicationException("Improper call to GetListFileChar for vendor DataSafe");
            }
            else
            {
                using (IConnection c = dataBase.Open())
                {
                    try
                    {
                        SqlParameter[] p = new SqlParameter[2];
                        p[0] = BuildParameter("@listType", (int)listType);
                        p[1] = BuildParameter("@vendor", (int)vendor);
                        using (SqlDataReader r = ExecuteReader(CommandType.StoredProcedure, "listFileCharacter$get", p))
                        {
                            if (r.HasRows == false)
                            {
                                return "A";
                            }
                            else
                            {
                                r.Read();
                                return r.GetString(0);
                            }
                        }
                    }
                    catch (SqlException e)
                    {
                        PublishException(e);
                        throw new DatabaseException(StripErrorMsg(e.Message), e);
                    }
                }
            }
        }

        /// <summary>
        /// Updates a list file character
        /// </summary>
        public void UpdateListFileChar(ListTypes listType, Vendors vendor, char ch)
        {
            if (vendor == Vendors.DataSafe)
            {
                throw new ApplicationException("Improper call to GetListFileChar for vendor DataSafe");
            }
            else
            {
                using (IConnection c = dataBase.Open())
                {
                    try
                    {
                        c.BeginTran();
                        SqlParameter[] p = new SqlParameter[3];
                        p[0] = BuildParameter("@listType", (int)listType);
                        p[1] = BuildParameter("@vendor", (int)vendor);
                        p[2] = BuildParameter("@c", ch.ToString());
                        ExecuteNonQuery(CommandType.StoredProcedure, "listFileCharacter$upd", p);
                        c.CommitTran();
                    }
                    catch (SqlException e)
                    {
                        c.RollbackTran();
                        PublishException(e);
                        throw new DatabaseException(StripErrorMsg(e.Message), e);
                    }
                }
            }
        }
    }
}
