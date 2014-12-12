<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    xmlns:mei="http://www.music-encoding.org/ns/mei"
    xmlns:uuid="java:java.util.UUID"
    exclude-result-prefixes="xs math xd"
    version="3.0">
    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p><xd:b>Created on:</xd:b> Nov 14, 2014</xd:p>
            <xd:p><xd:b>Author:</xd:b> Johannes Kepper</xd:p>
            <xd:p>
                This xsl operates on an MEI file resembling a full movement, that is, all pages must have been merged already.
                All events and control events should have been checked at this point.
                
                In a first step (mode="include.cpMarks"), the xsl identifies the cpMarks.xml file provided by Joachim Iffland, and
                pulls in the corresponding cpMarks. 
                
                In a second step, it resolves all abbreviations, resulting in mei:choice elements with both the original shortcut (as
                mei:orig) and the correpsonding expansion (as mei:reg). The following shortcuts are resolved:
                
                <xd:ul>
                    <xd:li>
                        <xd:b>bTrem</xd:b>: resolved into repeated notes / chords
                    </xd:li>
                    <xd:li>
                        <xd:b>fTrem</xd:b>: resolved into repeating note / chord groups
                    </xd:li>
                    <xd:li>
                        <xd:b>mRpt</xd:b>: copies in the music from the preceding measure
                    </xd:li>
                    <xd:li>
                        <xd:b>beatRpt</xd:b>: copies in music from the preceding beat 
                    </xd:li>
                    <xd:li>
                        <xd:b>cpMark</xd:b>: copies in the music from the referenced measure
                    </xd:li>
                </xd:ul>
                
                
            </xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:output method="xml" indent="yes"/>
    
    <xsl:variable name="docPath" select="document-uri(/)"/>
    <xsl:variable name="cpMarksPath" select="substring-before($docPath,'/musicSources/') || '/musicSources/sourcePrep/11.1%20ShortcutList/cpMarks.xml'" as="xs:string"/>
    <xsl:variable name="cpMarks" select="doc($cpMarksPath)//mei:cpMark" as="node()*"/>    
    
    <xsl:template match="/">
        <xsl:variable name="included.cpMarks">
            <xsl:apply-templates mode="include.cpMarks"/>    
        </xsl:variable>
        <xsl:variable name="resolved.shortCuts">
            <xsl:apply-templates select="$included.cpMarks" mode="resolve.shortCuts"/>
        </xsl:variable>
        
        <xsl:copy-of select="$resolved.shortCuts"/>        
    </xsl:template>
    
    <!-- mode include.cpMarks -->
    
    <xsl:template match="mei:measure" mode="include.cpMarks">
        <xsl:variable name="measure.id" select="@xml:id"/>
        <xsl:copy>
            <xsl:apply-templates select="node() | @*" mode="#current"/>
            <xsl:apply-templates select="$cpMarks[@freidi.measure = $measure.id]" mode="include.cpMarks"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="mei:cpMark" mode="include.cpMarks">
        <xsl:copy>
            <xsl:attribute name="xml:id" select="'x' || uuid:randomUUID()"/>
            <xsl:apply-templates select="node() | @*" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="@freidi.measure" mode="include.cpMarks"/>
    
    <!-- mode resolve.shortCuts -->
    
    <!--<xsl:template match="mei:layer[./mei:mRest]/mei:mRest" mode="resolve.shortCuts">
        <xsl:variable name="layer.hasN" select="exists(parent::mei:layer/@n)" as="xs:boolean"/>
        <xsl:variable name="layer.n" select="parent::mei:layer/@n" as="xs:string?"/>
        <xsl:variable name="staff.n" select="ancestor::mei:staff/@n" as="xs:string"/>
        
        <xsl:variable name="preceding.measure" select="ancestor::mei:measure/preceding::mei:measure"/>
        <xsl:variable name="corresponding.layer" select="if($layer.hasN) then($preceding.measure/mei:staff[@n = $staff.n]/mei:layer[@n = $layer.n]) else($preceding.measure/mei:staff[@n = $staff.n]/mei:layer)" as="node()"/>
        <xsl:copy>
            <xsl:apply-templates select="$corresponding.layer" mode="prepareIDs"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="mei:measure/mei:*[not(@layer) and @staff = parent::mei:measure/mei:staff/@n[parent::mei:staff//mei:mRest]]" mode="resolve.shortCuts">
        
    </xsl:template>-->
    
    <!-- mode prepareIDs -->
    
    <xsl:template match="@xml:id" mode="prepareIDs">
        <xsl:attribute name="xml:id" select="'x' || uuid:randomUUID()"/>
        <xsl:attribute name="origID" select="."/>
    </xsl:template>
    
        
    
    
    <xsl:template match="node() | @*" mode="#all">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
</xsl:stylesheet>