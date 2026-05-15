<?xml version="1.0" encoding="UTF-8"?>
<!-- Author: Ethan Gruber
    Date: April 2026
    Function: Content validator for Digital Divide vendor METS XML with embedded MODS metadata -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    xmlns:mets="http://www.loc.gov/METS/" xmlns:mods="http://www.loc.gov/mods/v3" xmlns:mix="http://www.loc.gov/mix/" xmlns:xlink="http://www.w3.org/1999/xlink"
    xmlns:alto="http://www.loc.gov/standards/alto/ns-v2#" exclude-result-prefixes="#all" version="2.0">

    <xsl:output method="xml" indent="yes"/>

    <!-- relative path string to folders containing XML files: document() function calls are relative to XSLT stylesheet. -->
    <xsl:param name="path" as="xs:string"/>

    <!-- filename -->
    <xsl:param name="filename" as="xs:string"/>

    <!-- load ALTO XML files referenced in the mets:fileGrp -->
    <xsl:variable name="alto" as="node()*">
        <mets:fileGrp>
            <xsl:for-each select="descendant::mets:fileGrp[@ID = 'ALTOGRP']/mets:file">
                <mets:file ID="{@ID}">
                    <!-- replace relative path in XML file with path relative to XSLT for processing, ensuring it uses forward slashes for Linux -->
                    <xsl:variable name="file" select="replace(mets:FLocat/@xlink:href, 'file://.', replace($path, '\\', '/'))"/>

                    <xsl:if test="doc-available($file)">
                        <xsl:copy-of select="document($file)"/>
                    </xsl:if>
                </mets:file>
            </xsl:for-each>
        </mets:fileGrp>
    </xsl:variable>

    <xsl:template match="/">
        <xsl:variable name="errors" as="node()*">
            <errors>
                <!-- validate semantic content of MODS metadata -->
                <xsl:apply-templates select="descendant::mods:*[starts-with(local-name(), 'date') or ends-with(local-name(), 'Date')]"/>

                <!-- validate structure of METS -->
                <xsl:apply-templates select="descendant::mets:dmdSec[not(@ID = 'MODSMD_PRINT') and not(@ID = 'MODSMD_ELEC')]"/>
            </errors>

        </xsl:variable>

        <xsl:choose>
            <xsl:when test="count($errors//error) &gt; 0">
                <response error="true">
                    <xsl:copy-of select="$errors/*"/>
                </response>
            </xsl:when>
            <xsl:otherwise>
                <response error="false">No errors reported.</response>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- MODS BIBLIOGRAPHIC METADATA VALIDATION -->
    <xsl:template match="mods:*[starts-with(local-name(), 'date') or ends-with(local-name(), 'Date')]">
        <xsl:if test="not(@encoding = 'iso8601')">
            <error><xsl:value-of select="$filename"/>: <xsl:value-of select="name()"/> does not have iso8601 encoding attribute</error>
        </xsl:if>
        <xsl:if test="not(. castable as xs:date or . castable as xs:gYearMonth or . castable as xs:gYear)">
            <error>
                <xsl:value-of select="$filename"/>: <xsl:value-of select="name()"/> does not have a valid ISO date: <xsl:value-of select="."/>
            </error>
        </xsl:if>
    </xsl:template>

    <!-- METS STRUCTURE VALIDATION -->
    <!-- ensure all articles defined in dmdSec exist in the StructMap -->
    <xsl:template match="mets:dmdSec">
        <xsl:variable name="id" select="@ID"/>
        <xsl:variable name="hasTitle" select="boolean(descendant::mods:title)" as="xs:boolean"/>

        <xsl:choose>
            <xsl:when test="//mets:div[@DMDID = $id]">
                <xsl:apply-templates select="//mets:div[@DMDID = $id]">
                    <xsl:with-param name="hasTitle" select="$hasTitle" as="xs:boolean"/>
                </xsl:apply-templates>
            </xsl:when>
            <xsl:otherwise>
                <error><xsl:value-of select="$filename"/>: dmdSec <xsl:value-of select="@ID"/>: No div in structMap</error>
            </xsl:otherwise>
        </xsl:choose>

    </xsl:template>

    <!-- ensure the area element exists in the div -->
    <xsl:template match="mets:div">
        <xsl:param name="hasTitle" as="xs:boolean"/>
        <xsl:variable name="id" select="@DMDID"/>

        <!-- ignore lack of title if the section is for advertisements -->
        <xsl:if test="$hasTitle = false() and not(descendant::mets:div[@TYPE = 'ADVERTISEMENT'])">
            <error><xsl:value-of select="$filename"/>: dmdSec <xsl:value-of select="@ID"/>: No MODS title</error>
        </xsl:if>

        <xsl:choose>
            <xsl:when test="descendant::mets:fptr/mets:area">
                <xsl:apply-templates select="descendant::mets:fptr/mets:area">
                    <xsl:with-param name="id" select="$id"/>
                </xsl:apply-templates>
            </xsl:when>
            <xsl:otherwise>
                <error><xsl:value-of select="$filename"/>: div <xsl:value-of select="@ID"/>: No associated area element, or missing attributes</error>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- validate area -->
    <xsl:template match="mets:area">
        <xsl:param name="id"/>

        <xsl:variable name="fileId" select="@FILEID"/>
        <xsl:variable name="blockID" select="@BEGIN"/>

        <xsl:choose>
            <xsl:when test="$alto//mets:file[@ID = $fileId]">

                <xsl:if test="not($alto//mets:file[@ID = $fileId]/descendant::*[@ID = $blockID])">
                    <error>
                        <xsl:value-of select="$filename"/>: area <xsl:value-of select="$id"/>: Block ID <xsl:value-of select="$blockID"/> not found in ALTO XML. </error>
                </xsl:if>

            </xsl:when>
            <xsl:otherwise>
                <error><xsl:value-of select="$filename"/>: area <xsl:value-of select="$id"/>: File ID not found in ALTO fileGrp</error>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

</xsl:stylesheet>
