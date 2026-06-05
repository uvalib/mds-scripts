<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.loc.gov/MARC21/slim"
  xmlns:marc="http://www.loc.gov/MARC21/slim"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="marc xs"
  version="2.0">
  <xsl:output method="xml" indent="yes"/>
  <xsl:strip-space elements="*"/>

  <!-- PARAMETERS -->
  <xsl:param name="keep999s" select="'false'"/>

  <!--<xsl:param name="force" select="'false'"/>-->

  <!-- INCLUDES/IMPORTS -->
  <xsl:import href="marcArticleList.xsl"/>

  <xsl:import href="marcCountryList.xsl"/>

  <!-- GLOBAL VARIABLES -->
  <xsl:variable name="marcDesc">
    <xsl:copy-of select="document('marcDesc.xml')"/>
  </xsl:variable>

  <xsl:variable name="progName">
    <xsl:text>fixMarcErrors.xsl</xsl:text>
  </xsl:variable>

  <xsl:variable name="progVersion">
    <xsl:text>v. 1.0</xsl:text>
  </xsl:variable>

  <xsl:variable name="fillSpaces">
    <xsl:text>&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;&#32;</xsl:text>
  </xsl:variable>

  <xsl:variable name="fillPipes">
    <xsl:text>||||||||||||||||||</xsl:text>
  </xsl:variable>

  <!-- UTILITIES / NAMED TEMPLATES -->
  <xsl:template name="createFixedFieldValue">
    <xsl:param name="legalValues"/>
    <xsl:param name="position"/>
    <xsl:param name="length"/>
    <!--<xsl:param name="defaultValue"/>-->
    <xsl:choose>
      <xsl:when test="number($position) = NaN">
        <xsl:message terminate="yes">Record <xsl:value-of
            select="ancestor::*:record/*:controlfield[@tag = '001']"/>: $position is not a
          number!</xsl:message>
      </xsl:when>
      <xsl:when test="number($length) = NaN">
        <xsl:message terminate="yes">Record <xsl:value-of
            select="ancestor::*:record/*:controlfield[@tag = '001']"/>: $length is not a
          number!</xsl:message>
      </xsl:when>
      <xsl:when test="normalize-space($legalValues) = ''">
        <xsl:message terminate="yes">Record <xsl:value-of
            select="ancestor::*:record/*:controlfield[@tag = '001']"/>: $legalValues is a
          zero-length string!</xsl:message>
      </xsl:when>
      <!--<xsl:when test="normalize-space($defaultValue) = ''">
        <xsl:message>$defaultValue is a zero-length string!</xsl:message>
      </xsl:when>-->
    </xsl:choose>
    <xsl:variable name="illegalValues">
      <xsl:choose>
        <xsl:when test="matches($legalValues, '^\[')">
          <xsl:value-of
            select="replace(replace($legalValues, '^\[', '[^'), '\{\d+\}$', '')"/>
        </xsl:when>
        <xsl:when test="matches($legalValues, '^\(')">
          <xsl:text>⁋</xsl:text>
        </xsl:when>
      </xsl:choose>
    </xsl:variable>
    <xsl:choose>
      <!-- Contains legal and illegal values -->
      <xsl:when
        test="matches(substring(., $position, $length), $legalValues) and matches(substring(., $position, $length), $illegalValues)">
        <!-- Delete illegal values -->
        <xsl:variable name="goodValues">
          <xsl:value-of
            select="replace(substring(., $position, $length), $illegalValues, '')"/>
        </xsl:variable>
        <!-- Output left-justified legal values -->
        <xsl:value-of
          select="substring(concat($goodValues, '&#32;&#32;&#32;&#32;'), 1, $length)"/>
      </xsl:when>
      <!-- Contains legal values -->
      <xsl:when test="matches(substring(., $position, $length), $legalValues)">
        <xsl:value-of select="substring(., $position, $length)"/>
      </xsl:when>
      <!-- Contains only illegal values; replace with default value or fill chars -->
      <xsl:otherwise>
        <xsl:value-of select="substring($fillPipes, 1, $length)"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Join non-repeatable subfields into a single subfield -->
  <xsl:template name="compressSubfields">
    <xsl:param name="tag"/>
    <xsl:param name="subfieldList"/>
    <!-- First subfield on the "stack" in $subfieldList -->
    <xsl:variable name="left">
      <xsl:value-of select="$subfieldList//*:subfield[1]/@code"/>
    </xsl:variable>
    <!-- Repeatability of the first subfield -->
    <xsl:variable name="repeat">
      <xsl:value-of
        select="$marcDesc//*:datafield[@tag = $tag]/*:subfield[@code = $left]/@repeat"/>
    </xsl:variable>
    <xsl:choose>
      <!-- Non-repeatable subfield -->
      <xsl:when test="$repeat = 'NR'">
        <subfield>
          <xsl:attribute name="code">
            <xsl:value-of select="$left"/>
          </xsl:attribute>
          <xsl:variable name="separator">
            <xsl:choose>
              <xsl:when test="$subfieldList//*:subfield[@code = $left][matches(normalize-space(.), '[\.,;:/]$')]">
                <xsl:text>&#32;</xsl:text>
              </xsl:when>
              <xsl:otherwise>
                <xsl:text>;&#32;</xsl:text>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>
          <xsl:value-of select="string-join($subfieldList//*:subfield[@code = $left], $separator)"/>
        </subfield>
      </xsl:when>
      <!-- Repeatable subfield -->
      <xsl:otherwise>
        <subfield>
          <xsl:attribute name="code">
            <xsl:value-of select="$left"/>
          </xsl:attribute>
          <xsl:value-of select="$subfieldList//*:subfield[1]"/>
        </subfield>
      </xsl:otherwise>
    </xsl:choose>
    <!-- Adjust list of remaining subfields based on repeatability of the subfield just processed -->
    <xsl:variable name="remainingSubfields">
      <xsl:choose>
        <xsl:when test="$repeat = 'NR'">
          <xsl:copy-of
            select="$subfieldList//*:subfield[position() &gt; 1 and @code != $left]"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:copy-of select="$subfieldList//*:subfield[position() &gt; 1]"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <!-- If there are subfields remaining, recurse -->
    <xsl:if test="$remainingSubfields//*:subfield">
      <xsl:call-template name="compressSubfields">
        <xsl:with-param name="tag">
          <xsl:value-of select="$tag"/>
        </xsl:with-param>
        <xsl:with-param name="subfieldList">
          <xsl:copy-of select="$remainingSubfields"/>
        </xsl:with-param>
      </xsl:call-template>
    </xsl:if>
  </xsl:template>

  <!-- Create 006 based on type of material -->
  <xsl:template name="materialSpecific006">
    <!-- Legal values are read from $marcDesc and leading and trailing apostrophes from @values
      are deleted. Alphabetic case is significant in comparisons. "A" doesn't match 'a'! -->
    <xsl:choose>
      <!-- BK -->
      <xsl:when test="matches(substring(., 1, 1), '[at]')">
        <xsl:variable name="materialType">BK</xsl:variable>
        <xsl:variable name="materialForm">
          <xsl:value-of select="substring(., 1, 1)"/>
        </xsl:variable>
        <xsl:variable name="illus">
          <xsl:variable name="position">2</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 006 and @materialType = $materialType]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 006 and @materialType = $materialType]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="audience">
          <xsl:variable name="position">6</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 006 and @materialType = $materialType]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 006 and @materialType = $materialType]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="itemForm">
          <xsl:variable name="position">7</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 006 and @materialType = $materialType]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 006 and @materialType = $materialType]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="contentNature">
          <xsl:variable name="position">8</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 006 and @materialType = $materialType]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 006 and @materialType = $materialType]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="govPub">
          <xsl:variable name="position">12</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 006 and @materialType = $materialType]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 006 and @materialType = $materialType]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="confPub">
          <xsl:variable name="position">13</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 006 and @materialType = $materialType]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 006 and @materialType = $materialType]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="festschrift">
          <xsl:variable name="position">14</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 006 and @materialType = $materialType]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 006 and @materialType = $materialType]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="index">
          <xsl:variable name="position">15</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 006 and @materialType = $materialType]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 006 and @materialType = $materialType]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="undef16">
          <xsl:value-of select="substring($fillSpaces, 1, 1)"/>
        </xsl:variable>
        <xsl:variable name="litForm">
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace($marcDesc//*:controlfield[@tag = 006 and @materialType = $materialType]/*:code[@position = &quot;17&quot;]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;)"
            />
          </xsl:variable>
          <xsl:choose>
            <!-- Purported to be non-fiction -->
            <xsl:when test="matches(substring(., 17, 1), '0')">
              <xsl:choose>
                <!-- When classed in "P" and no 6xx fields, mark as fiction -->
                <xsl:when
                  test="../*:datafield[matches(@tag, '999')]/*:subfield[@code = 'a'][matches(., '^P')] and not(../*:datafield[matches(@tag, '^6')])">
                  <text>1</text>
                </xsl:when>
                <!-- Retain non-fiction designation -->
                <xsl:otherwise>
                  <text>0</text>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:when>
            <!-- Purported to be fiction -->
            <xsl:when test="matches(substring(., 17, 1), '1')">
              <xsl:choose>
                <!-- When not classed in "P" and 6xx fields are present, mark as non-fiction -->
                <xsl:when
                  test="not(../*:datafield[matches(@tag, '999')]/*:subfield[@code = 'a'][matches(., '^P')]) and ../*:datafield[matches(@tag, '^6')]">
                  <text>0</text>
                </xsl:when>
                <!-- Retain fiction designation -->
                <xsl:otherwise>
                  <text>1</text>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:when>
            <!-- Pass through valid litForm value -->
            <xsl:when test="matches(substring(., 17, 1), $legalValues)">
              <xsl:value-of select="replace(substring(., 17, 1), '\p{Zs}', '&#32;')"/>
            </xsl:when>
            <!-- "No attempt to code" default value -->
            <xsl:otherwise>
              <xsl:value-of select="substring($fillPipes, 1, 1)"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="biography">
          <xsl:variable name="position">18</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 006 and @materialType = $materialType]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 006 and @materialType = $materialType]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:value-of
          select="concat($materialForm, $illus, $audience, $itemForm, $contentNature, $govPub, $confPub, $festschrift, $index, $undef16, $litForm, $biography)"
        />
      </xsl:when>
      <!-- CF -->
      <xsl:when test="matches(substring(., 1, 1), '[m]')">
        <xsl:variable name="materialType">CF</xsl:variable>
        <xsl:variable name="materialForm">
          <xsl:value-of select="substring(., 1, 1)"/>
        </xsl:variable>
        <xsl:variable name="undef2">
          <xsl:value-of select="substring($fillSpaces, 1, 4)"/>
        </xsl:variable>
        <xsl:variable name="audience">
          <xsl:variable name="position">6</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 006 and @materialType = $materialType]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 006 and @materialType = $materialType]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="itemForm">
          <xsl:variable name="position">7</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 006 and @materialType = $materialType]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 006 and @materialType = $materialType]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="undef8">
          <xsl:value-of select="substring($fillSpaces, 1, 2)"/>
        </xsl:variable>
        <xsl:variable name="fileType">
          <xsl:variable name="position">10</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 006 and @materialType = $materialType]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 006 and @materialType = $materialType]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="undef11">
          <xsl:value-of select="substring($fillSpaces, 1, 1)"/>
        </xsl:variable>
        <xsl:variable name="govPub">
          <xsl:variable name="position">12</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 006 and @materialType = $materialType]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 006 and @materialType = $materialType]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="undef13">
          <xsl:value-of select="substring($fillSpaces, 1, 6)"/>
        </xsl:variable>
        <xsl:value-of
          select="concat($materialForm, $undef2, $audience, $itemForm, $undef8, $fileType, $undef11, $govPub, $undef13)"
        />
      </xsl:when>
      <!-- MP -->
      <xsl:when test="matches(substring(., 1, 1), '[ef]')">
        <xsl:variable name="materialType">MP</xsl:variable>
        <xsl:variable name="materialForm">
          <xsl:value-of select="substring(., 1, 1)"/>
        </xsl:variable>
        <xsl:variable name="relief">
          <xsl:variable name="position">2</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 006 and @materialType = $materialType]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 006 and @materialType = $materialType]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="projection">
          <xsl:variable name="position">6</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 006 and @materialType = $materialType]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 006 and @materialType = $materialType]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="undef8">
          <xsl:value-of select="substring($fillSpaces, 1, 1)"/>
        </xsl:variable>
        <xsl:variable name="cartographicType">
          <xsl:variable name="position">9</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 006 and @materialType = $materialType]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 006 and @materialType = $materialType]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="undef10">
          <xsl:value-of select="substring($fillSpaces, 1, 2)"/>
        </xsl:variable>
        <xsl:variable name="govPub">
          <xsl:variable name="position">12</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 006 and @materialType = $materialType]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 006 and @materialType = $materialType]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="itemForm">
          <xsl:variable name="position">13</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 006 and @materialType = $materialType]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 006 and @materialType = $materialType]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="undef14">
          <xsl:value-of select="substring($fillSpaces, 1, 1)"/>
        </xsl:variable>
        <xsl:variable name="index">
          <xsl:variable name="position">15</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 006 and @materialType = $materialType]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 006 and @materialType = $materialType]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="undef16">
          <xsl:value-of select="substring($fillSpaces, 1, 1)"/>
        </xsl:variable>
        <xsl:variable name="specialFormat">
          <xsl:variable name="position">17</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 006 and @materialType = $materialType]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 006 and @materialType = $materialType]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:value-of
          select="concat($materialForm, $relief, $projection, $undef8, $cartographicType, $undef10, $govPub, $itemForm, $undef14, $index, $undef16, $specialFormat)"
        />
      </xsl:when>
      <!-- MU -->
      <xsl:when test="matches(substring(., 1, 1), '[cdij]')">
        <xsl:variable name="materialType">MU</xsl:variable>
        <xsl:variable name="materialForm">
          <xsl:value-of select="substring(., 1, 1)"/>
        </xsl:variable>
        <xsl:variable name="compositionForm">
          <xsl:variable name="position">2</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 006 and @materialType = $materialType]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 006 and @materialType = $materialType]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="musicFormat">
          <xsl:variable name="position">4</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 006 and @materialType = $materialType]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 006 and @materialType = $materialType]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="musicParts">
          <xsl:variable name="position">5</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 006 and @materialType = $materialType]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 006 and @materialType = $materialType]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="audience">
          <xsl:variable name="position">6</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 006 and @materialType = $materialType]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 006 and @materialType = $materialType]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="itemForm">
          <xsl:variable name="position">7</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 006 and @materialType = $materialType]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 006 and @materialType = $materialType]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="accMatter">
          <xsl:variable name="position">8</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 006 and @materialType = $materialType]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 006 and @materialType = $materialType]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="literaryText">
          <xsl:variable name="position">14</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 006 and @materialType = $materialType]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 006 and @materialType = $materialType]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="undef16">
          <xsl:value-of select="substring($fillSpaces, 1, 1)"/>
        </xsl:variable>
        <xsl:variable name="transpoArrangement">
          <xsl:variable name="position">17</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 006 and @materialType = $materialType]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 006 and @materialType = $materialType]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="undef18">
          <xsl:value-of select="substring($fillSpaces, 1, 1)"/>
        </xsl:variable>
        <xsl:value-of
          select="concat($materialForm, $compositionForm, $musicFormat, $musicParts, $audience, $itemForm, $accMatter, $literaryText, $undef16, $transpoArrangement, $undef18)"
        />
      </xsl:when>
      <!-- CR -->
      <xsl:when test="matches(substring(., 1, 1), '[s]')">
        <xsl:variable name="materialType">CR</xsl:variable>
        <xsl:variable name="materialForm">
          <xsl:value-of select="substring(., 1, 1)"/>
        </xsl:variable>
        <xsl:variable name="frequency">
          <xsl:variable name="position">2</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 006 and @materialType = $materialType]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 006 and @materialType = $materialType]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="regularity">
          <xsl:variable name="position">3</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 006 and @materialType = $materialType]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 006 and @materialType = $materialType]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="undef4">
          <xsl:value-of select="substring($fillSpaces, 1, 1)"/>
        </xsl:variable>
        <xsl:variable name="resourceType">
          <xsl:variable name="position">5</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 006 and @materialType = $materialType]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 006 and @materialType = $materialType]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="originalForm">
          <xsl:variable name="position">6</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 006 and @materialType = $materialType]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 006 and @materialType = $materialType]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="itemForm">
          <xsl:variable name="position">7</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 006 and @materialType = $materialType]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 006 and @materialType = $materialType]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="workNature">
          <xsl:variable name="position">8</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 006 and @materialType = $materialType]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 006 and @materialType = $materialType]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="contentNature">
          <xsl:variable name="position">9</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 006 and @materialType = $materialType]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 006 and @materialType = $materialType]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="govPub">
          <xsl:variable name="position">12</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 006 and @materialType = $materialType]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 006 and @materialType = $materialType]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="confPub">
          <xsl:variable name="position">13</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 006 and @materialType = $materialType]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 006 and @materialType = $materialType]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="undef14">
          <xsl:value-of select="substring($fillSpaces, 1, 3)"/>
        </xsl:variable>
        <xsl:variable name="alphaScript">
          <xsl:variable name="position">17</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 006 and @materialType = $materialType]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 006 and @materialType = $materialType]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="entryConvention">
          <xsl:variable name="position">18</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 006 and @materialType = $materialType]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 006 and @materialType = $materialType]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:value-of
          select="concat($materialForm, $frequency, $regularity, $undef4, $resourceType, $originalForm, $itemForm, $workNature, $contentNature, $govPub, $confPub, $undef14, $alphaScript, $entryConvention)"
        />
      </xsl:when>
      <!-- VM -->
      <xsl:when test="matches(substring(., 1, 1), '[gkor]')">
        <xsl:variable name="materialType">VM</xsl:variable>
        <xsl:variable name="materialForm">
          <xsl:value-of select="substring(., 1, 1)"/>
        </xsl:variable>
        <xsl:variable name="runningTime">
          <xsl:variable name="position">2</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 006 and @materialType = $materialType]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 006 and @materialType = $materialType]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="undef5">
          <xsl:value-of select="substring($fillSpaces, 1, 1)"/>
        </xsl:variable>
        <xsl:variable name="audience">
          <xsl:variable name="position">6</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 006 and @materialType = $materialType]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 006 and @materialType = $materialType]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="undef7">
          <xsl:value-of select="substring($fillSpaces, 1, 5)"/>
        </xsl:variable>
        <xsl:variable name="govPub">
          <xsl:variable name="position">12</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 006 and @materialType = $materialType]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 006 and @materialType = $materialType]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="itemForm">
          <xsl:variable name="position">13</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 006 and @materialType = $materialType]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 006 and @materialType = $materialType]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="undef14">
          <xsl:value-of select="substring($fillSpaces, 1, 3)"/>
        </xsl:variable>
        <xsl:variable name="visualType">
          <xsl:variable name="position">17</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 006 and @materialType = $materialType]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 006 and @materialType = $materialType]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="technique">
          <xsl:variable name="position">18</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 006 and @materialType = $materialType]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 006 and @materialType = $materialType]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:value-of
          select="concat($materialForm, $runningTime, $undef5, $audience, $undef7, $govPub, $itemForm, $undef14, $visualType, $technique)"
        />
      </xsl:when>
      <!-- MX -->
      <xsl:when test="matches(substring(., 1, 1), '[p]')">
        <xsl:variable name="materialType">MX</xsl:variable>
        <xsl:variable name="materialForm">
          <xsl:value-of select="substring(., 1, 1)"/>
        </xsl:variable>
        <xsl:variable name="undef2">
          <xsl:value-of select="substring($fillSpaces, 1, 5)"/>
        </xsl:variable>
        <xsl:variable name="itemForm">
          <xsl:variable name="position">7</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 006 and @materialType = $materialType]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 006 and @materialType = $materialType]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="undef8">
          <xsl:value-of select="substring($fillSpaces, 1, 11)"/>
        </xsl:variable>
        <xsl:value-of select="concat($materialForm, $undef2, $itemForm, $undef8)"/>
      </xsl:when>
      <!-- Unknown material -->
      <xsl:otherwise>
        <xsl:value-of select="."/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Create 007 based on type of material -->
  <xsl:template name="materialSpecific007">
    <!-- Legal values are read from $marcDesc and leading and trailing apostrophes from @values
      are deleted. Alphabetic case is significant in comparisons. "A" doesn't match 'a'! -->
    <xsl:choose>
      <!-- Map -->
      <xsl:when test="matches(substring(., 1, 1), '[a]', 'i')">
        <xsl:variable name="materialCategory">
          <xsl:value-of select="substring(., 1, 1)"/>
        </xsl:variable>
        <xsl:variable name="smd">
          <xsl:variable name="position">2</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="undef3">
          <xsl:value-of select="substring($fillSpaces, 1, 1)"/>
        </xsl:variable>
        <xsl:variable name="color">
          <xsl:variable name="position">4</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="physMedium">
          <xsl:variable name="position">5</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="reproType">
          <xsl:variable name="position">6</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="prodDetails">
          <xsl:variable name="position">7</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="posNeg">
          <xsl:variable name="position">8</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <controlfield>
          <xsl:apply-templates select="@*" mode="pass2"/>
          <xsl:value-of select="concat($materialCategory, $smd, $undef3, $color, $physMedium, $reproType, $prodDetails, $posNeg)"/>
        </controlfield>
      </xsl:when>
      <!-- Electronic resource -->
      <xsl:when test="matches(substring(., 1, 1), '[c]', 'i')">
        <xsl:variable name="materialCategory">
          <xsl:value-of select="substring(., 1, 1)"/>
        </xsl:variable>
        <xsl:variable name="smd">
          <xsl:variable name="position">2</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="undef3">
          <xsl:value-of select="substring($fillSpaces, 1, 1)"/>
        </xsl:variable>
        <xsl:variable name="color">
          <xsl:variable name="position">4</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="dimensions">
          <xsl:variable name="position">5</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="sound">
          <xsl:variable name="position">6</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="bitDepth">
          <xsl:variable name="position">7</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="fileFormat">
          <xsl:variable name="position">10</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="qualityTarget">
          <xsl:variable name="position">11</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="anteSource">
          <xsl:variable name="position">12</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="compression">
          <xsl:variable name="position">13</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="reformatQuality">
          <xsl:variable name="position">14</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <controlfield>
          <xsl:apply-templates select="@*" mode="pass2"/>
          <xsl:value-of select="concat($materialCategory, $smd, $undef3, $color, $dimensions, $sound, $bitDepth, $fileFormat, $qualityTarget, $anteSource, $compression, $reformatQuality)"/>
        </controlfield>
      </xsl:when>
      <!-- Globe -->
      <xsl:when test="matches(substring(., 1, 1), '[d]', 'i')">
        <xsl:variable name="materialCategory">
          <xsl:value-of select="substring(., 1, 1)"/>
        </xsl:variable>
        <xsl:variable name="smd">
          <xsl:variable name="position">2</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="undef3">
          <xsl:value-of select="substring($fillSpaces, 1, 1)"/>
        </xsl:variable>
        <xsl:variable name="color">
          <xsl:variable name="position">4</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="physMedium">
          <xsl:variable name="position">5</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="reproType">
          <xsl:variable name="position">6</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <controlfield>
          <xsl:apply-templates select="@*" mode="pass2"/>
          <xsl:value-of select="concat($materialCategory, $smd, $undef3, $color, $physMedium, $reproType)"/>
        </controlfield>
      </xsl:when>
      <!-- Tactile material -->
      <xsl:when test="matches(substring(., 1, 1), '[f]', 'i')">
        <xsl:variable name="materialCategory">
          <xsl:value-of select="substring(., 1, 1)"/>
        </xsl:variable>
        <xsl:variable name="smd">
          <xsl:variable name="position">2</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="undef3">
          <xsl:value-of select="substring($fillSpaces, 1, 1)"/>
        </xsl:variable>
        <xsl:variable name="brailleClass">
          <xsl:variable name="position">4</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="contractionLevel">
          <xsl:variable name="position">6</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="brailleMusicFormat">
          <xsl:variable name="position">7</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="specialChar">
          <xsl:variable name="position">10</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <controlfield>
          <xsl:apply-templates select="@*" mode="pass2"/>
          <xsl:value-of select="concat($materialCategory, $smd, $undef3, $brailleClass, $contractionLevel, $brailleMusicFormat, $specialChar)"/>
        </controlfield>
      </xsl:when>
      <!-- Projected graphic -->
      <xsl:when test="matches(substring(., 1, 1), '[g]', 'i')">
        <xsl:variable name="materialCategory">
          <xsl:value-of select="substring(., 1, 1)"/>
        </xsl:variable>
        <xsl:variable name="smd">
          <xsl:variable name="position">2</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="undef3">
          <xsl:value-of select="substring($fillSpaces, 1, 1)"/>
        </xsl:variable>
        <xsl:variable name="color">
          <xsl:variable name="position">4</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="emulsionBase">
          <xsl:variable name="position">5</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="soundOnMedium">
          <xsl:variable name="position">6</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="mediumOfSound">
          <xsl:variable name="position">7</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="dimensions">
          <xsl:variable name="position">8</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="support">
          <xsl:variable name="position">9</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <controlfield>
          <xsl:apply-templates select="@*" mode="pass2"/>
          <xsl:value-of select="concat($materialCategory, $smd, $undef3, $color, $emulsionBase, $soundOnMedium, $mediumOfSound, $dimensions, $support)"/>
        </controlfield>
      </xsl:when>
      <!-- Microform -->
      <xsl:when test="matches(substring(., 1, 1), '[h]', 'i')">
        <xsl:variable name="materialCategory">
          <xsl:value-of select="substring(., 1, 1)"/>
        </xsl:variable>
        <xsl:variable name="smd">
          <xsl:variable name="position">2</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="undef3">
          <xsl:value-of select="substring($fillSpaces, 1, 1)"/>
        </xsl:variable>
        <xsl:variable name="posNeg">
          <xsl:variable name="position">4</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="dimensions">
          <xsl:variable name="position">5</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="reductionRange">
          <xsl:variable name="position">6</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="reductionRatio">
          <xsl:variable name="position">7</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:choose>
            <!-- Value contains 3 dashes or mixture of digits and dashes -->
            <xsl:when test="matches(substring(., $position, $length), '-{3}|[\d-]{3}')">
              <xsl:value-of
                select="replace(substring(., $position, $length), '\p{Zs}', '&#32;')"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:value-of select="substring($fillPipes, 1, 3)"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="color">
          <xsl:variable name="position">10</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="emulsion">
          <xsl:variable name="position">11</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="generation">
          <xsl:variable name="position">12</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="filmBase">
          <xsl:variable name="position">13</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <controlfield>
          <xsl:apply-templates select="@*" mode="pass2"/>
          <xsl:value-of select="concat($materialCategory, $smd, $undef3, $posNeg, $dimensions, $reductionRange, $reductionRatio, $color, $emulsion, $generation, $filmBase)"/>
        </controlfield>
      </xsl:when>
      <!-- Nonprojected graphic -->
      <xsl:when test="matches(substring(., 1, 1), '[k]', 'i')">
        <xsl:variable name="materialCategory">
          <xsl:value-of select="substring(., 1, 1)"/>
        </xsl:variable>
        <xsl:variable name="smd">
          <xsl:variable name="position">2</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="undef3">
          <xsl:value-of select="substring($fillSpaces, 1, 1)"/>
        </xsl:variable>
        <xsl:variable name="color">
          <xsl:variable name="position">4</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="supportPrimary">
          <xsl:variable name="position">5</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="supportSecondary">
          <xsl:variable name="position">6</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <controlfield>
          <xsl:apply-templates select="@*" mode="pass2"/>
          <xsl:value-of select="concat($materialCategory, $smd, $undef3, $color, $supportPrimary, $supportSecondary)"/>
        </controlfield>
      </xsl:when>
      <!-- Motion picture -->
      <xsl:when test="matches(substring(., 1, 1), '[m]', 'i')">
        <xsl:variable name="materialCategory">
          <xsl:value-of select="substring(., 1, 1)"/>
        </xsl:variable>
        <xsl:variable name="smd">
          <xsl:variable name="position">2</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="undef3">
          <xsl:value-of select="substring($fillSpaces, 1, 1)"/>
        </xsl:variable>
        <xsl:variable name="color">
          <xsl:variable name="position">4</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="presentationFormat">
          <xsl:variable name="position">5</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="soundOnMedium">
          <xsl:variable name="position">6</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="mediumOfSound">
          <xsl:variable name="position">7</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="dimensions">
          <xsl:variable name="position">8</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="playbackChannels">
          <xsl:variable name="position">9</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="productionElements">
          <xsl:variable name="position">10</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="posNeg">
          <xsl:variable name="position">11</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="generation">
          <xsl:variable name="position">12</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="filmBase">
          <xsl:variable name="position">13</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="refinedColor">
          <xsl:variable name="position">14</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="colorStock">
          <xsl:variable name="position">15</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="deterioration">
          <xsl:variable name="position">16</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="completeness">
          <xsl:variable name="position">17</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="inspectionDate">
          <xsl:choose>
            <!-- Codes are valid -->
            <xsl:when
              test="matches(substring(., 18, 6), '([0-9]{4}([0-9]{2}|[\-]{2}))|[\-]{6}')">
              <xsl:value-of select="substring(., 18, 6)"/>
            </xsl:when>
            <!-- Replace w/ 'no attempt to code' -->
            <xsl:otherwise>
              <xsl:value-of select="substring($fillPipes, 1, 6)"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <controlfield>
          <xsl:apply-templates select="@*" mode="pass2"/>
          <xsl:value-of select="concat($materialCategory, $smd, $undef3, $color, $presentationFormat, $soundOnMedium, $mediumOfSound, $dimensions, $playbackChannels, $productionElements, $posNeg, $generation, $filmBase, $refinedColor, $colorStock, $deterioration, $completeness, $inspectionDate)"/>
        </controlfield>
      </xsl:when>
      <!-- Kit -->
      <xsl:when test="matches(substring(., 1, 1), '[o]', 'i')">
        <xsl:variable name="materialCategory">
          <xsl:value-of select="substring(., 1, 1)"/>
        </xsl:variable>
        <xsl:variable name="smd">
          <xsl:variable name="position">2</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <controlfield>
          <xsl:apply-templates select="@*" mode="pass2"/>
          <xsl:value-of select="concat($materialCategory, $smd)"/>
        </controlfield>
      </xsl:when>
      <!-- Notated music -->
      <xsl:when test="matches(substring(., 1, 1), '[q]', 'i')">
        <xsl:variable name="materialCategory">
          <xsl:value-of select="substring(., 1, 1)"/>
        </xsl:variable>
        <xsl:variable name="smd">
          <xsl:variable name="position">2</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <controlfield>
          <xsl:apply-templates select="@*" mode="pass2"/>
          <xsl:value-of select="concat($materialCategory, $smd)"/>
        </controlfield>
      </xsl:when>
      <!-- Remote-sensing image -->
      <xsl:when test="matches(substring(., 1, 1), '[r]', 'i')">
        <xsl:variable name="materialCategory">
          <xsl:value-of select="substring(., 1, 1)"/>
        </xsl:variable>
        <xsl:variable name="smd">
          <xsl:variable name="position">2</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="undef3">
          <xsl:value-of select="substring($fillSpaces, 1, 1)"/>
        </xsl:variable>
        <xsl:variable name="sensorAlt">
          <xsl:variable name="position">4</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="sensorAtt">
          <xsl:variable name="position">5</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="cloudCover">
          <xsl:variable name="position">6</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="platformConstruction">
          <xsl:variable name="position">7</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="platformUse">
          <xsl:variable name="position">8</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="sensorType">
          <xsl:variable name="position">9</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="dataType">
          <xsl:variable name="position">10</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <controlfield>
          <xsl:apply-templates select="@*" mode="pass2"/>
          <xsl:value-of select="concat($materialCategory, $smd, $undef3, $sensorAlt, $sensorAtt, $cloudCover, $platformConstruction, $platformUse, $sensorType, $dataType)"/>
        </controlfield>
      </xsl:when>
      <!-- Sound recording -->
      <xsl:when test="matches(substring(., 1, 1), '[s]', 'i')">
        <xsl:variable name="materialCategory">
          <xsl:value-of select="substring(., 1, 1)"/>
        </xsl:variable>
        <xsl:variable name="smd">
          <xsl:variable name="position">2</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="undef3">
          <xsl:value-of select="substring($fillSpaces, 1, 1)"/>
        </xsl:variable>
        <xsl:variable name="speed">
          <xsl:variable name="position">4</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="channelConfig">
          <xsl:variable name="position">5</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="groovePitch">
          <xsl:variable name="position">6</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="dimensions">
          <xsl:variable name="position">7</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="tapeWidth">
          <xsl:variable name="position">8</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="tapeConfig">
          <xsl:variable name="position">9</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="discCylinderTapeType">
          <xsl:variable name="position">10</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="materialKind">
          <xsl:variable name="position">11</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="cuttingType">
          <xsl:variable name="position">12</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="specialPlayback">
          <xsl:variable name="position">13</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="captureStorage">
          <xsl:variable name="position">14</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <controlfield>
          <xsl:apply-templates select="@*" mode="pass2"/>
          <xsl:value-of select="concat($materialCategory, $smd, $undef3, $speed, $channelConfig, $groovePitch, $dimensions, $tapeWidth, $tapeConfig, $discCylinderTapeType, $materialKind, $cuttingType, $specialPlayback, $captureStorage)"/>
        </controlfield>
      </xsl:when>
      <!-- Text -->
      <xsl:when test="matches(substring(., 1, 1), '[t]', 'i')">
        <xsl:variable name="materialCategory">
          <xsl:value-of select="substring(., 1, 1)"/>
        </xsl:variable>
        <xsl:variable name="smd">
          <xsl:variable name="position">2</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <controlfield>
          <xsl:apply-templates select="@*" mode="pass2"/>
          <xsl:value-of select="concat($materialCategory, $smd)"/>
        </controlfield>
      </xsl:when>
      <!-- Videorecording -->
      <xsl:when test="matches(substring(., 1, 1), '[v]', 'i')">
        <xsl:variable name="materialCategory">
          <xsl:value-of select="substring(., 1, 1)"/>
        </xsl:variable>
        <xsl:variable name="smd">
          <xsl:variable name="position">2</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="undef3">
          <xsl:value-of select="substring($fillSpaces, 1, 1)"/>
        </xsl:variable>
        <xsl:variable name="color">
          <xsl:variable name="position">4</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="format">
          <xsl:variable name="position">5</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="soundOnMedium">
          <xsl:variable name="position">6</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="mediumOfSound">
          <xsl:variable name="position">7</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="dimensions">
          <xsl:variable name="position">8</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="channelConfig">
          <xsl:variable name="position">9</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <controlfield>
          <xsl:apply-templates select="@*" mode="pass2"/>
          <xsl:value-of select="concat($materialCategory, $smd, $undef3, $color, $format, $soundOnMedium, $mediumOfSound, $dimensions, $channelConfig)"/>
        </controlfield>
      </xsl:when>
      <!-- Unspecified -->
      <xsl:when test="matches(substring(., 1, 1), '[z]', 'i')">
        <xsl:variable name="materialCategory">
          <xsl:value-of select="substring(., 1, 1)"/>
        </xsl:variable>
        <xsl:variable name="smd">
          <xsl:variable name="position">2</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 007 and @materialCategory = $materialCategory]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <controlfield>
          <xsl:apply-templates select="@*" mode="pass2"/>
          <xsl:value-of select="concat($materialCategory, $smd)"/>
        </controlfield>
      </xsl:when>
      <!-- Microform 007 erroneously contains subfields -->
      <xsl:when test="matches(., '^\|ah\|')">
        <xsl:variable name="materialCategory">
          <xsl:text>h</xsl:text>
        </xsl:variable>
        <xsl:variable name="smd">
          <xsl:choose>
            <xsl:when
              test="normalize-space(lower-case(substring(substring-after(., '|b'), 1, 1))) != ''">
              <xsl:value-of select="lower-case(substring(substring-after(., '|b'), 1, 1))"
              />
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="substring($fillPipes, 1, 1)"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="undef3">
          <xsl:value-of select="substring($fillSpaces, 1, 1)"/>
        </xsl:variable>
        <xsl:variable name="posNeg">
          <xsl:choose>
            <xsl:when
              test="normalize-space(lower-case(substring(substring-after(., '|d'), 1, 1))) != ''">
              <xsl:value-of select="lower-case(substring(substring-after(., '|d'), 1, 1))"
              />
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="substring($fillPipes, 1, 1)"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="dimensions">
          <xsl:choose>
            <xsl:when
              test="normalize-space(lower-case(substring(substring-after(., '|e'), 1, 1))) != ''">
              <xsl:value-of select="lower-case(substring(substring-after(., '|e'), 1, 1))"
              />
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="substring($fillPipes, 1, 1)"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="reductionRatioRange">
          <xsl:choose>
            <xsl:when
              test="normalize-space(lower-case(substring(substring-after(., '|f'), 1, 1))) != ''">
              <xsl:value-of select="lower-case(substring(substring-after(., '|f'), 1, 1))"
              />
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="substring($fillPipes, 1, 1)"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="reductionRatio">
          <xsl:value-of select="substring($fillPipes, 1, 3)"/>
        </xsl:variable>
        <xsl:variable name="color">
          <xsl:choose>
            <xsl:when
              test="normalize-space(lower-case(substring(substring-after(., '|g'), 1, 1))) != ''">
              <xsl:value-of select="lower-case(substring(substring-after(., '|g'), 1, 1))"
              />
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="substring($fillPipes, 1, 1)"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="emulsion">
          <xsl:choose>
            <xsl:when
              test="normalize-space(lower-case(substring(substring-after(., '|h'), 1, 1))) != ''">
              <xsl:value-of select="lower-case(substring(substring-after(., '|h'), 1, 1))"
              />
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="substring($fillPipes, 1, 1)"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="generation">
          <xsl:choose>
            <xsl:when
              test="normalize-space(lower-case(substring(substring-after(., '|i'), 1, 1))) != ''">
              <xsl:value-of select="lower-case(substring(substring-after(., '|i'), 1, 1))"
              />
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="substring($fillPipes, 1, 1)"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="filmBase">
          <xsl:choose>
            <xsl:when
              test="normalize-space(lower-case(substring(substring-after(., '|j'), 1, 1))) != ''">
              <xsl:value-of select="lower-case(substring(substring-after(., '|j'), 1, 1))"
              />
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="substring($fillPipes, 1, 1)"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <controlfield>
          <xsl:apply-templates select="@*" mode="pass2"/>
          <xsl:value-of select="concat($materialCategory, $smd, $undef3, $posNeg, $dimensions, $reductionRatioRange, $reductionRatio, $color, $emulsion, $generation, $filmBase)"/>
        </controlfield>
      </xsl:when>
      <!-- Unknown material; leave in place -->
      <xsl:otherwise>
        <controlfield>
          <xsl:apply-templates select="@*" mode="pass2"/>
          <xsl:value-of select="."/>
        </controlfield>
        <!--<xsl:variable name="recordIdentifier">
          <xsl:choose>
            <xsl:when test="../*:controlfield[@tag = '001']">
              <xsl:value-of select="../*:controlfield[@tag = '001']"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="position()"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:message>record <xsl:value-of select="$recordIdentifier"/>: Unknown value '<xsl:value-of
            select="substring(., 1, 1)"/>' in 007/00</xsl:message>-->
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Create 008 based on type of material -->
  <xsl:template name="materialSpecific008">
    <!-- Legal values are read from $marcDesc and leading and trailing apostrophes from @values
      are deleted. Alphabetic case is significant in comparisons. "A" doesn't match 'a'! -->
    <xsl:choose>
      <!-- BK -->
      <xsl:when
        test="matches(substring(../*:leader, 7, 1), '[at]') and matches(substring(../*:leader, 8, 1), '[acdm]')">
        <xsl:variable name="materialType">BK</xsl:variable>
        <xsl:variable name="illus">
          <xsl:variable name="position">19</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 008 and @materialType = $materialType]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 008 and @materialType = $materialType]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="audience">
          <xsl:variable name="position">23</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 008 and @materialType = $materialType]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace($marcDesc//*:controlfield[@tag = 008 and @materialType = $materialType]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;)"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="itemForm">
          <xsl:variable name="position">24</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 008 and @materialType = $materialType]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace($marcDesc//*:controlfield[@tag = 008 and @materialType = $materialType]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;)"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="contentNature">
          <xsl:variable name="position">25</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 008 and @materialType = $materialType]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 008 and @materialType = $materialType]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="govPub">
          <xsl:variable name="position">29</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 008 and @materialType = $materialType]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 008 and @materialType = $materialType]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="confPub">
          <xsl:variable name="position">30</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 008 and @materialType = $materialType]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 008 and @materialType = $materialType]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="festschrift">
          <xsl:variable name="position">31</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 008 and @materialType = $materialType]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 008 and @materialType = $materialType]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="index">
          <xsl:variable name="position">32</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 008 and @materialType = $materialType]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 008 and @materialType = $materialType]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="undef33">
          <xsl:value-of select="substring($fillSpaces, 1, 1)"/>
        </xsl:variable>
        <xsl:variable name="litForm">
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace($marcDesc//*:controlfield[@tag = &quot;008&quot; and @materialType = $materialType]/*:code[@position = &quot;34&quot;]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;)"
            />
          </xsl:variable>
          <xsl:choose>
            <!-- Purported to be non-fiction -->
            <xsl:when test="matches(substring(., 34, 1), '0')">
              <xsl:choose>
                <!-- When classed in "P" and no 6xx fields, mark as fiction -->
                <xsl:when
                  test="../*:datafield[matches(@tag, '999')]/*:subfield[@code = 'a'][matches(., '^P')] and not(../*:datafield[matches(@tag, '^6')])">
                  <text>1</text>
                </xsl:when>
                <!-- Retain non-fiction designation -->
                <xsl:otherwise>
                  <text>0</text>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:when>
            <!-- Purported to be fiction -->
            <xsl:when test="matches(substring(., 34, 1), '1')">
              <xsl:choose>
                <!-- When not classed in "P" and 6xx fields are present, mark as non-fiction -->
                <xsl:when
                  test="not(../*:datafield[matches(@tag, '999')]/*:subfield[@code = 'a'][matches(., '^P')]) and ../*:datafield[matches(@tag, '^6')]">
                  <text>0</text>
                </xsl:when>
                <!-- Retain fiction designation -->
                <xsl:otherwise>
                  <text>1</text>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:when>
            <!-- Pass through valid litForm value -->
            <xsl:when test="matches(substring(., 34, 1), $legalValues)">
              <xsl:value-of select="replace(substring(., 34, 1), '\p{Zs}', '&#32;')"/>
            </xsl:when>
            <!-- "No attempt to code" default value -->
            <xsl:otherwise>
              <xsl:value-of select="substring($fillPipes, 1, 1)"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="biography">
          <xsl:variable name="position">35</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 008 and @materialType = $materialType]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 008 and @materialType = $materialType]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:value-of
          select="concat($illus, $audience, $itemForm, $contentNature, $govPub, $confPub, $festschrift, $index, $undef33, $litForm, $biography)"
        />
      </xsl:when>
      <!-- CF -->
      <xsl:when test="matches(substring(../*:leader, 7, 1), '[m]')">
        <xsl:variable name="materialType">CF</xsl:variable>
        <xsl:variable name="undef19">
          <xsl:value-of select="substring($fillSpaces, 1, 4)"/>
        </xsl:variable>
        <xsl:variable name="audience">
          <xsl:variable name="position">23</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 008 and @materialType = $materialType]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 008 and @materialType = $materialType]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="itemForm">
          <xsl:variable name="position">24</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 008 and @materialType = $materialType]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 008 and @materialType = $materialType]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="undef25">
          <xsl:value-of select="substring($fillSpaces, 1, 2)"/>
        </xsl:variable>
        <xsl:variable name="fileType">
          <xsl:variable name="position">27</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 008 and @materialType = $materialType]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 008 and @materialType = $materialType]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="undef28">
          <xsl:value-of select="substring($fillSpaces, 1, 1)"/>
        </xsl:variable>
        <xsl:variable name="govPub">
          <xsl:variable name="position">29</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 008 and @materialType = $materialType]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 008 and @materialType = $materialType]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="undef30">
          <xsl:value-of select="substring($fillSpaces, 1, 6)"/>
        </xsl:variable>
        <xsl:value-of
          select="concat($undef19, $audience, $itemForm, $undef25, $fileType, $undef28, $govPub, $undef30)"
        />
      </xsl:when>
      <!-- MP -->
      <xsl:when test="matches(substring(../*:leader, 7, 1), '[ef]')">
        <xsl:variable name="materialType">MP</xsl:variable>
        <xsl:variable name="relief">
          <xsl:variable name="position">19</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 008 and @materialType = $materialType]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 008 and @materialType = $materialType]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="projection">
          <xsl:variable name="position">23</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 008 and @materialType = $materialType]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 008 and @materialType = $materialType]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="undef25">
          <xsl:value-of select="substring($fillSpaces, 1, 1)"/>
        </xsl:variable>
        <xsl:variable name="cartographicType">
          <xsl:variable name="position">26</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 008 and @materialType = $materialType]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 008 and @materialType = $materialType]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="undef27">
          <xsl:value-of select="substring($fillSpaces, 1, 2)"/>
        </xsl:variable>
        <xsl:variable name="govPub">
          <xsl:variable name="position">29</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 008 and @materialType = $materialType]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 008 and @materialType = $materialType]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="itemForm">
          <xsl:variable name="position">30</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 008 and @materialType = $materialType]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 008 and @materialType = $materialType]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="undef31">
          <xsl:value-of select="substring($fillSpaces, 1, 1)"/>
        </xsl:variable>
        <xsl:variable name="index">
          <xsl:variable name="position">32</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 008 and @materialType = $materialType]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 008 and @materialType = $materialType]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="undef33">
          <xsl:value-of select="substring($fillSpaces, 1, 1)"/>
        </xsl:variable>
        <xsl:variable name="specialFormat">
          <xsl:variable name="position">34</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 008 and @materialType = $materialType]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 008 and @materialType = $materialType]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:value-of
          select="concat($relief, $projection, $undef25, $cartographicType, $undef27, $govPub, $itemForm, $undef31, $index, $undef33, $specialFormat)"
        />
      </xsl:when>
      <!-- MU -->
      <xsl:when test="matches(substring(../*:leader, 7, 1), '[cdij]')">
        <xsl:variable name="materialType">MU</xsl:variable>
        <xsl:variable name="compositionForm">
          <xsl:variable name="position">19</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 008 and @materialType = $materialType]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 008 and @materialType = $materialType]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="musicFormat">
          <xsl:variable name="position">21</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 008 and @materialType = $materialType]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 008 and @materialType = $materialType]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="musicParts">
          <xsl:variable name="position">22</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 008 and @materialType = $materialType]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 008 and @materialType = $materialType]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="audience">
          <xsl:variable name="position">23</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 008 and @materialType = $materialType]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 008 and @materialType = $materialType]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="itemForm">
          <xsl:variable name="position">24</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 008 and @materialType = $materialType]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 008 and @materialType = $materialType]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="accMatter">
          <xsl:variable name="position">25</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 008 and @materialType = $materialType]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 008 and @materialType = $materialType]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="literaryText">
          <xsl:variable name="position">31</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 008 and @materialType = $materialType]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 008 and @materialType = $materialType]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="undef33">
          <xsl:value-of select="substring($fillSpaces, 1, 1)"/>
        </xsl:variable>
        <xsl:variable name="transpoArrangement">
          <xsl:variable name="position">34</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 008 and @materialType = $materialType]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 008 and @materialType = $materialType]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="undef35">
          <xsl:value-of select="substring($fillSpaces, 1, 1)"/>
        </xsl:variable>
        <xsl:value-of
          select="concat($compositionForm, $musicFormat, $musicParts, $audience, $itemForm, $accMatter, $literaryText, $undef33, $transpoArrangement, $undef35)"
        />
      </xsl:when>
      <!-- CR -->
      <xsl:when
        test="matches(substring(../*:leader, 7, 1), '[a]') and matches(substring(../*:leader, 8, 1), '[bis]')">
        <xsl:variable name="materialType">CR</xsl:variable>
        <xsl:variable name="frequency">
          <xsl:variable name="position">19</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 008 and @materialType = $materialType]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 008 and @materialType = $materialType]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="regularity">
          <xsl:variable name="position">20</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 008 and @materialType = $materialType]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 008 and @materialType = $materialType]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="undef21">
          <xsl:value-of select="substring($fillSpaces, 1, 1)"/>
        </xsl:variable>
        <xsl:variable name="resourceType">
          <xsl:variable name="position">22</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 008 and @materialType = $materialType]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 008 and @materialType = $materialType]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="originalForm">
          <xsl:variable name="position">23</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 008 and @materialType = $materialType]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 008 and @materialType = $materialType]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="itemForm">
          <xsl:variable name="position">24</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 008 and @materialType = $materialType]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 008 and @materialType = $materialType]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="workNature">
          <xsl:variable name="position">25</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 008 and @materialType = $materialType]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 008 and @materialType = $materialType]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="contentNature">
          <xsl:variable name="position">26</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 008 and @materialType = $materialType]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 008 and @materialType = $materialType]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="govPub">
          <xsl:variable name="position">29</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 008 and @materialType = $materialType]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 008 and @materialType = $materialType]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="confPub">
          <xsl:variable name="position">30</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 008 and @materialType = $materialType]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 008 and @materialType = $materialType]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="undef31">
          <xsl:value-of select="substring($fillSpaces, 1, 3)"/>
        </xsl:variable>
        <xsl:variable name="alphaScript">
          <xsl:variable name="position">34</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 008 and @materialType = $materialType]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 008 and @materialType = $materialType]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="entryConvention">
          <xsl:variable name="position">35</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 008 and @materialType = $materialType]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 008 and @materialType = $materialType]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:value-of
          select="concat($frequency, $regularity, $undef21, $resourceType, $originalForm, $itemForm, $workNature, $contentNature, $govPub, $confPub, $undef31, $alphaScript, $entryConvention)"
        />
      </xsl:when>
      <!-- VM -->
      <xsl:when test="matches(substring(../*:leader, 7, 1), '[gkor]')">
        <xsl:variable name="materialType">VM</xsl:variable>
        <xsl:variable name="runningTime">
          <xsl:variable name="position">19</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 008 and @materialType = $materialType]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 008 and @materialType = $materialType]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
          <!--<xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace($marcDesc//*:controlfield[@tag = &quot;008&quot; and @materialType = $materialType]/*:code[@position = &quot;19&quot;]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;)"
            />
          </xsl:variable>
          <xsl:choose>
            <xsl:when test="matches(substring(., 19, 3), $legalValues)">
              <xsl:value-of select="replace(substring(., 19, 3), '\p{Zs}', '&#32;')"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="substring($fillPipes, 1, 3)"/>
            </xsl:otherwise>
          </xsl:choose>-->
        </xsl:variable>
        <xsl:variable name="undef22">
          <xsl:value-of select="substring($fillSpaces, 1, 1)"/>
        </xsl:variable>
        <xsl:variable name="audience">
          <xsl:variable name="position">23</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 008 and @materialType = $materialType]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 008 and @materialType = $materialType]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="undef24">
          <xsl:value-of select="substring($fillSpaces, 1, 5)"/>
        </xsl:variable>
        <xsl:variable name="govPub">
          <xsl:variable name="position">29</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 008 and @materialType = $materialType]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 008 and @materialType = $materialType]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="itemForm">
          <xsl:variable name="position">30</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 008 and @materialType = $materialType]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 008 and @materialType = $materialType]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="undef31">
          <xsl:value-of select="substring($fillSpaces, 1, 3)"/>
        </xsl:variable>
        <xsl:variable name="visualType">
          <xsl:variable name="position">34</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 008 and @materialType = $materialType]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 008 and @materialType = $materialType]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="technique">
          <xsl:variable name="position">35</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 008 and @materialType = $materialType]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 008 and @materialType = $materialType]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:value-of
          select="concat($runningTime, $undef22, $audience, $undef24, $govPub, $itemForm, $undef31, $visualType, $technique)"
        />
      </xsl:when>
      <!-- MX -->
      <xsl:when test="matches(substring(../*:leader, 7, 1), '[p]')">
        <xsl:variable name="materialType">MX</xsl:variable>
        <xsl:variable name="undef19">
          <xsl:value-of select="substring($fillSpaces, 1, 5)"/>
        </xsl:variable>
        <xsl:variable name="itemForm">
          <xsl:variable name="position">24</xsl:variable>
          <xsl:variable name="length">
            <xsl:value-of
              select="$marcDesc//*:controlfield[@tag = 008 and @materialType = $materialType]/*:code[@position = $position]/@length"
            />
          </xsl:variable>
          <xsl:variable name="legalValues">
            <xsl:value-of
              select="replace(replace(replace($marcDesc//*:controlfield[@tag = 008 and @materialType = $materialType]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
            />
          </xsl:variable>
          <xsl:call-template name="createFixedFieldValue">
            <xsl:with-param name="position" select="$position"/>
            <xsl:with-param name="length" select="$length"/>
            <xsl:with-param name="legalValues" select="$legalValues"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="undef25">
          <xsl:value-of select="substring($fillSpaces, 1, 11)"/>
        </xsl:variable>
        <xsl:value-of select="concat($undef19, $itemForm, $undef25)"/>
      </xsl:when>
      <!-- Unknown material -->
      <xsl:otherwise>
        <xsl:value-of select="substring(., 19, 17)"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Split over-long 041 subfields into multiple subfields -->
  <xsl:template name="split041subfield">
    <xsl:param name="thisValue"/>
    <xsl:param name="thisCode"/>
    <xsl:choose>
      <xsl:when test="string-length($thisValue) &gt; 3">
        <subfield code="{$thisCode}">
          <!-- Fix common incorrect value for English and Japanese -->
          <xsl:value-of select="replace(replace(replace(substring($thisValue, 1, 3), 'jap', 'jpn'), 'ing', 'eng'), 'end', 'eng')"/>
        </subfield>
        <xsl:variable name="remainder">
          <xsl:value-of select="substring($thisValue, 4)"/>
        </xsl:variable>
        <xsl:call-template name="split041subfield">
          <xsl:with-param name="thisValue">
            <xsl:value-of select="$remainder"/>
          </xsl:with-param>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <subfield code="{$thisCode}">
          <!-- Fix common errors -->
          <xsl:value-of select="replace(replace(replace(replace($thisValue, 'jap', 'jpn'), 'ing', 'eng'), 'end', 'eng'), 'rur', 'rus')"/>
        </subfield>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- MAIN OUTPUT TEMPLATE -->
  <xsl:template match="/">
    <xsl:variable name="phase1">
      <xsl:apply-templates mode="phase1"/>
    </xsl:variable>
    <xsl:variable name="phase2">
      <xsl:apply-templates select="$phase1" mode="phase2"/>
    </xsl:variable>
    <xsl:apply-templates select="$phase2" mode="phase3"/>
  </xsl:template>

  <!-- MATCH TEMPLATES (phase 1) -->
  <xsl:template match="*:record" mode="phase1">
    <xsl:variable name="recordID">
      <xsl:choose>
        <xsl:when test="*:controlfield[@tag = '001']">
          <xsl:value-of select="*:controlfield[@tag = '001']"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="count(preceding-sibling::*:record) + 1"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <!-- Process record -->
    <xsl:variable name="pass0">
      <record xmlns="http://www.loc.gov/MARC21/slim">
        <xsl:apply-templates select="@*" mode="pass0"/>
        <xsl:apply-templates mode="pass0"/>
        <!-- If there's no leader, create a minimal, intentionally incorrect one -->
        <xsl:if test="not(*:leader)">
          <leader>00000||| a2200000uu 4500</leader>
        </xsl:if>
        <!-- If there's no 008, create a minimal one -->
        <xsl:if test="not(*:controlfield[@tag = '008'])">
          <controlfield tag="008">
                <xsl:text>000000|||||||||xx |||||||||||||||||und||</xsl:text>
              </controlfield>
        </xsl:if>
        <!-- If there's no 040, create a minimal one -->
        <xsl:if test="not(*:datafield[@tag = '040'])">
          <datafield tag="040" ind1=" " ind2=" ">
            <subfield code="a">xxxxund</subfield>
            <subfield code="b">eng</subfield>
            <subfield code="e">local</subfield>
          </datafield>
        </xsl:if>
      </record>
    </xsl:variable>
    <xsl:variable name="pass1">
      <xsl:apply-templates select="$pass0" mode="pass1"/>
    </xsl:variable>
    <xsl:variable name="pass2">
      <xsl:apply-templates select="$pass1" mode="pass2"/>
    </xsl:variable>
    <xsl:variable name="pass3">
      <xsl:apply-templates select="$pass2" mode="pass3"/>
    </xsl:variable>
    <xsl:variable name="pass4">
      <xsl:apply-templates select="$pass3" mode="pass4"/>
    </xsl:variable>
    <xsl:copy-of select="$pass4"/>

  </xsl:template>

  <!-- MATCH TEMPLATES (phase 1, pass 0) -->
  <!-- OCLC uses the alveolar click ('ǂ') or the double dagger ('‡') as a subfield
       delimiter. If these are pasted from an OCLC screen display, they will appear
       to be data, not delimiters.-->
  <xsl:template match="*:subfield" mode="pass0">
    <xsl:variable name="thisCode">
      <xsl:value-of select="@code"/>
    </xsl:variable>
    <xsl:variable name="thisContent">
      <xsl:value-of select="."/>
    </xsl:variable>
    <xsl:choose>
      <!-- Pass through subfields without OCLC delimiters -->
      <xsl:when test="not(matches(., '[ǂ‡]'))">
        <subfield>
          <xsl:copy-of select="@*"/>
          <xsl:value-of select="$thisContent"/>
        </subfield>
      </xsl:when>
      <!-- Create additional subfields based on the OCLC delimiters -->
      <xsl:otherwise>
        <xsl:analyze-string select="." regex="[ǂ‡]">
          <xsl:non-matching-substring>
            <xsl:choose>
              <!-- Subfield content is a single letter -->
              <!-- This happens if there's a single letter before the use of OCLC 
                delimiters; e.g., "a ǂb24000 ǂdW0773730 ǂeW0773000 ǂfN0374500 ǂgN0373730" -->
              <xsl:when test="matches(normalize-space(.), '^[a-z]$')">
                <subfield>
                  <xsl:attribute name="code">
                    <xsl:value-of select="substring(normalize-space(.), 1, 1)"/>
                  </xsl:attribute>
                  <xsl:value-of select="substring(normalize-space(.), 1)"/>
                </subfield>
              </xsl:when>
              <!-- Content is single letter + a space -->
              <xsl:when test="matches(normalize-space(.), '^[a-z] ')">
                <subfield>
                  <xsl:attribute name="code">
                    <xsl:value-of select="substring(normalize-space(.), 1, 1)"/>
                  </xsl:attribute>
                  <xsl:value-of select="substring(normalize-space(.), 3)"/>
                </subfield>
              </xsl:when>
              <!-- Content starts with a single letter -->
              <xsl:when test="matches(normalize-space(.), '^[a-z]')">
                <subfield>
                  <xsl:attribute name="code">
                    <xsl:value-of select="substring(normalize-space(.), 1, 1)"/>
                  </xsl:attribute>
                  <xsl:value-of select="substring(normalize-space(.), 2)"/>
                </subfield>
              </xsl:when>
              <!-- Otherwise -->
              <xsl:otherwise>
                <subfield>
                   <xsl:attribute name="code">
                    <xsl:value-of select="$thisCode"/>
                  </xsl:attribute>
                  <xsl:value-of select="."/>
                </subfield>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:non-matching-substring>
        </xsl:analyze-string>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- MATCH TEMPLATES (phase 1, pass 1) -->
  <!-- Leader -->
  <xsl:template match="*:leader" mode="pass1">
    <xsl:variable name="recordLength">
      <xsl:value-of select="substring(., 1, 5)"/>
    </xsl:variable>
    <xsl:variable name="recordStatus">
      <xsl:variable name="position">6</xsl:variable>
      <xsl:variable name="length">
        <xsl:value-of select="$marcDesc//*:leader/*:code[@position = $position]/@length"/>
      </xsl:variable>
      <xsl:variable name="legalValues">
        <xsl:value-of
          select="replace(replace(replace($marcDesc//*:leader/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
        />
      </xsl:variable>
      <xsl:call-template name="createFixedFieldValue">
        <xsl:with-param name="position" select="$position"/>
        <xsl:with-param name="length" select="$length"/>
        <xsl:with-param name="legalValues" select="$legalValues"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="recordType">
      <xsl:variable name="position">7</xsl:variable>
      <xsl:variable name="legalValues">
        <xsl:value-of
          select="replace(replace(replace($marcDesc//*:leader/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
        />
      </xsl:variable>
      <xsl:variable name="length">
        <xsl:value-of select="$marcDesc//*:leader/*:code[@position = $position]/@length"/>
      </xsl:variable>
      <xsl:choose>
        <!-- Replace invalid code -->
        <xsl:when test="not(matches(substring(., $position, $length), $legalValues, 'i'))"
          >|</xsl:when>
        <!-- Replace inaccurate value -->
        <xsl:when
          test="(../*:datafield[@tag = '099']/*:subfield[@code = 'a'][matches(., '^(MSS |RG)', 'i')] or ../*:datafield[@tag = '999']/*:subfield[@code = 'a'][matches(., '^(MSS |RG)', 'i')])">
          <xsl:choose>
            <xsl:when test="matches(substring(., $position, $length), '[^pt]', 'i')">
              <xsl:value-of select="substring(., $position, 1)"/>
            </xsl:when>
            <xsl:when
              test="number(../*:datafield[@tag = '300'][1]/*:subfield[@code = 'a'][1]) = 1">
              <xsl:text>t</xsl:text>
            </xsl:when>
            <xsl:when
              test="number(../*:datafield[@tag = '300'][1]/*:subfield[@code = 'a'][1]) &gt; 1">
              <xsl:text>p</xsl:text>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="lower-case(substring(., $position, $length))"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <!-- Keep current value -->
        <xsl:otherwise>
          <xsl:value-of select="lower-case(substring(., $position, $length))"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="bibLevel">
      <xsl:variable name="position">8</xsl:variable>
      <xsl:variable name="length">
        <xsl:value-of select="$marcDesc//*:leader/*:code[@position = $position]/@length"/>
      </xsl:variable>
      <xsl:variable name="legalValues">
        <xsl:value-of
          select="replace(replace(replace($marcDesc//*:leader/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
        />
      </xsl:variable>
      <xsl:choose>
        <!-- Replace inaccurate value -->
        <xsl:when
          test="(../*:datafield[@tag = '099']/*:subfield[@code = 'a'][matches(., '^(MSS |RG)', 'i')] or ../*:datafield[@tag = '999']/*:subfield[@code = 'a'][matches(., '^(MSS |RG)', 'i')])">
          <xsl:choose>
            <!-- MSS call number not collection or monograph -->
            <xsl:when test="matches(substring(., $position, $length), '[^cm]', 'i')">
              <!-- Keep the current value -->
              <xsl:value-of select="substring(., $position, $length)"/>
            </xsl:when>
            <!-- Datafield 300/ǂa indicates there's a single item -->
            <xsl:when
              test="number(../*:datafield[@tag = '300'][1]/*:subfield[@code = 'a'][1]) = 1 or number(substring-before(replace(../*:datafield[@tag = '300'][1]/*:subfield[@code = 'a'][1], '^\D*(\d)', '$1'), ' ')) = 1">
              <xsl:text>m</xsl:text>
            </xsl:when>
            <!-- Datafield 300/ǂa indicates there's more than 1 item -->
            <xsl:when
              test="number(../*:datafield[@tag = '300'][1]/*:subfield[@code = 'a'][1]) &gt; 1 or number(substring-before(replace(../*:datafield[@tag = '300'][1]/*:subfield[@code = 'a'][1], '^\D*(\d)', '$1'), ' ')) &gt; 1">
              <xsl:text>c</xsl:text>
            </xsl:when>
            <!-- Keep the current value -->
            <xsl:otherwise>
              <xsl:value-of select="lower-case(substring(., $position, $length))"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <!-- Replace invalid code -->
        <xsl:when test="not(matches(substring(., $position, $length), $legalValues, 'i'))"
          >|</xsl:when>
        <!-- Keep current value -->
        <xsl:otherwise>
          <xsl:value-of select="lower-case(substring(., $position, $length))"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="controlType">
      <xsl:variable name="position">9</xsl:variable>
      <xsl:variable name="length">
        <xsl:value-of select="$marcDesc//*:leader/*:code[@position = $position]/@length"/>
      </xsl:variable>
      <xsl:variable name="legalValues">
        <xsl:value-of
          select="replace(replace(replace($marcDesc//*:leader/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
        />
      </xsl:variable>
      <xsl:choose>
        <!-- Set to 'a' (archival) when 040/ǂa = 'appm' or 'dacs' -->
        <xsl:when
          test="../*:datafield[@tag = '040']/*:subfield[@code = 'e'][matches(., '(appm|dacs)', 'i')]">
          <xsl:text>a</xsl:text>
        </xsl:when>
        <!-- Set to ' ' when 040/ǂa = 'aacr' or 'rda' -->
        <xsl:when
          test="../*:datafield[@tag = '040']/*:subfield[@code = 'e'][matches(., '(aacr|rda)', 'i')]">
          <xsl:text>&#32;</xsl:text>
        </xsl:when>
        <!-- Set to 'a' (archival) when 099/ǂa or 999/ǂa matches '^MSS ' -->
        <xsl:when
          test="../*:datafield[@tag = '099' or @tag = '999']/*:subfield[@code = 'a'][matches(., '^MSS ', 'i')]">
          <xsl:text>a</xsl:text>
        </xsl:when>
        <!-- Keep valid value -->
        <xsl:when
          test="matches(lower-case(substring(., $position, $length)), $legalValues, 'i')">
          <xsl:value-of select="lower-case(substring(., $position, $length))"/>
        </xsl:when>
        <!-- Default to ' ' -->
        <xsl:otherwise>
          <xsl:text>&#32;</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="charCodeScheme">
      <xsl:variable name="position">10</xsl:variable>
      <xsl:variable name="length">
        <xsl:value-of select="$marcDesc//*:leader/*:code[@position = $position]/@length"/>
      </xsl:variable>
      <xsl:variable name="legalValues">
        <xsl:value-of
          select="replace(replace(replace($marcDesc//*:leader/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
        />
      </xsl:variable>
      <xsl:choose>
        <!-- Replace invalid code -->
        <xsl:when test="not(matches(substring(., $position, $length), $legalValues, 'i'))">
          <xsl:text>a</xsl:text>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="lower-case(substring(., $position, $length))"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <!-- Constant -->
    <xsl:variable name="indicatorCount">
      <xsl:text>2</xsl:text>
    </xsl:variable>
    <xsl:variable name="subfieldCodeCount">
      <xsl:text>2</xsl:text>
    </xsl:variable>
    <xsl:variable name="baseAddress">
      <xsl:value-of select="substring(., 13, 5)"/>
    </xsl:variable>
    <xsl:variable name="encodingLevel">
      <xsl:variable name="position">18</xsl:variable>
      <xsl:variable name="length">
        <xsl:value-of select="$marcDesc//*:leader/*:code[@position = $position]/@length"/>
      </xsl:variable>
      <xsl:variable name="legalValues">
        <xsl:value-of
          select="replace(replace(replace($marcDesc//*:leader/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
        />
      </xsl:variable>
      <xsl:choose>
        <!-- Pass through legal values -->
        <xsl:when test="matches(substring(., $position, $length), $legalValues)">
          <xsl:value-of select="substring(., $position, $length)"/>
        </xsl:when>
        <!-- Map outdated 'IJKM' values to appropriate current value -->
        <xsl:when test="matches(substring(., $position, $length), '[IJM]')">2</xsl:when>
        <xsl:when test="matches(substring(., $position, $length), '[K]')">7</xsl:when>
        <!-- Replace l (lower-case el) with 1 (digit) -->
        <xsl:when test="matches(substring(., $position, $length), 'l')">1</xsl:when>
        <!-- Fix case of 'U' and 'Z' -->
        <xsl:when test="matches(substring(., $position, $length), '[UZ]')">
          <xsl:value-of select="lower-case(substring(., $position, $length))"/>
        </xsl:when>
        <!-- Replace other illegal value with 'u' -->
        <xsl:otherwise>u</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="descriptiveForm">
      <xsl:variable name="position">19</xsl:variable>
      <xsl:variable name="length">
        <xsl:value-of select="$marcDesc//*:leader/*:code[@position = $position]/@length"/>
      </xsl:variable>
      <xsl:variable name="legalValues">
        <xsl:value-of
          select="replace(replace(replace($marcDesc//*:leader/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
        />
      </xsl:variable>
      <xsl:choose>
        <!-- Replace invalid code -->
        <xsl:when test="not(matches(substring(., $position, $length), $legalValues, 'i'))"
          >u</xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="lower-case(substring(., $position, $length))"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="multipleResourceLevel">
      <xsl:variable name="position">20</xsl:variable>
      <xsl:variable name="length">
        <xsl:value-of select="$marcDesc//*:leader/*:code[@position = $position]/@length"/>
      </xsl:variable>
      <xsl:variable name="legalValues">
        <xsl:value-of
          select="replace(replace(replace($marcDesc//*:leader/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
        />
      </xsl:variable>
      <xsl:choose>
        <!-- Replace invalid code -->
        <xsl:when test="not(matches(substring(., $position, $length), $legalValues, 'i'))">
          <xsl:text>&#32;</xsl:text>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="lower-case(substring(., $position, $length))"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <leader xmlns="http://www.loc.gov/MARC21/slim">
      <xsl:value-of select="concat($recordLength, $recordStatus, $recordType, $bibLevel, $controlType, $charCodeScheme, $indicatorCount, $subfieldCodeCount, $baseAddress, $encodingLevel, $descriptiveForm, $multipleResourceLevel, '4500')"/>
    </leader>
  </xsl:template>

  <!-- Make sure controlfields are in the MARC namespace -->
  <xsl:template match="*:controlfield[@tag &lt; 5]" mode="pass1">
    <controlfield xmlns="http://www.loc.gov/MARC21/slim">
      <xsl:apply-templates select="@*" mode="pass1"/>
      <xsl:apply-templates mode="pass1"/>
    </controlfield>
  </xsl:template>

  <!-- 006 -->
  <xsl:template match="*:controlfield[@tag = '006']" mode="pass1">
    <controlfield>
      <xsl:apply-templates select="@*" mode="pass1"/>
      <xsl:call-template name="materialSpecific006"/>
      </controlfield>
  </xsl:template>

  <!-- 007 -->
  <!-- Delete defective 007 -->
  <xsl:template match="*:controlfield[@tag = '007'][normalize-space(.) = 'ta']"
    mode="pass1"/>

  <!-- 008 -->
  <xsl:template match="*:controlfield[@tag = '008']" mode="pass1">
    <xsl:variable name="dateEntered">
      <xsl:choose>
        <!-- Codes are valid -->
        <xsl:when test="matches(substring(., 1, 6), '[0-9]{6}')">
          <xsl:value-of select="substring(., 1, 6)"/>
        </xsl:when>
        <xsl:otherwise>
          <!-- Replace 'l' (el) with '1' (one) and other non-digit chars w/ '0' -->
          <xsl:variable name="digits">
            <xsl:value-of
              select="replace(replace(substring(., 1, 6), 'l', '1'), '\D', '0')"/>
          </xsl:variable>
          <xsl:value-of select="substring($digits, 1, 2)"/>
          <xsl:value-of select="replace(substring($digits, 3, 2), '00', '01')"/>
          <xsl:value-of select="replace(substring($digits, 5, 2), '00', '01')"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="pubStatus">
      <xsl:variable name="position">7</xsl:variable>
      <xsl:variable name="length">
        <xsl:value-of
          select="$marcDesc//*:controlfield[@tag = 008 and not(@materialType)]/*:code[@position = $position]/@length"
        />
      </xsl:variable>
      <xsl:variable name="legalValues">
        <xsl:value-of
          select="replace(replace(replace($marcDesc//*:controlfield[@tag = 008 and not(@materialType)]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
        />
      </xsl:variable>
      <xsl:choose>
        <!-- Replace w/ 'n' (for 'unknown') -->
        <xsl:when
          test="matches(substring(., 8, 4), '[\p{Zs}u\\\|]{4}') and matches(substring(., 12, 4), '[\p{Zs}u\\\|]{4}')">
          <xsl:text>n</xsl:text>
        </xsl:when>
        <!-- Code is valid -->
        <xsl:when test="matches(substring(., $position, $length), $legalValues, 'i')">
          <xsl:value-of select="lower-case(substring(., $position, $length))"/>
        </xsl:when>
        <!-- Replace w/ 'no attempt to code' -->
        <xsl:otherwise>
          <xsl:value-of select="substring($fillPipes, 1, 1)"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="date1">
      <xsl:choose>
        <!-- Codes are valid -->
        <xsl:when test="matches(substring(., 8, 4), '[0-9u]{4}|[\p{Zs}\|]{4}', 'i')">
          <xsl:value-of
            select="replace(lower-case(substring(., 8, 4)), '\p{Zs}', '&#32;')"/>
        </xsl:when>
        <!-- Replace w/ 'no attempt to code' -->
        <xsl:otherwise>
          <xsl:value-of select="substring($fillPipes, 1, 4)"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="date2">
      <xsl:choose>
        <!-- Codes are valid -->
        <xsl:when test="matches(substring(., 12, 4), '[0-9u]{4}|[\p{Zs}\|]{4}', 'i')">
          <xsl:value-of
            select="replace(lower-case(substring(., 12, 4)), '\p{Zs}', '&#32;')"/>
        </xsl:when>
        <!-- Replace w/ 'no attempt to code' -->
        <xsl:otherwise>
          <xsl:value-of select="substring($fillPipes, 1, 4)"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="pubPlace">
      <xsl:choose>
        <!-- Code is minimally valid -->
        <xsl:when test="matches(substring(., 16, 3), '[a-z]{2}[a-z\s]')">
          <xsl:variable name="thisValue">
            <xsl:value-of select="substring(., 16, 3)"/>
          </xsl:variable>
          <xsl:choose>
            <!-- Replace obsolete codes with current values -->
            <xsl:when test="$thisValue = 'ac '">at </xsl:when>
            <xsl:when test="$thisValue = 'ai '">am </xsl:when>
            <xsl:when test="$thisValue = 'air'">ai </xsl:when>
            <xsl:when test="$thisValue = 'ajr'">aj </xsl:when>
            <xsl:when test="$thisValue = 'bwr'">bw </xsl:when>
            <xsl:when test="$thisValue = 'cn '">xxc</xsl:when>
            <xsl:when test="$thisValue = 'cp '">gb </xsl:when>
            <xsl:when test="$thisValue = 'cs '">xo </xsl:when>
            <xsl:when test="$thisValue = 'cz '">pn </xsl:when>
            <xsl:when test="$thisValue = 'err'">er </xsl:when>
            <xsl:when test="$thisValue = 'ge '">gw </xsl:when>
            <xsl:when test="$thisValue = 'gn '">gb </xsl:when>
            <xsl:when test="$thisValue = 'gsr'">gs </xsl:when>
            <xsl:when test="$thisValue = 'hk '">cc </xsl:when>
            <xsl:when test="$thisValue = 'iu '">is </xsl:when>
            <xsl:when test="$thisValue = 'iw '">is </xsl:when>
            <xsl:when test="$thisValue = 'jn '">no </xsl:when>
            <xsl:when test="$thisValue = 'kgr'">kg </xsl:when>
            <xsl:when test="$thisValue = 'kzr'">kz </xsl:when>
            <xsl:when test="$thisValue = 'lir'">li </xsl:when>
            <xsl:when test="$thisValue = 'ln '">gb </xsl:when>
            <xsl:when test="$thisValue = 'lvr'">lv </xsl:when>
            <xsl:when test="$thisValue = 'mh '">cc </xsl:when>
            <xsl:when test="$thisValue = 'mvr'">mv </xsl:when>
            <xsl:when test="$thisValue = 'na '">sn </xsl:when>
            <xsl:when test="$thisValue = 'nm '">nw </xsl:when>
            <xsl:when test="$thisValue = 'pt '">em </xsl:when>
            <xsl:when test="$thisValue = 'rur'">ru </xsl:when>
            <xsl:when test="$thisValue = 'ry '">ja </xsl:when>
            <xsl:when test="$thisValue = 'sb '">no </xsl:when>
            <xsl:when test="$thisValue = 'sk '">ii </xsl:when>
            <xsl:when test="$thisValue = 'sv '">ho </xsl:when>
            <xsl:when test="$thisValue = 'tar'">ta </xsl:when>
            <xsl:when test="$thisValue = 'tkr'">tk </xsl:when>
            <xsl:when test="$thisValue = 'tt '">pw </xsl:when>
            <xsl:when test="$thisValue = 'ui '">stk</xsl:when>
            <xsl:when test="$thisValue = 'uik'">stk</xsl:when>
            <xsl:when test="$thisValue = 'uk '">xxk</xsl:when>
            <xsl:when test="$thisValue = 'unr'">un </xsl:when>
            <xsl:when test="$thisValue = 'ur '">ru </xsl:when>
            <xsl:when test="$thisValue = 'us '">xxu</xsl:when>
            <xsl:when test="$thisValue = 'uzr'">uz </xsl:when>
            <xsl:when test="$thisValue = 'vn '">vm </xsl:when>
            <xsl:when test="$thisValue = 'vs '">vm </xsl:when>
            <xsl:when test="$thisValue = 'wb '">gw </xsl:when>
            <xsl:when test="$thisValue = 'xi '">am </xsl:when>
            <xsl:when test="$thisValue = 'xxr'">ru </xsl:when>
            <xsl:when test="$thisValue = 'ys '">ye </xsl:when>
            <xsl:when test="$thisValue = 'yu '">bn </xsl:when>
            <!-- Fix common errors -->
            <xsl:when test="$thisValue = 'ar '">ag </xsl:when>
            <xsl:when test="$thisValue = 'atk'">at </xsl:when>
            <xsl:when test="$thisValue = 'bck'">bcc</xsl:when>
            <xsl:when test="$thisValue = 'cnc'">onc</xsl:when>
            <xsl:when test="$thisValue = 'cnu'">ctu</xsl:when>
            <xsl:when test="$thisValue = 'dc '">dcu</xsl:when>
            <xsl:when test="$thisValue = 'en '">enk</xsl:when>
            <xsl:when test="$thisValue = 'en '">enk</xsl:when>
            <xsl:when test="$thisValue = 'guc'">quc</xsl:when>
            <xsl:when test="$thisValue = 'iek'">ie </xsl:when>
            <xsl:when test="$thisValue = 'iou'">iau</xsl:when>
            <xsl:when test="$thisValue = 'ma '">mau</xsl:when>
            <xsl:when test="$thisValue = 'mcu'">miu</xsl:when>
            <xsl:when test="$thisValue = 'neu'">nbu</xsl:when>
            <xsl:when test="$thisValue = 'nj '">nju</xsl:when>
            <xsl:when test="$thisValue = 'nku'">nkc</xsl:when>
            <xsl:when test="$thisValue = 'ny '">nyu</xsl:when>
            <xsl:when test="$thisValue = 'nyc'">nyu</xsl:when>
            <xsl:when test="$thisValue = 'nyk'">nyu</xsl:when>
            <xsl:when test="$thisValue = 'pru'">pr </xsl:when>
            <xsl:when test="$thisValue = 'tn '">tnu</xsl:when>
            <xsl:when test="$thisValue = 'unk'">enk</xsl:when>
            <xsl:when test="$thisValue = 'viu'">vau</xsl:when>
            <!-- Normalize space character -->
            <xsl:otherwise>
              <xsl:value-of select="replace($thisValue, '\p{Zs}', ' ')"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <!-- Replace w/ 'No place, unknown, or undetermined' value -->
        <xsl:otherwise>
          <xsl:text>xx </xsl:text>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="language">
      <xsl:choose>
        <!-- No attempt to code but there's an 041 -->
        <xsl:when
          test="matches(substring(., 36, 3), '\p{Zs}{3}|\|{3}') and ancestor::*:record/*:datafield[@tag = '041']">
          <xsl:value-of
            select="ancestor::*:record/*:datafield[@tag = '041'][1]/*:subfield[1]"/>
        </xsl:when>
        <!-- Code is minimally valid -->
        <xsl:when test="matches(substring(., 36, 3), '[a-z]{3}', 'i')">
          <xsl:variable name="thisValue">
            <xsl:value-of select="lower-case(substring(., 36, 3))"/>
          </xsl:variable>
          <xsl:choose>
            <!-- Replace obsolete codes with current values -->
            <xsl:when test="$thisValue = 'cro'">hrv</xsl:when>
            <xsl:when test="$thisValue = 'fle'">dut</xsl:when>
            <xsl:when test="$thisValue = 'mol'">rum</xsl:when>
            <xsl:when test="$thisValue = 'scc'">srp</xsl:when>
            <xsl:when test="$thisValue = 'scr'">hrv</xsl:when>
            <xsl:when test="$thisValue = 'scs'">srp</xsl:when>
            <xsl:when test="$thisValue = 'ser'">srp</xsl:when>
            <!-- Fix common errors -->
            <xsl:when test="$thisValue = 'end'">eng</xsl:when>
            <xsl:when test="$thisValue = 'enh'">eng</xsl:when>
            <xsl:when test="$thisValue = 'ing'">eng</xsl:when>
            <xsl:when test="$thisValue = 'jap'">jpn</xsl:when>
            <xsl:when test="$thisValue = 'rur'">rus</xsl:when>
            <!-- Normalize space character -->
            <xsl:otherwise>
              <xsl:value-of select="replace($thisValue, '\p{Zs}', '&#32;')"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <!-- Default to 'no attempt to code' -->
        <xsl:otherwise>
          <xsl:value-of select="substring($fillPipes, 1, 3)"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="recordMod">
      <xsl:variable name="position">39</xsl:variable>
      <xsl:variable name="length">
        <xsl:value-of
          select="$marcDesc//*:controlfield[@tag = 008 and not(@materialType)]/*:code[@position = $position]/@length"
        />
      </xsl:variable>
      <xsl:variable name="legalValues">
        <xsl:value-of
          select="replace(replace(replace($marcDesc//*:controlfield[@tag = 008 and not(@materialType)]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
        />
      </xsl:variable>
      <xsl:choose>
        <!-- Code is valid -->
        <xsl:when test="matches(substring(., $position, $length), $legalValues, 'i')">
          <xsl:value-of
            select="replace(lower-case(substring(., $position, $length)), '\p{Zs}', '&#32;')"
          />
        </xsl:when>
        <!-- Replace w/ 'no attempt to code' -->
        <xsl:otherwise>
          <xsl:value-of select="substring($fillPipes, 1, 1)"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="catalogSource">
      <xsl:variable name="position">40</xsl:variable>
      <xsl:variable name="length">
        <xsl:value-of
          select="$marcDesc//*:controlfield[@tag = 008 and not(@materialType)]/*:code[@position = $position]/@length"
        />
      </xsl:variable>
      <xsl:variable name="legalValues">
        <xsl:value-of
          select="replace(replace(replace($marcDesc//*:controlfield[@tag = 008 and not(@materialType)]/*:code[@position = $position]/@values, &quot;^&apos;&quot;, &quot;&quot;), &quot;&apos;$&quot;, &quot;&quot;), '\{\d+\}$', '')"
        />
      </xsl:variable>
      <xsl:choose>
        <!-- Code is valid -->
        <xsl:when test="matches(substring(., $position, $length), '[\p{Zs}\\\|cdu]', 'i')">
          <xsl:value-of
            select="replace(lower-case(substring(., $position, $length)), '\p{Zs}', '&#32;')"
          />
        </xsl:when>
        <!-- Replace w/ 'no attempt to code' -->
        <xsl:otherwise>
          <xsl:value-of select="substring($fillPipes, 1, 1)"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <controlfield>
      <xsl:apply-templates select="@*" mode="pass1"/>
      <xsl:value-of select="concat($dateEntered, $pubStatus, $date1, $date2, $pubPlace)"/>
      <xsl:call-template name="materialSpecific008"/>
      <xsl:value-of select="concat($language, $recordMod, $catalogSource)"/>
    </controlfield>
  </xsl:template>

  <!-- On 490 with too many subfield ǂ6s, delete all but the first subfield ǂ6 -->
  <xsl:template match="*:datafield[@tag = '490'][count(*:subfield[@code = '6']) &gt; 1]"
    mode="pass1">
    <datafield>
      <xsl:apply-templates select="@*" mode="pass1"/>
      <!-- Subfield 6 is always first -->
      <xsl:apply-templates select="*:subfield[@code = '6'][1]" mode="pass1"/>
      <xsl:apply-templates select="*:subfield[@code != '6']" mode="pass1"/>
    </datafield>
  </xsl:template>

  <!-- On 880 with too many subfield ǂ6s, join extra subfield ǂ6s to subfield ǂa -->
  <xsl:template
    match="*:datafield[@tag = '880'][count(*:subfield[@code = '6']) &gt; 1][count(*:subfield[@code = '6']) &gt; 1]"
    mode="pass1">
    <datafield>
      <xsl:apply-templates select="@*" mode="pass1"/>
      <xsl:apply-templates select="*:subfield[@code = '6'][1]" mode="pass1"/>
      <xsl:for-each select="*:subfield[@code != '6']">
        <xsl:copy>
          <xsl:apply-templates select="@*" mode="pass1"/>
          <xsl:choose>
            <xsl:when test="@code = 'a'">
              <xsl:value-of
                select="string-join(../*:subfield[@code = '6'][position() &gt; 1])"/>
              <xsl:value-of select="concat(' ', .)"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="."/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:copy>
      </xsl:for-each>
    </datafield>
  </xsl:template>

  <!-- Delete datafields that have no subfields or no content in their subfields -->
  <xsl:template
    match="*:datafield[not(*:subfield)] | *:datafield[normalize-space(.) eq '']"
    mode="pass1"/>

  <!-- MATCH TEMPLATES (phase 1, pass 2) -->
  <!-- Join subfields where @code = ' ' to preceding subfield -->
  <xsl:template match="*:datafield[*:subfield[normalize-space(@code) = '']]" mode="pass2">
    <xsl:variable name="thisTag">
      <xsl:value-of select="@tag"/>
    </xsl:variable>
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:for-each-group select="*"
        group-starting-with="*:subfield[normalize-space(@code) != '']">
        <xsl:for-each select="current-group()[1]">
          <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:value-of select="."/>
            <xsl:for-each select="current-group()[position() &gt; 1]">
              <!-- Don't add space separator if @tag = '041' -->
              <xsl:if test="$thisTag != '041'">
                <xsl:text>&#32;</xsl:text>
              </xsl:if>
              <xsl:value-of select="."/>
            </xsl:for-each>
          </xsl:copy>
        </xsl:for-each>
      </xsl:for-each-group>
    </xsl:copy>
  </xsl:template>

  <!-- Process other 007s -->
  <xsl:template match="*:controlfield[@tag = '007']" mode="pass2">
    <xsl:call-template name="materialSpecific007"/>
  </xsl:template>

  <!-- Translate country names in 044/ǂ9 to country codes in ǂa -->
  <xsl:template match="*:datafield[@tag = '044']" mode="pass2">
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <!-- Collect MARC country names from subfield ǂ9 -->
      <xsl:variable name="countryCodes">
        <xsl:for-each select="*:subfield[@code = '9']">
          <xsl:variable name="thisValue">
            <xsl:value-of select="normalize-space(.)"/>
          </xsl:variable>
          <subfield>
            <xsl:choose>
              <!-- When ǂ9 equals a name in $marcCountryCodes -->
              <xsl:when test="$marcCountryCodes/*:country[. = $thisValue]">
                <xsl:attribute name="code">
                  <xsl:text>a</xsl:text>
                </xsl:attribute>
                <xsl:for-each select="$marcCountryCodes/*:country[. = $thisValue][1]">
                  <xsl:choose>
                    <xsl:when test="@use">
                      <xsl:value-of select="@use"/>
                    </xsl:when>
                    <xsl:otherwise>
                      <xsl:value-of select="@code"/>
                    </xsl:otherwise>
                  </xsl:choose>
                </xsl:for-each>
              </xsl:when>
            <!-- No match in $marcCountryCodes, pass ǂ9 through -->
              <xsl:otherwise>
                <xsl:attribute name="code">
                  <xsl:text>9</xsl:text>
                </xsl:attribute>
                <xsl:value-of select="$thisValue"/>
              </xsl:otherwise>
            </xsl:choose>
          </subfield>
        </xsl:for-each>
      </xsl:variable>
      <!-- Output each unique code value in a new subfield ǂa -->
      <xsl:for-each
        select="distinct-values(*:subfield[@code = 'a'] | $countryCodes/*:subfield[@code = 'a'])">
        <xsl:sort select="lower-case(.)"/>
        <subfield code="a">
          <xsl:value-of select="."/>
        </subfield>
      </xsl:for-each>
      <xsl:for-each select="distinct-values($countryCodes/*:subfield[@code = '9'])">
        <xsl:sort select="lower-case(.)"/>
        <subfield code="9">
          <xsl:value-of select="."/>
        </subfield>
      </xsl:for-each>
      <!-- Output subfields other than ǂa and ǂ9 -->
      <xsl:apply-templates select="*:subfield[not(matches(@code, '[a9]'))]"/>
    </xsl:copy>
  </xsl:template>

  <!-- MATCH TEMPLATES (phase 1, pass 3) -->
  <!-- Join illegal subfields to preceding sibling. -->
  <!-- Datafield 044 is handled elsewhere. -->
  <xsl:template
    match="*:datafield[not(@tag = '044')][not(*:subfield[normalize-space(@code) = ''])]"
    mode="pass3">
    <datafield>
      <xsl:apply-templates select="@*" mode="pass3"/>
      <xsl:variable name="thisTag">
        <xsl:value-of select="@tag"/>
      </xsl:variable>
      <!-- Compress subfields -->
      <xsl:variable name="pass1">
        <xsl:call-template name="compressSubfields">
          <xsl:with-param name="tag">
            <xsl:value-of select="$thisTag"/>
          </xsl:with-param>
          <xsl:with-param name="subfieldList">
            <xsl:for-each select="*:subfield">
              <xsl:copy>
                <xsl:copy-of select="@*"/>
                <xsl:value-of select="normalize-space(.)"/>
              </xsl:copy>
            </xsl:for-each>
          </xsl:with-param>
        </xsl:call-template>
      </xsl:variable>
      <xsl:variable name="okSubfields">
        <xsl:variable name="definedSubfields">
          <xsl:choose>
            <xsl:when test="$thisTag = '880'">
              <xsl:variable name="linkedTag">
                <xsl:value-of select="substring(*:subfield[@code = '6'][1], 1, 3)"/>
              </xsl:variable>
              <xsl:value-of
                select="string-join($marcDesc//*:datafield[@tag = $linkedTag]/*:subfield/@code, ' ')"
              />
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of
                select="string-join($marcDesc//*:datafield[@tag = $thisTag]/*:subfield/@code, ' ')"
              />
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:if test="$definedSubfields ne ''">
          <xsl:value-of select="concat('[', $definedSubfields, ']')"/>
        </xsl:if>
      </xsl:variable>
      <xsl:choose>
        <!-- There are valid subfields to append to -->
        <xsl:when test="count(*:subfield[matches(@code, $okSubfields)]) &gt; 0">
          <xsl:variable name="groupedSubfields">
            <xsl:for-each-group select="$pass1/*:subfield"
              group-starting-with="*:subfield[matches(@code, $okSubfields)]">
              <group>
                <xsl:copy-of select="current-group()"/>
              </group>
            </xsl:for-each-group>
          </xsl:variable>
          <xsl:for-each
            select="$groupedSubfields/*:group[*:subfield[matches(@code, $okSubfields)]]/*:subfield[1]">
            <subfield>
              <xsl:apply-templates select="@*" mode="pass3"/>
              <xsl:value-of select="."/>
              <xsl:if test="following-sibling::*:subfield">
                <xsl:if test="$thisTag != '041'">
                <xsl:text>&#32;</xsl:text>
              </xsl:if>              
                <xsl:value-of select="string-join(following-sibling::*:subfield, ' ')"/>
              </xsl:if>
              <xsl:if test="position() = last() and ../preceding-sibling::*[count(*:subfield[matches(@code, $okSubfields)]) = 0]">
                <xsl:if test="$thisTag != '041'">
                <xsl:text>&#32;</xsl:text>
              </xsl:if>
              <xsl:value-of select="string-join(../preceding-sibling::*[count(*:subfield[matches(@code, $okSubfields)]) = 0]/*:subfield, ' ')"/>
              </xsl:if>
            </subfield>
          </xsl:for-each>
        </xsl:when>
        <!-- No valid subfields; output the invalid subfields -->
        <xsl:otherwise>
          <xsl:apply-templates select="*:subfield" mode="pass3"/>
        </xsl:otherwise>
      </xsl:choose>
    </datafield>
  </xsl:template>

  <!-- Delete 090 datafield that 
    1. doesn't have ǂa and doesn't have ǂb, or
    2. matches '^[A-Z]X\d+=' (noise found in some records) -->
  <xsl:template
    match="*:datafield[@tag = '090'][not(*:subfield[@code = 'a'] and *:subfield[@code = 'b'])] | *:datafield[@tag = '090'][matches(., '^\**[A-Z]X\d+=')]"
    mode="pass3" priority="3"/>

  <!-- MATCH TEMPLATES (phase 1, pass 4) -->
  <xsl:template match="*:datafield[@tag = '035']" mode="pass4">
    <xsl:if test="*:subfield and normalize-space(.) != ''">
      <datafield>
        <xsl:apply-templates select="@*" mode="pass4"/>
        <xsl:for-each select="*:subfield">
          <subfield>
          <xsl:attribute name="code">
            <xsl:choose>
              <!-- Replace subfield ǂ9 with subfield ǂz -->
              <xsl:when test="@code = '9'">
                <xsl:text>z</xsl:text>
              </xsl:when>
              <!-- Pass through other subfields -->
              <xsl:otherwise>
                <xsl:value-of select="@code"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:attribute>
          <xsl:value-of select="."/>
        </subfield>
        </xsl:for-each>
      </datafield>
    </xsl:if>
  </xsl:template>

  <!-- Join multiple 019 datafields into a single field -->
  <xsl:template match="*:datafield[@tag = '019'][1]" mode="pass4">
    <datafield>
      <xsl:apply-templates select="@*" mode="pass4"/>
      <!-- Ignore subfields other than ǂa; they're illegal -->
      <xsl:apply-templates select="*:subfield[@code = 'a']" mode="pass4"/>
      <xsl:apply-templates
        select="following-sibling::*:datafield[@tag = '019']/*:subfield[@code = 'a']"
        mode="pass4"/>
    </datafield>
  </xsl:template>

  <!-- Ignore datafield 019 after the first one -->
  <xsl:template match="*:datafield[@tag = '019'][position() &gt; 1]" mode="pass4"/>

  <!-- Delete the following datafields -->
  <xsl:template match="*:datafield[@tag = '039']" mode="pass4"/>
  <xsl:template match="*:datafield[@tag = '066']" mode="pass4"/>
  <xsl:template match="*:datafield[@tag = '092']" mode="pass4"/>

  <!-- Language of cataloging is required; default to 'eng' -->
  <xsl:template match="*:datafield[@tag = '040'][not(*:subfield[@code = 'b'])]"
    mode="pass4">
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <xsl:apply-templates select="*:subfield[@code = 'a']"/>
      <subfield code="b">eng</subfield>
      <xsl:apply-templates select="*:subfield[matches(@code, '[c-z\d]')]"/>
    </xsl:copy>
  </xsl:template>

  <!-- Delete 050 containg "provisional" (?) call number -->
  <xsl:template
    match="*:datafield[@tag = '050' and matches(normalize-space(.), '^[A-Z]{3}$')]"
    mode="pass4"/>

  <!-- Replace 090 with 050 with @ind2="4" -->
  <!-- "Bad" 090s; i.e., those lacking both ǂa and ǂb or containing noise, are deleted in pass 3 -->
  <xsl:template match="*:datafield[@tag = '090']" mode="pass4">
    <datafield tag="050" ind1=" " ind2="4">
      <xsl:apply-templates select="*:subfield" mode="pass4"/>
    </datafield>
  </xsl:template>

  <!-- Replace 099 subfield ǂv with subfield ǂa -->
  <xsl:template match="*:datafield[@tag = '099']/*:subfield[@code = 'v']" mode="pass4">
    <subfield>
      <xsl:attribute name="code">a</xsl:attribute>
      <xsl:apply-templates mode="pass4"/>
    </subfield>
  </xsl:template>

  <!-- Replace ind1="[Oo]" w/ "0" (zero) -->
  <xsl:template match="@ind1[matches(., 'O', 'i')]" priority="3" mode="pass4">
    <xsl:attribute name="ind1">
      <xsl:text>0</xsl:text>
    </xsl:attribute>
  </xsl:template>

  <!-- Replace ind2="[Oo]" w/ "0" (zero) -->
  <xsl:template match="@ind2[matches(., 'O', 'i')]" priority="3" mode="pass4">
    <xsl:attribute name="ind2">
      <xsl:text>0</xsl:text>
    </xsl:attribute>
  </xsl:template>

  <!-- MATCH TEMPLATES (phase 2) -->
  <xsl:template match="*:record" mode="phase2">
    <record>
      <!-- Copy leader from phase1 -->
      <xsl:copy-of select="*:leader"/>
      <!-- Process controlfields -->
      <xsl:apply-templates select="*:controlfield" mode="phase2">
        <xsl:sort select="number(@tag)"/>
      </xsl:apply-templates>
      <!-- Process datafields preceding 035 -->
      <xsl:apply-templates select="*:datafield[number(@tag) &lt; 35]" mode="phase2"/>
      <!-- Capture 035s -->
      <xsl:variable name="systemControlNumbers">
        <xsl:apply-templates select="*:datafield[number(@tag) = 35]" mode="phase2"/>
      </xsl:variable>
      <!-- Subset of captured 035s where subfield ǂa has a parenthetical system identifier -->
      <xsl:variable name="systemControlNumbersWithSystemID">
        <xsl:copy-of
          select="$systemControlNumbers/*:datafield[matches(*:subfield[@code = 'a'], '\(')]"
        />
      </xsl:variable>
      <!-- Clean up 035/ǂa values -->
      <xsl:variable name="systemControlNumbersClean">
        <xsl:for-each select="$systemControlNumbersWithSystemID/*:datafield">
          <xsl:copy>
            <xsl:apply-templates select="@*" mode="phase2"/>
            <xsl:for-each select="*:subfield">
              <xsl:copy>
                <xsl:apply-templates select="@*" mode="phase2"/>
                <xsl:choose>
                  <xsl:when test="@code = 'a'">
                    <xsl:value-of
                      select="replace(replace(normalize-space(.), '[^\(\)A-Za-z0-9]', '', 'i'), '^[^\(]+', '')"
                    />
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:value-of select="."/>
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:copy>
            </xsl:for-each>
          </xsl:copy>
        </xsl:for-each>
      </xsl:variable>
      <xsl:copy-of select="$systemControlNumbersClean"/>
      <!-- Process datafields following 035, but preceding 090 -->
      <xsl:apply-templates
        select="*:datafield[number(@tag) &gt; 35 and number(@tag) &lt; 90]" mode="phase2"/>
      <!-- Process unique 090s -->
      <xsl:for-each select="*:datafield[@tag = '090']">
        <xsl:variable name="thisValue">
          <xsl:value-of select="replace(normalize-space(.), '\s', '')"/>
        </xsl:variable>
        <xsl:if
          test="not(preceding-sibling::*:datafield[@tag = '090'][replace(normalize-space(.), '\s', '') = $thisValue]) and not(../*:datafield[@tag = '099'][replace(normalize-space(.), '\s', '') = $thisValue])">
          <xsl:apply-templates select="." mode="phase2"/>
        </xsl:if>
      </xsl:for-each>
      <!-- Process datafields following 090 -->
      <!-- Group datafields by hundreds, sort by @tag except 5xx and 6xx which remain in document order -->
      <xsl:apply-templates
        select="*:datafield[number(@tag) &gt; 90 and number(@tag) &lt; 100]" mode="phase2">
        <xsl:sort select="number(@tag)"/>
      </xsl:apply-templates>
      <xsl:apply-templates
        select="*:datafield[number(@tag) &gt;= 100 and number(@tag) &lt; 200]"
        mode="phase2">
        <xsl:sort select="number(@tag)"/>
      </xsl:apply-templates>
      <xsl:apply-templates
        select="*:datafield[number(@tag) &gt;= 200 and number(@tag) &lt; 300]"
        mode="phase2">
        <xsl:sort select="number(@tag)"/>
      </xsl:apply-templates>
      <xsl:apply-templates
        select="*:datafield[number(@tag) &gt;= 300 and number(@tag) &lt; 400]"
        mode="phase2">
        <xsl:sort select="number(@tag)"/>
      </xsl:apply-templates>
      <xsl:apply-templates
        select="*:datafield[number(@tag) &gt;= 400 and number(@tag) &lt; 500]"
        mode="phase2">
        <xsl:sort select="number(@tag)"/>
      </xsl:apply-templates>
      <!--  DON'T SORT 500s -->
      <xsl:apply-templates
        select="*:datafield[number(@tag) &gt;= 500 and number(@tag) &lt; 600]"
        mode="phase2"/>
      <xsl:apply-templates
        select="*:datafield[number(@tag) &gt;= 600 and number(@tag) &lt; 700]"
        mode="phase2">
        <xsl:sort select="number(@tag)"/>
      </xsl:apply-templates>
      <xsl:apply-templates
        select="*:datafield[number(@tag) &gt;= 700 and number(@tag) &lt; 800]"
        mode="phase2">
        <xsl:sort select="number(@tag)"/>
      </xsl:apply-templates>
      <xsl:apply-templates
        select="*:datafield[number(@tag) &gt;= 800 and number(@tag) &lt; 900]"
        mode="phase2">
        <xsl:sort select="number(@tag)"/>
      </xsl:apply-templates>
      <xsl:apply-templates
        select="*:datafield[number(@tag) &gt;= 900 and number(@tag) &lt;= 991]"
        mode="phase2">
        <xsl:sort select="number(@tag)"/>
      </xsl:apply-templates>
      <!-- Process 991s that don't match 'MARC (validation|remediation)'. This effectively copies
        991s that match 'OCLC remediation project'. -->
      <xsl:apply-templates
        select="*:datafield[@tag = '991'][not(*:subfield[@code = 'a'][matches(., 'MARC (validation|remediation)')])]"/>
      <!-- Add back a 991 containing 'MARC remediation' and the current date + time-->
      <datafield tag="991" ind1=" " ind2=" ">
        <subfield code="a">MARC remediation</subfield>
        <subfield code="b">
          <xsl:variable name="temp" select="string(current-dateTime())"/>
          <xsl:value-of select="concat(substring($temp, 1, 4), substring($temp, 6, 2), substring($temp, 9, 2), substring($temp, 12, 2), substring($temp, 15, 2), substring($temp, 18, 4))"/>
        </subfield>
        <subfield code="5">viu</subfield>
      </datafield>
      <xsl:apply-templates select="*:datafield[number(@tag) &gt; 991]" mode="phase2">
        <xsl:sort select="number(@tag)"/>
      </xsl:apply-templates>
    </record>
  </xsl:template>

  <!-- Repair Type of date/Publication status flag -->
  <xsl:template
    match="*:controlfield[@tag = '008'][matches(substring(., 7, 1), '[cdiku]') and ../*:leader[matches(substring(., 8, 1), 'm')]]"
    mode="phase2">
    <controlfield tag="008">
      <xsl:variable name="c260">
        <!-- Some records, e.g., u10459, use lowercase 'l' as number 1 -->
        <xsl:for-each select="../*:datafield[@tag = '260']/*:subfield[@code = 'c']">
          <xsl:value-of select="normalize-space(replace(., 'l', '1'))"/>
        </xsl:for-each>
      </xsl:variable>
      <xsl:variable name="date1">
        <xsl:value-of select="substring(., 8, 4)"/>
      </xsl:variable>
      <xsl:variable name="date2">
        <xsl:value-of select="substring(., 12, 4)"/>
      </xsl:variable>
      <!-- In date1copy and date2copy, character class contains
        copyright sign, copyright sign for recordings, "c", or "p" -->
      <xsl:variable name="date1copy">
        <xsl:value-of select="concat('[©℗cp]\s*', substring(., 8, 4))"/>
      </xsl:variable>
      <xsl:variable name="date2copy">
        <xsl:value-of select="concat('[©℗cp]\s*', substring(., 12, 4))"/>
      </xsl:variable>
      <xsl:variable name="dateRange">
        <xsl:value-of select="concat(substring(., 8, 4), '-', substring(., 12, 4))"/>
      </xsl:variable>
      <xsl:choose>
        <!-- 260ǂc contains a date range -->
        <xsl:when test="matches($c260, $dateRange)">
          <xsl:value-of select="concat(substring(., 1, 6), 'm', substring(., 8))"/>
        </xsl:when>
        <!-- 260ǂc contains a copyright or production date -->
        <xsl:when test="matches($c260, $date1copy) or matches($c260, $date2copy)">
          <xsl:value-of select="concat(substring(., 1, 6), 't', substring(., 8))"/>
        </xsl:when>
        <!-- 2 dates in 008 and 260ǂc matches either one; this is a slightly different
          version of the previous test -->
        <xsl:when test="normalize-space($date2) != '' and matches($c260, $date1) or matches($c260, $date2)">
          <xsl:value-of select="concat(substring(., 1, 6), 't', substring(., 8))"/>
        </xsl:when>
        <!-- There's a 500 note containing the string 'reprint' -->
        <xsl:when test="../*:datafield[@tag = '500'][matches(., 'reprint', 'i')]">
          <xsl:value-of select="concat(substring(., 1, 6), 'r', substring(., 8))"/>
        </xsl:when>
        <xsl:when test="normalize-space(substring(., 12, 4)) = ''">
          <xsl:value-of select="concat(substring(., 1, 6), 's', substring(., 8))"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="."/>
        </xsl:otherwise>
      </xsl:choose>
    </controlfield>
  </xsl:template>

  <!-- Repair @ind1 -->
  <!-- Fixed value = ' ' -->
  <xsl:template
    match="*:datafield[matches(@tag, '(010|013|015|017|018|019|020|025|026|027|030|031|032|035|036|038|040|042|043|044|046|047|048|051|061|066|071|072|074|084|085|088|090|096|099|222|250|251|254|255|256|257|258|261|262|263|300|306|310|321|336|337|338|340|343|344|345|346|347|348|351|352|357|365|366|370|377|380|381|383|385|386|440|500|501|502|504|507|508|513|514|515|518|525|530|533|534|536|538|539|540|546|547|550|552|562|563|580|584|585|591|592|593|594|595|596|597|598|647|648|651|656|657|658|662|691|751|752|753|754|758|830|841|842|843|844|845|850|855|876|877|878|882|884|887|910|936|938|987|994|999)')]/@ind1[not(matches(., '&#32;'))]"
    priority="2" mode="phase2">
    <xsl:attribute name="ind1">
      <xsl:text>&#32;</xsl:text>
    </xsl:attribute>
  </xsl:template>

  <!-- Fixed value = '0' -->
  <xsl:template
    match="*:datafield[matches(@tag, '(510|511)')]/@ind1[not(matches(., '[01]'))]"
    mode="phase2">
    <xsl:attribute name="ind1">
      <xsl:text>0</xsl:text>
    </xsl:attribute>
  </xsl:template>

  <!-- Best-guess value = '&#32;' -->
  <xsl:template
    match="*:datafield[matches(@tag, '(260)')]/@ind1[not(matches(., '[\s23]'))]"
    mode="phase2">
    <xsl:attribute name="ind1">
      <xsl:text>&#32;</xsl:text>
    </xsl:attribute>
  </xsl:template>

  <xsl:template
    match="*:datafield[matches(@tag, '(264)')]/@ind1[not(matches(., '[\s23]'))]"
    mode="phase2">
    <xsl:attribute name="ind1">
      <xsl:text>&#32;</xsl:text>
    </xsl:attribute>
  </xsl:template>

  <xsl:template
    match="*:datafield[matches(@tag, '(650)')]/@ind1[not(matches(., '[\s012]'))]"
    mode="phase2">
    <xsl:attribute name="ind1">
      <xsl:choose>
        <xsl:when test="count(ancestor::*:record/*:datafield[matches(@tag, '(650)')]) = 1">
          <xsl:text>0</xsl:text>
        </xsl:when>
        <xsl:otherwise>
          <xsl:text>&#32;</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:attribute>
  </xsl:template>

  <!-- Series traced/untraced -->
  <xsl:template match="*:datafield[matches(@tag, '(490)')]/@ind1[not(matches(., '[01]'))]"
    mode="phase2">
    <xsl:attribute name="ind1">
      <xsl:choose>
        <!-- Series traced -->
        <xsl:when test="../*:datafield[matches(@tag, '(800|810|811|830)')]">
          <xsl:text>1</xsl:text>
        </xsl:when>
        <!-- Series untraced -->
        <xsl:otherwise>
          <xsl:text>0</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:attribute>
  </xsl:template>

  <xsl:template match="*:datafield[matches(@tag, '(490)')]/@ind1[matches(., '1')]"
    mode="phase2">
    <xsl:attribute name="ind1">
      <xsl:choose>
        <!-- Change ind1 to '0' if there's no 8XX -->
        <xsl:when
          test="not(ancestor::*:record/*:datafield[matches(@tag, '(800|810|811|830)')])">
          <xsl:text>0</xsl:text>
        </xsl:when>
        <xsl:otherwise>
          <xsl:text>1</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:attribute>
  </xsl:template>

  <!-- Best-guess value = '0' -->
  <xsl:template
    match="*:datafield[matches(@tag, '(505)')]/@ind1[not(matches(., '[0128]'))]"
    mode="phase2">
    <xsl:attribute name="ind1">
      <xsl:text>0</xsl:text>
    </xsl:attribute>
  </xsl:template>

  <!-- Best-guess value = '1' -->
  <xsl:template match="*:datafield[matches(@tag, '(362)')]/@ind1[not(matches(., '[01]'))]"
    mode="phase2">
    <xsl:attribute name="ind1">
      <xsl:text>1</xsl:text>
    </xsl:attribute>
  </xsl:template>

  <xsl:template match="*:datafield[matches(@tag, '(535)')]/@ind1[not(matches(., '[12]'))]"
    mode="phase2">
    <xsl:attribute name="ind1">
      <xsl:text>1</xsl:text>
    </xsl:attribute>
  </xsl:template>

  <!-- Replace non-compliant value with best-guess value -->
  <xsl:template
    match="*:datafield[matches(@tag, '024')]/@ind1[not(matches(., '[0123478]'))]"
    mode="phase2">
    <xsl:attribute name="ind1">
      <xsl:text>8</xsl:text>
    </xsl:attribute>
  </xsl:template>

  <xsl:template match="*:datafield[matches(@tag, '655')]/@ind1[not(matches(., '[\s0]'))]"
    mode="phase2">
    <xsl:choose>
      <xsl:when test="count(../*:subfield[matches(@code, '[ab]')]) &gt; 1">
        <xsl:attribute name="ind1">
          <xsl:text>0</xsl:text>
        </xsl:attribute>
      </xsl:when>
      <xsl:otherwise>
        <xsl:attribute name="ind1">
          <xsl:text>&#32;</xsl:text>
        </xsl:attribute>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Repair name type flag in ind1 -->
  <xsl:template match="*:datafield[matches(@tag, '800')]/@ind1[not(matches(., '[013]'))]"
    mode="phase2">
    <xsl:choose>
      <xsl:when
        test="matches(replace(normalize-space(../*:subfield[@code = 'a']), '\W+$', ''), ',')">
        <xsl:attribute name="ind1">
          <xsl:text>1</xsl:text>
        </xsl:attribute>
      </xsl:when>
      <xsl:otherwise>
        <xsl:attribute name="ind1">
          <xsl:text>0</xsl:text>
        </xsl:attribute>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Repair @ind2 -->
  <!-- Fixed value = ' ' -->
  <xsl:template
    match="*:datafield[matches(@tag, '(010|013|015|016|018|019|020|022|025|026|027|029|030|031|032|035|036|037|038|040|042|043|044|045|046|051|052|061|066|070|071|074|080|083|084|085|086|088|090|092|096|100|110|111|130|250|251|254|255|256|257|258|260|261|262|263|300|306|307|310|321|336|337|338|340|341|343|344|345|346|347|348|351|352|355|357|362|365|366|370|380|381|383|384|385|386|388|490|500|501|502|504|506|507|508|510|511|513|514|515|516|518|520|521|522|524|525|526|530|532|533|534|535|536|538|539|540|541|542|544|545|546|547|550|552|555|556|561|562|563|565|567|580|581|583|584|585|586|588|590|591|592|593|594|595|596|597|598|654|658|662|720|751|752|753|754|758|800|810|811|841|842|843|844|845|850|855|876|877|878|882|883|884|886|887|910|936|938|987|994|999)')]/@ind2[not(matches(., '&#32;'))]"
    mode="phase2">
    <xsl:attribute name="ind2">
      <xsl:text>&#32;</xsl:text>
    </xsl:attribute>
  </xsl:template>

  <!-- Replace non-compliant value with fixed value -->
  <xsl:template
    match="*:datafield[matches(@tag, '(653)')]/@ind2[not(matches(., '[\s0-6]'))]"
    mode="phase2">
    <xsl:attribute name="ind2">
      <xsl:text>&#32;</xsl:text>
    </xsl:attribute>
  </xsl:template>

  <xsl:template
    match="*:datafield[matches(@tag, '(656|657)')]/@ind2[not(matches(., '7'))]"
    mode="phase2">
    <xsl:attribute name="ind2">
      <xsl:text>7</xsl:text>
    </xsl:attribute>
  </xsl:template>

  <!-- Replace non-compliant value with best-guess value -->
  <xsl:template
    match="*:datafield[matches(@tag, '(264)')]/@ind2[not(matches(., '[0-4]'))]"
    mode="phase2">
    <xsl:attribute name="ind2">
      <xsl:text>1</xsl:text>
    </xsl:attribute>
  </xsl:template>

  <xsl:template match="*:datafield[matches(@tag, '505')]/@ind2[not(matches(., '\s0'))]"
    mode="phase2">
    <xsl:attribute name="ind2">
      <xsl:choose>
        <xsl:when
          test="count(../*:subfield[@code = 'a']) = 1 and count(../*:subfield[@code != 'a']) = 0">
          <xsl:text>&#32;</xsl:text>
        </xsl:when>
        <xsl:otherwise>
          <xsl:text>0</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:attribute>
  </xsl:template>

  <xsl:template
    match="*:datafield[matches(@tag, '600|610|611|630|647|648|650|651|655')]/@ind2[not(matches(., '[0-7]'))]"
    mode="phase2">
    <xsl:choose>
      <xsl:when test="../*:subfield[@code = '2']">
        <xsl:attribute name="ind2">
          <xsl:text>7</xsl:text>
        </xsl:attribute>
      </xsl:when>
      <xsl:otherwise>
        <xsl:attribute name="ind2">
          <xsl:text>0</xsl:text>
        </xsl:attribute>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template
    match="*:datafield[matches(@tag, '(700|710|711|730|740)')]/@ind2[not(matches(., '[\s2]'))]"
    mode="phase2">
    <xsl:attribute name="ind2">
      <xsl:text>&#32;</xsl:text>
    </xsl:attribute>
  </xsl:template>

  <!--<xsl:template
    match="*:datafield[matches(@tag, '(830)')]/@ind2[not(matches(., '[0-9]'))]"
    mode="phase2">
    <xsl:attribute name="ind2">
      <xsl:text>0</xsl:text>
    </xsl:attribute>
  </xsl:template>
