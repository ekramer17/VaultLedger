using System;
using System.Reflection;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.IParser;

namespace Bandl.Library.VaultLedger.BLL
{
	/// <summary>
	/// Parser object loads the factory and obtains the parser object through the Load
	/// method so that version is not checked, and we can replace this file frequently
	/// without having to issue publisher policies or codebases.
	/// </summary>
	public class Parser
	{
        public static IParserObject GetParser(ParserTypes parserType, byte[] fileText)
        {
            return GetParser(parserType, fileText, String.Empty);
        }
        
        public static IParserObject GetParser(ParserTypes parserType, byte[] fileText, string fileName)
		{
            object[] p = new object[] {parserType};
            string assemblyName = "Bandl.Library.VaultLedger.Parsers";
            string factoryName = assemblyName + ".ParserFactory";
            // Create the parser factory
            IParserFactory f = (IParserFactory)Assembly.Load(assemblyName).CreateInstance(factoryName, true, 0, null, p, null, null);
            // Use it to get the parser
            return f.GetParser(fileText, fileName);
		}

        public static IInventoryParser GetInventoryParser(byte[] fileText)
        {
            string assemblyName = "Bandl.Library.VaultLedger.Parsers";
            string factoryName = assemblyName + ".ParserFactory";
            // Create the parser factory
            IParserFactory f = (IParserFactory)Assembly.Load(assemblyName).CreateInstance(factoryName, true, 0, null, null, null, null);
            // Use it to get the parser
            return f.GetInventoryParser(fileText);
        }

        public static bool CheckFile(ParserTypes parserType, byte[] fileText)
        {
            return CheckFile(parserType, fileText, String.Empty);
        }

        public static bool CheckFile(ParserTypes parserType, byte[] fileText, string fileName)
        {
            try
            {
                GetParser(parserType, fileText, fileName);
                return true;
            }
            catch
            {
                return false;
            }
        }
    }
}
