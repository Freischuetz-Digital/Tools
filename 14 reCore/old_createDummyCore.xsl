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
    
    <xsl:variable name="uri" select="document-uri(/)" as="xs:string"/>
    <xsl:variable name="fileName" select="tokenize($uri,'/')[last()]" as="xs:string"/>
    <xsl:variable name="baseURI" select="substring-before($uri,$fileName) || '/'" as="xs:string"/>
    
    <xsl:variable name="sourceRef" select="'#' || //mei:mei/@xml:id" as="xs:string"/>
    
    <xsl:variable name="coreFile">
        <xsl:apply-templates mode="coreFile"/>    
    </xsl:variable>
    
    <xsl:template match="/">
        <xsl:result-document href="{$baseURI || '_' || $fileName}">
            <xsl:apply-templates mode="sourceFile"/>
        </xsl:result-document>
        <xsl:result-document href="{$baseURI || '../_core_' || $fileName}">
            <xsl:apply-templates select="$coreFile" mode="coreFileCleanup"/>
        </xsl:result-document>
    </xsl:template>
    
    <!-- mode coreFile -->
    <xsl:template match="mei:choice" mode="coreFile">
        <xsl:choose>
            <xsl:when test="count(mei:reg) gt 1">
                <app xmlns="http://www.music-encoding.org/ns/mei">
                    <xsl:for-each select="mei:reg">
                        <rdg source="{$sourceRef}">
                            <xsl:apply-templates select="mei:*"/>
                        </rdg>
                    </xsl:for-each>
                </app>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="mei:reg/mei:*" mode="#current"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="mei:measure/@xml:id" mode="coreFile">
        <xsl:attribute name="xml:id" select="replace(.,substring-after($sourceRef,'#') || '_mov','core_mov')"/>
    </xsl:template>
    
    <xsl:template match="mei:measure//mei:*/@xml:id" mode="coreFile">
        <xsl:attribute name="newID" select="'c'||uuid:randomUUID()"/>
        <xsl:attribute name="xml:id" select="."/>
    </xsl:template>
    
    <!-- attributes and elements that don't belong in the core -->
    <xsl:template match="@stem.dir" mode="coreFile"/>
    <xsl:template match="@sameas" mode="coreFile"/>
    <xsl:template match="@curvedir" mode="coreFile"/>
    <xsl:template match="@place" mode="coreFile"/>
    <xsl:template match="@facs" mode="coreFile"/>
    <xsl:template match="mei:mRest/@dur" mode="coreFile"/>
    <xsl:template match="mei:facsimile" mode="coreFile"/>
    
    <!-- mode sourceFile -->
    
    <xsl:template match="mei:measure/@sameas" mode="sourceFile">
        <xsl:attribute name="sameas" select="replace(.,'../core.xml' || $sourceRef,'../freidi-musicCore.xml#core')"/>
    </xsl:template>
    
    <!-- @sameas: measure, mRest, note, rest, slur, chord, clef, dynam, dir -->
    <xsl:template match="mei:mRest | mei:rest | mei:note | mei:chord | mei:slur | mei:clef | mei:dynam | mei:dir " mode="sourceFile">
        <xsl:variable name="id" select="@xml:id"/>
        <xsl:copy>
            <xsl:attribute name="sameas" select="'../freidi-musicCore.xml/#' || $coreFile//mei:*[@xml:id = $id]/@newID"/>
            <xsl:apply-templates select="node() | @* except @sameas"/>
        </xsl:copy>
    </xsl:template>
    
    <!-- attributes and elements that don't belong in the sources -->
    <xsl:template match="@dur" mode="sourceFile"/>
    <xsl:template match="@dots" mode="sourceFile"/>
    <xsl:template match="@oct" mode="sourceFile"/>
    <xsl:template match="@pname" mode="sourceFile"/>
    <xsl:template match="@accid" mode="sourceFile"/>
    <xsl:template match="@accid.ges" mode="sourceFile"/>
    <xsl:template match="mei:mRest/@dur" mode="sourceFile"/>
    
    <!-- mode coreFileCleanup -->
    <xsl:template match="mei:measure//mei:*/@xml:id" mode="coreFileCleanup">
        <xsl:attribute name="xml:id" select="parent::mei:*/@newID"/>
    </xsl:template>
    
    <xsl:template match="@startid" mode="coreFileCleanup">
        <xsl:variable name="startid" select="."/>
        <xsl:attribute name="startid" select="'#' || $coreFile//mei:*[@xml:id = replace($startid,'#','')]/@newID"/>
    </xsl:template>
    
    <xsl:template match="@endid" mode="coreFileCleanup">
        <xsl:variable name="endid" select="."/>
        <xsl:attribute name="endid" select="'#' || $coreFile//mei:*[@xml:id = replace($endid,'#','')]/@newID"/>
    </xsl:template>
    
    <xsl:template match="@newID" mode="coreFileCleanup"/>
    
    <!-- generic copy template -->
    
    <xsl:template match="node() | @*" mode="#all">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
</xsl:stylesheet>