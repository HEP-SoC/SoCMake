<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:ipxact="http://www.accellera.org/XMLSchema/IPXACT/1685-2022"
    exclude-result-prefixes="ipxact">

    <xsl:output method="text" encoding="UTF-8"/>

    <!-- Define a key based on the vendor::library::name::version -->
    <xsl:key name="uniqueKey" match="*[
            @vendor and @library and @name and @version and (
                self::ipxact:busType or
                self::ipxact:abstractionRef or
                self::ipxact:designRef or
                self::ipxact:designConfigurationRef or
                self::ipxact:componentRef or
                self::ipxact:generatorChainRef or
                self::ipxact:generatorChainConfiguration or
                self::ipxact:abstractorRef or
                self::ipxact:extends or
                self::ipxact:typeDefinitionsRef or
                self::ipxact:vlnv
            )
        ]" 
        use="concat(@vendor, '|', @library, '|', @name, '|', @version)"/>

    <!-- Main template -->
    <xsl:template match="/">
        <xsl:text>ip_link(${IP}</xsl:text>
        <xsl:text>&#10;</xsl:text>

        <!-- Apply templates to only the first of each duplicate -->
        <xsl:for-each select="//*/self::ipxact:busType |
                              //*/self::ipxact:abstractionRef |
                              //*/self::ipxact:designRef |
                              //*/self::ipxact:designConfigurationRef |
                              //*/self::ipxact:componentRef |
                              //*/self::ipxact:generatorChainRef |
                              //*/self::ipxact:generatorChainConfiguration |
                              //*/self::ipxact:abstractorRef |
                              //*/self::ipxact:extends |
                              //*/self::ipxact:typeDefinitionsRef |
                              //*/self::ipxact:vlnv">

            <xsl:if test="@vendor and @library and @name and @version">
                <!-- Only process the first occurrence of each unique key -->
                <xsl:if test="generate-id() = generate-id(key('uniqueKey', concat(@vendor, '|', @library, '|', @name, '|', @version))[1])">
                    <xsl:text>    </xsl:text>
                    <xsl:value-of select="concat(@vendor, '::', @library, '::', @name, '::', @version)"/>
                    <xsl:text>&#10;</xsl:text>
                </xsl:if>
            </xsl:if>

        </xsl:for-each>

        <xsl:text>)</xsl:text>
        <xsl:text>&#10;</xsl:text>
    </xsl:template>

</xsl:stylesheet>
