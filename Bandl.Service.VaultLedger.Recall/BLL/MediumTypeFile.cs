using System;
using System.IO;
using System.Web;
using System.Text;
using System.Collections;
using System.Configuration;
using Bandl.Service.VaultLedger.Recall.Model;
using Bandl.Service.VaultLedger.Recall.Exceptions;

namespace Bandl.Service.VaultLedger.Recall.BLL
{
	/// <summary>
	/// Summary description for AccountFile.
	/// </summary>
	public class MediumTypeFile
	{
        private static string FileName
        {
            get
            {
                // Get the path of the file
                string appPath = HttpRuntime.AppDomainAppPath;
                string dirSeparator = Path.DirectorySeparatorChar.ToString();
                string fileName = String.Format("{0}{1}MedTypes.config", appPath, appPath.EndsWith(dirSeparator) ? "" : dirSeparator);
                // Verify that file exists
                if (false == File.Exists(fileName))
                {
                    throw new ApplicationException("Medium type file not found.");
                }
                else                    
                {
                    return fileName;
                }
            }
        }

        /// <summary>
        /// Gets the media types from the medium type file
        /// </summary>
        /// <param name="forceRead">
        /// Reads the file even if information is in the cache
        /// </param>
        /// <returns>
        /// Array of medium type objects
        /// </returns>
        public static MediumTypeDetails[] RetrieveMediumTypes(bool forceRead)
        {
            // Attempt to get the array from the cache
            MediumTypeDetails[] returnValue = (MediumTypeDetails[])HttpRuntime.Cache.Get("MediumTypes");
            // If nothing was in the cache, or if we're forced to do so, read the file
            if (returnValue == null || forceRead == true)
            {
                // Read through the file, adding accounts with the given global account
                using(StreamReader sr = new StreamReader(FileName))
                {
                    string fileLine;
                    string[] fields;

                    // Create the collection
                    ArrayList medTypes = new ArrayList();
                    // Read through the file
                    while((fileLine = sr.ReadLine()) != null )
                    {
                        // Split the string into fields.  If there are not 
                        // exactly three fields, then throw an exception
                        fields = fileLine.Split(new char[] {','});
                        if (fields.Length != 3)
                            throw new InvalidFieldCountException("Line with illegal number of fields found in medium type file.  Please contact Recall Corporation immediately.");
                        // Get the medium type
                        switch (fields[2].Trim())
                        {
                            case "1":
                            case "2":
                            case "3":
                                medTypes.Add(new MediumTypeDetails(fields[0].Trim(), fields[1].Trim(), Convert.ToInt32(fields[2].Trim())));
                                break;
                            default:
                                throw new ApplicationException("Illegal side/container value found in medium type file.  Please contact Recall Corporation immediately.");
                        }
                    }
                    // Add to the cache for ten minutes
                    returnValue = (MediumTypeDetails[])medTypes.ToArray(typeof(MediumTypeDetails));
                    HttpRuntime.Cache.Insert("MediumTypes",returnValue,null,DateTime.Now.AddMinutes(10),TimeSpan.Zero);
                }
            }
            // Return the array
            return returnValue;
        }
    }
}
