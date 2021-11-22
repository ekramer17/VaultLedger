
TableScroller = function () 
{
    this.wrappers = [];
},

TableScroller.prototype = 
{
    add : function (id)
    {
        this.wrappers.push(id);
        return this;
    },

    doScroll : function(i1) // wrapper object id
    {
        // Do nothing if not IE
        if (navigator.appName == "Microsoft Internet Explorer")
        {
            var w1 = document.getElementById(i1);
            // Valid?
            if (w1 == null) return false;
            // Get tables
            var t1 = w1.getElementsByTagName('table');
            if (t1.length == 0) return false;
            // Display
            w1.style.overflowX = t1[0].rows != 0 && (w1.scrollWidth - 1 > w1.clientWidth) ? 'scroll' : '';
        }
        // Return
        return true;
    }
}

