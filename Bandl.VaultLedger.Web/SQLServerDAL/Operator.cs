using System;
using System.Data;
using System.Data.SqlClient;
using Bandl.Library.VaultLedger.IDAL;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.Security;
using Bandl.Library.VaultLedger.Exceptions;
using Bandl.Library.VaultLedger.Collections;

namespace Bandl.Library.VaultLedger.SQLServerDAL
{
	/// <summary>
	/// Operator data access object
	/// </summary>
    public class Operator : SQLServer, IOperator
	{
        #region Constructors
        /// <summary>
        /// Default constructor
        /// </summary>
        public Operator() {}
        /// <summary>
        /// Creates a new data layer object that will use the given connection
        /// </summary>
        /// <param name="c">
        /// Connection that object should use when connecting to the database
        /// </param>
        public Operator(IConnection c) : base(c) {}
        /// <summary>
        /// Constructor that will or will not look for a persistent connection before
        /// creating a new one, depending on the value of demandCreate.
        /// </summary>
        /// <param name="demandCreate">
        /// If true, object will create a new connection.  If false, object will first
        /// search for a persistent connection on this thread for this session; if
        /// none is found, then a new connection will be created.
        /// </param>
        public Operator(bool demandCreate) : base(demandCreate) {}

        #endregion

        /// <summary>
        /// Get an operator from the data source based on the unique login
        /// </summary>
        /// <param name="login">Unique identifier for an operator</param>
        /// <returns>Operator information on success, null if operator not found</returns>
        public OperatorDetails GetOperator(string login)
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    SqlParameter[] operatorParms = new SqlParameter[1];
                    operatorParms[0] = BuildParameter("@login", login);
                    using(SqlDataReader r = ExecuteReader(CommandType.StoredProcedure, "operator$getByLogin", operatorParms))
                    {
                        // If no data then return null
                        if(r.HasRows == false) return null;
                        // Move to the first record and create a new instance
                        r.Read(); 
                        return(new OperatorDetails(r));
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
        /// Get an operator from the data source based on the unique id
        /// </summary>
        /// <param name="id">Unique identifier for an operator</param>
        /// <returns>Operator information</returns>
        public OperatorDetails GetOperator(int id)
        {   
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    SqlParameter[] operatorParms = new SqlParameter[1];
                    operatorParms[0] = BuildParameter("@id", id);
                    using(SqlDataReader r = ExecuteReader(CommandType.StoredProcedure, "operator$getById", operatorParms))
                    {
                        // If no data then return null
                        if(r.HasRows == false) return null;
                        // Move to the first record and create a new instance
                        r.Read(); 
                        return(new OperatorDetails(r));
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
        /// Returns the contents of the operator table
        /// </summary>
        /// <returns>Returns the operator information for the operator</returns>
        public OperatorCollection GetOperators()
        {
            using(IConnection dbc = dataBase.Open())
            {
                try
                {
                    using(SqlDataReader r = ExecuteReader(CommandType.StoredProcedure, "operator$getTable"))
                    {
                        return(new OperatorCollection(r));
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
        /// Gets the number of operators in the database
        /// </summary>
        /// <returns>
        /// Number of operators in the database
        /// </returns>
        public int GetOperatorCount()
        {
            using(IConnection dbc = dataBase.Open())
            {
                try
                {
                    return (int)ExecuteScalar(CommandType.StoredProcedure, "operator$getCount");
                }
                catch(SqlException e) 
                {
                    PublishException(e);
                    throw new DatabaseException(StripErrorMsg(e.Message), e);
                }
            }
        }

		/// <summary>
		/// Returns the the accounts for the given operator
		/// </summary>
		/// <returns>Returns the account information</returns>
		public AccountCollection GetAccounts(int id)
		{
			using (IConnection dbc = dataBase.Open())
			{
				try
				{
					SqlParameter[] p1 = new SqlParameter[1];
					p1[0] = BuildParameter("@o1", id);
					using(SqlDataReader r = ExecuteReader(CommandType.StoredProcedure, "operator$accounts", p1))
					{
						return(new AccountCollection(r));
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
		/// Sets the account permissions for a given user
		/// </summary>
		public void SetAccounts(Int32 id, String accounts)
		{
			using(IConnection c1 = dataBase.Open())
			{
				// Create parameters
				SqlParameter[] p = new SqlParameter[2];
				p[0] = BuildParameter("@o1", id);
				p[1] = BuildParameter("@a1", accounts);
				// Execute command
				ExecuteNonQuery(CommandType.StoredProcedure, "operator$account$upd", p);
			}
		}

        /// <summary>
        /// Inserts a new operator into the system
        /// </summary>
        /// <param name="o">Operator details to insert</param>
        public void Insert(OperatorDetails o)
        {
            // Insert the operator into the VaultLedger database
            using(IConnection dbc = dataBase.Open())
            {
                try
                {
                    dbc.BeginTran("insert operator");
                    // Build parameters
                    SqlParameter[] operatorParms = new SqlParameter[9];
                    operatorParms[0] = BuildParameter("@name", o.Name);
                    operatorParms[1] = BuildParameter("@login", o.Login);
                    operatorParms[2] = BuildParameter("@password", o.Password);
                    operatorParms[3] = BuildParameter("@salt", o.Salt);
                    operatorParms[4] = BuildParameter("@role", (int) Enum.Parse(typeof(Role), o.Role));
                    operatorParms[5] = BuildParameter("@phoneNo", o.PhoneNo);
                    operatorParms[6] = BuildParameter("@email", o.Email);
                    operatorParms[7] = BuildParameter("@notes", o.Notes);
                    operatorParms[8] = BuildParameter("@newId", SqlDbType.Int, ParameterDirection.Output);
                    // Insert the new operator
                    ExecuteNonQuery(CommandType.StoredProcedure, "operator$ins", operatorParms);
                    int newId = Convert.ToInt32(operatorParms[8].Value);
                    // Commit the transaction
                    dbc.CommitTran();
                }
                catch(SqlException e)
                {
                    // Rollback the transaction
                    dbc.RollbackTran();
                    // Issue exception
                    if (e.Message.IndexOf("akOperator$Login") != -1)
                    {
                        o.RowError = "An operator with the login '" + o.Login + "' already exists.";
                        throw new DatabaseException(o.RowError, e);
                    }
                    else
                    {
                        PublishException(e);
                        o.RowError = StripErrorMsg(e.Message);
                        throw new DatabaseException(StripErrorMsg(e.Message), e);
                    }
                }
            }
        }

        /// <summary>
        /// Updates an existing operator
        /// </summary>
        /// <param name="o">Operator details to update</param>
        public void Update(OperatorDetails o)
        {
            using(IConnection dbc = dataBase.Open())
            {
                try
                {
                    dbc.BeginTran("update operator");
                    // Build parameters
                    SqlParameter[] operatorParms = new SqlParameter[11];
                    operatorParms[0] = BuildParameter("@id", o.Id);
                    operatorParms[1] = BuildParameter("@name", o.Name);
                    operatorParms[2] = BuildParameter("@login", o.Login);
                    operatorParms[3] = BuildParameter("@password", o.Password);
                    operatorParms[4] = BuildParameter("@salt", o.Salt);
                    operatorParms[5] = BuildParameter("@role", (int) Enum.Parse(typeof(Role), o.Role));
                    operatorParms[6] = BuildParameter("@phoneNo", o.PhoneNo);
                    operatorParms[7] = BuildParameter("@email", o.Email);
                    operatorParms[8] = BuildParameter("@notes", o.Notes);
                    operatorParms[9] = BuildParameter("@lastLogin", o.LastLogin);
                    operatorParms[10] = BuildParameter("@rowVersion", o.RowVersion);
                    // Update the operator
                    ExecuteNonQuery(CommandType.StoredProcedure, "operator$upd", operatorParms);
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
        /// Deletes an existing operator
        /// </summary>
        /// <param name="o">Operator to delete</param>
        public void Delete(OperatorDetails o)
        {
            // Delete the operator
            using(IConnection dbc = dataBase.Open())
            {
                try
                {
                    dbc.BeginTran("delete operator");
                    // Build parameters
                    SqlParameter[] operatorParms = new SqlParameter[2];
                    operatorParms[0] = BuildParameter("@id", o.Id);
                    operatorParms[1] = BuildParameter("@rowVersion", o.RowVersion);
                    // Delete the operator
                    ExecuteNonQuery(CommandType.StoredProcedure, "operator$del", operatorParms);
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
        /// Gets a Recall service ticket associated with an operator
        /// </summary>
        /// <param name="login">Unique identifier for an operator</param>
        /// <returns>Recall service authentication ticket</returns>
        public Guid GetRecallTicket(string login)
        {
            using(IConnection dbc = dataBase.Open())
            {
                try
                {
                    SqlParameter[] ticketParms = new SqlParameter[1];
                    ticketParms[0] = BuildParameter("@login", login);
                    object returnObject = ExecuteScalar(CommandType.StoredProcedure, "recallTicket$get", ticketParms);
                    if(returnObject != null)
                        return (Guid)returnObject;
                    else
                        return Guid.Empty;
                }
                catch(Exception e) 
                {
                    PublishException(e);
                    throw new DatabaseException(StripErrorMsg(e.Message), e);
                }
            }
        }

        /// <summary>
        /// Inserts a new recall ticket
        /// </summary>
        /// <param name="login">Unique identifier for an operator</param>
        /// <param name="ticket">Recall service authentication ticket</param>
        public void InsertRecallTicket(string login, Guid ticket)
        {
            using(IConnection dbc = dataBase.Open())
            {
                try
                {
                    dbc.BeginTran("insert web service authenication ticket");
                    // Build parameters
                    SqlParameter[] ticketParms = new SqlParameter[2];
                    ticketParms[0] = BuildParameter("@login", login);
                    ticketParms[1] = BuildParameter("@ticket", ticket);
                    ExecuteNonQuery(CommandType.StoredProcedure, "recallTicket$ins", ticketParms);
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
        /// Deletes a Recall service ticket
        /// </summary>
        /// <param name="login">Unique identifier for an operator</param>
        public void DeleteRecallTicket(string login)
        {
            using(IConnection dbc = dataBase.Open())
            {
                try
                {
                    dbc.BeginTran("insert web service authenication ticket");
                    // Build parameters
                    SqlParameter[] ticketParms = new SqlParameter[1];
                    ticketParms[0] = BuildParameter("@login", login);
                    ExecuteNonQuery(CommandType.StoredProcedure, "recallTicket$del", ticketParms);
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
	}
}
