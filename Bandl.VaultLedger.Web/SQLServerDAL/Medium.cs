using System;
using System.Text;
using System.Data;
using System.Collections;
using System.Data.SqlTypes;
using System.Data.SqlClient;
using Bandl.Library.VaultLedger.IDAL;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.Exceptions;
using Bandl.Library.VaultLedger.Collections;

namespace Bandl.Library.VaultLedger.SQLServerDAL
{
    /// <summary>
    /// Medium data access object
    /// </summary>
	public class Medium : SQLServer, IMedium
	{
		#region Constructors
		/// <summary>
		/// Default constructor
		/// </summary>
		public Medium() {}
		/// <summary>
		/// Creates a new data layer object that will use the given connection
		/// </summary>
		/// <param name="c">
		/// Connection that object should use when connecting to the database
		/// </param>
		public Medium(IConnection c) : base(c) {}
		/// <summary>
		/// Constructor that will or will not look for a persistent connection before
		/// creating a new one, depending on the value of demandCreate.
		/// </summary>
		/// <param name="demandCreate">
		/// If true, object will create a new connection.  If false, object will first
		/// search for a persistent connection on this thread for this session; if
		/// none is found, then a new connection will be created.
		/// </param>
		public Medium(bool demandCreate) : base(demandCreate) {}

		#endregion

