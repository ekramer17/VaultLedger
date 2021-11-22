using System;
using System.Data;
using System.Data.SqlClient;
using Bandl.Library.VaultLedger.IDAL;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.Exceptions;
using Bandl.Library.VaultLedger.Collections;

namespace Bandl.Library.VaultLedger.SQLServerDAL
{
    /// <summary>
    /// Medium type data access object
    /// </summary>
    public class EmailGroup : SQLServer, IEmailGroup
    {
        #region Constructors
        /// <summary>
        /// Default constructor
        /// </summary>
        public EmailGroup() {}
        /// <summary>
        /// Creates a new data layer object that will use the given connection
        /// </summary>
        /// <param name="c">
        /// Connection that object should use when connecting to the database
        /// </param>
        public EmailGroup(IConnection c) : base(c) {}
        /// <summary>
        /// Constructor that will or will not look for a persistent connection before
        /// creating a new one, depending on the value of demandCreate.
        /// </summary>
        /// <param name="demandCreate">
        /// If true, object will create a new connection.  If false, object will first
        /// search for a persistent connection on this thread for this session; if
        /// none is found, then a new connection will be created.
        /// </param>
        public EmailGroup(bool demandCreate) : base(demandCreate) {}

        #endregion

        /// <summary>
        /// Gets the email groups in the database
        /// </summary>
        /// <returns>
        /// Email groups
        /// </returns>
        public EmailGroupDetails GetEmailGroup(int id)
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    SqlParameter[] p = new SqlParameter[1];
                    p[0] = BuildParameter("@groupId", id);
                    using(SqlDataReader r = ExecuteReader(CommandType.StoredProcedure, "emailGroup$getById", p))
                    {
                        if (r.HasRows == false)
                            return null;
                        else
                        {
                            r.Read();
                            return new EmailGroupDetails(r);
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
        /// Gets the email groups in the database
        /// </summary>
        /// <returns>
        /// Email groups
        /// </returns>
        public EmailGroupDetails GetEmailGroup(string name)
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    SqlParameter[] p = new SqlParameter[1];
                    p[0] = BuildParameter("@groupName", name);
                    using(SqlDataReader r = ExecuteReader(CommandType.StoredProcedure, "emailGroup$getByName", p))
                    {
                        if (r.HasRows == false)
                            return null;
                        else
                        {
                            r.Read();
                            return new EmailGroupDetails(r);
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
        /// Gets the email groups in the database
        /// </summary>
        /// <returns>
        /// Email groups
        /// </returns>
        public EmailGroupCollection GetEmailGroups()
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    using(SqlDataReader r = ExecuteReader(CommandType.StoredProcedure, "emailGroup$getTable"))
                    {
                        return new EmailGroupCollection(r);
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
        /// Gets the operatrors in an email group
        /// </summary>
        /// <returns>
        /// Operator collection
        /// </returns>
        public OperatorCollection GetOperators(int groupId)
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    SqlParameter[] p = new SqlParameter[1];
                    p[0] = BuildParameter("@groupId", groupId);
                    using(SqlDataReader r = ExecuteReader(CommandType.StoredProcedure, "emailGroup$getOperators", p))
                    {
                        return new OperatorCollection(r);
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
        /// Deletes an existing email group
        /// </summary>
        /// <param name="e">Email group to delete</param>
        public void Delete(EmailGroupDetails e)
        {
            // Delete the operator
            using(IConnection dbc = dataBase.Open())
            {
                try
                {
                    dbc.BeginTran("delete email group");
                    // Build parameters
                    SqlParameter[] p = new SqlParameter[1];
                    p[0] = BuildParameter("@groupId", e.Id);
                    // Delete the operator
                    ExecuteNonQuery(CommandType.StoredProcedure, "emailGroup$del", p);
                    // Commit the transaction
                    dbc.CommitTran();
                }
                catch(SqlException ex)
                {
                    dbc.RollbackTran();
                    PublishException(ex);
                    // Throw exception
                    throw new DatabaseException(StripErrorMsg(ex.Message), ex);
                }
            }
        }

        /// <summary>
        /// Creates a new email group
        /// </summary>
        /// <param name="e">
        /// Email group to create
        /// </param>
        /// <param name="o">
        /// Operators to add
        /// </param>
        public void Create(EmailGroupDetails e, OperatorCollection o)
        {
            using(IConnection c = dataBase.Open())
            {
                try
                {
                    c.BeginTran("create email group");
                    // Build parameters
                    SqlParameter[] p = new SqlParameter[2];
                    p[0] = BuildParameter("@groupName", e.Name);
                    p[1] = BuildParameter("@newId", SqlDbType.Int, ParameterDirection.Output);
                    // Insert the group
                    ExecuteNonQuery(CommandType.StoredProcedure, "emailGroup$ins", p);
                    // Get the new email group
                    EmailGroupDetails x = GetEmailGroup(Convert.ToInt32(p[1].Value));
                    // Insert the operators
                    for (int i = 0; i < o.Count; i++)
                        InsertOperator(x, o[i]);
                    // Commit the transaction
                    c.CommitTran();
                }
                catch(SqlException ex)
                {
                    c.RollbackTran();
                    PublishException(ex);
                    // Throw exception
                    throw new DatabaseException(StripErrorMsg(ex.Message), ex);
                }
            }
        }

        /// <summary>
        /// Inserts an operator into an email group
        /// </summary>
        /// <param name="e">
        /// Email group to which to add operator
        /// </param>
        /// <param name="o">
        /// Operator to add
        /// </param>
        public void InsertOperator(EmailGroupDetails e, OperatorDetails o)
        {
            // Delete the operator
            using(IConnection dbc = dataBase.Open())
            {
                try
                {
                    dbc.BeginTran("insert email group operator");
                    // Build parameters
                    SqlParameter[] p = new SqlParameter[2];
                    p[0] = BuildParameter("@groupId", e.Id);
                    p[1] = BuildParameter("@operatorId", o.Id);
                    // Delete the operator
                    ExecuteNonQuery(CommandType.StoredProcedure, "emailGroupOperator$ins", p);
                    // Commit the transaction
                    dbc.CommitTran();
                }
                catch(SqlException ex)
                {
                    dbc.RollbackTran();
                    PublishException(ex);
                    // Throw exception
                    throw new DatabaseException(StripErrorMsg(ex.Message), ex);
                }
            }
        }

        /// <summary>
        /// Delete an operator from an email group
        /// </summary>
        /// <param name="e">
        /// Email group from which to delete operator
        /// </param>
        /// <param name="o">
        /// Operator to delete
        /// </param>
        public void DeleteOperator(EmailGroupDetails e, OperatorDetails o)
        {
            // Delete the operator
            using(IConnection dbc = dataBase.Open())
            {
                try
                {
                    dbc.BeginTran("delete email group operator");
                    // Build parameters
                    SqlParameter[] p = new SqlParameter[2];
                    p[0] = BuildParameter("@groupId", e.Id);
                    p[1] = BuildParameter("@operatorId", o.Id);
                    // Delete the operator
                    ExecuteNonQuery(CommandType.StoredProcedure, "emailGroupOperator$del", p);
                    // Commit the transaction
                    dbc.CommitTran();
                }
                catch(SqlException ex)
                {
                    dbc.RollbackTran();
                    PublishException(ex);
                    // Throw exception
                    throw new DatabaseException(StripErrorMsg(ex.Message), ex);
                }
            }
        }
    }
}
