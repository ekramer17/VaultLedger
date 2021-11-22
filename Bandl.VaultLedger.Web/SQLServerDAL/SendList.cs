using System;
using System.Data;
using System.Text;
using System.Collections;
using System.Data.SqlTypes;
using System.Data.SqlClient;
using Bandl.Library.VaultLedger.IDAL;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.Exceptions;
using Bandl.Library.VaultLedger.Collections;
using System.Text.RegularExpressions;

namespace Bandl.Library.VaultLedger.SQLServerDAL
{
	/// <summary>
	/// Summary description for SendList.
	/// </summary>
	public class SendList : SQLServer, ISendList
	{
        #region Constructors
        /// <summary>
        /// Default constructor
        /// </summary>
        public SendList() {}
        /// <summary>
        /// Creates a new data layer object that will use the given connection
        /// </summary>
        /// <param name="c">
        /// Connection that object should use when connecting to the database
        /// </param>
        public SendList(IConnection c) : base(c) {}
        /// <summary>
        /// Constructor that will or will not look for a persistent connection before
        /// creating a new one, depending on the value of demandCreate.
        /// </summary>
        /// <param name="demandCreate">
        /// If true, object will create a new connection.  If false, object will first
        /// search for a persistent connection on this thread for this session; if
        /// none is found, then a new connection will be created.
        /// </param>
        public SendList(bool demandCreate) : base(demandCreate) {}

        #endregion