		/// <summary>
		/// Returns the profile information for a specific medium
		/// </summary>
		/// <param name="serialNo">Unique serial number of a medium</param>
		/// <returns>Returns the profile information for the medium</returns>
		public MediumDetails GetMedium(string serialNo)
		{   
			using (IConnection dbc = dataBase.Open())
			{
				try
				{
					SqlParameter[] mediumParms = new SqlParameter[1];
					mediumParms[0] = BuildParameter("@serialNo", serialNo);
					using(SqlDataReader r = ExecuteReader(CommandType.StoredProcedure, "medium$getBySerialNo", mediumParms))
					{
						// If no data then return null
						if(r.HasRows == false) return null;
						// Move to the first record and create a new instance
						r.Read(); 
						return(new MediumDetails(r));
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
		/// Gets the number of media in the database
		/// </summary>
		/// <returns>
		/// Number of media in the database
		/// </returns>
		public int GetMediumCount()
		{
			using(IConnection dbc = dataBase.Open())
			{
				try
				{
					return (int)ExecuteScalar(CommandType.StoredProcedure, "medium$getCount");
				}
				catch(SqlException e)
				{
					PublishException(e);
					throw new DatabaseException(StripErrorMsg(e.Message), e);
				}
			}
		}

		/// <summary>
		/// Returns all the media in a given sealed case
		/// </summary>
		/// <returns>
		/// Returns a collection of media in the given sealed case
		/// </returns>
		public MediumCollection GetMediaInCase(string caseName)
		{
			using (IConnection dbc = dataBase.Open())
			{
				try
				{
					SqlParameter[] mediumParms = new SqlParameter[1];
					mediumParms[0] = BuildParameter("@caseName", caseName);
					using(SqlDataReader r = ExecuteReader(CommandType.StoredProcedure, "medium$getByCase", mediumParms))
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
		/// Returns a page of the contents of the Medium table
		/// </summary>
		/// <returns>Returns a collection of media that fit the given filter in the given sort order</returns>
		public MediumCollection GetMediumPage(int pageNo, int pageSize, MediumFilter filter, MediumSorts sortColumn, out int totalMedia)
		{
			using (IConnection dbc = dataBase.Open())
			{
				try
				{
					string filterString = CreateFilterString(filter);
					SqlParameter[] mediumParms = new SqlParameter[4];
					mediumParms[0] = BuildParameter("@pageNo", pageNo);
					mediumParms[1] = BuildParameter("@pageSize", pageSize);
					mediumParms[2] = BuildParameter("@filter", filterString);
					mediumParms[3] = BuildParameter("@sort", (short)sortColumn);
					using(SqlDataReader r = ExecuteReader(CommandType.StoredProcedure, "medium$getPage", mediumParms))
					{
						MediumCollection m = new MediumCollection(r);
						r.NextResult();
						r.Read();
						totalMedia = r.GetInt32(r.GetOrdinal("RecordCount"));
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
		public string[] GetRecallCodes(params string[] serialNos)
		{
			using (IConnection dbc = dataBase.Open())
			{
				try
				{
					string[] recallCodes = new string[serialNos.Length];
					for(int i = 0; i < serialNos.Length; i++)
					{
						SqlParameter[] mediumParms = new SqlParameter[1];
						mediumParms[0] = BuildParameter("@serialNo", serialNos[i]);
						recallCodes[i] = (string)ExecuteScalar(CommandType.StoredProcedure, "medium$getRecallCode", mediumParms);
						if (recallCodes[i] == null || recallCodes[i] == String.Empty)
							throw new ApplicationException(String.Format("Medium code not found for medium: {0}", serialNos[i]));
					}
					// return the string array
					return recallCodes;
				}
				catch(SqlException e)
				{
					PublishException(e);
					throw new DatabaseException(StripErrorMsg(e.Message), e);
				}
			}
		}

		/// <summary>
		/// Returns the profile information for a specific medium
		/// </summary>
		/// <param name="id">Unique identifier of a medium</param>
		/// <returns>Returns the profile information for the medium</returns>
		public MediumDetails GetMedium(int id)
		{   
			using (IConnection dbc = dataBase.Open())
			{
				try
				{
					SqlParameter[] mediumParms = new SqlParameter[1];
					mediumParms[0] = BuildParameter("@id", id);
					using(SqlDataReader r = ExecuteReader(CommandType.StoredProcedure, "medium$getById", mediumParms))
					{
						// If no data then return null
						if(r.HasRows == false) return null;
						// Move to the first record and create a new instance
						r.Read(); 
						return(new MediumDetails(r));
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
		/// Determines whether or not a serial number already exists
		/// </summary>
		/// <param name="serialNo">
		/// Serial number to test
		/// </param>
		/// <returns>
		/// True if the serial number exists, else false
		/// </returns>
		private bool Exists(string serialNo)
		{
			using (IConnection dbc = dataBase.Open())
			{
				try
				{
					SqlParameter[] sqlParm = new SqlParameter[1];
					sqlParm[0] = BuildParameter("@serialNo", serialNo);
					if (0 == (int)ExecuteScalar(CommandType.StoredProcedure, "medium$exists", sqlParm))
					{
						return false;
					}
					else
					{
						return true;
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
		/// A method to insert a single new medium
		/// </summary>
		/// <param name="serialNo">
		/// Serial number to add
		/// </param>
		/// <param name="loc">
		/// Original location of medium
		/// </param>
		public void Insert(string serialNo, Locations loc)
		{
			this.Insert(new MediumDetails(serialNo, String.Empty, String.Empty, loc, String.Empty, String.Empty));
		}

		/// <summary>
		/// A method to insert a new medium
		/// </summary>
		/// <param name="m">A details entity with new medium information to insert</param>
		public void Insert(MediumDetails m)
		{
			// Check the media license
			int mediaAllowed = (new ProductLicense()).GetProductLicense(LicenseTypes.Media).Units;
			if (mediaAllowed != ProductLicenseDetails.Unlimited && GetMediumCount() + 1 > mediaAllowed)
				throw new ApplicationException("Additional media licenses required");
			// Add the medium
			using (IConnection dbc = dataBase.Open())
			{
				try
				{
					dbc.BeginTran("insert medium");
					// Build parameters
					SqlParameter[] mediumParms = new SqlParameter[9];
					mediumParms[0] = BuildParameter("@serialNo", m.SerialNo);
					mediumParms[1] = BuildParameter("@location", (int) m.Location);
					mediumParms[2] = BuildParameter("@hotStatus", m.HotSite);
					mediumParms[3] = BuildParameter("@returnDate", m.ReturnDate.Length != 0 ? DateTime.Parse(m.ReturnDate) : SqlDateTime.Null);
					mediumParms[4] = BuildParameter("@bSide", m.Flipside);
					mediumParms[5] = BuildParameter("@notes", m.Notes);
					mediumParms[6] = BuildParameter("@mediumType", m.MediumType);
					mediumParms[7] = BuildParameter("@accountName", m.Account);
					mediumParms[8] = BuildParameter("@newId", SqlDbType.Int, ParameterDirection.Output);
					// Insert the new operator
					ExecuteNonQuery(CommandType.StoredProcedure, "medium$ins", mediumParms);
					int newId = Convert.ToInt32(mediumParms[8].Value);
					// Commit the transaction
					dbc.CommitTran();
				}
				catch(SqlException e)
				{
					// Rollback the transaction
					dbc.RollbackTran();
					// Issue exception
					if (e.Message.IndexOf("akMedium$SerialNo") != -1)
					{
						m.RowError = "A medium with the serial number '" + m.SerialNo + "' already exists.";
						throw new DatabaseException(m.RowError, e);
					}
					else
					{
						PublishException(e);
						m.RowError = StripErrorMsg(e.Message);
						throw new DatabaseException(StripErrorMsg(e.Message), e);
					}
				}
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
		public int Insert(string start, string end, Locations loc, out MediumRange[] subRanges)
		{
			subRanges = null;
			int returnValue = 0;
			string serialNo = start;
			string mediumType = String.Empty;
			string accountName = String.Empty;
			ArrayList rangeList = new ArrayList();

			// Get the medium license from the database.
			int mediaLimit = (new ProductLicense()).GetProductLicense(LicenseTypes.Media).Units;
			// Add the media
			using (IConnection dbc = dataBase.Open())
			{
				try
				{
					// Do a pre-insert check on the license
					if (mediaLimit != ProductLicenseDetails.Unlimited)
					{
						int totalInsert = 0;
						string nextSerial = start;
						while (nextSerial.CompareTo(end) <= 0)
						{
							if (this.Exists(nextSerial) == false)
							{
								totalInsert += 1;
							}
							// Get the next serial number
							nextSerial = NextSerialNumber(nextSerial);
						}
						if (totalInsert + this.GetMediumCount() > mediaLimit)
						{
							throw new ApplicationException("Additional media licenses required");
						}
					}
					// Get the defaults for the first serial number
					PatternDefaultMedium pdm = new PatternDefaultMedium();
					pdm.GetMediumDefaults(serialNo, out mediumType, out accountName);
					MediumRange currentRange = new MediumRange(start, start, mediumType, accountName);
					// Begin the transaction
					dbc.BeginTran("insert medium");
					// Loop through, adding serial numbers
					while (serialNo.CompareTo(end) <= 0)
					{   
						try
						{
							// If the medium type or account number has changed, add the current range
							// object to the array list and create a new one.  Otherwise, set the
							// ending serial number in the current range to the current serial number.
							pdm.GetMediumDefaults(serialNo, out mediumType, out accountName);
							if (mediumType == currentRange.MediumType && accountName == currentRange.AccountName)
							{
								currentRange.SerialEnd = serialNo;
							}
							else
							{
								rangeList.Add(currentRange);
								currentRange = new MediumRange(serialNo, serialNo, mediumType, accountName);
							}
							// Check medium existence.  If it doesn't exist, insert it.
							if (this.Exists(serialNo) == false)
							{
								MediumDetails newMedium = new MediumDetails(serialNo, mediumType, accountName, loc, String.Empty, String.Empty);
								this.Insert(newMedium);
								returnValue += 1;
							}
							// Get the next serial number
							serialNo = NextSerialNumber(serialNo);
						}
						catch (SqlException e)
						{
							dbc.RollbackTran();
							PublishException(e);
							throw new DatabaseException(StripErrorMsg(e.Message), e);
						}
					}
					// Confirm that we have not violated a license.  We shouldn't have, as we
					// did a preliminary check, but check just in case.
					if (mediaLimit != ProductLicenseDetails.Unlimited)
					{
						if (this.GetMediumCount() > mediaLimit)
						{
							throw new ApplicationException("Additional media licenses required");
						}
					}
					// Commit the transaction
					dbc.CommitTran();
					// Add the final range to the array list and convert to an array
					rangeList.Add(currentRange);
					subRanges = (MediumRange[])rangeList.ToArray(typeof(MediumRange));
					// Return
					return returnValue;
				}
				catch(SqlException e)
				{
					subRanges = null;
					dbc.RollbackTran();
					PublishException(e);
					throw new DatabaseException(StripErrorMsg(e.Message), e);
				}
				catch(ApplicationException)
				{
					subRanges = null;
					dbc.RollbackTran();
					throw;
				}
			}
		}

        /// <summary>
        /// Forces change to account (adds media if necessary), does not insert bar code formats
        /// </summary>
        public void ForceAccount(string[] serials, Locations location, string accountNo)
        {
            String s1 = String.Join(",", serials);
            // Get the number of media allowed by the license
            int mediaAllowed = (new ProductLicense()).GetProductLicense(LicenseTypes.Media).Units;
            // Open database connection
            using (IConnection dbc = dataBase.Open())
            {
                try
                {
                    dbc.BeginTran();
                    // Loop through serial numbers in batches
                    while (s1 != String.Empty)
                    {
                        String s2 = s1;
                        // Get batch
                        if (s2.Length > 4000)
                        {
                            s2 = s2.Substring(0,4000);
                            s2 = s2.Substring(0, s2.LastIndexOf(','));
                            s1 = s1.Substring(s2.Length + 1);
                        }
                        else
                        {
                            s1 = String.Empty;
                        }
                        // Parameters
                        SqlParameter[] p1 = new SqlParameter[3];
                        p1[0] = BuildParameter("@serials", s2);
                        p1[1] = BuildParameter("@account", accountNo);
                        p1[2] = BuildParameter("@location", (int)location);
                        // Execute
                        ExecuteNonQuery(CommandType.StoredProcedure, "medium$upd$account", p1);
                    }
                    // Get license
                    int u1 = (new ProductLicense()).GetProductLicense(LicenseTypes.Media).Units;
                    // If over limit, roll back
                    if (u1 != ProductLicenseDetails.Unlimited && GetMediumCount() > u1)
                    {
                        throw new ApplicationException("Additional media licenses required");
                    }
                    else
                    {
                        dbc.CommitTran();
                    }
                }
                catch(SqlException e)
                {
                    // Rollback the transaction
                    dbc.RollbackTran();
                    PublishException(e);
                    throw new DatabaseException(StripErrorMsg(e.Message), e);
                }
            }
        }
        
        /// <summary>
		/// A method to insert a new medium and dictate the account and medium type.  Bar code
		/// formats will be adjusted if necessary.
		/// </summary>
		public int ForceAttributes(string serialNo, Locations location, string mediumType, string accountNo)
		{
			// Get the number of media allowed by the license
			int mediaAllowed = (new ProductLicense()).GetProductLicense(LicenseTypes.Media).Units;
			// Check the number of media against the license
			if (mediaAllowed != ProductLicenseDetails.Unlimited && GetMediumCount() + 1 > mediaAllowed)
			{
				throw new ApplicationException("Additional media licenses required");
			}
			else
			{
				using (IConnection dbc = dataBase.Open())
				{
					try
					{
						dbc.BeginTran();
						// Build parameters
						SqlParameter[] mediumParms = new SqlParameter[5];
						mediumParms[0] = BuildParameter("@serialNo", serialNo);
						mediumParms[1] = BuildParameter("@location", (int)location);
						mediumParms[2] = BuildParameter("@mediumType", mediumType);
						mediumParms[3] = BuildParameter("@accountName", accountNo);
						mediumParms[4] = BuildParameter("@mediumId", SqlDbType.Int, ParameterDirection.Output);
						// Insert the new operator
						ExecuteNonQuery(CommandType.StoredProcedure, "medium$addLiteral", mediumParms);
						int mediumId = Convert.ToInt32(mediumParms[4].Value);
						// Commit the transaction
						dbc.CommitTran();
						// Return the medium id
						return mediumId;
					}
					catch(SqlException e)
					{
						// Rollback the transaction
						dbc.RollbackTran();
						PublishException(e);
						throw new DatabaseException(StripErrorMsg(e.Message), e);
					}
				}
			}
		}
            
		/// <summary>
		/// A method to update an existing medium
		/// </summary>
		/// <param name="m">A details entity with information about the medium to be updated</param>
		public void Update(MediumDetails m)
		{
			using (IConnection dbc = dataBase.Open())
			{
				try
				{
					dbc.BeginTran("update medium");
					// Build parameters
					SqlParameter[] mediumParms = new SqlParameter[11];
					mediumParms[0] = BuildParameter("@id", m.Id);
					mediumParms[1] = BuildParameter("@serialNo", m.SerialNo);
					mediumParms[2] = BuildParameter("@location", (int)m.Location);
					mediumParms[3] = BuildParameter("@hotStatus", m.HotSite);
					mediumParms[4] = BuildParameter("@missing", m.Missing);
					mediumParms[5] = BuildParameter("@returnDate", m.ReturnDate.Length != 0 ? DateTime.Parse(m.ReturnDate) : SqlDateTime.Null);
					mediumParms[6] = BuildParameter("@bside", m.Flipside);
					mediumParms[7] = BuildParameter("@notes", m.Notes);
					mediumParms[8] = BuildParameter("@mediumType", m.MediumType);
					mediumParms[9] = BuildParameter("@account", m.Account);
					mediumParms[10] = BuildParameter("@rowVersion", m.RowVersion);
					// Update the operator
					ExecuteNonQuery(CommandType.StoredProcedure, "medium$upd", mediumParms);
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
		/// Deletes a range of media
		/// </summary>
		/// <param name="start">
		/// Starting serial number of the range to delete
		/// </param>
		/// <param name="end">
		/// Ending serial number of the range to delete
		/// </param>
		public void Delete(string start, string end)
		{
			string serialNo = start;

			using (IConnection dbc = dataBase.Open())
			{
				// Begin transaction
				dbc.BeginTran("delete medium");
				// Delete each serial number in the range
				while (serialNo.CompareTo(end) <= 0)
				{
					try
					{
						// Build parameters
						SqlParameter[] mediumParms = new SqlParameter[1];
						mediumParms[0] = BuildParameter("@serialNo", serialNo);
						// Delete the medium
						ExecuteNonQuery(CommandType.StoredProcedure, "medium$delBySerial", mediumParms);
						// Get the next serial number
						serialNo = NextSerialNumber(serialNo);
					}
					catch(SqlException e)
					{
						dbc.RollbackTran();
						PublishException(e);
						throw new DatabaseException(StripErrorMsg(e.Message), e);
					}
				}
				// Commit the transaction
				dbc.CommitTran();
			}
		}

		/// <summary>
		/// Deletes an existing medium
		/// </summary>
		/// <param name="m">Medium to delete</param>
		public void Delete(MediumDetails m)
		{
			using (IConnection dbc = dataBase.Open())
			{
				try
				{
					dbc.BeginTran("delete medium");
					// Build parameters
					SqlParameter[] mediumParms = new SqlParameter[2];
					mediumParms[0] = BuildParameter("@id", m.Id);
					mediumParms[1] = BuildParameter("@rowVersion", m.RowVersion);
					// Delete the operator
					ExecuteNonQuery(CommandType.StoredProcedure, "medium$del", mediumParms);
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
		/// Creates the filter string out of a medium filter object
		/// </summary>
		/// <param name="filter">Filter object</param>
		/// <returns>Filter string</returns>
		private string CreateFilterString(MediumFilter mf)
		{
			StringBuilder s = new StringBuilder();
			if (null == mf) return String.Empty;
			// Get the starting and ending serial numbers
			string serial1 = mf.StartingSerialNo;
			string serial2 = mf.EndingSerialNo;
			// Wildcards are not allowed in the ending serial number box
			if (0 != (mf.Filter & MediumFilter.FilterKeys.SerialEnd))
			{
				if (serial2.IndexOf('*') != -1 || serial2.IndexOf('?') != -1)
				{
					throw new ApplicationException("Wildcards are not allowed in the range ending serial number");
				}
				else if (0 != (mf.Filter & MediumFilter.FilterKeys.SerialStart))
				{
					if (serial1.IndexOf('*') != -1 || serial1.IndexOf('?') != -1)
					{
						throw new ApplicationException("Wildcards are not allowed in the starting serial number when an ending serial number is supplied");
					}
					else if (serial1.CompareTo(serial2) > 0)
					{
						string tempString = serial2;
						serial2 = serial1;
						serial1 = tempString;
					}
				}
			}
			// Start of serial range
			if (0 != (mf.Filter & MediumFilter.FilterKeys.SerialStart))
			{
				string[] x = serial1.Split(new char[] {','});
				// If single element, can be >= or LIKE.  If more than one, can be = or LIKE.
				if (x.Length == 1)
				{
					if (x[0].IndexOf('*') == -1 && x[0].IndexOf('?') == -1)
						s.AppendFormat("SerialNo >= '{0}'", x[0]);
					else
						s.AppendFormat("SerialNo LIKE '{0}'", x[0].Replace('*', '%').Replace('?', '_'));
				}
				else
				{
					// Begin with left parenthesis
					s.Append("(");
					// Add elements separated by OR's
					for (int i = 0; i < x.Length; i++)
					{
						if ((x[i] = x[i].Trim()).Length != 0) 
						{
							// Use 'OR' if not first element
							if (i != 0) s.Append(" OR ");
							// If wildcarded, use LIKE
							if (x[i].IndexOf('*') == -1 && x[i].IndexOf('?') == -1)
								s.AppendFormat("SerialNo = '{0}'", x[i]);
							else
								s.AppendFormat("SerialNo LIKE '{0}'", x[i].Replace('*', '%').Replace('?', '_'));
						}
					}
					// End with right parenthesis
					s.Append(")");
				}
			}
			// End of serial range
			if (0 != (mf.Filter & MediumFilter.FilterKeys.SerialEnd)) 
				s.AppendFormat("{0}SerialNo <= '{1}'", s.Length != 0 ? " AND " : String.Empty, serial2);
			// Location
			if (0 != (mf.Filter & MediumFilter.FilterKeys.Location))
				s.AppendFormat("{0}Location = {1}", s.Length != 0 ? " AND " : String.Empty, (int)mf.Location);
			// Return date
			if (0 != (mf.Filter & MediumFilter.FilterKeys.ReturnDate)) 
				s.AppendFormat("{0}ReturnDate = '{1}'", s.Length != 0 ? " AND " : String.Empty, mf.ReturnDate.ToString("yyyy-MM-dd"));
			// Missing status
			if (0 != (mf.Filter & MediumFilter.FilterKeys.Missing)) 
				s.AppendFormat("{0}Missing = {1}", s.Length != 0 ? " AND " : String.Empty, mf.Missing ? "1" : "0");
			// Account
			if (0 != (mf.Filter & MediumFilter.FilterKeys.Account)) 
				s.AppendFormat("{0}Account = '{1}'", s.Length != 0 ? " AND " : String.Empty, mf.Account);
			// Medium type
			if (0 != (mf.Filter & MediumFilter.FilterKeys.MediumType)) 
				s.AppendFormat("{0}MediumType = '{1}'", s.Length != 0 ? " AND " : String.Empty, mf.MediumType);
			// Case name
			if (0 != (mf.Filter & MediumFilter.FilterKeys.CaseName)) 
				s.AppendFormat("{0}CaseName = '{1}'", s.Length != 0 ? " AND " : String.Empty, mf.CaseName);
			// Disaster code
			if (0 != (mf.Filter & MediumFilter.FilterKeys.DisasterCode)) 
				s.AppendFormat("{0}Disaster = '{1}'", s.Length != 0 ? " AND " : String.Empty, mf.DisasterCode);
            // Destroyed status
            if (0 != (mf.Filter & MediumFilter.FilterKeys.Destroyed)) 
                s.AppendFormat("{0}Destroyed = {1}", s.Length != 0 ? " AND " : String.Empty, mf.Destroyed ? "1" : "0");
            // Notes
			if (0 != (mf.Filter & MediumFilter.FilterKeys.Notes))
			{
				// Replace all '*' with '%' and '?' with '_'
				string x = mf.Notes.Replace('*', '%').Replace('?', '_').Replace("%%", "%");
				bool likeOperator = x.IndexOf('%') != -1 || x.IndexOf('_') != -1;
				// Append to the stringbuilder
				s.AppendFormat("{0}Notes {1} '{2}'", s.Length != 0 ? " AND " : String.Empty, likeOperator ? "LIKE" : "=", x);
			}
			// Return string
			return s.ToString();
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
		private string NextSerialNumber(string serial)
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
		public void DoNotes(String[] s1, String n1, Boolean r1)
		{
			ArrayList p1 = new ArrayList();
			StringBuilder b1 = new StringBuilder();
			// Notes
			p1.Add(new SqlParameter("@a1", n1));
			// Parameters
			for (int i = 0; i < s1.Length; i += 1)
			{
				b1.Append(String.Format("{0}@x{1}", i != 0 ? "," : String.Empty, i));
				p1.Add(new SqlParameter(String.Format("@x{0}", i), s1[i]));
			}
			// Update
			using (IConnection c1 = dataBase.Open())
			{
				try
				{
					String q1 = null;
					c1.BeginTran("update medium");
					// Append or replace?
					if (r1 == true)
					{
						q1 = String.Format("UPDATE Medium SET Notes = SUBSTRING(@a1, 1, 1000) WHERE SerialNo IN ({0})", b1.ToString());
					}
					else
					{
						q1 = String.Format("UPDATE Medium SET Notes = SUBSTRING(Notes + ' ' + @a1, 1, 1000) WHERE SerialNo IN ({0})", b1.ToString());
					}
					// Execute
					ExecuteNonQuery(CommandType.Text, q1, (SqlParameter[])p1.ToArray(typeof(SqlParameter)));
					c1.CommitTran();
				}
				catch(SqlException e)
				{
					c1.RollbackTran();
					PublishException(e);
					throw new DatabaseException(StripErrorMsg(e.Message), e);
				}
			}
		}
        /// <summary>
        /// Updates notes on serial numbers
        /// </summary>
        /// <param name="s1">Serial number</param>
        /// <param name="m1">Message</param>
        public void Journalize(string s1, string m1)
        {
            using (IConnection c1 = dataBase.Open())
            {
                try
                {
                    c1.BeginTran("update medium");
                    // Insert
                    string q1 = String.Format("INSERT INTO XMedium (Object, Action, Detail) VALUES ('{0}', 0, '{1}')", s1, m1);
                    // Execute
                    ExecuteNonQuery(CommandType.Text, String.Format("INSERT INTO XMedium (Object, Action, Detail) VALUES ('{0}', 0, '{1}')", s1, m1));
                    // Commit
                    c1.CommitTran();
                }
                catch (SqlException e)
                {
                    c1.RollbackTran();
                    PublishException(e);
                    throw new DatabaseException(StripErrorMsg(e.Message), e);
                }
            }
        }
        /// <summary>
        /// Updates notes on serial numbers
        /// </summary>
        /// <param name="i1">Comma-delimited list of medium id numbers</param>
        public void Destroy(string i1)
        {
            using (IConnection c1 = dataBase.Open())
            {
                try
                {
                    c1.BeginTran("destroy medium");
                    // Destroy the media
                    ExecuteNonQuery(CommandType.StoredProcedure, "medium$destroy", new SqlParameter[] { BuildParameter("@id", i1) } );
                    // Commit the transaction
                    c1.CommitTran();
                }
                catch(SqlException e)
                {
                    c1.RollbackTran();
                    PublishException(e);
                    throw new DatabaseException(StripErrorMsg(e.Message), e);
                }
            }
        }
    }
}
