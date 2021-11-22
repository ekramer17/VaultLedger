using System;
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
    /// The Bandl.Library.VaultLedger.Model.PatternIgnoreDetails is used in most 
    /// methods and is used to store serializable information about an
    /// ignored bar code pattern.
    /// </summary>
    public class PatternIgnore
    {
        /// <summary>
        /// Returns the detail information for a specific ignored 
        /// bar code pattern
        /// </summary>
        /// <param name="pattern">Unique identifier for an ignored pattern</param>
        /// <returns>Returns the information for the ignored pattern</returns>
        public static PatternIgnoreDetails GetIgnoredPattern(string pattern) 
        {
            if(pattern == null)
            {
                throw new ArgumentNullException("Pattern may not be null.");
            }
            else if (pattern == String.Empty)
            {
                throw new ArgumentException("Pattern may not be an empty string.");
            }
            else
            {
                return PatternIgnoreFactory.Create().GetIgnoredPattern(pattern);
            }
        }

        /// <summary>
        /// Returns the detail information for a specific ignored
        /// bar code pattern
        /// </summary>
        /// <param name="id">Unique identifier for an ignored pattern</param>
        /// <returns>Returns the detail information for the ignored pattern</returns>
        public static PatternIgnoreDetails GetIgnoredPattern(int id) 
        {
            if (id <= 0)
            {
                throw new ArgumentException("Exclusion pattern id must be greater than zero.");
            }
            else
            {
                return PatternIgnoreFactory.Create().GetIgnoredPattern(id);
            }
        }

        /// <summary>
        /// Returns all the ignored patterns known to the system in a collection
        /// </summary>
        /// <returns>Returns all the ignored patterns known to the system</returns>
        public static PatternIgnoreCollection GetIgnoredPatterns()
        {
            return PatternIgnoreFactory.Create().GetIgnoredPatterns();
        }

        /// <summary>
        /// A method to insert a ignored pattern
        /// </summary>
        /// <param name="pattern">An entity with information about the new pattern</param>
        public static void Insert(ref PatternIgnoreDetails pattern) 
        {
            // Must have administrator privileges
            CustomPermission.Demand(Role.Administrator);
            // Make sure that the data is new
            // Make sure that the data is new
            if(pattern == null)
            {
                throw new ArgumentNullException("Reference must be set to an instance of an exclusion pattern object.");
            }
            else if(pattern.ObjState != ObjectStates.New)
            {
                throw new ObjectStateException("Only an exclusion pattern marked as new may be inserted.");
            }
            // Reset the error flag
            pattern.RowError = String.Empty;
            // Insert the pattern
            try
            {
                PatternIgnoreFactory.Create().Insert(pattern);
                pattern = GetIgnoredPattern(pattern.Pattern);
            }
            catch (Exception e)
            {
                pattern.RowError = e.Message;
                throw;
            }
        }

        /// <summary>
        /// A method to update an existing ignored pattern
        /// </summary>
        /// <param name="patterb">
        /// An entity with information about the ignored pattern to be updated
        /// </param>
        public static void Update(ref PatternIgnoreDetails pattern) 
        {
            // Must have administrator privileges
            CustomPermission.Demand(Role.Administrator);
            // Make sure that the data is modified
            if(pattern == null)
            {
                throw new ArgumentNullException("Reference must be set to an instance of an exclusion pattern object.");
            }
            else if(pattern.ObjState != ObjectStates.Modified)
            {
                throw new ObjectStateException("Only an exclusion pattern marked as modified may be updated.");
            }
            // Reset the error flag
            pattern.RowError = String.Empty;
            // Update the pattern
            try
            {
                PatternIgnoreFactory.Create().Update(pattern);
                pattern = GetIgnoredPattern(pattern.Id);
            }
            catch (Exception e)
            {
                pattern.RowError = e.Message;
                throw;
            }
        }

        /// <summary>
        /// Deletes an existing ignored pattern
        /// </summary>
        /// <param name="pattern">Ignored pattern to delete</param>
        public static void Delete(ref PatternIgnoreDetails pattern)
        {
            // Must have administrator privileges
            CustomPermission.Demand(Role.Administrator);
            // Make sure that the data is unmodified
            if(pattern == null)
            {
                throw new ArgumentNullException("Reference must be set to an instance of an exclusion pattern object.");
            }
            else if(pattern.ObjState != ObjectStates.Unmodified)
            {
                throw new ObjectStateException("Only an exclusion pattern marked as unmodified may be deleted.");
            }
            // Reset the error flag
            pattern.RowError = String.Empty;
            // Delete the pattern
            try
            {
                PatternIgnoreFactory.Create().Delete(pattern);
                pattern.ObjState = ObjectStates.Deleted;
                pattern.RowError = String.Empty;
            }
            catch (Exception e)
            {
                pattern.RowError = e.Message;
                throw;
            }
        }
    }
}
