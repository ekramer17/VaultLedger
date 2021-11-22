using System;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.Collections;

namespace Bandl.Library.VaultLedger.IDAL
{
    /// <summary>
    /// Inteface for the ExternalSite DAL
    /// </summary>
    public interface IExternalSite
    {
        /// <summary>
        /// Get an external site from the data source based on the unique name
        /// </summary>
        /// <param name="name">Unique identifier for an external site</param>
        /// <returns>External site information</returns>
        ExternalSiteDetails GetExternalSite(string name);

        /// <summary>
        /// Get an external site from the data source based on the unique id
        /// </summary>
        /// <param name="id">Unique identifier for an external site</param>
        /// <returns>External site information</returns>
        ExternalSiteDetails GetExternalSite(int id);

        /// <summary>
        /// Returns a collection of all the external sites
        /// </summary>
        /// <returns>Collection of all the external sites</returns>
        ExternalSiteCollection GetExternalSites();

        /// <summary>
        /// Inserts a new external site into the system
        /// </summary>
        /// <param name="site">External site details to insert</param>
        void Insert(ExternalSiteDetails site);

        /// <summary>
        /// Updates an existing external site
        /// </summary>
        /// <param name="site">External site details to update</param>
        void Update(ExternalSiteDetails site);

        /// <summary>
        /// Deletes an existing external site
        /// </summary>
        /// <param name="site">External site to delete</param>
        void Delete(ExternalSiteDetails site);
    }
}
