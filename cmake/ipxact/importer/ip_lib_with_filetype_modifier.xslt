<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:ipxact="http://www.accellera.org/XMLSchema/IPXACT/1685-2022"
    version="1.0">

  <xsl:output method="text" indent="no"/>

  <!-- Keys for matching sources and headers and group by file set name and fileType -->
  <xsl:key name="sources-by-set-and-language" 
           match="ipxact:file[not(ipxact:isIncludeFile='true')]" 
           use="concat(../ipxact:name, '|', ipxact:fileType)"/>

  <!-- Key for header files -->
  <xsl:key name="headers-by-set-and-language" 
           match="ipxact:file[ipxact:isIncludeFile='true']" 
           use="concat(../ipxact:name, '|', ipxact:fileType)"/>


  <!-- Template to write a single ip_sources(${IP} <LANGUAGE> [HEADERS] ...files... ) call -->
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
                <!-- Alternative output if '${' is NOT found -->
                <xsl:text>    ${IP_SOURCE_DIR}/</xsl:text>
                <xsl:value-of select="ipxact:name"/>
                <xsl:text>&#10;</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:for-each>

    <xsl:text>)&#10;&#10;</xsl:text>
  </xsl:template>

  <!-- Template to match root document and create an IP block with sources -->
  <xsl:template match="/">
      <xsl:text>add_ip(</xsl:text>
      <xsl:value-of select="concat(//ipxact:vendor, '::', //ipxact:library, '::', //ipxact:name, '::', //ipxact:version)"/>
      <xsl:text>)&#10;&#10;</xsl:text>

      <xsl:text>if(NOT DEFINED ${IP}_IPXACT_SOURCE_DIR)&#10;</xsl:text>
      <xsl:text>    set(IP_SOURCE_DIR ${CMAKE_CURRENT_LIST_DIR})&#10;</xsl:text>
      <xsl:text>else()&#10;</xsl:text>
      <xsl:text>    set(IP_SOURCE_DIR ${${IP}_IPXACT_SOURCE_DIR})&#10;</xsl:text>
      <xsl:text>endif()&#10;&#10;</xsl:text>

      <xsl:for-each select="//ipxact:fileSets/ipxact:fileSet">
        <xsl:variable name="file_set_name" select="ipxact:name"/>
        
        <!-- Write ip_sources for source files -->
        <xsl:for-each select="ipxact:file[not(ipxact:isIncludeFile='true')]
                              [count(. | key('sources-by-set-and-language', 
                                   concat($file_set_name, '|', ipxact:fileType))[1]) = 1]">
          <xsl:call-template name="write-ip-sources">
            <xsl:with-param name="sources" 
                            select="key('sources-by-set-and-language', 
                                   concat($file_set_name, '|', ipxact:fileType))"/>
            <xsl:with-param name="language" select="ipxact:fileType"/>
            <xsl:with-param name="file_set" select="$file_set_name"/>
          </xsl:call-template>
        </xsl:for-each>
        
        <!-- Write ip_sources for header files -->
        <xsl:for-each select="ipxact:file[ipxact:isIncludeFile='true']
                              [count(. | key('headers-by-set-and-language', 
                                   concat($file_set_name, '|', ipxact:fileType))[1]) = 1]">
          <xsl:call-template name="write-ip-sources">
            <xsl:with-param name="sources" 
                            select="key('headers-by-set-and-language', 
                                   concat($file_set_name, '|', ipxact:fileType))"/>
            <xsl:with-param name="language" select="ipxact:fileType"/>
            <xsl:with-param name="file_set" select="$file_set_name"/>
            <xsl:with-param name="is_header" select="true()"/>
          </xsl:call-template>
        </xsl:for-each>
      </xsl:for-each>
  </xsl:template>

</xsl:stylesheet>
