using System;
using System.Configuration;
using System.Threading;
using System.Web;
using System.Web.SessionState;
using Bandl.Library.VaultLedger.Model;

namespace Bandl.VaultLedger.Web.UI
{
    /// <summary>
    /// Summary description for TaskHandler.
    /// </summary>
    public class AsyncHandler : IHttpAsyncHandler, IRequiresSessionState
    {
        #region IHttpHandler Members

        public void ProcessRequest(HttpContext c) 
        {
            // Not used
        }

        public bool IsReusable
        {
            get {return false;}
        }

        #endregion

        #region IHttpAsyncHandler Members

        public IAsyncResult BeginProcessRequest(HttpContext ctx, AsyncCallback cb, object o)
        {
            // Create a result object to be used by asp.net
            AsyncRequestState ars = new AsyncRequestState(ctx, cb, o);
            // Place the state object in the session cache
            ctx.Session[CacheKeys.AsyncResult] = ars;
            // Create a new request object to perform the main logic
            AsyncRequest q = new AsyncRequest(ars);
            // Create a new worker thread to perform the work (this thread is not taken from the CLR thread pool)
            new Thread(new ThreadStart(q.ProcessRequest)).Start();
            // Return the state object to asp.net
            return ars;
        }

        public void EndProcessRequest(IAsyncResult ar)
        {
            // Check if the result is of our type
            AsyncRequestState ars = (AsyncRequestState)ar;
            // Perform any clean up of any resources used
            if (ars != null)
            {
                ;
            }

        }
        #endregion
    }
}