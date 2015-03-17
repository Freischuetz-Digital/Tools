<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    xmlns:mei="http://www.music-encoding.org/ns/mei"
    xmlns:uuid="java:java.util.UUID"
    xmlns:local="local"
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
    
    <xsl:function name="local:compareEvents">
        
    </xsl:function>
    
    
    <xsl:param name="coreName" select="'_core_KA1_mov6.xml'" as="xs:string"/>
    <xsl:variable name="baseURI" select="substring-before(document-uri(/),tokenize(document-uri(/),'/')[last()])" as="xs:string"/>
    <xsl:variable name="core" select="doc($baseURI || '/' || $coreName)" as="node()"/>
    <xsl:variable name="source" select="/" as="node()"/>
    
    <xsl:template match="/">
        <xsl:apply-templates select="$core" mode="frame"/>
    </xsl:template>
    
    <!-- temporary templates -->
    <xsl:template match="mei:meiHead" mode="frame"/>
    <xsl:template match="mei:scoreDef" mode="frame"/>
    
    <xsl:template match="mei:measure" mode="frame">
        <xsl:variable name="measureID" select="@xml:id" as="xs:string"/>
        
        <xsl:variable name="coreMeasure" select="." as="node()"/>
        <xsl:variable name="sourceMeasure" select="$source//mei:measure[@xml:id = $measureID]" as="node()"/>
        <xsl:variable name="staff.ns" select="distinct-values(./mei:staff/@n)" as="xs:string*"/>
        
        <xsl:for-each select="$staff.ns">
            <xsl:variable name="staff.n" select="."/>
            <xsl:variable name="staffProfiles.core" as="node()*">
                <xsl:apply-templates select="$coreMeasure/mei:staff[@n = $staff.n]" mode="profiling"/>
            </xsl:variable>
            <xsl:variable name="staffProfiles.source" as="node()*">
                <xsl:apply-templates select="$sourceMeasure/mei:staff[@n = $staff.n]" mode="profiling"/>
            </xsl:variable>
            
            <xsl:for-each select="$staffProfiles.source">
                <xsl:variable name="staffProfile.source" select="." as="node()"/>
                
                <xsl:for-each select="$staffProfiles.core">
                    <xsl:variable name="staffProfile.core" select="." as="node()"/>
                    
                    <xsl:choose>
                        <xsl:when test="deep-equal($staffProfile.source/mei:events,$staffProfile.core/mei:events)">
                            <!--<xsl:message select="'all the same in ' || $measureID || ' in staff ' || $staff.n"/>-->
                        </xsl:when>
                        <xsl:otherwise>
                            
                            <xsl:message select="'there are different events in ' || $measureID || ' in staff ' || $staff.n"/>
                            
                            <xsl:variable name="maxCount" select="max(count($staffProfile.source/mei:events/mei:*),$staffProfile.core/mei:events/mei:*)" as="xs:integer"/>                            

                            
                            <xsl:for-each select="(1 to maxCount)">
                                
                            </xsl:for-each>

                            <xsl:for-each select="$staffProfile.source/mei:events/mei:*">
                                <xsl:variable name="pos" select="position()" as="xs:integer"/>
                                <xsl:variable name="event.source" select="." as="node()"/>
                                <xsl:if test="not(deep-equal($event.source,$staffProfile.core/mei:events/mei:*[$pos]))">
                                    <xsl:message select="$staffProfile.source/mei:eventIDs/mei:eventID[$pos]/@xml:id || ' differs from ' || $staffProfile.core/mei:eventIDs/mei:eventID[$pos]/@xml:id"/>
                                    <difference xmlns="http://www.music-encoding.org/ns/mei" measure="{$measureID}" staff="{$staff.n}" type="event">
                                        <xsl:variable name="sourceElem" select="$source/id($staffProfile.source/mei:eventIDs/mei:eventID[$pos]/@xml:id)" as="node()"/>
                                        <xsl:variable name="coreElem" select="$core/id($staffProfile.core/mei:eventIDs/mei:eventID[$pos]/@xml:id)" as="node()"/>
                                        <xsl:variable name="diffType" select="if(local-name($sourceElem) != local-name($coreElem)) then('element') else('attributes')" as="xs:string"/>
                                        <source>
                                            <xsl:copy-of select="$sourceElem"/>    
                                        </source>
                                        <core>
                                            <xsl:copy-of select="$coreElem"/>    
                                        </core>
                                        <diffType type="{$diffType}">
                                            <xsl:if test="$diffType = 'attributes'">
                                                <xsl:variable name="atts.onlyInSource" select="$sourceElem/(@* except @xml:id)[not(local-name() = ($coreElem/(@* except @xml:id)/local-name()))]/local-name()" as="xs:string*"/>
                                                <xsl:variable name="atts.onlyInCore" select="$coreElem/(@* except @xml:id)[not(local-name() = ($sourceElem/(@* except @xml:id)/local-name()))]/local-name()" as="xs:string*"/>
                                                <xsl:variable name="atts.shared" select="$sourceElem/(@* except @xml:id)[local-name() = ($coreElem/(@* except @xml:id)/local-name())]/local-name()" as="xs:string*"/>
                                                <xsl:variable name="differingValues" as="xs:string*">
                                                    <xsl:for-each select="$atts.shared">
                                                        <xsl:variable name="att.name" select="." as="xs:string"/>
                                                        <xsl:if test="not(deep-equal($coreElem/@*[local-name() = $att.name],$sourceElem/@*[local-name() = $att.name]))">
                                                            <xsl:value-of select="$att.name"></xsl:value-of>
                                                        </xsl:if>
                                                    </xsl:for-each>
                                                </xsl:variable>
                                                
                                                <xsl:attribute name="onlyInSource" select="string-join($atts.onlyInSource,',')"/>
                                                <xsl:attribute name="onlyInCore" select="string-join($atts.onlyInCore,',')"/>
                                                <xsl:attribute name="differingValues" select="string-join($differingValues,',')"/>
                                            </xsl:if>
                                        </diffType>
                                    </difference>
                                </xsl:if>
                            </xsl:for-each>
                            
                            
                            <!--<difference xmlns="http://www.music-encoding.org/ns/mei" measure="{$measureID}" staff="{$staff.n}" type="event">
                                <core>
                                    <xsl:copy-of select="$staffProfile.core/mei:events"/>
                                </core>
                                <source xmlns="http://www.music-encoding.org/ns/mei" measure="{$measureID}" staff="{$staff.n}">
                                    <xsl:copy-of select="$staffProfile.source/mei:events"/>
                                </source>
                            </difference>-->
                        </xsl:otherwise>
                    </xsl:choose>
                    
                    <xsl:choose>
                        <xsl:when test="deep-equal($staffProfile.source/mei:other,$staffProfile.core/mei:other)">
                            <!--<xsl:message select="'all the same in ' || $measureID || ' in staff ' || $staff.n"/>-->
                        </xsl:when>
                        <xsl:otherwise>
                            <difference xmlns="http://www.music-encoding.org/ns/mei" measure="{$measureID}" staff="{$staff.n}" type="other"/>
                            <!--<xsl:message select="'there are unspecific differences in ' || $measureID || ' in staff ' || $staff.n"/>
                            <difference xmlns="http://www.music-encoding.org/ns/mei" measure="{$measureID}" staff="{$staff.n}" type="other">
                                <core>
                                    <xsl:copy-of select="$staffProfile.core/mei:other"/>
                                </core>
                                <source>
                                    <xsl:copy-of select="$staffProfile.source/mei:other"/>
                                </source>
                            </difference>-->
                        </xsl:otherwise>
                    </xsl:choose>
                    
                </xsl:for-each>
                
            </xsl:for-each>
        </xsl:for-each>
        
    </xsl:template>
    
    <!--
    mRest
    choice
    rest
    note
    beam
    clef
    chord
    -->
    
    <!-- mode profiling -->
    <xsl:template match="@xml:id" mode="profiling"/>
    <xsl:template match="mei:staff" mode="profiling">
        
        <xsl:variable name="prep">
            <xsl:apply-templates mode="profiling.prep"/>
        </xsl:variable>
        
        <staff xmlns="http://www.music-encoding.org/ns/mei">
            <events>
                <xsl:apply-templates select="$prep//(mei:note | mei:rest | mei:space | mei:clef)" mode="#current">
                    <xsl:sort select="@tstamp" data-type="number"/>
                    <xsl:sort select="local-name()" data-type="text"/>
                </xsl:apply-templates>
            </events>
            <eventIDs>
                <xsl:for-each select="$prep//mei:*[@tstamp]">
                    <eventID xml:id="{@xml:id}"/>
                </xsl:for-each>
            </eventIDs>
            <other>
                <xsl:apply-templates select="$prep//mei:layer//mei:*[not(@tstamp)]" mode="#current"/>
            </other>
            <otherIDs>
                <xsl:for-each select="$prep//mei:layer//mei:*[not(@tstamp)]">
                    <otherID xml:id="{@xml:id}"/>
                </xsl:for-each>
            </otherIDs>
        </staff>
    </xsl:template>
    
    <xsl:template name="setGraceOffset" as="xs:double">
        <xsl:param name="note" required="yes" as="node()"/>
        <xsl:variable name="next" as="xs:double">
            <xsl:choose>
                <xsl:when test="$note/following::mei:note[1]/@grace">
                    <xsl:call-template name="setGraceOffset">
                        <xsl:with-param name="note" select="$note/following::mei:note[1]" as="node()"/>
                    </xsl:call-template>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="0"/>
                </xsl:otherwise>
            </xsl:choose>    
        </xsl:variable>
        <xsl:value-of select="$next + 0.001"/>        
    </xsl:template>
    
    <!-- mode profiling.prep -->
    <xsl:template match="mei:note[@grace and not(@tstamp)]" mode="profiling.prep">
        <xsl:variable name="tstampOffset" as="xs:double">
            <xsl:call-template name="setGraceOffset">
                <xsl:with-param name="note" select="."/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:copy>
            <xsl:attribute name="tstamp" select="number(following-sibling::mei:note[@tstamp][1]/@tstamp) - $tstampOffset"/>
            <xsl:apply-templates select="node() | @*" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="mei:note[parent::mei:chord]" mode="profiling.prep">
        <xsl:copy>
            <xsl:attribute name="tstamp" select="parent::mei:chord/@tstamp"/>
            <xsl:apply-templates select="node() | @*" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="mei:clef[not(@tstamp)]" mode="profiling.prep">
        <xsl:copy>
            <xsl:variable name="tstamp" as="xs:string">
                <xsl:choose>
                    <xsl:when test="following-sibling::mei:*[@tstamp]">
                        <xsl:value-of select="number(following-sibling::mei:*[@tstamp][1]/@tstamp) - 0.005"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="number(preceding-sibling::mei:*[@tstamp][1]/@tstamp) + 0.005"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            <xsl:attribute name="tstamp" select="$tstamp"/>
            <xsl:apply-templates select="node() | @*" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="mei:beam" mode="profiling.prep">
        <xsl:apply-templates select="node()" mode="#current"/>
    </xsl:template>
    <xsl:template match="mei:chord" mode="profiling.prep">
        <xsl:apply-templates select="node()" mode="#current"/>
    </xsl:template>
    <xsl:template match="comment()" mode="profiling.prep"/>
    
    
    <!-- generic copy template -->
    
    <xsl:template match="node() | @*" mode="#all">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
</xsl:stylesheet>