using System;
using System.Text;
using System.Collections;
using System.Collections.Specialized;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.DALFactory;
using Bandl.Library.VaultLedger.IDAL;
using Bandl.Library.VaultLedger.Security;
using Bandl.Library.VaultLedger.Collections;
using Bandl.Library.VaultLedger.Exceptions;

namespace Bandl.Library.VaultLedger.BLL
{
    /// <summary>
    /// A business component used to manage media.
    /// The Bandl.Library.VaultLedger.Model.MediumDetails is used in most 
    /// methods and is used to store serializable information about a medium.
    /// </summary>
    public class Medium
	{
        public static int GetMediumCount()
        {
            return MediumFactory.Create().GetMediumCount();
        }

        /// <summary>
        /// Returns the profile information for a specific medium
        /// </summary>
        /// <param name="serialNo">Unique serial number of a medium</param>
        /// <returns>Returns the profile information for the medium</returns>
        public static MediumDetails GetMedium(string serialNo) 
        {
            if(serialNo == null)
            {
                throw new ArgumentNullException("Serial number may not be null.");
            }
            else if (serialNo == String.Empty)
            {
                throw new ArgumentException("Serial number may not be an empty string.");
            }
            else
            {
                return MediumFactory.Create().GetMedium(serialNo);
            }
        }

        /// <summary>
        /// Returns the profile information for a specific medium
        /// </summary>
        /// <param name="id">Unique identifier of a medium</param>
        /// <returns>Returns the profile information for the medium</returns>
        public static MediumDetails GetMedium(int id) 
        {
            if (id <= 0)
            {
                throw new ArgumentException("Medium id must be greater than zero.");
            }
            else
            {
                return MediumFactory.Create().GetMedium(id);
            }
        }

        /// <summary>
        /// Returns a page of the contents of the Medium table
        /// </summary>
        /// <returns>Returns a collection of media that fit the given filter in the given sort order</returns>
        public static MediumCollection GetMediumPage(int pageNo, int pageSize, MediumFilter mf, MediumSorts sortColumn, out int totalMedia) 
        {
            if (pageNo <= 0)
            {
                throw new ArgumentException("Page number must be greater than zero.");
            }
            else if (pageSize <= 0)
            {
                throw new ArgumentException("Page size must be greater than zero.");
            }
            else if ((mf.Filter & MediumFilter.FilterKeys.SerialStart) != 0 && (mf.Filter & MediumFilter.FilterKeys.SerialEnd) != 0 && mf.StartingSerialNo.IndexOf(',') != -1)
            {
                throw new ArgumentException("Ending serial number cannot be used when multiple starting serial number search strings are supplied.");
            }
            else
            {
                return MediumFactory.Create().GetMediumPage(pageNo, pageSize, mf, sortColumn, out totalMedia);
            }
        }

        private static Role InsertRequiredRole
        {
            get
            {
                if (Preference.GetPreference(PreferenceKeys.CreateTapesAdminOnly).Value[0] == 'N')
                    return Role.Operator;
                else
                    return Role.Administrator;
            }
        }

        /// <summary>
        /// A method to insert a single new medium
        /// </summary>
        /// <param name="serialNo">
        /// Serial number to add
        /// </param>
        /// <param name="loc">
        /// Original location of medium
        /// </param>
        public static void Insert(string serialNo, Locations loc)
        {
            // Must have librarian privileges
            CustomPermission.Demand(InsertRequiredRole);
            // Make sure that the data is new
            if(serialNo == null || serialNo.Length == 0)
            {
                throw new ArgumentNullException("Serial number cannot be an empty string.");
            }
            else
            {
                MediumFactory.Create().Insert(serialNo, loc);
            }
        }

