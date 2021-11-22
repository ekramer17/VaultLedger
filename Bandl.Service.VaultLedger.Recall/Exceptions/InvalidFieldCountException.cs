using System;
using System.Runtime.Serialization;

namespace Bandl.Service.VaultLedger.Recall.Exceptions
{
    /// <summary>
    /// Summary description for InvalidFieldCountException.
    /// </summary>
    [Serializable]
    public class InvalidFieldCountException : ApplicationException
    {
        // Default constructor
        public InvalidFieldCountException() : base()
        {
        }

        // Constructor with exception message
        public InvalidFieldCountException(string message) : base(message)
        {
        }

        // Constructor with message and inner exception
        public InvalidFieldCountException(string message, Exception inner) : base(message, inner)
        {
        }

        // Protected constructor to de-serialize data
        protected InvalidFieldCountException(SerializationInfo info, StreamingContext context) : base(info, context)
        {
        }
    }
}
