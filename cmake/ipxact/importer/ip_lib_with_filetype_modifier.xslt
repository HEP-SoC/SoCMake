<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:ipxact="http://www.accellera.org/XMLSchema/IPXACT/1685-2022"
    version="1.0">

  <xsl:output method="text" indent="no"/>

  <!-- Grouping key for unique fileTypes -->
  <xsl:key name="files-by-type" match="ipxact:file" use="ipxact:fileType"/>

  <!-- Main template -->
  <xsl:template match="/">
    <!-- Build the add_ip line -->
    <xsl:text>add_ip(</xsl:text>
    <xsl:value-of select="concat(ipxact:component/ipxact:vendor, '::', ipxact:component/ipxact:library, '::', ipxact:component/ipxact:name, '::', ipxact:component/ipxact:version)"/>
    <xsl:text>)</xsl:text>
    <xsl:text>&#10;&#10;</xsl:text>

    <!-- Loop over unique fileTypes by processing only the first file per type -->
    <xsl:for-each select="ipxact:component/ipxact:fileSets/ipxact:fileSet/ipxact:file[generate-id() = generate-id(key('files-by-type', ipxact:fileType)[1])]">
      <xsl:variable name="ftype" select="ipxact:fileType"/>
      <xsl:text>ip_sources(${IP} </xsl:text>

      <!-- Transform fileType to uppercase prefix -->
      <xsl:variable name="baseType">
        <xsl:choose>
          <xsl:when test="contains($ftype, 'Source')">
            <xsl:value-of select="substring-before($ftype, 'Source')"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="$ftype"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
      <xsl:value-of select="translate($baseType, 'abcdefghijklmnopqrstuvwxyz', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ')"/>
      <xsl:text>&#10;</xsl:text>

      <!-- Now list all files for this type using the key -->
      <xsl:for-each select="key('files-by-type', $ftype)">
        <xsl:text>   </xsl:text>
        <xsl:text>${</xsl:text>
        <xsl:value-of select="/ipxact:component/ipxact:name"/>
        <xsl:text>_SOURCE_DIR}/</xsl:text>
        <xsl:value-of select="ipxact:name"/>
        <xsl:text>&#10;</xsl:text>
      </xsl:for-each>

      <xsl:text>)</xsl:text>
      <xsl:text>&#10;&#10;</xsl:text>
    </xsl:for-each>
  </xsl:template>

</xsl:stylesheet>
