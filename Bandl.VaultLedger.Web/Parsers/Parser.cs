using System;
using System.IO;
using System.Collections;
using System.Globalization;
using System.Text.RegularExpressions;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.IParser;
using Bandl.Library.VaultLedger.Collections;
using Bandl.Library.VaultLedger.DALFactory;
using Bandl.Library.VaultLedger.Exceptions;

namespace Bandl.Library.VaultLedger.Parsers
{
    /// <summary>
    /// Summary description for Parser.
    /// </summary>
    public class Parser : IParserObject
    {
        protected enum ReportType {Unknown, Distribution, Picking}

        private ExternalSiteCollection esc = null;
        private string dictateIndicator = ".D.I.C.T.A.T.E.";
        private string employReturnDate = null;
        private string ignoreUnknownSite = null;
        private string dataSetNoteAction = null;
        private bool accountDictate = false;

        protected bool AccountDictate
        {
            get {return accountDictate;}
        }

        protected bool IsAccount(string accountName)
        {
            return AccountFactory.Create().GetAccount(accountName) != null;
        }

        protected bool EmployReturnDate
        {
            get
            {
                if (employReturnDate == null)
                {
                    PreferenceDetails option = PreferenceFactory.Create().GetPreference(PreferenceKeys.TmsReturnDates);
                    if (option == null) option = PreferenceDetails.CreateDefault(PreferenceKeys.TmsReturnDates);
                    employReturnDate = option.Value.ToUpper();
                }
                // Return the preference status
                return (employReturnDate == "TRUE" || employReturnDate == "YES");
            }        
        }

        protected string DataSetNoteAction
        {
            get
            {
                if (dataSetNoteAction == null)
                {
                    PreferenceDetails option = PreferenceFactory.Create().GetPreference(PreferenceKeys.TmsDataSetNotes);
                    if (option == null) option = PreferenceDetails.CreateDefault(PreferenceKeys.TmsDataSetNotes);
                    dataSetNoteAction = option.Value.ToUpper();
                }
                // Return the preference value
                return dataSetNoteAction;
            }        
        }

        protected bool IgnoreUnknownSite
        {
            get
            {
                if (ignoreUnknownSite == null)
                {
                    PreferenceDetails option = PreferenceFactory.Create().GetPreference(PreferenceKeys.TmsUnknownSite);
                    if (option == null) option = PreferenceDetails.CreateDefault(PreferenceKeys.TmsUnknownSite);
                    ignoreUnknownSite = option.Value.ToUpper();
                }
                // Return the preference status
                return (ignoreUnknownSite == "TRUE" || ignoreUnknownSite == "YES");
            }        
        }

        /// <summary>
        /// Resolves a site name to determine whether or not it corresponds
        /// to the enterprise or to the vault.
        /// </summary>
        /// <param name="siteName">
        /// Name of the site to resolve
        /// </param>
        /// <returns>
        /// True if the site resolves to the enterprise, else false
        /// </returns>
        public bool SiteIsEnterprise(string siteName)
        {
            string x = null;
            return SiteIsEnterprise(siteName, out x);
        }

        /// <summary>
        /// Resolves a site name to determine whether or not it corresponds
        /// to the enterprise or to the vault.
        /// </summary>
        /// <param name="siteName">
        /// Name of the site to resolve
        /// </param>
        /// <param name="accountName">
        /// Account name attached to site map
        /// </param>
        /// <returns>
        /// True if the site resolves to the enterprise, else false
        /// </returns>
        public bool SiteIsEnterprise(string siteName, out string accountName)
        {
            accountName = String.Empty;
            ExternalSiteDetails es = null;
            // Get the external sites from the database
            if (esc == null)
                esc = ExternalSiteFactory.Create().GetExternalSites();
            // Make everything uppercase so that comparisons will be case insensitive
            for (int i = 0; i < esc.Count; i++)
            {
                esc[i].Name = esc[i].Name.ToUpper().Replace("  ", " ");;
            }
            // Resolve the location of the site
            if ((es = esc.Find(siteName.ToUpper().Replace("  ", " "))) == null)
            {
                throw new ExternalSiteException("Unable to resolve location of destination site '" + siteName + "'.  Site unknown.");
            }
            else
            {
                accountName = es.Account;
                return es.Location == Locations.Enterprise;
            }
        }

