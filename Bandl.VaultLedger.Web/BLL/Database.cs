using System;
using System.Data;
using System.Text;
using System.Collections;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.DALFactory;
using Bandl.Library.VaultLedger.IDAL;
using Bandl.Library.VaultLedger.Exceptions;
using Bandl.Library.VaultLedger.Gateway.Bandl;
using Bandl.Library.VaultLedger.Security;

namespace Bandl.Library.VaultLedger.BLL
{
    /// <summary>
    /// A business component used to manage database
    /// </summary>
    public class Database
    {
        /// <summary>
        /// Returns the database version information
        /// </summary>
        /// <returns>Database version</returns>
        public static string GetConnectionString() 
        {
            using (IConnection c = ConnectionFactory.Create().Open())
            {
                return c.Connection.ConnectionString;
            }
        }

        /// <summary>
        /// Returns the database version information
        /// </summary>
        /// <returns>Database version</returns>
        public static DatabaseVersionDetails GetVersion() 
        {
            return DatabaseFactory.Create().GetVersion();
        }

        /// <summary>
        /// Updates the database.  User id and password supplied should have
        /// at least dbowner access.
        /// </summary>
        /// <param name="uid">
        /// User id with which to log in to the databae
        /// </param>
        /// <param name="pwd">
        /// Password with which to log in to the database
        /// </param>
        public static void Update(string uid, string pwd)
        {
            // Must have administrator privileges
            CustomPermission.Demand(Role.Administrator);
            // Verify input
            if(uid == null)
            {
                throw new ArgumentNullException("Database user login id may not be null.");
            }
            else if (uid == String.Empty)
            {
                throw new ArgumentException("Database user login id may not be an empty string.");
            }
            else if(pwd == null)
            {
                throw new ArgumentNullException("Database password may not be null.");
            }
            // Create the service gateway
            BandlGateway bandlService = new BandlGateway();
            // Object to hold the current version details
            DatabaseVersionDetails currentVersion = DatabaseFactory.Create().GetVersion();
            // Execute the commands against the database
            while (bandlService.NewScriptExists(currentVersion.String))
            {
                int index = 0;
                int lastIndex = 0;
                // Get the encrypted script from the web service
                byte[] scriptBytes = bandlService.DownloadNextScript(ref currentVersion);
                // Since we already checked for a new script, if the download
                // function returns null, then something went wrong somewhere.
                if (scriptBytes == null)
                {
                    throw new BLLException("New database script exists, but download returned nothing.");
                }
                // Decrypt new script
                string newScript = Crypto.Decrypt(scriptBytes);
                // Open a connection with which to initialize the database version object
                using (IConnection c = ConnectionFactory.Create().Open())
                {
                    // Begin transaction
                    c.BeginTran();
                    // Create the database version object
                    IDatabase dal = DatabaseFactory.Create(c);
                    // Execute the commands in the script
                    try
                    {
                        while ((index = newScript.IndexOf("\nGO", lastIndex)) != -1)
                        {
                            // Get the command text
                            string commandText = newScript.Substring(lastIndex, index - lastIndex).Trim();
                            lastIndex = index + 3;
                            // Execute the command
                            dal.ExecuteCommand(uid, pwd, commandText);
                        }
                        // Update the database version
                        dal.UpdateVersion(currentVersion);
                        // Commit transaction
                        c.CommitTran();
                    }
                    catch
                    {
                        c.RollbackTran();
                        throw;
                    }
                }
            }
        }
    
        /// <summary>
        /// Verifies that a connection to the database can be achieved
        /// </summary>
        /// <param name="uid">
        /// User id with which to log in to the databae
        /// </param>
        /// <param name="pwd">
        /// Password with which to log in to the database
        /// </param>
        /// <returns>
        /// Error message on failure, empty string on success
        /// </returns>
        public static string ConfirmConnection(string uid, string pwd)
        {
            try
            {
                using (IConnection c = ConnectionFactory.Create().Open(uid, pwd))
                {
                    return String.Empty;
                }
            }
            catch (Exception ex)
            {
                return ex.Message;
            }
        }

        /// <summary>
        /// Updates the database.  User id and password supplied should have
        /// at least dbowner access.
        /// </summary>
        /// <param name="uid">
        /// User id with which to log in to the databae
        /// </param>
        /// <param name="pwd">
        /// Password with which to log in to the database
        /// </param>
        public static void Update(string uid, string pwd, string cmdText)
        {
            using (IConnection c = ConnectionFactory.Create().Open(uid, pwd))
            {
                int x = 0;
                int y = 0;
                string z = String.Empty;
                // Begin transaction
                c.BeginTran();
                // Create the database version object
                IDatabase dal = DatabaseFactory.Create(c);
                // Execute the commands in the script
                try
                {
                    if (cmdText.IndexOf("\nGO") == -1)
                    {
                        dal.ExecuteCommand(uid, pwd, cmdText);
                    }
                    else
                    {
                        while ((x = cmdText.IndexOf("\nGO", y)) != -1)
                        {
                            // Get the command text
                            string s = cmdText.Substring(y, x - y).Trim();
                            z = s;
                            // Set the last index
                            y = x + 3;
                            // Execute the command
                            dal.ExecuteCommand(uid, pwd, s);
                        }
                    }
                    // Commit transaction
                    c.CommitTran();
                }
                catch
                {
                    c.RollbackTran();
                    throw;
                }
            }
        }

