using System;
using System.Collections;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.IDAL;
using Bandl.Library.VaultLedger.DALFactory;
using Bandl.Library.VaultLedger.Collections;
using Bandl.Library.VaultLedger.Exceptions;
using Bandl.Library.VaultLedger.Gateway.Bandl;
using Bandl.Library.VaultLedger.Gateway.Recall;
using Bandl.Library.VaultLedger.Security;

namespace Bandl.Library.VaultLedger.BLL
{
    /// <summary>
    /// A business component used to manage mediumTypes
    /// The Bandl.VaultLedger.Model.MediumTypeDetails is used in most 
    /// methods and is used to store serializable information about a 
    /// medium type.
    /// </summary>
    public class MediumType
    {
        /// <summary>
        /// Delegate for the RetrieveMediumTypes method of the web service
        /// gateway.  Retrieves the types in an ansynchronous manner.
        /// </summary>
        private delegate MediumTypeCollection RetrieveDelegate();

        /// <summary>
        /// Gets the number of medium types in the database
        /// </summary>
        /// <param name="container">
        /// Whether to get count for container types (true) or non-container 
        /// types (false)
        /// </param>
        /// <returns>
        /// Number of types in the database
        /// </returns>
        public static int GetMediumTypeCount(bool container)
        {
            return MediumTypeFactory.Create().GetMediumTypeCount(container);
        }

        /// <summary>
        /// Returns the information for a specific medium type
        /// </summary>
        /// <param name="name">Unique identifier for a medium type</param>
        /// <returns>Returns the information for the medium type</returns>
        public static MediumTypeDetails GetMediumType(string name) 
        {
            if(name == null)
            {
                throw new ArgumentNullException("Name of medium type may not be null.");
            }
            else if (name == String.Empty)
            {
                throw new ArgumentException("Name of medium type may not be an empty string.");
            }
            else
            {
                return MediumTypeFactory.Create().GetMediumType(name);
            }
        }

        /// <summary>
        /// Returns the information for a specific medium type
        /// </summary>
        /// <param name="id">Unique identifier for a medium type</param>
        /// <returns>Returns the information for the medium type</returns>
        public static MediumTypeDetails GetMediumType(int id) 
        {
            if (id <= 0)
            {
                throw new ArgumentException("Medium type id must be greater than zero.");
            }
            else
            {
                return MediumTypeFactory.Create().GetMediumType(id);
            }
        }

        /// <summary>
        /// Returns the contents of the MediumType table
        /// </summary>
        /// <returns>
        /// Returns all of the mdium types known to the system
        /// </returns>
        public static MediumTypeCollection GetMediumTypes() 
        {
            return MediumTypeFactory.Create().GetMediumTypes();
        }

        /// <summary>
        /// Returns the contents of the MediumType table, containers or non-containers only
        /// </summary>
        /// <param name="containerTypes">
        /// Returns container types if true, non-container types if false
        /// </param>
        /// <returns>
        /// Returns all of the appropriate medium types known to the system
        /// </returns>
        public static MediumTypeCollection GetMediumTypes(bool containerTypes)
        {
            return MediumTypeFactory.Create().GetMediumTypes(containerTypes);
        }

        /// <summary>
        /// A method to insert a new medium type
        /// </summary>
        /// <param name="mediumType">
        /// An medium type entity with information about the new medium type
        /// </param>
        public static void GetBandlTypes() 
        {
            IMediumType dal;
            MediumTypeCollection remoteTypes;

            try
            {
                remoteTypes = new BandlGateway().GetMediumTypes();
            }
            catch (Exception ex)
            {
                throw new ApplicationException("Unable to retrieve medium types from remote service.  " + ex.Message);
            }
            // Insert the remote medium types into the database
            try
            {
                using (IConnection c = ConnectionFactory.Create().Open())
                {
                    dal = MediumTypeFactory.Create(c);
                    try
                    {
                        c.BeginTran("Insert medium type", "System");
                        foreach (MediumTypeDetails m in remoteTypes)
                            dal.Insert(m);
                        c.CommitTran();
                    }
                    catch
                    {
                        c.RollbackTran();
                        throw;
                    }
                }
            }
            catch (Exception ex)
            {
                throw new ApplicationException("Unable to insert medium types from remote service.  " + ex.Message);
            }
        }

