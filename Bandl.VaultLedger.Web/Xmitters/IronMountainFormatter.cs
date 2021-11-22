using System;
using System.Text;
using System.Collections;
using Bandl.Library.VaultLedger.Model;

namespace Bandl.Library.VaultLedger.Xmitters
{
	/// <summary>
	/// Summary description for IronMountainFormatter.
	/// </summary>
	public class IronMountainFormatter : IFormatter
	{
		public IronMountainFormatter() {}

		/// <summary>
		/// Formats a send list and return the contents of what will be the written file
		/// </summary>
		/// <param name="sendList">
		/// Send list to format into file contents
		/// </param>
		/// <returns>
		/// String representing the contents of the to-be-transmitted file
		/// </returns>
		public string Format(SendListDetails sl)
		{
			ArrayList seals = new ArrayList();
            // Create the header and footer
            string header = String.Format("StartHeaderText~D~{0}~~EndHeaderText{1}", sl.Account, Environment.NewLine);
            string footer = String.Format("StartFooterText~D~{0}~~EndFooterText{1}", sl.Account, Environment.NewLine);
            // Create the stringbuilder
			StringBuilder s = new StringBuilder(header);
			// Loop through the sealed cases, creating a line for each
			foreach (SendListCaseDetails c in sl.ListCases)
			{
				if (c.Sealed == true)
				{
                    string serial = c.Name.PadRight(15,' ').Substring(0,15);
                    string date = c.ReturnDate.Length != 0 ? Convert.ToDateTime(c.ReturnDate).ToString("MMddyyyy") : String.Empty.PadRight(8,' ');
                    string desc = c.Notes.Length != 0 ? c.Notes.PadRight(60,' ').Substring(0,60) : String.Empty.PadRight(60,' ');
                    s.AppendFormat("{0} {1} {2} {3} {4}{5}", serial, String.Empty.PadRight(11,' '), desc, date, String.Empty.PadRight(3,' '), Environment.NewLine);
					// Add the sealed case name to the array list so that we may check
					// for it later when we're adding individual media.  If a medium is
					// in a sealed case, then that medium should not be written to the file.
					seals.Add(c.Name);
				}
			}
			// Now tackle the standalone media
			foreach (SendListItemDetails si in sl.ListItems)
			{
                if (si.Status == SLIStatus.Removed) // medium removed
                {
                    continue;
                }
                else if (si.CaseName.Length != 0 && seals.IndexOf(si.CaseName) != -1)   // medium in sealed case
                {
                    continue;
                }
                else
                {
                    string serial = si.SerialNo.PadRight(15,' ').Substring(0,15);
                    string date = si.ReturnDate.Length != 0 ? Convert.ToDateTime(si.ReturnDate).ToString("MMddyyyy") : String.Empty.PadRight(8,' ');
                    string desc = si.Notes.Length != 0 ? si.Notes.PadRight(60,' ').Substring(0,60) : String.Empty.PadRight(60,' ');
                    s.AppendFormat("{0} {1} {2} {3} {4}{5}", serial, String.Empty.PadRight(11,' '), desc, date, String.Empty.PadRight(3,' '), Environment.NewLine);
				}
			}
            // Append the footer
            s.AppendFormat("{0}{1}", footer, Environment.NewLine);
			// Return the string that is to be the contents of the transmitted file
			return s.ToString();
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
		public string Format(ReceiveListDetails rl)
		{
			ArrayList done = new ArrayList();
            // Create the header and footer
            string header = String.Format("StartHeaderText~P~{0}~~EndHeaderText{1}", rl.Account, Environment.NewLine);
            string footer = String.Format("StartFooterText~P~{0}~~EndFooterText{1}", rl.Account, Environment.NewLine);
            // Create the stringbuilder
            StringBuilder s = new StringBuilder(header);
			// Loop through the list items
			foreach(ReceiveListItemDetails ri in rl.ListItems)
			{
				bool b = false;
                //  Removed?
                if (ri.Status == RLIStatus.Removed)
                {
                    continue;
                }
				// If there's a case, check to see if it's already been accounted
				// for.  If it has, skip the entry; otherwise add the case to the
				// file contents.  If there is no case, just add the medium
				else if (ri.CaseName.Length != 0)
				{
                    // Check case collection
                    for (int i = 0; i < done.Count && b == false; i += 1)
						if (ri.CaseName == (string)done[i]) b = true;
					// If case not already processed, add it
                    if (b == false)
                    {
                        s.AppendFormat("{0} {1}{2}", ri.CaseName, String.Empty.PadRight(85,' '), Environment.NewLine);
                        done.Add(ri.CaseName);
                    }
				}
				else
				{
                    s.AppendFormat("{0} {1}{2}", ri.SerialNo, String.Empty.PadRight(85,' '), Environment.NewLine);
				}
			}
            // Append the footer
            s.AppendFormat("{0}{1}", footer, Environment.NewLine);
            // Return the string that is to be the contents of the transmitted file
			return s.ToString();
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
		public string Format(DisasterCodeListDetails dl)
		{
            // Create the header and footer
            string header = String.Format("StartHeaderText~R~{0}~~EndHeaderText{1}", dl.Account, Environment.NewLine);
            string footer = String.Format("StartFooterText~R~{0}~~EndFooterText{1}", dl.Account, Environment.NewLine);
            // Create the stringbuilder
            StringBuilder s = new StringBuilder(header);
            // Loop through the list items
            foreach(DisasterCodeListItemDetails di in dl.ListItems)
            {
                if (di.Status != DLIStatus.Removed)
                {
                    s.AppendFormat("{0} {1} {2}{3}", di.SerialNo, String.Empty.PadRight(81,' '), di.Code.PadRight(3,' ').Substring(0,3), Environment.NewLine);
                }
            }
            // Append the footer
            s.AppendFormat("{0}{1}", footer, Environment.NewLine);
            // Return the string that is to be the contents of the transmitted file
            return s.ToString();
        }
	}
}
