using System;
using System.Collections;
using System.ComponentModel;
using System.Drawing;
using System.Globalization;
using System.Text;
using System.Web;
using System.Web.UI;
using System.Web.UI.HtmlControls;
using System.Web.UI.WebControls;

[assembly: TagPrefix("Bandl.Web.UI.WebControls", "Bandl")]

namespace Bandl.Web.UI.WebControls
{
    /// <summary>
    /// A replacement for the <see cref="System.Web.UI.WebControls.Calendar"/> control.
    /// Displays a single month calendar that allows the user to select dates and move to the next or previous month.
    /// </summary>
    /// <remarks>
    /// <para>
    /// The <see cref="System.Web.UI.WebControls.Calendar"/> control is a useful tool but it does have some shortcomings:
    /// </para>
    /// <list type="bullet">
    /// <item><description>
    /// It generates inline style attributes on several HTML elements rendered for the control.
    /// These inline styles will override any style settings for those elements assigned via CSS classes, making it impossible to style the control using only style sheets.
    /// </description></item>
    /// <item><description>
    /// It applies only one <see cref="System.Web.UI.WebControls.Style.CssClass"/> style class from
    /// <see cref="System.Web.UI.WebControls.Calendar.DayStyle"/>,
    /// <see cref="System.Web.UI.WebControls.Calendar.WeekendDayStyle"/>,
    /// <see cref="System.Web.UI.WebControls.Calendar.OtherMonthDayStyle"/>,
    /// <see cref="System.Web.UI.WebControls.Calendar.TodayDayStyle"/> and
    /// <see cref="System.Web.UI.WebControls.Calendar.SelectedDayStyle"/>,
    /// to a given calendar day, even though several may apply.
    /// </description></item>
    /// <item><description>
    /// When week or month selectors are used, all dates within the given range are included in the selection even if the
    /// <see cref="System.Web.UI.WebControls.CalendarDay.IsSelectable"/> property of their corresponding
    /// <see cref="System.Web.UI.WebControls.CalendarDay"/> has been set to <strong>false</strong> via a
    /// <see cref="System.Web.UI.WebControls.Calendar.DayRender"/> event handler.
    /// </description></item>
    /// </list>
    /// <para>
    /// This derived control corrects the style class problems by rendering the control without default inline styles.
    /// Also, multiple style classes are assigned to individual calendar days when appropriate.
    /// For example, if today's date happened to fall on a weekend, the table cell for that day would have two class names in it's class attribute
    /// (the <see cref="System.Web.UI.WebControls.Style.CssClass"/> property values of both <see cref="System.Web.UI.WebControls.Calendar.TodayDayStyle"/> and <see cref="System.Web.UI.WebControls.Calendar.OtherMonthDayStyle"/>).
    /// Note that individual style properties, such as <see cref="System.Web.UI.WebControls.Style.ForeColor"/> and <see cref="System.Web.UI.WebControls.Style.BackColor"/>, <see cref="System.Web.UI.WebControls.Style.Width"/> and <see cref="System.Web.UI.WebControls.Style.Height"/>, etc. can be still be used.
    /// </para>
    /// <para>
    /// When week and month selectors are used, the <see cref="SelectAllInRange"/> property determines if dates that were marked nonselectable in the given range are included in the selection.
    /// Setting this property to <strong>true</strong> causes the control to follow the behavior of the <see cref="System.Web.UI.WebControls.Calendar"/> control.
    /// When set to <strong>false</strong> (the default), nonselectable dates are excluded from the selection.
    /// </para>
    /// <para>
    /// There are also some additional features provided by the control.
    /// </para>
    /// <para>
    /// You can limit the months the user is able to navigate.
    /// Setting the <see cref="MinVisibleDate"/> and/or <see cref="MaxVisibleDate"/> properties removes the previous and/or month navigation elements when appropriate, preventing the user from viewing months outside the defined range.
    /// Note that you can still programmatically set <see cref="System.Web.UI.WebControls.Calendar.VisibleDate"/> to a value outside this range, if desired.
    /// </para>
    /// <para>
    /// Finally, the <see cref="ShowLinkTitles"/> property, when set to <strong>true</strong>, adds HTML title attributes to links within the control, describing their function and improving web page accessibility.
    /// </para>
    /// </remarks>
    /// <seealso cref="System.Web.UI.WebControls.Calendar"/>
    [DefaultEvent("SelectionChanged"),
    ToolboxBitmap(typeof(BandlCalendar), "BandlCalendar.bmp"),
    ToolboxData("<{0}:BandlCalendar runat=\"server\"></{0}:BandlCalendar>")]
    public class BandlCalendar : System.Web.UI.WebControls.Calendar, IPostBackEventHandler
    {
        private enum LinkType {PrevYear, PrevMonth, NextMonth, NextYear}