        /// <summary>
        /// A method to insert a new medium type
        /// </summary>
        /// <param name="mediumType">
        /// An medium type entity with information about the new medium type
        /// </param>
        public static void Insert(ref MediumTypeDetails mediumType) 
        {
            // Must have administrator privileges
            CustomPermission.Demand(Role.Administrator);
            // Make sure that the data is new
            if(mediumType == null)
            {
                throw new ArgumentNullException("Reference must be set to an instance of a medium type object.");
            }
            else if(mediumType.ObjState != ObjectStates.New)
            {
                throw new ObjectStateException("Only a medium type marked as new may be inserted.");
            }
            // Reset the error flag
            mediumType.RowError = String.Empty;
            // Insert the medium type
            try
            {
                MediumTypeFactory.Create().Insert(mediumType);
                mediumType = GetMediumType(mediumType.Name);
            }
            catch (Exception e)
            {
                mediumType.RowError = e.Message;
                throw;
            }
        }

        /// <summary>
        /// A method to update an existing medium type
        /// </summary>
        /// <param name="mediumType">
        /// An medium type entity with information about the medium type
        /// </param>
        public static void Update(ref MediumTypeDetails mediumType) 
        {
            // Must have administrator privileges
            CustomPermission.Demand(Role.Administrator);
            // Make sure that the data is modified
            if(mediumType == null)
            {
                throw new ArgumentNullException("Reference must be set to an instance of a medium type object.");
            }
            else if(mediumType.ObjState != ObjectStates.Modified)
            {
                throw new ObjectStateException("Only a medium type marked as modified may be updated.");
            }
            // Reset the error flag
            mediumType.RowError = String.Empty;
            // Update the medium type
            try
            {
                MediumTypeFactory.Create().Update(mediumType);
                mediumType = GetMediumType(mediumType.Id);
            }
            catch (Exception e)
            {
                mediumType.RowError = e.Message;
                throw;
            }
        }

        /// <summary>
        /// Deletes an existing mediumType
        /// </summary>
        /// <param name="o">MediumType to delete</param>
        public static void Delete(ref MediumTypeDetails mediumType)
        {
            // Must have administrator privileges
            CustomPermission.Demand(Role.Administrator);
            // Make sure that the data is not new
            if(mediumType == null)
            {
                throw new ArgumentNullException("Reference must be set to an instance of a medium type object.");
            }
            else if(mediumType.ObjState != ObjectStates.Unmodified)
            {
                throw new ObjectStateException("Only a medium type marked as unmodified may be deleted.");
            }
            // Delete the medium type
            try
            {
                MediumTypeFactory.Create().Delete(mediumType);
                mediumType.ObjState = ObjectStates.Deleted;
                mediumType.RowError = String.Empty;
            }
            catch (Exception e)
            {
                mediumType.RowError = e.Message;
                throw;
            }
        }

        /// <summary>
        /// Compares the medium types in the database with medium types
        /// fetched from the remote (vault) web service.
        /// </summary>
        public static void SynchronizeMediumTypes(bool doSync)
        {
            // Must have administrator privileges
            CustomPermission.Demand(Role.Administrator);
            // Retrieve and compare asynchronously if we already have types
            // in the database.  Otherwise compare synchronously.
            if (!doSync && GetMediumTypeCount(false) != 0)
            {
                BeginRetrieveMediumTypes();
            }
            else
            {
                CompareMediumTypes((new RecallGateway()).RetrieveMediumTypes());
            }
        }

        /// <summary>
        /// Creates a delegate and invokes the RetrieveMediumTypes() method of
        /// the remote (vault) web service gateway asynchronously.
        /// </summary>
        private static void BeginRetrieveMediumTypes()
        {
            RetrieveDelegate rd = new RetrieveDelegate((new RecallGateway()).RetrieveMediumTypes);
            rd.BeginInvoke(new AsyncCallback(EndRetrieveMediumTypes), rd);
        }

        /// <summary>
        /// Callback method that takes the results of the asynchronous call to 
        /// RetrieveMediumTypes() in the remote (vault) web service and passes
        /// to the method that compares local to remote medium types.
        /// </summary>
        private static void EndRetrieveMediumTypes(IAsyncResult ar)
        {
            CompareMediumTypes(((RetrieveDelegate)ar.AsyncState).EndInvoke(ar));
        }

