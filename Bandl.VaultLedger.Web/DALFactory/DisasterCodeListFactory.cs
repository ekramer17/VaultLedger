using System;
using System.Reflection;
using Bandl.Library.VaultLedger.IDAL;

namespace Bandl.Library.VaultLedger.DALFactory
{
    /// <summary>
    /// Factory implementation for the Disaster Code List DAL object
    /// </summary>
    public class DisasterCodeListFactory : Factory
    {
        // At this point we will only be using the SQLServer provider,
        // so we really don't need a factory.  It is used just in case we
        // ever decide to support another database management system.
        public static IDisasterCodeList Create()
        {	
            return (IDisasterCodeList) Assembly.Load(DALName).CreateInstance(DALSpace + ".DisasterCodeList");
        }

        // Need a constructor that accepts a connection in case we want to use object
        // in a transaction with another DAL object
        public static IDisasterCodeList Create(IConnection c)
        {
            object[] obj = {c};
            return (IDisasterCodeList)Assembly.Load(DALName).CreateInstance(DALSpace + ".DisasterCodeList", true, 0, null, obj, null, null);
        }
    }
}
