using System;
using System.IO;
using System.Reflection;

namespace Bandl.Utility.VaultLedger.Registrar.BLL
{
	/// <summary>
	/// Summary description for Logger.
	/// </summary>
	public class Logger
	{
        #region Private Fields
        string directory = String.Empty;
        #endregion

        #region Constructors
        public Logger() 
        {
            string x = Path.GetDirectoryName(Assembly.GetExecutingAssembly().CodeBase);
            directory = x.Replace(@"file:\", String.Empty).Replace(@"\bin", String.Empty);
        }
        public Logger(string _directory)
        {
            directory = _directory;
        }
        #endregion

        #region Public Methods
        public void WriteLine(string m)
        {
            try
            {
                string p = Path.Combine(directory, "registrar.log");
                // Write the log messages
                using (StreamWriter w = new StreamWriter(p, true))
                {
                    if (m != null)
                    {
                        w.WriteLine("{0}: {1}", DateTime.Now.ToString("yyyy-MM-dd hh:mm:ss"), m);
                    }
                    else if (File.Exists(p))
                    {
                        w.WriteLine(String.Empty);
                    }
                }
            }
            catch
            {
                ;
            }
        }
        #endregion
    }
}
