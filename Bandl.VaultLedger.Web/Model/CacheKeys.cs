using System;
using System.Web;
using System.Threading;
using System.Web.Caching;

namespace Bandl.Library.VaultLedger.Model
{
	/// <summary>
	/// Summary description for CacheKeys.
	/// </summary>
    public class CacheKeys
    {
        public static void Remove(string key)
        {
            try
            {
                HttpRuntime.Cache.Remove(key);
            }
            catch
            {
                ;
            }
        }

        #region Application Cache Insert Methods
        public static void Insert(string key, object o, CacheDependency dependencies, DateTime absoluteExpiration, TimeSpan slidingExpiration)
        {
            try
            {
                HttpRuntime.Cache.Insert(key, o, dependencies, absoluteExpiration, slidingExpiration);
            }
            catch
            {
                ;
            }
        }

        public static void Insert(string key, object o, DateTime absoluteExpiration, TimeSpan slidingExpiration)
        {
            Insert(key, o, null, absoluteExpiration, slidingExpiration);
        }

        public static void Insert(string key, object o, DateTime absoluteExpiration)
        {
            Insert(key, o, null, absoluteExpiration, TimeSpan.Zero);
        }

        public static void Insert(string key, object o, TimeSpan slidingExpiration)
        {
            Insert(key, o, null, Cache.NoAbsoluteExpiration, slidingExpiration);
        }

        public static void Insert(string key, object o, int seconds)
        {
            Insert(key, o, null, Cache.NoAbsoluteExpiration, new TimeSpan(0, 0, seconds));
        }

        public static void Insert(string key, object o)
        {
            Insert(key, o, null, Cache.NoAbsoluteExpiration, TimeSpan.Zero);
        }
        #endregion

        #region Application Cache Keys
        // Parameters used for accessing online RoboHelp - used by all sessions
        public static string HelpParameters
        {
            get
            {
                return "HelpParameters";
            }
        }

        public static string SqlConstraints
        {
            get
            {
                return "SqlConstraints";
            }
        }
        #endregion

        //#region Application Cache Keys (Session Scope)
        //// These keys contain the session id but are kept in the application
        //// cache so that we may expire them quicker and reclaim memory.  These
        //// keys should always use a sliding expiration.
        //public static string DLStatuses
        //{
        //    get
        //    {
        //        return "DLStatuses";
        //    }
        //}

        //public static string RLStatuses
        //{
        //    get
        //    {
        //        return "RLStatuses";
        //    }
        //}

        //public static string SLStatuses
        //{
        //    get
        //    {
        //        return "SLStatuses";
        //    }
        //}

        //#endregion
        
        #region Router Keys (Session Scope)
        public static string ConnectOwner
        {
            get
            {
                if (HttpContext.Current != null)
                {
                    return String.Format("ConnectionOwner{0}", HttpContext.Current.Session.SessionID);
                }
                else
                {
                    return null;
                }
            }
        }

        public static string ConnectOperator
        {
            get
            {
                if (HttpContext.Current != null)
                {
                    return String.Format("ConnectionOperator{0}", HttpContext.Current.Session.SessionID);
                }
                else
                {
                    return null;
                }
            }
        }

        public static string AccountNo
        {
            get
            {
                if (HttpContext.Current != null)
                {
                    return String.Format("AccountNo{0}", HttpContext.Current.Session.SessionID);
                }
                else
                {
                    return null;
                }
            }
        }

        public static string AccountType
        {
            get
            {
                if (HttpContext.Current != null)
                {
                    return String.Format("AccountType{0}", HttpContext.Current.Session.SessionID);
                }
                else
                {
                    return null;
                }
            }
        }

        #endregion

        #region Session State Keys
        // These keys are for session variables.  We should only use
        // session variables to pass data between pages (and, even
        // then, only when necessary) so that the data may be
        // removed from the session state on retrieval.  The exception
        // is TimeLocale, which we'll need for the life span of
        // the session but don't want to use the application cache
        // because in that case we would have to use an infinite
        // expiration, which of course is bad.
        public static string AsyncResult
        {
            get
            {
                return "AsyncResult";
            }
        }

        public static string Exception
        {
            get
            {
                return "Exception";
            }
        }

        public static string MediumFilter
        {
            get
            {
                return "MediumFilter";
            }
        }

        public static string Object
        {
            get
            {
                return "Object";
            }
        }

        public static string Principal
        {
            get
            {
                return "Principal";
            }
        }

        public static string PrintSource
        {
            get
            {
                return "PrintSource";
            }
        }

        public static string PrintObjects
        {
            get
            {
                return "PrintObjects";
            }
        }

        public static string WaitRequest
        {
            get
            {
                return "WaitRequest";
            }
        }

        public static string WindowsIdentity
        {
            get
            {
                return "WindowsIdentity";
            }
        }
        #endregion

        #region Context Item Keys
        public static String Role { get { return "Role"; } }
        public static String Login { get { return "Login"; } }
        public static String DateMask { get { return "DateMask"; } }
        public static String TimeMask { get { return "TimeMask"; } }
        public static String TimeZone { get { return "TimeZone"; } }   // time zone offset
        #endregion

    }
}
