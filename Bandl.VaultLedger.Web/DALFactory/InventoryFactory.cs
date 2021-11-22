using System;
using System.Reflection;
using Bandl.Library.VaultLedger.IDAL;

namespace Bandl.Library.VaultLedger.DALFactory
{
    /// <summary>
    /// Factory implementation for the inventory DAL object
    /// </summary>
    public class InventoryFactory : Factory
    {
        // At this point we will only be using the SQLServer provider,
        // so we really don't need a factory.  It is used just in case we
        // ever decide to support another database management system.
        public static IInventory Create()
        {	
            return (IInventory) Assembly.Load(DALName).CreateInstance(DALSpace + ".Inventory");
        }
        // Need a constructor that accepts a connection in case we want to use object
        // in a transaction with another DAL object
        public static IInventory Create(IConnection c)
        {
            object[] obj = {c};
            return (IInventory)Assembly.Load(DALName).CreateInstance(DALSpace + ".Inventory", true, 0, null, obj, null, null);
        }    
    }
}
