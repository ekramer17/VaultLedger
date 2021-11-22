using System;
using System.IO;
using System.Globalization;
using Bandl.Library.VaultLedger.IDAL;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.IParser;
using Bandl.Library.VaultLedger.DALFactory;
using Bandl.Library.VaultLedger.Exceptions;
using Bandl.Library.VaultLedger.Collections;
using System.Text.RegularExpressions;

namespace Bandl.Library.VaultLedger.Parsers
{
	/// <summary>
	/// Summary description for ParserFactory.
	/// </summary>
	public class ParserFactory : IParserFactory
	{
        private ParserTypes parserType;

        #region Constructors
        public ParserFactory() : this(ParserTypes.Movement) {}
        public ParserFactory(ParserTypes _parserType) {parserType = _parserType;}
        #endregion

        /// <summary>
        /// Examines the file text array and determines the type of parser to 
        /// return to the caller.
        /// </summary>
        /// <param name="fileText">
        /// Byte array containing text to parse
        /// </param>
        /// <returns>
        /// Appropriate parser object
        /// </returns>
        public IParserObject GetParser(byte[] fileText)
        {
            return GetParser(fileText, String.Empty);
        }

        /// <summary>
        /// Examines the file text array and determines the type of parser to 
        /// return to the caller.
        /// </summary>
        /// <param name="fileText">
        /// Byte array containing text to parse
        /// </param>
        /// <returns>
        /// Appropriate parser object
        /// </returns>
        public IInventoryParser GetInventoryParser(byte[] fileText)
        {
            // Make sure that we have a byte array
            if (fileText == null)
            {
                throw new ArgumentNullException("fileText", "Report file cannot be null.");
            }
            else if (fileText.Length == 0)
            {
                throw new ValueRequiredException("fileText", "Report file stream cannot be empty.");
            }
            else
            {
                return CreateInventoryParser(fileText);
            }
        }

        /// <summary>
        /// Examines the file text array and determines the type of parser to 
        /// return to the caller.
        /// </summary>
        /// <param name="fileText">
        /// Byte array containing text to parse
        /// </param>
        /// <returns>
        /// Appropriate parser object
        /// </returns>
        public IParserObject GetParser(byte[] fileText, string fileName)
        {
            // Make sure that we have a byte array
            if (fileText == null)
            {
                throw new ArgumentNullException("fileText", "Report file cannot be null.");
            }
            else if (fileText.Length == 0)
            {
                throw new ValueRequiredException("fileText", "Report file stream cannot be empty.");
            }
            // If we have a filename, use only the filename, not the full path
            if (fileName != null && fileName.Length != 0)
            {
                int x = fileName.LastIndexOf(Path.DirectorySeparatorChar);
                if (x != -1) fileName = fileName.Substring(x+1);
            }
            // Determine the type of parser to create
            switch (parserType)
            {
                case ParserTypes.Movement:
                    return this.CreateMovementParser(fileText, fileName);
                case ParserTypes.Disaster:
                    return this.CreateDisasterParser(fileText, fileName);
                default:
                    throw new ApplicationException("No parser type specified");
            }
        }

        /// <summary>
        /// Examines the file text array and determines the type of parser to 
        /// return to the caller.
        /// </summary>
        /// <param name="fileText">
        /// Byte array containing text to parse
        /// </param>
        /// <returns>
        /// Appropriate parser object
        /// </returns>
        private IParserObject CreateMovementParser(byte[] fileText, string fileName)
        {
Tracer.Trace("[ATOS]PARSER DISCOVERY");
            // Find the type of file
			if (Sanofi2Report(fileText) == true)		// Ultra specific but must occur before other Sanofi parsers
			{
				return new Sanofi2Parser();
			}
			else if (Sanofi3Report(fileText) == true)	// Ultra specific but must be before final Sanofi parser
			{
				return new Sanofi3Parser();
			}
			else if (SanofiReport(fileText) == true)	// Ultra specific
			{
				return new SanofiParser();
			}
			else if (LATimesReport(fileText) == true)	// Ultra specific
			{
				return new LATimesParser();
			}
			else if (NJStateReport(fileText) == true)	// Ultra specific
			{
				return new NJStateParser();
			}
			else if (CoverallReport(fileText) == true)	// Ultra specific
			{
				return new CoverallParser();
			}
            else if (PSECUReport(fileText) == true)	    // Ultra specific
            {
                return new PSECUParser();
            }
            else if (DeltaReport(fileText) == true)	    // Ultra specific
            {
                return new DeltaParser();
            }
            else if (McKessonReport(fileText) == true)	    // Ultra specific
            {
                return new McKessonParser();
            }
            else if (McKesson2Report(fileText) == true)	    // Ultra specific
            {
                return new McKesson2Parser();
            }
            else if (AmericaOneReport(fileText) == true)	    // Ultra specific
            {
                return new AmericaOneParser();
            }
            else if (Exxon3Report(fileText) == true)	    // Ultra specific
            {
                return new Exxon3Parser();
            }
            else if (NaviSiteReport(fileText) == true)	    // Ultra specific
            {
                return new NaviSiteParser();
            }
            else if (FarmBureauReport(fileText) == true)	// Ultra specific
            {
                return new FarmBureauParser();
            }
            else if (ATOS1Report(fileText) == true)	// Ultra specific
            {
Tracer.Trace("[ATOS]PARSER DISCOVERED");
                return new ATOS1Parser();
            }
            else if (NavistarReport(fileText) == true)
            {
                return new NavistarParser();
            }
            else if (Navistar2Report(fileText) == true)
            {
                return new Navistar2Parser();
            }
            else if (CA25Report(fileText) == true)
            {
				return CA25Report_Quebec(fileText) ? new CA25QuebecParser() : new CA25Parser();
            }
            else if (Ricoh5Report(fileText) == true)    // more specific
            {
                return new Ricoh5Parser();
            }
            else if (Ricoh6Report(fileText) == true)    // more specific
            {
                return new Ricoh6Parser();
            }
            else if (Ricoh1Report(fileText) == true)
            {
                return new Ricoh1Parser();
            }
            else if (Ricoh2Report(fileText) == true)
            {
                return new Ricoh2Parser();
            }
            else if (Ricoh3Report(fileText) == true)
            {
                return new Ricoh3Parser();
            }
            else if (Ricoh4Report(fileText) == true)
            {
                return new Ricoh4Parser();
            }
            else if (BrightStorReport(fileText) == true)
            {
                return new BrightStorParser();
            }
            else if (DomesticReceiveExport(fileText) == true)
            {
                return new DomesticReceiveParser();
            }
            else if (DomesticSendExport(fileText) == true)
            {
                return new DomesticSendParser();
            }
            else if (Recall1Report(fileText) == true)
            {
                return new Recall1Parser();
            }
			else if (VTMSReport(fileText, fileName) == true)
            {
                return new VTMSParser(fileName.ToUpper()[0] == 'R');
            }
            else if (VideotronReport(fileText) == true)
            {
                return new VideotronParser();
            }
            else if (StarReport(fileText) == true)
            {
                return new StarParser();
            }
            else if (VeritasReport(fileText) == true)
            {
                return GetVeritasParser(fileText);
            }
            else if (RMM3Report(fileText) == true)
            {
                return new RMM3Parser();
            }
            else if (BLLIBReport(fileText) == true)
            {
                return new BLLIBParser();
            }
            else if (Countrywide1Report(fileText) == true)
            {
                return new Countrywide1Parser();
            }
            else if (Countrywide2Report(fileText) == true)
            {
                return new Countrywide2Parser();
            }
            else if (Countrywide3Report(fileText) == true)
            {
                return new Countrywide3Parser();
            }
            else if (ADP1Report(fileText) == true)
            {
                return new ADP1Parser();
            }
            else if (ADP2Report(fileText) == true)
            {
                return new ADP2Parser();
            }
            else if (GalaxyReport(fileText) == true)
            {
                return new GalaxyParser();
            }
            else if (BatchNewSendList(fileText) == true)
            {
                return new BatchSendListParser();
            }
            else if (BatchCompareFile(fileText) == true)
            {
                return new BatchCompareParser();
            }
			else if (CBS2Report(fileText) == true)
			{
				return new CBS2Parser();
			}
			else if (CBSReport(fileText) == true)
            {
                return new CBSParser();
            }
            else if (CanadaDefenseReport(fileText) == true)
            {
                return new CanadaDefenseParser();
            }
            else if (CanadianTireReport(fileText) == true)
            {
                return new CanadianTireParser();
            }
            else if (CanadianTire2Report(fileText) == true)
            {
                return new CanadianTire2Parser();
            }
            else if (CGI3Report(fileText) == true)  // must be before CGI2Parser
            {
                return new CGI3Parser();
            }
            else if (CGI2Report(fileText) == true)
            {
                return new CGI2Parser();
            }
            else if (CokeReport(fileText) == true)
            {
                return new CokeParser();
            }
            else if (Conseco1Report(fileText) == true)
            {
                return new Conseco1Parser();
            }
            else if (Conseco2Report(fileText) == true)
            {
                return new Conseco2Parser();
            }
            else if (IndianaFarmReport(fileText) == true)   // must be before Conseco3
            {
                return new IndianaFarmParser();
            }
            else if (Conseco3Report(fileText) == true)
            {
                return new Conseco3Parser();
            }
			else if (IronMountainReport(fileText) == true)
            {
                return new IronMountainParser();
            }
			else if (Loto1Report(fileText) == true)
			{
				return new Loto1Parser();
			}
			else if (Loto2Report(fileText) == true)
			{
				return new Loto2Parser();
			}
			else if (McDonaldsReport(fileText) == true)
            {
                return new McDonaldsParser();
            }
            else if (SprintReport(fileText) == true)
            {
                return new SprintParser();
            }
            else if (BMCReport(fileText) == true)
            {
                return new BMCParser();
            }
            else if (ACS1Report(fileText) == true)
            {
                return new ACS1Parser();
            }
            else if (Fox1Report(fileText) == true)
            {
                return new Fox1Parser();
            }
            else if (Exxon2Report(fileText) == true)
            {
                return new Exxon2Parser();
            }
            else if (ImationReport(fileText) == true)
            {
                return new ImationParser();
            }
            else if (LoewsReport(fileText) == true)
            {
                return new LoewsParser();
            }
            else if (ViacomReport(fileText) == true)
            {
                return new ViacomParser();
            }
            else if (USAGroupReport(fileText) == true)
            {
                return new USAGroupParser();
            }
            else if (TivoliReport(fileText) == true)
            {
                return new TivoliParser();
            }
            else if (Fox2Report(fileText) == true)  // low on the pole b/c of vague recognition string
            {
                return new Fox2Parser();
            }
			else if (Fox3Report(fileText) == true)  // low on the pole b/c of vague recognition string
			{
				return new Fox3Parser();
			}
			else if (IBM1Report(fileText) == true)  // low on the pole b/c of vague recognition string
            {
                return new IBM1Parser();
            }
            else if (GrummanReport(fileText) == true)  // low on the pole b/c of vague recognition string
            {
                return new GrummanParser();
            }
            else if (ACS2Report(fileText) == true)  // low on the pole b/c of vague recognition string
            {
                return new ACS2Parser();
            }
            else if (IBM2Report(fileText) == true)  // low on the pole b/c of vague recognition string
            {
                return new IBM2Parser();
            }
            else if (AmericanCentury1Report(fileText) == true)
            {
                return new AmericanCentury1Parser();
            }
            else if (AmericanCentury2Report(fileText) == true)
            {
                return new AmericanCentury2Parser();
            }
            else if (MassBayTransitReport(fileText) == true)
            {
                return new MBTAParser();
            }
            else if (BCBS1Report(fileText) == true)
            {
                return new BCBS1Parser();
            }
            else if (BCBS2Report(fileText) == true)
            {
                return new BCBS2Parser();
            }
            else if (INGReport(fileText, fileName) == true)     // Must be last b/c no headers at all
            {
                return new INGParser(fileName.ToUpper().StartsWith("PC") ? ListTypes.Send : ListTypes.Receive);
            }
            else
            {
                throw new ParserException("Report file was not of a type recognized by the parser.");
            }
        }


        /// <summary>
        /// Examines the file text array and determines the type of parser to 
        /// return to the caller.
        /// </summary>
        /// <param name="fileText">
        /// Byte array containing text to parse
        /// </param>
        /// <returns>
        /// Appropriate parser object
        /// </returns>
        private IParserObject CreateDisasterParser(byte[] fileText, string fileName)
        {
            if (CA25DisasterReport(fileText) == true)
            {
                return new CA25DisasterParser();
            }
            else if (TLMSDisasterReport(fileText) == true)
            {
                return new TLMSDisasterParser();
            }
            else if (VideotronDisasterReport(fileText) == true)
            {
                return new VideotronDisasterParser();
            }
            else if (CanadianTireDisasterReport(fileText) == true)
            {
                return new CanadianTireDisasterParser();
            }
            else if (CGI4DisasterReport(fileText) == true)
            {
                return new CGI4DisasterParser();
            }
            else if (CGI1DisasterReport(fileText) == true)
            {
                return new CGI1DisasterParser();
            }
            else if (CGI3DisasterReport(fileText) == true)  // Must come before CGI2
            {
                return new CGI3DisasterParser();
            }
            else if (CGI2DisasterReport(fileText) == true)
            {
                return new CGI2DisasterParser();
            }
            else if (ExxonDisasterReport(fileText) == true)
            {
                return new ExxonDisasterParser();
            }
            else if (LACountyDisasterReport(fileText) == true)
            {
                return new LACountyDisasterParser();
            }
            else if (IndianaFarmDisasterReport(fileText) == true)
            {
                return new IndianaFarmDisasterParser();
            }
            if (AmericanCenturyDisasterReport(fileText) == true)
            {
                return new AmericanCenturyDisasterParser();
            }
            else if (MediaExportDisasterReport(fileText) == true)
            {
                return new MediaExportDisasterParser();
            }
            else if (USAGroupDisasterReport(fileText) == true)
            {
                return new USAGroupDisasterParser();
            }
            else if (UMBBankDisasterReport(fileText) == true)
            {
                return new UMBBankDisasterParser();
            }
            else if (BatchDisasterFile(fileText) == true)
            {
                return new BatchDisasterListParser();
            }
            else
            {
                throw new ParserException("Report file was not of a type recognized by the parser.");
            }
        }

        /// <summary>
        /// Examines the file text array and determines the type of parser to 
        /// return to the caller.
        /// </summary>
        /// <param name="fileText">
        /// Byte array containing text to parse
        /// </param>
        /// <returns>
        /// Appropriate parser object
        /// </returns>
        private InventoryParser CreateInventoryParser(byte[] fileText)
        {
            if (BatchInventoryFile(fileText) == true)
            {
                return new BatchInventoryParser();
            }
            else if (ImationInventoryFile(fileText) == true)
            {
                return new ImationInventoryParser();
            }
            else if (TLMSInventoryFile(fileText) == true)
            {
                return new TLMSInventoryParser();
            }
            else if (IronMountain2InventoryFile(fileText) == true)
			{
				return new IronMountain2InventoryParser();
			}
			else if (IronMountainInventoryFile(fileText) == true)    // MUST BE LAST COMPARISON!  NO HEADER INFORMATION!
            {
                return new IronMountainInventoryParser();
            }
            else if (RQMMInventoryFile(fileText) == true)
            {
                return new RQMMInventoryParser();
            }
            else
            {
                throw new ParserException("Report file was not of a type recognized by the parser.");
            }
        }

