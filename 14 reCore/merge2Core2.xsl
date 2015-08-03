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
            <xd:p><xd:b>Created on:</xd:b> Jul 13, 2015</xd:p>
            <xd:p><xd:b>Author:</xd:b> Johannes Kepper</xd:p>
            <xd:p>
                This stylesheet merges a fully proofread source file with a pre-existing core 
                for that movement.  
            </xd:p>
            <xd:p>With the parameter $mode, it can be decided whether the stylesheet identifies the results of its execution and outputs
                them to a list of differences found (value 'probe', default), or if it should be executed without further notice (value
                'execute'). </xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:output method="xml" indent="yes"/>
    
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
    <!-- in source.preComp, a file almost similar to a core based on the source is generated. -->
    <xsl:variable name="source.preComp">
        <xsl:apply-templates mode="source.preComp"/>
    </xsl:variable>
    
    <xsl:variable name="core" select="doc(concat($basePath,'/14%20reCored/core_mov',$mov.n,'.xml'))//mei:mei" as="node()"/>
    
    
    <xsl:variable name="all.sources.so.far" as="xs:string+">
        <xsl:value-of select="substring-before(substring-after($core//mei:change[@n = '1']//mei:p,'from '),'_mov')"/>
        <xsl:for-each select="$core//mei:change[@n != '1']">
            <xsl:value-of select="substring-before(substring-after(.//mei:p,'from '),'_mov')"/>
        </xsl:for-each>
    </xsl:variable>
    
    
    
    <!-- main template -->
    <xsl:template match="/">
        
        <!--<xsl:if test="not($correctFolder)">
            <xsl:message terminate="yes" select="'You seem to use a file from the wrong folder. Relevant chunk of filePath is: ' || reverse(tokenize(document-uri(/),'/'))[3]"/>
        </xsl:if>-->
        
        <!--<xsl:if test="$sourceThereAlready">
            <xsl:message terminate="yes" select="'There is already a processed version of the file in /14 reCored…'"/>
        </xsl:if>-->
        
        <xsl:if test="not($source.raw//mei:application/mei:name[text() = 'addAccid.ges.xsl'])">
            <xsl:message terminate="yes" select="'The source file needs to be processed by addAccid.ges.xsl prior to merging into the core. Processing terminated.'"/>
        </xsl:if>
        
        <xsl:if test="not($coreThereAlready)">
            <xsl:message terminate="yes" select="'There is no core file for mov' || $mov.n || ' yet. Please use setupNewCore.xsl first. ' || concat($basePath,'/14%20reCored/core_mov',$mov.n,'.xml')"/>
        </xsl:if>
        
        <!-- basic checks: -->
        <xsl:if test="//mei:clef[not(@tstamp)]">
            <xsl:message terminate="yes" select="'ERROR: the following clefs have no @tstamp: ' || string-join(//mei:clef[not(@tstamp)]/@xml:id,', ')"/>
        </xsl:if>
        <xsl:if test="//@artic[not(. = ('dot','stroke'))]">
            <xsl:message terminate="no" select="'ERROR: @artic uses the following values: /' || string-join((distinct-values(//@artic)),'/, /') || '/, but only /dot/ and /stroke/ are supported'"/>
        </xsl:if>
        
        <!-- debug -->
        <xsl:message terminate="no" select="'INFO: adding ' || $source.id || ' to the core of mov' || $mov.n || ', which holds sources ' || string-join($all.sources.so.far,', ') || ' already'"/>
        
        <!-- in compare.phase1, the actual comparison is executed -->
        <xsl:variable name="compare.phase1">
            <xsl:apply-templates select="$core" mode="compare.phase1"/>
        </xsl:variable>
        
        <xsl:copy-of select="$compare.phase1"/>
        
    </xsl:template>
    
    <!-- mode source.preComp – START -->
    
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
            <xsl:attribute name="synch" select="@xml:id"/>
            <xsl:apply-templates select="node()" mode="#current"></xsl:apply-templates>
        </rdg>
    </xsl:template>
    
    <!-- <reg> is a result of ambiguous control events -->
    <xsl:template match="mei:reg" mode="source.preComp">
        <rdg xmlns="http://www.music-encoding.org/ns/mei">
            <xsl:attribute name="xml:id" select="'c'||uuid:randomUUID()"/>
            <xsl:attribute name="source" select="'#' || $source.id"/>
            <xsl:attribute name="synch" select="@xml:id"/>
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
    
    <!-- add temporary attributes for comparison reasons -->
    <xsl:template match="mei:measure" mode="source.preComp">
        <xsl:variable name="meter.count" select="preceding::mei:*[@meter.count][1]/@meter.count" as="xs:string"/>
        <xsl:copy>
            <xsl:apply-templates select="node() | @*" mode="#current">
                <xsl:with-param name="meter.count" select="$meter.count" as="xs:string" tunnel="yes"/>
            </xsl:apply-templates>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="mei:staff | mei:layer" mode="source.preComp">
        <xsl:param name="meter.count" as="xs:string" tunnel="yes"/>
        <xsl:copy>
            <xsl:apply-templates select="@*" mode="#current"/>
            <xsl:attribute name="tstamp.first" select="'1'"/>
            <xsl:attribute name="tstamp.end" select="string(number($meter.count) + 1)"/>
            <xsl:apply-templates select="node()" mode="#current"/>
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
    <xsl:template match="mei:space/@n" mode="source.preComp"/>
    
    <!-- /mode source.preComp – END -->
    
    <!-- mode profiling.prep – START -->
    
    <xsl:template match="mei:note[@grace and not(@tstamp)]" mode="source.preComp profiling.prep">
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
                        <xsl:value-of select="number((following-sibling::mei:*/descendant-or-self::mei:*[@tstamp])[1]/@tstamp) - 0.000"/>
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
    
    <!-- /mode profiling.prep – END -->
    
    <!-- mode compare.phase1 – START -->
    
    <xsl:template match="mei:measure" mode="compare.phase1">
        <xsl:variable name="core.measure" select="." as="node()"/>
        <xsl:variable name="source.measure.id" select="replace(@xml:id,'core_mov',$source.id || '_mov')" as="xs:string"/>
        <xsl:variable name="source.measure" select="$source.preComp/id($source.measure.id)" as="node()"/>
        
        <xsl:variable name="measure.att.diffs" as="node()*">
            <xsl:sequence select="local:compareAttributes($source.measure,$core.measure)"></xsl:sequence>
        </xsl:variable>
        
        <!-- decide if there are differences at measure level -->
        <xsl:choose>
            <!-- when there are no differences, continue (with core and source measures as tunnel parameter) -->
            <xsl:when test="count($measure.att.diffs/descendant-or-self::diff) = 0">
                <xsl:copy>
                    <xsl:apply-templates select="node() |@*" mode="#current">
                        <xsl:with-param name="source.measure" select="$source.measure" as="node()" tunnel="yes"/>
                        <xsl:with-param name="core.measure" select="$core.measure" as="node()" tunnel="yes"/>
                    </xsl:apply-templates>
                </xsl:copy>
            </xsl:when>
            <!-- when there are different attributes, ignore them for the time being, but write a warning -->
            <xsl:otherwise>
                <xsl:message terminate="no" select="'spotted attribute differences on measure ' || @xml:id || ', affecting attributes ' || string-join($measure.att.diffs//@att.name,' / ') || '. Problem ignored, processing continued.'"/>
                <!-- todo: temporary solution, should be improved to reflect those differences in code -->
                <xsl:copy>
                    <xsl:apply-templates select="node() |@*" mode="#current">
                        <xsl:with-param name="source.measure" select="$source.measure" as="node()" tunnel="yes"/>
                        <xsl:with-param name="core.measure" select="$core.measure" as="node()" tunnel="yes"/>
                    </xsl:apply-templates>
                </xsl:copy>                
            </xsl:otherwise>
        </xsl:choose>        
    </xsl:template>
    
    <xsl:template match="mei:staff" mode="compare.phase1">
        <xsl:param name="source.measure" as="node()" tunnel="yes"/>
        <xsl:param name="core.measure" as="node()" tunnel="yes"/>
        
        <xsl:variable name="staff.n" select="@n" as="xs:string"/>
        
        <xsl:variable name="core.staff.raw" select="." as="node()"/>
        <xsl:variable name="trans.semi.core" select="preceding::mei:*[(local-name() = 'staffDef' and @n = $staff.n and @trans.semi) or (local-name() = 'scoreDef' and @trans.semi)][1]/@trans.semi" as="xs:string?"/>
        
        <xsl:variable name="source.staff.raw" select="$source.measure/mei:staff[@n = $staff.n]" as="node()"/>        
        <xsl:variable name="trans.semi.source" select="$source.staff.raw/preceding::mei:*[(local-name() = 'staffDef' and @n = $staff.n and @trans.semi) or (local-name() = 'scoreDef' and @trans.semi)][1]/@trans.semi" as="xs:string?"/>
                
        <xsl:variable name="core.staff.profile" as="node()">
            <xsl:apply-templates select="." mode="profiling.prep">
                <xsl:with-param name="trans.semi" select="$trans.semi.core" tunnel="yes" as="xs:string?"/>
            </xsl:apply-templates>
        </xsl:variable>
        <xsl:variable name="source.staff.profile" as="node()">
            <xsl:apply-templates select="$source.staff.raw" mode="profiling.prep">
                <xsl:with-param name="trans.semi" select="$trans.semi.source" tunnel="yes" as="xs:string?"/>
            </xsl:apply-templates>
        </xsl:variable>
        
        <!-- simplest case: check if core and source match without further steps -->
        <xsl:variable name="full.staff.comparison" select="local:compareStaff($source.staff.profile,$core.staff.profile)" as="node()*"/>
        
        <!-- simple case: check if one of the existing sources matches the new without further steps -->
        <xsl:variable name="full.source.comparisons" as="node()*">
            <xsl:for-each select="$all.sources.so.far">
                <xsl:variable name="current.source.id" select="." as="xs:string"/>
                
                <xsl:variable name="rdg.staff.raw" as="node()">
                    <xsl:apply-templates select="$core.staff.raw" mode="resolveApp">
                        <xsl:with-param name="source.id" select="$current.source.id" as="xs:string" tunnel="yes"/>
                    </xsl:apply-templates>
                </xsl:variable>
                
                <xsl:variable name="rdg.staff.profile" as="node()">
                    <xsl:apply-templates select="$rdg.staff.raw" mode="profiling.prep">
                        <xsl:with-param name="trans.semi" select="$trans.semi.core" tunnel="yes" as="xs:string?"/>
                    </xsl:apply-templates>
                </xsl:variable>
                
                <source id="{$current.source.id}">
                    <xsl:sequence select="local:compareStaff($source.staff.profile,$rdg.staff.profile)"/>    
                </source>
            </xsl:for-each>
        </xsl:variable>
        
        <!-- main decision on how to resolve the differences -->
        <xsl:choose>
            
            <!-- when core has no apps (yet), and there are no differences found between core and source -->
            <xsl:when test="not($core.staff.raw//mei:app) and count($full.staff.comparison/descendant-or-self::diff) = 0">
                <xsl:copy>
                    <xsl:apply-templates select="node() | @*" mode="merge">
                        <xsl:with-param name="corresp" select="$full.staff.comparison/descendant-or-self::sameas" as="node()*" tunnel="yes"/>
                    </xsl:apply-templates>    
                </xsl:copy>
            </xsl:when>
            
            <!-- when one of the existing sources has the same profile as the new source --> 
            <xsl:when test="$core.staff.raw//mei:app and (some $full.source.comparison in $full.source.comparisons satisfies (count($full.source.comparison/descendant-or-self::diff) = 0))">
                
                <!-- identify matching source -->
                <xsl:variable name="matching.source.id" select="$full.source.comparisons/descendant-or-self::source[count(.//diff) = 0]/@id" as="xs:string+"/>
                <!-- debug message -->
                <xsl:if test="count($matching.source.id) gt 1">
                    <xsl:message terminate="yes" select="'Error: source ' || $source.id || ' matches the text of the following sources in '|| $core.staff.raw/@xml:id || ', even though they differ: ' || string-join($matching.source.id,', ')"/>
                </xsl:if>
                
                <xsl:message select="'   INFO: ' || $source.staff.raw/@xml:id || ' has the same text as ' || $matching.source.id || '. No special treatment scheduled.'"/>
                
                <xsl:copy>
                    <xsl:apply-templates select="node() | @*" mode="merge">
                        <xsl:with-param name="matching.source.id" select="$matching.source.id" as="xs:string" tunnel="yes"/>
                        <xsl:with-param name="corresp" select="$full.source.comparisons/descendant-or-self::source[@id = $matching.source.id]//sameas" as="node()*" tunnel="yes"/>
                    </xsl:apply-templates>    
                </xsl:copy>
            </xsl:when>
            
            <!-- all situations from here on require to resolve new differences -->
            
            <!-- core and source have the same number of layers, no apps yet -->
            <xsl:when test="not($core.staff.raw//mei:app) and count($core.staff.raw/mei:layer) = count($source.staff.raw/mei:layer)">
                <xsl:copy>
                    <xsl:apply-templates select="@*" mode="#current"/>
                    
                    <xsl:for-each select="$core.staff.raw/mei:layer">
                        
                        <xsl:variable name="core.layer" select="." as="node()"/>
                        <xsl:variable name="source.layer" select="$source.staff.raw/mei:layer[@n = $core.layer/@n]" as="node()?"/>
                        
                        <xsl:variable name="core.layer.profile" as="node()">
                            <xsl:apply-templates select="$core.layer" mode="profiling.prep">
                                <xsl:with-param name="trans.semi" select="$trans.semi.core" tunnel="yes" as="xs:string?"/>
                            </xsl:apply-templates>
                        </xsl:variable>
                        <xsl:variable name="source.layer.profile" as="node()">
                            <xsl:apply-templates select="$source.layer" mode="profiling.prep">
                                <xsl:with-param name="trans.semi" select="$trans.semi.source" tunnel="yes" as="xs:string?"/>
                            </xsl:apply-templates>
                        </xsl:variable>
                        
                        <!-- debug -->
                        <xsl:if test="not($source.layer)">
                            <xsl:message terminate="yes" select="'ERROR: The @n attributes for the layers in ' || $core.staff.raw/@xml:id || ' differ. No mei:layer/@n=' || $core.layer/@n || ' available in source ' || $source.id"/>
                            <!-- if the above assumption is not correct and different @n need to be allowed, this whole processing needs to be revised. Maybe a manual resolution is more appropriate then? -->
                        </xsl:if>
                        
                        <xsl:copy>
                            <xsl:apply-templates select="@*" mode="#current"/>
                            
                            <xsl:variable name="layer.comparison" select="local:compareStaff($source.layer.profile,$core.layer.profile)" as="node()*"/>
                            <xsl:choose>
                                <!-- when there are differences in this layer -->
                                <xsl:when test="exists($layer.comparison/descendant-or-self::diff)">
                                    
                                    <xsl:message select="'   INFO: ' || $source.staff.raw/@xml:id || '/layer[' || $core.layer/@n || '] differs, without existing differences in the other sources. One layer only.'"/>
                                    <xsl:variable name="layer.diffs" select="local:groupDiffs($layer.comparison[local-name() = 'diff'],$core.layer.profile,$source.layer.profile)"/>
                                    
                                    <xsl:variable name="first.diff.tstamp" select="number(($layer.diffs/descendant-or-self::diffGroup)[1]/@tstamp.first)" as="xs:double"/>
                                    
                                    <xsl:apply-templates select="$core.layer/child::mei:*" mode="get.by.tstamps">
                                        <xsl:with-param name="before.tstamp" select="$first.diff.tstamp" as="xs:double" tunnel="yes"/>
                                        <xsl:with-param name="corresp" select="$layer.comparison/descendant-or-self::sameas" as="node()*" tunnel="yes"/>
                                    </xsl:apply-templates>
                                    
                                    <xsl:for-each select="$layer.diffs/descendant-or-self::diffGroup">
                                        <xsl:variable name="current.diffGroup" select="." as="node()"/>
                                        <xsl:variable name="current.pos" select="position()" as="xs:integer"/>
                                        
                                        <xsl:variable name="first.rdg.id" select="'c'||uuid:randomUUID()" as="xs:string"/>
                                        <xsl:variable name="second.rdg.id" select="'c'||uuid:randomUUID()" as="xs:string"/>
                                        <xsl:variable name="annot.id" select="'c'||uuid:randomUUID()" as="xs:string"/>
                                        
                                        <app xmlns="http://www.music-encoding.org/ns/mei" xml:id="{'a'||uuid:randomUUID()}">
                                            <rdg xml:id="{$first.rdg.id}" source="#{string-join($all.sources.so.far,' #')}">
                                                <xsl:apply-templates select="$core.layer/child::mei:*" mode="get.by.tstamps">
                                                    <xsl:with-param name="from.tstamp" select="number($current.diffGroup/@tstamp.first)" as="xs:double" tunnel="yes"/>
                                                    <xsl:with-param name="to.tstamp" select="number($current.diffGroup/@tstamp.last)" as="xs:double" tunnel="yes"/>
                                                    <xsl:with-param name="corresp" select="$layer.comparison/descendant-or-self::sameas" as="node()*" tunnel="yes"/>
                                                </xsl:apply-templates>
                                            </rdg>
                                            <rdg xml:id="{$second.rdg.id}" source="#{$source.id}">
                                                
                                                <xsl:apply-templates select="$source.layer/child::mei:*" mode="get.by.tstamps">
                                                    <xsl:with-param name="from.tstamp" select="number($current.diffGroup/@tstamp.first)" as="xs:double" tunnel="yes"/>
                                                    <xsl:with-param name="to.tstamp" select="number($current.diffGroup/@tstamp.last)" as="xs:double" tunnel="yes"/>
                                                    <xsl:with-param name="corresp" select="$layer.comparison/descendant-or-self::sameas" as="node()*" tunnel="yes"/>
                                                </xsl:apply-templates>
                                                
                                            </rdg>
                                        </app>
                                        <annot xmlns="http://www.music-encoding.org/ns/mei" xml:id="{$annot.id}" type="diff" corresp="#{$source.id} #{string-join($all.sources.so.far,' #')}" plist="#{$first.rdg.id || ' #' || $second.rdg.id}">
                                            <xsl:if test="count(distinct-values($current.diffGroup//diff/@type)) = 1 and $current.diffGroup//diff[1]/@type = 'att.value' and $current.diffGroup//diff[1]/@att.name = 'artic'">
                                                <p>
                                                    Different articulation in source. <xsl:value-of select="string-join($all.sources.so.far,', ')"/> read 
                                                    <xsl:value-of select="$current.diffGroup//diff[1]/@core.value"/>, while <xsl:value-of select="$source.id"/>
                                                    reads <xsl:value-of select="$current.diffGroup//diff[1]/@source.value"/>.
                                                </p>
                                            </xsl:if>
                                            <!-- debug: keep the diff results -->
                                            <xsl:copy-of select="$current.diffGroup"/>    
                                            
                                        </annot>
                                        
                                        <!-- deal with material following the diff -->
                                        <xsl:choose>
                                            <!-- when there are subsequent diffs -->
                                            <xsl:when test="$current.pos lt count($layer.diffs//diffGroup)">
                                                <xsl:apply-templates select="$core.layer/child::mei:*" mode="get.by.tstamps">
                                                    <xsl:with-param name="after.tstamp" select="number($current.diffGroup/@tstamp.last)" as="xs:double" tunnel="yes"/>
                                                    <xsl:with-param name="before.tstamp" select="number($layer.diffs//diffGroup[($current.pos + 1)]/@tstamp.first)" as="xs:double" tunnel="yes"/>
                                                    <xsl:with-param name="corresp" select="$layer.comparison/descendant-or-self::sameas" as="node()*" tunnel="yes"/>
                                                </xsl:apply-templates>
                                            </xsl:when>
                                            <!-- when this is the last diff -->
                                            <xsl:otherwise>
                                                <xsl:apply-templates select="$core.layer/child::mei:*" mode="get.by.tstamps">
                                                    <xsl:with-param name="after.tstamp" select="number($current.diffGroup/@tstamp.last)" as="xs:double" tunnel="yes"/>
                                                    <xsl:with-param name="corresp" select="$layer.comparison/descendant-or-self::sameas" as="node()*" tunnel="yes"/>
                                                </xsl:apply-templates>
                                            </xsl:otherwise>
                                        </xsl:choose>
                                        
                                    </xsl:for-each>
                                    <!--
                                    
                                    <xsl:apply-templates select="$core.layer" mode="generate.apps">
                                        <xsl:with-param name="diff.groups" select="$layer.diffs//diffGroup" as="node()*" tunnel="yes"/>
                                        <xsl:with-param name="corresp" select="$layer.diffs/descendant-or-self::sameas" as="node()*" tunnel="yes"/>
                                    </xsl:apply-templates>-->
                                </xsl:when>
                                <!-- when there are no differences in this layer -->
                                <xsl:otherwise>
                                    <xsl:apply-templates select="$core.layer" mode="generate.apps">
                                        <xsl:with-param name="corresp" select="$layer.comparison/descendant-or-self::sameas" as="node()*" tunnel="yes"/>
                                    </xsl:apply-templates>
                                </xsl:otherwise>
                            </xsl:choose>
                            
                        </xsl:copy>
                    </xsl:for-each>
                </xsl:copy>
            </xsl:when>
            
            <!--<!-\- core and source both have one layer each, existing differences-\->
            <xsl:when test="$core.staff.raw//mei:app and count($core.staff.raw/mei:layer) = 1 and count($source.staff.raw/mei:layer) = 1">
                
                <!-\- need to split up by ranges -\->
                
                <!-\-<xsl:if test=""/>-\->
                <missing xml:id="{@xml:id}" case="apps justOneLayer"/>
            </xsl:when>-->
            
            <!-- core and source have the same number of layers, existing differences -->
            <xsl:when test="$core.staff.raw//mei:app and count($core.staff.raw/mei:layer) = count($source.staff.raw/mei:layer)">
                
                <xsl:message select="'   INFO: ' || $source.staff.raw/@xml:id || ' needs to be merged into existing apps'"/>
                
                <!-- need to split up by ranges -->
                
                <xsl:copy>
                    <xsl:apply-templates select="@*" mode="#current"/>
                    
                    <xsl:for-each select="$core.staff.raw/mei:layer">
                        
                        <xsl:variable name="core.layer" select="." as="node()"/>
                        <xsl:variable name="source.layer" select="$source.staff.raw/mei:layer[@n = $core.layer/@n]" as="node()?"/>
                        
                        <xsl:variable name="core.layer.profile" as="node()">
                            <xsl:apply-templates select="$core.layer" mode="profiling.prep">
                                <xsl:with-param name="trans.semi" select="$trans.semi.core" tunnel="yes" as="xs:string?"/>
                            </xsl:apply-templates>
                        </xsl:variable>
                        <xsl:variable name="source.layer.profile" as="node()">
                            <xsl:apply-templates select="$source.layer" mode="profiling.prep">
                                <xsl:with-param name="trans.semi" select="$trans.semi.source" tunnel="yes" as="xs:string?"/>
                            </xsl:apply-templates>
                        </xsl:variable>
                        
                        
                        <!-- debug -->
                        <xsl:if test="not($source.layer)">
                            <xsl:message terminate="yes" select="'Error: The @n attributes for the layers in ' || $core.staff.raw/@xml:id || ' differ. No mei:layer/@n=' || $core.layer/@n || ' available in source ' || $source.id"/>
                            <!-- if the above assumption is not correct and different @n need to be allowed, this whole processing needs to be revised. Maybe a manual resolution is more appropriate then? -->
                        </xsl:if>
                        
                        <xsl:copy>
                            <xsl:apply-templates select="@*" mode="#current"/>
                            
                            <xsl:variable name="layer.comparison" select="local:compareStaff($source.layer.profile,$core.layer.profile)" as="node()*"/>
                            
                            <xsl:choose>
                                <!-- this layer needs to be split up into multiple ranges -->
                                <xsl:when test="$core.layer//mei:app">
                                    
                                    <xsl:variable name="layer.source.comparisons" as="node()*">
                                        <xsl:for-each select="$all.sources.so.far">
                                            <xsl:variable name="current.source.id" select="." as="xs:string"/>
                                            
                                            <xsl:variable name="rdg.layer.raw" as="node()">
                                                <xsl:apply-templates select="$core.layer" mode="resolveApp">
                                                    <xsl:with-param name="source.id" select="$current.source.id" as="xs:string" tunnel="yes"/>
                                                </xsl:apply-templates>
                                            </xsl:variable>
                                            
                                            <xsl:variable name="rdg.layer.profile" as="node()">
                                                <xsl:apply-templates select="$rdg.layer.raw" mode="profiling.prep">
                                                    <xsl:with-param name="trans.semi" select="$trans.semi.core" tunnel="yes" as="xs:string?"/>
                                                </xsl:apply-templates>
                                            </xsl:variable>
                                            
                                            <source id="{$current.source.id}">
                                                <xsl:sequence select="local:compareStaff($source.layer.profile,$rdg.layer.profile)"/>    
                                            </source>
                                        </xsl:for-each>
                                    </xsl:variable>
                                    
                                    <!-- identify matching source -->
                                    <xsl:variable name="matching.source.id" select="$layer.source.comparisons/descendant-or-self::source[count(.//diff) = 0]/@id" as="xs:string?"/>
                                    <!-- debug message -->
                                    <xsl:if test="count($matching.source.id) gt 1">
                                        <xsl:message terminate="yes" select="'Error: source ' || $source.id || ' matches the text of the following sources in '|| $core.staff.raw/@xml:id || ', even though they differ: ' || string-join($matching.source.id,', ')"/>
                                    </xsl:if>
                                    
                                    <xsl:choose>
                                        <!-- the new source has the same text as another source for this layer -->
                                        <xsl:when test="exists($matching.source.id)">
                                            <xsl:message select="'   INFO: ' || $source.staff.raw/@xml:id || '/layer[' || $core.layer/@n || '] has the same text as ' || $matching.source.id"/>
                                            
                                            <xsl:copy>
                                                <xsl:apply-templates select="node() | @*" mode="merge">
                                                    <xsl:with-param name="matching.source.id" select="$matching.source.id" as="xs:string" tunnel="yes"/>
                                                    <xsl:with-param name="corresp" select="$layer.source.comparisons/descendant-or-self::source[@id = $matching.source.id]//sameas" as="node()*" tunnel="yes"/>
                                                </xsl:apply-templates>    
                                            </xsl:copy>
                                        </xsl:when>
                                        
                                        <!-- more apps need to be generated -->
                                        <xsl:otherwise>
                                            <xsl:message select="'INFO: more apps need to be generated for '  || $source.staff.raw/@xml:id || '/layer[' || $core.layer/@n || ']'"/>
                                            
                                            <xsl:variable name="closest.source.id" as="xs:string">
                                                <xsl:variable name="sources.sorted" as="node()+">
                                                    <xsl:for-each select="$layer.source.comparisons/descendant-or-self::source">
                                                        <xsl:sort select="count(.//sameas) div count(.//diff)" data-type="number" order="descending"/>
                                                        <xsl:sequence select="."/>
                                                    </xsl:for-each>
                                                </xsl:variable>
                                                <xsl:value-of select="$sources.sorted[1]/@id"/>
                                            </xsl:variable>
                                            
                                            <xsl:variable name="closest.rdg.layer.raw" as="node()">
                                                <xsl:apply-templates select="$core.layer" mode="resolveApp">
                                                    <xsl:with-param name="source.id" select="$closest.source.id" as="xs:string" tunnel="yes"/>
                                                </xsl:apply-templates>
                                            </xsl:variable>
                                            <xsl:variable name="closest.rdg.layer.profile" as="node()">
                                                <xsl:apply-templates select="$closest.rdg.layer.raw" mode="profiling.prep">
                                                    <xsl:with-param name="trans.semi" select="$trans.semi.core" tunnel="yes" as="xs:string?"/>
                                                </xsl:apply-templates>
                                            </xsl:variable>
                                            
                                            <xsl:variable name="closest.rdg.layer.diffs" select="local:groupDiffs($layer.source.comparisons/descendant-or-self::source[@id = $closest.source.id]//diff,$closest.rdg.layer.profile,$source.layer.profile)"/>
                                            
                                            
                                            <xsl:message select="'closest source is ' || $closest.source.id"/>
                                            
                                            <xsl:variable name="existing.ranges" as="node()+">
                                                <xsl:for-each select="$core.layer//mei:app">
                                                    <range tstamp.first="{min(.//mei:*[@tstamp]/number(@tstamp))}" tstamp.last="{max(.//mei:*[@tstamp]/number(@tstamp))}"/>
                                                </xsl:for-each>
                                            </xsl:variable>
                                            
                                            <!-- decide if differences between current source and the closest existing source require new apps -->
                                            <xsl:choose>
                                                
                                                <!-- when all spotted diffs fit into the existing app boundaries -->
                                                <xsl:when test="every $diffGroup in $closest.rdg.layer.diffs//diffGroup satisfies (
                                                    some $range in $existing.ranges/descendant-or-self::range satisfies (
                                                            $diffGroup/@tstamp.first = $range/@tstamp.first and
                                                            $diffGroup/@tstamp.last = $range/@tstamp.last
                                                        )
                                                    )">
                                                    
                                                    <xsl:variable name="first.diff.tstamp" select="number(($closest.rdg.layer.diffs//diffGroup)[1]/@tstamp.first)" as="xs:double"/>
                                                    
                                                    <xsl:apply-templates select="$core.layer/child::mei:*" mode="get.by.tstamps">
                                                        <xsl:with-param name="before.tstamp" select="$first.diff.tstamp" as="xs:double" tunnel="yes"/>
                                                        <xsl:with-param name="corresp" select="$layer.source.comparisons/descendant-or-self::source[@id = $matching.source.id]//sameas" as="node()*" tunnel="yes"/>
                                                    </xsl:apply-templates>
                                                    
                                                    <xsl:for-each select="$existing.ranges/descendant-or-self::range">
                                                        <xsl:variable name="current.range" select="." as="node()"/>
                                                        <xsl:variable name="current.pos" select="position()" as="xs:integer"/>
                                                        
                                                        <xsl:variable name="current.diffGroup" select="$closest.rdg.layer.diffs//diffGroup[@tstamp.first = $current.range/@tstamp.first and @tstamp.last = $current.range/@tstamp.last]" as="node()?"/>
                                                        <xsl:variable name="current.app" select="$core.layer//mei:app[min(.//mei:*[@tstamp]/number(@tstamp)) = $current.range/@tstamp.first]" as="node()"/>
                                                        
                                                        <xsl:choose>
                                                            <!-- the new source offers a new rdg for the current app -->
                                                            <xsl:when test="exists($current.diffGroup)">
                                                                
                                                                <xsl:variable name="new.rdg.id" select="'c'||uuid:randomUUID()" as="xs:string"/>
                                                                    
                                                                <app xmlns="http://www.music-encoding.org/ns/mei">
                                                                    <!-- copy existing app and rdg(s) -->
                                                                    <xsl:apply-templates select="$current.app/@* | $current.app/mei:rdg" mode="#current"/>
                                                                    
                                                                    <rdg xmlns="http://www.music-encoding.org/ns/mei" xml:id="{$new.rdg.id}" source="#{$source.id}">
                                                                        
                                                                        <xsl:apply-templates select="$source.layer/child::mei:*" mode="get.by.tstamps">
                                                                            <xsl:with-param name="from.tstamp" select="number($current.diffGroup/@tstamp.first)" as="xs:double" tunnel="yes"/>
                                                                            <xsl:with-param name="to.tstamp" select="number($current.diffGroup/@tstamp.last)" as="xs:double" tunnel="yes"/>
                                                                            <xsl:with-param name="corresp" select="$layer.source.comparisons/descendant-or-self::source[@id = $matching.source.id]//sameas" as="node()*" tunnel="yes"/>
                                                                        </xsl:apply-templates>
                                                                        
                                                                    </rdg>
                                                                </app>
                                                                
                                                                <xsl:apply-templates select="$current.app/following-sibling::mei:annot[1]" mode="#current">
                                                                    <xsl:with-param name="add.plist.entry" select="$new.rdg.id" tunnel="yes" as="xs:string"/>
                                                                </xsl:apply-templates>
                                                                
                                                            </xsl:when>
                                                            <!-- the new source matches the closest source and shares this rdg -->
                                                            <xsl:otherwise>
                                                                <xsl:apply-templates select="$current.app" mode="#current">
                                                                    <xsl:with-param name="matching.source" select="$closest.source.id" as="xs:string" tunnel="yes"/>
                                                                    <xsl:with-param name="corresp" select="$layer.source.comparisons/descendant-or-self::source[@id = $matching.source.id]//sameas" as="node()*" tunnel="yes"/>
                                                                </xsl:apply-templates>
                                                                
                                                                <xsl:apply-templates select="$current.app/following-sibling::mei:annot[1]" mode="#current"/>
                                                                
                                                            </xsl:otherwise>
                                                        </xsl:choose>
                                                        
                                                        <!-- deal with material following the diff -->
                                                        <xsl:choose>
                                                            <!-- when there are subsequent diffs -->
                                                            <xsl:when test="$current.pos lt count($closest.rdg.layer.diffs//diffGroup)">
                                                                <xsl:apply-templates select="$core.layer/child::mei:*" mode="get.by.tstamps">
                                                                    <xsl:with-param name="after.tstamp" select="number($current.diffGroup/@tstamp.last)" as="xs:double" tunnel="yes"/>
                                                                    <xsl:with-param name="before.tstamp" select="number($closest.rdg.layer.diffs//diffGroup[($current.pos + 1)]/@tstamp.first)" as="xs:double" tunnel="yes"/>
                                                                    <xsl:with-param name="corresp" select="$layer.source.comparisons/descendant-or-self::source[@id = $matching.source.id]//sameas" as="node()*" tunnel="yes"/>
                                                                </xsl:apply-templates>
                                                            </xsl:when>
                                                            <!-- when this is the last diff -->
                                                            <xsl:otherwise>
                                                                <xsl:apply-templates select="$core.layer/child::mei:*" mode="get.by.tstamps">
                                                                    <xsl:with-param name="after.tstamp" select="number($current.diffGroup/@tstamp.last)" as="xs:double" tunnel="yes"/>
                                                                    <xsl:with-param name="corresp" select="$layer.source.comparisons/descendant-or-self::source[@id = $matching.source.id]//sameas" as="node()*" tunnel="yes"/>
                                                                </xsl:apply-templates>
                                                            </xsl:otherwise>
                                                        </xsl:choose>
                                                        
                                                    </xsl:for-each>
                                                    
                                                </xsl:when>
                                                <xsl:otherwise>
                                                    <xsl:message select="'XXX: this situation requires a completely new app layout.'"></xsl:message>
                                                </xsl:otherwise>
                                            </xsl:choose>
                                            
                                        </xsl:otherwise>
                                    </xsl:choose>
                                    
                                    
                                </xsl:when>
                                
                                <!-- no apps in this layer, but there are still differences -->
                                <xsl:when test="$layer.comparison//diff">
                                    <xsl:variable name="layer.diffs" select="local:groupDiffs($layer.comparison[local-name() = 'diff'],$core.layer.profile,$source.layer.profile)"/>
                                    
                                    <xsl:apply-templates select="$core.layer" mode="generate.apps">
                                        <xsl:with-param name="diff.groups" select="$layer.diffs//diffGroup" as="node()*" tunnel="yes"/>
                                        <xsl:with-param name="corresp" select="$layer.comparison/descendant-or-self::sameas" as="node()*" tunnel="yes"/>
                                    </xsl:apply-templates>
                                </xsl:when>
                                
                                <!-- no apps, and no diffs in this layer -->
                                <xsl:otherwise>
                                    
                                    <xsl:apply-templates select="$core.layer" mode="generate.apps">
                                        <xsl:with-param name="corresp" select="$layer.comparison/descendant-or-self::sameas" as="node()*" tunnel="yes"/>
                                    </xsl:apply-templates>
                                    
                                </xsl:otherwise>
                            </xsl:choose>
                            
                            
                        </xsl:copy>
                        
                    </xsl:for-each>
                </xsl:copy>
                
            </xsl:when>
            
            
            
            
            <!-- situation can't be resolved, so generate a "hiccup" for manual resolution -->
            <xsl:otherwise>
                <copy>
                    <xsl:apply-templates select="@*" mode="#current"/>
                    <hiccup>
                        <core source="#{string-join($all.sources.so.far,' #')}">
                            <xsl:apply-templates select="mei:layer" mode="merge">
                                <xsl:with-param name="corresp" select="$full.staff.comparison/descendant-or-self::sameas" as="node()*" tunnel="yes"/>
                            </xsl:apply-templates>
                        </core>
                        <source id="{$source.id}">
                            <xsl:apply-templates select="$source.staff.raw/mei:layer" mode="#current"/>
                        </source>
                        <protocol>
                            <xsl:copy-of select="$full.staff.comparison"/>
                        </protocol>
                    </hiccup>
                </copy>
            </xsl:otherwise>
        </xsl:choose>
        
        
    </xsl:template>
    
    <xsl:template match="mei:annot/@plist" mode="compare.phase1">
        <xsl:param name="add.plist.entry" as="xs:string?" required="no" tunnel="yes"/>
        
        <xsl:choose>
            <xsl:when test="exists($add.plist.entry)">
                <xsl:attribute name="plist" select=". || ' #' || $add.plist.entry"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:next-match/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="mei:rdg/@source" mode="compare.phase1">
        <xsl:param name="matching.source" as="xs:string?" tunnel="yes" required="no"/>
        
        <xsl:choose>
            <xsl:when test="exists($matching.source) and $matching.source = tokenize(replace(.,'#',''),' ')">
                <xsl:attribute name="source" select=". || ' #' || $source.id"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:next-match/>
            </xsl:otherwise>
        </xsl:choose>
        
    </xsl:template>
    
    <!-- creates profiles for all variants contained in a staff element and compares them with the core -->
    <xsl:function name="local:compareStaff" as="node()*">
        <xsl:param name="source.staff" as="node()"/>
        <xsl:param name="core.staff" as="node()"/>
                
        <xsl:variable name="source.profile" select="local:getStaffProfile($source.staff)"/>
        <xsl:variable name="core.profile" select="local:getStaffProfile($core.staff)"/>
        
        <xsl:copy-of select="local:compareStaffProfile($source.profile,$core.profile)"/>
               
    </xsl:function>
    
    <!-- creates a profile for a single staff element -->
    <xsl:function name="local:getStaffProfile" as="node()">
        <xsl:param name="staff" as="node()"/>
        
        <!--<xsl:variable name="trans.semi" select="$staff/preceding::mei:*[(local-name() = 'staffDef' and @n = $staff/@n and @trans.semi) or (local-name() = 'scoreDef' and @trans.semi)][1]/@trans.semi" as="xs:string?"/>
        -->
        <!--<xsl:if test="$trans.semi">
            <xsl:message terminate="yes" select="'need to address trans.semi in local:getStaffProfile() at ' || $staff/@xml:id"/>
        </xsl:if>
        
        <!-\- todo: moved step to general comparison -\->
        <xsl:variable name="staff.prep" as="node()">
            <xsl:apply-templates select="$staff" mode="profiling.prep">
                <xsl:with-param name="trans.semi" select="$trans.semi" tunnel="yes" as="xs:string?"/>
            </xsl:apply-templates>
        </xsl:variable>-->
        
        <events staff.id="{$staff/@xml:id}">
            
            <!-- todo: trans.semi original <xsl:for-each select="$staff.prep//mei:*[@tstamp]"> -->
            <xsl:for-each select="$staff//mei:*[@tstamp]">
                <xsl:sort select="@tstamp" data-type="number"/>
                <xsl:sort select="@pnum" data-type="number"/>
                <xsl:sort select="local-name()" data-type="text"/>
                
                <xsl:copy-of select="."/>
                
            </xsl:for-each>    
        </events>
        
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
                        <!--<xsl:if test="count($source.profile/mei:*[@tstamp = $current.onset and @pnum = $current.pitch]) gt 1 or count($core.profile/mei:*[@tstamp = $current.onset and @pnum = $current.pitch]) gt 1">
                            <xsl:message terminate="no" select="'found multiple elements for pitch ' || upper-case($source.elem/@pname) || $source.elem/@oct || ' at tstamp ' || $current.onset || ' in staff ' || $source.profile/@staff.id"/>
                        </xsl:if>-->
                        
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
    
    </xsl:function>
    
    <!-- groups differences, into ranges of timestamps, where all notes in between vary. -->
    <xsl:function name="local:groupDiffs" as="node()">
        <xsl:param name="diffs" as="node()*"/>
        <xsl:param name="core.range" as="node()"/>
        <xsl:param name="source.range" as="node()"/>
        
        <xsl:variable name="scope.tstamp.first" select="number($source.range/@tstamp.first)" as="xs:double"/>
        <xsl:variable name="scope.tstamp.end" select="number($source.range/@tstamp.end)" as="xs:double"/>
        
        <!-- get all tstamps in that range -->
        <xsl:variable name="base.tstamps" as="xs:double*">
            <xsl:variable name="preSort" select="distinct-values(($core.range//@tstamp, $source.range//@tstamp))" as="xs:double*"/>
            <xsl:for-each select="$preSort">
                <xsl:sort select="number(.)" data-type="number"/>
                <xsl:value-of select="number(.)"/>
            </xsl:for-each>
        </xsl:variable>
        
        <!-- get all tstamps with differences -->
        <xsl:variable name="diff.tstamps" as="xs:double*">
            <xsl:variable name="preSort" select="distinct-values($diffs//@tstamp)" as="xs:double*"/>
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
        <xsl:variable name="ranges" as="node()*">
            <xsl:copy-of select="local:getDifferingRanges($differing.positions,0)"/>
        </xsl:variable>
        
        <!-- debug: if there are no ranges, something must be wrong. At least one range with the duration of one tstamp must be affected in this staff! -->
        <xsl:if test="count($ranges/descendant-or-self::range) = 0">
            <xsl:message select="'found no differing ranges, though there are differences with @tstamps. Please check the following diffs:'"/>
            <xsl:message select="'$base.tstamps:'"/>
            <xsl:message select="$base.tstamps"/>
            <xsl:message select="'$diff.tstamps:'"/>
            <xsl:message select="$diff.tstamps"/>
            
            <xsl:message select="count($differing.positions)"/>
            
            <xsl:for-each select="$diffs">
                <xsl:message select="."/>
            </xsl:for-each>
            <xsl:message terminate="yes" select="'processing stopped at ' || $core.range/@xml:id"/>
        </xsl:if>
        
        <scope>
            <!-- iterate all ranges for that staff -->
            <xsl:for-each select="$ranges/descendant-or-self::range">
                <xsl:variable name="range" select="." as="node()"/>
                
                <xsl:variable name="tstamp.first" select="$base.tstamps[$range/number(@start)]"/>
                <xsl:variable name="tstamp.last" select="$base.tstamps[$range/number(@end)]"/>
                
                <xsl:variable name="relevant.diffs" select="$diffs[number(@tstamp) ge $tstamp.first and number(@tstamp) le $tstamp.last]" as="node()+"/>
                
                <!-- debug: if there are no diffs in this range, something must be wrong -->
                <xsl:if test="count($relevant.diffs) = 0">
                    <xsl:message select="'found no diffs for the range from ' || $tstamp.first || ' to ' || $tstamp.last || ', though there should be some. Please check the following diffs:'"/>
                    <xsl:for-each select="$relevant.diffs">
                        <xsl:message select="."/>
                    </xsl:for-each>
                    <xsl:message terminate="yes" select="'processing stopped'"/>
                </xsl:if>
                
                <xsl:choose>
                    <!-- check if values are numeric -->
                    <xsl:when test="number($tstamp.first) = $tstamp.first and number($tstamp.last) = $tstamp.last">
                        
                        <xsl:variable name="pitchFixed.diffs" select="local:identifyDifferingPitches($source.preComp,$relevant.diffs)" as="node()*"/>
                        
                        <diffGroup tstamp.first="{$tstamp.first}" tstamp.last="{$tstamp.last}" diffCount="{count($pitchFixed.diffs)}">
                            <xsl:sequence select="$pitchFixed.diffs"/>
                        </diffGroup>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:message select="'problem with the following range in ' || $core.range"/>
                        <xsl:message select="$ranges"/>
                        <xsl:message terminate="yes" select="$range"/>
                    </xsl:otherwise>
                </xsl:choose>
                
                
            </xsl:for-each>
            
            <!-- get all diffs affecting elements without a tstamp -->
            <otherDiffs>
                <xsl:for-each select="$diffs">
                    <xsl:variable name="diff" select="." as="node()"/>
                    <xsl:if test="not($diff/@tstamp)">
                        <xsl:copy-of select="$diff"/>
                    </xsl:if>
                </xsl:for-each>
            </otherDiffs>
        </scope>
                
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
                                    <!--<xsl:message select="'merging diff at ' || $diff/@staff || ', tstamp ' || $diff/@tstamp"/>-->
                                    
                                    <xsl:variable name="source.elem" select="$source.preComp//mei:*[@xml:id = $diff/@existing.id]" as="node()"/>
                                    <xsl:variable name="core.elem" select="$core/id($core.diff/@existing.id)" as="node()"/>
                                    <xsl:variable name="better.diff" select="local:compareAttributes($source.elem,$core.elem)[local-name() = 'diff']" as="node()*"/>
                                    
                                    <xsl:choose>
                                        <!-- go with the different.pitch type now… -->
                                        <xsl:when test="$better.diff and 1 = 2">
                                            <xsl:copy-of select="$better.diff"/>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <diff type="different.pitch" staff="{$diff/@staff}" tstamp="{$diff/@tstamp}" source.pitch="{$diff/@pitch}" source.pnum="{$diff/@pnum}" core.pitch="{$core.diff/@pitch}" core.pnum="{$core.diff/@pnum}" source.elem.id="{$diff/@existing.id}" core.elem.id="{$core.diff/@existing.id}"/>
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

    
    <!-- /mode compare.phase1 – END -->
    
    <!-- mode merge – START -->
    
    <!-- when a source equals another source, add it to the list in rdg/@source-->
    <xsl:template match="mei:rdg/@source" mode="merge">
        <xsl:param name="matching.source.id" as="xs:string?" tunnel="yes" required="no"/>
        <xsl:choose>
            <xsl:when test="exists($matching.source.id) and $matching.source.id = tokenize(replace(.,'#',''),' ')">
                <xsl:attribute name="source" select=".  || ' #' || $source.id"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:next-match/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- if an xml:id is mentioned in the sameas list, add a @synch attribute with the right value -->
    <xsl:template match="@xml:id" mode="merge generate.apps get.by.tstamps">
        <xsl:param name="corresp" as="node()*" tunnel="yes"/>
        <xsl:variable name="this.id" select="."/>
        
        <xsl:copy-of select="."/>
        <xsl:if test="$this.id = $corresp/descendant-or-self::sameas/@core">
            <xsl:attribute name="synch" select="$corresp/descendant-or-self::sameas[@core = $this.id]/@source"/>
        </xsl:if>
        
    </xsl:template>
    
    <!-- /mode merge – END -->
    
    <!-- mode generate.apps – START -->
    
    <!-- resolving events -->
    <!--<xsl:template match="mei:staff" mode="generate.apps">
        <xsl:param name="diff.groups" as="node()?" tunnel="yes"/>
        <xsl:param name="corresp" as="node()*" tunnel="yes"/>
        
        <xsl:variable name="staff.id" select="@xml:id" as="xs:string"/>
        <xsl:variable name="staff.id.source" select="replace($staff.id,'core_',concat($source.id,'_'))" as="xs:string"/>
        <xsl:variable name="staff.n" select="@n" as="xs:string"/>
        <xsl:variable name="core.staff" select="." as="node()"/>
        
        <xsl:choose>
            <!-\- no variance to deal with for this staff -\->
            <xsl:when test="not($diff.groups//diffGroup) and not($diff.groups//otherDiffs/diff)">
                <xsl:apply-templates select="." mode="merge">
                    <xsl:with-param name="corresp" select="$corresp" as="node()*" tunnel="yes"/>
                </xsl:apply-templates>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="source.staff" select="$source.preComp//mei:staff[@xml:id = $staff.id.source]" as="node()"/>
                <xsl:variable name="local.diff.groups" select="$diff.groups//diffGroup" as="node()+"/>
                
                <!-\- staff needs to be copied prior to further processing -\->
                <xsl:copy>
                    <xsl:apply-templates select="@*" mode="#current"/>
                    
                    <layer xmlns="http://www.music-encoding.org/ns/mei">
                        <xsl:apply-templates select="child::mei:layer/@*" mode="#current"/>
                        
                        <xsl:apply-templates select="child::mei:layer/node()" mode="get.by.tstamps">
                            <xsl:with-param name="corresp" select="$corresp" as="node()*" tunnel="yes"/>
                            <xsl:with-param name="local.diff.groups" select="$local.diff.groups" as="node()+" tunnel="yes"/>
                            <xsl:with-param name="source.staff" select="$source.staff" as="node()" tunnel="yes"/>
                        </xsl:apply-templates>    
                        
                    </layer>
                    
                    
                    <annot xmlns="http://www.music-encoding.org/ns/mei" xml:id="x{uuid:randomUUID()}" type="merge.protocol" source="#{$source.id}">
                        <date isodate="{current-dateTime()}"/>
                        <xsl:copy-of select="$local.diff.groups//staff[@xml:id = ($staff.id,$staff.id.source)]"/>
                    </annot>
                    
                </xsl:copy>
                
            </xsl:otherwise>
        </xsl:choose>
        
    </xsl:template>-->
    
    <!-- /mode generate.apps – END -->
    
    <!-- mode get.by.tstamps – START -->
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
                    <xsl:next-match/>
                </xsl:if>
            </xsl:when>
            <!-- when only a starting tstamp is provided -->
            <xsl:when test="$before.tstamp and not($after.tstamp)">
                <!-- copy only if tstamp is lower than desired last tstamp-->
                <xsl:if test="$tstamp lt $before.tstamp">
                    <xsl:next-match/>
                </xsl:if>
            </xsl:when>
            <!-- when only an ending tstamp is provided -->
            <xsl:when test="$after.tstamp and not($before.tstamp)">
                <!-- copy only if tstamp is higher than desired starting tstamp-->
                <xsl:if test="$tstamp gt $after.tstamp">
                    <xsl:next-match/>
                </xsl:if>
            </xsl:when>
            <!-- when a non-inclusive range is desired -->
            <xsl:when test="$before.tstamp and $after.tstamp">
                <!-- copy only if tstamp is between end points-->
                <xsl:if test="$tstamp gt $after.tstamp and $tstamp lt $before.tstamp">
                    <xsl:next-match/>
                </xsl:if>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message select="'ERROR: why this case? ' || @xml:id"/>
                <xsl:next-match/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- container elements which have no tstamp on their own, like beams and tuplets -->
    <xsl:template match="mei:*[not(@tstamp) and descendant::mei:*/@tstamp and ancestor::mei:layer]" mode="get.by.tstamps">
        <xsl:param name="before.tstamp" as="xs:double?" tunnel="yes" required="no"/>
        <xsl:param name="from.tstamp" as="xs:double?" tunnel="yes" required="no"/>
        <xsl:param name="to.tstamp" as="xs:double?" tunnel="yes" required="no"/>
        <xsl:param name="after.tstamp" as="xs:double?" tunnel="yes" required="no"/>
        
        <xsl:variable name="current.elem" select="." as="node()"/>
        <xsl:variable name="lowest.contained.tstamp" select="min(descendant::mei:*[@tstamp]/number(@tstamp))" as="xs:double"/>
        <xsl:variable name="highest.contained.tstamp" select="max(descendant::mei:*[@tstamp]/number(@tstamp))" as="xs:double"/>
        <xsl:variable name="contained.tstamps" select="descendant::mei:*[@tstamp]/number(@tstamp)" as="xs:double+"/>
        
        <xsl:variable name="sources.so.far" select="if(ancestor::mei:rdg) then(tokenize(replace(ancestor::mei:rdg[1]/@source,'#',''),' ')) else($all.sources.so.far)" as="xs:string+"/>
        
        <xsl:choose>
            
            <!-- when a range for tstamps is included -->
            <xsl:when test="$from.tstamp and $to.tstamp">
                <!-- copy only if tstamp falls into the range -->
                <xsl:if test="some $tstamp in $contained.tstamps satisfies ($tstamp ge $from.tstamp and $tstamp le $to.tstamp)">
                    <xsl:next-match/>
                </xsl:if>
            </xsl:when>
            <!-- when only a starting tstamp is provided -->
            <xsl:when test="$before.tstamp and not($after.tstamp)">
                <!-- copy only if tstamp is lower than desired last tstamp-->
                <xsl:if test="some $tstamp in $contained.tstamps satisfies ($tstamp lt $before.tstamp)">
                    <xsl:next-match/>
                </xsl:if>
            </xsl:when>
            <!-- when only an ending tstamp is provided -->
            <xsl:when test="$after.tstamp and not($before.tstamp)">
                <!-- copy only if tstamp is higher than desired starting tstamp-->
                <xsl:if test="some $tstamp in $contained.tstamps satisfies ($tstamp gt $after.tstamp)">
                    <xsl:next-match/>
                </xsl:if>
            </xsl:when>
            <!-- when a non-inclusive range is desired -->
            <xsl:when test="$before.tstamp and $after.tstamp">
                <!-- copy only if tstamp is between end points-->
                <xsl:if test="some $tstamp in $contained.tstamps satisfies ($tstamp gt $after.tstamp and $tstamp lt $before.tstamp)">
                    <xsl:next-match/>
                </xsl:if>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message select="'ERROR: why this case? ' || @xml:id"/>
                <xsl:next-match/>
            </xsl:otherwise>
        </xsl:choose>
        
    </xsl:template>
    
    <!-- /mode get.by.tstamps – END -->
    
    <!-- mode resolveApp – START -->
    
    <!-- in mode resolveApp, add a reference to the current source to the staff element -->
    <xsl:template match="mei:staff" mode="resolveApp">
        <xsl:param name="source.id" as="xs:string" tunnel="yes"/>
        <xsl:copy>
            <xsl:attribute name="source" select="$source.id"/>
                
            <xsl:apply-templates select="node() | @*" mode="#current"/>        
        </xsl:copy>
    </xsl:template>
    
    <!-- just keep the contents of the right rdg child element -->
    <xsl:template match="mei:app" mode="resolveApp">
        <xsl:param name="source.id" as="xs:string" tunnel="yes"/>
        
        <xsl:apply-templates select="child::mei:rdg[$source.id = tokenize(replace(@source,'#',''),' ')]/child::*" mode="#current"/>
    </xsl:template>
    
    <!-- /mode resolveApp – END -->
    
    
    
    
    <!-- mode-independent functions – START -->
    
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
                        <diff type="att.value" staff="{$source.raw/id($source.elem/@xml:id)/ancestor::mei:staff/@xml:id}" source.elem.name="{local-name($source.elem)}" source.elem.id="{$source.elem/@xml:id}" att.name="{local-name($source.att)}" source.value="{string($source.att)}" core.value="{string($core.atts[local-name() = local-name($source.att)])}" core.elem.id="{$core.elem/@xml:id}" tstamp="{$source.elem/@tstamp}"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <!-- the attribute is missing from the core -->
                        <diff type="att.missing" staff="{$source.raw/id($source.elem/@xml:id)/ancestor::mei:staff/@xml:id}" source.elem.name="{local-name($source.elem)}" source.elem.id="{$source.elem/@xml:id}" missing.in="core" att.name="{local-name($source.att)}" source.value="{string($source.att)}" core.elem.id="{$core.elem/@xml:id}" tstamp="{$source.elem/@tstamp}"/>
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
                        <diff type="att.missing" staff="{$source.raw/id($source.elem/@xml:id)/ancestor::mei:staff/@xml:id}" source.elem.name="{local-name($source.elem)}" source.elem.id="{$source.elem/@xml:id}" missing.in="source" att.name="{local-name($core.att)}" core.value="{string($core.att)}" core.elem.id="{$core.elem/@xml:id}" tstamp="{$source.elem/@tstamp}"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:for-each>
        </xsl:variable>
        <sameas source="{$source.elem/@xml:id}" core="{$core.elem/@xml:id}" diffs="{count($diffs)}" elem.name="{local-name($source.elem)}" tstamp="{$source.elem/@tstamp}"/>
        <xsl:copy-of select="$diffs"/>
        
    </xsl:function>
    
    
    <!-- /mode-independent functions – END -->
    
    <!-- standard copy template for all modes -->
    <xsl:template match="node() | @*" mode="#all">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    
</xsl:stylesheet>