-->
  <xsl:template match="*:datafield[matches(@tag, '866')]/@ind2[not(matches(., '[0127]'))]"
    mode="phase2">
    <xsl:attribute name="ind2">
      <xsl:text>0</xsl:text>
    </xsl:attribute>
  </xsl:template>

  <!-- Fix 040 erroneous subfield @code -->
  <xsl:template
    match="*:datafield[matches(@tag, '040')]/*:subfield[@code = 'b' and . = 'VA@']"
    mode="phase2">
    <subfield code="d">VA@</subfield>
  </xsl:template>

  <!-- 041 -->
  <xsl:template match="*:datafield[@tag = '041']" mode="phase2">
    <xsl:choose>
      <!-- Replace 041 with 043 when subfield @code is missing -->
      <xsl:when test="count(*:subfield) = 1 and count(*:subfield[not(@code)]) = 1">
        <datafield tag="043" ind1=" " ind2=" ">
          <subfield code="a">
            <xsl:value-of select="."/>
          </subfield>
        </datafield>
      </xsl:when>
      <!-- Replace 041 with 043 when subfield ǂa matches '-' -->
      <xsl:when
        test="count(*:subfield) = 1 and count(*:subfield[@code = 'a']) = 1 and matches(*:subfield[@code = 'a'], '-')">
        <datafield tag="043" ind1=" " ind2=" ">
          <subfield code="a">
            <xsl:value-of select="."/>
          </subfield>
        </datafield>
      </xsl:when>
      <!-- Split over-long 041 subfields into multiple subfields -->
      <xsl:when test="*:subfield[string-length(.) &gt; 3]">
        <xsl:copy>
          <xsl:apply-templates select="@tag"/>
          <!-- Set @ind1 based on presence of subfield ǂh or ǂn -->
          <xsl:attribute name="ind1">
            <xsl:choose>
              <xsl:when test="*:subfield[matches(@code, '[hn]')]">
                <xsl:text>1</xsl:text>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="@ind1"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:attribute>
          <xsl:apply-templates select="@ind2" mode="phase2"/>
          <xsl:for-each select="*:subfield">
            <xsl:choose>
              <!-- Split multiple codes without separators into multiple subfields -->
              <xsl:when test="matches(., '([a-z]{3})+$')">
                <xsl:call-template name="split041subfield">
                  <xsl:with-param name="thisValue">
                    <!-- Fix common errors -->
                    <xsl:value-of
                      select="replace(replace(replace(replace(replace(normalize-space(.), '[^a-zA-Z]+$', ''), 'jap', 'jpn'), 'ing', 'eng'), 'end', 'eng'), 'rur', 'rus')"
                    />
                  </xsl:with-param>
                </xsl:call-template>
              </xsl:when>
              <!-- Split multiple codes with separators into multiple subfields -->
              <xsl:when test="matches(., '([a-z]{3}[^a-z])+')">
                <xsl:variable name="thisSubfield">
                  <xsl:value-of select="@code"/>
                </xsl:variable>
                <xsl:analyze-string
                  select="replace(normalize-space(.), '[^a-zA-Z]+$', '')" regex="[^a-z]+">
                  <xsl:non-matching-substring>
                    <subfield code="{$thisSubfield}">
                      <!-- Fix common errors -->
                      <xsl:value-of select="replace(replace(replace(replace(., 'jap', 'jpn'), 'ing', 'eng'), 'end', 'eng'), 'rur', 'rus')"/>
                    </subfield>
                  </xsl:non-matching-substring>
                </xsl:analyze-string>
              </xsl:when>
              <!-- Single code -->
              <xsl:otherwise>
                <subfield>
                  <xsl:attribute name="code">
                    <xsl:choose>
                      <xsl:when test="@code">
                        <xsl:value-of select="@code"/>
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:text>a</xsl:text>
                      </xsl:otherwise>
                    </xsl:choose>
                  </xsl:attribute>
                  <!-- Fix common errors -->
                  <xsl:value-of select="replace(replace(replace(replace(replace(normalize-space(.), '[^a-zA-Z]+$', ''), 'jap', 'jpn'), 'ing', 'eng'), 'end', 'eng'), 'rur', 'rus')"/>
                </subfield>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:for-each>
        </xsl:copy>
      </xsl:when>
      <!-- "Regular" 041 -->
      <xsl:otherwise>
        <datafield>
          <xsl:apply-templates select="@*" mode="phase2"/>
          <xsl:apply-templates mode="phase2"/>
        </datafield>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- 041 subfield ǂb -->
  <xsl:template match="*:datafield[@tag = '041']/*:subfield[@code = 'b']" mode="phase2">
    <xsl:choose>
      <!-- Substitute ǂj for ǂb for video material -->
      <xsl:when
        test="ancestor::*:record/*:datafield[@tag = '099'][*:subfield[@code = 'a'][matches(., '^VIDEO', 'i')]] or ancestor::*:record/*:datafield[@tag = '245'][*:subfield[@code = 'h'][matches(., 'videorecording', 'i')]] or ancestor::*:record/*:controlfield[@tag = '007'][substring(., 1, 1) = 'v'] or (ancestor::*:record/*:leader[substring(., 7, 1) = 'g'] and ancestor::*:record/*:controlfield[@tag = '008'][matches(substring(., 34, 1), '[mv]')])">
        <!-- Fix common errors -->
        <subfield code="j">
          <xsl:value-of select="replace(replace(replace(replace(replace(normalize-space(.), '[^a-zA-Z]+$', ''), 'jap', 'jpn'), 'ing', 'eng'), 'end', 'eng'), 'rur', 'rus')"/>
        </subfield>
      </xsl:when>
      <!-- Fix common errors -->
      <xsl:otherwise>
        <subfield code="b">
          <xsl:value-of select="replace(replace(replace(replace(replace(normalize-space(.), '[^a-zA-Z]+$', ''), 'jap', 'jpn'), 'ing', 'eng'), 'end', 'eng'), 'rur', 'rus')"/>
        </subfield>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- 041 subfields other than ǂb -->
  <xsl:template match="*:datafield[@tag = '041']/*:subfield[not(matches(@code, '[b]'))]"
    mode="phase2">
    <!-- Fix common errors -->
    <subfield>
      <xsl:attribute name="code">
        <xsl:value-of select="@code"/>
      </xsl:attribute>
      <xsl:value-of select="replace(replace(replace(replace(replace(normalize-space(.), '[^a-zA-Z]+$', ''), 'jap', 'jpn'), 'ing', 'eng'), 'end', 'eng'), 'rur', 'rus')"/>
    </subfield>
  </xsl:template>

  <!-- Repair 041 @ind1 -->
  <xsl:template match="*:datafield[@tag = '041']/@ind1" mode="phase2">
    <xsl:attribute name="ind1">
      <xsl:choose>
        <!-- Libretto language different than text or performed language -->
        <xsl:when
          test="../*:subfield[@code = 'e'] and ../*:subfield[matches(@code, '[ad]')] and not(deep-equal(distinct-values(../*:subfield[matches(@code, '[e]')]), distinct-values(../*:subfield[matches(@code, '[ad]')])))">
          <xsl:text>1</xsl:text>
        </xsl:when>
        <!-- Original language different than text, performed, or libretto language -->
        <xsl:when
          test="../*:subfield[@code = 'h'] and ../*:subfield[matches(@code, '[ade]')] and not(deep-equal(distinct-values(../*:subfield[matches(@code, '[h]')]), distinct-values(../*:subfield[matches(@code, '[ade]')])))">
          <xsl:text>1</xsl:text>
        </xsl:when>
        <!-- Intertitle language different than text, performed, libretto, or subtitle language -->
        <xsl:when
          test="../*:subfield[@code = 'i'] and ../*:subfield[matches(@code, '[adej]')] and not(deep-equal(distinct-values(../*:subfield[matches(@code, '[i]')]), distinct-values(../*:subfield[matches(@code, '[adej]')])))">
          <xsl:text>1</xsl:text>
        </xsl:when>
        <!-- Subtitle language different than text, performed, libretto, or original language -->
        <xsl:when
          test="../*:subfield[@code = 'j'] and ../*:subfield[matches(@code, '[adeh]')] and not(deep-equal(distinct-values(../*:subfield[matches(@code, '[j]')]), distinct-values(../*:subfield[matches(@code, '[adeh]')])))">
          <xsl:text>1</xsl:text>
        </xsl:when>
        <!-- Intermediate language different than text, performed, libretto, or original language -->
        <xsl:when
          test="../*:subfield[@code = 'k'] and ../*:subfield[matches(@code, '[adeh]')] and not(deep-equal(distinct-values(../*:subfield[matches(@code, '[k]')]), distinct-values(../*:subfield[matches(@code, '[adeh]')])))">
          <xsl:text>1</xsl:text>
        </xsl:when>
        <!-- Original accompanying material language different than accompanying material language -->
        <xsl:when
          test="../*:subfield[@code = 'm'] and ../*:subfield[matches(@code, '[g]')] and not(deep-equal(distinct-values(../*:subfield[matches(@code, '[m]')]), distinct-values(../*:subfield[matches(@code, '[g]')])))">
          <xsl:text>1</xsl:text>
        </xsl:when>
        <!-- Original libretto language different than libretto language -->
        <xsl:when
          test="../*:subfield[@code = 'n'] and ../*:subfield[matches(@code, '[e]')] and not(deep-equal(distinct-values(../*:subfield[matches(@code, '[n]')]), distinct-values(../*:subfield[matches(@code, '[e]')])))">
          <xsl:text>1</xsl:text>
        </xsl:when>
        <!-- Caption language different than text, performed, libretto, or original language -->
        <xsl:when
          test="../*:subfield[@code = 'p'] and ../*:subfield[matches(@code, '[adeh]')] and not(deep-equal(distinct-values(../*:subfield[matches(@code, '[p]')]), distinct-values(../*:subfield[matches(@code, '[adeh]')])))">
          <xsl:text>1</xsl:text>
        </xsl:when>
        <!-- Accessible audio language different than text, performed, libretto, or original language -->
        <xsl:when
          test="../*:subfield[@code = 'q'] and ../*:subfield[matches(@code, '[adeh]')] and not(deep-equal(distinct-values(../*:subfield[matches(@code, '[q]')]), distinct-values(../*:subfield[matches(@code, '[adeh]')])))">
          <xsl:text>1</xsl:text>
        </xsl:when>
        <!-- Accessible visual language different than text, performed, libretto, or original language -->
        <!-- This is not a translation according to https://www.loc.gov/marc/bibliographic/bd041.html -->
        <!--<xsl:when
          test="../*:subfield[@code = 'r'] and ../*:subfield[matches(@code, '[adeh]')] 
          and not(deep-equal(distinct-values(../*:subfield[matches(@code, '[r]')]), 
          distinct-values(../*:subfield[matches(@code, '[adeh]')])))">
          <xsl:text>1</xsl:text>
        </xsl:when>-->
        <!-- Transcript language different than text, performed, libretto, or original language -->
        <xsl:when
          test="../*:subfield[@code = 't'] and ../*:subfield[matches(@code, '[adeh]')] and not(deep-equal(distinct-values(../*:subfield[matches(@code, '[t]')]), distinct-values(../*:subfield[matches(@code, '[adeh]')])))">
          <xsl:text>1</xsl:text>
        </xsl:when>
        <!-- No translation indicated -->
        <xsl:otherwise>
          <xsl:text>0</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:attribute>
  </xsl:template>

  <!-- Since 049 isn't repeatable, join all 049s into a single datafield -->
  <xsl:template match="*:datafield[matches(@tag, '049')][1]" mode="phase2">
    <datafield>
      <xsl:apply-templates select="@*"/>
      <xsl:apply-templates select="*:subfield"/>
      <xsl:apply-templates
        select="following-sibling::*:datafield[matches(@tag, '049')]/*:subfield"/>
    </datafield>
  </xsl:template>

  <!-- Ignore 049s other than the first -->
  <xsl:template match="*:datafield[matches(@tag, '049')][position() &gt; 1]" mode="phase2"/>

  <!-- Repair @ind1 on 110, 111, 610, 611, 710, and 711 -->
  <xsl:template
    match="*:datafield[matches(@tag, '110|111|610|611|710|711')]/@ind1[not(matches(., '[012]'))]"
    mode="phase2">
    <xsl:attribute name="ind1">
      <xsl:choose>
        <!-- Jurisdiction name -->
        <xsl:when
          test="not(matches(../*:subfield[@code = 'a'], '\.$')) and count(tokenize(../*:subfield[@code = 'a'], '\.')) &gt; 1">
          <xsl:text>1</xsl:text>
        </xsl:when>
        <!-- Inverted name -->
        <xsl:when
          test="count(tokenize(../*:subfield[@code = 'a'], ',')) &gt; 1 and count(tokenize(tokenize(../*:subfield[@code = 'a'], ',')[1], '\W')) &lt; 3">
          <xsl:text>0</xsl:text>
        </xsl:when>
        <!-- Direct order name -->
        <xsl:otherwise>
          <xsl:text>2</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:attribute>
  </xsl:template>

  <!-- Repair @ind1 on 541 -->
  <xsl:template match="*:datafield[matches(@tag, '541')]/@ind1" mode="phase2">
    <xsl:attribute name="ind1">
      <xsl:choose>
        <!-- When ǂb (address) is present, set @ind1 to '0' (private) -->
        <xsl:when test="../*:subfield[@code = 'b']">
          <xsl:text>0</xsl:text>
        </xsl:when>
        <!-- Leave current value in place -->
        <xsl:otherwise>
          <xsl:value-of select="."/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:attribute>
  </xsl:template>

  <!-- Repair @ind1 on 100, 600, and 700 -->
  <xsl:template
    match="*:datafield[matches(@tag, '100|600|700')]/@ind1[not(matches(., '[013]'))]"
    mode="phase2">
    <xsl:attribute name="ind1">
      <xsl:choose>
        <!-- Family name -->
        <xsl:when test="matches(../*:subfield[@code = 'a'], 'family', 'i')">
          <xsl:text>3</xsl:text>
        </xsl:when>
        <!-- Surname -->
        <xsl:when
          test="count(tokenize(../*:subfield[@code = 'a'], ',')) &gt; 1 and count(tokenize(tokenize(../*:subfield[@code = 'a'], ',')[1], '\W')) &lt; 3">
          <xsl:text>1</xsl:text>
        </xsl:when>
        <!-- Forename -->
        <xsl:otherwise>
          <xsl:text>0</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:attribute>
  </xsl:template>

  <!-- Repair ind2 on 130, 630, and 730 -->
  <xsl:template match="*:datafield[matches(@tag, '(130|630|730)')]/@ind1" mode="phase2">
    <xsl:attribute name="ind1">
      <xsl:variable name="subfieldA" select="lower-case(../*:subfield[@code = 'a'])"/>
      <xsl:variable name="langCode"
        select="substring(ancestor::*:record/*:controlfield[@tag = '008'], 36, 3)"/>
      <xsl:choose>
        <xsl:when test="$marcArticleList//*:lang[matches(@codes, $langCode)]">
          <xsl:variable name="articleLength">
            <xsl:for-each select="$marcArticleList//*:lang[matches(@codes, $langCode)]">
              <xsl:variable name="articleString" select="concat('^', ../*:article)"/>
              <xsl:if test="matches($subfieldA, $articleString)">
                <xsl:value-of select="string-length($articleString) - 1"/>
              </xsl:if>
            </xsl:for-each>
          </xsl:variable>
          <xsl:choose>
            <xsl:when test="number($articleLength) &gt; 0">
              <xsl:value-of select="$articleLength"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:text>0</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:when test="not(matches(., '[0-9]'))">
          <xsl:text>0</xsl:text>
        </xsl:when>
        <xsl:otherwise>
          <xsl:text>0</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:attribute>
  </xsl:template>

  <!-- Since 245 isn't repeatable, convert occurrences after the first to 246? -->
  <!--<xsl:template match="*:datafield[matches(@tag, '245')][position() &gt; 1]">
  </xsl:template>-->

  <!-- On 210 and 240 replace non-compliant ind1 value with '1' -->
  <xsl:template
    match="*:datafield[matches(@tag, '210|240')]/@ind1[not(matches(., '[01]'))]"
    mode="phase2">
    <xsl:attribute name="ind1">
      <xsl:text>1</xsl:text>
    </xsl:attribute>
  </xsl:template>

  <!-- Repair 245 indicators -->
  <xsl:template match="*:datafield[matches(@tag, '245')]/@ind1[not(matches(., '[01]'))]"
    mode="phase2">
    <xsl:attribute name="ind1">
      <xsl:text>0</xsl:text>
    </xsl:attribute>
  </xsl:template>

  <!-- Repair ind2 on 222, 240, 243, 243, 245, 440, and 830 -->
  <xsl:template match="*:datafield[matches(@tag, '(222|240|242|243|245|440|830)')]/@ind2"
    mode="phase2">
    <xsl:attribute name="ind2">
      <xsl:variable name="subfieldA" select="lower-case(../*:subfield[@code = 'a'])"/>
      <xsl:variable name="langCode">
        <xsl:choose>
          <!-- Use first language code from first 041 -->
          <xsl:when
            test="matches(substring(ancestor::*:record/*:controlfield[@tag = '008'], 36, 3), 'zxx|\|{3}|\s{3}') and ancestor::*:record/*:datafield[@tag = '041']">
            <xsl:choose>
              <xsl:when
                test="ancestor::*:record/*:datafield[@tag = '041'][1]/*:subfield[1][matches(., 'zxx')]">
                <xsl:text>eng</xsl:text>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of
                  select="ancestor::*:record/*:datafield[@tag = '041'][1]/*:subfield[1]"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:when>
          <!-- Use code from 008 -->
          <xsl:when
            test="matches(substring(ancestor::*:record/*:controlfield[@tag = '008'], 36, 3), '[a-z]{3}')">
            <xsl:value-of
              select="substring(ancestor::*:record/*:controlfield[@tag = '008'], 36, 3)"/>
          </xsl:when>
          <!-- Default to English -->
          <xsl:otherwise>
            <xsl:text>eng</xsl:text>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
      <xsl:choose>
        <xsl:when test="$marcArticleList//*:lang[matches(@codes, $langCode)]">
          <xsl:variable name="articleLength">
            <xsl:for-each select="$marcArticleList//*:lang[matches(@codes, $langCode)]">
              <xsl:variable name="articleString" select="concat('^', ../*:article)"/>
              <xsl:if test="matches($subfieldA, $articleString)">
                <xsl:value-of select="string-length($articleString) - 1"/>
              </xsl:if>
            </xsl:for-each>
          </xsl:variable>
          <xsl:choose>
            <xsl:when test="number($articleLength) &gt; 0">
              <xsl:value-of select="$articleLength"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:text>0</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:otherwise>
          <xsl:text>0</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:attribute>
  </xsl:template>

  <!-- Repair 246 indicators -->
  <xsl:template match="*:datafield[matches(@tag, '246')]/@ind1[not(matches(., '[0123]'))]"
    mode="phase2">
    <xsl:attribute name="ind1">
      <xsl:text>1</xsl:text>
    </xsl:attribute>
  </xsl:template>

  <xsl:template
    match="*:datafield[matches(@tag, '246')]/@ind2[not(matches(., '[\s0-8]'))]"
    mode="phase2">
    <xsl:attribute name="ind2">
      <xsl:text>&#32;</xsl:text>
    </xsl:attribute>
  </xsl:template>

  <!-- Replace 506ǂs with ǂa -->
  <xsl:template match="*:datafield[@tag = '506']/*:subfield[@code = 's']" mode="phase2">
    <subfield code="a">
      <xsl:value-of select="."/>
    </subfield>
  </xsl:template>

  <!-- In 600 keep only allowed subfields -->
  <xsl:template match="*:datafield[@tag = '600']" mode="phase2">
    <datafield>
      <xsl:apply-templates select="@*" mode="phase2"/>
      <xsl:apply-templates
        select="*:subfield[matches(@code, '[abcdefghjklmnopqrstuvxyz0123468]')]"
        mode="phase2"/>
    </datafield>
  </xsl:template>

  <!-- In 653 keep ǂ6 & ǂ8, make all other subfields ǂa -->
  <xsl:template match="*:datafield[@tag = '653']" mode="phase2">
    <datafield>
      <xsl:apply-templates select="@*" mode="phase2"/>
      <xsl:for-each select="*:subfield">
        <subfield>
          <xsl:attribute name="code">
            <xsl:choose>
              <xsl:when test="matches(@code, '6|8')">
                <xsl:value-of select="@code"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:text>a</xsl:text>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:attribute>
          <xsl:value-of select="."/>
        </subfield>
      </xsl:for-each>
    </datafield>
  </xsl:template>

  <!-- Set @ind2 = '0' when value is invalid -->
  <xsl:template match="*:datafield[@tag = '695']/@ind2[not(matches(., '[0-59]'))]"
    mode="phase2">
    <xsl:attribute name="ind2">9</xsl:attribute>
  </xsl:template>

  <!-- Delete 773 when ǂa matches library name in 999 -->
  <xsl:template match="*:datafield[@tag = '773']" mode="phase2">
    <!-- Create a look-up table of library names -->
    <xsl:variable name="libraries">
      <xsl:copy-of select="../*:datafield[@tag = '999']/*:subfield[@code = 'm']"/>
    </xsl:variable>
    <!-- Capture ǂa -->
    <xsl:variable name="heading">
      <xsl:value-of select="upper-case(normalize-space(*:subfield[@code = 'a']))"/>
    </xsl:variable>
    <xsl:choose>
      <!-- Don't process the 773 if ǂa matches a library name -->
      <xsl:when test="$libraries//*:subfield[. eq $heading]"/>
      <xsl:otherwise>
        <datafield>
          <xsl:apply-templates select="@*" mode="phase2"/>
          <xsl:apply-templates mode="phase2"/>
        </datafield>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- On 76x, 77x, and 78x, replace non-compliant ind1 value with '0' -->
  <xsl:template
    match="*:datafield[matches(@tag, '(760|762|765|767|770|772|773|774|775|776|777|780|785|786|787)')]/@ind1[not(matches(., '[01]'))]"
    mode="phase2">
    <xsl:attribute name="ind1">
      <xsl:text>0</xsl:text>
    </xsl:attribute>
  </xsl:template>

  <!-- On 780, replace non-compliant ind2 value with '0' -->
  <xsl:template match="*:datafield[matches(@tag, '780')]/@ind2[not(matches(., '[0-7]'))]"
    mode="phase2">
    <xsl:attribute name="ind1">
      <xsl:text>0</xsl:text>
    </xsl:attribute>
  </xsl:template>

  <!-- On 785, replace non-compliant ind2 value with '0' -->
  <xsl:template match="*:datafield[matches(@tag, '785')]/@ind2[not(matches(., '[0-8]'))]"
    mode="phase2">
    <xsl:attribute name="ind1">
      <xsl:text>0</xsl:text>
    </xsl:attribute>
  </xsl:template>

  <!-- On 017, 76x, 77x, 786, and 787, replace non-compliant ind2 value based on presence of ǂi -->
  <xsl:template
    match="*:datafield[matches(@tag, '(017|760|762|765|767|770|773|774|775|776|777|786|787)')]/@ind2[not(matches(., '[\s8]'))]"
    mode="phase2">
    <xsl:attribute name="ind2">
      <xsl:choose>
        <xsl:when test="../*:subfield[@code = 'i']">
          <xsl:text>8</xsl:text>
        </xsl:when>
        <xsl:otherwise>
          <xsl:text>&#32;</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:attribute>
  </xsl:template>

  <!-- On 810, replace non-compliant ind2 value with '2' -->
  <xsl:template match="*:datafield[matches(@tag, '810')]/@ind1[not(matches(., '[012]'))]"
    mode="phase2">
    <xsl:attribute name="ind1">
      <xsl:text>2</xsl:text>
    </xsl:attribute>
  </xsl:template>

  <!-- Repair 856 -->
  <xsl:template match="*:datafield[@tag = '856']" mode="phase2">
    <xsl:copy>
      <xsl:apply-templates select="@tag"/>
      <xsl:choose>
        <!-- There's no need for @ind1='7' and ǂ2 when all ǂu subfields start with a standard protocol -->
        <xsl:when
          test="count(*:subfield[@code = 'u' and matches(., '^(mailto|ftp|telnet|https?):', 'i')]) = count(*:subfield[@code = 'u'])">
          <xsl:attribute name="ind1">
            <xsl:choose>
              <!-- All ǂu subfields begin with 'mailto:' -->
              <xsl:when
                test="count(*:subfield[@code = 'u' and matches(., '^mailto:', 'i')]) = count(*:subfield[@code = 'u'])"
                >0</xsl:when>
              <!-- All ǂu subfields begin with 'ftp:' -->
              <xsl:when
                test="count(*:subfield[@code = 'u' and matches(., '^ftp:', 'i')]) = count(*:subfield[@code = 'u'])"
                >1</xsl:when>
              <!-- All ǂu subfields begin with 'telnet:' -->
              <xsl:when
                test="count(*:subfield[@code = 'u' and matches(., '^telnet:', 'i')]) = count(*:subfield[@code = 'u'])"
                >2</xsl:when>
              <!-- All ǂu subfields begin with 'https?:' -->
              <xsl:when
                test="count(*:subfield[@code = 'u' and matches(., '^https?:', 'i')]) = count(*:subfield[@code = 'u'])"
                >4</xsl:when>
              <!-- A mixture of protocols -->
              <xsl:otherwise>
                <xsl:text>&#32;</xsl:text>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:attribute>
          <xsl:apply-templates select="@ind2" mode="phase2"/>
          <xsl:apply-templates select="*:subfield[not(@code = '2')]" mode="phase2"/>
        </xsl:when>
        <!-- If all ǂu subfields don't have a common protocol, set @ind1 = '7', put protocol in ǂ2 -->
        <xsl:when
          test="*:subfield[@code = 'u'][not(matches(., '^(mailto|ftp|telnet|https?)'))]">
          <xsl:attribute name="ind1">
            <xsl:choose>
              <xsl:when test="*:subfield[@code = 'u'][matches(., '^[^:]+:')]">7</xsl:when>
              <xsl:otherwise>
                <xsl:text>&#32;</xsl:text>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:attribute>
          <xsl:apply-templates select="@ind2" mode="phase2"/>
          <xsl:apply-templates select="*:subfield[not(@code = '2')]" mode="phase2"/>
          <xsl:for-each select="*:subfield[@code = 'u']">
            <xsl:if test="normalize-space(substring-before(*:subfield[@code = 'u'], ':'))">
              <subfield code="2">
              <xsl:value-of select="substring-before(*:subfield[@code = 'u'][not(matches(., '^(mailto|ftp|telnet|https?)'))], ':')"/>
            </subfield>
            </xsl:if>
          </xsl:for-each>
        </xsl:when>
        <xsl:otherwise>
          <xsl:apply-templates select="@*" mode="phase2"/>
          <xsl:apply-templates select="*:subfield" mode="phase2"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="*:datafield[@tag = '856']/@ind2" mode="phase2">
    <xsl:attribute name="ind2">
      <xsl:choose>
        <xsl:when test="../*:subfield[@code = '3'][matches(., 'cover image', 'i')]">
          <xsl:text>3</xsl:text>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="."/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:attribute>
  </xsl:template>

  <!-- Delete trailing period in 242/ǂy -->
  <xsl:template
    match="*:datafield[@tag = '242']/*:subfield[@code = 'y'][matches(., '\.$')]"
    mode="phase2">
    <subfield code="y">
      <xsl:value-of select="replace(., '\.+$', '')"/>
    </subfield>
  </xsl:template>

  <!-- In subfield ǂ8 replace forward slash w/ backslash -->
  <xsl:template match="*:subfield[@code = '8']" mode="phase2">
    <xsl:copy>
      <xsl:copy-of select="@code"/>
      <xsl:value-of select="replace(., '/', '\\')"/>
    </xsl:copy>
  </xsl:template>

  <!-- Repair subfield ǂ6 and indicators on 880 -->
  <xsl:template match="*:datafield[@tag = '880']" mode="phase2">
    <datafield>
      <xsl:variable name="subfields">
        <xsl:for-each select="*:subfield">
          <xsl:choose>
            <xsl:when test="@code = '6'">
              <subfield code="6">
              <xsl:choose>
                <!-- 3 tokens (2 slashes) -->
                <xsl:when test="count(tokenize(normalize-space(.), '/')) = 3">
                  <xsl:variable name="linkedTag">
                    <xsl:value-of select="normalize-space(tokenize(., '/')[1])"/>
                  </xsl:variable>
                  <xsl:variable name="linkingTag">
                    <xsl:value-of select="concat('880-', substring-after($linkedTag, '-'))"/>
                  </xsl:variable>
                  <xsl:variable name="script">
                    <xsl:value-of select="normalize-space(tokenize(., '/')[2])"/>
                  </xsl:variable>
                  <xsl:variable name="direction">
                    <xsl:value-of select="normalize-space(tokenize(., '/')[3])"/>
                  </xsl:variable>
                  <!-- Output the component tokens -->
                  <!-- Tag linked to -->
                  <xsl:value-of select="$linkedTag"/>
                  <!--<xsl:choose>
                    <!-\- When linking tag was a 490 that got changed to 440 -\->
                    <xsl:when test="matches($linkedTag, '^490') and ancestor::*:record/*:datafield[matches(*:subfield[@code = '6'], $linkingTag)]/@tag = '440'">
                      <xsl:value-of select="concat('440-', substring-after($linkedTag, '-'))"/>
                    </xsl:when>
                    <xsl:otherwise>
                      <xsl:value-of select="$linkedTag"/>
                    </xsl:otherwise>
                  </xsl:choose>-->
                  <!-- Script code -->
                  <xsl:choose>
                    <!-- MARC-compliant script code -->
                    <xsl:when test="matches($script, '^(\([BNS23]|\$1|\d{3}|[A-Za-z]{4})$')">
                      <xsl:value-of select="concat('/', $script)"/>
                    </xsl:when>
                    <xsl:otherwise>
                      <xsl:text>/Zyyy</xsl:text>
                    </xsl:otherwise>
                  </xsl:choose>
                  <!-- Direction -->
                  <xsl:if test="normalize-space($direction) ne ''">
                    <xsl:text>/r</xsl:text>
                  </xsl:if>
                </xsl:when>
                <!-- 2 tokens (1 slash) -->
                <xsl:when test="count(tokenize(normalize-space(.), '/')) = 2">
                  <xsl:variable name="linkedTag">
                    <xsl:value-of select="normalize-space(tokenize(., '/')[1])"/>
                  </xsl:variable>
                  <xsl:variable name="linkingTag">
                    <xsl:value-of select="concat('880-', substring-after($linkedTag, '-'))"/>
                  </xsl:variable>
                  <xsl:variable name="token2">
                    <xsl:value-of select="normalize-space(tokenize(., '/')[2])"/>
                  </xsl:variable>
                  <xsl:value-of select="$linkedTag"/>
                  <!--<xsl:choose>
                    <!-\- When linking tag was a 490 that got changed to 440 -\->
                    <xsl:when test="matches($linkedTag, '^490') and ancestor::*:record/*:datafield[matches(*:subfield[@code = '6'], $linkingTag)]/@tag = '440'">
                      <xsl:value-of select="concat('440-', substring-after($linkedTag, '-'))"/>
                    </xsl:when>
                    <xsl:otherwise>
                      <xsl:value-of select="$linkedTag"/>
                    </xsl:otherwise>
                  </xsl:choose>-->
                  <xsl:choose>
                    <!-- $token2 contains script code -->
                    <xsl:when test="matches($token2, '^(\([BNS23]|\$1|\d{3}|[A-Za-z]{4})$')">
                      <xsl:value-of select="concat('/', $token2)"/>
                    </xsl:when>
                    <!-- $token2 contains direction indicator -->
                    <xsl:otherwise>
                      <xsl:text>/Zyyy/r</xsl:text>
                    </xsl:otherwise>
                  </xsl:choose>
                </xsl:when>
                <!-- 1 token (no slashes) -->
                <xsl:when test="count(tokenize(normalize-space(.), '/')) = 1">
                  <xsl:analyze-string select="." regex="^(\d\d\d-\d\d)(.*)$">
                    <xsl:matching-substring>
                      <xsl:value-of select="regex-group(1)"/>
                      <xsl:choose>
                        <!-- script code & direction present -->
                        <xsl:when test="matches(regex-group(2), '^.+r$')">
                          <xsl:value-of select="concat('/', substring-before(regex-group(2), 'r'), '/r')"/>
                        </xsl:when>
                        <!-- script code missing, direction present -->
                        <xsl:when test="matches(regex-group(2), '^r$')">
                          <xsl:text>/Zyyy/r</xsl:text>
                        </xsl:when>
                        <!-- script code present, direction missing -->
                        <xsl:when test="matches(regex-group(2), '.+')">
                          <xsl:value-of select="concat('/', regex-group(2))"/>
                        </xsl:when>
                      </xsl:choose>
                    </xsl:matching-substring>
                  </xsl:analyze-string>
                </xsl:when>
                <!-- More than 3 tokens: pass the error along -->
                <xsl:otherwise>
                  <xsl:value-of select="."/>
                </xsl:otherwise>
              </xsl:choose>
            </subfield>
            </xsl:when>
            <xsl:otherwise>
              <xsl:copy-of select="."/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:for-each>
      </xsl:variable>
      <xsl:apply-templates select="@tag"/>
      <xsl:choose>
        <xsl:when test="matches($subfields/*:subfield[@code = '6'], '/')">
          <!-- Fix subfield 6 that looks like: "245-1(3/r" or "245-01(3/r" or "240 02(3/r" -->
          <xsl:variable name="normalizedLink">
            <xsl:value-of
              select="replace(replace(replace(replace($subfields/*:subfield[@code = '6'], '\(', '/('), '//', '/'), '(^\d{3}).(\d\D)', '$1-0$2'), '^(\d{3}).(\d)', '$1-$2')"
            />
          </xsl:variable>
          <xsl:variable name="linkingField">
            <xsl:value-of select="substring-before($normalizedLink, '/')"/>
          </xsl:variable>
          <xsl:variable name="linkingTag">
            <xsl:value-of select="substring-before($linkingField, '-')"/>
          </xsl:variable>
          <xsl:variable name="occurrenceNum">
            <xsl:choose>
              <xsl:when test="string-length(substring-after($linkingField, '-')) = 1">
                <xsl:value-of select="concat('0', substring-after($linkingField, '-'))"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="substring-after($linkingField, '-')"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>
          <xsl:variable name="linkedField">
            <xsl:value-of select="concat('880-', $occurrenceNum)"/>
          </xsl:variable>
          <xsl:choose>
            <!-- Linked field doesn't exist; use indicators as they are -->
            <xsl:when
              test="$linkingTag = '00' or not(ancestor::*:record/*:datafield[matches(@tag, $linkingTag) and matches(*:subfield[@code = '6'], $linkedField)])">
              <xsl:apply-templates select="@ind1" mode="phase2"/>
              <xsl:apply-templates select="@ind2" mode="phase2"/>
            </xsl:when>
            <xsl:otherwise>
              <!-- Use indicators from linked field -->
              <xsl:attribute name="ind1">
                <xsl:value-of
                  select="ancestor::*:record/*:datafield[matches(@tag, $linkingTag) and matches(*:subfield[@code = '6'], $linkedField)][1]/@ind1"
                />
              </xsl:attribute>
              <xsl:attribute name="ind2">
                <xsl:value-of
                  select="ancestor::*:record/*:datafield[matches(@tag, $linkingTag) and matches(*:subfield[@code = '6'], $linkedField)][1]/@ind2"
                />
              </xsl:attribute>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <!-- No slash in subfield ǂ6 -->
        <xsl:when test="not(matches($subfields/*:subfield[@code = '6'], '/'))">
          <xsl:variable name="linkingField">
            <xsl:value-of select="$subfields/*:subfield[@code = '6']"/>
          </xsl:variable>
          <xsl:variable name="linkingTag">
            <xsl:value-of select="substring-before($linkingField, '-')"/>
          </xsl:variable>
          <xsl:variable name="occurrenceNum">
            <xsl:value-of select="substring-after($linkingField, '-')"/>
          </xsl:variable>
          <xsl:variable name="linkedField">
            <xsl:value-of select="concat('880-', $occurrenceNum)"/>
          </xsl:variable>
          <xsl:choose>
            <!-- Linked field doesn't exist; use indicators as they are -->
            <xsl:when
              test="$occurrenceNum = '00' or not(ancestor::*:record/*:datafield[matches(@tag, $linkingTag) and matches(*:subfield[@code = '6'][1], $linkedField)])">
              <xsl:apply-templates select="@ind1" mode="phase2"/>
              <xsl:apply-templates select="@ind2" mode="phase2"/>
            </xsl:when>
            <xsl:otherwise>
              <!-- Use indicators from linked field -->
              <xsl:attribute name="ind1">
                <xsl:value-of
                  select="ancestor::*:record/*:datafield[matches(@tag, $linkingTag) and matches(*:subfield[@code = '6'][1], $linkedField)][1]/@ind1"
                />
              </xsl:attribute>
              <xsl:attribute name="ind2">
                <xsl:value-of
                  select="ancestor::*:record/*:datafield[matches(@tag, $linkingTag) and matches(*:subfield[@code = '6'][1], $linkedField)][1]/@ind2"
                />
              </xsl:attribute>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <!-- Malformed subfield ǂ6, use current indicator values -->
        <xsl:otherwise>
          <xsl:apply-templates select="@ind1" mode="phase2"/>
          <xsl:apply-templates select="@ind2" mode="phase2"/>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:copy-of select="$subfields"/>
    </datafield>
  </xsl:template>

  <!-- MATCH TEMPLATES (phase 3) -->
  <!-- Sort leader, controlfields, and datafields, except 5xx and 6xx -->
  <xsl:template match="*:record" mode="phase3">
    <record>
      <xsl:apply-templates select="*:leader"/>
      <xsl:apply-templates select="*:controlfield">
        <xsl:sort select="number(@tag)"/>
      </xsl:apply-templates>
      <xsl:apply-templates select="*:datafield[number(@tag) &lt; 500]">
        <xsl:sort select="number(@tag)"/>
      </xsl:apply-templates>
      <!--  DON'T SORT 5xxs or 6xxs -->
      <xsl:apply-templates
        select="*:datafield[number(@tag) &gt;= 500 and number(@tag) &lt; 600]"/>
      <xsl:apply-templates
        select="*:datafield[number(@tag) &gt;= 600 and number(@tag) &lt; 700]"/>
      <!-- Continue sorting -->
      <xsl:apply-templates
        select="*:datafield[number(@tag) &gt;= 700 and number(@tag) &lt; 999]"/>

      <!-- If $keep999s != 'true', 999s are discarded -->
      <xsl:if test="matches($keep999s, 'true', 'i')">
        <xsl:apply-templates select="*:datafield[number(@tag) = 999]">
          <!-- Sort 999s by call number, volume number, and copy number -->
          <xsl:sort select="*:subfield[@code = 'a']" data-type="text"/>
          <xsl:sort select="replace(*:subfield[@code = 'v'], '\D', '')" data-type="number"/>
          <xsl:sort select="replace(*:subfield[@code = 'c'], '\D', '')" data-type="number"
          />
        </xsl:apply-templates>
      </xsl:if>
    </record>
  </xsl:template>

  <!-- 010 -->
  <xsl:template match="*:datafield[@tag = '010'][1]" mode="phase3">
    <xsl:choose>
      <!-- Copy when datafield 010 is not repeated or following-sibling 
        datafield 010 has fields other than ǂz -->
      <xsl:when
        test="not(following-sibling::*:datafield[@tag = '010']) or following-sibling::*:datafield[@tag = '010']/*:subfield[matches(@code, '[^z]')]">
        <xsl:copy>
          <xsl:apply-templates select="@*" mode="phase3"/>
          <xsl:apply-templates mode="phase3"/>
        </xsl:copy>
      </xsl:when>
      <!-- Datafield 010 repeated -->
      <!-- Following sibling 010 has only ǂz subfields -->
      <xsl:when
        test="count(following-sibling::*:datafield[@tag = '010']/*:subfield[@code = 'z']) = count(following-sibling::*:datafield[@tag = '010']/*:subfield)">
        <!-- Include following sibling ǂz subfields -->
        <xsl:copy>
          <xsl:apply-templates select="@*" mode="phase3"/>
          <xsl:apply-templates mode="phase3"/>
          <xsl:apply-templates
            select="following-sibling::*:datafield[@tag = '010']/*:subfield[@code = 'z']"
            mode="phase3"/>
        </xsl:copy>
      </xsl:when>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="*:datafield[@tag = '010'][position() &gt; 1]" mode="phase3">
    <!-- Process 010 if there are subfields other than ǂz -->
    <xsl:if test="not(count(*:subfield[@code = 'z']) = count(*:subfield))">
      <xsl:copy>
        <xsl:apply-templates select="@*" mode="phase3"/>
        <xsl:apply-templates mode="phase3"/>
      </xsl:copy>
    </xsl:if>
  </xsl:template>

  <!-- Delete 035 that doesn't have ǂa -->
  <!--<xsl:template match="*:datafield[@tag = '035' and not(*:subfield[@code = 'a'])]"/>-->

  <!-- Because 040 is not repeatable, join all 040s into a single datafield -->
  <xsl:template match="*:datafield[@tag = '040'][1]" mode="phase3">
    <xsl:copy>
      <xsl:apply-templates select="@*" mode="phase3"/>
      <xsl:apply-templates select="*:subfield" mode="phase3"/>
      <xsl:for-each select="following-sibling::*:datafield[@tag = '040']">
        <xsl:apply-templates select="*:subfield" mode="phase3"/>
      </xsl:for-each>
    </xsl:copy>
  </xsl:template>

  <!-- Delete 040 other than first -->
  <xsl:template match="*:datafield[@tag = '040'][position() &gt; 1]" mode="phase3"/>

  <!-- Fix common language code errors -->
  <xsl:template match="*:datafield[@tag = '041']/*:subfield[matches(@code, '[a-z]')]"
    mode="phase3">
    <xsl:variable name="thisCode">
      <xsl:value-of select="@code"/>
    </xsl:variable>
    <subfield code="{$thisCode}">
      <xsl:value-of select="replace(replace(replace(replace(replace(replace(., 'ser', 'srp'), 'cro', 'hrv'), 'scs', 'srp'), 'scc', 'srp'), 'scr', 'srp'), 'fle', 'dut')"/>
    </subfield>
  </xsl:template>

  <!-- Normalize subfields containg MARC country codes -->
  <xsl:template
    match="*:datafield[@tag = '044']/*:subfield[@code = 'a'] | *:datafield[@tag = '365']/*:subfield[@code = 'k'] | *:datafield[@tag = '366']/*:subfield[@code = 'k'] | *:datafield[@tag = '775']/*:subfield[@code = 'f'] | *:datafield[@tag = '852']/*:subfield[@code = 'n']"
    mode="phase3">
    <subfield code="{@code}">
      <!-- Fix length and common errors -->
    <xsl:value-of select="replace(substring(concat(lower-case(normalize-space(.)), '   '), 1, 3), 'fre', 'fr ')"/>
    </subfield>
  </xsl:template>

  <!-- Normalize relator terms to lower case -->
  <xsl:template
    match="*:datafield[matches(@tag, '(100|110|111|400|410|600|610|611|63|650|651|654|662|688|700|705|710|715|720|751|752|800|810|811)')]/*:subfield[@code = 'e'] | *:datafield[matches(@tag, '711')]/*:subfield[@code = 'j']"
    mode="phase3">
    <xsl:copy>
      <xsl:apply-templates select="@*" mode="phase3"/>
      <xsl:value-of select="lower-case(.)"/>
    </xsl:copy>
  </xsl:template>

  <!-- Insert spaces in inverted, abbreviated names in access points per Fritz, 3.1-25, A 22 -->
  <xsl:template match="*:datafield[matches(@tag, '[1678]00')]/*:subfield[@code = 'a']"
    mode="phase3">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:value-of
        select="normalize-space(replace(replace(replace(., ', +([A-Z])\.\s*([A-Z])\.\s*([A-Z])\.', ', $1. $2. $3.'), ', +([A-Z])\.\s*([A-Z])\.', ', $1. $2. '), ' (\p{P})', '$1'))"
      />
    </xsl:copy>
  </xsl:template>

  <!-- Delete spaces in direct order, abbreviated names in access 
    points per Fritz, 3.1-31, A 24, and in 028 and 260 ǂb, since 
    the values of 028 ǂb and 260 ǂb are supposed to match each other. -->
  <xsl:template
    match="*:datafield[matches(@tag, '[1678]1[01]')]/*:subfield[@code = 'a'] | *:datafield[matches(@tag, '028|260')]/*:subfield[@code = 'b']"
    mode="phase3">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:value-of
        select="normalize-space(replace(replace(replace(., '^([A-Z])\.\s+([A-Z])\.\s+([A-Z])\.', '$1.$2.$3. '), '^([A-Z])\.\s+([A-Z])\.', '$1.$2. '), ' ([.,;:])', '$1'))"
      />
    </xsl:copy>
  </xsl:template>

  <!-- Set 246 @ind2 to '3' when subfield ǂa is not a substring of 245 -->
  <xsl:template
    match="*:datafield[@tag = '246' and @ind2 = '0' and normalize-space(*:subfield[@code = 'a']) != '' and normalize-space(ancestor::*:record/*:datafield[@tag = '245'][1]) != '']"
    mode="phase3">
    <xsl:variable name="title245">
      <xsl:for-each
        select="ancestor::*:record/*:datafield[@tag = '245'][1]/*:subfield[not(matches(@code, '[h678]'))]">
        <xsl:value-of select="."/>
        <xsl:text>&#32;</xsl:text>
      </xsl:for-each>
    </xsl:variable>
    <xsl:variable name="title245norm">
      <xsl:value-of
        select="normalize-space(replace(replace($title245, '\p{Z}', ' '), '[\p{P}|:|\$\+\*\|]', ''))"
      />
    </xsl:variable>
    <xsl:variable name="subfieldA"
      select="normalize-space(replace(replace(*:subfield[@code = 'a'], '\p{Z}', ' '), '[\p{P}|:|\$\+\*\|]', ''))"/>
    <xsl:copy>
      <xsl:copy-of select="@tag"/>
      <xsl:copy-of select="@ind1"/>
      <xsl:attribute name="ind2">
        <xsl:choose>
          <xsl:when test="matches($title245norm, $subfieldA, 'i')">
            <xsl:text>0</xsl:text>
          </xsl:when>
          <xsl:otherwise>
            <xsl:text>3</xsl:text>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:attribute>
      <xsl:apply-templates mode="phase3"/>
    </xsl:copy>
  </xsl:template>

  <!-- Normalize 336, 337, and 338 subfield ǂ2 -->
  <xsl:template
    match="*:datafield[matches(@tag, '33[678]')]/*:subfield[@code = '2'][matches(normalize-space(.), '^rda', 'i')]"
    mode="phase3">
    <xsl:copy>
      <xsl:apply-templates select="@*" mode="phase3"/>
      <xsl:choose>
        <xsl:when test="../@tag = '336'">
          <xsl:text>rdacontent</xsl:text>
        </xsl:when>
        <xsl:when test="../@tag = '337'">
          <xsl:text>rdamedia</xsl:text>
        </xsl:when>
        <xsl:when test="../@tag = '338'">
          <xsl:text>rdacarrier</xsl:text>
        </xsl:when>
      </xsl:choose>
    </xsl:copy>
  </xsl:template>

  <!-- On 880/264 set @ind2 based on presence/absence of subfields -->
  <xsl:template
    match="*:datafield[@tag = '880'][starts-with(*:subfield[@code = '6'], '264')]/@ind2[not(matches(., '[0-4]'))]"
    mode="phase3">
    <xsl:choose>
      <xsl:when test="count(../*:subfield[@code = 'c']) = count(../*:subfield)">
        <xsl:attribute name="ind2">
          <xsl:text>4</xsl:text>
        </xsl:attribute>
      </xsl:when>
      <xsl:otherwise>
        <xsl:attribute name="ind2">
          <xsl:text>1</xsl:text>
        </xsl:attribute>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Normalize UVA's institutional code to lowercase -->
  <xsl:template match="*:subfield[@code = '5'][matches(normalize-space(.), '^viu$', 'i')]"
    mode="phase3">
    <subfield code="5">
      <xsl:value-of select="lower-case(normalize-space(.))"/>
    </subfield>
  </xsl:template>

  <!-- DEFAULT TEMPLATE -->
  <xsl:template match="element() | processing-instruction() | comment() | @*" mode="#all">
    <xsl:copy exclude-result-prefixes="xs">
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:apply-templates mode="#current"/>
    </xsl:copy>
  </xsl:template>

</xsl:stylesheet>
