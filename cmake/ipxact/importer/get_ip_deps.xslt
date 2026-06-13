<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:ipxact="http://www.accellera.org/XMLSchema/IPXACT/1685-2022"
    exclude-result-prefixes="ipxact">

    <xsl:output method="text" encoding="UTF-8"/>

    <xsl:key name="deps"
             match="*[@vendor and @library and @name and @version]"
             use="concat(@vendor, '|', @library, '|', @name)"/>

    <xsl:template match="/">
        <xsl:text>ip_find_and_link(${IP}</xsl:text>
        <xsl:text>&#10;</xsl:text>
        <xsl:for-each select="//*[@vendor and @library and @name and @version]">
            <xsl:if test="generate-id() = generate-id(key('deps', concat(@vendor, '|', @library, '|', @name))[1])">
                <xsl:text>    </xsl:text>
                <xsl:value-of select="concat(@vendor, '::', @library, '::', @name)"/>
                <xsl:text>&#10;</xsl:text>
            </xsl:if>
        </xsl:for-each>
        <xsl:text>)&#10;</xsl:text>
    </xsl:template>

</xsl:stylesheet>
