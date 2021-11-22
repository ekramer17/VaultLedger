using System;
using Bandl.Library.VaultLedger.Exceptions;
using System.Text.RegularExpressions;

namespace Bandl.Library.VaultLedger.Model
{
	/// <summary>
	/// Summary description for PatternDetails.
	/// </summary>
	[Serializable]
	public abstract class PatternDetails : Details
	{
        protected string pattern;

        public string Pattern
        {
            get { return pattern; }
            set 
            { 
                if (null == value || 0 == value.Length)
                    throw new ValueRequiredException("Pattern", "Pattern is a required field.");
                else if (value.Length > 256)
                    throw new ValueFormatException("Pattern", "Pattern may not be longer than 256 characters.");
                else
                {
                    // Attempt to construct a new regular expression in order
                    // to assess the validity of the pattern
                    try 
                    {
                        Regex r = new Regex(value);
                    }
                    catch
                    {
                        throw new ValueException("Pattern", "'" + value + "' is not a valid bar code pattern.");
                    }
                }
                // Set the pattern
                pattern = value;
                // Set object state to modified
                this.ObjState = ObjectStates.Modified;
            }
        }
    }
}
