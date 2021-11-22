using System;

namespace Bandl.Library.VaultLedger.IDAL
{
	/// <summary>
	/// Summary description for ISubscription.
	/// </summary>
	public interface ISubscription
	{
        /// <summary>
        /// Returns the subscription number from the database
        /// </summary>
        /// <returns>
        /// Subscription number
        /// </returns>
        string GetSubscription();

        /// <summary>
        /// Inserts a subscription number in the database
        /// </summary>
        /// <param name="subscriptionNo">
        /// Subscription to insert into the database
        /// </param>
        void Insert(string subscriptionNo);
	}
}
