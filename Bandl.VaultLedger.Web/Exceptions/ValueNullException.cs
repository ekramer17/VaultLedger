using System;
using System.Runtime.Serialization;

namespace Bandl.Library.VaultLedger.Exceptions
{
    /// <summary>
    /// Thrown when a value has been supplied as null when a null is not allowed
    /// </summary>
    [Serializable]
    public class ValueNullException : ValueException
    {
        // Default constructor
        public ValueNullException() : base()
        {
        }

        // Constructor with exception message
        public ValueNullException(string message) : base(message)
        {
        }

        // Constructor with message and inner exception
        public ValueNullException(string message, Exception inner) : base(message, inner)
        {
        }

        // Constructor with parameter and message
        public ValueNullException(string paramName, string message) : base(paramName, message)
        {
        }

        // Constructor with parameter, message, and inner exception
        public ValueNullException(string paramName, string message, Exception inner) : base(paramName, message, inner)
        {
        }

        // Protected constructor to de-serialize data
        protected ValueNullException(SerializationInfo info, StreamingContext context) : base(info, context)
        {
        }
    }
}