        /// <summary>
        /// Resolves a site name to determine whether or not it corresponds
        /// to the enterprise or to the vault.
        /// </summary>
        /// <param name="siteName">
        /// Name of the site to resolve
        /// </param>
        /// <param name="accountName">
        /// Account name attached to site map
        /// </param>
        /// <returns>
        /// True if the site resolves to the enterprise, else false
        /// </returns>
        protected string GetAccountName(string siteName)
        {
            ExternalSiteDetails es = null;
            string accountName = String.Empty;
            // Compress whitespace
            while (siteName.IndexOf("  ") != -1)
            {
                siteName = siteName.Replace("  ", " ");
            }
            // Get the external sites from the database
            if (esc == null)
                esc = ExternalSiteFactory.Create().GetExternalSites();
            // Make everything uppercase so that comparisons will be case insensitive
            for (int i = 0; i < esc.Count; i++)
            {
                esc[i].Name = esc[i].Name.ToUpper().Trim();
                while (esc[i].Name.IndexOf("  ") != -1)
                {
                    esc[i].Name = esc[i].Name.Replace("  ", " ");
                }
            }
            // Resolve the location of the site
            if ((es = esc.Find(siteName.ToUpper().Trim())) == null)
            {
                return String.Empty;
            }
            else
            {
                return es.Account;
            }
        }
        /// <summary>
        /// Parses a date from a TMS report and returns the date in yyyy-MM-dd format.
        protected string ParseReportDate(string date)
        {
            date = date.Trim();
            // Determine if the date is a julian date or not
            if (new Regex(@"^20[0-9]{2}[/\-\.]{1}[0-9]{1,3}$").IsMatch(date))
            {
                int year = Convert.ToInt32(date.Substring(0,4));
                int day = Convert.ToInt32(date.Substring(5,date.Length - 1 - 5));
                return new DateTime(year, 1, 1).AddDays(day - 1).ToString("yyyy-MM-dd");
            }
            else if (new Regex(@"^20[0-9]{2}[/\-\.]{1}[0-9]{1,2}[/\-\.]{1}[0-9]{1,2}$").IsMatch(date))
            {
                int posSep = date.IndexOf(date.Substring(4, 1), 5);  // position of second separator
                int year = Convert.ToInt32(date.Substring(0, 4));
                int month = Convert.ToInt32(date.Substring(5, posSep - 5));
                int day = Convert.ToInt32(date.Substring(posSep + 1, date.Length - 1 - posSep));
                return new DateTime(year, month, day).ToString("yyyy-MM-dd");
            }
            else if (new Regex(@"^[0-9]{1-2}[/\-\.]{1}[0-9]{1-2}[/\-\.]{1}20[0-9]{2}$").IsMatch(date))
            {
                int posSep1 = date.IndexOfAny(new char[] {'.', '/', '-'});  // position of first separator
                int posSep2 = date.IndexOfAny(new char[] {'.', '/', '-'}, posSep1 + 1);  // position of second separator
                int year = Convert.ToInt32(date.Substring(posSep2 + 1, date.Length - 1 - posSep2));
                int month = 1;
                int day = 1;

                switch (new DateTimeFormatInfo().ShortDatePattern.ToUpper()[0])
                {
                    case 'D':
                        day = Convert.ToInt32(date.Substring(0, posSep1));
                        month = Convert.ToInt32(date.Substring(posSep1 + 1, posSep2 - posSep1 - 1));
                        return new DateTime(year, month, day).ToString("yyyy-MM-dd");
                    case 'M':
                        month = Convert.ToInt32(date.Substring(0, posSep1));
                        day = Convert.ToInt32(date.Substring(posSep1 + 1, posSep2 - posSep1 - 1));
                        return new DateTime(year, month, day).ToString("yyyy-MM-dd");
                    default:
                        throw new ParserException("Unrecognized return date format in TMS report.");
                }
            }
            else
            {
                return String.Empty;
            }
        }