        #region Public properties
        /// <summary>
        /// Gets or sets a value that indicates whether dates marked as nonselectable should be included in week and month selections.
        /// </summary>
        /// <value>
        /// <strong>true</strong> if all dates should be included when a week or month is selected by the user; otherwise <strong>false</strong>. The default value is <strong>false</strong>.
        /// </value>
        /// <remarks>
        /// <para>
        /// Days may be made nonselectable by setting the <see cref="System.Web.UI.WebControls.CalendarDay.IsSelectable"/> property to <strong>false</strong> on the <see cref="System.Web.UI.WebControls.CalendarDay"/> object passed to the <see cref="System.Web.UI.WebControls.Calendar.DayRender"/> event handler.
        /// However, with the <see cref="System.Web.UI.WebControls.Calendar"/> class, when a user selects a week or month, <em>all</em> dates in that week or month are included regardless of the date's corresponding <see cref="System.Web.UI.WebControls.CalendarDay.IsSelectable"/> value.
        /// </para>
        /// <para>
        /// The <see cref="BandlCalendar"/> class <em>does not</em> include such dates by default.
        /// Setting <strong>SelectAllInRange</strong> to <strong>true</strong> will cause those dates to be included just as the <see cref="System.Web.UI.WebControls.Calendar"/> class does.
        /// </para>
        /// </remarks>
        [Bindable(true), 
        Category("Behavior"), 
        Description("Whether nonselectable days are included in week and month selections."), 
        DefaultValue(false)]
        public Boolean SelectAllInRange
        {
            get
            {
                object o = this.ViewState["SelectAllInRange"];
                if (o != null)
                    return Boolean.Parse(o.ToString());
                else
                    return false;
            }
            set { this.ViewState["SelectAllInRange"] = value.ToString(); }
        }

        /// <summary>
        /// Gets or sets a value indicating whether the links for navigation and date selection on the <see cref="BandlCalendar"/> control are given title attributes describing their function.
        /// </summary>
        /// <value>
        /// <strong>true</strong> if descriptive title attributes are given to the links; otherwise, <strong>false</strong>. The default value is <strong>false</strong>.
        /// </value>
        /// <remarks>
        /// <para>
        /// The HTML title attribute can be used on an element tag to provide additional information and is often used to make a web page more accessible.
        /// Many browsers render this information in a tool tip but it may also be presented in other ways, such as speech or Braille.
        /// </para>
        /// <para>
        /// Note that while day names, month names and dates in the title text are generated according to the current culture (see <see cref="System.Globalization.CultureInfo"/>), the remaining text is fixed as English.
        /// </para>
        /// </remarks>
        [Bindable(true),
        Category("Appearance"),
        Description("True if title attributes are added to navigation and selector links."),
        DefaultValue(false)]
        public Boolean ShowLinkTitles
        {
            get
            {
                object o = this.ViewState["ShowLinkTitles"];
                if (o != null)
                    return Boolean.Parse(o.ToString());
                else
                    return false;
            }
            set { this.ViewState["ShowLinkTitles"] = value.ToString(); }
        }

        /// <summary>
        /// Displays or hides the navigation controls to the next or previous year.
        /// </summary>
        /// <value>
        /// <strong>true</strong> if we should display navigation controls to the next or previous year; otherwise <strong>false</strong>. The default value is <strong>false</strong>.
        /// </value>
        /// <remarks>
        /// </remarks>
        [Bindable(true), 
        Category("Behavior"), 
        Description("Displays or hides the navigation controls to the next or previous year."), 
        DefaultValue(false)]
        public Boolean ShowNextPrevYear
        {
            get
            {
                object o = this.ViewState["ShowNextPrevYear"];
                return o != null ? Boolean.Parse(o.ToString()) : false;
            }
            set 
            { 
                this.ViewState["ShowNextPrevYear"] = value.ToString(); 
            }
        }
        /// <summary>
        /// Gets or sets the date that specifies the maximum month that can be displayed on the <see cref="BandlCalendar"/> control.
        /// </summary>
        /// <value>
        /// A <see cref="System.DateTime"/> object that specifies the minimum month to display on the <see cref="BandlCalendar"/> control.
        /// The default value is <see cref="DateTime.MaxValue"/>, which signifies that no maximum is set.
        /// </value>
        /// <remarks>
        /// The <see cref="MinVisibleDate"/> and <strong>MaxVisibleDate</strong> properties can be used to limit the range of months that the user can navigate to using the next and previous month elements on the control.
        /// </remarks>
        /// <seealso cref="MaxVisibleDate"/>
        [Bindable(true),
        Category("Misc"),
        Description("The maximum month that can be displayed."),
        DefaultValue("")]
        public DateTime MaxVisibleDate
        {
            get
            {
                object o = this.ViewState["MaxVisibleDate"];
                if (o != null)
                    return DateTime.Parse(o.ToString());
                else
                    return DateTime.MaxValue;
            }
            set { this.ViewState["MaxVisibleDate"] = value.ToString(); }
        }

