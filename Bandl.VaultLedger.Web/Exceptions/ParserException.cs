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
    public class ParserException : BaseException
    {
        // Default constructor
        public ParserException() : base()
        {
        }

        // Constructor with exception message
        public ParserException(string message) : base(message)
        {
        }

        // Constructor with message and inner exception
        public ParserException(string message, Exception inner) : base(message, inner)
        {
        }

        // Protected constructor to de-serialize data
        protected ParserException(SerializationInfo info, StreamingContext context) : base(info, context)
        {
        }
    }
}
