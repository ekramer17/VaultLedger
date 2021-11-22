using System;
using System.Reflection;
using Bandl.Library.VaultLedger.IDAL;

namespace Bandl.Library.VaultLedger.DALFactory
{
    /// <summary>
    /// Factory implementation for the Receive List DAL object
    /// </summary>
    public class ReceiveListFactory : Factory
    {
        // At this point we will only be using the SQLServer provider,
        // so we really don't need a factory.  It is used just in case we
        // ever decide to support another database management system.
        public static IReceiveList Create()
        {	
            return (IReceiveList) Assembly.Load(DALName).CreateInstance(DALSpace + ".ReceiveList");
        }

        // Need a constructor that accepts a connection in case we want to use object
        // in a transaction with another DAL object
        public static IReceiveList Create(IConnection c)
        {
            object[] obj = {c};
            return (IReceiveList)Assembly.Load(DALName).CreateInstance(DALSpace + ".ReceiveList", true, 0, null, obj, null, null);
        }
    }
}
