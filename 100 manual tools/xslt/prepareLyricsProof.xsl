<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    xmlns:mei="http://www.music-encoding.org/ns/mei"
    exclude-result-prefixes="xs xd"
    version="3.0">
    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p><xd:b>Created on:</xd:b> Feb 5, 2015</xd:p>
            <xd:p><xd:b>Author:</xd:b> Johannes Kepper</xd:p>
            <xd:p>
                
            </xd:p>
        </xd:desc>
    </xd:doc>
    
    <xsl:output indent="yes" method="xml"/>
    
    <xsl:variable name="staves" select="distinct-values(//mei:staff[.//mei:syl]/@n)" as="xs:string*"/>
    <xsl:variable name="fileName" select="tokenize(document-uri(/),'/')[last()]"/>
    
    <xsl:template match="/">
        <xsl:result-document href="{'./../../../09.2_lyricProof/'||replace($fileName,'.xml','.html')}">
            <html>
                <head>
                    <title>Textunterlegung</title>
                    <style type="text/css">
                        .measure {
                        display: inline-block;
                        border-right: 0.5px solid #999999;
                        padding: 0 10px;
                        }
                        
                        .measure label {
                        color: #999999;
                        font-size: 14px;
                        }
                        
                        .sylBox {
                        display: inline-block;
                        margin-right: 5px;
                        }
                        
                        .sylBox .tstamp {
                        color: #666666;
                        font-size: 14px;
                        }
                        
                        .sylBox .text {
                        font-weight: bold;
                        font-size: 18px;
                        }
                        
                        .sylBox .text.initial {
                        color: #13a528;
                        }
                        
                        .sylBox .text.middle {
                        color: #598adb;
                        }
                        
                        .sylBox .text.terminal {
                        color: #f44c18;
                        }
                        
                    </style>
                </head>
                <body>
                    <xsl:apply-templates/>        
                </body>
            </html>
        </xsl:result-document>
    </xsl:template>
    
    <xsl:template match="mei:measure">
        <xsl:variable name="measure" select="."/>
        <div class="measure">
            <label class="measureN"><xsl:value-of select="$measure/@xml:id"/></label>
            <xsl:for-each select="$staves">
                <xsl:variable name="current.n" select="."/>
                
                <div class="staffBox">
                    <xsl:apply-templates select="$measure//mei:syl[ancestor::mei:staff/@n = $current.n]"/>    
                </div>
            </xsl:for-each>
        </div>
    </xsl:template>
    
    <xsl:template match="mei:syl">
        <div class="sylBox">
            
            <xsl:variable name="pitch" select="upper-case(ancestor::mei:*[@pname][1]/@pname) || ancestor::mei:*[@oct][1]/@oct"/>
            
            <div class="tstamp"><xsl:value-of select="string(ancestor::mei:*[@tstamp]/@tstamp) || ' (' || $pitch || ')'"/></div>
            <xsl:variable name="class" as="xs:string">
                <xsl:choose>
                    <xsl:when test="@wordpos = 'i'">initial</xsl:when>
                    <xsl:when test="@wordpos = 'm'">middle</xsl:when>
                    <xsl:when test="@wordpos = 't'">terminal</xsl:when>
                    <xsl:otherwise>fullword</xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            <xsl:variable name="underline" as="xs:string">
                <xsl:choose>
                    <xsl:when test=".//mei:rend[@rend = 'underline']"> underline</xsl:when>
                    <xsl:otherwise><xsl:value-of select="''"/></xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            <xsl:variable name="con" as="xs:string">
                <xsl:choose>
                    <xsl:when test="@con = 'd'">-</xsl:when>
                    <xsl:when test="@con = 'u'">_</xsl:when>
                    <xsl:otherwise><xsl:value-of select="''"/></xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            <div>
                <xsl:attribute name="class" select="concat('text ',$class, $underline)"/>
                <xsl:value-of select="concat(string-join(.//text(),''),$con)"/>
            </div>
        </div>
    </xsl:template>
    
    <xsl:template match="text()"/>
    
</xsl:stylesheet>