        #region Movement Parsers
        /// <summary>
        /// Veritas Vault may be slightly different depending on the company producing
        /// the report.  This method determines the correct Veritas parser or derivative
        /// to return to the caller.
        /// </summary>
        private IParserObject GetVeritasParser(byte[] fileText)
        {
            if (Conseco4Report(fileText))
                return new Conseco4Parser();
            else if (NYLifeReport(fileText))
                return new NYLifeParser();
            else if (Exxon1Report(fileText))
                return new Exxon1Parser();
            else if (CGI1Report(fileText))
                return new CGI1Parser();
            else
                return new VeritasParser();
        }

        /// <summary>
        /// Tests the file to determine whether or not the file is an
        /// ACS1 report file.
        /// </summary>
        /// <param name="fileText">
        /// Memory array of the file data
        /// </param>
        /// <returns>
        /// True if the stream is a ACS1 report, else false
        /// </returns>
        private bool ACS1Report(byte[] fileText)
        {
            string fileLine;
            // Create new memory stream
            MemoryStream ms = new MemoryStream(fileText);
            // Read to find distinctive marks
            using (StreamReader sr = new StreamReader(ms))
            {
                while ((fileLine = sr.ReadLine()) != null)
                {
                    if ((fileLine = fileLine.ToUpper().Trim()) != String.Empty)
                    {
                        if (fileLine.IndexOf("EXPORT MEDIA:") == 0 && fileLine.IndexOf(" TO ") != -1)
                        {
                            return true;
                        }
                        else
                        {
                            return false;
                        }
                    }
                }
            }
            // Conclude that this is not an ACS1 report
            return false;
        }

        /// <summary>
        /// Tests the file to determine whether or not the file is an
        /// ACS2 report file.
        /// </summary>
        /// <param name="fileText">
        /// Memory array of the file data
        /// </param>
        /// <returns>
        /// True if the stream is a ACS1 report, else false
        /// </returns>
        private bool ACS2Report(byte[] fileText)
        {
            string fileLine;
            // Create new memory stream
            MemoryStream ms = new MemoryStream(fileText);
            // Read to find distinctive marks
            using (StreamReader r = new StreamReader(ms))
            {
                while ((fileLine = r.ReadLine()) != null)
                {
                    if (fileLine.IndexOf("Please SEND to the vault") != -1)
                    {
                        return true;
                    }
                    else if (fileLine.IndexOf("Tapes to SEND to Recall") != -1)
                    {
                        return true;
                    }
                    else if (fileLine.IndexOf("Tapes to RETURN from Recall") != -1)
                    {
                        return true;
                    }
                }
            }
            // Conclude that this is not an ACS2 report
            return false;
        }

        /// <summary>
        /// Tests the file to determine whether or not the file is an
        /// ADP report file.
        /// </summary>
        /// <param name="fileText">
        /// Memory array of the file data
        /// </param>
        /// <returns>
        /// True if the stream is a ADP1 report, else false
        /// </returns>
        private bool ADP1Report(byte[] fileText)
        {
            string fileLine;
            // Create new memory stream
            MemoryStream ms = new MemoryStream(fileText);
            // Read to find distinctive marks
            using (StreamReader sr = new StreamReader(ms))
            {
                while ((fileLine = sr.ReadLine()) != null)
                {
                    // Uppercase the fileLine;  skip empty lines
                    if ((fileLine = fileLine.ToUpper().Trim()) == String.Empty)
                    {
                        continue;
                    }
                    else if (fileLine.IndexOf("ADP") == 0 && fileLine.IndexOf("OPERATION RESULTS") != -1) 
                    {
                        return true;
                    }
                    else
                    {
                        break;
                    }
                }
            }
            // Not an ADP1 report
            return false;
        }
         
        /// <summary>
        /// Tests the file to determine whether or not the file is an
        /// ADP report file.
        /// </summary>
        /// <param name="fileText">
        /// Memory array of the file data
        /// </param>
        /// <returns>
        /// True if the stream is a ADP report, else false
        /// </returns>
        private bool ADP2Report(byte[] fileText)
        {
            int x = 0;
            string fileLine;
            // Create new memory stream
            MemoryStream ms = new MemoryStream(fileText);
            // Read to find distinctive marks
            using (StreamReader sr = new StreamReader(ms))
            {
                while ((fileLine = sr.ReadLine()) != null)
                {
                    // Uppercase the fileLine;  skip empty lines
                    if ((fileLine = fileLine.ToUpper().Trim()) == String.Empty) continue;
                    // Look for string based on stage
                    switch (x)
                    {
                        case 0:
                            if (fileLine.IndexOf("MEDIA MOVEMENT REQUEST FORM") != -1) x += 1;
                            break;
                        case 1:
                            if (fileLine.IndexOf("REQUEST DATE:") != -1) x += 1;
                            break;
                        case 2:
                            if (fileLine.IndexOf("PLEASE CHECK ONE OF THE FOLLOWING") != -1) x += 1;
                            break;
                        case 3:
                            if (fileLine.IndexOf("TAPE #") != -1 && fileLine.IndexOf("MEDIA NUMBER") != -1) return true;
                            break;
                        default:
                            break;
                    }
                }
            }
            // Not an ADP report
            return false;
        }

        /// <summary>
        /// Tests the file to determine whether or not the file is an American Century report file.
        /// </summary>
        /// <param name="fileText">
        /// Memory array of the file data
        /// </param>
        /// <returns>
        /// True if the stream is a American Century report, else false
        /// </returns>
        private bool AmericanCentury1Report(byte[] fileText)
        {
            string fileLine = null;
            // Read to find distinctive marks
            using (StreamReader r = new StreamReader(new MemoryStream(fileText)))
            {
                // First line should contain company name
                if ((fileLine = r.ReadLine()) != null)
                {
                    if (fileLine.ToUpper().IndexOf("AMERICAN CENTURY") != -1)
                    {
                        return true;
                    }
                }
                // Nope
                return false;
            }
        }
        
        /// <summary>
        /// Tests the file to determine whether or not the file is an American Century report file.
        /// </summary>
        /// <param name="fileText">
        /// Memory array of the file data
        /// </param>
        /// <returns>
        /// True if the stream is a American Century report, else false
        /// </returns>
        private bool AmericanCentury2Report(byte[] fileText)
        {
            string fileLine = null;
            // Read to find distinctive marks
            using (StreamReader r = new StreamReader(new MemoryStream(fileText)))
            {
                // First line should contain movement header
                if ((fileLine = r.ReadLine()) != null)
                {
                    if (fileLine.ToUpper().IndexOf("MOVEMENT REPORT BY") != -1)
                    {
                        if ((fileLine = r.ReadLine().ToUpper()).IndexOf("FROM LOCATION") != -1 && fileLine.IndexOf("TO LOCATION") != -1)
                        {
                            return true;
                        }
                    }
                }
                // Nope
                return false;
            }
        }

        /// <summary>
        /// Tests the file to determine whether or not the file is a AmericaOne file
        /// </summary>
        /// <param name="fileText">
        /// Memory array of the file data
        /// </param>
        /// <returns>
        /// True if the stream is an AmericaOne file, else false
        /// </returns>
        private bool AmericaOneReport(byte[] b1)
        {
            String s1 = null;
            // First line all that is necessary
            using (StreamReader r1 = new StreamReader(new MemoryStream(b1)))
            {
                while ((s1 = r1.ReadLine()) != null)
                {
                    if (s1.Trim().Length != 0)
                    {
                        return s1.ToUpper().IndexOf("LIST FOR ONEAMERICA")  != -1;
                    }
                }
            }
            // Nope!
            return false;
        }

        /// <summary>
        /// Tests the file to determine whether or not the file is an
        /// ATOS report file.
        /// </summary>
        /// <param name="fileText">
        /// Memory array of the file data
        /// </param>
        /// <returns>
        /// True if the stream is a ATOS1 report, else false
        /// </returns>
        private bool ATOS1Report(byte[] fileText)
        {
            // Create new memory stream
            MemoryStream ms = new MemoryStream(fileText);
            // Read to find distinctive marks
            using (StreamReader sr = new StreamReader(ms))
            {
                string fileLine = sr.ReadLine();
                fileLine = sr.ReadLine().ToUpper(); // second line

                if (fileLine.IndexOf("ATOS VAULTING LIST") != -1 || fileLine.IndexOf("ATOS RECALL LIST") != -1)
                    return true;
                else
                    return false;
            }
        }

        /// <summary>
        /// Tests the file to determine whether or not the file is a 
        /// Blue Cross Blue Shield report (type 1).
        /// </summary>
        /// <param name="fileText">
        /// Memory array of the file data
        /// </param>
        /// <returns>
        /// True if the stream is a BCBS report, else false
        /// </returns>
        private bool BCBS1Report(byte[] fileText)
        {
            string fileLine;
            // Create new memory stream
            MemoryStream ms = new MemoryStream(fileText);
            // Read to find distinctive marks
            using (StreamReader sr = new StreamReader(ms))
            {
                while ((fileLine = sr.ReadLine()) != null)
                {
                    if (fileLine.ToUpper().IndexOf("BLUE CROSS BLUE SHIELD OF GA") != -1)
                    {
                        // Search for headers
                        while ((fileLine = sr.ReadLine()) != null)
                        {
                            if (fileLine.ToUpper().IndexOf("RACK") != -1 && fileLine.ToUpper().IndexOf("MEDIANAME") != -1)
                            {
                                // Next line should contain only hyphens
                                if ((fileLine = sr.ReadLine()).Replace("-", String.Empty).Trim().Length == 0)
                                {
                                    return true;
                                }
                            }
                        }
                    }
                }
                // Conclude that this is not a BCBS1 report
                return false;
            }
        }

        /// <summary>
        /// Tests the file to determine whether or not the file is a 
        /// Blue Cross Blue Shield report (type 2).
        /// </summary>
        /// <param name="fileText">
        /// Memory array of the file data
        /// </param>
        /// <returns>
        /// True if the stream is a BCBS report, else false
        /// </returns>
        private bool BCBS2Report(byte[] fileText)
        {
            string fileLine;
            // Create new memory stream
            MemoryStream ms = new MemoryStream(fileText);
            // Read to find distinctive marks
            using (StreamReader sr = new StreamReader(ms))
            {
                while ((fileLine = sr.ReadLine()) != null)
                {
                    if (fileLine.ToUpper().IndexOf("BLUE CROSS BLUE SHIELD OF GA") != -1)
                    {
                        // Search for headers
                        while ((fileLine = sr.ReadLine()) != null)
                        {
                            if (fileLine.ToUpper().IndexOf("VOLUME") != -1 && fileLine.ToUpper().IndexOf("BIN") != -1)
                            {
                                if (fileLine.ToUpper().IndexOf("CREATING") != -1 && fileLine.ToUpper().IndexOf("EXPIRATION") != -1)
                                {
                                    // Skip a line
                                    sr.ReadLine();
                                    // Next line should contain only hyphens
                                    if ((fileLine = sr.ReadLine()).Replace("-", String.Empty).Trim().Length == 0)
                                    {
                                        return true;
                                    }
                                }
                            }
                        }
                    }
                }
                // Conclude that this is not a BCBS1 report
                return false;
            }
        }

        /// <summary>
        /// Tests the file to determine whether or not the file is an
        /// BLLIB report file.
        /// </summary>
        /// <param name="fileText">
        /// Memory array of the file data
        /// </param>
        /// <returns>
        /// True if the stream is a BLLIB report, else false
        /// </returns>
        private bool BLLIBReport(byte[] fileText)
        {
            string fileLine;
            // Create new memory stream
            MemoryStream ms = new MemoryStream(fileText);
            // Read to find distinctive marks
            using (StreamReader sr = new StreamReader(ms))
            {
                while ((fileLine = sr.ReadLine()) != null)
                {
                    if (fileLine.Trim().Length != 0)
                    {
                        if (fileLine.Trim() == "BLLIB")
                            return true;
                        else
                            return false;
                    }
                }
            }
            // Conclude that this is not a BLLIB report
            return false;
        }

        /// <summary>
        /// Tests the file to determine whether or not the file is a 
        /// BMC report file.
        /// </summary>
        /// <param name="fileText">
        /// Memory array of the file data
        /// </param>
        /// <returns>
        /// True if the stream is a BMC report, else false
        /// </returns>
        private bool BMCReport(byte[] fileText)
        {
            string fileLine;
            // Create new memory stream
            MemoryStream ms = new MemoryStream(fileText);
            // Read to find distinctive marks
            using (StreamReader sr = new StreamReader(ms))
            {
                while ((fileLine = sr.ReadLine()) != null)
                {
                    if (fileLine.ToUpper().IndexOf("1BMC SOFTWARE, INC.") == 0)
                    {
                        if (fileLine.IndexOf("CONTROL-T") != -1)
                        {
                            return true;
                        }
                    }
                }
                return false;
            }
        }
        /// <summary>
        /// Tests the file to determine whether or not the file is an BrightStor report file.
        /// </summary>
        /// <param name="fileText">
        /// Memory array of the file data
        /// </param>
        /// <returns>
        /// True if the stream is a BrightStor report, else false
        /// </returns>
        private bool BrightStorReport(byte[] fileText)
        {
            int i1 = 0;
            string x1 = null;
            string s1 = "VOLUMES TO BE MOVED";
            // Create new memory stream
            MemoryStream ms = new MemoryStream(fileText);
            // Read to find distinctive marks
            using (StreamReader r = new StreamReader(ms))
            {
                x1 = r.ReadToEnd();
            }
            // Check
            if ((i1 = x1.IndexOf(s1)) == -1)
            {
                return false;
            }
            else
            {
                return x1.Substring(i1 + s1.Length).Trim().Substring(0,7) == "TLMS042";
            }
        }
        /// <summary>
		/// Tests the file to determine whether or not the file is a 
		/// CA25 report file.
		/// </summary>
		/// <param name="fileText">
		/// Memory array of the file data
		/// </param>
		/// <returns>
		/// True if the stream is a CA25 report, else false
		/// </returns>
		private bool CA25Report(byte[] fileText)
		{
			// Create new memory stream
			MemoryStream ms = new MemoryStream(fileText);
			// Read to find distinctive marks
			using (StreamReader sr = new StreamReader(ms))
			{
				string fileLine;
				// If we don't find something in the first 20 lines, we can
				// conclude that this is not a CA25 report.
				while ((fileLine = sr.ReadLine()) != null)
				{
                    if (fileLine.Trim().IndexOf("TMS REPORT-25") == 0)
					{
						return true;
					}
				}
				// Conclude that this is not a CA25 report
				return false;
			}
		}

