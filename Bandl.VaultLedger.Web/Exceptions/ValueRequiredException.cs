using System;
using System.Runtime.Serialization;

namespace Bandl.Library.VaultLedger.Exceptions
{
    /// <summary>
    /// Thrown when a required value has not been supplied, used often in the Model layer
    /// </summary>
    [Serializable]
    public class ValueRequiredException : ValueException
    {
        // Default constructor
        public ValueRequiredException() : base()
        {
        }

        // Constructor with exception message
        public ValueRequiredException(string message) : base(message)
        {
        }

        // Constructor with message and inner exception
        public ValueRequiredException(string message, Exception inner) : base(message, inner)
        {
        }

        // Constructor with parameter and message
        public ValueRequiredException(string paramName, string message) : base(paramName, message)
        {
        }

        // Constructor with parameter, message, and inner exception
        public ValueRequiredException(string paramName, string message, Exception inner) : base(paramName, message, inner)
        {
        }

        // Protected constructor to de-serialize data
        protected ValueRequiredException(SerializationInfo info, StreamingContext context) : base(info, context)
        {
        }
    }
}
