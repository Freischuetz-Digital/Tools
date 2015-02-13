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
            <xd:p><xd:b>Created on:</xd:b> Oct 24, 2014</xd:p>
            <xd:p><xd:b>Author:</xd:b> Johannes Kepper</xd:p>
            <xd:p>This stylesheet reverts the splitting up of pages
                (done by generateSystemFiles.xsl) after proof-reading. 
            </xd:p>
            
            <xd:p>TODO: check for other proofreading tools</xd:p>
        </xd:desc>
    </xd:doc>
    
    <xsl:output method="xml" indent="yes"/>
    
    <xsl:variable name="filePath" select="substring-before(document-uri(/),'/' || tokenize(document-uri(/),'/')[last()])" as="xs:string"/>    
    <xsl:variable name="files" select="collection($filePath)" as="node()*"/>
    <xsl:variable name="sourceID" select="substring-before(//mei:mdiv/@xml:id,'_')" as="xs:string"/>
    <xsl:variable name="movID" select="//mei:mdiv/@xml:id" as="xs:string"/>
    
    <xsl:variable name="resultPath" select="substring-before($filePath,'sourcePrep') || 'sourcePrep/12%20concatenated%20Pages/' || $sourceID || '/' || $movID || '.xml'" as="xs:string"/>
    
    <xsl:template match="/">
        
        <xsl:message>Processing folder "<xsl:value-of select="$filePath"/>/" with concatenateSystems.xsl</xsl:message>
        
        <!-- TODO: include other proofreading components in this test -->
        <xsl:for-each select="$files">
            <xsl:variable name="file" select="." as="node()"/>
            <xsl:variable name="path" select="tokenize(string(document-uri($file)),'/')[last()]" as="xs:string"/>
            
            <xsl:if test="not($file//mei:application[@xml:id='generateSystemFiles.xsl'] and $file//mei:change//mei:ref[@target='#generateSystemFiles.xsl'])">
                <xsl:message terminate="yes">File "<xsl:value-of select="$path"/>" has not been processed by generateSystemFiles.xsl. Please check!</xsl:message>
            </xsl:if>
            
            <xsl:if test="not($file//mei:application[@xml:id='pmd'] and $file//mei:change//mei:ref[@target='#pmd'])">
                <xsl:message terminate="yes">File "<xsl:value-of select="$path"/>" has not been processed by pmd.pitchtool. Please check!</xsl:message>
            </xsl:if>
            
            <xsl:variable name="allStaves" select="distinct-values($file//mei:staffDef/@n)" as="xs:string*"/>
            <xsl:variable name="checkedStaves" select="distinct-values($file//mei:change[.//mei:ref[@target='#pmd']]//tokenize(normalize-space(mei:p),' ')[3])" as="xs:string*"/>
            <xsl:variable name="unCheckedStaves" select="distinct-values($allStaves[not(.=$checkedStaves)])" as="xs:string*"/>
             
            <xsl:if test="count($unCheckedStaves) gt 0">
                <xsl:message terminate="no">In file "<xsl:value-of select="$path"/>", staves <xsl:value-of select="string-join($unCheckedStaves,', ')"/> haven't been
                    processed by pmd.pitchtool. Is this correct?</xsl:message>
            </xsl:if>
            
        </xsl:for-each>
        
        <xsl:result-document href="{$resultPath}" method="xml" indent="yes">
            <xsl:apply-templates mode="framingFile"/>    
        </xsl:result-document>
        
        <xsl:message select="'Successfully written file ' || $resultPath || '.'"/>
    </xsl:template>
    
    <xsl:template match="mei:notesStmt[not(./mei:*)]" mode="framingFile"/>
    
    <xsl:template match="mei:appInfo" mode="framingFile">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*" mode="#current"/>
            
            <application xmlns="http://www.music-encoding.org/ns/mei" xml:id="concatenateSystems.xsl">
                <name>concatenateSystems.xsl</name>
                <ptr target="https://github.com/Freischuetz-Digital/Tools/blob/develop/12%20concatenated%20Pages/concatenateSystems.xsl"/>
            </application>
            
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="mei:change[.//mei:ref[@target='#pmd']]" mode="framingFile" priority="1"/>
    
    <xsl:template match="mei:change[not(following-sibling::mei:change)]" mode="framingFile" priority="2">
        <xsl:next-match/>
        
        <xsl:variable name="editors" select="distinct-values($files//mei:change[.//mei:ref[@target='#pmd']]//mei:persName/text())" as="xs:string*"/>
        <xsl:variable name="dates" select="distinct-values($files//mei:change[.//mei:ref[@target='#pmd']]/mei:date/xs:date(substring(@isodate,1,10)))" as="xs:date*"/>
        
        
        <xsl:message select="'movement checked by ' || string-join($editors,', ') || ' between ' || min($dates) || ' and ' || max($dates)"/>
        
        <change xmlns="http://www.music-encoding.org/ns/mei" n="{number(@n) + 1}">
            <respStmt>
                <persName><xsl:value-of select="string-join($editors,', ')"/></persName>
            </respStmt>
            <changeDesc>
                <p>Movement proofread with the <ref target="#pmd">ProofMyData Pitchtool webservice</ref>. More detailed information about
                    responsibilities and dates can be found in the corresponding files in 'musicSources/' 
                    <xsl:value-of select="substring-after($filePath,'musicSources/')"/>.
                </p>
            </changeDesc>
            <date startdate="{min($dates)}" enddate="{max($dates)}"/>
        </change>
        
        <change xmlns="http://www.music-encoding.org/ns/mei" n="{number(@n) + 2}">
            <respStmt>
                <persName>Johannes Kepper</persName>
            </respStmt>
            <changeDesc>
                <p>Merged systems after proofreading with <ref target="#concatenateSystems.xsl">concatenateSystems.xsl</ref>.</p>
            </changeDesc>
            <date isodate="{substring(string(current-date()),1,10)}"/>
        </change>
    </xsl:template>
    
    <xsl:template match="mei:facsimile" mode="framingFile">
        <xsl:copy>
            <xsl:apply-templates select="@*" mode="framingFile"/>
            
            <xsl:variable name="surfaces" select="$files//mei:surface"/>
            
            <xsl:for-each select="$surfaces">
                <xsl:sort select="substring-after(@xml:id,'_surface')" data-type="number"/>
                <xsl:variable name="surface" select="." as="node()"/>
                
                <xsl:variable name="fileName" select="tokenize(string(document-uri($surface/root())),'/')[last()]" as="xs:string"/>
                <xsl:if test="not(contains($fileName,'_sys')) or ends-with($fileName,'_sys1.xml')">
                    <xsl:copy>
                        <xsl:apply-templates select="@*" mode="facsimiles"/>
                        <xsl:apply-templates select="mei:graphic" mode="facsimiles"/>
                        <xsl:variable name="id" select="@xml:id"/>
                        <xsl:variable name="zones" select="$surfaces//mei:zone[parent::mei:surface[@xml:id = $id]]"/>
                        <xsl:apply-templates select="$zones" mode="facsimiles"/>    
                    </xsl:copy>
                    
                </xsl:if>                
            </xsl:for-each>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="mei:score" mode="framingFile">
        <xsl:copy>
            <xsl:apply-templates select="mei:scoreDef | @*" mode="#current"/>
                        
            <xsl:for-each-group select="$files//mei:body//mei:section" group-starting-with="mei:section[not(@type)]">
                <xsl:variable name="compilableSection" select="current-group()" as="node()*"/>
                
                <section xmlns="http://www.music-encoding.org/ns/mei">
                    <xsl:apply-templates select="$compilableSection/mei:*"/>
                </section>
            </xsl:for-each-group>
        </xsl:copy>
    </xsl:template>
        
    <xsl:template match="node() | @*" mode="#all">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*" mode="#current"/>
        </xsl:copy>            
    </xsl:template>
    
</xsl:stylesheet>