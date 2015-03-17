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
            <xd:p><xd:b>Created on:</xd:b> Jan 05, 2015</xd:p>
            <xd:p><xd:b>Author:</xd:b> Johannes Kepper</xd:p>
            <xd:p>
                This stylesheet merges a fully proofread source file with a pre-existing core 
                for that movement.  
            </xd:p>
            <xd:p>With the parameter $mode, it can be decided whether the stylesheet identifies the results of its execution and outputs
                them to a list of differences found (value 'probe', default), and if it should be executed without further notice (value
                'execute'). </xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:output method="xml" indent="yes"/>
    
    <!-- compares attributes between two specified elements, omitting xml:ids -->
    <xsl:function name="local:compareAttributes" as="node()*">
        <xsl:param name="source.elem" as="node()"/>
        <xsl:param name="core.elem" as="node()"/>
        
        <xsl:variable name="source.atts" select="$source.elem/(@* except @xml:id)" as="attribute()*"/>
        <xsl:variable name="core.atts" select="$core.elem/(@* except @xml:id)" as="attribute()*"/>
        
        <xsl:variable name="source.atts.names" select="$source.elem/(@* except @xml:id)/local-name()" as="xs:string*"/>
        <xsl:variable name="core.atts.names" select="$core.elem/(@* except @xml:id)/local-name()" as="xs:string*"/>
        
        <xsl:for-each select="$source.atts">
            <xsl:variable name="source.att" select="."/>
            <xsl:choose>
                <xsl:when test="$source.att = $core.atts">
                    <!-- the attribute with the same value exists both in the core and the source -->                        
                </xsl:when>
                <xsl:when test="local-name($source.att) = $core.atts.names">
                    <!-- the attribute has a different value -->
                    <diff type="att.value" source.value="{string($source.att)}" core.value="{string($core.atts[local-name() = local-name($source.att)])}"/>
                </xsl:when>
                <xsl:otherwise>
                    <!-- the attribute is missing from the core -->
                    <diff type="att.missing" missing.in="core" att="{local-name($source.att)}" value="{string($source.att)}"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>
        <xsl:for-each select="$core.atts">
            <xsl:variable name="core.att" select="."/>
            <xsl:choose>
                <xsl:when test="local-name($core.att) = $source.atts.names">
                    <!-- this attribute has been handled before -->
                </xsl:when>
                <xsl:otherwise>
                    <!-- the attribute is missing from the source -->
                    <diff type="att.missing" missing.in="source" att="{local-name($core.att)}" value="{string($core.att)}"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>
        
    </xsl:function>
    
    <!-- this function compares two measures -->
    <xsl:function name="local:compareMeasures" as="node()*">
        <xsl:param name="source.measure" as="node()"/>
        <xsl:param name="core.measure" as="node()"/>
        
        <xsl:variable name="att.diff" select="local:compareAttributes($source.measure,$core.measure)" as="node()*"/>
        
        <xsl:choose>
            <xsl:when test="count($att.diff) gt 0">
                <mismatch level="att" for="{$core.measure/@xml:id}">
                    <xsl:copy-of select="$att.diff"/>
                </mismatch>
            </xsl:when>
            <xsl:otherwise>
                <match level="att" for="{$core.measure/@xml:id}"/>
            </xsl:otherwise>
        </xsl:choose>
        
        <xsl:for-each select="$source.measure/mei:staff">
            <xsl:variable name="staff.n" select="@n"/>
            <xsl:copy-of select="local:compareStaff(.,$core.measure/mei:staff[@n = $staff.n])"/>
        </xsl:for-each>
        
    </xsl:function>
    
    <!-- creates profiles for all variants contained in a staff element and compares them with the core -->
    <xsl:function name="local:compareStaff" as="node()*">
        <xsl:param name="source.staff" as="node()"/>
        <xsl:param name="core.staff" as="node()"/>
        
        <xsl:choose>
            <!-- both source and core have different variants for this staff -->
            <xsl:when test="$core.staff//mei:app and $source.staff//mei:app">
    <!-- todo -->                
            </xsl:when>
            <!-- only the core provides alternatives -->
            <xsl:when test="$core.staff//mei:app">
    <!-- todo -->
            </xsl:when>
            <!-- only the source provides alternatives -->
            <xsl:when test="$source.staff//mei:app">
    <!-- todo -->
            </xsl:when>
            <!-- both source and core have only one variant that needs to be checked for equality -->
            <xsl:otherwise>
                
                <xsl:variable name="source.profile" select="local:getStaffProfile($source.staff)"/>
                <xsl:variable name="core.profile" select="local:getStaffProfile($core.staff)"/>
                                
                <xsl:if test="count($source.profile/mei:*) != count($core.profile/mei:*)">
                    <xsl:message terminate="no">probably different content in staff <xsl:value-of select="$source.staff/@xml:id"/>.</xsl:message>    
                </xsl:if>
                
                <xsl:copy-of select="local:compareStaffProfile($source.profile,$core.profile)"/>
                
            </xsl:otherwise>
        </xsl:choose>
        
    </xsl:function>
    
    <!-- compares to staff elements that have been cleaned from <apps> and identifies their differences -->
    <xsl:function name="local:compareStaffProfile" as="node()*">
        <xsl:param name="source.profile" as="node()"/>
        <xsl:param name="core.profile" as="node()"/>
        
        <!-- get all tstamps from the source and core -->
        <xsl:variable name="source.onsets" select="distinct-values($source.profile//@tstamp)" as="xs:string*"/>
        <xsl:variable name="core.onsets" select="distinct-values($core.profile//@tstamp)" as="xs:string*"/>
        
        <!-- get a list of all onsets, and a list of onsets shared by source and core -->
        <xsl:variable name="all.onsets" select="distinct-values(($source.onsets,$core.onsets))" as="xs:string*"/>
        <xsl:variable name="shared.onsets" select="$source.onsets[. = $core.onsets]" as="xs:string*"/>
        
        <!--<xsl:message select="'tstamps: ' || string-join($all.onsets,', ')"></xsl:message>-->
        
        <!-- iterate over all tstamps, handle them according to their use in core and source -->        
        <xsl:for-each select="$all.onsets">
            
            <xsl:variable name="current.onset" select="." as="xs:string"/>
            <xsl:choose>
                
                <!-- current tstamp is used in both source and core -->
                <xsl:when test="$current.onset = $shared.onsets">
                    
                    <!-- get pitches at a given tstamp -->
                    <xsl:variable name="source.pitches" select="distinct-values($source.profile/mei:*[@tstamp = $current.onset and @pnum]/@pnum)" as="xs:string*"/>
                    <xsl:variable name="core.pitches" select="distinct-values($source.profile/mei:*[@tstamp = $current.onset and @pnum]/@pnum)" as="xs:string*"/>
                    
                    <!-- deal with all pitches that are shared between core and source -->
                    <xsl:for-each select="$source.pitches[. = $core.pitches]">
                        <xsl:variable name="current.pitch" select="."/>
                        
                        <xsl:variable name="source.elem" select="$source.profile/mei:*[@tstamp = $current.onset and @pnum = $current.pitch][1]"/>
                        <xsl:variable name="core.elem" select="$core.profile/mei:*[@tstamp = $current.onset and @pnum = $current.pitch][1]"/>
                        
                        <!-- todo: make choose and trace error! -->
                        <xsl:if test="exists($source.elem) and exists($core.elem)">
                            <xsl:copy-of select="local:compareAttributes($source.elem,$core.elem)"/>
                        </xsl:if>
                    </xsl:for-each>
                    
                    <!-- deal with pitches only available in core -->
                    <xsl:for-each select="$core.pitches[not(. = $source.pitches)]">
                        <xsl:variable name="current.pitch" select="."/>
                        <xsl:message>triggered core</xsl:message>
                        <diff type="missing.pitch" missing.in="source" staff="{$core.profile/@n}" tstamp="{$current.onset}" existing.id="{$core.profile/mei:*[@tstamp = $current.onset and @pnum = $current.pitch]/@xml:id}"/>
                    </xsl:for-each>
                    
                    <!-- deal with pitches only available in source -->
                    <xsl:for-each select="$source.pitches[not(. = $core.pitches)]">
                        <xsl:message>triggered source</xsl:message>
                        
                        <xsl:variable name="current.pitch" select="."/>
                        
                        <diff type="missing.pitch" missing.in="core" staff="{$core.profile/@n}" tstamp="{$current.onset}" existing.id="{$source.profile/mei:*[@tstamp = $current.onset and @pnum = $current.pitch]/@xml:id}"/>
                    </xsl:for-each>
                    
                    
                    <!-- deal with elements that don't have pitches -->
                    <xsl:variable name="source.unpitched" select="$source.profile/mei:*[@tstamp = $current.onset and not(@pnum)]" as="node()*"/>
                    <xsl:variable name="core.unpitched" select="$core.profile/mei:*[@tstamp = $current.onset and not(@pnum)]" as="node()*"/>
                    
                    <xsl:for-each select="$source.unpitched">
                        <xsl:variable name="source.elem" select="." as="node()"/>
                        <xsl:variable name="name" select="local-name()"/>
                        
                        <xsl:choose>
                            <xsl:when test="$core.unpitched[local-name() = $name]">
                                <xsl:variable name="core.elem" select="$core.unpitched[local-name() = $name][1]" as="node()"/>
                                
                                <xsl:if test="count($core.unpitched[local-name() = $name]) gt 1">
                                    <xsl:message select="'multiple elements of type ' || $name || ' found near #' || $core.elem/@xml:id || '. Please check!'"/>
                                </xsl:if>
                                
                                <xsl:copy-of select="local:compareAttributes($source.elem,$core.elem)"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <diff type="missing.elem" missing.in="core" staff="{$core.profile/@n}" tstamp="{$current.onset}" existing.id="{@xml:id}"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:for-each>
                    
                    <xsl:for-each select="$core.unpitched">
                        <xsl:variable name="name" select="local-name()"/>
                        
                        <xsl:if test="not($source.unpitched[local-name() = $name])">
                            <diff type="missing.elem" missing.in="source" staff="{$core.profile/@n}" tstamp="{$current.onset}" existing.id="{@xml:id}"/>
                        </xsl:if>
                        
                    </xsl:for-each>
                    
                </xsl:when>
                
                <!-- current tstamp is used only in source -->
                <xsl:when test="$current.onset = $source.onsets">
                    
                    <xsl:for-each select="$source.profile/mei:*[@tstamp = $current.onset and @pnum]">
                        <diff type="missing.pitch" missing.in="core" staff="{$core.profile/@n}" tstamp="{$current.onset}" existing.id="{@xml:id}"/>
                    </xsl:for-each>
                    
                    <xsl:for-each select="$source.profile/mei:*[@tstamp = $current.onset and not(@pnum)]">
                        <diff type="missing.elem" missing.in="core" staff="{$core.profile/@n}" tstamp="{$current.onset}" existing.id="{@xml:id}"/>
                    </xsl:for-each>
                    
                </xsl:when>
                
                <!-- current tstamp is used only in core -->
                <xsl:when test="$current.onset = $core.onsets">
                    
                    <xsl:for-each select="$core.profile/mei:*[@tstamp = $current.onset and @pnum]">
                        <diff type="missing.pitch" missing.in="source" staff="{$core.profile/@n}" tstamp="{$current.onset}" existing.id="{@xml:id}"/>
                    </xsl:for-each>
                    
                    <xsl:for-each select="$core.profile/mei:*[@tstamp = $current.onset and not(@pnum)]">
                        <diff type="missing.elem" missing.in="source" staff="{$core.profile/@n}" tstamp="{$current.onset}" existing.id="{@xml:id}"/>
                    </xsl:for-each>
                    
                </xsl:when>
                
            </xsl:choose>
            
        </xsl:for-each>
        
        
    </xsl:function>
    
    
    <!-- creates a profile for a single staff element -->
    <xsl:function name="local:getStaffProfile" as="node()">
        <xsl:param name="staff" as="node()"/>
        
        <xsl:variable name="trans.semi" select="$staff/preceding::mei:*[(local-name() = 'staffDef' and @n = $staff/@n and @trans.semi) or (local-name() = 'scoreDef' and @trans.semi)][1]/@trans.semi" as="xs:string?"/>
        
        <xsl:variable name="staff.prep" as="node()">
            <xsl:apply-templates select="$staff" mode="profiling.prep">
                <xsl:with-param name="trans.semi" select="$trans.semi" tunnel="yes" as="xs:string?"/>
            </xsl:apply-templates>
        </xsl:variable>
        
        <events>
            <xsl:for-each select="$staff.prep//mei:*[@tstamp]">
                <xsl:sort select="@tstamp" data-type="number"/>
                <xsl:sort select="@pnum" data-type="number"/>
                <xsl:sort select="local-name()" data-type="text"/>
                
                <xsl:copy-of select="."/>
                
            </xsl:for-each>    
        </events>
        
    </xsl:function>
    
    <!-- calculates the MIDI pitch of a single note -->
    <xsl:function name="local:getMIDIpitch" as="xs:integer">
        <xsl:param name="note" as="element()"/>
        <xsl:param name="trans.semi" as="xs:integer"/>
        
        <xsl:variable name="oct" select="round((number($note/@oct) + 1) * 12) cast as xs:integer" as="xs:integer"/>
        <xsl:variable name="pname" as="xs:integer">
            <xsl:choose>
                <xsl:when test="$note/@pname = 'c'">0</xsl:when>
                <xsl:when test="$note/@pname = 'd'">2</xsl:when>
                <xsl:when test="$note/@pname = 'e'">4</xsl:when>
                <xsl:when test="$note/@pname = 'f'">5</xsl:when>
                <xsl:when test="$note/@pname = 'g'">7</xsl:when>
                <xsl:when test="$note/@pname = 'a'">9</xsl:when>
                <xsl:when test="$note/@pname = 'b'">11</xsl:when>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="accid" as="xs:integer">
            <xsl:choose>
                <xsl:when test="not($note/@accid)">0</xsl:when>
                <xsl:when test="$note/@accid = 'n'">0</xsl:when>
                <xsl:when test="$note/@accid = 's'">1</xsl:when>
                <xsl:when test="$note/@accid = 'ss'">2</xsl:when>
                <xsl:when test="$note/@accid = 'x'">1</xsl:when>
                <xsl:when test="$note/@accid = 'f'">-1</xsl:when>
                <xsl:when test="$note/@accid = 'ff'">-2</xsl:when>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="accid.ges" as="xs:integer">
            <xsl:choose>
                <xsl:when test="exists($note/@accid)">0</xsl:when>
                <xsl:when test="not($note/@accid.ges)">0</xsl:when>
                <xsl:when test="$note/@accid.ges = 'n'">0</xsl:when>
                <xsl:when test="$note/@accid.ges = 's'">1</xsl:when>
                <xsl:when test="$note/@accid.ges = 'ss'">2</xsl:when>
                <xsl:when test="$note/@accid.ges = 'x'">1</xsl:when>
                <xsl:when test="$note/@accid.ges = 'f'">-1</xsl:when>
                <xsl:when test="$note/@accid.ges = 'ff'">-2</xsl:when>
            </xsl:choose>
        </xsl:variable>
        
        <xsl:value-of select="$oct + $pname + $accid + $accid.ges + $trans.semi"/>
    </xsl:function>
    
    <xsl:param name="mode" select="'probe'"/>
    
    <!-- version of this stylesheet -->
    <xsl:variable name="xsl.version" select="'1.0.0'"/>
    
    <!-- gets global variables based on some general principles of the Freischütz Data Model -->
    <xsl:variable name="source.id" select="substring-before(/mei:mei/@xml:id,'_')" as="xs:string"/>
    <xsl:variable name="mov.id" select="substring-before((//mei:measure)[1]/@xml:id,'_measure')" as="xs:string"/>
    <xsl:variable name="mov.n" select="substring-after($mov.id,'_mov')" as="xs:string"/>
    
    <!-- perform checks if everythin is in place as expected -->
    <xsl:variable name="correctFolder" select="starts-with(reverse(tokenize(document-uri(/),'/'))[3],'12.1')" as="xs:boolean"/>
    <xsl:variable name="basePath" select="substring-before(document-uri(/),'/12')"/>
    <xsl:variable name="sourceThereAlready" select="doc-available(concat($basePath,'/13%20reCored/',$source.id,'/',$mov.id,'.xml'))" as="xs:boolean"/>
    <xsl:variable name="coreThereAlready" select="doc-available(concat($basePath,'/13%20reCored/core_mov',$mov.n,'.xml'))" as="xs:boolean"/>
    
    <xsl:variable name="source.raw" select="//mei:mei" as="node()"/>
    <xsl:variable name="core" select="doc(concat($basePath,'/13%20reCored/core_mov',$mov.n,'.xml'))//mei:mei" as="node()"/>
    
    <xsl:template match="/">
        
        <!--<xsl:if test="not($correctFolder)">
            <xsl:message terminate="yes" select="'You seem to use a file from the wrong folder. Relevant chunk of filePath is: ' || reverse(tokenize(document-uri(/),'/'))[3]"/>
        </xsl:if>-->
        
        <xsl:if test="$sourceThereAlready">
            <xsl:message terminate="yes" select="'There is already a processed version of the file in /13 reCored…'"/>
        </xsl:if>
        
        <xsl:if test="not($coreThereAlready)">
            <xsl:message terminate="yes" select="'There is no core file for mov' || $mov.n || ' yet. Please use setupNewCore.xsl first.'"/>
        </xsl:if>
        
        <!-- in source.preComp, a file almost similar to a core based on the source is generated. -->
        <xsl:variable name="source.preComp">
            <xsl:apply-templates mode="source.preComp"/>
        </xsl:variable>
        
        <!-- in compare.phase1, the actual comparison is executed -->
        <xsl:variable name="compare.phase1">
            <xsl:apply-templates select="$source.preComp//mei:score" mode="compare.phase1"/>
        </xsl:variable>
        
        <xsl:copy-of select="$compare.phase1"/>
        
        <!--<xsl:variable name="coreDraft">
            <xsl:apply-templates mode="coreDraft"/>
        </xsl:variable>
        
        <!-\- source file -\->
        <xsl:result-document href="{concat($basePath,'/13%20reCored/',$source.id,'/',$mov.id,'.xml')}">
            <xsl:apply-templates mode="source">
                <xsl:with-param name="coreDraft" select="$coreDraft" tunnel="yes"/>
            </xsl:apply-templates>
        </xsl:result-document>
        
        <!-\- core file -\->
        <xsl:result-document href="{concat($basePath,'/13%20reCored/_core_mov',$mov.n,'.xml')}">
            <xsl:apply-templates select="$coreDraft" mode="core"/>
        </xsl:result-document>-->
        
    </xsl:template>
    
    <!-- resolving choices into apps when necessary -->
    <xsl:template match="mei:choice" mode="source.preComp">
        <xsl:choose>
            <xsl:when test="(count(mei:corr) gt 1) or (count(mei:reg) gt 1)">
                <app xmlns="http://www.music-encoding.org/ns/mei" xml:id="{'c'||uuid:randomUUID()}">
                    <xsl:apply-templates select="node()" mode="#current"/>
                </app>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="mei:corr/node() | mei:reg/node()" mode="#current"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- only <corr> and <reg> are addressed in the core -->
    <xsl:template match="mei:sic" mode="source.preComp"/>
    <xsl:template match="mei:orig" mode="source.preComp"/>    
    
    <!-- <corr> is a result of incorrect durations in the parent layer -->
    <xsl:template match="mei:corr" mode="source.preComp">
        <rdg xmlns="http://www.music-encoding.org/ns/mei">
            <xsl:attribute name="xml:id" select="'c'||uuid:randomUUID()"/>
            <xsl:attribute name="source" select="'#' || $source.id"/>
            <xsl:apply-templates select="node()" mode="#current"></xsl:apply-templates>
        </rdg>
    </xsl:template>
    
    <!-- <reg> is a result of ambiguous control events -->
    <xsl:template match="mei:reg" mode="source.preComp">
        <rdg xmlns="http://www.music-encoding.org/ns/mei">
            <xsl:attribute name="xml:id" select="'c'||uuid:randomUUID()"/>
            <xsl:attribute name="source" select="'#' || $source.id"/>
            <xsl:apply-templates select="node()" mode="#current"/>
        </rdg>
    </xsl:template>
    
    <xsl:template match="mei:appInfo" mode="source.preComp">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*" mode="#current"/>
            <xsl:if test="not(exists(mei:application[@xml:id='merge2Core.xsl_v' || $xsl.version]))">
                <application xmlns="http://www.music-encoding.org/ns/mei">
                    <xsl:attribute name="xml:id" select="'merge2Core.xsl_v' || $xsl.version"/>
                    <xsl:attribute name="version" select="$xsl.version"/>
                    <name>merge2Core.xsl</name>
                    <ptr target="https://github.com/Freischuetz-Digital/Tools/blob/develop/13%20reCore/merge2Core.xsl"/>
                </application>
            </xsl:if>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="mei:revisionDesc" mode="source.preComp">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*" mode="#current"/>
            <change xmlns="http://www.music-encoding.org/ns/mei">
                <xsl:attribute name="n" select="count(mei:change) + 1"/>
                <respStmt>
                    <persName>Johannes Kepper</persName>
                </respStmt>
                <changeDesc>
                    <p>
                        Updated the core for mov<xsl:value-of select="$mov.n"/> from <xsl:value-of select="$mov.id"/>.xml with
                        <ptr target="merge2Core.xsl_v{$xsl.version}"/>. Now all differences after proofreading <xsl:value-of select="$mov.id"/>
                        are incorporated in this file.
                        All change attributes from <xsl:value-of select="$mov.id"/>.xml have been stripped, as they describe the processing
                        of a source, not this core. When tracing the genesis of this file, however, they have to be considered.
                    </p>
                </changeDesc>
                <date isodate="{substring(string(current-date()),1,10)}"/>
            </change>
        </xsl:copy>
    </xsl:template>
    
    <!-- source-specific information to be removed from the core -->
    <xsl:template match="@sameas" mode="source.preComp"/>
    <xsl:template match="@stem.dir" mode="source.preComp"/>
    <xsl:template match="@curvedir" mode="source.preComp"/>
    <xsl:template match="@place" mode="source.preComp"/>
    <xsl:template match="mei:facsimile" mode="source.preComp"/>
    <xsl:template match="@facs" mode="source.preComp"/>
    
    
    
    <!-- ***COMPARE.PHASE1*MODE*********************************** -->   
    
    
    
    <xsl:template match="mei:measure" mode="compare.phase1">
        <xsl:variable name="source.measure" select="." as="node()"/>
        <xsl:variable name="core.measure.id" select="substring-after($source.raw/id($source.measure/@xml:id)/@sameas,'#')" as="xs:string"/>
        <xsl:message select="'core.measure.id: ' || $core.measure.id"/>
        <xsl:variable name="coreMeasure" select="$core/id($core.measure.id)" as="node()"/>
        <xsl:copy-of select="local:compareMeasures($source.measure,$coreMeasure)"/>
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
    <xsl:template match="mei:mSpace" mode="profiling.prep">
        <mRest xmlns="http://www.music-encoding.org/ns/mei">
            <xsl:apply-templates select="node() | @*" mode="#current"/>
        </mRest>
    </xsl:template>
    <xsl:template match="@pname" mode="profiling.prep">
        <xsl:param name="trans.semi" tunnel="yes" as="xs:string?"/>
        <xsl:copy-of select="."/>
        <xsl:attribute name="pnum" select="local:getMIDIpitch(parent::mei:note,if($trans.semi) then(number($trans.semi) cast as xs:integer) else(0))"/>
    </xsl:template>
    
    <xsl:template match="comment()" mode="profiling.prep" priority="1"/>
    
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
    
    
    
<!-- todo: appInfo und change für source -->    
    
    <!-- standard copy template for all modes -->
    <xsl:template match="node() | @*" mode="#all">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
</xsl:stylesheet>