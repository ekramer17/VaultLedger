using System;
using System.IO;
using System.Collections;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.Collections;

namespace Bandl.Library.VaultLedger.IParser
{
    /// <summary>
    /// Summary description for IParser.
    /// </summary>
    public interface IParserObject
    {
        /// <summary>
        /// Gets the string that signals that the account should be forced
        /// </summary>
        string GetDictateIndicator();

        /// <summary>
        /// When set to true, allows the report to dictate the account of the media within
        /// </summary>
        /// <param name="doDictate">
        /// True or false
        /// </param>
        void AllowAccountDictate(bool doDictate);

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
        void Parse(byte[] fileText, out SendListItemCollection sli, out ReceiveListItemCollection rli);

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
        void Parse(byte[] fileText, out SendListItemCollection sli, out ReceiveListItemCollection rli, out ArrayList s, out ArrayList a, out ArrayList l);

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
        void Parse(byte[] fileText, out SendListItemCollection sendCollection, out SendListCaseCollection caseCollection);

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
        void Parse(byte[] fileText, out ReceiveListItemCollection li);

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
        void Parse(byte[] fileText, out string[] serials, out string[] cases);

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
        void Parse(byte[] fileText, out DisasterCodeListItemCollection listItems);
    }
}
