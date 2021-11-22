using System;
using System.Reflection;
using Bandl.Library.VaultLedger.IDAL;

namespace Bandl.Library.VaultLedger.DALFactory
{
    /// <summary>
    /// Factory implementation for the email group DAL object
    /// </summary>
    public class EmailGroupFactory : Factory
    {
        // At this point we will only be using the SQLServer provider,
        // so we really don't need a factory.  It is used just in case we
        // ever decide to support another database management system.
        public static IEmailGroup Create()
        {	
            return (IEmailGroup) Assembly.Load(DALName).CreateInstance(DALSpace + ".EmailGroup");
        }
        // Need a constructor that accepts a connection in case we want to use object
        // in a transaction with another DAL object
        public static IEmailGroup Create(IConnection c)
        {
            object[] obj = {c};
            return (IEmailGroup)Assembly.Load(DALName).CreateInstance(DALSpace + ".EmailGroup", true, 0, null, obj, null, null);
        }
    }
}
