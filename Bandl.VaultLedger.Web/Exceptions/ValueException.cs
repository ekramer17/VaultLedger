using System;
using System.Runtime.Serialization;

namespace Bandl.Library.VaultLedger.Exceptions
{
    /// <summary>
    /// Generic business logic layer exception
    /// </summary>
    [Serializable]
    public class ValueException : BaseException
    {
        protected string parameter;

        // Default constructor
        public ValueException() : base()
        {
        }

        // Constructor with exception message
        public ValueException(string message) : base(message)
        {
        }

        // Constructor with message and inner exception
        public ValueException(string message, Exception inner) : base(message, inner)
        {
        }

        // Constructor with parameter and message
        public ValueException(string paramName, string message) : base(message)
        {
            parameter = paramName;
        }

        // Constructor with parameter, message, and inner exception
        public ValueException(string paramName, string message, Exception inner) : base(message, inner)
        {
            parameter = paramName;
        }

        // Protected constructor to de-serialize data
        protected ValueException(SerializationInfo info, StreamingContext context) : base(info, context)
        {
        }

        // Public property ParamName
        public virtual string ParamName
        {
            get {return parameter;}
        }
    }
}
