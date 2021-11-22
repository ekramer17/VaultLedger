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
    public class BatchDisasterListParser : Parser, IParserObject
    {
        public BatchDisasterListParser() {}

        /// <summary>
        /// Parses the given text array and returns a collection of 
        /// DisasterCodeListItemDetails objects.  Use this overload when
        /// creating a new disaster code list from a stream.
        /// </summary>
        /// <param name="fileText">
        /// Byte array containing text to parse
        /// </param>
        /// <param name="listItems">
        /// Receptacle for returned disaster code list items
        /// </param>
        public override void Parse(byte[] fileText, out DisasterCodeListItemCollection listItems)
        {
            // Create a new disaster code list collection
            listItems = new DisasterCodeListItemCollection();
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
                // Variables for codes and notes
                string disasterCode = String.Empty;
                string itemNotes = String.Empty;
                // Read each line, creating new disaster code list items
                do
                {
                    string serialNo = String.Empty;
                    string[] fields = fileLine.Split(new char[] {'%'});
                    
                    if (fields.Length > 4)
                        throw new ApplicationException("Parse error in disaster code list file");
                    else
                    {
                        foreach(string field in fields)
                        {
                            if (field != String.Empty)
                            {
                                switch (field[0])
                                {
                                    case 'V':
                                        serialNo = field.Substring(1).Trim();
                                        break;
                                    case 'D':
                                        disasterCode = field.Substring(1).Trim();
                                        if (Configurator.ProductType == "RECALL" && disasterCode.Length > 3)
                                            disasterCode = disasterCode.Substring(0,3);
                                        break;
                                    case 'N':
                                        itemNotes = field.Substring(1).Trim();
                                        break;
                                    default:
                                        throw new ApplicationException("Parse error in disaster code list file");
                                }
                            }
                        }
                        // Add item to the collection
                        if (serialNo == String.Empty)
                            throw new ApplicationException("Parse error in disaster code list file");
                        else
                            listItems.Add(new DisasterCodeListItemDetails(serialNo, disasterCode, itemNotes));
                    }
                } 
                while((fileLine = sr.ReadLine()) != null);
            }
        }
    }
}
