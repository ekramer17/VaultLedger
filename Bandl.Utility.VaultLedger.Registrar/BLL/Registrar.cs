using System;
using System.IO;
using System.Web;
using System.Text;
using System.Web.Caching;
using System.Web.SessionState;
using System.Text.RegularExpressions;
using Bandl.Utility.VaultLedger.Registrar.Model;
using Bandl.Utility.VaultLedger.Registrar.SQLServer;
using Bandl.Utility.VaultLedger.Registrar.Gateway.Bandl;

namespace Bandl.Utility.VaultLedger.Registrar.BLL
{
	public class Registrar : IProcessObject
	{
        private OwnerDetails newOwner = null;
        private Logger oLogger = null;

        private string OperatorLogin
        {
            get
            {
                switch (Configurator.ProductType)
                {
                    case "BANDL":
                        return "BLOperator";
                    case "RECALL":
                    default:
                        return "RMMOperator";
                }
            }
        }

//        private string UpdaterLogin
//        {
//            get
//            {
//                switch (Configurator.ProductType)
//                {
//                    case "BANDL":
//                        return "BLUpdater";
//                    case "RECALL":
//                    default:
//                        return "RMMUpdater";
//                }
//            }
//        }

        private string OperatorPassword
        {
            get
            {
                return "A1!s0n?K";
//				return "all1s0n";
			}
        }

//        private string UpdaterPassword
//        {
//            get
//            {
//                return "d4n13!";
////				return "d4n13l";
//			}
//        }
        
        // Constructor
        public Registrar(OwnerDetails o) 
        {
            newOwner = o;
            oLogger = new Logger();
        }

        /// <summary>
        /// Creates the database name for the new database
        /// </summary>
        /// <returns>
        /// New database name
        /// </returns>
        private string CreateDbName(RouterDb routerDb, OwnerDetails o)
        {
            if (Configurator.ProductType == "RECALL")
            {
                return String.Format("RQMM_{0}", o.AccountNo);
            }
            else
            {
                // Run through the company name and eliminate any non-alphanumerics
                Regex alphaNumeric = new Regex("^[a-zA-Z0-9]$");
                StringBuilder dbName = new StringBuilder();
                for (int i = 0; i < o.Company.Length; i++)
                    if (alphaNumeric.IsMatch(o.Company[i].ToString()))
                        dbName.Append(o.Company[i]);
                // Verify that there is at least one character in dbName
                if (dbName.Length == 0)
                {
                    throw new ArgumentException("Unable to formulate database name");
                }
                // Company name must start with a letter.  If it doesn't, start it with "A$"
                Regex firstLetter = new Regex("^[A-Za-z]$");
                if (firstLetter.IsMatch(dbName[0].ToString()) == false)
                    dbName.Insert(0, "A$");
                // Make sure that dbName is no more than 32 characters long
                if (dbName.Length > 32) dbName.Remove(32, dbName.Length - 32);
                // Append an underscore
                dbName.Append("_");
                // Attempt to append the account number.  If we can't, append five random digits.
                if (o.AccountNo.Length != 0 && routerDb.GetCatalog(String.Format("{0}{1}", dbName.ToString(), o.AccountNo)) == null)
                {
                    dbName.Append(o.AccountNo);
                }
                else
                {
                    while (true)
                    {
                        string newSuffix = new Random().Next(0,99999).ToString("00000");
                        if (routerDb.GetCatalog(String.Format("{0}{1}", dbName.ToString(), newSuffix)) == null)
                        {
                            dbName.Append(newSuffix);
                            break;
                        }
                    }
                }
                // Return the database name
                return Configurator.DbNamePrefix + dbName.ToString();
            }
        }

        /// <summary>
        /// Creates the new application database login
        /// </summary>
        /// <returns>
        /// New login
        /// </returns>
        private string CreateLogin(RouterDb routerDb)
        {
            StringBuilder newLogin;

            while (true)
            {
                newLogin = new StringBuilder("USER");
                newLogin.Append(new Random().Next(0,99999).ToString("00000"));
                if (routerDb.GetLogin(newLogin.ToString()) == null)
                {
                    return newLogin.ToString();
                }
            }
        }

