<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    xmlns:mei="http://www.music-encoding.org/ns/mei"
    exclude-result-prefixes="xs xd"
    version="2.0">
    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p><xd:b>Created on:</xd:b> Jan 14, 2013</xd:p>
            <xd:p><xd:b>Author:</xd:b> Johannes Kepper</xd:p>
            <xd:p>
                This stylesheet uses a separate document dimensions.xml to
                update @width and @height of mei:graphic elements, and to scale
                @ulx, @uly, @lrx and @lry of their following mei:zones. 
                
                The calculation is done per page, so differing scaling ratios
                are no problem. 
                
                The format of the dimensions.xml has to be like:
                
                dimensions
                    graphic target="sources/A/00000001.jpg" newWidth="4158" newHeight="3325"/
                    graphic target="sources/A/00000002.jpg" newWidth="4060" newHeight="3267"/
                /dimensions
                
                The relation between old and new graphic is connected based on the equality 
                of @target. 
                
            </xd:p>
        </xd:desc>
    </xd:doc>
    
    <xsl:variable name="graphics" select="document('dimensions.xml')//dimensions"/>
    
    <xsl:template match="/">
        <xsl:apply-templates/>
    </xsl:template>
    
    <xsl:template match="mei:graphic">
        <xsl:variable name="target" select="@target"/>
        <xsl:variable name="newSize" select="$graphics//graphic[@target eq $target]"/>
        <xsl:copy>
            <xsl:copy-of select="@target | @xml:id | @type"/>
            <xsl:attribute name="width" select="$newSize/@newWidth"/>
            <xsl:attribute name="height" select="$newSize/@newHeight"/>
        </xsl:copy>
        
        <xsl:variable name="widthScale" select="number($newSize/@newWidth) div number(@width)"/>
        <xsl:variable name="heightScale" select="number($newSize/@newHeight) div number(@height)"/>
        
        <xsl:apply-templates select="following-sibling::mei:zone" mode="change">
            <xsl:with-param name="widthScale" select="$widthScale"/>
            <xsl:with-param name="heightScale" select="$heightScale"/>
        </xsl:apply-templates>
        
    </xsl:template>
    
    <xsl:template match="mei:zone" mode="change">
        <xsl:param name="widthScale"/>
        <xsl:param name="heightScale"/>
        <xsl:copy>
            <xsl:copy-of select="@xml:id"/>
            <xsl:attribute name="type" select="'measure'"/>
            <xsl:attribute name="ulx" select="round(number(@ulx) * $widthScale)"/>
            <xsl:attribute name="uly" select="round(number(@uly) * $heightScale)"/>
            <xsl:attribute name="lrx" select="round(number(@lrx) * $widthScale)"/>
            <xsl:attribute name="lry" select="round(number(@lry) * $heightScale)"/>
            <xsl:copy-of select="@data"/>
        </xsl:copy>
        
    </xsl:template>
    
    <xsl:template match="mei:zone" mode="#default"/>
    
    <xsl:template match="node() | @*">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*"/>
        </xsl:copy>
    </xsl:template>
    
</xsl:stylesheet>