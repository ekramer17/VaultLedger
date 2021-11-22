using System;
using System.Runtime.Serialization;

namespace Bandl.Library.VaultLedger.Exceptions
{
    /// <summary>
    /// Exception thrown in a method where an object passed as a parameter
    /// has an object state inconsistent with the object state that the
    /// method expects.
    /// </summary>
    [Serializable]
    public class RouterException : BaseException
    {
        // Default constructor
        public RouterException() : base()
        {
        }

        // Constructor with exception message
        public RouterException(string message) : base(message)
        {
        }

        // Constructor with message and inner exception
        public RouterException(string message, Exception inner) : base(message, inner)
        {
        }

        // Protected constructor to de-serialize data
        protected RouterException(SerializationInfo info, StreamingContext context) : base(info, context)
        {
        }
    }
}
