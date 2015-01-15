<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    xmlns:mei="http://www.music-encoding.org/ns/mei"
    exclude-result-prefixes="xs math xd mei"
    version="3.0">
    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p><xd:b>Created on:</xd:b> Jan 15, 2015</xd:p>
            <xd:p><xd:b>Author:</xd:b> Johannes Kepper</xd:p>
            <xd:p>This stylesheet rounds tstamps to avoid problems with sanityCheck_durations.sch</xd:p>
        </xd:desc>
    </xd:doc>
    
    <xsl:output method="xml" indent="yes"/>
    <xsl:template match="/">
        <xsl:apply-templates/>
    </xsl:template>
    
    <xsl:template match="@tstamp">
        
        <xsl:variable name="current" select="number(format-number(number(.),'#.###'))"/>
        
        <xsl:variable name="value">
            <xsl:choose>
                <xsl:when test="(ceiling($current) - $current) le 0.01">
                    <xsl:value-of select="ceiling($current)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$current"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <xsl:attribute name="tstamp" select="$value"/>
        
    </xsl:template>
    
    <xsl:template match="@tstamp2">
        
        <xsl:variable name="current" select="number(format-number(number(.),'#.###'))"/>
        
        <xsl:variable name="value">
            <xsl:choose>
                <xsl:when test="(ceiling($current) - $current) le 0.01">
                    <xsl:value-of select="ceiling($current)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$current"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <xsl:attribute name="tstamp2" select="$value"/>
        
    </xsl:template>
    
    <xsl:template match="node() | @*">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*"/>
        </xsl:copy>
    </xsl:template>
    
</xsl:stylesheet>