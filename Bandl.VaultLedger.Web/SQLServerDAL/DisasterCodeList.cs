using System;
using System.Data;
using System.Text;
using System.Collections;
using System.Data.SqlClient;
using Bandl.Library.VaultLedger.IDAL;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.Exceptions;
using Bandl.Library.VaultLedger.Collections;
using System.Text.RegularExpressions;

namespace Bandl.Library.VaultLedger.SQLServerDAL
{
    /// <summary>
    /// Summary description for DisasterCodeList.
    /// </summary>
    public class DisasterCodeList : SQLServer, IDisasterCodeList
    {
        #region Constructors
        /// <summary>
        /// Default constructor
        /// </summary>
        public DisasterCodeList() {}
        /// <summary>
        /// Creates a new data layer object that will use the given connection
        /// </summary>
        /// <param name="c">
        /// Connection that object should use when connecting to the database
        /// </param>
        public DisasterCodeList(IConnection c) : base(c) {}
        /// <summary>
        /// Constructor that will or will not look for a persistent connection before
        /// creating a new one, depending on the value of demandCreate.
        /// </summary>
        /// <param name="demandCreate">
        /// If true, object will create a new connection.  If false, object will first
        /// search for a persistent connection on this thread for this session; if
        /// none is found, then a new connection will be created.
        /// </param>
        public DisasterCodeList(bool demandCreate) : base(demandCreate) {}

        #endregion

