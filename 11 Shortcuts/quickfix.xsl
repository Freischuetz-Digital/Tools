<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    xmlns:mei="http://www.music-encoding.org/ns/mei"
    xmlns:uuid="java:java.util.UUID"
    exclude-result-prefixes="xs math xd mei"
    version="3.0">
    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p><xd:b>Created on:</xd:b> Sep 10, 2015</xd:p>
            <xd:p><xd:b>Author:</xd:b> johannes</xd:p>
            <xd:p></xd:p>
        </xd:desc>
    </xd:doc>
    
    <xsl:variable name="doc" select="/" as="node()"/>
    
    <xsl:template match="/">
        <xsl:apply-templates/>
    </xsl:template>
    
    <xsl:template match="mei:slur[not(ancestor::mei:choice) and not(ancestor::mei:rdg)]">
        <xsl:variable name="start.id" select="replace(@startid,'#','')" as="xs:string"/>
        <xsl:variable name="start.elem" select="$doc//mei:*[@xml:id = $start.id]" as="node()"/>
        <xsl:variable name="parent.measure" select="ancestor::mei:measure/@xml:id" as="xs:string"/>
        <xsl:variable name="start.measure" select="$start.elem/ancestor::mei:measure/@xml:id" as="xs:string"/>
        <xsl:choose>
            <xsl:when test="$parent.measure = $start.measure">
                <xsl:next-match/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message select="'slur ' || @xml:id || ' is in wrong measure. Is located in ' || $parent.measure || ', but should be in ' || $start.measure"/>
                <xsl:next-match/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="mei:slur[ancestor::mei:reg and count(ancestor::mei:reg/preceding-sibling::mei:reg) = 0]">
        <xsl:variable name="parent.measure" select="ancestor::mei:measure/@xml:id" as="xs:string"/>
        
        <xsl:variable name="start.ids" select="for $slur in ancestor::mei:choice/mei:reg/mei:slur return (replace($slur/@startid,'#',''))" as="xs:string+"/>
        <xsl:variable name="start.elems" select="for $start.id in $start.ids return ($doc//mei:*[@xml:id = $start.id])" as="node()+"/>
        <xsl:variable name="start.measures" select="for $start.elem in $start.elems return ($start.elem/ancestor::mei:measure/@xml:id)" as="xs:string+"/>
        
        <xsl:if test="not(some $start.measure in $start.measures satisfies ($start.measure = $parent.measure))">
            <xsl:message select="'slur choice with id ' || @xml:id || ' is in wrong measure. Is located in ' || $parent.measure || ', but should be in ' || $start.measures[1]"/>
        </xsl:if>
        
        <xsl:next-match/>
    </xsl:template>
    
    <xsl:template match="mei:slur[ancestor::mei:rdg and count(ancestor::mei:rdg/preceding-sibling::mei:rdg) = 0]">
        <xsl:variable name="parent.measure" select="ancestor::mei:measure/@xml:id" as="xs:string"/>
        
        <xsl:variable name="start.ids" select="for $slur in ancestor::mei:app/mei:rdg/mei:slur return (replace($slur/@startid,'#',''))" as="xs:string+"/>
        <xsl:variable name="start.elems" select="for $start.id in $start.ids return ($doc//mei:*[@xml:id = $start.id])" as="node()+"/>
        <xsl:variable name="start.measures" select="for $start.elem in $start.elems return ($start.elem/ancestor::mei:measure/@xml:id)" as="xs:string+"/>
        
        <xsl:if test="not(some $start.measure in $start.measures satisfies ($start.measure = $parent.measure))">
            <xsl:message select="'slur choice with id ' || @xml:id || ' is in wrong measure. Is located in ' || $parent.measure || ', but should be in ' || $start.measures[1]"/>
        </xsl:if>
        
        <xsl:next-match/>
    </xsl:template>
    
    <xsl:template match="node() | @*">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*"/>
        </xsl:copy>
    </xsl:template>
    
</xsl:stylesheet>