        /// <summary>
        /// Main function, which creates and registers a new database
        /// </summary>
        private bool Register(HttpSessionState q)
        {
            ServerDetails oServer = null;
            OwnerDetails oOwner = null;
            string dbName = String.Empty;    
            string sid = String.Empty;
            bool accountCreated = false;
            bool databaseCreated = false;
            bool serverCreated = false;
            // Create database objects
            RouterDb routerDb = new RouterDb();
            MasterDb masterDb = new MasterDb();

            try
            {
                oLogger.WriteLine(null);
                // Generate the application login and password
                string appLogin = this.CreateLogin(routerDb);
                string appPasswd = Guid.NewGuid().ToString("N").Substring(0,6);
                oLogger.WriteLine(String.Format("Login,Password = {0},{1}", appLogin, appPasswd));
                // Grant licenses to the new account
                try
                {
                    sid = BandlGateway.CreateAccount(newOwner);
                    oLogger.WriteLine(String.Format("Subscription obtained = {0}", sid));
                    newOwner.Subscription = sid;
                    accountCreated = true;
                }
                catch (Exception e)
                {
                    oLogger.WriteLine("Exception caught during subscription fetch attempt: " + e.Message);
                    if (e.Message.IndexOf("already exists") != -1)
                    {
                        throw new ApplicationException("Account " + newOwner.AccountNo + " has already been registered.");
                    }
                    else
                    {
                        throw;
                    }
                }
                // Get what is to be the name of the new application database
                dbName = this.CreateDbName(routerDb, newOwner);
                // Create the application database
                masterDb.CreateDatabase(dbName);
                databaseCreated = true;
                oLogger.WriteLine(String.Format("Database created ({0})", dbName));
                // Get the server from the router database.  If it doesn't exist,
                // then create the new server.  Otherwise, confirm that both logins
                // exist on the application server.
                if ((oServer = routerDb.GetServer(Configurator.ClientDbServer)) == null)
                {
                    ServerLogin slo = new ServerLogin(OperatorLogin, false, OperatorPassword);
//                    ServerLogin slu = new ServerLogin(UpdaterLogin, false, UpdaterPassword);
//                    oServer = new ServerDetails(Configurator.ClientDbServer, slo, slu);
					oServer = new ServerDetails(Configurator.ClientDbServer, slo);
				}
                else
                {
                    if (!masterDb.LoginExists(oServer.Operator))
                    {
                        throw new ApplicationException(String.Format("Unable to connect to server '{0}' with login '{1}'.", oServer.Name, oServer.Operator.Login));
                    }
//                    else if (!masterDb.LoginExists(oServer.Updater))
//                    {
//                        throw new ApplicationException(String.Format("Unable to connect to server '{0}' with login '{1}'.", oServer.Name, oServer.Updater.Login));
//                    }
                }
                // If we server object is new, insert it into the router database and add
                // the logins to the master database.
                if (oServer.ObjState == ObjectStates.New)
                {
                    // Create the server record
                    routerDb.CreateServer(oServer);
                    oServer = routerDb.GetServer(Configurator.ClientDbServer);
                    // Set the server created flag
                    serverCreated = true;
                    // Create the logins
//                    masterDb.CreateLogin(oServer.Updater);
                    masterDb.CreateLogin(oServer.Operator);
                }
                // Insert the owner and make sure it has the subscription number
                int id = routerDb.InsertOwner(newOwner);
                oOwner = routerDb.GetOwner(id);
                oOwner.Subscription = sid;
                oLogger.WriteLine(String.Format("Owner inserted ({0})",id));
                // Insert the catalog
                routerDb.InsertCatalog(dbName, oServer, oOwner);
                CatalogDetails objCatalog = routerDb.GetCatalog(dbName);
                // Insert application login
                routerDb.InsertLogin(objCatalog, appLogin);
                LoginDetails objLogin = routerDb.GetLogin(appLogin);
                // Create an application database object
                VaultLedgerDb applicationDb = new VaultLedgerDb(dbName);
                // Initialize the database - populate with tables, procedures, and initial data
                applicationDb.InitializeDatabase(oOwner, appLogin, appPasswd);
                oLogger.WriteLine("Database initialized");
                // Add the server logins to the application database and grant permissions
                applicationDb.GrantPermissions(oServer.Operator.Login); //, oServer.Updater.Login);
                // Send email to owner
                Email.SendClientEmail(oOwner, appLogin, appPasswd);
                // Place the login and password in the context session
                q[CacheKeys.Uid] = appLogin;
                q[CacheKeys.Pwd] = appPasswd;
                // Send a notification to the email address in web.config
                try
                {
                    Email.SendNotification(oOwner, oServer.Name, dbName, appLogin, appPasswd);
                }
                catch
                {
                    ;
                }
                // Return
                oLogger.WriteLine("Process completed successfully");
                return true;
            }
            catch (Exception e)
            {
                oLogger.WriteLine(e.Message);
                oLogger.WriteLine(e.StackTrace);
                // All calls here will be surrounded by individual try/catch blocks
                // that ignore exceptions.  We want to perform every step yet ignore
                // any errors that may occur during the cleanup process.  In other
                // words, clean up what we can clean up.
                if (databaseCreated == true)
                {
                    try
                    {
                        masterDb.DropDatabase(dbName);
                        oLogger.WriteLine("Database dropped");
                    }
                    catch
                    {
                        ;
                    }
                }
                // Delete the owner (cascade delete will take care of catalog
                // and application login)
                if (oOwner != null)
                {
                    try
                    {
                        routerDb.DeleteOwner(oOwner.Id);
                        oLogger.WriteLine("Owner deleted");
                    }
                    catch
                    {
                        ;
                    }
                }
                // If the we created the server, delete it now along with 
                // the logins created by association. (If we created the 
                // server record, then we also created the logins.)
                if (serverCreated == true)
                {
                    try
                    {
                        routerDb.DeleteServer(oServer.Id);
                        oLogger.WriteLine("Server deleted");
                    }
                    catch
                    {
                        ;
                    }
//                    try
//                    {
//                        masterDb.DeleteLogin(oServer.Updater);
//                        oLogger.WriteLine("Updater login deleted");
//                    }
//                    catch
//                    {
//                        ;
//                    }
                    try
                    {
                        masterDb.DeleteLogin(oServer.Operator);
                        oLogger.WriteLine("Operator login deleted");
                    }
                    catch
                    {
                        ;
                    }
                }
                // Revoke licenses
                if (accountCreated == true)
                {
                    try
                    {
                        BandlGateway.DeleteAccount(newOwner);
                        oLogger.WriteLine("Account deleted by web service");
                    }
                    catch
                    {
                        ;
                    }
                }
                // Rethrow the exception
                throw;
            }            
        }

        #region IProcessObject Members

        public void Execute(HttpSessionState q)
        {
            this.Register(q);
        }
        #endregion
    }
}
