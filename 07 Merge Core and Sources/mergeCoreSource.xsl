<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns="http://www.music-encoding.org/ns/mei"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    xmlns:mei="http://www.music-encoding.org/ns/mei"
    version="2.0">
    
    <xd:doc scope="stylesheet">
      <xd:desc>
        <xd:p><xd:b>Author:</xd:b> Johannes Kepper</xd:p>
        <xd:p><xd:b>Documentation:</xd:b> Benjamin W. Bohl</xd:p>
        <xd:p>
          applied to a source file loads music data from core.xml and stores results to mergedSources/
        </xd:p>
      </xd:desc>
    </xd:doc>
  
    <xsl:output encoding="UTF-8" indent="yes" method="xml"/>
    
    <xd:doc scope="component">
      <xd:desc>
        <xd:p>Store core.xml in variable</xd:p>
      </xd:desc>
    </xd:doc>
    <xsl:param name="corePath"/>
    <xsl:variable name="core" select="document($corePath)"/>
  
    <xd:doc scope="component">
      <xd:desc>
        <xd:p>Store @xml:id in variable</xd:p>
      </xd:desc>
    </xd:doc>
    <xsl:variable name="siglum" select="//mei:mei/@xml:id"/>
    
    <xd:doc scope="component">
      <xd:desc>
        <xd:p>create output file in mergedSources</xd:p>
      </xd:desc>
    </xd:doc>
    <xsl:template match="/">
        <xsl:apply-templates/>
    </xsl:template>
    
    <!--<xsl:template match="@sameas">
        <xsl:variable name="sameas" select="substring-after(., '#')"/>
        <xsl:variable name="coreNode" select="$core/id($sameas)"/>
        <xsl:copy-of select="$coreNode/(@* except @xml:id) | ."/>
    </xsl:template>-->
    
    <xsl:template match="mei:*[@sameas]">
        <xsl:variable name="sameas" select="substring-after(@sameas, '#')"/>
        <xsl:variable name="coreNode" select="$core/id($sameas)"/>
        <xsl:copy>
            <xsl:apply-templates select="$coreNode/(@* except @xml:id)"/>
            <xsl:apply-templates select="@*"/>
            <xsl:apply-templates select="node()"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="mei:appInfo">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*"/>
            <xsl:element name="application" namespace="http://www.music-encoding.org/ns/mei">
                <xsl:attribute name="xml:id">mergeCoreSource.xsl</xsl:attribute>
                <xsl:element name="name" namespace="http://www.music-encoding.org/ns/mei">mergeCoreSource.xsl</xsl:element>
                <xsl:element name="ptr" namespace="http://www.music-encoding.org/ns/mei">
                    <xsl:attribute name="target">../xslt/mergeCoreSource.xsl</xsl:attribute>
                </xsl:element>
            </xsl:element>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="mei:revisionDesc">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*"/>
            <xsl:element name="change" namespace="http://www.music-encoding.org/ns/mei">
                <xsl:attribute name="n" select="number(mei:change[last()]/@n) + 1"/>
                <xsl:element name="respStmt" namespace="http://www.music-encoding.org/ns/mei">
                    <xsl:element name="persName" namespace="http://www.music-encoding.org/ns/mei">Johannes Kepper</xsl:element>
                </xsl:element>
                <xsl:element name="changeDesc" namespace="http://www.music-encoding.org/ns/mei">
                    <xsl:element name="p" namespace="http://www.music-encoding.org/ns/mei">
                        Source file merged with core to generate a complete encoding, using <xsl:element name="ref" namespace="http://www.music-encoding.org/ns/mei">
                            <xsl:attribute name="target">#mergeCoreSource.xsl</xsl:attribute>
                            <xsl:text>mergeCoreSource.xsl</xsl:text>
                        </xsl:element>. References to core.xml are kept intact. 
                    </xsl:element>
                </xsl:element>
                <xsl:element name="date" namespace="http://www.music-encoding.org/ns/mei">
                    <xsl:attribute name="isodate" select="substring(string(current-date()),1,10)"/>
                </xsl:element>
            </xsl:element>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="node() | @*">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
    </xsl:template>
    
</xsl:stylesheet>