using System;
using System.Runtime.Serialization;

namespace Bandl.Library.VaultLedger.Exceptions
{
    /// <summary>
    /// Generic business logic layer exception
    /// </summary>
    [Serializable]
    public class BLLException : BaseException
    {
        // Default constructor
        public BLLException() : base()
        {
        }

        // Constructor with exception message
        public BLLException(string message) : base(message)
        {
        }

        // Constructor with message and inner exception
        public BLLException(string message, Exception inner) : base(message, inner)
        {
        }

        // Protected constructor to de-serialize data
        protected BLLException(SerializationInfo info, StreamingContext context) : base(info, context)
        {
        }
    }
}
