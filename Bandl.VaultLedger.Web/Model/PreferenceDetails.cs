using System;
using System.Data;

namespace Bandl.Library.VaultLedger.Model
{
	/// <summary>
	/// Summary description for PreferenceDetails.
	/// </summary>
    [Serializable]
    public class PreferenceDetails : Details
	{
        private PreferenceKeys key;
        private string val;

		public PreferenceDetails(PreferenceKeys _key, string _value)
		{
            key = _key;
            Value = _value;
            this.ObjState = ObjectStates.New;
		}

        public PreferenceDetails(IDataReader r)
        {
            key = (PreferenceKeys)Enum.ToObject(typeof(PreferenceKeys),r.GetInt32(0));
            Value = r.GetString(1);
            this.ObjState = ObjectStates.Unmodified;
        }

        public PreferenceKeys Key
        {
            get {return key;}
        }

        public string Value
        {
            get {return val;}
            set 
            {
                if (value.ToUpper() == "TRUE")
                {
                    value = "YES";
                }
                else if (value.ToUpper() == "FALSE")
                {
                    value = "NO";
                }
                // Place the value.  Uppercase if case doesn't matter.
                switch (key)
                {
                    case PreferenceKeys.DateDisplayFormat:
                    case PreferenceKeys.TimeDisplayFormat:
                        val = value;
                        break;
                    case PreferenceKeys.NumberOfItemsPerPage:
                        try
                        {
                            int i = Int32.Parse(value);
                            val = i < 20 ? "20" : value;
                        }
                        catch
                        {
                            val = "20";
                        }
                        break;
                    case PreferenceKeys.MaxRfidSerialLength:
                        try
                        {
                            int i = Int32.Parse(value);
                            val = i < 4 ? "4" : value;
                        }
                        catch
                        {
                            val = "0";
                        }
                        break;
                    default:
                        val = value.ToUpper();
                        break;
                }
                // Mark object as modified
                this.ObjState = ObjectStates.Modified;
            }
        }

        public static PreferenceDetails CreateDefault(PreferenceKeys key)
        {
            string d;

            switch(key)
            {
                case PreferenceKeys.EmploySerialEditFormat:
                    d = "YES";
                    break;
                case PreferenceKeys.SendListCaseVerify:
                    d = "YES";
                    break;
                case PreferenceKeys.TmsDataSetNotes:
                    d = "REPLACE";
                    break;
                case PreferenceKeys.TmsReturnDates:
                    d = "YES";
                    break;
                case PreferenceKeys.TmsUnknownSite:
                    d = "YES";
                    break;
                case PreferenceKeys.InventoryExcludeActiveLists:
                    d = "YES";
                    break;
                case PreferenceKeys.InventoryExcludeTodaysLists:
                    d = "YES";
                    break;
                case PreferenceKeys.DeclareListAccounts:
                    d = "NO";
                    break;
                case PreferenceKeys.AllowTMSAccountAssigns:
                    d = "NO";
                    break;
                case PreferenceKeys.NumberOfItemsPerPage:
                    d = "20";
                    break;
                case PreferenceKeys.DateDisplayFormat:
                    d = "MM/dd/yyyy";
                    break;
                case PreferenceKeys.TimeDisplayFormat:
                    d = "h:mm:ss tt";
                    break;
                case PreferenceKeys.AllowOneClickVerify:
                    d = "YES";
                    break;
                case PreferenceKeys.AllowAddsOnReconcile:
                    d = Configurator.ProductType == "RECALL" ? "NO" : "YES";
                    break;
                case PreferenceKeys.ExportWithTabDelimiters:
                    d = "YES";
                    break;
                case PreferenceKeys.MaxRfidSerialLength:
                    d = "6";
                    break;
				case PreferenceKeys.ReceiveListAdminOnly:
					d = "NO";
					break;
                case PreferenceKeys.DissolveCompositeOnClear:
                    d = "NO";
                    break;
                case PreferenceKeys.DisplayNotesOnManifests:
                    d = "YES";
                    break;
                case PreferenceKeys.TmsSkipTapesNotResident:
                    d = "NO";
                    break;
                case PreferenceKeys.DestroyTapesAdminOnly:
                    d = "YES";
                    break;
                case PreferenceKeys.AllowAddsOnTMSListCreation:
                    d = "YES";
                    break;
                case PreferenceKeys.AllowDynamicListReplacement:
                    d = "YES";
                    break;
                case PreferenceKeys.CreateTapesAdminOnly:
                    d = "NO";
                    break;
                case PreferenceKeys.AssignAccountsOnReceiveListClear:
                    d = "NO";
                    break;
                default:
                    throw new ApplicationException("No default found for given preference key");
            }
            // Create the preference with the correct key
            return new PreferenceDetails(key, d);
        }
	}
}
