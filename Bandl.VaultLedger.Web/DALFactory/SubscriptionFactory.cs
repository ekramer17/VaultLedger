using System;
using System.Reflection;
using Bandl.Library.VaultLedger.IDAL;

namespace Bandl.Library.VaultLedger.DALFactory
{
	/// <summary>
	/// Summary description for SubscriptionFactory.
	/// </summary>
	public class SubscriptionFactory : Factory
	{
        // At this point we will only be using the SQLServer provider,
        // so we really don't need a factory.  It is used just in case we
        // ever decide to support another database management system.
        public static ISubscription Create()
        {	
            return (ISubscription) Assembly.Load(DALName).CreateInstance(DALSpace + ".Subscription");
        }

        // Need a constructor that accepts a connection in case we want to use object
        // in a transaction with another DAL object
        public static ISubscription Create(IConnection c)
        {
            object[] obj = {c};
            return (ISubscription)Assembly.Load(DALName).CreateInstance(DALSpace + ".Subscription", true, 0, null, obj, null, null);
        }
    }
}
