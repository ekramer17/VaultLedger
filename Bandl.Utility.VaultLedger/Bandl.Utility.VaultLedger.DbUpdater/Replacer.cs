using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace Bandl.Utility.VaultLedger.DbUpdater
{
    internal class Replacer
    {
        private static Dictionary<String, String> _x1 = new Dictionary<String, String>();

        public static void Add(String[] s1)
        {
            _x1[s1[0]] = s1[1];
        }

        public static String Replace(String q1)
        {
            foreach(KeyValuePair<String, String> x2 in _x1)
            {
                q1 = q1.Replace(x2.Key, x2.Value);
            }
            // Return
            return q1;
        }
    }
}