		/// <summary>
		/// Tests the file to determine whether or not the file is a 
		/// CA25 report file.
		/// </summary>
		/// <param name="fileText">
		/// Memory array of the file data
		/// </param>
		/// <returns>
		/// True if the stream is a CA25 report, else false
		/// </returns>
		private bool CA25Report_Quebec(byte[] fileText)
		{
			string x1;
			// Create new memory stream
			MemoryStream ms = new MemoryStream(fileText);
			// Read to find distinctive marks
			using (StreamReader r = new StreamReader(ms))
			{
				while ((x1 = r.ReadLine()) != null)
				{
					if (x1.IndexOf('-') != -1 && String.Empty == x1.Trim().Replace("-",String.Empty))
					{
						return (r.ReadLine().Trim() == "VOLSER");	// next line must be only VOLSER
					}
				}
			}
			// Blah
			return false;
		}

        /// <summary>
        /// Tests the file to determine whether or not the file is a 
        /// Canada Defense report.
        /// </summary>
        /// <param name="fileText">
        /// Memory array of the file data
        /// </param>
        /// <returns>
        /// True if the stream is a Canada Defense report, else false
        /// </returns>
        private bool CanadaDefenseReport(byte[] fileText)
        {
            string fileLine;
            // Create new memory stream
            MemoryStream ms = new MemoryStream(fileText);
            // Read to find distinctive marks
            using (StreamReader r = new StreamReader(ms))
            {
                // Read the first line
                fileLine = r.ReadLine().ToUpper().Trim();
                // Pick or retrieve
                if ((fileLine.StartsWith("R E T R I E V E") || fileLine.StartsWith("P I C K")) && fileLine.IndexOf("RECALL") != -1)
                {
                    // Next line should be only equal signs
                    if (0 == r.ReadLine().Replace("=","").Trim().Length)
                    {
                        return true;
                    }
                }
            }
            // Conclude that this is not a Canada Defense report
            return false;
        }

        /// <summary>
        /// Tests the file to determine whether or not the file is a 
        /// Canadian Tire report.
        /// </summary>
        /// <param name="fileText">
        /// Memory array of the file data
        /// </param>
        /// <returns>
        /// True if the stream is a Canadian Tire report, else false
        /// </returns>
        private bool CanadianTireReport(byte[] fileText)
        {
            string fileLine;
            // Create new memory stream
            MemoryStream ms = new MemoryStream(fileText);
            // Read to find distinctive marks
            using (StreamReader sr = new StreamReader(ms))
                while ((fileLine = sr.ReadLine()) != null)
                    if (fileLine.ToUpper().IndexOf("CANADIAN TIRE PICK") != -1 || fileLine.ToUpper().IndexOf("CANADIAN TIRE RETURN") != -1)
                        return true;
            // Conclude that this is not a Coke report
            return false;
        }

        /// <summary>
        /// Tests the file to determine whether or not the file is a 
        /// Canadian Tire report.
        /// </summary>
        /// <param name="fileText">
        /// Memory array of the file data
        /// </param>
        /// <returns>
        /// True if the stream is a Canadian Tire report, else false
        /// </returns>
        private bool CanadianTire2Report(byte[] fileText)
        {
            string x1;
            // Create new memory stream
            MemoryStream ms = new MemoryStream(fileText);
            // Read to find distinctive marks
            using (StreamReader r = new StreamReader(ms))
            {
                while ((x1 = r.ReadLine()) != null)
                {
                    if (x1.ToUpper().IndexOf("CANADIAN TIRE FINANCIAL") != -1)
                    {
                        return true;
                    }
                }
            }
            // Conclude that this is not a Coke report
            return false;
        }

        /// <summary>
        /// Tests the file to determine whether or not the file is a CBS report file.
        /// </summary>
        /// <param name="fileText">
        /// Memory array of the file data
        /// </param>
        /// <returns>
        /// True if the stream is a CBS report, else false
        /// </returns>
        private bool CBSReport(byte[] fileText)
        {
            string fileLine;
            // Create new memory stream
            MemoryStream ms = new MemoryStream(fileText);
            // Read to find distinctive marks
            using (StreamReader sr = new StreamReader(ms))
            {
                while ((fileLine = sr.ReadLine()) != null)
                {
                    if (fileLine.Trim().ToUpper().StartsWith("ACCOUNT #7710"))
                    {
                        return true;
                    }
                }
            }
            // Not a CBS report
            return false;
        }

		/// <summary>
		/// Tests the file to determine whether or not the file is a CBS2 report file.
		/// </summary>
		/// <param name="fileText">
		/// Memory array of the file data
		/// </param>
		/// <returns>
		/// True if the stream is a CBS2 report, else false
		/// </returns>
		private bool CBS2Report(byte[] t1)
		{
			string s1;
			// Create new memory stream
			MemoryStream ms = new MemoryStream(t1);
			// Read stream
			using (StreamReader r = new StreamReader(ms)) {s1 = r.ReadToEnd();}
			// Distinct?
			if (s1.IndexOf("CBS") != -1 && s1.IndexOf("LibName") != -1)
			{
				return true;
			}
			else
			{
				return false;
			}
		}
		
		/// <summary>
        /// Tests the file to determine whether or not the file is a CGI file
        /// </summary>
        /// <param name="fileText">
        /// Memory array of the file data
        /// </param>
        /// <returns>
        /// True if the stream is a CGI report, else false
        /// </returns>
        private bool CGI1Report(byte[] fileText)
        {
            string fileLine;
            // Create new memory stream
            MemoryStream ms = new MemoryStream(fileText);
            // Read to find distinctive marks
            using (StreamReader sr = new StreamReader(ms))
            {
                while ((fileLine = sr.ReadLine()) != null)
                {
                    if ((fileLine = fileLine.ToUpper().Trim()) != String.Empty)
                    {
                        if (fileLine.IndexOf("CGI OFFSITE REPORT") != -1)
                        {
                            return true;
                        }
                        else
                        {
                            return false;
                        }
                    }
                }
            }
            // Conclude that this is not an CGI1 report
            return false;
        }

        /// <summary>
        /// Tests the file to determine whether or not the file is a CGI file
        /// </summary>
        /// <param name="fileText">
        /// Memory array of the file data
        /// </param>
        /// <returns>
        /// True if the stream is a CG2 report, else false
        /// </returns>
        private bool CGI2Report(byte[] fileText)
        {
            string fileLine;
            // Create new memory stream
            MemoryStream ms = new MemoryStream(fileText);
            // Read to find distinctive marks
            using (StreamReader r = new StreamReader(ms))
            {
                if ((fileLine = r.ReadLine().ToUpper()).IndexOf("CGI MONTREAL") != -1)
                {
                    if (fileLine.IndexOf("JOBNAME:") != -1)
                    {
                        if (fileLine.IndexOf("DATE:") != -1)
                        {
                            // Trim the line at DATE:
                            fileLine = fileLine.Substring(0, fileLine.IndexOf("DATE:") - 1).Trim();
                            // Look for a valid list type
                            if (fileLine[fileLine.Length-1] == 'R')         // R - receiving
                            {
                                return true;
                            }
                            else if (fileLine[fileLine.Length-1] == 'E')    // E - shipping
                            {
                                return true;
                            }
                        }
                    }
                }
            }
            // Conclude that this is not an CGI2 report
            return false;
        }

        /// <summary>
        /// Tests the file to determine whether or not the file is a CGI file
        /// </summary>
        /// <param name="fileText">
        /// Memory array of the file data
        /// </param>
        /// <returns>
        /// True if the stream is a CGI3 report, else false
        /// </returns>
        private bool CGI3Report(byte[] x1)
        {
            string s1;
            // Read to find distinctive marks
            using (StreamReader r1 = new StreamReader(new MemoryStream(x1)))
            {
                if ((s1 = r1.ReadLine().ToUpper()).IndexOf("CGI MONTREAL") != -1)
                {
                    for (int i = 0; i < 5; i += 1)
                    {
                        if ((s1 = r1.ReadLine()) == null)
                        {
                            return false;
                        }
                        else if (s1.IndexOf("RUBANS A FAIRE REVENIR DE LA VOUTE") != -1)
                        {
                            return true;
                        }
                    }
                }
            }
            // nope
            return false;
        }

        /// <summary>
        /// Tests the file to determine whether or not the file is a 
        /// Coke report.
        /// </summary>
        /// <param name="fileText">
        /// Memory array of the file data
        /// </param>
        /// <returns>
        /// True if the stream is a Coke report, else false
        /// </returns>
        private bool CokeReport(byte[] fileText)
        {
            string fileLine;
            // Create new memory stream
            MemoryStream ms = new MemoryStream(fileText);
            // Read to find distinctive marks
            using (StreamReader sr = new StreamReader(ms))
            {
                while ((fileLine = sr.ReadLine()) != null)
                {
                    if (fileLine.Replace("=", String.Empty).Trim().Length == 0)
                    {
                        try
                        {
                            DateTime.ParseExact(sr.ReadLine().Trim(), "MM/dd/yy HH:mm:ss", null);
                        }
                        catch
                        {
                            continue;
                        }
                        // Skip a line
                        sr.ReadLine();
                        // Next line should contain List type header, followed by line of equal symbols
                        if ((fileLine = sr.ReadLine().ToUpper()).IndexOf("PICKING LIST FOR VAULT") != -1 || fileLine.IndexOf("DISTRIBUTION LIST FOR VAULT") != -1)
                        {
                            if (sr.ReadLine().Replace("=", String.Empty).Trim().Length == 0)
                            {
                                return true;
                            }
                        }
                    }
                }
                // Conclude that this is not a Coke report
                return false;
            }
        }

        /// <summary>
        /// Tests the file to determine whether or not the file is a 
        /// Conseco report.
        /// </summary>
        /// <param name="fileText">
        /// Memory array of the file data
        /// </param>
        /// <returns>
        /// True if the stream is a Conseco report, else false
        /// </returns>
        private bool Conseco1Report(byte[] fileText)
        {
            string fileLine;
            // Create new memory stream
            MemoryStream ms = new MemoryStream(fileText);
            // Read to find distinctive marks
            using (StreamReader sr = new StreamReader(ms))
                while ((fileLine = sr.ReadLine()) != null)
                    if (fileLine.ToUpper().Trim().IndexOf("FROM LOCATION:") == 0)
                        if ((fileLine = NextNonBlankLine(sr)) != null)
                            if (fileLine.ToUpper().Trim().IndexOf("DATE . .") == 0)
                                if ((fileLine = NextNonBlankLine(sr, true)) != null)
                                    return fileLine.IndexOf("VOLUME") != -1 && fileLine.IndexOf("FROM CTN") != -1 && fileLine.IndexOf("TO CTN") != -1;
            // Conclude that this is not a Conseco report
            return false;
        }

        /// <summary>
        /// Tests the file to determine whether or not the file is a 
        /// Conseco2 report.
        /// </summary>
        /// <param name="fileText">
        /// Memory array of the file data
        /// </param>
        /// <returns>
        /// True if the stream is a Conseco report, else false
        /// </returns>
        private bool Conseco2Report(byte[] fileText)
        {
            string fileLine;
            // Create new memory stream
            MemoryStream ms = new MemoryStream(fileText);
            // Read to find distinctive marks
            using (StreamReader sr = new StreamReader(ms))
            {
                while ((fileLine = sr.ReadLine()) != null)
                {
                    if (fileLine.ToUpper().Trim().IndexOf("C O N S E C O , I N C") != -1)
                    {
                        fileLine = sr.ReadLine().ToUpper();
                        if (fileLine.IndexOf("MOVEMENT") != -1 && fileLine.IndexOf("LOCATION") != -1)
                        {
                            fileLine = sr.ReadLine().ToUpper();
                            fileLine = sr.ReadLine().ToUpper();
                            if (fileLine.IndexOf("VOLSER") != -1 && fileLine.IndexOf("DATASET NAME") != -1)
                            {
                                return true;
                            }
                        }
                    }
                }
                // Conclude that this is not a Conseco2 report
                return false;
            }
        }

        /// <summary>
        /// Tests the file to determine whether or not the file is a 
        /// Conseco3 report.
        /// </summary>
        /// <param name="fileText">
        /// Memory array of the file data
        /// </param>
        /// <returns>
        /// True if the stream is a Conseco report, else false
        /// </returns>
        private bool Conseco3Report(byte[] fileText)
        {
            string fileLine;
            // Create new memory stream
            MemoryStream ms = new MemoryStream(fileText);
            // Read to find distinctive marks
            using (StreamReader r = new StreamReader(ms))
            {
                while ((fileLine = r.ReadLine()) != null)
                {
                    if (fileLine.Trim() == String.Empty)
                    {
                        ;
                    }
                    else if (fileLine.ToUpper().Trim().IndexOf("VOLUME MOVEMENT REPORT") != -1)
                    {
                        // Get second line
                        fileLine = r.ReadLine();
                        fileLine = r.ReadLine().ToUpper();
                        // Look for first line headers
                        if (fileLine.IndexOf("VOLUME") != -1)
                        {
                            if (fileLine.IndexOf("PEND") != -1)
                            {
                                if (fileLine.IndexOf("EXPIRATION") != -1)
                                {
                                    if (fileLine.IndexOf("CURRENT") != -1)
                                    {
                                        return fileLine.IndexOf("-- CONTAINER --") != -1;
                                    }
                                }
                            }
                        }
                        // Return
                        return false;
                    }
                }
            }
            // Conclude that this is not a Conseco3 report
            return false;
        }

        /// <summary>
        /// Tests the file to determine whether or not the file is a 
        /// Conseco4 report.
        /// </summary>
        /// <param name="fileText">
        /// Memory array of the file data
        /// </param>
        /// <returns>
        /// True if the stream is a Conseco report, else false
        /// </returns>
        private bool Conseco4Report(byte[] fileText)
        {
            string fileLine;
            // Create new memory stream
            MemoryStream ms = new MemoryStream(fileText);
            // Read to find distinctive marks
            using (StreamReader sr = new StreamReader(ms))
            {
                while ((fileLine = sr.ReadLine()) != null)
                {
                    if (fileLine.ToUpper().IndexOf("CONSECO VAULT REPORTS") != -1)
                    {
                        return true;
                    }
                }
                // Conclude that this is not a Conseco2 report
                return false;
            }
        }

        /// <summary>
        /// Tests the file to determine whether or not the file is a
        /// Countrywide report file.
        /// </summary>
        /// <param name="fileText">
        /// Memory array of the file data
        /// </param>
        /// <returns>
        /// True if the stream is a Countrywide report, else false
        /// </returns>
        private bool Countrywide1Report(byte[] fileText)
        {
            bool b = false;
            string fileLine;
            // Create new memory stream
            MemoryStream ms = new MemoryStream(fileText);
            // Read to find distinctive marks
            using (StreamReader sr = new StreamReader(ms))
            {
                while ((fileLine = sr.ReadLine()) != null)
                {
                    if (!b && fileLine.ToUpper().IndexOf("COUNTRYWIDE") != -1 && fileLine.IndexOf(',') == -1)
                    {
                        b = true;
                    }
                    else if (b && fileLine.ToUpper().IndexOf("MEDIA ID") != -1)
                    {
                        if (fileLine.ToUpper().IndexOf("RETURN ON") != -1 || fileLine.ToUpper().IndexOf("RETUN ON") != -1)
                        {
                            return true;
                        }
                        else
                        {
                            break;
                        }
                    }
                }
            }
            // Conclude that this is not a Countrywide report
            return false;
        }

