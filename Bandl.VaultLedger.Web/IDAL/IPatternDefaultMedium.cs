using System;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.Collections;

namespace Bandl.Library.VaultLedger.IDAL
{
    /// <summary>
    /// Inteface for the PatternDefaultMedium DAL
    /// </summary>
    public interface IPatternDefaultMedium
    {
        /// <summary>
        /// Returns a collection of all the pattern defaults
        /// </summary>
        /// <returns>
        /// Collection pattern defaults
        /// </returns>
        PatternDefaultMediumCollection GetPatternDefaults();

        /// <summary>
        /// Returns the final pattern; should be the catch-all
        /// </summary>
        /// <returns>
        /// Final pattern in the table
        /// </returns>
        PatternDefaultMediumDetails GetFinalPattern();

        /// <summary>
        /// Gets the default medium type and account for a medium serial number
        /// </summary>
        /// <param name="serialNo">
        /// Serial number for which to retrieve defaults
        /// </param>
        /// <param name="mediumType">
        /// Default medium type
        /// </param>
        /// <param name="accountName">
        /// Default account name
        /// </param>
        void GetMediumDefaults(string serialNo, out string mediumType, out string accountName);
            
        /// <summary>
        /// Updates all the pattern defaults known to the system
        /// </summary>
        /// <param name="patterns">
        /// Collection of pattern defaults to update
        /// </param>
        void Update(PatternDefaultMediumCollection patternCollection);
        
//        /// <summary>
//        /// Inserts the default case pattern
//        /// </summary>
//        void InsertDefault();
    }
}
