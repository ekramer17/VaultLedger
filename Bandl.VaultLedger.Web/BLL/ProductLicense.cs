using System;
using System.Threading;
using System.Security.Principal;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.IDAL;
using Bandl.Library.VaultLedger.Security;
using Bandl.Library.VaultLedger.DALFactory;
using Bandl.Library.VaultLedger.Collections;
using Bandl.Library.VaultLedger.Exceptions;
using Bandl.Library.VaultLedger.Gateway.Bandl;

namespace Bandl.Library.VaultLedger.BLL
{
    /// <summary>
    /// A business component used to manage external sites
    /// The Bandl.Library.VaultLedger.Model.ProductLicenseDetails is used in most 
    /// methods and is used to store serializable information about an
    /// external site.
    /// </summary>
    public class ProductLicense
    {
        /// <summary>
        /// Gets a license from the database
        /// </summary>
        /// <param name="licenseType">Type of license to retrieve</param>
        /// <returns>Product license detail object on success, null if not found</returns>
        public static ProductLicenseDetails GetProductLicense(LicenseTypes licenseType) 
        {
            return ProductLicenseFactory.Create().GetProductLicense(licenseType);
        }

        /// <summary>
        /// Gets all licenses from the database
        /// </summary>
        /// <returns>Product license collection</returns>
        public static ProductLicenseCollection GetProductLicenses()
        {
            return ProductLicenseFactory.Create().GetProductLicenses();
        }

        /// <summary>
        /// Compares the licenses in the database with licenses fetched from
        /// the web service.
        /// </summary>
        public static void RetrieveLicenses()
        {
            // Must have administrator privileges
            CustomPermission.Demand(Role.Administrator);
            // Compare the remote licenses with the local licenses
            CompareLicenses((new BandlGateway()).RetrieveLicenses());
        }

        /// <summary>
        /// Compares the licenses currently in the database to the licenses
        /// retrieved remotely from the Bandl web service.  Updates the 
        /// local database where necessary.
        /// </summary>
        /// <param name="localLicenses">
        /// Licenses from the local database
        /// </param>
        /// <param name="remoteLicenses">
        /// Licenses retrieved from the Bandl web service
        /// </param>
        private static void CompareLicenses(ProductLicenseCollection remoteLicenses)
        {
            ProductLicenseDetails r = null;
            ProductLicenseCollection localLicenses = GetProductLicenses();
            // Create a product license data access layer
            IProductLicense dal = ProductLicenseFactory.Create();
            // Add each remote licensethat does not exist in the collection 
            // of local licenses.
            foreach(ProductLicenseDetails p in remoteLicenses)
            {
                if (null == localLicenses.Find(p.LicenseType))
                {
                    try
                    {
                        dal.Insert(p);
                    }
                    catch (Exception e)
                    {
                        new BandlGateway().PublishException(e);
                        throw;
                    }
                }
            }
            // Go through the local licenses.  Delete each one not present in 
            // the list of remote licenses.  Update each one present if necessary.
            foreach(ProductLicenseDetails l in localLicenses)
            {
                if ((r = remoteLicenses.Find(l.LicenseType)) == null)
                {
                    try
                    {
                        // Certain license keys may not be deleted because
                        // they are not "licenses" per se, but rather things
                        // like web services passwords.
                        switch (l.LicenseType)
                        {
                            case LicenseTypes.Bandl:
                            case LicenseTypes.Recall:
                            case LicenseTypes.Failure:
                                break;
                            default:
                                dal.Delete(l.LicenseType);
                                break;
                        }
                    }
                    catch (Exception e)
                    {
                        new BandlGateway().PublishException(e);
                        throw;
                    }
                }
                else
                {
                    if (l.Units != r.Units) l.Units = r.Units;
                    if (l.IssueDate != r.IssueDate) l.IssueDate = r.IssueDate;
                    if (l.ExpireDate != r.ExpireDate) l.ExpireDate = r.ExpireDate;
                    // Update if modified
                    if (l.ObjState == ObjectStates.Modified) 
                    {
                        try
                        {
                            dal.Update(l);
                        }
                        catch (Exception e)
                        {
                            new BandlGateway().PublishException(e);
                            throw;
                        }
                    }
                }
            }
        }

        /// <summary>
        /// Determines whether or not a license is beeng violated
        /// </summary>
        /// <param name="licenseType">
        /// Type of license to check
        /// </param>
        /// <returns>
        /// True if system is within bounds of license, else false
        /// </returns>
        public static bool CheckLicense(LicenseTypes licenseType)
        {
            ProductLicenseDetails p = ProductLicense.GetProductLicense(licenseType);
            if (p == null) throw new ApplicationException("License not found (" + licenseType.ToString() + ")");
            // If unlimited units, return true
            if (p.Units == ProductLicenseDetails.Unlimited) return true;
            // Evaluate the license
            switch (licenseType)
            {
                case LicenseTypes.Days:
                    return Convert.ToDateTime(p.IssueDate).AddDays(p.Units) > Time.UtcToday;
                case LicenseTypes.Operators:
                    return p.Units >= Operator.GetOperatorCount();
                case LicenseTypes.Media:
                    return p.Units >= Medium.GetMediumCount();
                case LicenseTypes.RFID:
                    return p.Units == 1;
                default:
                    return false;
            }
        }

        /// <summary>
        /// Sets the date of failure to contact B&L web service
        /// </summary>
        /// <param name="licenseType">
        /// Type of license to check
        /// </param>
        /// <returns>
        /// True if system is within bounds of license, else false
        /// </returns>
        public static void SetContactFailure(DateTime d)
        {
            ProductLicenseDetails p = ProductLicense.GetProductLicense(LicenseTypes.Failure);
            // If we have a failure value, update it; otherwise insert
            if (p == null) 
            {
                p = new ProductLicenseDetails(LicenseTypes.Failure, -1, d, d);
                ProductLicenseFactory.Create().Insert(p);
            }
            else
            {
                p.Units = -1;
                p.IssueDate = d.ToString("yyyy-MM-dd");
                p.ExpireDate = d.ToString("yyyy-MM-dd");
                ProductLicenseFactory.Create().Update(p);
            }
        }
    }
}