        /// <summary>
        /// Trims string from left
        /// </summary>
        protected string LeftTrim(string x)
        {
            int i = -1;
            // If the string is null, return null
            if (x == null) return null;
            // Get rid of characters ascii space or less at the beginning of the string
            for (i = 0; i < x.Length; i++)
                if (x[i] > 32) 
                    return x.Substring(i);
            // No characters 
            return String.Empty;
        }
            
        /// <summary>
        /// Trims a string at next space or tab
        /// </summary>
        protected string Trim(string x)
        {
            int i = -1;
            // If the string is null, return null
            if (x == null) return null;
            // Left trim the string
            x = LeftTrim(x);
            // Find first character leq ascii 32
            for (i = 0; i < x.Length; i++)
                if (x[i] <= 32) 
                    return x.Substring(0, i);
            // No valid i; return the string in its entirety
            return x;
        }

        #region IParser Methods
        /// <summary>
        /// Gets the string that signals that the account should be forced
        /// </summary>
        public string GetDictateIndicator()
        {
            return dictateIndicator;
        }

        /// <summary>
        /// When set to true, allows the report to dictate the account of the media within
        /// </summary>
        /// <param name="allow">
        /// True or false
        /// </param>
        public void AllowAccountDictate(bool doDictate)
        {
            accountDictate = doDictate;
        }

        /// <summary>
        /// Parses the given text array and returns send list items and 
        /// receive list items.  Use this overload if the stream is a
        /// new TMS send/receive list report, e.g. CA-25.
        /// </summary>
        /// <param name="fileText">
        /// Byte array containing text to parse
        /// </param>
        /// <param name="sendCollection">
        /// Receptacle for returned send list item collection
        /// </param>
        /// <param name="receiveCollection">
        /// Receptacle for returned receive list item collection
        /// </param>
        public virtual void Parse(byte[] fileText, out SendListItemCollection sendCollection, out ReceiveListItemCollection receiveCollection)
        {
            sendCollection = null;
            receiveCollection = null;
            throw new ParserException("Incorrect parse method employed.");
        }

        /// <summary>
        /// Parses the given text array and returns send list items and 
        /// receive list items.  Use this overload if the stream is a
        /// new TMS send/receive list report, e.g. CA-25.
        /// </summary>
        /// <param name="fileText">
        /// Byte array containing text to parse
        /// </param>
        /// <param name="sli">
        /// Receptacle for returned send list item collection
        /// </param>
        /// <param name="rli">
        /// Receptacle for returned receive list item collection
        /// </param>
        /// <param name="s">
        /// Receptacle for returned serial numbers, whose accounts must be assigned to media directly
        /// </param>
        /// <param name="a">
        /// Receptacle for returned accounts, to which the serial numbers in s should be assigned
        /// </param>
        /// <param name="l">
        /// Receptacle for returned locations, where the serial numbers in s should be placed
        /// </param>
        public virtual void Parse(byte[] fileText, out SendListItemCollection sli, out ReceiveListItemCollection rli, out ArrayList s, out ArrayList a, out ArrayList l)
        {
            // Create empty array lists
            s = new ArrayList();
            a = new ArrayList();
            l = new ArrayList();
            // If not implemented in descendant, this will call the standard Parse method
            Parse(fileText, out sli, out rli);
        }

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
        public virtual void Parse(byte[] fileText, out SendListItemCollection sendCollection, out SendListCaseCollection caseCollection)
        {
            sendCollection = null;
            caseCollection = null;
            throw new ParserException("Incorrect parse method employed.");
        }

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
        public virtual void Parse(byte[] fileText, out string[] serials, out string[] cases)
        {
            serials = cases = null;
            throw new ParserException("Incorrect parse method employed.");
        }

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
        public virtual void Parse(byte[] fileText, out ReceiveListItemCollection li)
        {
            li = null;
            throw new ParserException("Incorrect parse method employed.");
        }

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
        public virtual void Parse(byte[] fileText, out DisasterCodeListItemCollection listItems)
        {
            listItems = null;
            throw new ParserException("Incorrect parse method employed.");
        }
        #endregion
    }
}