        /// <summary>
        /// Updates the database.  User id and password supplied should have
        /// at least dbowner access.
        /// </summary>
        /// <param name="uid">
        /// User id with which to log in to the databae
        /// </param>
        /// <param name="pwd">
        /// Password with which to log in to the database
        /// </param>
        public static string Query(string uid, string pwd, string queryText)
        {
            using (IConnection c = ConnectionFactory.Create().Open(uid, pwd))
            {
                using (IDataReader r = DatabaseFactory.Create(c).ExecuteQuery(uid, pwd, queryText))
                {
                    // If no data then throw exception
                    if(r == null) 
                    {
                        return "No rows were returned by the query";
                    }
                    else
                    {
                        StringBuilder returnValue = new StringBuilder();

                        while (true)
                        {
                            ArrayList maxLens = new ArrayList();
                            ArrayList dataRows = new ArrayList();
                            ArrayList dataTypes = new ArrayList();
                            ArrayList columnSizes = new ArrayList();
                            DataTable dataSchema = r.GetSchemaTable();
                            // Get the column names
                            for (int i = 0; i < dataSchema.Rows.Count; i++)
                            {
                                columnSizes.Add(Convert.ToInt32(dataSchema.Rows[i]["ColumnSize"]));
                                dataTypes.Add(dataSchema.Rows[i]["DataType"].ToString());
                                maxLens.Add(dataSchema.Rows[i]["ColumnName"].ToString().Length);
                            }
                            // Get the data from the reader
                            do
                            {
                                string stringValue = String.Empty;
                                StringBuilder rowString = new StringBuilder();
                                // Get the values
                                for (int i = 0; i < dataSchema.Rows.Count; i++)
                                {
                                    if (((string)dataTypes[i]).IndexOf("Byte[]") != -1)
                                    {
                                        byte[] b = new byte[(int)columnSizes[i]];
                                        r.GetBytes(i, 0, b, 0, (int)columnSizes[i]);
                                        StringBuilder hexBuilder = new StringBuilder("0x");
                                        for (int j = 0; j < b.Length; j++)
                                            hexBuilder.Append(String.Format("{0:x2}", b[j]));
                                        stringValue = hexBuilder.ToString();
                                    }
                                    else
                                    {
                                        stringValue = r.GetValue(i).ToString();
                                    }

                                    rowString.AppendFormat("{0}\t", stringValue);
                                    if (stringValue.Length > (int)maxLens[i])
                                        maxLens[i] = stringValue.Length;
                                }
                                // Add to the array list (strip the last tab)
                                dataRows.Add(rowString.Remove(rowString.Length-1,1).ToString());
                            } while (r.Read() == true);
                            // Create the column headers
                            StringBuilder dashesRow = new StringBuilder();
                            for (int i = 0; i < dataSchema.Rows.Count; i++)
                            {
                                if (i != dataSchema.Rows.Count - 1)
                                {
                                    returnValue.AppendFormat("{0}  ", dataSchema.Rows[i]["ColumnName"].ToString().PadRight((int)maxLens[i], ' '));
                                    dashesRow.AppendFormat("{0}  ", String.Empty.PadRight((int)maxLens[i], '-'));
                                }
                                else
                                {
                                    returnValue.AppendFormat("{0}{1}", dataSchema.Rows[i]["ColumnName"].ToString().PadRight((int)maxLens[i], ' '), Environment.NewLine);
                                    dashesRow.AppendFormat("{0}{1}", String.Empty.PadRight((int)maxLens[i], '-'), Environment.NewLine);
                                }
                            }
                            // Add the dashes rows to the returnString
                            returnValue.Append(dashesRow.ToString());
                            // Add the data row to the string
                            for (int i = 0; i < dataRows.Count; i++)
                            {
                                string[] dataFields = ((string)dataRows[i]).Split(new char[] {'\t'});
                                for (int j = 0; j < dataFields.Length; j++)
                                {
                                    if (j != dataFields.Length - 1)
                                        returnValue.AppendFormat("{0}  ", dataFields[j].PadRight((int)maxLens[j], ' '));
                                    else
                                        returnValue.AppendFormat("{0}{1}", dataFields[j].PadRight((int)maxLens[j], ' '), Environment.NewLine);
                                }
                            }
                            // If there is not next result then leave the loop.  Otherwise insert
                            // a couple of blank lines for separation.
                            if (r.NextResult() == false)
                            {
                                break;
                            }
                            else
                            {
                                r.Read();
                                returnValue.AppendFormat("{0}{0}", Environment.NewLine);
                            }
                        }
                        // Return the string
                        return returnValue.ToString();
                    }
                }
            }
         }
    }
}
