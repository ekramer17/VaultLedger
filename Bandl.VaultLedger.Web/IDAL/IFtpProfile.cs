using System;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.Collections;

namespace Bandl.Library.VaultLedger.IDAL
{
	/// <summary>
	/// Inteface for the Ftp Profile DAL
	/// </summary>
	public interface IFtpProfile
	{
        /// <summary>
        /// Gets an FTP profile
        /// </summary>
        /// <param name="id">
        /// Id of profile to retrieve
        /// </param>
        FtpProfileDetails GetProfile(int id);
            
        /// <summary>
        /// Gets an FTP profile
        /// </summary>
        /// <param name="profileName">
        /// Name of profile to retrieve
        /// </param>
        FtpProfileDetails GetProfile(string profileName);
            
		/// <summary>
		/// Gets an FTP profile using an account name
		/// </summary>
		/// <param name="accountName">
		/// Account name whose FTP profile to retrieve
		/// </param>
		FtpProfileDetails GetProfileByAccount(string accountName);
			
		/// <summary>
        /// Gets all the profiles for all the accounts in the system
        /// </summary>
        /// <returns>
        /// Collection of all FTP profiles in the database
        /// </returns>
        FtpProfileCollection GetProfiles();

        /// <summary>
        /// Inserts an FTP profile into the system
        /// </summary>
        /// <param name="ftp">
        /// FTP profile to insert
        /// </param>
        void Insert(FtpProfileDetails ftp);

        /// <summary>
        /// Updates an FTP profile
        /// </summary>
        /// <param name="ftp">
        /// FTP profile to update
        /// </param>
        void Update(FtpProfileDetails ftp);

        /// <summary>
        /// Deletes an FTP profile from the system
        /// </summary>
        /// <param name="ftp">
        /// FTP profile to delete
        /// </param>
        void Delete(FtpProfileDetails ftp);

        /// <summary>
        /// Gets the recall next list numbers
        /// </summary>
        /// <param name="accountName">Account name</param>
        /// <param name="sendNo">Send list number</param>
        /// <param name="receiveNo">Receive list number</param>
        /// <param name="disasterNo">Disaster list number</param>
        void GetRecallNumbers(string accountName, out int sendNo, out int receiveNo, out int disasterNo);

        /// <summary>
        /// Sets the recall next list numbers
        /// </summary>
        /// <param name="accountName">Account name</param>
        /// <param name="sendNo">Send list number</param>
        /// <param name="receiveNo">Receive list number</param>
        /// <param name="disasterNo">Disaster list number</param>
        void SetRecallNumbers(string accountName, int sendNo, int receiveNo, int disasterNo);
    }
}
