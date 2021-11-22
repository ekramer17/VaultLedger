using System;
using System.IO;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.IParser;
using Bandl.Library.VaultLedger.Collections;

namespace Bandl.Library.VaultLedger.Parsers
{
    /// <summary>
    /// Parses a batch scanner file to create a new send list
    /// </summary>
    public class BatchSendListParser : Parser, IParserObject
	{
        public BatchSendListParser() {}

        /// <summary>
        /// Parses the given text array and returns send list items.  Use this
        /// overload if the stream is a new send list from the batch scanner.
        /// </summary>
        /// <param name="fileText">
        /// Byte array containing text to parse
        /// </param>
        /// <param name="sendCollection">
        /// Receptacle for returned send list item collection
        /// </param>
        /// <param name="caseCollection">
        /// Receptacle for returned send list case collection
        /// </param>
        public override void Parse(byte[] fileText, out SendListItemCollection sendCollection, out SendListCaseCollection caseCollection)
        {
            // Create the new collections
            sendCollection = new SendListItemCollection();
            caseCollection = new SendListCaseCollection();
            // Create a new memory stream
            MemoryStream ms = new MemoryStream(fileText);
            // Read through the stream, collecting items
            string fileLine = String.Empty;
            using (StreamReader sr = new StreamReader(ms))
            {
                // Read through the headers
                while((fileLine = sr.ReadLine()) != null) 
                {
                    if (fileLine[0] != '$') break;
                }
                // Read each line, creating items and cases
                do
                {
                    string[] fields = fileLine.Split(new char[] {','});
                    if (fields.Length != 4)
                        throw new ApplicationException("Parse error in send list batch scanner file");
                    else
                    {
                        fields[0] = fields[0].Trim();
                        fields[1] = fields[1].Trim();
                        fields[2] = fields[2].Trim();
                        fields[3] = fields[3].Trim().ToUpper();
                        // Insert separators in the return date field
                        if (fields[2] != String.Empty)
                            fields[2] = String.Format("{0}/{1}/{2}", fields[2].Substring(0,4), fields[2].Substring(4,2), fields[2].Substring(6,2));
                        // Add a new send list item details object to the send collection
                        sendCollection.Add(new SendListItemDetails(fields[0], fields[2], String.Empty, fields[1]));
                        if (fields[1] != String.Empty && caseCollection.Find(fields[1]) == null)
                            caseCollection.Add(new SendListCaseDetails(fields[1], fields[3] != "N", fields[2], String.Empty));
                    }
                } 
                while((fileLine = sr.ReadLine()) != null);
            }
        }
	}
}
