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
            <xd:p><xd:b>Created on:</xd:b> Oct 27, 2015</xd:p>
            <xd:p><xd:b>Author:</xd:b> Johannes Kepper</xd:p>
            <xd:p>
                This stylesheet operates on the Edirom file in 00 measure positions. 
                It pulls in all existing movements for that particular source in 
            </xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:output method="xml" indent="yes"/>
    
    <xsl:variable name="repo.path" select="substring-before(document-uri(),'edition/')" as="xs:string"/>
    
    <xsl:variable name="core.docs" select="collection($repo.path || 'musicSources/sourcePrep/14%20reCored/?select=*.xml')//mei:mei[starts-with(tokenize(document-uri(./root()),'/')[last()],'core_mov')]" as="node()*"/>
    
    <xsl:template match="/">
        
        <xsl:message select="'INFO: Found music for movements ' || string-join($core.docs//mei:mdiv/@xml:id,', ')"/>
        
        <xsl:variable name="included.music">
            <xsl:apply-templates mode="pull.mdivs"/>    
        </xsl:variable>
        
        <xsl:variable name="cleaned.header">
            <xsl:apply-templates select="$included.music" mode="header"/>
        </xsl:variable>
        
        <xsl:result-document href="{$repo.path || 'musicSources/sourcePrep/15%20ReleasePrep/freidi-work.xml'}">
            <xsl:copy-of select="$cleaned.header"/>
        </xsl:result-document>
        
    </xsl:template>
    
    <xsl:template match="mei:music" mode="pull.mdivs">
        <xsl:copy>
            <body xmlns="http://www.music-encoding.org/ns/mei">
                <xsl:for-each select="$core.docs//mei:mdiv">
                    <xsl:sort select="number(substring-after(@xml:id,'_mov'))" data-type="number"/>
                    <xsl:variable name="mdiv" select="." as="node()"/>
                    <xsl:apply-templates select="$mdiv" mode="#current"/>
                </xsl:for-each>
            </body>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="mei:change//mei:persName/@xml:id" mode="header"/>
    
    <xsl:template match="mei:appInfo" mode="header">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*" mode="#current"/>
            <application xmlns="http://www.music-encoding.org/ns/mei">
                <xsl:attribute name="xml:id" select="'releasePrepCore_v1.0.0'"/>
                <xsl:attribute name="version" select="'1.0.0'"/>
                <name>releasePrepCore.xsl</name>
                <ptr target="https://github.com/Freischuetz-Digital/Tools/blob/develop/15%20ReleasePrep/releasePrepCore.xsl"/>
            </application>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="node() | @*" mode="#all">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
</xsl:stylesheet>