<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    xmlns:mei="http://www.music-encoding.org/ns/mei"
    exclude-result-prefixes="xs xd"
    version="2.0">
    
    <xsl:include href="../global-parameters.xsl"/>
  
    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p><xd:b>Created on:</xd:b> Mar 8, 2013</xd:p>
            <xd:p><xd:b>Author:</xd:b> Johannes Kepper</xd:p>
            <xd:p><xd:b>Documentation:</xd:b> Benjamin W. Bohl</xd:p>
            <xd:p>This stylesheet incorporates the music encoding available from a 
                blueprint file for a given movement into a source document. At the 
                same time, it adds zones for all contained staff elements.</xd:p>
          <xd:p>Has to be applied to the target source file</xd:p>
        </xd:desc>
    </xd:doc>
    
    <xsl:output indent="yes" method="xml"/>
    
    <xd:doc scope="component">
      <xd:desc>
        <xd:p>This parameter defines the relative path to the blueprint file which contains the music data for the respective movement (the pointers to the core)</xd:p>
      </xd:desc>
    </xd:doc>
  <xsl:param name="path" select="'../blueprints/_mov8.xml'"/>
  
  <xd:doc scope="component">
    <xd:desc>
      <xd:p>This parameter hold the xml:id of the movenment to be updated</xd:p>
    </xd:desc>
  </xd:doc>
    <xsl:param name="movNo" select="'KA9_mov8'"/>
    
    
    <xsl:variable name="musicDoc" select="doc($path)"/>
    <xsl:variable name="siglum" select="/mei:mei/@xml:id"/>
    <xsl:variable name="movID" select="concat($siglum, '_', $movNo)"/>
    
    <xsl:variable name="measures" select="//mei:mdiv[@xml:id = $movID]//mei:measure"/>
    
  <xd:doc scope="component">
    <xd:desc>
      <xd:p>Root template trigger creation of _SIGLUM.xml file</xd:p>
    </xd:desc>
  </xd:doc>
    <xsl:template match="/">
        <xsl:apply-templates/>
    </xsl:template>
    
    <xsl:template match="mei:appInfo">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*"/>
            
            <xsl:if test="not(mei:application[@xml:id = 'includeMusic2source.xsl'])">
                <xsl:element name="application" namespace="http://www.music-encoding.org/ns/mei">
                    <xsl:attribute name="xml:id" select="'includeMusic2source.xsl'"/>
                    <xsl:element name="name" namespace="http://www.music-encoding.org/ns/mei">includeMusic2source.xsl</xsl:element>
                    <xsl:element name="ptr" namespace="http://www.music-encoding.org/ns/mei">
                        <xsl:attribute name="target" select="'../xslt/includeMusic2source.xsl'"/>
                    </xsl:element>
                    
                </xsl:element>    
            </xsl:if>
            
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="mei:revisionDesc">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*"/>
        
            <xsl:variable name="maxN" select="max(.//mei:change/number(@n))"/>
            
            <xsl:element name="change" namespace="http://www.music-encoding.org/ns/mei">
                <xsl:attribute name="n" select="$maxN + 1"/>
                <xsl:element name="respStmt" namespace="http://www.music-encoding.org/ns/mei">
                    <xsl:element name="persName" namespace="http://www.music-encoding.org/ns/mei">
                      <xsl:value-of select="$transformationOperator"/>
                    </xsl:element>
                </xsl:element>
                <xsl:element name="changeDesc" namespace="http://www.music-encoding.org/ns/mei">
                    <xsl:element name="p" namespace="http://www.music-encoding.org/ns/mei">
                        Included musical content for #<xsl:value-of select="$movID"/> from
                      <xsl:value-of select="$path"/> using <xsl:element name="ref" namespace="http://www.music-encoding.org/ns/mei">
                        <xsl:attribute name="target" select="concat('https://github.com/Freischuetz-Digital/Tools/blob/',$FreiDi-Tools_version,'/06.2%20Include%20Music%20in%20Sources/includeMusic2source.xsl')"/>includeMusic2source.xsl</xsl:element> from Freischütz Digital Tools <xsl:value-of select="$FreiDi-Tools_version"/>.
                    </xsl:element>
                </xsl:element>
                <xsl:element name="date" namespace="http://www.music-encoding.org/ns/mei">
                    <xsl:attribute name="isodate" select="substring(string(current-date()),1,10)"/>
                </xsl:element>
            </xsl:element>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="mei:mdiv[@xml:id eq $movID]//mei:score">
        <!--<xsl:variable name="preScoreDefs" select="count(preceding-sibling::mei:scoreDef)"/>-->
        <xsl:apply-templates select="$musicDoc//mei:score"/>
    </xsl:template>
    
    <xsl:template match="mei:mdiv[not(@xml:id = $movID)]">
        <xsl:copy-of select="."/>
    </xsl:template>
    
    <xd:doc scope="component">
        <xd:p>
            Searching for measure in source that points to the right measure in the core.
        </xd:p>
    </xd:doc>
    <xsl:template match="mei:measure">
        
        <xsl:message select="concat('processing measure with ID: ',@xml:id)"/>
        
        <xsl:variable name="coreID" select="@xml:id"/>
        <!-- $coreID: core_mov4_measure2 -->
        
        <xsl:variable name="sourceID" select="concat($movID,'_measure',substring-after(@xml:id,'_measure'))"/>
        <!-- A_mov0 + _measure + 2 -->
        
        
        <xsl:variable name="facsMeasure" select="$measures[contains(@sameas,concat($coreID,' ')) or ends-with(@sameas,$coreID)]"/>
        
        <xsl:if test="exists($facsMeasure)">
            <xsl:copy>
                <xsl:attribute name="xml:id" select="$sourceID"/>
                
                <xsl:apply-templates select="$facsMeasure/@* except $facsMeasure/@xml:id"/>
                <xsl:apply-templates select="@* except (@xml:id,@sameas)"/>
                <xsl:attribute name="sameas" select="tokenize($facsMeasure/@sameas,' ')[ends-with(.,$coreID)]"/>
                
                <xsl:apply-templates select="node()" mode="copyMusic"/>
            </xsl:copy>    
        </xsl:if>
        
        
    </xsl:template>
    
    <xsl:template match="mei:staff" mode="copyMusic">
        <xsl:variable name="id" select="concat($siglum,'_',substring-after(parent::mei:measure/@xml:id,'_'),'_s',@n)"/>
        <xsl:variable name="facs" select="concat('#',$siglum,'_zoneOf_',substring-after(parent::mei:measure/@xml:id,'_'),'_s',@n)"/>
        
        <xsl:copy>
            <xsl:attribute name="xml:id" select="$id"/>
            <xsl:apply-templates select="@*"/>
            <xsl:attribute name="facs" select="$facs"/>
            
            
            
            <xsl:apply-templates select="node()" mode="copyMusic"/>
            
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="mei:zone[@type = 'measure']">
        <xsl:copy-of select="."/>
        <xsl:if test="substring-before(substring-after(@data,'_'),'_') = substring-after($movID,'_')">
        
            <xsl:variable name="measureID" select="substring(@data,2)"/>
            <xsl:variable name="lookupID" select="replace($measureID,$siglum,'core')"/>
            <xsl:variable name="measure" select="$musicDoc/id($lookupID)"/>
            
            <xsl:variable name="ulx" select="@ulx" as="xs:integer"/>
            <xsl:variable name="uly" select="@uly" as="xs:integer"/>
            <xsl:variable name="lrx" select="@lrx" as="xs:integer"/>
            <xsl:variable name="lry" select="@lry" as="xs:integer"/>
            
            <xsl:variable name="staffCount" select="if(count($measure/mei:staff) gt 0) then(count($measure/mei:staff)) else(1)" as="xs:integer"/>
            
            <xsl:variable name="normHeight" select="round(($lry - $uly) div $staffCount) cast as xs:integer" as="xs:integer"/>
            <xsl:variable name="margin" select="round($normHeight div 4) cast as xs:integer" as="xs:integer"/>
            
            <xsl:for-each select="$measure/mei:staff">
                
                <xsl:variable name="staffN" select="@n"/>
                <xsl:variable name="staffZoneID" select="concat(replace($measureID,$siglum,concat($siglum,'_zoneOf')),'_s',$staffN)"/>
                <xsl:variable name="pos" select="position()" as="xs:integer" />
                
                <xsl:element name="zone" namespace="http://www.music-encoding.org/ns/mei">
                    <xsl:attribute name="id" namespace="http://www.w3.org/XML/1998/namespace" select="$staffZoneID"/>
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
                    <xsl:attribute name="data" select="concat('#',$measureID,'_s',$staffN)"/>
                </xsl:element>
            </xsl:for-each>
            
            <xsl:variable name="otherMeasures" select="tokenize(id($measureID)/@sameas,' ')[not(. = concat('../core.xml#',$lookupID))]"/>
            
            <xsl:for-each select="$otherMeasures">
                <xsl:message>The measure <xsl:value-of select="$measureID"/> requires more than just one zone.</xsl:message>
            </xsl:for-each>
            
            <xsl:if test="count($otherMeasures) gt 0">
                <xsl:message>The measure <xsl:value-of select="$measureID"/> requires more than just one zone.</xsl:message>
            </xsl:if>
            
        </xsl:if>
        
    </xsl:template>
    
    <xd:doc scope="component">
      <xd:desc>This templates preexisting zone[@type='staff'] for the movement currently being processed</xd:desc>
    </xd:doc>
  <xsl:template match="mei:zone[@type='staff']">
      <xsl:choose>
        <xsl:when test="starts-with(@xml:id,concat(substring-before($movID,'_'),'_zoneOf_',substring-after($movID,'_')))"/>
        <xsl:otherwise>
          <xsl:copy-of select="."/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:template>
    
    <xsl:template match="mei:measure//@xml:id" mode="copyMusic">
        <xsl:attribute name="xml:id" select="replace(.,'source',$siglum)"/>
    </xsl:template>
    
    <xsl:template match="mei:measure//@startid" mode="copyMusic">
        <xsl:attribute name="startid" select="replace(.,'source',$siglum)"/>
    </xsl:template>
    
    <xsl:template match="mei:measure//@endid" mode="copyMusic">
        <xsl:attribute name="endid" select="replace(.,'source',$siglum)"/>
    </xsl:template>
    
    <xsl:template match="node() | @*" mode="#all">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
</xsl:stylesheet>