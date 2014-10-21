<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  exclude-result-prefixes="xs"
  version="2.0">
  
  <xsl:variable name="properties" select="doc('properties.xml')"/>
  
  <xsl:param name="FreiDi-Tools_version" select="$properties//FreiDi-Tools_version"/>
  <xsl:param name="transformationOperator" select="$properties//transformationOperator"/>
  
</xsl:stylesheet>