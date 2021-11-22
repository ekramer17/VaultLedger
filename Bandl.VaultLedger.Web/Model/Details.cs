using System;
using System.Web;
using System.Text.RegularExpressions;

namespace Bandl.Library.VaultLedger.Model
{
    // Enumeration for state of object data
    [Serializable]
    public enum ObjectStates {Unmodified = 0, New = 1, Modified = 2, Deleted = 3};

    /// <summary>
	/// Abstract class for all Details classes
	/// </summary>
    [Serializable]
	public abstract class Details
	{
        private ObjectStates objState;
        private string rowError;

        public ObjectStates ObjState
        {
            get { return objState; }
            set { objState = value; }
        }

        public string RowError
        {
            get { return rowError != null ? rowError : String.Empty; }
            set { rowError = value; }
        }

        protected bool ContainsSQLWildcards(string str)
        {
            if (str.IndexOf("%") != -1 || str.IndexOf("_") != -1)
            {
                return true;
            }
            else
            {
                return false;
            }
        }

        protected bool IsValidPhoneNo(string phoneNo)
        {
            if (false == new Regex(@"[0-9( )+\-xX\.]*").IsMatch(phoneNo))
                return false;
            else if (phoneNo[0] != '(' && phoneNo[0] != '+' && (phoneNo[0] < '0' || phoneNo[0] > '9'))
                return false;    // Must start with left parenthesis, plus symbol, or digit
            else if (phoneNo[phoneNo.Length-1] < '0' || phoneNo[phoneNo.Length-1] > '9')
                return false;    // Must end with a digit
            else if (phoneNo.Length - phoneNo.Replace("(", "").Length > 2)
                return false;    // Cannot have more than two sets of parentheses
            else if (phoneNo.Length - phoneNo.Replace("-", "").Length > 2)
                return false;    // Cannot have more than two hyphens
            else if (phoneNo.Length - phoneNo.Replace(".", "").Length > 2)
                return false;    // Cannot have more than two periods
            else if (phoneNo.IndexOf("-") != -1 && phoneNo.IndexOf(".") != -1)
                return false;    // Cannot have both hyphens and periods
            else
            {
                for(int i = 0; i < phoneNo.Length; i++)
                {
                    try
                    {
                        switch (phoneNo[i])
                        {
                            case '(':
                                // 1. Right parenthesis must occur after left
                                // 2. Value between parentheses must be numeric, positive, and no more than three digits in length
                                string s = phoneNo.Substring(i + 1, phoneNo.IndexOf(")", i) - i - 1);
                                if (Convert.ToInt32(s) < 0 || Convert.ToInt32(s) > 999) throw new Exception();
                                break;
                            case ')':
                                // A left parenthesis must appear before a right parenthesis
                                if (phoneNo.IndexOf("(") == -1 || phoneNo.IndexOf("(") > i) throw new Exception();
                                break;
                            case '+':
                                // 1. Character after plus must be a digit
                                // 2. Plus may be either first ot second character.  If second, first must be left parenthesis.
                                if (phoneNo[i+1] < '0' || phoneNo[i+1] > '9') throw new Exception();
                                if (i > 1 || (i == 1 && phoneNo[0] != '(')) throw new Exception();
                                break;
                            case '-':
                            case '.':
                                // 1. No parenthesis may occur after the first hyphen or period
                                // 2. Hyphen must have a digit on either side
                                if (phoneNo.IndexOf("(", i) != -1) throw new Exception();
                                if (phoneNo[i-1] < '0' || phoneNo[i-1] > '9') throw new Exception();
                                if (phoneNo[i+1] < '0' || phoneNo[i+1] > '9') throw new Exception();
                                break;
                            case ' ':
                                // Whitespace must be followed be left parenthesis or digit
                                if (phoneNo[i+1] != '(' && (phoneNo[i+1] < '0' || phoneNo[i+1] > '9')) throw new Exception();
                                break;
                            case 'x':
                            case 'X':
                                // Only digits may follow an extension character
                                if (Convert.ToInt32(phoneNo.Substring(i+1)) < 1) throw new Exception();
                                break;
                            default:
                                break;
                        }
                    }
                    catch
                    {
                        return false;
                    }
                }
            }
            // Format is valid
            return true;
        }
    }
}
