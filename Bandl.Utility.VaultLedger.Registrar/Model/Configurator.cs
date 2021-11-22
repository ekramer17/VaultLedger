using System;
using System.IO;
using System.Web;
using System.Configuration;
using Bandl.Library.VaultLedger.Common.Knock;

namespace Bandl.Utility.VaultLedger.Registrar.Model
{
    /// <summary>
    /// Summary description for Configuration.
    /// </summary>
    public class Configurator
    {
        private static string baseDir = String.Empty;

        public static string AccountFile
        {
            get
            {
                string fileName = String.Empty;
                string filePath = String.Empty;
                string dirSeparator = Path.DirectorySeparatorChar.ToString();
                string configPath = ConfigurationSettings.AppSettings["AccountFile"];
                // Get the path of the file
                if (configPath != null && configPath.Length != 0)
                {
                    filePath = ConfigurationSettings.AppSettings["AccountFile"];
                }
                else
                {
                    filePath = HttpRuntime.AppDomainAppPath;
                }
                // If the file path ends in .config, then they've use the file name
                if (filePath.ToLower().EndsWith(".config"))
                {
                    fileName = filePath;
                }
                else if (filePath.EndsWith(dirSeparator))
                {
                    fileName = filePath + "Accounts.config";
                }
                else
                {
                    fileName += filePath + dirSeparator + "Accounts.config";
                }
                // Verify that file exists
                if (false == File.Exists(fileName))
                {
                    throw new ApplicationException("Account file not found.");
                }
                else                    
                {
                    return fileName;
                }
            }
        }

        public static string BaseDirectory
        {
            get
            {
                return baseDir;
            }
            set
            {
                baseDir = value;
            }
        }

        public static string ClientDbServer
        {
            get
            {
                string x = ConfigurationSettings.AppSettings["ClientDbServer"];
                return x != null ? x : String.Empty;
            }
        }

        public static bool AllowDownload
        {
            get
            {
                string x = ConfigurationSettings.AppSettings["AllowDownload"];
                return x != null ? x.ToLower() == "true" : true;
            }
        }

        public static string ApplicationUrl
        {
            get
            {
                string x = ConfigurationSettings.AppSettings["ApplicationUrl"];
                return x != null ? x : String.Empty;
            }
        }

        public static string DbNamePrefix
        {
            get
            {
                string x = ConfigurationSettings.AppSettings["DbNamePrefix"];
                return x != null ? x : String.Empty;
            }
        }

        public static string DbDataFileLocation
        {
            get
            {
                string x = ConfigurationSettings.AppSettings["DbDataFileLocation"];
				// Present?
                if (x == null || x.Length == 0) 
                {
					if ((x = ConfigurationSettings.AppSettings["DbFileLocation"]) == null || x.Length == 0)
					{
						return String.Empty;
					}
                }
				// Add separator
                if (x.EndsWith(Path.DirectorySeparatorChar.ToString()))
                {
                    return x;
                }
                else
                {
                    return x + Path.DirectorySeparatorChar.ToString();
                }
            }
        }

		public static string DbLogFileLocation
		{
			get
			{
				string x = ConfigurationSettings.AppSettings["DbLogFileLocation"];
				// Present?
				if (x == null || x.Length == 0) 
				{
					if ((x = DbDataFileLocation) == String.Empty)
					{
						if ((x = ConfigurationSettings.AppSettings["DbFileLocation"]) == null || x.Length == 0)
						{
							return String.Empty;
						}
					}
				}
				// Add separator
				if (x.EndsWith(Path.DirectorySeparatorChar.ToString()))
				{
					return x;
				}
				else
				{
					return x + Path.DirectorySeparatorChar.ToString();
				}
			}
		}
		
		public static string DbDataFileGrowth
        {
            get
            {
                string x = ConfigurationSettings.AppSettings["DbDataFileGrowth"];
				// Present?
				if (x == null && (x = ConfigurationSettings.AppSettings["DbFileGrowth"]) == null)
				{
					return String.Empty;
				}
				else
				{
					return x;
				}
            }
        }

		public static string DbLogFileGrowth
		{
			get
			{
				string x = ConfigurationSettings.AppSettings["DbLogFileGrowth"];
				// Present?
				if (x == null && (x = ConfigurationSettings.AppSettings["DbFileGrowth"]) == null)
				{
					return String.Empty;
				}
				else
				{
					return x;
				}
			}
		}

		public static string EmailFromAddress
        {
            get
            {
                string x = ConfigurationSettings.AppSettings["EmailFromAddress"];
                return x != null ? x : String.Empty;
            }
        }

        public static string EmailNotifyAddress
        {
            get
            {
                string x = ConfigurationSettings.AppSettings["EmailNotifyAddress"];
                return x != null ? x : String.Empty;
            }
        }
        public static string EmailServer
        {
            get
            {
                string x = ConfigurationSettings.AppSettings["EmailServer"];
                return x != null ? x : String.Empty;
            }
        }

        public static string ProductName
        {
            get
            {
                if (Configurator.DbNamePrefix == "RQMM_")
                {
                    return "ReQuest Media Manager";
                }
                else
                {
                    switch (ProductType)
                    {
                        case "BANDL":
                            return "VaultLedger";
                        default:
                            return "ReQuest Media Manager";
                    }
                }
            }
        }

        public static string ProductType
        {
            get
            {
                string productType = ConfigurationSettings.AppSettings["ProductType"];
                if (productType == null) 
                {
                    return "RECALL";
                }
                else
                {
                    switch (productType.ToUpper())
                    {
                        case "B&L":
                        case "BANDL":
                            return "BANDL";
                        case "RECALL":
                        default:
                            return "RECALL";
                    }
                }
            }
        }

        public static string RouterDbConnectString
        {
            get
            {
                string x = ConfigurationSettings.AppSettings["ConnString"];
                string y = ConfigurationSettings.AppSettings["ConnVector"];
                if (x == null || y == null || y.Length == 0) 
                {
                    return x != null ? x : String.Empty;
                }
                else
                {
                    byte[] vectorBytes = Convert.FromBase64String(y);
                    byte[] stringBytes = Convert.FromBase64String(x);
                    return Balance.Exhume(stringBytes, vectorBytes);
                }
            }
        }

        public static string SAPassword
        {
            get
            {
                string x = ConfigurationSettings.AppSettings["SAPassword"];
                string y = ConfigurationSettings.AppSettings["SAPwdVector"];
                if (x == null || y == null || y.Length == 0) 
                {
                    return x != null ? x : String.Empty;
                }
                else
                {
                    byte[] vectorBytes = Convert.FromBase64String(y);
                    byte[] stringBytes = Convert.FromBase64String(x);
                    return Balance.Exhume(stringBytes, vectorBytes);
                }
            }
        }
    }
}
