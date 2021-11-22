using System;
using System.Collections;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.IParser;
using Bandl.Library.VaultLedger.Collections;

namespace Bandl.Library.VaultLedger.Parsers
{
	/// <summary>
	/// Summary description for InventoryParser.
	/// </summary>
	public class InventoryParser : IInventoryParser
	{
        // Inventory-related fields
        protected Locations   myLocation = Locations.Vault;
        protected ArrayList[] myNotes = null;
        protected ArrayList[] mySerials = null;
        protected String[]    myAccounts = null;
    
        public String[] GetAccounts()
        {
            return myAccounts;
        }

        public ArrayList[] GetNotes()
        {
            return myNotes;
        }

        public ArrayList[] GetSerials()
        {
            return mySerials;
        }

        public Locations Location
        {
            get {return myLocation;}
            set {myLocation = value;}
        }

        public virtual void Parse (byte[] fileText)
        {
            ;
        }
	}
}
