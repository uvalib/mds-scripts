<?xml version="1.0" encoding="UTF-8"?>
<!-- Author: Ethan Gruber
    Date: May 2026
    Function: Perform a basic XPath-based error report on ALTO XML files for newspaper segmentation -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    xmlns:alto="http://www.loc.gov/standards/alto/ns-v2#"
    exclude-result-prefixes="#all"
    version="2.0">
    
    <xsl:output method="xml" indent="yes"/>
    
    <!-- filename -->
    <xsl:param name="filename" as="xs:string"/>
    
    <xsl:template match="/">
        <xsl:variable name="errors" as="node()*">
            <errors>
                <xsl:apply-templates select="descendant::alto:TextBlock"/>
            </errors>
        </xsl:variable>
        
        <xsl:choose>
            <xsl:when test="count($errors//error) &gt; 0">
                <response error="true">
                    <xsl:copy-of select="$errors"/>
                </response>
            </xsl:when>
            <xsl:otherwise>
                <response error="false">No errors reported.</response>
            </xsl:otherwise>
        </xsl:choose>
        
    </xsl:template>
    
    
    <xsl:template match="alto:TextBlock">
        <xsl:if test="not(child::*)">
            <error><xsl:value-of select="$filename"/>: TextBlock <xsl:value-of select="@ID"/>: no content.</error>
        </xsl:if>
        
        <!-- ensure that a non-empty TextBlock has a valid language code -->
        <xsl:if test="child::alto:TextLine and not(string-length(@language) = 2)">
            <error><xsl:value-of select="$filename"/>: TextBlock <xsl:value-of select="@ID"/>: invalid language.</error>
        </xsl:if>
        <xsl:apply-templates select="descendant::alto:String" mode="content-length"/>
    </xsl:template>
    
    <!-- ensure the number of characters in the content is equal to the number of characters assigned to the certainty -->
    <xsl:template match="alto:String" mode="content-length">
        <xsl:if test="not(string-length(@CONTENT) = string-length(@CC))">
            <error><xsl:value-of select="$filename"/>: <xsl:value-of select="@ID"/>: content length mismatch</error>
        </xsl:if>
    </xsl:template>
    
</xsl:stylesheet>