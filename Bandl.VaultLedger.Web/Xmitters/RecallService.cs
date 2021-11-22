using System;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.Gateway.Recall;

namespace Bandl.Library.VaultLedger.Xmitters
{
	/// <summary>
	/// Summary description for RecallService.
	/// </summary>
	public class RecallService : BaseXmitter, IXmitter
	{
        private RecallGateway remoteProxy;

        // Constructor
        public RecallService() {remoteProxy = new RecallGateway();}

        /// <summary>
        /// Transmits a send list
        /// </summary>
        /// <param name="sendList">
        /// Discrete send list to transmit
        /// </param>
        public override void Transmit(SendListDetails sendList)
        {
            if (sendList.IsComposite)
            {
                throw new ApplicationException("Transmitter cannot transmit a composite list");
            }
            else
            {
                remoteProxy.TransmitSendList(sendList);
            }
        }

        /// <summary>
        /// Transmits a receive list
        /// </summary>
        /// <param name="receiveList">
        /// Discrete receive list to transmit
        /// </param>
        public override void Transmit(ReceiveListDetails receiveList)
        {
            if (receiveList.IsComposite)
            {
                throw new ApplicationException("Transmitter cannot transmit a composite list");
            }
            else
            {
                remoteProxy.TransmitReceiveList(receiveList);
            }
        }

        /// <summary>
        /// Transmits a disaster code list
        /// </summary>
        /// <param name="disasterList">
        /// Discrete disaster code list to transmit
        /// </param>
        public override void Transmit(DisasterCodeListDetails disasterList)
        {
            if (disasterList.IsComposite)
            {
                throw new ApplicationException("Transmitter cannot transmit a composite list");
            }
            else
            {
                remoteProxy.TransmitDisasterCodeList(disasterList);
            }
        }
    }
}
