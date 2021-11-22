using System;
using Bandl.Library.VaultLedger.IDAL;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.DALFactory;

namespace Bandl.Library.VaultLedger.BLL
{
	/// <summary>
	/// Summary description for TabPageDefault.
	/// </summary>
	public class TabPageDefault
	{
        /// <summary>
        /// Returns the operator information for a specific operator
        /// </summary>
        /// <param name="id">Unique identifier for an operator</param>
        /// <returns>Returns the operator information for the operator</returns>
        public static int GetDefault(TabPageDefaults id, string login)
        {
            if (login == null)
            {
                return 1;
            }
            else
            {
                return TabPageDefaultFactory.Create().GetDefault(id, login);
            }
        }
        /// <summary>
        /// Returns the operator information for a specific operator
        /// </summary>
        /// <param name="id">Unique identifier for an operator</param>
        /// <returns>Returns the operator information for the operator</returns>
        public static int GetDefault(TabPageDefaults id, object login)
        {
            if (login == null)
            {
                return 1;
            }
            else if (login is string)
            {
                return GetDefault(id, (string)login);
            }
            else
            {
                throw new ApplicationException("Login object must be a string.");
            }
        }
        /// <summary>
        /// Updates a tab page default
        /// </summary>
        /// <param name="id">Tab default to retrieve</param>
        /// <param name="login">Login for which to get tab page default</param>
        /// <param name="tabPage">Number of default tab page</param>
        public static void Update(TabPageDefaults id, string login, int tabPage)
        {
            TabPageDefaultFactory.Create().Update(id, login, tabPage);
        }
        /// <summary>
        /// Updates a tab page default
        /// </summary>
        /// <param name="id">Tab default to retrieve</param>
        /// <param name="login">Login for which to get tab page default</param>
        /// <param name="tabPage">Number of default tab page</param>
        public static void Update(TabPageDefaults id, object login, int tabPage)
        {
            if (login is string)
            {
                Update(id, (string)login, tabPage);
            }
            else
            {
                throw new ApplicationException("Login object must be a string.");
            }
        }
    }
}