        /// <summary>
        /// Gets or sets the date that specifies the minimum month that can be displayed on the <see cref="BandlCalendar"/> control.
        /// </summary>
        /// <value>
        /// A <see cref="System.DateTime"/> object that specifies the minimum month to display on the <see cref="BandlCalendar"/> control.
        /// The default value is <see cref="DateTime.MinValue"/>, which indicates that no minimum is set.
        /// </value>
        /// <remarks>
        /// The <strong>MinVisibleDate</strong> and <see cref="MaxVisibleDate"/> properties can be used to limit the range of months that the user can navigate to using the next and previous month elements on the control.
        /// </remarks>
        /// <seealso cref="MaxVisibleDate"/>
        [Bindable(true),
        Category("Misc"),
        Description("The minumum month that can be displayed."),
        DefaultValue("")]
        public DateTime MinVisibleDate
        {
            get
            {
                object o = this.ViewState["MinVisibleDate"];
                if (o != null)
                    return DateTime.Parse(o.ToString());
                else
                    return DateTime.MinValue;
            }
            set { this.ViewState["MinVisibleDate"] = value.ToString(); }
        }
        #endregion

        #region Private properties
        // Gets the date that specifies the month to be displayed. This will
        // be VisibleDate unless that property is defaulted to
        // DateTime.MinValue, in which case TodaysDate is returned instead.
        private DateTime TargetDate
        {
            get
            {
                return this.VisibleDate != DateTime.MinValue ? this.VisibleDate : this.TodaysDate;
            }
        }

        // This is the date used for creating day count values, i.e., the
        // number of days between some date and this one. These values are
        // used to create post back event arguments identical to those used
        // by the base Calendar class.
        private static readonly DateTime DayCountBaseDate = new DateTime(2000, 1, 1);
        #endregion

        /// <summary>
        /// Initializes a new instance of the <see cref="BandlCalendar"/> class.
        /// </summary>
        /// <remarks>
        /// Use this constructor to create and initialize a new instance of
        /// the <see cref="BandlCalendar"/> class.
        /// </remarks>
        public BandlCalendar() : base()
        {
            // Set today's date for users in different time zone
            this.TodaysDate = Bandl.Library.VaultLedger.Model.Time.Local;
        }

