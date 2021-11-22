<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"  xmlns:fo="http://www.w3.org/1999/XSL/Format">
<xsl:output method="html" version="1.0" encoding="UTF-8" indent="no"/>
	<xsl:param name="currentUrl"/>
	<xsl:template match="//navigation/home/levelOnes" name="levelOnes">
		<div id="levelTwoNav">
		<xsl:for-each select="levelOne">
			<xsl:if test="substring-before($currentUrl, '/') = starts-with(@url, substring-before($currentUrl, '/'))">
				<xsl:for-each select="levelTwos/levelTwo">
					<a>
						<xsl:attribute name="href">[BASE_URL]<xsl:value-of select="@url" /></xsl:attribute>
						<xsl:if test="$currentUrl = @url">
							<xsl:attribute name="id">selected</xsl:attribute>
						</xsl:if>
						<xsl:if test="$currentUrl = @url">[ </xsl:if>
						<xsl:value-of select="@label"/>
						<xsl:if test="$currentUrl = @url"> ]</xsl:if>
					</a>
				</xsl:for-each>
			</xsl:if>
		</xsl:for-each>
		</div>
	</xsl:template>
</xsl:stylesheet>