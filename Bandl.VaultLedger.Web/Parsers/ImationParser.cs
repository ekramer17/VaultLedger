using System;
using System.IO;
using System.Xml;
using System.Text;
using System.Collections;
using System.Security.Cryptography;
using Bandl.Library.VaultLedger.IDAL;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.IParser;
using Bandl.Library.VaultLedger.DALFactory;
using Bandl.Library.VaultLedger.Collections;

namespace Bandl.Library.VaultLedger.Parsers
{
	/// <summary>
	/// Summary description for ImationParser.
	/// </summary>
	public class ImationParser : Parser, IParserObject
	{
        int maxSerialLen = 0;

        public ImationParser() 
        {
            maxSerialLen = Int32.Parse(PreferenceFactory.Create().GetPreference(PreferenceKeys.MaxRfidSerialLength).Value);
        }

        private string DecryptFile(string x)
        {
            // Convert from Base64 string
            byte[] b = Convert.FromBase64String(x);
            // Create the Rijndael object
            RijndaelManaged rij = new RijndaelManaged();
            rij.Key = new byte[] {144, 165, 155, 49, 73, 101, 25, 155, 241, 140, 91, 217, 36, 44, 6, 120, 9, 218, 129, 46, 197, 55, 160, 29, 225, 179, 212, 28, 62, 206, 149, 243};
            rij.IV = new byte[] {59, 22, 28, 20, 5, 131, 17, 217, 61, 198, 142, 220, 254, 217, 157, 230};
            // Get a decryptor
            ICryptoTransform d = rij.CreateDecryptor(rij.Key, rij.IV);
            // Decrypt the data
            MemoryStream ms = new MemoryStream();
            CryptoStream cs = new CryptoStream(ms, d, CryptoStreamMode.Write);
            // Write all data to the crypto stream and flush it.
            cs.Write(b, 0, b.Length);
            cs.FlushFinalBlock();
            // Get the string
            string xml = Encoding.UTF8.GetString(ms.ToArray());
            // Left trim up to the first '<' symbol
            xml = xml.Substring(xml.IndexOf('<'));
            // Right trim to the last '>' character
            xml = xml.Substring(0, xml.LastIndexOf('>') + 1);
            // Return the string
            return xml;
        }

        /// <summary>
        /// Strips characters off the ends of serial numbers where necessary
        /// </summary>
        /// <param name="serialNo"></param>
        /// <returns></returns>
        private string StripCharacters(string serialNo)
        {
            return serialNo.Length <= maxSerialLen ? serialNo : serialNo.Substring(0,this.maxSerialLen);
        }

        #region List Verification Methods
        /// <summary>
        /// Parses the given text and returns an array of serial numbers
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
            string listType = null;
            XmlDocument doc = new XmlDocument();
            // Create array lists to hold the strings
            ArrayList c = new ArrayList();
            ArrayList s = new ArrayList();
            // Create a new memory stream
            MemoryStream ms = new MemoryStream(fileText);
            // Read through the stream, collecting items
            string fileLine = String.Empty;
            using (StreamReader sr = new StreamReader(ms))
            {
                // Read past the first line
                sr.ReadLine();
                // Read the rest of the file, decrypt it, and load it into an XML document
                try
                {
                    doc.Load(new MemoryStream(Encoding.UTF8.GetBytes(DecryptFile(sr.ReadToEnd()))));
                }
                catch
                {
                    throw new ApplicationException("File not in correct format for creation of list compare file (error during load).");
                }
                // Get the list type
                listType = doc.DocumentElement.SelectSingleNode("./type").InnerXml.ToUpper();
                // Make sure that it is valid
                if (listType != "SHIP" && listType != "RECEIVE")
                    throw new ApplicationException("Unrecognized document type in RFID output file.");
                // Make sure that this file is being used to create a list
                if (doc.DocumentElement.SelectSingleNode("./action").InnerXml.ToUpper() != "VERIFY")
                    throw new ApplicationException("This RFID file was not intended to verify a list.");
                // Read the list items
                ReadScanItems(doc, listType == "SHIP" ? ListTypes.Send : ListTypes.Receive, ref s, ref c);
                // Convert the arraylists to arrays
                cases = (string[])c.ToArray(typeof(string));
                serials = (string[])s.ToArray(typeof(string));
            }
        }
        /// <summary>
        /// Reads the items of the scan file
        /// </summary>
        /// <param name="sr">
        /// Streamreader attached to the report file
        /// </param>
        /// <param name="itemCollection">
        /// Collection of items into which to place new items
        /// </param>
        /// <returns>
        /// Nothing
        /// </returns>
        private void ReadScanItems(XmlDocument doc, ListTypes listType, ref ArrayList serials, ref ArrayList cases)
        {
            ISendList sdal = SendListFactory.Create();
            ISealedCase cdal = SealedCaseFactory.Create();
            // Add all the individual tapes to the list
            foreach (XmlNode n in doc.DocumentElement.SelectNodes("./tape"))
            {
                cases.Add(String.Empty);
                serials.Add(StripCharacters(n.InnerXml));
            }
            // Now get the tapes that are in cases
            foreach (XmlNode n in doc.DocumentElement.SelectNodes("./case"))
            {
                // Get the case name
                string caseName = n.Attributes["serialNo"].Value;
                // If no tapes, get all the tapes in the case from the database.  Otherwise,
                // loop through the nodes to record the tapes.
                if (!n.HasChildNodes)
                {
                    foreach(MediumDetails m in sdal.GetCaseMedia(caseName))
                    {
                        cases.Add(caseName);
                        serials.Add(m.SerialNo);
                    }
                }
                else
                {
                    for (XmlNode x = n.FirstChild; x != null; x = x.NextSibling)
                    {
                        cases.Add(caseName);
                        serials.Add(StripCharacters(x.InnerXml));
                    }
                }
            }
        }
        #endregion

