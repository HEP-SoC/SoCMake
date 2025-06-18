<?xml version="1.0"?>
<xsl:stylesheet 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:exslt="http://exslt.org/common"
    xmlns:ipxact="http://www.accellera.org/XMLSchema/IPXACT/1685-2022"
    version="1.0"
    extension-element-prefixes="exslt">
  <xsl:output omit-xml-declaration="yes" indent="no"/>
  <xsl:template match="/">
    <xsl:call-template name="value-of-template">
      <xsl:with-param name="select" select="/*/ipxact:vendor"/>
    </xsl:call-template>
    <xsl:text>;</xsl:text>
    <xsl:call-template name="value-of-template">
      <xsl:with-param name="select" select="/*/ipxact:library"/>
    </xsl:call-template>
    <xsl:text>;</xsl:text>
    <xsl:call-template name="value-of-template">
      <xsl:with-param name="select" select="/*/ipxact:name"/>
    </xsl:call-template>
    <xsl:text>;</xsl:text>
    <xsl:call-template name="value-of-template">
      <xsl:with-param name="select" select="/*/ipxact:version"/>
    </xsl:call-template>
  </xsl:template>

  <xsl:template name="value-of-template">
    <xsl:param name="select"/>
    <xsl:value-of select="$select"/>
    <xsl:for-each select="exslt:node-set($select)[position()&gt;1]">
      <xsl:value-of select="'&#10;'"/>
      <xsl:value-of select="."/>
    </xsl:for-each>
  </xsl:template>
</xsl:stylesheet>
