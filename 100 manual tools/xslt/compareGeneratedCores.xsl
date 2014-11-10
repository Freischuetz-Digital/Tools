<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    xmlns:mei="http://www.music-encoding.org/ns/mei" xmlns:xlink="http://www.w3.org/1999/xlink"
    exclude-result-prefixes="xs xd" version="2.0">
    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p><xd:b>Created on:</xd:b> Jan 4, 2013</xd:p>
            <xd:p><xd:b>Author:</xd:b> Johannes Kepper</xd:p>
            <xd:p> todo </xd:p>
        </xd:desc>
    </xd:doc>

    <xsl:output method="xml" indent="yes"
        xpath-default-namespace="http://www.music-encoding.org/ns/mei"/>

    <xsl:variable name="files" select="collection('../generatedCores/?select=*.xml')//mei:mei"/>

    <xsl:template match="/">
        <xsl:result-document href="../coreComparison.xml">
            <result date="{substring(string(current-date()),1,10)}">
                <xsl:for-each select="$files[1]//mei:mdiv">
                    <xsl:variable name="mdiv" select="position()"/>
                    <mdiv label="{@label}">

                        <xsl:variable name="length" select="count($files)"/>
                        <xsl:for-each select="(1 to $length)">
                            <xsl:variable name="i" select="."/>
                            <xsl:variable name="file" select="$files[$i]"/>
                            <xsl:variable name="mov" select="$file//mei:mdiv[$mdiv]"/>
                            <xsl:variable name="docTitle" select="$mov/root()//mei:title[1]/text()"/>
                            <xsl:variable name="measures" select="count($mov//mei:measure)"/>
                            <source measures="{$measures}" label="{$docTitle}"/>
                        </xsl:for-each>
                    </mdiv>
                </xsl:for-each>
            </result>
        </xsl:result-document>

    </xsl:template>


    <xsl:template match="node() | @*" mode="#all">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*" mode="#current"/>
        </xsl:copy>
    </xsl:template>

</xsl:stylesheet>
