using System;
using System.IO;
using System.Text;
using Bandl.Library.VaultLedger.Model;

namespace Bandl.Library.VaultLedger.Xmitters
{
	/// <summary>
	/// Summary description for RecallFormatter.
	/// </summary>
	public class VRIFileWriter : BaseFileWriter, IFileWriter
	{
        public VRIFileWriter() : base() {}

        /// <summary>
        /// Gets the name of the file to send
        /// </summary>
        /// <param name="sl">
        /// The list for which to get the next file name
        /// </param>
        public override string GetFileName(SendListDetails sl)
        {
            return String.Format("DIST_{0}.txt", sl.Name);
        }
        /// <summary>
        /// Gets the name of the file to send
        /// </summary>
        /// <param name="rl">
        /// The list for which to get the next file name
        /// </param>
        public override string GetFileName(ReceiveListDetails rl)
        {
            return String.Format("PICK_{0}.txt", rl.Name);
        }
    }
}
