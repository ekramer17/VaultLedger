<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"  xmlns:fo="http://www.w3.org/1999/XSL/Format">
<xsl:output method="html" version="1.0" encoding="UTF-8" indent="no"/>
	<xsl:template match="//navigation/home/constants" name="constants">
		<xsl:for-each select="constant">
			<!--<a href="#" id="firstBtn">My Profile</a><a href="#">Help</a><a href="#">Logout</a>-->
			<a><xsl:if test="(position() = 1)">
				<xsl:attribute name="id">firstBtn</xsl:attribute>
			</xsl:if>
			<xsl:attribute name="href">
				<xsl:value-of select="@url" />
			</xsl:attribute>
			<xsl:value-of select="@label" /></a>
		</xsl:for-each>
	</xsl:template>
</xsl:stylesheet>