        /// <summary>
        /// A method to insert a new medium
        /// </summary>
        /// <param name="m">A details entity with new medium information to insert</param>
        public static void Insert(ref MediumDetails m) 
        {
            // Reset the error flag
            m.RowError = String.Empty;
            // Must have librarian privileges
            CustomPermission.Demand(InsertRequiredRole);
            // Make sure that the data is new
            if(m == null)
            {
                throw new ArgumentNullException("Reference must be set to an instance of a medium object.");
            }
            else if(m.ObjState != ObjectStates.New)
            {
                throw new ObjectStateException("Only a medium marked as new may be inserted.");
            }
            // Insert the medium
            try
            {
                MediumFactory.Create().Insert(m);
                m = GetMedium(m.SerialNo);
            }
            catch (Exception e)
            {
                m.RowError = e.Message;
                throw;
            }
        }

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
        public static int Insert(string start, string end, Locations loc, out MediumRange[] subRanges)
        {
            subRanges = null;
            // Must have addition privileges
            try
            {
                CustomPermission.Demand(InsertRequiredRole);
            }
            catch
            {
                throw new ApplicationException("Medium not found and only administrators may add media.");
            }
            // Make sure that start is leq end, that the two strings are of
            // identical lengths, and that the characters of the strings line
            // up correctly.
            if (start == null || end == null)
            {
                throw new ValueNullException("Neither the start or the end of the range to be added may be null.");
            }
            else if (start.Length != end.Length || start.Length == 0)
            {
                throw new ValueException("The start and the end of the range must be non-empty strings of the same length.");
            }
            else if (start.CompareTo(end) > 0)
            {
                throw new ValueException("The end of the range must be greater than the start.");
            }
            else
            {
                Medium.ValidateSerialNumbers(start, end);
            }
            // Call the DAL to insert the media
            return MediumFactory.Create().Insert(start, end, loc, out subRanges);
        }

