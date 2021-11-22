using System;
using System.Web.Security;
using System.Security.Cryptography;

namespace Bandl.Library.VaultLedger.Security
{
	/// <summary>
	/// Summary description for Password class
	/// </summary>
	public sealed class PwordHasher
	{
        /// <summary>
        /// Generates a random salt value and returns it as a Base64 encoded string
        /// </summary>
        /// <param name="size">Size of the string</param>
        /// <returns>Salt value as a Base64 encoded string</returns>
        public static string CreateSalt(int size)
        {
            // Generate a cryptographic random number using the cryptographic
            // service provider
            RNGCryptoServiceProvider rng = new RNGCryptoServiceProvider();
            byte[] buff = new byte[size];
            rng.GetBytes(buff);
            // Return a base64 string representation of the random number
            return Convert.ToBase64String(buff);
        }

        /// <summary>
        /// Combines a password with a salt value and creates a hash to store in
        /// the database
        /// </summary>
        /// <param name="pwd">Password string</param>
        /// <param name="salt">Salt value as a Base64 string</param>
        /// <returns></returns>
        public static string HashPasswordAndSalt(string pwd, string salt)
        {
            string saltAndPwd = String.Concat(pwd, salt);
            return FormsAuthentication.HashPasswordForStoringInConfigFile(saltAndPwd, "SHA1");
        }
    }
}
