using System;
using Bandl.Library.VaultLedger.IDAL;
using Bandl.Library.VaultLedger.Model;
using Bandl.Library.VaultLedger.DALFactory;
using Bandl.Library.VaultLedger.Security;

namespace Bandl.Library.VaultLedger.BLL
{
	/// <summary>
	/// Summary description for Subscription.
	/// </summary>
	public class Subscription
	{
        /// <summary>
        /// Returns the subscription number from the database
        /// </summary>
        /// <returns>
        /// Subscription number
        /// </returns>
        public static string GetSubscription() 
        {
            return SubscriptionFactory.Create().GetSubscription();
        }

        /// <summary>
        /// Inserts a subscription number in the database
        /// </summary>
        /// <param name="subscriptionNo">
        /// Subscription to insert into the database
        /// </param>
        public static void Insert(string subscriptionNo)
        {
            // Must have administrator privileges
            CustomPermission.Demand(Role.Administrator);
            // Insert the subscription
            SubscriptionFactory.Create().Insert(subscriptionNo);
        }
    }
}
