using System;
using Bandl.Library.VaultLedger.Model;

namespace Bandl.Library.VaultLedger.IDAL
{
	/// <summary>
	/// Summary description for ITabPageDefault.
	/// </summary>
	public interface ITabPageDefault
	{
        /// <summary>
        /// Gets a tab page default
        /// </summary>
        /// <param name="id">Tab default to retrieve</param>
        /// <param name="login">Login for which to get tab page default</param>
        /// <returns>Integer indicating page to display</returns>
        int GetDefault(TabPageDefaults id, string login);
        /// <summary>
        /// Updates a tab page default
        /// </summary>
        /// <param name="id">Tab default to retrieve</param>
        /// <param name="login">Login for which to get tab page default</param>
        /// <param name="tabPage">Number of default tab page</param>
        void Update(TabPageDefaults id, string login, int tabPage);
    }
}
