using System;
using System.Web;
using System.Reflection;
using Bandl.Library.VaultLedger.IDAL;
using Bandl.Library.VaultLedger.Model;

namespace Bandl.Library.VaultLedger.DALFactory
{
	/// <summary>
	/// Summary description for ConnectionFactory.
	/// </summary>
	public class ConnectionFactory : Factory
	{
        public static IConnection Create()
        {	
            // Create an instance of the connection type
            IConnection newConnection = (IConnection)Assembly.Load(DALName).CreateInstance(DALSpace + ".DataLink");

            try
            {
                // Get the method by which we can search for persisted connections
                MethodInfo methodInfo = newConnection.GetType().GetMethod("GetPersistedConnection", BindingFlags.Public | BindingFlags.Static);
                // If we found the method, execute it
                if (methodInfo != null)
                {
                    IConnection persistedConnection = (IConnection)methodInfo.Invoke(null, null);
                    if (persistedConnection != null) return persistedConnection;
                }
            }
            catch
            {
                ;
            }

            // Persisted connection not found
            return newConnection;
        }
	}
}
