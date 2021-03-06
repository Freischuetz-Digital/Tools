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
            <xd:p>There are three modes specified in param $mode: "events", "controlEvents", "full", which resolve the corresponding things…</xd:p>
            <xd:p>
                TODO: 
                * beatRpt
                (* mRpt2)
                (* multiRpt)
                * mSpaces as mRpt
            </xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:output method="xml" indent="yes"/>
    
    <xsl:param name="mode" select="'events'" as="xs:string"/>
        
    <xsl:variable name="xsl.version" select="'1.0.0'"/>
    <xsl:variable name="docPath" select="document-uri(/)"/>
    <xsl:variable name="cpMarksPath" select="substring-before($docPath,'/musicSources/') || '/musicSources/sourcePrep/11.1%20ShortcutList/cpMarks.xml'" as="xs:string"/>
    <xsl:variable name="cpMarks" select="doc($cpMarksPath)//mei:cpMark" as="node()*"/>
    <xsl:variable name="sourcePath.events" select="substring-after($docPath,'sourcePrep/10%20concatenated%20Pages/')" as="xs:string"/>
    <xsl:variable name="resultFile.events" select="substring-before($docPath,'sourcePrep/10') || 'sourcePrep/11%20resolvedShortCuts%20events/' || $sourcePath.events" as="xs:string"/>
    
    <xsl:variable name="sourcePath.controlEvents" select="substring-after($docPath,'sourcePrep/12%20proven%20ControlEvents/')" as="xs:string"/>
    <xsl:variable name="resultFile.controlEvents" select="substring-before($docPath,'sourcePrep/12') || 'sourcePrep/13%20resolvedShortCuts%20controlEvents/' || $sourcePath.controlEvents" as="xs:string"/>
    
    <xsl:variable name="originalFile" select="/" as="node()"/>
    <xsl:variable name="music" select=".//mei:music" as="node()"/>
    
    <xsl:template match="/">
        
        <xsl:variable name="included.cpMarks">
            <xsl:apply-templates mode="include.cpMarks"/>
        </xsl:variable>
        <xsl:variable name="resolvedTrems">
            <xsl:apply-templates select="$included.cpMarks" mode="resolveTrems"/>
            <xsl:message select="'resolved tremolos'"/>
        </xsl:variable>
        <xsl:variable name="resolvedRpts">
            <xsl:apply-templates mode="resolveRpts" select="$resolvedTrems"/>
            <xsl:message select="'resolved repeats'"/>
        </xsl:variable>
        <xsl:variable name="cpInstructions">
            <xsl:apply-templates select="$resolvedRpts//mei:cpMark" mode="prepare.cpMarks"/>
        </xsl:variable>
        
        <xsl:variable name="cpMarks.enhanced" select="$resolvedRpts//mei:cpMark"/>
        
        <!--<xsl:variable name="cpInstructions.all" select="distinct-values($cpInstructions//copy[not(@sourceStaff.id = $cpInstructions//copy/@targetStaff.id)]/@cpMark.id)"/>
        <xsl:variable name="cpInstructions.second" select="distinct-values($cpInstructions//copy[@sourceStaff.id = $cpInstructions//copy/@targetStaff.id]/@cpMark.id)"/>
        <xsl:variable name="cpInstructions.first" select="$cpInstructions.all[not(. = $cpInstructions.second)]"/>-->
        
        <xsl:variable name="cpInstructions.all" select="distinct-values($cpInstructions//copy/@cpMark.id)"/>
        <xsl:variable name="cpInstructions.second" select="distinct-values($cpInstructions//copy[@sourceStaff.id = distinct-values((preceding-sibling::copy/@targetStaff.id,following-sibling::copy/@targetStaff.id))]/@cpMark.id)" as="xs:string*"/>
        <xsl:variable name="cpInstructions.first" select="distinct-values($cpInstructions.all[not(. = $cpInstructions.second)])"/>
        
        <!--<xsl:message select="'cpMarks.enhanced: ' || count($cpMarks.enhanced)"/>
        <xsl:message select="$cpInstructions.second"/>
        <xsl:message select="'staves: ' || string-join(for $i in $cpInstructions.second return $cpMarks.enhanced[@xml:id = $i]/concat(@freidi.measure,'_s',@staff,', (',@tstamp2,')'),', ')"></xsl:message>        
        <xsl:message select="'cpInstructions.all: ' || count($cpInstructions.all)"/>
        <xsl:message select="'cpInstructions.second: ' || count($cpInstructions.second)"/>
        <xsl:message select="'cpInstructions.first: ' || count($cpInstructions.first)"/>-->
        
        
        <!-- Test if everything is correct about the workflow -->
        <xsl:if test="not($mode = ('events','controlEvents','full'))">
            <xsl:message terminate="yes" select="'$mode=' || $mode || ' unsupported. Please use mode _events_, _controlEvents_ or _full_ instead.'"/>
        </xsl:if>
        <xsl:if test="$mode = 'events' and not(contains($docPath,'/sourcePrep/10'))">
            <xsl:message terminate="yes" select="'$mode=events requires the file to be stored in 10 concatenated Pages.'"/>
        </xsl:if>
        <xsl:if test="$mode = 'controlEvents' and not(contains($docPath,'/sourcePrep/12%20Proven'))">
            <xsl:message terminate="yes" select="'$mode=controlEvents requires the file to be stored in 12 Proven ControlEvents.'"/>
        </xsl:if>
        <xsl:if test="$mode = 'full'">
            <xsl:message terminate="yes" select="'$mode=full is not supported in the FreiDi workflow.'"/>
        </xsl:if>
        <xsl:if test="not(doc-available($cpMarksPath))">
            <xsl:message terminate="yes" select="'cpMarks.xml is missing from the expected location at ' || $cpMarksPath || '. Processing stopped.'"/>
        </xsl:if>
        
        <xsl:if test="$mode = 'controlEvents' and not(.//mei:change//mei:ptr[starts-with(@target,'resolveShortCuts.xsl_v')])">
            <xsl:message terminate="yes" select="'$mode=controlEvents requires that the $mode=events has been run on this file already.'"/>
        </xsl:if>
        
        <xsl:if test="$cpMarks.enhanced//@ref.startid">
            <xsl:message terminate="yes" select="'cpMarks with @ref.startid are not supported yet. Please update resolveShortCuts.xsl.'"/>
        </xsl:if>
        <xsl:if test="$music//mei:beatRpt">
            <xsl:message terminate="yes" select="'beatRpts should be working, but havent been tested yet. Please check, and if everything works as expected, remove terminate=yes in this xsl!'"/>
        </xsl:if>
        
        <xsl:message select="'total cpMarks: ' || count($cpMarks.enhanced) || ', first run: ' || count($cpInstructions.first) || ', second run: ' || count($cpInstructions.second)"/>
        
        <!-- resolve all cpMarks that point to a staff which contains direct content only -->
        
        <xsl:variable name="resolvedMarks">
            <xsl:apply-templates mode="resolveMarks" select="$resolvedRpts">
                <xsl:with-param name="run" select="1" as="xs:integer" tunnel="yes"/>
                <xsl:with-param name="material" select="$resolvedRpts//mei:music" as="node()" tunnel="yes"/>
                <xsl:with-param name="cpInstructions" select="$cpInstructions" tunnel="yes"/>
                <xsl:with-param name="cpMarks.enhanced" select="$cpMarks.enhanced" tunnel="yes"/>
                <xsl:with-param name="cpMark.ids" select="$cpInstructions.first" as="xs:string*" tunnel="yes"/>
            </xsl:apply-templates>
            <xsl:message select="'resolved first round of cpMarks'"/>
            
        </xsl:variable>
        
        <!--<xsl:message select="'cpMark.ids for first run (' || count($cpInstructions.first) || '): ' || string-join($cpInstructions.first,', ')"/>-->
        
        <!-- resolve all cpMarks which refer to staves also containing cpMarks -->
        
        <xsl:variable name="resolvedAllMarks">
            <xsl:apply-templates mode="resolveMarks" select="$resolvedMarks">
                <xsl:with-param name="run" select="2" as="xs:integer" tunnel="yes"/>
                <xsl:with-param name="material" select="$resolvedMarks//mei:music" as="node()" tunnel="yes"/>
                <xsl:with-param name="cpInstructions" select="$cpInstructions" tunnel="yes"/>
                <xsl:with-param name="cpMarks.enhanced" select="$cpMarks.enhanced" tunnel="yes"/>
                <xsl:with-param name="cpMark.ids" select="$cpInstructions.second" as="xs:string*" tunnel="yes"/>
            </xsl:apply-templates>
            <xsl:message select="'resolved second round of cpMarks'"/>
        </xsl:variable>
        
        <!--<xsl:message select="'cpMark.ids for second run (' || count($cpInstructions.second) || '): ' || string-join($cpInstructions.second,', ')"/>-->
        
        <xsl:result-document href="{$resultFile.events}">
          <xsl:processing-instruction name="xml-model">href="../../../../schemata/rng/freidi-schema-musicSource_pmdCoCo.rng" type="application/xml" schematypens="http://relaxng.org/ns/structure/1.0"</xsl:processing-instruction>
          <xsl:processing-instruction name="xml-model">href="../../../../schemata/rng/freidi-schema-musicSource_pmdCoCo.rng" type="application/xml" schematypens="http://purl.oclc.org/dsdl/schematron"</xsl:processing-instruction>
            <xsl:apply-templates select="$resolvedAllMarks" mode="cleanup"/>  
            <xsl:message select="'cleaned file and saving'"/>
        </xsl:result-document>
        
        <!--<xsl:copy-of select="$cpInstructions"/>-->
    </xsl:template>
  
    <xsl:template match="processing-instruction('xml-model')" mode="cleanup"/>
    
    <xsl:template match="mei:appInfo" mode="include.cpMarks">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*" mode="#current"/>
            <xsl:if test="not(mei:application[@xml:id = ('resolveShortCuts.xsl_v' || $xsl.version)])">
                <application xmlns="http://www.music-encoding.org/ns/mei">
                    <xsl:attribute name="xml:id" select="'resolveShortCuts.xsl_v' || $xsl.version"/>
                    <xsl:attribute name="version" select="$xsl.version"/>
                    <name>resolveShortCuts.xsl</name>
                    <ptr target="https://github.com/Freischuetz-Digital/Tools/blob/develop/12.1%20resolve%20ShortCuts/resolveShortCuts.xsl"/>
                </application>
            </xsl:if>            
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="mei:revisionDesc" mode="include.cpMarks">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*" mode="#current"/>
            <change xmlns="http://www.music-encoding.org/ns/mei">
                <xsl:attribute name="n" select="count(./mei:change) + 1"/>
                <respStmt>
                    <persName>Johannes Kepper</persName>
                </respStmt>
                <xsl:choose>
                    <xsl:when test="$mode = 'events'">
                        <changeDesc>
                            <p>
                                Resolved colla parte and copy instructions for events by using information from <xsl:value-of select="$cpMarksPath"/>
                                using <ptr target="resolveShortCuts.xsl_v{$xsl.version}"/>. Also resolved all mRpt, bTrems
                                and fTrems.
                            </p>
                        </changeDesc>        
                    </xsl:when>
                    <xsl:when test="$mode = 'controlEvents'">
                        <changeDesc>
                            <p>
                                Resolved abbreviated controlEvents according to <xsl:value-of select="$cpMarksPath"/>
                                using <ptr target="resolveShortCuts.xsl_v{$xsl.version}"/>. Events such as notes are expected to be resolved already.
                            </p>
                        </changeDesc>
                    </xsl:when>
                    <xsl:when test="$mode = 'full'">
                        <changeDesc>
                            <p>
                                Resolved shortcuts (for <xsl:value-of select="$mode"/> only) by using information from <xsl:value-of select="$cpMarksPath"/>
                                using <ptr target="resolveShortCuts.xsl_v{$xsl.version}"/>. Also resolved all mRpt, bTrems
                                and fTrems.
                            </p>
                        </changeDesc>
                    </xsl:when>
                </xsl:choose>
                <date isodate="{substring(string(current-date()),1,10)}"/>
            </change>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="mei:*[@tstamp and not(@grace) and ancestor::mei:layer]" mode="include.cpMarks">
        <xsl:variable name="elem.id" select="@xml:id" as="xs:string"/>
        <xsl:variable name="layer" select="ancestor::mei:layer" as="node()"/>
        <xsl:variable name="graces" select="$layer//mei:note[@grace and (following::mei:*[@tstamp and not(@grace)])[1]/@xml:id = $elem.id]" as="node()*"/>
        
        <xsl:copy>
            <xsl:if test="count($graces) gt 0">
                <!--<xsl:message select="'found graces in ' || ancestor::mei:staff/@xml:id"/>-->
                <xsl:attribute name="stayWithMe" select="string-join($graces/concat('#',@xml:id),' ')"/>
            </xsl:if>
            <xsl:apply-templates select="node() | @*" mode="#current"/>
        </xsl:copy>
        
    </xsl:template>
    
    <!-- including cpMarks -->
    <xsl:template match="mei:measure" mode="include.cpMarks">
        <xsl:variable name="measure.id" select="@xml:id"/>
        <xsl:copy>
            <xsl:attribute name="meter.count" select="preceding::mei:scoreDef[@meter.count and not(ancestor::mei:supplied)][1]/@meter.count"/>
            <xsl:apply-templates select="node() | @*" mode="#current"/>
            <xsl:apply-templates select="$cpMarks[@freidi.measure = $measure.id]" mode="include.cpMarks"/>
            <!--<xsl:message select="'cpMarks for measure ' || $measure.id || ': ' || count($cpMarks[@freidi.measure = $measure.id])"/>-->
        </xsl:copy>
    </xsl:template>
    
    <!-- todo: is this correct? -->
    <xsl:template match="mei:cpMark" mode="include.cpMarks">
        <xsl:choose>
            <xsl:when test="$mode = ('events','full')">
                <xsl:copy>
                    <xsl:attribute name="xml:id" select="'x' || uuid:randomUUID()"/>
                    <xsl:apply-templates select="node() | @*" mode="#current"/>
                </xsl:copy>
            </xsl:when>
            <xsl:otherwise>
                <!-- cpMarks are only copied into the file in modes "events" and "full". -->
            </xsl:otherwise>
        </xsl:choose>
        
    </xsl:template>
    
    <xsl:template match="@freidi.measure" mode="cleanup"/>
    
    <!-- resolving bTrems that aren't resolved already -->
    <xsl:template match="mei:bTrem[not(parent::mei:orig)]" mode="resolveTrems">
        <choice xmlns="http://www.music-encoding.org/ns/mei" xml:id="c{uuid:randomUUID()}">
            <orig>
                <xsl:copy>
                    <xsl:apply-templates select="node() | @*" mode="#current"/>
                </xsl:copy>
            </orig>
            <reg>
                <xsl:variable name="elem" select="child::mei:*" as="node()"/>
                <xsl:variable name="dur" select="1 div number($elem/@dur)" as="xs:double"/>
                <xsl:variable name="dots" select="if($elem/@dots) then(number($elem/@dots)) else(0)" as="xs:double"/>
                <xsl:variable name="totalDur" select="(2 * $dur) - ($dur div math:pow(2,$dots))" as="xs:double"/>
                
                <xsl:if test="not($elem/@stem.mod)">
                    <xsl:message terminate="yes" select="'problem: child of bTrem ' || @xml:id || ' has no @stem.mod. '"/>
                </xsl:if>
                
                <xsl:variable name="stem.mod.total" as="xs:integer">
                    <xsl:choose>
                        <xsl:when test="not(ancestor::mei:beam)">
                            <xsl:value-of select="number(substring($elem/@stem.mod,1,1))"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="number(substring($elem/@stem.mod,1,1)) + 1"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                
                <xsl:if test="not(number(($totalDur div ((1 div 8) div $stem.mod.total))) = ($totalDur div ((1 div 8) div $stem.mod.total)))">
                    <xsl:message select="'problem located at ' || @xml:id"/>
                </xsl:if>
                
                <xsl:variable name="count" select="($totalDur div ((1 div 8) div $stem.mod.total)) cast as xs:integer" as="xs:integer"/>
                <!--<xsl:variable name="count" select="4" as="xs:integer"/>-->
                <xsl:variable name="tstamp" select="number(@tstamp)" as="xs:double"/>
                
                <xsl:if test="not($elem/@stem.mod)">
                    <xsl:message select="local-name($elem) || '[#' || $elem/@xml:id || '] inside bTrem misses @stem.mod'"/>
                </xsl:if>
                
                <xsl:variable name="measperf" select="$stem.mod.total * 8" as="xs:double"/>
                
                <xsl:variable name="meter.unit" select="ancestor::mei:measure/preceding::mei:scoreDef[@meter.unit][1]/@meter.unit cast as xs:integer" as="xs:integer"/>
                <xsl:variable name="tstamp.step" select="$meter.unit div number($measperf)" as="xs:double"/>
                
                <!--<xsl:message select="$totalDur || ' dur makes ' || $count || ' found'"></xsl:message>-->
                
                <xsl:choose>
                    <xsl:when test="not(ancestor::mei:beam)">
                        <beam>
                            <xsl:for-each select="(1 to $count)">
                                <xsl:variable name="i" select="." as="xs:integer"/>
                                <xsl:variable name="n" select="$i - 1" as="xs:integer"/>
                                
                                <xsl:apply-templates select="$elem" mode="resolveTrems">
                                    <xsl:with-param name="dur" select="$measperf"/>
                                    <xsl:with-param name="tstamp" select="$tstamp + $n * $tstamp.step"/>
                                </xsl:apply-templates>
                                
                            </xsl:for-each>
                        </beam>
                    </xsl:when>
                    <xsl:otherwise>
                        
                            <xsl:for-each select="(1 to $count)">
                                <xsl:variable name="i" select="." as="xs:integer"/>
                                <xsl:variable name="n" select="$i - 1" as="xs:integer"/>
                                
                                <xsl:apply-templates select="$elem" mode="resolveTrems">
                                    <xsl:with-param name="dur" select="$measperf"/>
                                    <xsl:with-param name="tstamp" select="$tstamp + $n * $tstamp.step"/>
                                </xsl:apply-templates>
                                
                            </xsl:for-each>
                        
                    </xsl:otherwise>
                </xsl:choose>
                
                
                
                
            </reg>
        </choice>
    </xsl:template>
    
    <!-- resolving fTrems that aren't resolved already -->
    <xsl:template match="mei:fTrem[not(parent::mei:orig)]" mode="resolveTrems">
        <choice xmlns="http://www.music-encoding.org/ns/mei" xml:id="c{uuid:randomUUID()}">
            <orig>
                <xsl:copy>
                    <xsl:apply-templates select="node() | @*" mode="#current"/>
                </xsl:copy>
            </orig>
            <reg>
                <xsl:variable name="elem.1" select="child::mei:*[1]" as="node()"/>
                <xsl:variable name="elem.2" select="child::mei:*[2]" as="node()"/>
                <xsl:variable name="dur" select="1 div number(@dur)"/>
                <xsl:variable name="dots" select="if(@dots) then(number(@dots)) else(0)"/>
                <xsl:variable name="totalDur" select="(2 * $dur) - ($dur div math:pow(2,$dots))" as="xs:double"/>
                <xsl:variable name="measperf" select="@measperf" as="xs:string"/>
                <xsl:variable name="perfDur" select="1 div number($measperf)" as="xs:double"/>
                <xsl:variable name="count" select="(($totalDur div $perfDur) div 2) cast as xs:integer" as="xs:integer"/>
                <xsl:variable name="tstamp" select="number(@tstamp)" as="xs:double"/>
                
                <xsl:variable name="meter.unit" select="(ancestor::mei:measure/preceding::mei:scoreDef[@meter.unit])[1]/@meter.unit cast as xs:integer" as="xs:integer"/>
                <xsl:variable name="tstamp.step" select="$meter.unit div number($measperf)" as="xs:double"/>
                
                <beam>
                    <xsl:for-each select="(1 to $count)">
                        <xsl:variable name="i" select="." as="xs:integer"/>
                        <xsl:variable name="n" select="$i - 1" as="xs:integer"/>
                        <xsl:apply-templates select="$elem.1" mode="resolveTrems">
                            <xsl:with-param name="dur" select="$measperf"/>
                            <xsl:with-param name="tstamp" select="$tstamp + (2 * $n) * $tstamp.step"/>
                        </xsl:apply-templates>
                        <xsl:apply-templates select="$elem.2" mode="resolveTrems">
                            <xsl:with-param name="dur" select="$measperf"/>
                            <xsl:with-param name="tstamp" select="$tstamp + ((2 * $n) + 1) * $tstamp.step"/>
                        </xsl:apply-templates>
                    </xsl:for-each>
                </beam>
                
            </reg>
        </choice>
    </xsl:template>
    
    <!-- adjust notes and chords that are contained in a tremolo, i.e. apply duration and tstamp as provided -->
    <xsl:template match="mei:chord | mei:note[not(parent::mei:chord)]" mode="resolveTrems">
        <xsl:param name="dur"/>
        <xsl:param name="tstamp"/>
        <xsl:choose>
            <!-- when only controlEvents are to be resolved, no special treatment is necessary -->
            <xsl:when test="$mode = 'controlEvents'">
                <xsl:next-match/>
            </xsl:when>
            <!-- affect only those notes and chords that are child of a tremolo -->
            <xsl:when test="parent::mei:bTrem or parent::mei:fTrem">
                <xsl:copy>
                    <xsl:attribute name="xml:id" select="'e' || uuid:randomUUID()"/>
                    <xsl:if test="$dur">
                        <xsl:attribute name="dur" select="$dur"/>
                    </xsl:if>
                    <xsl:if test="$tstamp">
                        <xsl:attribute name="tstamp" select="$tstamp"/>
                    </xsl:if>
                    <xsl:apply-templates select="@* except (@xml:id,@dur,@dots,@tstamp,@stem.mod, @sameas)" mode="#current"/>
                    <xsl:apply-templates select="mei:* | comment()" mode="adjustMaterial"/>
                </xsl:copy>
            </xsl:when>
            <!-- all other notes and chords are just copied -->
            <xsl:otherwise>
                <xsl:next-match/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- notes within a chord don't need any special treatment -->
    <xsl:template match="mei:note[parent::mei:chord]" mode="resolveTrems">
        <xsl:next-match/>
    </xsl:template>
    
    <!-- *******MODE*****resolveRpts*** -->
    
    <!-- resolve mRpt that aren't resolved already -->
    <xsl:template match="mei:mRpt[not(parent::mei:abbr)]" mode="resolveRpts">
        
        <xsl:if test="@xml:id = 'x8699d781-81b0-4f63-9c85-6a3e942b5bdb'">
            <xsl:message select="'resolving'"></xsl:message>
        </xsl:if>
        
        <choice xmlns="http://www.music-encoding.org/ns/mei" xml:id="c{uuid:randomUUID()}">
            <abbr type="mRpt">
                <xsl:copy>
                    <xsl:apply-templates select="node() | @*" mode="#current"/>
                </xsl:copy>
            </abbr>
            <expan evidence="#{@xml:id}">
                <xsl:variable name="layer.hasN" select="exists(parent::mei:layer/@n)" as="xs:boolean"/>
                <xsl:variable name="layer.n" select="parent::mei:layer/@n" as="xs:string?"/>
                <xsl:variable name="staff.n" select="ancestor::mei:staff/@n" as="xs:string"/>
                
                <!-- todo: abfrage von layer.n genauer! -->
                <xsl:variable name="preceding.measure" select="ancestor::mei:measure/preceding::mei:measure[not(mei:staff[@n = $staff.n]/mei:layer[@n = $layer.n]/mei:mRpt)][1]"/>
                <xsl:variable name="corresponding.layer" select="if($layer.hasN) then($preceding.measure/mei:staff[@n = $staff.n]/mei:layer[@n = $layer.n]) else($preceding.measure/mei:staff[@n = $staff.n]/mei:layer)" as="node()"/>
                <xsl:apply-templates select="$corresponding.layer/mei:*" mode="adjustMaterial"/>
            </expan>
        </choice>
    </xsl:template>
    
    <!-- todo: do we need templates for beatRpt etc.? -->
    
    <!-- if material is to be resolved which has been resolved in a preceding processing step already,
        use only the resolved content, not the original -->
    <xsl:template match="mei:choice" mode="adjustMaterial">
        <xsl:apply-templates select="mei:reg/mei:* | mei:expan/mei:*" mode="#current"/>
    </xsl:template>
    
    <!-- in mode adjustMaterial, generate new xml:id, and add a reference to the original element with @corresp
        (or keep the existing @corresp reference, in case of "chained" references -->
    <xsl:template match="@xml:id" mode="adjustMaterial">
        <xsl:attribute name="xml:id" select="'r'||uuid:randomUUID()"/>
        <xsl:choose>
            <xsl:when test="parent::mei:*/@corresp">
                <xsl:attribute name="corresp" select="parent::mei:*/@corresp"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:attribute name="corresp" select="'#' || ."/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- disconnect @sameas in mode adjustMaterial -->
    <xsl:template match="@sameas" mode="adjustMaterial"/>
    
    <!-- transpose referenced material if necessary (ie. "in 8va") -->
    <xsl:template match="@oct" mode="adjustMaterial">
        <xsl:param name="oct.dis" as="xs:integer?" tunnel="yes"/>
        <xsl:attribute name="oct" select="number(string(.)) + (if($oct.dis) then($oct.dis) else(0))"/>
    </xsl:template>
    
    <!-- in mode adjustMaterial, layers aren't processed – just their contents -->
    <xsl:template match="mei:layer" mode="adjustMaterial">
        <xsl:apply-templates select="child::node()" mode="#current"/>
    </xsl:template>
    
    <!-- decide if things with a tstamp need to be included or not
        * if so, look for grace notes that are attached to the note as well -->
    <!-- todo: adjust tstamps when necessary -->
    <xsl:template match="mei:*[@tstamp]" mode="adjustMaterial">
        <xsl:param name="tstamp.first" tunnel="yes" as="xs:double?"/>
        <xsl:param name="tstamp.last" tunnel="yes" as="xs:double?"/>
        
        <xsl:choose>
            <xsl:when test="not(exists($tstamp.first) and exists($tstamp.last))">
                <xsl:next-match/>
            </xsl:when>
            <xsl:when test="number(@tstamp) ge $tstamp.first and number(@tstamp) le $tstamp.last">
                
                <!-- if there are preceding gracenotes (which have no @tstamp) -->
                <xsl:if test="@stayWithMe">
                    <xsl:variable name="grace.IDs" select="tokenize(@stayWithMe,' ')" as="xs:string+"/>
                    <xsl:variable name="graces" as="node()*">
                        <xsl:for-each select="$grace.IDs">
                            <xsl:sequence select="$originalFile//mei:music/id(replace(.,'#',''))"/>
                        </xsl:for-each>
                    </xsl:variable>
                    
                    <xsl:apply-templates select="$graces" mode="#current"/>
                </xsl:if>
                
                <xsl:copy>
                    <xsl:apply-templates select="node() | @*" mode="#current"/>
                </xsl:copy>
            </xsl:when>
            <xsl:otherwise/>
        </xsl:choose>
    </xsl:template>
    
    <!-- decide if tstamps need to be adjusted, i.e. in the case of beatRpt -->
    <xsl:template match="@tstamp" mode="adjustMaterial">
        <xsl:param name="tstamp.offset" tunnel="yes" as="xs:double?"/>
        <xsl:choose>
            <xsl:when test="exists($tstamp.offset)">
                <xsl:attribute name="tstamp" select="number(.) + $tstamp.offset"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:next-match/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- decide if elements like beam and tuplet need to be preserved, based on the tstamps of their children -->
    <xsl:template match="mei:*[not(@tstamp) and .//@tstamp]" mode="adjustMaterial">
        <xsl:param name="tstamp.first" tunnel="yes" as="xs:double?"/>
        <xsl:param name="tstamp.last" tunnel="yes" as="xs:double?"/>
        <xsl:choose>
            <xsl:when test="not($tstamp.first and $tstamp.last)">
                <xsl:next-match/>
            </xsl:when>
            <xsl:when test="some $tstamp in .//@tstamp satisfies (number($tstamp) ge $tstamp.first and number($tstamp) le $tstamp.last)">
                <xsl:copy>
                    <xsl:apply-templates select="node() | @*" mode="#current"/>
                </xsl:copy>
            </xsl:when>
            <xsl:otherwise/>
        </xsl:choose>
    </xsl:template>
    
    <!-- things to exclude from repeating -->
    <xsl:template match="mei:clef" mode="adjustMaterial"/>
    
    <!-- resolve controlEvents affected by a mRpt -->
    <!-- todo: better deal with controlEvents already nested into choices… -->
    <xsl:template match="mei:measure[.//mei:mRpt]" mode="resolveRpts">
        <xsl:choose>
            <xsl:when test="$mode = 'events'">
                <xsl:next-match/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy>
                    <xsl:apply-templates select="node() | @*" mode="#current"/>
                    
                    <xsl:variable name="affectedStaves" select="mei:staff[.//mei:mRpt]/@n" as="xs:string*"/>
                    <xsl:variable name="measure" select="."/>
                    
                    <xsl:for-each select="$affectedStaves">
                        <xsl:variable name="staff.n" select="."/>
                        
                        <!--<xsl:variable name="preceding.measure" select="$measure/preceding::mei:measure[not(mei:staff[@n = $staff.n]//mei:mRpt)][1]"/>-->
                        
                        <xsl:variable name="targetMeasure" select="$measure/preceding::mei:measure[mei:staff[@n = $staff.n and not(.//mei:mRpt) and not(.//mei:mSpace)]][1]"/>
                        <xsl:variable name="controlEvents" select="$targetMeasure/mei:*[not(local-name() = 'staff') and .//@staff = $staff.n and not(local-name() = 'cpMark') and not(.//mei:cpMark)]"/>
                        
                        <!--<xsl:message select="count($controlEvents) || ' controlEvents from mRpt #' || ($measure/mei:staff[@n = $staff.n]//mei:mRpt)[1]/@xml:id"/>-->
                        
                        <xsl:for-each select="$controlEvents">
                            
                            <xsl:variable name="controlEvent" select="." as="node()"/>                            
                            <choice xmlns="http://www.music-encoding.org/ns/mei" xml:id="c{uuid:randomUUID()}">
                                <abbr type="mRpt"/>
                                <expan evidence="#{($measure/mei:staff[@n = $staff.n]//mei:mRpt)[1]/@xml:id}">
                                    
                                    <xsl:choose>
                                        <xsl:when test="local-name() != 'choice'">
                                            <xsl:apply-templates select="." mode="adjustMaterial"/>        
                                        </xsl:when>
                                        <xsl:when test="local-name() = 'choice' and count(./mei:reg | ./mei:expan) = 1">
                                            <xsl:apply-templates select="./mei:reg | ./mei.expan" mode="adjustMaterial"/>
                                        </xsl:when>
                                        <xsl:when test="local-name() = 'choice' and count(./mei:reg | ./mei:expan) gt 1">
                                            <choice xmlns="http://www.music-encoding.org/ns/mei" xml:id="c{uuid:randomUUID()}" corresp="{@xml:id}">
                                                <xsl:for-each select="(./mei:reg | ./mei:expan)">
                                                    <xsl:apply-templates select="." mode="adjustMaterial"/>    
                                                </xsl:for-each>
                                            </choice>
                                        </xsl:when>
                                    </xsl:choose>
                                    
                                </expan>
                            </choice>       
                                                            
                        </xsl:for-each>
                    </xsl:for-each>    
                </xsl:copy>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- mode resolveMarks -->
    <xsl:template match="mei:cpMark" mode="resolveMarks">
        <xsl:param name="cpMark.ids" as="xs:string*" tunnel="yes"/>
        
        <xsl:variable name="staff.n" select="@staff" as="xs:string"/>
        <xsl:variable name="staff" select="ancestor::mei:measure/mei:staff[@n = $staff.n]" as="node()"/>
        
        <xsl:choose>
            
            <!-- this cpMark should have been processed in $mode=events already, so no need to touch it again -->
            <xsl:when test="$mode = 'controlEvents'">
                <xsl:next-match/>
            </xsl:when>
            
            <!-- this cpMark is processed in a different run -->
            <xsl:when test="not(@xml:id = $cpMark.ids)">
                <xsl:next-match/>
            </xsl:when>
            
            <xsl:when test="$staff//mei:mRpt and starts-with(@tstamp2,'0m+') and @ref.offset = '-1m+1'">
                <!--This cpMark is just a mRpt and already encoded as such.-->
                <xsl:variable name="endTstamp" select="number(substring-after(@tstamp2,'m+'))" as="xs:double"/>
                <xsl:variable name="maxMeter" select="number(parent::mei:measure/@meter.count)" as="xs:double"/>
                <xsl:if test="not($endTstamp ge $maxMeter and $endTstamp le ($maxMeter + 1))">
                    <xsl:message select="'something seems wrong for cpMark in ' || $staff/@xml:id || ', maxMeter is ' || $maxMeter"/>
                </xsl:if>
            </xsl:when>
            <!--<xsl:when test="$staff//mei:mSpace and starts-with(@tstamp2,'0m+') and @ref.offset = '-1m+1'">
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
                        
                        <xsl:variable name="preceding.measure" select="ancestor::mei:measure/preceding::mei:measure[not(mei:staff[@n = $staff.n]/mei:layer[@n = $layer.n]/mei:mRpt) and not(mei:staff[@n = $staff.n]/mei:layer[@n = $layer.n]/mei:mSpace)][1]"/>
                        <xsl:variable name="corresponding.layer" select="if($layer.hasN) then($preceding.measure/mei:staff[@n = $staff.n]/mei:layer[@n = $layer.n]) else($preceding.measure/mei:staff[@n = $staff.n]/mei:layer)" as="node()"/>
                        <xsl:apply-templates select="$corresponding.layer/mei:*" mode="adjustMaterial"/>
                    </reg>
                </choice>
            </xsl:when>-->
            <xsl:when test="@ref.staff and not(@ref.offset)">
                <!-- This cpMark is a colla parte instruction -->
                <!--<xsl:message select="'colla parte cpMark in ' || parent::mei:measure/@xml:id || ', staff ' || @staff"/>-->
                <xsl:copy>
                    <xsl:attribute name="type" select="'collaParte'"/>
                    <xsl:apply-templates select="node() | @*" mode="#current"/>
                </xsl:copy>
            </xsl:when>
            <xsl:when test="@ref.offset and not(@ref.staff)">
                <!-- This cpMark is a copy instruction from preceding measures -->
                <!--<xsl:message select="'copy instruction cpMark in ' || parent::mei:measure/@xml:id || ', staff ' || @staff"/>-->
                <xsl:copy>
                    <xsl:attribute name="type" select="'copyInstruction'"/>
                    <xsl:apply-templates select="node() | @*" mode="#current"/>
                </xsl:copy>
            </xsl:when>
            <xsl:when test="@ref.staff and @ref.offset">
                <!-- This cpMark is strange and should not exist in the Freischütz -->
                <xsl:message select="'found a strange cpMark in measure '|| ancestor::mei:measure/@xml:id"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message select="'cpMark to resolve: tstamp(' || @tstamp ||'), tstamp2(' || @tstamp2 || ')'"/>
                <xsl:copy>
                    <xsl:apply-templates select="node() | @*" mode="#current"/>
                </xsl:copy>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- resolve layers -->
    <xsl:template match="mei:layer" mode="resolveMarks">
        <xsl:param name="cpInstructions" tunnel="yes"/>
        <xsl:param name="cpMarks.enhanced" tunnel="yes"/>
        <xsl:param name="cpMark.ids" as="xs:string*" tunnel="yes"/>
        <xsl:param name="run" as="xs:integer" tunnel="yes"/>
        <xsl:param name="material" as="node()" tunnel="yes"/>
        
        <xsl:variable name="staff.id" select="parent::mei:staff/@xml:id"/>
        <xsl:variable name="layer" select="."/>
        
        <xsl:choose>
            <!-- when only resolving controlEvents, no special action is required -->
            <xsl:when test="$mode = 'controlEvents'">
                <xsl:next-match/>
            </xsl:when>
            <!-- when the current staff isn't mentioned as a target for copying in music, no special action is required -->
            <xsl:when test="not($staff.id = $cpInstructions//@targetStaff.id)">
                <xsl:next-match/>
            </xsl:when>
            <!-- there must be an instruction to copy in music, so resolve it -->
            <xsl:otherwise>
                <xsl:variable name="probable.cpInstructions" select="$cpInstructions/descendant-or-self::*[@targetStaff.id = $staff.id]"/>
                <xsl:variable name="local.cpMarks" select="$cpMarks.enhanced/descendant-or-self::*[@xml:id = $probable.cpInstructions/@cpMark.id 
                    and @xml:id = $cpMark.ids 
                    and (
                        (not(@layer) and not($layer/preceding-sibling::mei:layer)) 
                        or (@layer = $layer/@n) 
                        or ((@layer = '1') and not($layer/@n))
                    )]"/>
                
                <xsl:variable name="local.cpInstructions" as="node()*">
                    <xsl:perform-sort select="$probable.cpInstructions/descendant-or-self::*[@cpMark.id = $local.cpMarks/@xml:id]">
                        <xsl:sort select="@target.tstamp.first" data-type="number"/>
                        <xsl:sort select="@target.tstamp.last" data-type="number"/>
                    </xsl:perform-sort>
                </xsl:variable>
                
                <xsl:if test="count($local.cpInstructions) gt 1 and count($local.cpMarks) gt 1">
                    <xsl:message select="'multiple cpInstructions for layer in ' || $staff.id || ', at least two in the same run. Are there really two beatRpt?'"/>
                </xsl:if>
                
                <xsl:if test="count($local.cpMarks) != count($local.cpInstructions)">
                    <xsl:message select="'something is wrong for ' || $staff.id"/>
                </xsl:if>
                
                <xsl:choose>
                    
                    <!-- cpMarks processed in different iteration (there is a second iteration for copy instructions that refer to a measure which itself
                        copies in music) -->
                    <xsl:when test="count($local.cpMarks) = 0">
                        <xsl:next-match/>
                    </xsl:when>
                    
                    <!-- deal with all the cpMarks for this layer -->
                    <xsl:otherwise>
                        
                        <xsl:copy>
                            <xsl:apply-templates select="@*" mode="#current"/>
                            
                            <xsl:for-each select="(1 to count($local.cpMarks))">
                                <xsl:variable name="j" select="."/>
                                
                                <xsl:variable name="begin" select="if($j = 1) then(0) else($local.cpInstructions[$j - 1]/@target.tstamp.last)" as="xs:double"/>
                                <xsl:variable name="end" select="number($local.cpInstructions[$j]/@target.tstamp.first)" as="xs:double"/>
                                
                                <!--DEBUG <xsl:message select="'beginning at tstamp ' || $begin || ', ending at ' || $end  || ' for j=' || $j || ' in ' || $staff.id"/>-->
                                
                                <xsl:apply-templates select="$layer/node()" mode="#current">
                                    <xsl:with-param name="tstamp.after" select="$begin" as="xs:double" tunnel="yes"/>
                                    <xsl:with-param name="tstamp.before" select="number($local.cpInstructions[$j]/@target.tstamp.first)" as="xs:double" tunnel="yes"/>
                                </xsl:apply-templates>
                                
                                <choice xmlns="http://www.music-encoding.org/ns/mei" xml:id="c{uuid:randomUUID()}">
                                    <abbr type="cpMark" tstamp="{$local.cpInstructions[$j]/@target.tstamp.first}" tstamp2="0m+{$local.cpInstructions[$j]/@target.tstamp.last}">
                                        
                                        <xsl:apply-templates select="$layer/node()" mode="#current">
                                            <xsl:with-param name="tstamp.first" select="number($local.cpInstructions[$j]/@target.tstamp.first)" as="xs:double" tunnel="yes"/>
                                            <xsl:with-param name="tstamp.last" select="number($local.cpInstructions[$j]/@target.tstamp.last)" as="xs:double" tunnel="yes"/>
                                        </xsl:apply-templates>
                                    </abbr>
                                    <expan evidence="#{$local.cpMarks[$j]/@xml:id}">
                                        
                                        <xsl:variable name="sourceLayer" as="node()">
                                            <xsl:choose>
                                                <xsl:when test="$local.cpMarks[$j]/@ref.layer">
                                                    <xsl:sequence select="$material/id($local.cpInstructions[$j]/@sourceStaff.id)/mei:layer[@n = $local.cpMarks[$j]/@ref.layer]"/>
                                                </xsl:when>
                                                <xsl:otherwise>
                                                    <xsl:sequence select="$material/id($local.cpInstructions[$j]/@sourceStaff.id)/mei:layer[1]"/>
                                                </xsl:otherwise>
                                            </xsl:choose>
                                        </xsl:variable>
                                        
                                        <xsl:if test="local-name($sourceLayer) != 'layer'">
                                            <xsl:message select="'in staff ' || $layer/parent::mei:staff || ', layer ' || $layer/@n ||', $sourceLayer is a ' || local-name($sourceLayer)"/>
                                            <xsl:message select="$sourceLayer"/>
                                        </xsl:if>
                                        
                                        <xsl:variable name="oct.dis" as="xs:integer">
                                            <xsl:choose>
                                                <xsl:when test="$local.cpMarks[$j]/@dis = '8' and $local.cpMarks[$j]/@dis.place = 'above'">1</xsl:when>
                                                <xsl:when test="$local.cpMarks[$j]/@dis = '15' and $local.cpMarks[$j]/@dis.place = 'above'">2</xsl:when>
                                                <xsl:when test="$local.cpMarks[$j]/@dis = '22' and $local.cpMarks[$j]/@dis.place = 'above'">3</xsl:when>
                                                <xsl:when test="$local.cpMarks[$j]/@dis = '8' and $local.cpMarks[$j]/@dis.place = 'below'">-1</xsl:when>
                                                <xsl:when test="$local.cpMarks[$j]/@dis = '15' and $local.cpMarks[$j]/@dis.place = 'below'">-2</xsl:when>
                                                <xsl:when test="$local.cpMarks[$j]/@dis = '22' and $local.cpMarks[$j]/@dis.place = 'below'">-3</xsl:when>
                                                <xsl:otherwise>0</xsl:otherwise>
                                            </xsl:choose>
                                        </xsl:variable>
                                        
                                        <xsl:apply-templates select="$sourceLayer/mei:*" mode="adjustMaterial">
                                            <xsl:with-param name="oct.dis" select="$oct.dis" as="xs:integer" tunnel="yes"/>
                                            <xsl:with-param name="tstamp.first" select="number($local.cpInstructions[$j]/@source.tstamp.first)" as="xs:double" tunnel="yes"/>
                                            <xsl:with-param name="tstamp.last" select="number($local.cpInstructions[$j]/@source.tstamp.last)" as="xs:double" tunnel="yes"/>
                                            <!-- if material from tstamp=1 is copied into tstamp=3, value of tstamp.offset would be "-2" -->
                                            <xsl:with-param name="tstamp.offset" select="number($local.cpInstructions[$j]/@target.tstamp.last) - number($local.cpInstructions[$j]/@source.tstamp.last)" as="xs:double" tunnel="yes"/>                                           
                                        </xsl:apply-templates>
                                    </expan>
                                </choice>
                                
                            </xsl:for-each>
                            
                            <xsl:apply-templates select="$layer/node()" mode="#current">
                                <xsl:with-param name="tstamp.after" select="$local.cpInstructions[last()]/@target.tstamp.last" as="xs:double" tunnel="yes"/>
                            </xsl:apply-templates>
                            
                        </xsl:copy>
                        
                        <xsl:for-each select="$local.cpMarks">
                            <xsl:variable name="pos" select="position()" as="xs:integer"/>
                            <xsl:variable name="current.cpMark" select="." as="node()"/>
                            <xsl:variable name="current.cpInstruction" select="$local.cpInstructions[$pos]" as="node()"/>
                            <xsl:if test="not($current.cpMark/@layer) and count($material/id($current.cpInstruction/@sourceStaff.id)/mei:layer) gt 1 and not($layer/following-sibling::mei:layer)">
                                
                                <xsl:if test="count($local.cpMarks) gt 1">
                                    <xsl:message select="'there may be problems in the encoding of ' || $staff.id || ' with regard to a second generated layer. Please check!'"/>
                                </xsl:if>
                                
                                <xsl:for-each select="2 to (count($material/id($current.cpInstruction/@sourceStaff.id)/mei:layer))">
                                    <xsl:variable name="iteration" select="." as="xs:integer"/>
                                    
                                    <layer n="{$iteration}" xmlns="http://www.music-encoding.org/ns/mei" xml:id="l{uuid:randomUUID()}">
                                        <choice xml:id="x{uuid:randomUUID()}">
                                            <abbr type="cpMark" xml:id="g{uuid:randomUUID()}">
                                                <mSpace xml:id="m{uuid:randomUUID()}" tstamp="1"/>
                                            </abbr>
                                            <expan evidence="#{$current.cpMark/@xml:id}">
                                                
                                                <xsl:variable name="sourceLayer" select="$material/id($current.cpInstruction/@sourceStaff.id)/mei:layer[$iteration]" as="node()"/>
                                                
                                                
                                                <xsl:if test="local-name($sourceLayer) != 'layer'">
                                                    <xsl:message select="'in staff ' || $staff.id || ', layer ' || $iteration ||', $sourceLayer is a ' || local-name($sourceLayer)"/>
                                                    <xsl:message select="$sourceLayer"/>
                                                </xsl:if>
                                                
                                                <xsl:variable name="oct.dis" as="xs:integer">
                                                    <xsl:choose>
                                                        <xsl:when test="$current.cpMark/@dis = '8' and $current.cpMark/@dis.place = 'above'">1</xsl:when>
                                                        <xsl:when test="$current.cpMark/@dis = '15' and $current.cpMark/@dis.place = 'above'">2</xsl:when>
                                                        <xsl:when test="$current.cpMark/@dis = '22' and $current.cpMark/@dis.place = 'above'">3</xsl:when>
                                                        <xsl:when test="$current.cpMark/@dis = '8' and $current.cpMark/@dis.place = 'below'">-1</xsl:when>
                                                        <xsl:when test="$current.cpMark/@dis = '15' and $current.cpMark/@dis.place = 'below'">-2</xsl:when>
                                                        <xsl:when test="$current.cpMark/@dis = '22' and $current.cpMark/@dis.place = 'below'">-3</xsl:when>
                                                        <xsl:otherwise>0</xsl:otherwise>
                                                    </xsl:choose>
                                                </xsl:variable>
                                                
                                                <xsl:apply-templates select="$sourceLayer/mei:*" mode="adjustMaterial">
                                                    <xsl:with-param name="oct.dis" select="$oct.dis" as="xs:integer" tunnel="yes"/>
                                                    <xsl:with-param name="tstamp.first" select="number($current.cpInstruction/@source.tstamp.first)" as="xs:double" tunnel="yes"/>
                                                    <xsl:with-param name="tstamp.last" select="number($current.cpInstruction/@source.tstamp.last)" as="xs:double" tunnel="yes"/>
                                                    <!-- if material from tstamp=1 is copied into tstamp=3, value of tstamp.offset would be "-2" -->
                                                    <xsl:with-param name="tstamp.offset" select="number($current.cpInstruction/@target.tstamp.last) - number($current.cpInstruction/@source.tstamp.last)" as="xs:double" tunnel="yes"/>                                           
                                                </xsl:apply-templates>
                                            </expan>
                                        </choice>
                                    </layer>
                                    
                                </xsl:for-each>
                                
                                
                                
                            </xsl:if>
                        </xsl:for-each>
                        
                    </xsl:otherwise>
                    
                </xsl:choose>
                
                
                
                <!-- check for cpMarks that require to create a whole new layer for this staff -->
                <xsl:variable name="other.cpMarks" select="$cpMarks.enhanced/descendant-or-self::*[@xml:id = $probable.cpInstructions/@cpMark.id 
                    and @xml:id = $cpMark.ids 
                    and @layer
                    and @layer != $layer/@n]"/>
                
                <xsl:variable name="other.cpInstructions" as="node()*">
                    <xsl:perform-sort select="$probable.cpInstructions/descendant-or-self::*[@cpMark.id = $other.cpMarks/@xml:id]">
                        <xsl:sort select="@target.tstamp.first" data-type="number"/>
                        <xsl:sort select="@target.tstamp.last" data-type="number"/>
                    </xsl:perform-sort>
                </xsl:variable>
                
                <xsl:if test="count($other.cpMarks) gt 0 or count($other.cpInstructions) gt 0">
                    <xsl:message select="$staff.id || ': $other.cpMarks: ' || count($other.cpMarks) || ', $other.cpInstructions: ' || count($other.cpInstructions)"/>    
                </xsl:if>
                
                
                
                
                
                <!-- todo: check the following comment -->
                <!--<xsl:if test="count($other.cpInstructions) ge 1 or count($other.cpMarks) ge 1">
                    <xsl:message select="'a cpMark for staff ' || $staff.id || ' requires to create a whole new layer. Please check if everything is correct (you may have to insert spaces…)'"/>
                    
                    <xsl:for-each select="distinct-values($other.cpMarks//@layer)">
                        <xsl:variable name="num" select="count($layer/parent::mei:staff/mei:layer) + position()" as="xs:integer"/>
                        <xsl:variable name="current.layer" select="."/>
                        
                        <xsl:variable name="relevant.cpMarks" select="$other.cpMarks[@layer = $current.layer]" as="node()*"/>
                        <xsl:variable name="relevant.cpInstructions" select="$other.cpInstructions/descendant-or-self::*[@cpMark.id = $relevant.cpMarks/@xml:id]" as="node()*"/>
                        
                        <xsl:if test="count($relevant.cpMarks) != count($relevant.cpInstructions)">
                            <xsl:message select="'something went wrong after layer ' || $layer/xml:id || ': ' || count($relevant.cpMarks) || ' marks, ' || count($relevant.cpInstructions) || ' instructions'"/>
                            <xsl:message select="$relevant.cpMarks"/>
                        </xsl:if>
                        
                        <layer xmlns="http://www.music-encoding.org/ns/mei" xml:id="l{uuid:randomUUID()}" n="{$num}">
                            
                            <xsl:for-each select="(1 to count($relevant.cpMarks))">
                                <xsl:variable name="j" select="."/>
                                
                                <choice xmlns="http://www.music-encoding.org/ns/mei" xml:id="c{uuid:randomUUID()}">
                                    <abbr type="cpMark" tstamp="{$relevant.cpInstructions[$j]/@target.tstamp.first}" tstamp2="0m+{$relevant.cpInstructions[$j]/@target.tstamp.last}"/>
                                    <expan evidence="#{$relevant.cpMarks[$j]/@xml:id}">
                                        
                                        <!-\- sourceLayer scheint nicht zu klappen -\->
                                        <xsl:variable name="sourceLayer" as="node()">
                                            <xsl:choose>
                                                <xsl:when test="$relevant.cpMarks[$j]/@ref.layer">
                                                    <xsl:sequence select="$music/id($relevant.cpInstructions[$j]/@sourceStaff.id)/mei:layer[@n = $relevant.cpMarks[$j]/@ref.layer]"/>
                                                </xsl:when>
                                                <xsl:otherwise>
                                                    <xsl:if test="not($music/id($relevant.cpInstructions[$j]/@sourceStaff.id)/mei:layer)">
                                                        <xsl:message select="$relevant.cpInstructions[$j]"/>
                                                    </xsl:if>
                                                    
                                                    
                                                    <xsl:sequence select="$music/id($relevant.cpInstructions[$j]/@sourceStaff.id)/mei:layer[1]"/>
                                                </xsl:otherwise>
                                            </xsl:choose>
                                        </xsl:variable>
                                        <xsl:variable name="oct.dis" as="xs:integer">
                                            <xsl:choose>
                                                <xsl:when test="$relevant.cpMarks[$j]/@dis = '8' and $relevant.cpMarks[$j]/@dis.place = 'above'">1</xsl:when>
                                                <xsl:when test="$relevant.cpMarks[$j]/@dis = '15' and $relevant.cpMarks[$j]/@dis.place = 'above'">2</xsl:when>
                                                <xsl:when test="$relevant.cpMarks[$j]/@dis = '22' and $relevant.cpMarks[$j]/@dis.place = 'above'">3</xsl:when>
                                                <xsl:when test="$relevant.cpMarks[$j]/@dis = '8' and $relevant.cpMarks[$j]/@dis.place = 'below'">-1</xsl:when>
                                                <xsl:when test="$relevant.cpMarks[$j]/@dis = '15' and $relevant.cpMarks[$j]/@dis.place = 'below'">-2</xsl:when>
                                                <xsl:when test="$relevant.cpMarks[$j]/@dis = '22' and $relevant.cpMarks[$j]/@dis.place = 'below'">-3</xsl:when>
                                                <xsl:otherwise>0</xsl:otherwise>
                                            </xsl:choose>
                                        </xsl:variable>
                                        <xsl:apply-templates select="$sourceLayer" mode="adjustMaterial">
                                            <xsl:with-param name="oct.dis" select="$oct.dis" as="xs:integer" tunnel="yes"/>
                                            <xsl:with-param name="tstamp.first" select="number($relevant.cpInstructions[$j]/@target.tstamp.first)" as="xs:double" tunnel="yes"/>
                                            <xsl:with-param name="tstamp.last" select="number($relevant.cpInstructions[$j]/@target.tstamp.last)" as="xs:double" tunnel="yes"/>
                                        </xsl:apply-templates>
                                    </expan>
                                </choice>
                                
                            </xsl:for-each>
                            
                        </layer>
                    </xsl:for-each>
                    
                </xsl:if>-->
                
                
            </xsl:otherwise>

        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="mei:choice" mode="cleanup">
        
        <xsl:choose>
            <xsl:when test="not(ancestor::mei:choice)">
                <xsl:next-match/>
            </xsl:when>
            <xsl:when test="ancestor::mei:expan">
                <xsl:apply-templates select="mei:expan/child::mei:* | mei:reg/child::mei:* | mei:corr/child::mei:*" mode="adjustMaterial"/>
            </xsl:when>
        </xsl:choose>
        
        <!--<xsl:choose>
            <xsl:when test="self::node()/ancestor::mei:choice and ancestor::mei:expan">
                <xsl:apply-templates select="./mei:reg/child::mei:* | ./mei:expan/child::mei:* | ./mei:corr/child::mei:*" mode="adjustMaterial"/>
            </xsl:when>
            <xsl:when test="self::node()/ancestor::mei:choice and ancestor::mei:abbr">
                <xsl:apply-templates select="./mei:abbr/child::mei:*" mode="#current"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:next-match/>
            </xsl:otherwise>
        </xsl:choose>-->
    </xsl:template>
        
    <xsl:template match="mei:measure" mode="resolveMarks">
        <xsl:param name="cpInstructions" tunnel="yes"/>
        <xsl:param name="cpMarks.enhanced" tunnel="yes"/>
        <xsl:param name="cpMark.ids" as="xs:string*" tunnel="yes"/>
        
        <xsl:variable name="target.measure" select="."/>
        
        <xsl:copy>
            <xsl:apply-templates select="node() | @*" mode="#current"/>
            
            <xsl:variable name="affectedStaves" select="child::mei:staff[@xml:id = $cpInstructions//@targetStaff.id]"/>    
            
           <!-- <xsl:message select="count($affectedStaves) || ' affected staves'"/>-->
            
            <xsl:for-each select="$affectedStaves">
                
                <xsl:variable name="staff.id" select="@xml:id"/>
                <xsl:variable name="cpInstructions.all" select="$cpInstructions/descendant-or-self::*[@targetStaff.id = $staff.id]"/>
                <xsl:variable name="local.cpMarks" select="$cpMarks.enhanced/descendant-or-self::*[@xml:id = $cpInstructions.all/@cpMark.id and @xml:id = $cpMark.ids]"/>
                <xsl:variable name="local.cpInstructions" as="node()*">
                    <xsl:perform-sort select="$cpInstructions.all/descendant-or-self::*[@cpMark.id = $local.cpMarks/@xml:id]">
                        <xsl:sort select="@target.tstamp.first" data-type="number"/>
                        <xsl:sort select="@target.tstamp.last" data-type="number"/>
                    </xsl:perform-sort>
                </xsl:variable>
                
                <xsl:variable name="controlEvents" as="node()*">
                    <xsl:for-each select="$local.cpInstructions">
                        <xsl:variable name="pos" select="position()"/>
                        <xsl:variable name="current.cpInstruction" select="." as="node()"/>
                        <xsl:variable name="current.cpMark" select="$local.cpMarks[$pos]" as="node()"/>
                        
                        <xsl:variable name="current.measure" select="$music/id($current.cpInstruction/@sourceStaff.id)/ancestor::mei:measure"/>
                        <xsl:variable name="ce.onStaff" as="node()*">
                            <xsl:choose>
                                <xsl:when test="$current.cpMark/@ref.staff">
                                    <xsl:sequence select="$current.measure/mei:*[.//@staff = $current.cpMark/@ref.staff]"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:sequence select="$current.measure/mei:*[.//@staff = $current.cpMark/@staff]"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:variable>
                        <xsl:variable name="ce.onLayer" as="node()*">
                            <xsl:choose>
                                <xsl:when test="$current.cpMark/@ref.layer">
                                    <xsl:sequence select="$ce.onStaff/descendant-or-self::mei:*[parent::mei:measure and .//@layer = $current.cpMark/@ref.layer]"/>
                                </xsl:when>
                                <xsl:when test="$current.cpMark/@layer">
                                    <xsl:sequence select="$ce.onStaff/descendant-or-self::mei:*[parent::mei:measure and .//@layer = $current.cpMark/@layer]"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:sequence select="$ce.onStaff/descendant-or-self::mei:*[parent::mei:measure]"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:variable>
                        
                        <xsl:for-each select="$ce.onLayer/descendant-or-self::mei:*[parent::mei:measure and number(.//@tstamp) ge number($current.cpInstruction/@source.tstamp.first) and (not(starts-with((.//@tstamp2)[1],'0m+')) or number(substring-after((.//@tstamp2)[1],'m+')) le number($current.cpInstruction/@source.tstamp.last))
                            and not('cpMark' = descendant-or-self::mei:*/local-name())]">
                            <elem cpMark.id="{$current.cpMark/@xml:id}">
                                <xsl:sequence select="."/>
                            </elem>
                        </xsl:for-each>
                        
                        
                    </xsl:for-each>
                </xsl:variable>
                
                <!--<xsl:message select="string(count($controlEvents)) || ' controlEvents from cpMark #' || $cpMark/@xml:id"/>-->
                
                <xsl:if test="$mode = ('controlEvents','full')">
                    <xsl:for-each select="$controlEvents">
                        <!-- debug -->
                        <xsl:message select="'expanding controlEvent into ' || $target.measure/@xml:id"/>
                        <choice xmlns="http://www.music-encoding.org/ns/mei" xml:id="c{uuid:randomUUID()}">
                            <abbr type="cpMark"/>
                            <expan evidence="#{@cpMark.id}">
                                <xsl:choose>
                                    <xsl:when test="not(local-name(child::mei:*) = 'choice')">
                                        <xsl:apply-templates select="child::mei:*" mode="adjustMaterial"/>        
                                    </xsl:when>
                                    <xsl:when test="count(child::mei:choice/(mei:reg | mei:expan)) = 1">
                                        <xsl:apply-templates select="child::mei:choice/(mei:reg | mei:expan)/mei:*" mode="adjustMaterial"/>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <choice xmlns="http://www.music-encoding.org/ns/mei" xml:id="c{uuid:randomUUID()}">
                                            <xsl:apply-templates select="child::mei:choice/(mei:reg | mei:expan)" mode="adjustMaterial"/>
                                        </choice>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </expan>
                        </choice>    
                    </xsl:for-each>
                </xsl:if>
                
            </xsl:for-each>
            
        </xsl:copy>
    </xsl:template>
    
    <!-- if it is defined that only events before or after a certain tstamp should be considered, do the appropriate selection -->
    <!-- todo: is this required?? it seems to have the wrong mode! -->
    <xsl:template match="mei:*[@tstamp]" mode="resolveMarks">
        <xsl:param name="tstamp.before" tunnel="yes" as="xs:double?"/>
        <xsl:param name="tstamp.after" tunnel="yes" as="xs:double?"/>        
        <xsl:param name="tstamp.first" tunnel="yes" as="xs:double?"/>
        <xsl:param name="tstamp.last" tunnel="yes" as="xs:double?"/>
        
        <!--<xsl:if test="ancestor::mei:staff[@xml:id = 'A_mov6_measure78_s1']">
            <xsl:message select="'tstamp.before: ' || $tstamp.before || ', tstamp.after: ' || $tstamp.after || ', tstamp.first: ' || $tstamp.first || ', tstamp.last: ' || $tstamp.last || '(' || @xml:id || ')'"/>
        </xsl:if>-->
        
        <xsl:choose>
            <xsl:when test="not($tstamp.before or $tstamp.after or ($tstamp.first and $tstamp.last))">
                <xsl:next-match/>
            </xsl:when>
            <xsl:when test="exists($tstamp.after) and exists($tstamp.before) and number(@tstamp) gt $tstamp.after and number(@tstamp) lt $tstamp.before">
                <xsl:copy>
                    <xsl:apply-templates select="node() | @*" mode="#current"/>
                </xsl:copy>
            </xsl:when>
            <xsl:when test="exists($tstamp.before) and number(@tstamp) lt $tstamp.before and not($tstamp.after)">
                <xsl:copy>
                    <xsl:apply-templates select="node() | @*" mode="#current"/>
                </xsl:copy>
            </xsl:when>
            <xsl:when test="exists($tstamp.after) and number(@tstamp) gt $tstamp.after and not($tstamp.before)">
                <xsl:copy>
                    <xsl:apply-templates select="node() | @*" mode="#current"/>
                </xsl:copy>
            </xsl:when>
            <xsl:when test="exists($tstamp.first) and exists($tstamp.last) and number(@tstamp) ge $tstamp.first and number(@tstamp) le $tstamp.last">
                <xsl:copy>
                    <xsl:apply-templates select="node() | @*" mode="#current"/>
                </xsl:copy>
            </xsl:when>
            <xsl:otherwise/>
        </xsl:choose>
    </xsl:template>
    
    <!-- if it is defined that only events before or after a certain tstamp should be considered, check if the contents of a beam or tuplet match that -->
    <xsl:template match="mei:*[not(@tstamp) and .//@tstamp]" mode="resolveMarks">
        <xsl:param name="tstamp.before" tunnel="yes" as="xs:double?"/>
        <xsl:param name="tstamp.after" tunnel="yes" as="xs:double?"/>
        <xsl:param name="tstamp.first" tunnel="yes" as="xs:double?"/>
        <xsl:param name="tstamp.last" tunnel="yes" as="xs:double?"/>
        <xsl:choose>
            <xsl:when test="not($tstamp.before or $tstamp.after or ($tstamp.first and $tstamp.last))">
                <xsl:next-match/>
            </xsl:when>
            <xsl:when test="exists($tstamp.before) and exists($tstamp.after) 
                and (some $tstamp in .//@tstamp satisfies (number($tstamp) lt $tstamp.before)) 
                and (some $tstamp in .//@tstamp satisfies (number($tstamp) gt $tstamp.after))">
                <xsl:copy>
                    <xsl:apply-templates select="node() | @*" mode="#current"/>
                </xsl:copy>
            </xsl:when>
            <xsl:when test="exists($tstamp.before) and (some $tstamp in .//@tstamp satisfies (number($tstamp) lt $tstamp.before)) and not($tstamp.after)">
                <xsl:copy>
                    <xsl:apply-templates select="node() | @*" mode="#current"/>
                </xsl:copy>
            </xsl:when>
            <xsl:when test="exists($tstamp.after) and (some $tstamp in .//@tstamp satisfies (number($tstamp) gt $tstamp.after)) and not($tstamp.before)">
                <xsl:copy>
                    <xsl:apply-templates select="node() | @*" mode="#current"/>
                </xsl:copy>
            </xsl:when>
            <xsl:when test="exists($tstamp.first) and exists($tstamp.last) and (some $tstamp in .//@tstamp satisfies (number($tstamp) ge $tstamp.first) and number($tstamp) le $tstamp.last)">
                <xsl:copy>
                    <xsl:apply-templates select="node() | @*" mode="#current"/>
                </xsl:copy>
            </xsl:when>
            <xsl:otherwise/>
        </xsl:choose>
    </xsl:template>
    
    <!-- remove temporary attribute -->
    <xsl:template match="@stayWithMe" mode="cleanup"/>
        
    <!-- mode prepare.cpMarks -->
    <!-- this builds a list of targets that need to be filled -->
    <xsl:template match="mei:cpMark" mode="prepare.cpMarks">
        <xsl:variable name="cpMark" select="." as="node()"/>
        <xsl:variable name="origin.measure" select="ancestor::mei:measure" as="node()"/>
        <xsl:variable name="origin.measure.meter.count" select="$origin.measure/@meter.count" as="xs:string"/>
        <xsl:variable name="staff.n" select="@staff" as="xs:string"/>
        <xsl:variable name="origin.staff" select="$origin.measure/mei:staff[@n = $staff.n]" as="node()"/>
        <xsl:choose>
            
            <!--<xsl:when test="@tstamp2 = ('0m+' || $origin.measure.meter.count) and @ref.offset = '-1m+1' and not(@ref.staff) and ($origin.staff//mei:mRpt or $origin.staff//mei:mSpace)">-->
            <xsl:when test="@tstamp = '1' and (@tstamp2 = ('0m+' || max($origin.staff//@tstamp/number(.))) or @tstamp2 = ('0m+' || number($origin.measure.meter.count))) and @ref.offset = '-1m+1' and not(@ref.staff) and ($origin.staff//mei:mRpt or $origin.staff//mei:mSpace)">
                <!-- this is a mRpt and already covered as such -->
                <!--<xsl:message select="'cpMark equals mRpt: ' || @freidi.measure || '_' || $staff.n"/>-->
            </xsl:when>
            <!--<xsl:when test="@tstamp2 = ('0m+' || $origin.measure.meter.count) and @ref.offset = '-1m+1' and not(@ref.staff) and $origin.staff//mei:mSpace">
                <!-\- this is an mSpace serving as mRpt and already covered as such -\->
            </xsl:when>-->
            <xsl:when test="@ref.offset and not(@ref.staff)">
                <!-- This cpMark is a copy instruction from preceding measures -->
                <xsl:variable name="measure.count" select="number(substring-before(@tstamp2,'m+')) cast as xs:integer" as="xs:integer"/>
                <xsl:variable name="final.measure" select="if($measure.count gt 0) then($origin.measure/following::mei:measure[$measure.count]) else($origin.measure)" as="node()"/>
                <xsl:variable name="final.measure.meter.count" select="$final.measure/@meter.count" as="xs:string"/>
                <xsl:variable name="measure.offset" select="number(substring-before(@ref.offset,'m+')) cast as xs:integer" as="xs:integer"/>
                <xsl:variable name="offset.dir" select="if($measure.offset lt 0) then('preceding') else('following')" as="xs:string"/>
                <xsl:variable name="offset.dist" select="if($measure.offset lt 0) then($measure.offset * -1) else($measure.offset)" as="xs:integer"/>
                <xsl:variable name="offset.startMeasure" as="node()">
                    <xsl:choose>
                        <xsl:when test="$offset.dist = 0">
                            <xsl:sequence select="$origin.measure"/>
                        </xsl:when>
                        <xsl:when test="$offset.dir = 'preceding'">
                            <xsl:sequence select="$origin.measure/preceding::mei:measure[$offset.dist]"/>
                        </xsl:when>
                        <xsl:when test="$offset.dir = 'following'">
                            <xsl:sequence select="$origin.measure/following::mei:measure[$offset.dist]"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:message terminate="yes">Houston…</xsl:message>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                        
                <xsl:variable name="first.targetMeasure" select="$origin.measure" as="node()"/>
                <xsl:variable name="first.targetStaff" select="$first.targetMeasure/mei:staff[@n = $staff.n]" as="node()"/>
                
                <xsl:variable name="first.sourceMeasure" select="$offset.startMeasure" as="node()"/>
                <xsl:variable name="first.sourceStaff" select="$first.sourceMeasure/mei:staff[@n = $staff.n]" as="node()"/>
                
                <xsl:variable name="first.target.tstamp.last" select="if($measure.count = 0) 
                    then(number(substring-after($cpMark/@tstamp2,'m+'))) 
                    else(number($first.targetMeasure/@meter.count) + 1)" as="xs:double"/>
                <xsl:variable name="first.source.tstamp.last" select="if(number(substring-before($cpMark/@ref.offset2,'m+')) = 0) 
                    then(number(substring-after($cpMark/@ref.offset2,'m+'))) 
                    else(number($first.sourceMeasure/@meter.count) + 1)" as="xs:double"/>                
                
                <copy targetStaff.id="{$first.targetStaff/@xml:id}" 
                    sourceStaff.id="{$first.sourceStaff/@xml:id}" 
                    cpMark.id="{$cpMark/@xml:id}"
                    target.tstamp.first="{$cpMark/@tstamp}"
                    target.tstamp.last="{$first.target.tstamp.last}"
                    source.tstamp.first="{substring-after($cpMark/@ref.offset,'m+')}"
                    source.tstamp.last="{$first.source.tstamp.last}"/>
                
                <xsl:if test="$measure.count gt 0">
                    <xsl:for-each select="(1 to $measure.count)">
                        <xsl:variable name="i" select="." as="xs:integer"/>
                        <xsl:variable name="targetMeasure" select="$first.targetMeasure/following::mei:measure[$i]" as="node()"/>
                        <xsl:variable name="targetStaff" select="$targetMeasure/mei:staff[@n = $staff.n]" as="node()"/>
                        
                        <xsl:variable name="sourceMeasure" select="($first.sourceMeasure/following::mei:measure)[$i]" as="node()"/>
                        <xsl:variable name="sourceStaff" select="$sourceMeasure/mei:staff[@n = $staff.n]" as="node()"/>
                        
                        <!-- hier noch den richtigen Takt fischen, um passende tstamps zu erhalten -->
                        <xsl:variable name="target.tstamp.last" select="if($i = $measure.count) 
                            then(number(substring-after($cpMark/@tstamp2,'m+'))) 
                            else(number($targetMeasure/@meter.count) + 1)" as="xs:double"/>
                        <xsl:variable name="source.tstamp.last" select="if($i = $measure.count) 
                            then(number(substring-after($cpMark/@ref.offset2,'m+'))) 
                            else(number($sourceMeasure/@meter.count) + 1)" as="xs:double"/>
                        
                        <copy targetStaff.id="{$targetStaff/@xml:id}" 
                            sourceStaff.id="{$sourceStaff/@xml:id}" 
                            cpMark.id="{$cpMark/@xml:id}"
                            target.tstamp.first="1"
                            target.tstamp.last="{$target.tstamp.last}"
                            source.tstamp.first="1"
                            source.tstamp.last="{$source.tstamp.last}"/>
                    </xsl:for-each>
                </xsl:if>
            </xsl:when>
            <xsl:when test="not(@ref.offset) and @ref.staff">
                <!-- This cpMark is a colla parte instruction -->
                <xsl:variable name="measure.count" select="number(substring-before(@tstamp2,'m+')) cast as xs:integer" as="xs:integer"/>
                
                <xsl:variable name="first.targetMeasure" select="$origin.measure"/>
                <xsl:variable name="first.targetStaff" select="$first.targetMeasure/mei:staff[@n = $staff.n]"/>
                <xsl:variable name="target.tstamp.last" select="if($measure.count = 0) then(substring-after($cpMark/@tstamp2,'m+')) else(number($first.targetMeasure/@meter.count) + 1)"/>
                
                <xsl:variable name="first.target.tstamp.last" select="if($measure.count = 0) 
                    then(number(substring-after($cpMark/@tstamp2,'m+'))) 
                    else(number($first.targetMeasure/@meter.count) + 1)" as="xs:double"/>
                                
                <copy targetStaff.id="{$first.targetStaff/@xml:id}" 
                    sourceStaff.id="{$first.targetMeasure/mei:staff[@n = $cpMark/@ref.staff]/@xml:id}" 
                    cpMark.id="{$cpMark/@xml:id}"
                    target.tstamp.first="{$cpMark/@tstamp}"
                    target.tstamp.last="{$target.tstamp.last}"
                    source.tstamp.first="{$cpMark/@tstamp}"
                    source.tstamp.last="{$target.tstamp.last}"/>
                
                <xsl:if test="$measure.count gt 0">
                    <xsl:for-each select="(1 to $measure.count)">
                        <xsl:variable name="i" select="."/>
                        <xsl:variable name="targetMeasure" select="$origin.measure/following::mei:measure[$i]"/>
                        <xsl:variable name="targetStaff" select="$targetMeasure/mei:staff[@n = $staff.n]"/>
                        
                        <xsl:variable name="sourceStaff" select="$targetMeasure/mei:staff[@n = $cpMark/@ref.staff]"/>
                        <xsl:variable name="tstamp.last" select="if($i = $measure.count) then(substring-after($cpMark/@tstamp2,'m+')) else(number($targetMeasure/@meter.count) + 1)"/>
                        
                        <copy targetStaff.id="{$targetStaff/@xml:id}" 
                            sourceStaff.id="{$sourceStaff/@xml:id}" 
                            cpMark.id="{$cpMark/@xml:id}"
                            target.tstamp.first="1"
                            target.tstamp.last="{$tstamp.last}"
                            source.tstamp.first="1"
                            source.tstamp.last="{$tstamp.last}"/>
                    </xsl:for-each>
                </xsl:if>
                
            </xsl:when>
            <xsl:when test="@ref.staff and @ref.offset">
                <!-- This cpMark is strange and should not exist in the Freischütz -->
                <xsl:message select="'cpMark ' || $cpMark/@xml:id || ' is strange and should not be available in Freischütz. It copies music from a previous measure and a different staff…'"/>
            </xsl:when>
        </xsl:choose>
    </xsl:template>
    
    <!-- mode cleanup -->
    <xsl:template match="mei:abbr/@tstamp" mode="cleanup"/>
    <xsl:template match="mei:abbr/@tstamp2" mode="cleanup"/>
    <xsl:template match="mei:expan/@evidence" mode="cleanup">
        <xsl:attribute name="evidence" select="replace(.,'#','')"/>
    </xsl:template>
    <xsl:template match="mei:measure/@meter.count" mode="cleanup"/>
    <xsl:template match="mei:layer[not(@n) and following-sibling::mei:layer/@n = '2']" mode="cleanup">
        <xsl:copy>
            <xsl:attribute name="n" select="1"/>
            <xsl:apply-templates select="node() | @*" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="node() | @*" mode="#all">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
</xsl:stylesheet>