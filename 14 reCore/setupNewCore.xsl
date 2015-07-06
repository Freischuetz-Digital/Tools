<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    xmlns:mei="http://www.music-encoding.org/ns/mei"
    xmlns:uuid="java:java.util.UUID"
    xmlns:local="local"
    exclude-result-prefixes="xs math xd mei uuid local"
    version="3.0">
    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p><xd:b>Created on:</xd:b> Jan 05, 2015</xd:p>
            <xd:p><xd:b>Author:</xd:b> Johannes Kepper</xd:p>
            <xd:p>
                This stylesheet creates a new core file, based on the first source that is fully 
                proofread for one specific movement. 
            </xd:p>
            <xd:p>It operates on a movement file in "12.1 resolved ShortCuts", and generates the 
                corresponding core and source files in "13 reCored".</xd:p>
            <xd:p>
                A parameter "checkSetup" can be used to override this setup and allow the use of 
                this xsl in different contexts (value "false"). 
            </xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:output method="xml" indent="yes"/>
    
    <xsl:param name="checkSetup" select="'true'" as="xs:string"/>
    
    <!-- version of this stylesheet -->
    <xsl:variable name="xsl.version" select="'1.0.1'"/>
    
    <!-- gets global variables based on some general principles of the Freischütz Data Model -->
    <xsl:variable name="source.id" select="substring-before(/mei:mei/@xml:id,'_')" as="xs:string"/>
    <xsl:variable name="mov.id" select="substring-before((//mei:measure)[1]/@xml:id,'_measure')" as="xs:string"/>
    <xsl:variable name="mov.n" select="substring-after($mov.id,'_mov')" as="xs:string"/>
    
    <!-- perform the checks necessary for $checkSetup -->
    <xsl:variable name="correctFolder" select="starts-with(reverse(tokenize(document-uri(/),'/'))[3],'12')" as="xs:boolean"/>
    <xsl:variable name="basePath" select="substring-before(document-uri(/),'/1')"/>
    <xsl:variable name="sourceThereAlready" select="doc-available(concat($basePath,'/14%20reCored/',$source.id,'/',$mov.id,'.xml'))" as="xs:boolean"/>
    <xsl:variable name="coreThereAlready" select="doc-available(concat($basePath,'/14%20reCored/core_mov',$mov.n,'.xml'))" as="xs:boolean"/>
    
    <xsl:template match="/">
        
        <xsl:if test="$checkSetup != 'true'">
            <xsl:message terminate="no" select="'You decided against using this file in its original context. Be aware that things may break now…'"/>
        </xsl:if>
        
        <xsl:if test="$checkSetup = 'true' and not($correctFolder)">
            <xsl:message terminate="yes" select="'You seem to use a file from the wrong folder. Relevant chunk of filePath is: ' || reverse(tokenize(document-uri(/),'/'))[3]"/>
        </xsl:if>
        
        <xsl:if test="$checkSetup = 'true' and $sourceThereAlready">
            <xsl:message terminate="yes" select="'There is already a processed version of the file in /14 reCored…'"/>
        </xsl:if>
        
        <xsl:if test="$checkSetup = 'true' and $coreThereAlready">
            <xsl:message terminate="yes" select="'There is already a new core for mov' || $mov.n || '. Please use merge2Core.xsl instead.'"/>
        </xsl:if>
        
        <xsl:variable name="coreDraft">
            <xsl:apply-templates mode="coreDraft"/>
        </xsl:variable>
        
        <xsl:copy-of select="$coreDraft"/>
        
        <!-- source file -->
        <xsl:result-document href="{concat($basePath,'/14%20reCored/',$source.id,'/',$mov.id,'.xml')}">
            <xsl:apply-templates mode="source">
                <xsl:with-param name="coreDraft" select="$coreDraft" tunnel="yes"/>
            </xsl:apply-templates>
        </xsl:result-document>
        
        <!-- core file -->
        <xsl:result-document href="{concat($basePath,'/14%20reCored/core_mov',$mov.n,'.xml')}">
            <xsl:apply-templates select="$coreDraft" mode="core">
                <xsl:with-param name="coreDraft" select="$coreDraft" tunnel="yes"/>
            </xsl:apply-templates>
        </xsl:result-document>
        
    </xsl:template>
    
    <!-- ***COREDRAFT*MODE******************************** -->    
    
    <!-- preparing new xml:ids -->
    <xsl:template match="mei:*[local-name() = ('mdiv','section','measure','staff')]/@xml:id" mode="coreDraft">
        <xsl:variable name="old.id" select="string(.)" as="xs:string"/>
        <xsl:variable name="new.id" select="replace($old.id,$source.id,'core')" as="xs:string"/>
        <xsl:attribute name="xml:id" select="$new.id"/>
        <xsl:attribute name="old.id" select="$old.id"/>        
    </xsl:template>    
    <xsl:template match="mei:*[(ancestor::mei:staff) or (ancestor::mei:measure and not(ancestor::mei:staff) and not(local-name() = 'staff'))]/@xml:id" mode="coreDraft">        
        <xsl:attribute name="xml:id" select="'c'||uuid:randomUUID()"/>
        <xsl:attribute name="old.id" select="string(.)"/>
    </xsl:template>
    
    <!-- resolving choices into apps when necessary -->
    <xsl:template match="mei:choice" mode="coreDraft">
        
        <xsl:if test="count(child::mei:expan) gt 1">
            <xsl:message select="'working on choice ' || @xml:id"></xsl:message>
        </xsl:if>
        
        <xsl:choose>
            <xsl:when test="(count(child::mei:corr) gt 1) or (count(child::mei:reg) gt 1)">
                <app xmlns="http://www.music-encoding.org/ns/mei" xml:id="{'c'||uuid:randomUUID()}">
                    <xsl:apply-templates select="node()" mode="#current"/>
                </app>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="mei:corr/node() | mei:reg/node() | mei:expan/node()" mode="#current"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- only <corr>, <reg> and <expan> are addressed in the core -->
    <xsl:template match="mei:sic" mode="coreDraft"/>
    <xsl:template match="mei:abbr" mode="coreDraft"/>
    <xsl:template match="mei:orig" mode="coreDraft"/>    
    
    <!-- <corr> is a result of incorrect durations in the parent layer -->
    <xsl:template match="mei:corr" mode="coreDraft">
        <rdg xmlns="http://www.music-encoding.org/ns/mei">
            <xsl:attribute name="xml:id" select="'c'||uuid:randomUUID()"/>
            <xsl:attribute name="source" select="'#' || $source.id"/>
            <xsl:apply-templates select="node()" mode="#current"></xsl:apply-templates>
        </rdg>
    </xsl:template>
    
    <!-- <reg> is a result of ambiguous control events -->
    <xsl:template match="mei:reg" mode="coreDraft">
        <rdg xmlns="http://www.music-encoding.org/ns/mei">
            <xsl:attribute name="xml:id" select="'c'||uuid:randomUUID()"/>
            <xsl:attribute name="source" select="'#' || $source.id"/>
            <xsl:apply-templates select="node()" mode="#current"/>
        </rdg>
    </xsl:template>
    
    <!-- <expan> is a result of resolving abbreviations like mRpt and cpMark -->
    <xsl:template match="mei:expan" mode="coreDraft">
        <rdg xmlns="http://www.music-encoding.org/ns/mei">
            <xsl:attribute name="xml:id" select="'c'||uuid:randomUUID()"/>
            <xsl:attribute name="source" select="'#' || $source.id"/>
            <xsl:apply-templates select="node()" mode="#current"/>
        </rdg>
    </xsl:template>
    
    <xsl:template match="mei:appInfo" mode="coreDraft">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*" mode="#current"/>
            <application xmlns="http://www.music-encoding.org/ns/mei">
                <xsl:attribute name="xml:id" select="'setupNewCore.xsl_v' || $xsl.version"/>
                <xsl:attribute name="version" select="$xsl.version"/>
                <name>setupNewCore.xsl</name>
                <ptr target="https://github.com/Freischuetz-Digital/Tools/blob/develop/13%20reCore/setupNewCore.xsl"/>
            </application>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="mei:revisionDesc" mode="coreDraft">
        <xsl:copy>
            <change xmlns="http://www.music-encoding.org/ns/mei">
                <xsl:attribute name="n" select="1"/>
                <respStmt>
                    <persName>Johannes Kepper</persName>
                </respStmt>
                <changeDesc>
                    <p>
                        Generated a new core for mov<xsl:value-of select="$mov.n"/> from <xsl:value-of select="$mov.id"/>.xml  with
                        <ptr target="setupNewCore.xsl_v{$xsl.version}"/>. This new
                        core is not directly related to the original core file, and is a direct result of the proofreading process.
                        All change attributes from <xsl:value-of select="$mov.id"/>.xml have been stripped, as they describe the processing
                        of a source, not this core. When tracing the genesis of this file, however, they have to be considered.
                    </p>
                </changeDesc>
                <date isodate="{substring(string(current-date()),1,10)}"/>
            </change>
        </xsl:copy>
    </xsl:template>
        
    <!-- source-specific information to be removed from the core -->
    <xsl:template match="@sameas" mode="coreDraft"/>
    <xsl:template match="@stem.dir" mode="coreDraft"/>
    <xsl:template match="@curvedir" mode="coreDraft"/>
    <xsl:template match="@place" mode="coreDraft"/>
    <xsl:template match="mei:facsimile" mode="coreDraft"/>
    <xsl:template match="@facs" mode="coreDraft"/>
    <xsl:template match="@corresp" mode="coreDraft"/>
    
    <!-- ***SOURCE*MODE*********************************** -->
    
    <!-- preparing references to new xml:ids -->
    <xsl:template match="mei:*[(ancestor::mei:staff) or (ancestor::mei:measure and not(ancestor::mei:staff))]/@xml:id" mode="source">
        <xsl:param name="coreDraft" tunnel="yes"/>
        <xsl:variable name="ref.id" select="."/>
        <xsl:attribute name="xml:id" select="."/>
        <xsl:if test="not(local-name(parent::mei:*) = ('choice'))">
            <xsl:attribute name="sameas" select="'freidi-musicCore.xml#' || $coreDraft//mei:*[@old.id = $ref.id]/@xml:id"/>    
        </xsl:if>
    </xsl:template>
    
    <!-- all @sameas references will be rewritten by the preceding template, which generates a @sameas for everything with an @xml:id -->
    <xsl:template match="mei:measure//mei:*/@sameas" mode="source"/>
    
    <xsl:template match="mei:appInfo" mode="source">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*" mode="#current"/>
            <application xmlns="http://www.music-encoding.org/ns/mei">
                <xsl:attribute name="xml:id" select="'setupNewCore.xsl_v' || $xsl.version"/>
                <xsl:attribute name="version" select="$xsl.version"/>
                <name>setupNewCore.xsl</name>
                <ptr target="https://github.com/Freischuetz-Digital/Tools/blob/develop/13%20reCore/setupNewCore.xsl"/>
            </application>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="mei:revisionDesc" mode="source">
        <xsl:copy>
            <change xmlns="http://www.music-encoding.org/ns/mei">
                <xsl:attribute name="n" select="1"/>
                <respStmt>
                    <persName>Johannes Kepper</persName>
                </respStmt>
                <changeDesc>
                    <p>
                        Prepared mov<xsl:value-of select="$mov.n"/> for re-inclusion in the core with
                        <ptr target="setupNewCore.xsl_v{$xsl.version}"/>. Moved many attributes to the 
                        corresponding core file to reestablish the original core-source relation.
                    </p>
                </changeDesc>
                <date isodate="{substring(string(current-date()),1,10)}"/>
            </change>
        </xsl:copy>
    </xsl:template>
    
    <!-- core-specific information to be removed from the source -->
    <xsl:template match="@pname" mode="source"/>
    <xsl:template match="@dur" mode="source"/>
    <xsl:template match="@dots" mode="source"/>
    <xsl:template match="@oct" mode="source"/>
    <xsl:template match="@accid" mode="source"/>
    <xsl:template match="@accid.ges" mode="source"/>
    <xsl:template match="@grace" mode="source"/>
    <xsl:template match="@stem.mod" mode="source"/>
    <xsl:template match="mei:layer//@tstamp" mode="source"/>
    
    <!-- ***CORE*MODE************************************* -->
        
    <!-- remove temporary helpers -->
    <xsl:template match="@old.id" mode="core"/>
    <xsl:template match="mei:mSpace" mode="core">
        <mRest xmlns="http://www.music-encoding.org/ns/mei">
            <xsl:apply-templates select="node() | @*" mode="#current"/>
        </mRest>
    </xsl:template>
    
    <!-- adjust @startid and @endid -->
    <xsl:template match="@startid" mode="core">
        <xsl:param name="coreDraft" tunnel="yes" as="node()"/>
        
        <xsl:variable name="tokens" select="tokenize(normalize-space(.),' ')" as="xs:string*"/>
        <xsl:variable name="new.refs" as="xs:string*">
            <xsl:for-each select="$tokens">
                <xsl:variable name="current.token" select="." as="xs:string"/>
                <xsl:value-of select="$coreDraft//mei:*[@old.id = substring($current.token,2)]/@xml:id"/>
            </xsl:for-each>
        </xsl:variable>
        <xsl:attribute name="startid" select="'#' || string-join($new.refs,' #')"/>
    </xsl:template>
    <xsl:template match="@endid" mode="core">
        <xsl:param name="coreDraft" tunnel="yes" as="node()"/>
        
        <xsl:variable name="tokens" select="tokenize(normalize-space(.),' ')" as="xs:string*"/>
        <xsl:variable name="new.refs" as="xs:string*">
            <xsl:for-each select="$tokens">
                <xsl:variable name="current.token" select="." as="xs:string"/>
                <xsl:value-of select="$coreDraft//mei:*[@old.id = substring($current.token,2)]/@xml:id"/>
            </xsl:for-each>
        </xsl:variable>
        <xsl:attribute name="endid" select="'#' || string-join($new.refs,' #')"/>
    </xsl:template>
    
    <!-- standard copy template for all modes -->
    <xsl:template match="node() | @*" mode="#all">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
</xsl:stylesheet>