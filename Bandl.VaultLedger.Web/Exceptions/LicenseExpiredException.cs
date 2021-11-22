using System;
using System.Runtime.Serialization;

namespace Bandl.Library.VaultLedger.Exceptions
{
    /// <summary>
    /// Exception thrown when a license has expired
    /// </summary>
    [Serializable]
    public class LicenseExpiredException : BLLException
    {
        // Default constructor
        public LicenseExpiredException() : base()
        {
        }

        // Constructor with exception message
        public LicenseExpiredException(string message) : base(message)
        {
        }

        // Constructor with message and inner exception
        public LicenseExpiredException(string message, Exception inner) : base(message, inner)
        {
        }

        // Protected constructor to de-serialize data
        protected LicenseExpiredException(SerializationInfo info, StreamingContext context) : base(info, context)
        {
        }
    }
}
