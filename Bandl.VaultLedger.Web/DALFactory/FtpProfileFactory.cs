using System;
using System.Reflection;
using Bandl.Library.VaultLedger.IDAL;

namespace Bandl.Library.VaultLedger.DALFactory
{
    /// <summary>
    /// Factory implementation for the FtpProfile DAL object
    /// </summary>
    public class FtpProfileFactory : Factory
    {
        // At this point we will only be using the SQLServer provider,
        // so we really don't need a factory.  It is used just in case we
        // ever decide to support another database management system.
        public static IFtpProfile Create()
        {	
            return (IFtpProfile) Assembly.Load(DALName).CreateInstance(DALSpace + ".FtpProfile");
        }
        // Need a constructor that accepts a connection in case we want to use object
        // in a transaction with another DAL object
        public static IFtpProfile Create(IConnection c)
        {
            object[] obj = {c};
            return (IFtpProfile)Assembly.Load(DALName).CreateInstance(DALSpace + ".FtpProfile", true, 0, null, obj, null, null);
        }
    }
}
