using System;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.Collections;

namespace Bandl.Library.VaultLedger.IDAL
{
	/// <summary>
	/// Summary description for IPatternIgnore.
	/// </summary>
	public interface IPatternIgnore
	{
        /// <summary>
        /// Returns the detail information for a specific ignored 
        /// bar code pattern
        /// </summary>
        /// <param name="pattern">Unique identifier for an ignored pattern</param>
        /// <returns>Returns the information for the ignored pattern</returns>
        PatternIgnoreDetails GetIgnoredPattern(string pattern);

        /// <summary>
        /// Returns the detail information for a specific ignored
        /// bar code pattern
        /// </summary>
        /// <param name="id">Unique identifier for an ignored pattern</param>
        /// <returns>Returns the detail information for the ignored pattern</returns>
        PatternIgnoreDetails GetIgnoredPattern(int id);

        /// <summary>
        /// Returns all the ignored patterns known to the system in a collection
        /// </summary>
        /// <returns>Returns all the ignored patterns known to the system</returns>
        PatternIgnoreCollection GetIgnoredPatterns();

        /// <summary>
        /// A method to insert a ignored pattern
        /// </summary>
        /// <param name="pattern">An entity with information about the new pattern</param>
        void Insert(PatternIgnoreDetails pattern);

        /// <summary>
        /// A method to update an existing ignored pattern
        /// </summary>
        /// <param name="patterb">
        /// An entity with information about the ignored pattern to be updated
        /// </param>
        void Update(PatternIgnoreDetails pattern);

        /// <summary>
        /// Deletes an existing ignored pattern
        /// </summary>
        /// <param name="pattern">Ignored pattern to delete</param>
        void Delete(PatternIgnoreDetails pattern);
    }
}