        /// <summary>
        /// Gets the employed send list statuses from the database
        /// </summary>
        /// <returns>
        /// Receive list statuses used
        /// </returns>
        public SLStatus GetStatuses()
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    SqlParameter[] p = new SqlParameter[1];
                    p[0] = BuildParameter("@profileId", (int)ListTypes.Send);
                    using(SqlDataReader r = ExecuteReader(CommandType.StoredProcedure, "listStatusProfile$getById", p))
                    {
                        // If no data then throw exception
                        if(r.HasRows == false) 
                            return SLStatus.FullyVerifiedI | SLStatus.Xmitted;
                        // Move to the first record and get the statuses
                        r.Read();
                        return (SLStatus)Enum.ToObject(typeof(SLStatus), r.GetInt32(1));
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
        /// Updates the statuses used for send lists
        /// </summary>
        public void UpdateStatuses(SLStatus statuses)
        {
            using (IConnection c = dataBase.Open())
            {
                try
                {
                    c.BeginTran("update send list status profile");
                    SqlParameter[] p = new SqlParameter[2];
                    p[0] = BuildParameter("@profileId", (int)ListTypes.Send);
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
        /// Returns the information for a specific send list
        /// </summary>
        /// <param name="id">Unique identifier for a send list</param>
        /// <param name="getItems">
        /// Whether or not the user would like the details (items/cases) of the list
        /// </param>
        /// <returns>Returns the information for the send list</returns>
        public SendListDetails GetSendList(int id, bool getItems) 
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    SqlParameter[] listParms = new SqlParameter[1];
                    listParms[0] = BuildParameter("@id", id);
                    using(SqlDataReader r = ExecuteReader(CommandType.StoredProcedure, "sendList$getById", listParms))
                    {
                        // If no data then return null
                        if(r.HasRows == false) return null;
                        // Move to the first record and create a new instance
                        r.Read();
                        SendListDetails returnList = new SendListDetails(r);
                        // If there are any child lists, get them and attach them
                        // to the composite.
                        if (r.NextResult()) 
                        {
                            SendListCollection childLists = new SendListCollection(r);
                            returnList.ChildLists = (SendListDetails[])new ArrayList(childLists).ToArray(typeof(SendListDetails));
                        }
                        // If items and cases are requested, get them.
                        if (true == getItems) 
                        {
                            r.Close();
                            GetSendListItems(ref returnList);
                        }
                        // Return the list
                        return returnList;
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
        /// Returns the information for a specific send list
        /// </summary>
        /// <param name="name">Unique identifier for a send list</param>
        /// <param name="getItems">
        /// Whether or not the user would like the details (items/cases) of the list
        /// </param>
        /// <returns>Returns the information for the send list</returns>
        public SendListDetails GetSendList(string listName, bool getItems) 
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    SqlParameter[] listParms = new SqlParameter[1];
                    listParms[0] = BuildParameter("@listName", listName);
                    using(SqlDataReader r = ExecuteReader(CommandType.StoredProcedure, "sendList$getByName", listParms))
                    {
                        // If no data then retun null
                        if(r.HasRows == false) return null;
                        // Move to the first record and create a new instance
                        r.Read();
                        SendListDetails returnList = new SendListDetails(r);
                        // If there are any child lists, get them and attach them
                        // to the composite.
                        if (r.NextResult()) 
                        {
                            SendListCollection childLists = new SendListCollection(r);
                            returnList.ChildLists = (SendListDetails[])new ArrayList(childLists).ToArray(typeof(SendListDetails));
                        }
                        // If items and cases are requested, get them.
                        if (true == getItems) 
                        {
                            r.Close();
                            GetSendListItems(ref returnList);
                        }
                        // Return the list
                        return returnList;
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
        /// Returns the information for a specific send list on which the given item resides
        /// </summary>
        /// <param name="itemId">Id number for the given item</param>
        /// <param name="getItems">
        /// Whether or not the user would like the details (items/cases) of the list
        /// </param>
        /// <returns>Returns the information for the send list</returns>
        public SendListDetails GetSendListByItem(int itemId, bool getItems) 
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    SqlParameter[] listParms = new SqlParameter[1];
                    listParms[0] = BuildParameter("@itemid", itemId);
                    using(SqlDataReader r = ExecuteReader(CommandType.StoredProcedure, "sendList$getByItem", listParms))
                    {
                        // If no data then return null
                        if(r.HasRows == false) return null;
                        // Move to the first record and create a new instance
                        r.Read();
                        SendListDetails returnList = new SendListDetails(r);
                        // If there are any child lists, get them and attach them
                        // to the composite.
                        if (r.NextResult()) 
                        {
                            SendListCollection childLists = new SendListCollection(r);
                            returnList.ChildLists = (SendListDetails[])new ArrayList(childLists).ToArray(typeof(SendListDetails));
                        }
                        // If items and cases are requested, get them.
                        if (true == getItems) 
                        {
                            r.Close();
                            GetSendListItems(ref returnList);
                        }
                        // Return the list
                        return returnList;
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
        /// Returns the information for a specific send list on which the given medium resides
        /// </summary>
        /// <param name="serialNo">Serial number for a medium</param>
        /// <param name="getItems">
        /// Whether or not the user would like the details (items/cases) of the list
        /// </param>
        /// <returns>Returns the information for the send list</returns>
        public SendListDetails GetSendListByMedium(string serialNo, bool getItems) 
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    SqlParameter[] listParms = new SqlParameter[1];
                    listParms[0] = BuildParameter("@serialNo", serialNo);
                    using(SqlDataReader r = ExecuteReader(CommandType.StoredProcedure, "sendList$getByMedium", listParms))
                    {
                        // If no data then return null
                        if(r.HasRows == false) return null;
                        // Move to the first record and create a new instance
                        r.Read();
                        SendListDetails returnList = new SendListDetails(r);
                        // If there are any child lists, get them and attach them
                        // to the composite.
                        if (r.NextResult()) 
                        {
                            SendListCollection childLists = new SendListCollection(r);
                            returnList.ChildLists = (SendListDetails[])new ArrayList(childLists).ToArray(typeof(SendListDetails));
                        }
                        // If items and cases are requested, get them.
                        if (true == getItems) 
                        {
                            r.Close();
                            GetSendListItems(ref returnList);
                        }
                        // Return the list
                        return returnList;
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
                             FROM   XSENDLIST
                             WHERE  OBJECT = @n
                             UNION
                             SELECT ITEMID, DATE, OBJECT, ACTION, DETAIL, LOGIN, -1
                             FROM   XSENDLISTITEM
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
        /// Gets the send lists for a particular date
        /// </summary>
        /// <param name="date">Date for which to retrieve send lists</param>
        /// <returns>Collection of send lists created on the given date</returns>
        public SendListCollection GetListsByDate(DateTime date) 
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    SqlParameter[] listParms = new SqlParameter[1];
                    listParms[0] = BuildParameter("@createDate", date);
                    SendListCollection resultLists = new SendListCollection();
                    using(SqlDataReader r = ExecuteReader(CommandType.StoredProcedure, "sendList$getByDate", listParms))
                    {
                        // If no data then return empty collection
                        if(r.HasRows == false) 
                        {
                            return resultLists;
                        }
                        else
                        {
                            resultLists = new SendListCollection(r);
                        }
                    }
                    // For each of the lists in the collection, we need to
                    // fetch the list items.
                    for(int i = 0; i < resultLists.Count; i++) 
                    {
                        SendListDetails sendList = resultLists[i];
                        sendList = GetSendList(sendList.Id, true);
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
		/// Gets the send lists in the status(es)
		/// </summary>
		/// <param name="status">Status(es) to retrieve send lists</param>
		/// <param name="date">Date for which to retrieve send lists</param>
		/// <returns>Collection of send lists in the eligible status(es)</returns>

	public SendListCollection GetListsByStatusAndDate (SLStatus status, DateTime date)
	{
		using (IConnection dbc = dataBase.Open())
		{
			try
			{
				SqlParameter[] listParms = new SqlParameter[2];
				listParms[0] = BuildParameter("@status", status);
				listParms[1] = BuildParameter("@createDate", date);
				SendListCollection resultLists = new SendListCollection();
				using(SqlDataReader r = ExecuteReader(CommandType.StoredProcedure, "sendList$getByStatusAndDate", listParms))
				{
					// If no data then return empty collection
					if(r.HasRows == false) 
					{
						return resultLists;
					}
					else
					{
						resultLists = new SendListCollection(r);
					}
				}
				// For each of the lists in the collection, we need to
				// fetch the list items.
				for(int i = 0; i < resultLists.Count; i++) 
				{
					SendListDetails sendList = resultLists[i];
					sendList = GetSendList(sendList.Id, true);
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
        /// Gets the send lists created before a particular date that have been
        /// cleared.
        /// </summary>
        /// <param name="date">Create date</param>
        /// <returns>Collection of send lists</returns>
        public SendListCollection GetCleared(DateTime date) 
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    SqlParameter[] listParms = new SqlParameter[1];
                    listParms[0] = BuildParameter("@createDate", date);
                    SendListCollection resultLists = new SendListCollection();
                    using(SqlDataReader r = ExecuteReader(CommandType.StoredProcedure, "sendList$getCleared", listParms))
                    {
                        // If no data then return empty collection
                        if(r.HasRows == false)
                        {
                            return resultLists;
                        }
                        else
                        {
                            resultLists = new SendListCollection(r);
                        }
                    }
                    // If composite then get children
                    for(int i = 0; i < resultLists.Count; i++) 
                    {
                        if (String.Empty == resultLists[i].Account)
                        {
                            SendListDetails sl = resultLists[i];
                            sl = GetSendList(sl.Id, true);
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
		/// Returns a page of the contents of the SendList table
		/// </summary>
		/// <returns>Returns a collection of send lists in the given sort order</returns>
		public SendListCollection GetSendListPage(int pageNo, int pageSize, SLSorts sortColumn,out int totalLists)
		{
			return GetSendListPage(pageNo, pageSize, sortColumn, String.Empty, out totalLists);
		}
		/// <summary>
		/// Returns a page of the contents of the SendList table
		/// </summary>
		/// <returns>Returns a collection of send lists in the given sort order</returns>
		public SendListCollection GetSendListPage(int pageNo, int pageSize, SLSorts sortColumn, string filter, out int totalLists)
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
					using(SqlDataReader r = ExecuteReader(CommandType.StoredProcedure, "sendList$getPage", listParms))
					{
						SendListCollection m = new SendListCollection(r);
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
        /// Returns the information for a specific send list item
        /// </summary>
        /// <param name="itemId">
        /// Id number of the send list item
        /// </param>
        /// <returns>
        /// Send list item
        /// </returns>
        public SendListItemDetails GetSendListItem(int itemId)
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    SqlParameter[] itemParms = new SqlParameter[1];
                    itemParms[0] = BuildParameter("@itemId", itemId);
                    using(SqlDataReader r = ExecuteReader(CommandType.StoredProcedure, "sendListItem$get", itemParms))
                    {
                        if (r.HasRows == false)
                        {
                            return null;
                        }
                        else 
                        {
                            r.Read();
                            return new SendListItemDetails(r);
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
        /// Returns the information for a specific send list item
        /// </summary>
        /// <param name="serialNo">
        /// Serial number of a medium on a send list
        /// </param>
        /// <returns>
        /// Send list item
        /// </returns>
        public SendListItemDetails GetSendListItem(string serialNo)
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    SqlParameter[] itemParms = new SqlParameter[1];
                    itemParms[0] = BuildParameter("@serialNo", serialNo);
                    using(SqlDataReader r = ExecuteReader(CommandType.StoredProcedure, "sendListItem$getByMedium", itemParms))
                    {
                        if (r.HasRows == false)
                        {
                            return null;
                        }
                        else 
                        {
                            r.Read();
                            return new SendListItemDetails(r);
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
        /// Gets the number of entries on the send list with the given id
        /// </summary>
        /// <param name="listId">
        /// Id of list for which to get entry count
        /// </param>
        /// <returns>
        /// Number of entries on list
        /// </returns>
        public int GetSendListItemCount(int listId)
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    SqlParameter[] sqlParms = new SqlParameter[2];
                    sqlParms[0] = BuildParameter("@listId", listId);
                    sqlParms[1] = BuildParameter("@status", -1);
                    return (int)ExecuteScalar(CommandType.StoredProcedure, "sendList$getItemCount", sqlParms);
                }
                catch(SqlException e)
                {
                    PublishException(e);
                    throw new DatabaseException(StripErrorMsg(e.Message), e);
                }
            }
        }

        /// <summary>
        /// Gets the number of entries on the send list with the given id
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
        public int GetSendListItemCount(int listId, SLIStatus status)
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    SqlParameter[] sqlParms = new SqlParameter[2];
                    sqlParms[0] = BuildParameter("@listId", listId);
                    sqlParms[1] = BuildParameter("@status", (int)status);
                    return (int)ExecuteScalar(CommandType.StoredProcedure, "sendList$getItemCount", sqlParms);
                }
                catch(SqlException e)
                {
                    PublishException(e);
                    throw new DatabaseException(StripErrorMsg(e.Message), e);
                }
            }
        }

        /// <summary>
        /// Obtains the list details (items and cases) for a send list
        /// </summary>
        /// <param name="list">Send list for which to obtain details</param>
        private void GetSendListItems(ref SendListDetails list) 
        {
            // If the list is a composite, then we should get the details of
            // all its constituent lists.  Otherwise, get the cases followed
            // by the items for the list.
            if (true == list.IsComposite) 
            {
                foreach (SendListDetails s in list.ChildLists)
                {
                    SendListDetails s1 = s;
                    GetSendListItems(ref s1);
                }
            }
            else 
            {
                using (IConnection dbc = dataBase.Open())
                {
                    try
                    {
                        // Get the cases
                        SqlParameter[] caseParms = new SqlParameter[1];
                        caseParms[0] = BuildParameter("@listId", list.Id);
                        using(SqlDataReader r = ExecuteReader(CommandType.StoredProcedure, "sendList$getCases", caseParms))
                        {
                            if(r.HasRows == true) 
                            {
                                SendListCaseCollection cases = new SendListCaseCollection(r);
                                list.ListCases = (SendListCaseDetails[])new ArrayList(cases).ToArray(typeof(SendListCaseDetails));
                            }
                        }
                        // Get the items
                        SqlParameter[] itemParms = new SqlParameter[1];
                        itemParms[0] = BuildParameter("@listId", list.Id);
                        using(SqlDataReader r = ExecuteReader(CommandType.StoredProcedure, "sendList$getItems", itemParms))
                        {
                            if(r.HasRows == true) 
                            {
                                SendListItemCollection items = new SendListItemCollection(r);
                                list.ListItems = (SendListItemDetails[])new ArrayList(items).ToArray(typeof(SendListItemDetails));
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
        /// Returns a page of the items of a send list
        /// </summary>
        /// <returns>Returns a collection of send list items in the given sort order</returns>
        public SendListItemCollection GetSendListItemPage(int listId, int pageNo, int pageSize, SLISorts sortColumn, out int totalItems)
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
                    using(SqlDataReader r = ExecuteReader(CommandType.StoredProcedure, "sendListItem$getPage", itemParms))
                    {
                        SendListItemCollection m = new SendListItemCollection(r);
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
        /// Returns a page of the items of a send list
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
        /// Returns a collection of send list items in the given sort order
        /// </returns>
        public SendListItemCollection GetSendListItemPage(int listId, int pageNo, int pageSize, SLIStatus itemStatus, SLISorts sortColumn, out int totalItems)
        {
            // Build the filter string
            string pageFilter = String.Empty;
            foreach (int statusValue in Enum.GetValues(typeof(SLIStatus)))
            {
                if (statusValue != (int)SLIStatus.AllValues && (statusValue & Convert.ToInt32(itemStatus)) != 0)
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
                    using(SqlDataReader r = ExecuteReader(CommandType.StoredProcedure, "sendListItem$getPage", itemParms))
                    {
                        SendListItemCollection m = new SendListItemCollection(r);
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
        /// Gets a listing of the cases for a send list
        /// </summary>
        /// <param name="listId">
        /// Id of the list for which to get cases
        /// </param>
        public SendListCaseCollection GetSendListCases(int listId) 
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    // Get the cases
                    SqlParameter[] caseParms = new SqlParameter[1];
                    caseParms[0] = BuildParameter("@listId", listId);
                    SendListCaseCollection caseCollection = new SendListCaseCollection();
                    using(SqlDataReader r = ExecuteReader(CommandType.StoredProcedure, "sendList$getCases", caseParms))
                    {
                        if(r.HasRows == true) 
                            caseCollection = new SendListCaseCollection(r);
                    }
                    // return
                    return caseCollection;
                }
                catch(SqlException e)
                {
                    PublishException(e);
                    throw new DatabaseException(StripErrorMsg(e.Message), e);
                }
            }
        }

        /// <summary>
        /// Returns the information for a specific send list case
        /// </summary>
        /// <param name="id">Unique identifier for a send list case</param>
        /// <returns>Returns the information for the send list case</returns>
        public SendListCaseDetails GetSendListCase(int id)
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    SqlParameter[] caseParms = new SqlParameter[1];
                    caseParms[0] = BuildParameter("@id", id);
                    using(SqlDataReader r = ExecuteReader(CommandType.StoredProcedure, "sendListCase$getById", caseParms))
                    {
                        // If no data then throw exception return null
                        if(r.HasRows == false) return null;
                        // Move to the first record and create a new instance
                        r.Read();
                        return new SendListCaseDetails(r);
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
        /// Returns the information for a specific send list case
        /// </summary>
        /// <param name="caseName">Name of a send list case</param>
        /// <returns>Returns the information for the send list case</returns>
        public SendListCaseDetails GetSendListCase(string caseName)
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    SqlParameter[] p = new SqlParameter[1];
                    p[0] = BuildParameter("@caseName", caseName);
                    using(SqlDataReader r = ExecuteReader(CommandType.StoredProcedure, "sendListCase$getByName", p))
                    {
                        // If no data then throw exception return null
                        if(r.HasRows == false) return null;
                        // Move to the first record and create a new instance
                        r.Read();
                        return new SendListCaseDetails(r);
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
        /// Gets all of the media in a case
        /// </summary>
        /// <param name="caseName">
        /// Name of the case
        /// </param>
        /// <returns>
        /// Collection of the media in the case
        /// </returns>
        public MediumCollection GetCaseMedia(string caseName)
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    // Build parameters
                    SqlParameter[] p = new SqlParameter[1];
                    p[0] = BuildParameter("@caseName", caseName);
                    // Get the verified media
                    using (SqlDataReader r = ExecuteReader(CommandType.StoredProcedure, "sendListCase$getMedia", p))
                    {
                        return new MediumCollection(r);
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
		/// Determines whether the case is sealed
		/// </summary>
		/// <param name="caseName">
		/// Name of the case
		/// </param>
		/// <returns>
		/// Boolean indicating whether or not the case is sealed
		/// </returns>
		public bool IsCaseSealed(string caseName)
		{
			using (IConnection dbc = dataBase.Open())
			{
				try
				{
					// Build parameters
					SqlParameter[] parms = new SqlParameter[2];
					parms[0] = BuildParameter("@caseName", caseName);
					parms[1] = BuildParameter("@sealed", SqlDbType.Bit, ParameterDirection.Output);

					ExecuteNonQuery(CommandType.StoredProcedure, "sendListCase$isSealed", parms);
                    return Convert.ToBoolean(parms[1].Value);
				}
				catch(SqlException e)
				{
					PublishException(e);
					throw new DatabaseException(StripErrorMsg(e.Message), e);
				}
			}
		}


        /// <summary>
        /// Merges a collection of send lists
        /// </summary>
        /// <param name="listCollection">Collection of lists to merge</param>
        /// <returns>Composite list</returns>
        public SendListDetails Merge(SendListCollection listCollection) 
        {
            // Verify that there are at least two lists in the collection
            if (listCollection.Count < 2)
                throw new ArgumentException("Must have at least two lists to merge.", "listCollection");

            // Connect and begin transaction
            using (IConnection dbc = dataBase.Open())
            {
                // Initialize
                SendListDetails result = null;
                SendListCollection discretes = new SendListCollection();
                SendListCollection composites = new SendListCollection();
                // Get all the composites in one collection, all the discretes in another
                foreach (SendListDetails sl in listCollection)
                {
                    if (true == sl.IsComposite)
                        composites.Add(sl);
                    else
                        discretes.Add(sl);
                }
                // Merge the lists
                try 
                {
                    // Commence auditing
                    dbc.BeginTran("merge send list");
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
                            // Merge the lists
                            ExecuteNonQuery(CommandType.StoredProcedure, "sendList$merge", mergeParms);
                            // Get the updated result
                            result = GetSendList((int)mergeParms[4].Value, false);
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
                            ExecuteNonQuery(CommandType.StoredProcedure, "sendList$merge", mergeParms);
                            // Get the updated result
                            result = GetSendList((int)mergeParms[4].Value, false);
                        }
                    }
                    // Commit the transaction
                    dbc.CommitTran();
                    // return the merged list
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
        /// Creates a new send list from the given items and cases
        /// </summary>
        /// <param name="items">Items that will appear on the list(s)</param>
        /// <param name="initialStatus">
        /// Status with which the items are to be created.  Must be either verified
        /// or unverified.
        /// </param>
        /// <returns>Send list details object containing the created send list</returns>
        public SendListDetails Create(SendListItemCollection items, SLIStatus initialStatus)
        {
            // Create the connection
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    // Commence auditing
                    dbc.BeginTran("create send list");
                    // Add all the items into the database
                    StringBuilder listsInBatch = new StringBuilder(String.Empty);
                    foreach (SendListItemDetails i in items) 
                    {
                        SqlParameter[] itemParms = new SqlParameter[7];
                        itemParms[0] = BuildParameter("@serialNo", i.SerialNo);
                        itemParms[1] = BuildParameter("@initialStatus", (int)initialStatus);
                        itemParms[2] = BuildParameter("@caseName", i.CaseName);
                        itemParms[3] = BuildParameter("@returnDate", StringToDateTime(i.ReturnDate));
                        itemParms[4] = BuildParameter("@notes", i.Notes);
                        itemParms[5] = BuildParameter("@batchLists", listsInBatch.ToString());
                        itemParms[6] = BuildParameter("@newList", SqlDbType.NVarChar, ParameterDirection.Output);
                        itemParms[6].Size = 10;
                        // Insert the new item.  If the item is in a case, 
                        // it will be inserted as part of this procedure.
                        ExecuteNonQuery(CommandType.StoredProcedure, "sendListItem$ins", itemParms);
                        // If a new list was created then add it to the batch string
                        listsInBatch.Append(Convert.ToString(itemParms[6].Value));
                    }
                    // If more than one list was created, merge the lists
                    SendListDetails result;
                    switch (listsInBatch.Length)
                    {
                        case 0:
                            result = null;
                            break;
                        case 10:
                            result = GetSendList(listsInBatch.ToString(), false);
                            break;
                        default:
                            SendListCollection s = new SendListCollection();
                            for (int i = 0; i < listsInBatch.Length / 10; i++)
                                s.Add(GetSendList(listsInBatch.ToString(i * 10, 10), false));
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
        /// Extracts a send list from a composite
        /// </summary>
        /// <param name="compositeList">Composite list</param>
        /// <param name="discreteList">Discrete list to extract from composite</param>
        public void Extract(SendListDetails compositeList, SendListDetails discreteList)
        {
            // Create the connection
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    // Commence auditing
                    dbc.BeginTran("extract send list");
                    // Extract the list
                    SqlParameter[] extractParms = new SqlParameter[4];
                    extractParms[0] = BuildParameter("@listId", discreteList.Id);
                    extractParms[1] = BuildParameter("@listVersion", discreteList.RowVersion);
                    extractParms[2] = BuildParameter("@compositeId", compositeList.Id);
                    extractParms[3] = BuildParameter("@compositeVersion", compositeList.RowVersion);
                    ExecuteNonQuery(CommandType.StoredProcedure, "sendList$extract", extractParms);
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
        /// Dissolves a send list from composite.  In other words, extracts all
        /// discrete lists at once.
        /// </summary>
        /// <param name="compositeList">Composite list</param>
        public void Dissolve(SendListDetails compositeList) 
        {
            // Create the connection
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    // Commence auditing
                    dbc.BeginTran("extract send list");    // leave as extract
                    // Extract the list
                    SqlParameter[] extractParms = new SqlParameter[2];
                    extractParms[0] = BuildParameter("@listId", compositeList.Id);
                    extractParms[1] = BuildParameter("@listVersion", compositeList.RowVersion);
                    ExecuteNonQuery(CommandType.StoredProcedure, "sendList$dissolve", extractParms);
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
        /// Marks a list as in transit
        /// </summary>
        /// <param name="sl">
        /// Send list
        /// </param>
        public void MarkTransit(SendListDetails sl)
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    dbc.BeginTran("update send list");
                    // Remove the items
                    SqlParameter[] p = new SqlParameter[2];
                    p[0] = BuildParameter("@listId", sl.Id);
                    p[1] = BuildParameter("@rowVersion", sl.RowVersion);
                    ExecuteNonQuery(CommandType.StoredProcedure, "sendList$transit", p);
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
        /// <param name="sl">
        /// Send list
        /// </param>
        public void MarkArrived(SendListDetails sl)
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    dbc.BeginTran("update send list");
                    // Remove the items
                    SqlParameter[] p = new SqlParameter[2];
                    p[0] = BuildParameter("@listId", sl.Id);
                    p[1] = BuildParameter("@rowVersion", sl.RowVersion);
                    ExecuteNonQuery(CommandType.StoredProcedure, "sendList$arrive", p);
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
        /// Transmits a send list
        /// </summary>
        /// <param name="list">Send list to transmit</param>
        /// <param name="clear">Whether or not to clear the list after a successful transmit</param>
        public void Transmit(SendListDetails list, bool clear)
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    // Commence auditing
                    dbc.BeginTran("transmit send list");
                    // Transmit the list
                    SqlParameter[] transmitParms = new SqlParameter[2];
                    transmitParms[0] = BuildParameter("@listId", list.Id);
                    transmitParms[1] = BuildParameter("@rowVersion", list.RowVersion);
                    ExecuteNonQuery(CommandType.StoredProcedure, "sendList$transmit", transmitParms);
                    // Clear the list if requested -- refetch to avoid concurrency error
                    if (clear == true) Clear(GetSendList(list.Id, false));
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
        /// Transmits a send list collection
        /// </summary>
        /// <param name="listCollection">Send list collection to transmit</param>
        /// <param name="clear">Whether or not to clear the lists after a successful transmit</param>
        public void Transmit(SendListCollection listCollection, bool clear)
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    dbc.BeginTran("transmit send list");
                    // Transmit each list
                    foreach(SendListDetails list in listCollection) 
                        Transmit(list, clear);
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
        /// Clears a send list
        /// </summary>
        /// <param name="list">Send list to clear</param>
        public void Clear(SendListDetails list)
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    dbc.BeginTran("clear send list");
                    // Clear the list
                    SqlParameter[] clearParms = new SqlParameter[2];
                    clearParms[0] = BuildParameter("@listId", list.Id);
                    clearParms[1] = BuildParameter("@rowVersion", list.RowVersion);
                    ExecuteNonQuery(CommandType.StoredProcedure, "sendList$clear", clearParms);
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
        /// Deletes a send list
        /// </summary>
        /// <param name="list">Send list to delete</param>
        public void Delete(SendListDetails list)
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    dbc.BeginTran("delete send list");
                    // Delete the list
                    SqlParameter[] deleteParms = new SqlParameter[2];
                    deleteParms[0] = BuildParameter("@listId", list.Id);
                    deleteParms[1] = BuildParameter("@rowVersion", list.RowVersion);
                    ExecuteNonQuery(CommandType.StoredProcedure, "sendList$del", deleteParms);
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
        /// Verifies a sendlist item
        /// </summary>
        /// <param name="item">
        /// A send list item to verify
        /// </param>
        public void VerifyItem(SendListItemDetails item)
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    dbc.BeginTran("verify send list item");
                    SqlParameter[] verifyParms = new SqlParameter[2];
                    verifyParms[0] = BuildParameter("@itemId", item.Id);
                    verifyParms[1] = BuildParameter("@rowVersion", item.RowVersion);
                    ExecuteNonQuery(CommandType.StoredProcedure, "sendListItem$verify", verifyParms);
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
        /// Removes a send list item
        /// </summary>
        /// <param name="item">
        /// A send list item to remove
        /// </param>
        public void RemoveItem(SendListItemDetails item)
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    dbc.BeginTran("remove send list item");
                    SqlParameter[] removeParms = new SqlParameter[2];
                    removeParms[0] = BuildParameter("@itemId", item.Id);
                    removeParms[1] = BuildParameter("@rowVersion", item.RowVersion);
                    ExecuteNonQuery(CommandType.StoredProcedure, "sendListItem$remove", removeParms);
                    dbc.CommitTran();
                }
                catch(SqlException e)
                {
                    dbc.RollbackTran();
                    PublishException(e);
                    throw new DatabaseException(StripErrorMsg(e.Message), e);
                }
            }
        }   // end RemoveItems()

        /// <summary>
        /// Updates a send list item
        /// </summary>
        /// <param name="item">
        /// A send list item to update
        /// </param>
        public void UpdateItem(SendListItemDetails item)        
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    dbc.BeginTran("update send list item");
                    SqlParameter[] updateParms = new SqlParameter[5];
                    updateParms[0] = BuildParameter("@itemId", item.Id);
                    updateParms[1] = BuildParameter("@returnDate", StringToDateTime(item.ReturnDate));
                    updateParms[2] = BuildParameter("@notes", item.Notes);
                    updateParms[3] = BuildParameter("@caseName", item.CaseName);
                    updateParms[4] = BuildParameter("@rowVersion", item.RowVersion);
                    ExecuteNonQuery(CommandType.StoredProcedure, "sendListItem$upd", updateParms);
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
        /// Adds a send list item to an existing list
        /// </summary>
        /// <param name="list">
        /// List to which items should be added
        /// </param>
        /// <param name="item">
        /// Send list item object to add
        /// </param>
        /// <param name="initialStatus">
        /// Items may be added as unverified or verified
        /// </param>
        public void AddItem(SendListDetails list, SendListItemDetails item, SLIStatus initialStatus)        
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    dbc.BeginTran("add send list item");
                    SqlParameter[] addParms = new SqlParameter[6];
                    addParms[0] = BuildParameter("@serialNo", item.SerialNo);
                    addParms[1] = BuildParameter("@initialStatus", (int)initialStatus);
                    addParms[2] = BuildParameter("@caseName", item.CaseName);
                    addParms[3] = BuildParameter("@returnDate", StringToDateTime(item.ReturnDate));
                    addParms[4] = BuildParameter("@notes", item.Notes);
                    addParms[5] = BuildParameter("@listId", list.Id);
                    ExecuteNonQuery(CommandType.StoredProcedure, "sendListItem$add", addParms);
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
        /// Removes item from case
        /// </summary>
        /// <param name="itemId">
        /// Id number of send list item object
        /// </param>
        /// <param name="caseId">
        /// Id number of send list case object
        /// </param>
        public void RemoveItemFromCase(int itemId, int caseId) 
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    dbc.BeginTran("remove send list item from case");
                    SqlParameter[] sqlParm = new SqlParameter[2];
                    sqlParm[0] = BuildParameter("@itemId", itemId);
                    sqlParm[1] = BuildParameter("@caseId", caseId);
                    ExecuteNonQuery(CommandType.StoredProcedure, "sendListItemCase$remove", sqlParm);
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
        /// Updates a send list case
        /// </summary>
        /// <param name="item">
        /// A send list case to update
        /// </param>
        public void UpdateCase(SendListCaseDetails sendCase)        
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    dbc.BeginTran("update send list case");
                    SqlParameter[] p = new SqlParameter[7];
                    p[0] = BuildParameter("@caseId", sendCase.Id);
                    p[1] = BuildParameter("@typeName", sendCase.Type);
                    p[2] = BuildParameter("@caseName", sendCase.Name);
                    p[3] = BuildParameter("@sealed", sendCase.Sealed);
                    p[4] = BuildParameter("@returndate", sendCase.ReturnDate.Length != 0 ? DateTime.Parse(sendCase.ReturnDate) : SqlDateTime.Null);
                    p[5] = BuildParameter("@notes", sendCase.Notes);
                    p[6] = BuildParameter("@rowVersion", sendCase.RowVersion);
                    ExecuteNonQuery(CommandType.StoredProcedure, "sendListCase$upd", p);
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
        /// Deletes a send list case
        /// </summary>
        /// <param name="item">
        /// A send list case to delete
        /// </param>
        public void DeleteCase(SendListCaseDetails sendCase)        
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    dbc.BeginTran("delete send list case");
                    SqlParameter[] deleteParms = new SqlParameter[2];
                    deleteParms[0] = BuildParameter("@caseId", sendCase.Id);
                    deleteParms[1] = BuildParameter("@rowVersion", sendCase.RowVersion);
                    ExecuteNonQuery(CommandType.StoredProcedure, "sendListCase$del", deleteParms);
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
        /// Returns the information for a specific send list scan
        /// </summary>
        /// <param name="id">Unique identifier for a send list scan</param>
        /// <returns>Returns the information for the send list scan</returns>
        public SendListScanDetails GetScan(int id) 
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    SqlParameter[] scanParms = new SqlParameter[1];
                    scanParms[0] = BuildParameter("@id", id);
                    using(SqlDataReader r = ExecuteReader(CommandType.StoredProcedure, "sendListScan$getById", scanParms))
                    {
                        // If no data then return null
                        if(r.HasRows == false) return null;
                        // Move to the first record and create a new instance
                        r.Read();
                        SendListScanDetails s = new SendListScanDetails(r);
                        // Get the items of the scan
						if (r.NextResult())
						{
							SendListScanItemCollection scanItems = new SendListScanItemCollection(r);
							s.ScanItems = (SendListScanItemDetails[])new ArrayList(scanItems).ToArray(typeof(SendListScanItemDetails));
						}
                        // Return the list
                        return s;
                    }
                }
                catch(SqlException e)
                {
                    PublishException(e);
                    throw new DatabaseException(StripErrorMsg(e.Message), e);
                }
            }
        }   // end GetScan()

        /// <summary>
        /// Returns the information for a specific send list scan
        /// </summary>
        /// <param name="name">Unique identifier for a send list scan</param>
        /// <returns>Returns the information for the send list scan</returns>
        public SendListScanDetails GetScan(string name) 
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    SqlParameter[] scanParms = new SqlParameter[1];
                    scanParms[0] = BuildParameter("@scanName", name);
                    using(SqlDataReader r = ExecuteReader(CommandType.StoredProcedure, "sendListScan$getByName", scanParms))
                    {
                        // If no data then return null
                        if(r.HasRows == false) return null;
                        // Move to the first record and create a new instance
                        r.Read();
                        SendListScanDetails s = new SendListScanDetails(r);
                        // Get the items of the scan
						if (r.NextResult())
						{
							SendListScanItemCollection scanItems = new SendListScanItemCollection(r);
                            s.ScanItems = (SendListScanItemDetails[])new ArrayList(scanItems).ToArray(typeof(SendListScanItemDetails));
						}
                        // Return the list
                        return s;
                    }
                }
                catch(SqlException e)
                {
                    PublishException(e);
                    throw new DatabaseException(StripErrorMsg(e.Message), e);
                }
            }
        }   // end GetScan()

        /// <summary>
        /// Gets the scans for a specified send list
        /// </summary>
        /// <param name="listName">
        /// Name of the list
        /// </param>
        /// <returns>
        /// Collection of scans
        /// </returns>
        public SendListScanCollection GetScansForList(string listName, int stage)
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    SqlParameter[] scanParms = new SqlParameter[2];
                    scanParms[0] = BuildParameter("@listName", listName);
                    scanParms[1] = BuildParameter("@stage", stage);
                    using(SqlDataReader r = ExecuteReader(CommandType.StoredProcedure, "sendListScan$getByList", scanParms))
                    {
                        SendListScanCollection s = new SendListScanCollection();
                        if(r.HasRows == true) s.Fill(r);
                        return s;
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
        /// Creates a send list scan
        /// </summary>
        /// <returns>Created send list scan</returns>
        public SendListScanDetails CreateScan(string listName, string scanName, SendListScanItemDetails item)
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    // Commence auditing
                    dbc.BeginTran("create send list scan");
                    // Create the scan
                    SqlParameter[] scanParms = new SqlParameter[3];
                    scanParms[0] = BuildParameter("@listName", listName);
                    scanParms[1] = BuildParameter("@scanName", scanName);
                    scanParms[2] = BuildParameter("@newId", SqlDbType.Int, ParameterDirection.Output);
                    ExecuteNonQuery(CommandType.StoredProcedure, "sendListScan$ins", scanParms);
                    int newId = Convert.ToInt32(scanParms[2].Value);
                    // Insert the item
                    SqlParameter[] itemParms = new SqlParameter[3];
                    itemParms[0] = BuildParameter("@scanId", newId);
                    itemParms[1] = BuildParameter("@serialNo", item.SerialNo);
                    itemParms[2] = BuildParameter("@caseName", item.CaseName);
                    ExecuteNonQuery(CommandType.StoredProcedure, "sendListScanItem$ins", itemParms);
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
        }   // end CreateScan()

        /// <summary>
        /// Deletes a set of send list scans
        /// </summary>
        public void DeleteScan(SendListScanDetails scan)
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    dbc.BeginTran("delete send list scan");
                    SqlParameter[] deleteParms = new SqlParameter[1];
                    deleteParms[0] = BuildParameter("@scanId", scan.Id);
                    ExecuteNonQuery(CommandType.StoredProcedure, "sendListScan$del", deleteParms);
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
        /// Returns the information for a specific send list scan item
        /// </summary>
        /// <param name="id">
        /// Id of the item
        /// </param>
        /// <returns>
        /// Send list scan item object
        /// </returns>
        public SendListScanItemDetails GetScanItem(int id)
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    SqlParameter[] itemParms = new SqlParameter[1];
                    itemParms[0] = BuildParameter("@itemId", id);
                    using(SqlDataReader r = ExecuteReader(CommandType.StoredProcedure, "sendListScanItem$get", itemParms))
                    {
                        // If no data then throw exception
                        if(r.HasRows == false) return null;
                        // Move to the first record and create a new instance
                        r.Read();
                        return new SendListScanItemDetails(r);
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
		/// Returns the case name for a specific send list scan item
		/// </summary>
		/// <param name="listid">
		/// Id of the list
		/// </param>
		/// <param name="serial">
		/// Serial number
		/// </param>
		/// <returns>
		/// Case name
		/// </returns>
		public string GetScanItemCase(int listid, string serial)
		{
			using (IConnection dbc = dataBase.Open())
			{
				try
				{
					SqlParameter[] itemParms = new SqlParameter[2];
					itemParms[0] = BuildParameter("@listId", listid);
					itemParms[1] = BuildParameter("@serialNo", serial);
					using(SqlDataReader r = ExecuteReader(CommandType.StoredProcedure, "sendListScanItem$getCase", itemParms))
					{
						// If no data then throw exception
						if(r.HasRows == false) return String.Empty;
						// Move to the first record and create a new instance
						r.Read();
						return r.GetString(0);
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
        /// Adds an item to a scan
        /// </summary>
        public void AddScanItem(int scanId, SendListScanItemDetails item)        
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    dbc.BeginTran("add send list scan item");
                    SqlParameter[] itemParms = new SqlParameter[3];
                    itemParms[0] = BuildParameter("@scanId", scanId);
                    itemParms[1] = BuildParameter("@serialNo", item.SerialNo);
                    itemParms[2] = BuildParameter("@caseName", item.CaseName);
                    ExecuteNonQuery(CommandType.StoredProcedure, "sendListScanItem$ins", itemParms);
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
        /// Deletes a set of scan items
        /// </summary>
        public void DeleteScanItem(int itemId) 
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    dbc.BeginTran("delete send list scan item");
                    SqlParameter[] itemParms = new SqlParameter[1];
                    itemParms[0] = BuildParameter("@itemId", itemId);
                    ExecuteNonQuery(CommandType.StoredProcedure, "sendListScanItem$del", itemParms);
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
        /// <param name="scans">
        /// Scans to compare against the list
        /// </param>
        /// <returns>
        /// Structure holding the results of the comparison
        /// </returns>
        public SendListCompareResult CompareListToScans(string listName)
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    // Commence auditing
                    dbc.BeginTran("compare send list to scan");
                    // Get the scan names for this list
                    ArrayList scanNames = new ArrayList();
                    SendListDetails sl = GetSendList(listName, false);
                    SendListScanCollection scanCollection = GetScansForList(listName, sl.Status <= SLStatus.PartiallyVerifiedI ? 1 : 2);
                    // Create a list compare result with the returned scans
                    foreach(SendListScanDetails s in scanCollection) {scanNames.Add(s.Name);}
                    SendListCompareResult result = new SendListCompareResult(listName, (string[])scanNames.ToArray(typeof(string)));
                    // Compare list to scans
                    SqlParameter[] compareParms = new SqlParameter[1];
                    compareParms[0] = BuildParameter("@listName", listName);
                    using(SqlDataReader r = ExecuteReader(CommandType.StoredProcedure, "sendListScan$Compare", compareParms))
                    {
                        // Create ArrayLists to hold the differences
                        ArrayList listNotScan = new ArrayList();
                        ArrayList scanNotList = new ArrayList();
                        ArrayList casesDiffer = new ArrayList();
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
                        // The third result set holds the case differences
                        if (r.NextResult() && r.HasRows == true) 
                        {
                            while(r.Read()) 
                            {   
                                string serialNo = r.GetString(1);
                                string listCase = r.GetString(2);
                                string scanCase = r.GetString(3);
                                casesDiffer.Add(new SendListCompareResult.CaseDisparity(serialNo, listCase, scanCase));
                            }
                        }
                        // Assign all the arrays to the result object
                        result.ListNotScan = (string[])listNotScan.ToArray(typeof(string));
                        result.ScanNotList = (string[])scanNotList.ToArray(typeof(string));
                        result.CaseDifferences = (SendListCompareResult.CaseDisparity[])casesDiffer.ToArray(typeof(SendListCompareResult.CaseDisparity));
                    }
                    // Commit
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
        /// Gets the send list cases for the browse page
        /// </summary>
        /// <returns>
        /// A send list case collection
        /// </returns>
        public SendListCaseCollection GetSendListCases()
        {
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    using(SqlDataReader r = ExecuteReader(CommandType.StoredProcedure, "sendListCase$browse"))
                    {
                        return new SendListCaseCollection(r);
                    }
                }
                catch(SqlException e)
                {
                    PublishException(e);
                    throw new DatabaseException(StripErrorMsg(e.Message), e);
                }
            }
        }

        #region Email Groups
        /// <summary>
        /// Gets the email groups associated with a particular list status
        /// </summary>
        /// <param name="sl">
        /// List status for which to get email groups
        /// </param>
        /// <returns>
        /// Email group collection
        /// </returns>
        public EmailGroupCollection GetEmailGroups(SLStatus sl)
        {
            using (IConnection c = dataBase.Open())
            {
                try
                {
                    SqlParameter[] p = new SqlParameter[2];
                    p[0] = BuildParameter("@listType", (int)ListTypes.Send);
                    p[1] = BuildParameter("@status", (int)sl);
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
        /// <param name="sl">
        /// List status for which to get email groups
        /// </param>
        public void AttachEmailGroup(EmailGroupDetails e, SLStatus sl)
        {
            using (IConnection c = dataBase.Open())
            {
                try
                {
                    // Begin transaction
                    c.BeginTran("attach list status email group");
                    // Insert email group
                    SqlParameter[] p = new SqlParameter[3];
                    p[0] = BuildParameter("@listType", (int)ListTypes.Send);
                    p[1] = BuildParameter("@status", (int)sl);
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
        public void DetachEmailGroup(EmailGroupDetails e, SLStatus sl)
        {
            using (IConnection c = dataBase.Open())
            {
                try
                {
                    // Begin transaction
                    c.BeginTran("detach list status email group");
                    // Insert email group
                    SqlParameter[] p = new SqlParameter[3];
                    p[0] = BuildParameter("@listType", (int)ListTypes.Send);
                    p[1] = BuildParameter("@status", (int)sl);
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
                    p[0] = BuildParameter("@listType", (int)ListTypes.Send);
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
                    p[0] = BuildParameter("@listType", (int)ListTypes.Send);
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
                    p[0] = BuildParameter("@listType", (int)ListTypes.Send);
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
                    p[0] = BuildParameter("@listType", (int)ListTypes.Send);
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
                    p[0] = BuildParameter("@listType", (int)ListTypes.Send);
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
                    p[0] = BuildParameter("@listType", (int)ListTypes.Send);
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
                    p[0] = BuildParameter("@listType", (int)ListTypes.Send);
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