        #region Control rendering
        /// <summary> 
        /// This member overrides <see cref="System.Web.UI.Control.Render"/>.
        /// </summary>
        protected override void Render(HtmlTextWriter output)
        {
            // Create the main table.
            Table table = new Table();
            table.CellPadding = this.CellPadding;
            table.CellSpacing = this.CellSpacing;
            table.BorderColor = Color.LightGray;
            table.BorderWidth = 1;

            if (this.ShowGridLines)
                table.GridLines = GridLines.Both;
            else
                table.GridLines = GridLines.None;

            // If ShowTitle is true, add a row with the calendar title.
            if (this.ShowTitle)
            {
                // Create a one-cell table row.
                TableRow row = new TableRow();
                TableCell cell = new TableCell();
                if (this.HasWeekSelectors(this.SelectionMode))
                    cell.ColumnSpan = 8;
                else
                    cell.ColumnSpan = 7;

                // Apply styling.
                cell.MergeStyle(this.TitleStyle);

                // Add the title table to the cell.
                cell.Controls.Add(this.TitleTable());
                row.Cells.Add(cell);

                // Add it to the table.
                table.Rows.Add(row);
            }

            // If ShowDayHeader is true, add a row with the days header.
            if (this.ShowDayHeader)
                table.Rows.Add(DaysHeaderTableRow());

            // Find the first date that will be visible on the calendar.
            DateTime date = this.GetFirstCalendarDate();

            // Create a list for storing nonselectable dates.
            ArrayList nonselectableDates = new ArrayList();

            // Add rows for the dates (six rows are always displayed).
            for (int i = 0; i < 6; i++)
            {
                TableRow row = new TableRow();

                // Create a week selector, if needed.
                if (this.HasWeekSelectors(this.SelectionMode))
                {
                    TableCell cell = new TableCell();
                    cell.HorizontalAlign = HorizontalAlign.Center;
                    cell.MergeStyle(this.SelectorStyle);

                    if (this.Enabled)
                    {
                        // Create the post back link.
                        HtmlAnchor anchor = new HtmlAnchor();
                        string arg = String.Format("R{0}07", this.DayCountFromDate(date));
                        anchor.HRef = Page.ClientScript.GetPostBackClientHyperlink(this, arg);

                        // If ShowLinkTitles is true, add a title.
                        if (this.ShowLinkTitles)
                            anchor.Attributes.Add("title",
                                String.Format("Select the week starting {0}", date.ToString("D")));

                        anchor.Controls.Add(new LiteralControl(this.SelectWeekText));

                        // Add a color style to the anchor if it is explicitly
                        // set.
                        if (!this.SelectorStyle.ForeColor.IsEmpty)
                            anchor.Attributes.Add("style", String.Format("color:{0}", this.SelectorStyle.ForeColor.Name));

                        cell.Controls.Add(anchor);
                    }
                    else
                        cell.Controls.Add(new LiteralControl(this.SelectWeekText));

                    row.Cells.Add(cell);
                }

                // Add the days (there are always seven days per row).
                for (int j = 0; j < 7; j++)
                {
                    // Create a CalendarDay and a TableCell for the date.
                    CalendarDay day = this.Day(date);
                    TableCell cell = this.Cell(day);

                    // Raise the OnDayRender event.
                    this.OnDayRender(cell, day);

                    // If the day was marked nonselectable, add it to the list.
                    if (!day.IsSelectable)
                        nonselectableDates.Add(day.Date.ToShortDateString());

                    // If the day is selectable, and the selection mode allows
                    // it, convert the text to a link with post back.
                    if (this.Enabled && day.IsSelectable &&
                        this.SelectionMode != CalendarSelectionMode.None)
                    {
                        try
                        {
                            // Create the post back link.
                            HtmlAnchor anchor = new HtmlAnchor();
                            string arg = this.DayCountFromDate(date).ToString();
                            anchor.HRef = Page.ClientScript.GetPostBackClientHyperlink(this, arg);

                            // If ShowLinkTitles is true, add a title.
                            if (this.ShowLinkTitles)
                                anchor.Attributes.Add("title",
                                    String.Format("Select {0}", day.Date.ToString("D")));
							
                            // Copy the existing text.
                            anchor.Controls.Add(new LiteralControl(((LiteralControl) cell.Controls[0]).Text));

                            // Add a color style to the anchor if it is
                            // explicitly set. Note that the style precedence
                            // follows that of the base Calendar control.
                            string s = "";
                            if (!this.DayStyle.ForeColor.IsEmpty)
                                s = this.DayStyle.ForeColor.Name;
                            if (day.IsWeekend && !this.WeekendDayStyle.ForeColor.IsEmpty)
                                s = this.WeekendDayStyle.ForeColor.Name;
                            if (day.IsOtherMonth && !this.OtherMonthDayStyle.ForeColor.IsEmpty)
                                s = this.OtherMonthDayStyle.ForeColor.Name;
                            if (day.IsToday && !this.TodayDayStyle.ForeColor.IsEmpty)
                                s = this.TodayDayStyle.ForeColor.Name;
                            if (this.SelectedDates.Contains(day.Date) && !this.SelectedDayStyle.ForeColor.IsEmpty)
                                s = this.SelectedDayStyle.ForeColor.Name;
                            if (s.Length > 0)
                                anchor.Attributes.Add("style", String.Format("color:{0}", s));
							
                            // Replace the literal control in the cell with
                            // the anchor.
                            cell.Controls.RemoveAt(0);
                            cell.Controls.AddAt(0, anchor);
                        }
                        catch
                        {
                            ;
                        }
                    }

                    // Add the cell to the current table row.
                    row.Cells.Add(cell);

                    // Bump the date.
                    date = date.AddDays(1);
                }

                // Add the row.
                table.Rows.Add(row);
            }

            // Save the list of nonselectable dates.
            if (nonselectableDates.Count > 0)
                this.SaveNonselectableDates(nonselectableDates);

            // Apply styling.
            this.AddAttributesToRender(output);

            // Render the table.
            table.RenderControl(output);
        }

        // ====================================================================
        // Helper functions for rendering the control.
        // ====================================================================

        //
        // Generates a Table control for the calendar title.
        //
        private Table TitleTable()
        {
            TableCell prevYear = null;
            TableCell nextYear = null;
            TableCell prevMonth = null;
            TableCell nextMonth = null;

            // Create the year link cells
            if (this.ShowNextPrevYear)
            {
                prevYear = this.BuildMonthYearLink(LinkType.PrevYear);
                nextYear = this.BuildMonthYearLink(LinkType.NextYear);
                // If we're creating month cells as well, we need to create separation
                if (this.ShowNextPrevMonth)
                {
                    prevYear.Controls.Add(new LiteralControl("&nbsp;&nbsp;&nbsp;"));
                    nextYear.Controls.AddAt(0, new LiteralControl("&nbsp;&nbsp;&nbsp;"));
                }
            }
            // Create the month link cells
            if (this.ShowNextPrevMonth)
            {
                prevMonth = this.BuildMonthYearLink(LinkType.PrevMonth);
                nextMonth = this.BuildMonthYearLink(LinkType.NextMonth);
            }
            // Create a table row.
            TableRow tableRow = new TableRow();
            // Add the prev cells
            if (prevYear != null) tableRow.Cells.Add(prevYear);
            if (prevMonth != null) tableRow.Cells.Add(prevMonth);
            // Create the table title
            TableCell tableCell = new TableCell();
            tableCell.HorizontalAlign = HorizontalAlign.Center;
            if (this.ShowNextPrevMonth || this.ShowNextPrevYear)
                tableCell.Style.Add("width", "70%");
            else
                tableCell.Style.Add("width", "100%");
            if (this.TitleFormat == TitleFormat.Month)
                tableCell.Text = this.TargetDate.ToString("MMMM");
            else
                tableCell.Text = this.TargetDate.ToString("y").Replace(", ", " ");
            tableCell.Font.Size = this.TitleStyle.Font.Size;
            tableCell.Font.Bold = this.TitleStyle.Font.Bold;
            tableCell.Font.Italic = this.TitleStyle.Font.Italic;
            if (!this.TitleStyle.ForeColor.IsEmpty)
                tableCell.ForeColor = this.TitleStyle.ForeColor;
            // Add table title cell to row
            tableRow.Cells.Add(tableCell);
            // Add the next cells
            if (nextMonth != null) tableRow.Cells.Add(nextMonth);
            if (nextYear != null) tableRow.Cells.Add(nextYear);
            // Create the table and add the title row to it.
            Table titleTable = new Table();
            titleTable.CellPadding = 0;
            titleTable.CellSpacing = 0;
            titleTable.Attributes.Add("style", "width:100%;");
            titleTable.Rows.Add(tableRow);
            // Return the table
            return titleTable;
        }