        /// <summary>
        /// Tests the file to determine whether or not the file is a
        /// Countrywide2 report file.
        /// </summary>
        /// <param name="fileText">
        /// Memory array of the file data
        /// </param>
        /// <returns>
        /// True if the stream is a Countrywide2 report, else false
        /// </returns>
        private bool Countrywide2Report(byte[] fileText)
        {
            bool b = false;
            string fileLine;
            // Create new memory stream
            MemoryStream ms = new MemoryStream(fileText);
            // Read to find distinctive marks
            using (StreamReader sr = new StreamReader(ms))
            {
                while ((fileLine = sr.ReadLine()) != null)
                {
                    if (fileLine.Trim().Length != 0)
                    {
                        if (b == false && fileLine.Trim().ToUpper().IndexOf("COUNTRYWIDE") == 0)
                        {
                            b = true;
                        }
                        else if (b == true)
                        {
                            if (fileLine.ToUpper().Replace(", ",",").IndexOf("MEDIA ID,NOTES,RETURN") != -1)
                            {
                                return true;
                            }
                        }
                    }
                }
            }
            // Conclude that this is not a Countrywide report
            return false;
        }

        /// <summary>
        /// Tests the file to determine whether or not the file is a
        /// Countrywide report file.
        /// </summary>
        /// <param name="fileText">
        /// Memory array of the file data
        /// </param>
        /// <returns>
        /// True if the stream is a Countrywide report, else false
        /// </returns>
        private bool Countrywide3Report(byte[] fileText)
        {
            bool b = false;
            string fileLine;
            // Create new memory stream
            MemoryStream ms = new MemoryStream(fileText);
            // Read to find distinctive marks
            using (StreamReader sr = new StreamReader(ms))
            {
                while ((fileLine = sr.ReadLine()) != null)
                {
                    if (!b && fileLine.ToUpper().IndexOf("COUNTRYWIDE") != -1)
                    {
                        b = true;
                    }
                    else if (b && fileLine.ToUpper().IndexOf("RECEIVING LIST") != -1)
                    {
                        return true;
                    }
                }
            }
            // Conclude that this is not a Countrywide report
            return false;
        }

		/// <summary>
		/// Tests the file to determine whether or not the file is a Coverall report file.
		/// </summary>
		/// <param name="fileText">
		/// Memory array of the file data
		/// </param>
		/// <returns>
		/// True if the stream is a Coverall report, else false
		/// </returns>
		private bool CoverallReport(byte[] b1)
		{
			using (StreamReader r1 = new StreamReader(new MemoryStream(b1)))
			{
				String s1 = r1.ReadLine().ToUpper();
				return s1.IndexOf("LIST FOR") != -1 && s1.IndexOf("COVER-ALL") != -1;
			}
		}
		
        /// <summary>
        /// Tests the file to determine whether or not the file is a Delta Dental report file.
        /// </summary>
        /// <param name="fileText">
        /// Memory array of the file data
        /// </param>
        private bool DeltaReport(byte[] fileText)
        {
            using (StreamReader r1 = new StreamReader(new MemoryStream(fileText)))
            {
                String s1 = r1.ReadToEnd();
                // Delta?
                return s1.IndexOf("DELTANET INC.") != -1;
            }
        }
        
        /// <summary>
        /// Tests the file to determine whether or not the file is a Exxon report file
        /// </summary>
        /// <param name="fileText">
        /// Memory array of the file data
        /// </param>
        /// <returns>
        /// True if the stream is a Exxon report, else false
        /// </returns>
        private bool Exxon1Report(byte[] fileText)
        {
            int x = 0;
            string fileLine;
            // Create new memory stream
            MemoryStream ms = new MemoryStream(fileText);
            // Read to find distinctive marks
            using (StreamReader sr = new StreamReader(ms))
            {
                while ((fileLine = sr.ReadLine()) != null)
                {
                    // Upper case the line
                    fileLine = fileLine.ToUpper();
                    // Run through the steps
                    switch (x)
                    {
                        case 0:
                            if (fileLine.IndexOf("REPORT OF") != -1 && fileLine.IndexOf("VAULT SESSION") != -1) x +=1;
                            break;
                        case 1:
                            if (fileLine.IndexOf("VENDOR:") != -1) x += 1;
                            break;
                        case 2:
                            if (fileLine.IndexOf("REPORT HEADER:") != -1) x += 1;
                            break;
                        case 3:
                            if (fileLine.IndexOf("REPORT TITLE:") != -1) x += 1;
                            return true;
                    }
                }
                // Conclude that this is not an Exxon report
                return false;
            }
        }

        /// <summary>
        /// Tests the file to determine whether or not the file is a Exxon report file
        /// </summary>
        /// <param name="fileText">
        /// Memory array of the file data
        /// </param>
        /// <returns>
        /// True if the stream is a Exxon report, else false
        /// </returns>
        private bool Exxon2Report(byte[] fileText)
        {
            string fileLine;
            bool b1 = false;
            // Create new memory stream
            MemoryStream ms = new MemoryStream(fileText);
            // Read to find distinctive marks
            using (StreamReader sr = new StreamReader(ms))
            {
                while ((fileLine = sr.ReadLine()) != null)
                {
                    fileLine = fileLine.Trim().ToUpper();

                    if (fileLine.IndexOf("EXXONMOBIL") != -1)
                    {
                        b1 = true;
                    }

                    if (fileLine.StartsWith("SUBJECT:"))
                    {
                        if (fileLine.EndsWith("PICKLIST") || fileLine.EndsWith("DISTRIBUTION"))
                        {
                            return b1;
                        }
                    }
                }
                // Conclude that this is not an Exxon report
                return false;
            }
        }

        /// <summary>
        /// Tests the file to determine whether or not the file is a Exxon report file
        /// </summary>
        /// <param name="fileText">
        /// Memory array of the file data
        /// </param>
        /// <returns>
        /// True if the stream is a Exxon report, else false
        /// </returns>
        private bool Exxon3Report(byte[] fileText)
        {
            using (StreamReader r1 = new StreamReader(new MemoryStream(fileText)))
            {
                String s1 = r1.ReadToEnd().ToUpper();

                if (s1.IndexOf("EXXON HOUSTON SHIPPING LIST") != -1)
                {
                    return true;
                }
                else if (s1.IndexOf("EXXON HOUSTON RECEIVING LIST") != -1)
                {
                    return true;
                }
                else
                {
                    return false;
                }
            }
        }

        /// <summary>
        /// Tests the file to determine whether or not the file is a Farm Bureau report file
        /// </summary>
        /// <param name="fileText">
        /// Memory array of the file data
        /// </param>
        /// <returns>
        /// True if the stream is a Farm Bureau report, else false
        /// </returns>
        private bool FarmBureauReport(byte[] fileText)
        {
            using (StreamReader r1 = new StreamReader(new MemoryStream(fileText)))
            {
                String s1 = null;

                while ((s1 = r1.ReadLine()) != null)
                {
                    if (s1.Trim().Length != 0)
                    {
                        return s1.Trim().StartsWith("#1015 ");
                    }
                }

                return false;
            }
        }

        /// <summary>
        /// Tests the file to determine whether or not the file is a Fox report file
        /// </summary>
        /// <param name="fileText">
        /// Memory array of the file data
        /// </param>
        /// <returns>
        /// True if the stream is a Fox report, else false
        /// </returns>
        private bool Fox1Report(byte[] fileText)
        {
            string fileLine;
            // Create new memory stream
            MemoryStream ms = new MemoryStream(fileText);
            // Read to find distinctive marks
            using (StreamReader sr = new StreamReader(ms))
                while ((fileLine = sr.ReadLine()) != null)
                    if (fileLine.Trim().ToUpper() == "FOX")
                        if (sr.ReadLine().ToUpper().IndexOf("VOLUMES TO BE RECALLED") != -1)
                            if (sr.ReadLine().ToUpper().IndexOf("LXI") != -1)
                                if (sr.ReadLine().ToUpper().IndexOf("VOLID") != -1)
                                    return true;
            // Not a Fox report
            return false;
        }

        /// <summary>
        /// Tests the file to determine whether or not the file is a Fox report file
        /// </summary>
        /// <param name="fileText">
        /// Memory array of the file data
        /// </param>
        /// <returns>
        /// True if the stream is a Fox report, else false
        /// </returns>
        private bool Fox2Report(byte[] fileText)
        {
            // Create new memory stream
            MemoryStream ms = new MemoryStream(fileText);
            // Read to find distinctive marks
            using (StreamReader r = new StreamReader(ms))
            {
                string x = r.ReadLine().ToUpper();
                // Should contain items in quotes...this is an excel spreadsheet
                if (x.IndexOf("VOLID") != -1 && x.IndexOf("SYSTEM") != -1 && x.IndexOf("LABEL") != -1 && x.IndexOf("EXPIRE") != -1 && x.IndexOf("LOCATION") != -1)
                {
                    return true;
                }
                else
                {
                    return false;
                }
            }
        }

        /// <summary>
        /// Tests the file to determine whether or not the file is a Galaxy report file
        /// </summary>
        /// <param name="fileText">
        /// Memory array of the file data
        /// </param>
        /// <returns>
        /// True if the stream is a Galaxy report, else false
        /// </returns>
        private bool GalaxyReport(byte[] fileText)
        {
            using (StreamReader r1 = new StreamReader(new MemoryStream(fileText)))
            {
                bool b1 = false;
                String s1 = r1.ReadLine().ToUpper();
                // If not correct title, just return false
                if (s1.IndexOf("DATA AGING JOB SUMMARY REPORT") == -1) return false;
                // Read the rest of it
                while ((s1 = r1.ReadLine()) != null)
                {
                    if (!b1 && s1.ToUpper().IndexOf("-- REPORT CRITERIA --") != -1)
                    {
                        b1 = true;
                    }
                    else if (b1 && s1.ToUpper().IndexOf("MEDIA RECYCLED") != -1)
                    {
                        return true;
                    }
                }
            }
            // Return
            return false;
        }
        
        /// <summary>
		/// Tests the file to determine whether or not the file is a Fox report file
		/// </summary>
		/// <param name="fileText">
		/// Memory array of the file data
		/// </param>
		/// <returns>
		/// True if the stream is a Fox report, else false
		/// </returns>
		private bool Fox3Report(byte[] fileText)
		{
			// Create new memory stream
			MemoryStream ms = new MemoryStream(fileText);
			// Read to find distinctive marks
			using (StreamReader r = new StreamReader(ms))
			{
				return r.ReadLine().ToUpper().IndexOf("NETB SCRATCH TAPE REQUEST") != -1;
			}
		}
		
		/// <summary>
        /// Tests the file to determine whether or not the file is an IBM report file.
        /// </summary>
        /// <param name="fileText">
        /// Memory array of the file data
        /// </param>
        /// <returns>
        /// True if the stream is a IBM report, else false
        /// </returns>
        private bool IBM1Report(byte[] fileText)
        {
            string fileLine;
            // Create new memory stream
            MemoryStream ms = new MemoryStream(fileText);
            // Read to find distinctive marks
            using (StreamReader r = new StreamReader(ms))
            {
                while ((fileLine = r.ReadLine()) != null)
                {
                    if ((fileLine = fileLine.ToUpper().Trim()) != String.Empty)
                    {
                        if (fileLine.StartsWith("BELL ") && (fileLine.EndsWith(" INCOMING") || fileLine.EndsWith(" OUTGOING")))
                        {
                            return true;
                        }
                        else
                        {
                            return false;
                        }
                    }
                }
            }
            // Conclude that this is not an IBM report
            return false;
        }

        /// <summary>
        /// Tests the file to determine whether or not the file is an IBM report file.
        /// </summary>
        /// <param name="fileText">
        /// Memory array of the file data
        /// </param>
        /// <returns>
        /// True if the stream is a IBM report, else false
        /// </returns>
        private bool IBM2Report(byte[] fileText)
        {
            string fileLine;
            int numberOfSpaces = 0;
            // Create new memory stream
            MemoryStream ms = new MemoryStream(fileText);
            // Read to find distinctive marks
            using (StreamReader r = new StreamReader(ms))
            {
                fileLine = r.ReadLine().ToUpper().Trim();
                // Line must start with "FROM "
                if (!fileLine.StartsWith("FROM "))
                {
                    return false;
                }
                // Must contain " TO "
                if (fileLine.IndexOf(" TO ") == -1)
                {
                    return false;
                }
                // Must only contain three whitespace characters
                for (int i = 0; i < fileLine.Length; i++)
                {
                    if (fileLine[i] == ' ')
                    {
                        numberOfSpaces += 1;
                    }
                }
                if (numberOfSpaces != 3)
                {
                    return false;
                }
                else
                {
                    return true;
                }
            }
        }

        /// <summary>
        /// Tests the file to determine whether or not the file is an
        /// Grumman report file.
        /// </summary>
        /// <param name="fileText">
        /// Memory array of the file data
        /// </param>
        /// <returns>
        /// True if the stream is a Grumman report, else false
        /// </returns>
        private bool GrummanReport(byte[] fileText)
        {
            // Create new memory stream
            MemoryStream ms = new MemoryStream(fileText);
            // Read to find distinctive marks
            using (StreamReader r = new StreamReader(ms))
            {
                string x = r.ReadToEnd();
                // Replace tabs with spaces
                while (x.IndexOf('\t') != -1)
                {
                    x = x.Replace('\t', ' ');
                }
                // Replace all the double spaces with singles
                while (x.IndexOf("  ") != -1)
                {
                    x = x.Replace("  ", " ");
                }
                // Search for the telltale headers
                if (x.ToLower().IndexOf("volume vl access expires") != -1)
                {
                    return true;
                }
            }
            // Conclude that this is not an ACS2 report
            return false;
        }

        /// <summary>
        /// Tests the file to determine whether or not the file is an Imation RFID file
        /// </summary>
        /// <param name="fileText">
        /// Memory array of the file data
        /// </param>
        /// <returns>
        /// True if the stream is an Imation RFID file, else false
        /// </returns>
        private bool ImationReport(byte[] fileText)
        {
            // Create new memory stream
            MemoryStream ms = new MemoryStream(fileText);
            // Read to find distinctive marks
            using (StreamReader sr = new StreamReader(ms))
                if (sr.ReadLine().ToUpper().Trim() == "VAULTLEDGER IMATION RFID ENCRYPTED XML DOCUMENT") 
                    return true;
            // Conclude that this is not an Imation report
            return false;
        }

        /// <summary>
        /// Tests the file to determine whether or not the file is a 
        /// Conseco3 report.
        /// </summary>
        /// <param name="fileText">
        /// Memory array of the file data
        /// </param>
        /// <returns>
        /// True if the stream is a Conseco report, else false
        /// </returns>
        private bool IndianaFarmReport(byte[] fileText)
        {
            using (StreamReader r1 = new StreamReader(new MemoryStream(fileText)))
            {
                String x1 = r1.ReadToEnd().ToUpper();
                // Result?
                return x1.IndexOf("VOLUME MOVEMENT REPORT") != -1 && x1.IndexOf("INDIANA FARM BUREAU") != -1;
            }
        }

