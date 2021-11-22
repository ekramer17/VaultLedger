using System;
using System.Data;
using System.Data.SqlClient;
using System.Text.RegularExpressions;
using Bandl.Library.VaultLedger.Common.Knock;

namespace Bandl.Utility.VaultLedger.Registrar.SQLServer
{
	/// <summary>
	/// Summary description for ConnectionString.
	/// </summary>
	public class ConnectionString
	{
        /// <summary>
        /// Translates the connection string.  Determines if string is
        /// plain text or encrypted.  If encrypted, decrypts.
        /// </summary>
        /// <param name="connectString">
        /// Connection string, plain text or encrypted
        /// </param>
        /// <param name="connectVector">
        /// Vector used to encrypt the connection string</param>
        /// <returns>
        /// Connection string in plain text
        /// </returns>
        public static string Translate(string connectString, string connectVector)
        {
            // If there is no string, throw an exception.  If there is no vector,
            // return the connection string as is
            if (connectString == null || connectString == String.Empty)
                throw new ApplicationException("Connection string not found");
            else if (connectVector == null || connectVector == String.Empty)
                return connectString;
            // If the connection string contains a character not found in a
            // base64 string, return it as is
            if (new Regex(@"^[a-zA-Z0-9+/=\s]*$").IsMatch(connectString) == false)
                return connectString;
            // If we find the string "Database =" or "Database=" or 
            // "Initial Catalog =" or "Initial Catalog=" in the string, 
            // we can assume that the string is not encrypted
            if (new Regex(@"Database\s*=",RegexOptions.IgnoreCase).IsMatch(connectString) == true)
                return connectString;
            else if (new Regex(@"Initial Catalog\s*=",RegexOptions.IgnoreCase).IsMatch(connectString) == true)
                return connectString;
            // The string is encrypted and in base64 format.  Convert the 
            // strings back from base64.  A vector may have been supplied,
            // or the default vector may be used.  Decrypt and return the
            // connection string.
            if (connectVector == String.Empty)
                return Balance.Exhume(Convert.FromBase64String(connectString));
            else
            {
                byte[] vectorBytes = Convert.FromBase64String(connectVector);
                return Balance.Exhume(Convert.FromBase64String(connectString), vectorBytes);
            }
        }
    }
}
