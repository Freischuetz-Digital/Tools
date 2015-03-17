<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    xmlns:mei="http://www.music-encoding.org/ns/mei"
    exclude-result-prefixes="xs xd"
    version="2.0">
    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p><xd:b>Created on:</xd:b> Jan 16, 2013</xd:p>
            <xd:p><xd:b>Author:</xd:b> Johannes Kepper</xd:p>
            <xd:p>
                This stylesheet recounts the measures within a movement. It takes
                a measure ID (param "startID"), and starting from that measure, modifies every subsequent
                measure's ID, @n, @facs, @join and @sameas affiliation by the amount specified 
                in the parameter "diff". It also adjusts zones correspondingly.
            </xd:p>
        </xd:desc>
    </xd:doc>
    
    <xsl:output indent="yes" method="xml" xpath-default-namespace="http://www.music-encoding.org/ns/mei"/>
    
    <xsl:param name="startID" select="'ED-kl_mov6_measure2'"/>
    <xsl:param name="diff" select="-1"/>
    
    <xsl:variable name="measures" select="id($startID) | id($startID)/following-sibling::mei:measure" as="node()*"/>
    
    <xsl:variable name="affectedMeasures" select="$measures/@xml:id" as="xs:string*"/>
    <xsl:variable name="affectedZones" select="$measures/substring(@facs,2)" as="xs:string*"/>
    
    
    <xsl:template match="/">
        <xsl:apply-templates/>
    </xsl:template>
    
    <xsl:template match="mei:measure">
        <xsl:choose>
            <xsl:when test="@xml:id = $affectedMeasures">
                <xsl:copy>
                    <xsl:variable name="begin" select="substring-before(@xml:id,'_measure')" as="xs:string"/>
                    <xsl:variable name="source" select="substring-before($begin,'_mov')" as="xs:string"/>
                    <xsl:variable name="mov" select="substring-after($begin, $source)" as="xs:string"/>
                    
                    <xsl:variable name="oldName" select="substring-after(@xml:id, '_measure')" as="xs:string"/>
                    
                    <!-- if measure name contains anything besides digits, letters and digits preceded by a dot are stripped -->
                    <xsl:variable name="oldNum" select="if(matches($oldName,'^\d+$')) then($oldName cast as xs:integer) else(replace($oldName,'([a-z]|\.\d+)','') cast as xs:integer)" as="xs:integer"/>
                    
                    <!-- letter eventually contained in the measure name, like the a in measure 28a -->
                    <xsl:variable name="appendix" select="if(matches($oldName,'[a-z]+')) then(replace($oldName,'[^a-z]+','')) else('')" as="xs:string"/>
                    
                    <!-- part of an id that distinguishes between parts of the same (logical) measure, like the .1 in measure 4.1 -->
                    <xsl:variable name="subNumber" select="if(contains($oldName,'.')) then(concat('.',substring-after($oldName,'.'))) else('')" as="xs:string"/>
                    
                    <xsl:variable name="newNum" select="string($oldNum + $diff)" as="xs:string"/>
                    
                    <xsl:attribute name="n" select="concat($newNum,$appendix)"/>
                    <xsl:attribute name="xml:id" select="concat($begin,'_measure',$newNum,$appendix,$subNumber)"/>
                    
                    <xsl:attribute name="facs" select="concat('#',$source,'_zoneOf',$mov,'_measure',$newNum,$appendix,$subNumber)"/>
                    <xsl:attribute name="sameas" select="concat('../core.xml#core',$mov,'_measure',$newNum,$appendix,$subNumber)"/>
                    
                    
                    <!-- if @join is available, measure423 is replaced by measure437. This assumes that all joined measures share a number -->
                    <xsl:if test="@join">
                        <xsl:attribute name="join" select="replace(@join,concat('measure',$oldNum),concat('measure',$newNum))"/>
                    </xsl:if>
                    
                    
                    <!--<xsl:if test="@join">
                        <xsl:variable name="join" select="tokenize(@join,' ')" as="xs:string*"/>
                        <xsl:variable name="new" as="xs:string*">
                            <xsl:for-each select="$join">
                                <xsl:value-of select="concat('#',$begin,'_measure',$newNum,$appendix,substring(.,string-length(.)-1))"/>
                            </xsl:for-each>
                        </xsl:variable>
                        <xsl:attribute name="join" select="string-join($new,' ')"/>    
                    </xsl:if>-->
                    
                    <xsl:apply-templates select="node() | @* except (@xml:id | @n | @join | @facs | @sameas)"/>
                    
                </xsl:copy>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy>
                    <xsl:apply-templates select="node() | @*"/>
                </xsl:copy>
            </xsl:otherwise>
        </xsl:choose>
        
    </xsl:template>
    
    <xsl:template match="mei:zone">
        <xsl:choose>
            <xsl:when test="@xml:id = $affectedZones">
                <xsl:copy>
                    <xsl:variable name="begin" select="substring-before(@xml:id,'_measure')" as="xs:string"/>
                    
                    <xsl:variable name="oldName" select="substring-after(@xml:id, '_measure')" as="xs:string"/>
                    
                    <!-- if measure name contains anything besides digits, letters and digits preceded by a dot are stripped -->
                    <xsl:variable name="oldNum" select="if(matches($oldName,'^\d+$')) then($oldName cast as xs:integer) else(replace($oldName,'([a-z]|\.\d+)','') cast as xs:integer)" as="xs:integer"/>
                    
                    <!-- letter eventually contained in the measure name, like the a in measure 28a -->
                    <xsl:variable name="appendix" select="if(matches($oldName,'[a-z]+')) then(replace($oldName,'[^a-z]+','')) else('')" as="xs:string"/>
                    
                    <!-- part of an id that distinguishes between parts of the same (logical) measure, like the .1 in measure 4.1 -->
                    <xsl:variable name="subNumber" select="if(contains($oldName,'.')) then(concat('.',substring-after($oldName,'.'))) else('')" as="xs:string"/>
                    
                    <xsl:variable name="newNum" select="string($oldNum + $diff)" as="xs:string"/>
                    
                    <xsl:attribute name="xml:id" select="concat($begin,'_measure',$newNum,$appendix,$subNumber)"/>
                    <xsl:attribute name="data" select="concat('#',replace($begin,'_zoneOf',''),'_measure',$newNum,$appendix,$subNumber)"/>
                    
                    <xsl:apply-templates select="node() | @* except (@xml:id | @data)"/>
                    
                </xsl:copy>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy>
                    <xsl:apply-templates select="node() | @*"/>
                </xsl:copy>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    
    <xsl:template match="node() | @*">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*"/>
        </xsl:copy>
    </xsl:template>
    
</xsl:stylesheet>