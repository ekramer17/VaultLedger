using System;
using System.Web;
using System.Collections;
using System.Globalization;

namespace Bandl.Library.VaultLedger.Model
{
    /// <summary>
    /// Contains utility methods having to do with time, e.g. transformations between local and utc
    /// </summary>
    public class Time
    {
        public static DateTime Local
        {
            get
            {
                try
                {
                    return DateTime.UtcNow.AddHours((Int32)HttpContext.Current.Session[CacheKeys.TimeZone]);
                }
                catch
                {
                    return DateTime.Now;
                }
            }
        }

        public static DateTime Today
        {
            get
            {
                return ClearTime(Local);
            }
        }

        public static DateTime UtcToday
        {
            get
            {
                return ClearTime(DateTime.UtcNow);
            }
        }

        public static DateTime ClearTime(DateTime d)
        {
            return DateTime.Parse(d.ToString("yyyy-MM-dd"));
        }

        public static DateTime LocalToUtc(DateTime d)
        {
            try
            {
                return d.AddHours(-(Int32)HttpContext.Current.Session[CacheKeys.TimeZone]);
            }
            catch
            {
                return d;
            }
        }

        public static DateTime UtcToLocal(DateTime d)
        {
            try
            {
                return d.AddHours((Int32)HttpContext.Current.Session[CacheKeys.TimeZone]);
            }
            catch
            {
                return d;
            }
        }
    }

    /// <summary>
    /// Contains utility methods having to do with date, e.g. formatting
    /// </summary>
    public class Date
    {
        public static string Display(DateTime d, HttpContext c, bool time, bool seconds, bool milliseconds)
        {
            string dateString = null;
            // Get the date
            if (c != null && c.Items[CacheKeys.DateMask] != null)
                dateString = d.ToString((string)c.Items[CacheKeys.DateMask]);
            else
                dateString = d.ToString("yyyy/MM/dd");
            // If we want the time, get it
            if (time == false)
            {
                return dateString;
            }
            else
            {
                if (c == null || c.Items[CacheKeys.TimeMask] == null)
                {
                    return String.Format("{0} {1}", dateString, d.ToString("H:mm:ss"));
                }
                else
                {
                    string timeString = (string)c.Items[CacheKeys.TimeMask];
                    // Cannot have milliseconds without seconds
                    if (seconds == false) milliseconds = false;
                    // If milliseconds then replace seconds with milliseconds as well
                    if (milliseconds == true) timeString = timeString.Replace(":ss", ":ss.fff");
                    // If no seconds, getrid of seconds in the format string
                    if (seconds == false) timeString = timeString.Replace(":ss", String.Empty);
                    // Format the string
                    return String.Format("{0} {1}", dateString, d.ToString(timeString));
                }
            }
        }

        public static string Display(DateTime d, HttpContext c, bool time)
        {
            return Display(d, c, time, true, false);
        }
            
        public static string Display(DateTime d, bool time, bool seconds, bool milliseconds)
        {
            return Display(d, HttpContext.Current, time, seconds, milliseconds);
        }

        public static string Display(DateTime d, bool time, bool seconds)
        {
            return Display(d, HttpContext.Current, time, seconds, false);
        }

        public static string Display(DateTime d, bool time)
        {
            return Display(d, HttpContext.Current, time);
        }

        public static string Display(DateTime d)
        {
            return Display(d, HttpContext.Current, false);
        }

        public static string Display(string dateString, DateTime d, HttpContext c, bool time, bool seconds, bool milliseconds)
        {
            return Display(ParseExact(dateString, c), c, time, seconds, milliseconds);
        }
        
        public static string Display(string dateString, HttpContext c, bool time, bool seconds)
        {
            return Display(ParseExact(dateString, c), c, time, seconds, false);
        }

        public static string Display(string dateString, HttpContext c, bool time)
        {
            return Display(ParseExact(dateString, c), c, time);
        }

        public static string Display(string dateString, HttpContext c)
        {
            return Display(ParseExact(dateString, c), c, false);
        }

        public static string Display(string dateString, bool time, bool seconds)
        {
            return Display(dateString, HttpContext.Current, time, seconds);
        }

        public static string Display(string dateString, bool time)
        {
            return Display(dateString, HttpContext.Current, time);
        }

        public static string Display(string dateString)
        {
            return Display(dateString, HttpContext.Current, false);
        }

        public static DateTime ParseExact(string dateString, HttpContext c)
        {
            string date1 = null;
            string time1 = null;
            // Get the date and time (if any)
            if (dateString.IndexOf(' ') != -1)
            {
                date1 = dateString.Substring(0, dateString.IndexOf(' '));
                time1 = dateString.Substring(dateString.IndexOf(' ') + 1);
            }
            else
            {
                date1 = dateString;
                time1 = String.Empty;
            }
            // Create an array list with year-first formats
            ArrayList f = new ArrayList(new string[] {"yyyy/M/d", "yyyy-M-d", "yyyy.M.d"});
            // If we have session format, add it and permutations
            if (c != null && c.Items[CacheKeys.DateMask] != null)
            {
                string x = (string)c.Items[CacheKeys.DateMask];
                // If the format begins with 'y', then no other formats are necessary
                if (x[0] == 'M')
                {
                    f.Add("M/d/yyyy");
                    f.Add("M-d-yyyy");
                    f.Add("M.d.yyyy");
                    f.Add("M/d/yy");
                    f.Add("M-d-yy");
                    f.Add("M.d.yy");
                }
                else if (x[0] == 'd')
                {
                    f.Add("d/M/yyyy");
                    f.Add("d-M-yyyy");
                    f.Add("d.M.yyyy");
                    f.Add("d/M/yy");
                    f.Add("d-M-yy");
                    f.Add("d.M.yy");
                }
            }
            // Do the parse
            DateTime x1 = DateTime.ParseExact(date1, (string[])f.ToArray(typeof(string)), null, DateTimeStyles.None);
            // If we have a time, add it back
            if (time1.Length != 0)
            {
                return DateTime.Parse(String.Format("{0} {1}", x1.ToString("yyy-MM-dd"), time1));
            }
            else
            {
                return x1;
            }
        }

        public static DateTime ParseExact(string dateString)
        {
            return ParseExact(dateString, HttpContext.Current);
        }
    }
}