        /// <summary>
        /// Builds the link for the previous year
        /// </summary>
        /// <returns></returns>
        private TableCell BuildMonthYearLink(LinkType linkType)
        {
            TableCell tableCell = new TableCell();
            string linkText = null;
            string firstChar = null;
            DateTime linkDate;

            tableCell.MergeStyle(this.NextPrevStyle);
            // Find the first of the previous year, needed for post back processing.
            try
            {
                switch (linkType)
                {
                    case LinkType.PrevYear:
                        linkDate = new DateTime(this.TargetDate.Year, this.TargetDate.Month, 1).AddYears(-1);
                        break;
                    case LinkType.PrevMonth:
                        linkDate = new DateTime(this.TargetDate.Year, this.TargetDate.Month, 1).AddMonths(-1);
                        break;
                    case LinkType.NextMonth:
                        linkDate = new DateTime(this.TargetDate.Year, this.TargetDate.Month, 1).AddMonths(1);
                        break;
                    case LinkType.NextYear:
                        linkDate = new DateTime(this.TargetDate.Year, this.TargetDate.Month, 1).AddYears(1);
                        break;
                    default:
                        linkDate = this.TargetDate;
                        break;
                }
            }
            catch
            {
                linkDate = this.TargetDate;
            }
            // Get the date text and the first letter of the link name
            switch (linkType)
            {
                case LinkType.PrevYear:
                    firstChar = "Y";
                    tableCell.HorizontalAlign = HorizontalAlign.Left;
                    if (this.NextPrevFormat == NextPrevFormat.CustomText)
                        linkText = String.Format("{0}{0}", this.PrevMonthText);
                    else
                        linkText = linkDate.ToString("yyyy");
                    break;
                case LinkType.PrevMonth:
                    firstChar = "V";
                    tableCell.HorizontalAlign = HorizontalAlign.Left;
                    if (this.NextPrevFormat == NextPrevFormat.CustomText)
                        linkText = this.PrevMonthText;
                    else
                        linkText = linkDate.ToString(this.NextPrevFormat != NextPrevFormat.ShortMonth ? "MMMM" : "MMM");
                    break;
                case LinkType.NextMonth:
                    firstChar = "V";
                    tableCell.HorizontalAlign = HorizontalAlign.Right;
                    if (this.NextPrevFormat == NextPrevFormat.CustomText)
                        linkText = this.NextMonthText;
                    else
                        linkText = linkDate.ToString(this.NextPrevFormat != NextPrevFormat.ShortMonth ? "MMMM" : "MMM");
                    break;
                case LinkType.NextYear:
                    firstChar = "Y";
                    tableCell.HorizontalAlign = HorizontalAlign.Right;
                    if (this.NextPrevFormat == NextPrevFormat.CustomText)
                        linkText = String.Format("{0}{0}", this.NextMonthText);
                    else
                        linkText = linkDate.ToString("yyyy");
                    break;
            }
            // If disabled, just write the year text to a literal control
            if (this.Enabled == false)
            {
                tableCell.Controls.Add(new LiteralControl(linkText));
                tableCell.Font.Size = this.TitleStyle.Font.Size;
                tableCell.Font.Bold = this.TitleStyle.Font.Bold;
                tableCell.Font.Italic = this.TitleStyle.Font.Italic;
                if (!this.TitleStyle.ForeColor.IsEmpty)
                    tableCell.ForeColor = this.TitleStyle.ForeColor;
            }
            else if (new DateTime(this.MinVisibleDate.Year, this.MinVisibleDate.Month, 1) > linkDate)
            {
                // Do nothing -- previous year out of range
            }
            else if (new DateTime(this.MaxVisibleDate.Year, this.MaxVisibleDate.Month, 1) < linkDate)
            {
                // Do nothing -- previous year out of range
            }
            else
            {
                HtmlAnchor anchor = new HtmlAnchor();
                string linkName = String.Format("{0}{1}", firstChar, this.DayCountFromDate(linkDate));
                anchor.HRef = Page.ClientScript.GetPostBackClientHyperlink(this, linkName);
                // Add a color style to the anchor if it is explicitly set
                if (!this.NextPrevStyle.ForeColor.IsEmpty)
                    anchor.Attributes.Add("style", String.Format("color:{0}", this.NextPrevStyle.ForeColor.Name));
                // If ShowLinkTitles is true, add a title.
                if (this.ShowLinkTitles)
                    anchor.Attributes.Add("title", String.Format("View {0}", linkDate.ToString("Y")));
                // Add a label control to the anchor
                Label labelControl = new Label();
                labelControl.Text = linkText;
                labelControl.Font.Size = this.TitleStyle.Font.Size;
                labelControl.Font.Bold = this.TitleStyle.Font.Bold;
                labelControl.Font.Italic = this.TitleStyle.Font.Italic;
                if (!this.TitleStyle.ForeColor.IsEmpty)
                    labelControl.ForeColor = this.TitleStyle.ForeColor;
                // Add the label control to the anchor
                anchor.Controls.Add(labelControl);
                // Add the anchor to the cell
                tableCell.Controls.Add(anchor);
            }
            // Return the table cell
            return tableCell;
        }

