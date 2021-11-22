using System;
using System.Runtime.Serialization;

namespace Bandl.Library.VaultLedger.Exceptions
{
    /// <summary>
    /// Exception thrown where an object expected to be found in the
    /// database was not found.
    /// </summary>
    [Serializable]
    public class ObjectNotFoundException : BLLException
    {
        // Default constructor
        public ObjectNotFoundException() : base()
        {
        }

        // Constructor with exception message
        public ObjectNotFoundException(string message) : base(message)
        {
        }

        // Constructor with message and inner exception
        public ObjectNotFoundException(string message, Exception inner) : base(message, inner)
        {
        }

        // Protected constructor to de-serialize data
        protected ObjectNotFoundException(SerializationInfo info, StreamingContext context) : base(info, context)
        {
        }
    }
}