        /// <summary>
        /// Tests the file to determine whether or not the file is a ING report file (no headers).
        /// </summary>
        /// <param name="fileText">
        /// Memory array of the file data
        /// </param>
        /// <returns>
        /// True if the stream is a Recall standard report, else false
        /// </returns>
        private bool INGReport(byte[] fileText, string fileName)
        {
            int i = -1;
            string fileLine = null;
            // Must be ReQuest Media Manager
            if (Configurator.ProductType != "RECALL") return false;
            // File name must start with 'pc' or 'rc'
            if (!fileName.ToUpper().StartsWith("PC") && !fileName.ToUpper().StartsWith("RC")) return false;
            // Create new memory stream
            MemoryStream ms = new MemoryStream(fileText);
            // Read to find distinctive marks
            using (StreamReader r = new StreamReader(ms))
            {
                // Read the first line
                fileLine = r.ReadLine().Trim();
                // Get rid of all the double spaces
                while (fileLine.IndexOf("  ") != -1) fileLine = fileLine.Replace("  ", " ");
                // Split into columns
                string[] x = fileLine.Split(new char[] {' '});
                // Get medium types and accounts
                AccountCollection a1 = AccountFactory.Create().GetAccounts();
                MediumTypeCollection t1 = MediumTypeFactory.Create().GetMediumTypes(false);
                // First column should match an account number
                for (i = 0; i < a1.Count; i += 1)
                    if (a1[i].Name == x[0]) break;
                // Test counter
                if (i == a1.Count) return false;
                // Second column should be two characters
                if (x[1].Length != 2) return false;
                // Second column should match the Recall code of a medium type
                for (i = 0; i < t1.Count; i += 1)
                    if (t1[i].RecallCode == x[1]) break;
                // Test counter
                if (i == t1.Count) return false;
                // It is an ING report
                return true;
            }
        }


        /// <summary>
        /// Tests the file to determine whether or not the file is a 
        /// Iron Mountain report (type 1).
        /// </summary>
        /// <param name="fileText">
        /// Memory array of the file data
        /// </param>
        /// <returns>
        /// True if the stream is an Iron Mountain report, else false
        /// </returns>
        private bool IronMountainReport(byte[] fileText)
        {
            string fileLine;
            // Create new memory stream
            MemoryStream ms = new MemoryStream(fileText);
            // Read to find distinctive marks
            using (StreamReader sr = new StreamReader(ms))
            {
                while ((fileLine = sr.ReadLine()) != null)
                {
                    if (fileLine.ToUpper().StartsWith("STARTHEADERTEXT~"))
                    {
                        if (fileLine.ToUpper().EndsWith("~ENDHEADERTEXT"))
                        {
                            return true;
                        }
                    }
                }
                // Conclude that this is not an Iron Mountain report
                return false;
            }
        }

        /// <summary>
        /// Tests the file to determine whether or not the file is a 
        /// LA Times report file.
        /// </summary>
        /// <param name="fileText">
        /// Memory array of the file data
        /// </param>
        /// <returns>
        /// True if the stream is a LA Times report, else false
        /// </returns>
        private bool LATimesReport(byte[] fileText)
        {
            // Create new memory stream
            MemoryStream ms = new MemoryStream(fileText);
            // Read to find distinctive marks
            using (StreamReader sr = new StreamReader(ms))
            {
                string fileLine;
                // Loop through the report
                while ((fileLine = sr.ReadLine()) != null)
                {
                    if (fileLine.IndexOf("L O S   A N G E L E S   T I M E S") != -1)
                    {
                        while ((fileLine = sr.ReadLine()) != null)
                        {
                            if (fileLine.Trim().IndexOf("TMS REPORT-25") != -1)
                            {
                                return true;
                            }
                        }
                    }
                }
            }
            // Conclude that this is not an LA Times report
            return false;
        }

        /// <summary>
        /// Tests the file to determine whether or not the file is an
        /// MBTA report file.
        /// </summary>
        /// <param name="fileText">
        /// Memory array of the file data
        /// </param>
        /// <returns>
        /// True if the stream is a CA25 report, else false
        /// </returns>
        private bool MassBayTransitReport(byte[] fileText)
        {
            // Create new memory stream
            MemoryStream ms = new MemoryStream(fileText);
            // Read to find distinctive marks
            using (StreamReader sr = new StreamReader(ms))
            {
                string fileLine;
                // If we don't find something in the first 20 lines, we can
                // conclude that this is not an MBTA report.
                for(int i = 0; i < 20; i++)
                {
                    if ((fileLine = sr.ReadLine()) == null)
                    {
                        break;
                    }
                    else if (fileLine.ToUpper().IndexOf("MASS BAY TRANSIT AUTHORITY") != -1)
                    {
                        // Distinctive enough so that no further distinctions necessary.
                        return true;
                    }
                }
                // Conclude that this is not an American Century report
                return false;
            }
        }

        /// <summary>
        /// Tests the file to determine whether or not the file is a McKesson file
        /// </summary>
        /// <param name="fileText">
        /// Memory array of the file data
        /// </param>
        /// <returns>
        /// True if the stream is an McKesson file, else false
        /// </returns>
        private bool McKessonReport(byte[] b1)
        {
            String s1 = null;

            using (StreamReader r1 = new StreamReader(new MemoryStream(b1)))
            {
                s1 = r1.ReadToEnd();
            }
            // Cool?
            if (s1.IndexOf("M C K E S S O N") == -1)
            {
                return false;
            }
            else if (s1.ToUpper().IndexOf("MOVEMENT REPORT BY VOLUME SERIAL NUMBER") == -1)
            {
                return false;
            }
            else
            {
                return true;
            }
        }

        /// <summary>
        /// Tests the file to determine whether or not the file is a McKesson 2 file
        /// </summary>
        /// <param name="fileText">
        /// Memory array of the file data
        /// </param>
        /// <returns>
        /// True if the stream is an McKesson 2 file, else false
        /// </returns>
        private bool McKesson2Report(byte[] b1)
        {
            String s1 = null;

            using (StreamReader r1 = new StreamReader(new MemoryStream(b1)))
            {
                while ((s1 = r1.ReadLine()) != null)
                {
                    if (s1.Trim().Length != 0)
                    {
                        break;
                    }
                }
            }
            // Cool?
            if (s1 != null)
            {
                s1 = s1.ToUpper().Replace(".", String.Empty);
                // Header correct?
                if (s1.IndexOf("MCKESSON CORP REC" ) != -1 || s1.IndexOf("MCKESSON CORP SHIP" ) != -1)
                {
                    return true;
                }
            }
            // Nope!
            return false;
        }

        /// <summary>
        /// Tests the file to determine whether or not the file is a
        /// Loews report file.
        /// </summary>
        /// <param name="fileText">
        /// Memory array of the file data
        /// </param>
        /// <returns>
        /// True if the stream is a Loews report, else false
        /// </returns>
        private bool LoewsReport(byte[] fileText)
        {
            string fileLine;
            // Create new memory stream
            MemoryStream ms = new MemoryStream(fileText);
            // Read to find distinctive marks
            using (StreamReader sr = new StreamReader(ms))
            {
                while ((fileLine = sr.ReadLine()) != null)
                {
                    if (fileLine.Trim().Length != 0)
                    {
                        if (fileLine.ToUpper().IndexOf("LOEWS CORPORATION") == -1)
                        {
                            break;
                        }
                        else if (fileLine.ToUpper().IndexOf("SHIPPING") == -1 && fileLine.ToUpper().IndexOf("RETRIEVAL") == -1)
                        {
                            break;
                        }
                        else
                        {
                            return true;
                        }
                    }
                }
            }
            // Conclude that this is not a Loews report
            return false;
        }

		/// <summary>
		/// Tests the file to determine whether or not the file is a Loto1 report file.
		/// </summary>
		/// <param name="fileText">
		/// Memory array of the file data
		/// </param>
		/// <returns>
		/// True if the stream is a ACS1 report, else false
		/// </returns>
		private bool Loto1Report(byte[] t1)
		{
			string s1;
			// Create new memory stream
			MemoryStream ms = new MemoryStream(t1);
			// Read to find distinctive marks
			using (StreamReader r = new StreamReader(ms))
			{
				while ((s1 = r.ReadLine()) != null)
				{
					if (s1.StartsWith("Liste des cassettes"))
					{
						s1 = r.ReadLine();
						s1 = r.ReadLine();
						// Final check
						if (s1.StartsWith("MEDID"))
						{
							return true;
						}
						else
						{
							break;
						}
					}
				}
			}
			// Conclude that this is not an ACS1 report
			return false;
		}
		
		/// <summary>
		/// Tests the file to determine whether or not the file is a Loto2 report file.
		/// </summary>
		/// <param name="fileText">
		/// Memory array of the file data
		/// </param>
		/// <returns>
		/// True if the stream is a ACS1 report, else false
		/// </returns>
		private bool Loto2Report(byte[] t1)
		{
			string s1;
			// Create new memory stream
			MemoryStream ms = new MemoryStream(t1);
			// Read to find distinctive marks
			using (StreamReader r = new StreamReader(ms))
			{
				while ((s1 = r.ReadLine()) != null)
				{
					if (s1.ToUpper().IndexOf("OFFSITE TAPELIST FOR MASTER")  != -1)
					{
						// Read next two lines
						s1 = r.ReadLine();
						s1 = r.ReadLine();
						// Final check
						if (s1.ToUpper().IndexOf("LIST OF TAPE WITH") != -1)
						{
							return true;
						}
						else
						{
							break;
						}
					}
				}
			}
			// Nope
			return false;
		}

		/// <summary>
        /// Tests the file to determine whether or not the file is a
        /// McDonald's report file.
        /// </summary>
        /// <param name="fileText">
        /// Memory array of the file data
        /// </param>
        /// <returns>
        /// True if the stream is a McDonald's report, else false
        /// </returns>
        private bool McDonaldsReport(byte[] fileText)
        {
            string fileLine;
            // Create new memory stream
            MemoryStream ms = new MemoryStream(fileText);
            // Read to find distinctive marks
            using (StreamReader sr = new StreamReader(ms))
            {
                while ((fileLine = sr.ReadLine()) != null)
                {
                    if (fileLine.IndexOf("MCDONALDS CORPORATION") != -1)
                    {
                        return true;
                    }
                }
            }
            // Return
            return false;
        }

        /// <summary>
        /// Tests the file to determine whether or not the file is a NaviSite report file.
        /// </summary>
        /// <param name="fileText">
        /// Memory array of the file data
        /// </param>
        /// <returns>
        /// True if the stream is a McDonald's report, else false
        /// </returns>
        private bool NaviSiteReport(byte[] b1)
        {
            using (StreamReader r1 = new StreamReader(new MemoryStream(b1)))
            {
                String s1 = null;

                if ((s1 = r1.ReadLine()) != null && s1.ToUpper().IndexOf("NAVISITE") != -1)
                {
                    return true;
                }
                else
                {
                    return false;
                }
            }
        }

        private bool NavistarReport(byte[] fileText)
        {
            string fileLine;
            // Create new memory stream
            MemoryStream ms = new MemoryStream(fileText);
            // Read to find distinctive marks
            using (StreamReader sr = new StreamReader(ms))
            {
                while ((fileLine = sr.ReadLine()) != null)
                {
                    if ((fileLine = fileLine.ToUpper().Trim()) != String.Empty)
                    {
                        if (fileLine.IndexOf("SUBJECT:") != -1)
                        {
                            return fileLine.IndexOf("NAVISTAR/") != -1;
                        }
                    }
                }
            }
            // Conclude that this is not an Navistar report
            return false;
        }

        private bool Navistar2Report(byte[] fileText)
        {
            // Create new memory stream
            MemoryStream ms = new MemoryStream(fileText);
            // Read to find distinctive marks
            using (StreamReader sr = new StreamReader(ms))
            {
                String s = sr.ReadToEnd();
                if (s.ToUpper().Contains("NAVISTAR"))
                    if (s.ToUpper().Contains("VOLSER"))
                        if (s.ToUpper().Contains("FINAL TOTALS"))
                            return true;
            }
            // Conclude that this is not an Navistar report
            return false;
        }

        /// <summary>
		/// Tests the file to determine whether or not the file is an State of New Jersey report file.
		/// </summary>
		/// <param name="fileText">
		/// Memory array of the file data
		/// </param>
		/// <returns>
		/// True if the stream is a State of New Jersey report, else false
		/// </returns>
		private bool NJStateReport(byte[] fileText)
		{
			string fileLine = null;
			// Read to find distinctive marks
			using (StreamReader r = new StreamReader(new MemoryStream(fileText)))
			{
				// First line should contain company name
				if ((fileLine = r.ReadLine()) != null)
				{
					if ((fileLine = fileLine.ToUpper()).IndexOf("NEW JERSEY") != -1 && fileLine.IndexOf("MOVEMENT REPORT") != -1)
					{
						return true;
					}
				}
				// Nope
				return false;
			}
		}
		
		/// <summary>
        /// Tests the file to determine whether or not the file is a
        /// New York Life report file.
        /// </summary>
        /// <param name="fileText">
        /// Memory array of the file data
        /// </param>
        /// <returns>
        /// True if the stream is a New York Life pick report, else false
        /// </returns>
        private bool NYLifeReport(byte[] fileText)
        {
            string fileLine;
            // Create new memory stream
            MemoryStream ms = new MemoryStream(fileText);
            // Read to find distinctive marks
            using (StreamReader sr = new StreamReader(ms))
            {
                while ((fileLine = sr.ReadLine()) != null)
                {
                    if (fileLine.ToUpper().IndexOf("OFFSITE REPORT FOR") != -1)
                    {
                        while ((fileLine = sr.ReadLine()) != null)
                        {
                            if (fileLine.IndexOf("List") != -1 && fileLine.IndexOf("RECALL") != -1)
                            {
                                // Same line must contain either INJECTS or EJECTS
                                if (fileLine.IndexOf("INJECTS") != -1 || fileLine.IndexOf("EJECTS") != -1)
                                {
                                    return true;
                                }
                            }
                        }
                    }
                }
                // Conclude that this is not a New York Life pick report
                return false;
            }
        }
        
        /// <summary>
        /// Tests the file to determine whether or not the file is a
        /// New York Life dist report file.
        /// </summary>
        /// <param name="fileText">
        /// Memory array of the file data
        /// </param>
        /// <returns>
        /// True if the stream is a New York Life dist report, else false
        /// </returns>
        /// <remarks>
        /// OBSOLETE: Always returns false
        /// </remarks>
        private bool NYLifeDistReport(byte[] fileText)
        {
            return false;
        }

        /// <summary>
        /// Tests the file to determine whether or not the file is a
        /// New York Life pick report file.
        /// </summary>
        /// <param name="fileText">
        /// Memory array of the file data
        /// </param>
        /// <returns>
        /// True if the stream is a New York Life pick report, else false
        /// </returns>
        /// <remarks>
        /// OBSOLETE: Always returns false
        /// </remarks>
        private bool NYLifePickReport(byte[] fileText)
        {
            return false;
        }

