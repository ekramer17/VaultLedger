using System;
using System.Reflection;
using System.Runtime.Remoting;
using Bandl.Library.VaultLedger.IDAL;

namespace Bandl.Library.VaultLedger.DALFactory
{
    /// <summary>
    /// Factory implementation for the Send List DAL object
    /// </summary>
    public class SendListFactory : Factory
    {
        // At this point we will only be using the SQLServer provider,
        // so we really don't need a factory.  It is used just in case we
        // ever decide to support another database management system.
        public static ISendList Create()
        {	
            return (ISendList) Assembly.Load(DALName).CreateInstance(DALSpace + ".SendList");
        }

        // Need a constructor that accepts a connection in case we want to use object
        // in a transaction with another DAL object
        public static ISendList Create(IConnection c)
        {
            object[] obj = {c};
            return (ISendList)Assembly.Load(DALName).CreateInstance(DALSpace + ".SendList", true, 0, null, obj, null, null);
        }
    }
}
