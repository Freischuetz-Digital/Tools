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
            <xd:p>
                TODO: 
                * beatRpt
                * halfmRpt
                (* mRpt2)
                (* multiRpt)
                * mSpaces as mRpt
            </xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:output method="xml" indent="yes"/>
    
    <xsl:variable name="xsl.version" select="'1.0.0'"/>
    <xsl:variable name="docPath" select="document-uri(/)"/>
    <xsl:variable name="cpMarksPath" select="substring-before($docPath,'/musicSources/') || '/musicSources/sourcePrep/11.1%20ShortcutList/cpMarks.xml'" as="xs:string"/>
    <xsl:variable name="cpMarks" select="doc($cpMarksPath)//mei:cpMark" as="node()*"/>    
    <xsl:variable name="music" select=".//mei:music" as="node()"/>
    
    <xsl:template match="/">
        
        <xsl:variable name="included.cpMarks">
            <xsl:apply-templates mode="include.cpMarks"/>
        </xsl:variable>
        <xsl:variable name="resolvedTrems">
            <xsl:apply-templates select="$included.cpMarks" mode="resolveTrems"/>
        </xsl:variable>
        <xsl:variable name="resolvedRpts">
            <xsl:apply-templates mode="resolveRpts" select="$resolvedTrems"/>
        </xsl:variable>
        <xsl:variable name="cpInstructions">
            <xsl:apply-templates select="$resolvedRpts//mei:cpMark" mode="prepare.cpMarks"/>
        </xsl:variable>
        <xsl:variable name="cpMarks.enhanced" select="$resolvedRpts//mei:cpMark"/>
        
        <xsl:variable name="cpInstructions.all" select="distinct-values($cpInstructions//copy[not(@sourceStaff.id = $cpInstructions//copy/@targetStaff.id)]/@cpMark.id)"/>
        <xsl:variable name="cpInstructions.second" select="distinct-values($cpInstructions//copy[@sourceStaff.id = $cpInstructions//copy/@targetStaff.id]/@cpMark.id)"/>
        <xsl:variable name="cpInstructions.first" select="$cpInstructions.all[not(. = $cpInstructions.second)]"/>
        
        <xsl:message select="'total: ' || count($cpMarks.enhanced) || ', first: ' || count($cpInstructions.first) || ', second: ' || count($cpInstructions.second)"></xsl:message>
        
        <!-- Test if everything is correct about the workflow -->
        <xsl:if test="$cpMarks.enhanced//@ref.startid">
            <xsl:message terminate="yes" select="'cpMarks with @ref.startid are not supported yet. Please update resolveShortCuts.xsl.'"/>
        </xsl:if>
        <xsl:if test="$music//mei:beatRpt">
            <xsl:message terminate="yes" select="'beatRpts are not supported yet. Please update resolveShortCuts.xsl'"/>
        </xsl:if>
        <xsl:if test="$music//mei:halfmRpt">
            <xsl:message terminate="yes" select="'halfmRpts are not supported yet. Please update resolveShortCuts.xsl'"/>
        </xsl:if>
        
        <xsl:variable name="resolvedMarks">
            <xsl:apply-templates mode="resolveMarks" select="$resolvedRpts">
                <xsl:with-param name="cpInstructions" select="$cpInstructions" tunnel="yes"/>
                <xsl:with-param name="cpMarks.enhanced" select="$cpMarks.enhanced" tunnel="yes"/>
                <xsl:with-param name="cpMark.ids" select="$cpInstructions.first" as="xs:string*" tunnel="yes"/>
            </xsl:apply-templates>
        </xsl:variable>
        
        <xsl:variable name="resolvedAllMarks">
            <xsl:apply-templates mode="resolveMarks" select="$resolvedMarks">
                <xsl:with-param name="cpInstructions" select="$cpInstructions" tunnel="yes"/>
                <xsl:with-param name="cpMarks.enhanced" select="$cpMarks.enhanced" tunnel="yes"/>
                <xsl:with-param name="cpMark.ids" select="$cpInstructions.second" as="xs:string*" tunnel="yes"/>
            </xsl:apply-templates>
        </xsl:variable>
        
        
        <xsl:copy-of select="$resolvedAllMarks"/>
        <!--<xsl:copy-of select="$cpInstructions"/>-->
    </xsl:template>
    
    <xsl:template match="mei:appInfo" mode="include.cpMarks">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*" mode="#current"/>
            <application xmlns="http://www.music-encoding.org/ns/mei">
                <xsl:attribute name="xml:id" select="'resolveShortCuts.xsl_v' || $xsl.version"/>
                <xsl:attribute name="version" select="$xsl.version"/>
                <name>resolveShortCuts.xsl</name>
                <ptr target="https://github.com/Freischuetz-Digital/Tools/blob/develop/12.1%20resolve%20ShortCuts/resolveShortCuts.xsl"/>
            </application>
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
                <changeDesc>
                    <p>
                        Resolved all shortcuts by using information from <xsl:value-of select="$cpMarksPath"/>
                        using <ptr target="resolveShortCuts.xsl_v{$xsl.version}"/>. Also resolved all mRpt, bTrems
                        and fTrems.
                    </p>
                </changeDesc>
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
            <xsl:attribute name="meter.count" select="(preceding::mei:scoreDef[@meter.count])[1]/@meter.count"/>
            <xsl:apply-templates select="node() | @*" mode="#current"/>
            <xsl:apply-templates select="$cpMarks[@freidi.measure = $measure.id]" mode="include.cpMarks"/>
            <!--<xsl:message select="'cpMarks for measure ' || $measure.id || ': ' || count($cpMarks[@freidi.measure = $measure.id])"/>-->
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="mei:cpMark" mode="include.cpMarks">
        <xsl:copy>
            <xsl:attribute name="xml:id" select="'x' || uuid:randomUUID()"/>
            <xsl:apply-templates select="node() | @*" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="@freidi.measure" mode="include.cpMarks"/>
    
    <!-- resolving bTrems -->
    <xsl:template match="mei:bTrem[not(parent::mei:orig)]" mode="resolveTrems">
        <choice xmlns="http://www.music-encoding.org/ns/mei" xml:id="c{uuid:randomUUID()}">
            <orig>
                <xsl:copy>
                    <xsl:apply-templates select="node() | @*" mode="#current"/>
                </xsl:copy>
            </orig>
            <reg>
                <xsl:variable name="elem" select="child::mei:*" as="node()"/>
                <xsl:variable name="dur" select="1 div number($elem/@dur)"/>
                <xsl:variable name="dots" select="if($elem/@dots) then(number($elem/@dots)) else(0)"/>
                <xsl:variable name="totalDur" select="(2 * $dur) - ($dur div math:pow(2,$dots))" as="xs:double"/>
                <xsl:variable name="count" select="($totalDur div ((1 div 8) div number(substring($elem/@stem.mod,1,1)))) cast as xs:integer" as="xs:integer"/>
                <xsl:variable name="tstamp" select="number(@tstamp)" as="xs:double"/>
                
                <xsl:if test="not($elem/@stem.mod)">
                    <xsl:message select="local-name($elem) || '[#' || $elem/@xml:id || '] inside bTrem misses @stem.mod'"/>
                </xsl:if>
                <xsl:variable name="measperf" select="number(substring-before($elem/@stem.mod,'slash')) * 8"/>
                
                <xsl:variable name="meter.unit" select="(ancestor::mei:measure/preceding::mei:scoreDef[@meter.unit])[1]/@meter.unit cast as xs:integer" as="xs:integer"/>
                <xsl:variable name="tstamp.step" select="$meter.unit div number($measperf)" as="xs:double"/>
                
                <!--<xsl:message select="$totalDur || ' dur makes ' || $count || ' found'"></xsl:message>-->
                
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
                
            </reg>
        </choice>
    </xsl:template>
    
    <!-- resolving fTrems -->
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
    
    <xsl:template match="mei:chord | mei:note[not(parent::mei:chord)]" mode="resolveTrems">
        <xsl:param name="dur"/>
        <xsl:param name="tstamp"/>
        <xsl:choose>
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
            <xsl:otherwise>
                <xsl:next-match/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="mei:note[parent::mei:chord]" mode="resolveTrems">
        <xsl:next-match/>
    </xsl:template>
    
    <!-- mode resolveRpts -->
    <xsl:template match="mei:mRpt[not(parent::mei:orig)]" mode="resolveRpts">
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
                
                <xsl:variable name="preceding.measure" select="ancestor::mei:measure/preceding::mei:measure[not(mei:staff[@n = $staff.n]/mei:layer[@n = $layer.n]/mei:mRpt)][1]"/>
                <xsl:variable name="corresponding.layer" select="if($layer.hasN) then($preceding.measure/mei:staff[@n = $staff.n]/mei:layer[@n = $layer.n]) else($preceding.measure/mei:staff[@n = $staff.n]/mei:layer)" as="node()"/>
                <xsl:apply-templates select="$corresponding.layer/mei:*" mode="adjustMaterial"/>
            </expan>
        </choice>
    </xsl:template>

    <!-- things that were resolved in the preceding measure and are just copied into this one don't need to keep the orig… -->
    <xsl:template match="mei:choice" mode="adjustMaterial">
        <xsl:apply-templates select="mei:reg/mei:* | mei:expan/mei:*" mode="#current"/>
    </xsl:template>
    
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
    
    <xsl:template match="@sameas" mode="adjustMaterial"/>
    <xsl:template match="@stayWithMe" mode="adjustMaterial"/>
    
    <xsl:template match="@oct" mode="adjustMaterial">
        <xsl:param name="oct.dis" as="xs:integer?" tunnel="yes"/>
        <xsl:attribute name="oct" select="number(string(.)) + (if($oct.dis) then($oct.dis) else(0))"/>
    </xsl:template>
    
    <xsl:template match="mei:layer" mode="adjustMaterial">
        <xsl:apply-templates select="node()" mode="#current"/>
    </xsl:template>
    
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
                    <xsl:variable name="graces" as="node()+">
                        <xsl:for-each select="$grace.IDs">
                            <xsl:sequence select="$music/id(replace(.,'#',''))"/>
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
    <xsl:template match="mei:measure[.//mei:mRpt]" mode="resolveRpts">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*" mode="#current"/>
            
            <xsl:variable name="affectedStaves" select="mei:staff[.//mei:mRpt]/@n" as="xs:string*"/>
            <xsl:variable name="preceding.measure" select="preceding::mei:measure[1]"/>
            <xsl:variable name="measure" select="."/>
            
            <xsl:for-each select="$affectedStaves">
                <xsl:variable name="staff.n" select="."/>
                <xsl:variable name="targetMeasure" select="$measure/preceding::mei:measure[mei:staff[@n = $staff.n and not(.//mei:mRpt) and not(.//mei:mSpace)]][1]"/>
                <xsl:variable name="controlEvents" select="$targetMeasure/mei:*[@staff = $staff.n and not(local-name() = 'cpMark')]"/>
                
                <!--<xsl:message select="count($controlEvents) || ' controlEvents from mRpt #' || ($measure/mei:staff[@n = $staff.n]//mei:mRpt)[1]/@xml:id"/>-->
                
                <xsl:for-each select="$controlEvents">
                    <choice xmlns="http://www.music-encoding.org/ns/mei" xml:id="c{uuid:randomUUID()}">
                        <abbr type="mRpt"/>
                        <expan evidence="#{($measure/mei:staff[@n = $staff.n]//mei:mRpt)[1]/@xml:id}">
                            <xsl:apply-templates select="." mode="adjustMaterial"/>
                        </expan>
                    </choice>    
                </xsl:for-each>
            </xsl:for-each>    
        </xsl:copy>
    </xsl:template>
    
    <!-- mode resolveMarks -->
    <xsl:template match="mei:cpMark" mode="resolveMarks">
        <xsl:param name="cpMark.ids" as="xs:string*" tunnel="yes"/>
        
        <xsl:variable name="staff.n" select="@staff" as="xs:string"/>
        <xsl:variable name="staff" select="ancestor::mei:measure/mei:staff[@n = $staff.n]" as="node()"/>
        
        <xsl:choose>
            <!-- this cpMark is processed in a different run -->
            <xsl:when test="not(@xml:id = $cpMark.ids)">
                <xsl:next-match/>
            </xsl:when>
            
            <xsl:when test="$staff//mei:mRpt and starts-with(@tstamp2,'0m+') and @ref.offset = '-1m+1'">
                <!--This cpMark is just a mRpt and already encoded as such.-->
                <xsl:if test="not(ends-with(@tstamp2,'m+' || string(number(parent::mei:measure/@meter.count) + 0)))">
                    <xsl:message>something's wrong here…</xsl:message>
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
    
    <xsl:template match="mei:layer" mode="resolveMarks">
        <xsl:param name="cpInstructions" tunnel="yes"/>
        <xsl:param name="cpMarks.enhanced" tunnel="yes"/>
        <xsl:param name="cpMark.ids" as="xs:string*" tunnel="yes"/>
        
        <xsl:variable name="staff.id" select="parent::mei:staff/@xml:id"/>
        <xsl:variable name="layer" select="."/>
        <xsl:choose>
            <!-- when the current staff isn't mentioned as a target for copying in music, just copy as everything… -->
            <xsl:when test="not($staff.id = $cpInstructions//@targetStaff.id)">
                <xsl:next-match/>
            </xsl:when>
            <!-- there must be an instruction to copy in music, so resolve it -->
            <xsl:otherwise>
                
                <xsl:variable name="probable.cpInstructions" select="$cpInstructions/descendant-or-self::*[@targetStaff.id = $staff.id]"/>
                <xsl:variable name="local.cpMarks" select="$cpMarks.enhanced/descendant-or-self::*[@xml:id = $probable.cpInstructions/@cpMark.id and @xml:id = $cpMark.ids]"/>
                
                <xsl:if test="count($probable.cpInstructions) gt 1 and count($local.cpMarks) gt 1">
                    <xsl:message select="'multiple cpInstructions for layer in ' || $staff.id || ', at least two in the same run. Are there really two beatRpt?'"/>
                </xsl:if>
                
                <xsl:variable name="local.cpInstructions" as="node()*">
                    <xsl:perform-sort select="$probable.cpInstructions/descendant-or-self::*[@cpMark.id = $cpMark.ids]">
                        <xsl:sort select="@target.tstamp.first" data-type="number"/>
                        <xsl:sort select="@target.tstamp.last" data-type="number"/>
                    </xsl:perform-sort>
                </xsl:variable>
                
                <xsl:if test="count($local.cpMarks) != count($local.cpInstructions)">
                    <xsl:message select="'something is wrong for ' || $staff.id"/>
                </xsl:if>
                
                <xsl:choose>
                    
                    <!-- cpMarks processed in different iteration (there is a second iteration for copy instructions that refer to a measure which itself
                        copies in music) -->
                    <xsl:when test="count($local.cpMarks) = 0">
                        <xsl:next-match/>
                    </xsl:when>
                    
                    <!-- only one layer (so far) -->
                    <xsl:when test="count(parent::mei:staff/mei:layer) = 1">
                        
                        <xsl:choose>
                            
                            <!-- no cpMark specifies a layer, 
                                or: 
                                they refer to the current layer/@n (even though ther eis only one layer), 
                                or:
                                they refer to layer 1, and the current layer has no layer/@n -->
                            <xsl:when test="not($local.cpMarks/@layer) or 
                                (every $layer.ref in $local.cpMarks/@layer satisfies $layer.ref = $layer/@n) or
                                ((every $layer.ref in $local.cpMarks/@layer satisfies $layer.ref = '1') and not($layer/@n))">
                                <xsl:copy>
                                    <xsl:apply-templates select="@*" mode="#current"/>
                                    
                                    <xsl:for-each select="(1 to count($local.cpMarks))">
                                        <xsl:variable name="j" select="."/>
                                        
                                        <xsl:apply-templates select="$layer/node()" mode="#current">
                                            <xsl:with-param name="tstamp.after" select="if($j = 1) then(0) else($local.cpInstructions[$j - 1]/@target.tstamp.last)" as="xs:double" tunnel="yes"/>
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
                                                
                                                <!-- sourceLayer scheint nicht zu klappen -->
                                                <xsl:variable name="sourceLayer" as="node()">
                                                    <xsl:choose>
                                                        <xsl:when test="$local.cpMarks[$j]/@ref.layer">
                                                            <xsl:sequence select="$music/id($local.cpInstructions[$j]/@sourceStaff.id)/mei:layer[@n = $local.cpMarks[$j]/@ref.layer]"/>
                                                        </xsl:when>
                                                        <xsl:otherwise>
                                                            <xsl:sequence select="$music/id($local.cpInstructions[$j]/@sourceStaff.id)/mei:layer[1]"/>
                                                        </xsl:otherwise>
                                                    </xsl:choose>
                                                </xsl:variable>
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
                                                <xsl:apply-templates select="$sourceLayer" mode="adjustMaterial">
                                                    <xsl:with-param name="oct.dis" select="$oct.dis" as="xs:integer" tunnel="yes"/>
                                                    <xsl:with-param name="tstamp.first" select="number($local.cpInstructions[$j]/@target.tstamp.first)" as="xs:double" tunnel="yes"/>
                                                    <xsl:with-param name="tstamp.last" select="number($local.cpInstructions[$j]/@target.tstamp.last)" as="xs:double" tunnel="yes"/>
                                                </xsl:apply-templates>
                                            </expan>
                                        </choice>
                                        
                                    </xsl:for-each>
                                    
                                    <xsl:apply-templates select="$layer/node()" mode="#current">
                                        <xsl:with-param name="tstamp.after" select="$local.cpInstructions[last()]/@target.tstamp.last" as="xs:double" tunnel="yes"/>
                                    </xsl:apply-templates>
                                    
                                </xsl:copy>
                            </xsl:when>
                        
                            <!-- cpMark gets only a specific layer -->
                            <xsl:when test="count($local.cpMarks) = 1 and $local.cpMarks[1]/@layer">
                                
                                <xsl:choose>
                                    <!-- this is the right layer – treat like the cpMark get's everything -->
                                    <xsl:when test="not($layer/@n) or $local.cpMarks[1]/@layer = '1'">
                                        <xsl:copy>
                                            <xsl:apply-templates select="@*" mode="#current"/>
                                            
                                            <xsl:apply-templates select="node()" mode="#current">
                                                <xsl:with-param name="tstamp.before" select="number($local.cpInstructions[1]/@target.tstamp.first)" as="xs:double" tunnel="yes"/>
                                            </xsl:apply-templates>
                                            
                                            <choice xmlns="http://www.music-encoding.org/ns/mei" xml:id="c{uuid:randomUUID()}">
                                                <abbr type="cpMark" tstamp="{$local.cpInstructions[1]/@target.tstamp.first}" tstamp2="0m+{$local.cpInstructions[1]/@target.tstamp.last}">
                                                    <xsl:apply-templates select="node()" mode="#current">
                                                        <xsl:with-param name="tstamp.first" select="number($local.cpInstructions[1]/@target.tstamp.first)" as="xs:double" tunnel="yes"/>
                                                        <xsl:with-param name="tstamp.last" select="number($local.cpInstructions[1]/@target.tstamp.last)" as="xs:double" tunnel="yes"/>
                                                    </xsl:apply-templates>
                                                </abbr>
                                                <expan evidence="#{$local.cpMarks[1]/@xml:id}">
                                                    
                                                    <!-- sourceLayer scheint nicht zu klappen -->
                                                    <xsl:variable name="sourceLayer" as="node()">
                                                        <xsl:choose>
                                                            <xsl:when test="$local.cpMarks[1]/@ref.layer">
                                                                <xsl:sequence select="$music/id($local.cpInstructions[1]/@sourceStaff.id)/mei:layer[@n = $local.cpMarks[1]/@ref.layer]"/>
                                                            </xsl:when>
                                                            <xsl:otherwise>
                                                                <xsl:sequence select="$music/id($local.cpInstructions[1]/@sourceStaff.id)/mei:layer[1]"/>
                                                            </xsl:otherwise>
                                                        </xsl:choose>
                                                    </xsl:variable>
                                                    <xsl:variable name="oct.dis" as="xs:integer">
                                                        <xsl:choose>
                                                            <xsl:when test="$local.cpMarks[1]/@dis = '8' and $local.cpMarks[1]/@dis.place = 'above'">1</xsl:when>
                                                            <xsl:when test="$local.cpMarks[1]/@dis = '15' and $local.cpMarks[1]/@dis.place = 'above'">2</xsl:when>
                                                            <xsl:when test="$local.cpMarks[1]/@dis = '22' and $local.cpMarks[1]/@dis.place = 'above'">3</xsl:when>
                                                            <xsl:when test="$local.cpMarks[1]/@dis = '8' and $local.cpMarks[1]/@dis.place = 'below'">-1</xsl:when>
                                                            <xsl:when test="$local.cpMarks[1]/@dis = '15' and $local.cpMarks[1]/@dis.place = 'below'">-2</xsl:when>
                                                            <xsl:when test="$local.cpMarks[1]/@dis = '22' and $local.cpMarks[1]/@dis.place = 'below'">-3</xsl:when>
                                                            <xsl:otherwise>0</xsl:otherwise>
                                                        </xsl:choose>
                                                    </xsl:variable>
                                                    <xsl:apply-templates select="$sourceLayer" mode="adjustMaterial">
                                                        <xsl:with-param name="oct.dis" select="$oct.dis" as="xs:integer" tunnel="yes"/>
                                                        <xsl:with-param name="tstamp.first" select="number($local.cpInstructions[1]/@target.tstamp.first)" as="xs:double" tunnel="yes"/>
                                                        <xsl:with-param name="tstamp.last" select="number($local.cpInstructions[1]/@target.tstamp.last)" as="xs:double" tunnel="yes"/>
                                                    </xsl:apply-templates>
                                                </expan>
                                            </choice>
                                            
                                            <xsl:apply-templates select="node()" mode="#current">
                                                <xsl:with-param name="tstamp.after" select="number($local.cpInstructions[1]/@target.tstamp.last)" as="xs:double" tunnel="yes"/>
                                            </xsl:apply-templates>
                                            
                                        </xsl:copy>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:message terminate="yes" select="'cpMarks.xml references a layer for ' || $staff.id || ', but this staff contains only one layer. Please check! '"></xsl:message>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </xsl:when>
                            
                            <xsl:when test="count($local.cpMarks) gt 1">
                                <xsl:message terminate="yes" select="'resolveShortCuts.xsl needs to learn how to resolve multiple cpMarks for the very same staff and layer. Look for template matching mei:layer in mode resolveMarks.'"/>
                                
                                <xsl:copy>
                                    <xsl:apply-templates select="@*" mode="#current"/>
                                    
                                    <xsl:for-each select="(1 to count($local.cpMarks))">
                                        <xsl:variable name="j" select="."/>
                                        <xsl:variable name="breakStarts"/>
                                        
                                        <xsl:apply-templates select="$layer/node()" mode="#current">
                                            <xsl:with-param name="tstamp.after" select="if($j = 1) then(0) else($local.cpInstructions[$j - 1]/@target.tstamp.last)" as="xs:double" tunnel="yes"/>
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
                                                
                                                <!-- sourceLayer scheint nicht zu klappen -->
                                                <xsl:variable name="sourceLayer" as="node()">
                                                    <xsl:choose>
                                                        <xsl:when test="$local.cpMarks[$j]/@ref.layer">
                                                            <xsl:sequence select="$music/id($local.cpInstructions[$j]/@sourceStaff.id)/mei:layer[@n = $local.cpMarks[$j]/@ref.layer]"/>
                                                        </xsl:when>
                                                        <xsl:otherwise>
                                                            <xsl:sequence select="$music/id($local.cpInstructions[$j]/@sourceStaff.id)/mei:layer[1]"/>
                                                        </xsl:otherwise>
                                                    </xsl:choose>
                                                </xsl:variable>
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
                                                <xsl:apply-templates select="$sourceLayer" mode="adjustMaterial">
                                                    <xsl:with-param name="oct.dis" select="$oct.dis" as="xs:integer" tunnel="yes"/>
                                                    <xsl:with-param name="tstamp.first" select="number($local.cpInstructions[$j]/@target.tstamp.first)" as="xs:double" tunnel="yes"/>
                                                    <xsl:with-param name="tstamp.last" select="number($local.cpInstructions[$j]/@target.tstamp.last)" as="xs:double" tunnel="yes"/>
                                                </xsl:apply-templates>
                                            </expan>
                                        </choice>
                                        
                                    </xsl:for-each>
                                    
                                    <xsl:apply-templates select="$layer/node()" mode="#current">
                                        <xsl:with-param name="tstamp.after" select="$local.cpInstructions[last()]/@target.tstamp.last" as="xs:double" tunnel="yes"/>
                                    </xsl:apply-templates>
                                </xsl:copy>
                                                            
                            </xsl:when>
                            
                            <xsl:otherwise>
                                <xsl:message terminate="yes">I must have missed something…</xsl:message>
                            </xsl:otherwise>
                            
                            
                        </xsl:choose>
                    </xsl:when>
                    
                    <!-- multiple layers already exist -->
                    <xsl:otherwise>
                        
                        
                        <xsl:choose>
                            <!-- if no explicit layer is indicated, put it in the first -->
                            <xsl:when test="count($local.cpMarks) = 1 and (not($local.cpMarks[1]/@layer) and not(preceding-sibling::mei:layer)) or ($local.cpMarks[1]/@layer = @n)">
                                <xsl:copy>
                                    <xsl:apply-templates select="@*" mode="#current"/>
                                    
                                    <xsl:apply-templates select="node()" mode="#current">
                                        <xsl:with-param name="tstamp.before" select="number($local.cpInstructions[1]/@target.tstamp.first)" as="xs:double" tunnel="yes"/>
                                    </xsl:apply-templates>
                                    
                                    <choice xmlns="http://www.music-encoding.org/ns/mei" xml:id="c{uuid:randomUUID()}">
                                        <abbr type="cpMark" tstamp="{$local.cpInstructions[1]/@tstamp.first}" tstamp2="0m+{$local.cpInstructions[1]/@tstamp.last}">
                                            <xsl:apply-templates select="node()" mode="#current">
                                                <xsl:with-param name="tstamp.first" select="number($local.cpInstructions[1]/@target.tstamp.first)" as="xs:double" tunnel="yes"/>
                                                <xsl:with-param name="tstamp.last" select="number($local.cpInstructions[1]/@target.tstamp.last)" as="xs:double" tunnel="yes"/>
                                            </xsl:apply-templates>
                                        </abbr>
                                        <expan evidence="#{$local.cpMarks[1]/@xml:id}">
                                            <xsl:variable name="sourceLayer" as="node()">
                                                <xsl:choose>
                                                    <xsl:when test="$local.cpMarks[1]/@ref.layer">
                                                        <xsl:sequence select="$music/id($local.cpInstructions[1]/@sourceStaff.id)/mei:layer[@n = $local.cpMarks[1]/@ref.layer]"/>
                                                    </xsl:when>
                                                    <xsl:otherwise>
                                                        <xsl:sequence select="$music/id($local.cpInstructions[1]/@sourceStaff.id)/mei:layer[1]"/>
                                                    </xsl:otherwise>
                                                </xsl:choose>
                                            </xsl:variable>
                                            <xsl:variable name="oct.dis" as="xs:integer">
                                                <xsl:choose>
                                                    <xsl:when test="$local.cpMarks[1]/@dis = '8' and $local.cpMarks[1]/@dis.place = 'above'">1</xsl:when>
                                                    <xsl:when test="$local.cpMarks[1]/@dis = '15' and $local.cpMarks[1]/@dis.place = 'above'">2</xsl:when>
                                                    <xsl:when test="$local.cpMarks[1]/@dis = '22' and $local.cpMarks[1]/@dis.place = 'above'">3</xsl:when>
                                                    <xsl:when test="$local.cpMarks[1]/@dis = '8' and $local.cpMarks[1]/@dis.place = 'below'">-1</xsl:when>
                                                    <xsl:when test="$local.cpMarks[1]/@dis = '15' and $local.cpMarks[1]/@dis.place = 'below'">-2</xsl:when>
                                                    <xsl:when test="$local.cpMarks[1]/@dis = '22' and $local.cpMarks[1]/@dis.place = 'below'">-3</xsl:when>
                                                    <xsl:otherwise>0</xsl:otherwise>
                                                </xsl:choose>
                                            </xsl:variable>
                                            <xsl:apply-templates select="$sourceLayer" mode="adjustMaterial">
                                                <xsl:with-param name="oct.dis" select="$oct.dis" as="xs:integer" tunnel="yes"/>
                                                <xsl:with-param name="tstamp.first" select="number($local.cpInstructions[1]/@source.tstamp.first)" as="xs:double" tunnel="yes"/>
                                                <xsl:with-param name="tstamp.last" select="number($local.cpInstructions[1]/@source.tstamp.last)" as="xs:double" tunnel="yes"/>
                                            </xsl:apply-templates>
                                        </expan>
                                    </choice>
                                    
                                    <xsl:apply-templates select="node()" mode="#current">
                                        <xsl:with-param name="tstamp.after" select="number($local.cpInstructions[1]/@target.tstamp.last)" as="xs:double" tunnel="yes"/>
                                    </xsl:apply-templates>
                                    
                                </xsl:copy>
                            </xsl:when>
                            
                            <xsl:when test="count($local.cpMarks) gt 1 and (not($local.cpMarks[1]/@layer) and not(preceding-sibling::mei:layer)) or ($local.cpMarks[1]/@layer = @n)">
                                <xsl:message>am I right?</xsl:message>
                                
                                <!-- repeat what's above… -->
                                
                            </xsl:when>
                            
                            <xsl:otherwise>
                                <xsl:next-match/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:otherwise>

        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="mei:measure" mode="resolveMarks">
        <xsl:param name="cpInstructions" tunnel="yes"/>
        <xsl:param name="cpMarks.enhanced" tunnel="yes"/>
        <xsl:param name="cpMark.ids" as="xs:string*" tunnel="yes"/>
        
        <xsl:copy>
            <xsl:apply-templates select="node() | (@* except @meter.count)" mode="#current"/>
            
            <xsl:variable name="affectedStaves" select="child::mei:staff[@xml:id = $cpInstructions//@targetStaff.id]"/>    
            
           <!-- <xsl:message select="count($affectedStaves) || ' affected staves'"/>-->
            
            <xsl:for-each select="$affectedStaves">
                
                <xsl:variable name="staff.id" select="@xml:id"/>
                <xsl:variable name="cpInstruction" select="$cpInstructions/descendant-or-self::*[@targetStaff.id = $staff.id]"/>
                <xsl:variable name="cpMark" select="$cpMarks.enhanced/descendant-or-self::*[@xml:id = $cpInstruction/@cpMark.id and @xml:id = $cpMark.ids][1]"/>
                
                <xsl:variable name="controlEvents" select="$music/id($cpInstruction/@sourceStaff.id)/parent::mei:measure/mei:*[
                    if($cpMark/@ref.staff) then(.//@staff = $cpMark/@ref.staff) else(.//@staff = $cpMark/@staff) 
                    and (if($cpMark/@ref.layer and .//@layer) then(.//@layer = $cpMark/@ref.layer) else(
                        if($cpMark/@layer and .//@layer) then(.//@layer = $cpMark/@layer) else(true())))
                        and number(@tstamp) ge number($cpInstruction/@tstamp.first)
                        and (not(starts-with(.//@tstamp2,'0m+')) or number(substring-after(.//@tstamp2,'m+')) le number($cpInstruction/@tstamp.last))
                    and not(local-name(.) = 'cpMark')]"/>
                
                <!--<xsl:message select="string(count($controlEvents)) || ' controlEvents from cpMark #' || $cpMark/@xml:id"/>-->
                
                <xsl:for-each select="$controlEvents">
                    <choice xmlns="http://www.music-encoding.org/ns/mei" xml:id="c{uuid:randomUUID()}">
                        <abbr type="cpMark"/>
                        <expan evidence="#{$cpMark/@xml:id}">
                            <xsl:apply-templates select="." mode="adjustMaterial"/>
                        </expan>
                    </choice>    
                </xsl:for-each>
            </xsl:for-each>
            
        </xsl:copy>
    </xsl:template>
    
    <!-- if it is defined that only events before or after a certain tstamp should be considered, do the appropriate selection -->
    <xsl:template match="mei:*[@tstamp]" mode="resolveMarks">
        <xsl:param name="tstamp.before" tunnel="yes" as="xs:double?"/>
        <xsl:param name="tstamp.after" tunnel="yes" as="xs:double?"/>        
        <xsl:param name="tstamp.first" tunnel="yes" as="xs:double?"/>
        <xsl:param name="tstamp.last" tunnel="yes" as="xs:double?"/>
        
        <xsl:choose>
            <xsl:when test="not($tstamp.before or $tstamp.after or ($tstamp.first and $tstamp.last))">
                <xsl:next-match/>
            </xsl:when>
            <xsl:when test="exists($tstamp.before) and number(@tstamp) lt $tstamp.before">
                <xsl:copy>
                    <xsl:apply-templates select="node() | @*" mode="#current"/>
                </xsl:copy>
            </xsl:when>
            <xsl:when test="exists($tstamp.after) and number(@tstamp) gt $tstamp.after">
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
            <xsl:when test="exists($tstamp.before) and (some $tstamp in .//@tstamp satisfies (number($tstamp) lt $tstamp.before))">
                <xsl:copy>
                    <xsl:apply-templates select="node() | @*" mode="#current"/>
                </xsl:copy>
            </xsl:when>
            <xsl:when test="exists($tstamp.after) and (some $tstamp in .//@tstamp satisfies (number($tstamp) gt $tstamp.after))">
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
    <xsl:template match="@stayWithMe" mode="resolveMarks"/>
        
    <!-- mode prepare.cpMarks -->
    <!-- this builds a list of targets that need to be filled -->
    <xsl:template match="mei:cpMark" mode="prepare.cpMarks">
        <xsl:variable name="cpMark" select="." as="node()"/>
        <xsl:variable name="origin.measure" select="ancestor::mei:measure" as="node()"/>
        <xsl:variable name="origin.measure.meter.count" select="$origin.measure/@meter.count" as="xs:string"/>
        <xsl:variable name="staff.n" select="@staff" as="xs:string"/>
        <xsl:variable name="origin.staff" select="$origin.measure/mei:staff[@n = $staff.n]" as="node()"/>
        <xsl:choose>
            <xsl:when test="@tstamp2 = ('0m+' || $origin.measure.meter.count) and @ref.offset = '-1m+1' and not(@ref.staff) and ($origin.staff//mei:mRpt or $origin.staff//mei:mSpace)">
                <!-- this is a mRpt and already covered as such -->
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
                            <xsl:message>Houston…</xsl:message>
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
    
    <xsl:template match="node() | @*" mode="#all">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
</xsl:stylesheet>