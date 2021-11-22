using System;
using System.Web;
using System.Web.Caching;
using System.Text.RegularExpressions;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.IDAL;
using Bandl.Library.VaultLedger.Security;
using Bandl.Library.VaultLedger.DALFactory;
using Bandl.Library.VaultLedger.Collections;
using Bandl.Library.VaultLedger.Exceptions;

namespace Bandl.Library.VaultLedger.BLL
{
    /// <summary>
    /// A business component used to manage external sites
    /// The Bandl.Library.VaultLedger.Model.PatternDefaultMediumDetails is used in most 
    /// methods and is used to store serializable information about an
    /// external site.
    /// </summary>
    public class PatternDefaultMedium
    {
        /// <summary>
        /// Verifies that the default catch-all pattern exists in the system. If not, adds the default pattern.
        /// </summary>
        public static void CheckFinalPattern()
        {
            // Get the final bar code pattern and make sure the pattern is .*
            PatternDefaultMediumDetails p = PatternDefaultMediumFactory.Create().GetFinalPattern();
            // If we don't have one, then create one
            if (p == null || p.Pattern != ".*")
            {
                PatternDefaultMediumCollection c = GetPatternDefaults();                    // current collection
                PatternDefaultMediumCollection update = new PatternDefaultMediumCollection();    // holds updated collection
                // Add the new pattern to a new collection
                AccountCollection a = Account.GetAccounts();
                MediumTypeCollection m = MediumType.GetMediumTypes(false);
                // Create the default
                if (m.Count == 0)
                {
                    throw new BLLException("Cannot insert medium bar code pattern catch-all.  There are no non-container medium types in system.");
                }
                else if (a.Count == 0)
                {
                    throw new BLLException("Cannot insert medium bar code pattern catch-all.  There are no accounts in system.");
                }
                else
                {
                    update.Add(new PatternDefaultMediumDetails(".*", a[0].Name, m[0].Name, String.Empty));
                }
                // Insert each of the patterns into the collection, in the same order as before.  
                // Have to do this b/c there is no appending to a pattern collection.
                for (int i = c.Count; i > 0; i--)
                {
                    if (c[i-1].Pattern != ".*")
                    {
                        update.Insert(0, c[i-1]);
                    }
                }
                // Update the patterns
                PatternDefaultMediumFactory.Create().Update(update);
            }
        }
        
        /// <summary>
        /// Returns a collection of all the pattern defaults
        /// </summary>
        /// <returns>
        /// Collection pattern defaults
        /// </returns>
        public static PatternDefaultMediumCollection GetPatternDefaults()
        {
            return PatternDefaultMediumFactory.Create().GetPatternDefaults();
        }
            
        /// <summary>
		/// A method to update all the pattern defaults. Synchronizes media asynchronously.
		/// </summary>
		/// <param name="patterns">
		/// An entity with information about the new set of pattern defaults
		/// </param>
		public static void Update(ref PatternDefaultMediumCollection patternCollection) 
		{
			Update(ref patternCollection, false);
		}

		/// <summary>
		/// A method to update all the pattern defaults
		/// </summary>
		/// <param name="patterns">
		/// An entity with information about the new set of pattern defaults
		/// </param>
		/// <param name="blockSync">
		/// Block while synchronizing media to updated patterns
		/// </param>
		public static void Update(ref PatternDefaultMediumCollection patternCollection, bool blockThread) 
		{
			// Must have administrator privileges
			CustomPermission.Demand(Role.Administrator);
            // Must have objects in the collection
            if (patternCollection == null)
            {
                throw new ArgumentNullException("Reference must be set to an instance of a medium bar code pattern collection object.");
            }
            else if (patternCollection.Count == 0)
            {
                throw new ArgumentException("Medium bar code pattern collection must contain at least one medium bar code pattern object.");
            }
            // Reset the error flag
            patternCollection.HasErrors = false;
            // Make sure that the last element of the collection has a pattern
			// string of ".*"
			if (patternCollection[patternCollection.Count-1].Pattern != ".*") 
			{
				throw new BLLException("Final bar code pattern must be '.*'");
			}
            // Update the patterns.  If an exception is thrown, let it bubble
            // to the front end.
            PatternDefaultMediumFactory.Create().Update(patternCollection);
            // Refresh the defaults
            patternCollection = GetPatternDefaults();
		}

        /// <summary>
        /// Determines the correct default account and medium type for a serial number
        /// </summary>
        /// <param name="serial">
        /// Serial number for which to search for match
        /// </param>
        /// <param name="account">
        /// Variable in which to return the matching account
        /// </param>
        /// <param name="mediumType">
        /// Variable in which to return the matching medium type
        /// </param>
		public static void GetAttributes(string serialNo, out string account, out string mediumType)
        {
			account = String.Empty;
			mediumType = String.Empty;
            // Verify input
            if (serialNo == null)
            {
                throw new ArgumentNullException("Serial number may not be null.");
            }
            else if (serialNo == String.Empty)
            {
                throw new ArgumentException("Serial number may not be an empty string.");
            }
            else
            {
                PatternDefaultMediumFactory.Create().GetMediumDefaults(serialNo, out mediumType, out account);
            }
        }
    }
}