        /// <summary>
        /// Allows the user to see the medium types and accounts for the sub ranges
        /// prior to committing additional media to the databsae.
        /// </summary>
        /// <param name="start">
        /// Starting serial number of range
        /// </param>
        /// <param name="end">
        /// Ending serial number of range
        /// </param>
        /// <param name="subRanges">
        /// The subranges within the range, delimited by difference in account
        /// and/or medium type
        /// </param>
        public static void PreviewInsert(string startNo, string endNo, out MediumRange[] subRanges)
        {
            subRanges = null;
            string serialNo = String.Empty;
            string mediumType = String.Empty;
            string accountName = String.Empty;
            ArrayList rangeList = new ArrayList();
            // Must have librarian privileges
            CustomPermission.Demand(InsertRequiredRole);
            // Validate the input
            if (startNo == null || endNo == null)
            {
                throw new ValueNullException("Neither the start or the end of the range to be added may be null.");
            }
            else if (startNo.Length != endNo.Length || startNo.Length == 0)
            {
                throw new ValueException("The start and the end of the range must be non-empty strings of the same length.");
            }
            else if (startNo.CompareTo(endNo) > 0)
            {
                throw new ValueException("The end of the range must be greater than the start.");
            }
            else
            {
                Medium.ValidateSerialNumbers(startNo, endNo);
            }
            // Create the first medium range and add it to the range list
            PatternDefaultMedium.GetAttributes(startNo, out accountName, out mediumType);
            MediumRange currentRange = new MediumRange(startNo, startNo, mediumType, accountName);
            serialNo = Medium.NextSerialNumber(startNo);
            rangeList.Add(currentRange);
            // Run through the medium serial numbers, getting medium type and account for each
            while (serialNo.CompareTo(endNo) <= 0)
            {
                PatternDefaultMedium.GetAttributes(serialNo, out accountName, out mediumType);
                // If the account and medium type matches the current range, set the end of the
                // current range to the current serial number.  Otherwise start a new range.
                if (accountName == currentRange.AccountName && mediumType == currentRange.MediumType)
                {
                    currentRange.SerialEnd = serialNo;
                }
                else
                {
                    currentRange = new MediumRange(serialNo, serialNo, mediumType, accountName);
                    rangeList.Add(currentRange);
                }
                // Get the next serial number
                serialNo = Medium.NextSerialNumber(serialNo);
            }
            // Convert the ranges to an array
            subRanges = (MediumRange[])rangeList.ToArray(typeof(MediumRange));
        }
        /// <summary>
        /// This is a special update method used for designating a medium as 
        /// missing.  It is necessary because when a medium is missing from
        /// a sealed case, we need to perform extra steps.
        /// </summary>
        /// <param name="m">
        /// Medium to update
        /// </param>
        /// <param name="caseAction">
        /// What to do if a medium is in a sealed case.  There are three
        /// possible values for this parameter: 0 (unknown), 1 (designate
        /// this medium only), or 2 (designate all media in case).  If
        /// any other value is given, the method will interpret it as 0.
        /// </param>
        /// <returns>
        /// True on success, false if caseAction was required but 0 was passed.
        /// A return value of false should cause the calling page to ask
        /// the user what he would like to do, and then call this function
        /// again with the value of caseAction in line with the option
        /// the user selected.
        /// </returns>
        public static bool Update(ref MediumCollection mediumCollection, int caseAction)
        {
            // Reset the error flag
            mediumCollection.HasErrors = false;
            // Enforce security
            CustomPermission.Demand(Role.Operator);
            // Make sure that the data is modified
            if (mediumCollection == null)
            {
                throw new ArgumentNullException("Reference must be set to an instance of a medium object collection.");
            }
            else if (mediumCollection.Count == 0)
            {
                return true;
            }

            using (IConnection c = ConnectionFactory.Create().Open())
            {
                c.BeginTran("update medium");
                mediumCollection.HasErrors = false;
                IMedium dalMedium = MediumFactory.Create(c);
                ISealedCase dalCase = SealedCaseFactory.Create(c);

                foreach (MediumDetails m in mediumCollection)
                {
                    try
                    {
                        m.RowError = String.Empty;
                        // Refresh the medium object, because there is a decent chance that
                        // the medium is already missing if it was in a sealed case.  On a
                        // receive list, for example, if a medium is marked missing, often
                        // all of the other media in the case will be marked missing.  If
                        // we didn't do this, then these other media would have incorrect
                        // rowversion timestamps on update attempt.
                        MediumDetails medium = dalMedium.GetMedium(m.Id);
                        // If missing status has not been updated, then no special
                        // treatment is necessary.
                        if (m.Missing == medium.Missing)
                        {
                            dalMedium.Update(m);
                            continue;
                        }
                        // If the medium is not in a case, then no special
                        // treatment is necessary.
                        if (0 == medium.CaseName.Length)
                        {
                            dalMedium.Update(m);
                            continue;
                        }
                        // If the medium is in a sealed case and any medium
                        // other than this one appears on a receive list as
                        // verified, force the caseAction to individual
                        // medium removal.
                        if (caseAction != 1)
                            if (ReceiveList.SealedCaseVerified(medium.CaseName, medium.SerialNo))
                                caseAction = 1;
                        // If none were verified, then we need to determine whether to mark
                        // only the single media given to this method (caseAction = 1) or 
                        // all media in the case (caseAction = 2) as missing.  If the latter, 
                        // then we don't remove the item from the case; otherwise we do.
                        switch (caseAction)
                        {
                            case 1:
                                dalCase.RemoveMedium(m);
                                dalMedium.Update(m);
                                break;
                            case 2:
                                dalMedium.Update(m);
                                break;
                            default:
                                c.RollbackTran();
                                return false;
                        }

                    }
                    catch (Exception ex)
                    {
                        mediumCollection.HasErrors = true;
                        m.RowError = ex.Message;
                    }
                }
                // If errors then throw exception.  Otherwise, if the case
                // action does not require sealed case operations, commit 
                // the transaction and return true.
                if (mediumCollection.HasErrors)
                {
                    c.RollbackTran();
                    throw new CollectionErrorException(mediumCollection);
                }
                else if (caseAction != 2)
                {
                    c.CommitTran();
                    return true;
                }
                // If the case action was 2, then we need to run through the media
                // and make sure that all media in sealed cases have consistent
                // missing status values.  We must do this after the update above
                // so as to not throw off any rowversions.  Specifically, if a tape
                // in a sealed case is updated as missing, and then is later updated
                // in the collection, the rowversion will be incongruous.
                StringCollection usedCases = new StringCollection();
                foreach(MediumDetails m in mediumCollection)
                {
                    try
                    {
                        bool caseDone = false;
                        if (m.CaseName.Length != 0)
                        {
                            foreach (object caseName in usedCases)
                            {
                                if (m.CaseName == (string)caseName)
                                {
                                    caseDone = true;
                                    break;
                                }
                            }
                            // Case hasn't been done yet.  Process it.
                            if (caseDone == false)
                            {
                                // Get all of the media in the case
                                MediumCollection caseMedia = dalMedium.GetMediaInCase(m.CaseName);
                                // Update all the media in the case besides the current medium
                                for (int i = 0; i < caseMedia.Count; i++)
                                {
                                    MediumDetails updateMedium = caseMedia[i];
                                    if (updateMedium.Id != m.Id && updateMedium.Missing != m.Missing)
                                    {
                                        updateMedium.Missing = m.Missing;
                                        dalMedium.Update(updateMedium);
                                    }
                                }
                                // Add to the processed case list
                                usedCases.Add(m.CaseName);
                            }
                        }
                    }
                    catch (Exception ex)
                    {
                        mediumCollection.HasErrors = true;
                        m.RowError = ex.Message;
                    }
                }
                // If errors then throw exception.  Otherwise commit the
                // transaction and return true.
                if (mediumCollection.HasErrors)
                {
                    c.RollbackTran();
                    throw new CollectionErrorException(mediumCollection);
                }
                else
                {
                    c.CommitTran();
                    return true;
                }
            }
        }