        //
        // Generates a TableRow control for the calendar days header.
        //
        private TableRow DaysHeaderTableRow()
        {
            // Create the table row.
            TableRow row = new TableRow();

            // Create an array of days.
            DayOfWeek[] days = {
                                   DayOfWeek.Sunday,
                                   DayOfWeek.Monday,
                                   DayOfWeek.Tuesday,
                                   DayOfWeek.Wednesday,
                                   DayOfWeek.Thursday,
                                   DayOfWeek.Friday,
                                   DayOfWeek.Saturday
                               };

            // Adjust the array to get the specified starting day at the first index.
            DayOfWeek first = this.GetFirstDayOfWeek();
            while(days[0] != first)
            {
                DayOfWeek temp = days[0];
                for (int i = 0; i < days.Length - 1; i++)
                    days[i] = days[i + 1];
                days[days.Length - 1] = temp;
            }

            // Add a month selector column, if needed.
            if (this.HasWeekSelectors(this.SelectionMode))
            {
                TableCell cell = new TableCell();
                cell.HorizontalAlign = HorizontalAlign.Center;

                // If months are selectable, create the selector.
                if (this.SelectionMode == CalendarSelectionMode.DayWeekMonth)
                {
                    // Find the first of the month.
                    DateTime date = new DateTime(this.TargetDate.Year, this.TargetDate.Month, 1);

                    // Use the selector style.
                    cell.MergeStyle(this.SelectorStyle);

                    // Create the post back link.
                    if (this.Enabled)
                    {
                        HtmlAnchor anchor = new HtmlAnchor();
                        string arg = String.Format("R{0}{1}",
                            this.DayCountFromDate(date),
                            DateTime.DaysInMonth(date.Year, date.Month));
                        anchor.HRef = Page.ClientScript.GetPostBackClientHyperlink(this, arg);

                        // If ShowLinkTitles is true, add a title.
                        if (this.ShowLinkTitles)
                            anchor.Attributes.Add("title",
                                String.Format("Select the month of {0}", date.ToString("Y")));

                        anchor.Controls.Add(new LiteralControl(this.SelectMonthText));

                        // Add a color style to the anchor if it is explicitly
                        // set.
                        if (!this.SelectorStyle.ForeColor.IsEmpty)
                            anchor.Attributes.Add("style", String.Format("color:{0}", this.SelectorStyle.ForeColor.Name));

                        cell.Controls.Add(anchor);
                    }
                    else
                        cell.Controls.Add(new LiteralControl(this.SelectMonthText));
                }
                else
                    // Use the day header style.
                    cell.CssClass = this.DayHeaderStyle.CssClass;

                row.Cells.Add(cell);
            }

            // Add the day names to the header.
            foreach (System.DayOfWeek day in days)
                row.Cells.Add(this.DayHeaderTableCell(day));

            return row;
        }

        //
        // Returns a table cell containing a day name for the calendar day
        // header.
        //
        private TableCell DayHeaderTableCell(System.DayOfWeek dayOfWeek)
        {
            // Generate the day name text based on the specified format.
            string s;
            if (this.DayNameFormat == DayNameFormat.Short)
                s = CultureInfo.CurrentCulture.DateTimeFormat.AbbreviatedDayNames[(int) dayOfWeek];
            else
            {
                s = CultureInfo.CurrentCulture.DateTimeFormat.DayNames[(int) dayOfWeek];
                if (this.DayNameFormat == DayNameFormat.FirstTwoLetters)
                    s = s.Substring(0, 2);
                if (this.DayNameFormat == DayNameFormat.FirstLetter)
                    s = s.Substring(0, 1);
            }

            // Create the cell, set the style and the text.
            TableCell cell = new TableCell();
            cell.HorizontalAlign = HorizontalAlign.Center;
            cell.MergeStyle(this.DayHeaderStyle);
            cell.Text = s;

            return cell;
        }

