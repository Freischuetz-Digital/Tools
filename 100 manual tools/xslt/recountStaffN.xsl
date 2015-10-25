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
        Moves staff/@n from a given n by a given offset. 
      </xd:p>
    </xd:desc>
  </xd:doc>
  
  <xsl:output method="xml" indent="yes"/>
  
  <xsl:param name="staff.start" select="9" as="xs:integer"/>
  <xsl:param name="staff.diff" select="-1" as="xs:integer"/>
    
  <xsl:template match="/">
    <xsl:apply-templates/>
  </xsl:template>
  
  <xsl:template match="@staff">
    <xsl:choose>
      <xsl:when test="number(.) ge $staff.start">
        <xsl:attribute name="staff" select="number(.) + $staff.diff"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:next-match/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template match="mei:staff/@n">
    <xsl:choose>
      <xsl:when test="number(.) ge $staff.start">
        <xsl:attribute name="n" select="number(.) + $staff.diff"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:next-match/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template match="mei:staffDef/@n">
    <xsl:choose>
      <xsl:when test="number(.) ge $staff.start">
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