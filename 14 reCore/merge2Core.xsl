<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    xmlns:mei="http://www.music-encoding.org/ns/mei"
    xmlns:uuid="java:java.util.UUID"
    xmlns:xlink="http://www.w3.org/1999/xlink"
    xmlns:local="local"
    exclude-result-prefixes="xs math xd mei uuid local xlink"
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
        
        <xsl:variable name="diffs" as="node()*">
            <xsl:for-each select="$source.atts">
                <xsl:variable name="source.att" select="."/>
                <xsl:choose>
                    <xsl:when test="$source.att = $core.atts">
                        <!-- the attribute with the same value exists both in the core and the source -->                        
                    </xsl:when>
                    <xsl:when test="local-name($source.att) = $core.atts.names">
                        <!-- the attribute has a different value -->
                        <diff type="att.value" staff="{$source.raw/id($source.elem/@xml:id)/ancestor::mei:staff/@xml:id}" source.elem.name="{local-name($source.elem)}" source.elem.id="{$source.elem/@xml:id}" att.name="{local-name($source.att)}" source.value="{string($source.att)}" core.value="{string($core.atts[local-name() = local-name($source.att)])}" tstamp="{$source.elem/@tstamp}"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <!-- the attribute is missing from the core -->
                        <diff type="att.missing" staff="{$source.raw/id($source.elem/@xml:id)/ancestor::mei:staff/@xml:id}" source.elem.name="{local-name($source.elem)}" source.elem.id="{$source.elem/@xml:id}" missing.in="core" att.name="{local-name($source.att)}" source.value="{string($source.att)}" tstamp="{$source.elem/@tstamp}"/>
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
                        <diff type="att.missing" staff="{$source.raw/id($source.elem/@xml:id)/ancestor::mei:staff/@xml:id}" source.elem.name="{local-name($source.elem)}" source.elem.id="{$source.elem/@xml:id}" missing.in="source" att.name="{local-name($core.att)}" core.value="{string($core.att)}" tstamp="{$source.elem/@tstamp}"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:for-each>
        </xsl:variable>
        
        <sameas source="{$source.elem/@xml:id}" core="{$core.elem/@xml:id}" diffs="{count($diffs)}" elem.name="{local-name($source.elem)}" tstamp="{$source.elem/@tstamp}"/>
        <xsl:copy-of select="$diffs"/>
        
    </xsl:function>
    
    <!-- this function compares two measures -->
    <xsl:function name="local:compareMeasures" as="node()*">
        <xsl:param name="source.measure" as="node()"/>
        <xsl:param name="core.measure" as="node()"/>
        
        <xsl:copy-of select="local:compareAttributes($source.measure,$core.measure)"/>
        
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
                    <xsl:message terminate="no" select="$source.staff/@xml:id || ': expecting different content.'"></xsl:message>    
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
                    <xsl:variable name="core.pitches" select="distinct-values($core.profile/mei:*[@tstamp = $current.onset and @pnum]/@pnum)" as="xs:string*"/>
                    
                    <!-- deal with all pitches that are shared between core and source -->
                    <xsl:for-each select="$source.pitches[. = $core.pitches]">
                        <xsl:variable name="current.pitch" select="."/>
                        
                        <xsl:variable name="source.elem" select="$source.profile/mei:*[@tstamp = $current.onset and @pnum = $current.pitch][1]"/>
                        <xsl:variable name="core.elem" select="$core.profile/mei:*[@tstamp = $current.onset and @pnum = $current.pitch][1]"/>
                        
                        <!-- todo: check number of occurences of that pitch, then look if spaces are used in the source -->
                        <xsl:if test="count($source.profile/mei:*[@tstamp = $current.onset and @pnum = $current.pitch]) gt 1 or count($core.profile/mei:*[@tstamp = $current.onset and @pnum = $current.pitch]) gt 1">
                            <xsl:message terminate="no" select="'found multiple elements for pitch ' || upper-case($source.elem/@pname) || $source.elem/@oct || ' at tstamp ' || $current.onset || ' in staff ' || $source.profile/@staff.id"/>
                        </xsl:if>
                        
                        <xsl:choose>
                            <!-- normally, both elements should exist. If not, something must be wrong… -->
                            <xsl:when test="exists($source.elem) and exists($core.elem)">
                                <xsl:copy-of select="local:compareAttributes($source.elem,$core.elem)"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:message terminate="no" select="'Error while processing ' || $source.profile//@staff.id || ': problem while processing pnum ' || $current.pitch || ' at tstamp ' || $current.onset || '. Please check!'"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:for-each>
                    
                    <!-- deal with pitches only available in core -->
                    <xsl:for-each select="$core.pitches[not(. = $source.pitches)]">
                        <xsl:variable name="current.pitch" select="."/>
                        <diff type="missing.pitch" missing.in="source" staff="{$core.profile//@staff.id}" pitch="{$core.profile/mei:*[@tstamp = $current.onset and @pnum = $current.pitch][1]/concat(upper-case(@pname),@oct)}" pnum="{$current.pitch}" tstamp="{$current.onset}" existing.id="{$core.profile/mei:*[@tstamp = $current.onset and @pnum = $current.pitch][1]/@xml:id}"/>
                    </xsl:for-each>
                    
                    <!-- deal with pitches only available in source -->
                    <xsl:for-each select="$source.pitches[not(. = $core.pitches)]">
                        <xsl:variable name="current.pitch" select="."/>
                        <diff type="missing.pitch" missing.in="core" staff="{$core.profile//@staff.id}" pitch="{$source.profile/mei:*[@tstamp = $current.onset and @pnum = $current.pitch][1]/concat(upper-case(@pname),@oct)}" pnum="{$current.pitch}" tstamp="{$current.onset}" existing.id="{$source.profile/mei:*[@tstamp = $current.onset and @pnum = $current.pitch][1]/@xml:id}"/>
                    </xsl:for-each>
                    
                    <!-- deal with elements that don't have pitches -->
                    <xsl:variable name="source.unpitched" select="$source.profile/mei:*[@tstamp = $current.onset and not(@pnum)]" as="node()*"/>
                    <xsl:variable name="core.unpitched" select="$core.profile/mei:*[@tstamp = $current.onset and not(@pnum)]" as="node()*"/>
                    
                    <xsl:for-each select="$source.unpitched">
                        <xsl:variable name="source.elem" select="." as="node()"/>
                        <xsl:variable name="name" select="local-name()" as="xs:string"/>
                        
                        <xsl:choose>
                            <xsl:when test="$core.unpitched[local-name() = $name]">
                                <xsl:variable name="core.elem" select="$core.unpitched[local-name() = $name][1]" as="node()"/>
                                
                                <xsl:if test="count($core.unpitched[local-name() = $name]) gt 1">
                                    <xsl:message select="'multiple unpitched elements of type ' || $name || ' at tstamp #' || $current.onset || ' in staff ' || $source.profile/@staff.id || '. Please check!'"/>
                                </xsl:if>
                                
                                <xsl:copy-of select="local:compareAttributes($source.elem,$core.elem)"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <diff type="missing.elem" elem.name="{$name}" missing.in="core" staff="{$core.profile//@staff.id}" tstamp="{$current.onset}" existing.id="{@xml:id}"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:for-each>
                    
                    <xsl:for-each select="$core.unpitched">
                        <xsl:variable name="name" select="local-name()"/>
                        
                        <xsl:if test="not($source.unpitched[local-name() = $name])">
                            <diff type="missing.elem" elem.name="{$name}" missing.in="source" staff="{$core.profile//@staff.id}" tstamp="{$current.onset}" existing.id="{@xml:id}"/>
                        </xsl:if>
                    </xsl:for-each>
                    
                </xsl:when>
                
                <!-- current tstamp is used only in source -->
                <xsl:when test="$current.onset = $source.onsets">
                    
                    <xsl:for-each select="$source.profile/mei:*[@tstamp = $current.onset and @pnum]">
                        <diff type="missing.pitch" missing.in="core" staff="{$core.profile//@staff.id}" pitch="{concat(upper-case(@pname),@oct)}" pnum="{@pnum}" tstamp="{$current.onset}" existing.id="{@xml:id}"/>
                    </xsl:for-each>
                    
                    <xsl:for-each select="$source.profile/mei:*[@tstamp = $current.onset and not(@pnum)]">
                        <diff type="missing.elem" elem.name="{local-name()}" missing.in="core" staff="{$core.profile//@staff.id}" tstamp="{$current.onset}" existing.id="{@xml:id}"/>
                    </xsl:for-each>
                    
                </xsl:when>
                
                <!-- current tstamp is used only in core -->
                <xsl:when test="$current.onset = $core.onsets">
                    
                    <xsl:for-each select="$core.profile/mei:*[@tstamp = $current.onset and @pnum]">
                        <diff type="missing.pitch" missing.in="source" staff="{$core.profile//@staff.id}" pitch="{concat(upper-case(@pname),@oct)}" pnum="{@pnum}" tstamp="{$current.onset}" existing.id="{@xml:id}"/>
                    </xsl:for-each>
                    
                    <xsl:for-each select="$core.profile/mei:*[@tstamp = $current.onset and not(@pnum)]">
                        <diff type="missing.elem" elem.name="{local-name()}" missing.in="source" staff="{$core.profile//@staff.id}" tstamp="{$current.onset}" existing.id="{@xml:id}"/>
                    </xsl:for-each>
                    
                </xsl:when>
                
            </xsl:choose>
            
        </xsl:for-each>
        
        <!-- deal with elements without @tstamp -->
        <xsl:variable name="source.untimed" select="$source.profile/mei:*[not(@tstamp) and not(@pnum)]" as="node()*"/>
        <xsl:variable name="core.untimed" select="$core.profile/mei:*[not(@tstamp) and not(@pnum)]" as="node()*"/>
        
        <xsl:for-each select="$source.untimed">
            <xsl:variable name="source.elem" select="." as="node()"/>
            <xsl:variable name="name" select="name()" as="xs:string"/>
            
            <xsl:choose>
                <xsl:when test="$core.untimed[local-name() = $name]">
                    <xsl:variable name="core.elem" select="$core.untimed[local-name() = $name][1]" as="node()"/>
                    
                    <xsl:if test="count($core.untimed[local-name() = $name]) gt 1">
                        <xsl:message select="'multiple elements of type ' || $name || ' found near #' || $core.elem/@xml:id || '. Please check!'"/>
                    </xsl:if>
                    
                    <xsl:copy-of select="local:compareAttributes($source.elem,$core.elem)"/>
                </xsl:when>
                <xsl:otherwise>
                    <diff type="missing.elem" elem.name="{$name}" missing.in="core" staff="{$core.profile//@staff.id}" existing.id="{@xml:id}"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>
        
        <xsl:for-each select="$core.untimed[not(local-name() = distinct-values($source.untimed/local-name()))]">
            <diff type="missing.elem" elem.name="{local-name()}" missing.in="source" staff="{$core.profile//@staff.id}" existing.id="{@xml:id}"/>
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
        
        <events staff.id="{$staff/@xml:id}">
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
    <xsl:variable name="basePath" select="substring-before(document-uri(/),'/1')"/>
    <xsl:variable name="sourceThereAlready" select="doc-available(concat($basePath,'/14%20reCored/',$source.id,'/',$mov.id,'.xml'))" as="xs:boolean"/>
    <xsl:variable name="coreThereAlready" select="doc-available(concat($basePath,'/14%20reCored/core_mov',$mov.n,'.xml'))" as="xs:boolean"/>
    
    <xsl:variable name="source.raw" select="//mei:mei" as="node()"/>
    <xsl:variable name="core" select="doc(concat($basePath,'/14%20reCored/core_mov',$mov.n,'.xml'))//mei:mei" as="node()"/>
    
    <xsl:variable name="all.sources.so.far" as="xs:string+">
        <xsl:value-of select="substring-before(substring-after($core//mei:change[@n = '1']//mei:p,'from '),'_mov')"/>
        <xsl:for-each select="$core//mei:change[@n != '1']">
            <xsl:value-of select="substring-before(substring-after(.//mei:p,'from '),'_mov')"/>
        </xsl:for-each>
    </xsl:variable>
    
    <xsl:template match="/">
        
        <!--<xsl:if test="not($correctFolder)">
            <xsl:message terminate="yes" select="'You seem to use a file from the wrong folder. Relevant chunk of filePath is: ' || reverse(tokenize(document-uri(/),'/'))[3]"/>
        </xsl:if>-->
        
        <xsl:if test="$sourceThereAlready">
            <xsl:message terminate="yes" select="'There is already a processed version of the file in /13 reCored…'"/>
        </xsl:if>
        
        <xsl:if test="not($coreThereAlready)">
            <xsl:message terminate="yes" select="'There is no core file for mov' || $mov.n || ' yet. Please use setupNewCore.xsl first. ' || concat($basePath,'/14%20reCored/core_mov',$mov.n,'.xml')"/>
        </xsl:if>
        
        <!-- in source.preComp, a file almost similar to a core based on the source is generated. -->
        <xsl:variable name="source.preComp">
            <xsl:apply-templates mode="source.preComp"/>
        </xsl:variable>
        
        <!-- in compare.phase1, the actual comparison is executed -->
        <xsl:variable name="compare.phase1">
            <xsl:apply-templates select="$source.preComp//mei:score" mode="compare.phase1"/>
        </xsl:variable>
        
        
    <!-- todo: decide which rdg is most relevant and merge source into it -->
        
        <xsl:variable name="source.prep" as="node()">
            <xsl:apply-templates select="$source.preComp//mei:score" mode="profiling.prep"/>
        </xsl:variable>
        <xsl:variable name="diff.groups">
            <xsl:copy-of select="local:groupDiffs($compare.phase1,$source.prep)"/>
        </xsl:variable>
        
        <!--<xsl:copy-of select="$diff.groups"/>-->
        
        <xsl:variable name="newCore" as="node()">
            <xsl:apply-templates select="$core" mode="generate.apps">
                <xsl:with-param name="diff.groups" select="$diff.groups" as="node()" tunnel="yes"/>
                <xsl:with-param name="source.prep" select="$source.prep" as="node()" tunnel="yes"/>
                <xsl:with-param name="mov.id" select="$mov.id" as="xs:string" tunnel="yes"/>
            </xsl:apply-templates>
        </xsl:variable>
        
        <xsl:copy-of select="$newCore"/>
        
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
            <xsl:when test="./mei:expan">
                <xsl:apply-templates select="mei:expan/node()" mode="#current"/>
            </xsl:when>
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
                        All change elements from <xsl:value-of select="$mov.id"/>.xml have been stripped, as they describe the processing
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
    <xsl:template match="@corresp" mode="source.preComp"/>
    
    
    <!-- ***COMPARE.PHASE1*MODE*********************************** -->   
    
    
    
    <xsl:template match="mei:measure" mode="compare.phase1">
        <xsl:variable name="source.measure" select="." as="node()"/>
        <xsl:variable name="core.measure.id" select="substring-after($source.raw/id($source.measure/@xml:id)/@sameas,'#')" as="xs:string"/>
        <!--<xsl:message select="'core.measure.id: ' || $core.measure.id"/>-->
        <xsl:variable name="coreMeasure" select="$core/id($core.measure.id)" as="node()"/>
        <xsl:copy-of select="local:compareMeasures($source.measure,$coreMeasure)"/>
    </xsl:template>
    
    
    
    <!-- ***groupDiffs*MODE*********************************** -->
    
    <!-- groups differences, first by staff, then into ranges of timestamps, where all notes in between vary. -->
    <xsl:function name="local:groupDiffs" as="node()">
        <xsl:param name="diffsContainer" as="node()"/>
        <xsl:param name="source.preComp" as="node()"/>
        
        <xsl:variable name="diffs" select="$diffsContainer//diff" as="node()*"/>
        
        <xsl:message select="'****starting groupDiffs function****'"/>
        
        <xsl:variable name="staves">
            <xsl:for-each-group select="$diffs" group-by="substring-after(@staff,'_')">
                
                <!-- creates a container for all affected staves -->
                <staff xml:id="{'core_' || current-grouping-key()}" diffCount="{count(current-group())}">
                    <xsl:variable name="staff.diffs" select="current-group()" as="node()*"/>
                    <xsl:variable name="source.staff" select="$source.preComp//mei:*[@xml:id = ($source.id || '_' || current-grouping-key())]" as="node()"/>
                    <xsl:variable name="core.staff" select="$core/id('core_' || current-grouping-key())" as="node()"/>
                    
                    <!-- get all tstamps in that measure -->
                    <xsl:variable name="base.tstamps" as="xs:double*">
                        <xsl:variable name="preSort" select="distinct-values(($core.staff//@tstamp, $source.staff//@tstamp))" as="xs:double*"/>
                        <xsl:for-each select="$preSort">
                            <xsl:sort select="number(.)" data-type="number"/>
                            <xsl:value-of select="number(.)"/>
                        </xsl:for-each>
                    </xsl:variable>
                    <!-- get all tstamps with differences -->
                    <xsl:variable name="diff.tstamps" as="xs:double*">
                        <xsl:variable name="preSort" select="distinct-values($staff.diffs//@tstamp)" as="xs:double*"/>
                        <xsl:for-each select="$preSort">
                            <xsl:sort select="number(.)" data-type="number"/>
                            <xsl:value-of select="number(.)"/>
                        </xsl:for-each>
                    </xsl:variable>
                    <!-- get the positions in $base.tstamps array where differences occur -->
                    <xsl:variable name="differing.positions" as="xs:integer*">
                        <xsl:for-each select="(1 to count($base.tstamps))">
                            <xsl:variable name="pos" select="position()" as="xs:integer"/>
                            <xsl:if test="$base.tstamps[$pos] = $diff.tstamps">
                                <xsl:value-of select="$pos"/>
                            </xsl:if>
                        </xsl:for-each>    
                    </xsl:variable>
                    <!-- group differences into ranges of uninterupted difference -->
                    <xsl:variable name="ranges">
                        <xsl:copy-of select="local:getDifferingRanges($differing.positions,0)"/>
                    </xsl:variable>
                    
                    <!-- debug: if there are no ranges, something must be wrong. At least one range with the duration of one tstamp must be affected in this staff! -->
                    <xsl:if test="count($ranges/range) = 0">
                        <xsl:message select="'found no differing ranges for ' || $core.staff/@xml:id || ', though there are differences with @tstamps. Please check the following diffs:'"/>
                        <xsl:for-each select="$staff.diffs">
                            <xsl:message select="."/>
                        </xsl:for-each>
                        <xsl:message terminate="yes" select="'processing stopped'"/>
                    </xsl:if>
                    
                    <!-- iterate all ranges for that staff -->
                    <xsl:for-each select="$ranges/range">
                        <xsl:variable name="range" select="." as="node()"/>
                        
                        <xsl:variable name="tstamp.first" select="$base.tstamps[$range/number(@start)]"/>
                        <xsl:variable name="tstamp.last" select="$base.tstamps[$range/number(@end)]"/>
                        
                        <xsl:variable name="diffs" select="$staff.diffs[number(@tstamp) ge $tstamp.first and number(@tstamp) le $tstamp.last]" as="node()+"/>
                        
                        <!-- debug: if there are no diffs in this range, something must be wrong -->
                        <xsl:if test="count($diffs) = 0">
                            <xsl:message select="'found no diffs for the range from ' || $tstamp.first || ' to ' || $tstamp.last || ' in ' || $core.staff/@xml:id || ', though there should be some. Please check the following diffs:'"/>
                            <xsl:for-each select="$staff.diffs">
                                <xsl:message select="."/>
                            </xsl:for-each>
                            <xsl:message terminate="yes" select="'processing stopped'"/>
                        </xsl:if>
                        
                        <xsl:choose>
                            <!-- check if values are numeric -->
                            <xsl:when test="number($tstamp.first) = $tstamp.first and number($tstamp.last) = $tstamp.last">
                                <diffGroup tstamp.first="{$tstamp.first}" tstamp.last="{$tstamp.last}" diffCount="{count($diffs)}">
                                    
                                    <!--<xsl:copy-of select="$diffs"/>-->
                                    <xsl:copy-of select="local:identifyDifferingPitches($source.preComp,$diffs)"/>
                                </diffGroup>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:message select="'problem with the following range in ' || $core.staff/@xml:id"/>
                                <xsl:message select="$range"/>
                            </xsl:otherwise>
                        </xsl:choose>
                        
                        
                    </xsl:for-each>
                    
                    <!-- get all diffs affecting elements without a tstamp -->
                    <otherDiffs>
                        <xsl:for-each select="$staff.diffs">
                            <xsl:variable name="diff" select="." as="node()"/>
                            <xsl:if test="not($diff/@tstamp)">
                                <xsl:copy-of select="$diff"/>
                            </xsl:if>
                        </xsl:for-each>
                    </otherDiffs>
                    
                </staff>
            </xsl:for-each-group>
        </xsl:variable>
        <results>
            <unmatched>
                <xsl:for-each select="$diffs">
                    <xsl:variable name="diff" select="."/>
                    <xsl:if test="not(some $otherDiff in $staves//diff satisfies deep-equal($diff,$otherDiff))">
                        <xsl:copy-of select="$diff"/>
                    </xsl:if>
                </xsl:for-each>
            </unmatched>
            <groups diffs="{count($staves//diff)}">
                <xsl:message select="'affected staves: ' || count($staves/staff)"/>
                <xsl:copy-of select="$staves"/>
            </groups>
            <similarities>
                <xsl:copy-of select="$diffsContainer//sameas[@diffs = '0']"/>
            </similarities>
            <rawDiffs count="{count($diffs)}">
                <xsl:copy-of select="$diffs"/>
            </rawDiffs>
        </results>
        
        <xsl:message select="'****ending groupDiffs function****'"/>
        
    </xsl:function>
    
    <xsl:function name="local:getDifferingRanges" as="node()*">
        <xsl:param name="differing.positions" as="xs:integer*"/>
        <xsl:param name="position" as="xs:integer"/>
        <xsl:choose>
            <xsl:when test="some $pos in $differing.positions satisfies ($pos gt $position)">
                <xsl:variable name="start.pos" select="$differing.positions[. gt $position][1]" as="xs:integer"/>
                <xsl:variable name="end.pos" select="if($start.pos + 1 = $differing.positions) then(local:getEndPos($differing.positions,$start.pos + 1)) else($start.pos)" as="xs:integer"/>
                
                <range start="{$start.pos}" end="{$end.pos}"/>
                <xsl:copy-of select="local:getDifferingRanges($differing.positions,$end.pos + 1)"/>
            </xsl:when>
        </xsl:choose>
    </xsl:function>
    
    <xsl:function name="local:identifyDifferingPitches" as="node()*">
        <xsl:param name="source.preComp" as="node()"/>
        <xsl:param name="diffs" as="node()+"/>
        
        <xsl:choose>
            <xsl:when test="count($diffs) lt 2 or count($diffs[@type = 'missing.pitch']) lt 2">
                <xsl:copy-of select="$diffs"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:for-each select="$diffs">
                    <xsl:variable name="diff" select="." as="node()"/>
                    <xsl:choose>
                        <xsl:when test="not($diff/@type = 'missing.pitch')">
                            <xsl:copy-of select="$diff"/>
                        </xsl:when>
                        <xsl:when test="$diff/@missing.in = 'core'">
                            <xsl:variable name="tstamp" select="$diff/@tstamp" as="xs:string"/>
                            <xsl:variable name="core.diff" select="$diffs/descendant-or-self::diff[@type = 'missing.pitch' and @tstamp = $tstamp and @missing.in = 'source']" as="node()?"/>
                            <xsl:variable name="source.dur" select="local:getDur($source.preComp//mei:*[@xml:id = $diff/@existing.id])"/>
                            <xsl:variable name="core.dur" select="if(exists($core.diff)) then(local:getDur($core/id($core.diff/@existing.id))) else('NaN')" as="xs:string"/>
                            
                            <xsl:choose>
                                <xsl:when test="exists($core.diff) and $source.dur = $core.dur">
                                    <xsl:message select="'merging diff at ' || $diff/@staff || ', tstamp ' || $diff/@tstamp"/>
                                    
                                    <xsl:variable name="source.elem" select="$source.preComp//mei:*[@xml:id = $diff/@existing.id]" as="node()"/>
                                    <xsl:variable name="core.elem" select="$core/id($core.diff/@existing.id)" as="node()"/>
                                    <xsl:variable name="better.diff" select="local:compareAttributes($source.elem,$core.elem)[local-name() = 'diff']" as="node()*"/>
                                    
                                    <xsl:choose>
                                        <!-- go with the different.pitch type now… -->
                                        <xsl:when test="$better.diff and 1 = 2">
                                            <xsl:copy-of select="$better.diff"/>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <diff type="different.pitch" staff="{$diff/@staff}" tstamp="{$diff/@tstamp}" source.pitch="{$diff/@pitch}" source.pnum="{$diff/@pnum}" core.pitch="{$core.diff/@pitch}" core.pnum="{$core.diff/@pnum}" source.id="{$diff/@existing.id}" core.id="{$core.diff/@existing.id}"/>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                    
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:copy-of select="$diff"/>
                                </xsl:otherwise>
                            </xsl:choose>
                            
                        </xsl:when>
                        <xsl:when test="$diff/@missing.in = 'source'">
                            <xsl:variable name="tstamp" select="$diff/@tstamp" as="xs:string"/>
                            <xsl:variable name="source.diff" select="$diffs/descendant-or-self::diff[@type = 'missing.pitch' and @tstamp = $tstamp and @missing.in = 'core']" as="node()?"/>
                            <xsl:variable name="core.dur" select="local:getDur($core/id($diff/@existing.id))"/>
                            <xsl:variable name="source.dur" select="if(exists($source.diff)) then(local:getDur($source.preComp//mei:*[@xml:id = $source.diff/@existing.id])) else('NaN')" as="xs:string"/>
                            
                            <xsl:choose>
                                <xsl:when test="exists($source.diff) and $source.dur = $core.dur">
                                    <!-- this diff should have been addressed above, and is thus removed here. -->
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:copy-of select="$diff"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:when>
                    </xsl:choose>
                </xsl:for-each>
            </xsl:otherwise>
        </xsl:choose>
        
        
        
    </xsl:function>
    
    <xsl:function name="local:getDur" as="xs:string">
        <xsl:param name="elem" as="node()"/>
        
        <xsl:choose>
            <xsl:when test="$elem/@dur">
                <xsl:value-of select="$elem/@dur"/>
            </xsl:when>
            <xsl:when test="$elem/parent::mei:chord/@dur">
                <xsl:value-of select="$elem/parent::mei:chord/@dur"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message select="'unable to obtain duration for element ' || $elem/@xml:id"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <xsl:function name="local:getEndPos" as="xs:integer">
        <xsl:param name="differing.positions" as="xs:integer*"/>
        <xsl:param name="position" as="xs:integer"/>
        
        <xsl:choose>
            <xsl:when test="$position + 1 = $differing.positions">
                <xsl:value-of select="local:getEndPos($differing.positions,$position + 1)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$position"/>
            </xsl:otherwise>
        </xsl:choose>
        
    </xsl:function>
    
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
            <xsl:attribute name="dur" select="parent::mei:chord/@dur"/>
            <xsl:apply-templates select="node() | @*" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="mei:clef[not(@tstamp)]" mode="profiling.prep">
        <xsl:copy>
            <xsl:variable name="tstamp" as="xs:string">
                <xsl:choose>
                    <xsl:when test="following-sibling::mei:*/descendant-or-self::mei:*[@tstamp]">
                        <xsl:value-of select="number((following-sibling::mei:*/descendant-or-self::mei:*[@tstamp])[1]/@tstamp) - 0.005"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="number((preceding-sibling::mei:*/descendant-or-self::mei:*[@tstamp])[1]/@tstamp) + 0.005"/>
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
    
    
    <!-- mode generate.apps -->
    <xsl:template match="mei:mdiv" mode="generate.apps">
        <xsl:param name="mov.id" as="xs:string" tunnel="yes"/>
        <xsl:choose>
            <xsl:when test="substring-after(@xml:id,'_') = substring-after($mov.id,'_')">
                <xsl:next-match/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy-of select="."/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="mei:staff" mode="generate.apps">
        <xsl:param name="diff.groups" as="node()" tunnel="yes"/>
        <xsl:param name="source.prep" as="node()" tunnel="yes"/>
        
        <xsl:variable name="staff.id" select="@xml:id" as="xs:string"/>
        <xsl:variable name="staff.id.source" select="replace($staff.id,'core_',concat($source.id,'_'))" as="xs:string"/>
        <xsl:variable name="staff.n" select="@n" as="xs:string"/>
        <xsl:variable name="core.staff" select="." as="node()"/>
        
        <xsl:choose>
            <!-- no variance to deal with for this staff -->
            <xsl:when test="not($staff.id = $diff.groups//staff/@xml:id) and not($staff.id.source = $diff.groups//staff/@xml:id)">
                <xsl:next-match/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="source.staff" select="$source.prep//mei:staff[@xml:id = $staff.id.source]" as="node()"/>
                <xsl:variable name="local.diff.groups" select="$diff.groups//staff[@xml:id = ($staff.id,$staff.id.source)]/diffGroup" as="node()+"/>
                
                <!-- element needs to be copied -->
                <xsl:copy>
                    <xsl:apply-templates select="@*" mode="#current"/>
                    
                    <!-- determine how many layers are involved -->
                    <xsl:choose>
                        <xsl:when test="count($core.staff/mei:layer) = 1 and count($source.staff/mei:layer) = 1">
                            <xsl:choose>
                                <!-- if there is only one local.diff.group -->
                                <xsl:when test="count($local.diff.groups) = 1">
                                    
                                    <!-- "copy" the single child layer, together with its attributes -->
                                    <layer xmlns="http://www.music-encoding.org/ns/mei">
                                        <xsl:apply-templates select="child::mei:layer/@*" mode="#current"/>
                                        
                                        <xsl:apply-templates select="child::mei:layer/node()" mode="get.by.tstamps">
                                            <xsl:with-param name="local.diff.groups" select="$local.diff.groups" as="node()+" tunnel="yes"/>
                                            <xsl:with-param name="source.staff" select="$source.staff" as="node()" tunnel="yes"/>
                                        </xsl:apply-templates>    
                                        
                                    </layer>
                                    
                                </xsl:when>
                                <!-- otherwise separation by tstamp is more complicated -->
                                <xsl:otherwise>
                                    <xsl:message select="'Need to resolve ' || count($local.diff.groups) || ' diff ranges for ' || $staff.id"/>    
                                </xsl:otherwise>
                            </xsl:choose>
                            
                        </xsl:when>
                        <xsl:otherwise>
                            <!-- resolving of layers required! -->
                            <xsl:message select="'need to deal with multiple layers when creating app(s) for ' || $staff.id"/>
                        </xsl:otherwise>
                    </xsl:choose>
                    
                </xsl:copy>
                
            </xsl:otherwise>
        </xsl:choose>
        
    </xsl:template>
    
    <!-- *** mode get.by.tstamps ********************* -->
    <!-- used to select contents of a staff depending on tstamps -->
    
    <!-- elements which have a tstamp, like notes and rests -->
    <xsl:template match="mei:*[@tstamp]" mode="get.by.tstamps">
        <xsl:param name="before.tstamp" as="xs:double?" tunnel="yes" required="no"/>
        <xsl:param name="from.tstamp" as="xs:double?" tunnel="yes" required="no"/>
        <xsl:param name="to.tstamp" as="xs:double?" tunnel="yes" required="no"/>
        <xsl:param name="after.tstamp" as="xs:double?" tunnel="yes" required="no"/>
        
        <xsl:variable name="tstamp" select="number(@tstamp)" as="xs:double"/>
        
        <xsl:choose>
            <!-- when a range for tstamps is included -->
            <xsl:when test="$from.tstamp and $to.tstamp">
                <!-- copy only if tstamp falls into the range -->
                <xsl:if test="$tstamp ge $from.tstamp and $tstamp le $to.tstamp">
                    <xsl:copy>
                        <xsl:apply-templates select="node() | @*" mode="#current"/>
                    </xsl:copy>
                </xsl:if>
            </xsl:when>
            <!-- when only a starting tstamp is provided -->
            <xsl:when test="$before.tstamp and not($after.tstamp)">
                <!-- copy only if tstamp is lower than desired last tstamp-->
                <xsl:if test="$tstamp lt $before.tstamp">
                    <xsl:copy>
                        <xsl:apply-templates select="node() | @*" mode="#current"/>
                    </xsl:copy>
                </xsl:if>
            </xsl:when>
            <!-- when only an ending tstamp is provided -->
            <xsl:when test="$after.tstamp and not($before.tstamp)">
                <!-- copy only if tstamp is higher than desired starting tstamp-->
                <xsl:if test="$tstamp gt $after.tstamp">
                    <xsl:copy>
                        <xsl:apply-templates select="node() | @*" mode="#current"/>
                    </xsl:copy>
                </xsl:if>
            </xsl:when>
            <!-- when a non-inclusive range is desired -->
            <xsl:when test="$before.tstamp and $after.tstamp">
                <!-- copy only if tstamp is between end points-->
                <xsl:if test="$tstamp gt $after.tstamp and $tstamp lt $before.tstamp">
                    <xsl:copy>
                        <xsl:apply-templates select="node() | @*" mode="#current"/>
                    </xsl:copy>
                </xsl:if>
            </xsl:when>
            <xsl:otherwise>
                <xsl:next-match/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- container elements which have no tstamp on their own, like beams and tuplets -->
    <xsl:template match="mei:*[not(@tstamp) and child::mei:*/@tstamp]" mode="get.by.tstamps">
        <xsl:param name="local.diff.groups" as="node()+" tunnel="yes" required="no"/>
        <xsl:param name="source.staff" as="node()" tunnel="yes"/>
        
        <xsl:variable name="lowest.contained.tstamp" select="min(child::mei:*[@tstamp]/number(@tstamp))" as="xs:double"/>
        <xsl:variable name="highest.contained.tstamp" select="max(child::mei:*[@tstamp]/number(@tstamp))" as="xs:double"/>
        <xsl:variable name="contained.tstamps" select="child::mei:*[@tstamp]/number(@tstamp)" as="xs:double+"/>
        
        <xsl:variable name="sources.so.far" select="if(ancestor::mei:rdg) then(tokenize(replace(ancestor::mei:rdg[1]/@source,'#',''),' ')) else($all.sources.so.far)" as="xs:string+"/>
        
        <xsl:choose>
            <!-- when there is only one diff in this measure -->
            <xsl:when test="count($local.diff.groups) = 1">
                
                <xsl:variable name="diff.first.tstamp" select="number(($local.diff.groups//@tstamp.first)[1])" as="xs:double"/>
                <xsl:variable name="diff.last.tstamp" select="number(($local.diff.groups//@tstamp.last)[1])" as="xs:double"/>
                
                <xsl:variable name="preceding.content" select="some $tstamp in $contained.tstamps satisfies ($tstamp lt $diff.first.tstamp)" as="xs:boolean"/>
                <xsl:variable name="following.content" select="some $tstamp in $contained.tstamps satisfies ($tstamp gt $diff.last.tstamp)" as="xs:boolean"/>
                <xsl:variable name="affected.by.diff" select="some $tstamp in $contained.tstamps satisfies($tstamp ge $diff.first.tstamp and $tstamp le $diff.last.tstamp)" as="xs:boolean"/>
                
                <xsl:message select="ancestor::mei:staff/@xml:id || ': resolving a ' || local-name(.) || ' from lowest tstamp ' || $lowest.contained.tstamp || ' to highest tstamp ' || $highest.contained.tstamp || '. diff between ' || $diff.first.tstamp || ' and ' || $diff.last.tstamp"/>
                
                <xsl:choose>
                    <!-- when there is no diff for the range of tstamps that this element contains -->
                    <xsl:when test="not($affected.by.diff)">
                        <xsl:message select="'not affected'"/>
                        <xsl:next-match/>
                    </xsl:when>
                    
                    <!-- when the diff range is fully contained in this container -->
                    <xsl:when test="$lowest.contained.tstamp le $diff.first.tstamp and $highest.contained.tstamp ge $diff.last.tstamp">
                        <xsl:message select="'fully wrapped in container'"/>
                        <xsl:copy>
                            <xsl:apply-templates select="@*" mode="#current"/>
                            <xsl:apply-templates select="node()" mode="#current">
                                <xsl:with-param name="before.tstamp" select="$diff.first.tstamp" as="xs:double" tunnel="yes"/>
                            </xsl:apply-templates>
                            
                            <xsl:variable name="first.rdg.id" select="'c'||uuid:randomUUID()" as="xs:string"/>
                            <xsl:variable name="second.rdg.id" select="'c'||uuid:randomUUID()" as="xs:string"/>
                            <xsl:variable name="annot.id" select="'c'||uuid:randomUUID()" as="xs:string"/>
                            
                            <app xmlns="http://www.music-encoding.org/ns/mei" xml:id="{'a'||uuid:randomUUID()}">
                                <rdg xml:id="{$first.rdg.id}" source="#{string-join($sources.so.far,' #')}">
                                    <xsl:apply-templates select="node()" mode="#current">
                                        <xsl:with-param name="from.tstamp" select="number($local.diff.groups[1]/@tstamp.first)" as="xs:double" tunnel="yes"/>
                                        <xsl:with-param name="to.tstamp" select="number($local.diff.groups[1]/@tstamp.last)" as="xs:double" tunnel="yes"/>
                                    </xsl:apply-templates>
                                </rdg>
                                <rdg xml:id="{$second.rdg.id}" source="#{$source.id}">
                                    
                                    <xsl:apply-templates select="$source.staff/mei:layer/child::mei:*" mode="adjustMaterial">
                                        <xsl:with-param name="from.tstamp" select="$diff.first.tstamp" as="xs:double" tunnel="yes"/>
                                        <xsl:with-param name="to.tstamp" select="$diff.last.tstamp" as="xs:double" tunnel="yes"/>
                                    </xsl:apply-templates>
                                    
                                    <!-- todo: fill in correct elements -->
                                </rdg>
                            </app>
                            <annot xmlns="http://www.music-encoding.org/ns/mei" xml:id="{$annot.id}" type="diff" corresp="#{$source.id} #{string-join($sources.so.far,' #')}" plist="#{$first.rdg.id || ' #' || $second.rdg.id}">
                                <xsl:copy-of select="$local.diff.groups"/>
                            </annot>
                            
                            <xsl:apply-templates select="node()" mode="#current">
                                <xsl:with-param name="after.tstamp" select="$diff.last.tstamp" as="xs:double" tunnel="yes"/>
                            </xsl:apply-templates>
                        </xsl:copy>
                    </xsl:when>
                    <!-- diff range extends around both ends of this container -->
                    <xsl:when test="$lowest.contained.tstamp ge $diff.first.tstamp and $highest.contained.tstamp le $diff.last.tstamp">
                        <xsl:message select="'uh oh!'"></xsl:message>
                    </xsl:when>
                    
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                
            </xsl:otherwise>
        </xsl:choose>
        
    </xsl:template>
    
