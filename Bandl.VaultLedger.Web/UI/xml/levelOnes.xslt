<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"  xmlns:fo="http://www.w3.org/1999/XSL/Format">
<xsl:output method="html" version="1.0" encoding="UTF-8" indent="no"/>
	<xsl:param name="currentUrl"/>
	<xsl:template match="//navigation/home/levelOnes" name="levelOnes">
		<div id="levelOneNav">
		<xsl:for-each select="levelOne">
			<a><xsl:attribute name="href">[BASE_URL]<xsl:value-of select="@url" /></xsl:attribute>
				<img>
					<xsl:choose>
						<xsl:when test="string-length(substring-before($currentUrl, '/')) > 0">
							<xsl:choose>
								<xsl:when test="substring-before($currentUrl, '/') = starts-with(@url, substring-before($currentUrl, '/'))">
									<xsl:attribute name="src">[IMAGE_URL]/btns/<xsl:value-of select="@srcOn" /></xsl:attribute>
								</xsl:when>
								<xsl:otherwise>
									<xsl:attribute name="src">[IMAGE_URL]/btns/<xsl:value-of select="@srcOff" /></xsl:attribute>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:when>
						<xsl:otherwise>
							<xsl:choose>
								<xsl:when test="$currentUrl = @url">
									<xsl:attribute name="src">[IMAGE_URL]/btns/<xsl:value-of select="@srcOn" /></xsl:attribute>
								</xsl:when>
								<xsl:otherwise>
									<xsl:attribute name="src">[IMAGE_URL]/btns/<xsl:value-of select="@srcOff" /></xsl:attribute>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:otherwise>
					</xsl:choose>
					<xsl:attribute name="border">0</xsl:attribute>
					<xsl:attribute name="alt"><xsl:value-of select="@label" /></xsl:attribute>
					<xsl:attribute name="title"><xsl:value-of select="@label" /></xsl:attribute>
				</img>
			</a>
		</xsl:for-each>
		</div>
	</xsl:template>
</xsl:stylesheet>