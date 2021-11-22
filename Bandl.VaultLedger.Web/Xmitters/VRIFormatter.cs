using System;
using System.Text;
using System.Collections;
using Bandl.Library.VaultLedger.Model;

namespace Bandl.Library.VaultLedger.Xmitters
{
	/// <summary>
	/// Summary description for VRIFormatter.
	/// </summary>
	public class VRIFormatter : IFormatter
	{
		public VRIFormatter() {}

		/// <summary>
		/// Formats a send list and return the contents of what will be the written file
		/// </summary>
		/// <param name="sendList">
		/// Send list to format into file contents
		/// </param>
		/// <returns>
		/// String representing the contents of the to-be-transmitted file
		/// </returns>
		public string Format(SendListDetails sendList)
		{
			ArrayList sealedCases = new ArrayList();
			// First line is the account number
			StringBuilder fileContents = new StringBuilder(String.Format("{0}{1}", sendList.Account, Environment.NewLine));
			// Loop through the sealed cases, creating a line for each
			foreach (SendListCaseDetails sendCase in sendList.ListCases)
			{
				if (sendCase.Sealed == true)
				{
					// Add the sealed case name to the array list so that we may check
					// for it later when we're adding individual media.  If a medium is
					// in a sealed case, then that medium should not be written to the file.
					sealedCases.Add(sendCase.Name);
					// Serial number (will always be different)
					fileContents.AppendFormat("{0},", sendCase.Name);
					// Data set name (none)
					fileContents.Append(",");
					// Site name (none)
					fileContents.Append(",");
					// Location (none)
					fileContents.Append(",");
					// Effective date (none)
					fileContents.Append(",");
					// Return date
					if (sendCase.ReturnDate.Length != 0)
					{
						fileContents.Append(DateTime.Parse(sendCase.ReturnDate).ToString("MM/dd/yyyy"));
					}
					// Append the newline
					fileContents.Append(Environment.NewLine);
				}
			}
			// Now tackle the standalone media
			foreach (SendListItemDetails sendItem in sendList.ListItems)
			{
                if (sendItem.Status == SLIStatus.Removed) // medium removed
                {
                    continue;
                }
                else if (sendItem.CaseName.Length != 0 && sealedCases.IndexOf(sendItem.CaseName) != -1)   // medium in sealed case
                {
                    continue;
                }
                else
                {
					// Serial number (will always be different)
					fileContents.AppendFormat("{0},", sendItem.SerialNo);
					// Data set name (none)
					fileContents.Append(",");
					// Site name (none)
					fileContents.Append(",");
					// Location (none)
					fileContents.Append(",");
					// Effective date (none)
					fileContents.Append(",");
					// Return date
					if (sendItem.ReturnDate.Length != 0)
					{
						fileContents.Append(DateTime.Parse(sendItem.ReturnDate).ToString("MM/dd/yyyy"));
					}
					// Append the newline
					fileContents.Append(Environment.NewLine);
				}
			}
			// Return the string that is to be the contents of the transmitted file
			return fileContents.ToString();
		}
		/// <summary>
		/// Formats a receive list and return the contents of what will be the written file
		/// </summary>
		/// <param name="receiveList">
		/// Receive list to format into file contents
		/// </param>
		/// <returns>
		/// String representing the contents of the to-be-transmitted file
		/// </returns>
		public string Format(ReceiveListDetails receiveList)
		{
			ArrayList doneCases = new ArrayList();
			// First line is the account number
			StringBuilder fileContents = new StringBuilder(String.Format("{0}{1}", receiveList.Account, Environment.NewLine));
			// Loop through the list items
			foreach(ReceiveListItemDetails receiveItem in receiveList.ListItems)
			{
				bool caseDone = false;
                //  Removed?
                if (receiveItem.Status == RLIStatus.Removed)
                {
                    continue;
                }
                // If there's a case, check to see if it's already been accounted
				// for.  If it has, skip the entry; otherwise add the case to the
				// file contents.  If there is no case, just add the medium
				if (receiveItem.CaseName.Length != 0)
				{
					foreach (string caseName in doneCases)
					{
						if (receiveItem.CaseName == caseName)
						{
							caseDone = true;
							break;
						}
					}
					// If case not already processed, add it
					if (caseDone == false)
					{
                        doneCases.Add(receiveItem.CaseName);
						// Serial number (will always be different)
						fileContents.AppendFormat("{0},", receiveItem.CaseName);
						// Data set name (none)
						fileContents.Append(",");
						// Site name (none)
						fileContents.Append(",");
						// Location (none)
						fileContents.Append(",");
						// Effective date (none)
						fileContents.Append(",");
						// Append the newline
						fileContents.Append(Environment.NewLine);
					}
				}
				else
				{
					// Serial number (will always be different)
					fileContents.AppendFormat("{0},", receiveItem.SerialNo);
					// Data set name (none)
					fileContents.Append(",");
					// Site name (none)
					fileContents.Append(",");
					// Location (none)
					fileContents.Append(",");
					// Effective date (none)
					fileContents.Append(",");
					// Append the newline
					fileContents.Append(Environment.NewLine);
				}
			}
			// Return the string that is to be the contents of the transmitted file
			return fileContents.ToString();
		}
		/// <summary>
		/// Formats a disaster code list and return the contents of what will be the written file
		/// </summary>
		/// <param name="disasterList">
		/// Disaster code list to format into file contents
		/// </param>
		/// <returns>
		/// String representing the contents of the to-be-transmitted file
		/// </returns>
		public string Format(DisasterCodeListDetails disasterList)
		{
			throw new ApplicationException("Vital Records does not accept transmission of disaster recovery lists at this time.");
		}
	}
}