        /// <summary>
        /// Tests the file to determine whether or not the file is a PSECU report file.
        /// </summary>
        /// <param name="fileText">
        /// Memory array of the file data
        /// </param>
        /// <returns>
        /// True if the stream is a PSECU report, else false
        /// </returns>
        private bool PSECUReport(byte[] t1)
        {
            string s1;
            // Create new memory stream
            MemoryStream ms = new MemoryStream(t1);
            // Read stream
            using (StreamReader r = new StreamReader(ms)) {s1 = r.ReadToEnd().ToUpper();}
            // Distinct?
            if (s1.IndexOf("P.S.E.C.U") != -1 && s1.IndexOf("TIVOLI") != -1 && s1.IndexOf("LIBNAME") != -1)
            {
                return true;
            }
            else
            {
                return false;
            }
        }
		
        /// <summary>
        /// Tests the file to determine whether or not the file is of the correct report type
        /// </summary>
        /// <param name="fileText">
        /// Memory array of the file data
        /// </param>
        /// <returns>
        /// True if the stream is of the correct report type, else false
        /// </returns>
        private bool Ricoh1Report(byte[] fileText)
        {
            string s1;
            // Read to find distinctive marks
            using (StreamReader r1 = new StreamReader(new MemoryStream(fileText)))
            {
                s1 = r1.ReadToEnd();
            }
            // Yes?
            if (s1.IndexOf("IKON OFFICE SOLUTIONS") != -1 || s1.IndexOf("IKON DATA CENTER") != -1)
            {
                return true;
            }
            else if (s1.IndexOf("RICOH AMERICAS CORPORATION") != -1 || s1.IndexOf("RICOH AMERICAS CORPORTATION") != -1)
            {
                return true;
            }
            else
            {
                return false;
            }
        }

        /// <summary>
        /// Tests the file to determine whether or not the file is of the correct report type
        /// </summary>
        /// <param name="fileText">
        /// Memory array of the file data
        /// </param>
        /// <returns>
        /// True if the stream is of the correct report type, else false
        /// </returns>
        private bool Ricoh2Report(byte[] fileText)
        {
            string s1;
            // Read to find distinctive marks
            using (StreamReader r1 = new StreamReader(new MemoryStream(fileText)))
            {
                s1 = r1.ReadToEnd();
            }
            // Yes?
            if (s1.IndexOf("IKON CAPITAL TAPE REPORTING SYSTEM") != -1)
            {
                return true;
            }
            else if (s1.IndexOf("WELLS FARGO TAPE REPORTING SYSTEM") != -1)
            {
                return true;
            }
            else
            {
                return false;
            }
        }

        /// <summary>
        /// Tests the file to determine whether or not the file is of the correct report type
        /// </summary>
        /// <param name="fileText">
        /// Memory array of the file data
        /// </param>
        /// <returns>
        /// True if the stream is of the correct report type, else false
        /// </returns>
        private bool Ricoh3Report(byte[] fileText)
        {
            string s1;
            // Read to find distinctive marks
            using (StreamReader r1 = new StreamReader(new MemoryStream(fileText)))
            {
                if ((s1 = r1.ReadLine()) == null)
                    return false;

                if (s1.Replace("*", "").Trim() != "")
                    return false;

                if ((s1 = r1.ReadLine()) == null)
                    return false;

                if (s1.IndexOf("REI #") == -1)
                    return false;

                return true;

            }
        }

        /// <summary>
        /// Tests the file to determine whether or not the file is of the correct report type
        /// </summary>
        /// <param name="fileText">
        /// Memory array of the file data
        /// </param>
        /// <returns>
        /// True if the stream is of the correct report type, else false
        /// </returns>
        private bool Ricoh4Report(byte[] fileText)
        {
            string s1;
            // Read to find distinctive marks
            using (StreamReader r1 = new StreamReader(new MemoryStream(fileText)))
            {
                s1 = r1.ReadToEnd();
            }
            // Yes?
            if (s1.ToUpper().IndexOf("RICOH CANADA VAULT") != -1)
            {
                return true;
            }
            else
            {
                return false;
            }
        }

        /// <summary>
        /// Tests the file to determine whether or not the file is of the correct report type
        /// </summary>
        /// <param name="fileText">
        /// Memory array of the file data
        /// </param>
        /// <returns>
        /// True if the stream is of the correct report type, else false
        /// </returns>
        private bool Ricoh5Report(byte[] fileText)
        {
            string s1;
            // Read to find distinctive marks
            using (StreamReader r1 = new StreamReader(new MemoryStream(fileText)))
            {
                s1 = r1.ReadToEnd().ToUpper();
            }
            // Yes?
            if (s1.IndexOf("RICOH CANADA") != -1 && s1.IndexOf("RCBTSM VAULT RETRIEVAL REPORT") != -1)
                return true;
            else
                return false;
        }

        /// <summary>
        /// Tests the file to determine whether or not the file is of the correct report type
        /// </summary>
        /// <param name="fileText">
        /// Memory array of the file data
        /// </param>
        /// <returns>
        /// True if the stream is of the correct report type, else false
        /// </returns>
        private bool Ricoh6Report(byte[] fileText)
        {
            string s1;
            // Read to find distinctive marks
            using (StreamReader r1 = new StreamReader(new MemoryStream(fileText)))
            {
                s1 = r1.ReadToEnd().ToUpper();
            }
            // Yes?
            if (s1.IndexOf("RCBTSM - VOLUMES SENT TO OFF-SITE VAULT") != -1)
                return true;
            else
                return false;
        }

        /// <summary>
        /// Tests the file to determine whether or not the file is a 
        /// RMM3 report file.
        /// </summary>
        /// <param name="fileText">
        /// Memory array of the file data
        /// </param>
        /// <returns>
        /// True if the stream is a RMM3 report, else false
        /// </returns>
        private bool RMM3Report(byte[] fileText)
        {
            // Create new memory stream
            MemoryStream ms = new MemoryStream(fileText);
            // Read to find distinctive marks
            using (StreamReader sr = new StreamReader(ms))
            {
                string fileLine;
                // If we don't find something in the first 20 lines, we can
                // conclude that this is not a RMM3 report.
                for(int i = 0; i < 20; i++)
                {
                    if ((fileLine = sr.ReadLine()) == null)
                        break;
                    else if (fileLine.IndexOf("  Report 3 ") == 0)
                    {
                        // In either two or three more lines, we should see the headers
                        for (int j = 0; j < 3; j++)
                        {
                            fileLine = sr.ReadLine();
                            if (j != 0)
                            {
                                if (fileLine.Trim().IndexOf("SERIAL LOCATION BIN #") == 0)
                                {
                                    if (fileLine.IndexOf("D A T A S E T   N A M E") != -1)
                                    {
                                        return true;
                                    }
                                }
                            }

                        }
                    }
                }
                // Conclude that this is not a RMM3 report
                return false;
            }
        }

		/// <summary>
		/// Tests the file to determine whether or not the file is a Sanofi report file.
		/// </summary>
		/// <param name="fileText">
		/// Memory array of the file data
		/// </param>
		/// <returns>
		/// True if the stream is a Sanofi report, else false
		/// </returns>
		private bool SanofiReport(byte[] t1)
		{
			string s1;
			// Create new memory stream
			MemoryStream ms = new MemoryStream(t1);
			// Read to find distinctive marks
			using (StreamReader r = new StreamReader(ms))
			{
				return (s1 = r.ReadLine()) != null && s1.ToUpper().IndexOf("SANOFI-AVENTIS") != -1;
			}
		}

		/// <summary>
		/// Tests the file to determine whether or not the file is a Sanofi report file.
		/// </summary>
		/// <param name="fileText">
		/// Memory array of the file data
		/// </param>
		/// <returns>
		/// True if the stream is a Sanofi report, else false
		/// </returns>
		private bool Sanofi2Report(byte[] t1)
		{
			string s1;
			// Create new memory stream
			MemoryStream ms = new MemoryStream(t1);
			// Read stream
			using (StreamReader r = new StreamReader(ms)) {s1 = r.ReadToEnd().ToUpper();}
			// Distinct?
			if (s1.IndexOf("SANOFI-AVENTIS") != -1 && s1.IndexOf("AUTOMATED") != -1 && s1.IndexOf("LIBNAME") != -1)
			{
				return true;
			}
			else
			{
				return false;
			}
		}
		
		/// <summary>
		/// Tests the file to determine whether or not the file is a Sanofi report file.
		/// </summary>
		/// <param name="fileText">
		/// Memory array of the file data
		/// </param>
		/// <returns>
		/// True if the stream is a Sanofi report, else false
		/// </returns>
		private bool Sanofi3Report(byte[] t1)
		{
			string s1;
			// Create new memory stream
			MemoryStream m1 = new MemoryStream(t1);
			// Read to find distinctive marks
			using (StreamReader r = new StreamReader(m1))
			{
				return (s1 = r.ReadLine()) != null && s1.ToUpper().IndexOf("SANOFI RESTON") != -1;
			}
		}


		/// <summary>
        /// Tests the file to determine whether or not the file is a 
        /// Sprint report file.
        /// </summary>
        /// <param name="fileText">
        /// Memory array of the file data
        /// </param>
        /// <returns>
        /// True if the stream is a Sprint report, else false
        /// </returns>
        private bool SprintReport(byte[] fileText)
        {
            // Create new memory stream
            MemoryStream ms = new MemoryStream(fileText);
            // Read to find distinctive marks
            using (StreamReader sr = new StreamReader(ms))
            {
                string fileLine;
                // If we don't find something in the first 20 lines, we can
                // conclude that this is not a Sprint report.
                for (int i = 0; i < 20; i++)
                {
                    if ((fileLine = sr.ReadLine()) == null)
                    {
                        break;
                    }
                    else if (fileLine.IndexOf("Media Movement Report") != -1)
                    {
                        // Try next five lines
                        for (int j = 0; j < 5; j++)
                        {
                            if ((fileLine = sr.ReadLine()).IndexOf("From location . .") != -1 && fileLine.IndexOf("To location . .") != -1)
                            {
                                return true;
                            }
                        }
                        // Nope
                        return false;
                    }
                }
                // Conclude that this is not a Sprint report
                return false;
            }
        }

        /// <summary>
        /// Tests the file to determine whether or not the file is a 
        /// STAR-1100 report file.
        /// </summary>
        /// <param name="fileText">
        /// Memory array of the file data
        /// </param>
        /// <returns>
        /// True if the stream is a STAR-1100 report, else false
        /// </returns>
        private bool StarReport(byte[] fileText)
        {
            string fileLine;
            // Create new memory stream
            MemoryStream ms = new MemoryStream(fileText);
            // Read to find distinctive marks
            using (StreamReader sr = new StreamReader(ms))
            {
                while ((fileLine = sr.ReadLine()) != null)
                {
                    if (fileLine.IndexOf(" STAR-1100 VAULT MANAGEMENT SUBSYSTEM ") != -1)
                    {
                        while((fileLine = sr.ReadLine()) != null)
                        {
                            if (fileLine.IndexOf("QUALIFIER") != -1 && fileLine.IndexOf("FNAME") != -1)
                            {
                                return true;
                            }
                        }
                    }
                }
                // Conclude that this is not a STAR report
                return false;
            }
        }

        /// <summary>
        /// Tests the file to determine whether or not the file is a 
        /// Recall standard report file.
        /// </summary>
        /// <param name="fileText">
        /// Memory array of the file data
        /// </param>
        /// <returns>
        /// True if the stream is a Recall standard report, else false
        /// </returns>
        private bool Recall1Report(byte[] fileText)
        {
            if (Configurator.ProductType != "RECALL")
            {
                return false;
            }
            else
            {
                // Create new memory stream
                MemoryStream ms = new MemoryStream(fileText);
                // Read to find distinctive marks
                using (StreamReader sr = new StreamReader(ms))
                {
                    string fileLine;
                    // If we don't find something in the first 20 lines, we can
                    // conclude that this is not a Sprint report.
                    for(int i = 0; i < 20; i++)
                    {
                        if ((fileLine = sr.ReadLine()) == null)
                        {
                            break;
                        }
                        else if (fileLine.ToUpper().IndexOf("DESTINATION SITE:") != -1)
                        {
                            // Search for headers
                            while ((fileLine = sr.ReadLine()) != null)
                            {
                                // Headers must appear
                                if (fileLine.IndexOf("ACCT") != -1 && fileLine.IndexOf("TYPE") != -1)
                                {
                                    if (fileLine.IndexOf("DATA SET") != -1 &&  fileLine.IndexOf("SERIAL") != -1)
                                    {
                                        return true;
                                    }
                                }
                            }
                        }
                    }
                    // Conclude that this is not a standard Recall report
                    return false;
                }
            }
        }

        /// <summary>
        /// Tests the file to determine whether or not the file is a
        /// USA Group report file.
        /// </summary>
        /// <param name="fileText">
        /// Memory array of the file data
        /// </param>
        /// <returns>
        /// True if the stream is a Tivoli report, else false
        /// </returns>
        private bool TivoliReport(byte[] fileText)
        {
            // Create new memory stream
            MemoryStream ms = new MemoryStream(fileText);
            // Read to find distinctive marks
            using (StreamReader r = new StreamReader(ms))
            {
                // Read the entire content
                if (r.ReadToEnd().ToUpper().IndexOf("TSM OPERATIONAL REPORTING") != -1)
                {
                    return true;
                }
                else
                {
                    return false;
                }
            }
        }

        /// <summary>
        /// Tests the file to determine whether or not the file is a
        /// USA Group report file.
        /// </summary>
        /// <param name="fileText">
        /// Memory array of the file data
        /// </param>
        /// <returns>
        /// True if the stream is a USA Group report, else false
        /// </returns>
        private bool USAGroupReport(byte[] fileText)
        {
            string fileLine;
            // Create new memory stream
            MemoryStream ms = new MemoryStream(fileText);
            // Read to find distinctive marks
            using (StreamReader sr = new StreamReader(ms))
            {
                while ((fileLine = sr.ReadLine()) != null)
                {
                    if (fileLine.Replace("*",String.Empty).Trim().Length == 0)
                    {
                        // Get the next line
                        if ((fileLine = sr.ReadLine()) == null) 
                        {
                            break;
                        }
                        else
                        {
                            // Check for list type
                            if ((fileLine = fileLine.ToUpper()).IndexOf("SEND LIST") != -1 || fileLine.IndexOf("BRINGBACK LIST") != -1)
                            {
                                // Get the next line
                                if ((fileLine = sr.ReadLine()) == null) break;
                                // Check for asterisk-only line
                                if (fileLine.Replace("*",String.Empty).Trim().Length == 0)
                                    while ((fileLine = sr.ReadLine()) != null)
                                        if (fileLine.IndexOf("TAPE#") != -1)
                                            return true;
                            }
                        }
                    }
                }
            }
            // Conclude that this is not a USA Group report
            return false;
        }

        /// <summary>
        /// Tests the file to determine whether or not the file is a
        /// Veritas Vault report file.
        /// </summary>
        /// <param name="fileText">
        /// Memory array of the file data
        /// </param>
        /// <returns>
        /// True if the stream is a Veritas Vault report, else false
        /// </returns>
        private bool VeritasReport(byte[] fileText)
        {
            string fileLine;
            // Create new memory stream
            MemoryStream ms = new MemoryStream(fileText);
            // Read to find distinctive marks
            using (StreamReader sr = new StreamReader(ms))
            {
                while ((fileLine = sr.ReadLine()) != null)
                {
                    // Uppercase the line
                    fileLine = fileLine.ToUpper();
                    // Look for the recognized header
                    if (fileLine.IndexOf("ROBOT:") != -1 && fileLine.IndexOf("VAULT:") != -1 && fileLine.IndexOf("PROFILE:") != -1)
                    {
                        return true;
                    }
                }
            }
            // Not a Veritas Vault report
            return false;
        }

