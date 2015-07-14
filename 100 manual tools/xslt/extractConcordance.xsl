<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    xmlns:mei="http://www.music-encoding.org/ns/mei"
    exclude-result-prefixes="xs xd"
    version="3.0">
    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p><xd:b>Created on:</xd:b> Feb 21, 2013</xd:p>
            <xd:p><xd:b>Author:</xd:b> Johannes Kepper</xd:p>
            <xd:p>This file is supposed to be applied to the musicCore file (freidi-musicCore.xml).</xd:p>
        </xd:desc>
    </xd:doc>
    
    <xsl:output method="xml" indent="yes"/>
    
    <xsl:variable name="basePath" select="substring-before(document-uri(/),'/edition')" as="xs:string"/>
    <xsl:variable name="sources" select="collection($basePath || '/musicSources/sourcePrep/00 measure positions/?select=*.xml')//mei:mei[not(starts-with(tokenize(document-uri(./root()),'/')[last()],'_'))]"/>
    
    <xsl:template match="/">
        <concordance name="Taktkonkordanz nach neuer Struktur">
            <xsl:comment>Concordance automatically generated on <xsl:value-of select="substring(string(current-date()),1,10)"/>
                Sources considered: <xsl:value-of select="string-join($sources/@xml:id,', ')"/></xsl:comment>
            <groups label="Satz">
                <xsl:apply-templates select=".//mei:mdiv"/>
            </groups>
        </concordance>
    </xsl:template>
    
    <xsl:template match="mei:mdiv">
        <group name="{@label}">
            <connections label="Takt">
                <xsl:apply-templates select=".//mei:measure"/>
            </connections>
        </group>    
    </xsl:template>
    
    <xsl:template match="mei:measure">
        <xsl:variable name="coreID" select="@xml:id" as="xs:string"/>
        <xsl:variable name="prefix" select="'xmldb:exist:///db/contents/sources/'" as="xs:string"/>
        <xsl:variable name="measures" select="$sources//mei:measure[@sameas = concat('../core.xml#',$coreID)]" as="node()*"/>
        
        <xsl:if test="count($measures) lt count($sources)">
            <xsl:variable name="unfilled.sources" select="$sources[not(.//mei:measure[@sameas = concat('../core.xml#',$coreID)])]" as="node()+"/>            
            <xsl:message select="concat('measure ', $coreID,' not referenced in source(s) ',string-join($unfilled.sources/@xml:id,', '))"/>
        </xsl:if>
        
        <xsl:variable name="references" as="xs:string*">
            <xsl:for-each select="$measures">
                <xsl:variable name="id" select="@xml:id" as="xs:string"/>
                <xsl:variable name="file" select="tokenize(document-uri(./root()),'/')[last()]" as="xs:string"/>
                <xsl:value-of select="concat($prefix,$file,'#',$id)"/>
            </xsl:for-each>
        </xsl:variable>
        
        <connection name="{string(@n)}" plist="{string-join($references,' ')}"/>
        
    </xsl:template>
    
</xsl:stylesheet>