<div id="topBar">
	<div id="logo"><img id="iLogo" alt="" runat="server"></div>
	<div id="logoHeader"><img id="iProduct" alt="" border="0" runat="server"></div>
	<div id="constants" runat="server">
		<div id="welcome" align="right"><asp:Label id="lblGreeting" runat="server"></asp:Label></div>
		<div id="helpHeaders" runat="server"><%= this.BuildHeader(0) %></div>
	</div>
    <div style="display:none" id="imationBlock" runat="server">
        <img id="imationLogo" runat="server">
    </div>
</div>
<%= this.BuildHeader(1) %>
<%= this.BuildHeader(2) %> 
