using System;
using System.Text;
using System.Security;
using System.Threading;
using System.Security.Principal;
using System.Security.Permissions;

namespace Bandl.Library.VaultLedger.Security
{
    [Flags]
    public enum Role
    {
        Viewer = 8,
        Auditor = 128,
        Operator = 2048, // Librarian
        VaultOps = 8192, // Vault operator
        Administrator = 32768
    }

    [Serializable]
    public sealed class CustomPermission : IPermission, IUnrestrictedPermission
    {  
        private bool unrestricted = false;
        private Role role = Role.Viewer;

        // Constructors
        public CustomPermission(PermissionState _state) : this(_state, Role.Viewer) {}
        public CustomPermission(Role _minRole) : this(PermissionState.None, _minRole) {}

        public CustomPermission(PermissionState _state, Role _role) 
        {
            if (_state == PermissionState.Unrestricted)
            {
                unrestricted = true;
            }
            else
            {
                // Get the role of the current principal
                IPrincipal currentPrincipal = Thread.CurrentPrincipal;
                // If the principal is an administrator, no need to do any other checks
                if (currentPrincipal.IsInRole("Administrator"))
                {
                    unrestricted = true;
                }
                else if (false == currentPrincipal is CustomPrincipal)
                {
                    throw new SecurityException("Principal must be of custom variety.");
                }
                else if ((int)(((CustomPrincipal)currentPrincipal).PrincipalRole & _role) > 0)
                {
                    unrestricted = true;
                }
                else
                {
                    unrestricted = false;
                }
            }
        }

        public Role OperatorRole
        {
            get {return role;}
        }

        public bool IsUnrestricted()
        {
            return unrestricted;
        }

        public IPermission Copy()
        {
            return new CustomPermission(PermissionState.None, role);
        }

        public IPermission Union(IPermission target)
        {
            if (target == null) 
                return this.Copy();
            else if (false == target is CustomPermission)
                throw new ApplicationException("Illegal union");
            else
            {
                CustomPermission p = (CustomPermission)target;
                Role unionRole = role > p.OperatorRole ? role : p.OperatorRole;
                return new CustomPermission(PermissionState.None, unionRole);
            }
        }

        public IPermission Intersect(IPermission target)
        {
            try
            {
                if(null == target) return null;
                CustomPermission PassedPermission = (CustomPermission)target;

                if(!PassedPermission.IsUnrestricted())
                    return PassedPermission;
                else
                    return this.Copy();
            }
            catch (InvalidCastException)
            {
                throw new ArgumentException("Incorrect argument type", this.GetType().FullName);
            }                
        }

        public bool IsSubsetOf(IPermission target)
        {  
            if(null == target)
            {
                return !this.unrestricted;
            }
            else
            {
                try
                {        
                    CustomPermission passedpermission = (CustomPermission)target;
                    return (this.unrestricted == passedpermission.unrestricted);
                }
                catch (InvalidCastException)
                {
                    throw new ArgumentException("Incorrect argument type", this.GetType().FullName);
                }
            }    
        }

        public SecurityElement ToXml()
        {
            Type type = this.GetType();
            SecurityElement element = new SecurityElement("IPermission");
            StringBuilder AssemblyName = new StringBuilder(type.Assembly.ToString());
            AssemblyName.Replace('\"', '\'');
            element.AddAttribute("class", type.FullName + ", " + AssemblyName);
            element.AddAttribute("version", "1");
            element.AddAttribute("Unrestricted", unrestricted.ToString());
            return element;
        }

        public void FromXml(SecurityElement PassedElement)
        {
            string element = PassedElement.Attribute("Unrestricted");
            if(null != element)
            {  
                this.unrestricted = Convert.ToBoolean(element);
            }
        }

        public void Demand()
        {
            if (!unrestricted) throw new SecurityException();
        }

        public static Role CurrentOperatorRole()
        {
            // Get the role of the current principal
            IPrincipal currentPrincipal = Thread.CurrentPrincipal;
            // Role will be of custom variety
            if (false == currentPrincipal is CustomPrincipal)
            {
                throw new SecurityException("Principal must be of custom variety.");
            }
            else 
            {
                return ((CustomPrincipal)currentPrincipal).PrincipalRole;
            }        
        }

        /// <summary>
        /// Demands that the current operator belong to one of the roles passed
        /// as an argument.  Since administrators can do anything, if any other
        /// role is being supplied then administrator is implied and need not
        /// be specified.  If user is not of a given role, this method throws
        /// a security exception.
        /// </summary>
        /// <param name="role">
        /// Roles to which user must belong.  If more than one
        /// is specified, user must belong to at least one of them.
        /// </param>
        public static void Demand(Role role)
        {
            if (CurrentOperatorRole() != Role.Administrator)
            {
                if (0 == (int)(CurrentOperatorRole() & role))
                {
                    throw new SecurityException();
                }
            }
        }
    }
}