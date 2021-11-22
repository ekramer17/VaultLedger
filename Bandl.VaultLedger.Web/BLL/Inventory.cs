using System;
using System.Collections;
using System.Security.Cryptography;
using Bandl.Library.VaultLedger.IDAL;
using Bandl.Library.VaultLedger.DALFactory;
using Bandl.Library.VaultLedger.Collections;
using Bandl.Library.VaultLedger.Exceptions;
using Bandl.Library.VaultLedger.Gateway.Recall;
using Bandl.Library.VaultLedger.Security;
using Bandl.Library.VaultLedger.IParser;
using Bandl.Library.VaultLedger.Model;

namespace Bandl.Library.VaultLedger.BLL
{
	/// <summary>
	/// Summary description for Inventory.
	/// </summary>
	public class Inventory
	{
		/// <summary>
		/// Checks to see whether an inventory file is different from the last uploaded/downloaded inventory file by comparing hashes
		/// </summary>
		/// <returns>
		/// True if file is new, else false
		/// </returns>
		private static bool CheckInventoryFile(string account, Locations loc, byte[] hash1)
		{
			// Verify validity of data
			if (account == null || account == String.Empty)
				throw new ArgumentException("Account name not supplied.");
			// If no new hash, return false
			if (null == hash1) return false;
			// Get the last file hash
			byte[] hash2 = InventoryFactory.Create().GetLatestFileHash(account, loc);
			// If we have no local hash, return true
			if (null == hash2) return true;
			// Return true if the hashes are different, else false
			if (hash1.Length != hash2.Length)
			{
				throw new BLLException("Inventory file hashes of different lengths");
			}
			else
			{
				for (int i = 0; i < hash1.Length; i++)
					if (hash1[i] != hash2[i])
						return true;
			}
			// Hashes are identical - file has not changed
			return false;
		}

		/// <summary>
		/// Downloads the inventory for all accounts from the web service of the given vendor
		/// </summary>
		public static void DownloadInventory(Vendors vendor)
		{
			// Must have librarian privileges
			CustomPermission.Demand(Role.Operator);
			// Download the inventory for each account
			foreach(AccountDetails a in Account.GetAccounts())
				DownloadInventory(a.Name, vendor);
		}

		/// <summary>
		/// Downloads the inventory for a given account from the web service
		/// </summary>
		/// <returns>
		/// Returns the number of items in the downloaded inventory
		/// </returns>
		public static void DownloadInventory(string account, Vendors vendor)
		{
			// Must have librarian privileges
			CustomPermission.Demand(Role.Operator);
			// Verify validity of data
			if (account == null || account == String.Empty)
				throw new ArgumentException("Account name not supplied.");
			// Create the gateway to the remote web service
			switch (vendor)
			{
				case Vendors.Recall:
					RecallGateway rs = new RecallGateway();
					if (CheckInventoryFile(account, Locations.Vault, rs.GetInventoryFileHash(account)))
						rs.DownloadInventory(account);
					break;
				case Vendors.IronMountain:
					throw new ApplicationException("No inventory retrieval method currently exists for Iron Mountain");
				case Vendors.VytalRecords:
					throw new ApplicationException("No inventory retrieval method currently exists for Vytal Records");
                case Vendors.DataSafe:
                    throw new ApplicationException("No inventory retrieval method currently exists for DataSafe");
            }
		}
		/// <summary>
		/// Compares inventory for each account/location combination in the system
		/// </summary>
        /// <param name="accounts">
        /// Comma-delimited list of account id numbers
        /// </param>
        /// <param name="makeMedia">
		/// Create media for unknown serial numbers
		/// </param>
		/// <returns>
		/// Number of discrepancies present in the database after comparison
		/// </returns>
		public static void CompareInventories(string accounts, bool makeMedia)
		{
			// Must have librarian privileges
			CustomPermission.Demand(Role.Operator);
			// Compare the inventory
			InventoryFactory.Create().CompareInventories(accounts, makeMedia, true);
		}
		/// <summary>
		/// Uploads a local inventory file and inserts the inventory into the database if necessary.
		/// </summary>
		/// <param name="fileText">
		/// Byte stream representing the contents of the file
		/// </param>
		public static void UploadInventory(byte[] fileText, out ArrayList[] serials, out ArrayList[] notes, out String[] accounts)
		{
			byte[] b = null;
			// Parse the file
			IInventoryParser p = Parser.GetInventoryParser(fileText);
            p.Location = Locations.Enterprise;
			p.Parse(fileText);
			// Get the notes and location
			Locations myLocation = p.Location;
            accounts = p.GetAccounts();
            serials = p.GetSerials();
			notes = p.GetNotes();
			// Compute the hash of the file
			using (HashAlgorithm hasher = HashAlgorithm.Create("SHA-256"))
			{
				b = hasher.ComputeHash(fileText);
			}
			// For each of the accounts, insert inventory if new file
			for (int i = 0; i < accounts.Length; i++)
			{
				if (CheckInventoryFile(accounts[i], myLocation, b))
				{
					ArrayList ii = new ArrayList();
					string[] s1 = (string[])serials[i].ToArray(typeof(string));
					// Create the inventory items
					for (int j = 0; j < s1.Length; j += 1)
					{
						ii.Add(new InventoryItemDetails(s1[j], String.Empty, false));
					}
					// Insert the inventory
					InventoryItemDetails[] iid = (InventoryItemDetails[])ii.ToArray(typeof(InventoryItemDetails));
					InventoryFactory.Create().InsertInventory(accounts[i], myLocation, b, iid);
				}
			}
		}
	}
}
