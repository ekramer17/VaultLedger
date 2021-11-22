using System;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.Security;
using Bandl.Library.VaultLedger.DALFactory;
using Bandl.Library.VaultLedger.Exceptions;
using Bandl.Library.VaultLedger.Collections;

namespace Bandl.Library.VaultLedger.BLL
{
	/// <summary>
	/// Business object for FTP Profile
	/// </summary>
	public class FtpProfile
	{
        /// <summary>
        /// Gets an FTP profile
        /// </summary>
        /// <param name="id">
        /// Name of profile to retrieve
        /// </param>
        public static FtpProfileDetails GetProfile(int id)
        {
            return FtpProfileFactory.Create().GetProfile(id);
        }

        /// <summary>
        /// Gets an FTP profile
        /// </summary>
        /// <param name="profileName">
        /// Name of profile to retrieve
        /// </param>
        public static FtpProfileDetails GetProfile(string profileName)
        {
            if(profileName == null)
            {
                throw new ArgumentNullException("Profile name may not be null.");
            }
            else if (profileName == String.Empty)
            {
                throw new ArgumentException("Profile name may not be an empty string.");
            }
            else
            {
                return FtpProfileFactory.Create().GetProfile(profileName);
            }
        }

        /// <summary>
        /// Gets all the profiles for all the accounts in the system
        /// </summary>
        /// <returns>
        /// Collection of all FTP profiles in the database
        /// </returns>
        public static FtpProfileCollection GetProfiles()
        {
            return FtpProfileFactory.Create().GetProfiles();
        }
 
        /// <summary>
        /// Inserts an FTP profile into the system
        /// </summary>
        /// <param name="ftp">
        /// FTP profile to insert
        /// </param>
        public static void Insert(ref FtpProfileDetails ftp)
        {
            // Must have administrator privileges
            CustomPermission.Demand(Role.Administrator);
            // Make sure that the data is new
            if (ftp == null)
            {
                throw new ArgumentNullException("Reference must be set to an instance of an FTP profile object.");
            }
            else if(ftp.ObjState != ObjectStates.New)
            {
                throw new ObjectStateException("Only an FTP profile marked as new may be inserted.");
            }
            // Reset the error flag
            ftp.RowError = String.Empty;
            // Insert the pattern
            try
            {
                FtpProfileFactory.Create().Insert(ftp);
                ftp = GetProfile(ftp.Name);
            }
            catch (Exception e)
            {
                ftp.RowError = e.Message;
                throw;
            }
        }
            
        /// <summary>
        /// Updates an FTP profile
        /// </summary>
        /// <param name="ftp">
        /// FTP profile to update
        /// </param>
        public static void Update(ref FtpProfileDetails ftp)
        {
            // Must have administrator privileges
            CustomPermission.Demand(Role.Administrator);
            // Make sure that the data is new
            if (ftp == null)
            {
                throw new ArgumentNullException("Reference must be set to an instance of an FTP profile object.");
            }
            else if(ftp.ObjState != ObjectStates.Modified)
            {
                throw new ObjectStateException("Only an FTP profile marked as modified may be inserted.");
            }
            // Reset the error flag
            ftp.RowError = String.Empty;
            // Insert the pattern
            try
            {
                FtpProfileFactory.Create().Update(ftp);
                ftp = GetProfile(ftp.Id);
            }
            catch (Exception e)
            {
                ftp.RowError = e.Message;
                throw;
            }
        }

        /// <summary>
        /// Deletes an FTP profile from the system
        /// </summary>
        /// <param name="ftp">
        /// FTP profile to delete
        /// </param>
        public static void Delete(FtpProfileDetails ftp)
        {
            // Must have administrator privileges
            CustomPermission.Demand(Role.Administrator);
            // Delete the FTP profile
            FtpProfileFactory.Create().Delete(ftp);
        }
    }
}
