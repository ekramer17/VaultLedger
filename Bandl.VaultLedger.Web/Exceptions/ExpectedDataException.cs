using System;
using System.Runtime.Serialization;

namespace Bandl.Library.VaultLedger.Exceptions
{
    /// <summary>
    /// Summary description for ExpectedDataException.
    /// </summary>
    [Serializable]
    public class ExpectedDataException : BusinessLogicException
    {
        // Default constructor
        public ExpectedDataException() : base()
        {
        }

        // Constructor with exception message
        public ExpectedDataException(string message) : base(message)
        {
        }

        // Constructor with message and inner exception
        public ExpectedDataException(string message, Exception inner) : base(message, inner)
        {
        }

        // Protected constructor to de-serialize data
        protected ExpectedDataException(SerializationInfo info, StreamingContext context) : base(info, context)
        {
        }
    }
}