        /// <summary>
        /// Tests the file to determine whether or not the file is an
        /// Viacom report file.
        /// </summary>
        /// <param name="fileText">
        /// Memory array of the file data
        /// </param>
        /// <returns>
        /// True if the stream is a Viacom report, else false
        /// </returns>
        private bool ViacomReport(byte[] fileText)
        {
            string fileLine;
            // Create new memory stream
            MemoryStream ms = new MemoryStream(fileText);
            // Read to find distinctive marks
            using (StreamReader sr = new StreamReader(ms))
            {
                while ((fileLine = sr.ReadLine()) != null)
                {
                    if (fileLine.IndexOf("Date:") != -1)
                    {
                        // Skip line
                        sr.ReadLine();
                        // Next line should contain account
                        if (sr.ReadLine().IndexOf("Account:") != -1)
                        {
                            // Skip line
                            sr.ReadLine();
                            // Next line should contain return date header
                            if (sr.ReadLine().IndexOf("Return Date:") != -1)
                            {
                                return true;
                            }
                        }
                    }
                }
            }
            // Conclude that this is not an ACS1 report
            return false;
        }

        /// <summary>
        /// Tests the file to determine whether or not the file is a Videotron report file.
        /// </summary>
        /// <param name="fileText">
        /// Memory array of the file data
        /// </param>
        /// <returns>
        /// True if the stream is a Videotron report, else false
        /// </returns>
        private bool VideotronReport(byte[] fileText)
        {
            string f1;
            int b1 = 0;
            // Create new memory stream
            MemoryStream m1 = new MemoryStream(fileText);
            // Read to find distinctive marks
            using (StreamReader r1 = new StreamReader(m1))
            {
                while ((f1 = r1.ReadLine()) != null)
                {
                    if (b1 == 0 && (f1 = f1.ToUpper()).IndexOf("MOVEMENT REPORT BY VOLUME SERIAL") != -1)
                    {
                        b1 = 1;
                    }
                    else if (b1 == 1 && (f1 = f1.ToUpper()).IndexOf("TO DESTINATION / FROM LOCATION") != -1)
                    {
                        return true;
                    }
                }
            }
            // Conclude that this is not a Videotron report
            return false;
        }

        /// <summary>
        /// Tests the file to determine whether or not the file is a
        /// VTMS Connect report file.
        /// </summary>
        /// <param name="fileText">
        /// Memory array of the file data
        /// </param>
        /// <returns>
        /// True if the stream is a VTMS Connect report, else false
        /// </returns>
        private bool VTMSReport(byte[] fileText, string fileName)
        {
            int i = 0;
            string fileLine;
            string[] elements;
            int elementCount;
            char[] spaceChar = new char[] {' '};
            Regex codeRegex = new Regex("^[A-Z]{2}$");
            // Make sure we are using the Recall implementation
            if (Configurator.ProductType != "RECALL")
                return false;
            // Make sure the filename jives
            if (fileName.Length == 0)
            {
                return false;
            }
            else
            {
                switch (fileName.ToUpper()[0])
                {
                    case 'P':
                    case 'R':
                        break;
                    default:
                        return false;
                }
            }
            // Create new memory stream
            MemoryStream ms = new MemoryStream(fileText);
            // Read to find distinctive marks
            using (StreamReader sr = new StreamReader(ms))
            {
                while ((fileLine = sr.ReadLine()) != null && i < 5)
                {
                    if (fileLine.Trim().Length != 0)
                    {
                        elementCount = 0;
                        elements = fileLine.Split(spaceChar);
                        // Count the elements
                        for (int j = 0; j < elements.Length; j++)
                        {
                            if (elements[j].Length != 0)
                                if (++elementCount == 2)
                                    if (elements[j].Length != 2 || codeRegex.IsMatch(elements[j]) == false)
                                        return false;
                        }
                        // If we do not have exactly three elements, return false
                        if (elementCount != 3)
                            return false;
                        // Do this for at most five lines
                        i++;
                    }
                }
            }
            // It is a VTMS report
            return true;
        }

        /// <summary>
        /// Tests the file to determine whether or not the file is a 
        /// new send list file from the batch scanner.
        /// </summary>
        /// <param name="fileText">
        /// Memory array of the file data
        /// </param>
        /// <returns>
        /// True if the stream is a send list batch scanner file, else false
        /// </returns>
        private bool BatchNewSendList(byte[] fileText)
        {
            // Create new memory stream
            MemoryStream ms = new MemoryStream(fileText);
            // Read to find distinctive marks
            using (StreamReader r = new StreamReader(ms))
            {
                string fileLine;
                // If we don't find something in the first 3 lines, we can
                // conclude that this is not a VaultTrack batch send list.
                for(int i = 0; i < 3; i++)
                {
                    if ((fileLine = r.ReadLine()) == null)
                    {
                        break;
                    }
                    else if (IsBatchFile(fileLine))
                    {
                        return r.ReadLine().ToUpper().IndexOf("$SEND LIST - NEW") == 0;
                    }
                }
                // Conclude that this is not a VaultTrack batch send list
                return false;
            }
        }

        /// <summary>
        /// Tests the file to determine whether or not the file is a 
        /// new list compare file from the batch scanner.
        /// </summary>
        /// <param name="fileText">
        /// Memory array of the file data
        /// </param>
        /// <returns>
        /// True if the stream is a list compare batch scanner file, else false
        /// </returns>
        private bool BatchCompareFile(byte[] fileText)
        {
            // Create new memory stream
            MemoryStream ms = new MemoryStream(fileText);
            // Read to find distinctive marks
            using (StreamReader r = new StreamReader(ms))
            {
                string fileLine;
                // If we don't find something in the first 3 lines, we can
                // conclude that this is not a VaultTrack list compare file.
                for(int i = 0; i < 3; i++)
                {
                    if ((fileLine = r.ReadLine()) == null)
                    {
                        break;
                    }
                    else if (IsBatchFile(fileLine))
                    {
                        return r.ReadLine().ToUpper().IndexOf("$SEND/RECEIVE LIST - VERIFY") == 0;
                    }
                }
                // Conclude that this is not a VaultTrack list compare file
                return false;
            }
        }

        /// <summary>
        /// Tests the file to determine whether or not the file is a 
        /// receiving list file from the product.
        /// </summary>
        /// <param name="fileText">
        /// Memory array of the file data
        /// </param>
        /// <returns>
        /// True if the stream is a domestic receiving list file
        /// </returns>
        private bool DomesticReceiveExport(byte[] fileText)
        {
            // Create new memory stream
            MemoryStream ms = new MemoryStream(fileText);
            // Read to find distinctive marks
            using (StreamReader sr = new StreamReader(ms))
                return sr.ReadLine().IndexOf("Receiving List RE-") != -1;
        }

        /// <summary>
        /// Tests the file to determine whether or not the file is a 
        /// shipping list file from the product.
        /// </summary>
        /// <param name="fileText">
        /// Memory array of the file data
        /// </param>
        /// <returns>
        /// True if the stream is a domestic send list file
        /// </returns>
        private bool DomesticSendExport(byte[] fileText)
        {
            // Create new memory stream
            MemoryStream ms = new MemoryStream(fileText);
            // Read to find distinctive marks
            using (StreamReader sr = new StreamReader(ms))
                return sr.ReadLine().IndexOf("Shipping List SD-") != -1;
        }
        #endregion

