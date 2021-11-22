using System;
using System.Data;
using System.Text;
using System.Text.RegularExpressions;
using Bandl.Library.VaultLedger.Common.Knock;

namespace Bandl.Utility.VaultLedger.Registrar.Model
{
	/// <summary>
	/// The client application database as it is known in the registrar database.
	/// </summary>
	public class CatalogDetails : Details
	{
        private int id;
        private string dbName;
        private string ownerName;
        private string serverName;
        private DateTime lastUsed;

        public CatalogDetails(string _serverName, string _dbName)
        {
            // Check validity of parameters
            if (_serverName == null || _serverName == String.Empty)
            {
                throw new ArgumentException("Server name not supplied");
            }
            if (_dbName == null || _dbName == String.Empty)
            {
                throw new ArgumentException("Catalog name not supplied");
            }
            // Initialize fields
            dbName = _dbName;
            lastUsed = DateTime.Now;
            serverName = _serverName;
            this.ObjState = ObjectStates.New;
        }

        public CatalogDetails(IDataReader r)
        {
            id = r.GetInt32(0);
            dbName = r.GetString(1);
            lastUsed = r.GetDateTime(2);
            serverName = r.GetString(3);
            ownerName = r.GetString(4);
            this.ObjState = ObjectStates.Unmodified;
        }

        public int Id
        {
            get {return id;}
        }
            
        public string Name
        {
            get {return dbName;}
        }

        public DateTime LastUsed
        {
            get {return lastUsed;}
        }

        public string Server
        {
            get {return serverName;}
        }

        public string Owner
        {
            get {return ownerName;}
        }
    }
}
