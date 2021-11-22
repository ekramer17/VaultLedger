using System;
using System.Web;
using System.Threading;
using System.Security.Principal;
using Bandl.Library.VaultLedger.BLL;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.Collections;

namespace Bandl.VaultLedger.Web.UI
{
    /// <summary>
    /// Summary description for AsyncRequestResult.
    /// </summary>
    public class AsyncRequestState : IAsyncResult
    {
        private HttpContext ctx;
        private AsyncCallback cb;
        private ManualResetEvent ce = null; // complete event
        private object d;
        private bool isComplete = false;
		
        /// <summary>
        /// Default constructor
        /// </summary>
        /// <param name="ctx">Current Http Context</param>
        /// <param name="cb">Callback used by ASP.NET</param>
        /// <param name="d">Data set by the calling thread</param>
        public AsyncRequestState(HttpContext _ctx, AsyncCallback _cb, object _d)
        {
            ctx = _ctx;
            cb = _cb;
            d = _d;
        }

        /// <summary>
        /// Gets the current HttpContext associated with the request
        /// </summary>
        public HttpContext Context  {get {return ctx;}}

        /// <summary>
        /// Completes the request and tells the ASP.NET pipeline that the 
        /// execution is complete.
        /// </summary>
        public void Complete()
        {
            isComplete = true;
            // Complete any manually registered events
            lock(this)
                if(ce != null)
                    ce.Set();
            // Call any registered callback handers
            if (cb != null) cb(this);
        }

        #region IAsyncResult Members
        /// <summary>
        /// Gets the object on which one could perform a lock
        /// </summary>
        public object AsyncState
        {
            get { return d; }
        }
        /// <summary>
        /// Always returns false
        /// </summary>
        public bool CompletedSynchronously
        {
            get { return false; }
        }
        /// <summary>
        /// Gets a handle that a monitor could lock on.
        /// </summary>
        public WaitHandle AsyncWaitHandle
        {
            get
            {
                lock(this)
                {
                    if (ce == null)
                        ce = new ManualResetEvent(false);

                    return ce;
                }
            }
        }
        /// <summary>
        /// Gets the current status of the request
        /// </summary>
        public bool IsCompleted
        {
            get { return this.isComplete; }
        }
        #endregion
    }
}