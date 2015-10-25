<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    xmlns:mei="http://www.music-encoding.org/ns/mei"
    xmlns:uuid="java:java.util.UUID"
    xmlns:local="local"
    exclude-result-prefixes="xs math xd mei uuid local"
    version="3.0">
    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p><xd:b>Created on:</xd:b> Oct 15, 2015</xd:p>
            <xd:p><xd:b>Author:</xd:b> Johannes Kepper</xd:p>
            <xd:p>
                To be applied to the music doc
            </xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:output method="xml" indent="yes"/>
    
    <xsl:param name="source.id" select="'A'" as="xs:string"/>
    <xsl:param name="mov.n" select="'2'" as="xs:string"/>
    
    <xsl:variable name="mov.id" select="$source.id || '_mov' || $mov.n" as="xs:string"/>
    <xsl:variable name="repo.path" select="substring-before(document-uri(),'sourcePrep') || 'sourcePrep/'" as="xs:string"/>
    
    <xsl:variable name="eo.file.prefix" select="'freidi-musicSource_'" as="xs:string"/>
    <xsl:variable name="eo.file.fullpath" select="$repo.path || '00%20measure%20positions/' || $eo.file.prefix || $source.id || '.xml'" as="xs:string"/>
    
    <xsl:variable name="eo.file.available" select="doc-available($eo.file.fullpath)" as="xs:boolean"/>
    <xsl:variable name="musicDoc.correctSourceID" select="boolean(/mei:mei/@xml:id = $source.id)" as="xs:boolean"/>
    
    <xsl:variable name="music.file" select="/mei:mei" as="node()"/>
    <xsl:variable name="eo.file" select="doc($eo.file.fullpath)/mei:mei" as="node()?"/>
    
    <xsl:variable name="eo.mov" select="$eo.file//mei:mdiv[@xml:id = $music.file//mei:mdiv/@xml:id]" as="node()?"/>
    <xsl:variable name="eo.measures" select="$eo.mov//mei:measure" as="node()*"/>
    <xsl:variable name="eo.pages" select="$eo.file//mei:surface[.//mei:zone[replace(@data,'#','') = $eo.measures/@xml:id]]" as="node()*"/>
    
    <xsl:variable name="cpMarks.path" select="substring-before(document-uri(),'/musicSources/') || '/musicSources/sourcePrep/11.1%20ShortcutList/cpMarks.xml'" as="xs:string"/>
    <xsl:variable name="cpMarks.raw" select="doc($cpMarks.path)//mei:cpMark" as="node()*"/>
    
    <xsl:template match="/">
        <xsl:message select="'Opening file ' || $eo.file.prefix || '.xml'"/>
        <xsl:if test="not($eo.file.available) or not($eo.file)">
            <xsl:message terminate="yes" select="'ERROR: Could not open file ' || $eo.file.fullpath || '. Processing terminated.'"/>
        </xsl:if>
        <xsl:if test="not($musicDoc.correctSourceID)">
            <xsl:message terminate="yes" select="'ERROR: Something is wrong with the source ID. Mismatch between $source.id param and @xml:id in musicDoc. Processing terminated.'"/>
        </xsl:if>
        <xsl:if test="not($eo.mov)">
            <xsl:message terminate="yes" select="'ERROR: Could not retrieve the right mdiv (@xml:id = ' || $music.file//mei:mdiv/@xml:id || ') in eo file. Processing terminated.'"/>
        </xsl:if>
        <xsl:if test="$music.file//mei:tupletSpan">
            <xsl:message terminate="yes" select="'ERROR: Spotted tupletSpans in source file. Please resolve them before processing!'"/>
        </xsl:if>
        <xsl:if test="count($cpMarks.raw) = 0">
            <xsl:message terminate="yes" select="'ERROR: Unable to reach cpMarks from ' || $cpMarks.path || '. Processing terminated.'"/>
        </xsl:if>
        
        
        <xsl:variable name="music.included" as="node()">
            <xsl:message select="'INFO: Including music…'"/>
            <xsl:apply-templates select="$eo.file" mode="include.music"/>
        </xsl:variable>
        
        <xsl:variable name="music.included.clean" as="node()">
            <xsl:message select="'INFO: Cleaning music…'"/>
            <xsl:apply-templates select="$music.included" mode="include.music.clean"/>
        </xsl:variable>
        
        <xsl:variable name="added.tstamps" as="node()">
            <xsl:message select="'INFO: Adding tstamps…'"/>
            <xsl:apply-templates select="$music.included.clean" mode="tstamps"/>
        </xsl:variable>
        
        <xsl:variable name="included.cpMarks" as="node()">
            <xsl:message select="'INFO: Including cpMarks…'"/>
            <xsl:apply-templates select="$added.tstamps" mode="include.cpMarks"/>
        </xsl:variable>
        
        <xsl:variable name="cpMarks" select="$included.cpMarks//mei:cpMark" as="node()*"/>
        <xsl:variable name="cpInstructions" as="node()*">
            <xsl:apply-templates select="$included.cpMarks//mei:cpMark" mode="prepare.cpMarks"/>
        </xsl:variable>
        
        <xsl:variable name="cpInstructions.first" select="distinct-values($cpInstructions/descendant-or-self::copy[@cpMark.id = $cpMarks[@type = 'mRpt']/@xml:id]/@cpMark.id)" as="xs:string*"/>
        <xsl:variable name="cpInstructions.second" select="distinct-values($cpInstructions/descendant-or-self::copy[@cpMark.id = $cpMarks[@type = 'cpInstruction']/@xml:id]/@cpMark.id)" as="xs:string*"/>
        <xsl:variable name="cpInstructions.third" select="distinct-values($cpInstructions/descendant-or-self::copy[@cpMark.id = $cpMarks[@type = 'collaParte']/@xml:id]/@cpMark.id)" as="xs:string*"/>
        
        <xsl:message select="'    cpMarks of type mRpt: ' || count($cpInstructions.first)"/>
        <xsl:message select="'    cpMarks with other horizontal copy instructions: ' || count($cpInstructions.second)"/>
        <xsl:message select="'    cpMarks of type colla parte: ' || count($cpInstructions.third)"/>
        
        <xsl:variable name="resolved.trems" as="node()">
            <xsl:message select="'INFO: Resolving tremolos…'"/>
            <xsl:apply-templates select="$included.cpMarks" mode="resolve.trems">
                <xsl:with-param name="music.file.expan" select="$included.cpMarks" tunnel="yes" as="node()"/>
            </xsl:apply-templates>
        </xsl:variable>
        
        <xsl:variable name="resolved.rpts" as="node()">
            <xsl:message select="'INFO: Resolving rpts…'"/>
            <xsl:apply-templates select="$resolved.trems" mode="resolve.marks">
                <xsl:with-param name="material" select="$resolved.trems" tunnel="yes" as="node()"/>
                <xsl:with-param name="cpInstructions" select="$cpInstructions" tunnel="yes" as="node()*"/>
                <xsl:with-param name="cpMarks.enhanced" select="$cpMarks" tunnel="yes" as="node()*"/>
                <xsl:with-param name="cpMark.ids" select="$cpInstructions.first" tunnel="yes" as="xs:string*"/>
                <xsl:with-param name="mode" select="'mRpt'" tunnel="yes" as="xs:string"/>
            </xsl:apply-templates>
        </xsl:variable>
        
        <xsl:variable name="resolved.instructions" as="node()">
            <xsl:message select="'INFO: Resolving cpInstructions…'"/>
            <xsl:apply-templates select="$resolved.rpts" mode="resolve.marks">
                <xsl:with-param name="material" select="$resolved.rpts" tunnel="yes" as="node()"/>
                <xsl:with-param name="cpInstructions" select="$cpInstructions" tunnel="yes" as="node()*"/>
                <xsl:with-param name="cpMarks.enhanced" select="$cpMarks" tunnel="yes" as="node()*"/>
                <xsl:with-param name="cpMark.ids" select="$cpInstructions.second" tunnel="yes" as="xs:string*"/>
                <xsl:with-param name="mode" select="'cpInstruction'" tunnel="yes" as="xs:string"/>
            </xsl:apply-templates>
        </xsl:variable>
        
        <xsl:variable name="resolved.collaParte" as="node()">
            <xsl:message select="'INFO: Resolving colla parte instructions…'"/>
            <xsl:apply-templates select="$resolved.instructions" mode="resolve.marks">
                <xsl:with-param name="material" select="$resolved.instructions" tunnel="yes" as="node()"/>
                <xsl:with-param name="cpInstructions" select="$cpInstructions" tunnel="yes" as="node()*"/>
                <xsl:with-param name="cpMarks.enhanced" select="$cpMarks" tunnel="yes" as="node()*"/>
                <xsl:with-param name="cpMark.ids" select="$cpInstructions.third" tunnel="yes" as="xs:string*"/>
                <xsl:with-param name="mode" select="'collaParte'" tunnel="yes" as="xs:string"/>
            </xsl:apply-templates>
        </xsl:variable>
        
        <xsl:variable name="shortcuts.cleaned" as="node()">
            <xsl:message select="'INFO: Cleaning up shortcuts…'"/>
            <xsl:apply-templates select="$resolved.collaParte" mode="shortCut.cleanup"/>
        </xsl:variable>
        
        <xsl:variable name="added.accid.ges" as="node()">
            <xsl:message select="'INFO: Fixing @accid.ges…'"/>
            <xsl:apply-templates select="$shortcuts.cleaned" mode="addAccid.ges"/>
        </xsl:variable>
        
        <xsl:variable name="final.cleanup" as="node()">
            <xsl:message select="'INFO: doing some cleanup…'"/>
            <xsl:apply-templates select="$added.accid.ges" mode="final.cleanup"/>
        </xsl:variable>
        
        <!-- file for folder 12 -->
        <xsl:result-document href="{$repo.path || '12%20Proven%20ControlEvents/' || $source.id || '/' || $source.id || '_mov' || $mov.n || '.xml'}">
            <xsl:copy-of select="$final.cleanup"/>    
        </xsl:result-document>
        
        <xsl:variable name="core.draft" as="node()">
            <xsl:message select="'INFO: preparing core draft…'"/>
            <xsl:apply-templates select="$final.cleanup" mode="coreDraft"/>
        </xsl:variable>
        
        <xsl:result-document href="{$repo.path || '14%20reCored/' || $source.id || '/' || $mov.id || '.xml'}">
            <xsl:message select="'INFO: generating source file…'"/>
            <xsl:apply-templates select="$final.cleanup" mode="source">
                <xsl:with-param name="coreDraft" select="$core.draft" tunnel="yes"/>
            </xsl:apply-templates>
        </xsl:result-document>
        
        <xsl:result-document href="{$repo.path || '14%20reCored/core_mov' || $mov.n || '.xml'}">
            <xsl:message select="'INFO: generating core file…'"/>
            <xsl:apply-templates select="$core.draft" mode="core">
                <xsl:with-param name="coreDraft" select="$core.draft" tunnel="yes"/>
            </xsl:apply-templates>
        </xsl:result-document>
        
        <xsl:message select="'INFO: Processing completed. ' || $mov.id || ' is now finished.'"/>
        
    </xsl:template>
    
    <!-- mode include.music -->
    <xsl:template match="mei:mdiv" mode="include.music">
        <!-- keep only the relevant mdiv -->
        <xsl:if test="@xml:id = $eo.mov/@xml:id">
            <xsl:next-match/>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="mei:surface" mode="include.music">
        <!-- keep only relevant pages -->
        <xsl:if test="@xml:id = $eo.pages/@xml:id">
            <xsl:next-match/>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="mei:score" mode="include.music">
        <xsl:copy>
            <xsl:apply-templates select="@*" mode="#current"/>
            <xsl:apply-templates select="($music.file//mei:score/mei:scoreDef)[1]" mode="#current"/>
            <xsl:apply-templates select="node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="mei:measure" mode="include.music">
        <!-- issue warning if measure is split across systems or pages -->
        <xsl:if test="@join">
            <xsl:message select="'WARNING: measure ' || @xml:id || ' has a @join attribute and may cause problems during processing. Please check the results!'"/>
        </xsl:if>
        
        <xsl:variable name="measure.n" select="@n" as="xs:string"/>
        <xsl:variable name="music.measure" select="$music.file//mei:measure[@n = $measure.n]" as="node()"/>
            
            
        <xsl:if test="local-name($music.measure/preceding-sibling::mei:*[1]) = 'scoreDef'">
            <xsl:apply-templates select="$music.measure/preceding-sibling::mei:scoreDef[1]" mode="#current"/>
        </xsl:if>    
        <!-- copy measure and it's attributes -->
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:apply-templates select="$music.measure/mei:*" mode="#current">
                <xsl:with-param name="measure.id" select="@xml:id" tunnel="yes" as="xs:string"/>
            </xsl:apply-templates>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="mei:staff" mode="include.music">
        <xsl:param name="measure.id" tunnel="yes" as="xs:string"/>
        <xsl:copy>
            <xsl:attribute name="xml:id" select="$measure.id || '_s' || @n"/>
            <xsl:apply-templates select="node() | (@* except @xml:id)" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="mei:mdiv//@xml:id" mode="include.music">
        <xsl:choose>
            <xsl:when test="parent::mei:measure">
                <xsl:next-match/>
            </xsl:when>
            <xsl:when test="parent::mei:staffDef"/>
            <xsl:when test="parent::mei:staffGrp"/>
            <xsl:otherwise>
                <xsl:attribute name="xml:id" select="'im' || uuid:randomUUID()"/>
                <xsl:attribute name="old.id" select="."/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="mei:zone[@type = 'measure']" mode="include.music">
        <!-- first, keep original measure zone -->
        <xsl:next-match/>
        
        <!-- get corresponding measure -->
        <xsl:variable name="measure.zone" select="." as="node()"/>
        <xsl:variable name="measure" select="$eo.measures[@xml:id = $measure.zone/replace(@data,'#','')]" as="node()"/>
        <xsl:variable name="music.measure" select="$music.file//mei:measure[@n = $measure/@n]"/>
        
        <xsl:variable name="ulx" select="@ulx" as="xs:integer"/>
        <xsl:variable name="uly" select="@uly" as="xs:integer"/>
        <xsl:variable name="lrx" select="@lrx" as="xs:integer"/>
        <xsl:variable name="lry" select="@lry" as="xs:integer"/>
        
        <xsl:variable name="staffCount" select="if(count($measure/mei:staff) gt 0) then(count($measure/mei:staff)) else(1)" as="xs:integer"/>
        
        <xsl:variable name="normHeight" select="round(($lry - $uly) div $staffCount) cast as xs:integer" as="xs:integer"/>
        <xsl:variable name="margin" select="round($normHeight div 4) cast as xs:integer" as="xs:integer"/>
        <!-- create a new zone for each staff -->
        <xsl:for-each select="$music.measure/mei:staff">
            
            <xsl:variable name="staff.n" select="@n"/>
            <xsl:variable name="staff.zone.id" select="$measure.zone/@xml:id || '_s' || $staff.n"/>
            <xsl:variable name="pos" select="position()" as="xs:integer" />
            
            <xsl:element name="zone" namespace="http://www.music-encoding.org/ns/mei">
                <xsl:attribute name="xml:id" select="$staff.zone.id"/>
                <xsl:attribute name="type" select="'staff'"/>
                <xsl:attribute name="ulx" select="$ulx"/>
                <xsl:attribute name="uly">
                    <xsl:choose>
                        <xsl:when test="$pos = 1">
                            <xsl:value-of select="$uly"/>
                        </xsl:when>
                        <xsl:when test="$pos = $staffCount">
                            <xsl:value-of select="$lry - $normHeight - round($margin * 1.3)"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="$uly + (($pos - 1) * $normHeight) - $margin"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:attribute>
                <xsl:attribute name="lrx" select="$lrx"/>
                <xsl:attribute name="lry">
                    <xsl:choose>
                        <xsl:when test="$pos = 1">
                            <xsl:value-of select="$uly + $normHeight + round($margin * 1.3)"/>
                        </xsl:when>
                        <xsl:when test="$pos = $staffCount">
                            <xsl:value-of select="$lry"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="$uly + ($pos * $normHeight) + $margin"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:attribute>
                <xsl:attribute name="data" select="$measure.zone/@data || '_s' || $staff.n"/>
            </xsl:element>
        </xsl:for-each>
        
    </xsl:template>
    
    <xsl:template match="mei:appInfo" mode="include.music">
        <xsl:copy>
            <xsl:apply-templates select="($music.file//mei:application | $eo.file//mei:application)[not(@xml:id = ('includeMusic2source.xsl'))]" mode="#current"/>
            <application xmlns="http://www.music-encoding.org/ns/mei" xml:id="core_directSetup.xsl">
                <name>core_directSetup.xsl</name>
                <xsl:comment>This stylesheet takes a music file and automatically generates an MEI file following the Freischütz Digital data model. It short-circuits the whole proof-reading process and assumes that everything has been corrected in Finale already.</xsl:comment>
                <ptr target="https://github.com/Freischuetz-Digital/Tools/blob/develop/100%20manual%20tools/core_directSetup.xsl"/>
            </application>
            <application xmlns="http://www.music-encoding.org/ns/mei" xml:id="addIDs_and_tstamps" version="1.0">
                <name>addIDs_and_tstamps.xsl</name>
                <xsl:comment>Actually, a version of addIDs_and_tstamps.xsl has been integrated into core_directSetup.xsl.</xsl:comment>
                <ptr target="https://github.com/Freischuetz-Digital/Tools/blob/develop/09.1%20Add%20IDs%20and%20Tstamps/addIDs_and_tstamps.xsl"/>
            </application>
            <application xmlns="http://www.music-encoding.org/ns/mei" xml:id="resolveShortCuts.xsl_v1.0.0" version="1.0.0">
                <name>resolveShortCuts.xsl</name>
                <xsl:comment>Actually, a special version of resolveShortCuts.xsl has been integrated into core_directSetup.xsl. This version doesn't resolve shortcuts, but includes them in the music file, so it's just the opposite direction.</xsl:comment>
                <ptr target="https://github.com/Freischuetz-Digital/Tools/blob/develop/12.1%20resolve%20ShortCuts/resolveShortCuts.xsl"/>
            </application>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="@meiversion.num" mode="include.music">
        <xsl:attribute name="meiversion.num" select="'2.1.1'"/>
    </xsl:template>
    <xsl:template match="@dur.ges" mode="include.music"/>
    <xsl:template match="@midi.channel" mode="include.music"/>
    <xsl:template match="@midi.instrnum" mode="include.music"/>
    <xsl:template match="mei:instrDef" mode="include.music"/>
    <xsl:template match="mei:measure/@width" mode="include.music"/>
    <xsl:template match="@page.height" mode="include.music"/>
    <xsl:template match="@page.width" mode="include.music"/>
    <xsl:template match="@page.leftmar" mode="include.music"/>
    <xsl:template match="@page.rightmar" mode="include.music"/>
    <xsl:template match="@page.topmar" mode="include.music"/>
    <xsl:template match="@page.botmar" mode="include.music"/>
    <xsl:template match="@system.topmar" mode="include.music"/>
    <xsl:template match="@system.leftmar" mode="include.music"/>
    <xsl:template match="@system.rightmar" mode="include.music"/>
    <xsl:template match="@ppq" mode="include.music"/>
    <xsl:template match="@spacing" mode="include.music"/>
    <xsl:template match="@spacing.system" mode="include.music"/>
    <xsl:template match="@spacing.staff" mode="include.music"/>
    <xsl:template match="@page.units" mode="include.music"/>
    <xsl:template match="@page.scale" mode="include.music"/>
    <xsl:template match="@music.name" mode="include.music"/>
    <xsl:template match="@music.size" mode="include.music"/>
    <xsl:template match="@text.name" mode="include.music"/>
    <xsl:template match="@text.size" mode="include.music"/>
    <xsl:template match="@lyric.name" mode="include.music"/>
    <xsl:template match="@lyric.size" mode="include.music"/>
    <xsl:template match="@fontsize" mode="include.music"/>
    <xsl:template match="mei:accid" mode="include.music"/>
    <xsl:template match="mei:artic" mode="include.music"/>
    <xsl:template match="@stem.y" mode="include.music"/>
    <xsl:template match="@opening" mode="include.music"/>
    <xsl:template match="mei:dynam/text()" mode="include.music">
        <xsl:value-of select="replace(.,'(^\s+)|(\s+$)','')"></xsl:value-of>
    </xsl:template>
    <xsl:template match="mei:slur/@tstamp" mode="include.music"/>
    <xsl:template match="mei:slur/@tstamp2" mode="include.music"/>
    <xsl:template match="@startto" mode="include.music"/>
    <xsl:template match="@endto" mode="include.music"/>
    <xsl:template match="@ho" mode="include.music"/>
    <xsl:template match="@vo" mode="include.music"/>
    <xsl:template match="mei:change/@n" mode="include.music"/>
    <xsl:template match="mei:tempo" mode="include.music"/>
    <xsl:template match="mei:fermata" mode="include.music"/>
    <xsl:template match="mei:dir/@label" mode="include.music"/>
    <xsl:template match="mei:dynam/@label" mode="include.music"/>
    <xsl:template match="mei:hairpin/@endid" mode="include.music"/>
    
    <xsl:template match="mei:revisionDesc" mode="include.music">
        <xsl:copy>
            <xsl:apply-templates select="$music.file//mei:change" mode="#current"/>
            <xsl:apply-templates select="$eo.file//mei:change[not(.//mei:ref[@target = '#includeMusic2source.xsl'])]" mode="#current"/>
            <change xmlns="http://www.music-encoding.org/ns/mei">
                <respStmt>
                    <persName>Johannes Kepper</persName>    
                </respStmt>
                <changeDesc>
                    <p>Merged Edirom Online encoding and polished Finale file to reflect the Freischütz Digital data model using <ref target="#core_directSetup.xsl">core_directSetup.xsl</ref>.</p>
                </changeDesc>
                <date isodate="{substring(string(current-date()),1,10)}"/>
            </change>
            <change xmlns="http://www.music-encoding.org/ns/mei">
                <respStmt>
                    <persName>Johannes Kepper</persName>
                </respStmt>
                <changeDesc>
                    <p>Automatically added @xml:ids (for notes added during proofreading of pitches) and tstamps for all events to prepare for proofreading of controlevents. Done by running <ref target="#addIDs_and_tstamps">addIDs_and_tstamps.xsl</ref>, version 1.0.</p>
                </changeDesc>
                <date isodate="{substring(string(current-date()),1,10)}"/>
            </change>
            <change xmlns="http://www.music-encoding.org/ns/mei">
                <respStmt>
                    <persName>Johannes Kepper</persName>
                </respStmt>
                <changeDesc>
                    <p>
                        Included colla parte and copy instructions for events by using information from <xsl:value-of select="$cpMarks.path"/> using <ptr target="resolveShortCuts.xsl_v1.0.0"/>. Also resolved all mRpt, bTrems and fTrems.
                    </p>
                </changeDesc>   
                <date isodate="{substring(string(current-date()),1,10)}"/>
            </change>
        </xsl:copy>
    </xsl:template>
    
    <!-- mode include.music.clean -->
    
    <xsl:template match="mei:change" mode="include.music.clean">
        <xsl:copy>
            <xsl:attribute name="n" select="count(preceding-sibling::mei:change) + 1"/>
            <xsl:apply-templates select="node() | @*" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="@startid" mode="include.music.clean">
        <xsl:variable name="old.start" select="replace(.,'#','')" as="xs:string"/>
        <xsl:variable name="target" select="ancestor::mei:mdiv//mei:*[@old.id = $old.start]" as="node()*"/>
        <xsl:if test="not($target)">
            <xsl:message terminate="yes" select="'ERROR: unable to identify element ' || $old.start || ', which is referenced from a @startid in measure ' || ancestor::mei:measure/@n || '. Processing terminated.'"/>
        </xsl:if>
        <xsl:if test="count($target) gt 1">
            <xsl:message terminate="no" select="'WARNING: multiple targets with ' || $old.start || ', which are referenced from a @startid in measure ' || ancestor::mei:measure/@n || '. Processing terminated.'"/>
            <xsl:for-each select="$target">
                <xsl:variable name="current.target" select="." as="node()"/>
                <xsl:message select="'   DEBUG: ' || local-name($current.target) || ' @id=' || $current.target/@old.id || ' in ' || string-join($current.target/ancestor-or-self::mei:*/concat(local-name(),'[',count(preceding-sibling::mei:*) +1,']'),'/')"/>
            </xsl:for-each>            
        </xsl:if>        
        <xsl:attribute name="startid" select="'#' || $target[1]/@xml:id"/>
    </xsl:template>
    
    <xsl:template match="@endid" mode="include.music.clean">
        <xsl:variable name="old.end" select="replace(.,'#','')" as="xs:string"/>
        <xsl:variable name="target" select="ancestor::mei:mdiv//mei:*[@old.id = $old.end]" as="node()*"/>
        <xsl:if test="not($target)">
            <xsl:message terminate="yes" select="'ERROR: unable to identify element ' || $old.end || ', which is referenced from a @startid in measure ' || ancestor::mei:measure/@n || '. Processing terminated.'"/>
        </xsl:if>
        <xsl:if test="count($target) gt 1">
            <xsl:message terminate="no" select="'WARNING: multiple targets with ' || $old.end || ', which are referenced from a @endid in measure ' || ancestor::mei:measure/@n || '. Processing terminated.'"/>
            <xsl:for-each select="$target">
                <xsl:variable name="current.target" select="." as="node()"/>
                <xsl:message select="'   DEBUG: ' || local-name($current.target) || ' @id=' || $current.target/@old.id || ' in ' || string-join($current.target/ancestor-or-self::mei:*/concat(local-name(),'[',count(preceding-sibling::mei:*) +1,']'),'/')"/>
            </xsl:for-each>            
        </xsl:if>      
        <xsl:attribute name="endid" select="'#' || $target[1]/@xml:id"/>
    </xsl:template>
    
    <xsl:template match="@old.id" mode="include.music.clean"/>
    
    <xsl:template match="mei:measure//mei:*[not(@xml:id)]" mode="include.music.clean">
        <xsl:copy>
            <xsl:attribute name="xml:id" select="'x' || uuid:randomUUID()"/>
            <xsl:apply-templates select="node() | @*" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <!-- mode tstamp.events -->
    
    <xsl:template match="mei:measure" mode="tstamps">
        <xsl:if test="not((preceding::mei:scoreDef[@meter.count])[1]/@meter.count)">
            <xsl:message select="'unable to get scoreDef from ' || @xml:id"/>
            <xsl:message select="(preceding::mei:scoreDef[@meter.count])[1]"/>
        </xsl:if>
        <xsl:variable name="meter.count" select="(preceding::mei:scoreDef[@meter.count])[1]/@meter.count cast as xs:integer" as="xs:integer"/>
        <xsl:variable name="meter.unit" select="(preceding::mei:scoreDef[@meter.unit])[1]/@meter.unit cast as xs:integer" as="xs:integer"/>
        
        <xsl:copy>
            <xsl:apply-templates select="node() | @*" mode="#current">
                <xsl:with-param name="meter.count" select="$meter.count" tunnel="yes"/>
                <xsl:with-param name="meter.unit" select="$meter.unit" tunnel="yes"/>
            </xsl:apply-templates>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="mei:layer" mode="tstamps">
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
    
    <xsl:template match="mei:layer//mei:*[(@dur and not((ancestor::mei:*[@dur] or ancestor::mei:bTrem or ancestor::mei:fTrem)) and not(@grace)) or (local-name() = ('bTrem','fTrem','beatRpt','halfmRpt'))]" mode="tstamps">
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
    
    <xsl:template match="mei:mRest" mode="tstamps">
        <xsl:copy>
            <xsl:apply-templates select="@*" mode="#current"/>
            <xsl:attribute name="tstamp" select="'1'"/>
            <xsl:apply-templates select="node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="mei:mSpace" mode="tstamps">
        <xsl:copy>
            <xsl:apply-templates select="@*" mode="#current"/>
            <xsl:attribute name="tstamp" select="'1'"/>
            <xsl:apply-templates select="node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="mei:mRpt" mode="tstamps">
        <xsl:copy>
            <xsl:apply-templates select="@*" mode="#current"/>
            <xsl:attribute name="tstamp" select="'1'"/>
            <xsl:apply-templates select="node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <!-- mode include.cpMarks -->
    
    <xsl:template match="mei:*[@tstamp and not(@grace) and ancestor::mei:layer]" mode="include.cpMarks">
        <!-- this template adds a temporary attribute to make sure graces notes stay attached to the following note -->
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
    
    <xsl:template match="mei:measure" mode="include.cpMarks">
        <!-- include cpMarks into measure -->
        <xsl:variable name="measure.id" select="@xml:id"/>
        <xsl:variable name="meter.count" select="round(number(preceding::mei:scoreDef[@meter.count and not(ancestor::mei:supplied)][1]/@meter.count)) cast as xs:integer" as="xs:integer"/>
        <xsl:copy>
            <xsl:attribute name="meter.count" select="$meter.count"/>
            <xsl:apply-templates select="node() | @*" mode="#current"/>
            <xsl:apply-templates select="$cpMarks.raw[@freidi.measure = $measure.id]" mode="#current">
                <xsl:with-param name="meter.count" select="$meter.count" as="xs:integer" tunnel="yes"/>
            </xsl:apply-templates>
            <!--<xsl:message select="'cpMarks for measure ' || $measure.id || ': ' || count($cpMarks[@freidi.measure = $measure.id])"/>-->
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="mei:cpMark" mode="include.cpMarks">
        <!-- classifies cpMark as colla parte, mRpt or copy instruction -->
        <xsl:param name="meter.count" tunnel="yes" as="xs:integer"/>
        
        <xsl:variable name="refers.preceding.measure" select="exists(@ref.offset) and @ref.offset = '-1m+1'" as="xs:boolean"/>
        <xsl:variable name="refers.other.staff" select="exists(@ref.staff)" as="xs:boolean"/>
        <xsl:variable name="scope.is.one.measure" select="starts-with(@tstamp2,'0m+') and number(substring-after(@tstamp2,'0m+')) ge $meter.count" as="xs:boolean"/>
        
        <xsl:variable name="new.id" select="'x' || uuid:randomUUID()" as="xs:string"/>
        <xsl:copy>
            <xsl:attribute name="xml:id" select="$new.id"/>
            
            <xsl:choose>
                <xsl:when test="$refers.other.staff">
                    <xsl:attribute name="type" select="'collaParte'"/>
                </xsl:when>
                <xsl:when test="$refers.preceding.measure and $scope.is.one.measure">
                    <xsl:attribute name="type" select="'mRpt'"/>
                </xsl:when>
                <xsl:when test="not($refers.preceding.measure) or not($scope.is.one.measure)">
                    <xsl:attribute name="type" select="'cpInstruction'"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:message select="'WARNING: scope of cpMark ' || $new.id || ' could not be determined'"/>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:apply-templates select="@*" mode="#current"/>
            <xsl:apply-templates select="normalize-space(string-join(./text(),''))" mode="#current"/>
        </xsl:copy>
        
    </xsl:template>
    
    <!-- mode resolve.trems -->
    
    <!-- resolving bTrems that aren't resolved already -->
    <xsl:template match="mei:bTrem[not(parent::mei:orig)]" mode="resolve.trems">
        <choice xmlns="http://www.music-encoding.org/ns/mei" xml:id="c{uuid:randomUUID()}">
            <orig xml:id="{'o' || uuid:randomUUID()}">
                <xsl:copy>
                    <xsl:apply-templates select="node() | @*" mode="#current"/>
                </xsl:copy>
            </orig>
            <reg xml:id="{'r' || uuid:randomUUID()}">
                <xsl:variable name="elem" select="child::mei:*" as="node()"/>
                <xsl:variable name="dur" select="1 div number($elem/@dur)" as="xs:double"/>
                <xsl:variable name="dots" select="if($elem/@dots) then(number($elem/@dots)) else(0)" as="xs:double"/>
                <xsl:variable name="totalDur" select="(2 * $dur) - ($dur div math:pow(2,$dots))" as="xs:double"/>
                
                <xsl:if test="not($elem/@stem.mod)">
                    <xsl:message terminate="yes" select="'ERROR: child of bTrem ' || @xml:id || ' has no @stem.mod. '"/>
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
                
                <xsl:variable name="count" select="($totalDur div (1 div (4 * math:pow(2,$stem.mod.total)))) cast as xs:integer" as="xs:integer"/>
                <!--<xsl:message select="'INFO: bTrem with dur of ' || $totalDur || ' and ' || $stem.mod.total || ' slashes results in ' || $count || ' notes'"/>-->
                
                <xsl:variable name="tstamp" select="number(@tstamp)" as="xs:double"/>
                
                <xsl:if test="not($elem/@stem.mod)">
                    <xsl:message select="local-name($elem) || '[#' || $elem/@xml:id || '] inside bTrem misses @stem.mod'"/>
                </xsl:if>
                
                <xsl:variable name="measperf" select="4 * math:pow(2,$stem.mod.total)" as="xs:double"/>
                
                <xsl:variable name="meter.unit" select="ancestor::mei:measure/preceding::mei:scoreDef[@meter.unit][1]/@meter.unit cast as xs:integer" as="xs:integer"/>
                <xsl:variable name="tstamp.step" select="$meter.unit div number($measperf)" as="xs:double"/>
                
                <!--<xsl:message select="$totalDur || ' dur makes ' || $count || ' found'"></xsl:message>-->
                
                <xsl:choose>
                    <xsl:when test="not(ancestor::mei:beam)">
                        <beam xml:id="{'b' || uuid:randomUUID()}">
                            <xsl:for-each select="(1 to $count)">
                                <xsl:variable name="i" select="." as="xs:integer"/>
                                <xsl:variable name="n" select="$i - 1" as="xs:integer"/>
                                
                                <xsl:apply-templates select="$elem" mode="#current">
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
                            
                            <xsl:apply-templates select="$elem" mode="#current">
                                <xsl:with-param name="dur" select="$measperf"/>
                                <xsl:with-param name="tstamp" select="$tstamp + $n * $tstamp.step"/>
                                <xsl:with-param name="i" select="$i" as="xs:integer"/>
                                <xsl:with-param name="count" select="$count" as="xs:integer"/>
                            </xsl:apply-templates>
                            
                        </xsl:for-each>
                        
                    </xsl:otherwise>
                </xsl:choose>
            </reg>
        </choice>
    </xsl:template>
    
    <!-- resolving fTrems that aren't resolved already -->
    <xsl:template match="mei:fTrem[not(parent::mei:orig)]" mode="resolve.trems">
        <choice xmlns="http://www.music-encoding.org/ns/mei" xml:id="c{uuid:randomUUID()}">
            <orig xml:id="{'o' || uuid:randomUUID()}">
                <xsl:copy>
                    <xsl:apply-templates select="node() | @*" mode="#current"/>
                </xsl:copy>
            </orig>
            <reg xml:id="{'r' || uuid:randomUUID()}">
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
                
                <beam xml:id="{'b' || uuid:randomUUID()}">
                    <xsl:for-each select="(1 to $count)">
                        <xsl:variable name="i" select="." as="xs:integer"/>
                        <xsl:variable name="n" select="$i - 1" as="xs:integer"/>
                        <xsl:apply-templates select="$elem.1" mode="#current">
                            <xsl:with-param name="dur" select="$measperf"/>
                            <xsl:with-param name="tstamp" select="$tstamp + (2 * $n) * $tstamp.step"/>
                        </xsl:apply-templates>
                        <xsl:apply-templates select="$elem.2" mode="#current">
                            <xsl:with-param name="dur" select="$measperf"/>
                            <xsl:with-param name="tstamp" select="$tstamp + ((2 * $n) + 1) * $tstamp.step"/>
                        </xsl:apply-templates>
                    </xsl:for-each>
                </beam>
                
            </reg>
        </choice>
    </xsl:template>
    
    <!-- adjust notes and chords that are contained in a tremolo, i.e. apply duration and tstamp as provided -->
    <xsl:template match="mei:chord | mei:note[not(parent::mei:chord)]" mode="resolve.trems">
        <xsl:param name="dur"/>
        <xsl:param name="tstamp"/>
        <xsl:param name="i" as="xs:integer?"/>
        <xsl:param name="count" as="xs:integer?"/>
        <xsl:choose>
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
                    <xsl:apply-templates select="@* except (@xml:id,@dur,@dots,@tstamp,@stem.mod, @sameas,@tie,@accid)" mode="#current"/>
                    <xsl:if test="not($dur and $tstamp)">
                        <xsl:apply-templates select="@stem.mod" mode="#current"/>
                    </xsl:if>
                    <xsl:if test="$i and $i = 1 and @tie and @tie = ('m','t')">
                        <xsl:attribute name="tie" select="'t'"/>
                    </xsl:if>
                    <xsl:if test="$i and $count and $i = $count and @tie and @tie = ('i','m')">
                        <xsl:attribute name="tie" select="'i'"/>
                    </xsl:if>
                    <xsl:if test="$i and $i = 1">
                        <xsl:apply-templates select="@accid" mode="#current"/>
                    </xsl:if>
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
    <xsl:template match="mei:note[parent::mei:chord]" mode="resolve.trems">
        <xsl:next-match/>
    </xsl:template>
    
    <!-- mode adjustMaterial -->
    
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
        <xsl:param name="music.file.expan" tunnel="yes" as="node()?"/>
        
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
                            <xsl:sequence select="$music.file.expan//mei:music/id(replace(.,'#',''))"/>
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
                
                <xsl:variable name="first.target.tstamp.last" select="
                    if($measure.count = 0) 
                    then(number(substring-after($cpMark/@tstamp2,'m+'))) 
                    else(number($first.targetMeasure/@meter.count) + 1)" as="xs:double"/>
                <xsl:variable name="first.source.tstamp.last" select="
                    if(number(substring-before($cpMark/@ref.offset2,'m+')) = 0) 
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
    
    
    <!-- mode resolve.marks -->
    
    <!-- resolve mRpt that aren't resolved already -->
    <xsl:template match="mei:layer" mode="resolve.marks">
        
        <xsl:param name="material" tunnel="yes" as="node()"/>
        <xsl:param name="cpInstructions" tunnel="yes" as="node()*"/>
        <xsl:param name="cpMarks.enhanced" tunnel="yes" as="node()*"/>
        <xsl:param name="cpMark.ids" tunnel="yes" as="xs:string*"/>
        <xsl:param name="mode" tunnel="yes" as="xs:string"/>
        
        <xsl:variable name="layer" select="." as="node()"/>
        <xsl:variable name="layer.n" select="@n" as="xs:string?"/>
        <xsl:variable name="staff" select="parent::mei:staff" as="node()"/>
        
        <xsl:variable name="cpInstructions.all" select="$cpInstructions[@targetStaff.id = $staff/@xml:id]" as="node()*"/>
        <xsl:variable name="local.cpMarks" select="$cpMarks.enhanced[@xml:id = $cpInstructions.all/@cpMark.id and (not(@layer) or @layer = $layer.n or not($layer.n)) and @xml:id = $cpMark.ids]" as="node()*"/>
        <xsl:variable name="local.cpInstructions" as="node()*">
            <xsl:perform-sort select="$cpInstructions.all[@cpMark.id = $local.cpMarks/@xml:id]">
                <xsl:sort select="@target.tstamp.first" data-type="number"/>
                <xsl:sort select="@target.tstamp.last" data-type="number"/>
            </xsl:perform-sort>
        </xsl:variable>
        
        <xsl:choose>
            <xsl:when test="not(count($local.cpMarks) = count($local.cpInstructions))">
                <xsl:message terminate="yes" select="'ERROR: Processing of cpMarks for ' || $staff/@xml:id || ' went wrong. Please check!'"/>
            </xsl:when>
            <xsl:when test="count($local.cpInstructions) = 0">
                <xsl:next-match/>
            </xsl:when>
            <!-- resolve mRpts -->
            <xsl:when test="count($local.cpMarks) = 1 and $local.cpMarks/@type = 'mRpt' and $mode = 'mRpt'">
                <xsl:copy>
                    <xsl:apply-templates select="@*" mode="#current"/>
                    <choice xmlns="http://www.music-encoding.org/ns/mei" xml:id="c{uuid:randomUUID()}">
                        <abbr xml:id="c{uuid:randomUUID()}" type="mRpt">
                            <mRpt xml:id="c{uuid:randomUUID()}" tstamp="1"/>
                        </abbr>
                        <expan xml:id="c{uuid:randomUUID()}" evidence="#{$local.cpMarks/@xml:id}">
                            <xsl:apply-templates select="child::node()" mode="#current">
                                <xsl:with-param name="relevant.cpInstructions" select="$local.cpInstructions" tunnel="yes" as="node()*"/>
                                <xsl:with-param name="source.staff" select="$material//mei:staff[@xml:id = $local.cpInstructions/@sourceStaff.id]" tunnel="yes" as="node()"/>
                                <xsl:with-param name="layer.n" select="$layer.n" tunnel="yes" as="xs:string?"/>
                            </xsl:apply-templates>
                        </expan>
                    </choice>
                </xsl:copy>
            </xsl:when>
            
            <!-- include arbitrary horizontal copy instructions -->
            <xsl:when test="count($local.cpMarks) = 1 and $local.cpMarks/@type = ('cpInstruction','collaParte') and $mode = $local.cpMarks/@type">
                
                <xsl:copy>
                    <xsl:apply-templates select="@*" mode="#current"/>
                    
                    <xsl:choose>
                        <xsl:when test="child::mei:mRest">
                            <xsl:apply-templates select="child::node()" mode="#current"/>
                        </xsl:when>
                        
                        <xsl:otherwise>
                            <xsl:apply-templates select="$layer/node()" mode="#current">
                                <xsl:with-param name="tstamp.before" select="number($local.cpInstructions/@target.tstamp.first)" as="xs:double" tunnel="yes"/>
                            </xsl:apply-templates>
                            
                            <choice xmlns="http://www.music-encoding.org/ns/mei" xml:id="c{uuid:randomUUID()}">
                                <abbr xml:id="c{uuid:randomUUID()}" type="{if($local.cpMarks/@type = 'cpInstruction') then('cpMark') else('collaParte')}">                            
                                    <xsl:apply-templates select="$layer/node()" mode="makeSpace">
                                        <xsl:with-param name="tstamp.first" select="number($local.cpInstructions/@target.tstamp.first)" as="xs:double" tunnel="yes"/>
                                        <xsl:with-param name="tstamp.last" select="number($local.cpInstructions/@target.tstamp.last)" as="xs:double" tunnel="yes"/>
                                    </xsl:apply-templates>
                                </abbr>
                                
                                <xsl:if test="not(exists($material//mei:staff[@xml:id = $local.cpInstructions/@sourceStaff.id]))">
                                    <xsl:message select="$local.cpMarks"/>
                                </xsl:if>
                                
                                <expan xml:id="c{uuid:randomUUID()}" evidence="#{$local.cpMarks/@xml:id}">
                                    <xsl:apply-templates select="child::node()" mode="#current">
                                        <xsl:with-param name="relevant.cpInstructions" select="$local.cpInstructions" tunnel="yes" as="node()*"/>
                                        <xsl:with-param name="source.staff" select="$material//mei:staff[@xml:id = $local.cpInstructions/@sourceStaff.id]" tunnel="yes" as="node()"/>
                                        <xsl:with-param name="layer.n" select="$layer.n" tunnel="yes" as="xs:string?"/>
                                        <xsl:with-param name="tstamp.first" select="number($local.cpInstructions/@target.tstamp.first)" as="xs:double" tunnel="yes"/>
                                        <xsl:with-param name="tstamp.last" select="number($local.cpInstructions/@target.tstamp.last)" as="xs:double" tunnel="yes"/>
                                    </xsl:apply-templates>                            
                                </expan>
                            </choice>
                            
                            <xsl:apply-templates select="$layer/node()" mode="#current">
                                <xsl:with-param name="tstamp.after" select="$local.cpInstructions[last()]/@target.tstamp.last" as="xs:double" tunnel="yes"/>
                            </xsl:apply-templates>
                        </xsl:otherwise>
                    </xsl:choose>
                    
                </xsl:copy>
            </xsl:when>
            <xsl:when test="count($local.cpMarks) gt 1">
                <xsl:message select="'INFO: Multiple cpMarks for ' || $staff/@xml:id || '. Ignoring them for now…'"/>
                <xsl:next-match/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:next-match/>
            </xsl:otherwise>
        </xsl:choose>
            
    </xsl:template>
    
    <!-- turn existing elements into spaces of same duration -->
    <xsl:template match="mei:*[@dur]" mode="makeSpace">
        <xsl:param name="tstamp.before" tunnel="yes" as="xs:double?"/>
        <xsl:param name="tstamp.after" tunnel="yes" as="xs:double?"/>        
        <xsl:param name="tstamp.first" tunnel="yes" as="xs:double?"/>
        <xsl:param name="tstamp.last" tunnel="yes" as="xs:double?"/>
        
        <xsl:variable name="this.tstamp" select="number(@tstamp)" as="xs:double"/>
        
        <xsl:choose>
            <xsl:when test="exists($tstamp.first) and $this.tstamp lt $tstamp.first"/>
            <xsl:when test="exists($tstamp.last) and $this.tstamp gt $tstamp.last"/>
            <xsl:when test="exists($tstamp.before) and $this.tstamp ge $tstamp.before"/>
            <xsl:when test="exists($tstamp.after) and $this.tstamp le $tstamp.after"/>
            <xsl:otherwise>
                <space xmlns="http://www.music-encoding.org/ns/mei" xml:id="c{uuid:randomUUID()}">
                    <xsl:apply-templates select="@dur | @tstamp | @dots" mode="#current"/>
                </space>
            </xsl:otherwise>
        </xsl:choose>
        
    </xsl:template>
    
    <xsl:template match="mei:*[@tstamp]" mode="resolve.marks">
        <xsl:param name="relevant.cpInstructions" tunnel="yes" as="node()*"/>
        <xsl:param name="source.staff" tunnel="yes" as="node()*"/>
        <xsl:param name="staff.n" tunnel="yes" as="xs:string?"/>
        
        <xsl:param name="tstamp.before" tunnel="yes" as="xs:double?"/>
        <xsl:param name="tstamp.after" tunnel="yes" as="xs:double?"/>        
        <xsl:param name="tstamp.first" tunnel="yes" as="xs:double?"/>
        <xsl:param name="tstamp.last" tunnel="yes" as="xs:double?"/>
        
        <xsl:variable name="this.elem" select="." as="node()"/>
        <xsl:variable name="this.name" select="local-name()" as="xs:string"/>
        <xsl:variable name="this.tstamp" select="number(@tstamp)" as="xs:double"/>
        <xsl:variable name="this.cpInstruction" select="$relevant.cpInstructions/descendant-or-self::copy[number(@target.tstamp.first) le $this.tstamp and number(@target.tstamp.last) ge $this.tstamp]" as="node()*"/>
        
        <xsl:choose>
            <xsl:when test="exists($tstamp.first) and $this.tstamp lt $tstamp.first"/>
            <xsl:when test="exists($tstamp.last) and $this.tstamp gt $tstamp.last"/>
            <xsl:when test="exists($tstamp.before) and $this.tstamp ge $tstamp.before"/>
            <xsl:when test="exists($tstamp.after) and $this.tstamp le $tstamp.after"/>
            
            <xsl:when test="ancestor::mei:orig or ancestor::mei:abbr">
                <!-- only deal with "real" content, not abbreviations -->
                <xsl:next-match/>
            </xsl:when>
            <xsl:when test="count($this.cpInstruction) gt 1">
                <xsl:message select="'WARNING: multiple cpMarks seem to influence ' || local-name() || ' @xml:id=' || @xml:id || ' in staff ' || ancestor::mei:staff/@xml:id || ' at the same time. No @corresp added!'"/>
                <xsl:next-match/>
            </xsl:when>
            <xsl:when test="count($this.cpInstruction) = 0">
                <!-- element not affected by cpInstruction -->
                <xsl:next-match/>
            </xsl:when>
            <xsl:otherwise>
                
                <xsl:variable name="tstamp.offset" select="number($relevant.cpInstructions/@source.tstamp.first) - number($relevant.cpInstructions/@target.tstamp.first)" as="xs:double"/>
                    
                <xsl:variable name="matching.elem" as="node()?">
                    <xsl:choose>
                        <xsl:when test="not($staff.n) and count($source.staff/mei:layer) = 1">
                            <xsl:sequence select="($source.staff/mei:layer//mei:*[number(@tstamp) = ($this.tstamp - $tstamp.offset) and local-name() = $this.name and not(ancestor::mei:orig)])[1]"/>
                        </xsl:when>
                        <xsl:when test="$staff.n and $source.staff/mei:layer[@n = $staff.n]">
                            <xsl:sequence select="($source.staff/mei:layer[@n = $staff.n]//mei:*[number(@tstamp) = ($this.tstamp - $tstamp.offset) and local-name() = $this.name and not(ancestor::mei:orig)])[1]"/>
                        </xsl:when>
                    </xsl:choose>
                </xsl:variable>    
                
                <xsl:copy>
                    <xsl:if test="$matching.elem">
                        <xsl:attribute name="corresp" select="'#' || $matching.elem/@xml:id"/>
                    </xsl:if>                    
                    <xsl:apply-templates select="node() | @*" mode="#current"/>
                </xsl:copy>
                
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="mei:*[not(@tstamp) and .//@tstamp]" mode="resolveMarks makeSpace">
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
    
    <!-- mode cpMark.cleanup -->
    <xsl:template match="@freidi.measure" mode="shortCut.cleanup"/>
    <xsl:template match="mei:abbr/@tstamp" mode="shortCut.cleanup"/>
    <xsl:template match="mei:abbr/@tstamp2" mode="shortCut.cleanup"/>
    <xsl:template match="mei:expan/@evidence" mode="shortCut.cleanup">
        <xsl:attribute name="evidence" select="replace(.,'#','')"/>
    </xsl:template>
    <xsl:template match="mei:measure/@meter.count" mode="shortCut.cleanup"/>
    
    
    <!-- mode addAccid.ges -->
    <xsl:template match="mei:appInfo" mode="addAccid.ges">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*" mode="#current"/>
            <application xmlns="http://www.music-encoding.org/ns/mei" xml:id="addAccid.ges.xsl_v0.10" version="0.10">
                <name>addAccid.ges.xsl</name>
                <xsl:comment>This is a special version of addAccid.ges.xsl integrated into core_directSetup.xsl</xsl:comment>
                <ptr target="https://github.com/Freischuetz-Digital/Tools/blob/develop/13%20reCore/addAccid.ges.xsl"/>
            </application>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="mei:revisionDesc" mode="addAccid.ges">
        <xsl:copy>
            <xsl:apply-templates select="@*" mode="#current"/>
            <xsl:apply-templates select="mei:change" mode="#current">
                <xsl:sort select="if(./mei:date/text()) then(./mei:date/text()) else(./mei:date/@isodate)" data-type="text" order="ascending"/>
            </xsl:apply-templates>
            
            <change xmlns="http://www.music-encoding.org/ns/mei">
                <respStmt>
                    <persName>Johannes Kepper</persName>
                </respStmt>
                <changeDesc>
                    <p>Included @accid.ges for all notes by using <ptr target="addAccid.ges.xsl_v0.10"/>.</p>
                </changeDesc>
                <date isodate="{substring(string(current-date()),1,10)}"/>
            </change>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="mei:staff" mode="addAccid.ges">
        <xsl:variable name="n" select="@n" as="xs:string"/>
        
        <xsl:variable name="key.sig" as="xs:string?">
            <xsl:choose>
                <xsl:when test=".//mei:staffDef[count(preceding-sibling::mei:*) = 0 and @key.sig]">
                    <xsl:value-of select=".//mei:staffDef[count(preceding-sibling::mei:*) = 0 and @key.sig][1]/@key.sig"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="preceding::mei:*[(local-name() = 'staffDef' and @n = $n and @key.sig) or (local-name() = 'scoreDef' and @key.sig)][1]/@key.sig"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="accids" as="element()*">
            <xsl:for-each select=".//mei:*[@accid]">
                <xsl:sort select="@tstamp" data-type="number"/>
                <xsl:choose>
                    <xsl:when test="local-name() = 'note'">
                        <accid xmlns="http://www.music-encoding.org/ns/mei" pname="{@pname}" oct="all" tstamp="{@tstamp}" accid="{@accid}"/>
                    </xsl:when>
                    <xsl:when test="local-name() = 'accid' and @ploc and @oloc">
                        <accid xmlns="http://www.music-encoding.org/ns/mei" pname="{string(@ploc)}" oct="all" tstamp="{@tstamp}" accid="{@accid}"/>
                    </xsl:when>
                    <xsl:when test="local-name() = 'accid' and @loc">
                        <!-- todo: hier Tonhöhe raussuchen -->
                        <xsl:message select="'ERROR: encountered an unexpected situation with accidentals and @loc attribute at ' || @xml:id ||'. Processing stopped.'"></xsl:message>
                    </xsl:when>                    
                </xsl:choose>
            </xsl:for-each>
        </xsl:variable>
        <xsl:variable name="preceding.staff" select="local:getPrecedingStaff(.)" as="element()?"/>
        
        <xsl:copy>
            <xsl:apply-templates select="node() | @*" mode="#current">
                <xsl:with-param name="key.sig" select="$key.sig" tunnel="yes" as="xs:string?"/>
                <xsl:with-param name="accids" select="$accids" tunnel="yes" as="element()*"/>
                <xsl:with-param name="preceding.staff" select="$preceding.staff" tunnel="yes" as="element()?"/>
            </xsl:apply-templates>    
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="mei:note" mode="addAccid.ges">
        <xsl:param name="key.sig" tunnel="yes" as="xs:string?"/>
        <xsl:param name="accids" tunnel="yes" as="element()*"/>
        <xsl:param name="preceding.staff" tunnel="yes" as="element()?"/>
        
        <xsl:variable name="current.pname" select="string(@pname)" as="xs:string"/>
        <xsl:variable name="current.oct" select="string(@oct)" as="xs:string"/>
        <xsl:variable name="current.tstamp" select="number(@tstamp)" as="xs:double"/>
        <xsl:variable name="current.id" select="string(@xml:id)" as="xs:string"/>
        
        <xsl:variable name="key.sig.mod" as="xs:string?">
            <xsl:variable name="sharps" select="('f','c','g','d','a','e','b')" as="xs:string*"/>
            <xsl:variable name="flats" select="('b','e','a','d','g','c','f')" as="xs:string*"/>
            <xsl:if test="exists($key.sig) and $key.sig != '0'">
                <xsl:choose>
                    <xsl:when test="ends-with($key.sig,'s') and index-of($sharps,$current.pname) le number(substring-before($key.sig,'s'))">s</xsl:when>
                    <xsl:when test="ends-with($key.sig,'f') and index-of($flats,$current.pname) le number(substring-before($key.sig,'f'))">f</xsl:when>
                </xsl:choose>
            </xsl:if>
        </xsl:variable>
        
        <xsl:copy>
            <xsl:apply-templates select="@*" mode="#current"/>
            
            <xsl:choose>
                <!-- if an @accid is present, no further action is required -->
                <xsl:when test="@accid"/>
                
                <!-- if accid on preceding note of same pitch is found -->
                <xsl:when test="$accids[@pname = $current.pname and 
                    number(@tstamp) lt $current.tstamp]">
                    
                    <xsl:variable name="preceding.accid" select="$accids[@pname = $current.pname and 
                        number(@tstamp) lt $current.tstamp][last()]" as="element()"/>
                    
                    <xsl:choose>
                        <xsl:when test="@accid.ges and string(@accid.ges) != string($preceding.accid/@accid)">
                            <xsl:message terminate="no" select="'False @accid.ges on note #' || $current.id || '. Accid earlier in the staff. @accid.ges was: ' || @accid.ges || ', is: ' || string($preceding.accid/@accid)"/>
                            <xsl:attribute name="accid.ges" select="string($preceding.accid/@accid)"/>
                        </xsl:when>
                    </xsl:choose>
                    
                </xsl:when>
                
                <!-- if note is tied to note in preceding staff -->
                <xsl:when test="@tie and @tie = ('m','t') and @tstamp = '1'">
                    <xsl:variable name="tieStart" select="local:getTieStartInPrecedingStaff(ancestor::mei:staff,$current.pname)" as="element()?"/>
                    
                    <xsl:choose>
                        
                        <!-- the note seems incorrectly tied -->
                        <xsl:when test="not(exists($tieStart))">
                            <xsl:message terminate="no" select="'note ' || @xml:id || ' in ' || ancestor::mei:staff/@xml:id || ' seems incorrectly tied. Please check!'"/>
                        </xsl:when>
                        <!-- the note where the tie starts has an @accid by itself -->
                        <xsl:when test="$tieStart/@accid">
                            <xsl:attribute name="accid.ges" select="string($tieStart/@accid)"/>
                        </xsl:when>
                        <!-- when there is a preceding note in that measure that has an accid for the same pname -->
                        <xsl:when test="number($tieStart/@tstamp) gt 1 and 
                            $tieStart/ancestor::mei:staff[.//mei:note[@pname = $current.pname and 
                            number(@tstamp) lt number($tieStart/@tstamp) and
                            @accid]]">
                            <xsl:variable name="accid.ges" select="($tieStart/ancestor::mei:staff//mei:note[@pname = $current.pname and 
                                number(@tstamp) lt number($tieStart/@tstamp) and
                                @accid])[last()]/@accid" as="xs:string"/>
                            
                            <xsl:choose>
                                <xsl:when test="@accid.ges and string(@accid.ges) != string($accid.ges)">
                                    <xsl:message terminate="no" select="'False @accid.ges on note #' || $current.id || '. To be derived from preceding measure. @accid.ges: ' || @accid.ges || ', is: ' || string($accid.ges)"/>
                                    <xsl:attribute name="accid.ges" select="$accid.ges"/>
                                </xsl:when>
                            </xsl:choose>
                            
                        </xsl:when>
                    </xsl:choose>
                    
                </xsl:when>
                
                <!-- accid depending on key.sig -->
                <xsl:when test="exists($key.sig.mod)">
                    <xsl:choose>
                        <xsl:when test="@accid.ges and string(@accid.ges) != $key.sig.mod">
                            <xsl:message terminate="no" select="'False @accid.ges on note #' || $current.id || '. Key sig differs. @accid.ges was: ' || @accid.ges || ', is: ' || $key.sig.mod"/>
                            <xsl:attribute name="accid.ges" select="$key.sig.mod"/>
                        </xsl:when>
                    </xsl:choose>
                </xsl:when>
                
            </xsl:choose>
            
            <xsl:apply-templates select="node()" mode="#current"/>
        </xsl:copy>
        
    </xsl:template>
    
    <xsl:function name="local:getTieStartInPrecedingStaff" as="element()?">
        <xsl:param name="staff" as="element()"/>
        <xsl:param name="pname" as="xs:string"/>
        <xsl:variable name="preceding.staff" select="local:getPrecedingStaff($staff)"/>
        <xsl:choose>
            <xsl:when test="$preceding.staff//mei:note[@tie = 'i' and @pname = $pname]">
                <xsl:sequence select="($preceding.staff//mei:note[@tie = 'i' and @pname = $pname])[last()]"/>
            </xsl:when>
            <xsl:when test="$preceding.staff">
                <xsl:sequence select="local:getTieStartInPrecedingStaff($preceding.staff,$pname)"/>
            </xsl:when>
            <xsl:otherwise>
                
            </xsl:otherwise>
        </xsl:choose>
        
    </xsl:function>
    
    <xsl:function name="local:getPrecedingStaff" as="element()?">
        <xsl:param name="staff" as="element()"/>
        <xsl:variable name="n" select="$staff/@n"/>
        <xsl:sequence select="$staff/preceding::mei:staff[@n = $n][1]"/>
    </xsl:function>
    
    <!-- mode final.cleanup -->
    <xsl:template match="mei:facsimile/text()" mode="final.cleanup"/>
    <xsl:template match="mei:layer/text()" mode="final.cleanup"/>
    <xsl:template match="mei:note/text()" mode="final.cleanup"/>
    <xsl:template match="mei:body/text()" mode="final.cleanup"/>
    <xsl:template match="@stayWithMe" mode="final.cleanup"/>
    <xsl:template match="mei:beam[count(child::mei:*) = 0 or (every $child in child::mei:* satisfies (local-name($child) = 'space'))]" mode="final.cleanup"/>
    <xsl:template match="mei:tuplet[count(child::mei:*) = 0]" mode="final.cleanup"/>
    
    <xsl:template match="mei:beam/@xml:id" mode="final.cleanup">
        <xsl:attribute name="xml:id" select="'b' || uuid:randomUUID()"/>
    </xsl:template>
    
    <xsl:template match="mei:clef[not(@tstamp)]" mode="final.cleanup">
        <xsl:copy>
            <xsl:apply-templates select="@*" mode="#current"/>
            <xsl:attribute name="tstamp" select="if(following-sibling::mei:*[@tstamp]) 
                then(following-sibling::mei:*[@tstamp][1]/@tstamp) 
                else(preceding-sibling::mei:*[@tstamp][1]/@tstamp)"/>
            <xsl:apply-templates select="node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="@artic" mode="final.cleanup">
        <xsl:variable name="values" as="xs:string*">
            <xsl:for-each select="tokenize(.,' ')">
                <xsl:variable name="value" select="." as="xs:string"/>
                <xsl:choose>
                    <xsl:when test="$value = 'acc'">
                        <xsl:value-of select="'acc'"/>
                    </xsl:when>
                    <xsl:when test="$value = 'stacc'">
                        <xsl:value-of select="'dot'"/>
                    </xsl:when>
                    <xsl:when test="$value = 'spicc'">
                        <xsl:value-of select="'dot'"/>
                    </xsl:when>
                    <xsl:when test="$value = 'stacciss'">
                        <xsl:value-of select="'stroke'"/>
                    </xsl:when>
                    <xsl:when test="$value = 'marc'">
                        <xsl:value-of select="'stroke'"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:message select="'ERROR: a value of ' || $value || ' for @artic is currently not supported. Processing stopped.'"/>
                    </xsl:otherwise>
                </xsl:choose>    
            </xsl:for-each>
        </xsl:variable>
        <xsl:attribute name="artic" select="string-join($values,' ')"/>
    </xsl:template>
    
    <xsl:template match="mei:mdiv/@xml:id" mode="final.cleanup">
        <xsl:attribute name="xml:id" select="$mov.id"/>
    </xsl:template>
    
    <xsl:template match="mei:change" mode="final.cleanup">
        <xsl:copy>
            <xsl:apply-templates select="@* except @n" mode="#current"/>
            <xsl:attribute name="n" select="string(count(preceding-sibling::mei:change) + 1)"/>
            <xsl:apply-templates select="node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    
    <!-- mode coreDraft -->
    <!-- preparing new xml:ids -->
    <xsl:template match="mei:*[local-name() = ('mdiv','section','measure','staff')]/@xml:id" mode="coreDraft">
        <xsl:variable name="old.id" select="string(.)" as="xs:string"/>
        <xsl:variable name="new.id" select="replace($old.id,$source.id,'core')" as="xs:string"/>
        <xsl:attribute name="xml:id" select="$new.id"/>
        <xsl:attribute name="old.id" select="$old.id"/>        
    </xsl:template>    
    <xsl:template match="mei:*[(ancestor::mei:staff) or (ancestor::mei:measure and not(ancestor::mei:staff) and not(local-name() = 'staff'))]/@xml:id" mode="coreDraft">        
        <xsl:attribute name="xml:id" select="'c'||uuid:randomUUID()"/>
        <xsl:attribute name="old.id" select="string(.)"/>
    </xsl:template>
    
    <!-- resolving choices into apps when necessary -->
    <xsl:template match="mei:choice" mode="coreDraft">
        
        <xsl:if test="count(child::mei:expan) gt 1">
            <xsl:message select="'working on choice ' || @xml:id"></xsl:message>
        </xsl:if>
        
        <xsl:choose>
            <xsl:when test="(count(child::mei:corr) gt 1) or (count(child::mei:reg) gt 1)">
                <app xmlns="http://www.music-encoding.org/ns/mei" xml:id="{'c'||uuid:randomUUID()}">
                    <xsl:apply-templates select="node()" mode="#current"/>
                </app>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="mei:corr/node() | mei:reg/node() | mei:expan/node()" mode="#current"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- only <corr>, <reg> and <expan> are addressed in the core -->
    <xsl:template match="mei:sic" mode="coreDraft"/>
    <xsl:template match="mei:abbr" mode="coreDraft"/>
    <xsl:template match="mei:orig" mode="coreDraft"/>    
    
    <!-- <corr> is a result of incorrect durations in the parent layer -->
    <xsl:template match="mei:corr" mode="coreDraft">
        <rdg xmlns="http://www.music-encoding.org/ns/mei">
            <xsl:attribute name="xml:id" select="'c'||uuid:randomUUID()"/>
            <xsl:attribute name="source" select="'#' || $source.id"/>
            <xsl:apply-templates select="node()" mode="#current"></xsl:apply-templates>
        </rdg>
    </xsl:template>
    
    <!-- <reg> is a result of ambiguous control events -->
    <xsl:template match="mei:reg" mode="coreDraft">
        <rdg xmlns="http://www.music-encoding.org/ns/mei">
            <xsl:attribute name="xml:id" select="'c'||uuid:randomUUID()"/>
            <xsl:attribute name="source" select="'#' || $source.id"/>
            <xsl:apply-templates select="node()" mode="#current"/>
        </rdg>
    </xsl:template>
    
    <!-- <expan> is a result of resolving abbreviations like mRpt and cpMark -->
    <xsl:template match="mei:expan" mode="coreDraft">
        <xsl:choose>
            <xsl:when test="parent::mei:choice">
                <rdg xmlns="http://www.music-encoding.org/ns/mei">
                    <xsl:attribute name="xml:id" select="'c'||uuid:randomUUID()"/>
                    <xsl:attribute name="source" select="'#' || $source.id"/>
                    <xsl:apply-templates select="node()" mode="#current"/>
                </rdg>
            </xsl:when>
            <xsl:when test="parent::mei:syl">
                <xsl:apply-templates select="node()" mode="#current"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message terminate="yes" select="'Doh, another mei:expan I have no idea what to do with… (' || @xml:id || ' in measure ' || ancestor::mei:measure/@n || ')'"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="mei:appInfo" mode="coreDraft">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*" mode="#current"/>
            <application xmlns="http://www.music-encoding.org/ns/mei" xml:id="setupNewCore.xsl_v1.0.2" version="1.0.2">
                <name>setupNewCore.xsl</name>
                <xsl:comment>This version of setupNewCore.xsl is integrated into core_directSetup.xsl.</xsl:comment>
                <ptr target="https://github.com/Freischuetz-Digital/Tools/blob/develop/14%20reCore/setupNewCore.xsl"/>
            </application>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="mei:revisionDesc" mode="coreDraft">
        <xsl:copy>
            <change xmlns="http://www.music-encoding.org/ns/mei" n="1">
                <respStmt>
                    <persName>Johannes Kepper</persName>
                </respStmt>
                <changeDesc>
                    <p>Generated a new core for mov<xsl:value-of select="$mov.n"/> from <xsl:value-of select="$mov.id"/>.xml with <ptr target="setupNewCore.xsl_v1.0.2"/>. This new core is not directly related to the original core file, and is a direct result of the proofreading process. All change attributes from <xsl:value-of select="$mov.id"/>.xml have been stripped, as they describe the processing of a source, not this core. When tracing the genesis of this file, however, they have to be considered.</p>
                </changeDesc>
                <date isodate="{substring(string(current-date()),1,10)}"/>
            </change>
        </xsl:copy>
    </xsl:template>
    
    <!-- for the core, generate a tstamp for grace notes -->
    <xsl:template match="mei:note[@grace and not(@tstamp)]" mode="include.cpMarks coreDraft">
        <xsl:variable name="tstampOffset" as="xs:double">
            <xsl:call-template name="setGraceOffset">
                <xsl:with-param name="note" select="."/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:copy>
            <xsl:attribute name="tstamp" select="number(following::mei:note[@tstamp][1]/@tstamp) - $tstampOffset"/>
            <xsl:apply-templates select="node() | @*" mode="#current"/>
        </xsl:copy>
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
    
    
    <!-- source-specific information to be removed from the core -->
    <xsl:template match="@sameas" mode="coreDraft"/>
    <xsl:template match="@stem.dir" mode="coreDraft"/>
    <xsl:template match="@curvedir" mode="coreDraft"/>
    <xsl:template match="@place" mode="coreDraft"/>
    <xsl:template match="mei:facsimile" mode="coreDraft"/>
    <xsl:template match="mei:pb" mode="coreDraft"/>
    <xsl:template match="mei:sb" mode="coreDraft"/>
    <xsl:template match="@facs" mode="coreDraft"/>
    <xsl:template match="@corresp" mode="coreDraft"/>
    <xsl:template match="mei:space/@n" mode="coreDraft"/>
    <xsl:template match="mei:cpMark" mode="coreDraft"/>
    
    <!-- mode source -->
    
    <!-- preparing references to new xml:ids -->
    <xsl:template match="mei:*[(ancestor::mei:layer) or (ancestor::mei:measure and not(ancestor::mei:staff))]/@xml:id" mode="source">
        <xsl:param name="coreDraft" tunnel="yes"/>
        <xsl:variable name="ref.id" select="."/>
        <xsl:attribute name="xml:id" select="."/>
        <xsl:variable name="elem" select="parent::mei:*" as="element()"/>
        <xsl:variable name="elem.name" select="local-name($elem)" as="xs:string"/>
        <xsl:choose>
            <xsl:when test="$elem.name = 'choice'"/>
            <xsl:when test="$elem.name = 'orig'"/>
            <xsl:when test="$elem.name = 'reg'"/>
            <xsl:when test="$elem.name = 'abbr'"/>
            <xsl:when test="$elem.name = 'expan'"/>
            <xsl:when test="$elem.name = 'sic'"/>
            <xsl:when test="$elem.name = 'corr'"/>
            <xsl:when test="$elem.name = 'tuplet'"/>
            <xsl:when test="$elem.name = 'beam'"/>
            <xsl:when test="$elem.name = 'bTrem'"/>
            <xsl:when test="$elem.name = 'fTrem'"/>
            <xsl:when test="$elem.name = 'measure'"/>
            <xsl:when test="$elem.name = 'staff'"/>
            <xsl:when test="$elem.name = 'verse'"/>
            <xsl:when test="$elem.name = 'syl'"/>
            <xsl:when test="$elem.name = 'cpMark'"/>
            <xsl:when test="$elem/ancestor::mei:orig"/>
            <xsl:when test="$elem/ancestor::mei:abbr"/>
            <xsl:when test="$elem/ancestor::mei:sic"/>
            <xsl:otherwise>
                
                <xsl:if test="count($coreDraft//mei:*[@old.id = $ref.id]/@xml:id) = 0">
                    <xsl:message select="'spotted an error with ' || string-join($coreDraft//mei:*[@old.id = $ref.id]/@xml.id,', ') || ', looking for ' || $ref.id"/>                
                </xsl:if>
                <xsl:attribute name="sameas" select="'freidi-musicCore.xml#' || $coreDraft//mei:*[@old.id = $ref.id]/@xml:id"/>    
            
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- all @sameas references will be rewritten by the preceding template, which generates a @sameas for everything with an @xml:id -->
    <xsl:template match="mei:measure//mei:*/@sameas" mode="source"/>
    
    <xsl:template match="mei:appInfo" mode="source">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*" mode="#current"/>
            <application xmlns="http://www.music-encoding.org/ns/mei" xml:id="setupNewCore.xsl_v1.0.2" version="1.0.2">
                <name>setupNewCore.xsl</name>
                <xsl:comment>This version of setupNewCore.xsl is integrated into core_directSetup.xsl.</xsl:comment>
                <ptr target="https://github.com/Freischuetz-Digital/Tools/blob/develop/14%20reCore/setupNewCore.xsl"/>
            </application>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="mei:revisionDesc" mode="source">
        <xsl:copy>
            <change xmlns="http://www.music-encoding.org/ns/mei">
                <xsl:attribute name="n" select="1"/>
                <respStmt>
                    <persName>Johannes Kepper</persName>
                </respStmt>
                <changeDesc>
                    <p>Prepared mov<xsl:value-of select="$mov.n"/> for re-inclusion in the core with <ptr target="setupNewCore.xsl_v1.0.2"/>. Moved many attributes to the corresponding core file to reestablish the original core-source relation.</p>
                </changeDesc>
                <date isodate="{substring(string(current-date()),1,10)}"/>
            </change>
        </xsl:copy>
    </xsl:template>
    
    <!-- core-specific information to be removed from the source -->
    <xsl:template match="@pname[not(ancestor::mei:orig) and not(ancestor::mei:sic) and not(ancestor::mei:abbr)]" mode="source"/>
    <xsl:template match="@dur[not(ancestor::mei:orig) and not(ancestor::mei:sic) and not(ancestor::mei:abbr)]" mode="source"/>
    <xsl:template match="@dots[not(ancestor::mei:orig) and not(ancestor::mei:sic) and not(ancestor::mei:abbr)]" mode="source"/>
    <xsl:template match="@oct[not(ancestor::mei:orig) and not(ancestor::mei:sic) and not(ancestor::mei:abbr)]" mode="source"/>
    <xsl:template match="@artic[not(ancestor::mei:orig) and not(ancestor::mei:sic) and not(ancestor::mei:abbr)]" mode="source"/>
    <xsl:template match="@accid[not(ancestor::mei:orig) and not(ancestor::mei:sic) and not(ancestor::mei:abbr)]" mode="source"/>
    <xsl:template match="@accid.ges[not(ancestor::mei:orig) and not(ancestor::mei:sic) and not(ancestor::mei:abbr)]" mode="source"/>
    <xsl:template match="@grace[not(ancestor::mei:orig) and not(ancestor::mei:sic) and not(ancestor::mei:abbr)]" mode="source"/>
    <xsl:template match="@stem.mod[not(ancestor::mei:orig) and not(ancestor::mei:sic) and not(ancestor::mei:abbr)]" mode="source"/>
    <xsl:template match="mei:layer//@tstamp[not(ancestor::mei:orig) and not(ancestor::mei:sic) and not(ancestor::mei:abbr)]" mode="source"/>
    
    <!-- mode core -->
    
    <!-- remove temporary helpers -->
    <xsl:template match="@old.id" mode="core"/>
    <xsl:template match="mei:mSpace" mode="core">
        <mRest xmlns="http://www.music-encoding.org/ns/mei">
            <xsl:apply-templates select="node() | @*" mode="#current"/>
        </mRest>
    </xsl:template>
    
    <!-- adjust @startid and @endid -->
    <xsl:template match="@startid" mode="core">
        <xsl:param name="coreDraft" tunnel="yes" as="node()"/>
        
        <xsl:variable name="tokens" select="tokenize(normalize-space(.),' ')" as="xs:string*"/>
        <xsl:variable name="new.refs" as="xs:string*">
            <xsl:for-each select="$tokens">
                <xsl:variable name="current.token" select="." as="xs:string"/>
                <xsl:value-of select="$coreDraft//mei:*[@old.id = substring($current.token,2)]/@xml:id"/>
            </xsl:for-each>
        </xsl:variable>
        <xsl:attribute name="startid" select="'#' || string-join($new.refs,' #')"/>
    </xsl:template>
    <xsl:template match="@endid" mode="core">
        <xsl:param name="coreDraft" tunnel="yes" as="node()"/>
        
        <xsl:variable name="tokens" select="tokenize(normalize-space(.),' ')" as="xs:string*"/>
        <xsl:variable name="new.refs" as="xs:string*">
            <xsl:for-each select="$tokens">
                <xsl:variable name="current.token" select="." as="xs:string"/>
                <xsl:value-of select="$coreDraft//mei:*[@old.id = substring($current.token,2)]/@xml:id"/>
            </xsl:for-each>
        </xsl:variable>
        <xsl:attribute name="endid" select="'#' || string-join($new.refs,' #')"/>
    </xsl:template>
    
    
    <!-- generic copy template -->
    <xsl:template match="node() | @*" mode="#all">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
</xsl:stylesheet>