        /// <summary>
        /// A method to update an existing medium
        /// </summary>
        /// <param name="m">
        /// A details entity with information about the medium to be updated
        /// </param>
        /// <param name="caseAction">
        /// What to do if a medium is in a sealed case.  There are three
        /// possible values for this parameter: 0 (unknown), 1 (designate
        /// this medium only), or 2 (designate all media in case).  If
        /// any other value is given, the method will interpret it as 0.
        /// </param>
        /// <returns>
        /// True on success, false if caseAction was required but 0 was passed.
        /// A return value of false should cause the calling page to ask
        /// the user what he would like to do, and then call this function
        /// again with the value of caseAction in line with the option
        /// the user selected.
        /// </returns>
        public static bool Update(ref MediumDetails m, int caseAction) 
        {
            // Reset the error flag
            m.RowError = String.Empty;
            // Must have librarian privileges
            CustomPermission.Demand(Role.Operator);
            // Make sure that the data is modified
            if(m == null)
            {
                throw new ArgumentNullException("Reference must be set to an instance of a medium object.");
            }
            else if(m.ObjState != ObjectStates.Modified)
            {
                throw new ObjectStateException("Only a medium marked as modified may be updated.");
            }
            // Update the medium
            try
            {
                // Place in a collection to pass to Update overload
                MediumCollection mediumCollection = new MediumCollection();
                mediumCollection.Add(m);
                // Update the medium
                bool returnValue = Update(ref mediumCollection, caseAction);
                // Fetch the medium on success
                if (returnValue == true)
                {
                    m = GetMedium(m.Id);
                }
                // Return
                return returnValue;
            }
            catch (CollectionErrorException)
            {
                throw new ApplicationException(m.RowError);
            }
            catch (Exception e)
            {
                m.RowError = e.Message;
                throw;
            }
        }

        public static void Delete(ref MediumCollection mediumCollection)
        {
            // Reset the error flag
            mediumCollection.HasErrors = false;
            // Enforce security
            CustomPermission.Demand(Role.Operator);
            // Make sure that we have a collection
            if (mediumCollection == null)
            {
                throw new ArgumentNullException("Reference must be set to an instance of a medium object collection.");
            }
            else if (mediumCollection.Count == 0)
            {
                return;
            }

            using (IConnection c = ConnectionFactory.Create().Open())
            {
                c.BeginTran("update medium");
                mediumCollection.HasErrors = false;
                IMedium dal = MediumFactory.Create(c);
                // Delete each of the media
                foreach(MediumDetails m in mediumCollection)
                {
                    try
                    {
                        if (m.ObjState != ObjectStates.Unmodified)
                        {
                            throw new ObjectStateException("Only a medium marked as unmodified may be deleted.");
                        }
                        else
                        {
                            dal.Delete(m);
                            m.RowError = String.Empty;
                        }
                    }
                    catch (Exception ex)
                    {
                        m.RowError = ex.Message;
                        mediumCollection.HasErrors = true;
                    }
                }
                // If we have errors, throw a collection error exception.  Else
                // commit the transaction and set the status of each to deleted.
                if (mediumCollection.HasErrors)
                {
                    c.RollbackTran();
                    throw new CollectionErrorException(mediumCollection);
                }
                else
                {
                    c.CommitTran();
                    for (int i = 0; i < mediumCollection.Count; i++)
                    {
                        MediumDetails m = mediumCollection[i];
                        m.ObjState = ObjectStates.Deleted;
                    }
                }
            }
        }

        /// <summary>
        /// Deletes an existing medium
        /// </summary>
        /// <param name="m">Medium to delete</param>
        public static void Delete(ref MediumDetails m)
        {
            // Reset the error flag
            m.RowError = String.Empty;
            // Must have librarian privileges
            CustomPermission.Demand(Role.Operator);
            // Make sure that the data is unmodified
            if(m == null)
            {
                throw new ArgumentNullException("Reference must be set to an instance of a medium object.");
            }
            else if(m.ObjState != ObjectStates.Unmodified)
            {
                throw new ObjectStateException("Only a medium marked as unmodified may be deleted.");
            }
            // Delete the medium
            try
            {
                // Wrap in a collection
                MediumCollection mediumCollection = new MediumCollection();
                mediumCollection.Add(m);
                // Submit to the overloaded delete method
                Medium.Delete(ref mediumCollection);
            }
            catch (CollectionErrorException)
            {
                throw new ApplicationException(m.RowError);
            }
            catch (Exception e)
            {
                m.RowError = e.Message;
                throw;
            }
        }