        //
        // Determines the first day of the week based on the FirstDayOfWeek
        // property setting.
        //
        private System.DayOfWeek GetFirstDayOfWeek()
        {
            // If the default value is specifed, use the system default.
            if (this.FirstDayOfWeek == FirstDayOfWeek.Default)
                return CultureInfo.CurrentCulture.DateTimeFormat.FirstDayOfWeek;
            else
                return (DayOfWeek) this.FirstDayOfWeek;
        }

        //
        // Returns the date that should appear in the first day cell of the
        // calendar display.
        //
        private DateTime GetFirstCalendarDate()
        {
            // Start with the first of the month.
            DateTime date = new DateTime(this.TargetDate.Year, this.TargetDate.Month, 1);

            // While that day does not fall on the first day of the week, move back.
            DayOfWeek firstDay = this.GetFirstDayOfWeek();
            while(date.DayOfWeek != firstDay)
                date = date.AddDays(-1);

            return date;
        }

        //
        // Creates a CalendarDay instance for the given date.
        //
        // Note: This object is included in the DayRenderEventArgs passed to
        // the DayRender event handler.
        //
        private CalendarDay Day(DateTime date)
        {
            CalendarDay day = new CalendarDay(
                date,
                date.DayOfWeek == DayOfWeek.Saturday || date.DayOfWeek == DayOfWeek.Sunday,
                date == this.TodaysDate,
                date == this.SelectedDate,
                !(date.Month == this.TargetDate.Month && date.Year == this.TargetDate.Year),
                date.Day.ToString());

            // Default the day to selectable.
            day.IsSelectable = true;

            return day;
        }

        //
        // Creates a TableCell control for the given calendar day.
        //
        // Note: This object is included in the DayRenderEventArgs passed to
        // the DayRender event handler.
        //
        private TableCell Cell(CalendarDay day)
        {
            TableCell cell = new TableCell();
            cell.HorizontalAlign = HorizontalAlign.Center;
            if (this.HasWeekSelectors(this.SelectionMode))
                cell.Attributes.Add("style", "width:12%");
            else
                cell.Attributes.Add("style", "width:14%");

            // Add styling based on day flags.
            // Note:
            //   - Styles are applied per the precedence order used by the
            //     base Calendar control.
            //   - For CssClass, multiple class names may be added.
            StringBuilder sb = new StringBuilder();
            if (this.SelectedDates.Contains(day.Date))
            {
                cell.MergeStyle(this.SelectedDayStyle);
                sb.AppendFormat(" {0}", this.SelectedDayStyle.CssClass);
            }
            if (day.IsToday)
            {
                cell.MergeStyle(this.TodayDayStyle);
                sb.AppendFormat(" {0}", this.TodayDayStyle.CssClass);
            }
            if (day.IsOtherMonth)
            {
                cell.MergeStyle(this.OtherMonthDayStyle);
                sb.AppendFormat(" {0}", this.OtherMonthDayStyle.CssClass);
            }
            if (day.IsWeekend)
            {
                cell.MergeStyle(this.WeekendDayStyle);
                sb.AppendFormat(" {0}", this.WeekendDayStyle.CssClass);
            }
            cell.MergeStyle(this.DayStyle);
            sb.AppendFormat(" {0}", this.DayStyle.CssClass);
            string s = sb.ToString().Trim();
            if (s.Length > 0)
                cell.CssClass = s;

            // Add a literal control to the cell using the day number for the
            // text.
            cell.Controls.Add(new LiteralControl(day.DayNumberText));

            return cell;
        }

        //
        // Returns true if the selection mode includes week selectors.
        //
        private new bool HasWeekSelectors(CalendarSelectionMode selectionMode)
        {
//            if (selectionMode == CalendarSelectionMode.DayWeek ||
//                selectionMode == CalendarSelectionMode.DayWeekMonth)
//                return true;
//            else
                return false;
        }
        #endregion

        #region Post back event handling
        // ====================================================================
        // Functions for converting between DateTime and day count values.
        // ====================================================================

        //
        // Returns the number of days between the given DateTime value and the
        // base date.
        //
        private int DayCountFromDate(DateTime date)
        {
            return ((TimeSpan) (date - BandlCalendar.DayCountBaseDate)).Days;
        }

        //
        // Returns a DateTime value equal to the base date plus the given number
        // of days.
        //
        private DateTime DateFromDayCount(int dayCount)
        {
            return BandlCalendar.DayCountBaseDate.AddDays(dayCount);
        }

        // ====================================================================
        // Functions to save and load the nonselectable dates list.
        //
        // Note: A hidden form field is used to store this data rather than the
        // view state because the nonselectable dates are not known until after
        // the DayRender event has been raised for each day as the control is
        // rendered.
        //
        // To minimize the amount of data stored in that field, the dates are
        // represented as day count values.
        // ====================================================================