        #region Disaster Parsers
        /// <summary>
        /// Tests the file to determine whether or not the file is a 
        /// American Century disaster report.
        /// </summary>
        /// <param name="fileText">
        /// Memory array of the file data
        /// </param>
        /// <returns>
        /// True if the stream is a American Century disaster report, else false
        /// </returns>
        private bool AmericanCenturyDisasterReport(byte[] fileText)
        {
            string fileLine;
            // Create new memory stream
            MemoryStream ms = new MemoryStream(fileText);
            // Read to find distinctive marks
            using (StreamReader r = new StreamReader(ms))
            {
                while ((fileLine = r.ReadLine()) != null)
                {
                    if (fileLine.ToUpper().IndexOf("AMERICAN CENTURY") != -1)
                    {
                        if (r.ReadLine().ToUpper().IndexOf("TUBS") != -1)
                        {
                            return true;
                        }
                    }
                }
            }
            // Conclude that this is not an American Century report
            return false;
        }
        /// <summary>
        /// Tests the file to determine whether or not the file is a 
        /// new disaster code list file.
        /// </summary>
        /// <param name="fileText">
        /// Memory array of the file data
        /// </param>
        /// <returns>
        /// True if the stream is a new disaster code list file, else false
        /// </returns>
        private bool BatchDisasterFile(byte[] fileText)
        {
            // Create new memory stream
            MemoryStream ms = new MemoryStream(fileText);
            // Read to find distinctive marks
            using (StreamReader sr = new StreamReader(ms))
            {
                string fileLine;
                // If we don't find something in the first 3 lines, we can
                // conclude that this is not a VaultTrack disaster code
                // list file.
                for(int i = 0; i < 3; i++)
                {
                    if ((fileLine = sr.ReadLine()) == null)
                    {
                        break;
                    }
                    else if (IsBatchFile(fileLine))
                    {
                        fileLine = sr.ReadLine().ToUpper().Trim();
                        return fileLine.IndexOf("$DISASTER CODE LIST") == 0 || fileLine.IndexOf("$DISASTER RECOVERY LIST") == 0;
                    }
                }
            }
            // Not a VaultLedger disaster code list file.
            return false;
        }
        /// <summary>
        /// Tests the file to determine whether or not the file is a CA25 disaster report.
        /// </summary>
        /// <param name="fileText">
        /// Memory array of the file data
        /// </param>
        /// <returns>
        /// True if the stream is a CA25 disaster report, else false
        /// </returns>
        private bool CA25DisasterReport(byte[] fileText)
        {
            string fileLine;
            // Create new memory stream
            MemoryStream ms = new MemoryStream(fileText);
            // Read to find distinctive marks
            using (StreamReader r = new StreamReader(ms))
            {
                while ((fileLine = r.ReadLine()) != null)
                {
                    if (fileLine.ToUpper().IndexOf("INVENTORY LIST FOR VAULT") != -1)
                    {
                        while ((fileLine = r.ReadLine()) != null)
                        {
                            if (0 == fileLine.Trim().Replace("-", String.Empty).Length)
                            {
                                return true;
                            }
                        }
                        // Nope!
                        break;
                    }
                }
            }
            // Conclude that this is not a CA25 disaster report
            return false;
        }
        /// <summary>
        /// Tests the file to determine whether or not the file is a 
        /// Canadian Tire disaster report.
        /// </summary>
        /// <param name="fileText">
        /// Memory array of the file data
        /// </param>
        /// <returns>
        /// True if the stream is a Canadian Tire disaster report, else false
        /// </returns>
        private bool CanadianTireDisasterReport(byte[] fileText)
        {
            string fileLine;
            // Create new memory stream
            MemoryStream ms = new MemoryStream(fileText);
            // Read to find distinctive marks
            using (StreamReader sr = new StreamReader(ms))
                while ((fileLine = sr.ReadLine()) != null)
                    if (fileLine.ToUpper().IndexOf("CANADIAN TIRE DRP") != -1)
                        return true;
            // Conclude that this is not a Coke report
            return false;
        }
        /// <summary>
        /// Tests the file to determine whether or not the file is a 
        /// Canadian Tire disaster report.
        /// </summary>
        /// <param name="fileText">
        /// Memory array of the file data
        /// </param>
        /// <returns>
        /// True if the stream is a CGI disaster report, else false
        /// </returns>
        private bool CGI1DisasterReport(byte[] fileText)
        {
            string fileLine;
            // Create new memory stream
            MemoryStream ms = new MemoryStream(fileText);
            // Read to find distinctive marks
            using (StreamReader sr = new StreamReader(ms))
                while ((fileLine = sr.ReadLine()) != null)
                    if (fileLine.ToUpper().IndexOf("CGI DISASTER") != -1)
                        return true;
            // Conclude that this is not a Coke report
            return false;
        }
        /// <summary>
        /// Tests the file to determine whether or not the file is a CGI file
        /// </summary>
        /// <param name="fileText">
        /// Memory array of the file data
        /// </param>
        /// <returns>
        /// True if the stream is a CGI2 report, else false
        /// </returns>
        private bool CGI2DisasterReport(byte[] fileText)
        {
            string fileLine;
            // Create new memory stream
            MemoryStream ms = new MemoryStream(fileText);
            // Read to find distinctive marks
            using (StreamReader r = new StreamReader(ms))
            {
                if ((fileLine = r.ReadLine().ToUpper()).IndexOf("CGI MONTREAL") != -1)
                {
                    if (fileLine.IndexOf("DATE:") != -1)
                    {
                        // Trim the line at DATE:
                        fileLine = fileLine.Substring(0, fileLine.IndexOf("DATE:") - 1).Trim();
                        // Look for valid list type
                        if (fileLine[fileLine.Length-1] == 'N')         // N - disaster recovery
                        {
                            return true;
                        }
                    }
                }
            }
            // Conclude that this is not an CGI2 report
            return false;
        }
        /// <summary>
        /// Tests the file to determine whether or not the file is a CGI file
        /// </summary>
        /// <param name="fileText">
        /// Memory array of the file data
        /// </param>
        /// <returns>
        /// True if the stream is a CGI3 report, else false
        /// </returns>
        private bool CGI3DisasterReport(byte[] fileText)
        {
            string fileLine = String.Empty;
            // Create new memory stream
            MemoryStream ms = new MemoryStream(fileText);
            // Read to find distinctive marks
            using (StreamReader r = new StreamReader(ms))
            {
                for (int i = 0; i < 20 && fileLine != null; i++)
                {
                    if ((fileLine = r.ReadLine()) == null)
                    {
                        break;
                    }
                    else if (fileLine.IndexOf("INVENTORY OF VOLUMES") != -1)
                    {
                        while ((fileLine = r.ReadLine()) != null)
                        {
                            if (fileLine.IndexOf("DATA SET NAME") != -1 && fileLine.IndexOf("SEQ.") != -1)
                            {
                                return true;
                            }
                        }
                    }
                }
            }
            // Conclude that this is not an CGI3 report
            return false;
        }
        /// <summary>
        /// Tests the file to determine whether or not the file is a CGI file
        /// </summary>
        /// <param name="fileText">
        /// Memory array of the file data
        /// </param>
        /// <returns>
        /// True if the stream is a CGI4 report, else false
        /// </returns>
        private bool CGI4DisasterReport(byte[] fileText)
        {
            string fileLine = String.Empty;
            // Create new memory stream
            MemoryStream ms = new MemoryStream(fileText);
            // Read to find distinctive marks
            using (StreamReader r = new StreamReader(ms))
            {
                if ((fileLine = r.ReadLine()) == null)
                {
                    ;
                }
                else if (fileLine.ToUpper().IndexOf("CGIC DISASTER RECOVERY TAPE LISTING") != -1)
                {
                    if ((fileLine = r.ReadLine()).ToUpper().IndexOf("SENT OFFSITE") != -1)
                    {
                        return true;
                    }
                }
            }
            // Conclude that this is not an CGI4 report
            return false;
        }
        /// <summary>
        /// Tests the file to determine whether or not the file is an
        /// Exxon DR report file.
        /// </summary>
        /// <param name="fileText">
        /// Memory array of the file data
        /// </param>
        /// <returns>
        /// True if the stream is an Exxon DR report file, else false
        /// </returns>
        private static bool ExxonDisasterReport(byte[] fileText)
        {
            // Create new memory stream
            MemoryStream ms = new MemoryStream(fileText);
            // Read to find distinctive marks
            using (StreamReader r = new StreamReader(ms))
            {
                string fileLine;
                // If we don't find something in the first 20 lines, we can
                // conclude that this is not an Exxon DR file
                for (int i = 0; i < 20; i++)
                {
                    if ((fileLine = r.ReadLine()) == null)
                    {
                        break;
                    }
                    else if (fileLine.ToUpper().IndexOf("EXXONMOBIL") != -1)
                    {
                        return true;
                    }
                    else if (fileLine.ToUpper().IndexOf("MOBIL OIL") != -1)
                    {
                        return true;
                    }
                }
            }
            // Not an Exxon file
            return false;
        }
        /// <summary>
        /// Tests the file to determine whether or not the file is an Indiana Farm Board DR file.
        /// </summary>
        /// <param name="fileText">
        /// Memory array of the file data
        /// </param>
        /// <returns>
        /// True if it is, false if not
        /// </returns>
        private static bool IndianaFarmDisasterReport(byte[] b1)
        {
            String s1 = null;
            bool x1 = false;
            // Loop
            using (StreamReader r1 = new StreamReader(new MemoryStream(b1)))
            {
                while (null != (s1 = r1.ReadLine()))
                {
                    if (!x1 && s1.ToUpper().IndexOf("RECOVERY VOLUME SUMMARY REPORT") != -1)
                    {
                        x1 = true;
                    }
                    else if (x1 && s1.ToUpper().IndexOf("SERIAL") != -1 && s1.ToUpper().IndexOf("LOCATION") != -1)
                    {
                        return true;
                    }
                }
                // Nope
                return false;
            }
        }
        /// <summary>
        /// Tests the file to determine whether or not the file is an
        /// LA County DR report file.
        /// </summary>
        /// <param name="fileText">
        /// Memory array of the file data
        /// </param>
        /// <returns>
        /// True if the stream is an LA County DR report file, else false
        /// </returns>
        private static bool LACountyDisasterReport(byte[] fileText)
        {
            // Create new memory stream
            MemoryStream ms = new MemoryStream(fileText);
            // Read to find distinctive marks
            using (StreamReader sr = new StreamReader(ms))
            {
                string fileLine;
                // If we don't find something in the first 20 lines, we can
                // conclude that this is not an LA County DR file
                for (int i = 0; i < 20; i++)
                {
                    if ((fileLine = sr.ReadLine()) == null)
                    {
                        break;
                    }
                    else if (fileLine.Trim().StartsWith("VAULTING REPORT"))
                    {
                        // Next line should start with "SORTED BY"
                        if (sr.ReadLine().Trim().StartsWith("SORTED BY"))
                        {
                            // Headers should be somewhere in the next 10 lines
                            for (int j = 0; j < 10; j++)
                            {
                                if ((fileLine = sr.ReadLine()) == null)
                                    break;
                                else if (fileLine.IndexOf("VCRT-DATE") != -1 && fileLine.IndexOf("VCRT-TIME") != -1)
                                    return true;
                            }
                        }
                    }
                }
            }
            // Not an LA County file
            return false;
        }
        /// <summary>
        /// Tests the file to determine whether or not the file is an
        /// MediaExport DR report file.
        /// </summary>
        /// <param name="fileText">
        /// Memory array of the file data
        /// </param>
        /// <returns>
        /// True if the stream is an MediaExport DR report file, else false
        /// </returns>
        private static bool MediaExportDisasterReport(byte[] fileText)
        {
            string fileLine = null;
            // Create new memory stream
            MemoryStream ms = new MemoryStream(fileText);
            // Read to find distinctive marks
            using (StreamReader r = new StreamReader(ms))
            {
                // First line should be a distinct header
                if ((fileLine = r.ReadLine()).IndexOf(String.Format("{0} Media Search", Configurator.ProductName)) != -1)
                {
                    return true;
                }
            }
            // Not a MediaExport file
            return false;
        }
        /// <summary>
        /// Tests the file to determine whether or not the file is a  TLMS006 file
        /// </summary>
        /// <param name="fileText">
        /// Memory array of the file data
        /// </param>
        /// <returns>
        /// True if the stream is an TLMS006 file, else false
        /// </returns>
        private bool TLMSDisasterReport(byte[] fileText)
        {
            string s1 = null;
            // Create new memory stream
            MemoryStream ms = new MemoryStream(fileText);
            // Read through file, making sure each line has account name
            using (StreamReader r = new StreamReader(ms))
            {
                while ((s1 = r.ReadLine()) != null)
                {
                    if ((s1 = s1.ToUpper()).IndexOf("INVENTORY REPORT FOR") != -1 && s1.IndexOf("TLMS006") != -1)
                    {
                        return true;
                    }
                }
            }
            // Nope
            return false;
        }
        /// <summary>
        /// Tests the file to determine whether or not the file is a
        /// USA Group DR report file.
        /// </summary>
        /// <param name="fileText">
        /// Memory array of the file data
        /// </param>
        /// <returns>
        /// True if the stream is an USA Group DR report file, else false
        /// </returns>
        private static bool USAGroupDisasterReport(byte[] fileText)
        {
            string fileLine;
            // Create new memory stream
            MemoryStream ms = new MemoryStream(fileText);
            // Read to find distinctive marks
            using (StreamReader sr = new StreamReader(ms))
            {
                while((fileLine = sr.ReadLine()) != null) 
                    if (fileLine.Trim().ToUpper().StartsWith("PLEASE PULL THE FOLLOWING MVCS FOR THE D/R EXERCISE"))
                        while ((fileLine = sr.ReadLine()) != null)
                            if (fileLine.ToUpper().IndexOf("MVC VOLUME") != -1)
                                return true;
            }
            // Not a USA Group DR file
            return false;
        }
        /// <summary>
        /// Tests the file to determine whether or not the file is a UMB Bank disaster report.
        /// </summary>
        /// <param name="fileText">
        /// Memory array of the file data
        /// </param>
        /// <returns>
        /// True if the stream is a UMB Bank disaster report, else false
        /// </returns>
        private bool UMBBankDisasterReport(byte[] fileText)
        {
            string fileLine;
            // Create new memory stream
            MemoryStream ms = new MemoryStream(fileText);
            // Read to find distinctive marks
            using (StreamReader sr = new StreamReader(ms))
                while ((fileLine = sr.ReadLine()) != null)
                    if (fileLine.ToUpper().IndexOf("UMB BANK DISASTER") != -1)
                        return true;
            // Conclude that this is not a Coke report
            return false;
        }
        /// <summary>
        /// Tests the file to determine whether or not the file is a Videotron disaster report.
        /// </summary>
        /// <param name="fileText">
        /// Memory array of the file data
        /// </param>
        /// <returns>
        /// True if the stream is a Videotron disaster report, else false
        /// </returns>
        private bool VideotronDisasterReport(byte[] fileText)
        {
            string s1;
            bool b1 = false;
            // Create new memory stream
            MemoryStream m1 = new MemoryStream(fileText);
            // Read to find distinctive marks
            using (StreamReader r1 = new StreamReader(m1))
            {
                while ((s1 = r1.ReadLine()) != null)
                {
                    if (b1 == false && s1.ToUpper().IndexOf("INVENTORY OF VOLUMES BY LOCATION") != -1)
                    {
                        b1 = true;
                    }
                    else if (b1 == true && s1.ToUpper().IndexOf("CURRENT LOCATION NAME") != -1)
                    {
                        return true;
                    }
                }
            }
            // Nope
            return false;
        }
        #endregion

        #region Inventory Parsers
        /// <summary>
        /// Tests the file to determine whether or not the file is a 
        /// new disaster code list file.
        /// </summary>
        /// <param name="fileText">
        /// Memory array of the file data
        /// </param>
        /// <returns>
        /// True if the stream is a new disaster code list file, else false
        /// </returns>
        private bool BatchInventoryFile(byte[] fileText)
        {
            string fileLine = null;
            // Create a new memory stream
            MemoryStream ms = new MemoryStream(fileText);
            // Read through the stream
            using (StreamReader sr = new StreamReader(ms))
            {
                try
                {
                    // First line should be "$VAULTLEDGER INVENTORY".  Second line should be datetime of inventory.
                    if ((fileLine = sr.ReadLine()).ToUpper() != "$VAULTLEDGER INVENTORY" && fileLine.ToUpper() != "$TVAULTLEDGER INVENTORY")
                    {
                        return false;
                    }
                    else if ((fileLine = sr.ReadLine()).Substring(0,2) != "$D")
                    {
                        return false;
                    }
                    else
                    {
                        string[] dateFormats = new string[] {"yyyy/MM/dd HH:mm:ss", "yyyy-MM-dd HH:mm:ss", "yyyy.MM.dd HH:mm:ss"};
                        DateTime.ParseExact(fileLine.Substring(2,19), dateFormats, DateTimeFormatInfo.InvariantInfo, DateTimeStyles.None);
                    }
                    // Third line should start with $A
                    if ((fileLine = sr.ReadLine()).Substring(0,2) != "$A")
                    {
                        return false;
                    }
                    // Everything checks out okay
                    return true;
                }
                catch
                {
                    return false;
                }
            }
        }
        /// <summary>
        /// Tests the file to determine whether or not the file is an Imation RFID file
        /// </summary>
        /// <param name="fileText">
        /// Memory array of the file data
        /// </param>
        /// <returns>
        /// True if the stream is an Imation RFID file, else false
        /// </returns>
        private bool ImationInventoryFile(byte[] fileText)
        {
            // Create new memory stream
            MemoryStream ms = new MemoryStream(fileText);
            // Read to find distinctive marks
            using (StreamReader sr = new StreamReader(ms))
                if (sr.ReadLine().ToUpper().Trim() == "VAULTLEDGER IMATION RFID ENCRYPTED XML DOCUMENT") 
                    return true;
            // Conclude that this is not an Imation report
            return false;
        }
        /// <summary>
        /// Tests the file to determine whether or not the file is an Iron Mountain file
        /// </summary>
        /// <param name="fileText">
        /// Memory array of the file data
        /// </param>
        /// <returns>
        /// True if the stream is an Iron Mountain file, else false
        /// </returns>
        private bool IronMountainInventoryFile(byte[] fileText)
        {
            string fileLine = null;
            // Create new memory stream
            MemoryStream ms = new MemoryStream(fileText);
            // Get the account collection from the database
            AccountCollection c = ((IAccount)AccountFactory.Create()).GetAccounts();
            // Read through file, making sure each line has account name
            using (StreamReader r = new StreamReader(ms))
            {
                while ((fileLine = r.ReadLine()) != null)
                {
                    bool accountOk = false;
                    // Must be a space in the line
                    if (fileLine.IndexOf(' ') == -1) return false;
                    // Get the account number
                    string accountName = fileLine.Substring(0, fileLine.IndexOf(' '));
                    // Run through the accounts
                    for (int i = 0; i < c.Count && accountOk == false; i++)
                        if (c[i].Name == accountName)
                            accountOk = true;
                    // If the account was not found, return false
                    if (accountOk == false) return false;
                }
            }
            // Conclude that this is qualifies as an Iron Mountain inventory report
            return true;
        }
		/// <summary>
		/// Tests the file to determine whether or not the file is an Iron Mountain file
		/// </summary>
		/// <param name="fileText">
		/// Memory array of the file data
		/// </param>
		/// <returns>
		/// True if the stream is an Iron Mountain file, else false
		/// </returns>
		private bool IronMountain2InventoryFile(byte[] fileText)
		{
			// Create new memory stream
			MemoryStream ms = new MemoryStream(fileText);
			// Read through file, making sure each line has account name
			using (StreamReader r = new StreamReader(ms))
			{
				// Read top line
				string fileLine = r.ReadLine();
				// Check for headers
				if (fileLine.IndexOf("Cust #") != -1 && fileLine.IndexOf("Media #") != -1)
				{
					return true;
				}
				else
				{
					return false;
				}
			}
		}
        /// <summary>
        /// Tests the file to determine whether or not the file is a RQMM inventory file
        /// </summary>
        /// <param name="fileText">
        /// Memory array of the file data
        /// </param>
        private bool RQMMInventoryFile(byte[] fileText)
        {
            string fileLine = null;
            // Read first line
            using (StreamReader sr = new StreamReader(new MemoryStream(fileText)))
            {
                if (null == (fileLine = sr.ReadLine()))
                {
                    return false;
                }
                else if (fileLine.ToUpper().StartsWith("INVENTORY LIST FOR "))
                {
                    return true;
                }
                else
                {
                    return false;
                }
            }
        }
        /// <summary>
        /// Tests the file to determine whether or not the file is a  TLMS006 file
        /// </summary>
        /// <param name="fileText">
        /// Memory array of the file data
        /// </param>
        /// <returns>
        /// True if the stream is an TLMS006 file, else false
        /// </returns>
        private bool TLMSInventoryFile(byte[] fileText)
        {
            string s1 = null;
            // Create new memory stream
            MemoryStream ms = new MemoryStream(fileText);
            // Read through file, making sure each line has account name
            using (StreamReader r = new StreamReader(ms))
            {
                while ((s1 = r.ReadLine()) != null)
                {
                    if ((s1 = s1.ToUpper()).IndexOf("INVENTORY REPORT FOR") != -1 && s1.IndexOf("TLMS006") != -1)
                    {
                        return true;
                    }
                }
            }
            // Nope
            return false;
        }
        #endregion
    
        #region Utility Methods
        private bool IsBatchFile(string fileLine)
        {
			string s1 = fileLine.ToUpper();
            string[] s2 = new string[] {"$VAULTTRACK TEXT FILE", "$VAULTLEDGER TEXT FILE", "$VAULTTRACK BATCH FILE", "$VAULTLEDGER BATCH FILE"};
            // Test for one of the strings
			foreach (string x1 in s2)
			{
				if (s1.IndexOf(x1) == 0)
				{
					return true;
				}
			}
            // String not found
            return false;
        }

        private string NextNonBlankLine(StreamReader r, bool upper)
        {
            string fileLine;
            // Loop through the file
            while ((fileLine = r.ReadLine()) != null)
                if (fileLine.Trim().Length != 0)
                    return upper ? fileLine.ToUpper() : fileLine ;
            // Return null
            return null;
        }

        private string NextNonBlankLine(StreamReader r)
        {
            return NextNonBlankLine(r, false);
        }
        #endregion
    }
}
