using System;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.Collections;

namespace Bandl.Library.VaultLedger.IDAL
{
    /// <summary>
    /// Inteface for the PatternCaseDefault DAL
    /// </summary>
    public interface IPatternDefaultCase
    {
        /// <summary>
        /// Returns a collection of all the pattern defaults
        /// </summary>
        /// <returns>Collection of all the pattern defaults</returns>
        PatternDefaultCaseCollection GetPatternDefaults();

        /// <summary>
        /// Returns the final pattern; should be the catch-all
        /// </summary>
        /// <returns>
        /// Final pattern in the table
        /// </returns>
        PatternDefaultCaseDetails GetFinalPattern();
            
        /// <summary>
        /// Updates all the pattern defaults known to the system
        /// </summary>
        /// <param name="patterns">
        /// Collection of pattern defaults to update
        /// </param>
        void Update(PatternDefaultCaseCollection patternCollection);

        /// <summary>
        /// Inserts the default case pattern
        /// </summary>
        void InsertDefault();
    }
}
