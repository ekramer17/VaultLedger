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
    public class ObjectStateException : BLLException
    {
        // Default constructor
        public ObjectStateException() : base()
        {
        }

        // Constructor with exception message
        public ObjectStateException(string message) : base(message)
        {
        }

        // Constructor with message and inner exception
        public ObjectStateException(string message, Exception inner) : base(message, inner)
        {
        }

        // Protected constructor to de-serialize data
        protected ObjectStateException(SerializationInfo info, StreamingContext context) : base(info, context)
        {
        }
    }
}
