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
                for that movement. It is the final step in setting up the music encodings of the
                Freischütz Digital project (FreiDi, http://www.freischuetz-digital.de). While this stylesheet
                certainly has several components which are of interest to other projects as well, 
                it is highly integrated into the FreiDi workflow, and may not be useful as is to others. 
            </xd:p>
            <xd:p>
                This stylesheet strictly controls its own usage; therefore, it is important to know how to use it. 
                It is applied to a file in "musicSources/sourcePrep/12 Proven ControlEvents". In addition to the 
                regular proofreading, this file must have been treated with the stylesheet "addAccid.ges.xsl" before
                merge2Core2.xsl will accept it as input file. It will also make sure that another source has been used
                already to generate a core file for this particular movement. If not, it will request the user to 
                generate such a core file by using "setupNewCore.xsl" instead of this stylesheet. 
            </xd:p>
            <xd:p>
                In its first run on an acceptable input file, it will generate a temporary "protocol" file, which will
                be stored in the source's subfolder in "14 reCored". This file contains a draft of the future core, and 
                also a copy of the pre-processed source. 
            </xd:p>
            <xd:p>
                There are certain situations where a fully-automated merging of the new source into the existing core is 
                not possible (by reasonable means). In these situations, the stylesheet generates a "hiccup" element with 
                all available information. Less detailed "hiccups" ( //hiccup[@type="control"]) are generated wherever new
                apps and / or readings are generated. 
            </xd:p>
            <xd:p>
                After the first run, it is required to manually examine all these hiccups and resolve them as appropriate. This
                is the most important part of this semi-automatic process, and requires the highest familiarity with the 
                encoding model. 
            </xd:p>
            <xd:p>
                After all hiccups have been resolved (the stylesheet will control that!), this very same XSLT is applied to the 
                very same input file again. It will automatically pick up the temporary protocol file (which should be stored
                in SVN both before and after its manual processing), check if everything is at it should be, and will update the 
                core file accordingly. 
            </xd:p>
            <xd:p>
                After this procedure, another source may be merged into the core. It is very important to resolve sources 
                *completely and one after the other*.
            </xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:output method="xml" indent="yes"/>
    
    <!-- version of this stylesheet -->
    <xsl:variable name="xsl.version" select="'1.0.1'"/>
    
    <!-- gets global variables based on some general principles of the Freischütz Data Model -->
    <xsl:variable name="source.id" select="substring-before(/mei:mei/@xml:id,'_')" as="xs:string"/>
    <xsl:variable name="mov.id" select="substring-before((//mei:measure)[1]/@xml:id,'_measure')" as="xs:string"/>
    <xsl:variable name="mov.n" select="substring-after($mov.id,'_mov')" as="xs:string"/>
    
    <!-- perform checks if everythin is in place as expected -->
    <xsl:variable name="correctFolder" select="starts-with(reverse(tokenize(document-uri(/),'/'))[3],'12')" as="xs:boolean"/>
    <xsl:variable name="basePath" select="substring-before(document-uri(/),'/1')"/>
    <xsl:variable name="sourceThereAlready" select="doc-available(concat($basePath,'/14%20reCored/',$source.id,'/',$mov.id,'.xml'))" as="xs:boolean"/>
    <xsl:variable name="coreThereAlready" select="doc-available(concat($basePath,'/14%20reCored/core_mov',$mov.n,'.xml'))" as="xs:boolean"/>
    
    <xsl:variable name="protocolThereAlready" select="doc-available(concat($basePath,'/14%20reCored/',$source.id,'/core_mov',$mov.n,'+',$source.id,'-protocol.xml'))" as="xs:boolean"/>
    <xsl:variable name="protocol.file" select="doc(concat($basePath,'/14%20reCored/',$source.id,'/core_mov',$mov.n,'+',$source.id,'-protocol','.xml'))" as="node()?"/>
    
    <xsl:variable name="source.raw" select="//mei:mei" as="node()"/>
    <!-- in source.preComp, a file almost similar to a core based on the source is generated. -->
    <xsl:variable name="source.preComp">
        <xsl:apply-templates mode="source.preComp"/>
    </xsl:variable>
    
    <xsl:variable name="core" select="doc(concat($basePath,'/14%20reCored/core_mov',$mov.n,'.xml'))//mei:mei" as="node()"/>
    
    <xsl:variable name="all.sources.so.far" as="xs:string+">
        
        <xsl:choose>
            <xsl:when test="count($core//mei:change) = 1 and $core//mei:change//mei:ptr[starts-with(@target,'setupNewCore.xsl')]">
                <xsl:variable name="full.text" select="normalize-space(string-join($core//mei:change//mei:p//text(),''))" as="xs:string"/>
                <xsl:value-of select="substring-before(substring-after($full.text,' from '),'_')"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="change" select="$core//mei:change[last()]" as="node()"/>
                <xsl:if test="not(starts-with(normalize-space(string-join($change//mei:p//text(),'')),'Merged ')) and $change//mei:ptr[starts-with(@target,'merge2Core2.xsl_')]">
                    <xsl:message terminate="yes" select="'ERROR: The last change element in the core file does not provide information about the source merged so far. Please check!'"/>
                </xsl:if>
                
                <xsl:variable name="complete.string" select="normalize-space(string-join($change//mei:p//text(),''))" as="xs:string"/>
                <xsl:variable name="old.sources" select="tokenize(substring-before(substring-after($complete.string,' movement now contains '),' plus '),', ')" as="xs:string+"/>
                <xsl:variable name="newest.source" select="substring-before(substring-after($complete.string,concat(string-join($old.sources,', '),' plus ')),'.')" as="xs:string"/>
                
                <xsl:sequence select="$old.sources, $newest.source"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    
    
    
    <!-- main template -->
    <xsl:template match="/">
        
        <xsl:if test="not($correctFolder)">
            <xsl:message terminate="yes" select="'You seem to use a file from the wrong folder. Relevant chunk of filePath is: ' || reverse(tokenize(document-uri(/),'/'))[3]"/>
        </xsl:if>
        
        <xsl:if test="$sourceThereAlready">
            <xsl:message terminate="yes" select="'There is already a processed version of the file in /14 reCored…'"/>
        </xsl:if>
        
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
        <xsl:if test="//@artic[not(every $value in tokenize(.,' ') satisfies $value = ('dot','stroke','acc'))]">
            <xsl:message terminate="no" select="'ERROR: @artic uses the following values: /' || string-join((distinct-values(//@artic)),'/, /') || '/, but only /acc/, /dot/ and /stroke/ are supported'"/>
        </xsl:if>
        
        <xsl:choose>
            
            <!-- generate protocol file for manual resolution of problems -->
            <xsl:when test="not($protocolThereAlready)">
                
                <!-- debug -->
                <xsl:message terminate="no" select="'INFO: first round with merge2Core2.xsl to merge ' || $source.id || ' into the core of mov' || $mov.n || '. Existing sources for that movement: ' || string-join($all.sources.so.far,', ')"/>
                <xsl:message terminate="no" select="'   Please continue by manually resolving all issues which cannot be automated in file ' || concat($basePath,'/14%20reCored/',$source.id,'/core_mov',$mov.n,'+',$source.id,'-protocol','.xml')"/>
                <xsl:message select="' '"/>
                
                <!-- in compare.phase1, the actual comparison of events is executed -->
                <xsl:variable name="compare.phase1">
                    <xsl:apply-templates select="$core" mode="compare.phase1"/>
                </xsl:variable>
                
                <!-- in compare.phase2, the actual comparison of controlevents is executed -->
                <xsl:variable name="compare.phase2">
                    <xsl:apply-templates select="$compare.phase1" mode="compare.phase2"/>
                </xsl:variable>
                
                <xsl:variable name="compare.phase3">
                    <xsl:apply-templates select="$compare.phase2" mode="compare.phase3">
                        <xsl:with-param name="core.draft" select="$compare.phase2" tunnel="yes" as="node()"/>
                        <xsl:with-param name="source.preComp" select="$source.preComp" tunnel="yes" as="node()"/>
                    </xsl:apply-templates>
                </xsl:variable>
                
                <xsl:result-document href="{concat($basePath,'/14%20reCored/',$source.id,'/core_mov',$mov.n,'+',$source.id,'-protocol','.xml')}">
                    <protocol>
                        <coreDraft>
                            <xsl:copy-of select="$compare.phase3"/>        
                        </coreDraft>
                        <source.preComp>
                            <xsl:copy-of select="$source.preComp"/>
                        </source.preComp>
                    </protocol>
                </xsl:result-document>
                
                <!-- stop processing if not all elements of the source are synched to the core -->
                <xsl:if test="some $elem in $source.preComp//mei:*[(@tstamp and ancestor::mei:layer and not(local-name() = ('chord','space'))) or (local-name() = 'note') or (local-name() = ('slur','hairpin','dynam','dir') and not(ancestor::mei:orig))]
                    satisfies not($compare.phase3//mei:*[@synch = $elem/@xml:id])">
                    
                    <xsl:variable name="missing.elements" select="$source.preComp//mei:*[((@tstamp and ancestor::mei:layer and not(local-name() = ('chord','space'))) or (local-name() = 'note') or (local-name() = ('slur','hairpin','dynam','dir') and not(ancestor::mei:orig))) and not(@xml:id = $compare.phase3//@synch)]" as="node()+"/>
                    
                    <xsl:message select="' '"/>
                    <xsl:message select="'Attention: Not all elements from the source could be synched properly. Please make sure the following elements are covered while resolving the protocol: '"/>
                    <xsl:for-each select="$missing.elements">
                        <xsl:variable name="elem" select="." as="node()"/>
                        <xsl:choose>
                            <xsl:when test="local-name() = ('slur','hairpin','dynam','dir')">
                                <xsl:message select="'   ' || local-name($elem) || ' ' || $elem/@xml:id || ' (measure ' || $elem/ancestor::mei:measure/@n || ')'"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:message select="'   ' || local-name($elem) || ' ' || $elem/@xml:id || ' (measure ' || $elem/ancestor::mei:measure/@n || ', staff ' || $elem/ancestor::mei:staff/@n || ')'"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:for-each>
                    <xsl:message select="' '"/>
                    <xsl:message terminate="no" select="'Please address these elements while resolving hiccups!'"/>
                </xsl:if>
                
            </xsl:when>
            
            <!-- check if all hiccups are resolved -->
            <xsl:when test="$protocol.file//*[local-name() = 'hiccup' or @hiccup]">
                <!-- debug -->
                <xsl:message terminate="no" select="'INFO: second round with merge2Core2.xsl to merge ' || $source.id || ' into the core of mov' || $mov.n || '. Examining protocol file at ' || concat($basePath,'/14%20reCored/',$source.id,'/core_mov',$mov.n,'+',$source.id,'-protocol','.xml')"/>
                <xsl:message select="' '"/>
                <xsl:message terminate="yes" select="'ERROR: Protocol still contains hiccups. Please resolve!'"/>
            </xsl:when>
            
            <!-- check if all elements in the source are referenced properly -->
            <xsl:when test="some $elem in $protocol.file//source.preComp//mei:*[(@tstamp and ancestor::mei:layer and not(local-name() = ('chord','space'))) or (local-name() = 'note') or (local-name() = ('slur','hairpin','dynam','dir') and not(ancestor::mei:orig))]
                satisfies not($protocol.file//coreDraft//mei:*[@synch = $elem/@xml:id])">
                <xsl:variable name="missing.elements" select="$protocol.file//source.preComp//mei:*[((@tstamp and ancestor::mei:layer and not(local-name() = ('chord','space'))) or (local-name() = 'note') or (local-name() = ('slur','hairpin','dynam','dir') and not(ancestor::mei:orig))) and not(@xml:id = $protocol.file//coreDraft//@synch)]" as="node()+"/>
                
                <!-- debug -->
                <xsl:message terminate="no" select="'INFO: second round with merge2Core2.xsl to merge ' || $source.id || ' into the core of mov' || $mov.n || '. Examining protocol file at ' || concat($basePath,'/14%20reCored/',$source.id,'/core_mov',$mov.n,'+',$source.id,'-protocol','.xml')"/>
                <xsl:message select="' '"/>
                <xsl:message select="'ERROR: Not all elements from the source have been synched properly. Missing elements: '"/>
                <xsl:message select="' '"/>
                <xsl:for-each select="$missing.elements">
                    <xsl:variable name="elem" select="." as="node()"/>
                    <xsl:choose>
                        <xsl:when test="local-name() = ('slur','hairpin','dynam','dir')">
                            <xsl:message select="'   ' || local-name($elem) || ' ' || $elem/@xml:id || ' (measure ' || $elem/ancestor::mei:measure/@n || ')'"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:message select="'   ' || local-name($elem) || ' ' || $elem/@xml:id || ' (measure ' || $elem/ancestor::mei:measure/@n || ', staff ' || $elem/ancestor::mei:staff/@n || ')'"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:for-each>
                <xsl:message select="' '"/>
                <xsl:message terminate="yes" select="'You need to add @synch to the corresponding elements in the core before completing this movement!'"/>
                
            </xsl:when>
            
            <!-- file seems to be ok, so execute final merging -->
            <xsl:otherwise>
                
                <!-- debug -->
                <xsl:message terminate="no" select="'INFO: second round with merge2Core2.xsl to merge ' || $source.id || ' into the core of mov' || $mov.n || '. Examining protocol file at ' || concat($basePath,'/14%20reCored/',$source.id,'/core_mov',$mov.n,'+',$source.id,'-protocol','.xml')"/>
                <xsl:message select="' '"/>
                
                <xsl:variable name="newCore" select="$protocol.file//coreDraft/mei:mei" as="node()"/>
                <xsl:variable name="source.preComp" select="$protocol.file//source.preComp/mei:mei" as="node()"/>
                
                <xsl:result-document href="{concat($basePath,'/14%20reCored/',$source.id,'/',$mov.id,'.xml')}">
                    <xsl:apply-templates select="$source.raw" mode="source.cleanup">
                        <xsl:with-param name="core.draft" select="$newCore" tunnel="yes"/>
                    </xsl:apply-templates>
                </xsl:result-document>
                
                <!-- core file -->
                <xsl:result-document href="{concat($basePath,'/14%20reCored/_core_mov',$mov.n,'.','xml')}">
                    <xsl:apply-templates select="$newCore" mode="core.cleanup"/>
                </xsl:result-document>
            </xsl:otherwise>
            
        </xsl:choose>
        
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
            <xsl:if test="not(exists(mei:application[@xml:id='merge2Core2.xsl_v' || $xsl.version]))">
                <application xmlns="http://www.music-encoding.org/ns/mei">
                    <xsl:attribute name="xml:id" select="'merge2Core2.xsl_v' || $xsl.version"/>
                    <xsl:attribute name="version" select="$xsl.version"/>
                    <name>merge2Core2.xsl</name>
                    <ptr target="https://github.com/Freischuetz-Digital/Tools/blob/develop/14%20reCore/merge2Core2.xsl"/>
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
                        <ptr target="merge2Core2.xsl_v{$xsl.version}"/>. Now all differences after proofreading <xsl:value-of select="$mov.id"/>
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
    <xsl:template match="@sameas[not(parent::mei:measure)]" mode="source.preComp"/>
    <xsl:template match="@stem.dir" mode="source.preComp"/>
    <xsl:template match="@curvedir" mode="source.preComp"/>
    <xsl:template match="@place" mode="source.preComp"/>
    <xsl:template match="mei:facsimile" mode="source.preComp"/>
    <xsl:template match="@facs" mode="source.preComp"/>
    <xsl:template match="@corresp" mode="source.preComp"/>
    <xsl:template match="@fermata" mode="source.preComp">
        <xsl:attribute name="fermata" select="'above'"/>
    </xsl:template>
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
            <xsl:apply-templates select="parent::mei:chord/@artic | parent::mei:chord/@dots | parent::mei:chord/@tie" mode="profiling.prep"/>
            <xsl:apply-templates select="node() | @*" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    <!-- in case of multiple layers, make sure to share articulation -->
    <xsl:template match="mei:note[not(parent::mei:chord) and not(@grace)]" mode="profiling.prep">
        <xsl:copy>
            <xsl:if test="not(@artic)">
                <xsl:variable name="tstamp" select="@tstamp" as="xs:string"/>
                <xsl:variable name="dur" select="@dur" as="xs:string"/>
                <xsl:variable name="dots" select="@dots" as="xs:string?"/>
                
                <xsl:apply-templates select="ancestor::mei:staff//mei:note[@tstamp = $tstamp and @dur = $dur and (if ($dots) then(@dots and @dots = $dots) else(true()))]/@artic" mode="#current"/>
            </xsl:if>
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
    
    <xsl:template match="mei:space" mode="profiling.prep"/>
    
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
    
    <xsl:template match="mei:appInfo" mode="compare.phase1">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*" mode="#current"/>
            <xsl:if test="not(exists(mei:application[@xml:id='merge2Core2.xsl_v' || $xsl.version]))">
                <application xmlns="http://www.music-encoding.org/ns/mei">
                    <xsl:attribute name="xml:id" select="'merge2Core2.xsl_v' || $xsl.version"/>
                    <xsl:attribute name="version" select="$xsl.version"/>
                    <name>merge2Core2.xsl</name>
                    <ptr target="https://github.com/Freischuetz-Digital/Tools/blob/develop/14%20reCore/merge2Core2.xsl"/>
                </application>
            </xsl:if>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="mei:revisionDesc" mode="compare.phase1">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*" mode="#current"/>
            <change xmlns="http://www.music-encoding.org/ns/mei">
                <xsl:attribute name="n" select="count(mei:change) + 1"/>
                <respStmt>
                    <persName>Johannes Kepper</persName>
                </respStmt>
                <changeDesc>
                    <p>
                        Generated prototype for integrating <xsl:value-of select="$mov.id"/> into core.xml using 
                        <ptr target="merge2Core2.xsl_v{$xsl.version}"/>.
                    </p>
                </changeDesc>
                <date isodate="{substring(string(current-date()),1,10)}"/>
            </change>
            <change xmlns="http://www.music-encoding.org/ns/mei">
                <xsl:attribute name="n" select="count(mei:change) + 2"/>
                <respStmt>
                    <persName>Joachim Iffland</persName>
                </respStmt>
                <changeDesc>
                    <p>
                        Manually resolved hiccups from generated prototype for <xsl:value-of select="$mov.id"/>. File is now ready to be merged with core.
                    </p>
                </changeDesc>
                <date isodate="{substring(string(current-date()),1,10)}"/>
            </change>
            <hiccup reason="adjustChangeElem">Please give correct credit and date here!</hiccup>
        </xsl:copy>
    </xsl:template>
    
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
    
    <!-- this template is the main component for resolving events -->
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
                    <xsl:message terminate="no" select="'WARNING: source ' || $source.id || ' matches the text of the following sources in '|| $core.staff.raw/@xml:id || ', even though they differ: ' || string-join($matching.source.id,', ')"/>
                </xsl:if>
                
                <xsl:message select="'   INFO: ' || $source.staff.raw/@xml:id || ' has the same text as ' || $matching.source.id[1] || '. No special treatment scheduled.'"/>
                
                <xsl:copy>
                    <xsl:apply-templates select="node() | @*" mode="merge">
                        <xsl:with-param name="matching.source.id" select="$matching.source.id[1]" as="xs:string" tunnel="yes"/>
                        <xsl:with-param name="corresp" select="$full.source.comparisons/descendant-or-self::source[@id = $matching.source.id[1]]//sameas" as="node()*" tunnel="yes"/>
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
                                    
                                    <xsl:message select="'   INFO: ' || $source.staff.raw/@xml:id || '/layer[' || $core.layer/@n || '] differs, without existing differences in the other sources.'"/>
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
                                        
                                        <!-- decide if there is a beam or tuplet enclosing all content of the prospective app -->
                                        <xsl:variable name="grouping.ancestor" as="node()?">
                                            <xsl:variable name="affected.elements" select="$core.layer//mei:*[@tstamp and 
                                                number(@tstamp) ge number($current.diffGroup/@tstamp.first) and
                                                number(@tstamp) le number($current.diffGroup/@tstamp.last)]" as="node()*"/>
                                            
                                            <xsl:if test="count(distinct-values($affected.elements/ancestor::mei:*[local-name() =  ('beam','tuplet')]/@xml:id)) = 1">
                                                <xsl:sequence select="$affected.elements/ancestor::mei:*[local-name() =  ('beam','tuplet')]"/>
                                            </xsl:if>
                                        </xsl:variable>
                                        <xsl:if test="exists($grouping.ancestor) and (min($grouping.ancestor//number(@tstamp)) lt $current.diffGroup/number(@tstamp.first) or max($grouping.ancestor//number(@tstamp)) gt $current.diffGroup/number(@tstamp.last))">
                                            <xsl:message select="'HICCUP: the ' || local-name($grouping.ancestor) || ' with xml:id ' || $grouping.ancestor/@xml:id || ' is probably nested incorrectly. Please check!'"></xsl:message>
                                            <hiccup reason="nesting" elem.name="{local-name($grouping.ancestor)}" elem.id="{$grouping.ancestor/@xml:id}">nesting is probably broken, element may have been encoded multiple times</hiccup>
                                        </xsl:if>
                                        
                                        <app xmlns="http://www.music-encoding.org/ns/mei" xml:id="{'a'||uuid:randomUUID()}">
                                            <rdg xml:id="{$first.rdg.id}" source="#{string-join($all.sources.so.far,' #')}">
                                                <xsl:apply-templates select="$core.layer/child::mei:*" mode="get.by.tstamps">
                                                    <xsl:with-param name="from.tstamp" select="number($current.diffGroup/@tstamp.first)" as="xs:double" tunnel="yes"/>
                                                    <xsl:with-param name="to.tstamp" select="number($current.diffGroup/@tstamp.last)" as="xs:double" tunnel="yes"/>
                                                </xsl:apply-templates>
                                            </rdg>
                                            <rdg xml:id="{$second.rdg.id}" source="#{$source.id}">
                                                <xsl:apply-templates select="$source.layer/child::mei:*" mode="get.by.tstamps">
                                                    <xsl:with-param name="from.tstamp" select="number($current.diffGroup/@tstamp.first)" as="xs:double" tunnel="yes"/>
                                                    <xsl:with-param name="to.tstamp" select="number($current.diffGroup/@tstamp.last)" as="xs:double" tunnel="yes"/>
                                                    <xsl:with-param name="corresp" select="$layer.comparison/descendant-or-self::sameas" as="node()*" tunnel="yes"/>
                                                    <xsl:with-param name="needs.fresh.id" select="true()" as="xs:boolean" tunnel="yes"/>
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
                                        <hiccup reason="control">added an app in a previously unapped staff</hiccup>
                                        
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
            
            <!-- core and source have the same number of layers, existing differences -->
            <xsl:when test="$core.staff.raw//mei:app and count($core.staff.raw/mei:layer) = count($source.staff.raw/mei:layer)">
                
                <!-- need to split up by ranges -->
                
                <xsl:copy>
                    <xsl:apply-templates select="@*" mode="#current"/>
                    
                    <!-- address layers individually -->
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
                                
                                <!-- this layer needs to be split up into multiple ranges -->
                                <xsl:when test="$core.layer//mei:app">
                                    
                                    <!-- generate a separate comparison with the text version of each source -->
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
                                    <xsl:variable name="matching.source.id" select="($layer.source.comparisons/descendant-or-self::source[count(.//diff) = 0])[1]/@id" as="xs:string?"/>
                                    
                                    <!--<!-\- debug message -\->
                                    <xsl:if test="count($matching.source.id) gt 1">
                                        <xsl:message terminate="yes" select="'Error: source ' || $source.id || ' matches the text of the following sources in '|| $core.staff.raw/@xml:id || ', even though they should differ: ' || string-join($matching.source.id,', ')"/>
                                        <!-\- this error is probably incorrect, as multiple sources might share the same variant without causing a problem. 
                                            Probably I only need to ensure that $matching.source.id takes the id of just the first matching source, and that's it… -\->
                                    </xsl:if>-->
                                    
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
                                            <xsl:message select="'   INFO: more apps need to be generated for '  || $source.staff.raw/@xml:id || '/layer[' || $core.layer/@n || ']'"/>
                                            
                                            <!-- get the id of the source with the smallest number of differences -->
                                            <xsl:variable name="closest.source.id" as="xs:string">
                                                <xsl:variable name="sources.sorted" as="node()+">
                                                    <xsl:for-each select="$layer.source.comparisons/descendant-or-self::source">
                                                        <xsl:sort select="count(.//sameas) div count(.//diff)" data-type="number" order="descending"/>
                                                        <xsl:sequence select="."/>
                                                    </xsl:for-each>
                                                </xsl:variable>
                                                <xsl:value-of select="$sources.sorted[1]/@id"/>
                                            </xsl:variable>
                                            
                                            <xsl:message select="'      DETAIL: closest source is ' || $closest.source.id"/>
                                            
                                            <!-- get the raw text of the closest source -->
                                            <xsl:variable name="closest.rdg.layer.raw" as="node()">
                                                <xsl:apply-templates select="$core.layer" mode="resolveApp">
                                                    <xsl:with-param name="source.id" select="$closest.source.id" as="xs:string" tunnel="yes"/>
                                                </xsl:apply-templates>
                                            </xsl:variable>
                                            
                                            <!-- generate the comparison profile for the closest source -->
                                            <xsl:variable name="closest.rdg.layer.profile" as="node()">
                                                <xsl:apply-templates select="$closest.rdg.layer.raw" mode="profiling.prep">
                                                    <xsl:with-param name="trans.semi" select="$trans.semi.core" tunnel="yes" as="xs:string?"/>
                                                </xsl:apply-templates>
                                            </xsl:variable>
                                            
                                            <!-- identify the ranges of apps existing in the core already -->
                                            <xsl:variable name="existing.ranges" as="node()+">
                                                <xsl:for-each select="$core.layer//mei:app">
                                                    <range tstamp.first="{min(.//mei:*[@tstamp]/number(@tstamp))}" tstamp.last="{max(.//mei:*[@tstamp]/number(@tstamp))}"/>
                                                </xsl:for-each>
                                            </xsl:variable>
                                            
                                            <!-- calculate optimal grouping of diffs, based on existing apps -->
                                            <xsl:variable name="closest.rdg.layer.diffs" select="local:groupDiffs($layer.source.comparisons/descendant-or-self::source[@id = $closest.source.id]//diff,$closest.rdg.layer.profile,$source.layer.profile,$existing.ranges)"/>
                                            
                                            
                                            <!-- deal with area preceding the first existing app -->
                                            <xsl:variable name="first.diff.tstamp" select="min($existing.ranges/descendant-or-self::range/number(@tstamp.first))" as="xs:double"/>
                                            <xsl:choose>
                                                <!-- no spotted differences precede the first existing app -->
                                                <xsl:when test="not(min($closest.rdg.layer.diffs//diffGroup/number(@tstamp.first)) lt $first.diff.tstamp)">
                                                    
                                                    <xsl:apply-templates select="$core.layer/child::mei:*" mode="get.by.tstamps">
                                                        <xsl:with-param name="before.tstamp" select="$first.diff.tstamp" as="xs:double" tunnel="yes"/>
                                                        <xsl:with-param name="matching.source.id" select="$closest.source.id" as="xs:string" tunnel="yes"/>
                                                        <xsl:with-param name="corresp" select="$layer.source.comparisons/descendant-or-self::source[@id = $closest.source.id]//sameas" as="node()*" tunnel="yes"/>
                                                    </xsl:apply-templates>
                                                    
                                                </xsl:when>
                                                
                                                <!-- one or more diffs are spotted before the first existing app -->
                                                <xsl:otherwise>
                                                    <xsl:variable name="relevant.diffs" select="$closest.rdg.layer.diffs//diffGroup[number(@tstamp.first) lt $first.diff.tstamp]" as="node()+"/>
                                                    
                                                    <xsl:for-each select="$relevant.diffs">
                                                        
                                                        <xsl:variable name="current.diffGroup" select="." as="node()"/>
                                                        <xsl:variable name="current.pos" select="position()" as="xs:integer"/>
                                                        
                                                        <!-- deal with material preceding the first difference -->
                                                        <xsl:if test="$current.pos = 1">
                                                            <xsl:apply-templates select="$core.layer/child::mei:*" mode="get.by.tstamps">
                                                                <xsl:with-param name="after.tstamp" select="0" as="xs:double" tunnel="yes"/>
                                                                <xsl:with-param name="before.tstamp" select="$current.diffGroup/@tstamp.first" as="xs:double" tunnel="yes"/>
                                                                <xsl:with-param name="corresp" select="$layer.source.comparisons/descendant-or-self::source[@id = $closest.source.id]//sameas" as="node()*" tunnel="yes"/>
                                                                <xsl:with-param name="matching.source.id" select="$closest.source.id" as="xs:string" tunnel="yes"/>
                                                            </xsl:apply-templates>
                                                        </xsl:if>
                                                        
                                                        <xsl:message select="'      INFO: Inserting new app from tstamp ' || $current.diffGroup/@tstamp.first || ' to ' || $current.diffGroup/@tstamp.last"/>
                                                        
                                                        <xsl:variable name="first.rdg.id" select="'c'||uuid:randomUUID()" as="xs:string"/>
                                                        <xsl:variable name="second.rdg.id" select="'c'||uuid:randomUUID()" as="xs:string"/>
                                                        <xsl:variable name="annot.id" select="'c'||uuid:randomUUID()" as="xs:string"/>
                                                        
                                                        <!-- decide if there is a beam or tuplet enclosing all content of the prospective app -->
                                                        <xsl:variable name="grouping.ancestor" as="node()?">
                                                            <xsl:variable name="affected.elements" select="$core.layer//mei:*[@tstamp and 
                                                                number(@tstamp) ge number($current.diffGroup/@tstamp.first) and
                                                                number(@tstamp) le number($current.diffGroup/@tstamp.last)]" as="node()*"/>
                                                            
                                                            <xsl:if test="count(distinct-values($affected.elements/ancestor::mei:*[local-name() =  ('beam','tuplet')]/@xml:id)) = 1">
                                                                <xsl:sequence select="$affected.elements/ancestor::mei:*[local-name() =  ('beam','tuplet')]"/>
                                                            </xsl:if>
                                                        </xsl:variable>
                                                        <xsl:if test="exists($grouping.ancestor) and (min($grouping.ancestor//number(@tstamp)) lt $current.diffGroup/number(@tstamp.first) or max($grouping.ancestor//number(@tstamp)) gt $current.diffGroup/number(@tstamp.last))">
                                                            <xsl:message select="'HICCUP: the ' || local-name($grouping.ancestor) || ' with xml:id ' || $grouping.ancestor/@xml:id || ' is probably nested incorrectly. Please check!'"></xsl:message>
                                                            <hiccup reason="nesting" elem.name="{local-name($grouping.ancestor)}" elem.id="{$grouping.ancestor/@xml:id}">nesting is probably broken, element may have been encoded multiple times</hiccup>
                                                        </xsl:if>
                                                        
                                                        <app xmlns="http://www.music-encoding.org/ns/mei" xml:id="{'a'||uuid:randomUUID()}">
                                                            <rdg xml:id="{$first.rdg.id}" source="#{string-join($all.sources.so.far,' #')}">
                                                                <xsl:apply-templates select="$core.layer/child::mei:*" mode="get.by.tstamps">
                                                                    <xsl:with-param name="from.tstamp" select="number($current.diffGroup/@tstamp.first)" as="xs:double" tunnel="yes"/>
                                                                    <xsl:with-param name="to.tstamp" select="number($current.diffGroup/@tstamp.last)" as="xs:double" tunnel="yes"/>
                                                                </xsl:apply-templates>
                                                            </rdg>
                                                            <rdg xml:id="{$second.rdg.id}" source="#{$source.id}">
                                                                
                                                                <xsl:apply-templates select="$source.layer/child::mei:*" mode="get.by.tstamps">
                                                                    <xsl:with-param name="from.tstamp" select="number($current.diffGroup/@tstamp.first)" as="xs:double" tunnel="yes"/>
                                                                    <xsl:with-param name="to.tstamp" select="number($current.diffGroup/@tstamp.last)" as="xs:double" tunnel="yes"/>
                                                                    <xsl:with-param name="corresp" select="$layer.source.comparisons/descendant-or-self::source[@id = $closest.source.id]//sameas" as="node()*" tunnel="yes"/>
                                                                    <xsl:with-param name="needs.fresh.id" select="true()" as="xs:boolean" tunnel="yes"/>
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
                                                        <hiccup reason="control">added an app before the first existing app</hiccup>
                                                        
                                                        <!-- deal with material following the diff -->
                                                        <xsl:choose>
                                                            <!-- when there are subsequent diffs -->
                                                            <xsl:when test="$current.pos lt count($relevant.diffs)">
                                                                <xsl:apply-templates select="$core.layer/child::mei:*" mode="get.by.tstamps">
                                                                    <xsl:with-param name="after.tstamp" select="number($current.diffGroup/@tstamp.last)" as="xs:double" tunnel="yes"/>
                                                                    <xsl:with-param name="before.tstamp" select="number($relevant.diffs[($current.pos + 1)]/@tstamp.first)" as="xs:double" tunnel="yes"/>
                                                                    <xsl:with-param name="corresp" select="$layer.source.comparisons/descendant-or-self::source[@id = $closest.source.id]//sameas" as="node()*" tunnel="yes"/>
                                                                    <xsl:with-param name="matching.source.id" select="$closest.source.id" as="xs:string" tunnel="yes"/>
                                                                </xsl:apply-templates>
                                                            </xsl:when>
                                                            <!-- when this is the last diff -->
                                                            <xsl:otherwise>
                                                                <xsl:apply-templates select="$core.layer/child::mei:*" mode="get.by.tstamps">
                                                                    <xsl:with-param name="after.tstamp" select="number($current.diffGroup/@tstamp.last)" as="xs:double" tunnel="yes"/>
                                                                    <xsl:with-param name="before.tstamp" select="$first.diff.tstamp" as="xs:double" tunnel="yes"/>
                                                                    <xsl:with-param name="corresp" select="$layer.source.comparisons/descendant-or-self::source[@id = $closest.source.id]//sameas" as="node()*" tunnel="yes"/>
                                                                    <xsl:with-param name="matching.source.id" select="$closest.source.id" as="xs:string" tunnel="yes"/>
                                                                </xsl:apply-templates>
                                                            </xsl:otherwise>
                                                        </xsl:choose>
                                                        
                                                    </xsl:for-each>
                                                    
                                                </xsl:otherwise>
                                                
                                            </xsl:choose>
                                            
                                            <!-- deal with all existing apps -->
                                            <xsl:for-each select="$existing.ranges">
                                                <xsl:variable name="current.range" select="." as="node()"/>
                                                <xsl:variable name="current.pos" select="position()" as="xs:integer"/>
                                                
                                                <xsl:variable name="current.app" select="($core.layer//mei:app[min(.//mei:*[@tstamp]/number(@tstamp)) = $current.range/@tstamp.first])[1]" as="node()"/>
                                                
                                                <!-- decide if a new diff is inside this app -->
                                                <xsl:choose>
                                                    
                                                    <!-- no diff found for this app -->
                                                    <xsl:when test="not($closest.rdg.layer.diffs//diffGroup[number(@tstamp.first) ge $current.range/number(@tstamp.first)
                                                        and number(@tstamp.last) le $current.range/number(@tstamp.last)])">
                                                        
                                                        
                                                        <xsl:apply-templates select="$current.app" mode="#current">
                                                            <xsl:with-param name="matching.source" select="$closest.source.id" as="xs:string" tunnel="yes"/>
                                                            <xsl:with-param name="corresp" select="$layer.source.comparisons/descendant-or-self::source[@id = $closest.source.id]//sameas" as="node()*" tunnel="yes"/>
                                                        </xsl:apply-templates>
                                                        
                                                        <xsl:apply-templates select="$current.app/following-sibling::mei:annot[1]" mode="#current"/>
                                                        
                                                    </xsl:when>
                                                    
                                                    <!-- a diff has exactly the same extension as the current app -> just create a new rdg -->
                                                    <xsl:when test="$closest.rdg.layer.diffs//diffGroup[number(@tstamp.first) = $current.range/number(@tstamp.first)
                                                        and number(@tstamp.last) = $current.range/number(@tstamp.last)]">
                                                        
                                                        <!-- todo: maybe it's better to ckeck all rdgs for better matches… -->
                                                        
                                                        <xsl:variable name="current.diffGroup" select="$closest.rdg.layer.diffs//diffGroup[number(@tstamp.first) = $current.range/number(@tstamp.first)
                                                            and number(@tstamp.last) = $current.range/number(@tstamp.last)]" as="node()"/>
                                                        <xsl:variable name="new.rdg.id" select="'c'||uuid:randomUUID()" as="xs:string"/>
                                                        
                                                        <xsl:message select="'      INFO: added new rdg for ' || $source.id || ' to app starting at tstamp ' || $current.range/@tstamp.first"/>
                                                        
                                                        <app xmlns="http://www.music-encoding.org/ns/mei">
                                                            <!-- copy existing app and rdg(s) -->
                                                            <xsl:apply-templates select="$current.app/@* | $current.app/mei:rdg" mode="#current"/>
                                                            
                                                            <rdg xmlns="http://www.music-encoding.org/ns/mei" xml:id="{$new.rdg.id}" source="#{$source.id}">
                                                                
                                                                <xsl:apply-templates select="$source.layer/child::mei:*" mode="get.by.tstamps">
                                                                    <xsl:with-param name="from.tstamp" select="number($current.diffGroup/@tstamp.first)" as="xs:double" tunnel="yes"/>
                                                                    <xsl:with-param name="to.tstamp" select="number($current.diffGroup/@tstamp.last)" as="xs:double" tunnel="yes"/>
                                                                    <xsl:with-param name="corresp" select="$layer.source.comparisons/descendant-or-self::source[@id = $closest.source.id]//sameas" as="node()*" tunnel="yes"/>
                                                                    <xsl:with-param name="needs.fresh.id" select="true()" as="xs:boolean" tunnel="yes"/>
                                                                </xsl:apply-templates>
                                                                
                                                            </rdg>
                                                            <hiccup reason="control">added a new reading for this source</hiccup>
                                                        </app>
                                                        
                                                        <xsl:apply-templates select="$current.app/following-sibling::mei:annot[1]" mode="#current">
                                                            <xsl:with-param name="add.plist.entry" select="$new.rdg.id" tunnel="yes" as="xs:string"/>
                                                        </xsl:apply-templates>
                                                    </xsl:when>
                                                    
                                                    <!-- there must be one or more diffs, which require to split the app into different tstamp ranges -->
                                                    <xsl:otherwise>
                                                        <xsl:variable name="relevant.diffs" select="$closest.rdg.layer.diffs//diffGroup[number(@tstamp.first) ge $current.range/number(@tstamp.first)
                                                            and number(@tstamp.last) le $current.range/number(@tstamp.last)]" as="node()+"/>
                                                        
                                                        <xsl:message select="'      HICCUP: app starting at tstamp ' || $current.range/@tstamp.first || ' needs to be revamped. Generated hiccup for manual resolution.'"/>
                                                        
                                                        <hiccup reason="diff.in.app">
                                                            <core source="#{string-join($all.sources.so.far,' #')}">
                                                                <xsl:apply-templates select="$current.app" mode="#current"/>
                                                            </core>
                                                            <source id="{$source.id}">
                                                                <xsl:apply-templates select="$source.layer/child::mei:*" mode="get.by.tstamps">
                                                                    <xsl:with-param name="from.tstamp" select="number($current.range/@tstamp.first)" as="xs:double" tunnel="yes"/>
                                                                    <xsl:with-param name="to.tstamp" select="number($current.range/@tstamp.last)" as="xs:double" tunnel="yes"/>
                                                                    <xsl:with-param name="corresp" select="$layer.source.comparisons/descendant-or-self::source[@id = $closest.source.id]//sameas" as="node()*" tunnel="yes"/>
                                                                </xsl:apply-templates>
                                                            </source>
                                                            <protocol closest.source.id="{$closest.source.id}">
                                                                <xsl:copy-of select="$relevant.diffs"/>
                                                            </protocol>
                                                        </hiccup>
                                                        
                                                        
                                                    </xsl:otherwise>
                                                    
                                                    
                                                </xsl:choose>
                                                
                                                <!-- deal with material between apps -->
                                                <xsl:choose>
                                                    <!-- there are subsequent apps -->
                                                    <xsl:when test="$current.pos lt count($existing.ranges)">
                                                        <xsl:variable name="next.start" select="number($existing.ranges[($current.pos + 1)]/@tstamp.first)" as="xs:double"/>
                                                        
                                                        <!-- get potential diffs for this section -->
                                                        <xsl:variable name="relevant.diffs" select="$closest.rdg.layer.diffs//diffGroup[number(@tstamp.first) gt $current.range/number(@tstamp.last)
                                                            and number(@tstamp.last) lt $next.start]" as="node()*"/>
                                                        
                                                        <xsl:choose>
                                                            <!-- when there are no diffs in here, just include the relevant content -->
                                                            <xsl:when test="count($relevant.diffs) = 0">
                                                                <xsl:apply-templates select="$core.layer/child::mei:*" mode="get.by.tstamps">
                                                                    <xsl:with-param name="after.tstamp" select="$current.range/number(@tstamp.last)" as="xs:double" tunnel="yes"/>
                                                                    <xsl:with-param name="before.tstamp" select="$next.start" as="xs:double" tunnel="yes"/>
                                                                    <xsl:with-param name="matching.source.id" select="$closest.source.id" as="xs:string" tunnel="yes"/>
                                                                    <xsl:with-param name="corresp" select="$layer.source.comparisons/descendant-or-self::source[@id = $closest.source.id]//sameas" as="node()*" tunnel="yes"/>
                                                                </xsl:apply-templates>
                                                                
                                                            </xsl:when>
                                                            <!-- there are diffs in here -->
                                                            <xsl:otherwise>
                                                                
                                                                <xsl:for-each select="$relevant.diffs">
                                                                    
                                                                    <xsl:variable name="current.diffGroup" select="." as="node()"/>
                                                                    <xsl:variable name="current.pos" select="position()" as="xs:integer"/>
                                                                    
                                                                    <xsl:message select="'      INFO: Inserting new app from tstamp ' || $current.diffGroup/@tstamp.first || ' to ' || $current.diffGroup/@tstamp.last"/>
                                                                    
                                                                    <xsl:variable name="first.rdg.id" select="'c'||uuid:randomUUID()" as="xs:string"/>
                                                                    <xsl:variable name="second.rdg.id" select="'c'||uuid:randomUUID()" as="xs:string"/>
                                                                    <xsl:variable name="annot.id" select="'c'||uuid:randomUUID()" as="xs:string"/>
                                                                    
                                                                    <!-- decide if there is a beam or tuplet enclosing all content of the prospective app -->
                                                                    <xsl:variable name="grouping.ancestor" as="node()?">
                                                                        <xsl:variable name="affected.elements" select="$core.layer//mei:*[@tstamp and 
                                                                            number(@tstamp) ge number($current.diffGroup/@tstamp.first) and
                                                                            number(@tstamp) le number($current.diffGroup/@tstamp.last)]" as="node()*"/>
                                                                        
                                                                        <xsl:if test="count(distinct-values($affected.elements/ancestor::mei:*[local-name() =  ('beam','tuplet')]/@xml:id)) = 1">
                                                                            <xsl:sequence select="$affected.elements/ancestor::mei:*[local-name() =  ('beam','tuplet')]"/>
                                                                        </xsl:if>
                                                                    </xsl:variable>
                                                                    <xsl:if test="exists($grouping.ancestor) and (min($grouping.ancestor//number(@tstamp)) lt $current.diffGroup/number(@tstamp.first) or max($grouping.ancestor//number(@tstamp)) gt $current.diffGroup/number(@tstamp.last))">
                                                                        <xsl:message select="'HICCUP: the ' || local-name($grouping.ancestor) || ' with xml:id ' || $grouping.ancestor/@xml:id || ' is probably nested incorrectly. Please check!'"></xsl:message>
                                                                        <hiccup reason="nesting" elem.name="{local-name($grouping.ancestor)}" elem.id="{$grouping.ancestor/@xml:id}">nesting is probably broken, element may have been encoded multiple times</hiccup>
                                                                    </xsl:if>
                                                                    
                                                                    <app xmlns="http://www.music-encoding.org/ns/mei" xml:id="{'a'||uuid:randomUUID()}">
                                                                        <rdg xml:id="{$first.rdg.id}" source="#{string-join($all.sources.so.far,' #')}">
                                                                            <xsl:apply-templates select="$core.layer/child::mei:*" mode="get.by.tstamps">
                                                                                <xsl:with-param name="from.tstamp" select="number($current.diffGroup/@tstamp.first)" as="xs:double" tunnel="yes"/>
                                                                                <xsl:with-param name="to.tstamp" select="number($current.diffGroup/@tstamp.last)" as="xs:double" tunnel="yes"/>
                                                                            </xsl:apply-templates>
                                                                        </rdg>
                                                                        <rdg xml:id="{$second.rdg.id}" source="#{$source.id}">
                                                                            
                                                                            <xsl:apply-templates select="$source.layer/child::mei:*" mode="get.by.tstamps">
                                                                                <xsl:with-param name="from.tstamp" select="number($current.diffGroup/@tstamp.first)" as="xs:double" tunnel="yes"/>
                                                                                <xsl:with-param name="to.tstamp" select="number($current.diffGroup/@tstamp.last)" as="xs:double" tunnel="yes"/>
                                                                                <xsl:with-param name="corresp" select="$layer.source.comparisons/descendant-or-self::source[@id = $closest.source.id]//sameas" as="node()*" tunnel="yes"/>
                                                                                <xsl:with-param name="needs.fresh.id" select="true()" as="xs:boolean" tunnel="yes"/>
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
                                                                    <hiccup reason="control">added an app between / before / after existing apps</hiccup>
                                                                    
                                                                    <!-- deal with material following the diff -->
                                                                    <xsl:choose>
                                                                        <!-- when there are subsequent diffs -->
                                                                        <xsl:when test="$current.pos lt count($relevant.diffs)">
                                                                            <xsl:apply-templates select="$core.layer/child::mei:*" mode="get.by.tstamps">
                                                                                <xsl:with-param name="after.tstamp" select="number($current.diffGroup/@tstamp.last)" as="xs:double" tunnel="yes"/>
                                                                                <xsl:with-param name="before.tstamp" select="number($relevant.diffs[($current.pos + 1)]/@tstamp.first)" as="xs:double" tunnel="yes"/>
                                                                                <xsl:with-param name="corresp" select="$layer.source.comparisons/descendant-or-self::source[@id = $closest.source.id]//sameas" as="node()*" tunnel="yes"/>
                                                                                <xsl:with-param name="matching.source.id" select="$closest.source.id" as="xs:string" tunnel="yes"/>
                                                                            </xsl:apply-templates>
                                                                        </xsl:when>
                                                                        <!-- when this is the last diff -->
                                                                        <xsl:otherwise>
                                                                            <xsl:apply-templates select="$core.layer/child::mei:*" mode="get.by.tstamps">
                                                                                <xsl:with-param name="after.tstamp" select="number($current.diffGroup/@tstamp.last)" as="xs:double" tunnel="yes"/>
                                                                                <xsl:with-param name="before.tstamp" select="$next.start" as="xs:double" tunnel="yes"/>
                                                                                <xsl:with-param name="corresp" select="$layer.source.comparisons/descendant-or-self::source[@id = $closest.source.id]//sameas" as="node()*" tunnel="yes"/>
                                                                                <xsl:with-param name="matching.source.id" select="$closest.source.id" as="xs:string" tunnel="yes"/>
                                                                            </xsl:apply-templates>
                                                                        </xsl:otherwise>
                                                                    </xsl:choose>
                                                                    
                                                                </xsl:for-each>
                                                                
                                                                
                                                            </xsl:otherwise>
                                                            
                                                        </xsl:choose>
                                                        
                                                    </xsl:when>
                                                    <!-- this is the end of the layer, after the final app -->
                                                    <xsl:otherwise>
                                                        
                                                        <!-- get potential diffs for this section -->
                                                        <xsl:variable name="relevant.diffs" select="$closest.rdg.layer.diffs//diffGroup[number(@tstamp.first) gt $current.range/number(@tstamp.last)]" as="node()*"/>
                                                        
                                                        <xsl:choose>
                                                            <!-- when there are no diffs in here, just include the relevant content -->
                                                            <xsl:when test="count($relevant.diffs) = 0">
                                                                <xsl:apply-templates select="$core.layer/child::mei:*" mode="get.by.tstamps">
                                                                    <xsl:with-param name="after.tstamp" select="$current.range/number(@tstamp.last)" as="xs:double" tunnel="yes"/>
                                                                    <xsl:with-param name="matching.source.id" select="$closest.source.id" as="xs:string" tunnel="yes"/>
                                                                    <xsl:with-param name="corresp" select="$layer.source.comparisons/descendant-or-self::source[@id = $closest.source.id]//sameas" as="node()*" tunnel="yes"/>
                                                                </xsl:apply-templates>
                                                            </xsl:when>
                                                            <!-- there are diffs in here -->
                                                            <xsl:otherwise>
                                                                
                                                                <xsl:for-each select="$relevant.diffs">
                                                                    
                                                                    <xsl:variable name="current.diffGroup" select="." as="node()"/>
                                                                    <xsl:variable name="current.pos" select="position()" as="xs:integer"/>
                                                                    
                                                                    <xsl:message select="'      INFO: Inserting new app from tstamp ' || $current.diffGroup/@tstamp.first || ' to ' || $current.diffGroup/@tstamp.last"/>
                                                                    
                                                                    <xsl:variable name="first.rdg.id" select="'c'||uuid:randomUUID()" as="xs:string"/>
                                                                    <xsl:variable name="second.rdg.id" select="'c'||uuid:randomUUID()" as="xs:string"/>
                                                                    <xsl:variable name="annot.id" select="'c'||uuid:randomUUID()" as="xs:string"/>
                                                                    
                                                                    <!-- decide if there is a beam or tuplet enclosing all content of the prospective app -->
                                                                    <xsl:variable name="grouping.ancestor" as="node()?">
                                                                        <xsl:variable name="affected.elements" select="$core.layer//mei:*[@tstamp and 
                                                                            number(@tstamp) ge number($current.diffGroup/@tstamp.first) and
                                                                            number(@tstamp) le number($current.diffGroup/@tstamp.last)]" as="node()*"/>
                                                                        
                                                                        <xsl:if test="count(distinct-values($affected.elements/ancestor::mei:*[local-name() =  ('beam','tuplet')]/@xml:id)) = 1">
                                                                            <xsl:sequence select="$affected.elements/ancestor::mei:*[local-name() =  ('beam','tuplet')]"/>
                                                                        </xsl:if>
                                                                    </xsl:variable>
                                                                    <xsl:if test="exists($grouping.ancestor) and (min($grouping.ancestor//number(@tstamp)) lt $current.diffGroup/number(@tstamp.first) or max($grouping.ancestor//number(@tstamp)) gt $current.diffGroup/number(@tstamp.last))">
                                                                        <xsl:message select="'HICCUP: the ' || local-name($grouping.ancestor) || ' with xml:id ' || $grouping.ancestor/@xml:id || ' is probably nested incorrectly. Please check!'"></xsl:message>
                                                                        <hiccup reason="nesting" elem.name="{local-name($grouping.ancestor)}" elem.id="{$grouping.ancestor/@xml:id}">nesting is probably broken, element may have been encoded multiple times</hiccup>
                                                                    </xsl:if>
                                                                    
                                                                    <xsl:variable name="start.tstamp" as="xs:double">
                                                                        <xsl:choose>
                                                                            <xsl:when test="$current.pos = 1">
                                                                                <xsl:value-of select="$current.range/number(@tstamp.last)"/>
                                                                            </xsl:when>
                                                                            <xsl:otherwise>
                                                                                <xsl:value-of select="number($relevant.diffs[($current.pos - 1)]/@tstamp.last)"/>
                                                                            </xsl:otherwise>
                                                                        </xsl:choose>
                                                                    </xsl:variable>
                                                                    
                                                                    <xsl:apply-templates select="$core.layer/child::mei:*" mode="get.by.tstamps">
                                                                        <xsl:with-param name="after.tstamp" select="$start.tstamp" as="xs:double" tunnel="yes"/>
                                                                        <xsl:with-param name="before.tstamp" select="number($current.diffGroup/@tstamp.first)" as="xs:double" tunnel="yes"/>
                                                                        <xsl:with-param name="matching.source.id" select="$closest.source.id" as="xs:string" tunnel="yes"/>
                                                                        <xsl:with-param name="corresp" select="$layer.source.comparisons/descendant-or-self::source[@id = $closest.source.id]//sameas" as="node()*" tunnel="yes"/>
                                                                    </xsl:apply-templates>
                                                                    
                                                                    <app xmlns="http://www.music-encoding.org/ns/mei" xml:id="{'a'||uuid:randomUUID()}">
                                                                        <rdg xml:id="{$first.rdg.id}" source="#{string-join($all.sources.so.far,' #')}">
                                                                            <xsl:apply-templates select="$core.layer/child::mei:*" mode="get.by.tstamps">
                                                                                <xsl:with-param name="from.tstamp" select="number($current.diffGroup/@tstamp.first)" as="xs:double" tunnel="yes"/>
                                                                                <xsl:with-param name="to.tstamp" select="number($current.diffGroup/@tstamp.last)" as="xs:double" tunnel="yes"/>
                                                                            </xsl:apply-templates>
                                                                        </rdg>
                                                                        <rdg xml:id="{$second.rdg.id}" source="#{$source.id}">
                                                                            
                                                                            <xsl:apply-templates select="$source.layer/child::mei:*" mode="get.by.tstamps">
                                                                                <xsl:with-param name="from.tstamp" select="number($current.diffGroup/@tstamp.first)" as="xs:double" tunnel="yes"/>
                                                                                <xsl:with-param name="to.tstamp" select="number($current.diffGroup/@tstamp.last)" as="xs:double" tunnel="yes"/>
                                                                                <xsl:with-param name="corresp" select="$layer.source.comparisons/descendant-or-self::source[@id = $closest.source.id]//sameas" as="node()*" tunnel="yes"/>
                                                                                <xsl:with-param name="needs.fresh.id" select="true()" as="xs:boolean" tunnel="yes"/>
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
                                                                    <hiccup reason="control">added an app after the last existing app</hiccup>
                                                                    
                                                                    <!-- deal with material following the diff -->
                                                                    <xsl:choose>
                                                                        <!-- when there are subsequent diffs -->
                                                                        <xsl:when test="$current.pos lt count($relevant.diffs)">
                                                                            <xsl:apply-templates select="$core.layer/child::mei:*" mode="get.by.tstamps">
                                                                                <xsl:with-param name="after.tstamp" select="number($current.diffGroup/@tstamp.last)" as="xs:double" tunnel="yes"/>
                                                                                <xsl:with-param name="before.tstamp" select="number($relevant.diffs[($current.pos + 1)]/@tstamp.first)" as="xs:double" tunnel="yes"/>
                                                                                <xsl:with-param name="corresp" select="$layer.source.comparisons/descendant-or-self::source[@id = $closest.source.id]//sameas" as="node()*" tunnel="yes"/>
                                                                                <xsl:with-param name="matching.source.id" select="$closest.source.id" as="xs:string" tunnel="yes"/>
                                                                            </xsl:apply-templates>
                                                                        </xsl:when>
                                                                        <!-- when this is the last diff -->
                                                                        <xsl:otherwise>
                                                                            <xsl:apply-templates select="$core.layer/child::mei:*" mode="get.by.tstamps">
                                                                                <xsl:with-param name="after.tstamp" select="number($current.diffGroup/@tstamp.last)" as="xs:double" tunnel="yes"/>
                                                                                <xsl:with-param name="corresp" select="$layer.source.comparisons/descendant-or-self::source[@id = $closest.source.id]//sameas" as="node()*" tunnel="yes"/>
                                                                                <xsl:with-param name="matching.source.id" select="$closest.source.id" as="xs:string" tunnel="yes"/>
                                                                            </xsl:apply-templates>
                                                                        </xsl:otherwise>
                                                                    </xsl:choose>
                                                                    
                                                                </xsl:for-each>
                                                                
                                                            </xsl:otherwise>
                                                            
                                                        </xsl:choose>
                                                        
                                                        
                                                    </xsl:otherwise>
                                                </xsl:choose>
                                                
                                            </xsl:for-each>
                                                 
                                                    
                                            
                                        </xsl:otherwise>
                                    </xsl:choose>
                                    
                                    
                                </xsl:when>
                                
                                <!-- no apps in this layer, but there are still differences -->
                                <xsl:when test="$layer.comparison//diff">
                                    
                                    <xsl:message select="'   INFO: new differences found for layer ' || $core.layer/@n || ' in ' || $source.staff.raw/@xml:id || ', with existing apps in other layers (please check).'"/>
                                    
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
                
                <xsl:message select="'HICCUP: ' || $source.staff.raw/@xml:id || ' seems impossible to be resolved. Generated hiccup, please resolve manually.'"/>
                
                <xsl:copy>
                    <xsl:apply-templates select="@*" mode="#current"/>
                    <hiccup reason="layersUnclear">
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
                </xsl:copy>
            </xsl:otherwise>
        </xsl:choose>
        
        
    </xsl:template>
    
    <xsl:template match="mei:annot/@plist" mode="compare.phase1 #unnamed">
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
    
    <xsl:template match="mei:annot" mode="get.by.tstamps merge compare.phase1"/>
    <xsl:template match="mei:app" mode="compare.phase1">
        <xsl:next-match/>
        <xsl:if test="local-name(following-sibling::mei:*[1]) = 'annot'"/>
        <xsl:apply-templates select="following-sibling::mei:annot[1]" mode="#unnamed"/>
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
    
    <xsl:function name="local:groupDiffs" as="node()">
        <xsl:param name="diffs" as="node()*"/>
        <xsl:param name="core.range" as="node()"/>
        <xsl:param name="source.range" as="node()"/>
        
        <xsl:variable name="null" as="node()">
            <noRanges/>
        </xsl:variable>
        
        <xsl:sequence select="local:groupDiffs($diffs,$core.range,$source.range,$null)"/>
        
    </xsl:function>
    
    <!-- groups differences, into ranges of timestamps, where all notes in between vary. -->
    <xsl:function name="local:groupDiffs" as="node()">
        <xsl:param name="diffs" as="node()*"/>
        <xsl:param name="core.range" as="node()"/>
        <xsl:param name="source.range" as="node()"/>
        <xsl:param name="existing.ranges" required="no" as="node()*"/>
        
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
        
        <!-- get starting tstamps of existing apps -->
        <xsl:variable name="existing.app.start.positions" as="xs:integer*">
            <xsl:for-each select="(1 to count($base.tstamps))">
                <xsl:variable name="pos" select="position()" as="xs:integer"/>
                <xsl:if test="$base.tstamps[$pos] = $existing.ranges//@tstamp.first">
                    <xsl:value-of select="$pos"/>
                </xsl:if>
            </xsl:for-each>
        </xsl:variable>
        
        <!-- group differences into ranges of uninterupted difference -->
        <xsl:variable name="ranges" as="node()*">
            <xsl:copy-of select="local:getDifferingRanges($differing.positions,0,$existing.app.start.positions)"/>
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
        <xsl:param name="existing.app.start.positions" as="xs:integer*"/>
        <xsl:choose>
            <xsl:when test="some $pos in $differing.positions satisfies ($pos gt $position)">
                <xsl:variable name="start.pos" select="$differing.positions[. gt $position][1]" as="xs:integer"/>
                <xsl:variable name="end.pos" select="if(($start.pos + 1 = $differing.positions) and not($start.pos + 1 = $existing.app.start.positions)) then(local:getEndPos($differing.positions,$start.pos + 1)) else($start.pos)" as="xs:integer"/>
                
                <xsl:if test="($start.pos + 1 = $differing.positions) and ($start.pos + 1 = $existing.app.start.positions)">
                    <xsl:message select="'      INFO: rearranged ranges because of existing apps!'"/>
                </xsl:if>
                
                <range start="{$start.pos}" end="{$end.pos}"/>
                <xsl:copy-of select="local:getDifferingRanges($differing.positions,$end.pos + 1,$existing.app.start.positions)"/>
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
                            <xsl:variable name="core.diffs" select="$diffs/descendant-or-self::diff[@type = 'missing.pitch' and @tstamp = $tstamp and @missing.in = 'source']" as="node()*"/>
                            <xsl:variable name="source.dur" select="local:getDur($source.preComp//mei:*[@xml:id = $diff/@existing.id])"/>
                            <xsl:variable name="core.dur" select="if(count($core.diffs) gt 0) then(for $core.diff in $core.diffs return local:getDur($core/id($core.diff/@existing.id))) else('NaN')" as="xs:string*"/>
                            
                            <xsl:choose>
                                <xsl:when test="count($core.diffs) = 1 and count(distinct-values($core.dur)) = 1 and $source.dur = $core.dur[1]">
                                    <!--<xsl:message select="'merging diff at ' || $diff/@staff || ', tstamp ' || $diff/@tstamp"/>-->
                                    
                                    <xsl:variable name="source.elem" select="$source.preComp//mei:*[@xml:id = $diff/@existing.id]" as="node()"/>
                                    <xsl:variable name="core.elem" select="$core/id($core.diffs[1]/@existing.id)" as="node()"/>
                                    <xsl:variable name="better.diff" select="local:compareAttributes($source.elem,$core.elem)[local-name() = 'diff']" as="node()*"/>
                                    
                                    <xsl:choose>
                                        <!-- go with the different.pitch type now… -->
                                        <xsl:when test="$better.diff and 1 = 2">
                                            <xsl:copy-of select="$better.diff"/>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <diff type="different.pitch" staff="{$diff/@staff}" tstamp="{$diff/@tstamp}" source.pitch="{$diff/@pitch}" source.pnum="{$diff/@pnum}" core.pitch="{$core.diffs[1]/@pitch}" core.pnum="{$core.diffs[1]/@pnum}" source.elem.id="{$diff/@existing.id}" core.elem.id="{$core.diffs[1]/@existing.id}"/>
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
                            <xsl:variable name="source.diffs" select="$diffs/descendant-or-self::diff[@type = 'missing.pitch' and @tstamp = $tstamp and @missing.in = 'core']" as="node()*"/>
                            <xsl:variable name="core.dur" select="local:getDur($core/id($diff/@existing.id))"/>
                            <xsl:variable name="source.dur" select="if(count($source.diffs) gt 0) then(for $source.diff in $source.diffs return local:getDur($source.preComp//mei:*[@xml:id = $source.diff/@existing.id])) else('NaN')" as="xs:string*"/>
                            
                            <xsl:choose>
                                <xsl:when test="count($source.diffs) = 1 and count(distinct-values($source.dur)) = 1 and $source.dur[1] = $core.dur">
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
        <xsl:param name="needs.fresh.id" as="xs:boolean?" tunnel="yes"/>
        
        <xsl:variable name="this.id" select="."/>
        
        <xsl:choose>
            <!-- dealing with element from core -->
            <xsl:when test="$this.id = $corresp/descendant-or-self::sameas/@core and not($needs.fresh.id)">
                <xsl:copy-of select="."/>
                <xsl:attribute name="synch" select="$corresp/descendant-or-self::sameas[@core = $this.id]/@source"/>                
            </xsl:when>
            <xsl:when test="$this.id = $corresp/descendant-or-self::sameas/@core and $needs.fresh.id">
                <xsl:attribute name="xml:id" select="'z'||uuid:randomUUID()"/>
                <xsl:attribute name="synch" select="$corresp/descendant-or-self::sameas[@core = $this.id]/@source"/>
            </xsl:when>
            <!-- dealing with element from source -->
            <xsl:when test="$this.id = $corresp/descendant-or-self::sameas[number(@diffs) = 0]/@source">
                <xsl:attribute name="xml:id" select="$corresp/descendant-or-self::sameas[@source = $this.id]/@core"/>
                <xsl:attribute name="synch" select="$this.id"/>
            </xsl:when>
            <xsl:when test="$this.id = $corresp/descendant-or-self::sameas[number(@diffs) gt 0]/@source">
                <xsl:attribute name="xml:id" select="'p'||uuid:randomUUID()"/>
                <xsl:attribute name="synch" select="$this.id"/>
            </xsl:when>
            <xsl:when test="not(starts-with(ancestor::mei:staff/@xml:id,'core_'))">
                <xsl:attribute name="xml:id" select="'c'||uuid:randomUUID()"/>
                <xsl:attribute name="synch" select="$this.id"/>
            </xsl:when>
            <xsl:when test="$needs.fresh.id">
                <xsl:attribute name="xml:id" select="'p'||uuid:randomUUID()"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy-of select="."/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- /mode merge – END -->
    
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
    
    <!-- mode compare.phase2 – START -->
    
    <xsl:template match="mei:mdiv" mode="compare.phase2">
        
        <xsl:message select="' '"/>
        <xsl:message select="'INFO: Generating profiles for controlEvents. Second phase of comparison started.'"/>
        <xsl:message select="' '"/>
        
        <!-- generate profiles for all controlevents, both in core and source -->
        <xsl:variable name="controlEvents.source.profile" as="node()*">
            <xsl:for-each select="$source.preComp//mei:*[local-name() = ('slur','hairpin','dynam','dir') and not(ancestor::orig)]">
                <xsl:copy-of select="local:getCEProfile(.,$source.raw)"/>
            </xsl:for-each>    
        </xsl:variable>
        <xsl:variable name="controlEvents.core.profile" as="node()*">
            <xsl:for-each select="$core//mei:*[local-name() = ('slur','hairpin','dynam','dir')]">
                <xsl:copy-of select="local:getCEProfile(.,$core)"/>
            </xsl:for-each>    
        </xsl:variable>
        
        <!-- compare those controlevent profiles -->
        <xsl:variable name="ce.comparison" as="node()">
            <ce.comparison>
                <xsl:sequence select="local:compareControlEvents($controlEvents.source.profile,$controlEvents.core.profile)"/>
            </ce.comparison>
        </xsl:variable>
        
        <xsl:copy>
            <xsl:apply-templates select="node() | @*" mode="#current">
                <xsl:with-param name="diff.groups" select="$ce.comparison" tunnel="yes" as="node()"/>
                <xsl:with-param name="source.prep" select="$source.preComp//mei:score" tunnel="yes" as="node()"/>
            </xsl:apply-templates>
        </xsl:copy>
        
    </xsl:template>
    
    <xsl:function name="local:getCEProfile" as="node()?">
        <xsl:param name="controlEvent" as="node()"/>
        <xsl:param name="file" as="node()"/>
        
        <xsl:choose>
            <!-- profile slurs -->
            <xsl:when test="local-name($controlEvent) = 'slur'">
                <xsl:variable name="start.elem" select="$file//mei:*[@xml:id = $controlEvent/substring(@startid,2)]" as="node()*"/>
                <xsl:variable name="end.elem" select="$file//mei:*[@xml:id = $controlEvent/substring(@endid,2)]" as="node()*"/>
                <xsl:variable name="start.measure" select="$start.elem/ancestor::mei:measure/@n" as="xs:string?"/>
                
                <xsl:if test="count($start.elem) gt 1">
                    <xsl:message terminate="yes" select="'ERROR: The slur with id ' || $controlEvent/@xml:id || ' in measure ' || $start.measure || ' points out that two (or more) elements share an @xml:id, which is: ' || $controlEvent/substring(@startid,2)"/>
                </xsl:if>
                
                <xsl:if test="count($end.elem) gt 1">
                    <xsl:message terminate="yes" select="'ERROR: The slur with id ' || $controlEvent/@xml:id || ' in measure ' || $start.measure || ' points out that two (or more) elements share an @xml:id, which is: ' || $controlEvent/substring(@endid,2)"/>
                </xsl:if>
                
                <xsl:choose>
                    <!-- check if both start and end are available -->
                    <xsl:when test="exists($start.elem) and exists($end.elem)">
                        
                        <xsl:variable name="start.tstamp" select="if($start.elem/parent::mei:chord) then($start.elem/parent::mei:chord/@tstamp) else($start.elem/@tstamp)" as="xs:string?"/>
                        <xsl:variable name="end.tstamp" select="if($end.elem/parent::mei:chord) then($end.elem/parent::mei:chord/@tstamp) else($end.elem/@tstamp)" as="xs:string?"/>
                        
                        <xsl:if test="not($start.tstamp)">
                            <xsl:message terminate="yes" select="'ERROR: could not determine start.tstamp for ' || local-name($start.elem) || ' with ID ' || $start.elem/@xml:id || ' (measure ' || $start.elem/ancestor::mei:measure/@n || ')'"/>
                        </xsl:if>
                        <xsl:if test="not($end.tstamp)">
                            <xsl:message terminate="yes" select="'ERROR: could not determine end.tstamp for ' || local-name($end.elem) || ' with ID ' || $end.elem/@xml:id || ' (measure ' || $end.elem/ancestor::mei:measure/@n || ')'"/>
                        </xsl:if>
                        
                        <xsl:variable name="end.measure" select="$end.elem/ancestor::mei:measure/@n" as="xs:string"/>
                        
                        <!-- debug -->
                        <xsl:if test="$end.measure != string(number($end.measure))">
                            <xsl:message select="'$end.measure/@n for slur ' || $controlEvent/@xml:id || ' contains characters. Please check!'" terminate="yes"/>
                        </xsl:if>
                        
                        <!-- debug -->
                        <xsl:if test="$start.measure != string(number($start.measure))">
                            <xsl:message select="'$start.measure/@n for slur ' || $controlEvent/@xml:id || ' contains characters. Please check!'" terminate="yes"/>
                        </xsl:if>
                        
                        <slur xml:id="{$controlEvent/@xml:id}" staff.n="{$start.elem/ancestor::mei:staff/@n}" start.tstamp="{$start.tstamp}" end.tstamp="{$end.tstamp}" start.measure="{$start.measure}" end.measure="{$end.measure}"/>
                        
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:message terminate="yes" select="'ERROR: slur ' || $controlEvent/@xml:id || ' in measure ' || $controlEvent/ancestor::mei:measure/@n || ' has incorrect @startid and / or @endid. Please check! (processing stopped)'"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <!-- profile hairpins -->
            <xsl:when test="local-name($controlEvent) = 'hairpin'">
                
                <xsl:if test="not($controlEvent/@tstamp)">
                    <xsl:message select="$controlEvent"/>
                    <xsl:message terminate="yes" select="'please check!'"></xsl:message>
                </xsl:if>
                
                <xsl:variable name="start.tstamp" select="$controlEvent/@tstamp" as="xs:string"/>
                <xsl:variable name="end.tstamp" select="$controlEvent/substring-after(@tstamp2,'m+')" as="xs:string"/>
                <xsl:variable name="start.measure" select="$controlEvent/ancestor::mei:measure/@n" as="xs:string"/>
                <xsl:variable name="end.measure" as="xs:string">
                    <xsl:choose>
                        <xsl:when test="starts-with($controlEvent/@tstamp2,'0m+')">
                            <xsl:value-of select="$controlEvent/ancestor::mei:measure/@n"/>
                        </xsl:when>
                        <xsl:when test="contains($controlEvent/@tstamp2,'m+')">
                            <xsl:value-of select="$controlEvent/ancestor::mei:measure/following::mei:measure[position() = number(substring-before($controlEvent/@tstamp2,'m+'))]/@n"/>
                        </xsl:when>
                    </xsl:choose>
                </xsl:variable>
                
                <!-- debug -->
                <xsl:if test="$end.measure != string(number($end.measure))">
                    <xsl:message select="'$end.measure/@n for hairpin ' || $controlEvent/@xml:id || ' contains characters (' || $end.measure || '). Please check!'" terminate="yes"/>
                </xsl:if>
                
                <!-- debug -->
                <xsl:if test="$start.measure != string(number($start.measure))">
                    <xsl:message select="'$start.measure/@n for hairpin ' || $controlEvent/@xml:id || ' contains characters (' || $end.measure || '). Please check!'" terminate="yes"/>
                </xsl:if>
                
                <xsl:choose>
                    <!-- separate crescendo from diminuendo -->
                    <xsl:when test="$controlEvent/@form = 'cres'">                        
                        <hairpin.cres xml:id="{$controlEvent/@xml:id}" staff.n="{$controlEvent/@staff}" start.tstamp="{$start.tstamp}" end.tstamp="{$end.tstamp}" start.measure="{$start.measure}" end.measure="{$end.measure}"/>                        
                    </xsl:when>
                    <xsl:when test="$controlEvent/@form = 'dim'">                        
                        <hairpin.dim xml:id="{$controlEvent/@xml:id}" staff.n="{$controlEvent/@staff}" start.tstamp="{$start.tstamp}" end.tstamp="{$end.tstamp}" start.measure="{$start.measure}" end.measure="{$end.measure}"/>                        
                    </xsl:when>
                </xsl:choose>
            </xsl:when>
            <xsl:when test="local-name($controlEvent) = 'dynam'">
                
                <xsl:variable name="start.measure" select="$controlEvent/ancestor::mei:measure/@n" as="xs:string"/>
                <xsl:variable name="value" select="$controlEvent/replace(normalize-space(string-join(.//text(),'')),'[\.:]','')"/>
                <!-- normalize values -->
                <xsl:variable name="normalizedValue" as="xs:string">
                    <xsl:choose>         
                        <xsl:when test="$value = 'cres'">
                            <xsl:value-of select="'cresc'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'crs'">
                            <xsl:value-of select="'cresc'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'cresc'">
                            <xsl:value-of select="'cresc'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'crescendo'">
                            <xsl:value-of select="'cresc'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'crescendo assai'">
                            <xsl:value-of select="'crescAssai'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'cres assai'">
                            <xsl:value-of select="'crescAssai'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'crs assai'">
                            <xsl:value-of select="'crescAssai'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'crescen'">
                            <xsl:value-of select="'cresc'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'decresc'">
                            <xsl:value-of select="'decresc'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'decres'">
                            <xsl:value-of select="'decresc'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'decrescendo'">
                            <xsl:value-of select="'decresc'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'decrs'">
                            <xsl:value-of select="'decresc'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'crescendo poco a poco'">
                            <xsl:value-of select="'crescPocoAPoco'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'crescendo poco poco a poco'">
                            <xsl:value-of select="'crescPocoAPoco'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'crescendo a poco a poco'">
                            <xsl:value-of select="'crescPocoAPoco'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'poco a poco cresc'">
                            <xsl:value-of select="'crescPocoAPoco'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'poco a poco crescendo'">
                            <xsl:value-of select="'crescPocoAPoco'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'a poco a poco cres'">
                            <xsl:value-of select="'crescPocoAPoco'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'cres poco a poco'">
                            <xsl:value-of select="'crescPocoAPoco'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'crs poco a poco'">
                            <xsl:value-of select="'crescPocoAPoco'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'Cres poco a poco'">
                            <xsl:value-of select="'crescPocoAPoco'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'f'">
                            <xsl:value-of select="'f'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'ff'">
                            <xsl:value-of select="'ff'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'ffo'">
                            <xsl:value-of select="'ff'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'ffr'">
                            <xsl:value-of select="'ff'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'fo'">
                            <xsl:value-of select="'f'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'for'">
                            <xsl:value-of select="'f'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'fp'">
                            <xsl:value-of select="'fp'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'fpo'">
                            <xsl:value-of select="'fp'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'fr'">
                            <xsl:value-of select="'f'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'mf'">
                            <xsl:value-of select="'mf'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'mfo'">
                            <xsl:value-of select="'mf'"/>
                        </xsl:when>                        
                        <xsl:when test="$value = 'mfr'">
                            <xsl:value-of select="'mf'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'mrf'">
                            <xsl:value-of select="'mf'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'mzfr'">
                            <xsl:value-of select="'mf'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'mzf'">
                            <xsl:value-of select="'mf'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'p'">
                            <xsl:value-of select="'p'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'po'">
                            <xsl:value-of select="'p'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'pp'">
                            <xsl:value-of select="'pp'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'ppo'">
                            <xsl:value-of select="'pp'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'ppp'">
                            <xsl:value-of select="'ppp'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'sf'">
                            <xsl:value-of select="'sf'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'sfr'">
                            <xsl:value-of select="'sf'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'sfo'">
                            <xsl:value-of select="'sf'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'sfz'">
                            <xsl:value-of select="'fz'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'fz'">
                            <xsl:value-of select="'fz'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'fzo'">
                            <xsl:value-of select="'fz'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'rf'">
                            <xsl:value-of select="'rf'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'rfz'">
                            <xsl:value-of select="'rf'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'rfo'">
                            <xsl:value-of select="'rf'"/>
                        </xsl:when>
                        <!-- unknown / faulty encodings:  -->
                        <xsl:when test="$value = 'cres e stringendo'">
                            <xsl:message terminate="yes" select="'Since element ' || $controlEvent/@xml:id || ' contains /stringendo/, it should be an mei:dir, not an mei:dynam. Please correct!'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'cresc e stringendo'">
                            <xsl:message terminate="yes" select="'Since element ' || $controlEvent/@xml:id || ' contains /stringendo/, it should be an mei:dir, not an mei:dynam. Please correct!'"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:message terminate="yes" select="'a value of ' || $value || ' for dynam ' || $controlEvent/@xml:id || ' is currently not supported by merge2Core.xsl. Please check!'"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                
                <dynam xml:id="{$controlEvent/@xml:id}" staff.n="{$controlEvent/@staff}" start.measure="{$start.measure}" start.tstamp="{$controlEvent/@tstamp}" value="{$normalizedValue}"/>
                
            </xsl:when>
            <xsl:when test="local-name($controlEvent) = 'dir'">
                
                <xsl:variable name="quot" as="xs:string">'</xsl:variable>
                <xsl:variable name="start.measure" select="$controlEvent/ancestor::mei:measure/@n" as="xs:string"/>
                <xsl:variable name="value" select="replace($controlEvent/replace(lower-case(normalize-space(string-join(.//text(),''))),'[\.:]',''),$quot,'')"/>
                
                <xsl:variable name="normalizedValue" as="xs:string">
                    <xsl:choose>
                        <xsl:when test="$value = ' '">
                            <xsl:message terminate="yes" select="'dir ' || $controlEvent/@xml:id || ' seems to have no text content. Please check!'"/>
                        </xsl:when>
                        <xsl:when test="$value = '1mo solo'">
                            <xsl:value-of select="'primoSolo'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'imo solo'">
                            <xsl:value-of select="'primoSolo'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'pmo solo'">
                            <xsl:value-of select="'primoSolo'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'solo io'">
                            <xsl:value-of select="'primoSolo'"/>
                        </xsl:when>
                        <xsl:when test="$value = '2do'">
                            <xsl:value-of select="'secondo'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'a 2do'">
                            <xsl:value-of select="'secondo'"/>
                        </xsl:when>
                        <xsl:when test="$value = '2do solo'">
                            <xsl:value-of select="'secondoSolo'"/>
                        </xsl:when>
                        <xsl:when test="$value = '2o solo'">
                            <xsl:value-of select="'secondoSolo'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'iid solo'">
                            <xsl:value-of select="'secondoSolo'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'a 2'">
                            <xsl:value-of select="'aDue'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'a due'">
                            <xsl:value-of select="'aDue'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'à 2'">
                            <xsl:value-of select="'aDue'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'à piacere, mà con tutta la forza'">
                            <xsl:value-of select="'aPiacereMaConTuttaLaForza'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'a piacere mi con tutta la forza'">
                            <xsl:value-of select="'aPiacereMaConTuttaLaForza'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'a piacere, mà con tutto la forza'">
                            <xsl:value-of select="'aPiacereMaConTuttaLaForza'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'a piacere ma con tutta la forza'">
                            <xsl:value-of select="'aPiacereMaConTuttaLaForza'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'a piacere mà con tutta la forza'">
                            <xsl:value-of select="'aPiacereMaConTuttaLaForza'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'a piacere, ma tutta la forza'">
                            <xsl:value-of select="'aPiacereMaConTuttaLaForza'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'a piacere, ma con tutto la forza'">
                            <xsl:value-of select="'aPiacereMaConTuttaLaForza'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'a piacere pia con tutta la forza'">
                            <xsl:value-of select="'aPiacereMaConTuttaLaForza'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'a tempo'">
                            <xsl:value-of select="'aTempo'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'a tempor'">
                            <xsl:value-of select="'aTempo'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'a tem'">
                            <xsl:value-of select="'aTempo'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'accelerando'">
                            <xsl:value-of select="'accel'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'accellerando'">
                            <xsl:value-of select="'accel'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'adagio'">
                            <xsl:value-of select="'adagio'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'agitato'">
                            <xsl:value-of select="'agitato'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'allegretto grazioso'">
                            <xsl:value-of select="'allegrettoGrazioso'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'allegretto grizioso'">
                            <xsl:value-of select="'allegrettoGrazioso'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'allegro'">
                            <xsl:value-of select="'allegro'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'allo'">
                            <xsl:value-of select="'allegro'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'allegro vivace'">
                            <xsl:value-of select="'allegroVivace'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'allo vivace'">
                            <xsl:value-of select="'allegroVivace'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'andante'">
                            <xsl:value-of select="'andante'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'andte'">
                            <xsl:value-of select="'andante'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'andantino'">
                            <xsl:value-of select="'andantino'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'arco'">
                            <xsl:value-of select="'arco'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'assai dol'">
                            <xsl:value-of select="'dolceAssai'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'assai dolce'">
                            <xsl:value-of select="'dolceAssai'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'colla parte'">
                            <xsl:value-of select="'collaParte'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'colla parte,'">
                            <xsl:value-of select="'collaParte'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'col parte'">
                            <xsl:value-of select="'collaParte'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'coll part'">
                            <xsl:value-of select="'collaParte'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'col part'">
                            <xsl:value-of select="'collaParte'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'con forza'">
                            <xsl:value-of select="'conForza'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'con fuoco'">
                            <xsl:value-of select="'conFuoco'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'con sordini'">
                            <xsl:value-of select="'conSordini'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'sordini'">
                            <xsl:value-of select="'conSordini'"/>
                        </xsl:when>
                        
                        <xsl:when test="$value = 'cres e stringendo'">
                            <xsl:value-of select="'cresStringendo'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'cresc e string'">
                            <xsl:value-of select="'cresStringendo'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'cresc e stringendo'">
                            <xsl:value-of select="'cresStringendo'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'crescendo e stringendo'">
                            <xsl:value-of select="'cresStringendo'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'stringendo cresc'">
                            <xsl:value-of select="'cresStringendo'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'stringendo e cresc'">
                            <xsl:value-of select="'cresStringendo'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'stringendo e crescendo'">
                            <xsl:value-of select="'cresStringendo'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'stringendo e cres'">
                            <xsl:value-of select="'cresStringendo'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'cres e string'">
                            <xsl:value-of select="'cresStringendo'"/>
                        </xsl:when>           
                        <xsl:when test="$value = 'stringendo'">
                            <xsl:value-of select="'stringendo'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'divisi'">
                            <xsl:value-of select="'divisi'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'dol'">
                            <xsl:value-of select="'dolce'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'dolce'">
                            <xsl:value-of select="'dolce'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'dol assai'">
                            <xsl:value-of select="'dolceAssai'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'dolce assai'">
                            <xsl:value-of select="'dolceAssai'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'in e'">
                            <xsl:value-of select="'inE'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'legeremente'">
                            <xsl:value-of select="'leggeremente'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'leggeremente'">
                            <xsl:value-of select="'leggeremente'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'leggeremento'">
                            <xsl:value-of select="'leggeremente'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'leggermento'">
                            <xsl:value-of select="'leggeremente'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'leggermente'">
                            <xsl:value-of select="'leggeremente'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'molto dol'">
                            <xsl:value-of select="'moltoDolce'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'molto dolce'">
                            <xsl:value-of select="'moltoDolce'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'morendo'">
                            <xsl:value-of select="'morendo'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'pizz'">
                            <xsl:value-of select="'pizz'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'piz'">
                            <xsl:value-of select="'pizz'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'pizzo'">
                            <xsl:value-of select="'pizz'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'punto darco'">
                            <xsl:value-of select="'puntoDarco'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'punta darco'">
                            <xsl:value-of select="'puntoDarco'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'puto darco'">
                            <xsl:value-of select="'puntoDarco'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'recit'">
                            <xsl:value-of select="'recit'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'rect'">
                            <xsl:value-of select="'recit'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'rec'">
                            <xsl:value-of select="'recit'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'ritardando'">
                            <xsl:value-of select="'ritardando'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'rit'">
                            <xsl:value-of select="'ritardando'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'ritard'">
                            <xsl:value-of select="'ritardando'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'scherz'">
                            <xsl:value-of select="'scherzando'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'scherzando'">
                            <xsl:value-of select="'scherzando'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'senza sord'">
                            <xsl:value-of select="'senzaSordini'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'senza sordini'">
                            <xsl:value-of select="'senzaSordini'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'soli'">
                            <xsl:value-of select="'soli'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'solo'">
                            <xsl:value-of select="'solo'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'stacato'">
                            <xsl:value-of select="'staccato'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'stacc'">
                            <xsl:value-of select="'staccato'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'staccato'">
                            <xsl:value-of select="'staccato'"/>
                        </xsl:when>                    
                        <xsl:when test="$value = 'stac'">
                            <xsl:value-of select="'staccato'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'tempo'">
                            <xsl:value-of select="'tempo'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'tem'">
                            <xsl:value-of select="'tempo'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'ten'">
                            <xsl:value-of select="'tenuto'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'unis'">
                            <xsl:value-of select="'unisono'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'vivace'">
                            <xsl:value-of select="'vivace'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'vivace con fuoco'">
                            <xsl:value-of select="'vivaceConFuoco'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'vivace von fuoco'">
                            <xsl:value-of select="'vivaceConFuoco'"/>
                        </xsl:when>
                        <!-- faulty / unknown encodings: -->
                        <xsl:when test="$value = 'divisi con sordini'">
                            <xsl:message terminate="yes" select="'/divisi con sordini/ seems like two different directives, dont you think? Please split up mei:dir@xml:id=' || $controlEvent/@xml:id"/>
                        </xsl:when>
                        <xsl:when test="$value = 'divisi sordini'">
                            <xsl:message terminate="yes" select="'/divisi sordini/ seems like two different directives, dont you think? Please split up mei:dir@xml:id=' || $controlEvent/@xml:id"/>
                        </xsl:when>
                        <xsl:when test="$value = 'cres'">
                            <xsl:message terminate="yes" select="'Element ' || $controlEvent/@xml:id || ' seems like an mei:dynam, not mei:dir (' || $value || '). Please correct!'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'cresc'">
                            <xsl:message terminate="yes" select="'Element ' || $controlEvent/@xml:id || ' seems like an mei:dynam, not mei:dir (' || $value || '). Please correct!'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'crescendo'">
                            <xsl:message terminate="yes" select="'Element ' || $controlEvent/@xml:id || ' seems like an mei:dynam, not mei:dir (' || $value || '). Please correct!'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'crescendo assai'">
                            <xsl:message terminate="yes" select="'Element ' || $controlEvent/@xml:id || ' seems like an mei:dynam, not mei:dir (' || $value || '). Please correct!'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'crescen'">
                            <xsl:message terminate="yes" select="'Element ' || $controlEvent/@xml:id || ' seems like an mei:dynam, not mei:dir (' || $value || '). Please correct!'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'decresc'">
                            <xsl:message terminate="yes" select="'Element ' || $controlEvent/@xml:id || ' seems like an mei:dynam, not mei:dir (' || $value || '). Please correct!'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'decrescendo'">
                            <xsl:message terminate="yes" select="'Element ' || $controlEvent/@xml:id || ' seems like an mei:dynam, not mei:dir (' || $value || '). Please correct!'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'crescendo poco a poco'">
                            <xsl:message terminate="yes" select="'Element ' || $controlEvent/@xml:id || ' seems like an mei:dynam, not mei:dir (' || $value || '). Please correct!'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'crescendo poco poco a poco'">
                            <xsl:message terminate="yes" select="'Element ' || $controlEvent/@xml:id || ' seems like an mei:dynam, not mei:dir (' || $value || '). Please correct!'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'crescendo a poco a poco'">
                            <xsl:message terminate="yes" select="'Element ' || $controlEvent/@xml:id || ' seems like an mei:dynam, not mei:dir (' || $value || '). Please correct!'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'poco a poco cresc'">
                            <xsl:message terminate="yes" select="'Element ' || $controlEvent/@xml:id || ' seems like an mei:dynam, not mei:dir (' || $value || '). Please correct!'"/>
                        </xsl:when>
                        <xsl:when test="$value = 'poco a poco crescendo'">
                            <xsl:message terminate="yes" select="'Element ' || $controlEvent/@xml:id || ' seems like an mei:dynam, not mei:dir (' || $value || '). Please correct!'"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:choose>
                                <xsl:when test="$controlEvent/@type = 'stage'">
                                    <xsl:message terminate="no" select="'Since dir ' || $controlEvent/@xml:id || ' is of type=stage, its value (' || $value || ') is not considered for comparison. Please check results!'"/>
                                    <xsl:value-of select="'stage'"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:message terminate="yes" select="'a value of ' || $value || ' for dir ' || $controlEvent/@xml:id || ' is currently not supported by merge2Core.xsl. Please check!'"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                
                <dir xml:id="{$controlEvent/@xml:id}" staff.n="{$controlEvent/@staff}" start.measure="{$start.measure}" start.tstamp="{$controlEvent/@tstamp}" value="{$normalizedValue}"/>
                
            </xsl:when>
        </xsl:choose>
        
    </xsl:function>
    
    <!-- function to compare controlEvents -->
    <xsl:function name="local:compareControlEvents" as="node()*">
        <xsl:param name="controlEvents.source.profile" as="node()*"/>
        <xsl:param name="controlEvents.core.profile" as="node()*"/>
        
        <!-- put all found matches / differences in variable first, in order to allow "a look from the 
            core perspective" -->
        <xsl:variable name="from.source" as="node()*">
            
            <!-- checking slurs -->
            <xsl:for-each-group select="$controlEvents.source.profile[local-name() = 'slur']" group-by="@staff.n">
                <xsl:variable name="ce.perStaff" select="current-group()" as="node()*"/>
                <xsl:variable name="current.staff" select="current-grouping-key()" as="xs:string"/>
                
                <xsl:for-each-group select="$ce.perStaff" group-by="@start.measure">
                    <xsl:variable name="ce.sharing.start.measure" select="current-group()" as="node()*"/>
                    <xsl:variable name="current.start.measure" select="current-grouping-key()" as="xs:string"/>
                    
                    <xsl:for-each-group select="$ce.sharing.start.measure" group-by="@start.tstamp">
                        <xsl:variable name="ce.sharing.start.tstamp" select="current-group()" as="node()*"/>
                        <xsl:variable name="current.start.tstamp" select="current-grouping-key()" as="xs:string"/>
                        
                        <xsl:for-each-group select="$ce.sharing.start.tstamp" group-by="@end.measure">
                            <xsl:variable name="ce.sharing.end.measure" select="current-group()" as="node()*"/>
                            <xsl:variable name="current.end.measure" select="current-grouping-key()" as="xs:string"/>
                            
                            <xsl:for-each-group select="$ce.sharing.end.measure" group-by="@end.tstamp">
                                <xsl:variable name="ce.sharing.end.tstamp" select="current-group()" as="node()*"/>
                                <xsl:variable name="current.end.tstamp" select="current-grouping-key()" as="xs:string"/>
                                
                                <xsl:variable name="match" select="$controlEvents.core.profile[local-name() = 'slur' 
                                    and @start.measure = $current.start.measure
                                    and @start.tstamp = $current.start.tstamp
                                    and @end.tstamp = $current.end.tstamp
                                    and @end.measure = $current.end.measure
                                    and @staff.n = $current.staff]" as="node()*"/>
                                
                                <xsl:variable name="match.count" select="count($match)" as="xs:integer"/>
                                
                                <xsl:choose>
                                    <!-- core has the same number of slurs as source -->
                                    <xsl:when test="$match.count = count($ce.sharing.end.tstamp)">
                                        <xsl:for-each select="$ce.sharing.end.tstamp">
                                            <xsl:variable name="pos" select="position()" as="xs:integer"/>
                                            <ce.match type="ce" elem.name="slur" source.id="{@xml:id}" core.id="{$match[$pos]/@xml:id}"/>
                                            <xsl:if test="not(@xml:id) or @xml:id = ''">
                                                <xsl:message select="."/>
                                                <xsl:message select="'PROBLEM: I have no idea why this thingy has no @xml:id – please debug!'" terminate="yes"/>
                                            </xsl:if>
                                        </xsl:for-each>
                                    </xsl:when>
                                    
                                    <!-- core has no corresponding slur -->
                                    <xsl:when test="$match.count = 0">
                                        <xsl:for-each select="$ce.sharing.end.tstamp">
                                            <ce.diff type="missing.ce" elem.name="slur" measure="{$current.start.measure}" staff="{$current.staff}" missing.in="core" existing.id="{@xml:id}"/>
                                        </xsl:for-each>
                                    </xsl:when>
                                    
                                    <!-- core has more corresponding slurs than available in source -->
                                    <xsl:when test="$match.count gt count($ce.sharing.end.tstamp)">
                                        <!-- look up all source slurs with same profile -->
                                        
                                        <!-- set up matches between slurs -->
                                        <xsl:for-each select="(1 to count($ce.sharing.end.tstamp))">
                                            <xsl:variable name="pos" select="." as="xs:integer"/>
                                            <ce.match type="ce" elem.name="slur" source.id="{$ce.sharing.end.tstamp[$pos]/@xml:id}" core.id="{$match[$pos]/@xml:id}"/>
                                            <xsl:if test="not($ce.sharing.end.tstamp[$pos]/@xml:id) or $ce.sharing.end.tstamp[$pos]/@xml:id = ''">
                                                <xsl:message select="$ce.sharing.end.tstamp[$pos]"/>
                                                <xsl:message select="'PROBLEM: I have no idea why this thingy has no @xml:id – please debug!'" terminate="yes"/>
                                            </xsl:if>
                                        </xsl:for-each>
                                        <!-- create diffs for missing slurs in source -->
                                        <xsl:for-each select="((count($ce.sharing.end.tstamp) + 1) to $match.count)">
                                            <xsl:variable name="pos" select="." as="xs:integer"/>
                                            <ce.diff type="missing.ce" elem.name="slur" measure="{$current.start.measure}" staff="{$current.staff}" missing.in="source" existing.id="{$match[$pos]/@xml:id}"/>
                                        </xsl:for-each>
                                        
                                    </xsl:when>
                                    
                                    <!-- core has less corresponding slurs than available in source -->
                                    <xsl:when test="$match.count lt count($ce.sharing.end.tstamp)">
                                        <!-- look up all source slurs with same profile -->
                                        
                                        <!-- set up matches between slurs -->
                                        <xsl:for-each select="(1 to $match.count)">
                                            <xsl:variable name="pos" select="." as="xs:integer"/>
                                            <ce.match type="ce" elem.name="slur" source.id="{$ce.sharing.end.tstamp[$pos]/@xml:id}" core.id="{$match[$pos]/@xml:id}"/>
                                            <xsl:if test="not($ce.sharing.end.tstamp[$pos]/@xml:id) or $ce.sharing.end.tstamp[$pos]/@xml:id = ''">
                                                <xsl:message select="$ce.sharing.end.tstamp[$pos]"/>
                                                <xsl:message select="'PROBLEM: I have no idea why this thingy has no @xml:id – please debug!'" terminate="yes"/>
                                            </xsl:if>
                                        </xsl:for-each>
                                        <!-- create diffs for missing slurs in core -->
                                        <xsl:for-each select="(($match.count + 1) to count($ce.sharing.end.tstamp))">
                                            <xsl:variable name="pos" select="." as="xs:integer"/>
                                            <ce.diff type="missing.ce" elem.name="slur" measure="{$current.start.measure}" staff="{$current.staff}" missing.in="core" existing.id="{$ce.sharing.end.tstamp[$pos]/@xml:id}"/>
                                        </xsl:for-each>
                                        
                                    </xsl:when>
                                    
                                </xsl:choose>
                                <!-- not sharing end.tstamp anymore -->
                            </xsl:for-each-group>
                            <!-- not sharing end.measure anymore -->
                        </xsl:for-each-group>
                        <!-- not sharing start.tstamp anymore -->    
                    </xsl:for-each-group>
                    <!-- not sharing staff anymore --> 
                </xsl:for-each-group>
                
            <!-- not sharing measure anymore --> 
            </xsl:for-each-group>
        
            <!-- checking crescendo hairpins -->
            <xsl:for-each-group select="$controlEvents.source.profile[local-name() = 'hairpin.cres']" group-by="@staff.n">
                <xsl:variable name="ce.perStaff" select="current-group()" as="node()*"/>
                <xsl:variable name="current.staff" select="current-grouping-key()" as="xs:string"/>
                
                <xsl:for-each-group select="$ce.perStaff" group-by="@start.measure">
                    <xsl:variable name="ce.sharing.start.measure" select="current-group()" as="node()*"/>
                    <xsl:variable name="current.start.measure" select="current-grouping-key()" as="xs:string"/>
                
                    <xsl:for-each-group select="$ce.sharing.start.measure" group-by="@start.tstamp">
                        <xsl:variable name="ce.sharing.start.tstamp" select="current-group()" as="node()*"/>
                        <xsl:variable name="current.start.tstamp" select="current-grouping-key()" as="xs:string"/>
                        
                        <xsl:for-each-group select="$ce.sharing.start.tstamp" group-by="@end.measure">
                            <xsl:variable name="ce.sharing.end.measure" select="current-group()" as="node()*"/>
                            <xsl:variable name="current.end.measure" select="current-grouping-key()" as="xs:string"/>
                            
                            <xsl:for-each-group select="$ce.sharing.end.measure" group-by="@end.tstamp">
                                <xsl:variable name="ce.sharing.end.tstamp" select="current-group()" as="node()*"/>
                                <xsl:variable name="current.end.tstamp" select="current-grouping-key()" as="xs:string"/>
                                
                                <xsl:variable name="match" select="$controlEvents.core.profile[local-name() = 'hairpin.cres' 
                                    and @start.measure = $current.start.measure
                                    and @start.tstamp = $current.start.tstamp
                                    and @end.tstamp = $current.end.tstamp
                                    and @end.measure = $current.end.measure
                                    and @staff.n = $current.staff]" as="node()*"/>
                                
                                <xsl:variable name="match.count" select="count($match)" as="xs:integer"/>
                                
                                <xsl:choose>
                                    <!-- core has the same number of slurs as source -->
                                    <xsl:when test="$match.count = count($ce.sharing.end.tstamp)">
                                        <xsl:for-each select="$ce.sharing.end.tstamp">
                                            <xsl:variable name="pos" select="position()" as="xs:integer"/>
                                            <ce.match type="ce" elem.name="hairpin" source.id="{@xml:id}" core.id="{$match[$pos]/@xml:id}"/>
                                            <xsl:if test="not(@xml:id) or @xml:id = ''">
                                                <xsl:message select="."/>
                                                <xsl:message select="'PROBLEM: I have no clue…'" terminate="yes"/>
                                            </xsl:if>
                                        </xsl:for-each>
                                    </xsl:when>
                                    
                                    <!-- core has no corresponding slur -->
                                    <xsl:when test="$match.count = 0">
                                        <xsl:for-each select="$ce.sharing.end.tstamp">
                                            <ce.diff type="missing.ce" elem.name="hairpin" start.measure="{$current.start.measure}" staff="{$current.staff}" missing.in="core" existing.id="{@xml:id}"/>
                                        </xsl:for-each>
                                    </xsl:when>
                                    
                                    <!-- core has more corresponding slurs than available in source -->
                                    <xsl:when test="$match.count gt count($ce.sharing.end.tstamp)">
                                        <!-- look up all source slurs with same profile -->
                                        
                                        <!-- set up matches between slurs -->
                                        <xsl:for-each select="(1 to count($ce.sharing.end.tstamp))">
                                            <xsl:variable name="pos" select="." as="xs:integer"/>
                                            <ce.match type="ce" elem.name="hairpin" source.id="{$ce.sharing.end.tstamp[$pos]/@xml:id}" core.id="{$match[$pos]/@xml:id}"/>
                                            <xsl:if test="not($ce.sharing.end.tstamp[$pos]/@xml:id) or $ce.sharing.end.tstamp[$pos]/@xml:id = ''">
                                                <xsl:message select="$ce.sharing.end.tstamp[$pos]"/>
                                                <xsl:message select="'PROBLEM: I have no clue…'" terminate="yes"/>
                                            </xsl:if>
                                        </xsl:for-each>
                                        <!-- create diffs for missing slurs in source -->
                                        <xsl:for-each select="((count($ce.sharing.end.tstamp) + 1) to $match.count)">
                                            <xsl:variable name="pos" select="." as="xs:integer"/>
                                            <ce.diff type="missing.ce" elem.name="hairpin" start.measure="{$current.start.measure}" staff="{$current.staff}" missing.in="source" existing.id="{$match[$pos]/@xml:id}"/>
                                        </xsl:for-each>
                                        
                                    </xsl:when>
                                    
                                    <!-- core has less corresponding slurs than available in source -->
                                    <xsl:when test="$match.count lt count($ce.sharing.end.tstamp)">
                                        <!-- look up all source slurs with same profile -->
                                        
                                        <!-- set up matches between slurs -->
                                        <xsl:for-each select="(1 to $match.count)">
                                            <xsl:variable name="pos" select="." as="xs:integer"/>
                                            <ce.match type="ce" elem.name="hairpin" source.id="{$ce.sharing.end.tstamp[$pos]/@xml:id}" core.id="{$match[$pos]/@xml:id}"/>
                                            <xsl:if test="not($ce.sharing.end.tstamp[$pos]/@xml:id) or $ce.sharing.end.tstamp[$pos]/@xml:id = ''">
                                                <xsl:message select="$ce.sharing.end.tstamp[$pos]"/>
                                                <xsl:message select="'PROBLEM: I have no clue…'" terminate="yes"/>
                                            </xsl:if>
                                        </xsl:for-each>
                                        <!-- create diffs for missing slurs in core -->
                                        <xsl:for-each select="(($match.count + 1) to count($ce.sharing.end.tstamp))">
                                            <xsl:variable name="pos" select="." as="xs:integer"/>
                                            <ce.diff type="missing.ce" elem.name="hairpin" start.measure="{$current.start.measure}" staff="{$current.staff}" missing.in="core" existing.id="{$ce.sharing.end.tstamp[$pos]/@xml:id}"/>
                                        </xsl:for-each>
                                        
                                    </xsl:when>
                                    
                                </xsl:choose>
                                <!-- not sharing end.tstamp anymore -->
                            </xsl:for-each-group>
                            <!-- not sharing end.measure anymore -->
                        </xsl:for-each-group>
                        <!-- not sharing start.tstamp anymore -->    
                    </xsl:for-each-group>
                
                    <!-- not sharing measure anymore --> 
                </xsl:for-each-group>
                
                <!-- not sharing staff anymore --> 
            </xsl:for-each-group>
        
            <!-- checking diminuendo hairpins -->
            <xsl:for-each-group select="$controlEvents.source.profile[local-name() = 'hairpin.dim']" group-by="@staff.n">
                <xsl:variable name="ce.perStaff" select="current-group()" as="node()*"/>
                <xsl:variable name="current.staff" select="current-grouping-key()" as="xs:string"/>
                
                <xsl:for-each-group select="$ce.perStaff" group-by="@start.measure">
                    <xsl:variable name="ce.sharing.start.measure" select="current-group()" as="node()*"/>
                    <xsl:variable name="current.start.measure" select="current-grouping-key()" as="xs:string"/>
                
                    <xsl:for-each-group select="$ce.sharing.start.measure" group-by="@start.tstamp">
                        <xsl:variable name="ce.sharing.start.tstamp" select="current-group()" as="node()*"/>
                        <xsl:variable name="current.start.tstamp" select="current-grouping-key()" as="xs:string"/>
                        
                        <xsl:for-each-group select="$ce.sharing.start.tstamp" group-by="@end.measure">
                            <xsl:variable name="ce.sharing.end.measure" select="current-group()" as="node()*"/>
                            <xsl:variable name="current.end.measure" select="current-grouping-key()" as="xs:string"/>
                            
                            <xsl:for-each-group select="$ce.sharing.end.measure" group-by="@end.tstamp">
                                <xsl:variable name="ce.sharing.end.tstamp" select="current-group()" as="node()*"/>
                                <xsl:variable name="current.end.tstamp" select="current-grouping-key()" as="xs:string"/>
                                
                                <xsl:variable name="match" select="$controlEvents.core.profile[local-name() = 'hairpin.dim' 
                                    and @start.measure = $current.start.measure
                                    and @start.tstamp = $current.start.tstamp
                                    and @end.tstamp = $current.end.tstamp
                                    and @end.measure = $current.end.measure
                                    and @staff.n = $current.staff]" as="node()*"/>
                                
                                <xsl:variable name="match.count" select="count($match)" as="xs:integer"/>
                                
                                <xsl:choose>
                                    <!-- core has the same number of slurs as source -->
                                    <xsl:when test="$match.count = count($ce.sharing.end.tstamp)">
                                        <xsl:for-each select="$ce.sharing.end.tstamp">
                                            <xsl:variable name="pos" select="position()" as="xs:integer"/>
                                            <ce.match type="ce" elem.name="hairpin" source.id="{@xml:id}" core.id="{$match[$pos]/@xml:id}"/>
                                            <xsl:if test="not(@xml:id) or @xml:id = ''">
                                                <xsl:message select="."/>
                                                <xsl:message select="'PROBLEM: I have no clue…'" terminate="no"/>
                                            </xsl:if>
                                        </xsl:for-each>
                                    </xsl:when>
                                    
                                    <!-- core has no corresponding slur -->
                                    <xsl:when test="$match.count = 0">
                                        <xsl:for-each select="$ce.sharing.end.tstamp">
                                            <ce.diff type="missing.ce" elem.name="hairpin" start.measure="{$current.start.measure}" staff="{$current.staff}" missing.in="core" existing.id="{@xml:id}"/>
                                        </xsl:for-each>
                                    </xsl:when>
                                    
                                    <!-- core has more corresponding slurs than available in source -->
                                    <xsl:when test="$match.count gt count($ce.sharing.end.tstamp)">
                                        <!-- look up all source slurs with same profile -->
                                        
                                        <!-- set up matches between slurs -->
                                        <xsl:for-each select="(1 to count($ce.sharing.end.tstamp))">
                                            <xsl:variable name="pos" select="." as="xs:integer"/>
                                            <ce.match type="ce" elem.name="hairpin" source.id="{$ce.sharing.end.tstamp[$pos]/@xml:id}" core.id="{$match[$pos]/@xml:id}"/>
                                            <xsl:if test="not($ce.sharing.end.tstamp[$pos]/@xml:id) or $ce.sharing.end.tstamp[$pos]/@xml:id = ''">
                                                <xsl:message select="$ce.sharing.end.tstamp[$pos]"/>
                                                <xsl:message select="'PROBLEM: I have no clue…'" terminate="yes"/>
                                            </xsl:if>
                                        </xsl:for-each>
                                        <!-- create diffs for missing slurs in source -->
                                        <xsl:for-each select="((count($ce.sharing.end.tstamp) + 1) to $match.count)">
                                            <xsl:variable name="pos" select="." as="xs:integer"/>
                                            <ce.diff type="missing.ce" elem.name="hairpin" start.measure="{$current.start.measure}" staff="{$current.staff}" missing.in="source" existing.id="{$match[$pos]/@xml:id}"/>
                                        </xsl:for-each>
                                        
                                    </xsl:when>
                                    
                                    <!-- core has less corresponding slurs than available in source -->
                                    <xsl:when test="$match.count lt count($ce.sharing.end.tstamp)">
                                        <!-- look up all source slurs with same profile -->
                                        
                                        <!-- set up matches between slurs -->
                                        <xsl:for-each select="(1 to $match.count)">
                                            <xsl:variable name="pos" select="." as="xs:integer"/>
                                            <ce.match type="ce" elem.name="hairpin" source.id="{$ce.sharing.end.tstamp[$pos]/@xml:id}" core.id="{$match[$pos]/@xml:id}"/>
                                            <xsl:if test="not($ce.sharing.end.tstamp[$pos]/@xml:id) or $ce.sharing.end.tstamp[$pos]/@xml:id = ''">
                                                <xsl:message select="$ce.sharing.end.tstamp[$pos]"/>
                                                <xsl:message select="'PROBLEM: I have no clue…'" terminate="yes"/>
                                            </xsl:if>
                                        </xsl:for-each>
                                        <!-- create diffs for missing slurs in core -->
                                        <xsl:for-each select="(($match.count + 1) to count($ce.sharing.end.tstamp))">
                                            <xsl:variable name="pos" select="." as="xs:integer"/>
                                            <ce.diff type="missing.ce" elem.name="hairpin" start.measure="{$current.start.measure}" staff="{$current.staff}" missing.in="core" existing.id="{$ce.sharing.end.tstamp[$pos]/@xml:id}"/>
                                        </xsl:for-each>
                                        
                                    </xsl:when>
                                    
                                </xsl:choose>
                                <!-- not sharing end.tstamp anymore -->
                            </xsl:for-each-group>
                            <!-- not sharing end.measure anymore -->
                        </xsl:for-each-group>
                        <!-- not sharing start.tstamp anymore -->    
                    </xsl:for-each-group>
                    
                    <!-- not sharing measure anymore --> 
                </xsl:for-each-group>
                    
                <!-- not sharing staff anymore --> 
            </xsl:for-each-group>
            
            <!-- checking dynams -->
            <xsl:for-each-group select="$controlEvents.source.profile[local-name() = 'dynam']" group-by="@staff.n">
                <xsl:variable name="ce.perStaff" select="current-group()" as="node()*"/>
                <xsl:variable name="current.staff" select="current-grouping-key()" as="xs:string"/>
                
                <xsl:for-each-group select="$ce.perStaff" group-by="@start.measure">
                    <xsl:variable name="ce.sharing.start.measure" select="current-group()" as="node()*"/>
                    <xsl:variable name="current.start.measure" select="current-grouping-key()" as="xs:string"/>
                
                    <xsl:for-each-group select="$ce.sharing.start.measure" group-by="@start.tstamp">
                        <xsl:variable name="ce.sharing.start.tstamp" select="current-group()" as="node()*"/>
                        <xsl:variable name="current.start.tstamp" select="current-grouping-key()" as="xs:string"/>
                        
                        <xsl:for-each-group select="$ce.sharing.start.tstamp" group-by="@value">
                            <xsl:variable name="ce.sharing.value" select="current-group()" as="node()*"/>
                            <xsl:variable name="current.value" select="current-grouping-key()" as="xs:string"/>
                                
                            <xsl:variable name="match" select="$controlEvents.core.profile[local-name() = 'dynam' 
                                and @start.measure = $current.start.measure
                                and @start.tstamp = $current.start.tstamp
                                and @value = $current.value
                                and @staff.n = $current.staff]" as="node()*"/>
                            
                            <xsl:variable name="match.count" select="count($match)" as="xs:integer"/>
                            
                            <xsl:choose>
                                <!-- core has the same number of slurs as source -->
                                <xsl:when test="$match.count = count($ce.sharing.value)">
                                    <xsl:for-each select="$ce.sharing.value">
                                        <xsl:variable name="pos" select="position()" as="xs:integer"/>
                                        <ce.match type="ce" elem.name="dynam" source.id="{@xml:id}" core.id="{$match[$pos]/@xml:id}"/>
                                        <xsl:if test="not(@xml:id) or @xml:id = ''">
                                            <xsl:message select="."/>
                                            <xsl:message select="'PROBLEM: I have no clue…'" terminate="no"/>
                                        </xsl:if>
                                    </xsl:for-each>
                                </xsl:when>
                                
                                <!-- core has no corresponding slur -->
                                <xsl:when test="$match.count = 0">
                                    <xsl:for-each select="$ce.sharing.value">
                                        <ce.diff type="missing.ce" elem.name="dynam" start.measure="{$current.start.measure}" staff="{$current.staff}" missing.in="core" existing.id="{@xml:id}"/>
                                    </xsl:for-each>
                                </xsl:when>
                                
                                <!-- core has more corresponding slurs than available in source -->
                                <xsl:when test="$match.count gt count($ce.sharing.value)">
                                    <!-- look up all source slurs with same profile -->
                                    
                                    <!-- set up matches between slurs -->
                                    <xsl:for-each select="(1 to count($ce.sharing.value))">
                                        <xsl:variable name="pos" select="." as="xs:integer"/>
                                        <ce.match type="ce" elem.name="dynam" source.id="{$ce.sharing.value[$pos]/@xml:id}" core.id="{$match[$pos]/@xml:id}"/>
                                        <xsl:if test="not($ce.sharing.value[$pos]/@xml:id) or $ce.sharing.value[$pos]/@xml:id = ''">
                                            <xsl:message select="$ce.sharing.value[$pos]"/>
                                            <xsl:message select="'PROBLEM: I have no clue…'" terminate="yes"/>
                                        </xsl:if>
                                    </xsl:for-each>
                                    <!-- create diffs for missing slurs in source -->
                                    <xsl:for-each select="((count($ce.sharing.value) + 1) to $match.count)">
                                        <xsl:variable name="pos" select="." as="xs:integer"/>
                                        <ce.diff type="missing.ce" elem.name="dynam" start.measure="{$current.start.measure}" staff="{$current.staff}" missing.in="source" existing.id="{$match[$pos]/@xml:id}"/>
                                    </xsl:for-each>
                                    
                                </xsl:when>
                                
                                <!-- core has less corresponding slurs than available in source -->
                                <xsl:when test="$match.count lt count($ce.sharing.value)">
                                    <!-- look up all source slurs with same profile -->
                                    
                                    <!-- set up matches between slurs -->
                                    <xsl:for-each select="(1 to $match.count)">
                                        <xsl:variable name="pos" select="." as="xs:integer"/>
                                        <ce.match type="ce" elem.name="dynam" source.id="{$ce.sharing.value[$pos]/@xml:id}" core.id="{$match[$pos]/@xml:id}"/>
                                        <xsl:if test="not($ce.sharing.value[$pos]/@xml:id) or $ce.sharing.value[$pos]/@xml:id = ''">
                                            <xsl:message select="$ce.sharing.value[$pos]"/>
                                            <xsl:message select="'PROBLEM: I have no clue…'" terminate="yes"/>
                                        </xsl:if>
                                    </xsl:for-each>
                                    <!-- create diffs for missing slurs in core -->
                                    <xsl:for-each select="(($match.count + 1) to count($ce.sharing.value))">
                                        <xsl:variable name="pos" select="." as="xs:integer"/>
                                        <ce.diff type="missing.ce" elem.name="dynam" start.measure="{$current.start.measure}" staff="{$current.staff}" missing.in="core" existing.id="{$ce.sharing.value[$pos]/@xml:id}"/>
                                    </xsl:for-each>
                                    
                                </xsl:when>
                                
                            </xsl:choose>
                            <!-- not sharing value anymore -->
                        </xsl:for-each-group>
                        <!-- not sharing start.tstamp anymore -->    
                    </xsl:for-each-group>
                    
                    <!-- not sharing measure anymore --> 
                </xsl:for-each-group>
                <!-- not sharing staff anymore --> 
            </xsl:for-each-group>
            
            <!-- checking dirs -->
            <xsl:for-each-group select="$controlEvents.source.profile[local-name() = 'dir']" group-by="@staff.n">
                <xsl:variable name="ce.perStaff" select="current-group()" as="node()*"/>
                <xsl:variable name="current.staff" select="current-grouping-key()" as="xs:string"/>
                
                <xsl:for-each-group select="$ce.perStaff" group-by="@start.measure">
                    <xsl:variable name="ce.sharing.start.measure" select="current-group()" as="node()*"/>
                    <xsl:variable name="current.start.measure" select="current-grouping-key()" as="xs:string"/>
                    
                    <xsl:for-each-group select="$ce.sharing.start.measure" group-by="@start.tstamp">
                        <xsl:variable name="ce.sharing.start.tstamp" select="current-group()" as="node()*"/>
                        <xsl:variable name="current.start.tstamp" select="current-grouping-key()" as="xs:string"/>
                        
                        <xsl:for-each-group select="$ce.sharing.start.tstamp" group-by="@value">
                            <xsl:variable name="ce.sharing.value" select="current-group()" as="node()*"/>
                            <xsl:variable name="current.value" select="current-grouping-key()" as="xs:string"/>
                            
                            <xsl:variable name="match" select="$controlEvents.core.profile[local-name() = 'dir' 
                                and @start.measure = $current.start.measure
                                and @start.tstamp = $current.start.tstamp
                                and @value = $current.value
                                and @staff.n = $current.staff]" as="node()*"/>
                            
                            <xsl:variable name="match.count" select="count($match)" as="xs:integer"/>
                            
                            <xsl:choose>
                                <!-- core has the same number of slurs as source -->
                                <xsl:when test="$match.count = count($ce.sharing.value)">
                                    <xsl:for-each select="$ce.sharing.value">
                                        <xsl:variable name="pos" select="position()" as="xs:integer"/>
                                        <ce.match type="ce" elem.name="dir" source.id="{@xml:id}" core.id="{$match[$pos]/@xml:id}"/>
                                        <xsl:if test="not(@xml:id) or @xml:id = ''">
                                            <xsl:message select="."/>
                                            <xsl:message select="'PROBLEM: I have no clue…'" terminate="no"/>
                                        </xsl:if>
                                    </xsl:for-each>
                                </xsl:when>
                                
                                <!-- core has no corresponding slur -->
                                <xsl:when test="$match.count = 0">
                                    <xsl:for-each select="$ce.sharing.value">
                                        <ce.diff type="missing.ce" elem.name="dir" start.measure="{$current.start.measure}" staff="{$current.staff}" missing.in="core" existing.id="{@xml:id}"/>
                                    </xsl:for-each>
                                </xsl:when>
                                
                                <!-- core has more corresponding slurs than available in source -->
                                <xsl:when test="$match.count gt count($ce.sharing.value)">
                                    <!-- look up all source slurs with same profile -->
                                    
                                    <!-- set up matches between slurs -->
                                    <xsl:for-each select="(1 to count($ce.sharing.value))">
                                        <xsl:variable name="pos" select="." as="xs:integer"/>
                                        <ce.match type="ce" elem.name="dir" source.id="{$ce.sharing.value[$pos]/@xml:id}" core.id="{$match[$pos]/@xml:id}"/>
                                        <xsl:if test="not($ce.sharing.value[$pos]/@xml:id) or $ce.sharing.value[$pos]/@xml:id = ''">
                                            <xsl:message select="$ce.sharing.value[$pos]"/>
                                            <xsl:message select="'PROBLEM: I have no clue…'" terminate="yes"/>
                                        </xsl:if>
                                    </xsl:for-each>
                                    <!-- create diffs for missing slurs in source -->
                                    <xsl:for-each select="((count($ce.sharing.value) + 1) to $match.count)">
                                        <xsl:variable name="pos" select="." as="xs:integer"/>
                                        <ce.diff type="missing.ce" elem.name="dir" start.measure="{$current.start.measure}" staff="{$current.staff}" missing.in="source" existing.id="{$match[$pos]/@xml:id}"/>
                                    </xsl:for-each>
                                    
                                </xsl:when>
                                
                                <!-- core has less corresponding slurs than available in source -->
                                <xsl:when test="$match.count lt count($ce.sharing.value)">
                                    <!-- look up all source slurs with same profile -->
                                    
                                    <!-- set up matches between slurs -->
                                    <xsl:for-each select="(1 to $match.count)">
                                        <xsl:variable name="pos" select="." as="xs:integer"/>
                                        <ce.match type="ce" elem.name="dir" source.id="{$ce.sharing.value[$pos]/@xml:id}" core.id="{$match[$pos]/@xml:id}"/>
                                        <xsl:if test="not($ce.sharing.value[$pos]/@xml:id) or $ce.sharing.value[$pos]/@xml:id = ''">
                                            <xsl:message select="$ce.sharing.value[$pos]"/>
                                            <xsl:message select="'PROBLEM: I have no clue…'" terminate="yes"/>
                                        </xsl:if>
                                    </xsl:for-each>
                                    <!-- create diffs for missing slurs in core -->
                                    <xsl:for-each select="(($match.count + 1) to count($ce.sharing.value))">
                                        <xsl:variable name="pos" select="." as="xs:integer"/>
                                        <ce.diff type="missing.ce" elem.name="dir" start.measure="{$current.start.measure}" staff="{$current.staff}" missing.in="core" existing.id="{$ce.sharing.value[$pos]/@xml:id}"/>
                                    </xsl:for-each>
                                    
                                </xsl:when>
                                
                            </xsl:choose>
                            <!-- not sharing value anymore -->
                        </xsl:for-each-group>
                        <!-- not sharing start.tstamp anymore -->    
                    </xsl:for-each-group>
                    
                    <!-- not sharing measure anymore --> 
                </xsl:for-each-group>
                <!-- not sharing staff anymore --> 
            </xsl:for-each-group>
            
        </xsl:variable>
        
        <xsl:variable name="from.core" as="node()*">
            <xsl:for-each select="$controlEvents.core.profile[local-name() = 'slur']">
                <xsl:variable name="current.slur" select="." as="node()"/>
                
                <xsl:if test="not($from.source/descendant-or-self::ce.match[@core.id = $current.slur/@xml:id]) and 
                    not($from.source/descendant-or-self::ce.diff[@existing.id = $current.slur/@xml:id][@missing.in = 'source'])">
                    <ce.diff type="missing.ce" elem.name="slur" start.measure="{$current.slur/@start.measure}" staff="{$current.slur/@staff.n}" missing.in="source" existing.id="{$current.slur/@xml:id}"/>
                </xsl:if>
            </xsl:for-each>
            
            <xsl:for-each select="$controlEvents.core.profile[local-name() = 'hairpin.cres']">
                <xsl:variable name="current.cres" select="." as="node()"/>
                
                <xsl:if test="not($from.source/descendant-or-self::ce.match[@core.id = $current.cres/@xml:id]) and 
                    not($from.source/descendant-or-self::ce.diff[@existing.id = $current.cres/@xml:id][@missing.in = 'source'])">
                    <ce.diff type="missing.ce" elem.name="hairpin" start.measure="{$current.cres/@start.measure}" staff="{$current.cres/@staff.n}" missing.in="source" existing.id="{$current.cres/@xml:id}"/>
                </xsl:if>
            </xsl:for-each>
            
            <xsl:for-each select="$controlEvents.core.profile[local-name() = 'hairpin.dim']">
                <xsl:variable name="current.dim" select="." as="node()"/>
                
                <xsl:if test="not($from.source/descendant-or-self::ce.match[@core.id = $current.dim/@xml:id]) and 
                    not($from.source/descendant-or-self::ce.diff[@existing.id = $current.dim/@xml:id][@missing.in = 'source'])">
                    <ce.diff type="missing.ce" elem.name="hairpin" start.measure="{$current.dim/@start.measure}" staff="{$current.dim/@staff.n}" missing.in="source" existing.id="{$current.dim/@xml:id}"/>
                </xsl:if>
            </xsl:for-each>
            
            <xsl:for-each select="$controlEvents.core.profile[local-name() = 'dynam']">
                <xsl:variable name="current.dynam" select="." as="node()"/>
                
                <xsl:if test="not($from.source/descendant-or-self::ce.match[@core.id = $current.dynam/@xml:id]) and 
                    not($from.source/descendant-or-self::ce.diff[@existing.id = $current.dynam/@xml:id][@missing.in = 'source'])">
                    <ce.diff type="missing.ce" elem.name="dynam" start.measure="{$current.dynam/@start.measure}" staff="{$current.dynam/@staff.n}" missing.in="source" existing.id="{$current.dynam/@xml:id}"/>
                </xsl:if>
            </xsl:for-each>
            
            <xsl:for-each select="$controlEvents.core.profile[local-name() = 'dir']">
                <xsl:variable name="current.dir" select="." as="node()"/>
                
                <xsl:if test="not($from.source/descendant-or-self::ce.match[@core.id = $current.dir/@xml:id]) and 
                    not($from.source/descendant-or-self::ce.diff[@existing.id = $current.dir/@xml:id][@missing.in = 'source'])">
                    <ce.diff type="missing.ce" elem.name="dir" start.measure="{$current.dir/@start.measure}" staff="{$current.dir/@staff.n}" missing.in="source" existing.id="{$current.dir/@xml:id}"/>
                </xsl:if>
            </xsl:for-each>
            
        </xsl:variable>
        
        <xsl:copy-of select="$from.source | $from.core"/>
        
    </xsl:function>
    
    <!-- resolves controlEvents -->
    <xsl:template match="mei:app[parent::mei:measure]/mei:rdg[mei:*[local-name() = ('slur','hairpin','dynam','dir')]]" mode="compare.phase2">
        <xsl:param name="diff.groups" as="node()" tunnel="yes"/>
        <xsl:param name="source.prep" as="node()" tunnel="yes"/>
        
        <xsl:variable name="controlEvent.id" select="child::mei:*[local-name() = ('slur','hairpin','dynam','dir')]/@xml:id" as="xs:string"/>
        <xsl:variable name="controlEvent.name" select="local-name(child::mei:*[local-name() = ('slur','hairpin','dynam','dir')])" as="xs:string"/>
        <xsl:variable name="match" select="$diff.groups//ce.match[@core.id = $controlEvent.id]" as="node()?"/>
        <xsl:variable name="missing.in.source" select="$diff.groups//ce.diff[@existing.id = $controlEvent.id][@type = 'missing.ce'][@missing.in = 'source']" as="node()?"/>
        
        <!-- when applicable, add reference to source to rdg, and add reference to source controlEvent's id for later processing -->
        <xsl:choose>
            <xsl:when test="$missing.in.source">
                <xsl:copy-of select="."/>
                <!-- add empty rdg for new source only once -->
                <xsl:if test="(parent::mei:app//mei:*[local-name() = $controlEvent.name])[last()]/@xml:id = $controlEvent.id">
                    <xsl:variable name="rdg.id" select="'x' || uuid:randomUUID()" as="xs:string"/>
                    
                    <rdg xmlns="http://www.music-encoding.org/ns/mei" xml:id="{$rdg.id}" source="#{$source.id}"/>
                    <annot xmlns="http://www.music-encoding.org/ns/mei" xml:id="j{uuid:randomUUID()}" type="diff" subtype="{$controlEvent.name}" plist="#{$rdg.id}">
                        <xsl:copy-of select="$missing.in.source"/>
                        <p>Source <xsl:value-of select="$source.id"/> has no corresponding <xsl:value-of select="$controlEvent.name"/>.</p>
                    </annot>
                    <hiccup reason="control">added a rdg</hiccup>
                </xsl:if>
                
            </xsl:when>
            <!-- es ist nicht als missing.in.source erkannt, aber es gibt auch keine Entsprechung in den Core. Wie sollte dieser Fall eintreten? -->
            <xsl:when test="not(exists($match))">
                <!-- todo: is this correct? -->
                <xsl:message select="'DEBUG: Is this correct?'"/>
                <xsl:next-match/>
            </xsl:when>
            <!-- there is a match between core and source -->
            <xsl:otherwise>
                <xsl:copy>
                    <xsl:apply-templates select="node() | @*" mode="#current">
                        <xsl:with-param name="source.id.toAdd" select="$source.id" tunnel="yes" as="xs:string"/>
                        <xsl:with-param name="controlEvent.id.toAdd" select="$match/@source.id" tunnel="yes" as="xs:string"/>
                    </xsl:apply-templates>
                </xsl:copy>
                
                <xsl:variable name="source.choice" select="$source.prep//mei:*[@xml:id = $match/@source.id]/parent::mei:rdg/parent::mei:app" as="node()?"/>
                <xsl:if test="$source.choice">
                    
                    <!-- get all controlEvents in the source that are not encoded in the core (yet) -->
                    <xsl:variable name="all.controlEvents" select="$source.choice//mei:*[local-name() = $controlEvent.name]" as="node()+"/>
                    <xsl:variable name="matched.controlEvents" select="$all.controlEvents/descendant-or-self::mei:*[@xml:id = $diff.groups//ce.match/@source.id]" as="node()+"/>
                    <xsl:variable name="unmatched.controlEvents" select="$all.controlEvents[@xml:id = $diff.groups//ce.diff[@missing.in = 'core']/@existing.id]" as="node()*"/>
                    
                    <!-- when dealing with last matched controlEvent, take care of unmatched controlEvents of same kind, 
                i.e. those slurs that are only available in the source -->
                    <xsl:if test="($matched.controlEvents/@xml:id)[last()] = $controlEvent.id">
                        <xsl:for-each select="$unmatched.controlEvents">
                            <rdg xmlns="http://www.music-encoding.org/ns/mei" xml:id="x{uuid:randomUUID()}" source="#{$source.id}" n="todo">
                                <xsl:apply-templates select="." mode="adjustMaterial"/>
                            </rdg>
                            <xsl:comment select="'annot: no match for ' || $controlEvent.name || ' from source ' || $source.id || ' in core.'"/>
                            <hiccup reason="control">found a rdg in the source not yet available in the core</hiccup>
                        </xsl:for-each>
                    </xsl:if>
                </xsl:if>
                
            </xsl:otherwise>
        </xsl:choose>
        
    </xsl:template>
    
    <xsl:template match="@xml:id" mode="adjustMaterial">
        <xsl:attribute name="xml:id" select="'r'||uuid:randomUUID()"/>
        <xsl:attribute name="synch" select="."/>
    </xsl:template>
    
    <!-- resolves slurs -->
    <xsl:template match="mei:slur | mei:hairpin | mei:dynam | mei:dir" mode="compare.phase2">
        <xsl:param name="diff.groups" as="node()" tunnel="yes"/>
        <xsl:param name="source.prep" as="node()" tunnel="yes"/>
        <xsl:param name="controlEvent.id.toAdd" as="xs:string?" tunnel="yes"/>
        
        <xsl:variable name="this" select="." as="node()"/>
        <xsl:variable name="this.name" select="local-name($this)"/>
        
        <xsl:choose>
            <!-- when a corresponding controlEvent has been identified at an ancestor::rdg, 
                just add a reference to that controlEvent here -->
            <xsl:when test="exists($controlEvent.id.toAdd)">
                <xsl:copy>
                    <xsl:attribute name="synch" select="$controlEvent.id.toAdd"/>
                    <xsl:apply-templates select="node() | @*" mode="#current"/>
                </xsl:copy>
            </xsl:when>
            
            <!-- when controlEvent has been inambiguous so far, and a match between core and source can be identified -->
            <xsl:when test="not(ancestor::mei:rdg) and $diff.groups//ce.match[@core.id = $this/@xml:id]">
                
                <xsl:variable name="match" select="$diff.groups//ce.match[@core.id = $this/@xml:id]" as="node()"/>
                
                <xsl:variable name="source.controlEvent" select="$source.prep//mei:*[local-name() = $this.name and @xml:id = $match/@source.id]" as="node()"/>
                
                <!-- decide if source has alternate readings or not -->
                <xsl:choose>
                    <!-- the controlEvent is inambiguous in the source as well -->
                    <xsl:when test="not($source.controlEvent/parent::mei:rdg)">
                        <xsl:copy>
                            <xsl:attribute name="synch" select="$match/@source.id"/>
                            <xsl:apply-templates select="node() | @*" mode="#current"/>
                        </xsl:copy>
                    </xsl:when>
                    <xsl:otherwise>
                        <!-- generate additional rdgs for all controlEvents from source -->
                        
                        <xsl:variable name="rdg1.id" select="'q' || uuid:randomUUID()" as="xs:string"/>
                        <xsl:variable name="other.controlEvents" select="$source.controlEvent/ancestor::mei:app//mei:*[local-name() = $this.name and @xml:id != $source.controlEvent/@xml:id]" as="node()*"/>
                        <xsl:variable name="rdg.ids" as="xs:string*">
                            <xsl:for-each select="(1 to count($other.controlEvents))">
                                <xsl:value-of select="'n' || uuid:randomUUID()"/>
                            </xsl:for-each>
                        </xsl:variable>
                        
                        <app xmlns="http://www.music-encoding.org/ns/mei" xml:id="q{uuid:randomUUID()}">
                            <rdg xml:id="{$rdg1.id}" source="#{string-join($all.sources.so.far,' #') || ' #' || $source.id}">
                                <xsl:copy>
                                    <xsl:attribute name="synch" select="$controlEvent.id.toAdd"/>
                                    <xsl:apply-templates select="node() | @*" mode="#current"/>
                                </xsl:copy>
                            </rdg>
                            <xsl:for-each select="$other.controlEvents">
                                <rdg xml:id="{$rdg.ids[position()]}" source="#{$source.id}">
                                    <xsl:apply-templates select="." mode="adjustMaterial"/>
                                </rdg>
                            </xsl:for-each>
                        </app>
                        <annot xmlns="http://www.music-encoding.org/ns/mei" xml:id="r{uuid:randomUUID()}" plist="{'#' || $rdg1.id || ' #' || string-join($rdg.ids, ' #')}" 
                            type="diff" subtype="{$this.name}" corresp="#{string-join($all.sources.so.far,' #') || ' #' || $source.id}">
                            <xsl:copy-of select="$match"/>
                            <p>Source <xsl:value-of select="$source.id"/> has some alternatives for this <xsl:value-of select="$this.name"/>.</p>
                        </annot>
                        <hiccup reason="control">generated an app</hiccup>
                    </xsl:otherwise>
                </xsl:choose>
                
                
            </xsl:when>
            
            <!-- when the controlEvent has been identified as missing in the new source -->
            <xsl:when test="not(ancestor::mei:rdg) and $diff.groups//ce.diff[@type = 'missing.ce'][@missing.in = 'source'][@existing.id = $this/@xml:id]">
                
                <xsl:variable name="rdg1.id" select="'q' || uuid:randomUUID()" as="xs:string"/>
                <xsl:variable name="rdg2.id" select="'n' || uuid:randomUUID()" as="xs:string"/>
                
                <xsl:variable name="diff" select="$diff.groups//ce.diff[@type = 'missing.ce' and @missing.in = 'source' and @existing.id = $this/@xml:id]" as="node()*"/>
                
                <app xmlns="http://www.music-encoding.org/ns/mei" xml:id="q{uuid:randomUUID()}">
                    <rdg xml:id="{$rdg1.id}" source="#{string-join($all.sources.so.far,' #')}">
                        <xsl:next-match/>
                    </rdg>
                    <rdg xml:id="{$rdg2.id}" source="#{$source.id}"/>
                </app>
                <annot xmlns="http://www.music-encoding.org/ns/mei" xml:id="r{uuid:randomUUID()}" plist="{'#' || $rdg1.id || ' #' || $rdg2.id}" 
                    type="diff" subtype="{$this.name}" corresp="#{string-join($all.sources.so.far,' #') || ' #' || $source.id}">
                    <xsl:copy-of select="$diff"/>
                    <p>No corresponding <xsl:value-of select="$this.name"/> in source <xsl:value-of select="$source.id"/>.</p>
                </annot>
                <hiccup reason="control">generated an app</hiccup>
            </xsl:when>
            
            <!-- when the controlEvent is nested into a rdg, all corresponding cases are covered from there -->
            <!-- controlEvent mit rdg in core, aber nicht gematcht -->
            <xsl:otherwise>
                <xsl:message select="'this should not have happened at ' || $this/@xml:id" terminate="yes"/>    
            </xsl:otherwise>
        </xsl:choose>
        
    </xsl:template>
    
    <!-- adds controlEvents that haven't been referenced in the core yet (not even through alternative readings) -->
    <xsl:template match="mei:measure" mode="compare.phase2">
        <xsl:param name="diff.groups" as="node()" tunnel="yes"/>
        <xsl:param name="source.prep" as="node()" tunnel="yes"/>
        
        <xsl:variable name="core.measure" select="." as="node()"/>
        <xsl:variable name="source.measure" select="$source.prep//mei:measure[substring-after(@sameas,'#') = $core.measure/@xml:id]" as="node()"/>
        
        <xsl:copy>
            <xsl:apply-templates select="node() | @*" mode="#current"/>
            
            <xsl:variable name="all.source.ce" select="$source.measure//mei:*[local-name() = ('slur','hairpin','dynam','dir')]" as="node()*"/>
            <xsl:variable name="all.missing.ce" select="$all.source.ce[@xml:id = $diff.groups//ce.diff[@missing.in = 'core']/@existing.id]" as="node()*"/>
            <xsl:variable name="all.unreferenced.ce" as="node()*">
                <xsl:for-each select="$all.missing.ce">
                    <xsl:variable name="current.missing.ce" select="." as="node()"/>
                    <xsl:choose>
                        <!-- if ce is in a rdg, check if all alternative readings aren't matching the core either-->
                        <xsl:when test="$current.missing.ce/parent::mei:rdg">
                            <xsl:variable name="app" select="$current.missing.ce/ancestor::mei:app[1]" as="node()"/>
                            <xsl:if test="not(some $rdg in $app/mei:rdg/mei:* satisfies $rdg/@xml:id = $diff.groups//ce.match/@source.id)">
                                <xsl:sequence select="$current.missing.ce"/>
                            </xsl:if>
                        </xsl:when>
                        <!-- if no app surrounds this ce, it can't be resolved from a different rdg –> must be included here -->
                        <xsl:otherwise>
                            <xsl:sequence select="$current.missing.ce"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:for-each>
            </xsl:variable>
            
            <xsl:for-each select="$all.unreferenced.ce">
                <xsl:variable name="current.ce" select="." as="node()"/>
                <xsl:choose>
                    <!-- this ce has no multiple readings -->
                    <xsl:when test="not($current.ce/parent::mei:rdg)">
                        <xsl:variable name="rdg1.id" select="'q' || uuid:randomUUID()" as="xs:string"/>
                        <xsl:variable name="rdg2.id" select="'n' || uuid:randomUUID()" as="xs:string"/>
                        
                        <xsl:variable name="diff" select="$diff.groups//ce.diff[@type = 'missing.ce' and @missing.in = 'core' and @existing.id = $current.ce/@xml:id]" as="node()"/>
                        
                        <app xmlns="http://www.music-encoding.org/ns/mei" xml:id="q{uuid:randomUUID()}">
                            <rdg xml:id="{$rdg1.id}" source="#{string-join($all.sources.so.far,' #')}"/>                            
                            <rdg xml:id="{$rdg2.id}" source="#{$source.id}">
                                <xsl:apply-templates select="$current.ce" mode="adjustMaterial"/>
                            </rdg>
                        </app>
                        <annot xmlns="http://www.music-encoding.org/ns/mei" xml:id="r{uuid:randomUUID()}" plist="{'#' || $rdg1.id || ' #' || $rdg2.id}" 
                            type="diff" subtype="{local-name($current.ce)}" corresp="#{string-join($all.sources.so.far,' #') || ' #' || $source.id}">
                            <xsl:copy-of select="$diff"/>
                            <p>Source <xsl:value-of select="$source.id"/> has a <xsl:value-of select="local-name($current.ce)"/>, which is not available in <xsl:value-of select="string-join($all.sources.so.far,', ')"/>.</p>
                        </annot>
                        <hiccup reason="control">spotted a controlEvent not available in the core (yet)</hiccup>
                    </xsl:when>
                    <!-- this ce has alternative readings, but is the first alternative -> this one will cover all alternatives… -->
                    <xsl:when test="not($current.ce/parent::mei:rdg/preceding-sibling::mei:rdg)">
                        
                        <xsl:variable name="all.alternatives" select="$current.ce/parent::mei:rdg/parent::mei:app/child::mei:rdg/child::mei:*" as="node()+"/>
                        
                        <xsl:variable name="rdg1.id" select="'q' || uuid:randomUUID()" as="xs:string"/>
                        
                        <xsl:variable name="new.ids" as="xs:string*">
                            <xsl:for-each select="$all.alternatives">
                                <xsl:value-of select="'n' || uuid:randomUUID()"/>
                            </xsl:for-each>
                        </xsl:variable>
                        
                        <xsl:variable name="diffs" select="$diff.groups//ce.diff[@type = 'missing.ce' and @missing.in = 'core' and @existing.id = $all.alternatives/@xml:id]" as="node()+"/>
                        
                        <app xmlns="http://www.music-encoding.org/ns/mei" xml:id="q{uuid:randomUUID()}">
                            <rdg xml:id="{$rdg1.id}" source="#{string-join($all.sources.so.far,' #')}"/>  
                            
                            <xsl:for-each select="$all.alternatives">
                                <xsl:variable name="this.ce" select="." as="node()"/>
                                <xsl:variable name="pos" select="position()" as="xs:integer"/>
                                
                                <rdg xml:id="{$new.ids[$pos]}" source="#{$source.id}">
                                    <xsl:apply-templates select="$this.ce" mode="adjustMaterial"/>
                                </rdg>
                            </xsl:for-each>
                        </app>
                        <annot xmlns="http://www.music-encoding.org/ns/mei" xml:id="r{uuid:randomUUID()}" plist="{'#' || $rdg1.id || ' #' || string-join($new.ids,' #')}" 
                            type="diff" subtype="{local-name($current.ce)}" corresp="#{string-join($all.sources.so.far,' #') || ' #' || $source.id}">
                            <xsl:copy-of select="$diffs"/>
                            <p>Source <xsl:value-of select="$source.id"/> has an ambiguous <xsl:value-of select="local-name($current.ce)"/>, which is not available in <xsl:value-of select="string-join($all.sources.so.far,', ')"/>.</p>
                        </annot>
                        <hiccup reason="control">spotted an ambiguous controlEvent not available in the core (yet)</hiccup>
                    </xsl:when>
                </xsl:choose>
            </xsl:for-each>
            
        </xsl:copy>
    
    </xsl:template>
    
    
        
    <xsl:template match="mei:rdg/@source" mode="compare.phase2">
        <xsl:param name="source.id.toAdd" tunnel="yes" as="xs:string?"/>
        
        <xsl:choose>
            <xsl:when test="not(exists($source.id.toAdd))">
                <xsl:next-match/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:attribute name="source" select=". || ' #' || $source.id.toAdd"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- /mode compare.phase2 – END -->
    
    <!-- mode compare.phase3 – START -->
    
    <!-- adjust @startid and @endid -->
    <xsl:template match="@startid" mode="compare.phase3">
        <xsl:param name="core.draft" tunnel="yes" as="node()"/>
        <xsl:param name="source.preComp" tunnel="yes" as="node()"/>
        
        <xsl:choose>
            <xsl:when test="not(ancestor::mei:rdg[@source = ('#' || $source.id)])">
                <xsl:next-match/>
            </xsl:when>
            <xsl:otherwise>
                
                <xsl:variable name="tokens" select="tokenize(normalize-space(.),' ')" as="xs:string*"/>
                <xsl:variable name="new.refs" as="xs:string*">
                    <xsl:for-each select="$tokens">
                        <xsl:variable name="current.token" select="." as="xs:string"/>
                        <xsl:value-of select="$core.draft//mei:*[@synch = substring($current.token,2)]/@xml:id"/>
                    </xsl:for-each>
                </xsl:variable>
                <xsl:attribute name="startid" select="'#' || string-join($new.refs,' #')"/>
                
            </xsl:otherwise>
        </xsl:choose>
        
        
    </xsl:template>
    
    <xsl:template match="@endid" mode="compare.phase3">
        <xsl:param name="core.draft" tunnel="yes" as="node()"/>
        <xsl:param name="source.preComp" tunnel="yes" as="node()"/>
        
        <xsl:choose>
            <xsl:when test="not(ancestor::mei:rdg[@source = ('#' || $source.id)])">
                <xsl:next-match/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="tokens" select="tokenize(normalize-space(.),' ')" as="xs:string*"/>
                <xsl:variable name="new.refs" as="xs:string*">
                    <xsl:for-each select="$tokens">
                        <xsl:variable name="current.token" select="." as="xs:string"/>
                        <xsl:value-of select="$core.draft//mei:*[@synch = substring($current.token,2)]/@xml:id"/>
                    </xsl:for-each>
                </xsl:variable>
                <xsl:attribute name="endid" select="'#' || string-join($new.refs,' #')"/>
            </xsl:otherwise>
        </xsl:choose>
        
    </xsl:template>
    
    <!-- removing unnecessary empty reading -->
    <xsl:template match="mei:rdg" mode="compare.phase3">
        <xsl:choose>
            <!-- controlEvent clarification -->
            
            <!-- when this rdg indicates a missing controlEvent in older sources, 
                and the current source also lacks this controlEvent, just add a 
                reference to the current source here, and remove the newly created
                rdg (next xsl:when) -->
            <xsl:when test="parent::mei:app/parent::mei:measure 
                and not(child::mei:*) 
                and not(@source = ('#' || $source.id))
                and parent::mei:app/child::mei:rdg[not(child::mei:*) 
                    and @source = ('#' || $source.id)
                    and starts-with(@xml:id,'x')
                ]">
                <xsl:copy>
                    <xsl:apply-templates select="@* except @source" mode="#current"/>
                    <xsl:attribute name="source" select="@source || ' #' || $source.id"/>
                    <xsl:apply-templates select="node()" mode="#current"/>
                </xsl:copy>
            </xsl:when>
            <xsl:when test="parent::mei:app/parent::mei:measure 
                and not(child::mei:*)
                and @source = ('#' || $source.id)
                and parent::mei:app/child::mei:rdg[not(child::mei:*)
                    and not(@source = ('#' || $source.id))
                ]
                and starts-with(@xml:id,'x')
                and following-sibling::mei:*[1][local-name() = 'annot'
                    and child::mei:p[contains(text(), ' has no corresponding ')]
                    and starts-with(@xml:id,'j')
                ]">
                <!-- do nothing -->
            </xsl:when>
            
            
            <!-- other, event-related cases -->
            
            <!-- if rdg references other source(s), copy it -->
            <xsl:when test="not(@source = ('#' || $source.id))">
                <xsl:next-match/>
            </xsl:when>
            <!-- if rdg contains something, copy it -->
            <xsl:when test="child::mei:*">
                <xsl:next-match/>
            </xsl:when>
            
            <!-- when there is no sibling rdg that refers to the current source, copy it -->
            <xsl:when test="not(preceding-sibling::mei:rdg[$source.id = tokenize(replace(@source,'#',''),' ')]
                or following-sibling::mei:rdg[$source.id = tokenize(replace(@source,'#',''),' ')]
                )">
                <xsl:next-match/>
            </xsl:when>
            <!-- rdg refers to the current source, has no content, and the current source offers another alternative: 
                in essence, the current rdg is unnecessary and should go away…
                -->
            <xsl:otherwise/>
        </xsl:choose>
    </xsl:template>
    
    <!-- remove annots for missing slurs if they can be merged into existing rdgs-->
    <xsl:template match="mei:annot" mode="compare.phase3">
        <xsl:choose>
            <!-- remove annots which are contained in the file already -->
            <xsl:when test="@xml:id = preceding-sibling::mei:annot/@xml:id"/>
            
            <xsl:when test="not(starts-with(@xml:id,'j'))">
                <xsl:next-match/>
            </xsl:when>
            <xsl:when test="not(@type = 'diff')">
                <xsl:next-match/>
            </xsl:when>
            <xsl:when test="not(child::ce.diff[@type = 'missing.ce' and @missing.in = 'source'])">
                <xsl:next-match/>
            </xsl:when>
            <xsl:when test="not(child::mei:p[contains(text(),' has no corresponding ')])">
                <xsl:next-match/>
            </xsl:when>
            <xsl:when test="not(count(parent::mei:app/child::mei:rdg[not(child::mei:*)]) gt 1)">
                <xsl:next-match/>
            </xsl:when>
            <xsl:when test="not(preceding-sibling::mei:rdg[1][starts-with(@xml:id,'x')
                and @source = ('#' || $source.id)
                and not(child::mei:*)
                ])">
                <xsl:next-match/>
            </xsl:when>
            <!-- all conditions are matched, so remove this annot -->
            <xsl:otherwise>
                <xsl:message select="'INFO: Simplified encoding of controlEvents in ' || ancestor::mei:measure/@n"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="hiccup[@reason = 'control']" mode="compare.phase3">
        <xsl:variable name="annot" select="preceding-sibling::*[1]" as="node()"/>
        <xsl:variable name="rdg" select="preceding-sibling::*[2]" as="node()"/>
        <xsl:choose>
            <xsl:when test="not(text() = 'added a rdg')">
                <xsl:next-match/>
            </xsl:when>
            <xsl:when test="not(local-name($annot) = 'annot' and local-name($rdg) = 'rdg')">
                <xsl:next-match/>
            </xsl:when>
            <xsl:when test="not(starts-with($annot/@xml:id,'j') and starts-with($rdg/@xml:id,'x'))">
                <xsl:next-match/>
            </xsl:when>
            <xsl:when test="not($annot//mei:p[contains(text(),' has no corresponding ')])">
                <xsl:next-match/>
            </xsl:when>
            <xsl:when test="$rdg/child::mei:*">
                <xsl:next-match/>
            </xsl:when>
            <xsl:when test="not(count($rdg/parent::mei:app/child::mei:rdg[not(child::mei:*)]) gt 1)">
                <xsl:next-match/>
            </xsl:when>
            <xsl:when test="not($rdg/@source = ('#' || $source.id))">
                <xsl:next-match/>
            </xsl:when>
            <xsl:otherwise/>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="@xml:id" mode="compare.phase3">
        
        <xsl:variable name="this.id" select="." as="xs:string"/>
        <xsl:variable name="elem" select="parent::mei:*" as="node()"/>
        <xsl:variable name="elem.name" select="local-name($elem)" as="xs:string"/>
        
        <xsl:variable name="new.rdg" select="exists($elem/ancestor-or-self::mei:rdg[@source = ('#' || $source.id)])" as="xs:boolean"/>
                
        <xsl:choose>
            <xsl:when test="$elem.name = 'beam'">
                <xsl:variable name="preceding.elems" select="$elem/preceding::mei:beam[@xml:id = $this.id]" as="node()*"/>
                <xsl:choose>
                    <xsl:when test="count($preceding.elems) gt 0">
                        <xsl:attribute name="xml:id" select="'i'||uuid:randomUUID()"/>
                        <xsl:attribute name="hiccup" select="'changed ID, added corresp'"/>
                        <xsl:attribute name="corresp" select="'#'||$this.id"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:next-match/>
                    </xsl:otherwise>
                </xsl:choose>
                
            </xsl:when>
            <xsl:when test="$new.rdg">
                
                <xsl:variable name="preceding.elems" select="$elem/preceding::mei:*[local-name() = $elem.name and @xml:id = $this.id]" as="node()*"/>
                
                <xsl:choose>
                    <xsl:when test="count($preceding.elems) gt 0">
                        <xsl:attribute name="xml:id" select="'i'||uuid:randomUUID()"/>
                        <xsl:choose>
                            <xsl:when test="exists($elem/@synch)">
                                <xsl:attribute name="hiccup" select="'changed ID'"/>        
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:attribute name="hiccup" select="'replaced ID, no synch!'"/>
                            </xsl:otherwise>
                        </xsl:choose>
                        
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:next-match/>
                    </xsl:otherwise>
                </xsl:choose>
                
            </xsl:when>
            <xsl:otherwise>
                <xsl:next-match/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    
    <!-- /mode compare.phase3 – END -->
    
    <!-- mode source.cleanup – START -->
    
    <xsl:template match="@sameas" mode="source.cleanup">
        <!-- preserve only @sameas for measures -->
        <xsl:choose>
            <xsl:when test="parent::mei:measure">
                <xsl:next-match/>
            </xsl:when>
            <xsl:otherwise/>
        </xsl:choose>
    </xsl:template>
    
    <!-- generate new @sameas where applicable -->
    <xsl:template match="@xml:id" mode="source.cleanup">
        
        <xsl:param name="core.draft" as="node()" tunnel="yes"/>
        
        <xsl:variable name="this.id" select="string(.)"/>
        <xsl:variable name="synch" select="$core.draft//mei:*[@synch=$this.id]" as="node()*"/>
        
        <xsl:if test="count($synch) gt 1">
            <xsl:message terminate="no" select="'ERROR: Multiple elements seem to synch with element ' || $this.id || ':'"/>
            <xsl:for-each select="$synch">
                <xsl:variable name="current.synch" select="." as="node()"/>
                <xsl:message select="local-name($current.synch) || ' with id ' || $current.synch/@xml:id || ' (measure ' || $current.synch/ancestor::mei:measure/@n || ')'"></xsl:message>
            </xsl:for-each>
            <xsl:message terminate="yes" select="'prcessing stopped'"/>
        </xsl:if>
        
        <xsl:attribute name="xml:id" select="$this.id"/>
        
        <xsl:choose>
            <xsl:when test="ancestor::mei:orig">
                <xsl:next-match/>
            </xsl:when>
            <xsl:when test="ancestor::mei:sic">
                <xsl:next-match/>
            </xsl:when>
            <xsl:when test="ancestor::mei:abbr">
                <xsl:next-match/>
            </xsl:when>
            <xsl:when test="parent::mei:space">
                <xsl:next-match/>
            </xsl:when>
            <xsl:when test="parent::mei:chord">
                <xsl:next-match/>
            </xsl:when>
            <xsl:when test="parent::mei:cpMark">
                <xsl:next-match/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:if test="exists(parent::mei:*/@tstamp) and not(exists($synch))">
                    <xsl:message terminate="no" select="local-name(parent::mei:*) || ' in measure ' || ancestor::mei:measure/@n || ' lacks a synch (id: ' || $this.id || ')'"/>
                </xsl:if>
                
                <xsl:if test="$synch">
                    <xsl:attribute name="sameas" select="'#' || $synch/@xml:id"/>
                </xsl:if>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- core-specific information to be removed from source -->
    <xsl:template match="@pname[not(ancestor::mei:orig) and not(ancestor::mei:sic) and not(ancestor::mei:abbr)]" mode="source.cleanup"/>
    <xsl:template match="@dur[not(ancestor::mei:orig) and not(ancestor::mei:sic) and not(ancestor::mei:abbr)]" mode="source.cleanup"/>
    <xsl:template match="@dots[not(ancestor::mei:orig) and not(ancestor::mei:sic) and not(ancestor::mei:abbr)]" mode="source.cleanup"/>
    <xsl:template match="@oct[not(ancestor::mei:orig) and not(ancestor::mei:sic) and not(ancestor::mei:abbr)]" mode="source.cleanup"/>
    <xsl:template match="@accid[not(ancestor::mei:orig) and not(ancestor::mei:sic) and not(ancestor::mei:abbr)]" mode="source.cleanup"/>
    <xsl:template match="@accid.ges[not(ancestor::mei:orig) and not(ancestor::mei:sic) and not(ancestor::mei:abbr)]" mode="source.cleanup"/>
    <xsl:template match="@artic[not(ancestor::mei:orig) and not(ancestor::mei:sic) and not(ancestor::mei:abbr)]" mode="source.cleanup"/>
    <xsl:template match="@grace[not(ancestor::mei:orig) and not(ancestor::mei:sic) and not(ancestor::mei:abbr)]" mode="source.cleanup"/>
    <xsl:template match="@stem.mod[not(ancestor::mei:orig) and not(ancestor::mei:sic) and not(ancestor::mei:abbr)]" mode="source.cleanup"/>
    <xsl:template match="mei:layer//@tstamp[not(ancestor::mei:orig) and not(ancestor::mei:sic) and not(ancestor::mei:abbr)]" mode="source.cleanup"/>
    
    <xsl:template match="mei:appInfo" mode="source.cleanup">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*" mode="#current"/>
            <xsl:if test="not(exists(mei:application[@xml:id='merge2Core2.xsl_v' || $xsl.version]))">
                <application xmlns="http://www.music-encoding.org/ns/mei">
                    <xsl:attribute name="xml:id" select="'merge2Core2.xsl_v' || $xsl.version"/>
                    <xsl:attribute name="version" select="$xsl.version"/>
                    <name>merge2Core2.xsl</name>
                    <ptr target="https://github.com/Freischuetz-Digital/Tools/blob/develop/14%20reCore/merge2Core2.xsl"/>
                </application>
            </xsl:if>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="mei:revisionDesc" mode="source.cleanup">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*" mode="#current"/>
            <change xmlns="http://www.music-encoding.org/ns/mei">
                <xsl:attribute name="n" select="count(mei:change) + 1"/>
                <respStmt>
                    <persName>Johannes Kepper</persName>
                </respStmt>
                <changeDesc>
                    <p>
                        Merged <xsl:value-of select="$mov.id"/>.xml back into core with 
                        <ptr target="merge2Core2.xsl_v{$xsl.version}"/>. All core-related information removed from this file, and
                        required links to the core are added using @sameas. 
                    </p>
                </changeDesc>
                <date isodate="{substring(string(current-date()),1,10)}"/>
            </change>
        </xsl:copy>
    </xsl:template>
    
    <!-- /mode source.cleanup – END -->
    
    <!-- mode core.cleanup – START -->
    <xsl:template match="@synch" mode="core.cleanup"/>
    
    <xsl:template match="mei:appInfo" mode="core.cleanup">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*" mode="#current"/>
            <xsl:if test="not(exists(mei:application[@xml:id='merge2Core2.xsl_v' || $xsl.version]))">
                <application xmlns="http://www.music-encoding.org/ns/mei">
                    <xsl:attribute name="xml:id" select="'merge2Core2.xsl_v' || $xsl.version"/>
                    <xsl:attribute name="version" select="$xsl.version"/>
                    <name>merge2Core2.xsl</name>
                    <ptr target="https://github.com/Freischuetz-Digital/Tools/blob/develop/14%20reCore/merge2Core2.xsl"/>
                </application>
            </xsl:if>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="mei:revisionDesc" mode="core.cleanup">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*" mode="#current"/>
            <change xmlns="http://www.music-encoding.org/ns/mei">
                <xsl:attribute name="n" select="count(mei:change) + 1"/>
                <respStmt>
                    <persName>Johannes Kepper</persName>
                </respStmt>
                <changeDesc>
                    <p>
                        Merged <xsl:value-of select="$mov.id"/> into core, using 
                        <ptr target="merge2Core2.xsl_v{$xsl.version}"/>. Core for this movement now contains <xsl:value-of select="string-join($all.sources.so.far,', ')"/>
                        plus <xsl:value-of select="$source.id"/>.
                    </p>
                </changeDesc>
                <date isodate="{substring(string(current-date()),1,10)}"/>
            </change>
        </xsl:copy>
    </xsl:template>
    
    <!-- /mode core.cleanup – END -->
    
    <!-- mode-independent functions – START -->
    
    <!-- compares attributes between two specified elements, omitting xml:ids -->
    <xsl:function name="local:compareAttributes" as="node()*">
        <xsl:param name="source.elem" as="node()"/>
        <xsl:param name="core.elem" as="node()"/>
        
        <xsl:variable name="source.atts" select="$source.elem/(@* except (@xml:id|@sameas))" as="attribute()*"/>
        <xsl:variable name="core.atts" select="$core.elem/(@* except @xml:id)" as="attribute()*"/>
        
        <xsl:variable name="source.atts.names" select="$source.elem/(@* except (@xml:id|@sameas))/local-name()" as="xs:string*"/>
        <xsl:variable name="core.atts.names" select="$core.elem/(@* except @xml:id)/local-name()" as="xs:string*"/>
        
        <xsl:variable name="diffs" as="node()*">
            <xsl:for-each select="$source.atts">
                <xsl:variable name="source.att" select="."/>
                <xsl:choose>
                    <xsl:when test="string($source.att) = string($core.atts[local-name() = local-name($source.att)])">
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