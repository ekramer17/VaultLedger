using System;
using System.Reflection;
using Bandl.Library.VaultLedger.IDAL;

namespace Bandl.Library.VaultLedger.DALFactory
{
    /// <summary>
    /// Factory implementation for the Operator DAL object
    /// </summary>
    public class OperatorFactory : Factory
	{
        // At this point we will only be using the SQLServer provider,
        // so we really don't need a factory.  It is used just in case we
        // ever decide to support another database management system.
        public static IOperator Create()
        {	
            return (IOperator) Assembly.Load(DALName).CreateInstance(DALSpace + ".Operator");
        }
        // Need a constructor that accepts a connection in case we want to use object
        // in a transaction with another DAL object
        public static IOperator Create(IConnection c)
        {
            object[] obj = {c};
            return (IOperator)Assembly.Load(DALName).CreateInstance(DALSpace + ".Operator", true, 0, null, obj, null, null);
        }
    }
}
