using System;
using System.Data;
using Bandl.Library.VaultLedger.Common.Knock;

namespace Bandl.Service.VaultLedger.Recall.Model
{
    /// <summary>
    /// An account as it looks in the local RequestMM database
    /// </summary>
    [Serializable]
    public class LocalAccountDetails
    {
        public LocalAccountDetails() {}

        public int id;
        public string name;
        public string password;
        public string salt;
        public bool allowDynamic;
        public string filePath;

        public LocalAccountDetails(string _name, string _password)
        {
            id = 0;
            name = _name;
            allowDynamic = false;
            filePath = String.Empty;
            // Create salt value
            salt = PwordHasher.CreateSalt(10);
            // Hash password with salt value
            password = PwordHasher.HashPasswordAndSalt(_password,salt);
        }

        public LocalAccountDetails(string _name, string _password, bool _allowDynamic, string _filePath)
        {
            id = 0;
            name = _name;
            allowDynamic = _allowDynamic;
            filePath = _filePath;
            // Create salt value
            salt = PwordHasher.CreateSalt(10);
            // Hash password with salt value
            password = PwordHasher.HashPasswordAndSalt(_password,Salt);
        }

        public LocalAccountDetails(IDataReader reader)
        {
            id = reader.GetInt32(0);
            name = reader.GetString(1);
            password = reader.GetString(2);
            salt = reader.GetString(3);
            allowDynamic = reader.GetBoolean(4);
            filePath = reader.GetString(5);
            // If the salt value is empty, supply it with one
            if (salt == String.Empty) salt = PwordHasher.CreateSalt(10);
        }

        public int Id
        {
            get {return id;}
        }

        public string Name
        {
            get {return name;}
            set {name = value;}
        }

        public string Password
        {
            get {return password;}
            set {password = value;}
        }

        public string Salt
        {
            get {return salt;}
        }

        public bool AllowDynamic
        {
            get {return allowDynamic;}
            set {allowDynamic = value;}
        }

        public string FilePath
        {
            get {return filePath;}
            set {filePath = value;}
        }
    }
}
