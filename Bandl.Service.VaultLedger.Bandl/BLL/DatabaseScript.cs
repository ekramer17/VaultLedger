using System;
using System.IO;
using System.Web;
using System.Configuration;

namespace Bandl.Service.VaultLedger.Bandl.BLL
{
	/// <summary>
	/// Summary description for DatabaseScript.
	/// </summary>
	public class DatabaseScript
	{
        /// <summary>
        /// Given a database version number, returns true if there is a database
        /// script with a higher version number
        /// </summary>
        /// <param name="dbVersion">
        /// Database version number
        /// </param>
        /// <returns>
        /// True if a newer script exists, else false
        /// </returns>
        public static bool NewScriptExists(string dbVersion)
        {
            return (String.Empty != GetNextScript(dbVersion));
        }
        
        /// <summary>
        /// Given a database version number, returns the name of the
        /// next script
        /// </summary>
        /// <param name="dbVersion">
        /// Database version number
        /// </param>
        /// <returns>
        /// Name of the next database script
        /// </returns>
        public static string GetNextScript(string dbVersion)
        {
            // For the script path
            string directory = ConfigurationSettings.AppSettings["dbScripts"];
            string scriptPath = String.Format("{0}{1}{2}", HttpContext.Current.Request.PhysicalApplicationPath,
                                                           directory != null ? directory : String.Empty, 
                                                           Path.DirectorySeparatorChar.ToString());
            // Break up the client version
            string[] clientFields = dbVersion.Split(new char[] {'.'});
            int major = Convert.ToInt32(clientFields[0]);
            int minor = Convert.ToInt32(clientFields[1]);
            int revision = Convert.ToInt32(clientFields[2]);
            // Look for the next revision
            string nextScript = String.Format("{0}{1}_{2}_{3}.sqe", scriptPath, major, minor, revision + 1 );
            if (File.Exists(nextScript)) return nextScript;
            // If next revision not present, look for next minor with a zero revision
            nextScript = String.Format("{0}{1}_{2}_0.sqe", scriptPath, major, minor + 1 );
            if (File.Exists(nextScript)) return nextScript;
            // If next minor not present, look for next major with zero minor and zero revision
            nextScript = String.Format("{0}{1}_0_0.sqe", scriptPath, major + 1);
            if (File.Exists(nextScript)) return nextScript;
            // No next script
            return String.Empty;
        }

        /// <summary>
        /// Reads a database script into an array of bytes and returns the 
        /// array to the caller.
        /// </summary>
        /// <param name="scriptPath">
        /// Full path of the database script to read
        /// </param>
        /// <returns>
        /// Array of bytes
        /// </returns>
        public static byte[] ReadScript(string scriptPath)
        {
            byte[] scriptBytes = null;
            FileInfo fi = new FileInfo(scriptPath);
            using(FileStream fs = new FileStream(scriptPath, FileMode.Open, FileAccess.Read))
            {
                using(BinaryReader br = new BinaryReader(fs))
                {
                    br.Read(scriptBytes, 0, Convert.ToInt32(fi.Length));
                    return scriptBytes;
                }
            }
        }
	}
}
