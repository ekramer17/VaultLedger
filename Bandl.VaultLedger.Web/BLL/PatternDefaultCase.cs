using System;
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
    /// The Bandl.Library.VaultLedger.Model.PatternDefaultCaseCaseDetails is used in most 
    /// methods and is used to store serializable information about an
    /// external site.
    /// </summary>
    public class PatternDefaultCase
    {
        /// <summary>
        /// Verifies that the default catch-all pattern exists in the system. If not, adds the default pattern.
        /// </summary>
        public static void CheckFinalPattern()
        {
            // Get the final bar code pattern and make sure the pattern is .*
            PatternDefaultCaseDetails p = PatternDefaultCaseFactory.Create().GetFinalPattern();
            // If we don't have one, then create one
            if (p == null || p.Pattern != ".*")
            {
                PatternDefaultCaseCollection c = GetPatternDefaultCases();                    // current collection
                PatternDefaultCaseCollection update = new PatternDefaultCaseCollection();    // holds updated collection
                // Add the new pattern to a new collection
                MediumTypeCollection m = MediumType.GetMediumTypes(true);
                // Create the default
                if (m.Count == 0)
                {
                    throw new BLLException("Cannot insert medium bar code pattern catch-all.  There are no non-container medium types in system.");
                }
                else
                {
                    update.Add(new PatternDefaultCaseDetails(".*", m[0].Name, String.Empty));
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
                PatternDefaultCaseFactory.Create().Update(update);
            }
        }

//        /// <summary>
//        /// Verifies that the default catch-all pattern exists in the system.
//        /// If not, adds the default pattern.
//        /// </summary>
//        public static void CheckFinalPattern()
//        {
//			PatternDefaultCaseCollection casePatterns = PatternDefaultCaseFactory.Create().GetPatternDefaults();
//
//			if (casePatterns.Count == 0 || casePatterns[casePatterns.Count-1].Pattern != ".*")
//			{
//                MediumTypeCollection mediumTypes = MediumType.GetMediumTypes(true);
//
//				if (mediumTypes.Count == 0)
//				{
//					throw new BLLException("Cannot insert case bar code pattern catch-all.  There are no container types in system.");
//				}
//                else
//                {
//                    // Try to find the catch-all pattern in the collection
//                    PatternDefaultCaseDetails lastDefault = casePatterns.Find(".*");
//                    // If the final pattern exists, but is not in the last position, we
//                    // have to put it there.  If it is not found, then create it.
//                    if (lastDefault == null)
//                    {
//                        if (casePatterns.Count == 0)
//                        {
//                            lastDefault = new PatternDefaultCaseDetails(".*", mediumTypes[0].Name, String.Empty);
//                        }
//                        else
//                        {
//                            PatternDefaultCaseDetails p = casePatterns[casePatterns.Count-1];
//                            lastDefault = new PatternDefaultCaseDetails(".*", p.CaseType, String.Empty);
//                        }
//                    }
//                    // Initialize a new collection with only the default pattern
//                    PatternDefaultCaseCollection newCollection = new PatternDefaultCaseCollection();
//                    newCollection.Add(lastDefault);
//                    // Insert each of the patterns into the collection, in the same order as before
//                    for (int i = casePatterns.Count; i > 0; i--)
//                    {
//                        if (casePatterns[i-1].Pattern != ".*")
//                        {
//                            newCollection.Insert(0, casePatterns[i-1]);
//                        }
//                    }
//                    // Update the collection
//                    PatternDefaultCaseFactory.Create().Update(newCollection, false);
//                }
//			}
//		}

        /// <summary>
        /// Returns all the pattern defaults known to the system in a collection
        /// </summary>
        /// <returns>Returns all the pattern defaults known to the system</returns>
        public static PatternDefaultCaseCollection GetPatternDefaultCases()
        {
            return PatternDefaultCaseFactory.Create().GetPatternDefaults();
        }

        /// <summary>
        /// A method to update all the pattern defaults
        /// </summary>
        /// <param name="patterns">
        /// An entity with information about the new set of pattern defaults
        /// </param>
        public static void Update(ref PatternDefaultCaseCollection patternCollection, bool blockThread) 
        {
            // Must have administrator privileges
            CustomPermission.Demand(Role.Administrator);
            // Must have objects in the collection
            if (patternCollection == null)
            {
                throw new ArgumentNullException("Reference must be set to an instance of a case bar code pattern collection object.");
            }
            else if (patternCollection.Count == 0)
            {
                throw new ArgumentException("Case bar code pattern collection must contain at least one case bar code pattern object.");
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
			PatternDefaultCaseFactory.Create().Update(patternCollection);
            // Refresh the patterns
            patternCollection = GetPatternDefaultCases();
        }

		/// <summary>
		/// A method to update all the pattern defaults. Synchronizes media asynchronously.
		/// </summary>
		/// <param name="patterns">
		/// An entity with information about the new set of pattern defaults
		/// </param>
		public static void Update(ref PatternDefaultCaseCollection patternCollection) 
		{
			Update(ref patternCollection, false);
		}
    }
}
