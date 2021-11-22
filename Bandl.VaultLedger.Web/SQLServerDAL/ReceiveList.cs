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
    /// Summary description for ReceiveList.
    /// </summary>
    public class ReceiveList : SQLServer, IReceiveList
    {
        #region Constructors
        /// <summary>
        /// Default constructor
        /// </summary>
        public ReceiveList() {}
        /// <summary>
        /// Creates a new data layer object that will use the given connection
        /// </summary>
        /// <param name="c">
        /// Connection that object should use when connecting to the database
        /// </param>
        public ReceiveList(IConnection c) : base(c) {}
        /// <summary>
        /// Constructor that will or will not look for a persistent connection before
        /// creating a new one, depending on the value of demandCreate.
        /// </summary>
        /// <param name="demandCreate">
        /// If true, object will create a new connection.  If false, object will first
        /// search for a persistent connection on this thread for this session; if
        /// none is found, then a new connection will be created.
        /// </param>
        public ReceiveList(bool demandCreate) : base(demandCreate) {}

        #endregion

        /// <summary>
        /// Gets the employed receive list statuses from the database
        /// </summary>
        /// <returns>
        /// Receive list statuses used
        /// </returns>
        public RLStatus GetStatuses()
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    SqlParameter[] p = new SqlParameter[1];
                    p[0] = BuildParameter("@profileId", (int)ListTypes.Receive);
                    using(SqlDataReader r = ExecuteReader(CommandType.StoredProcedure, "listStatusProfile$getById", p))
                    {
                        // If no data then throw exception
                        if(r.HasRows == false) 
                            return RLStatus.FullyVerifiedI | RLStatus.Xmitted;
                        // Move to the first record and get the statuses
                        r.Read();
                        return (RLStatus)Enum.ToObject(typeof(RLStatus), r.GetInt32(1));
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
        /// Updates the statuses used fro receive lists
        /// </summary>
        public void UpdateStatuses(RLStatus statuses)
        {
            using (IConnection c = dataBase.Open())
            {
                try
                {
                    c.BeginTran("update receive list status profile");
                    SqlParameter[] p = new SqlParameter[2];
                    p[0] = BuildParameter("@profileId", (int)ListTypes.Receive);
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
        /// Returns the information for a specific receive list
        /// </summary>
        /// <param name="id">
        /// Unique identifier for a receive list
        /// </param>
        /// <param name="getItems">
        /// Whether or not the user would like the items of the list
        /// </param>
        /// <returns>Returns the information for the receive list</returns>
        public ReceiveListDetails GetReceiveList(int id, bool getItems) 
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    SqlParameter[] listParms = new SqlParameter[1];
                    listParms[0] = BuildParameter("@id", id);
                    using(SqlDataReader r = ExecuteReader(CommandType.StoredProcedure, "receiveList$getById", listParms))
                    {
                        // If no data then throw exception
                        if(r.HasRows == false) return null;
                        // Move to the first record and create a new instance
                        r.Read();
                        ReceiveListDetails rl = new ReceiveListDetails(r);
                        // If there are any child lists, get them and attach them
                        // to the composite.
                        if (r.NextResult()) 
                        {
                            ReceiveListCollection childLists = new ReceiveListCollection(r);
                            rl.ChildLists = (ReceiveListDetails[])new ArrayList(childLists).ToArray(typeof(ReceiveListDetails));
                        }
                        // If items and cases are requested, get them.
                        if (true == getItems) 
                        {
                            r.Close();
                            GetReceiveListItems(ref rl);
                        }
                        // Return the list
                        return rl;
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
        /// Returns the information for a specific receive list
        /// </summary>
        /// <param name="listName">
        /// Unique name of a receive list
        /// </param>
        /// <param name="getItems">
        /// Whether or not the user would like the items of the list
        /// </param>
        /// <returns>Returns the information for the receive list</returns>
        public ReceiveListDetails GetReceiveList(string listName, bool getItems) 
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    SqlParameter[] listParms = new SqlParameter[1];
                    listParms[0] = BuildParameter("@listName", listName);
                    using(SqlDataReader r = ExecuteReader(CommandType.StoredProcedure, "receiveList$getByName", listParms))
                    {
                        // If no data then throw exception
                        if(r.HasRows == false) return null;
                        // Move to the first record and create a new instance
                        r.Read();
                        ReceiveListDetails rl = new ReceiveListDetails(r);
                        // If there are any child lists, get them and attach them
                        // to the composite.
                        if (r.NextResult()) 
                        {
                            ReceiveListCollection childLists = new ReceiveListCollection(r);
                            rl.ChildLists = (ReceiveListDetails[])new ArrayList(childLists).ToArray(typeof(ReceiveListDetails));
                        }
                        // If items and cases are requested, get them.
                        if (true == getItems) 
                        {
                            r.Close();
                            GetReceiveListItems(ref rl);
                        }
                        // Return the list
                        return rl;
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
        /// Returns the complete receive list on which the given item appears
        /// </summary>
        /// <param name="ItemId">
        /// Item id number
        /// </param>
        /// <returns>
        /// Returns the complete receive list (with items), null if the 
        /// item does not appear on any lists.
        /// </returns>
        public ReceiveListDetails GetReceiveListByItem(int itemId, bool getItems)
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    SqlParameter[] listParms = new SqlParameter[1];
                    listParms[0] = BuildParameter("@itemId", itemId);
                    using(SqlDataReader r = ExecuteReader(CommandType.StoredProcedure, "receiveList$getByItem", listParms))
                    {
                        // If no data then return null
                        if(r.HasRows == false) return null;
                        // Move to the first record and create a new instance
                        r.Read();
                        ReceiveListDetails rl = new ReceiveListDetails(r);
                        // If there are any child lists, get them and attach them
                        // to the composite.
                        if (r.NextResult()) 
                        {
                            ReceiveListCollection childLists = new ReceiveListCollection(r);
                            rl.ChildLists = (ReceiveListDetails[])new ArrayList(childLists).ToArray(typeof(ReceiveListDetails));
                        }
                        // If items and cases are requested, get them.
                        if (true == getItems) 
                        {
                            r.Close();
                            GetReceiveListItems(ref rl);
                        }
                        // Return the list
                        return rl;
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
        /// Returns the complete receive list on which the given medium
        /// appears as active.
        /// </summary>
        /// <param name="serialNo">
        /// Medium serial number
        /// </param>
        /// <returns>
        /// Returns the complete receive list (with items), null if the 
        /// medium does not actively appear on any lists
        /// </returns>
        public ReceiveListDetails GetReceiveListByMedium(string serialNo, bool getItems)
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    SqlParameter[] listParms = new SqlParameter[1];
                    listParms[0] = BuildParameter("@serialNo", serialNo);
                    using(SqlDataReader r = ExecuteReader(CommandType.StoredProcedure, "receiveList$getByMedium", listParms))
                    {
                        // If no data then return null
                        if(r.HasRows == false) return null;
                        // Move to the first record and create a new instance
                        r.Read();
                        ReceiveListDetails rl = new ReceiveListDetails(r);
                        // If there are any child lists, get them and attach them
                        // to the composite.
                        if (r.NextResult()) 
                        {
                            ReceiveListCollection childLists = new ReceiveListCollection(r);
                            rl.ChildLists = (ReceiveListDetails[])new ArrayList(childLists).ToArray(typeof(ReceiveListDetails));
                        }
                        // If items and cases are requested, get them.
                        if (true == getItems) 
                        {
                            r.Close();
                            GetReceiveListItems(ref rl);
                        }
                        // Return the list
                        return rl;
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
        /// Gets the history of a given send list
        /// </summary>
        public AuditTrailCollection GetHistory(string listname)
        {
            AuditTrailCollection atc = new AuditTrailCollection();

            using (IConnection dbc = dataBase.Open())
            {
                string s = @"SELECT ITEMID, DATE, OBJECT, ACTION, DETAIL, LOGIN, -1
                             FROM   XRECEIVELIST
                             WHERE  OBJECT = @n
                             UNION
                             SELECT ITEMID, DATE, OBJECT, ACTION, DETAIL, LOGIN, -1
                             FROM   XRECEIVELISTITEM
                             WHERE  OBJECT = @n
                             ORDER  BY DATE ASC";
                SqlParameter[] p = new SqlParameter[1];
                p[0] = BuildParameter("@n", listname);
                using (SqlDataReader r = ExecuteReader(CommandType.Text, s, p))
                {
                    while (r.Read())
                    {
                        atc.Add(new AuditTrailDetails(r));
                    }
                }
            }

            return atc;
        }


        /// <summary>
        /// Gets the receive lists for a particular date
        /// </summary>
        /// <param name="date">Date for which to retrieve receive lists</param>
        /// <returns>Collection of receive lists created on the given date</returns>
        public ReceiveListCollection GetListsByDate(DateTime date) 
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    SqlParameter[] listParms = new SqlParameter[1];
                    listParms[0] = BuildParameter("@createDate", date);
                    ReceiveListCollection resultLists = new ReceiveListCollection();
                    using(SqlDataReader r = ExecuteReader(CommandType.StoredProcedure, "receiveList$getByDate", listParms))
                    {
                        // If no data then throw exception
                        if(r.HasRows == false) return resultLists;
                        // Add the lists to the collection
                        while (r.Read()) 
                            resultLists.Add(new ReceiveListDetails(r));
                    }
                    // If composite then get children
                    for(int i = 0; i < resultLists.Count; i++) 
                    {
                        if (String.Empty == resultLists[i].Account)
                        {
                            ReceiveListDetails rl = resultLists[i];
                            rl = GetReceiveList(rl.Id, false);
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
		/// Gets the receive lists for particular status(es) and date
		/// </summary>
		/// <param name="date">Date for which to retrieve receive lists</param>
		/// <returns>Collection of receive lists created on the given date in the status(es)</returns>
		public ReceiveListCollection GetListsByStatusAndDate(RLStatus status, DateTime date) 
		{
			using (IConnection dbc = dataBase.Open())
			{
				try
				{
					SqlParameter[] listParms = new SqlParameter[2];
					listParms[0] = BuildParameter("@status", status);
					listParms[1] = BuildParameter("@createDate", date);
					ReceiveListCollection resultLists = new ReceiveListCollection();
					using(SqlDataReader r = ExecuteReader(CommandType.StoredProcedure, "receiveList$getByStatusAndDate", listParms))
					{
						// If no data then throw exception
						if(r.HasRows == false) return resultLists;
						// Add the lists to the collection
						while (r.Read()) 
							resultLists.Add(new ReceiveListDetails(r));
					}
					// If composite then get children
					for(int i = 0; i < resultLists.Count; i++) 
					{
						if (String.Empty == resultLists[i].Account)
						{
							ReceiveListDetails rl = resultLists[i];
							rl = GetReceiveList(rl.Id, false);
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
        /// Gets the receive lists created before a particular date that have been
        /// cleared.
        /// </summary>
        /// <param name="date">Create date</param>
        /// <returns>Collection of receive lists</returns>
        public ReceiveListCollection GetCleared(DateTime date) 
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    SqlParameter[] listParms = new SqlParameter[1];
                    listParms[0] = BuildParameter("@createDate", date);
                    ReceiveListCollection resultLists = new ReceiveListCollection();
                    using(SqlDataReader r = ExecuteReader(CommandType.StoredProcedure, "receiveList$getCleared", listParms))
                    {
                        // If no data then return empty collection
                        if(r.HasRows == false)
                        {
                            return resultLists;
                        }
                        else
                        {
                            resultLists = new ReceiveListCollection(r);
                        }
                    }
                    // If composite then get children
                    for(int i = 0; i < resultLists.Count; i++) 
                    {
                        if (String.Empty == resultLists[i].Account)
                        {
                            ReceiveListDetails rl = resultLists[i];
                            rl = GetReceiveList(rl.Id, true);
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
        /// Returns a page of the contents of the ReceiveList table
        /// </summary>
        /// <returns>Returns a collection of receive lists in the given sort order</returns>
        public ReceiveListCollection GetReceiveListPage(int pageNo, int pageSize, RLSorts sortColumn, out int totalLists)
        {
			return GetReceiveListPage(pageNo, pageSize, sortColumn, String.Empty, out totalLists);
        }

		/// <summary>
		/// Returns a page of the contents of the ReceiveList table
		/// </summary>
		/// <returns>Returns a collection of receive lists in the given sort order</returns>
		public ReceiveListCollection GetReceiveListPage(int pageNo, int pageSize, RLSorts sortColumn, string filter, out int totalLists)
		{
			using (IConnection dbc = dataBase.Open())
			{
				try
				{
					SqlParameter[] listParms = new SqlParameter[4];
					listParms[0] = BuildParameter("@pageNo", pageNo);
					listParms[1] = BuildParameter("@pageSize", pageSize);
					listParms[2] = BuildParameter("@filter", filter);
					listParms[3] = BuildParameter("@sort", (short)sortColumn);
					using(SqlDataReader r = ExecuteReader(CommandType.StoredProcedure, "receiveList$getPage", listParms))
					{
						ReceiveListCollection m = new ReceiveListCollection(r);
						r.NextResult();
						r.Read();
						totalLists = r.GetInt32(r.GetOrdinal("RecordCount"));
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
        /// Gets the number of entries on the receive list with the given id
        /// </summary>
        /// <param name="listId">
        /// Id of list for which to get entry count
        /// </param>
        /// <returns>
        /// Number of entries on list
        /// </returns>
        public int GetReceiveListItemCount(int listId)
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    SqlParameter[] sqlParms = new SqlParameter[2];
                    sqlParms[0] = BuildParameter("@listId", listId);
                    sqlParms[1] = BuildParameter("@status", -1);
                    return (int)ExecuteScalar(CommandType.StoredProcedure, "receiveList$getItemCount", sqlParms);
                }
                catch(SqlException e)
                {
                    PublishException(e);
                    throw new DatabaseException(StripErrorMsg(e.Message), e);
                }
            }
        }

        /// <summary>
        /// Gets the number of entries on the receive list with the given id
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
        public int GetReceiveListItemCount(int listId, RLIStatus status)
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    SqlParameter[] sqlParms = new SqlParameter[2];
                    sqlParms[0] = BuildParameter("@listId", listId);
                    sqlParms[1] = BuildParameter("@status", (int)status);
                    return (int)ExecuteScalar(CommandType.StoredProcedure, "receiveList$getItemCount", sqlParms);
                }
                catch(SqlException e)
                {
                    PublishException(e);
                    throw new DatabaseException(StripErrorMsg(e.Message), e);
                }
            }
        }

        /// <summary>
        /// Obtains the list details items for a receive list
        /// </summary>
        /// <param name="list">Receive list for which to obtain details</param>
        private void GetReceiveListItems(ref ReceiveListDetails list) 
        {
            // If the list is a composite, then we should get the details of
            // all its constituent lists.  Otherwise, get the cases followed
            // by the items for the list.
            if (true == list.IsComposite) 
            {
                foreach (ReceiveListDetails r in list.ChildLists)
                {
                    ReceiveListDetails r1 = r; 
                    GetReceiveListItems(ref r1);
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
                        using(SqlDataReader r = ExecuteReader(CommandType.StoredProcedure, "receiveList$getItems", itemParms))
                        {
                            if(r.HasRows == true) 
                            {
                                ReceiveListItemCollection items = new ReceiveListItemCollection(r);
                                list.ListItems = (ReceiveListItemDetails[])new ArrayList(items).ToArray(typeof(ReceiveListItemDetails));
                            }
                        }
                    }
                    catch(SqlException e)
                    {
                        PublishException(e);
                        throw new DatabaseException(StripErrorMsg(e.Message), e);
                    }
                }
            }
        }

        /// <summary>
        /// Returns the information for a specific receive list item
        /// </summary>
        /// <param name="itemId">
        /// Id number of the receive list item
        /// </param>
        /// <returns>
        /// Receive list item
        /// </returns>
        public ReceiveListItemDetails GetReceiveListItem(int itemId)
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    SqlParameter[] itemParms = new SqlParameter[1];
                    itemParms[0] = BuildParameter("@itemId", itemId);
                    using(SqlDataReader r = ExecuteReader(CommandType.StoredProcedure, "receiveListItem$get", itemParms))
                    {
                        if (r.HasRows == false)
                        {
                            return null;
                        }
                        else 
                        {
                            r.Read();
                            return new ReceiveListItemDetails(r);
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
        /// Returns the information for a specific receive list item
        /// </summary>
        /// <param name="serialNo">
        /// Serial number of a medium on the receive list
        /// </param>
        /// <returns>
        /// Receive list item
        /// </returns>
        public ReceiveListItemDetails GetReceiveListItem(string serialNo)
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    SqlParameter[] itemParms = new SqlParameter[1];
                    itemParms[0] = BuildParameter("@serialNo", serialNo);
                    using(SqlDataReader r = ExecuteReader(CommandType.StoredProcedure, "receiveListItem$getByMedium", itemParms))
                    {
                        if (r.HasRows == false)
                        {
                            return null;
                        }
                        else 
                        {
                            r.Read();
                            return new ReceiveListItemDetails(r);
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
        /// Returns a page of the items of a receive list
        /// </summary>
        /// <returns>
        /// Returns a collection of receive list items in the given sort order
        /// </returns>
        public ReceiveListItemCollection GetReceiveListItemPage(int listId, int pageNo, int pageSize, RLISorts sortColumn, out int totalItems)
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
                    using(SqlDataReader r = ExecuteReader(CommandType.StoredProcedure, "receiveListItem$getPage", itemParms))
                    {
                        ReceiveListItemCollection m = new ReceiveListItemCollection(r);
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
        /// Returns a page of the items of a receive list
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
        /// Returns a collection of receive list items in the given sort order
        /// </returns>
        public ReceiveListItemCollection GetReceiveListItemPage(int listId, int pageNo, int pageSize, RLIStatus itemStatus, RLISorts sortColumn, out int totalItems)
        {
            // Build the filter string
            string pageFilter = String.Empty;
            foreach (int statusValue in Enum.GetValues(typeof(RLIStatus)))
            {
                if (statusValue != (int)RLIStatus.AllValues && (statusValue & Convert.ToInt32(itemStatus)) != 0)
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
                    using(SqlDataReader r = ExecuteReader(CommandType.StoredProcedure, "receiveListItem$getPage", itemParms))
                    {
                        ReceiveListItemCollection m = new ReceiveListItemCollection(r);
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
        /// Merges a collection of receive lists
        /// </summary>
        /// <param name="listCollection">Collection of lists to merge</param>
        /// <returns>Composite list</returns>
        public ReceiveListDetails Merge(ReceiveListCollection listCollection) 
        {
            if (listCollection.Count < 2)
                throw new ArgumentException("Must have at least two lists to merge.", "listCollection");

            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    dbc.BeginTran("merge receive list");
                    ReceiveListDetails result = null;
                    ReceiveListCollection discretes = new ReceiveListCollection();
                    ReceiveListCollection composites = new ReceiveListCollection();
                    // Get all the composites in one collection, all the discretes in another
                    foreach (ReceiveListDetails sl in listCollection)
                    {
                        if (true == sl.IsComposite)
                            composites.Add(sl);
                        else
                            discretes.Add(sl);
                    }
                    // Merge the composites
                    if (composites.Count > 0) 
                    {
                        result = composites[0];
                        for (int i = 1; i < composites.Count; i++)
                        {
                            SqlParameter[] mergeParms = new SqlParameter[5];
                            mergeParms[0] = BuildParameter("@listId1", result.Id);
                            mergeParms[1] = BuildParameter("@rowVersion1", result.RowVersion);
                            mergeParms[2] = BuildParameter("@listId2", composites[i].Id);
                            mergeParms[3] = BuildParameter("@rowVersion2", composites[i].RowVersion);
                            mergeParms[4] = BuildParameter("@compositeId", SqlDbType.Int, ParameterDirection.Output);
                            // Insert the new operator
                            ExecuteNonQuery(CommandType.StoredProcedure, "receiveList$merge", mergeParms);
                            // Get the updated result
                            result = GetReceiveList((int)mergeParms[4].Value, false);
                        }
                    }
                    // Merge the discretes
                    if (discretes.Count > 0) 
                    {
                        int i = 0;
                        // If there were no composites, set the result to the first list
                        if (null == result) 
                        {
                            i = 1;
                            result = discretes[0];
                        }
                        // Merge the discretes
                        for ( ; i < discretes.Count; i++)
                        {
                            SqlParameter[] mergeParms = new SqlParameter[5];
                            mergeParms[0] = BuildParameter("@listId1", result.Id);
                            mergeParms[1] = BuildParameter("@rowVersion1", result.RowVersion);
                            mergeParms[2] = BuildParameter("@listId2", discretes[i].Id);
                            mergeParms[3] = BuildParameter("@rowVersion2", discretes[i].RowVersion);
                            mergeParms[4] = BuildParameter("@compositeId", SqlDbType.Int, ParameterDirection.Output);
                            // Insert the new operator
                            ExecuteNonQuery(CommandType.StoredProcedure, "receiveList$merge", mergeParms);
                            // Get the updated result
                            result = GetReceiveList((int)mergeParms[4].Value, false);
                        }
                    }
                    // Commit the transaction
                    dbc.CommitTran();
                    // Return
                    return result;
                }
                catch(SqlException e)
                {
                    dbc.RollbackTran();
                    PublishException(e);
                    throw new DatabaseException(StripErrorMsg(e.Message), e);
                }
            }
        }   // end Merge()

        /// <summary>
        /// Creates a new receive list from the given items
        /// </summary>
        /// <param name="items">
        /// Items that will appear on the list(s)
        /// </param>
        /// <returns>
        /// Receive list details object containing the created receive list
        /// </returns>
        public ReceiveListDetails Create(ReceiveListItemCollection items)
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    dbc.BeginTran("create receive list");
                    // Add all the items into the database
                    string listsInBatch = String.Empty;
                    foreach (ReceiveListItemDetails i in items) 
                    {
                        SqlParameter[] itemParms = new SqlParameter[3];
                        itemParms[0] = BuildParameter("@serialNo", i.SerialNo);
                        itemParms[1] = BuildParameter("@notes", i.Notes);
                        itemParms[2] = BuildParameter("@batchLists", SqlDbType.NVarChar, ParameterDirection.InputOutput);
                        itemParms[2].Value = listsInBatch;
                        itemParms[2].Size = 4000;
                        // Insert the new item.  If the item is in a case, 
                        // it will be inserted as part of this procedure.
                        ExecuteNonQuery(CommandType.StoredProcedure, "receiveListItem$ins", itemParms);
                        // Get the list string
                        listsInBatch = Convert.ToString(itemParms[2].Value);
                    }
                    // If more than one list was created, merge the lists
                    ReceiveListDetails result;
                    switch (listsInBatch.Length)
                    {
                        case 0:
                            result = null;
                            break;
                        case 10:
                            result = GetReceiveList(listsInBatch, false);
                            break;
                        default:
                            ReceiveListCollection s = new ReceiveListCollection();
                            for (int i = 0; i < listsInBatch.Length / 10; i++)
                                s.Add(GetReceiveList(listsInBatch.Substring(i * 10, 10), false));
                            result = Merge(s);
                            break;
                    }
                    // Commit the transaction
                    dbc.CommitTran();
                    // Return the composite
                    return result;
                }
                catch(SqlException e)
                {
                    dbc.RollbackTran();
                    PublishException(e);
                    throw new DatabaseException(StripErrorMsg(e.Message), e);
                }
            }
        }   // end Create()

        /// <summary>
        /// Creates a new receive list using the given date as a return date
        /// </summary>
        /// <param name="receiveDate">
        /// Return date to use as cutoff point.  System will get all media at
        /// the vault, not currently on another list, with a return date 
        /// earlier or equal to the given date.
        /// </param>
        /// <param name="accounts">
        /// Comma-delimited list of account id numbers
        /// </param>
        /// <returns>
        /// Receive list details object containing the created receive list
        /// </returns>
        public ReceiveListDetails Create(DateTime receiveDate, String accounts)
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    dbc.BeginTran("create receive list");
                    // Create the parameters
                    string listsInBatch = String.Empty;
                    SqlParameter[] listParms = new SqlParameter[3];
                    listParms[0] = BuildParameter("@listDate", receiveDate);
                    listParms[1] = BuildParameter("@accounts", accounts);
                    listParms[2] = BuildParameter("@batchLists", SqlDbType.NVarChar, ParameterDirection.Output);
                    listParms[2].Size = 4000;
                    // Create the new receive list(s)
                    ExecuteNonQuery(CommandType.StoredProcedure, "receiveList$createByDate", listParms);
                    // Get the list string
                    listsInBatch = Convert.ToString(listParms[2].Value);
                    // If more than one list was created, merge the lists
                    ReceiveListDetails result;
                    switch (listsInBatch.Length)
                    {
                        case 0:
                            result = null;
                            break;
                        case 10:
                            result = GetReceiveList(listsInBatch, false);
                            break;
                        default:
                            ReceiveListCollection s = new ReceiveListCollection();
                            for (int i = 0; i < listsInBatch.Length / 10; i++)
                                s.Add(GetReceiveList(listsInBatch.Substring(i * 10, 10), false));
                            result = Merge(s);
                            break;
                    }
                    // Commit the transaction
                    dbc.CommitTran();
                    // Return the composite
                    return result;
                }
                catch(SqlException e)
                {
                    dbc.RollbackTran();
                    PublishException(e);
                    throw new DatabaseException(StripErrorMsg(e.Message), e);
                }
            }
        }   // end Create()

        /// <summary>
        /// Extracts a receive list from a composite
        /// </summary>
        /// <param name="compositeList">Composite list</param>
        /// <param name="discreteList">Discrete list to extract from composite</param>
        public void Extract(ReceiveListDetails compositeList, ReceiveListDetails discreteList)
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    dbc.BeginTran("extract receive list");
                    // Extract the list
                    SqlParameter[] extractParms = new SqlParameter[4];
                    extractParms[0] = BuildParameter("@listId", discreteList.Id);
                    extractParms[1] = BuildParameter("@listVersion", discreteList.RowVersion);
                    extractParms[2] = BuildParameter("@compositeId", compositeList.Id);
                    extractParms[3] = BuildParameter("@compositeVersion", compositeList.RowVersion);
                    ExecuteNonQuery(CommandType.StoredProcedure, "receiveList$extract", extractParms);
                    // Commit the transaction
                    dbc.CommitTran();
                }
                catch(SqlException e)
                {
                    dbc.RollbackTran();
                    PublishException(e);
                    throw new DatabaseException(StripErrorMsg(e.Message), e);
                }
            }
        }   // end Extract

        /// <summary>
        /// Dissolves a receive list from composite.  In other words, extracts
        /// all discrete lists at once.
        /// </summary>
        /// <param name="compositeList">Composite list</param>
        public void Dissolve(ReceiveListDetails compositeList) 
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    dbc.BeginTran("extract receive list");
                    // Extract the list
                    SqlParameter[] extractParms = new SqlParameter[2];
                    extractParms[0] = BuildParameter("@listId", compositeList.Id);
                    extractParms[1] = BuildParameter("@listVersion", compositeList.RowVersion);
                    ExecuteNonQuery(CommandType.StoredProcedure, "receiveList$dissolve", extractParms);
                    // Commit the transaction
                    dbc.CommitTran();
                }
                catch(SqlException e)
                {
                    dbc.RollbackTran();
                    PublishException(e);
                    throw new DatabaseException(StripErrorMsg(e.Message), e);
                }
            }
        }

        /// <summary>
        /// Transmits a receive list
        /// </summary>
        /// <param name="list">Receive list to transmit</param>
        public void Transmit(ReceiveListDetails list)
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    dbc.BeginTran("transmit receive list");
                    // Transmit the list
                    SqlParameter[] transmitParms = new SqlParameter[2];
                    transmitParms[0] = BuildParameter("@listId", list.Id);
                    transmitParms[1] = BuildParameter("@rowVersion", list.RowVersion);
                    ExecuteNonQuery(CommandType.StoredProcedure, "receiveList$transmit", transmitParms);
                    // Commit the transaction
                    dbc.CommitTran();
                }
                catch(SqlException e)
                {
                    dbc.RollbackTran();
                    PublishException(e);
                    throw new DatabaseException(StripErrorMsg(e.Message), e);
                }
            }
        } // end Transmit()

        /// <summary>
        /// Transmits a receive list collection
        /// </summary>
        /// <param name="listCollection">Receive list collection to transmit</param>
        public void Transmit(ReceiveListCollection listCollection)
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    dbc.BeginTran("transmit receive list");
                    // Transmit each list
                    foreach(ReceiveListDetails list in listCollection)
                    {
                        Transmit(list);
                    }
                    // Commit the transaction
                    dbc.CommitTran();
                }
                catch(SqlException e)
                {
                    dbc.RollbackTran();
                    PublishException(e);
                    throw new DatabaseException(StripErrorMsg(e.Message), e);
                }
            }
        } // end Transmit()

        /// <summary>
        /// Clears a receive list
        /// </summary>
        /// <param name="list">Receive list to clear</param>
        public void Clear(ReceiveListDetails list)
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    dbc.BeginTran("clear receive list");
                    // Clear the list
                    SqlParameter[] clearParms = new SqlParameter[2];
                    clearParms[0] = BuildParameter("@listId", list.Id);
                    clearParms[1] = BuildParameter("@rowVersion", list.RowVersion);
                    ExecuteNonQuery(CommandType.StoredProcedure, "receiveList$clear", clearParms);
                    // Commit the transaction
                    dbc.CommitTran();
                }
                catch(SqlException e)
                {
                    dbc.RollbackTran();
                    PublishException(e);
                    throw new DatabaseException(StripErrorMsg(e.Message), e);
                }
            }
        } // end Clear()

        /// <summary>
        /// Clears all fully verified receive lists, with the exception that
        /// if a discrete belongs to a composite, then it will not be cleared
        /// until all the other discretes in the composite are also cleared
        /// </summary>
        public void ClearVerified()
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    ExecuteNonQuery(CommandType.StoredProcedure, "receiveList$clearVerified");
                }
                catch(SqlException e)
                {
                    dbc.RollbackTran();
                    PublishException(e);
                    throw new DatabaseException(StripErrorMsg(e.Message), e);
                }
            }
        } // end Clear()

        /// <summary>
        /// Deletes a receive list
        /// </summary>
        /// <param name="list">Receive list to delete</param>
        public void Delete(ReceiveListDetails list)
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    dbc.BeginTran("delete receive list");
                    // Delete the list
                    SqlParameter[] deleteParms = new SqlParameter[2];
                    deleteParms[0] = BuildParameter("@listId", list.Id);
                    deleteParms[1] = BuildParameter("@rowVersion", list.RowVersion);
                    ExecuteNonQuery(CommandType.StoredProcedure, "receiveList$del", deleteParms);
                    // Commit the transaction
                    dbc.CommitTran();
                }
                catch(SqlException e)
                {
                    dbc.RollbackTran();
                    PublishException(e);
                    throw new DatabaseException(StripErrorMsg(e.Message), e);
                }
            }
        } // end Delete()

        /// <summary>
        /// Verifies a receive list item.
        /// </summary>
        /// <param name="item">
        /// A receive list item to verify
        /// </param>
        public void VerifyItem(ReceiveListItemDetails item)
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    dbc.BeginTran("verify receive list item");
                    // Remove the items
                    SqlParameter[] itemParms = new SqlParameter[2];
                    itemParms[0] = BuildParameter("@itemId", item.Id);
                    itemParms[1] = BuildParameter("@rowVersion", item.RowVersion);
                    ExecuteNonQuery(CommandType.StoredProcedure, "receiveListItem$verify", itemParms);
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
        /// Marks a list as in transit
        /// </summary>
        /// <param name="rl">
        /// Receive list
        /// </param>
        public void MarkTransit(ReceiveListDetails rl)
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    dbc.BeginTran("update receive list");
                    // Remove the items
                    SqlParameter[] p = new SqlParameter[2];
                    p[0] = BuildParameter("@listId", rl.Id);
                    p[1] = BuildParameter("@rowVersion", rl.RowVersion);
                    ExecuteNonQuery(CommandType.StoredProcedure, "receiveList$transit", p);
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
        /// Marks a list as arrived
        /// </summary>
        /// <param name="rl">
        /// Receive list
        /// </param>
        public void MarkArrived(ReceiveListDetails rl)
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    dbc.BeginTran("update receive list");
                    // Remove the items
                    SqlParameter[] p = new SqlParameter[2];
                    p[0] = BuildParameter("@listId", rl.Id);
                    p[1] = BuildParameter("@rowVersion", rl.RowVersion);
                    ExecuteNonQuery(CommandType.StoredProcedure, "receiveList$arrive", p);
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
        /// Removes a receive list item.
        /// </summary>
        /// <param name="item">
        /// A receive list item to remove
        /// </param>
        public void RemoveItem(ReceiveListItemDetails item) 
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    dbc.BeginTran("remove receive list item");
                    // Remove the item
                    SqlParameter[] removeParms = new SqlParameter[2];
                    removeParms[0] = BuildParameter("@itemId", item.Id);
                    removeParms[1] = BuildParameter("@rowVersion", item.RowVersion);
                    ExecuteNonQuery(CommandType.StoredProcedure, "receiveListItem$remove", removeParms);
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
        /// Updates a receive list item.
        /// </summary>
        /// <param name="item">
        /// A receive list item to update
        /// </param>
        /// <remarks>
        /// For a receive list item, only the Notes property can change
        /// </remarks>
        public void UpdateItem(ReceiveListItemDetails item) 
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    dbc.BeginTran("update receive list item");
                    SqlParameter[] updateParms = new SqlParameter[3];
                    updateParms[0] = BuildParameter("@itemId", item.Id);
                    updateParms[1] = BuildParameter("@notes", item.Notes);
                    updateParms[2] = BuildParameter("@rowVersion", item.RowVersion);
                    ExecuteNonQuery(CommandType.StoredProcedure, "receiveListItem$upd", updateParms);
                    dbc.CommitTran();
                }
                catch(SqlException e)
                {
                    dbc.RollbackTran();
                    PublishException(e);
                    throw new DatabaseException(StripErrorMsg(e.Message), e);
                }
            }
        }   // end UpdateItems()

        /// <summary>
        /// Adds all items in the collection to a given list.  This method 
        /// iterates through the collection and adds each item.  If an error
        /// occurs on any item, the transaction is rolled back and the 
        /// HasErrors property of the collection is set to true.  Each item 
        /// that resulted in error will have its RowError property set with 
        /// a description of the error.
        /// </summary>
        /// <param name="list">
        /// List to which items should be added.  Upon success, this list
        /// is refetched.
        /// </param>
        /// <param name="items">
        /// Collection of ReceiveListItemDetails objects
        /// </param>
        public void AddItem(ReceiveListDetails list, ReceiveListItemDetails item)
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    dbc.BeginTran("add receive list item");
                    SqlParameter[] addParms = new SqlParameter[3];
                    addParms[0] = BuildParameter("@serialNo", item.SerialNo);
                    addParms[1] = BuildParameter("@notes", item.Notes);
                    addParms[2] = BuildParameter("@listId", list.Id);
                    ExecuteNonQuery(CommandType.StoredProcedure, "receiveListItem$add", addParms);
                    dbc.CommitTran();
                }
                catch(SqlException e)
                {
                    dbc.RollbackTran();
                    PublishException(e);
                    throw new DatabaseException(StripErrorMsg(e.Message), e);
                }
            }
        }   // end AddItems()

        /// <summary>
        /// Returns the information for a specific receive list scan
        /// </summary>
        /// <param name="id">Unique identifier for a receive list scan</param>
        /// <returns>Returns the information for the receive list scan</returns>
        public ReceiveListScanDetails GetScan(int id) 
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    SqlParameter[] scanParms = new SqlParameter[1];
                    scanParms[0] = BuildParameter("@id", id);
                    using(SqlDataReader r = ExecuteReader(CommandType.StoredProcedure, "receiveListScan$getById", scanParms))
                    {
                        // If no data then throw exception
                        if(r.HasRows == false) return null;
                        // Move to the first record and create a new instance
                        r.Read();
                        ReceiveListScanDetails rl = new ReceiveListScanDetails(r);
                        // Get the items of the scan
                        if (r.NextResult()) 
                        {
                            ReceiveListScanItemCollection items = new ReceiveListScanItemCollection(r);
                            rl.ScanItems = (ReceiveListScanItemDetails[])new ArrayList(items).ToArray(typeof(ReceiveListScanItemDetails));
                        }
                        // Return the list
                        return rl;
                    }
                }
                catch(SqlException e)
                {
                    PublishException(e);
                    throw new DatabaseException(StripErrorMsg(e.Message), e);
                }
            }
        }   // end GetReceiveListScan()

        /// <summary>
        /// Returns the information for a specific receive list scan
        /// </summary>
        /// <param name="name">Unique identifier for a receive list scan</param>
        /// <returns>Returns the information for the receive list scan</returns>
        public ReceiveListScanDetails GetScan(string name) 
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    SqlParameter[] scanParms = new SqlParameter[1];
                    scanParms[0] = BuildParameter("@scanName", name);
                    using(SqlDataReader r = ExecuteReader(CommandType.StoredProcedure, "receiveListScan$getByName", scanParms))
                    {
                        // If no data then throw exception
                        if(r.HasRows == false) return null;
                        // Move to the first record and create a new instance
                        r.Read();
                        ReceiveListScanDetails rl = new ReceiveListScanDetails(r);
                        // Get the items of the scan
                        if (r.NextResult()) 
                        {
                            ReceiveListScanItemCollection items = new ReceiveListScanItemCollection(r);
                            rl.ScanItems = (ReceiveListScanItemDetails[])new ArrayList(items).ToArray(typeof(ReceiveListScanItemDetails));
                        }
                        // Return the list
                        return rl;
                    }
                }
                catch(SqlException e)
                {
                    PublishException(e);
                    throw new DatabaseException(StripErrorMsg(e.Message), e);
                }
            }
        }   // end GetReceiveListScan()

        /// <summary>
        /// Returns the information for a specific receive list scan item
        /// </summary>
        /// <param name="id">
        /// Id of the item
        /// </param>
        /// <returns>
        /// Receive list scan item object
        /// </returns>
        public ReceiveListScanItemDetails GetScanItem(int id)
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    SqlParameter[] itemParms = new SqlParameter[1];
                    itemParms[0] = BuildParameter("@itemId", id);
                    using(SqlDataReader r = ExecuteReader(CommandType.StoredProcedure, "receiveListScanItem$get", itemParms))
                    {
                        // If no data then throw exception
                        if(r.HasRows == false) return null;
                        // Move to the first record and create a new instance
                        r.Read();
                        return new ReceiveListScanItemDetails(r);
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
        /// Gets the scans for a specified receive list
        /// </summary>
        /// <param name="listName">
        /// Name of the list
        /// </param>
        /// <returns>
        /// Collection of scans
        /// </returns>
        public ReceiveListScanCollection GetScansForList(string listName, int stage)
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    SqlParameter[] scanParms = new SqlParameter[2];
                    scanParms[0] = BuildParameter("@listName", listName);
                    scanParms[1] = BuildParameter("@stage", stage);
                    using(SqlDataReader r = ExecuteReader(CommandType.StoredProcedure, "receiveListScan$getByList", scanParms))
                    {
                        ReceiveListScanCollection rl = new ReceiveListScanCollection();
                        if(r.HasRows == true) rl.Fill(r);
                        return rl;
                    }
                }
                catch(SqlException e)
                {
                    PublishException(e);
                    throw new DatabaseException(StripErrorMsg(e.Message), e);
                }
            }
        }   // End GetScansForList()

        /// <summary>
        /// Creates a receive list scan
        /// </summary>
        /// <param name="listName">
        /// List to which to attach the scan
        /// </param>
        /// <param name="scanName">
        /// Name to assign to the scan
        /// </param>
        /// <param name="item">
        /// Item to place in the scan
        /// </param>
        /// <returns>
        /// Created receive list scan
        /// </returns>
        public ReceiveListScanDetails CreateScan(string listName, string scanName, ReceiveListScanItemDetails item)
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    // Commence auditing
                    dbc.BeginTran("create receive list scan");
                    // Create the scan
                    SqlParameter[] scanParms = new SqlParameter[3];
                    scanParms[0] = BuildParameter("@listName", listName);
                    scanParms[1] = BuildParameter("@scanName", scanName);
                    scanParms[2] = BuildParameter("@newId", SqlDbType.Int, ParameterDirection.Output);
                    ExecuteNonQuery(CommandType.StoredProcedure, "receiveListScan$ins", scanParms);
                    int newId = Convert.ToInt32(scanParms[2].Value);
                    // Insert the item
                    SqlParameter[] itemParms = new SqlParameter[2];
                    itemParms[0] = BuildParameter("@scanId", newId);
                    itemParms[1] = BuildParameter("@serialNo", item.SerialNo);
                    ExecuteNonQuery(CommandType.StoredProcedure, "receiveListScanItem$ins", itemParms);
                    // Commit the transacation
                    dbc.CommitTran();
                    // Return the scan
                    return GetScan(newId);
                }
                catch(SqlException e)
                {
                    dbc.RollbackTran();
                    PublishException(e);
                    throw new DatabaseException(StripErrorMsg(e.Message), e);
                }
            }
        }

        /// <summary>
        /// Deletes a receive list scan
        /// </summary>
        public void DeleteScan(ReceiveListScanDetails scan)
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    dbc.BeginTran("delete receive list scan");
                    SqlParameter[] deleteParms = new SqlParameter[1];
                    deleteParms[0] = BuildParameter("@scanId", scan.Id);
                    ExecuteNonQuery(CommandType.StoredProcedure, "receiveListScan$del", deleteParms);
                    dbc.CommitTran();
                }
                catch(SqlException e)
                {
                    dbc.RollbackTran();
                    PublishException(e);
                    throw new DatabaseException(StripErrorMsg(e.Message), e);
                }
            }
        }   // end DeleteScans()

        /// <summary>
        /// Adds an item to a scan
        /// </summary>
        public void AddScanItem(int scanId, ReceiveListScanItemDetails item) 
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    // Commence auditing
                    dbc.BeginTran("add receive list scan item");
                    // Add the item
                    SqlParameter[] itemParms = new SqlParameter[2];
                    itemParms[0] = BuildParameter("@scanId", scanId);
                    itemParms[1] = BuildParameter("@serialNo", item.SerialNo);
                    ExecuteNonQuery(CommandType.StoredProcedure, "receiveListScanItem$ins", itemParms);
                    dbc.CommitTran();
                }
                catch(SqlException e)
                {
                    dbc.RollbackTran();
                    PublishException(e);
                    throw new DatabaseException(StripErrorMsg(e.Message), e);
                }
            }
        }

        /// <summary>
        /// Deletes a scan item
        /// </summary>
        public void DeleteScanItem(int itemId) 
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    // Commence auditing
                    dbc.BeginTran("delete receive list scan item");
                    // Update the items
                    SqlParameter[] itemParms = new SqlParameter[1];
                    itemParms[0] = BuildParameter("@itemId", itemId);
                    ExecuteNonQuery(CommandType.StoredProcedure, "receiveListScanItem$del", itemParms);
                    dbc.CommitTran();
                }
                catch(SqlException e)
                {
                    dbc.RollbackTran();
                    PublishException(e);
                    throw new DatabaseException(StripErrorMsg(e.Message), e);
                }
            }
        }

        /// <summary>
        /// Compares a list against one or more scans
        /// </summary>
        /// <param name="listName">
        /// Name of the list against which to compare
        /// </param>
        /// <returns>
        /// Structure holding the results of the comparison
        /// </returns>
        public ListCompareResult CompareListToScans(string listName)
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    // Commence auditing
                    dbc.BeginTran("compare receive list to scan");
                    // Get the scan names for this list
                    ArrayList scanNames = new ArrayList();
                    ReceiveListDetails rl = GetReceiveList(listName, false);
                    ReceiveListScanCollection scanCollection = GetScansForList(listName, rl.Status <= RLStatus.PartiallyVerifiedI ? 1 : 2);
                    // Create a list compare result with the returned scans
                    foreach(ReceiveListScanDetails r in scanCollection) {scanNames.Add(r.Name);}
                    ListCompareResult result = new ListCompareResult(listName, (string[])scanNames.ToArray(typeof(string)));
                    // Compare list to scans
                    SqlParameter[] compareParms = new SqlParameter[1];
                    compareParms[0] = BuildParameter("@listName", listName);
                    using(SqlDataReader r = ExecuteReader(CommandType.StoredProcedure, "receiveListScan$compare", compareParms))
                    {
                        // Create ArrayLists to hold the differences
                        ArrayList listNotScan = new ArrayList();
                        ArrayList scanNotList = new ArrayList();
                        // The first result set holds the serial numbers of
                        // media on the list but not on the scan.
                        if(r.HasRows == true)
                            while(r.Read()) 
                                listNotScan.Add(r.GetString(0));
                        // The second result set holds the serial numbers of
                        // media on the scan but not on the list.
                        if (r.NextResult() && r.HasRows == true)
                            while(r.Read()) 
                                scanNotList.Add(r.GetString(0));
                        // Assign all the arrays to the result object
                        result.ListNotScan = (string[])listNotScan.ToArray(typeof(string));
                        result.ScanNotList = (string[])scanNotList.ToArray(typeof(string));
                    }
                    // Commit the transaction
                    dbc.CommitTran();
                    // Return the result object
                    return result;
                }
                catch(SqlException e)
                {
                    dbc.RollbackTran();
                    PublishException(e);
                    throw new DatabaseException(StripErrorMsg(e.Message), e);
                }
            }
        }   // end CompareListToScans()

        /// <summary>
        /// Returns true if a medium in the given case, besides the given medium,
        /// has been initially verified on an active receive list.  Useful in
        /// determining whether or not a medium marked as missing should be 
        /// removed from its case.
        /// </summary>
        /// <param name="caseName">
        /// Name of sealed case
        /// </param>
        /// <param name="serialNo">
        /// Serial number of medium to be ignored
        /// </param>
        public bool SealedCaseVerified(string caseName, string serialNo) 
        {
            using (IConnection dbc = dataBase.Open())
            {
                SqlParameter[] p = new SqlParameter[2];
                p[0] = BuildParameter("@caseName", caseName);
                p[1] = BuildParameter("@serialNo", serialNo);
                return 1 == (int)this.ExecuteScalar(CommandType.StoredProcedure, "receiveList$caseVerified", p);
            }
        }

        /// <summary>
        /// Removes a sealed case from the list
        /// </summary>
        /// <param name="rl">
        /// List detail object
        /// </param>
        /// <param name="caseName">
        /// Case to remove from list
        /// </param>
        public void RemoveSealedCase(ReceiveListDetails rl, string caseName)
        {
            using (IConnection c = dataBase.Open())
            {
                try
                {
                    // Begin transaction
                    c.BeginTran("remove case from list");
                    // Insert email group
                    SqlParameter[] p = new SqlParameter[3];
                    p[0] = BuildParameter("@listId", rl.Id);
                    p[1] = BuildParameter("@rowversion", rl.RowVersion);
                    p[2] = BuildParameter("@caseName", caseName);
                    ExecuteNonQuery(CommandType.StoredProcedure, "receiveList$removeCase", p);
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


        #region Email Groups
        /// <summary>
        /// Gets the email groups associated with a particular list status
        /// </summary>
        /// <param name="rl">
        /// List status for which to get email groups
        /// </param>
        /// <returns>
        /// Email group collection
        /// </returns>
        public EmailGroupCollection GetEmailGroups(RLStatus rl)
        {
            using (IConnection c = dataBase.Open())
            {
                try
                {
                    SqlParameter[] p = new SqlParameter[2];
                    p[0] = BuildParameter("@listType", (int)ListTypes.Receive);
                    p[1] = BuildParameter("@status", (int)rl);
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
        /// <param name="rl">
        /// List status for which to get email groups
        /// </param>
        public void AttachEmailGroup(EmailGroupDetails e, RLStatus rl)
        {
            using (IConnection c = dataBase.Open())
            {
                try
                {
                    // Begin transaction
                    c.BeginTran("attach list status email group");
                    // Insert email group
                    SqlParameter[] p = new SqlParameter[3];
                    p[0] = BuildParameter("@listType", (int)ListTypes.Receive);
                    p[1] = BuildParameter("@status", (int)rl);
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
        /// <param name="rl">
        /// List status for which to get email groups
        /// </param>
        public void DetachEmailGroup(EmailGroupDetails e, RLStatus rl)
        {
            using (IConnection c = dataBase.Open())
            {
                try
                {
                    // Begin transaction
                    c.BeginTran("detach list status email group");
                    // Insert email group
                    SqlParameter[] p = new SqlParameter[3];
                    p[0] = BuildParameter("@listType", (int)ListTypes.Receive);
                    p[1] = BuildParameter("@status", (int)rl);
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
                    p[0] = BuildParameter("@listType", (int)ListTypes.Receive);
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
                    p[0] = BuildParameter("@listType", (int)ListTypes.Receive);
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
                    p[0] = BuildParameter("@listType", (int)ListTypes.Receive);
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
                    p[0] = BuildParameter("@listType", (int)ListTypes.Receive);
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
                    p[0] = BuildParameter("@listType", (int)ListTypes.Receive);
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
                    p[0] = BuildParameter("@listType", (int)ListTypes.Receive);
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
                    p[0] = BuildParameter("@listType", (int)ListTypes.Receive);
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
