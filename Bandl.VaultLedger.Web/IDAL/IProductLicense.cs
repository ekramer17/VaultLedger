using System;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.Collections;

namespace Bandl.Library.VaultLedger.IDAL
{
    /// <summary>
    /// Inteface for the Product License DAL
    /// </summary>
    public interface IProductLicense
    {
        /// <summary>
        /// Gets a license from the database
        /// </summary>
        /// <param name="licenseType">Type of license to retrieve</param>
        /// <returns>Product license detail object on success, null if not found</returns>
        ProductLicenseDetails GetProductLicense(LicenseTypes licenseType);

        /// <summary>
        /// Gets all licenses from the database
        /// </summary>
        /// <returns>Product license collection</returns>
        ProductLicenseCollection GetProductLicenses();

        /// <summary>
        /// Inserts a license into the database
        /// </summary>
        /// <param name="license">Product license detail object</param>
        void Insert(ProductLicenseDetails license);

        /// <summary>
        /// Updates a license in the database
        /// </summary>
        /// <param name="license">
        /// Product license detail object
        /// </param>
        void Update(ProductLicenseDetails license);

        /// <summary>
        /// Deletes a license in the database
        /// </summary>
        /// <param name="license">
        /// Product license detail object
        /// </param>
        void Delete(LicenseTypes licenseType);
    }
}
