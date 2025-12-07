<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:ipxact="http://www.accellera.org/XMLSchema/IPXACT/1685-2022"
    exclude-result-prefixes="ipxact">

    <xsl:output method="text" encoding="UTF-8"/>

    <!-- Define a key based on vendor::library::name::version -->
    <xsl:key name="uniqueKey"
             match="*[@vendor and @library and @name and @version]"
             use="concat(@vendor, '|', @library, '|', @name, '|', @version)"/>

    <!-- Main template -->
    <xsl:template match="/">
        <!-- Iterate over all elements with VLNV attributes -->
        <xsl:for-each select="//*[@vendor and @library and @name and @version]">
            <!-- Only process the first occurrence of each unique key -->
            <xsl:if test="generate-id() = generate-id(key('uniqueKey', concat(@vendor, '|', @library, '|', @name, '|', @version))[1])">
                <xsl:text>find_ip(</xsl:text>
                <xsl:value-of select="concat(@vendor, '::', @library, '::', @name)"/>
                <xsl:text> REQUIRED)</xsl:text>
                <xsl:text>&#10;</xsl:text>
            </xsl:if>
        </xsl:for-each>

        <xsl:text>&#10;</xsl:text>
    </xsl:template>

</xsl:stylesheet>