        #region Send List Creation
        /// <summary>
        /// Parses a send list create file
        /// </summary>
        /// <param name="fileText"></param>
        /// <param name="si"></param>
        /// <param name="c"></param>
        public override void Parse(byte[] fileText, out SendListItemCollection si, out SendListCaseCollection c)
        {
            c = new SendListCaseCollection();
            si = new SendListItemCollection();
            // Create an xml document to hold the file
            XmlDocument doc = new XmlDocument();
            // Create a new memory stream
            MemoryStream ms = new MemoryStream(fileText);
            // Read through the stream, collecting items
            string fileLine = String.Empty;
            using (StreamReader sr = new StreamReader(ms))
            {
                // Read past the first line
                sr.ReadLine();
                // Read the rest of the file, decrypt it, and load it into an XML document
                try
                {
                    doc.Load(new MemoryStream(Encoding.UTF8.GetBytes(DecryptFile(sr.ReadToEnd()))));
                }
                catch
                {
                    throw new ApplicationException("File not in correct format for creation of shipping list (error during load).");
                }
                // Make sure that the file is intended to create a ship list
                if (doc.DocumentElement.SelectSingleNode("./type").InnerXml.ToUpper() != "SHIP")
                {
                    throw new ApplicationException("File not in correct format for creation of shipping list (incorrect type node).");
                }
                else if (doc.DocumentElement.SelectSingleNode("./action").InnerXml.ToUpper() != "CREATE")
                {
                    throw new ApplicationException("File not in correct format for creation of shipping list (incorrect action node).");
                }
                else
                {
                    ReadSendCreate(doc, ref si, ref c);
                }
            }
        }
        /// <summary>
        /// Reads the send list items and cases from the file
        /// </summary>
        /// <param name="doc"></param>
        /// <param name="si"></param>
        /// <param name="c"></param>
        private void ReadSendCreate(XmlDocument doc, ref SendListItemCollection si, ref SendListCaseCollection c)
        {
            c = new SendListCaseCollection();
            si = new SendListItemCollection();
            // Add all the individual tapes to the list
            foreach (XmlNode n in doc.DocumentElement.SelectNodes("./tape"))
            {
                string r = String.Empty;
                if (EmployReturnDate && n.Attributes["returndate"] != null) r = n.Attributes["returndate"].Value;
                si.Add(new SendListItemDetails(StripCharacters(n.InnerXml), r, String.Empty, String.Empty));
            }
            // Now get the tapes that are in cases
            foreach (XmlNode n in doc.DocumentElement.SelectNodes("./case"))
            {
                string r = String.Empty;
                // Get the return date and case name
                string caseName = n.Attributes["serialNo"].Value;
                bool seal = n.Attributes["sealed"] != null && n.Attributes["sealed"].Value.ToUpper() == "TRUE";
                // If no tapes, nothing further to do
                if (!n.HasChildNodes) throw new ApplicationException("Case " + caseName + " listed with no tapes inside.");
                // Get the return date (only used for send lists)
                if (EmployReturnDate && n.Attributes["returndate"] != null) r = n.Attributes["returndate"].Value;
                // Create the case object
                if (c.Find(caseName) == null)
                    c.Add(new SendListCaseDetails(caseName, seal, r, String.Empty));
                // Loop through the nodes.  Note: for whatever reason, this code works with
                // a try/catch block around the statement...no exception occurs.  However, if
                // you remove the block, you get an object reference error.  No idea why.
                for (XmlNode x = n.FirstChild; x != null; x = x.NextSibling)
                {
                    try
                    {
                        si.Add(new SendListItemDetails(StripCharacters(x.InnerXml), r, String.Empty, caseName));
                    }
                    catch
                    {
                        throw;
                    }
                }
            }
        }
        #endregion

