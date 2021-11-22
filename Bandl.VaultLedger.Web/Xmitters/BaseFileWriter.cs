using System;
using System.IO;
using System.Web;
using System.Text;
using Bandl.Library.VaultLedger.Model;

namespace Bandl.Library.VaultLedger.Xmitters
{
	/// <summary>
	/// Summary description for BaseFormat.
	/// </summary>
	public class BaseFileWriter : IFileWriter
	{
        public BaseFileWriter() {}
        /// <summary>
        /// Gets the name of the file to send
        /// </summary>
        /// <param name="sl">
        /// The list for which to get the next file name
        /// </param>
        public virtual string GetFileName(SendListDetails sl) {return String.Empty;}
        /// <summary>
        /// Gets the name of the file to send
        /// </summary>
        /// <param name="rl">
        /// The list for which to get the next file name
        /// </param>
        public virtual string GetFileName(ReceiveListDetails rl) {return String.Empty;}
        /// <summary>
        /// Gets the name of the file to send
        /// </summary>
        /// <param name="dl">
        /// The list for which to get the next file name
        /// </param>
        public virtual string GetFileName(DisasterCodeListDetails dl) {return String.Empty;}
        /// <summary>
		/// Sets the next file name for a send list
		/// </summary>
		/// <param name="sendList">
		/// Send list written to file that was just transmitted
		/// </param>
		/// <param name="fileName">
		/// Name of the file that was just transmitted
		/// </param>
		public virtual void SetNextFileName(SendListDetails sendList, string fileName) {}
		/// <summary>
		/// Sets the next file name for a receive list
		/// </summary>
		/// <param name="receiveList">
		/// Receive list written to file that was just transmitted
		/// </param>
		/// <param name="fileName">
		/// Name of the file that was just transmitted
		/// </param>
		public virtual void SetNextFileName(ReceiveListDetails receiveList, string fileName) {}
		/// <summary>
		/// Sets the next file name for a disaster code list
		/// </summary>
		/// <param name="disasterList">
		/// Disaster code list written to file that was just transmitted
		/// </param>
		/// <param name="fileName">
		/// Name of the file that was just transmitted
		/// </param>
		public virtual void SetNextFileName(DisasterCodeListDetails disasterList, string fileName) {}        
    }
}
