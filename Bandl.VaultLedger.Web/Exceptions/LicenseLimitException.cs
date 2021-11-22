using System;
using System.Runtime.Serialization;

namespace Bandl.Library.VaultLedger.Exceptions
{
    /// <summary>
    /// Exceptiono thrown when a license has reached capacity
    /// </summary>
    [Serializable]
    public class LicenseLimitException : BLLException
    {
        // Default constructor
        public LicenseLimitException() : base()
        {
        }

        // Constructor with exception message
        public LicenseLimitException(string message) : base(message)
        {
        }

        // Constructor with message and inner exception
        public LicenseLimitException(string message, Exception inner) : base(message, inner)
        {
        }

        // Protected constructor to de-serialize data
        protected LicenseLimitException(SerializationInfo info, StreamingContext context) : base(info, context)
        {
        }
    }
}
