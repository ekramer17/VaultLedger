using System;
using System.Reflection;
using Bandl.Library.VaultLedger.IDAL;

namespace Bandl.Library.VaultLedger.DALFactory
{
    /// <summary>
    /// Summary description for SubscriptionFactory.
    /// </summary>
    public class TabPageDefaultFactory : Factory
    {
        // At this point we will only be using the SQLServer provider,
        // so we really don't need a factory.  It is used just in case we
        // ever decide to support another database management system.
        public static ITabPageDefault Create()
        {	
            return (ITabPageDefault) Assembly.Load(DALName).CreateInstance(DALSpace + ".TabPageDefault");
        }

        // Need a constructor that accepts a connection in case we want to use object
        // in a transaction with another DAL object
        public static ITabPageDefault Create(IConnection c)
        {
            object[] obj = {c};
            return (ITabPageDefault)Assembly.Load(DALName).CreateInstance(DALSpace + ".TabPageDefault", true, 0, null, obj, null, null);
        }
    }
}