        /// <summary>
        /// Gets the employed disaster list statuses from the database
        /// </summary>
        /// <returns>
        /// Disaster list statuses used
        /// </returns>
        public DLStatus GetStatuses()
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    SqlParameter[] p = new SqlParameter[1];
                    p[0] = BuildParameter("@profileId", (int)ListTypes.DisasterCode);
                    using(SqlDataReader r = ExecuteReader(CommandType.StoredProcedure, "listStatusProfile$getById", p))
                    {
                        // If no data then throw exception
                        if(r.HasRows == false) 
                            return DLStatus.Xmitted;
                        // Move to the first record and get the statuses
                        r.Read();
                        return (DLStatus)Enum.ToObject(typeof(DLStatus), r.GetInt32(1));
                    }
                }
                catch(SqlException e)
                {
                    PublishException(e);
                    throw new DatabaseException(StripErrorMsg(e.Message), e);
                }
            }
        }

        /// <summary>
        /// Updates the statuses used for disaster code lists
        /// </summary>
        public void UpdateStatuses(DLStatus statuses)
        {
            using (IConnection c = dataBase.Open())
            {
                try
                {
                    c.BeginTran("update disaster code list status profile");
                    SqlParameter[] p = new SqlParameter[2];
                    p[0] = BuildParameter("@profileId", (int)ListTypes.DisasterCode);
                    p[1] = BuildParameter("@statuses", (int)statuses);
                    ExecuteNonQuery(CommandType.StoredProcedure, "listStatusProfile$upd", p);
                    c.CommitTran();
                }
                catch(SqlException e)
                {
                    c.RollbackTran();
                    PublishException(e);
                    throw new DatabaseException(StripErrorMsg(e.Message), e);
                }
            }
        }

        /// <summary>
        /// Returns the information for a specific disaster code list
        /// </summary>
        /// <param name="id">
        /// Unique identifier for a disaster code list
        /// </param>
        /// <param name="getItems">
        /// Whether or not the user would like the items of the list
        /// </param>
        /// <returns>Returns the information for the disaster code list</returns>
        public DisasterCodeListDetails GetDisasterCodeList(int id, bool getItems) 
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    SqlParameter[] listParms = new SqlParameter[1];
                    listParms[0] = BuildParameter("@id", id);
                    using(SqlDataReader r = ExecuteReader(CommandType.StoredProcedure, "disasterCodeList$getById", listParms))
                    {
                        // If no data then return null
                        if(r.HasRows == false) return null;                        // Move to the first record and create a new instance
                        r.Read();
                        DisasterCodeListDetails rl = new DisasterCodeListDetails(r);
                        // If there are any child lists, get them and attach them
                        // to the composite.
                        if (r.NextResult()) 
                        {
                            DisasterCodeListCollection childLists = new DisasterCodeListCollection(r);
                            rl.ChildLists = (DisasterCodeListDetails[])new ArrayList(childLists).ToArray(typeof(DisasterCodeListDetails));
                        }
                        // If items are requested, get them.
                        if (true == getItems) 
                        {
                            r.Close();
                            GetDisasterCodeListItems(ref rl);
                        }
                        // Return the list
                        return rl;
                    }
                }
                catch(SqlException e)
                {
                    ExceptionPublisher.Publish(e);
                    throw new DatabaseException(StripErrorMsg(e.Message), e);
                }
            }
        }

        /// <summary>
        /// Returns the information for a specific disaster code list
        /// </summary>
        /// <param name="listName">
        /// Unique name of a disaster code list
        /// </param>
        /// <param name="getItems">
        /// Whether or not the user would like the items of the list
        /// </param>
        /// <returns>Returns the information for the disaster code list</returns>
        public DisasterCodeListDetails GetDisasterCodeList(string listName, bool getItems) 
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    SqlParameter[] listParms = new SqlParameter[1];
                    listParms[0] = BuildParameter("@listName", listName);
                    using(SqlDataReader r = ExecuteReader(CommandType.StoredProcedure, "disasterCodeList$getByName", listParms))
                    {
                        // If no data then return null
                        if(r.HasRows == false) return null;
                        // Move to the first record and create a new instance
                        r.Read();
                        DisasterCodeListDetails rl = new DisasterCodeListDetails(r);
                        // If there are any child lists, get them and attach them
                        // to the composite.
                        if (r.NextResult()) 
                        {
                            DisasterCodeListCollection childLists = new DisasterCodeListCollection(r);
                            rl.ChildLists = (DisasterCodeListDetails[])new ArrayList(childLists).ToArray(typeof(DisasterCodeListDetails));
                        }
                        // If items and cases are requested, get them.
                        if (true == getItems) 
                        {
                            r.Close();
                            GetDisasterCodeListItems(ref rl);
                        }
                        // Return the list
                        return rl;
                    }
                }
                catch(SqlException e)
                {
                    ExceptionPublisher.Publish(e);
                    throw new DatabaseException(StripErrorMsg(e.Message), e);
                }
            }
        }

        /// <summary>
        /// Gets the disaster code lists for a particular date
        /// </summary>
        /// <param name="date">Date for which to retrieve disaster code lists</param>
        /// <returns>Collection of disaster code lists created on the given date</returns>
        public DisasterCodeListCollection GetListsByDate(DateTime date) 
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    SqlParameter[] listParms = new SqlParameter[1];
                    listParms[0] = BuildParameter("@createDate", date);
                    DisasterCodeListCollection resultLists = new DisasterCodeListCollection();
                    using(SqlDataReader r = ExecuteReader(CommandType.StoredProcedure, "disasterCodeList$getByDate", listParms))
                    {
                        // If no data then throw exception
                        if(r.HasRows == false) return resultLists;
                        // Add the lists to the collection
                        while (r.Read()) 
                            resultLists.Add(new DisasterCodeListDetails(r));
                    }
                    // If composite then get children
                    for(int i = 0; i < resultLists.Count; i++) 
                    {
                        if (String.Empty == resultLists[i].Account)
                        {
                            DisasterCodeListDetails dl = resultLists[i];
                            dl = GetDisasterCodeList(dl.Id, false);
                        }
                    }
                    // return the collection
                    return resultLists;
                }
                catch(SqlException e)
                {
                    ExceptionPublisher.Publish(e);
                    throw new DatabaseException(StripErrorMsg(e.Message), e);
                }
            }
        }

        /// <summary>
        /// Gets the disaster code lists created before a particular date that 
        /// have been cleared.
        /// </summary>
        /// <param name="date">Create date</param>
        /// <returns>Collection of disaster code lists</returns>
        public DisasterCodeListCollection GetCleared(DateTime date) 
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    SqlParameter[] listParms = new SqlParameter[1];
                    listParms[0] = BuildParameter("@createDate", date);
                    DisasterCodeListCollection resultLists = new DisasterCodeListCollection();
                    using(SqlDataReader r = ExecuteReader(CommandType.StoredProcedure, "disasterCodeList$getCleared", listParms))
                    {
                        // If no data then return empty collection
                        if(r.HasRows == false)
                        {
                            return resultLists;
                        }
                        else
                        {
                            resultLists = new DisasterCodeListCollection(r);
                        }
                    }
                    // If composite then get children
                    for(int i = 0; i < resultLists.Count; i++) 
                    {
                        if (String.Empty == resultLists[i].Account)
                        {
                            DisasterCodeListDetails sl = resultLists[i];
                            sl = GetDisasterCodeList(sl.Id, true);
                        }
                    }
                    // return the collection
                    return resultLists;
                }
                catch(SqlException e)
                {
                    PublishException(e);
                    throw new DatabaseException(StripErrorMsg(e.Message), e);
                }
            }
        }

        /// <summary>
        /// Returns a page of the contents of the DisasterCodeList table
        /// </summary>
        /// <returns>Returns a collection of disaster code lists in the given sort order</returns>
        public DisasterCodeListCollection GetDisasterCodeListPage(int pageNo, int pageSize, DLSorts sortColumn, out int totalLists)
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    SqlParameter[] listParms = new SqlParameter[4];
                    listParms[0] = BuildParameter("@pageNo", pageNo);
                    listParms[1] = BuildParameter("@pageSize", pageSize);
                    listParms[2] = BuildParameter("@filter", String.Empty);
                    listParms[3] = BuildParameter("@sort", (short)sortColumn);
                    using(SqlDataReader r = ExecuteReader(CommandType.StoredProcedure, "disasterCodeList$getPage", listParms))
                    {
                        DisasterCodeListCollection m = new DisasterCodeListCollection(r);
                        r.NextResult();
                        r.Read();
                        totalLists = r.GetInt32(r.GetOrdinal("RecordCount"));
                        return(m);
                    }
                }
                catch(SqlException e)
                {
                    ExceptionPublisher.Publish(e);
                    throw new DatabaseException(StripErrorMsg(e.Message), e);
                }
            }
        }

        /// <summary>
        /// Gets the number of entries on the disaster code list with the given id
        /// </summary>
        /// <param name="listId">
        /// Id of list for which to get entry count
        /// </param>
        /// <returns>
        /// Number of entries on list
        /// </returns>
        public int GetDisasterCodeListItemCount(int listId)
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    SqlParameter[] sqlParms = new SqlParameter[2];
                    sqlParms[0] = BuildParameter("@listId", listId);
                    sqlParms[1] = BuildParameter("@status", -1);
                    return (int)ExecuteScalar(CommandType.StoredProcedure, "disasterCodeList$getItemCount", sqlParms);
                }
                catch(SqlException e)
                {
                    PublishException(e);
                    throw new DatabaseException(StripErrorMsg(e.Message), e);
                }
            }
        }

        /// <summary>
        /// Gets the number of entries on the disaster code list with the given id
        /// </summary>
        /// <param name="listId">
        /// Id of list for which to get entry count
        /// </param>
        /// <param name="status">
        /// The status of the entries being counted toward the total
        /// </param>
        /// <returns>
        /// Number of entries on list
        /// </returns>
        public int GetDisasterCodeListItemCount(int listId, DLIStatus status)
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    SqlParameter[] sqlParms = new SqlParameter[2];
                    sqlParms[0] = BuildParameter("@listId", listId);
                    sqlParms[1] = BuildParameter("@status", (int)status);
                    return (int)ExecuteScalar(CommandType.StoredProcedure, "disasterCodeList$getItemCount", sqlParms);
                }
                catch(SqlException e)
                {
                    PublishException(e);
                    throw new DatabaseException(StripErrorMsg(e.Message), e);
                }
            }
        }

        /// <summary>
        /// Obtains the list details items for a disaster code list
        /// </summary>
        /// <param name="list">Disaster Code list for which to obtain details</param>
        private void GetDisasterCodeListItems(ref DisasterCodeListDetails list) 
        {
            // If the list is a composite, then we should get the details of
            // all its constituent lists.  Otherwise, get the cases followed
            // by the items for the list.
            if (true == list.IsComposite) 
            {
                foreach (DisasterCodeListDetails r in list.ChildLists)
                {
                    DisasterCodeListDetails r1 = r; 
                    GetDisasterCodeListItems(ref r1);
                }
            }
            else 
            {
                using (IConnection dbc = dataBase.Open())
                {
                    try
                    {
                        // Get the items
                        SqlParameter[] itemParms = new SqlParameter[1];
                        itemParms[0] = BuildParameter("@listId", list.Id);
                        using(SqlDataReader r = ExecuteReader(CommandType.StoredProcedure, "disasterCodeList$getItems", itemParms))
                        {
                            if(r.HasRows == true) 
                            {
                                DisasterCodeListItemCollection items = new DisasterCodeListItemCollection(r);
                                list.ListItems = (DisasterCodeListItemDetails[])new ArrayList(items).ToArray(typeof(DisasterCodeListItemDetails));
                            }
                        }
                    }
                    catch(SqlException e)
                    {
                        ExceptionPublisher.Publish(e);
                        throw new DatabaseException(StripErrorMsg(e.Message), e);
                    }
                }
            }
        }

        /// <summary>
        /// Returns the information for a specific disaster code list item
        /// </summary>
        /// <param name="itemId">
        /// Id number of the disaster code list item
        /// </param>
        /// <returns>
        /// Disaster code list item
        /// </returns>
        public DisasterCodeListItemDetails GetDisasterCodeListItem(int itemId)
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    SqlParameter[] itemParms = new SqlParameter[1];
                    itemParms[0] = BuildParameter("@itemId", itemId);
                    using(SqlDataReader r = ExecuteReader(CommandType.StoredProcedure, "disasterCodeListItem$get", itemParms))
                    {
                        if (r.HasRows == false)
                        {
                            return null;
                        }
                        else 
                        {
                            r.Read();
                            return new DisasterCodeListItemDetails(r);
                        }
                    }
                }
                catch(SqlException e)
                {
                    ExceptionPublisher.Publish(e);
                    throw new DatabaseException(StripErrorMsg(e.Message), e);
                }
            }
        }

        /// <summary>
        /// Returns a page of the items of a disaster code list
        /// </summary>
        /// <returns>Returns a collection of disaster code items in the given sort order</returns>
        public DisasterCodeListItemCollection GetDisasterCodeListItemPage(int listId, int pageNo, int pageSize, DLISorts sortColumn, out int totalItems)
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    SqlParameter[] itemParms = new SqlParameter[5];
                    itemParms[0] = BuildParameter("@listId", listId);
                    itemParms[1] = BuildParameter("@pageNo", pageNo);
                    itemParms[2] = BuildParameter("@pageSize", pageSize);
                    itemParms[3] = BuildParameter("@filter", String.Empty);
                    itemParms[4] = BuildParameter("@sort", (short)sortColumn);
                    using(SqlDataReader r = ExecuteReader(CommandType.StoredProcedure, "disasterCodeListItem$getPage", itemParms))
                    {
                        DisasterCodeListItemCollection m = new DisasterCodeListItemCollection(r);
                        r.NextResult();
                        r.Read();
                        totalItems = r.GetInt32(r.GetOrdinal("RecordCount"));
                        return(m);
                    }
                }
                catch(SqlException e)
                {
                    ExceptionPublisher.Publish(e);
                    throw new DatabaseException(StripErrorMsg(e.Message), e);
                }
            }
        }

        /// <summary>
        /// Returns a page of the items of a disaster code list
        /// </summary>
        /// <param name="listId">
        /// Id of the list whose items to retrieve
        /// </param>
        /// <param name="pageNo">
        /// Number of page to retrieve
        /// </param>
        /// <param name="pageSize">
        /// Number of records to be displayed on each page
        /// </param>
        /// <param name="sortColumn">
        /// Attribute on which to sort
        /// </param>
        /// <param name="itemStatus">
        /// Status that an item must have to be returned in the result set
        /// </param>
        /// <param name="totalItems">
        /// Number of items on the given list with the given item status
        /// </param>
        /// <returns>
        /// Returns a collection of list items in the given sort order
        /// </returns>
        public DisasterCodeListItemCollection GetDisasterCodeListItemPage(int listId, int pageNo, int pageSize, DLIStatus itemStatus, DLISorts sortColumn, out int totalItems)
        {
            // Build the filter string
            string pageFilter = String.Empty;
            foreach (int statusValue in Enum.GetValues(typeof(DLIStatus)))
            {
                if (statusValue != (int)DLIStatus.AllValues && (statusValue & Convert.ToInt32(itemStatus)) != 0)
                {
                    if (pageFilter.Length != 0)
                    {
                        pageFilter += "," + statusValue.ToString();
                    }
                    else
                    {
                        pageFilter = "Status IN (" + statusValue.ToString(); 
                    }
                }
            }
            // If we have a filter, then add the terminating parenthesis
            if (pageFilter.Length != 0)
            {
                pageFilter += ")";
            }
            // Retrieve the page from the database
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    SqlParameter[] itemParms = new SqlParameter[5];
                    itemParms[0] = BuildParameter("@listId", listId);
                    itemParms[1] = BuildParameter("@pageNo", pageNo);
                    itemParms[2] = BuildParameter("@pageSize", pageSize);
                    itemParms[3] = BuildParameter("@filter", pageFilter);
                    itemParms[4] = BuildParameter("@sort", (short)sortColumn);
                    using(SqlDataReader r = ExecuteReader(CommandType.StoredProcedure, "disasterCodeListItem$getPage", itemParms))
                    {
                        DisasterCodeListItemCollection m = new DisasterCodeListItemCollection(r);
                        r.NextResult();
                        r.Read();
                        totalItems = r.GetInt32(r.GetOrdinal("RecordCount"));
                        return(m);
                    }
                }
                catch(SqlException e)
                {
                    PublishException(e);
                    throw new DatabaseException(StripErrorMsg(e.Message), e);
                }
            }
        }

        /// <summary>
        /// Merges a collection of disaster code lists
        /// </summary>
        /// <param name="listCollection">Collection of lists to merge</param>
        /// <returns>Composite list</returns>
        public DisasterCodeListDetails Merge(DisasterCodeListCollection listCollection) 
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    dbc.BeginTran("merge disaster code list");
                    DisasterCodeListDetails returnList = null;
                    DisasterCodeListCollection discretes = new DisasterCodeListCollection();
                    DisasterCodeListCollection composites = new DisasterCodeListCollection();
                    // Get all the composites in one collection, all the discretes in another
                    foreach (DisasterCodeListDetails dl in listCollection)
                    {
                        if (true == dl.IsComposite)
                            composites.Add(dl);
                        else
                            discretes.Add(dl);
                    }
                    // Merge the composites
                    if (composites.Count > 0) 
                    {
                        returnList = composites[0];
                        for (int i = 1; i < composites.Count; i++)
                        {
                            SqlParameter[] mergeParms = new SqlParameter[5];
                            mergeParms[0] = BuildParameter("@listId1", returnList.Id);
                            mergeParms[1] = BuildParameter("@rowVersion1", returnList.RowVersion);
                            mergeParms[2] = BuildParameter("@listId2", composites[i].Id);
                            mergeParms[3] = BuildParameter("@rowVersion2", composites[i].RowVersion);
                            mergeParms[4] = BuildParameter("@compositeId", SqlDbType.Int, ParameterDirection.Output);
                            // Insert the new operator
                            ExecuteNonQuery(CommandType.StoredProcedure, "disasterCodeList$merge", mergeParms);
                            // Get the updated result
                            returnList = GetDisasterCodeList((int)mergeParms[4].Value, false);
                        }
                    }
                    // Merge the discretes
                    if (discretes.Count > 0) 
                    {
                        int i = 0;
                        // If there were no composites, set the result to the first list
                        if (null == returnList) 
                        {
                            i = 1;
                            returnList = discretes[0];
                        }
                        // Merge the discretes
                        for ( ; i < discretes.Count; i++)
                        {
                            SqlParameter[] mergeParms = new SqlParameter[5];
                            mergeParms[0] = BuildParameter("@listId1", returnList.Id);
                            mergeParms[1] = BuildParameter("@rowVersion1", returnList.RowVersion);
                            mergeParms[2] = BuildParameter("@listId2", discretes[i].Id);
                            mergeParms[3] = BuildParameter("@rowVersion2", discretes[i].RowVersion);
                            mergeParms[4] = BuildParameter("@compositeId", SqlDbType.Int, ParameterDirection.Output);
                            // Insert the new operator
                            ExecuteNonQuery(CommandType.StoredProcedure, "disasterCodeList$merge", mergeParms);
                            // Get the updated result
                            returnList = GetDisasterCodeList((int)mergeParms[4].Value, false);
                        }
                    }
                    // Commit the transaction
                    dbc.CommitTran();
                    // Return the merged list
                    return returnList;
                }
                catch(SqlException e)
                {
                    dbc.RollbackTran();
                    ExceptionPublisher.Publish(e);
                    throw new DatabaseException(StripErrorMsg(e.Message), e);
                }
            }
        }   // end Merge()

        /// <summary>
        /// Creates a new disaster code list from the given items
        /// </summary>
        /// <param name="items">
        /// Items that will appear on the list(s)
        /// </param>
        /// <returns>
        /// Disaster Code list details object containing the created disaster code list
        /// </returns>
        public DisasterCodeListDetails Create(DisasterCodeListItemCollection items)
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    DisasterCodeListDetails returnList = null;
                    DisasterCodeListCollection dlc = null;
                    // Begin the transaction
                    dbc.BeginTran("create disaster code list");
                    // Add all the items into the database
                    string listNames = String.Empty;
                    foreach (DisasterCodeListItemDetails i in items) 
                    {
                        SqlParameter[] p = new SqlParameter[4];
                        p[0] = BuildParameter("@serialNo", i.SerialNo);
                        p[1] = BuildParameter("@code", i.Code);
                        p[2] = BuildParameter("@notes", i.Notes);
                        p[3] = BuildParameter("@batch", listNames, SqlDbType.NVarChar, ParameterDirection.InputOutput);
                        p[3].Size = 4000;
                        // Insert the new item
                        ExecuteNonQuery(CommandType.StoredProcedure, "disasterCodeListItem$ins", p);
                        // Update the listNames variable
                        listNames = (string)p[3].Value;
                    }
                    // If more than one list was created, merge the lists
                    switch (listNames.Length)
                    {
                        case 0:
                            returnList = null;
                            break;
                        case 10:    // List names are always ten characters in length
                            returnList = GetDisasterCodeList(listNames, false);
                            break;
                        default:
                            dlc = new DisasterCodeListCollection();
                            for (int i = 0; i < listNames.Length / 10; i++)
                                dlc.Add(GetDisasterCodeList(listNames.Substring(i * 10, 10), false));
                            returnList = Merge(dlc);
                            break;
                    }
                    // Set the status of the list.  This must be done explicitly for disaster code lists.  Whereas
                    // other list types must have an intermediary status, dr lists can go immediately from submitted
                    // to processed.  As a result, we cannot set the status of a list in the afterInsert item
                    // trigger; if we did, and if the user did not transmit lists, we would never be able to create 
                    // a list of more than one item.
                    if (dlc != null)
                    {
                        for (int i = 0; i < dlc.Count; i++)
                        {
                            // Have to refetch, as rowversion has changed due to merge
                            DisasterCodeListDetails d = GetDisasterCodeList(dlc[i].Id, false);
                            // Set its status
                            SqlParameter[] p = new SqlParameter[2];
                            p[0] = BuildParameter("@listId", d.Id);
                            p[1] = BuildParameter("@rowVersion", d.RowVersion);
                            ExecuteNonQuery(CommandType.StoredProcedure, "disasterCodeList$setStatus", p);
                        }
                    }
                    else if (returnList != null)
                    {
                        SqlParameter[] p = new SqlParameter[2];
                        p[0] = BuildParameter("@listId", returnList.Id);
                        p[1] = BuildParameter("@rowVersion", returnList.RowVersion);
                        ExecuteNonQuery(CommandType.StoredProcedure, "disasterCodeList$setStatus", p);
                    }
                    // Commit the transaction
                    dbc.CommitTran();
                    // Return the composite
                    return returnList;
                }
                catch(SqlException e)
                {
                    dbc.RollbackTran();
                    ExceptionPublisher.Publish(e);
                    throw new DatabaseException(StripErrorMsg(e.Message), e);
                }
            }
        }   // end Create()

        /// <summary>
        /// Extracts a disaster code list from a composite
        /// </summary>
        /// <param name="compositeList">Composite list</param>
        /// <param name="discreteList">Discrete list to extract from composite</param>
        public void Extract(DisasterCodeListDetails compositeList, DisasterCodeListDetails discreteList)
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    dbc.BeginTran("extract disaster code list");
                    // Extract the list
                    SqlParameter[] extractParms = new SqlParameter[4];
                    extractParms[0] = BuildParameter("@listId", discreteList.Id);
                    extractParms[1] = BuildParameter("@listVersion", discreteList.RowVersion);
                    extractParms[2] = BuildParameter("@compositeId", compositeList.Id);
                    extractParms[3] = BuildParameter("@compositeVersion", compositeList.RowVersion);
                    ExecuteNonQuery(CommandType.StoredProcedure, "disasterCodeList$extract", extractParms);
                    // Commit the transaction
                    dbc.CommitTran();
                }
                catch(SqlException e)
                {
                    dbc.RollbackTran();
                    ExceptionPublisher.Publish(e);
                    throw new DatabaseException(StripErrorMsg(e.Message), e);
                }
            }
        }   // end Extract

        /// <summary>
        /// Dissolves a disaster code list from composite.  In other words, 
        /// extracts all discrete lists at once.
        /// </summary>
        /// <param name="compositeList">Composite list</param>
        public void Dissolve(DisasterCodeListDetails compositeList) 
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    dbc.BeginTran("extract disaster code list");
                    // Extract the list
                    SqlParameter[] extractParms = new SqlParameter[2];
                    extractParms[0] = BuildParameter("@listId", compositeList.Id);
                    extractParms[1] = BuildParameter("@listVersion", compositeList.RowVersion);
                    ExecuteNonQuery(CommandType.StoredProcedure, "disasterCodeList$dissolve", extractParms);
                    // Commit the transaction
                    dbc.CommitTran();
                }
                catch(SqlException e)
                {
                    dbc.RollbackTran();
                    ExceptionPublisher.Publish(e);
                    throw new DatabaseException(StripErrorMsg(e.Message), e);
                }
            }
        }

        /// <summary>
        /// Transmits a disaster code list
        /// </summary>
        /// <param name="list">Disaster Code list to transmit</param>
        public void Transmit(DisasterCodeListDetails list)
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    dbc.BeginTran("transmit disaster code list");
                    // Transmit the list
                    SqlParameter[] transmitParms = new SqlParameter[2];
                    transmitParms[0] = BuildParameter("@listId", list.Id);
                    transmitParms[1] = BuildParameter("@rowVersion", list.RowVersion);
                    ExecuteNonQuery(CommandType.StoredProcedure, "disasterCodeList$transmit", transmitParms);
                    // Commit the transaction
                    dbc.CommitTran();
                }
                catch(SqlException e)
                {
                    dbc.RollbackTran();
                    ExceptionPublisher.Publish(e);
                    throw new DatabaseException(StripErrorMsg(e.Message), e);
                }
            }
        } // end Transmit()

        /// <summary>
        /// Clears a disaster code list
        /// </summary>
        /// <param name="list">Disaster Code list to clear</param>
        public void Clear(DisasterCodeListDetails list)
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    dbc.BeginTran("clear disaster code list");
                    // Clear the list
                    SqlParameter[] clearParms = new SqlParameter[2];
                    clearParms[0] = BuildParameter("@listId", list.Id);
                    clearParms[1] = BuildParameter("@rowVersion", list.RowVersion);
                    ExecuteNonQuery(CommandType.StoredProcedure, "disasterCodeList$clear", clearParms);
                    // Commit the transaction
                    dbc.CommitTran();
                }
                catch(SqlException e)
                {
                    dbc.RollbackTran();
                    ExceptionPublisher.Publish(e);
                    throw new DatabaseException(StripErrorMsg(e.Message), e);
                }
            }
        } // end Clear()

        /// <summary>
        /// Deletes a disaster code list
        /// </summary>
        /// <param name="list">Disaster Code list to delete</param>
        public void Delete(DisasterCodeListDetails list)
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    dbc.BeginTran("delete disaster code list");
                    // Delete the list
                    SqlParameter[] deleteParms = new SqlParameter[2];
                    deleteParms[0] = BuildParameter("@listId", list.Id);
                    deleteParms[1] = BuildParameter("@rowVersion", list.RowVersion);
                    ExecuteNonQuery(CommandType.StoredProcedure, "disasterCodeList$del", deleteParms);
                    // Commit the transaction
                    dbc.CommitTran();
                }
                catch(SqlException e)
                {
                    dbc.RollbackTran();
                    ExceptionPublisher.Publish(e);
                    throw new DatabaseException(StripErrorMsg(e.Message), e);
                }
            }
        } // end Delete()

        /// <summary>
        /// Removes a set disaster code list item.
        /// </summary>
        /// <param name="item">
        /// A disaster code list items to remove
        /// </param>
        public void RemoveItem(DisasterCodeListItemDetails item)
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    dbc.BeginTran("remove disaster code list item");
                    // Remove the items
                    SqlParameter[] removeParms = new SqlParameter[2];
                    removeParms[0] = BuildParameter("@itemId", item.Id);
                    removeParms[1] = BuildParameter("@rowVersion", item.RowVersion);
                    ExecuteNonQuery(CommandType.StoredProcedure, "disasterCodeListItem$remove", removeParms);
                    // Commit the transaction
                    dbc.CommitTran();
                }
                catch(SqlException e)
                {
                    dbc.RollbackTran();
                    ExceptionPublisher.Publish(e);
                    throw new DatabaseException(StripErrorMsg(e.Message), e);
                }
            }
        }   // end RemoveItems()

        /// <summary>
        /// Updates a disaster code list item
        /// </summary>
        /// <param name="item">
        /// A disaster code list item to update
        /// </param>
        public void UpdateItem(DisasterCodeListItemDetails item) 
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    dbc.BeginTran("update disaster code list item");
                    // Update the items
                    SqlParameter[] updateParms = new SqlParameter[4];
                    updateParms[0] = BuildParameter("@itemId", item.Id);
                    updateParms[1] = BuildParameter("@code", item.Code);
                    updateParms[2] = BuildParameter("@notes", item.Notes);
                    updateParms[3] = BuildParameter("@rowVersion", item.RowVersion);
                    ExecuteNonQuery(CommandType.StoredProcedure, "disasterCodeListItem$upd", updateParms);
                    // Commit the transaction
                    dbc.CommitTran();
                }
                catch(SqlException e)
                {
                    dbc.RollbackTran();
                    ExceptionPublisher.Publish(e);
                    throw new DatabaseException(StripErrorMsg(e.Message), e);
                }
            }
        }

        /// <summary>
        /// Adds an item to a given list
        /// </summary>
        /// <param name="listId">
        /// Id of the list to which the item should be added
        /// </param>
        /// <param name="item">
        /// Disaster code list item to add
        /// </param>
        public void AddItem(String n1, DisasterCodeListItemDetails item)        
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    dbc.BeginTran("add disaster code list item");
                    // Add the item
                    SqlParameter[] addParms = new SqlParameter[4];
                    addParms[0] = BuildParameter("@serialNo", item.SerialNo);
                    addParms[1] = BuildParameter("@code", item.Code);
                    addParms[2] = BuildParameter("@notes", item.Notes);
                    addParms[3] = BuildParameter("@batch", n1);
                    ExecuteNonQuery(CommandType.StoredProcedure, "disasterCodeListItem$ins", addParms);
                    // Commit the transaction
                    dbc.CommitTran();
                }
                catch(SqlException e)
                {
                    dbc.RollbackTran();
                    ExceptionPublisher.Publish(e);
                    throw new DatabaseException(StripErrorMsg(e.Message), e);
                }
            }
        }

        #region Email Groups
        /// <summary>
        /// Gets the email groups associated with a particular list status
        /// </summary>
        /// <param name="dl">
        /// List status for which to get email groups
        /// </param>
        /// <returns>
        /// Email group collection
        /// </returns>
        public EmailGroupCollection GetEmailGroups(DLStatus dl)
        {
            using (IConnection c = dataBase.Open())
            {
                try
                {
                    SqlParameter[] p = new SqlParameter[2];
                    p[0] = BuildParameter("@listType", (int)ListTypes.DisasterCode);
                    p[1] = BuildParameter("@status", (int)dl);
                    using(SqlDataReader r = ExecuteReader(CommandType.StoredProcedure, "listStatusEmail$get", p))
                    {
                        return(new EmailGroupCollection(r));
                    }
                }
                catch(SqlException e)
                {
                    PublishException(e);
                    throw new DatabaseException(StripErrorMsg(e.Message), e);
                }
            }
        }

        /// <summary>
        /// Attaches an email group to a list status
        /// </summary>
        /// <param name="e">
        /// Email group to attach
        /// </param>
        /// <param name="dl">
        /// List status for which to get email groups
        /// </param>
        public void AttachEmailGroup(EmailGroupDetails e, DLStatus dl)
        {
            using (IConnection c = dataBase.Open())
            {
                try
                {
                    // Begin transaction
                    c.BeginTran("attach list status email group");
                    // Insert email group
                    SqlParameter[] p = new SqlParameter[3];
                    p[0] = BuildParameter("@listType", (int)ListTypes.DisasterCode);
                    p[1] = BuildParameter("@status", (int)dl);
                    p[2] = BuildParameter("@groupId", e.Id);
                    ExecuteNonQuery(CommandType.StoredProcedure, "listStatusEmail$ins", p);
                    // Commit transaction
                    c.CommitTran();
                }
                catch(SqlException ex)
                {
                    c.RollbackTran();
                    PublishException(ex);
                    throw new DatabaseException(StripErrorMsg(ex.Message), ex);
                }
            }
        }

        /// <summary>
        /// Detaches an email group from a list status
        /// </summary>
        /// <param name="e">
        /// Email group to attach
        /// </param>
        /// <param name="sl">
        /// List status for which to get email groups
        /// </param>
        public void DetachEmailGroup(EmailGroupDetails e, DLStatus dl)
        {
            using (IConnection c = dataBase.Open())
            {
                try
                {
                    // Begin transaction
                    c.BeginTran("detach list status email group");
                    // Insert email group
                    SqlParameter[] p = new SqlParameter[3];
                    p[0] = BuildParameter("@listType", (int)ListTypes.DisasterCode);
                    p[1] = BuildParameter("@status", (int)dl);
                    p[2] = BuildParameter("@groupId", e.Id);
                    ExecuteNonQuery(CommandType.StoredProcedure, "listStatusEmail$del", p);
                    // Commit transaction
                    c.CommitTran();
                }
                catch(SqlException ex)
                {
                    c.RollbackTran();
                    PublishException(ex);
                    throw new DatabaseException(StripErrorMsg(ex.Message), ex);
                }
            }
        }


        /// <summary>
        /// Gets the email groups associated with a particular list alert profile
        /// </summary>
        /// <returns>
        /// Email group collection
        /// </returns>
        public EmailGroupCollection GetEmailGroups()
        {
            using (IConnection c = dataBase.Open())
            {
                try
                {
                    SqlParameter[] p = new SqlParameter[1];
                    p[0] = BuildParameter("@listType", (int)ListTypes.DisasterCode);
                    using(SqlDataReader r = ExecuteReader(CommandType.StoredProcedure, "listAlertEmail$get", p))
                    {
                        return(new EmailGroupCollection(r));
                    }
                }
                catch(SqlException e)
                {
                    PublishException(e);
                    throw new DatabaseException(StripErrorMsg(e.Message), e);
                }
            }
        }

        /// <summary>
        /// Attaches an email group to a list alert profile
        /// </summary>
        /// <param name="e">
        /// Email group to attach
        /// </param>
        public void AttachEmailGroup(EmailGroupDetails e)
        {
            using (IConnection c = dataBase.Open())
            {
                try
                {
                    // Begin transaction
                    c.BeginTran("attach list alert email group");
                    // Insert email group
                    SqlParameter[] p = new SqlParameter[2];
                    p[0] = BuildParameter("@listType", (int)ListTypes.DisasterCode);
                    p[1] = BuildParameter("@groupId", e.Id);
                    ExecuteNonQuery(CommandType.StoredProcedure, "listAlertEmail$ins", p);
                    // Commit transaction
                    c.CommitTran();
                }
                catch(SqlException ex)
                {
                    c.RollbackTran();
                    PublishException(ex);
                    throw new DatabaseException(StripErrorMsg(ex.Message), ex);
                }
            }
        }

        /// <summary>
        /// Detaches an email group from a list alert profile
        /// </summary>
        /// <param name="e">
        /// Email group to attach
        /// </param>
        public void DetachEmailGroup(EmailGroupDetails e)
        {
            using (IConnection c = dataBase.Open())
            {
                try
                {
                    // Begin transaction
                    c.BeginTran("detach list alert email group");
                    // Insert email group
                    SqlParameter[] p = new SqlParameter[2];
                    p[0] = BuildParameter("@listType", (int)ListTypes.DisasterCode);
                    p[1] = BuildParameter("@groupId", e.Id);
                    ExecuteNonQuery(CommandType.StoredProcedure, "listAlertEmail$del", p);
                    // Commit transaction
                    c.CommitTran();
                }
                catch(SqlException ex)
                {
                    c.RollbackTran();
                    PublishException(ex);
                    throw new DatabaseException(StripErrorMsg(ex.Message), ex);
                }
            }
        }

        /// <summary>
        /// Gets the list alert days for shipping lists
        /// </summary>
        /// <returns></returns>
        public int GetListAlertDays()
        {
            using (IConnection c = dataBase.Open())
            {
                try
                {
                    // Insert email group
                    SqlParameter[] p = new SqlParameter[2];
                    p[0] = BuildParameter("@listType", (int)ListTypes.DisasterCode);
                    p[1] = BuildParameter("@days", SqlDbType.Int, ParameterDirection.Output);
                    ExecuteNonQuery(CommandType.StoredProcedure, "listAlert$getDays", p);
                    return Convert.ToInt32(p[1].Value);
                }
                catch(SqlException ex)
                {
                    c.RollbackTran();
                    PublishException(ex);
                    throw new DatabaseException(StripErrorMsg(ex.Message), ex);
                }
            }
        }

        /// <summary>
        /// Gets the time of the last list alert
        /// </summary>
        /// <returns></returns>
        public DateTime GetListAlertTime()
        {
            using (IConnection c = dataBase.Open())
            {
                try
                {
                    // Insert email group
                    SqlParameter[] p = new SqlParameter[2];
                    p[0] = BuildParameter("@listType", (int)ListTypes.DisasterCode);
                    p[1] = BuildParameter("@time", SqlDbType.DateTime, ParameterDirection.Output);
                    ExecuteNonQuery(CommandType.StoredProcedure, "listAlert$getTime", p);
                    return Convert.ToDateTime(p[1].Value);
                }
                catch(SqlException ex)
                {
                    c.RollbackTran();
                    PublishException(ex);
                    throw new DatabaseException(StripErrorMsg(ex.Message), ex);
                }
            }
        }

        /// <summary>
        /// Updates the alert days
        /// </summary>
        /// <param name="listTypes">
        /// Type of list
        /// </param>
        /// <param name="days">
        /// Days for alert
        /// </param>
        public void UpdateAlertDays(int days)
        {
            using (IConnection c = dataBase.Open())
            {
                try
                {
                    // Begin transaction
                    c.BeginTran("update alert days");
                    // Insert email group
                    SqlParameter[] p = new SqlParameter[2];
                    p[0] = BuildParameter("@listType", (int)ListTypes.DisasterCode);
                    p[1] = BuildParameter("@days", days);
                    ExecuteNonQuery(CommandType.StoredProcedure, "listAlert$updDays", p);
                    // Commit transaction
                    c.CommitTran();
                }
                catch(SqlException ex)
                {
                    c.RollbackTran();
                    PublishException(ex);
                    throw new DatabaseException(StripErrorMsg(ex.Message), ex);
                }
            }
        }

        /// <summary>
        /// Updates the alert time
        /// </summary>
        /// <param name="d">
        /// Time to update
        /// </param>
        public void UpdateAlertTime(DateTime d)
        {
            using (IConnection c = dataBase.Open())
            {
                try
                {
                    // Begin transaction
                    c.BeginTran("update alert time");
                    // Insert email group
                    SqlParameter[] p = new SqlParameter[2];
                    p[0] = BuildParameter("@listType", (int)ListTypes.DisasterCode);
                    p[1] = BuildParameter("@time", d);
                    ExecuteNonQuery(CommandType.StoredProcedure, "listAlert$updTime", p);
                    // Commit transaction
                    c.CommitTran();
                }
                catch(SqlException ex)
                {
                    c.RollbackTran();
                    PublishException(ex);
                    throw new DatabaseException(StripErrorMsg(ex.Message), ex);
                }
            }
        }
        #endregion Email Groups
    }
}
