using System;
using System.Configuration;

namespace Bandl.Library.VaultLedger.Model
{
	/// <summary>
	/// Summary description for Configurator.
	/// </summary>
	public class Configurator
	{
        public static int CommandTimeout
        {
            get
            {
                try
                {
                    return Int32.Parse(ConfigurationManager.AppSettings["DbCmdTimeout"]);
                }
                catch
                {
                    return 60;
                }
            }
        }

        public static string ConnectionString
        {
            get
            {
                string returnValue = ConfigurationManager.AppSettings["ConnString"];
                return returnValue != null ? returnValue : String.Empty;
            }
        }

        public static string ConnectionVector
        {
            get
            {
                string returnValue = ConfigurationManager.AppSettings["ConnVector"];
                return returnValue != null ? returnValue : String.Empty;
            }
        }

        public static string DatabaseType
        {
            get
            {
                string returnValue = ConfigurationManager.AppSettings["DBMS"];
                return returnValue != null ? returnValue : "SQLServer";
            }
        }

        public static String EmailFontFamily
        {
            get
            {
                string returnValue = ConfigurationManager.AppSettings["EmailFontFamily"];
                return String.IsNullOrEmpty(returnValue) ? "Verdana;Tahoma;Arial" : returnValue;
            }
        }

        public static String EmailFontSize
        {
            get
            {
                string returnValue = ConfigurationManager.AppSettings["EmailFontSize"];
                return String.IsNullOrEmpty(returnValue) ? "10pt" : returnValue;
            }
        }

        public static String EmailLogin
        {
            get
            {
                string returnValue = ConfigurationManager.AppSettings["EmailLogin"];
                return String.IsNullOrEmpty(returnValue) ? String.Empty : returnValue;
            }
        }

        public static String EmailPassword
        {
            get
            {
                string returnValue = ConfigurationManager.AppSettings["EmailPassword"];
                return String.IsNullOrEmpty(returnValue) ? String.Empty : returnValue;
            }
        }

        public static String EmailSender
        {
            get
            {
                string returnValue = ConfigurationManager.AppSettings["EmailSender"];
                return String.IsNullOrEmpty(returnValue) ? "alerts@vaultledger.com" : returnValue;
            }
        }

        public static String EmailServer
        {
            get
            {
                String returnValue = ConfigurationManager.AppSettings["EmailServer"];
                return String.IsNullOrEmpty(returnValue) ? "127.0.0.1" : returnValue;
            }
        }

        public static string GlobalAccount
        {
            get
            {
                string returnValue = ConfigurationManager.AppSettings["GlobalAccount"];
                return returnValue != null ? returnValue : String.Empty;
            }
        }

        public static bool Trace
        {
            get
            {
                string returnValue = ConfigurationManager.AppSettings["TraceEnabled"];
                if (returnValue == null) returnValue = ConfigurationManager.AppSettings["DoTrace"];
                returnValue = returnValue != null ? returnValue.ToUpper() : "FALSE";
                return returnValue == "TRUE" || returnValue == "YES";
            }
        }

        public static string ProductType
        {
            get
            {
                string returnValue = ConfigurationManager.AppSettings["ProductType"];
                return returnValue != null ? returnValue.ToUpper() : "BANDL";
            }
        }

        public static string ProductName
        {
            get
            {
                // Are we forcing the name to ReQuest?
                string r = ConfigurationManager.AppSettings["RecallName"];
                if (r != null && r.ToUpper() == "TRUE")
                {
                    return "ReQuest Media Manager";
                }
                else
                {
                    string returnValue = ConfigurationManager.AppSettings["ProductName"];
                    // If a product name was explicitly defined, use it.  Otherwise,
                    // the name depends on the product type.
                    if (returnValue != null)
                    {
                        return returnValue;
                    }
                    else
                    {
                        switch (ProductType)
                        {
                            case "RECALL":
                                return "ReQuest Media Manager";
                            default:
                                return "VaultLedger";
                        }
                    }
                }
            }
        }

        public static string Proxy
        {
            get
            {
                string x = ConfigurationManager.AppSettings["WebProxy"];
                if (x == null || x.ToLower().IndexOf("address:") != -1 || x.ToLower().IndexOf(":port") != -1)
                {
                    return String.Empty;
                }
                else
                {
                    return x;
                }
            }
        }

        public static string RecallErrorUrl
        {
            get
            {
                string x = ConfigurationManager.AppSettings["RecallErrorUrl"];
                return x != null ? x : String.Empty;
            }
        }

        public static string RecallLogoutUrl
        {
            get
            {
                string x = ConfigurationManager.AppSettings["RecallLogoutUrl"];
                return x != null ? x : String.Empty;
            }
        }

        public static bool Router
        {
            get
            {
                string x = ConfigurationManager.AppSettings["Router"];
                return x != null && x.ToUpper() == "TRUE" ? true : false;
            }
        }

        public static int SessionTimeout
        {
            get
            {
                try
                {
                    return Convert.ToInt32(ConfigurationManager.AppSettings["Idle"]);
                }
                catch
                {
                    return 20;
                }
            }
        }

        public static bool SupportLogin
        {
            get
            {
                string returnValue = ConfigurationManager.AppSettings["SupportAccess"];
                if (returnValue == null) returnValue = "false";
                
                switch (returnValue.ToUpper())
                {
                    case "YES":
                    case "TRUE":
                        return true;
                    default:
                        return false;
                }
            }
        }

        public static string XmitMethod
        {
            get
            {
                string returnValue = ConfigurationManager.AppSettings["XmitMethod"];
                returnValue = returnValue != null ? returnValue.ToUpper() : "NONE";

				switch (returnValue)
                {
                    case "FTP":
                    case "RECALLSERVICE":
                        return returnValue;
                    default:
                        return ProductType != "RECALL" ? "NONE" : "RECALLSERVICE";
                }
            }
        }
    }
}
