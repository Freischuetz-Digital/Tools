<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    xmlns:mei="http://www.music-encoding.org/ns/mei"
    xmlns:xlink="http://www.w3.org/1999/xlink"
    exclude-result-prefixes="xs xd mei"
    version="2.0">
    
    <xsl:import href="../global-parameters.xsl"/>
    
    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p><xd:b>Created on:</xd:b> Jun 20, 2013</xd:p>
            <xd:p><xd:b>Author:</xd:b> johannes</xd:p>
            <xd:p><xd:b>Documentation:</xd:b> Benjamin W. Bohl</xd:p>
            <xd:p>This stylesheet generates separate files for all systems (accolades) in the given movement.</xd:p>
            <xd:param name="movement">Integer value to determine the mdiv element in the MEI file being processed. <xd:a docid="param_movements">See parameter description for details.</xd:a></xd:param>
        </xd:desc>
    </xd:doc>
    
    <xd:doc scope="component">
        <xd:desc>
            <xd:p>Declare the output method as indented xml and define a default namespace for XPath.</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:output encoding="UTF-8" method="xml" indent="yes" xpath-default-namespace="http://www.music-encoding.org/ns/mei"/>
    
    <xd:doc scope="component" id="param_movements">
        <xd:desc>
            <xd:p>This parameter holds a sequence of integers for selecting the right mdiv elements from the MEI file being processed.</xd:p>
            <xd:p>Please enter manually as supplying the values externally hasn't been tested successfully.</xd:p>
        </xd:desc>
    </xd:doc>
    <!-- e.g. <xsl:param name="movements" select="(0,4,5,6,7,8,9,12)" as="xs:integer*"/>  -->
    <xsl:param name="movement" select="8" as="xs:integer"/>
    <xsl:param name="destdir"/>
    
    <xsl:variable name="header" select="//mei:meiHead"/>
    <xsl:variable name="body" select="//mei:body"/>
    
    <xsl:variable name="siglum" select="//mei:mei/@xml:id"/>
    <xsl:variable name="movementID" select="concat($siglum,'_mov', $movement)" as="xs:string"/>
    
    
    <xd:doc scope="component">
        <xd:desc>
            <xd:p>The root templates logs an XSL-message 'looking for movements:</xd:p></xd:desc>
    </xd:doc>
    <xsl:template match="/">
        
        <xsl:message select="concat('looking for movements: ',$movementID)"/>
        
        <xsl:apply-templates/>    
    </xsl:template>
    
    <xsl:template match="mei:mdiv[@xml:id = $movementID]">
        <xsl:variable name="movID" select="@xml:id"/>
        <xsl:variable name="mov" select="."/>
        
        <xsl:choose>
            <xsl:when test="not(.//mei:note)">
                <xsl:message select="concat('Movement ',$movID,' does not contain music yet. Processing skipped.')"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="measureZoneIDs" select=".//mei:measure/@facs/substring(.,2)"/>
                <!--<xsl:variable name="measureZones"/>-->
                
                <xsl:variable name="measureIDs" select=".//mei:measure/@xml:id" as="xs:string*"/>
                    
                <xsl:variable name="pages" select="//mei:surface[.//mei:zone[@type = 'measure']/@data/substring(.,2) = $measureIDs]"/>
                
                <xsl:for-each select="$pages">
                    <xsl:variable name="page" select="."/>
                    
                    <xsl:variable name="pageHeight" select="number($page/mei:graphic/@height)"/>
                    <xsl:variable name="avgMeasureHeight" select="avg($page/mei:zone[@type='measure']/(number(@lry) - number(@uly)))"/>
                    
                    <xsl:variable name="ratio" select="$avgMeasureHeight div $pageHeight"/>
                    
                    <xsl:variable name="measureGroups">
                        <xsl:choose>
                            <xsl:when test="$ratio gt 0.5">
                                <group>
                                    <xsl:sequence select=".//mei:zone[@type='measure']"/>
                                </group>    
                            </xsl:when>
                            <xsl:when test="$ratio gt 0.33">
                                <group>
                                    <xsl:sequence select=".//mei:zone[@type='measure' and number(@uly) lt ($pageHeight * 0.3)]"/>
                                </group>
                                <group>
                                    <xsl:sequence select=".//mei:zone[@type='measure' and number(@uly) gt ($pageHeight * 0.3)]"/>
                                </group>
                            </xsl:when>
                            <xsl:when test="$ratio gt 0.25">
                                <group>
                                    <xsl:sequence select=".//mei:zone[@type='measure' and number(@uly) lt ($pageHeight * 0.5) and number(@lry) lt ($pageHeight * 0.5)]"/>
                                </group>
                                <group>
                                    <xsl:sequence select=".//mei:zone[@type='measure' and number(@uly) lt ($pageHeight * 0.5) and number(@lry) gt ($pageHeight * 0.5)]"/>
                                </group>
                                <group>
                                    <xsl:sequence select=".//mei:zone[@type='measure' and number(@uly) gt ($pageHeight * 0.5) and number(@lry) gt ($pageHeight * 0.5)]"/>
                                </group>
                            </xsl:when>
                        </xsl:choose>
                    </xsl:variable>
                    
                    <xsl:for-each select="$measureGroups/group[mei:zone]">
                        
                        <xsl:variable name="suffix" as="xs:string">
                            <xsl:choose>
                                <xsl:when test="count($measureGroups/group) gt 1">
                                    <xsl:value-of select="concat('_sys',position())"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="''"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:variable>
                        
                        <xsl:variable name="systemmeasureIDs" select="mei:zone/@data/substring(.,2)" as="xs:string*"/>
                        <xsl:variable name="score">
                            <xsl:apply-templates select="$mov//mei:score" mode="getSections">
                                <xsl:with-param name="systemmeasureIDs" select="$systemmeasureIDs" tunnel="yes"/>
                            </xsl:apply-templates>
                        </xsl:variable>
                        
                        <xsl:variable name="providedScoreDef">
                            <!-- nur dann, wenn die Seite nicht mit einem scoreDef anfängt (egal, was tatsächlich im scoreDef steht) -->
                            <!--<xsl:if test="not($score//mei:score/mei:*[1][local-name() eq 'scoreDef'])">-->
                            
                            <!-- immer, nur nicht auf der ersten Seite -->
                            <xsl:if test="not(($score//mei:measure)[1]/@xml:id = ($mov//mei:measure)[1]/@xml:id)">
                                
                                <xsl:element name="annot" namespace="http://www.music-encoding.org/ns/mei">
                                    <xsl:attribute name="type" select="'providedScoreDef'"/>
                                    <xsl:element name="supplied" namespace="http://www.music-encoding.org/ns/mei">
                                        <xsl:element name="section" namespace="http://www.music-encoding.org/ns/mei">
                                           <!--<xsl:copy-of select="$newScoreDef"/>-->
                                            
                                            <xsl:apply-templates select="($mov//mei:score/mei:scoreDef)[1]" mode="getDefaultScoreDef">
                                                <xsl:with-param name="mov" select="$mov" as="node()" tunnel="yes"/>
                                                <xsl:with-param name="firstMeasureID" select="$systemmeasureIDs[1]" tunnel="yes"/>
                                            </xsl:apply-templates>
                                        </xsl:element>
                                    </xsl:element>
                                </xsl:element>
                            </xsl:if>
                        </xsl:variable>
                        <xsl:variable name="continuedSection">
                            <xsl:if test="$score//mei:section[@type = 'freidi:continuedSection']">
                                <xsl:element name="annot" namespace="http://www.music-encoding.org/ns/mei">
                                    <xsl:attribute name="type" select="'sectionContinued'"/>
                                    <xsl:element name="p" namespace="http://www.music-encoding.org/ns/mei">
                                        The first section in this file is a continuation of the section on the preceding page. When 
                                        combining the pages to a complete encoding, it has to be merged with the previous page's section.
                                    </xsl:element>
                                </xsl:element>
                            </xsl:if>
                        </xsl:variable>
                        
                        <xsl:variable name="pageN">
                            <xsl:choose>
                                <xsl:when test="string-length($page/@n) = 1">
                                    <xsl:value-of select="concat('00',$page/@n)"/>
                                </xsl:when>
                                <xsl:when test="string-length($page/@n) = 2">
                                    <xsl:value-of select="concat('0',$page/@n)"/>
                                </xsl:when>
                                <xsl:when test="string-length($page/@n) = 3">
                                    <xsl:value-of select="$page/@n"/>
                                </xsl:when>
                            </xsl:choose>
                        </xsl:variable>
                        
                        <xsl:result-document href="{concat($destdir, '/', $siglum,'/',$movID,'/',$siglum,'_page',$pageN,$suffix,'.xml')}" indent="yes" method="xml">
                            <xsl:processing-instruction name="xml-model">href="../../../../../schemata/rng/freidi-schema-musicSource.rng" type="application/xml" schematypens="http://relaxng.org/ns/structure/1.0"</xsl:processing-instruction>
                            <xsl:processing-instruction name="xml-model">href="../../../../../schemata/rng/freidi-schema-musicSource.rng" type="application/xml" schematypens="http://purl.oclc.org/dsdl/schematron"</xsl:processing-instruction>
                            <xsl:element name="mei" namespace="http://www.music-encoding.org/ns/mei">
                                <xsl:namespace name="xlink" select="'http://www.w3.org/1999/xlink'"/>
                                <xsl:attribute name="xml:id" select="concat($siglum,'_page',$page/@n,$suffix)"/>
                                <xsl:attribute name="meiversion" select="'2013'"/>
                                <xsl:element name="meiHead" namespace="http://www.music-encoding.org/ns/mei">
                                    <xsl:element name="fileDesc" namespace="http://www.music-encoding.org/ns/mei">
                                        <xsl:copy-of select="$header//mei:fileDesc/mei:titleStmt"/>
                                        <xsl:copy-of select="$header//mei:fileDesc/mei:pubStmt"/>
                                        <xsl:if test="$providedScoreDef/mei:annot or $continuedSection/mei:annot">
                                        <xsl:element name="notesStmt" namespace="http://www.music-encoding.org/ns/mei">
                                            <xsl:copy-of select="$providedScoreDef"/>
                                            <xsl:copy-of select="$continuedSection"/>
                                        </xsl:element>
                                        </xsl:if>
                                        <xsl:copy-of select="$header//mei:fileDesc/mei:sourceStmt"/>
                                    </xsl:element>
                                    <xsl:element name="encodingDesc" namespace="http://www.music-encoding.org/ns/mei">
                                        <xsl:element name="appInfo" namespace="http://www.music-encoding.org/ns/mei">
                                            <xsl:copy-of select="$header//mei:application"/>
                                            <xsl:element name="application" namespace="http://www.music-encoding.org/ns/mei">
                                                <xsl:attribute name="xml:id" select="'generateSystemFiles.xsl'"/>
                                                <xsl:element name="name" namespace="http://www.music-encoding.org/ns/mei">generateSystemFiles.xsl</xsl:element>
                                                <xsl:element name="ptr" namespace="http://www.music-encoding.org/ns/mei">
                                                    <xsl:attribute name="target" select="'../xslt/generateSystemFiles.xsl'"/>
                                                </xsl:element>
                                            </xsl:element>
                                        </xsl:element>
                                    </xsl:element>
                                    <xsl:element name="revisionDesc" namespace="http://www.music-encoding.org/ns/mei">
                                        <xsl:copy-of select="$header//mei:change"/>
                                        <xsl:element name="change" namespace="http://www.music-encoding.org/ns/mei">
                                            <xsl:attribute name="n" select="count(($header//mei:change)) + 1"/>
                                            <xsl:element name="respStmt" namespace="http://www.music-encoding.org/ns/mei">
                                                <xsl:element name="persName" namespace="http://www.music-encoding.org/ns/mei">
                                                  <xsl:value-of select="$transformationOperator"/>
                                                </xsl:element>
                                            </xsl:element>
                                            <xsl:element name="changeDesc" namespace="http://www.music-encoding.org/ns/mei">
                                                <xsl:element name="p" namespace="http://www.music-encoding.org/ns/mei">
                                                    File extracted from <xsl:value-of select="$siglum"/>_merged.xml, using <xsl:element name="ref" namespace="http://www.music-encoding.org/ns/mei">
                                                      <xsl:attribute name="target" select="concat('https://github.com/Freischuetz-Digital/Tools/blob/',$FreiDi-Tools_version,'/08%20Split%20in%20pages/generateSystemFiles.xsl')"/>
                                                      <xsl:text>generateSystemFiles.xsl</xsl:text></xsl:element> from Freischütz Digital Tools <xsl:value-of select="$FreiDi-Tools_version"/>.
                                                </xsl:element>
                                            </xsl:element>
                                            <xsl:element name="date" namespace="http://www.music-encoding.org/ns/mei">
                                                <xsl:attribute name="isodate" select="substring(string(current-date()),1,10)"/>
                                            </xsl:element>
                                        </xsl:element>
                                    </xsl:element>
                                    
                                </xsl:element>
                                <xsl:element name="music" namespace="http://www.music-encoding.org/ns/mei">
                                    <xsl:element name="facsimile" namespace="http://www.music-encoding.org/ns/mei">
                                        <xsl:element name="surface" namespace="http://www.music-encoding.org/ns/mei">
                                            <xsl:copy-of select="$page/@* | $page/mei:graphic | $page/mei:zone"/>
                                        </xsl:element>
                                    </xsl:element>
                                    <xsl:element name="body" namespace="http://www.music-encoding.org/ns/mei">
                                        <xsl:element name="mdiv" namespace="http://www.music-encoding.org/ns/mei">
                                            <xsl:attribute name="xml:id" select="$movID"/>
                                            <xsl:attribute name="label" select="$mov/@label"/>
                                            <xsl:copy-of select="$score"/>
                                        </xsl:element>
                                    </xsl:element>
                                </xsl:element>
                            </xsl:element>
                            
                        </xsl:result-document>
                        
                    </xsl:for-each>
                    
                    
                </xsl:for-each>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- mode getSections -->
    
    <xsl:template match="mei:section" mode="getSections">
        <xsl:param name="systemmeasureIDs" tunnel="yes"/>
        
        <xsl:if test="some $measureID in .//mei:measure/@xml:id satisfies ($measureID = $systemmeasureIDs)">
            <xsl:variable name="firstMeasure" select=".//mei:measure[@xml:id = $systemmeasureIDs][1]"/>
            
            <xsl:copy>
                <xsl:if test="$firstMeasure/preceding-sibling::mei:measure">
                    <xsl:attribute name="type" select="'freidi:continuedSection'"/>
                </xsl:if>
                <xsl:apply-templates select="node()" mode="getSections"/>
            </xsl:copy>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="mei:measure" mode="getSections">
        <xsl:param name="systemmeasureIDs" tunnel="yes"/>
        <xsl:if test="@xml:id = $systemmeasureIDs">
            <xsl:copy>
                <xsl:apply-templates select="node() | @*" mode="getSections"/>
            </xsl:copy>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="mei:scoreDef | mei:staffDef | mei:pb | mei:sb" mode="getSections">
        <xsl:param name="systemmeasureIDs" tunnel="yes"/>
        <xsl:variable name="beforeLast" select="exists(following::mei:measure[@xml:id = $systemmeasureIDs])" as="xs:boolean"/>
        <xsl:variable name="afterFirst" select="exists(preceding::mei:measure[@xml:id = $systemmeasureIDs])" as="xs:boolean"/>
        <xsl:variable name="isBegin" select="following::mei:measure[1]/@xml:id = $systemmeasureIDs[1]" as="xs:boolean"/>
        
        <xsl:if test="$isBegin or ($beforeLast and $afterFirst)">
            <xsl:copy>
                <xsl:apply-templates select="node() | @*" mode="getSections"/>
            </xsl:copy>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="node() | @*" mode="getSections">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*" mode="getSections"/>
        </xsl:copy>
    </xsl:template>
    
    <!-- mode getDefaultScoreDef -->
    
    <xsl:template match="mei:scoreDef" mode="getDefaultScoreDef">
        <xsl:param name="mov" tunnel="yes"/>
        <xsl:param name="firstMeasureID" tunnel="yes"/>
        
        <xsl:variable name="firstMeasure" select="$mov/id($firstMeasureID)"/>
        
        <xsl:message select="concat('looking for providedScoreDef on page starting with measure ',$firstMeasureID)"/>
        
        <!--<xsl:variable name="precedingMeter" select="($firstMeasure/preceding::mei:scoreDef[@meter.count and @meter.unit])[1]" as="node()?"/>
        <xsl:variable name="precedingKey" select="($firstMeasure/preceding::mei:scoreDef[@key.sig])[1]" as="node()?"/>-->
        
        <!--<xsl:variable name="precedingMeter" select="$mov//following::mei:scoreDef[./following::mei:measure[@xml:id = $firstMeasureID] and @meter.count and @meter.unit][last()]" as="node()?"/>
        <xsl:variable name="precedingKey" select="$mov//following::mei:scoreDef[./following::mei:measure[@xml:id = $firstMeasureID] and @key.sig][last()]" as="node()?"/>
        -->
        
        <xsl:variable name="precedingMeter" select="($mov//mei:section/mei:scoreDef[./following::mei:measure[@xml:id = $firstMeasureID] and @meter.count and @meter.unit])[last()]" as="node()?"/>
        <xsl:variable name="precedingKey" select="($mov//mei:section/mei:scoreDef[./following::mei:measure[@xml:id = $firstMeasureID] and @key.sig])[last()]" as="node()?"/>
        
        
        <xsl:if test="exists($precedingMeter) or exists($precedingKey)">
            <xsl:message select="concat('found preceding ',if(exists($precedingMeter))then(concat('meter(',$precedingMeter/following::mei:measure[1]/@xml:id,') ')) else(''),if(exists($precedingKey))then('key ')else(''))"/>    
        </xsl:if>
        
        <xsl:copy>
            <xsl:apply-templates select="@*" mode="getDefaultScoreDef"/>
            <xsl:if test="exists($precedingMeter)">
                <xsl:copy-of select="$precedingMeter/(@meter.count | @meter.unit | @meter.sym)"/>    
            </xsl:if>
            <xsl:if test="exists($precedingKey)">
                <xsl:copy-of select="$precedingKey/(@key.sig | @key.mode | @key.sig.show)"/>    
            </xsl:if>    
            
            <xsl:apply-templates select="child::mei:*" mode="getDefaultScoreDef"/>    
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="mei:staffDef" mode="getDefaultScoreDef">
        <xsl:param name="mov" tunnel="yes"/>
        <xsl:param name="firstMeasureID" tunnel="yes"/>
        
        <xsl:variable name="firstMeasure" select="$mov/id($firstMeasureID)"/>
        <xsl:variable name="n" select="@n"/>
        <xsl:variable name="defaultStaffDef" select="."/>
        
        <!--<xsl:variable name="precedingClef" select="$firstMeasure/preceding::mei:*[(local-name() = 'staffDef' and @n = $n and @clef.line and @clef.shape) or 
            (local-name() = 'clef' and ancestor::mei:staff/@n = $n and @line and @shape)][1]"/>
        <xsl:variable name="precedingKey" select="$firstMeasure/preceding::mei:staffDef[@n = $n and @key.sig][1]"/>
        <xsl:variable name="precedingMeter" select="$firstMeasure/preceding::mei:staffDef[@n = $n and @meter.count and @meter.unit][1]"/>-->
        
        
        <xsl:variable name="precedingClef" select="($mov//mei:section//(mei:staffDef | mei:clef)[./following::mei:measure[@xml:id = $firstMeasureID] and ((local-name() = 'staffDef' and @n = $n and @clef.line and @clef.shape) or 
            (local-name() = 'clef' and ancestor::mei:staff/@n = $n and @line and @shape))])[last()]" as="node()?"/>
        
        <xsl:variable name="precedingKey" select="($mov//mei:section//mei:staffDef[./following::mei:measure[@xml:id = $firstMeasureID] and @n = $n and @key.sig])[last()]" as="node()?"/>
        
        <xsl:variable name="precedingMeter" select="($mov//mei:section//mei:staffDef[./following::mei:measure[@xml:id = $firstMeasureID] and @n = $n and @meter.count and @meter.unit])[last()]" as="node()?"/>
        
        <xsl:if test="exists($precedingClef) or exists($precedingKey) or exists($precedingMeter)">
            <xsl:message select="concat('found ',if(exists($precedingClef))then('clef ')else(''),if(exists($precedingMeter))then('meter ')else(''),if(exists($precedingKey))then('key ')else(''), 'on staff ',$n)"/>
        </xsl:if>
        
        <xsl:copy>
            <xsl:apply-templates select="@* except(@clef.line,@clef.shape,@key.sig,@key.mode,@meter.count,@meter.unit,@meter.sym)" mode="getDefaultScoreDef"/> <!-- bwb warum except lines @lines,-->
            <xsl:choose>
                <xsl:when test="exists($precedingClef)">
                    <xsl:apply-templates select="$precedingClef/(@clef.line | @clef.shape | @line | @shape)" mode="getDefaultScoreDef"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates select="$defaultStaffDef/(@clef.line | @clef.shape)" mode="getDefaultScoreDef"/>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:choose>
                <xsl:when test="exists($precedingKey)">
                    <xsl:apply-templates select="$precedingKey/(@key.sig | @key.mode)" mode="getDefaultScoreDef"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates select="$defaultStaffDef/(@key.sig | @key.mode)" mode="getDefaultScoreDef"/>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:choose>
                <xsl:when test="exists($precedingMeter)">
                    <xsl:copy-of select="$precedingMeter/(@meter.count | @meter.unit | @meter.sym)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:copy-of select="$defaultStaffDef/(@meter.count | @meter.unit | @meter.sym)"/>
                </xsl:otherwise>
            </xsl:choose>
            
            <xsl:apply-templates select="child::mei:*" mode="getDefaultScoreDef"/>    
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="@line" mode="getDefaultScoreDef">
        <xsl:attribute name="clef.line" select="."/>
    </xsl:template>
    
    <xsl:template match="@shape" mode="getDefaultScoreDef">
        <xsl:attribute name="clef.shape" select="."/>
    </xsl:template>
    
    <xsl:template match="node() | @*" mode="getDefaultScoreDef">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*" mode="getDefaultScoreDef"/>
        </xsl:copy>
    </xsl:template>
    
    <!-- build new default scoredef -->
    
    <xsl:template name="buildNewScoreDef">
        <xsl:param name="precedingScoreDefs">
            
        </xsl:param>
        <scoreDef xmlns="http://www.music-encoding.org/ns/mei">
            <xsl:for-each select="$precedingScoreDefs">
                <xsl:copy-of select="./@*"/>
            </xsl:for-each>
            <staffGrp>
                <xsl:for-each select="$precedingScoreDefs">
                    <xsl:copy-of select="./mei:staffGrp/@*"/>
                </xsl:for-each>
                
                <xsl:for-each select="$precedingScoreDefs[1]//mei:staffDef/@n">
                    <xsl:variable name="n" select="."/>
                    <staffDef>
                        <xsl:for-each select="$precedingScoreDefs">
                            <xsl:copy-of select=".//mei:staffDef[@n = $n]/@*"/>
                        </xsl:for-each>
                    </staffDef>
                </xsl:for-each>
            </staffGrp>
        </scoreDef>
        
        
    </xsl:template>
    
    
    <!-- default copy template -->
    
    <xsl:template match="node() | @*">
        <xsl:apply-templates select="node() | @*"/>
    </xsl:template>
    
</xsl:stylesheet>