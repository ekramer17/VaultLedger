using System;
using System.Web;
using System.Data;
using System.Text;
using System.Data.SqlTypes;
using System.Data.SqlClient;
using Bandl.Library.VaultLedger.IDAL;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.Security;
using Bandl.Library.VaultLedger.Exceptions;

namespace Bandl.Library.VaultLedger.SQLServerDAL
{
    /// <summary>
	/// Summary description for SQLServer.
	/// </summary>
	public abstract class SQLServer
	{
        protected IConnection dataBase;
        private string systemName = "System";
        private int commandTimeout = Configurator.CommandTimeout;
        
        #region Constructors
        /// <summary>
        /// Default constructor
        /// </summary>
        public SQLServer() : this(false) {}
        /// <summary>
        /// Creates a new data layer object that will use the given connection
        /// </summary>
        /// <param name="c">
        /// Connection that object should use when connecting to the database
        /// </param>
        public SQLServer(IConnection c) 
        {
            dataBase = c;
        }
        /// <summary>
        /// Constructor that will or will not look for a persistent connection before
        /// creating a new one, depending on the value of demandCreate.
        /// </summary>
        /// <param name="demandCreate">
        /// If true, object will create a new connection.  If false, object will first
        /// search for a persistent connection on this thread for this session; if
        /// none is found, then a new connection will be created.
        /// </param>
        public SQLServer(bool demandCreate)
        {
            // Look among the persisted connections for a suitable one.  If none
            // is found, then create a new connection.
            if (demandCreate == true || (dataBase = DataLink.GetPersistedConnection()) == null)
            {
                dataBase = new DataLink();
            }
        }

        #endregion

        protected int CommandTimeout
        {
            get {return commandTimeout;}
            set {if (value >= 0) commandTimeout = value;}
        }

        protected string SystemName
        {
            get {return systemName;}
        }

        protected void PublishException(Exception ex)
        {
            //
        }
        
        protected SqlDateTime StringToDateTime(string date)
        {
            return date != String.Empty ? (SqlDateTime)Date.ParseExact(date) : SqlDateTime.Null;
        }

        protected string StripErrorMsg(string m)
        {
            // Perform any substituion necessary
            m = ErrorStrings.Substitute(m);
            // Strip database error tag if present
            if (m.EndsWith(">") == false || m.LastIndexOf("<") == -1)
                return m;
            else
                return m.Substring(0, m.LastIndexOf("<"));
        }

        #region Parameter building methods
        protected SqlParameter BuildParameter(string parameterName, object value)
        {
            SqlParameter newParameter = new SqlParameter(parameterName, value);
            return newParameter;
        }

        protected SqlParameter BuildParameter(string parameterName, SqlDbType sqlType, ParameterDirection direction, int size)
        {
            SqlParameter newParameter = new SqlParameter(parameterName, sqlType);
            newParameter.Direction = direction;
            newParameter.Size = size;
            return newParameter;
        }

        protected SqlParameter BuildParameter(string parameterName, SqlDbType sqlType, ParameterDirection direction)
        {
            SqlParameter newParameter = new SqlParameter(parameterName, sqlType);
            newParameter.Direction = direction;
            return newParameter;
        }

        protected SqlParameter BuildParameter(string parameterName, object value, SqlDbType sqlType, ParameterDirection direction)
        {
            SqlParameter newParameter = new SqlParameter(parameterName, sqlType);
            newParameter.Direction = direction;
            newParameter.Value = value;
            return newParameter;
        }

        protected SqlParameter BuildParameter(SqlDbType sqlType, ParameterDirection direction)
        {
            SqlParameter newParameter = new SqlParameter();
            newParameter.Direction = direction;
            newParameter.SqlDbType = sqlType;
            return newParameter;
        }

        #endregion

        #region Execute Methods

        private SqlCommand BuildCommand(CommandType commandType, string name, params SqlParameter[] parameterValues)
        {
            SqlCommand cmd = ((SqlConnection)dataBase.Connection).CreateCommand();
            cmd.CommandTimeout = commandTimeout;
            cmd.CommandType = commandType;
            cmd.CommandText = name;
            // Add the parameters
            if (parameterValues != null)
            {
                foreach (SqlParameter p in parameterValues)
                {
                    cmd.Parameters.Add(p);
                }
            }
            // If we have a transaction, attach it
            if (dataBase.NestingLevel != 0) cmd.Transaction = (SqlTransaction)dataBase.Transaction;
            // If the commandType is stored procedure, prepare it
//            if (commandType != CommandType.StoredProcedure) cmd.Prepare();
            // Return the command
            return cmd;
        }

        public object ExecuteScalar(CommandType commandType, string name, SqlParameter[] parameterValues)
        {
            return BuildCommand(commandType, name, parameterValues).ExecuteScalar();
        }

        public object ExecuteScalar(CommandType commandType, string name)
        {
            return BuildCommand(commandType, name, null).ExecuteScalar();
        }

        public void ExecuteNonQuery(CommandType commandType, string name, SqlParameter[] parameterValues)
        {
            BuildCommand(commandType, name, parameterValues).ExecuteNonQuery();
        }

        public void ExecuteNonQuery(CommandType commandType, string name)
        {
            BuildCommand(commandType, name, null).ExecuteNonQuery();
        }

        public SqlDataReader ExecuteReader(CommandType commandType, string name, SqlParameter[] parameterValues)
        {
            return BuildCommand(commandType, name, parameterValues).ExecuteReader();
        }

        public SqlDataReader ExecuteReader(CommandType commandType, string name)
        {
            return BuildCommand(commandType, name, null).ExecuteReader();
        }

        #endregion

    }
}