        //
        // Saves a list of dates to the hidden form field.
        //
        private void SaveNonselectableDates(ArrayList dates)
        {
            // Build a string array by converting each date to a day count
            // value.
            string[] list = new string[dates.Count];
            for (int i = 0; i < list.Length; i++)
                list[i] = this.DayCountFromDate(DateTime.Parse(dates[i].ToString())).ToString();

            // Get the hidden field name.
            string fieldName  = this.GetHiddenFieldName();

            // For the field value, create a comma-separated list from the day
            // count values.
            string fieldValue = HttpUtility.HtmlAttributeEncode(String.Join(",", list));

            // Add the hidden form field to the page.
            Page.ClientScript.RegisterHiddenField(fieldName, fieldValue);
        }

        //
        // Returns a list of dates stored in the hidden form field.
        //
        private ArrayList LoadNonselectableDates()
        {
            // Create an empty list.
            ArrayList dates = new ArrayList();

            // Get the value stored in the hidden form field.
            string fieldName  = this.GetHiddenFieldName();
            string fieldValue = this.Page.Request.Form[fieldName];

            // If no dates were stored, return the empty list.
            if (fieldValue == null)
                return dates;

            // Extract the individual day count values.
            string[] list = fieldValue.Split(',');

            // Convert those values to dates and store them in an array list.
            foreach (string s in list)
                dates.Add(this.DateFromDayCount(Int32.Parse(s)));

            return dates;
        }

        //
        // Returns the name of the hidden field used to store nonselectable
        // dates on the form.
        //
        private string GetHiddenFieldName()
        {
            // Create a unique field name.
            return String.Format("{0}_NonselectableDates", this.ClientID);
        }

        // ====================================================================
        // Implementation of the IPostBackEventHandler.RaisePostBackEvent
        // event handler.
        // ====================================================================

        /// <summary>
        /// Handles a post back event targeted at the control.
        /// </summary>
        /// <param name="eventArgument">
        /// A <see cref="System.String"/> representing the event argument passed to the handler.
        /// </param>
        protected override void RaisePostBackEvent(string eventArgument)
        {
//            base.RaisePostBackEvent(eventArgument);
            // Was the post back initiated by a previous or next month link?
            if (eventArgument.StartsWith("V"))
            {
                try
                {
                    // Save the current visible date.
                    DateTime previousDate = this.TargetDate;

                    // Extract the day count from the argument and use it to
                    // change the visible date.
                    int d = Int32.Parse(eventArgument.Substring(1));
                    this.VisibleDate = this.DateFromDayCount(d);

                    // Raise the VisibleMonthChanged event.
                    OnVisibleMonthChanged(this.VisibleDate, previousDate);
                }
                catch
                {
                    ;
                }
            }
            // Was the post back initiated by a previous or next year link?
            else if (eventArgument.StartsWith("Y"))
            {
                try
                {
                    // Save the current visible date.
                    DateTime previousDate = this.TargetDate;
                    // Extract the day count from the argument and use it to
                    // change the visible date.
                    int d = Int32.Parse(eventArgument.Substring(1));
                    this.VisibleDate = this.DateFromDayCount(d);
                    // Raise the VisibleMonthChanged event.
                    OnVisibleMonthChanged(this.VisibleDate, previousDate);
                }
                catch
                {
                    ;
                }
            }
                // Was the post back initiated by a month or week selector link?
            else if (eventArgument.StartsWith("R"))
            {
                try
                {
                    // Extract the day count and number of days from the
                    // argument.
                    int d = Int32.Parse(eventArgument.Substring(1, eventArgument.Length - 3));
                    int n = Int32.Parse(eventArgument.Substring(eventArgument.Length - 2));

                    // Get the starting date.
                    DateTime date = this.DateFromDayCount(d);

                    // Reset the selected dates collection to include all the
                    // dates in the given range.
                    this.SelectedDates.Clear();
                    this.SelectedDates.SelectRange(date, date.AddDays(n - 1));

                    // If SelectAllInRange is false, remove any dates found
                    // in the nonselectable date list.
                    if (!this.SelectAllInRange)
                    {
                        ArrayList nonselectableDates = this.LoadNonselectableDates();
                        foreach(DateTime badDate in nonselectableDates)
                            this.SelectedDates.Remove(badDate);
                    }

                    // Raise the SelectionChanged event.
                    OnSelectionChanged();
                }
                catch
                {
                    ;
                }
            }
            else
            {
                // The post back must have been initiated by a calendar day link.
                try
                {
                    // Get the day count from the argument.
                    int d = Int32.Parse(eventArgument);

                    // Reset the selected dates collection to include only the
                    // newly selected date.
                    this.SelectedDates.Clear();
                    this.SelectedDates.Add(this.DateFromDayCount(d));

                    // Raise the SelectionChanged event.
                    OnSelectionChanged();
                }
                catch
                {
                    ;
                }
            }
        }
        #endregion
    }
}
