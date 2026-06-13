<?xml version="1.0"?>
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:ipxact="http://www.accellera.org/XMLSchema/IPXACT/1685-2022"
    version="1.0">
  <xsl:output omit-xml-declaration="yes" indent="no"/>
  <xsl:template match="/">
    <xsl:value-of select="/*/ipxact:vendor"/>
    <xsl:text>::</xsl:text>
    <xsl:value-of select="/*/ipxact:library"/>
    <xsl:text>::</xsl:text>
    <xsl:value-of select="/*/ipxact:name"/>
    <xsl:text>::</xsl:text>
    <xsl:value-of select="/*/ipxact:version"/>
  </xsl:template>
</xsl:stylesheet>
