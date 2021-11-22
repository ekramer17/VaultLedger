using System;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.DALFactory;
using Bandl.Library.VaultLedger.IDAL;
using Bandl.Library.VaultLedger.Security;
using Bandl.Library.VaultLedger.Collections;
using Bandl.Library.VaultLedger.Exceptions;

namespace Bandl.Library.VaultLedger.BLL
{
	/// <summary>
	/// Summary description for SealedCase.
	/// </summary>
	public class SealedCase
	{
        /// <summary>
        /// Returns the profile information for a specific sealed case
        /// </summary>
        /// <param name="caseName">
        /// Name of the case
        /// </param>
        /// <returns>
        /// Profile information for the case
        /// </returns>
        public static SealedCaseDetails GetSealedCase(string caseName) 
        {
            if(caseName == null)
            {
                throw new ArgumentNullException("Case name may not be null.");
            }
            else if (caseName == String.Empty)
            {
                throw new ArgumentException("Case name may not be an empty string.");
            }
            else
            {
                return SealedCaseFactory.Create().GetSealedCase(caseName);
            }
        }

        /// <summary>
        /// Gets the sealed cases for the browse page
        /// </summary>
        /// <returns>
        /// A sealed case collection
        /// </returns>
        public static SealedCaseCollection GetSealedCases()
        {
            return SealedCaseFactory.Create().GetSealedCases();
        }

        /// <summary>
        /// Removes a medium from its sealed case
        /// </summary>
        /// <param name="m">
        /// Medium to remove from its sealed case
        /// </param>
        public static void Insert(SealedCaseDetails c)
        {
            if(c == null)
            {
                throw new ArgumentNullException("Reference must be set to an instance of a sealed case object.");
            }
            else
            {
                SealedCaseFactory.Create().Insert(c);
            }
        }

        /// <summary>
        /// Inserts a medium into a sealed case
        /// </summary>
        /// <param name="caseName">
        /// Name of the case into which to insert the medium
        /// </param>
        /// <param name="serialNo">
        /// Serial number of the medium to place in the case
        /// </param>
        public static void InsertMedium(string caseName, string serialNo)
        {
            if(caseName == null)
            {
                throw new ArgumentNullException("Case name may not be null.");
            }
            else if (caseName == String.Empty)
            {
                throw new ArgumentException("Case name may not be an empty string.");
            }
            else if(serialNo == null)
            {
                throw new ArgumentNullException("Serial number may not be null.");
            }
            else if (serialNo == String.Empty)
            {
                throw new ArgumentException("Serial number may not be an empty string.");
            }
            else
            {
                SealedCaseFactory.Create().InsertMedium(caseName, serialNo);
            }
        }

        /// <summary>
        /// Inserts media into a sealed case
        /// </summary>
        /// <param name="caseName">
        /// Name of the case into which to insert the medium
        /// </param>
        /// <param name="media">
        /// Media to insert into the case
        /// </param>
        public static void InsertMedia(string caseName, MediumCollection media)
        {
            if (caseName == null)
                throw new ArgumentNullException("Case name may not be null.");
            else if (caseName == String.Empty)
                throw new ArgumentException("Case name may not be an empty string.");

            using (IConnection c = ConnectionFactory.Create().Open())
            {
                // Begin a transaction
                c.BeginTran();
                // Initialize a data access layer object with the connection
                ISealedCase dal = SealedCaseFactory.Create(c);
                // Remove
                foreach (MediumDetails m in media)
                {
                    try
                    {
                        dal.InsertMedium(caseName, m.SerialNo);
                        m.RowError = String.Empty;
                    }
                    catch (Exception e)
                    {
                        m.RowError = e.Message;
                        media.HasErrors = true;
                    }
                }
                // Rollback the transaction if an error occurred.  Otherwise
                // commit the transaction.
                if (media.HasErrors == true)
                {
                    c.RollbackTran();
                    throw new CollectionErrorException(media);
                }
                else
                {
                    c.CommitTran();
                }
            }
        }

        /// <summary>
        /// Removes a medium from its sealed case
        /// </summary>
        /// <param name="m">
        /// Medium to remove from its sealed case
        /// </param>
        public static void RemoveMedium(MediumDetails m)
        {
            if(m == null)
            {
                throw new ArgumentNullException("Reference must be set to an instance of a medium object.");
            }
            else if (m.CaseName.Length == 0)
            {
                throw new ArgumentException("Medium does not appear to reside in a sealed case.");
            }
            else
            {
                SealedCaseFactory.Create().RemoveMedium(m);
            }
        }

