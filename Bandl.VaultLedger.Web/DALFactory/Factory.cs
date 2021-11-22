using System;
using System.IO;
using System.Web;
using Bandl.Library.VaultLedger.Model;

namespace Bandl.Library.VaultLedger.DALFactory
{
	/// <summary>
	/// Summary description for Factory.
	/// </summary>
	public abstract class Factory
	{
        // Name of the DAL Assembly
        protected static string DALName
        {
            get 
            {
                return String.Format("Bandl.Library.VaultLedger.{0}DAL", Configurator.DatabaseType);
            }
        }

        // Name of the DAL Namespace.  For now, it is the same string as the DALName property.
        protected static string DALSpace
        {
            get 
            {
                return DALName;
            }
        }
    }
}
