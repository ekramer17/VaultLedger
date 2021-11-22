using System;
using System.Text;
using System.Collections;
using Bandl.Library.VaultLedger.IDAL;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.DALFactory;
using Bandl.Library.VaultLedger.Collections;

namespace Bandl.Library.VaultLedger.Xmitters
{
    /// <summary>
    /// Summary description for RecallFormat.
    /// </summary>
    public class RecallFormatter : IFormatter
    {
        #region Type Collections
        private MediumTypeCollection caseTypes = null;
        private MediumTypeCollection mediumTypes = null;

        private MediumTypeCollection CaseTypes
        {
            get
            {
                if (caseTypes == null)
                {
                    caseTypes = ((IMediumType)MediumTypeFactory.Create()).GetMediumTypes(true);
                }
                // Return the media codes
                return caseTypes;
            }
        }

        private MediumTypeCollection MediumTypes
        {
            get
            {
                if (mediumTypes == null)
                {
                    mediumTypes = ((IMediumType)MediumTypeFactory.Create()).GetMediumTypes(false);
                }
                // Return the media codes
                return mediumTypes;
            }
        }

        #endregion

        public RecallFormatter() {}

        /// <summary>
        /// Formats a return date in MM/dd/yyyy format
        /// </summary>
        /// <param name="returnDate">
        /// String represent date to transform
        /// </param>
        /// <returns>
        /// Date in MM/dd/yyyy format.  If null or empty string, returns 01/01/2999.
        /// </returns>
        private string GetReturnDate(string returnDate)
        {
            if (returnDate != null && returnDate.Length != 0)
            {
                return DateTime.Parse(returnDate).ToString("MM/dd/yyyy");
            }
            else
            {
                return "01/01/2999";
            }
        }
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
            int itemCount = 0;
            string itemCode = null;
            string itemReturn = null;
            string mediaCode = String.Empty;
            string returnDate = String.Empty;
            ArrayList sealedCases = new ArrayList();
            IMedium mediumDAL = (IMedium)MediumFactory.Create();
            // Create a new stringbuilder object and initialize with account number
            StringBuilder fileContents = new StringBuilder(String.Format("%C{0}", sendList.Account.PadRight(5,' ')));
            // Loop through the sealed cases, creating a line for each
            foreach (SendListCaseDetails sendCase in sendList.ListCases)
            {
                if (sendCase.Sealed == true)
                {
                    itemCount += 1;
                    // Add the sealed case name to the array list so that we may check
                    // for it later when we're adding individual media.  If a medium is
                    // in a sealed case, then that medium should not be written to the file.
                    sealedCases.Add(sendCase.Name);
                    // Set the medium code
                    if (mediaCode != (itemCode = CaseTypes.Find(sendCase.Type,true).RecallCode))
                    {
                        fileContents.AppendFormat("%M{0}", itemCode);
                        mediaCode = itemCode;
                    }
                    // Serial number (will always be different)
                    fileContents.AppendFormat("%V{0}", sendCase.Name);
                    // Return date
                    if (returnDate != (itemReturn = this.GetReturnDate(sendCase.ReturnDate)))
                    {
                        fileContents.AppendFormat("%E{0}", itemReturn);
                        returnDate = itemReturn;
                    }
                    // Append the newline.  If this is the first line in the file, place the create date as well.
                    if (itemCount != 1)  
                    {
                        fileContents.Append(Environment.NewLine);
                    }
                    else
                    {
                        fileContents.AppendFormat("%X{0}{1}", sendList.CreateDate.ToString("MM/dd/yyyy"), Environment.NewLine);
                    }
                }
            }
            // Loop through the media
            foreach(SendListItemDetails sendItem in sendList.ListItems)
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
                    itemCount += 1;
                }
                // Media code
                if (mediaCode != (itemCode = MediumTypes.Find(mediumDAL.GetMedium(sendItem.SerialNo).MediumType,false).RecallCode)) 
                {
                    fileContents.AppendFormat("%M{0}", itemCode);
                    mediaCode = itemCode;
                }
                // Serial number (will always be different)
                fileContents.AppendFormat("%V{0}", sendItem.SerialNo);
                // Return date
                if (returnDate != (itemReturn = this.GetReturnDate(sendItem.ReturnDate)))
                {
                    fileContents.AppendFormat("%E{0}", itemReturn);
                    returnDate = itemReturn;
                }
                // Append the newline.  If this is the first line in the file, place the create date as well.
                if (itemCount != 1)  
                {
                    fileContents.Append(Environment.NewLine);
                }
                else
                {
                    fileContents.AppendFormat("%X{0}{1}", sendList.CreateDate.ToString("MM/dd/yyyy"), Environment.NewLine);
                }
            }
            // Write the quantity (number of tapes in the file)
            fileContents.AppendFormat(String.Format("%#{0}{1}", itemCount, Environment.NewLine));
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
            int itemCount = 0;
            string itemCode = null;
            string mediaCode = String.Empty;
            ArrayList doneCases = new ArrayList();
            IMedium mediumDAL = (IMedium)MediumFactory.Create();
            ISealedCase caseDAL = (ISealedCase)SealedCaseFactory.Create();
            // Create a new stringbuilder object and initialize with account number
            StringBuilder fileContents = new StringBuilder(String.Format("%C{0}", receiveList.Account.PadRight(5,' ')));
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
                        itemCount += 1;
                        doneCases.Add(receiveItem.CaseName);
                        SealedCaseDetails sealedCase = caseDAL.GetSealedCase(receiveItem.CaseName);
                        // Set the medium code
                        if (mediaCode != (itemCode = CaseTypes.Find(sealedCase.CaseType,true).RecallCode))
                        {
                            fileContents.AppendFormat("%M{0}", itemCode);
                            mediaCode = itemCode;
                        }
                        // Serial number (will always be different)
                        fileContents.AppendFormat("%V{0}", sealedCase.CaseName);
                        // Append the newline.  If this is the first line in the file, place the create date as well.
                        if (itemCount != 1)  
                        {
                            fileContents.Append(Environment.NewLine);
                        }
                        else
                        {
                            fileContents.AppendFormat("%X{0}{1}", receiveList.CreateDate.ToString("MM/dd/yyyy"), Environment.NewLine);
                        }
                    }
                }
                else
                {
                    itemCount += 1;
                    MediumDetails medium = mediumDAL.GetMedium(receiveItem.SerialNo);
                    // Media code
                    if (mediaCode != (itemCode = MediumTypes.Find(medium.MediumType,false).RecallCode)) 
                    {
                        fileContents.AppendFormat("%M{0}", itemCode);
                        mediaCode = itemCode;
                    }
                    // Serial number (will always be different)
                    fileContents.AppendFormat("%V{0}", receiveItem.SerialNo);
                    // Append the newline.  If this is the first line in the file, place the create date as well.
                    if (itemCount != 1)  
                    {
                        fileContents.Append(Environment.NewLine);
                    }
                    else
                    {
                        fileContents.AppendFormat("%X{0}{1}", receiveList.CreateDate.ToString("MM/dd/yyyy"), Environment.NewLine);
                    }
                }
            }
            // Write the quantity (number of tapes in the file)
            fileContents.AppendFormat(String.Format("%#{0}{1}", itemCount, Environment.NewLine));
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
        public string Format(DisasterCodeListDetails dl)
        {
            int i = -1;
            int numItems = 0;
            string y = null;
            string dlCode = String.Empty;
            string typeCode = String.Empty;
            ArrayList doneCases = new ArrayList();
            IMedium mdal = (IMedium)MediumFactory.Create();
            ISealedCase cdal = (ISealedCase)SealedCaseFactory.Create();
            // Create a new stringbuilder object and initialize with account number
            StringBuilder fileContents = new StringBuilder(String.Format("%C{0}", dl.Account.PadRight(5,' ')));
            // Loop through the list items
            foreach(DisasterCodeListItemDetails di in dl.ListItems)
            {
                //  Removed?
                if (di.Status == DLIStatus.Removed)
                {
                    continue;
                }
                // If the case name is non-blank, check to see if it has been added.  If it hasn't, get
                // its type and write a line to the file
                else if (di.CaseName.Length != 0)
                {
                    // Run through the sealed cases already written
                    for (i = 0; i < doneCases.Count; i++)
                        if (((string)doneCases[i]) == di.CaseName)
                            break;
                    // If case not accounted for, write line to file
                    if (i == doneCases.Count)
                    {
                        numItems += 1;
                        doneCases.Add(di.CaseName);
                        SealedCaseDetails c = cdal.GetSealedCase(di.CaseName);
                        // Get the medium code and store it
                        if (typeCode != (y = CaseTypes.Find(c.CaseType,true).RecallCode))
                            fileContents.AppendFormat("%M{0}", (typeCode = y));
                        // Serial number (will always be different)
                        fileContents.AppendFormat("%V{0}", di.CaseName);
                        // Set the disaster code
                        if (dlCode != di.Code)
                            fileContents.AppendFormat("%P{0}", (dlCode = di.Code));
                        // Append the newline.  If this is the first line in the file, place the create date as well.
                        fileContents.AppendFormat("%X{0}{1}", numItems == 1 ? dl.CreateDate.ToString("MM/dd/yyyy") : String.Empty, Environment.NewLine);
                    }
                }
                else
                {
                    numItems += 1;
                    MediumDetails m = mdal.GetMedium(di.SerialNo);
                    // Media code
                    if (typeCode != (y = MediumTypes.Find(m.MediumType,false).RecallCode)) 
                        fileContents.AppendFormat("%M{0}", (typeCode = y));
                    // Serial number (will always be different)
                    fileContents.AppendFormat("%V{0}", di.SerialNo);
                    // Set the disaster code
                    if (dlCode != di.Code)
                        fileContents.AppendFormat("%P{0}", (dlCode = di.Code));
                    // Append the newline.  If this is the first line in the file, place the create date as well.
                    // Append the newline.  If this is the first line in the file, place the create date as well.
                    fileContents.AppendFormat("%X{0}{1}", numItems == 1 ? dl.CreateDate.ToString("MM/dd/yyyy") : String.Empty, Environment.NewLine);
                }
            }
            // Write the quantity (number of tapes in the file)
            fileContents.AppendFormat(String.Format("%#{0}{1}", numItems, Environment.NewLine));
            // Return the string that is to be the contents of the transmitted file
            return fileContents.ToString();
        }
    }
}