        /// <summary>
        /// Removes a medium from its sealed case
        /// </summary>
        /// <param name="m">
        /// Medium to remove from its sealed case
        /// </param>
        public static void RemoveMedia(MediumCollection m)
        {
            using (IConnection c = ConnectionFactory.Create().Open())
            {
                // Begin a transaction
                c.BeginTran();
                // Initialize a data access layer object with the connection
                ISealedCase dal = SealedCaseFactory.Create(c);
                // Remove
                foreach (MediumDetails m2 in m)
                {
                    try
                    {
                        dal.RemoveMedium(m2);
                        m2.RowError = String.Empty;
                    }
                    catch (Exception e)
                    {
                        m2.RowError = e.Message;
                        m.HasErrors = true;
                    }
                }
                // Rollback the transaction if an error occurred.  Otherwise
                // commit the transaction.
                if (m.HasErrors == true)
                {
                    c.RollbackTran();
                    throw new CollectionErrorException(m);
                }
                else
                {
                    c.CommitTran();
                }
            }
        }

        /// <summary>
        /// Gets all of the media in a case
        /// </summary>
        /// <param name="caseName">
        /// Name of the sealed case
        /// </param>
        /// <returns>
        /// Collection of the media in the case
        /// </returns>
        public static MediumCollection GetResidentMedia(string caseName)
        {
            if(caseName == null)
            {
                throw new ArgumentNullException("Case name may not be null.");
            }
            else if (caseName == String.Empty)
            {
                throw new ArgumentException("Case name may not be an empty string.");
            }
            else
            {
                return SealedCaseFactory.Create().GetResidentMedia(caseName);
            }
        }

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
        public static MediumCollection GetVerifiedMedia(string caseName)
        {
            if(caseName == null)
            {
                throw new ArgumentNullException("Case name may not be null.");
            }
            else if (caseName == String.Empty)
            {
                throw new ArgumentException("Case name may not be an empty string.");
            }
            else
            {
                return SealedCaseFactory.Create().GetVerifiedMedia(caseName);
            }
        }

        /// <summary>
        /// Updates the attributes for a collection of cases.  This method
        /// iterates through the collection and updates each case.  If an 
        /// error occurs on any item, the transaction is rolled back and 
        /// the HasErrors property of the collection is set to true.  Each 
        /// item that resulted in error will have its RowError property set 
        /// with an error description.
        /// </summary>
        /// <param name="cc">
        /// Collection of sealed cases
        /// </param>
        public static void Update(ref SealedCaseCollection cc) 
        {
            // Must have librarian privileges
            CustomPermission.Demand(Role.Operator);
            // Validate the input data
            if (cc == null)
            {
                throw new ArgumentNullException("Reference must be set to an instance of a sealed case collection object.");
            }
            // Reset the error flag
            cc.HasErrors = false;
            // Create a connection for the data access layer object
            using (IConnection c = ConnectionFactory.Create().Open())
            {
                // Begin a transaction
                c.BeginTran();
                // Initialize a data access layer object with the connection
                ISealedCase dal = SealedCaseFactory.Create(c);
                // Remove each item from the list
                foreach(SealedCaseDetails d in cc)
                {
                    try
                    {
                        dal.Update(d);
                        d.RowError = String.Empty;
                    }
                    catch (Exception e)
                    {
                        d.RowError = e.Message;
                        cc.HasErrors = true;
                    }
                }
                // Rollback the transaction if an error occurred.  Otherwise
                // commit the transaction.
                if (cc.HasErrors == true)
                {
                    c.RollbackTran();
                    throw new CollectionErrorException(cc);
                }
                else
                {
                    c.CommitTran();
                    // Refresh the items in the collection
                    for (int i = 0; i < cc.Count; i++)
                        cc.Replace(cc[i], dal.GetSealedCase(cc[i].CaseName));
                }
            }
        }

        /// <summary>
        /// Deletes a sealed case
        /// </summary>
        /// <param name="o">Operator to delete</param>
        public static void Delete(SealedCaseDetails d)
        {
            // Must have operator privileges
            CustomPermission.Demand(Role.Operator);
            // Make sure that the data is not new
            if (d == null)
            {
                throw new ArgumentNullException("Reference must be set to an instance of an sealed case object.");
            }
            else if (d.ObjState != ObjectStates.Unmodified)
            {
                throw new ObjectStateException("Only an operator marked as unmodified may be deleted.");
            }
            else
            {
                SealedCaseFactory.Create().Delete(d);
            }
        }
    }
}
