using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace Bandl.Utility.VaultLedger.DbUpdater
{
    public class AsyncHelper
    {
        private Boolean _complete = false;
        private Object _value = null;   // return value
        private Exception _exception = null;
        private SqlServer _sql = null;

        #region P U B L I C   P R O P E R T I E S
        public Boolean Complete
        {
            get { return this._complete; }
        }

        public Object Value
        {
            get { return this._value; }
        }

        public Exception Exception
        {
            get { return this._exception; }
        }
        #endregion

        #region C O N S T R U C T O R S
        public AsyncHelper() { }
        public AsyncHelper(SqlServer s1) { this._sql = s1; }
        #endregion

        public void GetSqlServers()
        {
            try
            {
                this._value = SqlServer.GetSqlServers();
            }
            catch (Exception e)
            {
                this._exception = e;
            }
            finally
            {
                this._complete = true;
            }
        }

        public void GetVaultLedgerDatabases()
        {
            try
            {
                this._value = this._sql.GetVaultLedgerDatabases().ToArray();
            }
            catch (Exception e)
            {
                this._exception = e;
            }
            finally
            {
                this._complete = true;
            }
        }

        public void Update()
        {
            try
            {
                this._sql.Update();
            }
            catch (Exception e)
            {
                this._exception = e;
            }
            finally
            {
                this._complete = true;
            }
        }
    }
}
