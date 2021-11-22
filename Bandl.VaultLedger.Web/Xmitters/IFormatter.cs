using System;
using Bandl.Library.VaultLedger.Model;

namespace Bandl.Library.VaultLedger.Xmitters
{
	/// <summary>
	/// Summary description for IFormat.
	/// </summary>
	public interface IFormatter
	{
		/// <summary>
		/// Formats a send list and return the contents of what will be the written file
		/// </summary>
		/// <param name="sendList">
		/// Send list to format into file contents
		/// </param>
		/// <returns>
		/// String representing the contents of the to-be-transmitted file
		/// </returns>
		string Format(SendListDetails sendList);
		/// <summary>
		/// Formats a receive list and return the contents of what will be the written file
		/// </summary>
		/// <param name="receiveList">
		/// Receive list to format into file contents
		/// </param>
		/// <returns>
		/// String representing the contents of the to-be-transmitted file
		/// </returns>
		string Format(ReceiveListDetails receiveList);
		/// <summary>
		/// Formats a disaster code list and return the contents of what will be the written file
		/// </summary>
		/// <param name="disasterList">
		/// Disaster code list to format into file contents
		/// </param>
		/// <returns>
		/// String representing the contents of the to-be-transmitted file
		/// </returns>
		string Format(DisasterCodeListDetails disasterList);
	}
}
