using System;
using System.IO;
using System.Collections;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.IParser;
using Bandl.Library.VaultLedger.Collections;

namespace Bandl.Library.VaultLedger.Parsers
{
    /// <summary>
    /// Parses a batch scanner file to create a new send list
    /// </summary>
    public class BatchCompareParser : Parser, IParserObject
    {
        public BatchCompareParser() {}

        /// <summary>
        /// Parses the given text array and returns an array of serial numbers
        /// and an array of cases.  Both arrays will be of the same length,
        /// and an index in the case array will correspond to the medium
        /// at same same index in the serial array.  If the medium is not
        /// in a case, then the corresponding value in the case array will be
        /// the empty string.  Use this overload when creating a new send
        /// or receive list compare file from the batch scanner.
        /// </summary>
        /// <param name="fileText">
        /// Byte array containing text to parse
        /// </param>
        /// <param name="serials">
        /// Receptacle for returned serial numbers
        /// </param>
        /// <param name="cases">
        /// Receptacle for returned cases
        /// </param>
        public override void Parse(byte[] fileText, out string[] serials, out string[] cases)
        {
            // Create array lists to hold the strings
            ArrayList serialList = new ArrayList();
            ArrayList caseList = new ArrayList();
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

					if (fields.Length != 2 && fields.Length != 6)
					{
						throw new ApplicationException("Parse error in list compare batch scanner file");
					}
					else if (fields.Length == 2)
					{
						serialList.Add(fields[0].Trim());
						caseList.Add(fields[1].Trim());
					}
					else if (fields.Length == 6 && fields[5] == "1")
					{
						serialList.Add(fields[1].Trim());
						caseList.Add(fields[2].Trim());
					}
                } 
                while ((fileLine = sr.ReadLine()) != null);
            }
            // Convert to string arrays
            serials = (string[])serialList.ToArray(typeof(string));
            cases = (string[])caseList.ToArray(typeof(string));
        }
    }
}
