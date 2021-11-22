using System;
using Bandl.Library.VaultLedger.Exceptions;
using Bandl.Library.VaultLedger.Collections;
using Bandl.Library.VaultLedger.DALFactory;
using Bandl.Library.VaultLedger.IDAL;
using Bandl.Library.VaultLedger.Model;

namespace Bandl.Library.VaultLedger.BLL
{
	/// <summary>
	/// Summary description for Preference.
	/// </summary>
	public class Preference
	{
        /// <summary>
        /// Gets a preference from the database
        /// </summary>
        /// <param name="key">Key value of the preference to retrieve</param>
        /// <returns>Preference on success, null if not found</returns>
        public static PreferenceDetails GetPreference(PreferenceKeys key)
        {
            return PreferenceFactory.Create().GetPreference(key);
        }

        /// <summary>
        /// Gets all preferences from the database
        /// </summary>
        /// <returns>
        /// Collection of all preferences in the database
        /// </returns>
        public static PreferenceCollection GetPreferences()
        {
            return PreferenceFactory.Create().GetPreferences();
        }

        /// <summary>
        /// Updates a preference in the database
        /// </summary>
        /// <param name="p">Preference to update</param>
        public static void Update(PreferenceDetails p)
        {
            // Make sure that the data is modified
            if(p == null)
            {
                throw new ArgumentNullException("Reference must be set to an instance of a preference object.");
            }
            else if(p.ObjState != ObjectStates.Modified)
            {
                throw new ObjectStateException("Only a preference marked as modified may be updated.");
            }
            // Call the DAL to update the preference
            try
            {
                PreferenceFactory.Create().Update(p);
                p = GetPreference(p.Key);
            }
            catch (Exception e)
            {
                p.RowError = e.Message;
                throw;
            }
        }

        /// <summary>
        /// Updates preferences in the database
        /// </summary>
        /// <param name="prefCollection">
        /// Preferences to update
        /// </param>
        public static void Update(ref PreferenceCollection prefCollection)
        {
            // Make sure that the data is modified
            if (prefCollection == null)
            {
                throw new ArgumentNullException("Reference must be set to an instance of a preference collection object.");
            }
            else if (prefCollection.Count == 0)
            {
                throw new ArgumentException("Preference collection must contain at least one preference object.");
            }
            // Perform the updates
            using (IConnection c = ConnectionFactory.Create().Open())
            {
                // Begin a transaction
                c.BeginTran();
                // Reset the collection error flag
                prefCollection.HasErrors = false;
                // Create a DAL object
                IPreference dal = PreferenceFactory.Create(c);
                // Loop through the audit trail expirations
                foreach (PreferenceDetails preference in prefCollection)
                {
                    if (preference.ObjState == ObjectStates.Modified)
                    {
                        try
                        {
                            dal.Update(preference);
                            preference.RowError = String.Empty;
                        }
                        catch (Exception e)
                        {
                            preference.RowError = e.Message;
                            prefCollection.HasErrors = true;
                        }
                    }
                }
                // If the collection has errors, roll back the transaction and
                // throw a collection exception.
                if (prefCollection.HasErrors)
                {
                    c.RollbackTran();
                    throw new CollectionErrorException(prefCollection);
                }
                else
                {
                    c.CommitTran();
                    // Get the current preferences and create an empty collection
                    PreferenceCollection currentPreferences = GetPreferences();
                    PreferenceCollection returnCollection = new PreferenceCollection();
                    // Fill the empty collection with the updated versions of those
                    // expirations that were modified.  Simply add those that were not.
                    foreach (PreferenceDetails preference in currentPreferences)
                    {
                        if (preference.ObjState != ObjectStates.Modified)
                        {
                            returnCollection.Add(preference);
                        }
                        else
                        {
                            returnCollection.Add(currentPreferences.Find(preference.Key));
                        }
                    
                    }
                    // Return the updated collection by reference
                    prefCollection = returnCollection;
                }
            }
        }

        /// <summary>
        /// Gets the name of the standard bar code format to use when
        /// user enters serial numbers of media, possibly cases.  If an
        /// editing format is being used, pages will create javascript
        /// functions to handle the transformations.
        /// </summary>
        public static SerialEditFormatTypes GetSerialEditFormat()
        {
            // See if the preferences are set to edit
            PreferenceDetails p = GetPreference(PreferenceKeys.EmploySerialEditFormat);
            // If so, then return the product type name
            if (p.Value.ToUpper() == "YES" || p.Value.ToUpper() == "TRUE")
            {
                switch (Configurator.ProductType.ToUpper())
                {
                    case "B&L":
                    case "BANDL":
                    case "IMATION":
                        return SerialEditFormatTypes.UpperOnly;
                    case "RECALL":
                        return SerialEditFormatTypes.RecallStandard;
                    default:
                        break;
                }
            }
            // No editing used
            return SerialEditFormatTypes.None;
        }

        /// <summary>
        /// Gets the number of items per page for detail pages
        /// </summary>
        /// <returns></returns>
        public static int GetItemsPerPage()
        {
            return Int32.Parse(GetPreference(PreferenceKeys.NumberOfItemsPerPage).Value);
        }
	}
}
