<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    xmlns:mei="http://www.music-encoding.org/ns/mei"
    xmlns:functx="http://www.functx.com"
    exclude-result-prefixes="xs xd functx"
    version="2.0">
    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p><xd:b>Created on:</xd:b> Jan 25, 2013</xd:p>
            <xd:p><xd:b>Author:</xd:b> Johannes Kepper</xd:p>
            <xd:p><xd:b>Documentation:</xd:b> Benjamin W. Bohl</xd:p>
            <xd:p>This stylesheet merges a facsimile-oriented MEI originating from Edirom Editor
                with an encoding of the musical content, derived from Finale, Sibelius. 
                
                It takes two parameters: 
                    $musicDoc holds the path to the MEI file with the musical content
                    $targetMov holds the xml:id of the movement that will be filled with the content
                    
                The file operates on core.xml, and outputs
                    - an updated _core.xml
                    - a ./blueprints/_movN.xml, containing the graphical information to be stored in the sources
                    
            </xd:p>
        </xd:desc>
    </xd:doc>
    
    <xsl:output method="xml" indent="yes" xpath-default-namespace="http://www.music-encoding.org/ns/mei"/>
    
    <xsl:param name="musicDoc" select="'../music/WeGA_C07_Nr.08mei.xml'"/>
    <xsl:param name="targetMov" select="'core_mov8'"/>
    <xsl:param name="bluePrintfile" select="'./blueprints/_mov8.xml'"/>
    
    <xsl:variable name="music" select="doc($musicDoc)//mei:mdiv"/>
    <xsl:variable name="applications" select="doc($musicDoc)//mei:application | //mei:application"/>
    <xsl:variable name="changes" select="doc($musicDoc)//mei:change | //mei:change"/>
    <xsl:variable name="nymRefs" select="//mei:persName/@xml:id"/>
    
    <xd:doc scope="component">
      <xd:desc>
        <xd:p>The root-template checks whether the given input file has the correct xml:id (matching the target movement), and returns a message if not.</xd:p>
        <xd:p>Moreover it launches cration of _core.xml and blueprint output documents</xd:p>
      </xd:desc>
    </xd:doc>
  <xsl:template match="/">
        <xsl:if test="not(//mei:mdiv[@xml:id = $music/@xml:id])">
            <xsl:message select="concat('targetMov: ',$targetMov)"/>
            <xsl:message select="concat('musicMov: ',$music/@xml:id)"/>
            <xsl:message terminate="yes">The mdiv/@xml:id in the musicFile needs to match the targetMov!</xsl:message>
        </xsl:if>
        
        <xsl:apply-templates select="node()" mode="core"/>

        <xsl:variable name="mov" select="substring-after($targetMov,'_')"/>
        <xsl:result-document href="{$bluePrintfile}">
            <!--<xsl:apply-templates select="//mei:mdiv[@xml:id eq $targetMov]" mode="source"/>-->
            <xsl:apply-templates select="$music" mode="source"/>
        </xsl:result-document>
    </xsl:template>
    
  <xd:doc scope="component">
    <xd:desc>
      <xd:p>template for copying mei:change elements assigning new @n values</xd:p>
    </xd:desc>
  </xd:doc>
    <xsl:template match="mei:change" mode="copyChange">
        <xsl:param name="count"/>
        <xsl:copy>
            <xsl:apply-templates select="@* except @n"/>
            <xsl:attribute name="n" select="$count"/>
            <xsl:apply-templates select="node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
  <xd:doc scope="component">
    <xd:desc>
      <xd:p>template adding copying and adding another mei:p element in mei:change if target file is not core.xml to include a hint on which file the change was originally performed</xd:p>
    </xd:desc>
  </xd:doc>
    <xsl:template match="mei:p[ancestor::mei:change]" mode="copyChange">
        <xsl:param name="file" tunnel="yes"/>
        <xsl:copy>
            <xsl:apply-templates select="node()" mode="#current"/>
        </xsl:copy>
        <xsl:if test="$file != 'core.xml'">
            <xsl:element name="p" namespace="http://www.music-encoding.org/ns/mei">
                Originally performed on file <xsl:value-of select="$file"/>, moved to current file on <xsl:value-of select="substring(string(current-date()),1,10)"/>.
            </xsl:element>
        </xsl:if>
    </xsl:template>
    
  <xd:doc scope="component">
    <xd:desc>
      <xd:p>copy mei:revisionDesc and call copyChange with new @n values</xd:p>
      <xd:p>add</xd:p>
    </xd:desc>
  </xd:doc>
    <xsl:template match="mei:revisionDesc" mode="core">
        <xsl:copy>
            
            <xsl:variable name="changeCount" select="count($changes)"/>
            
            <xsl:if test="count($changes) gt 0">
                <xsl:for-each select="(1 to $changeCount)">
                    <xsl:variable name="step" select="."/>
                    <xsl:apply-templates select="$changes[$step]" mode="copyChange">
                        <xsl:with-param name="count" select="."/>
                        <xsl:with-param name="file" select="tokenize(document-uri($changes[$step]/root()),'/')[last()]" tunnel="yes"/>
                    </xsl:apply-templates>
                </xsl:for-each>
            </xsl:if>
            
            <xsl:element name="change" namespace="http://www.music-encoding.org/ns/mei">
                <xsl:attribute name="n" select="$changeCount + 1"/>
                <xsl:element name="respStmt" namespace="http://www.music-encoding.org/ns/mei">
                    <xsl:element name="persName" namespace="http://www.music-encoding.org/ns/mei">
                        <xsl:attribute name="nymref" select="'#smJK'"/>
                    </xsl:element>
                </xsl:element>
                <xsl:element name="changeDesc" namespace="http://www.music-encoding.org/ns/mei">
                    <xsl:element name="p" namespace="http://www.music-encoding.org/ns/mei">
                        Included musical content for #<xsl:value-of select="$targetMov"/> from
                        <xsl:value-of select="$musicDoc"/> using <xsl:element name="ref" namespace="http://www.music-encoding.org/ns/mei">
                            <xsl:attribute name="target" select="'#includeMusic2core.xsl'"/>includeMusic2core.xsl</xsl:element>.
                    </xsl:element>
                </xsl:element>
                <xsl:element name="date" namespace="http://www.music-encoding.org/ns/mei">
                    <xsl:attribute name="isodate" select="substring(string(current-date()),1,10)"/>
                </xsl:element>
            </xsl:element>
        </xsl:copy>
    </xsl:template>
    
    <xd:doc scope="component">
      <xd:desc>
        <xd:p>Add another application entry to mei:appInfo mentioning this stylesheet</xd:p>
      </xd:desc>
    </xd:doc>
  <xsl:template match="mei:appInfo" mode="core">
        <xsl:copy>
            <xsl:apply-templates select="@* | node() | $applications"/>
            <xsl:element name="application" namespace="http://www.music-encoding.org/ns/mei">
                <xsl:attribute name="xml:id" select="'includeMusic2core.xsl'"/>
                <xsl:element name="name" namespace="http://www.music-encoding.org/ns/mei">includeMusic2core.xsl</xsl:element>
                <xsl:element name="ptr" namespace="http://www.music-encoding.org/ns/mei">
                    <xsl:attribute name="target" select="'../xslt/includeMusic2core.xsl'"/>
                </xsl:element>
            </xsl:element>
        </xsl:copy>
    </xsl:template>
    
    <xd:doc scope="component">
      <xd:desc>
        <xd:p>functx function for returning a sequence stripped of a given value</xd:p>
      </xd:desc>
    </xd:doc>
  <xsl:function name="functx:value-except" as="xs:anyAtomicType*" 
        xmlns:functx="http://www.functx.com" >
        <xsl:param name="arg1" as="xs:anyAtomicType*"/> 
        <xsl:param name="arg2" as="xs:anyAtomicType*"/> 
        
        <xsl:sequence select=" 
            distinct-values($arg1[not(.=$arg2)])
            "/>
        
    </xsl:function>
    
  <xd:doc scope="component">
    <xd:desc>
      <xd:p>template for processing the mei:mdiv matching the correct xml:id of the set target movement parameter</xd:p>
    </xd:desc>
  </xd:doc>
    <xsl:template match="mei:mdiv[@xml:id eq $targetMov]" mode="core">
        
        <xsl:variable name="coreMeasureCount" select="count(.//mei:measure)"/>
        <xsl:variable name="musicMeasureCount" select="count($music//mei:measure)"/>
        
        <xsl:variable name="notInCore" select="functx:value-except($music//mei:measure/@xml:id/replace(.,'prefix',$targetMov),.//mei:measure/@xml:id)"/>
        <xsl:variable name="notInMusic" select="functx:value-except(.//mei:measure/@xml:id, $music//mei:measure/@xml:id/replace(.,'prefix',$targetMov))"/>
        
        
        <xsl:message>core.xml contains <xsl:value-of select="$coreMeasureCount"/> measures, <xsl:value-of select="$musicMeasureCount"/> of them are mapped to the music file.</xsl:message>
        <xsl:if test="count($notInCore) gt 0">
            <xsl:message terminate="yes">The following measures from <xsl:value-of select="$musicDoc"/> have no corresponding measure in core.xml: <xsl:value-of select="string-join($notInCore,', ')"/>.</xsl:message>
        </xsl:if>
        <xsl:if test="count($notInMusic) gt 0">
            <xsl:message terminate="yes">The following measures from core.xml have no corresponding measure in  <xsl:value-of select="$musicDoc"/>: <xsl:value-of select="string-join($notInMusic,', ')"/>.</xsl:message>
        </xsl:if>
        <xsl:copy>
            <xsl:apply-templates select="@*" mode="core"/>
            <xsl:apply-templates select="($music//mei:score)[1]" mode="core"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="mei:mdiv[@xml:id != $targetMov]" mode="#all">
        <xsl:copy-of select="."/>
    </xsl:template>
    
    <xsl:template match="mei:measure" mode="core">
        
        <!--<xsl:message select="concat('processing measure ',@xml:id, ' in core mode')"/>-->
        
        <xsl:variable name="id" select="replace(@xml:id,'prefix',$targetMov)"/>
        <xsl:variable name="facsMeasure" select="//mei:measure[@xml:id = $id]"/>
        
        <xsl:if test="$facsMeasure">
            <xsl:message>No equivalent in original file for measure <xsl:value-of select="$id"/>.</xsl:message>
        </xsl:if>
        <xsl:copy>
            <xsl:attribute name="xml:id" select="$id"/>
            <xsl:apply-templates select="@* except @xml:id" mode="core"/>
            
            <xsl:apply-templates select="$facsMeasure/@join" mode="core"/>
            <xsl:apply-templates select="$facsMeasure/@sameas" mode="core"/>
            
            <xsl:apply-templates select="node()" mode="core">
                <xsl:with-param name="measureID" select="substring-after(@xml:id,'measure')" tunnel="yes"/>
            </xsl:apply-templates>
        </xsl:copy>
        
    </xsl:template>
    
    
    <!--<xsl:template match="mei:score" mode="source">
        <!-\-<xsl:apply-templates select="($music//mei:score)[1]" mode="source"/>-\->
        <xsl:copy/>
        <xsl:message>Stopped at score</xsl:message>
    </xsl:template>-->
    
    <xsl:template match="mei:measure" mode="source">
        
        <!--<xsl:message select="concat('processing measure ',@xml:id, ' in source mode')"/>-->
        
        <xsl:variable name="id" select="replace(@xml:id,'prefix',$targetMov)"/>
        <xsl:variable name="facsMeasure" select="//mei:measure[@xml:id = $id]"/>
        
        
        <xsl:copy>
            <xsl:attribute name="xml:id" select="$id"/>
            <xsl:apply-templates select="@* except @xml:id" mode="source"/>
            
            <xsl:apply-templates select="$facsMeasure/@* except $facsMeasure/@xml:id" mode="source"/>
            
            <xsl:if test="$facsMeasure//mei:mRest">
                <xsl:attribute name="subtype" select="'mRest'"/>
            </xsl:if>
            <xsl:if test="$facsMeasure//mei:multiRest">
                <xsl:attribute name="subtype" select="concat('multiRest(',.//mei:multiRest/@num,')')"/>
            </xsl:if>
            
            <xsl:apply-templates select="node() except @*" mode="source">
                <xsl:with-param name="measureID" tunnel="yes" select="substring-after(@xml:id,'measure')"/>
            </xsl:apply-templates>
            
        </xsl:copy>
    </xsl:template>
    
    
    <xsl:template match="mei:staffDef/@xml:id" mode="#all"/>
    <xsl:template match="mei:staffGrp/@xml:id" mode="#all"/>
    
    <xsl:template match="mei:measure/node()//@xml:id" mode="core">
        <xsl:param name="measureID" tunnel="yes"/>
        
        <xsl:choose>
            <xsl:when test="not(ancestor::mei:scoreDef) and not(ancestor::mei:staffDef)">
                <xsl:variable name="staffN" select="ancestor::mei:staff/@n"/>
                
                <xsl:variable name="layerN" select="count(ancestor::mei:layer/preceding-sibling::mei:layer) + 1"/>
                
                <xsl:variable name="ids" select="ancestor::mei:layer//@xml:id" as="xs:string*"/>
                <xsl:variable name="idPos" select="if(count($ids) gt 0) then(index-of($ids,.)) else('')"/>
                
                <xsl:attribute name="xml:id" select="concat($targetMov,'_measure',$measureID,'_s',$staffN,'l',$layerN,'_e',$idPos)"/>
            </xsl:when>
            <xsl:otherwise>
                
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="mei:measure//@xml:id" mode="source">
        <xsl:param name="measureID" tunnel="yes"/>
        
        <xsl:choose>
            <xsl:when test="not(ancestor::mei:scoreDef) and not(ancestor::mei:staffDef)">
                <xsl:variable name="staffN" select="ancestor::mei:staff/@n"/>
                
                <xsl:variable name="layerN" select="count(ancestor::mei:layer/preceding-sibling::mei:layer) + 1"/>
                
                <xsl:variable name="ids" select="ancestor::mei:layer//@xml:id" as="xs:string*"/>
                <xsl:variable name="idPos" select="if(count($ids) gt 0) then(index-of($ids,.)) else('')"/>
                
                <xsl:attribute name="xml:id" select="concat(replace($targetMov,'core','source'),'_measure',$measureID,'_s',$staffN,'l',$layerN,'_e',$idPos)"/>
                <xsl:attribute name="sameas" select="concat('../core.xml#',$targetMov,'_measure',$measureID,'_s',$staffN,'l',$layerN,'_e',$idPos)"/>
            </xsl:when>
            <xsl:otherwise>
                
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xd:doc scope="component">
      <xd:desc>
        <xd:p>template for @startid in measures in mode="core"</xd:p>
      </xd:desc>
    </xd:doc>
  <xsl:template match="mei:measure//@startid" mode="core">
        <xsl:variable name="ref" select="if(starts-with(.,'#')) then(substring(.,2)) else(.)"/>
        <xsl:variable name="target" select="$music/id($ref)"/>
        
        <xsl:variable name="measure" select="$target/ancestor::mei:staff/parent::mei:measure"/>
        <xsl:variable name="staffN" select="$target/ancestor::mei:staff/@n"/>
        
        <xsl:variable name="layerN" select="count(ancestor::mei:layer/preceding-sibling::mei:layer) + 1"/>
        
        <xsl:variable name="ids" select="$target/ancestor::mei:layer//@xml:id" as="xs:string*"/>
        <xsl:variable name="idPos" select="if(count($ids) gt 0) then(index-of($ids,$ref)) else('')"/>
        
        <xsl:attribute name="startid" select="concat('#',$targetMov,'_measure',$measure/@n,'_s',$staffN,'l',$layerN,'_e',$idPos)"/>
    </xsl:template>
    
  <xd:doc scope="component">
    <xd:desc>
      <xd:p>template for @startid in measures in mode="source"</xd:p>
    </xd:desc>
  </xd:doc>
    <xsl:template match="mei:measure//@startid" mode="source">
        <xsl:variable name="ref" select="if(starts-with(.,'#')) then(substring(.,2)) else(.)"/>
        <xsl:variable name="target" select="$music/id($ref)"/>
        
        <xsl:variable name="measure" select="$target/ancestor::mei:staff/parent::mei:measure"/>
        <xsl:variable name="staffN" select="$target/ancestor::mei:staff/@n"/>
        
        <xsl:variable name="layerN" select="count(ancestor::mei:layer/preceding-sibling::mei:layer) + 1"/>
        
        <xsl:variable name="ids" select="$target/ancestor::mei:layer//@xml:id" as="xs:string*"/>
        <xsl:variable name="idPos" select="if(count($ids) gt 0) then(index-of($ids,$ref)) else('')"/>
        
        <xsl:attribute name="startid" select="concat('#',replace($targetMov,'core','source'),'_measure',$measure/@n,'_s',$staffN,'l',$layerN,'_e',$idPos)"/>
    </xsl:template>
    
  <xd:doc scope="component">
    <xd:desc>
      <xd:p>template for @endid in measures in mode="core"</xd:p>
    </xd:desc>
  </xd:doc>
    <xsl:template match="mei:measure//@endid" mode="core">
        <xsl:variable name="ref" select="if(starts-with(.,'#')) then(substring(.,2)) else(.)"/>
        <xsl:variable name="target" select="$music/id($ref)"/>
        
        <xsl:variable name="measure" select="$target/ancestor::mei:staff/parent::mei:measure"/>
        <xsl:variable name="staffN" select="$target/ancestor::mei:staff/@n"/>
        
        <xsl:variable name="layerN" select="count(ancestor::mei:layer/preceding-sibling::mei:layer) + 1"/>
        
        <xsl:variable name="ids" select="$target/ancestor::mei:layer//@xml:id" as="xs:string*"/>
        <xsl:variable name="idPos" select="if(count($ids) gt 0) then(index-of($ids,$ref)) else('')"/>
        
        
        <xsl:attribute name="endid" select="concat('#',$targetMov,'_measure',$measure/@n,'_s',$staffN,'l',$layerN,'_e',$idPos)"/>
    </xsl:template>
    
  <xd:doc scope="component">
    <xd:desc>
      <xd:p>template for @endid in measures in mode="source"</xd:p>
    </xd:desc>
  </xd:doc>
    <xsl:template match="mei:measure//@endid" mode="source">
        <xsl:variable name="ref" select="if(starts-with(.,'#')) then(substring(.,2)) else(.)"/>
        <xsl:variable name="target" select="$music/id($ref)"/>
        
        <xsl:variable name="measure" select="$target/ancestor::mei:staff/parent::mei:measure"/>
        <xsl:variable name="staffN" select="$target/ancestor::mei:staff/@n"/>
        
        <xsl:variable name="layerN" select="count(ancestor::mei:layer/preceding-sibling::mei:layer) + 1"/>
        
        <xsl:variable name="ids" select="$target/ancestor::mei:layer//@xml:id" as="xs:string*"/>
        <xsl:variable name="idPos" select="if(count($ids) gt 0) then(index-of($ids,$ref)) else('')"/>
        
        <xsl:attribute name="endid" select="concat('#',replace($targetMov,'core','source'),'_measure',$measure/@n,'_s',$staffN,'l',$layerN,'_e',$idPos)"/>
    </xsl:template>
    
  <xd:doc scope="component">
    <xd:desc>
      <xd:p>template for @corresp in measures in mode="core"</xd:p>
    </xd:desc>
  </xd:doc>
    <xsl:template match="mei:measure//@corresp" mode="core">
        <xsl:variable name="ref" select="if(starts-with(.,'#')) then(substring(.,2)) else(.)"/>
        <xsl:variable name="target" select="$music/id($ref)"/>
        
        <xsl:variable name="measure" select="$target/ancestor::mei:staff/parent::mei:measure"/>
        <xsl:variable name="staffN" select="$target/ancestor::mei:staff/@n"/>
        
        <xsl:variable name="layerN" select="count(ancestor::mei:layer/preceding-sibling::mei:layer) + 1"/>
        
        <xsl:variable name="ids" select="$target/ancestor::mei:layer//@xml:id" as="xs:string*"/>
        <xsl:variable name="idPos" select="if(count($ids) gt 0) then(index-of($ids,$ref)) else('')"/>
        
        <xsl:attribute name="corresp" select="concat('#',$targetMov,'_measure',$measure/@n,'_s',$staffN,'l',$layerN,'_e',$idPos)"/>
    </xsl:template>
    
  <xd:doc scope="component">
    <xd:desc>
      <xd:p>template for @corresp in measures in mode="source"</xd:p>
    </xd:desc>
  </xd:doc>
    <xsl:template match="mei:measure//@corresp" mode="source">
        <xsl:variable name="ref" select="if(starts-with(.,'#')) then(substring(.,2)) else(.)"/>
        <xsl:variable name="target" select="$music/id($ref)"/>
        
        <xsl:variable name="measure" select="$target/ancestor::mei:staff/parent::mei:measure"/>
        <xsl:variable name="staffN" select="$target/ancestor::mei:staff/@n"/>
        
        <xsl:variable name="layerN" select="count(ancestor::mei:layer/preceding-sibling::mei:layer) + 1"/>
        
        <xsl:variable name="ids" select="$target/ancestor::mei:layer//@xml:id" as="xs:string*"/>
        <xsl:variable name="idPos" select="if(count($ids) gt 0) then(index-of($ids,$ref)) else('')"/>
        
        <xsl:attribute name="corresp" select="concat('#',replace($targetMov,'core','source'),'_measure',$measure/@n,'_s',$staffN,'l',$layerN,'_e',$idPos)"/>
    </xsl:template>
    
    
    <!-- TODO: are there any plists? -->
    
    
  <xd:doc scope="component">
    <xd:desc>
      <xd:p>template handling mei:staff element children of mei:measure in mode="core"</xd:p>
    </xd:desc>
  </xd:doc>
    <xsl:template match="mei:measure/mei:*[not(local-name() eq 'staff')]" mode="core">
        <xsl:param name="measureID" tunnel="yes"/>
        
        <xsl:choose>
            <xsl:when test="local-name() != 'fermata'">
                <xsl:copy>
                    <xsl:apply-templates select="@*" mode="#current"/>
                    
                    <xsl:variable name="pos" select="count(preceding-sibling::mei:*[not(local-name() eq 'staff')]) + 1"/>
                    
                    <xsl:attribute name="xml:id" select="concat($targetMov,'_measure',$measureID,'_ce',$pos)"/>
                    
                    <xsl:apply-templates select="node()" mode="#current"/>
                </xsl:copy>
            </xsl:when>
            <xsl:otherwise>
                <xsl:if test="not(exists(id(substring(@startid,2))))">
                    <xsl:message terminate="yes" select="concat('lost fermata on ',@startid)"/>
                </xsl:if>
            </xsl:otherwise>
        </xsl:choose>
        
    </xsl:template>
    
  <xd:doc scope="component">
    <xd:desc>
      <xd:p>template handling mei:staff element children of mei:measure in mode="source"</xd:p>
    </xd:desc>
  </xd:doc>
    <xsl:template match="mei:measure/mei:*[not(local-name() eq 'staff')]" mode="source">
        <xsl:param name="measureID" tunnel="yes"/>
        
        <xsl:choose>
            <xsl:when test="local-name() != 'fermata'">
                <xsl:copy>
                    <xsl:apply-templates select="@*" mode="#current"/>
                    
                    <xsl:variable name="pos" select="count(preceding-sibling::mei:*[not(local-name() eq 'staff')]) + 1"/>
                    
                    <xsl:attribute name="xml:id" select="concat(replace($targetMov,'core','source'),'_measure',$measureID,'_ce',$pos)"/>
                    <xsl:attribute name="sameas" select="concat('../core.xml#',$targetMov,'_measure',$measureID,'_ce',$pos)"/>
                    
                    <xsl:apply-templates select="node()" mode="#current"/>
                </xsl:copy>
            </xsl:when>
            <xsl:otherwise>
                <xsl:if test="not(exists(id(substring(@startid,2))))">
                    <xsl:message terminate="yes" select="concat('lost fermata on ',@startid)"/>
                </xsl:if>
            </xsl:otherwise>
        </xsl:choose>
        
    </xsl:template>
    
  <xd:doc scope="component">
    <xd:desc>
      <xd:p>templates for ignoring attributes</xd:p>
    </xd:desc>
  </xd:doc>
    <!-- Attributes ignored in all files: -->
    <xsl:template match="@dur.ges" mode="#all"/>
    <xsl:template match="@midi.channel" mode="#all"/>
    <xsl:template match="@midi.instrnum" mode="#all"/>
    <xsl:template match="mei:instrDef" mode="#all"/>
    <xsl:template match="mei:measure/@width" mode="#all"/>
    <xsl:template match="@page.height" mode="#all"/>
    <xsl:template match="@page.width" mode="#all"/>
    <xsl:template match="@page.leftmar" mode="#all"/>
    <xsl:template match="@page.rightmar" mode="#all"/>
    <xsl:template match="@page.topmar" mode="#all"/>
    <xsl:template match="@page.botmar" mode="#all"/>
    <xsl:template match="@system.topmar" mode="#all"/>
    <xsl:template match="@system.leftmar" mode="#all"/>
    <xsl:template match="@system.rightmar" mode="#all"/>
    <xsl:template match="@ppq" mode="#all"/>
    <xsl:template match="@spacing" mode="#all"/>
    <xsl:template match="@spacing.system" mode="#all"/>
    <xsl:template match="@spacing.staff" mode="#all"/>
    <xsl:template match="@page.units" mode="#all"/>
    <xsl:template match="@page.scale" mode="#all"/>
    <xsl:template match="@music.name" mode="#all"/>
    <xsl:template match="@music.size" mode="#all"/>
    <xsl:template match="@text.name" mode="#all"/>
    <xsl:template match="@text.size" mode="#all"/>
    <xsl:template match="@lyric.name" mode="#all"/>
    <xsl:template match="@lyric.size" mode="#all"/>
    <xsl:template match="@fontsize" mode="#all"/>
    <xsl:template match="mei:accid" mode="#all"/>
    <xsl:template match="mei:artic" mode="#all"/>
    <xsl:template match="@stem.y" mode="#all"/>
    <xsl:template match="@opening" mode="#all"/>
    <xsl:template match="mei:dynam/text()" mode="#all">
        <xsl:value-of select="replace(.,'(^\s+)|(\s+$)','')"></xsl:value-of>
    </xsl:template>
    <xsl:template match="mei:slur/@tstamp" mode="#all"/>
    <xsl:template match="mei:slur/@tstamp2" mode="#all"/>
    
    <!-- Attributes ignored in the core -->
    <xsl:template match="@startto" mode="core"/>
    <xsl:template match="@endto" mode="core"/>
    <xsl:template match="@ho" mode="core"/>
    <xsl:template match="@vo" mode="core"/>
    <xsl:template match="@stem.dir" mode="core"/>
    <xsl:template match="@curvedir" mode="core"/>
    <xsl:template match="@place" mode="core"/>
    
    <!-- Attributes ignored in the sources -->
    <xsl:template match="@pname" mode="source"/>
    <xsl:template match="@oct" mode="source"/>
    <xsl:template match="@dur" mode="source">
        <xsl:if test="local-name(parent::node()) = 'hairpin'">
            <xsl:copy-of select="."/>
        </xsl:if>
    </xsl:template>
    <xsl:template match="@accid" mode="source"/>
    <xsl:template match="@accid.ges" mode="source"/>
    <xsl:template match="@dots" mode="source"/>
    <xsl:template match="@stem.mod" mode="source"/>
    
    
    <xd:doc scope="component">
      <xd:desc>
        <xd:p>A general copy template applying xsl:copy to all nodes incuding attributes.</xd:p>
      </xd:desc>
    </xd:doc>
  <xsl:template match="node() | @*" mode="#all">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
</xsl:stylesheet>