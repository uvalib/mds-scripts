<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    xmlns:xpf="http://www.w3.org/2005/xpath-functions" xmlns:numishare="https://github.com/ewg118/numishare" xmlns:mods="http://www.loc.gov/mods/v3"
    xmlns:mods2la="https://linked.art/ns/v1/linked-art.json" exclude-result-prefixes="#all" version="3.0">

    <xsl:include href="json-metamodel.xsl"/>

    <xsl:output method="text" encoding="UTF-8" indent="yes"/>

    <xsl:param name="pid"/>

    <xsl:variable name="roles" as="node()*">
        <xsl:copy-of select="document('roles.xml')"/>
    </xsl:variable>

    <xsl:template match="/">
        <xsl:variable name="model" as="item()*">
            <_object>
                <xsl:apply-templates select="//mods:mods"/>
            </_object>
        </xsl:variable>

        <xsl:apply-templates select="$model"/>

    </xsl:template>

    <xsl:template match="mods:mods">
        <__context>https://linked.art/ns/v1/linked-art.json</__context>
        <id>https://search.lib.virginia.edu/sources/images/items/uva-lib:2372197</id>
        <type>HumanMadeObject</type>
        <_label>
            <xsl:value-of select="mods2la:generateTitle(mods:titleInfo)"/>
        </_label>

        <identified_by>
            <_array>
                <xsl:apply-templates select="mods:titleInfo[not(@type)]"/>
                <xsl:apply-templates select="mods:relatedItem[@type = 'original']/mods:identifier[@type = 'local']"/>
            </_array>
        </identified_by>

        <!-- HMO classification -->
        <xsl:if test="mods:genre[@authority]">
            <classified_as>
                <_array>
                    <xsl:apply-templates select="mods:genre[@authority]"/>
                </_array>
            </classified_as>
        </xsl:if>

        <!-- abstract -->
        <xsl:if test="mods:abstract">
            <referred_to_by>
                <xsl:apply-templates select="mods:abstract"/>
            </referred_to_by>
        </xsl:if>

        <!-- production event -->
        <xsl:if test="mods:name or mods:relatedItem[@type = 'original']/mods:originInfo or mods:originInfo">
            <produced_by>
                <_object>
                    <type>Production</type>
                    
                    <!-- accommodate differing originInfo, depending on MARC source or manual MODS -->
                    <xsl:choose>
                        <xsl:when test="mods:relatedItem[@type = 'original']/mods:originInfo">
                            <xsl:apply-templates select="mods:relatedItem[@type = 'original']/mods:originInfo"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:apply-templates select="mods:originInfo"/>
                        </xsl:otherwise>
                    </xsl:choose>

                    <!-- if more than one role is reported among the name(s), then split the production activity into parts -->
                    <xsl:choose>
                        <xsl:when test="count(distinct-values(mods:name/mods:role/mods:roleTerm[@authority = 'marcrelator']/@valueURI)) &gt; 1 and count(mods:name) &gt; 1">
                            <part>
                                <_array>
                                    <xsl:for-each select="mods:name">
                                        <_object>
                                            <type>Production</type>
                                            <carried_out_by>
                                                <_array>
                                                    <xsl:apply-templates select="self::node()" mode="production"/>
                                                </_array>
                                            </carried_out_by>

                                            <xsl:if test="mods:role/mods:roleTerm[@authority = 'marcrelator' and @valueURI]">
                                                <technique>
                                                    <_array>
                                                        <xsl:for-each select="mods:role/mods:roleTerm[@authority = 'marcrelator' and @valueURI]">
                                                            <xsl:variable name="uri" select="@valueURI"/>

                                                            <_object>
                                                                <id>
                                                                    <xsl:value-of select="$roles//role[@marcrelator = $uri]/@technique"/>
                                                                </id>
                                                                <type>Type</type>
                                                                <_label>
                                                                    <xsl:value-of select="$roles//role[@marcrelator = $uri]/@techniqueLabel"/>
                                                                </_label>
                                                            </_object>
                                                        </xsl:for-each>
                                                    </_array>
                                                </technique>
                                            </xsl:if>
                                        </_object>
                                    </xsl:for-each>
                                </_array>
                            </part>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:if test="mods:name">
                                <carried_out_by>
                                    <_array>
                                        <xsl:apply-templates select="mods:name" mode="production"/>
                                    </_array>
                                </carried_out_by>
                            </xsl:if>

                            <xsl:if test="count(mods:name/mods:role/mods:roleTerm[@authority = 'marcrelator' and @valueURI]) &gt; 0">
                                <technique>
                                    <_array>
                                        <xsl:for-each select="distinct-values(mods:name/mods:role/mods:roleTerm[@authority = 'marcrelator']/@valueURI)">
                                            <xsl:variable name="uri" select="."/>

                                            <_object>
                                                <id>
                                                    <xsl:value-of select="$roles//role[@marcrelator = $uri]/@technique"/>
                                                </id>
                                                <type>Type</type>
                                                <_label>
                                                    <xsl:value-of select="$roles//role[@marcrelator = $uri]/@techniqueLabel"/>
                                                </_label>
                                            </_object>
                                        </xsl:for-each>
                                    </_array>
                                </technique>
                            </xsl:if>
                        </xsl:otherwise>
                    </xsl:choose>

                </_object>
            </produced_by>
        </xsl:if>
        
        <!-- VisualItems depicted or represented in image -->
        <xsl:if test="mods:subject[@valueURI or @authority]">
            <shows>
                <_array>
                    <_object>
                        <type>VisualItem</type>
                        <_label>Visual content of <xsl:value-of select="mods:titleInfo/mods:title"/></_label>

                        <!-- Linked Art: Still life paintings, photographs and many other artworks depict things which we can 
                            recognize by type or classification, but not as unique or individual entities in reality. -->
                        <xsl:if test="mods:subject[@valueURI and not(@authority)]/mods:topic">
                            <represents_instance_of_type>
                                <_array>
                                    <xsl:apply-templates select="mods:subject[@valueURI and not(@authority)][mods:topic]"/>
                                </_array>
                            </represents_instance_of_type>
                        </xsl:if>

                        <!-- Linked Art: Subjects are the concepts or things that the artwork evokes, as opposed to an 
                            object (real or imaginary) that is depicted by the artwork. -->
                        <xsl:if test="mods:subject[@valueURI and @authority = 'lcsh'][mods:topic] or mods:subject[@authority = 'tgn']/descendant::*[@valueURI]">
                            <about>
                                <_array>
                                    <xsl:apply-templates select="mods:subject[@valueURI and @authority = 'lcsh'][mods:topic]"/>
                                    <xsl:apply-templates select="mods:subject[@authority = 'tgn']/descendant::*[last()][@valueURI]"/>
                                </_array>
                            </about>
                        </xsl:if>

                    </_object>
                </_array>
            </shows>
        </xsl:if>
        
        <!-- collection -->
        <xsl:if test="mods:relatedItem[@type = 'host' and lower-case(@displayLabel) = 'part of'][mods:location/mods:url]">
            <member_of>
                <_array>
                    <xsl:apply-templates select="mods:relatedItem[@type = 'host' and lower-case(@displayLabel) = 'part of'][mods:location/mods:url]"/>
                </_array>
            </member_of>
        </xsl:if>

    </xsl:template>

    <!-- titles and identifiers -->
    <xsl:template match="mods:titleInfo">
        <_object>
            <type>Name</type>
            <content>
                <xsl:value-of select="mods2la:generateTitle(.)"/>
            </content>
            <classified_as>
                <_array>
                    <_object>
                        <id>http://vocab.getty.edu/aat/300404670</id>
                        <_label>preferred forms</_label>
                        <type>Type</type>
                    </_object>
                </_array>
            </classified_as>
        </_object>
    </xsl:template>

    <xsl:template match="mods:identifier[@type = 'local']">
        <xsl:if test="contains(lower-case(@displayLabel), 'call number')">
            <_object>
                <type>Identifier</type>
                <content>
                    <xsl:value-of select="."/>
                </content>
                <classified_as>
                    <_array>
                        <_object>
                            <id>http://vocab.getty.edu/aat/300311706</id>
                            <_label>call numbers</_label>
                            <type>Type</type>
                        </_object>
                    </_array>
                </classified_as>
            </_object>
        </xsl:if>
    </xsl:template>

    <!-- classifications -->
    <xsl:template match="mods:genre">
        <_object>
            <xsl:if test="@valueURI">
                <id>
                    <xsl:value-of select="@valueURI"/>
                </id>
            </xsl:if>
            <type>Type</type>
            <_label>
                <xsl:value-of select="."/>
            </_label>
            <classified_as>
                <_array>
                    <_object>
                        <id>http://vocab.getty.edu/aat/300435443</id>
                        <type>Type</type>
                        <_label>Type of Work</_label>
                    </_object>
                </_array>
            </classified_as>
        </_object>
    </xsl:template>

    <xsl:template match="mods:abstract">
        <_array>
            <_object>
                <type>LinguisticObject</type>
                <content>
                    <xsl:value-of select="."/>
                </content>
                <classified_as>
                    <_array>
                        <_object>
                            <id>http://vocab.getty.edu/aat/300435416</id>
                            <type>Type</type>
                            <_label>Description</_label>
                            <classified_as>
                                <_array>
                                    <_object>
                                        <id>http://vocab.getty.edu/aat/300418049</id>
                                        <type>Type</type>
                                        <_label>Brief Text</_label>
                                    </_object>
                                </_array>
                            </classified_as>
                        </_object>
                    </_array>
                </classified_as>
            </_object>
        </_array>
    </xsl:template>

    <!-- production properties -->
    <xsl:template match="mods:originInfo">
        <xsl:apply-templates select="mods:dateCreated"/>
    </xsl:template>

    <xsl:template match="mods:dateCreated">
        <timespan>
            <_object>
                <type>TimeSpan</type>
                <_label>
                    <xsl:value-of select="."/>
                </_label>
                <xsl:if test="@encoding = 'edtf' or @encoding = 'iso8601' or @encoding = 'marc'">
                    <xsl:variable name="dateRange" as="node()*">
                        <xsl:if test="unparsed-text-available('http://127.0.0.1:8000/')">
                            <xsl:copy-of select="json-to-xml(unparsed-text(concat('http://127.0.0.1:8000/parse?date=', .)))"/>
                        </xsl:if>
                    </xsl:variable>

                    <xsl:if test="$dateRange/xpf:map/*">
                        <begin_of_the_begin>
                            <xsl:value-of select="concat($dateRange/xpf:map/xpf:string[@key = 'fromDate'], 'T00:00:00Z')"/>
                        </begin_of_the_begin>
                        <end_of_the_end>
                            <xsl:value-of select="concat($dateRange/xpf:map/xpf:string[@key = 'toDate'], 'T23:59:59Z')"/>
                        </end_of_the_end>
                    </xsl:if>
                </xsl:if>
            </_object>
        </timespan>
    </xsl:template>

    <xsl:template match="mods:name" mode="production">
        <_object>
            <xsl:if test="@valueURI">
                <id>
                    <xsl:value-of select="@valueURI"/>
                </id>
            </xsl:if>
            <type>
                <xsl:value-of select="
                        if (@type = 'personal') then
                            'Person'
                        else
                            'Group'"/>
            </type>
            <_label>
                <xsl:choose>
                    <xsl:when test="count(mods:namePart) = 1">
                        <xsl:value-of select="mods:namePart"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:choose>
                            <xsl:when test="mods:namePart[@type = 'family'] and mods:namePart[@type = 'given']">
                                <xsl:value-of select="mods:namePart[@type = 'family']"/>
                                <xsl:text>, </xsl:text>
                                <xsl:value-of select="mods:namePart[@type = 'given']"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="mods:namePart[not(@type)]"/>
                            </xsl:otherwise>
                        </xsl:choose>
                        <xsl:if test="mods:namePart[@type = 'date']">
                            <xsl:text>, </xsl:text>
                            <xsl:value-of select="mods:namePart[@type = 'date']"/>
                        </xsl:if>
                    </xsl:otherwise>
                </xsl:choose>
            </_label>
        </_object>
    </xsl:template>

    <!-- VisualItems -->
    <xsl:template match="mods:subject[@valueURI][mods:topic]">
        <_object>
            <id>
                <xsl:value-of select="@valueURI"/>
            </id>
            <type>Type</type>
            <_label>
                <xsl:value-of select="string-join(*, '--')"/>
            </_label>
        </_object>
    </xsl:template>
    
    <!-- geographic subjects -->
    <xsl:template match="mods:geographic | *[parent::mods:hierarchicalGeographic]">
        <_object>
            <id>
                <xsl:value-of select="@valueURI"/>               
            </id>
            <type>Place</type>
            <_label>
                <xsl:value-of select="."/>
            </_label>
        </_object>
    </xsl:template>
    
    <!-- la:Set (collection) -->
    <xsl:template match="mods:relatedItem[@type = 'host' and lower-case(@displayLabel) = 'part of'][mods:location/mods:url]">
        <_object>
            <id>
                <xsl:value-of select="mods:location/mods:url"/>
            </id>
            <type>Set</type>
            <_label>
                <xsl:value-of select="mods2la:generateTitle(mods:titleInfo)"/>
            </_label>
        </_object>
    </xsl:template>

    <!-- FUNCTIONS -->
    <xsl:function name="mods2la:generateTitle">
        <xsl:param name="titleInfo"/>

        <xsl:value-of select="$titleInfo/mods:title"/>
        <xsl:if test="$titleInfo/mods:subTitle">
            <xsl:text>: </xsl:text>
            <xsl:value-of select="$titleInfo/mods:subTitle"/>
        </xsl:if>
    </xsl:function>

</xsl:stylesheet>
