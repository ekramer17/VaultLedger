using System;
using System.Runtime.Serialization;

namespace Bandl.Library.VaultLedger.Exceptions
{
    /// <summary>
    /// Thrown when a string value has a length that is too long
    /// </summary>
    [Serializable]
    public class ValueLengthException : ValueException
    {
        // Default constructor
        public ValueLengthException() : base()
        {
        }

        // Constructor with exception message
        public ValueLengthException(string message) : base(message)
        {
        }

        // Constructor with message and inner exception
        public ValueLengthException(string message, Exception inner) : base(message, inner)
        {
        }

        // Constructor with parameter and message
        public ValueLengthException(string paramName, string message) : base(paramName, message)
        {
        }

        // Constructor with parameter, message, and inner exception
        public ValueLengthException(string paramName, string message, Exception inner) : base(paramName, message, inner)
        {
        }

        // Protected constructor to de-serialize data
        protected ValueLengthException(SerializationInfo info, StreamingContext context) : base(info, context)
        {
        }
    }
}