        /// <summary>
        /// Deletes a range of media
        /// </summary>
        /// <param name="start">
        /// Starting serial number of the range to delete
        /// </param>
        /// <param name="end">
        /// Ending serial number of the range to delete
        /// </param>
        public static void Delete(string start, string end)
        {
            // Must have librarian privileges
            CustomPermission.Demand(Role.Operator);
            // Make sure that start is leq end, that the two strings are of
            // identical lengths, and that the characters of the strings line
            // up correctly.
            if (start == null || end == null)
            {
                throw new ValueNullException("Neither the start or the end of the range to be deleted may be null.");
            }
            else if (start.Length != end.Length || start.Length == 0)
            {
                throw new ValueException("The start and the end of the range must be non-empty strings of the same length.");
            }
            else if (start.CompareTo(end) > 0)
            {
                throw new ValueException("The end of the range must be greater than the start.");
            }
            else
            {
                ValidateSerialNumbers(start, end);
            }
            // Call the DAL to delete the media in the range
            MediumFactory.Create().Delete(start, end);
        }

        /// <summary>
        /// Destroys media
        /// </summary>
        /// <param name="c1">Media to delete</param>
        public static void Destroy(MediumCollection c1)
        {
            String x1 = String.Empty;
            // Must have librarian privileges
            CustomPermission.Demand(Role.Operator);
            // Destroy the media
            foreach (MediumDetails m1 in c1)
            {
                x1 += String.Format(",{0}", m1.Id);
            }
            // Call the DAL to delete the media in the range
            MediumFactory.Create().Destroy(x1.Substring(1));
        }

        /// <summary>
        /// Validates a range of serial numbers
        /// </summary>
        /// <param name="start"></param>
        /// <param name="end"></param>
        private static void ValidateSerialNumbers(string start, string end)
        {
            if (start.Length != end.Length)
            {
                throw new ValueException("Range-delimiting serial numbers must be of same length.");
            }
            else
            {
                for(int i = 0; i < start.Length; i++)
                {
                    if (start[i] >= 48 && start[i] <= 57) // number
                    {
                        if (end[i] < 48 || end[i] > 57)
                        {
                            throw new ValueException("Alphas and numerics must be aligned by position.");
                        }
                    }
                    else if (start[i] >= 65 && start[i] <= 90) // uppercase alpha
                    {
                        if (end[i] < 65 || end[i] > 90)
                        {
                            throw new ValueException("Alphas and numerics must be aligned by position.");
                        }
                    }
                    else if (start[i] >= 97 && start[i] <= 122) // lowercase alpha
                    {
                        if (end[i] < 97 || end[i] > 122)
                        {
                            throw new ValueException("Alphas and numerics must be aligned by position.");
                        }
                    }
                    else 
                    {
                        throw new ValueException("Serial numbers may only consist of alphanumeric characters.");
                    }
                }
            }
        }
        /// <summary>
        /// Increments a serial number by one
        /// </summary>
        /// <param name="serial">
        /// Serial number to increment
        /// </param>
        /// <returns>
        /// Next serial number
        /// </returns>
        private static string NextSerialNumber(string serial)
        {
            // Get string as byte array
            byte[] b = Encoding.UTF8.GetBytes(serial);
            // Increment serial
            for (int i = b.Length; i > 0; i -= 1)
            {
                b[i-1] = (byte)((b[i-1]) + 1);
                switch (b[i-1])
                {
                    case 58:
                        b[i-1] = 48;
                        break;
                    case 91:
                        b[i-1] = 65;
                        break;
                    case 123:
                        b[i-1] = 97;
                        break;
                    default:
                        i = -1; // break loop
                        break;
                }
            }
            // Return string
            return Encoding.UTF8.GetString(b);
        }
		/// <summary>
		/// Updates notes on serial numbers
		/// </summary>
		/// <param name="s1">Serial numbers</param>
		/// <param name="n1">Note</param>
		/// <param name="r1">Replace if true, append if false</param>
		public static void DoNotes(String[] s1, String n1, Boolean r1)
		{
            MediumFactory.Create().DoNotes(s1, n1, r1);
		}
        /// <summary>
        /// Updates notes on serial numbers
        /// </summary>
        /// <param name="s1">Serial number</param>
        /// <param name="m1">Message</param>
        public static void Journalize(string s1, string m1)
        {
            MediumFactory.Create().Journalize(s1, m1);
        }
	}
}
