using System;
using System.IO;
using System.Xml;
using System.Text;
using System.Collections;
using System.Security.Cryptography;
using Bandl.Library.VaultLedger.IDAL;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.IParser;
using Bandl.Library.VaultLedger.Exceptions;
using Bandl.Library.VaultLedger.DALFactory;

namespace Bandl.Library.VaultLedger.Parsers
{
	/// <summary>
	/// Summary description for ImationInventoryParser.
	/// </summary>
	public class ImationInventoryParser : InventoryParser
	{
        public ImationInventoryParser() {}

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
        /// Gets the account name from the file, if it occurs
        /// </summary>
        /// <param name="doc"></param>
        /// <returns>Name of the account on success, else empty string</returns>
        private string GetInventoryAccount(XmlDocument doc)
        {
            XmlNode n = doc.DocumentElement;
            // Get the account if there is one, else return -1
            if (n.Attributes["account"] == null)
            {
                return String.Empty;
            }
            else 
            {
                string accountNo = n.Attributes["account"].Value;
                // Retrieve the account
                if (AccountFactory.Create().GetAccount(accountNo) == null)
                {
                    throw new ApplicationException("Account " + accountNo + " does not exist in the system");
                }
                else
                {
                    return accountNo;
                }            
            }
        }
        /// <summary>
        /// Gets the location name from the file, if it occurs
        /// </summary>
        /// <param name="doc"></param>
        /// <returns>Location of inventory</returns>
        private Locations GetInventoryLocation(XmlDocument doc)
        {
            try
            {
                switch (doc.DocumentElement.SelectSingleNode("./location").InnerXml.ToUpper())
                {
                    case "VAULT":
                        return Locations.Vault;
                    case "ENTERPRISE":
                    case "LOCAL":
                        return Locations.Enterprise;
                    default:
                        throw new ApplicationException();
                }
            }
            catch
            {
                throw new ApplicationException("No location for the inventory was specified in the uploaded file.");
            }
        }
        /// <summary>
        /// Reads the items of the inventory report
        /// </summary>
        /// <param name="doc">
        /// XML docuemnt containing the inventory file
        /// </param>
        /// <param name="accountNo">
        /// Account number of the inventory or empty string
        /// </param>
        /// <param name="s">
        /// ArrayList of ArrayLists containing serial numbers
        /// </param>
        /// <param name="a">
        /// ArrayList of account numbers
        /// </param>
        private void ReadInventoryItems(XmlDocument doc, string accountNo, ref ArrayList s, ref ArrayList a)
        {
            MediumDetails m = null;
            ArrayList f = new ArrayList();
            ArrayList c = new ArrayList();
            IMedium mdal = MediumFactory.Create();
            ISealedCase cdal = SealedCaseFactory.Create();
            IPatternDefaultMedium pdal = PatternDefaultMediumFactory.Create();
            // Gather all the serial numbers
            foreach (XmlNode n in doc.DocumentElement.SelectNodes("./tape")) f.Add(n.InnerXml);
            // Get all the serial numbers in sealed cases
            foreach (XmlNode n in doc.DocumentElement.SelectNodes("./case"))
                foreach (MediumDetails x in cdal.GetResidentMedia(n.InnerXml))
                    f.Add(x.SerialNo);
            // For each of the serial numbers, add them to the inventory                
            foreach (string serialNo in f)
            {
                if (accountNo.Length != 0)
                {
                    ((ArrayList)s[0]).Add(serialNo);
                }
                else
                {
                    int i = -1;
                    string x = String.Empty;
                    // Get the account to which the medium corresponds
                    if ((m = mdal.GetMedium(serialNo)) != null)
                    {
                        x = m.Account;
                    }
                    else
                    {
                        string y = String.Empty;    // Not used but needed as parameter
                        pdal.GetMediumDefaults(serialNo, out y, out x);
                    }
                    // Find the account in the account array list
                    for (int j = 0; j < a.Count && i == -1; j += 1)
                        if (x == (string)a[j])
                            i = j;
                    // If no account index, add the account to the array list and create a new serial number arraylist
                    if (i != -1)
                    {
                        ((ArrayList)s[i]).Add(serialNo);
                    }
                    else
                    {
                        a.Add(x);
                        s.Add(new ArrayList());
                        ((ArrayList)s[s.Count-1]).Add(serialNo);
                    }
                }
            }
        }

        /// <summary>
        /// Parses a byte array of the contents of a batch scanner inventory file
        /// </summary>
        /// <param name="fileText">
        /// Byte array of the contents of the inventory file
        /// </param>
        /// <param name="accounts">
        /// String array of account numbers
        /// </param>
        /// <param name="serials">
        /// Array of arraylists; each arraylist is a list of serial numbers belonging to
        /// the account number contained at the same index of the accounts array.
        /// </param>
        public override void Parse(byte[] fileText)
        {
            XmlDocument doc = new XmlDocument();
            // Create arraylists for the serial number and accounts
            ArrayList s = new ArrayList();
            ArrayList a = new ArrayList();
            // Create a new memory stream
            MemoryStream ms = new MemoryStream(fileText);
            // Read through the stream, collecting items
            using (StreamReader sr = new StreamReader(ms))
            {
                // Read past the first line (header)
                sr.ReadLine();
                // Read the rest of the file, decrypt it, and load it into an XML document
                try
                {
                    doc.Load(new MemoryStream(Encoding.UTF8.GetBytes(DecryptFile(sr.ReadToEnd()))));
                }
                catch
                {
                    throw new ApplicationException("File is not in correct format for inventory upload (error during load).");
                }
                // Get the inventory location
                this.myLocation = GetInventoryLocation(doc);
                // See if we have an account - if we don't, we'll get the account for each medium as it occurs
                string accountNo = GetInventoryAccount(doc);
                if (accountNo.Length != 0) {a.Add(accountNo); s.Add(new ArrayList());}
                // Read through the items
                ReadInventoryItems(doc, accountNo, ref s, ref a);
            }
            // Convert account number arraylist to string array
            this.myAccounts = (string[])a.ToArray(typeof(string));
            // Convert serial number arraylist to array of arraylists
            this.mySerials = (ArrayList[])s.ToArray(typeof(ArrayList));
        }
    }
}
