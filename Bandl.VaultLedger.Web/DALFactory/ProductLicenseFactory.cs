using System;
using System.Reflection;
using Bandl.Library.VaultLedger.IDAL;

namespace Bandl.Library.VaultLedger.DALFactory
{
    /// <summary>
    /// Factory implementation for the Product License DAL object
    /// </summary>
    public class ProductLicenseFactory : Factory
    {
        // At this point we will only be using the SQLServer provider,
        // so we really don't need a factory.  It is used just in case we
        // ever decide to support another database management system.
        public static IProductLicense Create()
        {	
            return (IProductLicense) Assembly.Load(DALName).CreateInstance(DALSpace + ".ProductLicense");
        }
        // Need a constructor that accepts a connection in case we want to use object
        // in a transaction with another DAL object
        public static IProductLicense Create(IConnection c)
        {
            object[] obj = {c};
            return (IProductLicense)Assembly.Load(DALName).CreateInstance(DALSpace + ".ProductLicense", true, 0, null, obj, null, null);
        }
    }
}
