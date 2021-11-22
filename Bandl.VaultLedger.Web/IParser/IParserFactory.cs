using System;

namespace Bandl.Library.VaultLedger.IParser
{
	/// <summary>
	/// Summary description for IParserFactory.
	/// </summary>
	public interface IParserFactory
	{
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
        IInventoryParser GetInventoryParser(byte[] fileText);
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
        IParserObject GetParser(byte[] fileText);
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
        IParserObject GetParser(byte[] fileText, string fileName);
    }
}
