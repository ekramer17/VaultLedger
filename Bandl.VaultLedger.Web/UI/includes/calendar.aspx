<%@ Page language="c#" Codebehind="calendar.aspx.cs" AutoEventWireup="false" Inherits="Bandl.VaultLedger.Web.UI.calendarPage" %>
<%@ Register TagPrefix="Bandl" Namespace="Bandl.Web.UI.WebControls" Assembly="Bandl.VaultLedger.Web.UI"%>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN" >
<HTML>
    <HEAD>
        <title>Select Date</title>
        <style>
        .calendar { FONT-FAMILY: tahoma, arial, sans-serif }
	    .calendar A { TEXT-DECORATION: none }
	    </style>
        <meta content="Microsoft Visual Studio .NET 7.1" name=GENERATOR>
        <meta content=C# name=CODE_LANGUAGE>
        <meta content=JavaScript name=vs_defaultClientScript>
        <meta content=http://schemas.microsoft.com/intellisense/ie5 name=vs_targetSchema>
    </HEAD>
<body xmlns:bandl="urn:http://schemas.bandl.com/AspNet/WebControls">
<form id=Form1 method=post runat="server">
    <bandl:bandlcalendar id=Calendar1 style="PADDING-RIGHT: 0px; PADDING-LEFT: 0px; PADDING-BOTTOM: 0px; MARGIN: 0px; PADDING-TOP: 0px" runat="server" ShowNextPrevYear="True" Height="100%" Width="100%" CssClass="calendar" MaxVisibleDate="12/31/3999 23:59:00">
        <OtherMonthDayStyle ForeColor="DarkGray"></OtherMonthDayStyle>
        <TitleStyle Font-Size="X-Small" Font-Names="Tahoma" Font-Bold="True" ForeColor="White" BackColor="DarkBlue"></TitleStyle>
        <NextPrevStyle Font-Size="X-Small" Font-Bold="True" ForeColor="White"></NextPrevStyle>
        <DayStyle Font-Size="X-Small" Font-Names="Tahoma" ForeColor="Black" CssClass="noUnderline"></DayStyle>
        <DayHeaderStyle Font-Size="X-Small" Font-Names="Tahoma" Font-Bold="True" ForeColor="DarkGoldenrod" BackColor="LightSteelBlue"></DayHeaderStyle>
	</bandl:bandlcalendar>
</form>
</body>
</HTML>
