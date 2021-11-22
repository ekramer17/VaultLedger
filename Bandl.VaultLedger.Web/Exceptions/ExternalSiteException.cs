using System;
using System.Runtime.Serialization;

namespace Bandl.Library.VaultLedger.Exceptions
{
    /// <summary>
    /// Exception thrown in a method where an external site could not
    /// be resolved (given site does not correspond to any site in
    /// the database).
    /// </summary>
    [Serializable]
    public class ExternalSiteException : BLLException
    {
        // Default constructor
        public ExternalSiteException() : base()
        {
        }

        // Constructor with exception message
        public ExternalSiteException(string message) : base(message)
        {
        }

        // Constructor with message and inner exception
        public ExternalSiteException(string message, Exception inner) : base(message, inner)
        {
        }

        // Protected constructor to de-serialize data
        protected ExternalSiteException(SerializationInfo info, StreamingContext context) : base(info, context)
        {
        }
    }
}
