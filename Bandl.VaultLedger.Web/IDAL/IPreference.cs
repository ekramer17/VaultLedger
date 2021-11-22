using System;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.Collections;

namespace Bandl.Library.VaultLedger.IDAL
{
    /// <summary>
    /// Inteface for the Preference DAL
    /// </summary>
    public interface IPreference
    {
        /// <summary>
        /// Gets a preference from the database
        /// </summary>
        /// <param name="key">Key value of the preference to retrieve</param>
        /// <returns>Preference on success, null if not found</returns>
        PreferenceDetails GetPreference(PreferenceKeys key);

        /// <summary>
        /// Gets all preferences from the database
        /// </summary>
        /// <returns>
        /// Collection of all preferences in the database
        /// </returns>
        PreferenceCollection GetPreferences();

        /// <summary>
        /// Updates a preference in the database
        /// </summary>
        /// <param name="p">Preference to update</param>
        void Update(PreferenceDetails p);
    }
}
