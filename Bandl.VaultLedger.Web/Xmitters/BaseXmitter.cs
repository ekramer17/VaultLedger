using System;
using System.Threading;
using Bandl.Library.VaultLedger.Model;

namespace Bandl.Library.VaultLedger.Xmitters
{
	/// <summary>
	/// Summary description for BaseXmitter.
	/// </summary>
	public class BaseXmitter : IXmitter
	{
		private static object lockObject = new object();
		private int normalTimeout = 30;
		protected int NormalTimeout
		{
			get {return normalTimeout;}
		}

        public BaseXmitter() {}

		#region IXmitter Methods

        public virtual void Transmit(SendListDetails sendList) {}

        public virtual void Transmit(ReceiveListDetails receiveList) {}

        public virtual void Transmit(DisasterCodeListDetails disasterList) {}

		#endregion

		#region Xmitter Locking Methods

		protected void GrabLock()
		{
			Monitor.Enter(BaseXmitter.lockObject);
		}

		protected bool GrabLock(int timeout)
		{
			return Monitor.TryEnter(BaseXmitter.lockObject, TimeSpan.FromSeconds(timeout));
		}

		protected void ReleaseLock()
		{
			Monitor.Exit(BaseXmitter.lockObject);
		}

		#endregion
    }
}
