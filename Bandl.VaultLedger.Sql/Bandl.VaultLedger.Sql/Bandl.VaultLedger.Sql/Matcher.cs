using System;
using System.Data.SqlTypes;
using System.Data.SqlClient;
using Microsoft.SqlServer.Server;
using System.Text.RegularExpressions;

namespace Bandl.VaultLedger.Sql
{
    public class Matcher
    {
        public Matcher() {}
        /// <summary>
        /// This function will be called from the SQL Stored Procedure.
        /// </summary>
        /// Name
        /// <returns>True if match, else false</returns>
        [SqlFunction]
        public static SqlInt32 Match(SqlString s1, SqlString r1)
        {
            return Regex.IsMatch(s1.ToString(), String.Format("^{0}$", r1.ToString()), RegexOptions.IgnoreCase) ? 1 : 0;
        }
    }
}