<!-- *** mode adjustMaterial -->
<!-- this mode is used to create new elements in the core to point at from a source. 
        By definition, this occurs only in variants -->    
    
    <xsl:template match="@xml:id" mode="adjustMaterial">
        <xsl:attribute name="xml:id" select="'r'||uuid:randomUUID()"/>
        <xsl:attribute name="synch" select="."/>
    </xsl:template>
    
    <!-- this attribute is only generated for comparison and thus removed again -->
    <xsl:template match="@pnum" mode="adjustMaterial"/>
    
    <!-- decide if things with a tstamp need to be included or not
        * if so, look for grace notes that are attached to the note as well -->
    <!-- todo: adjust tstamps when necessary -->
    <xsl:template match="mei:*[@tstamp]" mode="adjustMaterial">
        <xsl:param name="from.tstamp" tunnel="yes" as="xs:double?"/>
        <xsl:param name="to.tstamp" tunnel="yes" as="xs:double?"/>
        
        <xsl:choose>
            <xsl:when test="not(exists($from.tstamp) and exists($to.tstamp))">
                <xsl:next-match/>
            </xsl:when>
            <xsl:when test="number(@tstamp) ge $from.tstamp and number(@tstamp) le $to.tstamp">
                <xsl:copy>
                    <xsl:apply-templates select="node() | @*" mode="#current"/>
                </xsl:copy>
            </xsl:when>
            <xsl:otherwise/>
        </xsl:choose>
    </xsl:template>
    
    <!-- decide if elements like beam and tuplet need to be preserved, based on the tstamps of their children -->
    <xsl:template match="mei:*[not(@tstamp) and .//@tstamp]" mode="adjustMaterial">
        <xsl:param name="from.tstamp" tunnel="yes" as="xs:double?"/>
        <xsl:param name="to.tstamp" tunnel="yes" as="xs:double?"/>
        <xsl:choose>
            <xsl:when test="not($from.tstamp and $to.tstamp)">
                <xsl:next-match/>
            </xsl:when>
            <xsl:when test="some $tstamp in .//@tstamp satisfies (number($tstamp) ge $from.tstamp and number($tstamp) le $to.tstamp)">
                <xsl:copy>
                    <xsl:apply-templates select="node() | @*" mode="#current"/>
                </xsl:copy>
            </xsl:when>
            <xsl:otherwise/>
        </xsl:choose>
    </xsl:template>
    
    
<!-- todo: appInfo und change für source -->    
    
    <!-- standard copy template for all modes -->
    <xsl:template match="node() | @*" mode="#all">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
</xsl:stylesheet>