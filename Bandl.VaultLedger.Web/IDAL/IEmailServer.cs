using System;

namespace Bandl.Library.VaultLedger.IDAL
{
    /// <summary>
    /// Inteface for the Email Server DAL
    /// </summary>
    public interface IEmailServer
    {
        /// <summary>
        /// Gets the email groups in the database
        /// </summary>
        /// <returns>
        /// Email groups
        /// </returns>
        void GetServer(ref string serverName, ref string fromAddress);

        /// <summary>
        /// Updates the email server
        /// </summary>
        /// <param name="serverName">
        /// Name of the email server
        /// </param>
        /// <param name="fromAddress">
        /// Address from which to send email
        /// </param>
        void Update(string serverName, string fromAddress);
    }
}
