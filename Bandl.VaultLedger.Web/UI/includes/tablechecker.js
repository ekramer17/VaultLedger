
/// <summary>
/// Encapsulates the functionality of header/item checkbox synchronization, 
/// and provides a method to obtain checked rows (<tr> nodes).
/// </summary>
TableChecker = function (id) 
{
    this.myTotal = 0;           // total selected at the current time
    this.myItems = [];          // item checkboxes
    this.myHeader = null;       // header checkbox
    this.myId = id ? id : -1;   // index of cell that contains object id (optional)
},

TableChecker.prototype = 
{
    /// <summary>
    /// Initializes the checkbox group
    /// </summary>
    /// 1. id: id of element (usually table) that contains both header and item check boxes
    /// 2. suffix1: suffix of id of header checkbox (suffix only due to ASP.NET name mangling)
    /// 3. suffix2: suffix of id of item checkboxes (ditto)
    initialize : function(a1, s1)
    {
        // Get table element
        var e1 = document.getElementById(a1);
        // Make sure we have an element
        if (e1 == null) return null;
        // Loop through rows
        for (var i = 0; i < e1.rows.length; i += 1)
        {
            var b1 = e1.rows[i].getElementsByTagName("input");
            // Make sure we have one
            if (b1.length == 0) continue;
            // Header or item?
            if (i == 0)
            {
                this.myHeader = b1[0];
            }
            else
            {
                this.myItems.push(b1[0]);
                if (b1[0].checked) this.myTotal += 1;
            }
        }
        // Check header?
        if (this.myHeader)
        {
            this.myHeader.checked = this.myTotal != 0 && this.myTotal == this.myItems.length;
        }
        // Return
        return this;
    },
    /// <summary>
    /// Checks the rows that have id values contained in the comma-delimited string.  Useful on postbacks
    /// where some id values failed.
    /// </summary>
    reset : function(s1) 
    {
        // Reset total
        this.myTotal = 0;
        // Are we checking?
        var b1 = (s1 != null && s1.match(/[^,]/) != null);
        // Need comma at beginning and at end
        if (b1 && s1.charAt(0) != ',') s1 = ',' + s1;
        if (b1 && s1.charAt(s1.length-1) != ',') s1 += ',';
        // Loop through items
        for (var i = 0; i < this.myItems.length; i++)
        {
            if (!b1)
            {
                this.myItems[i].checked = false;
            }
            else
            {
                for (var p1 = this.myItems[i].parentNode; p1 != null; p1 = p1.parentNode)
                {
                    if (p1.nodeName.toLowerCase() == 'tr')
                    {
                        var x1 = s1.indexOf(',' + p1.getElementsByTagName('td')[this.myId].innerHTML + ',');
                        this.myItems[i].checked = (x1 != -1);
                        if (x1 != -1) this.myTotal += 1;
                        break;
                    }
                }
            }
        }
        // Check or uncheck header
        this.myHeader.checked = this.myItems.length != 0 && this.myTotal == this.myItems.length;
    },
    /// <summary>
    /// Click handler - synchronizes the header and item checkboxes.  All checkboxes in the group should employ this
    /// in the onclick event.  For example, if you have a javascript variable named cbg1 containing your checkboxgroup
    /// then each of the checkboxes assigned to the group should have its onclick as: onclick="cbg1.click(this)"
    /// </summary>
    click : function(o1) 
    {
        var c1 = o1.checked;

        if (this.myHeader && this.myHeader.id == o1.id)
        {
            for (var i = 0; i < this.myItems.length; i++)
            {
                if (this.myItems[i].checked != c1)
                {
                    this.myTotal += c1 ? 1 : -1;
                    this.myItems[i].checked = c1;
                }
            }
        }
        else
        {
            this.myTotal += c1 ? 1 : -1;
            this.myHeader.checked = this.myTotal != 0 && this.myTotal == this.myItems.length;
        }
    },
    /// <summary>
    /// Returns the checked rows of the group (actual tr nodes)
    /// </summary>
    checked : function() 
    {
        var r1 = [];
        // Get the checked rows
        for (var i = 0; i < this.myItems.length; i++)
        {
            if (this.myItems[i].checked)
            {
                var p1 = this.myItems[i].parentNode;
                while (p1 != null && p1.nodeName.toLowerCase() != 'tr')
                    p1 = p1.parentNode;
                if (p1 != null) r1.push(p1);
            }
        }
        // Return the array of row elements
        return r1;
    }
}

