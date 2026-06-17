<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:ipxact="http://www.accellera.org/XMLSchema/IPXACT/1685-2022"
    version="1.0">

  <xsl:output method="text" indent="no"/>

  <xsl:key name="files-by-set-language-header"
           match="ipxact:file"
           use="concat(../ipxact:name, '|', ipxact:fileType, '|', ipxact:isIncludeFile='true')"/>

  <xsl:key name="deps"
           match="*[@vendor and @library and @name and @version]"
           use="concat(@vendor, '|', @library, '|', @name)"/>

  <xsl:template name="write-ip-sources">
    <xsl:param name="sources"/>
    <xsl:param name="language"/>
    <xsl:param name="file_set"/>
    <xsl:param name="is_header" select="false()"/>

    <xsl:text>ip_sources(${IP} </xsl:text>
    <xsl:variable name="socmake_language">
        <xsl:choose>
            <xsl:when test="contains($language, 'Source')">
                <xsl:value-of select="substring-before($language, 'Source')"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$language"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

    <xsl:value-of select="translate($socmake_language, 'abcdefghijklmnopqrstuvwxyz', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ')"/>

    <xsl:text> FILE_SET </xsl:text>
    <xsl:value-of select="$file_set"/>

    <xsl:if test="$is_header"> HEADERS</xsl:if>
    <xsl:text>&#10;</xsl:text>

    <xsl:for-each select="$sources">
        <xsl:choose>
            <xsl:when test="starts-with(ipxact:name, '$')">
                <xsl:text>    </xsl:text>
                <xsl:value-of select="ipxact:name"/>
                <xsl:text>&#10;</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>    ${CMAKE_CURRENT_LIST_DIR}/</xsl:text>
                <xsl:value-of select="ipxact:name"/>
                <xsl:text>&#10;</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:for-each>

    <xsl:text>)&#10;&#10;</xsl:text>
  </xsl:template>

  <xsl:template match="/">
      <xsl:variable name="comp" select="/*"/>
      <xsl:text>add_ip(</xsl:text>
      <xsl:value-of select="concat($comp/ipxact:vendor, '::', $comp/ipxact:library, '::', $comp/ipxact:name, '::', $comp/ipxact:version)"/>
      <xsl:text>)&#10;&#10;</xsl:text>

      <xsl:for-each select="$comp/ipxact:fileSets/ipxact:fileSet">
        <xsl:variable name="file_set_name" select="ipxact:name"/>

        <xsl:for-each select="ipxact:file
            [count(. | key('files-by-set-language-header',
                concat($file_set_name, '|', ipxact:fileType, '|', ipxact:isIncludeFile='true'))[1]) = 1]">
          <xsl:call-template name="write-ip-sources">
            <xsl:with-param name="sources"
                            select="key('files-by-set-language-header',
                                concat($file_set_name, '|', ipxact:fileType, '|', ipxact:isIncludeFile='true'))"/>
            <xsl:with-param name="language" select="ipxact:fileType"/>
            <xsl:with-param name="file_set" select="$file_set_name"/>
            <xsl:with-param name="is_header" select="ipxact:isIncludeFile='true'"/>
          </xsl:call-template>
        </xsl:for-each>
      </xsl:for-each>

      <xsl:variable name="dep_nodes" select="//*[@vendor and @library and @name and @version]"/>
      <xsl:if test="$dep_nodes">
          <xsl:text>ip_find_and_link(${IP}</xsl:text>
          <xsl:text>&#10;</xsl:text>
          <xsl:for-each select="$dep_nodes">
              <xsl:if test="generate-id() = generate-id(key('deps', concat(@vendor, '|', @library, '|', @name))[1])">
                  <xsl:text>	</xsl:text>
                  <xsl:value-of select="concat(@vendor, '::', @library, '::', @name)"/>
                  <xsl:text>&#10;</xsl:text>
              </xsl:if>
          </xsl:for-each>
          <xsl:text>)&#10;</xsl:text>
      </xsl:if>
  </xsl:template>

</xsl:stylesheet>
