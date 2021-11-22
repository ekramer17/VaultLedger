using System;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.Collections;

namespace Bandl.Library.VaultLedger.IDAL
{
    /// <summary>
    /// Inteface for the Medium DAL
    /// </summary>
    public interface IMedium
    {
        /// <summary>
        /// Returns the profile information for a specific medium
        /// </summary>
        /// <param name="serialNo">Unique serial number of a medium</param>
        /// <returns>Returns the profile information for the medium</returns>
        MediumDetails GetMedium(string serialNo);

        /// <summary>
        /// Returns the profile information for a specific medium
        /// </summary>
        /// <param name="id">Unique identifier of a medium</param>
        /// <returns>Returns the profile information for the medium</returns>
        MediumDetails GetMedium(int id);

        /// <summary>
        /// Gets the number of media in the database
        /// </summary>
        /// <returns>
        /// Number of media in the database
        /// </returns>
        int GetMediumCount();

        /// <summary>
        /// Returns all the media in a given sealed case
        /// </summary>
        /// <returns>
        /// Returns a collection of media in the given sealed case
        /// </returns>
        MediumCollection GetMediaInCase(string caseName);

        /// <summary>
        /// Returns a page of the contents of the Medium table
        /// </summary>
        /// <returns>Returns a collection of media that fit the given filter in the given sort order</returns>
        MediumCollection GetMediumPage(int pageNo, int pageSize, MediumFilter filter, MediumSorts sortColumn, out int totalMedia);

        /// <summary>
        /// Gets the recall codes for a list of medium serial numbers.  Used
        /// mainly when creating list objects for the web service.
        /// </summary>
        /// <param name="serialNos">
        /// Array of medium serial numbers
        /// </param>
        /// <returns>
        /// Array of same length as given array, containing the 
        /// corresponding recall code at each index
        /// </returns>
        string[] GetRecallCodes(params string[] serialNos);

        /// <summary>
        /// A method to insert a new medium
        /// </summary>
        /// <param name="m">A details entity with new medium information to insert</param>
        void Insert(MediumDetails m);

        /// <summary>
        /// A method to insert a single new medium
        /// </summary>
        /// <param name="serialNo">
        /// Serial number to add
        /// </param>
        /// <param name="loc">
        /// Original location of medium
        /// </param>
        void Insert(string serialNo, Locations loc);

        /// <summary>
        /// A method to insert a range of new media
        /// </summary>
        /// <param name="start">
        /// Starting serial number of range
        /// </param>
        /// <param name="end">
        /// Ending serial number of range
        /// </param>
        /// <param name="loc">
        /// Original location of media
        /// </param>
        /// <param name="subRanges">
        /// The subranges within the range, delimited by difference in account
        /// and/or medium type
        /// </param>
        /// <returns>
        /// Number of media actually added
        /// </returns>
        int Insert(string start, string end, Locations loc, out MediumRange[] subRanges);

        /// <summary>
        /// Forces change to account (adds media if necessary), does not insert bar code formats
        /// </summary>
        void ForceAccount(string[] serials, Locations location, string accountNo);
            
        /// <summary>
        /// A method to insert a new medium and dictate the account and medium type.  Bar code
        /// formats will be adjusted if necessary.
        /// </summary>
//        int ForceAttributes(string serialNo, Locations location, string mediumType, string accountNo);

        /// <summary>
        /// A method to update an existing medium
        /// </summary>
        /// <param name="m">A details entity with information about the medium to be updated</param>
        void Update(MediumDetails m);

        /// <summary>
        /// Deletes an existing medium
        /// </summary>
        /// <param name="m">Medium to delete</param>
        void Delete(MediumDetails m);

        /// <summary>
        /// Deletes a range of media
        /// </summary>
        /// <param name="start">
        /// Starting serial number of the range to delete
        /// </param>
        /// <param name="end">
        /// Ending serial number of the range to delete
        /// </param>
        void Delete(string start, string end);

        /// <summary>
		/// Updates notes on serial numbers
		/// </summary>
		/// <param name="s1">Serial numbers</param>
		/// <param name="n1">Note</param>
		/// <param name="r1">Replace if true, append if false</param>
		void DoNotes(String[] s1, String n1, Boolean r1);

        /// <summary>
        /// Writes a journal message directly to XMedium table
        /// </summary>
        /// <param name="s1">Serial number</param>
        /// <param name="m1">Message</param>
        void Journalize(string s1, string m1);

        /// <summary>
        /// Updates notes on serial numbers
        /// </summary>
        /// <param name="i1">Comma-delimited list of medium id numbers</param>
        void Destroy(string i1);
	}
}
