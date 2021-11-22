using System;
using System.Data;

namespace Bandl.Utility.VaultLedger.Registrar.Model
{
	/// <summary>
	/// Summary description for LoginDetails.
	/// </summary>
	public class LoginDetails : Details
	{
        int id;
        string login;
        string catalogName;

		public LoginDetails(string _catalogName, string _login)
		{
            catalogName = _catalogName;
            login = _login;
            this.ObjState = ObjectStates.New;
        }

        public LoginDetails(IDataReader r)
        {
            id = r.GetInt32(0);
            login = r.GetString(1);
            catalogName = r.GetString(1);
            this.ObjState = ObjectStates.Unmodified;
        }

        public string Login
        {
            get {return login;}
        }

        public string CatalogName
        {
            get {return catalogName;}
        }
	}
}
