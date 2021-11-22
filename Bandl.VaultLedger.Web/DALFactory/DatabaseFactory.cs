using System;
using System.Reflection;
using Bandl.Library.VaultLedger.IDAL;

namespace Bandl.Library.VaultLedger.DALFactory
{
    /// <summary>
    /// Factory implementation for the Database DAL object
    /// </summary>
    public class DatabaseFactory : Factory
    {
        // At this point we will only be using the SQLServer provider,
        // so we really don't need a factory.  It is used just in case we
        // ever decide to support another database management system.
        public static IDatabase Create()
        {	
            return (IDatabase) Assembly.Load(DALName).CreateInstance(DALSpace + ".Database");
        }

        // Need a constructor that accepts a connection in case we want to use object
        // in a transaction with another DAL object
        public static IDatabase Create(IConnection c)
        {
            object[] obj = {c};
            return (IDatabase)Assembly.Load(DALName).CreateInstance(DALSpace + ".Database", true, 0, null, obj, null, null);
        }
    }
}
