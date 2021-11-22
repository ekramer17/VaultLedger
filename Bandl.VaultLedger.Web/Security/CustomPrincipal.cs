using System;
using System.Security;
using System.Security.Principal;

namespace Bandl.Library.VaultLedger.Security
{
	/// <summary>
	/// Summary description for CustomPrincipal.
	/// </summary>
    [Serializable]
    public class CustomPrincipal : GenericPrincipal
	{
        private Role role;

        public Role PrincipalRole
        {
            get {return role;}
        }

        public CustomPrincipal(IIdentity _identity, string[] _roles) : base(_identity, _roles)
		{
            // Only one role allowed
            if (_roles == null || _roles.Length == 0)
                throw new SecurityException("No security role specified");
            else if (_roles.Length > 1)
                throw new SecurityException("User may only belong to one role");
            else
            {
                try
                {
                    role = (Role)Enum.Parse(typeof(Role), _roles[0], true);
                }
                catch
                {
                    throw new SecurityException("Invalid role specified");
                }
            }
        }
	}
}
