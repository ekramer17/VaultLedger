using System;
using System.Runtime.Serialization;

namespace Bandl.Library.VaultLedger.Exceptions
{
    /// <summary>
    /// Base for all custom exceptions
    /// </summary>
    [Serializable]
    public class BaseException : ApplicationException
    {
        // Default constructor
        public BaseException() : base()
        {
        }

        // Constructor with exception message
        public BaseException(string message) : base(message)
        {
        }

        // Constructor with message and inner exception
        public BaseException(string message, Exception inner) : base(message, inner)
        {
        }

        // Protected constructor to de-serialize data
        protected BaseException(SerializationInfo info, StreamingContext context) : base(info, context)
        {
        }
    }
}
