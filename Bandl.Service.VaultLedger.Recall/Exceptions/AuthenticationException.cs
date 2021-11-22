using System;
using System.Runtime.Serialization;

namespace Bandl.Service.VaultLedger.Recall.Exceptions
{
    /// <summary>
    /// Summary description for AuthenticationException.
    /// </summary>
    [Serializable]
    public class AuthenticationException : ApplicationException
    {
        // Default constructor
        public AuthenticationException() : base()
        {
        }

        // Constructor with exception message
        public AuthenticationException(string message) : base(message)
        {
        }

        // Constructor with message and inner exception
        public AuthenticationException(string message, Exception inner) : base(message, inner)
        {
        }

        // Protected constructor to de-serialize data
        protected AuthenticationException(SerializationInfo info, StreamingContext context) : base(info, context)
        {
        }
    }
}
