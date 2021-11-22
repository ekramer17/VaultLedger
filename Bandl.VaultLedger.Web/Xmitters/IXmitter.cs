using System;
using Bandl.Library.VaultLedger.Model;

namespace Bandl.Library.VaultLedger.Xmitters
{
	/// <summary>
	/// Summary description for ITransmit interface.
	/// </summary>
	public interface IXmitter
	{
        /// <summary>
        /// Transmits a collection of send lists
        /// </summary>
        /// <param name="sendList">
        /// Collection of send lists to transmit
        /// </param>
        void Transmit(SendListDetails sendList);

        /// <summary>
        /// Transmits a receive list
        /// </summary>
        /// <param name="receiveList">
        /// Discrete receive list to transmit
        /// </param>
        void Transmit(ReceiveListDetails receiveList);

        /// <summary>
        /// Transmits a disaster code list
        /// </summary>
        /// <param name="disasterList">
        /// Discrete disaster code list to transmit
        /// </param>
        void Transmit(DisasterCodeListDetails disasterList);
    }
}
