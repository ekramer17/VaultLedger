using System;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.Collections;

namespace Bandl.Library.VaultLedger.IDAL
{
    /// <summary>
    /// Inteface for the Sealed Case DAL
    /// </summary>
    public interface ISealedCase
    {
        /// <summary>
        /// Returns the profile information for a specific case
        /// </summary>
        SealedCaseDetails GetSealedCase(string caseName);

        /// <summary>
        /// Inserts an empty sealed case
        /// </summary>
        /// <param name="c">
        /// Sealed case details to insert
        /// </param>
        Int32 Insert(SealedCaseDetails c);

        /// <summary>
        /// Inserts a medium into a sealed case
        /// </summary>
        /// <param name="caseName">
        /// Name of the case into which to insert the medium
        /// </param>
        /// <param name="serialNo">
        /// Serial number of the medium to place in the case
        /// </param>
        void InsertMedium(string caseName, string serialNo);
            
        /// <summary>
        /// Removes a medium from its sealed case
        /// </summary>
        /// <param name="m">
        /// Medium to remove from its sealed case
        /// </param>
        void RemoveMedium(MediumDetails m);

        /// <summary>
        /// Gets the recall codes for a list of case names.  Used
        /// when creating list objects for the web service.
        /// </summary>
        /// <param name="caseNames">
        /// Array of caseNames
        /// </param>
        /// <returns>
        /// Array of same length as given array, containing the 
        /// corresponding recall code at each index
        /// </returns>
        string[] GetRecallCodes(params string[] caseNames);

        /// <summary>
        /// Gets all of the media in a case
        /// </summary>
        /// <param name="caseName">
        /// Name of the sealed case
        /// </param>
        /// <returns>
        /// Collection of the media in the case
        /// </returns>
        MediumCollection GetResidentMedia(string caseName);
            
        /// <summary>
        /// Gets the media in the case that are verified on an active
        /// receive list.
        /// </summary>
        /// <param name="caseName">
        /// Name of the sealed case
        /// </param>
        /// <returns>
        /// Collection of the verified media
        /// </returns>
        MediumCollection GetVerifiedMedia(string caseName);

        /// <summary>
        /// Gets the sealed cases for the browse page
        /// </summary>
        /// <returns>
        /// A sealed case collection
        /// </returns>
        SealedCaseCollection GetSealedCases();

        /// <summary>
        /// Updates a sealed case
        /// </summary>
        void Update(SealedCaseDetails d);

        ///<summary>
        /// Deletes a sealed case
        /// </summary>
        void Delete(SealedCaseDetails d);
    }
}
