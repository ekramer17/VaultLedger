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
    /// The Bandl.Library.VaultLedger.Model.ExternalSiteDetails is used in most 
    /// methods and is used to store serializable information about an
    /// external site.
    /// </summary>
    public class ExternalSite
    {
        /// <summary>
        /// Returns the detail information for a specific external site
        /// </summary>
        /// <param name="name">Unique identifier for an external site</param>
        /// <returns>Returns the information for the external site</returns>
        public static ExternalSiteDetails GetExternalSite(string name) 
        {
            return ExternalSiteFactory.Create().GetExternalSite(name);
        }

        /// <summary>
        /// Returns the detail information for a specific external site
        /// </summary>
        /// <param name="id">Unique identifier for an external site</param>
        /// <returns>Returns the detail information for the external site</returns>
        public static ExternalSiteDetails GetExternalSite(int id) 
        {
            return ExternalSiteFactory.Create().GetExternalSite(id);
        }

        /// <summary>
        /// Returns all the exterrnal sites known to the system in a collection
        /// </summary>
        /// <returns>Returns all the external sites known to the system</returns>
        public static ExternalSiteCollection GetExternalSites()
        {
            return ExternalSiteFactory.Create().GetExternalSites();
        }

        /// <summary>
        /// A method to insert a new external site
        /// </summary>
        /// <param name="site">An entity with information about the new external site</param>
        public static void Insert(ref ExternalSiteDetails site) 
        {
            // Must have administrator privileges
            CustomPermission.Demand(Role.Administrator);
            // Make sure that the data is new
            if(site == null)
            {
                throw new ArgumentNullException("site", "Reference must be set to an instance of an external site object.");
            }
            else if(site.ObjState != ObjectStates.New)
            {
                throw new ObjectStateException("Only an external site marked as new may be inserted.");
            }
            // Reset the error flag
            site.RowError = String.Empty;
            // Insert the site
            try
            {
                ExternalSiteFactory.Create().Insert(site);
                site = GetExternalSite(site.Name);
            }
            catch (Exception e)
            {
                site.RowError = e.Message;
                throw;
            }
        }

        /// <summary>
        /// A method to update an existing external site
        /// </summary>
        /// <param name="site">
        /// An entity with information about the external site to be updated
        /// </param>
        public static void Update(ref ExternalSiteDetails site) 
        {
            // Must have administrator privileges
            CustomPermission.Demand(Role.Administrator);
            // Make sure that the data is modified
            if(site == null)
            {
                throw new ArgumentNullException("site", "Reference must be set to an instance of an external site object.");
            }
            else if(site.ObjState != ObjectStates.Modified)
            {
                throw new ObjectStateException("Only an external site marked as modified may be updated.");
            }
            // Reset the error flag
            site.RowError = String.Empty;
            // Update the site
            try
            {
                ExternalSiteFactory.Create().Update(site);
                site = GetExternalSite(site.Id);
            }
            catch (Exception e)
            {
                site.RowError = e.Message;
                throw;
            }
        }

        /// <summary>
        /// Deletes an existing external site
        /// </summary>
        /// <param name="o">External site to delete</param>
        public static void Delete(ref ExternalSiteDetails site)
        {
            // Must have administrator privileges
            CustomPermission.Demand(Role.Administrator);
            // Make sure that the data is not new
            if(site == null)
            {
                throw new ArgumentNullException("site", "Reference must be set to an instance of an external site object.");
            }
            else if(site.ObjState != ObjectStates.Unmodified)
            {
                throw new ObjectStateException("Only an external site marked as unmodified may be deleted.");
            }
            // Reset the error flag
            site.RowError = String.Empty;
            // Delete the site
            try
            {
                ExternalSiteFactory.Create().Delete(site);
                site.ObjState = ObjectStates.Deleted;
                site.RowError = String.Empty;
            }
            catch (Exception e)
            {
                site.RowError = e.Message;
                throw;
            }
        }
    }
}
