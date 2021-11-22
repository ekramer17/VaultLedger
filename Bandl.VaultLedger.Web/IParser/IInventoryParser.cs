using System;
using System.IO;
using System.Collections;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.Collections;

namespace Bandl.Library.VaultLedger.IParser
{
    /// <summary>
    /// Summary description for IInventoryParser.
    /// </summary>
    public interface IInventoryParser
    {
        String[] GetAccounts();

        ArrayList[] GetNotes();

        ArrayList[] GetSerials();

        Locations Location {get;set;}

        void Parse(byte[] fileText);
    }
}
