<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    xmlns:mei="http://www.music-encoding.org/ns/mei"
    xmlns:uuid="java:java.util.UUID"
    exclude-result-prefixes="xs math xd mei uuid"
    version="3.0">
    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p><xd:b>Created on:</xd:b> Nov 14, 2014</xd:p>
            <xd:p><xd:b>Author:</xd:b> Johannes Kepper</xd:p>
            <xd:p>
                
            </xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:output method="xml" indent="yes"/>
    
    
    <xsl:template match="/">
        <xsl:variable name="resolvedTrems">
            <xsl:apply-templates mode="resolveTrems"/>
        </xsl:variable>
        <xsl:variable name="resolvedRpts">
            <xsl:apply-templates mode="resolveRpts" select="$resolvedTrems"/>
        </xsl:variable>
        <xsl:copy-of select="$resolvedRpts"/>
    </xsl:template>
    
    <!-- resolving bTrems -->
    <xsl:template match="mei:bTrem[not(parent::mei:orig)]" mode="resolveTrems">
        <choice xmlns="http://www.music-encoding.org/ns/mei" xml:id="c{uuid:randomUUID()}">
            <orig>
                <xsl:copy>
                    <xsl:apply-templates select="node() | @*" mode="#current"/>
                </xsl:copy>
            </orig>
            <reg>
                <xsl:variable name="elem" select="child::mei:*" as="node()"/>
                <xsl:variable name="dur" select="1 div number($elem/@dur)"/>
                <xsl:variable name="dots" select="if($elem/@dots) then(number($elem/@dots)) else(0)"/>
                <xsl:variable name="totalDur" select="(2 * $dur) - ($dur div math:pow(2,$dots))" as="xs:double"/>
                <xsl:variable name="count" select="($totalDur div ((1 div 8) div number(substring($elem/@stem.mod,1,1)))) cast as xs:integer" as="xs:integer"/>
                
                <xsl:message select="$totalDur || ' dur makes ' || $count || ' found'"></xsl:message>
                
                <xsl:for-each select="(1 to $count)">
                    <xsl:element name="{local-name($elem)}" xmlns="http://www.music-encoding.org/ns/mei">
                        <xsl:attribute name="xml:id" select="'e' || uuid:randomUUID()"/>
                        <xsl:apply-templates select="$elem/(@* except (@xml:id, @tstamp, @stem.mod, @sameas))" mode="resolveTrems"/>
                    </xsl:element>
                </xsl:for-each>
            </reg>
        </choice>
    </xsl:template>
    
    <!-- mode resolveRpts -->
    <xsl:template match="mei:mRpt[not(parent::mei:orig)]" mode="resolveRpts">
        <choice xmlns="http://www.music-encoding.org/ns/mei" xml:id="c{uuid:randomUUID()}">
            <orig>
                <xsl:copy>
                    <xsl:apply-templates select="node() | @*"/>
                </xsl:copy>
            </orig>
            <reg>
                <xsl:variable name="layer.hasN" select="exists(parent::mei:layer/@n)" as="xs:boolean"/>
                <xsl:variable name="layer.n" select="parent::mei:layer/@n" as="xs:string?"/>
                <xsl:variable name="staff.n" select="ancestor::mei:staff/@n" as="xs:string"/>
                
                <xsl:variable name="preceding.measure" select="ancestor::mei:measure/preceding::mei:measure[not(mei:staff[@n = $staff.n]/mei:layer[@n = $layer.n]/mei:mRpt)][1]"/>
                <xsl:variable name="corresponding.layer" select="if($layer.hasN) then($preceding.measure/mei:staff[@n = $staff.n]/mei:layer[@n = $layer.n]) else($preceding.measure/mei:staff[@n = $staff.n]/mei:layer)" as="node()"/>
                <xsl:apply-templates select="$corresponding.layer/mei:*" mode="adjustMaterial"/>
            </reg>
        </choice>
    </xsl:template>
    
    <xsl:template match="mei:choice" mode="adjustMaterial">
        <xsl:message select="'found a choice to remove: ' || @xml:id"/>
        <xsl:apply-templates select="mei:reg/mei:*" mode="#current"/>
    </xsl:template>
    
    <xsl:template match="@xml:id" mode="adjustMaterial">
        <xsl:attribute name="xml:id" select="'r'||uuid:randomUUID()"/>
    </xsl:template>
    
    <!-- things to exclude from repeating -->
    <xsl:template match="mei:clef" mode="adjustMaterial"/>
    
    <xsl:template match="mei:measure[.//mei:mRpt]" mode="resolveRpts">
        <xsl:variable name="staffNs" select="mei:staff[.//mei:mRpt]/@n" as="xs:string*"/>
        <xsl:variable name="preceding.measure" select="preceding::mei:measure[1]"/>
        
        <xsl:copy>
            <xsl:apply-templates select="node() | @*" mode="#current"/>
            
            <xsl:comment>Need to check for controlevents from preceding measure for staves <xsl:value-of select="string-join($staffNs,', ')"/></xsl:comment>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="node() | @*" mode="#all">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
</xsl:stylesheet>