<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:ipxact="http://www.accellera.org/XMLSchema/IPXACT/1685-2022"
    version="1.0">

  <xsl:output method="text" indent="no"/>

  <!-- Main template -->
  <xsl:template match="/">
    <!-- Build the add_ip line -->
    <xsl:text>add_ip(</xsl:text>
    <xsl:value-of select="concat(ipxact:component/ipxact:vendor, '::', ipxact:component/ipxact:library, '::', ipxact:component/ipxact:name, '::', ipxact:component/ipxact:version)"/>
    <xsl:text>)</xsl:text>
    <xsl:text>&#10;&#10;</xsl:text>

    <!-- Process each unique fileType -->
    <xsl:for-each select="ipxact:component/ipxact:fileSets/ipxact:fileSet/ipxact:file/ipxact:fileType[not(. = preceding::ipxact:fileType)]">
      <xsl:variable name="ftype" select="."/>
      <xsl:text>ip_sources(${IP} </xsl:text>
      <xsl:value-of select="$ftype"/>
      <xsl:text>&#10;</xsl:text>

      <!-- List all files matching this fileType -->
      <xsl:for-each select="/ipxact:component/ipxact:fileSets/ipxact:fileSet/ipxact:file[ipxact:fileType = $ftype]">
        <xsl:text>   </xsl:text>
        <xsl:text>${</xsl:text><xsl:value-of select="/ipxact:component/ipxact:name"/><xsl:text>_SOURCE_DIR}/</xsl:text><xsl:value-of select="ipxact:name"/>
        <xsl:text>&#10;</xsl:text>
      </xsl:for-each>

      <xsl:text>)</xsl:text>
      <xsl:text>&#10;&#10;</xsl:text>
    </xsl:for-each>
  </xsl:template>

</xsl:stylesheet>

