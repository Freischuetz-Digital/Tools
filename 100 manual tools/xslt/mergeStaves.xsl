<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:math="http://www.w3.org/2005/xpath-functions/math"
  xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
  xmlns:mei="http://www.music-encoding.org/ns/mei"
  exclude-result-prefixes="xs math xd mei"
  version="3.0">
  <xd:doc scope="stylesheet">
    <xd:desc>
      <xd:p><xd:b>Created on:</xd:b> Nov 10, 2014</xd:p>
      <xd:p><xd:b>Author:</xd:b> Johannes Kepper</xd:p>
      <xd:p>
        Merge two staves in one. The staff provided with $secondStaff.n is merged into $firstStaff.n
      </xd:p>
    </xd:desc>
  </xd:doc>
  
  <xsl:output method="xml" indent="yes"/>
  
  <xsl:param name="firstStaff.n" select="4" as="xs:integer"/>
  <xsl:param name="secondStaff.n" select="5" as="xs:integer"/>
  
  <xsl:param name="staff.diff" select="-1" as="xs:integer?"/>
  <xsl:param name="staff.adjust.above" select="5" as="xs:integer?"/>
  <xsl:param name="staff.adjust.below" as="xs:integer?"/>
  
  <xsl:variable name="firstStaff.maxLayers" select="max(//mei:staff[@n = $firstStaff.n]/count(./mei:layer))" as="xs:integer"/>
  <xsl:variable name="secondStaff.maxLayers" select="max(//mei:staff[@n = $secondStaff.n]/count(./mei:layer))" as="xs:integer"/>
    
  <xsl:template match="/">
    
    <xsl:variable name="potentialConflicts" select="//mei:measure[./mei:staff[@n = $firstStaff.n and .//mei:note] and ./mei:staff[@n = $secondStaff.n and .//mei:note]]" as="node()*"/>
    
    <xsl:if test="count($potentialConflicts) gt 0">
      <xsl:message select="'There seem to be measures (' || string-join($potentialConflicts/@xml:id, ', ') || ') in which both staves contain music. Is this correct? Please check the file manually afterwards for any potential conflicts.'"/>
    </xsl:if>
    
    <xsl:variable name="firstRun" as="node()*">
      <xsl:apply-templates mode="firstRun">
        <xsl:with-param name="potentialConflicts" select="$potentialConflicts" tunnel="yes" as="node()*"/>
      </xsl:apply-templates>  
    </xsl:variable>
    
    <xsl:choose>
      <xsl:when test="$staff.diff and $staff.adjust.above">
        <xsl:apply-templates select="$firstRun" mode="secondRun"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:copy-of select="$firstRun"/>
      </xsl:otherwise>
    </xsl:choose>
    
  </xsl:template>
  
  <xsl:template match="mei:staffDef[ancestor::mei:scoreDef and @n = $firstStaff.n]" mode="firstRun">
    
    <xsl:variable name="firstStaffDef" select="." as="node()"/>
    <xsl:variable name="secondStaffDef" select="ancestor::mei:staffGrp[parent::mei:scoreDef]//mei:staffDef[@n = $secondStaff.n]" as="node()"/>
    
    <xsl:if test="mei:layerDef | $secondStaffDef/mei:layerDef">
      <xsl:message terminate="yes">There are already layerDefs. Please check manually and improve this stylesheet :-)</xsl:message>
    </xsl:if>
    
    <xsl:variable name="firstStaff.atts" select="(@* except (@xml:id,@label,@label.abbr, @n, @trans.diat, @trans.semi))"/>
    <xsl:variable name="secondStaff.atts" select="$secondStaffDef/(@* except (@xml:id,@label,@label.abbr, @n, @trans.diat, @trans.semi))"/>
    
    <xsl:choose>
      <xsl:when test="(every $att in $firstStaff.atts satisfies $att = $secondStaff.atts) and (every $att in $secondStaff.atts satisfies $att = $firstStaff.atts)">
        <xsl:copy>
          <xsl:apply-templates select="(@* except (@label,@label.abbr))"/>
          
          
          
          <xsl:for-each select="(1 to $firstStaff.maxLayers)">
            <layerDef xmlns="http://www.music-encoding.org/ns/mei">
              <xsl:variable name="num" select="." as="xs:integer"/>
              <xsl:attribute name="n" select="$num"/>
              <xsl:apply-templates select="$firstStaffDef/(@label, @label.abbr, @trans.diat, @trans.semi)"/>
            </layerDef>
          </xsl:for-each>
          
          <xsl:for-each select="($firstStaff.maxLayers + 1 to $firstStaff.maxLayers + $secondStaff.maxLayers)">
            <layerDef xmlns="http://www.music-encoding.org/ns/mei">
              <xsl:variable name="num" select="." as="xs:integer"/>
              <xsl:attribute name="n" select="$num"/>
              <xsl:apply-templates select="$secondStaffDef/(@label, @label.abbr, @trans.diat, @trans.semi)"/>
            </layerDef>
          </xsl:for-each>
          
        </xsl:copy>    
      </xsl:when>
      <xsl:otherwise>
        <xsl:message terminate="yes">The stylesheet doesn't cover differing staffDefs (yet).</xsl:message>
      </xsl:otherwise>
    </xsl:choose>
    
  </xsl:template>
  
  <xsl:template match="mei:staffDef[ancestor::mei:scoreDef and @n = $secondStaff.n]" mode="firstRun"/>
  
  <xsl:template match="mei:staffDef[@n = $secondStaff.n]">
    <xsl:copy>
      <xsl:apply-templates select="@* except (@n,@xml:id)"/>
      <xsl:variable name="id" select="if(@xml:id) then(@xml:id) else(generate-id(.))"/>
      <xsl:attribute name="xml:id" select="$id"/>
      <xsl:attribute name="n" select="$firstStaff.n"/>
      <xsl:apply-templates select="node()"/>
      <xsl:message select="'changed @n of staffDef(@xml:id=' || $id || ') from staff ' || $secondStaff.n || ' to ' || $firstStaff.n"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="mei:staff[@n = $firstStaff.n]" mode="firstRun">
    <xsl:variable name="firstStaff" select="." as="node()"/>
    <xsl:variable name="secondStaff" select="parent::mei:measure/mei:staff[@n = $secondStaff.n]" as="node()"/>
    
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      
      <xsl:variable name="layers" as="node()*">
        <xsl:for-each select="(1 to $firstStaff.maxLayers)">
          <xsl:variable name="num" select="."/>
          <xsl:apply-templates select="$firstStaff/mei:layer[$num]" mode="setN">
            <xsl:with-param name="newNum" select="$num" tunnel="yes"/>
          </xsl:apply-templates>
        </xsl:for-each>
        
        <xsl:for-each select="(1 to $secondStaff.maxLayers)">
          <xsl:variable name="num" select="."/>
          <xsl:apply-templates select="$secondStaff/mei:layer[$num]" mode="setN">
            <xsl:with-param name="newNum" select="$firstStaff.maxLayers + $num" tunnel="yes"/>
          </xsl:apply-templates>
        </xsl:for-each>  
      </xsl:variable>
      
      <xsl:choose>
        <xsl:when test="every $elem in $layers//mei:*[parent::mei:layer] satisfies local-name($elem) = 'mRest'">
          <xsl:apply-templates select="$layers[1]" mode="unsetN"/>
          <xsl:variable name="removed.mRests" select="($layers//mei:mRest)[position() gt 1]/@xml:id"/>
          <xsl:message select="'merged mRests of staves' || $firstStaff.n || ' and ' || $secondStaff.n || ' in measure ' || parent::mei:measure/@xml:id ||
            ', which effectively removes mRests with xml:ids ' || string-join($removed.mRests,', ')"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:copy-of select="$layers"/>
        </xsl:otherwise>
      </xsl:choose>      
      
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="mei:staff[@n = $secondStaff.n]" mode="firstRun"/>
  
  <xsl:template match="mei:layer" mode="setN">
    <xsl:param name="newNum" tunnel="yes"/>
    <xsl:copy>
      <xsl:attribute name="n" select="$newNum"/>
      <xsl:apply-templates select="node() | (@* except @n)"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="mei:layer" mode="unsetN">
    <xsl:copy>
      <xsl:apply-templates select="node() | (@* except @n)"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="mei:*[parent::mei:measure and @staff = $secondStaff.n]" mode="firstRun">
    <xsl:variable name="measure.id" select="parent::mei:measure/@xml:id"/>
    <xsl:variable name="name" select="local-name()"/>
    
    <xsl:copy>
      <xsl:apply-templates select="@* except @n"/>
      <xsl:attribute name="n" select="$firstStaff.n"/>
      <xsl:apply-templates select="node()"/>
      <xsl:message select="'moved ' || $name || ' in measure/@xml:id=' || $measure.id || ' from staff ' || $secondStaff.n || ' to ' || $firstStaff.n"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="mei:appInfo" mode="firstRun">
    <xsl:copy>
      <xsl:apply-templates select="node() | @*" mode="#current"/>
      <application xmlns="http://www.music-encoding.org/ns/mei" xml:id="mergeStaves.xsl">
        <name>mergeStaves.xsl</name>
        <xsl:comment>This stylesheet merges two staves into one, in order to overcome differences between a Finale file and the original source document.</xsl:comment>
        <ptr target="https://github.com/Freischuetz-Digital/Tools/blob/develop/100%20manual%20tools/mergeStaves.xsl"/>
      </application>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="mei:revisionDesc" mode="firstRun">
    
    <xsl:param name="potentialConflicts" tunnel="yes" as="node()*"/>
    
    <xsl:copy>
      <xsl:apply-templates select="node() | @*" mode="#current"/>
      
      <change xmlns="http://www.music-encoding.org/ns/mei" n="{string(count(child::mei:change) + 1)}">
        <respStmt>
          <persName>Johannes Kepper</persName>    
        </respStmt>
        <changeDesc>
          <p>Merged staff <xsl:value-of select="$secondStaff.n"/> into <xsl:value-of select="$firstStaff.n"/>. <xsl:if test="count($potentialConflicts) gt 0">This may have caused conflicts in measures <xsl:value-of select="string-join($potentialConflicts/@xml:id, ', ')"/>.</xsl:if></p>
        </changeDesc>
        <date isodate="{substring(string(current-date()),1,10)}"/>
      </change>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="@staff" mode="secondRun">
    <xsl:choose>
      <xsl:when test="exists($staff.adjust.above) and number(.) gt $staff.adjust.above">
        <xsl:attribute name="staff" select="number(.) + $staff.diff"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:next-match/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template match="mei:staff/@n" mode="secondRun">
    <xsl:choose>
      <xsl:when test="exists($staff.adjust.above) and number(.) gt $staff.adjust.above">
        <xsl:attribute name="n" select="number(.) + $staff.diff"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:next-match/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template match="mei:staffDef/@n" mode="secondRun">
    <xsl:choose>
      <xsl:when test="exists($staff.adjust.above) and number(.) gt $staff.adjust.above">
        <xsl:attribute name="n" select="number(.) + $staff.diff"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:next-match/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template match="node() | @*" mode="#all">
    <xsl:copy>
      <xsl:apply-templates select="node() | @*" mode="#current"/>
    </xsl:copy>
  </xsl:template>
  
</xsl:stylesheet>