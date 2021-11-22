using System;
using System.Data;
using Bandl.Library.VaultLedger.Common.Knock;

namespace Bandl.Utility.VaultLedger.Registrar.Model
{
    public class ServerLogin
    {
        private bool trusted; 
        private string login;
        private string password;
        private string pwdVector;

        public ServerLogin (string _login, bool _trusted, string _password)
        {
            login = _login;
            trusted = _trusted;
            // Encrypt the password
            byte[] vectorBytes = null;
            byte[] stringBytes = null;
            stringBytes = Balance.Inter(_password, out vectorBytes);
            password = Convert.ToBase64String(stringBytes);
            pwdVector = Convert.ToBase64String(vectorBytes);
        }

        public ServerLogin (string _login, bool _trusted, string _password, string _pwdVector)
        {
            login = _login;
            trusted = _trusted;
            // Do not encrypt the password
            password = _password;
            pwdVector = _pwdVector;
        }

        public bool Trusted
        {
            get {return trusted;}
            set {trusted = value;}
        }

        public string Login
        {
            get {return login;}
            set {login = value;}
        }

        public string Password
        {
            get {return password;}
            set
            {
                byte[] vectorBytes = null;
                byte[] stringBytes = null;
                stringBytes = Balance.Inter(value, out vectorBytes);
                password = Convert.ToBase64String(stringBytes);
                pwdVector = Convert.ToBase64String(vectorBytes);
            }
        }

        public string PwdVector
        {
            get {return pwdVector;}
        }

        public string DecryptPassword()
        {
            // Normal password
            byte[] vectorBytes = Convert.FromBase64String(pwdVector);
            byte[] stringBytes = Convert.FromBase64String(password);
            return Balance.Exhume(stringBytes, vectorBytes);
        }
    }

    /// <summary>
    /// Summary description for ServerDetails.
    /// </summary>
    public class ServerDetails : Details
    {
        private int id;
        private string name;
//        private ServerLogin slu;
        private ServerLogin slo;

		public ServerDetails(string _name, ServerLogin _slo)
		{
			name = _name;
			slo = _slo;
			this.ObjState = ObjectStates.New;
		}
		
//		public ServerDetails(string _name, ServerLogin _slo, ServerLogin _slu)
//        {
//            name = _name;
//            slu = _slu;
//            slo = _slo;
//            this.ObjState = ObjectStates.New;
//        }

        public ServerDetails(IDataReader r)
        {
            id = r.GetInt32(0);
            name = r.GetString(1);
            slo = new ServerLogin(r.GetString(2), (r.GetInt32(3) == 0), r.GetString(4), r.GetString(5));
//            slu = new ServerLogin(r.GetString(6), (r.GetInt32(7) == 0), r.GetString(8), r.GetString(9));
            this.ObjState = ObjectStates.Unmodified;
        }

        public int Id
        {
            get {return id;}
        }

        public string Name
        {
            get {return name;}
        }

        public ServerLogin Operator
        {
            get {return slo;}
        }

//        public ServerLogin Updater
//        {
//            get {return slu;}
//        }
	}
}
