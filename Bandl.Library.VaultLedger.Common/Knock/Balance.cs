using System;
using System.IO;
using System.Text;
using System.Security.Cryptography;

namespace Bandl.Library.VaultLedger.Common.Knock
{
	/// <summary>
	/// Summary description for Balance.
	/// </summary>
	public class Balance
	{
        private static byte[] scale = {243, 101, 150, 203, 16, 115, 22, 166, 45, 23, 157, 179, 115, 115, 254, 96, 102, 145, 194, 162, 17, 9, 165, 213, 128, 111, 208, 54, 69, 175, 105, 13};
        private static byte[] ray = {64, 173, 200, 168, 30, 1, 107, 249, 202, 73, 79, 25, 154, 239, 137, 137};

        public static byte[] Inter(string s)
        {
            return Inter(s, scale, ray);
        }

        public static byte[] Inter(string s, byte[] v)
        {
            return Inter(s, scale, v);
        }

        public static byte[] Inter(string s, out byte[] v)
        {
            RijndaelManaged rij = new RijndaelManaged();
            rij.GenerateIV();
            v = rij.IV;
            return Inter(s, scale, v);
        }

        public static byte[] Inter(string s, byte[] k, byte[] v)
        {
            RijndaelManaged rij = new RijndaelManaged();
            rij.Key = k;
            rij.IV = v;

            // Get an encryptor
            ICryptoTransform e = rij.CreateEncryptor(rij.Key, rij.IV);

            // Encrypt the data
            MemoryStream ms = new MemoryStream();
            CryptoStream cs = new CryptoStream(ms, e, CryptoStreamMode.Write);

            // Convert the data to a byte array.
            byte[] eBytes = Encoding.UTF8.GetBytes(s);

            // Write all data to the crypto stream and flush it.
            cs.Write(eBytes, 0, eBytes.Length);
            cs.FlushFinalBlock();

            // Get encrypted array of bytes.
            return ms.ToArray();
        }

        public static string Exhume(byte[] b)
        {
            return Exhume(b, scale, ray);
        }

        public static string Exhume(byte[] b, byte[] v)
        {
            return Exhume(b, scale, v);
        }

        public static string Exhume(byte[] b, byte[] k, byte[] v)
        {
            RijndaelManaged rij = new RijndaelManaged();
            rij.Key = k;
            rij.IV = v;

            // Get a decryptor
            ICryptoTransform d = rij.CreateDecryptor(rij.Key, rij.IV);

            // Decrypt the data
            MemoryStream ms = new MemoryStream();
            CryptoStream cs = new CryptoStream(ms, d, CryptoStreamMode.Write);

            // Write all data to the crypto stream and flush it.
            cs.Write(b, 0, b.Length);
            cs.FlushFinalBlock();
            
            // Get string
            return Encoding.UTF8.GetString(ms.ToArray());
        }
    }
}
