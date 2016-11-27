<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    xmlns:mei="http://www.music-encoding.org/ns/mei"
    xmlns:local="no:where"
    exclude-result-prefixes="xs xd"
    version="2.0">
  
    <xsl:import href="../global-parameters.xsl"/>
  
    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p><xd:b>Created on:</xd:b> Apr 19, 2013</xd:p>
            <xd:p><xd:b>Author:</xd:b> johannes</xd:p>
            <xd:p><xd:b>Documentation:</xd:b> Benjamin W. Bohl</xd:p>
            <xd:p>
                This stylesheet tries to pregenerate predictable IDs for measure that
                match the format of the IDs in the facsimile-based source files. It tries
                to resolve repetitions into a similar way to allow a good mapping between 
                the two files. 
            </xd:p>
        </xd:desc>
    </xd:doc>
    
    <xd:doc scope="component">
        <xd:desc>
            <xd:p>Define output method as UTF-8 encoded XML with identation.</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:output method="xml" indent="yes" encoding="UTF-8"/>
    
    <xd:doc scope="component">
        <xd:desc>The newSchemaRef parameter defines a new URL for RNG and Schematron schemata; if empty the existing schemaRef will be retained</xd:desc>
    </xd:doc>
    <xsl:param name="newSchemaRef">https://raw.githubusercontent.com/music-encoding/music-encoding/MEI2013_v2.1.1/schemata/mei-all.rng</xsl:param>
    
    <xd:doc scope="component">
        <xd:desc>
            <xd:p>Parameter for mdiv id</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:param name="movID"/>
    
    <xd:doc scope="component">
        <xd:desc>
            <xd:p>Cache all measures in a variable named $measures</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:variable name="measures" select="//mei:measure"/>
    
    <xd:doc scope="component">
        <xd:desc>
            <xd:p>cache file-name in a variable</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:variable name="fileName" select="tokenize(document-uri(root()),'/')[last()]"/>
    
    <xd:doc scope="component">
        <xd:desc>
            <xd:p>General template or copying all nodes that are not being nahdled by a more specific xsl:template</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template match="node() | @*" mode="#all">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <xd:doc scope="component">
        <xd:desc>
            <xd:p>This root template processes the input into two variables 'firstRun' --> mode="core" and 'secondRun' --> mode="lastRun"</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template match="/">
        <xsl:variable name="firstRun">
            <xsl:apply-templates mode="firstRun"/>
        </xsl:variable>
        <xsl:variable name="secondRun">
            <xsl:apply-templates select="$firstRun" mode="core"/> 
        </xsl:variable>
        <xsl:apply-templates select="$secondRun" mode="lastRun"/>
    </xsl:template>
    
    <xd:doc scope="component">
        <xd:desc>
            <xd:p>in mode="firstRun" mei:tupletSpan elements are being added a xml:id and processed according to all other templates in the same mode.</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template match="mei:tupletSpan" mode="firstRun">
        <xsl:copy>
            <xsl:attribute name="xml:id" select="generate-id()"/>
            <xsl:apply-templates select="node() | @*" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <xd:doc scope="component">
        <xd:desc>
            <xd:p>in mode="lastRun" mei:tupletSpan … <!-- TODO: --></xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template match="mei:tupletSpan" mode="lastRun">
        <xsl:variable name="id" select="@xml:id"/>
        <xsl:if test="not(exists(//mei:fTrem[@tempRef = $id]))">
            <xsl:next-match/>
        </xsl:if>
    </xsl:template>
    
    <xd:doc scope="component">
        <xd:desc>
            <xd:p>in mode="lastRun" mei:mdiv with id</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template match="mei:mdiv" mode="lastRun">
        <xsl:copy>
            <xsl:attribute name="xml:id" select="$movID"/>
            <xsl:apply-templates select="@* | node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <xd:doc scope="component">
        <xd:desc>
            <xd:p>in mode="lastRun" remove @type[contains='generated']</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template match="@type[contains(., 'generated')]" mode="lastRun"/>
    
    <xd:doc scope="component">
        <xd:desc>
            <xd:p>in mode="lastRun" remove @type[contains='sharesLayer']</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template match="@type[contains(., 'sharesLayer')]" mode="lastRun"/>
    
    <xd:doc scope="component">
        <xd:desc>
            <xd:p>in mode="lastRun" remove @subtype</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template match="@subtype" mode="lastRun"/>
    
    <xd:doc scope="component">
        <xd:desc>in mode="lastRun" mei:fTrem elements are not being processed any further</xd:desc>
    </xd:doc>
    <xsl:template match="mei:fTrem/@tempRef" mode="lastRun"/>
    
    <xsl:template match="mei:tuplet" mode="firstRun">
        <xsl:copy>
            <xsl:variable name="childs" select="descendant::mei:*[@dur]"/>
            <xsl:variable name="durs" as="xs:double*">
                <xsl:for-each select="$childs">
                    <xsl:variable name="elem" select="."/>
                    <xsl:value-of select="local:getDuration($elem)"/>
                </xsl:for-each>
            </xsl:variable>
            <xsl:variable name="dur" select="sum($durs)"/>
            
            <xsl:apply-templates select="@*" mode="#current"/>
            <xsl:attribute name="dur" select="1 div ($dur * number(@numbase) div number(@num))"/>
            <xsl:apply-templates select="node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>
            <xd:p>In mode="core" mei:measure elements</xd:p>
            <xd:ul>
                <xd:li>joinsNext</xd:li>
            </xd:ul>
        </xd:desc>
    </xd:doc>
    <xsl:template match="mei:measure" mode="core">
        
        <xsl:variable name="joinsNext" select="starts-with(following::mei:measure[1]/@n,'X')" as="xs:boolean"/>
        <xsl:variable name="joinsPrev" select="starts-with(@n,'X')" as="xs:boolean"/>
        <xsl:variable name="n1" select="if(not($joinsPrev)) then(@n) else(preceding::mei:measure[not(starts-with(@n,'X'))][1]/@n)"/>
        
        <xsl:variable name="nStart" select="if(preceding::mei:measure) then(preceding::mei:measure[last()]/@n) else(@n)"/>
        <xsl:variable name="nCount" select="count(preceding::mei:measure[not(starts-with(@n,'X')) and not(exists(parent::mei:ending[number(@n) gt 1]))])"/>
        <xsl:variable name="nMod" select="if($joinsPrev) then(-1) else(0)"/>
        
        <xsl:variable name="n1" select="string((number($nStart) + number($nCount) + number($nMod)))"/>
        
        <xsl:variable name="ending" select="exists(parent::mei:ending)" as="xs:boolean"/>
        
        <xsl:variable name="n">
            <xsl:choose>
                <xsl:when test="not($ending)">
                    <xsl:value-of select="$n1"/>
                </xsl:when>
                <xsl:when test="parent::mei:ending[@n = '1']">
                    <xsl:value-of select="concat($n1,'a')"/>
                </xsl:when>
                <xsl:when test="parent::mei:ending[@n = '2']">
                    
                    <xsl:variable name="reduceCount" select="count(parent::mei:ending/preceding-sibling::mei:ending[@n='1'][1]/mei:measure[not(starts-with(@n,'X'))])"/>
                    
                    <xsl:value-of select="concat(string((number($n1) - $reduceCount)),'b')"/>
                </xsl:when>
            </xsl:choose>
        </xsl:variable>
        
        <xsl:variable name="preJoins" select="if(not($joinsPrev)) then(0) else(2 + local:getPreJoined(.))" as="xs:integer"/>
        <xsl:variable name="preJoins" select="if($joinsNext) then($preJoins + 1) else($preJoins)"/>
        <xsl:variable name="joinedIDaddendum" select="if($preJoins gt 0) then(concat('.',string($preJoins))) else('')" as="xs:string"/>
        
        <xsl:copy>
            <xsl:attribute name="xml:id" select="concat('prefix_measure',$n,$joinedIDaddendum)"/>
            <xsl:attribute name="n" select="$n"/>
            <xsl:apply-templates select="node() | @* except (@xml:id,@n)" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <xd:doc scope="component">
        <xd:desc>
            <xd:p>this template takes care that mei:mei element holds meiversion.num</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template match="@meiversion.num" mode="lastRun">
        <xsl:attribute name="meiversion.num">
            <xsl:value-of select="tokenize(substring-after($newSchemaRef,'MEI2013_v'),'/')[1]"/>
        </xsl:attribute>
    </xsl:template>
    
    <xd:doc scope="component">
        <xd:desc>
            <xd:p>mei:pb elements are to be excluded from the result, as notation program specific page breaks are irrelevant for the project.</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template match="mei:pb" mode="#all"/>
    
    <xd:doc scope="component">
        <xd:desc>
            <xd:p>mei:pb elements are to be excluded from the result, as notation program specific system breaks are irrelevant for the project.</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template match="mei:sb" mode="#all"/>
    
    <xsl:template match="mei:rend[not(@rend = ('sub','sup'))]" mode="core">
        <xsl:apply-templates select="node()" mode="#current"/>
    </xsl:template>
    
    <xd:doc scope="component">
        <xd:desc>Avoid mei:dynam/mei:rend that gets the rend element stripped from retaining the indentation text nodes</xd:desc>
    </xd:doc>
    <xsl:template match="mei:dynam" mode="lastRun">
        <xsl:choose>
            <xsl:when test="mei:rend[@rend = ('sub','sup')]">
                <xsl:apply-templates mode="#current"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy>
                    <xsl:apply-templates select="@*" mode="#current"/>
                    <xsl:analyze-string select="." regex="[^ \n]+">
                        <xsl:matching-substring>
                            <xsl:copy/>
                        </xsl:matching-substring>
                        <xsl:non-matching-substring/>
                    </xsl:analyze-string>
                </xsl:copy>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xd:doc scope="component">
        <xd:desc>
            <xd:p>Chords with stem mods seem to be an indication for bTrem, thus they are transformed accordingly.</xd:p>
            <xd:p>mei:artic child elements of the chord are to be transformed into attribute values according to the FreiDi Encoding Guidelines.</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template match="mei:chord[.//@stem.mod[not(parent::*/@grace)]]" mode="core">
        
        <xsl:element name="bTrem" namespace="http://www.music-encoding.org/ns/mei">
            <xsl:choose>
                <xsl:when test=".//*[@stem.mod]/@dur eq '8'">
                    <xsl:attribute name="slash" select="1"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:comment>todo: if meant to resolve into precise note durations, add @slash="<xsl:value-of select="substring((.//@stem.mod)[1],1,1)"/>"</xsl:comment>
                </xsl:otherwise>
            </xsl:choose>
            
            <xsl:copy>
                <xsl:apply-templates select="@*" mode="#current"/>
                
                <xsl:if test="./mei:artic">
                    <xsl:apply-templates select="./mei:artic/@artic" mode="#current"/>
                </xsl:if>
                
                <xsl:copy-of select=".//@stem.mod"/>
                <xsl:apply-templates select="node()" mode="#current"/>
                
            </xsl:copy>
            
        </xsl:element>
    </xsl:template>
    
    <xd:doc scope="component">
        <xd:desc>
            <xd:p>mei:note elements not being a grace note and with stem.nod and being part of a chord. Moreover:</xd:p>
            <xd:ul>
                <xd:li>mei:artic to @artic</xd:li>
                <xd:li>mei:accid to @accid</xd:li>
            </xd:ul>
        </xd:desc>
    </xd:doc>
    <xsl:template match="mei:note[@stem.mod and ancestor::mei:chord and not(@grace)]" mode="core">
        <xsl:copy>
            <xsl:apply-templates select="@* except @stem.mod" mode="#current"/>
            
            <xsl:if test="./mei:artic">
                <xsl:apply-templates select="./mei:artic/@artic" mode="#current"/>
            </xsl:if>
            
            <xsl:if test="./mei:accid">
                <xsl:apply-templates select="./mei:accid/@accid" mode="#current"/>
            </xsl:if>
            
            <xsl:apply-templates select="node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <xd:doc scope="component">
        <xd:desc>
            <xd:p>mei:note elements not being a grace note and with stem.mod and not being part of a chord will bwe transformed to mei:bTrem elements. Moreover:</xd:p>
            <xd:ul>
                <xd:li>mei:artic to @artic</xd:li>
                <xd:li>mei:accid to @accid</xd:li>
            </xd:ul>
        </xd:desc>
    </xd:doc>
    <xsl:template match="mei:note[@stem.mod and not(ancestor::mei:chord) and not(@grace)]" mode="core">
        
        <xsl:element name="bTrem" namespace="http://www.music-encoding.org/ns/mei">
            <xsl:choose>
                <xsl:when test=".//*[@stem.mod]/@dur eq '8'">
                    <xsl:attribute name="slash" select="1"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:comment>todo: if meant to resolve into precise note durations, add @slash="<xsl:value-of select="substring(@stem.mod,1,1)"/>"</xsl:comment>
                </xsl:otherwise>
            </xsl:choose>
            
            <xsl:copy>
                <xsl:apply-templates select="@*" mode="#current"/>
                
                <xsl:if test="./mei:artic">
                    <xsl:apply-templates select="./mei:artic/@artic" mode="#current"/>
                </xsl:if>
                
                <xsl:if test="./mei:accid">
                    <xsl:apply-templates select="./mei:accid/@accid" mode="#current"/>
                </xsl:if>
                
                <xsl:apply-templates select="node()" mode="#current"/>
            </xsl:copy>
            
        </xsl:element>
        
    </xsl:template>
    
    <xd:doc scope="component">
        <xd:desc>
            <xd:p>mei:note elements are being checked for mei:artic and mei:accid children which will be transformed to the respective attribute values according to the FreiDi Encoding Guidelines</xd:p>
            <xd:ul>
                <xd:li>mei:artic to @artic</xd:li>
                <xd:li>mei:accid to @accid</xd:li>
            </xd:ul>
        </xd:desc>
    </xd:doc>
    <xsl:template match="mei:note" mode="core">
        
        <xsl:copy>
            <xsl:apply-templates select="@*" mode="#current"/>
            
            <xsl:if test="./mei:artic">
                <xsl:apply-templates select="./mei:artic/@artic" mode="#current"/>
            </xsl:if>
            
            <xsl:if test="./mei:accid">
                <xsl:apply-templates select="./mei:accid/@accid" mode="#current"/>
            </xsl:if>
            
            <xsl:apply-templates select="node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="mei:staffDef[not(exists(ancestor::staffGrp)) and parent::mei:section]" mode="core"/>
    
    <xsl:template match="mei:staff[ancestor::mei:measure/preceding-sibling::mei:*[1][local-name() = 'staffDef']]" mode="core">
        <xsl:variable name="staffN" select="@n"/>
        <xsl:variable name="measure" select="ancestor::mei:measure"/>
        <xsl:variable name="prec" select="$measure/preceding::mei:measure"/>
        <xsl:variable name="staffDef" select="$prec/following::mei:staffDef[@n = $staffN and following-sibling::mei:measure/@xml:id = $measure/@xml:id]"/>
        <xsl:variable name="canBeClef" select="if(not(exists($staffDef))) then(false()) else(exists($staffDef/@n) and exists($staffDef/@clef.shape) and exists($staffDef/@clef.line) and (count($staffDef/@*) = 3))"/>
        <xsl:copy>
            <xsl:apply-templates select="@*" mode="#current"/>
            <xsl:if test="exists($staffDef) and not($canBeClef)">
                <xsl:copy-of select="$staffDef"/>
            </xsl:if>
            
            <xsl:apply-templates select="element() | processing-instruction() | text() | comment()" mode="#current">
                <xsl:with-param name="clef" as="node()?">
                    <xsl:if test="$canBeClef">
                        <xsl:element name="clef" xmlns="http://www.music-encoding.org/ns/mei">
                            <xsl:attribute name="xml:id" select="generate-id()"/>
                            <xsl:attribute name="tstamp" select="1"/>
                            <xsl:attribute name="type" select="'generated'"/>
                            <xsl:attribute name="shape" select="$staffDef/@clef.shape"/>
                            <xsl:attribute name="line" select="$staffDef/@clef.line"/>
                        </xsl:element>
                    </xsl:if>
                </xsl:with-param>
            </xsl:apply-templates>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="mei:layer" mode="core">
        <xsl:param name="clef" as="node()?"/>
        <xsl:variable name="n" select="@n"/>
        
        <xsl:variable name="staffN" select="ancestor::mei:staff/@n"/>
        <xsl:variable name="def" select="preceding::mei:*[@meter.unit and @meter.count and (local-name() = 'scoreDef' or @n = $staffN)][1]"/>
        
        <xsl:variable name="elems" select="(descendant::mei:mRest[@dur] | descendant::mei:space[@dur] | descendant::mei:note[@dur and not(ancestor::mei:tuplet)] | descendant::mei:tuplet | descendant::mei:rest | descendant::mei:chord[@dur and not(.//mei:note[@dur])])"/>
        
        <xsl:variable name="elemDurs" as="xs:double*">
            <xsl:for-each select="$elems">
                <xsl:variable name="elem" select="."/>
                <xsl:value-of select="local:getDuration($elem)"/>
            </xsl:for-each>
        </xsl:variable>
        
        <xsl:variable name="durSum" select="sum($elemDurs)"/>
        <xsl:variable name="meterRatio" select="number($def/@meter.count) div number($def/@meter.unit)"/>
        
        
        <xsl:copy>
            
            <xsl:apply-templates select="@*" mode="#current"/>
            <xsl:choose>
                <xsl:when test="$n = '1'">
                    <xsl:copy-of select="$clef"/>        
                </xsl:when>
                <xsl:when test="exists($clef)">
                    <xsl:element name="clef" namespace="http://www.music-encoding.org/ns/mei">
                        <xsl:attribute name="type" select="'sharesLayer1'"/>
                        <xsl:attribute name="corresp" select="concat('#',$clef/@xml:id)"/>
                    </xsl:element>
                </xsl:when>
            </xsl:choose>
            
            <xsl:variable name="isUnfilledLayer1" select="$n = 1 and $durSum lt $meterRatio"/>
            
            <xsl:apply-templates select="element() | processing-instruction() | text() | comment()" mode="#current">
                <xsl:with-param name="isUnfilledLayer1" select="$isUnfilledLayer1"/>
            </xsl:apply-templates>
            
            <xsl:if test="$durSum lt $meterRatio">
                
                <xsl:variable name="layer1elems" select="preceding-sibling::mei:layer[@n = '1']/(descendant::mei:mRest[@dur] | descendant::mei:space[@dur] | descendant::mei:note[@dur and not(ancestor::mei:tuplet)] | descendant::mei:tuplet | descendant::mei:rest | descendant::mei:chord[@dur and not(.//mei:note[@dur])])"/>
                <xsl:variable name="layer1Durs" as="xs:double*">
                    <xsl:for-each select="$layer1elems">
                        <xsl:variable name="elem" select="."/>
                        <xsl:value-of select="local:getDuration($elem)"/>
                    </xsl:for-each>
                </xsl:variable>
                
                <xsl:variable name="events" as="node()*">
                    <xsl:for-each select="$layer1elems">
                        <xsl:variable name="elem" select="."/>
                        <xsl:variable name="pos" select="position()"/>
                        <xsl:variable name="precDur" select="sum(subsequence($layer1Durs,1,$pos))"/>
                        <xsl:if test="$precDur gt $durSum">
                            <xsl:copy-of select="$elem"/>
                        </xsl:if>
                    </xsl:for-each>
                </xsl:variable>
                
                <xsl:for-each select="$events">
                    <xsl:variable name="elem" select="."/>
                    <xsl:element name="space" namespace="http://www.music-encoding.org/ns/mei">
                        <xsl:attribute name="xml:id" select="generate-id()"/>
                        <xsl:attribute name="type" select="'sharesLayer1'"/>
                        <xsl:attribute name="subtype" select="local-name($elem)"/>
                        <xsl:attribute name="corresp" select="concat('#',$elem/@xml:id)"/>
                        <xsl:copy-of select="$elem/@dur"/>
                        <xsl:copy-of select="$elem/@dots"/>
                    </xsl:element>
                </xsl:for-each>
            </xsl:if>
            
            
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="mei:space" mode="core">
        
        <xsl:variable name="staffN" select="ancestor::mei:staff/@n"/>
        <xsl:variable name="def" select="preceding::mei:*[@meter.unit and @meter.count and (local-name() = 'scoreDef' or @n = $staffN)][1]"/>
        
        <xsl:variable name="tstamp" select="local:getTstamp(.,$def)"/>
        
        <xsl:variable name="layer1" select="ancestor::mei:layer/preceding-sibling::mei:layer[@n = '1']"/>
        <xsl:variable name="layer1elems" select="$layer1/(descendant::mei:mRest[@dur] | descendant::mei:space[@dur] | descendant::mei:note[@dur and not(ancestor::mei:tuplet)] | descendant::mei:tuplet | descendant::mei:rest | descendant::mei:chord[@dur and not(.//mei:note[@dur])])"/>
        
        <xsl:variable name="layer1tstamps" as="xs:string*">
            <xsl:for-each select="$layer1elems">
                <xsl:variable name="elem" select="."/>
                <xsl:value-of select="local:getTstamp($elem,$def)"/>
            </xsl:for-each>
        </xsl:variable>
        
        <xsl:variable name="index" select="index-of($layer1tstamps,$tstamp)"/>
        
        <xsl:variable name="corresp" select="$layer1elems[$index]"/>
        
        <xsl:choose>
            <xsl:when test="local:getDuration(.) = local:getDuration($corresp)">
                <xsl:copy>
                    <xsl:copy-of select="@xml:id"/>
                    <xsl:attribute name="type" select="'sharesLayer1'"/>
                    <xsl:attribute name="subtype" select="local-name($corresp)"/>
                    <xsl:attribute name="corresp" select="concat('#',$corresp/@xml:id)"/>
                    <xsl:copy-of select="@dur"/>
                    <xsl:copy-of select="@dots"/>
                </xsl:copy>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="maxT" select="number($tstamp) + (number($def/@meter.unit) div number(@dur))"/>
                
                <xsl:variable name="indizes" as="xs:integer*">
                    <xsl:for-each select="$layer1tstamps">
                        <xsl:if test="number(.) ge number($tstamp) and number(.) lt number($maxT)">
                            <xsl:value-of select="position()"/>
                        </xsl:if>
                    </xsl:for-each>
                </xsl:variable>
                
                <xsl:variable name="correspGrp" select="$layer1elems[position() = $indizes]" as="node()*"/>
                
               <xsl:for-each select="$correspGrp">
                   <xsl:variable name="curr" select="."/>
                   <xsl:element name="space" namespace="http://www.music-encoding.org/ns/mei">
                       <xsl:attribute name="xml:id" select="generate-id()"/>
                       <xsl:attribute name="type" select="'sharesLayer1'"/>
                       <xsl:attribute name="subtype" select="local-name($curr)"/>
                       <xsl:attribute name="corresp" select="concat('#',$curr/@xml:id)"/>
                       <xsl:copy-of select="$curr/@dur"/>
                       <xsl:copy-of select="$curr/@dots"/>
                   </xsl:element>
               </xsl:for-each>
                
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="mei:beam" mode="core">
        <xsl:param name="isUnfilledLayer1"/>
        <xsl:variable name="childs" select="child::mei:*"/>
        <xsl:variable name="measure" select="ancestor::mei:measure"/>
        <xsl:variable name="tupletSpan" select="$measure/mei:tupletSpan[substring(@startid,2) = $childs[1]/@xml:id and substring(@endid,2) = $childs[2]/@xml:id]" as="node()?"/>
        
        
        <xsl:choose>
            <xsl:when test="$isUnfilledLayer1 and count($childs) = 2 and exists($tupletSpan)">
                <xsl:message terminate="no" select="concat('beam in measure ',$measure/@n,', staff ', ancestor::mei:staff/@n,' is suspicious')"/>
                <xsl:element name="fTrem" namespace="http://www.music-encoding.org/ns/mei">
                    <xsl:attribute name="dur" select="2"/>
                    <xsl:if test="$childs/@dots">
                        <xsl:copy-of select="$childs/@dots[1]"/>
                    </xsl:if>
                    <xsl:attribute name="measperf" select="$childs[1]/@dur"/>
                    <xsl:attribute name="slash" select="number($childs[1]/@dur) div 8"/>
                    <xsl:attribute name="type" select="'generated'"/>
                    <xsl:attribute name="tempRef" select="$tupletSpan/@xml:id"/>
                    <xsl:apply-templates select="$childs" mode="#current">
                        <xsl:with-param name="overrideDur" select="2" tunnel="yes" as="xs:integer?"/>
                    </xsl:apply-templates>
                </xsl:element>
            </xsl:when>
            <xsl:otherwise>
                <!--<xsl:message terminate="no" select="concat('beam in measure ',$measure/@n,', staff ', ancestor::mei:staff/@n,' seems correct')"/>-->
                <xsl:next-match/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="@dur" mode="core">
        <xsl:param name="overrideDur" tunnel="yes" as="xs:integer?"/>
        <xsl:variable name="val" select="."/>
        <xsl:choose>
            <xsl:when test="exists($overrideDur)">
                <xsl:attribute name="dur" select="$overrideDur"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:attribute name="dur" select="$val"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="@ploc" mode="firstRun"/>
    <xsl:template match="@oloc" mode="firstRun"/>
    
    <xsl:function name="local:getPreJoined" as="xs:integer">
        <xsl:param name="measure"/>
        <xsl:variable name="prev" select="$measure/preceding::mei:measure[1]"/>
        <xsl:choose>
            <xsl:when test="starts-with($prev/@n,'X')">
                <xsl:value-of select="1 + local:getPreJoined($prev)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="0"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function> 
    
    <xsl:function name="local:getDuration" as="xs:double">
        <xsl:param name="elem"/>
        
        <xsl:variable name="baseDur" select="1 div number($elem/@dur)"/>
        
        <xsl:variable name="dotsDur" as="xs:double*">
            <xsl:if test="$elem/@dots">
                <xsl:for-each select="(1 to ($elem/@dots cast as xs:integer))">
                    <xsl:variable name="i" select="."/>
                    <xsl:value-of select="$baseDur div ($i * 2)"/>
                </xsl:for-each>
            </xsl:if>
        </xsl:variable>
        
        <xsl:value-of select="$baseDur + sum($dotsDur)"/>
    </xsl:function>
    
    <xsl:function name="local:getTstamp">
        <xsl:param name="elem"/>
        <xsl:param name="def"/>
        
        <xsl:variable name="eventid" select="$elem/@xml:id"/>
        <xsl:variable name="layer" select="$elem/ancestor::mei:layer"/>
        
        <xsl:variable name="meter.unit" select="$def/@meter.unit"/>
        <xsl:variable name="meter.count" select="$def/@meter.count"/>
        
        <!--  Given a context layer and an @xml:id of a note or rest, 
                    return the timestamp of the note or rest.-->
        <xsl:variable name="base" select="number($meter.unit)"/>
        <xsl:variable name="events">
            <xsl:for-each select="$layer/descendant::mei:space[@dur] | $layer/descendant::mei:note[@dur] | $layer/descendant::mei:rest | $layer/descendant::mei:chord[@dur and not(.//mei:note[@dur])]">
                <!-- Other events that should be considered? -->
                <local:event>
                    <xsl:if test="$eventid = @xml:id">
                        <xsl:attribute name="this">this</xsl:attribute>
                    </xsl:if>
                    <xsl:value-of select="1 div @dur"/>
                </local:event>
                <xsl:if test="@dots">
                    <xsl:variable name="total" select="@dots"/>
                    <xsl:variable name="dur" select="@dur"/>
                    <xsl:call-template name="add_dots">
                        <xsl:with-param name="dur" select="$dur"/>
                        <xsl:with-param name="total" select="$total"/>
                    </xsl:call-template>
                </xsl:if>
                <xsl:if test="descendant::dot">
                    <xsl:variable name="total" select="count(descendant::dot)"/>
                    <xsl:variable name="dur" select="@dur"/>
                    <xsl:call-template name="add_dots">
                        <xsl:with-param name="dur" select="$dur"/>
                        <xsl:with-param name="total" select="$total"/>
                    </xsl:call-template>
                </xsl:if>
            </xsl:for-each>
        </xsl:variable>
        <!--DEBUG<xsl:copy-of select="$events"/>-->
        
        <!--<xsl:value-of select="count($events//local:event[@this])"/>-->
        <xsl:value-of select="(sum($events//local:event[@this]/preceding::local:event) div (1 div $base))+1"/>
    </xsl:function>
    <xsl:template name="add_dots">
        <xsl:param name="dur"/>
        <xsl:param name="total"/>
        
        <!--Given an event's duration and a number of dots, 
                    return the value of the dots-->
        <local:event dot="extradot">
            <xsl:value-of select="1 div ($dur * 2)"/>
        </local:event>
        <xsl:if test="$total != 1">
            <xsl:call-template name="add_dots">
                <xsl:with-param name="dur" select="$dur * 2"/>
                <xsl:with-param name="total" select="$total - 1"/>
            </xsl:call-template>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="mei:fileDesc" mode="core">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*" mode="#current"/>
        </xsl:copy>
        <xsl:if test="not(./following-sibling::mei:encodingDesc)">
          <xsl:call-template name="encodingDesc">
            <xsl:with-param name="createNew" select="boolean('true')"/>
          </xsl:call-template>
        </xsl:if>
        
    </xsl:template>
  
  <xsl:template match="mei:encodingDesc" name="encodingDesc" mode="core">
    <xsl:param name="createNew" select="boolean(())"/>
    <xsl:choose>
      <xsl:when test="$createNew">
        <xsl:element name="encodingDesc" namespace="http://www.music-encoding.org/ns/mei">
          <xsl:element name="appInfo" namespace="http://www.music-encoding.org/ns/mei">
            <xsl:element name="application" namespace="http://www.music-encoding.org/ns/mei">
              <xsl:attribute name="xml:id" select="'improveMusic.xsl'"/>
              <xsl:element name="name" namespace="http://www.music-encoding.org/ns/mei">improveMusic.xsl</xsl:element>
              <xsl:element name="ptr" namespace="http://www.music-encoding.org/ns/mei">
                <xsl:attribute name="target" select="'../xslt/improveMusic.xsl'"/>
              </xsl:element>
            </xsl:element>
          </xsl:element>
        </xsl:element>
      </xsl:when>
      <xsl:otherwise>
        <xsl:copy>
          <xsl:apply-templates select="@*" mode="#current"/>
          <xsl:element name="appInfo" namespace="http://www.music-encoding.org/ns/mei">
            <xsl:element name="application" namespace="http://www.music-encoding.org/ns/mei">
              <xsl:attribute name="xml:id" select="'improveMusic.xsl'"/>
              <xsl:element name="name" namespace="http://www.music-encoding.org/ns/mei">improveMusic.xsl</xsl:element>
              <xsl:element name="ptr" namespace="http://www.music-encoding.org/ns/mei">
                <xsl:attribute name="target" select="'../xslt/improveMusic.xsl'"/>
              </xsl:element>
            </xsl:element>
          </xsl:element>
          <xsl:apply-templates select="node()" mode="#current"/>
        </xsl:copy>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
    
    <xd:doc scope="component">
        <xd:desc>
            <xd:p>mei:revisionDesc gets added a mei:change for application of this stylesheet.</xd:p>
            <xd:ul>
                <xd:li>mei:artic to @artic</xd:li>
                <xd:li>mei:accid to @accid</xd:li>
            </xd:ul>
        </xd:desc>
    </xd:doc>
    <xsl:template match="mei:revisionDesc" mode="core">
        <xsl:copy>
            
            <xsl:apply-templates select="node() | @*" mode="#current"/>
            
            <xsl:element name="change" namespace="http://www.music-encoding.org/ns/mei">
                <xsl:attribute name="n" select="max(mei:change/@n) + 1"/>
                <xsl:element name="respStmt" namespace="http://www.music-encoding.org/ns/mei">
                    <xsl:element name="persName" namespace="http://www.music-encoding.org/ns/mei">
                        <xsl:value-of select="$transformationOperator"/>
                    </xsl:element>
                </xsl:element>
                <xsl:element name="changeDesc" namespace="http://www.music-encoding.org/ns/mei">
                    <xsl:variable name="text">
                        Content of <xsl:value-of select="$fileName"/> processed with <xsl:element name="ref" namespace="http://www.music-encoding.org/ns/mei">
                          <xsl:attribute name="target" select="concat('https://github.com/Detmolder-Hoftheater/Tools/blob/',$FreiDi-Tools_version,'/04%20MEI%20cleaning/improveMusic.xsl')"/>improveMusic.xsl</xsl:element> from Freischütz Digital Tools <xsl:value-of select="$FreiDi-Tools_version"/> in order to resolve mei:bTrems, mei:fTrems, intermediary mei:scoreDefs and mei:staffDef, transform mei:artic and mei:accid to respective attributes, etc.</xsl:variable>
                    
                    <xsl:element name="p" namespace="http://www.music-encoding.org/ns/mei">
                        <xsl:value-of select="normalize-space($text)"/>
                    </xsl:element>
                </xsl:element>
                <xsl:element name="date" namespace="http://www.music-encoding.org/ns/mei">
                    <xsl:attribute name="isodate" select="substring(string(current-date()),1,10)"/>
                </xsl:element>
            </xsl:element>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="mei:mRest/@dur" mode="lastRun"/>
  
    <xsl:template match="mei:mSpace/@dur" mode="lastRun"/>
    
    <xsl:template match="@instr" mode="lastRun"/>
    
    <xsl:template match="mei:staffDef[@n and count(@*) = 1 and not(./node())]" mode="lastRun"/>
    
    <xd:doc scope="component">
        <xd:desc>if all descendant staffDef elements of a scoreDef have no values except @n and soreDef has attributes then copy scoreDef and attributes</xd:desc>
    </xd:doc>
    <xsl:template match="mei:scoreDef[descendant::mei:staffDef[@n and count(@*) = 1 and not(./node())]]" mode="lastRun">
        <xsl:copy>
            <xsl:apply-templates select="@*" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <xd:doc scope="component">
        <xd:desc>Replace general mei-all.rng references with custom freidi-schema reference</xd:desc>
    </xd:doc>
    <xsl:template match="processing-instruction('xml-model')" mode="lastRun">
        <xsl:choose>
          <xsl:when test="$newSchemaRef!=''">
              <xsl:choose>
                <xsl:when test="contains(.,'relaxng')">
                    <xsl:processing-instruction name="xml-model"><xsl:text>href="</xsl:text><xsl:value-of select="$newSchemaRef"/><xsl:text>" type="application/xml" schematypens="http://relaxng.org/ns/structure/1.0"</xsl:text></xsl:processing-instruction>
                </xsl:when>
                <xsl:when test="contains(.,'schematron')">
                    <xsl:processing-instruction name="xml-model"><xsl:text>href="</xsl:text><xsl:value-of select="$newSchemaRef"/><xsl:text>" type="application/xml" schematypens="http://purl.oclc.org/dsdl/schematron"</xsl:text></xsl:processing-instruction>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates select="." mode="#current"/>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:when>
          <xsl:otherwise>
            <xsl:copy/>
          </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
</xsl:stylesheet>