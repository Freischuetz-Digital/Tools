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
            <xd:p><xd:b>Created on:</xd:b> Oct 10, 2014</xd:p>
            <xd:p><xd:b>Author:</xd:b> Johannes Kepper</xd:p>
            <xd:p>This stylesheet ensures that all relevant elements have xml:ids and
                that all events have tstamps to refer to. It is used in preparation
                of the proofreading of control events.</xd:p>
        </xd:desc>
    </xd:doc>
    
    <xsl:output method="xml" indent="yes"/>
    
    <xsl:variable name="version" select="'1.0'" as="xs:string"/>
    
    <!-- TODO: 
        nothing
    -->
    
    <xsl:template match="/">
        
        <xsl:if test="//mei:application[@xml:id = 'addIDs_and_tstamps']">
            <xsl:message terminate="yes">This file has already been processed by addIDs_and_tstamps.xsl. Execution stopped.</xsl:message>
        </xsl:if>
        
        <xsl:variable name="ids">
            <xsl:apply-templates mode="ids"/>
        </xsl:variable>
        
        <xsl:variable name="events">
            <xsl:apply-templates select="$ids" mode="events"/>    
        </xsl:variable>
        
        <xsl:variable name="controlEvents">
            <xsl:apply-templates select="$events" mode="controlEvents"/>
        </xsl:variable>
        
        <xsl:variable name="path" select="tokenize(document-uri(),'/')"/>
        
        <xsl:result-document href="{'../../../09.1 Added IDs/' || $path[last()-2] || '/' || $path[last() - 1] || '/' || $path[last()]}">
            <xsl:copy-of select="$events"/>    
        </xsl:result-document>
        
        
        <!--<xsl:copy-of select="$events"/>-->
    </xsl:template>
    
    <xsl:template match="mei:application[not(following-sibling::mei:application)]" mode="ids">
        <xsl:copy-of select="."/>
        <application xmlns="http://www.music-encoding.org/ns/mei" xml:id="addIDs_and_tstamps" version="{$version}">
            <name>addIDs_and_tstamps.xsl</name>
            <ptr target="../xslt/addIDs_and_tstamps.xsl"/>
        </application>
    </xsl:template>
    
    <xsl:template match="mei:change[not(following-sibling::mei:change)]" mode="ids">
        <xsl:copy-of select="."/>
        <change xmlns="http://www.music-encoding.org/ns/mei" n="{number(@n) + 1}">
            <respStmt>
                <persName nymref="#smJK"/>
            </respStmt>
            <changeDesc>
                <p>Automatically added @xml:ids (for notes added during proofreading of pitches) and 
                    tstamps for all events to prepare for proofreading of controlevents. Done by running
                    <ref target="#addIDs_and_tstamps">addIDs_and_tstamps.xsl</ref>, version 
                    <xsl:value-of select="$version"/>. 
                </p>
            </changeDesc>
            <date isodate="{substring(string(current-date()),1,10)}"/>
        </change>
    </xsl:template>
    
    <xsl:template match="mei:measure//mei:*[not(@xml:id)]" mode="ids">
        <xsl:copy>
            <xsl:attribute name="xml:id" select="'x' || uuid:randomUUID()"/>
            <xsl:apply-templates select="node() | @*" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="mei:measure" mode="events">
        <xsl:variable name="meter.count" select="(preceding::mei:scoreDef[@meter.count])[1]/@meter.count cast as xs:integer" as="xs:integer"/>
        <xsl:variable name="meter.unit" select="(preceding::mei:scoreDef[@meter.unit])[1]/@meter.unit cast as xs:integer" as="xs:integer"/>
          
        <xsl:copy>
            <xsl:apply-templates select="node() | @*" mode="#current">
                <xsl:with-param name="meter.count" select="$meter.count" tunnel="yes"/>
                <xsl:with-param name="meter.unit" select="$meter.unit" tunnel="yes"/>
            </xsl:apply-templates>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="mei:layer" mode="events">
        <xsl:param name="meter.count" tunnel="yes"/>
        <xsl:param name="meter.unit" tunnel="yes"/>
        
        <xsl:variable name="events" select=".//mei:*[(@dur and not((ancestor::mei:*[@dur] or ancestor::mei:bTrem or ancestor::mei:fTrem)) and not(@grace)) or (local-name() = ('bTrem','fTrem','beatRpt','halfmRpt'))]"/>
        <xsl:variable name="durations" as="xs:double*">
            
            <xsl:for-each select="$events">
                <xsl:variable name="dur" as="xs:double">
                    <xsl:choose>
                        <xsl:when test="@dur">
                            <xsl:value-of select="1 div number(@dur)"/>
                        </xsl:when>
                        <xsl:when test="local-name() = 'bTrem'">
                            <xsl:value-of select="1 div (child::mei:*)[1]/number(@dur)"/>
                        </xsl:when>
                        <xsl:when test="local-name() = 'fTrem'">
                            <xsl:value-of select="1 div ((child::mei:*)[1]/number(@dur) * 2)"/>
                        </xsl:when>
                        <xsl:when test="local-name() = 'beatRpt'">
                            <xsl:value-of select="1 div $meter.unit"/>
                        </xsl:when>
                        <xsl:when test="local-name() = 'halfmRpt'">
                            <xsl:value-of select="($meter.count div 2) div $meter.unit"/>
                        </xsl:when>
                    </xsl:choose>
                </xsl:variable>
                <xsl:variable name="tupletFactor" as="xs:double">
                    <xsl:choose>
                        <xsl:when test="ancestor::mei:tuplet">
                            <xsl:value-of select="(ancestor::mei:tuplet)[1]/number(@numbase) div (ancestor::mei:tuplet)[1]/number(@num)"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="1"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <xsl:variable name="dots" as="xs:double">
                    <xsl:choose>
                        <xsl:when test="@dots">
                            <xsl:value-of select="number(@dots)"/>
                        </xsl:when>
                        <xsl:when test="local-name() = 'bTrem' and child::mei:*/@dots">
                            <xsl:value-of select="child::mei:*[@dots]/number(@dots)"/>
                        </xsl:when>
                        <xsl:when test="local-name() = 'fTrem' and child::mei:*/@dots">
                            <xsl:value-of select="child::mei:*[@dots][1]/number(@dots)"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="0"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <xsl:value-of select="(2 * $dur - ($dur div math:pow(2,$dots))) * $tupletFactor"/>
            </xsl:for-each>
        </xsl:variable>
        <xsl:variable name="tstamps">
            <xsl:for-each select="$events">
               <xsl:variable name="pos" select="position()"/>
               <event id="{@xml:id}" onset="{sum($durations[position() lt $pos])}"/>
            </xsl:for-each>
        </xsl:variable>
        
        <xsl:copy>
            <xsl:apply-templates select="node() | @*" mode="#current">
                <xsl:with-param name="tstamps" select="$tstamps" tunnel="yes"/>
            </xsl:apply-templates>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="mei:layer//mei:*[(@dur and not((ancestor::mei:*[@dur] or ancestor::mei:bTrem or ancestor::mei:fTrem)) and not(@grace)) or (local-name() = ('bTrem','fTrem','beatRpt','halfmRpt'))]" mode="events">
        <xsl:param name="tstamps" tunnel="yes"/>
        <xsl:param name="meter.count" tunnel="yes"/>
        <xsl:param name="meter.unit" tunnel="yes"/>
        <xsl:variable name="id" select="@xml:id" as="xs:string"/>
        <xsl:variable name="onset" select="$tstamps//*[@id=$id]/@onset"/>
        <xsl:copy>
            <xsl:apply-templates select="@*" mode="#current"/>
            <xsl:choose>
                <xsl:when test="local-name() = 'bTrem'">
                    <xsl:copy-of select="child::mei:*/@dur | child::mei:*/@dots"/>
                </xsl:when>
                <xsl:when test="local-name() = 'fTrem'">
                    <xsl:copy-of select="(child::mei:*)[1]/@dur | (child::mei:*)[1]/@dots"/>
                </xsl:when>
                <xsl:when test="local-name() = 'beatRpt'">
                    <xsl:attribute name="dur" select="$meter.unit"/>
                </xsl:when>
                <xsl:when test="local-name() = 'halfmRpt'">
                    <xsl:choose>
                        <xsl:when test="$meter.count = 4 and $meter.unit = 4">
                            <xsl:attribute name="dur" select="2"/>        
                        </xsl:when>
                        <xsl:when test="$meter.count = 6 and $meter.unit = 8">
                            <xsl:attribute name="dur" select="4"/>
                            <xsl:attribute name="dots" select="1"/>
                        </xsl:when>
                        <xsl:when test="$meter.count = 2 and $meter.unit = 2">
                            <xsl:attribute name="dur" select="2"/>
                        </xsl:when>
                        <xsl:when test="$meter.count = 2 and $meter.unit = 4">
                            <xsl:attribute name="dur" select="4"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:attribute name="dur"/>
                            <xsl:message>Could not identify the correct duration for halfmRpt</xsl:message>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
            </xsl:choose>
            <xsl:attribute name="tstamp" select="($onset * $meter.unit) + 1"/>
            <xsl:apply-templates select="node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="mei:mRest" mode="events">
        <xsl:copy>
            <xsl:apply-templates select="@*" mode="#current"/>
            <xsl:attribute name="tstamp" select="'1'"/>
            <xsl:apply-templates select="node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="mei:mSpace" mode="events">
        <xsl:copy>
            <xsl:apply-templates select="@*" mode="#current"/>
            <xsl:attribute name="tstamp" select="'1'"/>
            <xsl:apply-templates select="node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="mei:mRpt" mode="events">
        <xsl:copy>
            <xsl:apply-templates select="@*" mode="#current"/>
            <xsl:attribute name="tstamp" select="'1'"/>
            <xsl:apply-templates select="node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="node() | @*" mode="#all">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
</xsl:stylesheet>