        /// <summary>
        /// Compares the medium types in the database with types fetched from
        /// the web service.
        /// </summary>
        /// <param name="remoteTypes">
        /// Collection of medium types retrieved from the web service
        /// </param>
        private static void CompareMediumTypes(MediumTypeCollection remoteTypes)
        {
            MediumTypeDetails x = null;
            string errorText = String.Empty;
            MediumTypeCollection localTypes = MediumType.GetMediumTypes();
            MediumTypeCollection deleteTypes = new MediumTypeCollection();
            MediumTypeCollection insertTypes = new MediumTypeCollection();
            MediumTypeCollection updateTypes = new MediumTypeCollection();
            // Add each remote type that does not exist in the collection 
            // of local types.  Examine the Recall Code rather than the
            // medium type name.
            foreach(MediumTypeDetails m in remoteTypes)
            {
                if (m.RecallCode.Length != 0)
                {
                    if (localTypes.FindCode(m.RecallCode, m.Container) == null)
                        insertTypes.Add(m);     // add to collection; insert later
                }
                else
                {
                    if ((x = localTypes.Find(m.Name, m.Container)) == null)
                        insertTypes.Add(m);     // add to collection; insert later
                    else
                    {
                        if(x.RecallCode != m.RecallCode) x.RecallCode = m.RecallCode;
                        if(x.TwoSided != m.TwoSided) x.TwoSided = m.TwoSided;
                        if(x.Name != m.Name) x.Name = m.Name;
                        // Update if modified
                        if (x.ObjState == ObjectStates.Modified) 
                            updateTypes.Add(x);	// Add to collection; update later
                    }
                }
            }
            // Go through the local types.  Delete each one not present in 
            // the list of remote types.  Update each one present if necessary.
            foreach(MediumTypeDetails l in localTypes)
            {
                if (l.RecallCode.Length != 0)
                {
                    if ((x = remoteTypes.FindCode(l.RecallCode, l.Container)) == null)
                    {
                        deleteTypes.Add(l);	// Add to collection; delete later
                    }
                    else
                    {
                        if(l.RecallCode != x.RecallCode) l.RecallCode = x.RecallCode;
                        if(l.TwoSided != x.TwoSided) l.TwoSided = x.TwoSided;
                        if(l.Name != x.Name) l.Name = x.Name;
                        // Update if modified
                        if (l.ObjState == ObjectStates.Modified) 
                            updateTypes.Add(l);	// Add to collection; update later
                    }
                }
                else
                {
                    if ((x = remoteTypes.Find(l.Name, l.Container)) == null)
                        deleteTypes.Add(l);     // add to collection; insert later
                    else
                    {
                        if(l.RecallCode != x.RecallCode) l.RecallCode = x.RecallCode;
                        if(l.TwoSided != x.TwoSided) l.TwoSided = x.TwoSided;
                        if(l.Name != x.Name) l.Name = x.Name;
                        // Update if modified
                        if (l.ObjState == ObjectStates.Modified) 
                            updateTypes.Add(l);	// Add to collection; update later
                    }
                }
            }
            // If no action, just return
            if (deleteTypes.Count == 0)
                if (insertTypes.Count == 0)
                    if (updateTypes.Count == 0) 
                        return;
            // Create an account data access layer object
            using (IConnection c = ConnectionFactory.Create().Open())
            {
                try
                {
                    c.BeginTran("update medium types");
                    // Create a medium type data access layer object
                    IMediumType dal = MediumTypeFactory.Create(c);
                    // If we have any to update, do that first
                    foreach (MediumTypeDetails d in updateTypes)
                        dal.Update(d);
                    // Change the delete types so as to blank the type code and
                    // generate a random string for the type name
                    ArrayList modifiedNames = new ArrayList();
                    for (int i = 0; i < deleteTypes.Count; i++)
                    {
                        string randomName = Guid.NewGuid().ToString("N");
                        modifiedNames.Add(randomName);
                        deleteTypes[i].Name = randomName;
                        deleteTypes[i].RecallCode = String.Empty;
                        dal.Update(deleteTypes[i]);
                    }
                    // Insert all the new medium types
                    foreach (MediumTypeDetails d in insertTypes)
                        dal.Insert(d);
                    // Commit to this point
                    c.CommitTran();
                    c.BeginTran("delete medium type");
                    // Refresh the delete types
                    for (int i = 0; i < deleteTypes.Count; i++)
                        deleteTypes[i] = GetMediumType(deleteTypes[i].Id);
                    // If we're deleting types, we have to replace those types
                    // being deleted with those types being kept
                    if (deleteTypes.Count != 0)
                    {
                        int i;
                        bool update1 = false;
                        bool update2 = false;
                        bool keptType = false;
                        string mediumType = String.Empty;
                        string containerType = String.Empty;;
                        // Get a non-container medium type that is not going to be deleted
                        foreach (MediumTypeDetails d in GetMediumTypes(false))
                        {
                            for (keptType = true, i = 0; keptType && i < modifiedNames.Count; i++)
                                keptType = (d.Name != (string)modifiedNames[i]);
                            // If x is still true, then the type is not being deleted and
                            // we have our medium type.
                            if (keptType == true)
                            {
                                mediumType = d.Name;
                                break;
                            }
                        }
                        // Get a container medium type that is not going to be deleted
                        foreach (MediumTypeDetails d in GetMediumTypes(true))
                        {
                            for (keptType = true, i = 0; keptType && i < modifiedNames.Count; i++)
                                keptType = (d.Name != (string)modifiedNames[i]);
                            // If x is still true, then the type is not being deleted and
                            // we have our medium type.
                            if (keptType == true)
                            {
                                containerType = d.Name;
                                break;
                            }
                        }
                        // Get the pattern default for both media and containers
                        PatternDefaultMediumCollection pmc = PatternDefaultMedium.GetPatternDefaults();
                        PatternDefaultCaseCollection pcc = PatternDefaultCase.GetPatternDefaultCases();
                        // Run through the bar code medium formats
                        for (i = 0; i < pmc.Count; i++)
                        {
                            foreach (MediumTypeDetails d in deleteTypes)
                            {
                                if (!d.Container && pmc[i].MediumType == d.Name)
                                {
                                    pmc[i].MediumType = mediumType;
                                    update1 = true;
                                    break;
                                }
                            }
                        }
                        // Run through the bar code case formats
                        for (i = 0; i < pcc.Count; i++)
                        {
                            foreach (MediumTypeDetails d in deleteTypes)
                            {
                                if (d.Container && pcc[i].CaseType == d.Name)
                                {
                                    pcc[i].CaseType = containerType;
                                    update2 = true;
                                    break;
                                }
                            }
                        }
                        // Update the bar code formats where necessary
                        if (update1) PatternDefaultMediumFactory.Create(c).Update(pmc);
                        if (update2) PatternDefaultCaseFactory.Create(c).Update(pcc);
                        // Delete the medium types to be deleted
                        foreach (MediumTypeDetails d in deleteTypes)
                            dal.Delete(d);
                    }
                    // Commit the transaction
                    c.CommitTran();
                }
                catch (Exception ex)
                {
                    c.RollbackTran();
                    new BandlGateway().PublishException(ex);
                    throw new ApplicationException(ex.Message);
                }
            }
        }
        /// <summary>
        /// Deletes an existing medium type
        /// </summary>
        /// <param name="typeCollection">
        /// Medium types to be deleted
        /// </param>
        public static void Delete(MediumTypeCollection typeCollection) 
        {
            // Must have administrator privileges
            CustomPermission.Demand(Role.Administrator);
            // Make sure that the data is unmodified and that this is not the Recall product
            if(typeCollection == null)
            {
                throw new ArgumentNullException("Reference must be set to an instance of a medium type collection object.");
            }
            else if (Configurator.ProductType == "RECALL")
            {
                throw new ApplicationException("Recall implementation cannot conventionally delete medium types.");
            }
            // Check object status
            foreach (MediumTypeDetails mediumType in typeCollection)
                if(mediumType.ObjState != ObjectStates.Unmodified)
                    throw new ObjectStateException("Only a medium type marked as unmodified may be deleted.");
            // Get all the media and case bar code patterns from the database
            PatternDefaultCaseCollection casePatterns = PatternDefaultCase.GetPatternDefaultCases();
            PatternDefaultMediumCollection mediaPatterns = PatternDefaultMedium.GetPatternDefaults();
            // If there are any bar code patterns that use this account, deny delete
            foreach (MediumTypeDetails mediumType in typeCollection)
            {
                if (mediumType.Container)
                {
                    foreach (PatternDefaultCaseDetails barCode in casePatterns)
                        if (barCode.CaseType == mediumType.Name)
                            throw new ApplicationException("Case type " + mediumType.Name + " is referenced by a case format and may not be deleted.  Adjust your case formats and try again.");
                }
                else
                {
                    foreach (PatternDefaultMediumDetails barCode in mediaPatterns)
                        if (barCode.MediumType == mediumType.Name)
                            throw new ApplicationException("Medium type " + mediumType.Name + " is referenced by a bar code format and may not be deleted.  Adjust your bar code formats and try again.");
                }
            }
            // Create the data access layer object
            IMediumType dal = MediumTypeFactory.Create();
            // Run through the collection, deleting medium types
            foreach (MediumTypeDetails m in typeCollection)
            {
                try
                {
                    dal.Delete(m);
                }
                catch (Exception ex)
                {
                    m.RowError = ex.Message;
                    typeCollection.HasErrors = true;
                }
            }
            // If there were errors then throw a collection error exception
            if (typeCollection.HasErrors)
                throw new CollectionErrorException(typeCollection);
        }
    }
}