        #region Receive List Creation
        /// <summary>
        /// Parses the given text array and returns a collection of receive list items.  Use 
        /// this overload when creating a new receive list only from a stream.
        /// </summary>
        /// <param name="fileText">
        /// Byte array containing text to parse
        /// </param>
        /// <param name="listItems">
        /// Receptacle for returned disaster code list items
        /// </param>
        public override void Parse(byte[] fileText, out ReceiveListItemCollection ri)
        {
            XmlDocument doc = new XmlDocument();
            ri = new ReceiveListItemCollection();
            // Create a new memory stream
            MemoryStream ms = new MemoryStream(fileText);
            // Read through the stream, collecting items
            string fileLine = String.Empty;
            using (StreamReader sr = new StreamReader(ms))
            {
                // Read past the first line
                sr.ReadLine();
                // Read the rest of the file, decrypt it, and load it into an XML document
                try
                {
                    doc.Load(new MemoryStream(Encoding.UTF8.GetBytes(DecryptFile(sr.ReadToEnd()))));
                }
                catch
                {
                    throw new ApplicationException("File not in correct format for creation of receiving list (error during load).");
                }
                // Make sure that the file is intended to create a ship list
                if (doc.DocumentElement.SelectSingleNode("./type").InnerXml.ToUpper() != "RECEIVE")
                {
                    throw new ApplicationException("File not in correct format for creation of receiving list (incorrect type node).");
                }
                else if (doc.DocumentElement.SelectSingleNode("./action").InnerXml.ToUpper() != "CREATE")
                {
                    throw new ApplicationException("File not in correct format for creation of receiving list (incorrect action node).");
                }
                else
                {
                    ReadReceiveCreate(doc, ref ri);
                }
            }
        }
        /// <summary>
        /// Reads the receive list items and cases from the file
        /// </summary>
        /// <param name="doc"></param>
        /// <param name="ri"></param>
        private void ReadReceiveCreate(XmlDocument doc, ref ReceiveListItemCollection ri)
        {
            string tapeSerial = String.Empty;
            ArrayList caseNames = new ArrayList();
            IMedium mdal = MediumFactory.Create();
            ISealedCase cdal = SealedCaseFactory.Create();
            // Add all the individual tapes to the list
            foreach (XmlNode n in doc.DocumentElement.SelectNodes("./tape"))
                ri.Add(new ReceiveListItemDetails(StripCharacters(n.InnerXml), String.Empty));
            // Now get the tapes that are in cases
            foreach (XmlNode n in doc.DocumentElement.SelectNodes("./case"))
            {
                bool b = false;
                // Get the case name
                string caseName = n.Attributes["serialNo"].Value;
                // Create the case object
                foreach (string x in caseNames)
                    if (caseName == x)
                        b = true;
                // If already have the case, skip to next
                if (b == true) continue;
                // Otherwise add the case to the collection
                caseNames.Add(caseName);
                // Get the media known to be in this case from the database
                foreach (MediumDetails m in cdal.GetResidentMedia(caseName))
                {
                    ri.Add(new ReceiveListItemDetails(m.SerialNo, String.Empty));
                }
                // If there are tapes listed in the file under this case, get them
                if (n.HasChildNodes)
                {
                    for (XmlNode x = n.FirstChild; x != null; x = x.NextSibling)
                    {
                        try
                        {
                            // Get the tape serial number
                            tapeSerial = StripCharacters(x.InnerXml);
                            // If we can't find the item, add it
                            if (ri.Find(tapeSerial) == null)
                            {
                                ri.Add(new ReceiveListItemDetails(tapeSerial, String.Empty));
                            }
                        }
                        catch
                        {
                            throw;
                        }
                    }
                }
            }
        }
        #endregion
    }
}
