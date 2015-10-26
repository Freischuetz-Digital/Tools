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
            <xd:p><xd:b>Created on:</xd:b> Sep 10, 2015</xd:p>
            <xd:p><xd:b>Author:</xd:b> johannes</xd:p>
            <xd:p></xd:p>
        </xd:desc>
    </xd:doc>
    
    <xsl:output method="xml" indent="yes"/>
    
    <xsl:variable name="source.id" select="/mei:mei/@xml:id" as="xs:string"/>
    <xsl:variable name="mov.id" select="/mei:mdiv/@xml:id" as="xs:string"/>
    
    <xsl:variable name="perfMedium" as="node()">
        <perfMedium xmlns="http://www.music-encoding.org/ns/mei">
            <instrumentation>
                <xsl:for-each select="(//mei:score/mei:scoreDef)[1]//mei:staffDef">
                    <xsl:variable name="staffdef" select="." as="node()"/>
                    <instrVoice xml:id="in{uuid:randomUUID()}" label="" n="{$staffdef/@n}" authURI="http://www.loc.gov/standards/valuelist/marcmusperf.html">
                        <xsl:choose>
                            <xsl:when test="$staffdef/@label = 'Clarinetti in B'">
                                <xsl:attribute name="code" select="'wc'"/>
                            </xsl:when>
                            <xsl:when test="$staffdef/@label = 'Clarinetti in B.'">
                                <xsl:attribute name="code" select="'wc'"/>
                            </xsl:when>
                            <xsl:when test="$staffdef/@label = 'Clarinetti [in B]'">
                                <xsl:attribute name="code" select="'wc'"/>
                            </xsl:when>
                            <xsl:when test="$staffdef/@label = 'Clarinetti in C'">
                                <xsl:attribute name="code" select="'wc'"/>
                            </xsl:when>
                            <xsl:when test="$staffdef/@label = 'Clarinetto in C (Theater)'">
                                <xsl:attribute name="code" select="'wc'"/>
                            </xsl:when>
                            <xsl:when test="$staffdef/@label = 'Corni in Es'">
                                <xsl:attribute name="code" select="'wf'"/>
                            </xsl:when>
                            <xsl:when test="$staffdef/@label = 'Corni in F'">
                                <xsl:attribute name="code" select="'wf'"/>
                            </xsl:when>
                            <xsl:when test="$staffdef/@label = 'Corni [in F]'">
                                <xsl:attribute name="code" select="'wf'"/>
                            </xsl:when>
                            <xsl:when test="$staffdef/@label = 'Corni in C'">
                                <xsl:attribute name="code" select="'wf'"/>
                            </xsl:when>
                            <xsl:when test="$staffdef/@label = 'Corni in G (a. d. Th.)'">
                                <xsl:attribute name="code" select="'wf'"/>
                            </xsl:when>
                            <xsl:when test="$staffdef/@label = 'Fagotti'">
                                <xsl:attribute name="code" select="'wd'"/>
                            </xsl:when>
                            <xsl:when test="$staffdef/@label = 'Viole'">
                                <xsl:attribute name="code" select="'sb'"/>
                            </xsl:when>
                            <xsl:when test="$staffdef/@label = 'Violoncello Solo'">
                                <xsl:attribute name="code" select="'sc'"/>
                            </xsl:when>
                            <xsl:when test="$staffdef/@label = 'Violoncelli'">
                                <xsl:attribute name="code" select="'sc'"/>
                            </xsl:when>
                            <xsl:when test="$staffdef/@label = 'Violoncello (Theater)'">
                                <xsl:attribute name="code" select="'sc'"/>
                            </xsl:when>
                            <xsl:when test="$staffdef/@label = 'Bassi'">
                                <xsl:attribute name="code" select="''"/>
                            </xsl:when>
                            <xsl:when test="$staffdef/@label = 'Baßi'">
                                <xsl:attribute name="code" select="''"/>
                            </xsl:when>
                            <xsl:when test="$staffdef/@label = 'Bassi [Vc., Cb.]'">
                                <xsl:attribute name="code" select="'BITTE AUFTEILEN!!!'"/>
                            </xsl:when>
                            <xsl:when test="$staffdef/@label = 'Flauti'">
                                <xsl:attribute name="code" select="'wa'"/>
                            </xsl:when>
                            <xsl:when test="$staffdef/@label = 'Flauti e Piccoli'">
                                <xsl:attribute name="code" select="'BITTE AUFTEILEN'"/>
                            </xsl:when>
                            <xsl:when test="$staffdef/@label = 'Flauto'">
                                <xsl:attribute name="code" select="'wa'"/>
                            </xsl:when>
                            <xsl:when test="$staffdef/@label = 'Piccolo'">
                                <xsl:attribute name="code" select="'wa'"/>
                            </xsl:when>
                            <xsl:when test="$staffdef/@label = 'Oboi'">
                                <xsl:attribute name="code" select="'wb'"/>
                            </xsl:when>
                            <xsl:when test="$staffdef/@label = 'Trombe in C'">
                                <xsl:attribute name="code" select="'bb'"/>
                            </xsl:when>
                            <xsl:when test="$staffdef/@label = 'Trombe in D.'">
                                <xsl:attribute name="code" select="'bb'"/>
                            </xsl:when>
                            <xsl:when test="$staffdef/@label = 'Tromba in C (Theater)'">
                                <xsl:attribute name="code" select="'bb'"/>
                            </xsl:when>
                            <xsl:when test="$staffdef/@label = 'Timpani in C, A'">
                                <xsl:attribute name="code" select="'pa'"/>
                            </xsl:when>
                            <xsl:when test="$staffdef/@label = 'Violini'">
                                <xsl:attribute name="code" select="'sa'"/>
                            </xsl:when>
                            <xsl:when test="$staffdef/parent::mei:staffGrp/@label = 'Violini'">
                                <xsl:attribute name="code" select="'sa'"/>
                            </xsl:when>
                            <xsl:when test="$staffdef/@label = 'Violine 2 (Theater)'">
                                <xsl:attribute name="code" select="'sa'"/>
                            </xsl:when>
                            
                            <xsl:when test="$staffdef/@label = 'Agathe'">
                                <xsl:attribute name="code" select="'va'"/>
                                <xsl:attribute name="solo" select="'true'"/>
                            </xsl:when>
                            <xsl:when test="$staffdef/@label = 'Ännchen'">
                                <xsl:attribute name="code" select="'va'"/>
                                <xsl:attribute name="solo" select="'true'"/>
                            </xsl:when>
                            <xsl:when test="$staffdef/@label = 'Aennchen'">
                                <xsl:attribute name="code" select="'va'"/>
                                <xsl:attribute name="solo" select="'true'"/>
                            </xsl:when>
                            <xsl:when test="$staffdef/@label = 'Kilian'">
                                <xsl:attribute name="code" select="'ve'"/>
                                <xsl:attribute name="solo" select="'true'"/>
                            </xsl:when>
                            <xsl:when test="$staffdef/@label = 'Max'">
                                <xsl:attribute name="code" select="'vd'"/>
                                <xsl:attribute name="solo" select="'true'"/>
                            </xsl:when>
                            <xsl:when test="$staffdef/@label = 'Max.'">
                                <xsl:attribute name="code" select="'vd'"/>
                                <xsl:attribute name="solo" select="'true'"/>
                            </xsl:when>
                            <xsl:when test="$staffdef/@label = 'Cuno'">
                                <xsl:attribute name="code" select="'vf'"/>
                                <xsl:attribute name="solo" select="'true'"/>
                            </xsl:when>
                            <xsl:when test="$staffdef/@label = 'Caspar'">
                                <xsl:attribute name="code" select="'vf'"/>
                                <xsl:attribute name="solo" select="'true'"/>
                            </xsl:when>
                            <xsl:when test="$staffdef/@label = 'Casper'">
                                <xsl:attribute name="code" select="'vf'"/>
                                <xsl:attribute name="solo" select="'true'"/>
                            </xsl:when>
                            <xsl:when test="$staffdef/@label = 'Ottokar'">
                                <xsl:attribute name="code" select="'ve'"/>
                                <xsl:attribute name="solo" select="'true'"/>
                            </xsl:when>
                            
                            <xsl:when test="$staffdef/@label = 'Soprani'">
                                <xsl:attribute name="code" select="'va'"/>
                            </xsl:when>
                            <xsl:when test="$staffdef/@label = 'Soprani ed Alti'">
                                <xsl:attribute name="code" select="'BITTE AUFTEILEN'"/>
                            </xsl:when>
                            <xsl:when test="$staffdef/@label = '[Sopran]'">
                                <xsl:attribute name="code" select="'va'"/>
                            </xsl:when>
                            <xsl:when test="$staffdef/@label = '[S.]'">
                                <xsl:attribute name="code" select="'va'"/>
                            </xsl:when>
                            <xsl:when test="$staffdef/@label = 'Sopran (Bauern &amp; Jäger)'">
                                <xsl:attribute name="code" select="'va'"/>
                            </xsl:when>
                            <xsl:when test="$staffdef/@label = 'Alti'">
                                <xsl:attribute name="code" select="'vc'"/>
                            </xsl:when>
                            <xsl:when test="$staffdef/@label = '[Alt]'">
                                <xsl:attribute name="code" select="'vc'"/>
                            </xsl:when>
                            <xsl:when test="$staffdef/@label = '[A.]'">
                                <xsl:attribute name="code" select="'vc'"/>
                            </xsl:when>
                            <xsl:when test="$staffdef/@label = 'Alt (Bauern &amp; Jäger)'">
                                <xsl:attribute name="code" select="'vc'"/>
                            </xsl:when>
                            <xsl:when test="$staffdef/@label = 'Tenori'">
                                <xsl:attribute name="code" select="'vd'"/>
                            </xsl:when>
                            <xsl:when test="$staffdef/@label = 'Tenor (Bauern &amp; Jäger)'">
                                <xsl:attribute name="code" select="'vd'"/>
                            </xsl:when>
                            <xsl:when test="$staffdef/@label = '[Tenor Jäger]'">
                                <xsl:attribute name="code" select="'vd'"/>
                            </xsl:when>
                            <xsl:when test="$staffdef/@label = '[T.]'">
                                <xsl:attribute name="code" select="'vd'"/>
                            </xsl:when>
                            <xsl:when test="$staffdef/@label = '[Tenor u. Kilian]'">
                                <xsl:attribute name="code" select="'BITTE AUFTEILEN'"/>
                            </xsl:when>
                            <xsl:when test="$staffdef/@label = 'Bass (Bauern &amp; Jäger)'">
                                <xsl:attribute name="code" select="'vf'"/>
                            </xsl:when>
                            <xsl:when test="$staffdef/@label = '[Bass Jäger]'">
                                <xsl:attribute name="code" select="'vf'"/>
                            </xsl:when>
                            <xsl:when test="$staffdef/@label = '[B,]'">
                                <xsl:attribute name="code" select="'vf'"/>
                            </xsl:when>
                            
                            <xsl:otherwise>
                                <xsl:attribute name="code"/>
                            </xsl:otherwise>
                        </xsl:choose>
                        <xsl:if test="contains(lower-case($staffdef/@label),'solo')">
                            <xsl:attribute name="solo" select="'true'"/>
                        </xsl:if>
                    </instrVoice>
                </xsl:for-each>
            </instrumentation>
        </perfMedium>
    </xsl:variable>
    
    <xsl:template match="/">
        <xsl:apply-templates/>
    </xsl:template>
    
    <xsl:template match="mei:encodingDesc">
        <xsl:next-match/>
        
        <workDesc xmlns="http://www.music-encoding.org/ns/mei">
            <work>
                <expressionList>
                    <expression label="{$source.id}" xml:id="freidi-work_exp-musicSource_{$source.id}">
                        <componentGrp>
                            <expression label="{$mov.id}" xml:id="freidi-work_exp-musicSource_{$mov.id}">
                                <titleStmt>
                                    <title>
                                        <persName>Ackermann, Otto</persName>
                                        <date isodate="1951-04">April 1951</date>
                                        <geogName>Salzburg</geogName>
                                    </title>
                                    <respStmt>
                                        <corpName role="mus" authority="GND" authURI="http://d-nb.info/gnd/" dbkey="802137-5">Chor der Wiener Staatsoper</corpName>
                                    </respStmt>
                                </titleStmt>
                                <xsl:copy-of select="$perfMedium"/>
                            </expression>
                        </componentGrp>
                    </expression>
                </expressionList>
            </work>
        </workDesc>
        
    </xsl:template>
    
    <xsl:template match="mei:staffDef">
        <xsl:variable name="staff.n" select="@n" as="xs:string"/>
        <xsl:copy>
            <xsl:attribute name="decls" select="'#' || $perfMedium//mei:instrVoice[@n = $staff.n]/@xml:id"/>
            <xsl:apply-templates select="node() | @*"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="node() | @*" mode="#all">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
</xsl:stylesheet>