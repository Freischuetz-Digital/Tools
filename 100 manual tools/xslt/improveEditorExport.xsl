<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    xmlns:mei="http://www.music-encoding.org/ns/mei"
    xmlns:xlink="http://www.w3.org/1999/xlink"
    exclude-result-prefixes="xs xd"
    version="2.0">
    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p><xd:b>Created on:</xd:b> Jan 4, 2013</xd:p>
            <xd:p><xd:b>Author:</xd:b> Johannes Kepper</xd:p>
            <xd:p>
                This stylesheet takes an export from Edirom Editor (exported towards Edirom Online).
            </xd:p>
            <xd:p>
                It depends on:
                <xd:ul>
                    <xd:li>the filename will be used for many ids etc., it should match the intended siglum</xd:li>
                </xd:ul>
            </xd:p>
            <xd:p>
                It does:
                <xd:ul>
                    <xd:li>unifies all @xml:id into a predictable format, based on the filename.</xd:li> 
                    <xd:li>creates backlinks from zones to measures</xd:li>
                    <xd:li>provides initial pointers to core.xml (without considering a concordance or core.xml itself)</xd:li>
                    <xd:li>generates a core.xml which resembles this source and may be used for comparison</xd:li>
                    <xd:li>adjusts the header</xd:li>
                    <xd:li>sets a change note in the header</xd:li>
                </xd:ul>
                It is not intended to be used within eXist, but in the filesystem.
            </xd:p>
            <xd:p>If you want to move through the documentation step by step proceed to <xd:a docid="root"></xd:a></xd:p>
        </xd:desc>
    </xd:doc>
    
    <xsl:output method="xml" indent="yes" xpath-default-namespace="http://www.music-encoding.org/ns/mei"/>
    
    <xsl:key name="measuresByFacs" match="mei:measure" use="@facs" />
    
    <xsl:variable name="docID" select="substring-before(tokenize(document-uri(root()),'/')[last()],'.xml')"/>
    
    <xd:doc id="measures">
        <xd:desc></xd:desc>
    </xd:doc>
    <xsl:variable name="measures">
        <xsl:apply-templates select="//mei:measure" mode="prepare"/>
    </xsl:variable>
    
    <xd:doc scope="component" id="root">
        <xd:desc>
            <xd:p>The root template triggers the creation of two files</xd:p>
            <xd:ul>
                <xd:li>a file called _$FILENAME.xml residing in the same directory as the processed file</xd:li>
                <xd:li>a file called _$FILENAMEcore.xml residing in ../generatedCoresx</xd:li>
            </xd:ul>
        </xd:desc>
    </xd:doc>
    <xsl:template match="/">
        <!-- creates temporary _source.xml file -->
        <xsl:result-document href="_{$docID}.xml">
            <xsl:apply-templates/>    
        </xsl:result-document>
        <!-- creates a core file exclusively based on the source file processed  -->
        <xsl:result-document href="../generatedCores/core{$docID}.xml">
            <xsl:apply-templates mode="core"/>
        </xsl:result-document>
    </xsl:template>
    
    
    <xd:doc scope="component">
        <xd:desc>
            <xd:p>This template generates mei:fileDesc for the output; most important it creates mei:change entries in the mei:changeDesc that document the application of this stylesheet on the data</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template match="mei:fileDesc">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
            <xsl:apply-templates select="following-sibling::mei:sourceDesc"/>
        </xsl:copy>
        
        <xsl:element name="encodingDesc" namespace="http://www.music-encoding.org/ns/mei">
            <xsl:element name="appInfo" namespace="http://www.music-encoding.org/ns/mei">
                <xsl:element name="application" namespace="http://www.music-encoding.org/ns/mei">
                    <xsl:attribute name="xml:id" select="'ediromEditor'"/>
                    <xsl:attribute name="version" select="'1.1.22'"/>
                    <xsl:element name="name" namespace="http://www.music-encoding.org/ns/mei">Edirom Editor</xsl:element>
                    <xsl:element name="ptr" namespace="http://www.music-encoding.org/ns/mei">
                        <xsl:attribute name="target" select="'http://www.edirom.de/software/edirom-werkzeuge/'"/>
                    </xsl:element>
                </xsl:element>
                <xsl:element name="application" namespace="http://www.music-encoding.org/ns/mei">
                    <xsl:attribute name="xml:id" select="'xsltUp-01'"/>
                    <xsl:element name="name" namespace="http://www.music-encoding.org/ns/mei">improveEditorExport.xsl</xsl:element>
                    <xsl:element name="ptr" namespace="http://www.music-encoding.org/ns/mei">
                        <xsl:attribute name="target" select="'../xslt/improveEditorExport.xsl'"/>
                    </xsl:element>
                </xsl:element>
            </xsl:element>
        </xsl:element>
        <xsl:element name="revisionDesc" namespace="http://www.music-encoding.org/ns/mei">
            <xsl:element name="change" namespace="http://www.music-encoding.org/ns/mei">
                <xsl:attribute name="n" select="'1'"/>
                <xsl:element name="respStmt" namespace="http://www.music-encoding.org/ns/mei">
                    <xsl:element name="persName" namespace="http://www.music-encoding.org/ns/mei">[todo: student's name]</xsl:element>
                </xsl:element>
                <xsl:element name="changeDesc" namespace="http://www.music-encoding.org/ns/mei">
                    <xsl:element name="p" namespace="http://www.music-encoding.org/ns/mei">Measure positions marked manually using
                        <xsl:element name="ref" namespace="http://www.music-encoding.org/ns/mei">
                            <xsl:attribute name="target" select="'#ediromEditor'"/>
                            <xsl:value-of select="'Edirom Editor'"/>
                        </xsl:element>.</xsl:element>
                </xsl:element>
                <xsl:element name="date" namespace="http://www.music-encoding.org/ns/mei">
                    <xsl:attribute name="notafter" select="substring(string(current-date()),1,10)"/>
                </xsl:element>
            </xsl:element>
            <xsl:element name="change" namespace="http://www.music-encoding.org/ns/mei">
                <xsl:attribute name="n" select="'2'"></xsl:attribute>
                <xsl:element name="respStmt" namespace="http://www.music-encoding.org/ns/mei">
                    <xsl:element name="persName" namespace="http://www.music-encoding.org/ns/mei">
                        <xsl:attribute name="xml:id" select="'smJK'"/>
                        <xsl:value-of select="'Johannes Kepper'"/>
                    </xsl:element>
                </xsl:element>
                <!-- generates changeDesc entry for application of this stylesheet ('improveExport.xsl') -->
                <xsl:element name="changeDesc" namespace="http://www.music-encoding.org/ns/mei">
                    <xsl:element name="p" namespace="http://www.music-encoding.org/ns/mei">Encoding improved using 
                        <xsl:element name="ref" namespace="http://www.music-encoding.org/ns/mei">
                            <xsl:attribute name="target" select="'#xsltUp-01'"/>
                            <xsl:value-of select="'improveEditorExport.xsl'"/>
                        </xsl:element>. 
                        Initial set up for header, implemented predictable @xml:ids, and first references to core.xml 
                        (which isn't available yet).</xsl:element>
                </xsl:element>
                <xsl:element name="date" namespace="http://www.music-encoding.org/ns/mei">
                    <xsl:attribute name="isodate" select="substring(string(current-date()),1,10)"/>
                </xsl:element>
            </xsl:element>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="mei:sourceDesc"/>
    
    <xsl:template match="mei:identifier/@type">
        <xsl:copy><xsl:value-of select="$docID"/></xsl:copy>
    </xsl:template>
    
    <xsl:template match="mei:relation">
        <xsl:copy>
            <xsl:attribute name="rel" select="'isEmbodimentOf'"/>
            <xsl:attribute name="target" select="'../core.xml#fs_exp1'"/>
        </xsl:copy>
    </xsl:template>
    
    
    <xsl:template match="mei:mei/@xml:id">
        <xsl:attribute name="xml:id" select="$docID"/>
    </xsl:template> 
    
    <xsl:template match="mei:mei/@xml:id" mode="core">
        <xsl:attribute name="xml:id" select="'core'"/>
    </xsl:template>
    
    <xsl:template match="mei:relation[@rel eq 'isEmbodimentOf']/@target">
        <xsl:attribute name="target" select="'../core/core.xml#fs_v01'"/>
    </xsl:template>
    
    <xsl:template match="mei:facsimile" mode="core"/>
    
    <xsl:template match="mei:surface">
        <xsl:variable name="pageName" select="substring-before(tokenize(mei:graphic/@target,'/')[last()],'.')"/>
        <!--<xsl:variable name="label" select="if(matches($pageName, '^\d+$')) then(string(number($pageName))) else($pageName)"/>-->
        <!-- why this "if" for $label? -->
        <xsl:variable name="label" select="$pageName"/>
        <xsl:variable name="n" select="count(preceding-sibling::mei:surface) + 1"/>
        
        <xsl:copy>
            <xsl:attribute name="xml:id" select="concat($docID,'_surface',$n)"/>
            <xsl:attribute name="n" select="$n"/>
            <xsl:if test="string($n) != $label">
                <xsl:attribute name="label" select="$label"/>
            </xsl:if>
            
            <xsl:for-each select="mei:graphic">
                <xsl:copy>
                    <xsl:attribute name="target" select="concat('sources/',$docID,'/',$pageName,'.jpg')"/>
                    <xsl:attribute name="xml:id" select="concat($docID,'_surface',$n,'_graphic1')"/>
                    <xsl:copy-of select="@type | @width | @height"/>
                </xsl:copy>
            </xsl:for-each>
            <xsl:apply-templates select="mei:zone"/>            
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="mei:zone">
        <xsl:copy>
            <xsl:variable name="oldMeasureID" select="key('measuresByFacs',concat('#',@xml:id))[1]/@xml:id"/>
            <xsl:variable name="measureID" select="$measures//mei:measure[@oldID eq $oldMeasureID]/@xml:id"/>
            
            <xsl:attribute name="xml:id" select="concat(substring-before($measureID,'_mov'),'_zoneOf_mov',substring-after($measureID,'_mov'))"/>
            <xsl:copy-of select="@* except @xml:id"/>            
            
            <xsl:attribute name="data" select="concat('#',$measureID)"/>
            
        </xsl:copy>    
    </xsl:template>
    
    <xsl:template match="mei:mdiv">
        <xsl:copy>
            <xsl:variable name="mdivNo" select="count(preceding-sibling::mei:mdiv)"/>
            <xsl:attribute name="xml:id" select="concat($docID,'_mov',$mdivNo)"/>
            <xsl:attribute name="label">
                <xsl:choose>
                    <xsl:when test="$mdivNo eq 0">Ouverture</xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="concat('Nummer ',$mdivNo)"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:attribute>            
            <xsl:apply-templates select="node()"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="mei:mdiv" mode="core">
        <xsl:copy>
            <xsl:variable name="mdivNo" select="count(preceding-sibling::mei:mdiv)"/>
            <xsl:attribute name="xml:id" select="concat('core_mov',$mdivNo)"/>
            <xsl:attribute name="label">
                <xsl:choose>
                    <xsl:when test="$mdivNo eq 0">Ouverture</xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="concat('Nummer ',$mdivNo)"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:attribute>            
            <xsl:apply-templates select="node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="mei:measure" mode="prepare">
        <xsl:copy>
            <xsl:variable name="measurePos" select="count(preceding-sibling::mei:measure) + 1"/>
            <xsl:variable name="mdivNo" select="count(ancestor::mei:mdiv/preceding-sibling::mei:mdiv)"/>
            
            <xsl:variable name="measureN" select="@n"/>
            <xsl:variable name="predictedID" select="concat($docID,'_mov',$mdivNo,'_measure',$measureN)"/>
            
            <xsl:attribute name="n" select="$measureN"/>
            <xsl:attribute name="oldID" select="@xml:id"/>
            
            <xsl:variable name="followingHasSameN" select="following-sibling::mei:measure and following-sibling::mei:measure[1]/@n eq @n" as="xs:boolean"/>
            <xsl:variable name="precedingHasSameN" select="preceding-sibling::mei:measure and preceding-sibling::mei:measure[1]/@n eq @n" as="xs:boolean"/>
            <xsl:variable name="thisIsUpbeat" select="@type and @type eq 'upbeat'" as="xs:boolean"/>
            <xsl:variable name="precedingIsUpbeat" select="preceding-sibling::mei:measure and preceding-sibling::mei-measure[1]/@type eq 'upbeat'" as="xs:boolean"/>
            
            <xsl:variable name="joinLetter" as="xs:string">
                <xsl:choose>
                    <xsl:when test="$followingHasSameN and not($precedingHasSameN) and not($thisIsUpbeat)">
                        <xsl:value-of select="'.1'"/>
                    </xsl:when>
                    <xsl:when test="$precedingHasSameN and not($precedingIsUpbeat)">
                        <xsl:variable name="precedingCount" select="count(preceding-sibling::mei:measure[@n eq $measureN])"/>                            
                        <xsl:value-of select="concat('.',$precedingCount+1)"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="''"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            
            <xsl:variable name="joinCount" as="xs:integer">
                <xsl:choose>
                    <xsl:when test="$followingHasSameN or $precedingHasSameN">
                        <xsl:variable name="count" select="count(following-sibling::mei:measure[@n eq $measureN]) + count(preceding-sibling::mei:measure[@n eq $measureN]) + 1" as="xs:integer"/>
                        <xsl:value-of select="$count"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="1"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            
            <xsl:attribute name="xml:id" select="concat($predictedID,$joinLetter)"/>
            
            <xsl:if test="$joinCount gt 1">
                <xsl:variable name="joinRefs" as="xs:string*">
                    <xsl:for-each select="(1 to $joinCount)">
                        <xsl:variable name="current" select="concat('.',.)" as="xs:string"/>
                        <xsl:if test="$joinLetter != $current">
                            <xsl:value-of select="concat('#',$predictedID,$current)"/>
                        </xsl:if>
                    </xsl:for-each>
                </xsl:variable>
                <xsl:attribute name="join" select="string-join($joinRefs,' ')"/>
            </xsl:if>
            
            <xsl:attribute name="facs" select="concat('#',$docID,'_zoneOf_mov',$mdivNo,'_measure',$measureN,$joinLetter)"/>
            <xsl:attribute name="sameas">
                <xsl:choose>
                    <xsl:when test=".//mei:multiRest">
                        <xsl:variable name="num" select=".//mei:multiRest[1]/@num" as="xs:integer"/>
                        <xsl:variable name="coreRefs" as="xs:string*">
                            <xsl:for-each select="(0 to ($num - 1))">
                                <xsl:variable name="newN" select="(($measureN cast as xs:integer) + .)" as="xs:integer"/>
                                <xsl:value-of select="concat('../core.xml#core',substring-after(substring-before($predictedID, concat('_measure',$measureN)),$docID),'_measure',$newN)"/>
                            </xsl:for-each>
                        </xsl:variable>
                        <xsl:value-of select="string-join($coreRefs, ' ')"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="concat('../core.xml#core',substring-after($predictedID,$docID),$joinLetter)"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:attribute>
            
            <xsl:apply-templates select="node()"/>
            
        </xsl:copy>
    </xsl:template>
    
    <xd:doc >
        <xd:desc>
            Depends on
        </xd:desc>
    </xd:doc>
    <xsl:template match="mei:measure">
        <xsl:variable name="id" select="@xml:id"/>
        <xsl:variable name="newMeasure" select="$measures//mei:measure[@oldID = $id]"/>
        <xsl:copy>
            <xsl:apply-templates select="$newMeasure/@* except $newMeasure/@oldID"/>
            <xsl:apply-templates select="$newMeasure/node()"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="mei:measure" mode="core">
        <xsl:variable name="measurePos" select="count(preceding-sibling::mei:measure) + 1"/>
        <xsl:variable name="mdivNo" select="count(ancestor::mei:mdiv/preceding-sibling::mei:mdiv)"/>
        
        <xsl:variable name="measureN" select="@n"/>
        <xsl:variable name="predictedID" select="concat('core_mov',$mdivNo,'_measure',$measureN)"/>
        
        <xsl:variable name="following" select="following-sibling::mei:measure and following-sibling::mei:measure[1]/@n eq @n" as="xs:boolean"/>
        <xsl:variable name="preceding" select="preceding-sibling::mei:measure and preceding-sibling::mei:measure[1]/@n eq @n" as="xs:boolean"/>
        <xsl:variable name="thisUpbeat" select="@type and @type eq 'upbeat'" as="xs:boolean"/>
        <xsl:variable name="precedingUpbeat" select="preceding-sibling::mei:measure and preceding-sibling::mei-measure[1]/@type eq 'upbeat'" as="xs:boolean"/>
        
        <xsl:variable name="joinLetter" as="xs:string">
            <xsl:choose>
                <xsl:when test="$following and not($preceding) and not($thisUpbeat)">
                    <xsl:value-of select="'.1'"/>
                </xsl:when>
                <xsl:when test="$preceding and not($precedingUpbeat)">
                    <xsl:variable name="precedingCount" select="count(preceding-sibling::mei:measure[@n eq $measureN])"/>                            
                    <xsl:value-of select="concat('.',$precedingCount+1)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="''"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <xsl:variable name="joinCount" as="xs:integer">
            <xsl:choose>
                <xsl:when test="$following or $preceding">
                    <xsl:variable name="count" select="count(following-sibling::mei:measure[@n eq $measureN]) + count(preceding-sibling::mei:measure[@n eq $measureN]) + 1" as="xs:integer"/>
                    <xsl:value-of select="$count"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="1"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <xsl:copy>
            
            <xsl:attribute name="n" select="$measureN"/>
            <xsl:attribute name="xml:id" select="concat($predictedID,'___',$joinLetter,'___Hurz!')"/>
            
            <xsl:if test="$joinCount gt 1">
                <xsl:variable name="joinRefs" as="xs:string*">
                    <xsl:for-each select="(1 to $joinCount)">
                        <xsl:variable name="current" select="codepoints-to-string((. + 96))" as="xs:string"/>
                        <xsl:if test="substring($joinLetter,2) != $current">
                            <xsl:value-of select="concat('#',$predictedID,$current)"/>
                        </xsl:if>
                    </xsl:for-each>
                </xsl:variable>
                <xsl:attribute name="join" select="string-join($joinRefs,' ')"/>
            </xsl:if>
            
        </xsl:copy>
        <xsl:choose>
            <xsl:when test=".//mei:multiRest">
                <xsl:variable name="num" select=".//mei:multiRest[1]/@num" as="xs:integer"/>
                <xsl:for-each select="(1 to $num - 1)">
                    <xsl:variable name="newN" select="(($measureN cast as xs:integer) + .)" as="xs:integer"/>
                    <xsl:element name="measure" namespace="http://www.music-encoding.org/ns/mei">
                        <xsl:attribute name="n" select="$newN"/>
                        <xsl:attribute name="xml:id" select="concat(substring-before($predictedID,'_measure'),'_measure',string($newN))"/>
                        <xsl:attribute name="type">generated</xsl:attribute>
                    </xsl:element>
                </xsl:for-each>
            </xsl:when>
        </xsl:choose>
        
    </xsl:template>
    
    
    <xsl:template match="node() | @*" mode="#all">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
</xsl:stylesheet>