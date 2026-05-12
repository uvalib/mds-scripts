<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs">
  <xsl:output method="xml" omit-xml-declaration="no" indent="yes"/>

  <!-- Provide the name of the external file as a stylesheet parameter -->
  <!-- This stylesheet is not likely to work with any other file -->
  <xsl:param name="text-uri" as="xs:string"
    select="'https://www.loc.gov/marc/bibliographic/ecbdlist.html'"/>

  <xsl:param name="includeLocalFields" select="'true'"/>
  <xsl:param name="includeObsoleteFields" select="'true'"/>
  <xsl:param name="includeUvaFields" select="'true'"/>
  <xsl:param name="includeValueDefs" select="'true'"/>

  <xsl:variable name="progName">marcHTML2xsl.xsl</xsl:variable>
  <xsl:variable name="progVersion">1.0</xsl:variable>

  <!-- Local fields are NOT described by 
    https://www.loc.gov/marc/bibliographic/ecbdlist.html. They're
    included if $includLocalFields = 'true'. -->
  <xsl:variable name="localFields">
    <!-- Datafield 019 is reserved for use by OCLC -->
    <datafield tag="019" repeat="NR" desc="OCLC CONTROL NUMBER CROSS-REFERENCE">
      <ind1 values=" " desc="Undefined"/>
      <ind2 values=" " desc="Undefined"/>
      <subfield code="a" repeat="R" desc="OCLC control number of merged and deleted record"/>
    </datafield>
    <datafield tag="049" repeat="NR" desc="LOCAL HOLDINGS">
      <ind1 values=" 012" desc="Controls printing"/>
      <ind2 values=" 01" desc="Indicates the completeness of holdings data"/>
      <subfield code="a" repeat="R" desc="Holding library"/>
      <subfield code="c" repeat="R" desc="Copy statement"/>
      <subfield code="d" repeat="R" desc="Definition of bibliographic subdivisions"/>
      <subfield code="l" repeat="R" desc="Local processing data"/>
      <subfield code="m" repeat="R" desc="Missing elements"/>
      <subfield code="n" repeat="NR" desc="Notes about holdings"/>
      <subfield code="o" repeat="R" desc="Local processing data"/>
      <subfield code="p" repeat="R" desc="Secondary bibliographic subdivision"/>
      <subfield code="q" repeat="R" desc="Third bibliographic subdivision"/>
      <subfield code="r" repeat="R" desc="Fourth bibliographic subdivision"/>
      <subfield code="s" repeat="R" desc="Fifth bibliographic subdivision"/>
      <subfield code="t" repeat="R" desc="Sixth bibliographic subdivision"/>
      <subfield code="u" repeat="R" desc="Seventh bibliographic subdivision"/>
      <subfield code="v" repeat="R" desc="Primary bibliographic subdivision"/>
      <subfield code="y" repeat="NR" desc="Inclusive dates of publication or coverage"/>
    </datafield>
    <!-- Datafield 090 is described by https://www.loc.gov/marc/bibliographic/ecbdlist.html
      but is labeled as obsolete. 090 is defined in $uvaFields so that it will always be 
      present. -->
    <datafield tag="092" repeat="R" desc="LOCALLY ASSIGNED DEWEY CALL NUMBER">
      <ind1 values=" 01" desc="DDC edition"/>
      <ind2 values=" " desc="Undefined"/>
      <subfield code="a" repeat="NR" desc="Classification number"/>
      <subfield code="b" repeat="NR" desc="Item number"/>
      <subfield code="e" repeat="NR" desc="Feature heading"/>
      <subfield code="f" repeat="NR" desc="Filing suffix"/>
      <!-- $2 appears to be optional rather than recommended -->
      <subfield code="2" repeat="NR" desc="Edition number"/>
    </datafield>
    <datafield tag="096" repeat="R" desc="LOCALLY ASSIGNED NLM-TYPE CALL NUMBER">
      <ind1 values=" " desc="Undefined"/>
      <ind2 values=" " desc="Undefined"/>
      <subfield code="a" repeat="NR" desc="Classification number"/>
      <subfield code="b" repeat="NR" desc="Item number"/>
      <subfield code="e" repeat="NR" desc="Feature heading"/>
      <subfield code="f" repeat="NR" desc="Filing suffix"/>
    </datafield>
    <!-- Datafield 099 is defined in $uvaFields so that it will always be included. -->
    <datafield tag="539" repeat="R" desc="FIXED-LENGTH DATA ELEMENTS OF REPRODUCTION
      NOTE/OCLC RESERVED">
      <ind1 values=" " desc="Undefined"/>
      <ind2 values=" " desc="Undefined"/>
      <subfield code="a" repeat="NR" desc="Type of date/Publication status"/>
      <subfield code="b" repeat="NR" desc="Date 1/Beginning date of publication"/>
      <subfield code="c" repeat="NR" desc="Date 2/Ending date of publication"/>
      <subfield code="d" repeat="NR" desc="Place of publication, production, or execution (NR)"/>
      <subfield code="e" repeat="NR" desc="Frequency"/>
      <subfield code="f" repeat="NR" desc="Regularity"/>
      <subfield code="g" repeat="NR" desc="Form of item"/>
    </datafield>
    <!-- Datafield 590 is defined in $uvaFields so that it will always be included. -->
    <datafield tag="591" repeat="R" desc="LOCAL NOTE">
      <ind1 values=" " desc="Undefined"/>
      <ind2 values=" " desc="Undefined"/>
      <!-- OCLC specs say subfields not repeatable, data doesn't conform -->
      <subfield code="abcdefghijklmnopqrstuvwxyz012345789" repeat="R" desc="Defined for local use"/>
      <subfield code="6" repeat="NR" desc="Linkage"/>
    </datafield>
    <datafield tag="592" repeat="R" desc="LOCAL NOTE">
      <ind1 values=" " desc="Undefined"/>
      <ind2 values=" " desc="Undefined"/>
      <!-- OCLC specs say subfields not repeatable, data doesn't conform -->
      <subfield code="abcdefghijklmnopqrstuvwxyz012345789" repeat="R" desc="Defined for local use"/>
      <subfield code="6" repeat="NR" desc="Linkage"/>
    </datafield>
    <datafield tag="593" repeat="R" desc="LOCAL NOTE">
      <ind1 VALUES=" " desc="Undefined"/>
      <ind2 values=" " desc="Undefined"/>
      <!-- OCLC specs say subfields not repeatable, data doesn't conform -->
      <subfield code="abcdefghijklmnopqrstuvwxyz012345789" repeat="R" desc="Defined for local use"/>
      <subfield code="6" repeat="NR" desc="Linkage"/>
    </datafield>
    <!-- Datafield 594 reserved for use by Sirsi -->
    <datafield tag="594" repeat="R" desc="LOCAL NOTE/SIRSI RESERVED">
      <ind1 values=" " desc="Undefined"/>
      <ind2 values=" " desc="Undefined"/>
      <!-- OCLC specs say subfields not repeatable, data doesn't conform -->
      <subfield code="abcdefghijklmnopqrstuvwxyz012345789" repeat="R" desc="Defined for local use"/>
      <subfield code="6" repeat="NR" desc="Linkage"/>
    </datafield>
    <datafield tag="595" repeat="R" desc="LOCAL NOTE">
      <ind1 values=" " desc="Undefined"/>
      <ind2 values=" " desc="Undefined"/>
      <!-- OCLC specs say subfields not repeatable, data doesn't conform -->
      <subfield code="abcdefghijklmnopqrstuvwxyz012345789" repeat="R" desc="Defined for local use"/>
      <subfield code="6" repeat="NR" desc="Linkage"/>
    </datafield>
    <!-- Datafield 596 reserved for use by Sirsi -->
    <datafield tag="596" repeat="R" desc="LOCAL NOTE/SIRSI RESERVED">
      <ind1 values=" " desc="Undefined"/>
      <ind2 values=" " desc="Undefined"/>
      <!-- OCLC specs say subfields not repeatable, data doesn't conform -->
      <subfield code="abcdefghijklmnopqrstuvwxyz012345789" repeat="R" desc="Defined for local use"/>
      <subfield code="6" repeat="NR" desc="Linkage"/>
    </datafield>
    <!-- Datafield 597 reserved for use by Sirsi -->
    <datafield tag="597" repeat="R" desc="LOCAL NOTE/SIRSI RESERVED">
      <ind1 values=" " desc="Undefined"/>
      <ind2 values=" " desc="Undefined"/>
      <!-- OCLC specs say subfields not repeatable, data doesn't conform -->
      <subfield code="abcdefghijklmnopqrstuvwxyz012345789" repeat="R" desc="Defined for local use"/>
      <subfield code="6" repeat="NR" desc="Linkage"/>
    </datafield>
    <!-- Datafield 598 reserved for use by Sirsi -->
    <datafield tag="598" repeat="R" desc="LOCAL NOTE/SIRSI RESERVED">
      <ind1 values=" " desc="Undefined"/>
      <ind2 values=" " desc="Undefined"/>
      <!-- OCLC specs say subfields not repeatable, data doesn't conform -->
      <subfield code="abcdefghijklmnopqrstuvwxyz012345789" repeat="R" desc="Defined for local use"/>
      <subfield code="6" repeat="NR" desc="Linkage"/>
    </datafield>
    <!-- Datafield 599 reserved for use by Sirsi -->
    <datafield tag="599" repeat="R" desc="DIFFERENTIABLE LOCAL NOTE/SIRSI RESERVED">
      <ind1 values=" 0-9" desc="Locally defined"/>
      <ind2 values=" 0-9" desc="Locally defined"/>
      <!-- OCLC specs say subfields not repeatable, data doesn't conform -->
      <subfield code="abcdefghijklmnopqrstuvwxyz012345789" repeat="R" desc="Defined for local use"/>
      <subfield code="6" repeat="NR" desc="Linkage"/>
    </datafield>
    <datafield tag="690" repeat="R" desc="LOCAL SUBJECT ADDED ENTRY — TOPICAL TERM">
      <ind1 values=" 012" desc="Level of subject"/>
      <ind2 values=" 01234567" desc="Thesaurus"/>
      <subfield code="a" repeat="NR" desc="Topical term or geographic name as entry element"/>
      <subfield code="b" repeat="NR" desc="Topical term following geographic name as entry element"/>
      <subfield code="c" repeat="NR" desc="Location of event"/>
      <subfield code="d" repeat="NR" desc="Active dates"/>
      <subfield code="e" repeat="NR" desc="Relator term"/>
      <subfield code="g" repeat="R" desc="Miscellaneous information"/>
      <subfield code="v" repeat="R" desc="Form subdivision"/>
      <subfield code="x" repeat="R" desc="General subdivision"/>
      <subfield code="y" repeat="R" desc="Chronological subdivision"/>
      <subfield code="z" repeat="R" desc="Geographic subdivision"/>
      <subfield code="1" repeat="R" desc="Real World Object URI"/>
      <subfield code="2" repeat="NR" desc="Source of heading or term"/>
      <subfield code="3" repeat="NR" desc="Materials specified"/>
      <subfield code="6" repeat="NR" desc="Linkage"/>
      <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      <subfield code="9" repeat="NR" desc="Special entry"/>
    </datafield>
    <datafield tag="691" repeat="R" desc="LOCAL SUBJECT ADDED ENTRY — GEOGRAPHIC NAME">
      <ind1 values=" " desc="Undefined"/>
      <ind2 values=" 01234567" desc="Thesaurus"/>
      <subfield code="a" repeat="NR" desc="Geographic name"/>
      <subfield code="b" repeat="NR" desc="Geographic element following geographic name"/>
      <subfield code="g" repeat="R" desc="Miscellaneous information"/>
      <subfield code="v" repeat="R" desc="Form subdivision"/>
      <subfield code="x" repeat="R" desc="General subdivision"/>
      <subfield code="y" repeat="R" desc="Chronological subdivision"/>
      <subfield code="z" repeat="R" desc="Geographic subdivision"/>
      <subfield code="1" repeat="R" desc="Real World Object URI"/>
      <subfield code="2" repeat="NR" desc="Source of heading or term"/>
      <subfield code="3" repeat="NR" desc="Materials specified"/>
      <subfield code="6" repeat="NR" desc="Linkage"/>
      <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      <subfield code="9" repeat="NR" desc="Special entry"/>
    </datafield>
    <datafield tag="695" repeat="R" desc="ADDED CLASS NUMBER/OCLC RESERVED">
      <ind1 values=" 01" desc="Type of edition"/>
      <ind2 values=" 0123459" desc="Classification scheme"/>
      <subfield code="a" repeat="NR" desc="Added class number"/>
      <subfield code="b" repeat="R" desc="Item number"/>
      <subfield code="e" repeat="R" desc="Heading"/>
      <subfield code="f" repeat="R" desc="Filing suffix"/>
      <subfield code="2" repeat="NR" desc="Edition number"/>
    </datafield>
    <datafield tag="696" repeat="R" desc="LOCAL SUBJECT ADDED ENTRY — PERSONAL NAME">
      <ind1 values="013" desc="Type of personal name entry element"/>
      <ind2 values="0-7" desc="Thesaurus"/>
      <subfield code="a" repeat="NR" desc="Personal name"/>
      <subfield code="b" repeat="NR" desc="Numeration"/>
      <subfield code="c" repeat="R" desc="Titles and other words associated with a name"/>
      <subfield code="d" repeat="NR" desc="Dates associated with a name"/>
      <subfield code="e" repeat="R" desc="Relator term"/>
      <subfield code="f" repeat="NR" desc="Date of a work"/>
      <subfield code="g" repeat="NR" desc="Miscellaneous information"/>
      <subfield code="h" repeat="NR" desc="Medium"/>
      <subfield code="j" repeat="R" desc="Attribution qualifier"/>
      <subfield code="k" repeat="R" desc="Form subheading"/>
      <subfield code="l" repeat="NR" desc="Language of a work"/>
      <subfield code="m" repeat="R" desc="Medium of performance for music"/>
      <subfield code="n" repeat="R" desc="Number of part/section of a work"/>
      <subfield code="o" repeat="NR" desc="Arranged statement for music"/>
      <subfield code="p" repeat="R" desc="Name of part/section of a work"/>
      <subfield code="q" repeat="NR" desc="Fuller form of name"/>
      <subfield code="r" repeat="NR" desc="Key for music"/>
      <subfield code="s" repeat="NR" desc="Version"/>
      <subfield code="t" repeat="NR" desc="Title of a work"/>
      <subfield code="u" repeat="NR" desc="Affiliation"/>
      <subfield code="v" repeat="R" desc="Form subdivision"/>
      <subfield code="x" repeat="R" desc="General subdivision"/>
      <subfield code="y" repeat="R" desc="Chronological subdivision"/>
      <subfield code="z" repeat="R" desc="Geographic subdivision"/>
      <subfield code="0" repeat="R" desc="Authority record control number or standard number"/>
      <subfield code="1" repeat="R" desc="Real World Object URI"/>
      <subfield code="2" repeat="NR" desc="Source of heading or term"/>
      <subfield code="3" repeat="NR" desc="Materials specified"/>
      <subfield code="4" repeat="R" desc="Relator code"/>
      <subfield code="6" repeat="NR" desc="Linkage"/>
      <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      <subfield code="9" repeat="NR" desc="Special entry"/>
    </datafield>
    <datafield tag="697" repeat="R" desc="LOCAL SUBJECT ADDED ENTRY — CORPORATE NAME">
      <ind1 values="012" desc="Type of corporate name entry element"/>
      <ind2 values="0-7" desc="Thesaurus"/>
      <subfield code="a" repeat="NR" desc="Corporate name or jurisdiction name as entry element"/>
      <subfield code="b" repeat="R" desc="Subordinate unit"/>
      <subfield code="c" repeat="NR" desc="Location of meeting"/>
      <subfield code="d" repeat="R" desc="Date of meeting or treaty signing"/>
      <subfield code="e" repeat="R" desc="Relator term"/>
      <subfield code="f" repeat="NR" desc="Date of a work"/>
      <subfield code="g" repeat="NR" desc="Miscellaneous information"/>
      <subfield code="h" repeat="NR" desc="Medium"/>
      <subfield code="k" repeat="R" desc="Form subheading"/>
      <subfield code="l" repeat="NR" desc="Language of a work"/>
      <subfield code="m" repeat="R" desc="Medium of performance for music"/>
      <subfield code="n" repeat="R" desc="Number of part/section/meeting"/>
      <subfield code="o" repeat="NR" desc="Arranged statement for music"/>
      <subfield code="p" repeat="R" desc="Name of part/section of a work"/>
      <subfield code="r" repeat="NR" desc="Key for music"/>
      <subfield code="s" repeat="NR" desc="Version"/>
      <subfield code="t" repeat="NR" desc="Title of a work"/>
      <subfield code="u" repeat="NR" desc="Affiliation"/>
      <subfield code="v" repeat="R" desc="Form subdivision"/>
      <subfield code="x" repeat="R" desc="General subdivision"/>
      <subfield code="y" repeat="R" desc="Chronological subdivision"/>
      <subfield code="z" repeat="R" desc="Geographic subdivision"/>
      <subfield code="0" repeat="R" desc="Authority record control number or standard number"/>
      <subfield code="1" repeat="R" desc="Real World Object URI"/>
      <subfield code="2" repeat="NR" desc="Source of heading or term"/>
      <subfield code="3" repeat="NR" desc="Materials specified"/>
      <subfield code="4" repeat="R" desc="Relator code"/>
      <subfield code="6" repeat="NR" desc="Linkage"/>
      <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      <subfield code="9" repeat="NR" desc="Special entry"/>
    </datafield>
    <datafield tag="698" repeat="R" desc="LOCAL SUBJECT ADDED ENTRY — MEETING NAME">
      <ind1 values="012" desc="Type of meeting name entry element"/>
      <ind2 values="0-7" desc="Thesaurus"/>
      <subfield code="a" repeat="NR" desc="Meeting name or jurisdiction name as entry element"/>
      <subfield code="c" repeat="NR" desc="Location of meeting"/>
      <subfield code="d" repeat="NR" desc="Date of meeting"/>
      <subfield code="e" repeat="R" desc="Subordinate unit"/>
      <subfield code="f" repeat="NR" desc="Date of a work"/>
      <subfield code="g" repeat="NR" desc="Miscellaneous information"/>
      <subfield code="h" repeat="NR" desc="Medium"/>
      <subfield code="j" repeat="R" desc="Relator term"/>
      <subfield code="k" repeat="R" desc="Form subheading"/>
      <subfield code="l" repeat="NR" desc="Language of a work"/>
      <subfield code="n" repeat="R" desc="Number of part/section/meeting"/>
      <subfield code="p" repeat="R" desc="Name of part/section of a work"/>
      <subfield code="q" repeat="NR" desc="Name of meeting following jurisdiction name entry element"/>
      <subfield code="s" repeat="NR" desc="Version"/>
      <subfield code="t" repeat="NR" desc="Title of a work"/>
      <subfield code="u" repeat="NR" desc="Affiliation"/>
      <subfield code="v" repeat="R" desc="Form subdivision"/>
      <subfield code="x" repeat="R" desc="General subdivision"/>
      <subfield code="y" repeat="R" desc="Chronological subdivision"/>
      <subfield code="z" repeat="R" desc="Geographic subdivision"/>
      <subfield code="0" repeat="R" desc="Authority record control number or standard number"/>
      <subfield code="1" repeat="R" desc="Real World Object URI"/>
      <subfield code="2" repeat="NR" desc="Source of heading or term"/>
      <subfield code="3" repeat="NR" desc="Materials specified"/>
      <subfield code="4" repeat="R" desc="Relator code"/>
      <subfield code="6" repeat="NR" desc="Linkage"/>
      <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      <subfield code="9" repeat="NR" desc="Special entry"/>
    </datafield>
    <datafield tag="699" repeat="R" desc="LOCAL SUBJECT ADDED ENTRY — UNIFORM TITLE">
      <ind1 values="0-9" desc="Nonfiling characters"/>
      <ind2 values="0-7" desc="Thesaurus"/>
      <subfield code="a" repeat="NR" desc="Uniform title"/>
      <subfield code="d" repeat="R" desc="Date of treaty signing"/>
      <subfield code="e" repeat="R" desc="Relator term"/>
      <subfield code="f" repeat="NR" desc="Date of a work"/>
      <subfield code="g" repeat="NR" desc="Miscellaneous information"/>
      <subfield code="h" repeat="NR" desc="Medium"/>
      <subfield code="k" repeat="R" desc="Form subheading"/>
      <subfield code="l" repeat="NR" desc="Language of a work"/>
      <subfield code="m" repeat="R" desc="Medium of performance for music"/>
      <subfield code="n" repeat="R" desc="Number of part/section of a work"/>
      <subfield code="o" repeat="NR" desc="Arranged statement for music"/>
      <subfield code="p" repeat="R" desc="Name of part/section of a work"/>
      <subfield code="r" repeat="NR" desc="Key for music"/>
      <subfield code="s" repeat="NR" desc="Version"/>
      <subfield code="t" repeat="NR" desc="Title of a work"/>
      <subfield code="v" repeat="R" desc="Form subdivision"/>
      <subfield code="x" repeat="R" desc="General subdivision"/>
      <subfield code="y" repeat="R" desc="Chronological subdivision"/>
      <subfield code="z" repeat="R" desc="Geographic subdivision"/>
      <subfield code="0" repeat="R" desc="Authority record control number or standard number"/>
      <subfield code="1" repeat="R" desc="Real World Object URI"/>
      <subfield code="2" repeat="NR" desc="Source of heading or term"/>
      <subfield code="3" repeat="NR" desc="Materials specified"/>
      <subfield code="4" repeat="R" desc="Relationship"/>
      <subfield code="6" repeat="NR" desc="Linkage"/>
      <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      <subfield code="9" repeat="NR" desc="Special entry"/>
    </datafield>
    <datafield tag="790" repeat="R" desc="LOCAL ADDED ENTRY — PERSONAL NAME">
      <ind1 values="013" desc="Type of personal name"/>
      <ind2 values=" 2" desc="Type of added entry"/>
      <subfield code="a" repeat="NR" desc="Personal name"/>
      <subfield code="b" repeat="NR" desc="Numeration"/>
      <subfield code="c" repeat="R" desc="Titles and other words associated with a name"/>
      <subfield code="d" repeat="NR" desc="Dates associated with a name"/>
      <subfield code="e" repeat="R" desc="Relator term"/>
      <subfield code="f" repeat="NR" desc="Date of a work"/>
      <subfield code="g" repeat="R" desc="Miscellaneous information"/>
      <subfield code="h" repeat="NR" desc="Medium"/>
      <subfield code="i" repeat="R" desc="Relationship information"/>
      <subfield code="j" repeat="R" desc="Attribution qualifier"/>
      <subfield code="k" repeat="R" desc="Form subheading"/>
      <subfield code="l" repeat="NR" desc="Language of a work"/>
      <subfield code="m" repeat="R" desc="Medium of performance for music"/>
      <subfield code="n" repeat="R" desc="Number of part/section of a work"/>
      <subfield code="o" repeat="NR" desc="Arranged statement for music"/>
      <subfield code="p" repeat="R" desc="Name of part/section of a work"/>
      <subfield code="q" repeat="NR" desc="Fuller form of name"/>
      <subfield code="r" repeat="NR" desc="Key for music"/>
      <subfield code="s" repeat="R" desc="Version"/>
      <subfield code="t" repeat="NR" desc="Title of a work"/>
      <subfield code="u" repeat="NR" desc="Affiliation"/>
      <subfield code="x" repeat="NR" desc="International Standard Serial Number"/>
      <subfield code="0" repeat="R" desc="Authority record control number or standard number"/>
      <subfield code="1" repeat="R" desc="Real World Object URI"/>
      <subfield code="2" repeat="NR" desc="Source of heading or term"/>
      <subfield code="3" repeat="NR" desc="Materials specified"/>
      <subfield code="4" repeat="R" desc="Relationship"/>
      <subfield code="5" repeat="NR" desc="Institution to which field applies"/>
      <subfield code="6" repeat="NR" desc="Linkage"/>
      <subfield code="8" repeat="R" desc="Field link and sequence number"/>
    </datafield>
    <datafield tag="791" desc="LOCAL ADDED ENTRY — CORPORATE NAME" repeat="R">
      <ind1 values="012" desc="Type of corporate name entry element"/>
      <ind2 values=" 2" desc="Type of added entry"/>
      <subfield code="a" repeat="NR" desc="Corporate name or jurisdiction name as entry element"/>
      <subfield code="b" repeat="R" desc="Subordinate unit"/>
      <subfield code="c" repeat="NR" desc="Location of meeting"/>
      <subfield code="d" repeat="R" desc="Date of meeting or treaty signing"/>
      <subfield code="e" repeat="R" desc="Relator term"/>
      <subfield code="f" repeat="NR" desc="Date of a work"/>
      <subfield code="g" repeat="R" desc="Miscellaneous information"/>
      <subfield code="h" repeat="NR" desc="Medium"/>
      <subfield code="i" repeat="R" desc="Relationship information"/>
      <subfield code="k" repeat="R" desc="Form subheading"/>
      <subfield code="l" repeat="NR" desc="Language of a work"/>
      <subfield code="m" repeat="R" desc="Medium of performance for music"/>
      <subfield code="n" repeat="R" desc="Number of part/section/meeting"/>
      <subfield code="o" repeat="NR" desc="Arranged statement for music"/>
      <subfield code="p" repeat="R" desc="Name of part/section of a work"/>
      <subfield code="r" repeat="NR" desc="Key for music"/>
      <subfield code="s" repeat="R" desc="Version"/>
      <subfield code="t" repeat="NR" desc="Title of a work"/>
      <subfield code="u" repeat="NR" desc="Affiliation"/>
      <subfield code="x" repeat="NR" desc="International Standard Serial Number"/>
      <subfield code="0" repeat="R" desc="Authority record control number or standard number"/>
      <subfield code="1" repeat="R" desc="Real World Object URI"/>
      <subfield code="2" repeat="NR" desc="Source of heading or term"/>
      <subfield code="3" repeat="NR" desc="Materials specified"/>
      <subfield code="4" repeat="R" desc="Relationship"/>
      <subfield code="5" repeat="NR" desc="Institution to which field applies"/>
      <subfield code="6" repeat="NR" desc="Linkage"/>
      <subfield code="8" repeat="R" desc="Field link and sequence number"/>
    </datafield>
    <datafield tag="792" desc="LOCAL ADDED ENTRY — MEETING NAME" repeat="R">
      <ind1 values="012" desc="Type of corporate name entry element"/>
      <ind2 values=" 2" desc="Type of added entry"/>
      <subfield code="a" repeat="NR" desc="Meeting name name or jurisdiction name as entry element"/>
      <subfield code="c" repeat="NR" desc="Location of meeting"/>
      <subfield code="d" repeat="R" desc="Date of meeting or treaty signing"/>
      <subfield code="e" repeat="R" desc="Subordinate unit"/>
      <subfield code="f" repeat="NR" desc="Date of work"/>
      <subfield code="g" repeat="R" desc="Miscellaneous information"/>
      <subfield code="h" repeat="NR" desc="Medium"/>
      <subfield code="i" repeat="R" desc="Relationship information"/>
      <subfield code="j" repeat="R" desc="Relator code"/>
      <subfield code="k" repeat="R" desc="Form subheading"/>
      <subfield code="l" repeat="NR" desc="Language of a work"/>
      <subfield code="n" repeat="R" desc="Number of part/section/meeting"/>
      <subfield code="p" repeat="R" desc="Name of part/section of a work"/>
      <subfield code="q" repeat="NR" desc="Name of meeting following jurisdiction name entry element"/>
      <subfield code="s" repeat="R" desc="Version"/>
      <subfield code="t" repeat="NR" desc="Title of a work"/>
      <subfield code="u" repeat="NR" desc="Affiliation"/>
      <subfield code="x" repeat="NR" desc="International Standard Serial Number"/>
      <subfield code="0" repeat="R" desc="Authority record control number or standard number"/>
      <subfield code="1" repeat="R" desc="Real World Object URI"/>
      <subfield code="2" repeat="NR" desc="Source of heading or term"/>
      <subfield code="3" repeat="NR" desc="Materials specified"/>
      <subfield code="4" repeat="R" desc="Relationship"/>
      <subfield code="5" repeat="NR" desc="Institution to which field applies"/>
      <subfield code="6" repeat="NR" desc="Linkage"/>
      <subfield code="8" repeat="R" desc="Field link and sequence number"/>
    </datafield>
    <datafield tag="793" repeat="R" desc="LOCAL ADDED ENTRY — UNIFORM TITLE">
      <ind1 values="0-9" desc="Nonfiling characters"/>
      <ind2 values=" 2" desc="Type of added entry"/>
      <subfield code="a" repeat="NR" desc="Uniform title"/>
      <subfield code="d" repeat="R" desc="Date of treaty signing"/>
      <subfield code="f" repeat="NR" desc="Date of a work"/>
      <subfield code="g" repeat="R" desc="Miscellaneous information"/>
      <subfield code="h" repeat="NR" desc="Medium"/>
      <subfield code="i" repeat="R" desc="Relationship information"/>
      <subfield code="k" repeat="R" desc="Form subheading"/>
      <subfield code="l" repeat="NR" desc="Language of a work"/>
      <subfield code="m" repeat="R" desc="Medium of performance for music"/>
      <subfield code="n" repeat="R" desc="Number of part/section of a work"/>
      <subfield code="o" repeat="NR" desc="Arranged statement for music"/>
      <subfield code="p" repeat="R" desc="Name of part/section of a work"/>
      <subfield code="r" repeat="NR" desc="Key for music"/>
      <subfield code="s" repeat="R" desc="Version"/>
      <subfield code="t" repeat="NR" desc="Title of a work"/>
      <subfield code="x" repeat="NR" desc="International Standard Serial Number"/>
      <subfield code="0" repeat="R" desc="Authority record control number or standard number"/>
      <subfield code="1" repeat="R" desc="Real World Object URI"/>
      <subfield code="2" repeat="NR" desc="Source of heading or term"/>
      <subfield code="3" repeat="NR" desc="Materials specified"/>
      <subfield code="5" repeat="NR" desc="Institution to which field applies"/>
      <subfield code="6" repeat="NR" desc="Linkage"/>
      <subfield code="8" repeat="R" desc="Field link and sequence number"/>
    </datafield>
    <datafield tag="796" repeat="R" desc="LOCAL ADDED ENTRY — PERSONAL NAME">
      <ind1 values="013" desc="Type of personal name entry element"/>
      <ind2 values=" 2" desc="Type of added entry"/>
      <subfield code="a" repeat="NR" desc="Personal name"/>
      <subfield code="b" repeat="NR" desc="Numeration"/>
      <subfield code="c" repeat="R" desc="Titles and other words associated with a name"/>
      <subfield code="d" repeat="NR" desc="Dates associated with a name"/>
      <subfield code="e" repeat="R" desc="Relator term"/>
      <subfield code="f" repeat="NR" desc="Date of a work"/>
      <subfield code="g" repeat="R" desc="Miscellaneous information"/>
      <subfield code="h" repeat="NR" desc="Medium"/>
      <subfield code="i" repeat="R" desc="Relationship information"/>
      <subfield code="j" repeat="R" desc="Attribution qualifier"/>
      <subfield code="k" repeat="R" desc="Form subheading"/>
      <subfield code="l" repeat="NR" desc="Language of a work"/>
      <subfield code="m" repeat="R" desc="Medium of performance for music"/>
      <subfield code="n" repeat="R" desc="Number of part/section of a work"/>
      <subfield code="o" repeat="NR" desc="Arranged statement for music"/>
      <subfield code="p" repeat="R" desc="Name of part/section of a work"/>
      <subfield code="q" repeat="NR" desc="Fuller form of name"/>
      <subfield code="r" repeat="NR" desc="Key for music"/>
      <subfield code="s" repeat="R" desc="Version"/>
      <subfield code="t" repeat="NR" desc="Title of a work"/>
      <subfield code="u" repeat="NR" desc="Affiliation"/>
      <subfield code="x" repeat="NR" desc="International Standard Serial Number"/>
      <subfield code="0" repeat="R" desc="Authority record control number or standard number"/>
      <subfield code="1" repeat="R" desc="Real World Object URI"/>
      <subfield code="2" repeat="NR" desc="Source of heading or term"/>
      <subfield code="3" repeat="NR" desc="Materials specified"/>
      <subfield code="4" repeat="R" desc="Relationship"/>
      <subfield code="5" repeat="NR" desc="Institution to which field applies"/>
      <subfield code="6" repeat="NR" desc="Linkage"/>
      <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      <subfield code="9" repeat="NR" desc="Special Entry"/>
    </datafield>
    <datafield tag="797" repeat="R" desc="LOCAL ADDED ENTRY — CORPORATE NAME">
      <ind1 values="012" desc="Type of corporate name entry element"/>
      <ind2 values=" 2" desc="Type of added entry"/>
      <subfield code="a" repeat="NR" desc="Corporate name or jurisdiction name as entry element"/>
      <subfield code="b" repeat="R" desc="Subordinate unit"/>
      <subfield code="c" repeat="NR" desc="Location of meeting"/>
      <subfield code="d" repeat="R" desc="Date of meeting or treaty signing"/>
      <subfield code="e" repeat="R" desc="Relator term"/>
      <subfield code="f" repeat="NR" desc="Date of a work"/>
      <subfield code="g" repeat="R" desc="Miscellaneous information"/>
      <subfield code="h" repeat="NR" desc="Medium"/>
      <subfield code="i" repeat="R" desc="Relationship information"/>
      <subfield code="k" repeat="R" desc="Form subheading"/>
      <subfield code="l" repeat="NR" desc="Language of a work"/>
      <subfield code="m" repeat="R" desc="Medium of performance for music"/>
      <subfield code="n" repeat="R" desc="Number of part/section/meeting"/>
      <subfield code="o" repeat="NR" desc="Arranged statement for music"/>
      <subfield code="p" repeat="R" desc="Name of part/section of a work"/>
      <subfield code="r" repeat="NR" desc="Key for music"/>
      <subfield code="s" repeat="R" desc="Version"/>
      <subfield code="t" repeat="NR" desc="Title of a work"/>
      <subfield code="u" repeat="NR" desc="Affiliation"/>
      <subfield code="x" repeat="NR" desc="International Standard Serial Number"/>
      <subfield code="0" repeat="R" desc="Authority record control number or standard number"/>
      <subfield code="1" repeat="R" desc="Real World Object URI"/>
      <subfield code="2" repeat="NR" desc="Source of heading or term"/>
      <subfield code="3" repeat="NR" desc="Materials specified"/>
      <subfield code="4" repeat="R" desc="Relationship"/>
      <subfield code="5" repeat="NR" desc="Institution to which field applies"/>
      <subfield code="6" repeat="NR" desc="Linkage"/>
      <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      <subfield code="9" repeat="NR" desc="Special entry"/>
    </datafield>
    <datafield tag="798" repeat="R" desc="LOCAL ADDED ENTRY — MEETING NAME">
      <ind1 values="012" desc="Type of corporate name entry element"/>
      <ind2 values=" 2" desc="Type of added entry"/>
      <subfield code="a" repeat="NR" desc="Meeting name name or jurisdiction name as entry element"/>
      <subfield code="c" repeat="NR" desc="Location of meeting"/>
      <subfield code="d" repeat="R" desc="Date of meeting or treaty signing"/>
      <subfield code="e" repeat="R" desc="Subordinate unit"/>
      <subfield code="f" repeat="NR" desc="Date of work"/>
      <subfield code="g" repeat="R" desc="Miscellaneous information"/>
      <subfield code="h" repeat="NR" desc="Medium"/>
      <subfield code="i" repeat="R" desc="Relationship information"/>
      <subfield code="j" repeat="R" desc="Relator code"/>
      <subfield code="k" repeat="R" desc="Form subheading"/>
      <subfield code="l" repeat="NR" desc="Language of a work"/>
      <subfield code="n" repeat="R" desc="Number of part/section/meeting"/>
      <subfield code="p" repeat="R" desc="Name of part/section of a work"/>
      <subfield code="q" repeat="NR" desc="Name of meeting following jurisdiction name entry element"/>
      <subfield code="s" repeat="R" desc="Version"/>
      <subfield code="t" repeat="NR" desc="Title of a work"/>
      <subfield code="u" repeat="NR" desc="Affiliation"/>
      <subfield code="x" repeat="NR" desc="International Standard Serial Number"/>
      <subfield code="0" repeat="R" desc="Authority record control number or standard number"/>
      <subfield code="1" repeat="R" desc="Real World Object URI"/>
      <subfield code="2" repeat="NR" desc="Source of heading or term"/>
      <subfield code="3" repeat="NR" desc="Materials specified"/>
      <subfield code="4" repeat="R" desc="Relationship"/>
      <subfield code="5" repeat="NR" desc="Institution to which field applies"/>
      <subfield code="6" repeat="NR" desc="Linkage"/>
      <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      <subfield code="9" repeat="NR" desc="Special entry"/>
    </datafield>
    <datafield tag="799" repeat="R" desc="LOCAL ADDED ENTRY — UNIFORM TITLE">
      <ind1 values="0-9" desc="Nonfiling characters"/>
      <ind2 values=" 2" desc="Type of added entry"/>
      <subfield code="a" repeat="NR" desc="Uniform title"/>
      <subfield code="d" repeat="R" desc="Date of treaty signing"/>
      <subfield code="f" repeat="NR" desc="Date of a work"/>
      <subfield code="g" repeat="R" desc="Miscellaneous information"/>
      <subfield code="h" repeat="NR" desc="Medium"/>
      <subfield code="i" repeat="R" desc="Relationship information"/>
      <subfield code="k" repeat="R" desc="Form subheading"/>
      <subfield code="l" repeat="NR" desc="Language of a work"/>
      <subfield code="m" repeat="R" desc="Medium of performance for music"/>
      <subfield code="n" repeat="R" desc="Number of part/section of a work"/>
      <subfield code="o" repeat="NR" desc="Arranged statement for music"/>
      <subfield code="p" repeat="R" desc="Name of part/section of a work"/>
      <subfield code="r" repeat="NR" desc="Key for music"/>
      <subfield code="s" repeat="R" desc="Version"/>
      <subfield code="t" repeat="NR" desc="Title of a work"/>
      <subfield code="x" repeat="NR" desc="International Standard Serial Number"/>
      <subfield code="0" repeat="R" desc="Authority record control number or standard number"/>
      <subfield code="1" repeat="R" desc="Real World Object URI"/>
      <subfield code="2" repeat="NR" desc="Source of heading or term"/>
      <subfield code="3" repeat="NR" desc="Materials specified"/>
      <subfield code="5" repeat="NR" desc="Institution to which field applies"/>
      <subfield code="6" repeat="NR" desc="Linkage"/>
      <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      <subfield code="9" repeat="NR" desc="Special entry"/>
    </datafield>
    <datafield tag="896" repeat="R" desc="LOCAL SERIES ADDED ENTRY — PERSONAL NAME">
      <ind1 values="013" desc="Type of personal name entry element"/>
      <ind2 values=" " desc="Undefined"/>
      <subfield code="a" repeat="NR" desc="Personal name"/>
      <subfield code="b" repeat="NR" desc="Numeration"/>
      <subfield code="c" repeat="R" desc="Titles and other words associated with a name"/>
      <subfield code="d" repeat="NR" desc="Dates associated with a name"/>
      <subfield code="e" repeat="R" desc="Relator term"/>
      <subfield code="f" repeat="NR" desc="Date of a work"/>
      <subfield code="g" repeat="R" desc="Miscellaneous information"/>
      <subfield code="h" repeat="NR" desc="Medium"/>
      <subfield code="j" repeat="R" desc="Attribution qualifier"/>
      <subfield code="k" repeat="R" desc="Form subheading"/>
      <subfield code="l" repeat="NR" desc="Language of a work"/>
      <subfield code="m" repeat="R" desc="Medium of performance for music"/>
      <subfield code="n" repeat="R" desc="Number of part/section of a work"/>
      <subfield code="o" repeat="NR" desc="Arranged statement for music"/>
      <subfield code="p" repeat="R" desc="Name of part/section of a work"/>
      <subfield code="q" repeat="NR" desc="Fuller form of name"/>
      <subfield code="r" repeat="NR" desc="Key for music"/>
      <subfield code="s" repeat="R" desc="Version"/>
      <subfield code="t" repeat="NR" desc="Title of a work"/>
      <subfield code="u" repeat="NR" desc="Affiliation"/>
      <subfield code="v" repeat="NR" desc="Volume/sequential designation"/>
      <subfield code="w" repeat="R" desc="Bibliographic record control number"/>
      <subfield code="x" repeat="NR" desc="International Standard Serial Number"/>
      <subfield code="0" repeat="R" desc="Authority record control number or standard number"/>
      <subfield code="1" repeat="R" desc="Real World Object URI"/>
      <subfield code="2" repeat="NR" desc="Source of heading or term"/>
      <subfield code="3" repeat="NR" desc="Materials specified"/>
      <subfield code="4" repeat="R" desc="Relationship"/>
      <subfield code="5" repeat="R" desc="Institution to which field applies"/>
      <subfield code="6" repeat="NR" desc="Linkage"/>
      <subfield code="7" repeat="NR" desc="Control subfield"/>
      <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      <subfield code="9" repeat="NR" desc="Special entry"/>
    </datafield>
    <datafield tag="897" repeat="R" desc="LOCAL SERIES ADDED ENTRY — CORPORATE NAME">
      <ind1 values="012" desc="Type of corporate name entry element"/>
      <ind2 values=" " desc="Undefined"/>
      <subfield code="a" repeat="NR" desc="Corporate name or jurisdiction name as entry element"/>
      <subfield code="b" repeat="R" desc="Subordinate unit"/>
      <subfield code="c" repeat="R" desc="Location of meeting"/>
      <subfield code="d" repeat="R" desc="Date of meeting or treaty signing"/>
      <subfield code="e" repeat="R" desc="Relator term"/>
      <subfield code="f" repeat="NR" desc="Date of a work"/>
      <subfield code="g" repeat="R" desc="Miscellaneous information"/>
      <subfield code="h" repeat="NR" desc="Medium"/>
      <subfield code="k" repeat="R" desc="Form subheading"/>
      <subfield code="l" repeat="NR" desc="Language of a work"/>
      <subfield code="m" repeat="R" desc="Medium of performance for music"/>
      <subfield code="n" repeat="R" desc="Number of part/section/meeting"/>
      <subfield code="o" repeat="NR" desc="Arranged statement for music"/>
      <subfield code="p" repeat="R" desc="Name of part/section of a work"/>
      <subfield code="r" repeat="NR" desc="Key for music"/>
      <subfield code="s" repeat="R" desc="Version"/>
      <subfield code="t" repeat="NR" desc="Title of a work"/>
      <subfield code="u" repeat="NR" desc="Affiliation"/>
      <subfield code="v" repeat="NR" desc="Volume/sequential designation"/>
      <subfield code="w" repeat="R" desc="Bibliographic record control number"/>
      <subfield code="x" repeat="NR" desc="International Standard Serial Number"/>
      <subfield code="0" repeat="R" desc="Authority record control number or standard number"/>
      <subfield code="1" repeat="R" desc="Real World Object URI"/>
      <subfield code="2" repeat="NR" desc="Source of heading or term"/>
      <subfield code="3" repeat="NR" desc="Materials specified"/>
      <subfield code="4" repeat="R" desc="Relationship"/>
      <subfield code="5" repeat="R" desc="Institution to which field applies"/>
      <subfield code="6" repeat="NR" desc="Linkage"/>
      <subfield code="7" repeat="NR" desc="Control subfield"/>
      <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      <subfield code="9" repeat="NR" desc="Special entry"/>
    </datafield>
    <datafield tag="898" repeat="R" desc="LOCAL SERIES ADDED ENTRY — MEETING NAME">
      <ind1 values="012" desc="Type of meeting name entry element"/>
      <ind2 values=" " desc="Undefined"/>
      <subfield code="a" repeat="NR" desc="Meeting name or jurisdiction name as entry element"/>
      <subfield code="c" repeat="R" desc="Location of meeting"/>
      <subfield code="d" repeat="R" desc="Date of meeting or treaty signing"/>
      <subfield code="e" repeat="R" desc="Subordinate unit"/>
      <subfield code="f" repeat="NR" desc="Date of a work"/>
      <subfield code="g" repeat="R" desc="Miscellaneous information"/>
      <subfield code="h" repeat="NR" desc="Medium"/>
      <subfield code="j" repeat="R" desc="Relator term"/>
      <subfield code="k" repeat="R" desc="Form subheading"/>
      <subfield code="l" repeat="NR" desc="Language of a work"/>
      <subfield code="n" repeat="R" desc="Number of part/section/meeting"/>
      <subfield code="p" repeat="R" desc="Name of part/section of a work"/>
      <subfield code="q" repeat="NR" desc="Name of meeting following jurisdiction name entry element"/>
      <subfield code="s" repeat="R" desc="Version"/>
      <subfield code="t" repeat="NR" desc="Title of a work"/>
      <subfield code="u" repeat="NR" desc="Affiliation"/>
      <subfield code="v" repeat="NR" desc="Volume number/sequential designation"/>
      <subfield code="w" repeat="R" desc="Bibliographic record control number"/>
      <subfield code="x" repeat="NR" desc="International Standard Serial Number"/>
      <subfield code="0" repeat="R" desc="Authority record control number or standard number"/>
      <subfield code="1" repeat="R" desc="Real World Object URI"/>
      <subfield code="2" repeat="NR" desc="Source of heading or term"/>
      <subfield code="3" repeat="NR" desc="Materials specified"/>
      <subfield code="4" repeat="R" desc="Relationship"/>
      <subfield code="5" repeat="R" desc="Institution to which field applies"/>
      <subfield code="6" repeat="NR" desc="Linkage"/>
      <subfield code="7" repeat="NR" desc="Control subfield"/>
      <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      <subfield code="9" repeat="NR" desc="Special entry"/>
    </datafield>
    <datafield tag="899" repeat="R" desc="LOCAL SERIES ADDED ENTRY — UNIFORM TITLE">
      <ind1 values=" " desc="Undefined"/>
      <ind2 values="0-9" desc="Nonfiling characters"/>
      <subfield code="a" repeat="NR" desc="Uniform title"/>
      <subfield code="d" repeat="R" desc="Date of treaty signing"/>
      <subfield code="f" repeat="NR" desc="Date of a work"/>
      <subfield code="g" repeat="R" desc="Miscellaneous information"/>
      <subfield code="h" repeat="NR" desc="Medium"/>
      <subfield code="k" repeat="R" desc="Form subheading"/>
      <subfield code="l" repeat="NR" desc="Language of a work"/>
      <subfield code="m" repeat="R" desc="Medium of performance for music"/>
      <subfield code="n" repeat="R" desc="Number of part/section of a work"/>
      <subfield code="o" repeat="NR" desc="Arranged statement for music"/>
      <subfield code="p" repeat="R" desc="Name of part/section of a work"/>
      <subfield code="r" repeat="NR" desc="Key for music"/>
      <subfield code="s" repeat="R" desc="Version"/>
      <subfield code="t" repeat="NR" desc="Title of a work"/>
      <subfield code="v" repeat="NR" desc="Volume/sequential designation"/>
      <subfield code="w" repeat="R" desc="Bibliographic record control number"/>
      <subfield code="x" repeat="NR" desc="International Standard Serial Number"/>
      <subfield code="0" repeat="R" desc="Authority record control number or standard number"/>
      <subfield code="1" repeat="R" desc="Real World Object URI"/>
      <subfield code="2" repeat="NR" desc="Source of heading or term"/>
      <subfield code="3" repeat="NR" desc="Materials specified"/>
      <subfield code="5" repeat="R" desc="Institution to which field applies"/>
      <subfield code="6" repeat="NR" desc="Linkage"/>
      <subfield code="7" repeat="NR" desc="Control subfield"/>
      <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      <subfield code="9" repeat="NR" desc="Special enty"/>
    </datafield>
    <datafield tag="901" repeat="R" desc="LOCAL DATA">
      <ind1 values=" 0-9" desc="Defined for local use"/>
      <ind2 values=" 0-9" desc="Defined for local use"/>
      <subfield code="abcdefghijklmnopqrstuvwxyz012345789" repeat="R" desc="Defined for local use"/>
      <subfield code="6" repeat="NR" desc="Linkage"/>
    </datafield>
    <datafield tag="902" repeat="R" desc="LOCAL DATA">
      <ind1 values=" 0-9" desc="Defined for local use"/>
      <ind2 values=" 0-9" desc="Defined for local use"/>
      <subfield code="abcdefghijklmnopqrstuvwxyz012345789" repeat="R" desc="Defined for local use"/>
      <subfield code="6" repeat="NR" desc="Linkage"/>
    </datafield>
    <datafield tag="903" repeat="R" desc="LOCAL DATA">
      <ind1 values=" 0-9" desc="Defined for local use"/>
      <ind2 values=" 0-9" desc="Defined for local use"/>
      <subfield code="abcdefghijklmnopqrstuvwxyz012345789" repeat="R" desc="Defined for local use"/>
      <subfield code="6" repeat="NR" desc="Linkage"/>
    </datafield>
    <datafield tag="904" repeat="R" desc="LOCAL DATA">
      <ind1 values=" 0-9" desc="Defined for local use"/>
      <ind2 values=" 0-9" desc="Defined for local use"/>
      <subfield code="abcdefghijklmnopqrstuvwxyz012345789" repeat="R" desc="Defined for local use"/>
      <subfield code="6" repeat="NR" desc="Linkage"/>
    </datafield>
    <datafield tag="905" repeat="R" desc="LOCAL DATA">
      <ind1 values=" 0-9" desc="Defined for local use"/>
      <ind2 values=" 0-9" desc="Defined for local use"/>
      <subfield code="abcdefghijklmnopqrstuvwxyz012345789" repeat="R" desc="Defined for local use"/>
      <subfield code="6" repeat="NR" desc="Linkage"/>
    </datafield>
    <datafield tag="906" repeat="R" desc="LOCAL DATA">
      <ind1 values=" 0-9" desc="Defined for local use"/>
      <ind2 values=" 0-9" desc="Defined for local use"/>
      <subfield code="abcdefghijklmnopqrstuvwxyz012345789" repeat="R" desc="Defined for local use"/>
      <subfield code="6" repeat="NR" desc="Linkage"/>
    </datafield>
    <datafield tag="907" repeat="R" desc="LOCAL DATA">
      <ind1 values=" 0-9" desc="Defined for local use"/>
      <ind2 values=" 0-9" desc="Defined for local use"/>
      <subfield code="abcdefghijklmnopqrstuvwxyz012345789" repeat="R" desc="Defined for local use"/>
      <subfield code="6" repeat="NR" desc="Linkage"/>
    </datafield>
    <!-- https://www.oclc.org/bibformats/en/9xx/910.html says 910 is not repeatable and that 
      only a single ǂa is valid. However, SIRSI contains records that defy this rule. -->
    <datafield tag="910" repeat="R" desc="LOCAL DATA">
      <ind1 values=" " desc="Undefined"/>
      <ind2 values=" " desc="Undefined"/>
      <subfield code="abcdefghijklmnopqrstuvwxyz012345789" repeat="R" desc="Local data"/>
    </datafield>
    <datafield tag="945" repeat="R" desc="LOCAL DATA">
      <ind1 values=" 0-9" desc="Defined for local use"/>
      <ind2 values=" 0-9" desc="Defined for local use"/>
      <subfield code="abcdefghijklmnopqrstuvwxyz012345789" repeat="R" desc="Defined for local use"/>
      <subfield code="6" repeat="NR" desc="Linkage"/>
    </datafield>
    <datafield tag="946" repeat="R" desc="LOCAL DATA">
      <ind1 values=" 0-9" desc="Defined for local use"/>
      <ind2 values=" 0-9" desc="Defined for local use"/>
      <subfield code="abcdefghijklmnopqrstuvwxyz012345789" repeat="R" desc="Defined for local use"/>
      <subfield code="6" repeat="NR" desc="Linkage"/>
    </datafield>
    <datafield tag="947" repeat="R" desc="LOCAL DATA">
      <ind1 values=" 0-9" desc="Defined for local use"/>
      <ind2 values=" 0-9" desc="Defined for local use"/>
      <subfield code="abcdefghijklmnopqrstuvwxyz012345789" repeat="R" desc="Defined for local use"/>
      <subfield code="6" repeat="NR" desc="Linkage"/>
    </datafield>
    <datafield tag="956" repeat="R" desc="LOCAL ELECTRONIC LOCATION AND ACCESS">
      <ind1 values=" 012347" desc="Access method"/>
      <ind2 values=" 0128" desc="Relationship"/>
      <subfield code="a" repeat="R" desc="Host name"/>
      <subfield code="b" repeat="R" desc="Access number"/>
      <subfield code="c" repeat="R" desc="Compression information"/>
      <subfield code="d" repeat="R" desc="Path"/>
      <subfield code="f" repeat="R" desc="Electronic name"/>
      <subfield code="h" repeat="R" desc="Processor of request"/>
      <subfield code="i" repeat="R" desc="Instruction"/>
      <subfield code="j" repeat="NR" desc="Bits per second"/>
      <subfield code="k" repeat="NR" desc="Password"/>
      <subfield code="l" repeat="NR" desc="Logon"/>
      <subfield code="m" repeat="R" desc="Contact for access assistance"/>
      <subfield code="n" repeat="NR" desc="Name of location of host"/>
      <subfield code="o" repeat="NR" desc="Operating system"/>
      <subfield code="p" repeat="NR" desc="Port"/>
      <subfield code="q" repeat="NR" desc="Electronic format type"/>
      <subfield code="r" repeat="NR" desc="Settings"/>
      <subfield code="s" repeat="R" desc="File size"/>
      <subfield code="t" repeat="R" desc="Terminal emulation"/>
      <subfield code="u" repeat="R" desc="Uniform resource identifier"/>
      <subfield code="v" repeat="R" desc="Hours access method available"/>
      <subfield code="w" repeat="R" desc="Record control number"/>
      <subfield code="y" repeat="R" desc="Link text"/>
      <subfield code="x" repeat="R" desc="Nonpublic note"/>
      <subfield code="z" repeat="R" desc="Public note"/>
      <subfield code="2" repeat="NR" desc="Access method"/>
      <subfield code="3" repeat="NR" desc="Materials specified"/>
      <subfield code="6" repeat="NR" desc="Linkage"/>
    </datafield>
    <datafield tag="987" repeat="R" desc="LOCAL ROMANIZATION/CONVERSION HISTORY">
      <ind1 values=" " desc="Undefined"/>
      <ind2 values=" " desc="Undefined"/>
      <subfield code="a" repeat="NR" desc="Romanization/conversion identifier"/>
      <subfield code="b" repeat="NR" desc="Agency that converted, created or reviewed romanization/conversion"/>
      <subfield code="c" repeat="NR" desc="Date of conversion or review"/>
      <subfield code="d" repeat="NR" desc="Status code"/>
      <subfield code="e" repeat="NR" desc="Version of conversion program used"/>
      <subfield code="f" repeat="NR" desc="Note"/>
    </datafield>
    <datafield tag="900" repeat="R" desc="LOCAL DATA/OCLC RESERVED">
      <ind1 values=" 0-9" desc="Defined for local use"/>
      <ind2 values=" 0-9" desc="Defined for local use"/>
      <subfield code="abcdefghijklmnopqrstuvwxyz012345789" repeat="R" desc="Defined for local use"/>
      <subfield code="6" repeat="NR" desc="Linkage"/>
    </datafield>
    <datafield tag="908" repeat="R" desc="LOCAL DATA/OCLC RESERVED">
      <ind1 values=" 0-9" desc="Defined for local use"/>
      <ind2 values=" 0-9" desc="Defined for local use"/>
      <subfield code="abcdefghijklmnopqrstuvwxyz012345789" repeat="R" desc="Defined for local use"/>
      <subfield code="6" repeat="NR" desc="Linkage"/>
    </datafield>
    <datafield tag="909" repeat="R" desc="LOCAL DATA/OCLC RESERVED">
      <ind1 values=" 0-9" desc="Defined for local use"/>
      <ind2 values=" 0-9" desc="Defined for local use"/>
      <subfield code="abcdefghijklmnopqrstuvwxyz012345789" repeat="R" desc="Defined for local use"/>
      <subfield code="6" repeat="NR" desc="Linkage"/>
    </datafield>
    <datafield tag="911" repeat="R" desc="LOCAL DATA/OCLC RESERVED">
      <ind1 values=" 0-9" desc="Defined for local use"/>
      <ind2 values=" 0-9" desc="Defined for local use"/>
      <subfield code="abcdefghijklmnopqrstuvwxyz012345789" repeat="R" desc="Defined for local use"/>
      <subfield code="6" repeat="NR" desc="Linkage"/>
    </datafield>
    <datafield tag="912" repeat="R" desc="LOCAL DATA/OCLC RESERVED">
      <ind1 values=" 0-9" desc="Defined for local use"/>
      <ind2 values=" 0-9" desc="Defined for local use"/>
      <subfield code="abcdefghijklmnopqrstuvwxyz012345789" repeat="R" desc="Defined for local use"/>
      <subfield code="6" repeat="NR" desc="Linkage"/>
    </datafield>
    <datafield tag="913" repeat="R" desc="LOCAL DATA/OCLC RESERVED">
      <ind1 values=" 0-9" desc="Defined for local use"/>
      <ind2 values=" 0-9" desc="Defined for local use"/>
      <subfield code="abcdefghijklmnopqrstuvwxyz012345789" repeat="R" desc="Defined for local use"/>
      <subfield code="6" repeat="NR" desc="Linkage"/>
    </datafield>
    <datafield tag="914" repeat="R" desc="LOCAL DATA/OCLC RESERVED">
      <ind1 values=" 0-9" desc="Defined for local use"/>
      <ind2 values=" 0-9" desc="Defined for local use"/>
      <subfield code="abcdefghijklmnopqrstuvwxyz012345789" repeat="R" desc="Defined for local use"/>
      <subfield code="6" repeat="NR" desc="Linkage"/>
    </datafield>
    <datafield tag="915" repeat="R" desc="LOCAL DATA/OCLC RESERVED">
      <ind1 values=" 0-9" desc="Defined for local use"/>
      <ind2 values=" 0-9" desc="Defined for local use"/>
      <subfield code="abcdefghijklmnopqrstuvwxyz012345789" repeat="R" desc="Defined for local use"/>
      <subfield code="6" repeat="NR" desc="Linkage"/>
    </datafield>
    <datafield tag="916" repeat="R" desc="LOCAL DATA/OCLC RESERVED">
      <ind1 values=" 0-9" desc="Defined for local use"/>
      <ind2 values=" 0-9" desc="Defined for local use"/>
      <subfield code="abcdefghijklmnopqrstuvwxyz012345789" repeat="R" desc="Defined for local use"/>
      <subfield code="6" repeat="NR" desc="Linkage"/>
    </datafield>
    <datafield tag="917" repeat="R" desc="LOCAL DATA/OCLC RESERVED">
      <ind1 values=" 0-9" desc="Defined for local use"/>
      <ind2 values=" 0-9" desc="Defined for local use"/>
      <subfield code="abcdefghijklmnopqrstuvwxyz012345789" repeat="R" desc="Defined for local use"/>
      <subfield code="6" repeat="NR" desc="Linkage"/>
    </datafield>
    <datafield tag="918" repeat="R" desc="LOCAL DATA/OCLC RESERVED">
      <ind1 values=" 0-9" desc="Defined for local use"/>
      <ind2 values=" 0-9" desc="Defined for local use"/>
      <subfield code="abcdefghijklmnopqrstuvwxyz012345789" repeat="R" desc="Defined for local use"/>
      <subfield code="6" repeat="NR" desc="Linkage"/>
    </datafield>
    <datafield tag="919" repeat="R" desc="LOCAL DATA/OCLC RESERVED">
      <ind1 values=" 0-9" desc="Defined for local use"/>
      <ind2 values=" 0-9" desc="Defined for local use"/>
      <subfield code="abcdefghijklmnopqrstuvwxyz012345789" repeat="R" desc="Defined for local use"/>
      <subfield code="6" repeat="NR" desc="Linkage"/>
    </datafield>
    <datafield tag="920" repeat="R" desc="LOCAL DATA/OCLC RESERVED">
      <ind1 values=" 0-9" desc="Defined for local use"/>
      <ind2 values=" 0-9" desc="Defined for local use"/>
      <subfield code="abcdefghijklmnopqrstuvwxyz012345789" repeat="R" desc="Defined for local use"/>
      <subfield code="6" repeat="NR" desc="Linkage"/>
    </datafield>
    <datafield tag="921" repeat="R" desc="LOCAL DATA/OCLC RESERVED">
      <ind1 values=" 0-9" desc="Defined for local use"/>
      <ind2 values=" 0-9" desc="Defined for local use"/>
      <subfield code="abcdefghijklmnopqrstuvwxyz012345789" repeat="R" desc="Defined for local use"/>
      <subfield code="6" repeat="NR" desc="Linkage"/>
    </datafield>
    <datafield tag="922" repeat="R" desc="LOCAL DATA/OCLC RESERVED">
      <ind1 values=" 0-9" desc="Defined for local use"/>
      <ind2 values=" 0-9" desc="Defined for local use"/>
      <subfield code="abcdefghijklmnopqrstuvwxyz012345789" repeat="R" desc="Defined for local use"/>
      <subfield code="6" repeat="NR" desc="Linkage"/>
    </datafield>
    <datafield tag="923" repeat="R" desc="LOCAL DATA/OCLC RESERVED">
      <ind1 values=" 0-9" desc="Defined for local use"/>
      <ind2 values=" 0-9" desc="Defined for local use"/>
      <subfield code="abcdefghijklmnopqrstuvwxyz012345789" repeat="R" desc="Defined for local use"/>
      <subfield code="6" repeat="NR" desc="Linkage"/>
    </datafield>
    <datafield tag="924" repeat="R" desc="LOCAL DATA/OCLC RESERVED">
      <ind1 values=" 0-9" desc="Defined for local use"/>
      <ind2 values=" 0-9" desc="Defined for local use"/>
      <subfield code="abcdefghijklmnopqrstuvwxyz012345789" repeat="R" desc="Defined for local use"/>
      <subfield code="6" repeat="NR" desc="Linkage"/>
    </datafield>
    <datafield tag="925" repeat="R" desc="LOCAL DATA/OCLC RESERVED">
      <ind1 values=" 0-9" desc="Defined for local use"/>
      <ind2 values=" 0-9" desc="Defined for local use"/>
      <subfield code="abcdefghijklmnopqrstuvwxyz012345789" repeat="R" desc="Defined for local use"/>
      <subfield code="6" repeat="NR" desc="Linkage"/>
    </datafield>
    <datafield tag="926" repeat="R" desc="LOCAL DATA/OCLC RESERVED">
      <ind1 values=" 0-9" desc="Defined for local use"/>
      <ind2 values=" 0-9" desc="Defined for local use"/>
      <subfield code="abcdefghijklmnopqrstuvwxyz012345789" repeat="R" desc="Defined for local use"/>
      <subfield code="6" repeat="NR" desc="Linkage"/>
    </datafield>
    <datafield tag="927" repeat="R" desc="LOCAL DATA/OCLC RESERVED">
      <ind1 values=" 0-9" desc="Defined for local use"/>
      <ind2 values=" 0-9" desc="Defined for local use"/>
      <subfield code="abcdefghijklmnopqrstuvwxyz012345789" repeat="R" desc="Defined for local use"/>
      <subfield code="6" repeat="NR" desc="Linkage"/>
    </datafield>
    <datafield tag="928" repeat="R" desc="LOCAL DATA/OCLC RESERVED">
      <ind1 values=" 0-9" desc="Defined for local use"/>
      <ind2 values=" 0-9" desc="Defined for local use"/>
      <subfield code="abcdefghijklmnopqrstuvwxyz012345789" repeat="R" desc="Defined for local use"/>
      <subfield code="6" repeat="NR" desc="Linkage"/>
    </datafield>
    <datafield tag="929" repeat="R" desc="LOCAL DATA/OCLC RESERVED">
      <ind1 values=" 0-9" desc="Defined for local use"/>
      <ind2 values=" 0-9" desc="Defined for local use"/>
      <subfield code="abcdefghijklmnopqrstuvwxyz012345789" repeat="R" desc="Defined for local use"/>
      <subfield code="6" repeat="NR" desc="Linkage"/>
    </datafield>
    <datafield tag="930" repeat="R" desc="LOCAL DATA/OCLC RESERVED">
      <ind1 values=" 0-9" desc="Defined for local use"/>
      <ind2 values=" 0-9" desc="Defined for local use"/>
      <subfield code="abcdefghijklmnopqrstuvwxyz012345789" repeat="R" desc="Defined for local use"/>
      <subfield code="6" repeat="NR" desc="Linkage"/>
    </datafield>
    <datafield tag="931" repeat="R" desc="LOCAL DATA/OCLC RESERVED">
      <ind1 values=" 0-9" desc="Defined for local use"/>
      <ind2 values=" 0-9" desc="Defined for local use"/>
      <subfield code="abcdefghijklmnopqrstuvwxyz012345789" repeat="R" desc="Defined for local use"/>
      <subfield code="6" repeat="NR" desc="Linkage"/>
    </datafield>
    <datafield tag="932" repeat="R" desc="LOCAL DATA/OCLC RESERVED">
      <ind1 values=" 0-9" desc="Defined for local use"/>
      <ind2 values=" 0-9" desc="Defined for local use"/>
      <subfield code="abcdefghijklmnopqrstuvwxyz012345789" repeat="R" desc="Defined for local use"/>
      <subfield code="6" repeat="NR" desc="Linkage"/>
    </datafield>
    <datafield tag="933" repeat="R" desc="LOCAL DATA/OCLC RESERVED">
      <ind1 values=" 0-9" desc="Defined for local use"/>
      <ind2 values=" 0-9" desc="Defined for local use"/>
      <subfield code="abcdefghijklmnopqrstuvwxyz012345789" repeat="R" desc="Defined for local use"/>
      <subfield code="6" repeat="NR" desc="Linkage"/>
    </datafield>
    <datafield tag="934" repeat="R" desc="LOCAL DATA/OCLC RESERVED">
      <ind1 values=" 0-9" desc="Defined for local use"/>
      <ind2 values=" 0-9" desc="Defined for local use"/>
      <subfield code="abcdefghijklmnopqrstuvwxyz012345789" repeat="R" desc="Defined for local use"/>
      <subfield code="6" repeat="NR" desc="Linkage"/>
    </datafield>
    <datafield tag="935" repeat="R" desc="LOCAL DATA/OCLC RESERVED">
      <ind1 values=" 0-9" desc="Defined for local use"/>
      <ind2 values=" 0-9" desc="Defined for local use"/>
      <subfield code="abcdefghijklmnopqrstuvwxyz012345789" repeat="R" desc="Defined for local use"/>
      <subfield code="6" repeat="NR" desc="Linkage"/>
    </datafield>
    <datafield tag="936" repeat="NR" desc="CONSER/OCLC MISCELLANEOUS DATA">
      <ind1 values=" " desc="Undefined"/>
      <ind2 values=" " desc="Undefined"/>
      <subfield code="a" repeat="NR" desc="CONSER/OCLC miscellaneous data"/>
    </datafield>
    <datafield tag="937" repeat="R" desc="LOCAL DATA/OCLC RESERVED">
      <ind1 values=" 0-9" desc="Defined for local use"/>
      <ind2 values=" 0-9" desc="Defined for local use"/>
      <subfield code="abcdefghijklmnopqrstuvwxyz012345789" repeat="R" desc="Defined for local use"/>
      <subfield code="6" repeat="NR" desc="Linkage"/>
    </datafield>
    <datafield tag="938" repeat="R" desc="VENDOR-SPECIFIC ORDERING DATA">
      <ind1 values=" " desc="Undefined"/>
      <ind2 values=" " desc="Undefined"/>
      <subfield code="a" repeat="NR" desc="Full name of vendor"/>
      <subfield code="b" repeat="NR" desc="OCLC-defined symbol for vendor"/>
      <subfield code="c" repeat="NR" desc="Terms of availability"/>
      <subfield code="d" repeat="NR" desc="Vendor net price"/>
      <subfield code="i" repeat="NR" desc="Inventory number"/>
      <subfield code="n" repeat="NR" desc="Vendor control number"/>
      <subfield code="s" repeat="NR" desc="Vendor status"/>
      <subfield code="z" repeat="NR" desc="Note"/>
    </datafield>
    <datafield tag="939" repeat="R" desc="LOCAL DATA/OCLC RESERVED">
      <ind1 values=" 0-9" desc="Defined for local use"/>
      <ind2 values=" 0-9" desc="Defined for local use"/>
      <subfield code="abcdefghijklmnopqrstuvwxyz012345789" repeat="R" desc="Defined for local use"/>
      <subfield code="6" repeat="NR" desc="Linkage"/>
    </datafield>
    <datafield tag="940" repeat="R" desc="LOCAL DATA/OCLC RESERVED">
      <ind1 values=" 0-9" desc="Defined for local use"/>
      <ind2 values=" 0-9" desc="Defined for local use"/>
      <subfield code="abcdefghijklmnopqrstuvwxyz012345789" repeat="R" desc="Defined for local use"/>
      <subfield code="6" repeat="NR" desc="Linkage"/>
    </datafield>
    <datafield tag="941" repeat="R" desc="LOCAL DATA/OCLC RESERVED">
      <ind1 values=" 0-9" desc="Defined for local use"/>
      <ind2 values=" 0-9" desc="Defined for local use"/>
      <subfield code="abcdefghijklmnopqrstuvwxyz012345789" repeat="R" desc="Defined for local use"/>
      <subfield code="6" repeat="NR" desc="Linkage"/>
    </datafield>
    <datafield tag="942" repeat="R" desc="LOCAL DATA/OCLC RESERVED">
      <ind1 values=" 0-9" desc="Defined for local use"/>
      <ind2 values=" 0-9" desc="Defined for local use"/>
      <subfield code="abcdefghijklmnopqrstuvwxyz012345789" repeat="R" desc="Defined for local use"/>
      <subfield code="6" repeat="NR" desc="Linkage"/>
    </datafield>
    <datafield tag="943" repeat="R" desc="LOCAL DATA/OCLC RESERVED">
      <ind1 values=" 0-9" desc="Defined for local use"/>
      <ind2 values=" 0-9" desc="Defined for local use"/>
      <subfield code="abcdefghijklmnopqrstuvwxyz012345789" repeat="R" desc="Defined for local use"/>
      <subfield code="6" repeat="NR" desc="Linkage"/>
    </datafield>
    <datafield tag="944" repeat="R" desc="LOCAL DATA/OCLC RESERVED">
      <ind1 values=" 0-9" desc="Defined for local use"/>
      <ind2 values=" 0-9" desc="Defined for local use"/>
      <subfield code="abcdefghijklmnopqrstuvwxyz012345789" repeat="R" desc="Defined for local use"/>
      <subfield code="6" repeat="NR" desc="Linkage"/>
    </datafield>
    <!-- Datafield 948 is reserved for use by Sirsi -->
    <datafield tag="948" repeat="R" desc="LOCAL DATA/SIRSI RESERVED">
      <ind1 values=" 0-9" desc="Defined for local use"/>
      <ind2 values=" 0-9" desc="Defined for local use"/>
      <subfield code="abcdefghijklmnopqrstuvwxyz012345789" repeat="R" desc="Defined for local use"/>
      <subfield code="6" repeat="NR" desc="Linkage"/>
    </datafield>
    <!-- Datafield 949 is reserved for use by Sirsi -->
    <datafield tag="949" repeat="R" desc="LOCAL DATA/SIRSI RESERVED">
      <ind1 values=" 0-9" desc="Defined for local use"/>
      <ind2 values=" 0-9" desc="Defined for local use"/>
      <subfield code="abcdefghijklmnopqrstuvwxyz012345789" repeat="R" desc="Defined for local use"/>
      <subfield code="6" repeat="NR" desc="Linkage"/>
    </datafield>
    <datafield tag="950" repeat="R" desc="LOCAL DATA/OCLC RESERVED">
      <ind1 values=" 0-9" desc="Defined for local use"/>
      <ind2 values=" 0-9" desc="Defined for local use"/>
      <subfield code="abcdefghijklmnopqrstuvwxyz012345789" repeat="R" desc="Defined for local use"/>
      <subfield code="6" repeat="NR" desc="Linkage"/>
    </datafield>
    <datafield tag="951" repeat="R" desc="LOCAL DATA/OCLC RESERVED">
      <ind1 values=" 0-9" desc="Defined for local use"/>
      <ind2 values=" 0-9" desc="Defined for local use"/>
      <subfield code="abcdefghijklmnopqrstuvwxyz012345789" repeat="R" desc="Defined for local use"/>
      <subfield code="6" repeat="NR" desc="Linkage"/>
    </datafield>
    <datafield tag="952" repeat="R" desc="LOCAL DATA/OCLC RESERVED">
      <ind1 values=" 0-9" desc="Defined for local use"/>
      <ind2 values=" 0-9" desc="Defined for local use"/>
      <subfield code="abcdefghijklmnopqrstuvwxyz012345789" repeat="R" desc="Defined for local use"/>
      <subfield code="6" repeat="NR" desc="Linkage"/>
    </datafield>
    <datafield tag="953" repeat="R" desc="LOCAL DATA/OCLC RESERVED">
      <ind1 values=" 0-9" desc="Defined for local use"/>
      <ind2 values=" 0-9" desc="Defined for local use"/>
      <subfield code="abcdefghijklmnopqrstuvwxyz012345789" repeat="R" desc="Defined for local use"/>
      <subfield code="6" repeat="NR" desc="Linkage"/>
    </datafield>
    <datafield tag="954" repeat="R" desc="LOCAL DATA/OCLC RESERVED">
      <ind1 values=" 0-9" desc="Defined for local use"/>
      <ind2 values=" 0-9" desc="Defined for local use"/>
      <subfield code="abcdefghijklmnopqrstuvwxyz012345789" repeat="R" desc="Defined for local use"/>
      <subfield code="6" repeat="NR" desc="Linkage"/>
    </datafield>
    <datafield tag="955" repeat="R" desc="LOCAL DATA/OCLC RESERVED">
      <ind1 values=" 0-9" desc="Defined for local use"/>
      <ind2 values=" 0-9" desc="Defined for local use"/>
      <subfield code="abcdefghijklmnopqrstuvwxyz012345789" repeat="R" desc="Defined for local use"/>
      <subfield code="6" repeat="NR" desc="Linkage"/>
    </datafield>
    <datafield tag="957" repeat="R" desc="LOCAL DATA/OCLC RESERVED">
      <ind1 values=" 0-9" desc="Defined for local use"/>
      <ind2 values=" 0-9" desc="Defined for local use"/>
      <subfield code="abcdefghijklmnopqrstuvwxyz012345789" repeat="R" desc="Defined for local use"/>
      <subfield code="6" repeat="NR" desc="Linkage"/>
    </datafield>
    <datafield tag="958" repeat="R" desc="LOCAL DATA/OCLC RESERVED">
      <ind1 values=" 0-9" desc="Defined for local use"/>
      <ind2 values=" 0-9" desc="Defined for local use"/>
      <subfield code="abcdefghijklmnopqrstuvwxyz012345789" repeat="R" desc="Defined for local use"/>
      <subfield code="6" repeat="NR" desc="Linkage"/>
    </datafield>
    <datafield tag="959" repeat="R" desc="LOCAL DATA/OCLC RESERVED">
      <ind1 values=" 0-9" desc="Defined for local use"/>
      <ind2 values=" 0-9" desc="Defined for local use"/>
      <subfield code="abcdefghijklmnopqrstuvwxyz012345789" repeat="R" desc="Defined for local use"/>
      <subfield code="6" repeat="NR" desc="Linkage"/>
    </datafield>
    <datafield tag="960" repeat="R" desc="LOCAL DATA/OCLC RESERVED">
      <ind1 values=" 0-9" desc="Defined for local use"/>
      <ind2 values=" 0-9" desc="Defined for local use"/>
      <subfield code="abcdefghijklmnopqrstuvwxyz012345789" repeat="R" desc="Defined for local use"/>
      <subfield code="6" repeat="NR" desc="Linkage"/>
    </datafield>
    <datafield tag="961" repeat="R" desc="LOCAL DATA/OCLC RESERVED">
      <ind1 values=" 0-9" desc="Defined for local use"/>
      <ind2 values=" 0-9" desc="Defined for local use"/>
      <subfield code="abcdefghijklmnopqrstuvwxyz012345789" repeat="R" desc="Defined for local use"/>
      <subfield code="6" repeat="NR" desc="Linkage"/>
    </datafield>
    <datafield tag="962" repeat="R" desc="LOCAL DATA/OCLC RESERVED">
      <ind1 values=" 0-9" desc="Defined for local use"/>
      <ind2 values=" 0-9" desc="Defined for local use"/>
      <subfield code="abcdefghijklmnopqrstuvwxyz012345789" repeat="R" desc="Defined for local use"/>
      <subfield code="6" repeat="NR" desc="Linkage"/>
    </datafield>
    <datafield tag="963" repeat="R" desc="LOCAL DATA/OCLC RESERVED">
      <ind1 values=" 0-9" desc="Defined for local use"/>
      <ind2 values=" 0-9" desc="Defined for local use"/>
      <subfield code="abcdefghijklmnopqrstuvwxyz012345789" repeat="R" desc="Defined for local use"/>
      <subfield code="6" repeat="NR" desc="Linkage"/>
    </datafield>
    <datafield tag="964" repeat="R" desc="LOCAL DATA/OCLC RESERVED">
      <ind1 values=" 0-9" desc="Defined for local use"/>
      <ind2 values=" 0-9" desc="Defined for local use"/>
      <subfield code="abcdefghijklmnopqrstuvwxyz012345789" repeat="R" desc="Defined for local use"/>
      <subfield code="6" repeat="NR" desc="Linkage"/>
    </datafield>
    <datafield tag="965" repeat="R" desc="LOCAL DATA/OCLC RESERVED">
      <ind1 values=" 0-9" desc="Defined for local use"/>
      <ind2 values=" 0-9" desc="Defined for local use"/>
      <subfield code="abcdefghijklmnopqrstuvwxyz012345789" repeat="R" desc="Defined for local use"/>
      <subfield code="6" repeat="NR" desc="Linkage"/>
    </datafield>
    <datafield tag="966" repeat="R" desc="LOCAL DATA/OCLC RESERVED">
      <ind1 values=" 0-9" desc="Defined for local use"/>
      <ind2 values=" 0-9" desc="Defined for local use"/>
      <subfield code="abcdefghijklmnopqrstuvwxyz012345789" repeat="R" desc="Defined for local use"/>
      <subfield code="6" repeat="NR" desc="Linkage"/>
    </datafield>
    <datafield tag="967" repeat="R" desc="LOCAL DATA/OCLC RESERVED">
      <ind1 values=" 0-9" desc="Defined for local use"/>
      <ind2 values=" 0-9" desc="Defined for local use"/>
      <subfield code="abcdefghijklmnopqrstuvwxyz012345789" repeat="R" desc="Defined for local use"/>
      <subfield code="6" repeat="NR" desc="Linkage"/>
    </datafield>
    <datafield tag="968" repeat="R" desc="LOCAL DATA/OCLC RESERVED">
      <ind1 values=" 0-9" desc="Defined for local use"/>
      <ind2 values=" 0-9" desc="Defined for local use"/>
      <subfield code="abcdefghijklmnopqrstuvwxyz012345789" repeat="R" desc="Defined for local use"/>
      <subfield code="6" repeat="NR" desc="Linkage"/>
    </datafield>
    <datafield tag="969" repeat="R" desc="LOCAL DATA/OCLC RESERVED">
      <ind1 values=" 0-9" desc="Defined for local use"/>
      <ind2 values=" 0-9" desc="Defined for local use"/>
      <subfield code="abcdefghijklmnopqrstuvwxyz012345789" repeat="R" desc="Defined for local use"/>
      <subfield code="6" repeat="NR" desc="Linkage"/>
    </datafield>
    <!-- Used by UVA to indicate authority review/remediation by Marcive -->
    <!--<datafield tag="970" repeat="R" desc="LOCAL DATA/OCLC RESERVED">
      <ind1 values=" 0-9" desc="Defined for local use"/>
      <ind2 values=" 0-9" desc="Defined for local use"/>
      <subfield code="abcdefghijklmnopqrstuvwxyz012345789" repeat="R" desc="Defined for local use"/>
      <subfield code="6" repeat="NR" desc="Linkage"/>
    </datafield>-->
    <datafield tag="971" repeat="R" desc="LOCAL DATA/OCLC RESERVED">
      <ind1 values=" 0-9" desc="Defined for local use"/>
      <ind2 values=" 0-9" desc="Defined for local use"/>
      <subfield code="abcdefghijklmnopqrstuvwxyz012345789" repeat="R" desc="Defined for local use"/>
      <subfield code="6" repeat="NR" desc="Linkage"/>
    </datafield>
    <datafield tag="972" repeat="R" desc="LOCAL DATA/OCLC RESERVED">
      <ind1 values=" 0-9" desc="Defined for local use"/>
      <ind2 values=" 0-9" desc="Defined for local use"/>
      <subfield code="abcdefghijklmnopqrstuvwxyz012345789" repeat="R" desc="Defined for local use"/>
      <subfield code="6" repeat="NR" desc="Linkage"/>
    </datafield>
    <datafield tag="973" repeat="R" desc="LOCAL DATA/OCLC RESERVED">
      <ind1 values=" 0-9" desc="Defined for local use"/>
      <ind2 values=" 0-9" desc="Defined for local use"/>
      <subfield code="abcdefghijklmnopqrstuvwxyz012345789" repeat="R" desc="Defined for local use"/>
      <subfield code="6" repeat="NR" desc="Linkage"/>
    </datafield>
    <datafield tag="974" repeat="R" desc="LOCAL DATA/OCLC RESERVED">
      <ind1 values=" 0-9" desc="Defined for local use"/>
      <ind2 values=" 0-9" desc="Defined for local use"/>
      <subfield code="abcdefghijklmnopqrstuvwxyz012345789" repeat="R" desc="Defined for local use"/>
      <subfield code="6" repeat="NR" desc="Linkage"/>
    </datafield>
    <datafield tag="975" repeat="R" desc="LOCAL DATA/OCLC RESERVED">
      <ind1 values=" 0-9" desc="Defined for local use"/>
      <ind2 values=" 0-9" desc="Defined for local use"/>
      <subfield code="abcdefghijklmnopqrstuvwxyz012345789" repeat="R" desc="Defined for local use"/>
      <subfield code="6" repeat="NR" desc="Linkage"/>
    </datafield>
    <datafield tag="976" repeat="R" desc="LOCAL DATA/OCLC RESERVED">
      <ind1 values=" 0-9" desc="Defined for local use"/>
      <ind2 values=" 0-9" desc="Defined for local use"/>
      <subfield code="abcdefghijklmnopqrstuvwxyz012345789" repeat="R" desc="Defined for local use"/>
      <subfield code="6" repeat="NR" desc="Linkage"/>
    </datafield>
    <datafield tag="977" repeat="R" desc="LOCAL DATA/OCLC RESERVED">
      <ind1 values=" 0-9" desc="Defined for local use"/>
      <ind2 values=" 0-9" desc="Defined for local use"/>
      <subfield code="abcdefghijklmnopqrstuvwxyz012345789" repeat="R" desc="Defined for local use"/>
      <subfield code="6" repeat="NR" desc="Linkage"/>
    </datafield>
    <datafield tag="978" repeat="R" desc="LOCAL DATA/OCLC RESERVED">
      <ind1 values=" 0-9" desc="Defined for local use"/>
      <ind2 values=" 0-9" desc="Defined for local use"/>
      <subfield code="abcdefghijklmnopqrstuvwxyz012345789" repeat="R" desc="Defined for local use"/>
      <subfield code="6" repeat="NR" desc="Linkage"/>
    </datafield>
    <datafield tag="979" repeat="R" desc="LOCAL DATA/OCLC RESERVED">
      <ind1 values=" 0-9" desc="Defined for local use"/>
      <ind2 values=" 0-9" desc="Defined for local use"/>
      <subfield code="abcdefghijklmnopqrstuvwxyz012345789" repeat="R" desc="Defined for local use"/>
      <subfield code="6" repeat="NR" desc="Linkage"/>
    </datafield>
    <datafield tag="980" repeat="R" desc="LOCAL DATA/OCLC RESERVED">
      <ind1 values=" 0-9" desc="Defined for local use"/>
      <ind2 values=" 0-9" desc="Defined for local use"/>
      <subfield code="abcdefghijklmnopqrstuvwxyz012345789" repeat="R" desc="Defined for local use"/>
      <subfield code="6" repeat="NR" desc="Linkage"/>
    </datafield>
    <datafield tag="981" repeat="R" desc="LOCAL DATA/OCLC RESERVED">
      <ind1 values=" 0-9" desc="Defined for local use"/>
      <ind2 values=" 0-9" desc="Defined for local use"/>
      <subfield code="abcdefghijklmnopqrstuvwxyz012345789" repeat="R" desc="Defined for local use"/>
      <subfield code="6" repeat="NR" desc="Linkage"/>
    </datafield>
    <datafield tag="982" repeat="R" desc="LOCAL DATA/OCLC RESERVED">
      <ind1 values=" 0-9" desc="Defined for local use"/>
      <ind2 values=" 0-9" desc="Defined for local use"/>
      <subfield code="abcdefghijklmnopqrstuvwxyz012345789" repeat="R" desc="Defined for local use"/>
      <subfield code="6" repeat="NR" desc="Linkage"/>
    </datafield>
    <datafield tag="983" repeat="R" desc="LOCAL DATA/OCLC RESERVED">
      <ind1 values=" 0-9" desc="Defined for local use"/>
      <ind2 values=" 0-9" desc="Defined for local use"/>
      <subfield code="abcdefghijklmnopqrstuvwxyz012345789" repeat="R" desc="Defined for local use"/>
      <subfield code="6" repeat="NR" desc="Linkage"/>
    </datafield>
    <datafield tag="984" repeat="R" desc="LOCAL DATA/OCLC RESERVED">
      <ind1 values=" 0-9" desc="Defined for local use"/>
      <ind2 values=" 0-9" desc="Defined for local use"/>
      <subfield code="abcdefghijklmnopqrstuvwxyz012345789" repeat="R" desc="Defined for local use"/>
      <subfield code="6" repeat="NR" desc="Linkage"/>
    </datafield>
    <datafield tag="985" repeat="R" desc="LOCAL DATA/OCLC RESERVED">
      <ind1 values=" 0-9" desc="Defined for local use"/>
      <ind2 values=" 0-9" desc="Defined for local use"/>
      <subfield code="abcdefghijklmnopqrstuvwxyz012345789" repeat="R" desc="Defined for local use"/>
      <subfield code="6" repeat="NR" desc="Linkage"/>
    </datafield>
    <datafield tag="986" repeat="R" desc="LOCAL DATA/OCLC RESERVED">
      <ind1 values=" 0-9" desc="Defined for local use"/>
      <ind2 values=" 0-9" desc="Defined for local use"/>
      <subfield code="abcdefghijklmnopqrstuvwxyz012345789" repeat="R" desc="Defined for local use"/>
      <subfield code="6" repeat="NR" desc="Linkage"/>
    </datafield>
    <datafield tag="988" repeat="R" desc="LOCAL DATA/OCLC RESERVED">
      <ind1 values=" 0-9" desc="Defined for local use"/>
      <ind2 values=" 0-9" desc="Defined for local use"/>
      <subfield code="abcdefghijklmnopqrstuvwxyz012345789" repeat="R" desc="Defined for local use"/>
      <subfield code="6" repeat="NR" desc="Linkage"/>
    </datafield>
    <datafield tag="989" repeat="R" desc="LOCAL DATA/OCLC RESERVED">
      <ind1 values=" 0-9" desc="Defined for local use"/>
      <ind2 values=" 0-9" desc="Defined for local use"/>
      <subfield code="abcdefghijklmnopqrstuvwxyz012345789" repeat="R" desc="Defined for local use"/>
      <subfield code="6" repeat="NR" desc="Linkage"/>
    </datafield>
    <datafield tag="990" repeat="R" desc="LOCAL DATA/OCLC RESERVED">
      <ind1 values=" 0-9" desc="Defined for local use"/>
      <ind2 values=" 0-9" desc="Defined for local use"/>
      <subfield code="abcdefghijklmnopqrstuvwxyz012345789" repeat="R" desc="Defined for local use"/>
      <subfield code="6" repeat="NR" desc="Linkage"/>
    </datafield>
    <datafield tag="992" repeat="R" desc="LOCAL DATA/OCLC RESERVED">
      <ind1 values=" 0-9" desc="Defined for local use"/>
      <ind2 values=" 0-9" desc="Defined for local use"/>
      <subfield code="abcdefghijklmnopqrstuvwxyz012345789" repeat="R" desc="Defined for local use"/>
      <subfield code="6" repeat="NR" desc="Linkage"/>
    </datafield>
    <datafield tag="993" repeat="R" desc="LOCAL DATA/OCLC RESERVED">
      <ind1 values=" 0-9" desc="Defined for local use"/>
      <ind2 values=" 0-9" desc="Defined for local use"/>
      <subfield code="abcdefghijklmnopqrstuvwxyz012345789" repeat="R" desc="Defined for local use"/>
      <subfield code="6" repeat="NR" desc="Linkage"/>
    </datafield>
    <datafield tag="994" repeat="NR" desc="OCLC-MARC TRANSACTION CODE">
      <ind1 values=" " desc="Undefined"/>
      <ind2 values=" " desc="Undefined"/>
      <subfield code="a" repeat="NR" desc="Transaction code"/>
      <subfield code="b" repeat="NR" desc="Institution symbol">
    </subfield>
    </datafield>
    <datafield tag="995" repeat="R" desc="LOCAL DATA/OCLC RESERVED">
      <ind1 values=" 0-9" desc="Defined for local use"/>
      <ind2 values=" 0-9" desc="Defined for local use"/>
      <subfield code="abcdefghijklmnopqrstuvwxyz012345789" repeat="R" desc="Defined for local use"/>
      <subfield code="6" repeat="NR" desc="Linkage"/>
    </datafield>
    <datafield tag="996" repeat="R" desc="LOCAL DATA/OCLC RESERVED">
      <ind1 values=" 0-9" desc="Defined for local use"/>
      <ind2 values=" 0-9" desc="Defined for local use"/>
      <subfield code="abcdefghijklmnopqrstuvwxyz012345789" repeat="R" desc="Defined for local use"/>
      <subfield code="6" repeat="NR" desc="Linkage"/>
    </datafield>
    <datafield tag="997" repeat="R" desc="LOCAL DATA/OCLC RESERVED">
      <ind1 values=" 0-9" desc="Defined for local use"/>
      <ind2 values=" 0-9" desc="Defined for local use"/>
      <subfield code="abcdefghijklmnopqrstuvwxyz012345789" repeat="R" desc="Defined for local use"/>
      <subfield code="6" repeat="NR" desc="Linkage"/>
    </datafield>
    <datafield tag="998" repeat="R" desc="LOCAL DATA/OCLC RESERVED">
      <ind1 values=" 0-9" desc="Defined for local use"/>
      <ind2 values=" 0-9" desc="Defined for local use"/>
      <subfield code="abcdefghijklmnopqrstuvwxyz012345789" repeat="R" desc="Defined for local use"/>
      <subfield code="6" repeat="NR" desc="Linkage"/>
    </datafield>
    <datafield tag="999" repeat="R" desc="LOCAL DATA/UVA DEFINED">
      <ind1 values=" " desc="Undefined"/>
      <ind2 values=" " desc="Undefined"/>
      <subfield code="a" repeat="NR" desc="Item call number"/>
      <subfield code="v" repeat="NR" desc="Volume number"/>
      <subfield code="w" repeat="NR" desc="Call number sort type"/>
      <subfield code="c" repeat="NR" desc="Copy number"/>
      <subfield code="h" repeat="NR" desc="Holding code"/>
      <subfield code="i" repeat="NR" desc="Item identifier"/>
      <subfield code="m" repeat="NR" desc="Library"/>
      <subfield code="d" repeat="NR" desc="Last activity"/>
      <subfield code="e" repeat="NR" desc="Date last charged"/>
      <subfield code="f" repeat="NR" desc="Date inventoried"/>
      <subfield code="g" repeat="NR" desc="Time inventoried"/>
      <subfield code="j" repeat="NR" desc="Number of pieces"/>
      <subfield code="k" repeat="NR" desc="Checkout status"/>
      <subfield code="l" repeat="NR" desc="Item location"/>
      <subfield code="n" repeat="NR" desc="Total charges"/>
      <subfield code="o" repeat="R" desc="Item notes or comments"/>
      <subfield code="p" repeat="NR" desc="Price"/>
      <subfield code="q" repeat="NR" desc="In-house charges"/>
      <subfield code="r" repeat="NR" desc="Circulate flag"/>
      <subfield code="s" repeat="NR" desc="Permanent flag"/>
      <subfield code="t" repeat="NR" desc="Item type"/>
      <subfield code="u" repeat="NR" desc="Acquisitions date"/>
      <subfield code="x" repeat="NR" desc="Item category 1"/>
      <subfield code="z" repeat="NR" desc="Item category 2"/>
      <subfield code="0" repeat="NR" desc="Item category 3"/>
      <subfield code="1" repeat="NR" desc="Item category 4"/>
      <subfield code="2" repeat="NR" desc="Item category 5"/>
    </datafield>
  </xsl:variable>

  <!-- Some fields are defined/used by UVA and are always included. -->
  <xsl:variable name="uvaFields">
    <!-- https://www.loc.gov/marc/bibliographic/ecbdlist.html says 090 and 590 obsolete -->
    <!-- Defined here because UVA uses them -->
    <datafield tag="090" repeat="R" desc="LOCALLY ASSIGNED LC-TYPE CALL NUMBER/UVA
      DEFINED">
      <ind1 values=" " desc="Undefined"/>
      <ind2 values=" " desc="Undefined"/>
      <subfield code="a" repeat="R" desc="Classification number"/>
      <subfield code="b" repeat="NR" desc="Local cutter number"/>
      <subfield code="e" repeat="NR" desc="Feature heading"/>
      <subfield code="f" repeat="NR" desc="Filing suffix"/>
      <subfield code="m" repeat="NR" desc="Insttitution code"/>
      <subfield code="q" repeat="NR" desc="Library"/>
    </datafield>
    <datafield tag="099" repeat="R" desc="LOCAL FREE-TEXT CALL NUMBER/UVA DEFINED">
      <ind1 values=" " desc="Undefined"/>
      <ind2 values=" 019" desc="Source of call number"/>
      <subfield code="a" repeat="R" desc="Classification number"/>
      <subfield code="e" repeat="NR" desc="Feature heading"/>
      <subfield code="f" repeat="NR" desc="Filing suffix"/>
    </datafield>
    <datafield tag="590" repeat="R" desc="LOCAL NOTE/UVA DEFINED">
      <ind1 values=" 01" desc="Privacy"/>
      <ind2 values=" " desc="Undefined"/>
      <subfield code="a" repeat="NR" desc="Local note"/>
      <subfield code="3" repeat="NR" desc="Materials specified"/>
      <subfield code="6" repeat="NR" desc="Linkage"/>
      <subfield code="8" repeat="R" desc="Field link and sequence number"/>
    </datafield>
    <!-- Datafield 970 used indicate authority review/remediation by Marcive -->
    <datafield tag="970" repeat="NR" desc="DOCUMENTATION OF MARCIVE REVIEW/REMEDIATION">
      <ind1 values=" " desc="Undefined"/>
      <ind2 values=" " desc="Undefined"/>
      <subfield code="a" repeat="NR" desc="Name of remediation agent/project"/>
    </datafield>
    <!-- Datafield 991 used for UVA MARC remediation documentation -->
    <datafield tag="991" repeat="R" desc="LOCALLY DEFINED/UVA DEFINED">
      <ind1 values=" " desc="Undefined"/>
      <ind2 values=" " desc="Undefined"/>
      <subfield code="a" repeat="NR" desc="Name of remediation agent/project"/>
      <subfield code="b" repeat="NR" desc="Date of modification"/>
      <subfield code="5" repeat="R" desc="Institution to which field applies"/>
      <!-- To allow the following subfields, uncomment them  -->
      <!--<subfield code="cdefghijklmnopqrstuvwxyz" desc="Locally defined"/>
      <subfield code="0" repeat="R" desc="Authority record control number or standard number"/>
      <subfield code="1" repeat="R" desc="Real World Object URI"/>
      <subfield code="2" repeat="R" desc="Source"/>
      <subfield code="3" repeat="R" desc="Materials specified"/>
      <subfield code="4" repeat="R" desc="Relationship"/>
      <subfield code="6" repeat="NR" desc="Linkage"/>
      <subfield code="7" repeat="R" desc="Control subfield"/>
      <subfield code="8" repeat="R" desc="Field link and sequence number"/>
      <subfield code="9" repeat="R" desc="Special entry"/>-->
    </datafield>
    <!-- Datafield 999 used for Sirsi item information -->
    <datafield tag="999" repeat="R" desc="LOCAL DATA/UVA DEFINED">
      <ind1 values=" " desc="Undefined"/>
      <ind2 values=" " desc="Undefined"/>
      <subfield code="a" repeat="NR" desc="Item call number"/>
      <subfield code="v" repeat="NR" desc="Volume number"/>
      <subfield code="w" repeat="NR" desc="Call number sort type"/>
      <subfield code="c" repeat="NR" desc="Copy number"/>
      <subfield code="h" repeat="NR" desc="Holding code"/>
      <subfield code="i" repeat="NR" desc="Item identifier"/>
      <subfield code="m" repeat="NR" desc="Library"/>
      <subfield code="d" repeat="NR" desc="Last activity"/>
      <subfield code="e" repeat="NR" desc="Date last charged"/>
      <subfield code="f" repeat="NR" desc="Date inventoried"/>
      <subfield code="g" repeat="NR" desc="Time inventoried"/>
      <subfield code="j" repeat="NR" desc="Number of pieces"/>
      <subfield code="k" repeat="NR" desc="Checkout status"/>
      <subfield code="l" repeat="NR" desc="Item location"/>
      <subfield code="n" repeat="NR" desc="Total charges"/>
      <subfield code="o" repeat="R" desc="Item notes or comments"/>
      <subfield code="p" repeat="NR" desc="Price"/>
      <subfield code="q" repeat="NR" desc="In-house charges"/>
      <subfield code="r" repeat="NR" desc="Circulate flag"/>
      <subfield code="s" repeat="NR" desc="Permanent flag"/>
      <subfield code="t" repeat="NR" desc="Item type"/>
      <subfield code="u" repeat="NR" desc="Acquisitions date"/>
      <subfield code="x" repeat="NR" desc="Item category 1"/>
      <subfield code="z" repeat="NR" desc="Item category 2"/>
      <subfield code="0" repeat="NR" desc="Item category 3"/>
      <subfield code="1" repeat="NR" desc="Item category 4"/>
      <subfield code="2" repeat="NR" desc="Item category 5"/>
    </datafield>
  </xsl:variable>

  <xsl:template match="/">
    <xsl:choose>
      <xsl:when test="unparsed-text-available($text-uri)">
        <!-- Read MARC 21 Bibliographic Data Field List as unparsed text -->
        <xsl:variable name="vText" select="unparsed-text($text-uri)"/>

        <!-- Create line elements, effectively turning the plain text into generic XML -->
        <xsl:variable name="pass1">
          <xsl:analyze-string select="$vText" regex="\n">
            <xsl:non-matching-substring>
              <line>
                <xsl:value-of select="."/>
              </line>
            </xsl:non-matching-substring>
          </xsl:analyze-string>
        </xsl:variable>

        <xsl:variable name="topComment">
          <xsl:text>&#32;This file describes the MARC bibliographic format </xsl:text>
          <xsl:value-of
            select="replace(replace($pass1/*:line[matches(., 'class.*edition')], '&lt;br>', ' '), '&lt;/?[^>]+>', '')"/>
          <xsl:text>&#xa;</xsl:text>
          <xsl:value-of
            select="replace($pass1/*:line[matches(., 'Update')], '&lt;/?[^>]+>', '')"/>
          <xsl:text>. It is&#xa;generated from </xsl:text>
          <xsl:value-of select="$text-uri"/>
          <xsl:text> by&#xa;</xsl:text>
          <xsl:value-of select="$progName"/>
          <xsl:text>.&#32;</xsl:text>
          <xsl:text>&#xa;&#xa;</xsl:text>
          <xsl:text>PARAMETERS USED:&#xa;</xsl:text>
          <xsl:value-of
            select="concat(&quot;text-uri = &apos;&quot;, $text-uri, &quot;&apos;&#xa;includeLocalFields = &apos;&quot;, $includeLocalFields, &quot;&apos;&#xa;includeObsoleteFields = &apos;&quot;, $includeObsoleteFields, &quot;&apos;&#xa;includeUvaFields = &apos;&quot;, $includeUvaFields, &quot;&apos;&#xa;includeValueDefs = &apos;&quot;, $includeValueDefs, &quot;&apos;&#xa;&quot;)"
          />
        </xsl:variable>

        <!-- Refine markup created in pass 1 -->
        <!-- Create field elements -->
        <xsl:variable name="pass2">
          <xsl:for-each-group select="$pass1/*:line[not(normalize-space(.) = '')]"
            group-starting-with=".[matches(., '^( +LEADER| +DIRECTORY|\d{3})')]">
            <field>
              <xsl:for-each select="current-group()">
                <xsl:copy-of select="."/>
              </xsl:for-each>
            </field>
          </xsl:for-each-group>
        </xsl:variable>

        <!-- Refine the markup created in pass 2 -->
        <xsl:variable name="pass3">
          <!-- Leader -->
          <xsl:for-each select="$pass2/*:field[matches(*:line[1], 'LEADER')]">
            <leader tag="000" repeat="NR" desc="LEADER">
              <xsl:for-each-group select="*:line" group-starting-with="*:line[matches(., '^     \d\d')]">
                <!-- Capture the group -->
                <xsl:variable name="group">
                  <xsl:copy-of select="current-group()"/>
                </xsl:variable>
                <xsl:copy-of select="$group"/>
              </xsl:for-each-group>
            </leader>
          </xsl:for-each>
          <!-- Fixed fields -->
          <xsl:for-each select="$pass2/*:field[matches(*:line[1], '^00[678] -')]">
            <controlfield>
              <xsl:attribute name="tag">
                <xsl:value-of select="substring(*:line[1], 1, 3)"/>
              </xsl:attribute>
              <xsl:attribute name="repeat">
                <xsl:choose>
                  <xsl:when test="matches(*:line[1], '\(NR\)')">
                    <xsl:text>NR</xsl:text>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:text>R</xsl:text>
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:attribute>
              <xsl:attribute name="desc">
                <xsl:value-of select="replace(replace(substring-after(normalize-space(*:line[1]), ' - '), ' \(N?R\)', ''), '--', '&#x2014;')"/>
              </xsl:attribute>
              <!-- Group lines by material form -->
              <xsl:for-each-group select="*:line" group-starting-with="*:line[matches(., '--(ALL MATERIALS|BOOKS|COMPUTER FILES|MAPS|MUSIC|CONTINUING RESOURCES|VISUAL MATERIALS|MIXED MATERIALS|MAP|ELECTRONIC RESOURCE|GLOBE|TACTILE MATERIAL|.*GRAPHIC|MICROFORM|MOTION PICTURE|KIT|NOTATED MUSIC|REMOTE-SENSING IMAGE|SOUND RECORDING|TEXT|VIDEORECORDING|UNSPECIFIED)')]">
                <xsl:variable name="group">
                  <xsl:copy-of select="current-group()"/>
                </xsl:variable>
                <format>
                  <xsl:copy-of select="$group"/>
                </format>
              </xsl:for-each-group>
            </controlfield>
          </xsl:for-each>
          <xsl:for-each select="$pass2/*:field[matches(*:line[1], '^00[1359] -')]">
            <controlfield>
              <xsl:attribute name="tag">
                <xsl:value-of select="substring(*:line[1], 1, 3)"/>
              </xsl:attribute>
              <xsl:attribute name="repeat">
                <xsl:choose>
                  <xsl:when test="matches(*:line[1], '\(NR\)')">
                    <xsl:text>NR</xsl:text>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:text>R</xsl:text>
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:attribute>
              <xsl:attribute name="desc">
                <xsl:value-of select="replace(replace(substring-after(normalize-space(*:line[1]), ' - '), ' \(N?R\)', ''), '--', '&#x2014;')"/>
              </xsl:attribute>
              <xsl:if test="matches(., '00[6789]')">
                <xsl:for-each-group select="*:line" group-starting-with="*:line[matches(., '^ +\d\d\d--')]">
                  <!-- Capture the group -->
                  <xsl:variable name="group">
                    <xsl:copy-of select="current-group()"/>
                  </xsl:variable>
                  <xsl:copy-of select="$group"/>
                </xsl:for-each-group>
              </xsl:if>
            </controlfield>
          </xsl:for-each>

          <!-- Data fields -->
          <xsl:for-each
            select="$pass2/*:field[matches(*:line[1], '^\d{3} -') and not(matches(*:line[1], '^00[1356789] -'))]">
            <datafield>
              <!-- Group lines into $indicators, $subfields and other stuff -->
              <xsl:for-each-group select="*:line"
                group-starting-with="*:line[matches(., 'Indicators|Subfield Codes')]">
                <!-- Capture the group -->
                <xsl:variable name="group">
                  <xsl:copy-of select="current-group()"/>
                </xsl:variable>
                <xsl:choose>
                  <!-- When first line of the group matches a 3-digit number -->
                  <!-- Put field number and description into @tag, @desc, @repeat -->
                  <xsl:when test="matches($group/*:line[1], '^\d{3}')">
                    <xsl:attribute name="tag">
                      <xsl:value-of select="substring($group/*:line[1], 1, 3)"/>
                    </xsl:attribute>
                    <xsl:attribute name="repeat">
                      <xsl:choose>
                        <xsl:when test="matches($group/*:line[1], '\(NR\)')">
                          <xsl:text>NR</xsl:text>
                        </xsl:when>
                        <xsl:otherwise>
                          <xsl:text>R</xsl:text>
                        </xsl:otherwise>
                      </xsl:choose>
                    </xsl:attribute>
                    <xsl:attribute name="desc">
                      <xsl:value-of
                        select="replace(replace(substring-after(normalize-space($group/*:line[1]), ' - '), ' \(N?R\)', ''), '--', '&#x2014;')"
                      />
                    </xsl:attribute>
                  </xsl:when>
                  <!-- When first line of the group matches 'Indicators' -->
                  <!-- Process the group into indGroup sub-groups -->
                  <xsl:when test="matches($group/*:line[1], 'Indicators')">
                    <xsl:variable name="indicators">
                      <xsl:copy-of select="$group"/>
                    </xsl:variable>
                    <xsl:for-each-group select="$indicators/*:line"
                      group-starting-with="*:line[matches(., '^ +(First|Second)')]">
                      <xsl:variable name="indGroup">
                        <xsl:copy-of select="current-group()"/>
                      </xsl:variable>
                      <!-- Create ind1 and ind2 elements depending on the content of $indGroup -->
                      <xsl:choose>
                        <xsl:when
                          test="matches($indGroup/*:line[1], 'First') and not(matches($indGroup/*:line[1], 'OBSOLETE'))">
                          <ind1>
                            <xsl:copy-of select="$indGroup"/>
                          </ind1>
                        </xsl:when>
                        <xsl:when
                          test="matches($indGroup/*:line[1], 'Second') and not(matches($indGroup/*:line[1], 'OBSOLETE'))">
                          <ind2>
                            <xsl:copy-of select="$indGroup"/>
                          </ind2>
                        </xsl:when>
                      </xsl:choose>
                    </xsl:for-each-group>
                  </xsl:when>
                  <!-- When the first line of the group matches 'Subfield Codes' -->
                  <!-- Wrap the group in a <subfields> element -->
                  <xsl:when test="matches($group/*:line[1], 'Subfield Codes')">
                    <subfields>
                      <xsl:copy-of select="$group"/>
                    </subfields>
                  </xsl:when>
                </xsl:choose>
              </xsl:for-each-group>
            </datafield>
          </xsl:for-each>
        </xsl:variable>

        <!--<marcDesc xmlns:sch="http://purl.oclc.org/dsdl/schematron"
          xmlns:sqf="http://www.schematron-quickfix.com/validator/process"
          xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
          <xsl:copy-of select="$pass3"/>
        </marcDesc>
        <xsl:message terminate="yes"/>-->

        <!-- Refine the markup created in pass 3 -->
        <xsl:variable name="pass4">
          <xsl:for-each select="$pass3/*:leader">
            <xsl:text>&#xa;&#xa;</xsl:text>
            <xsl:comment>&#32;Leader&#32;</xsl:comment>
            <xsl:copy>
              <xsl:copy-of select="@*"/>
              <xsl:text>&#xa;</xsl:text>
              <length>
                <xsl:for-each select="*:line[matches(., '^\s+\d\d(-\d\d)?')][last()]">
                  <xsl:variable name="length">
                    <xsl:value-of select="normalize-space(substring-before(., ' - '))"/>
                  </xsl:variable>
                  <xsl:choose>
                    <xsl:when test="matches($length, '-')">
                      <xsl:value-of select="number(substring-after($length, '-')) + 1"/>
                    </xsl:when>
                    <xsl:otherwise>
                      <xsl:value-of select="number($length) + 1"/>
                    </xsl:otherwise>
                  </xsl:choose>
                </xsl:for-each>
              </length>
              <xsl:for-each-group select="*:line"
                group-starting-with="*:line[matches(., '^\s+\d\d')]">
                <xsl:variable name="group">
                  <xsl:copy-of select="current-group()"/>
                </xsl:variable>
                <xsl:if test="matches(., '^\s+\d\d')">
                  <xsl:variable name="startEnd">
                    <xsl:value-of select="normalize-space(substring-before(., ' - '))"/>
                  </xsl:variable>
                  <xsl:variable name="start">
                    <xsl:choose>
                      <xsl:when test="substring-before($startEnd, '-')">
                        <xsl:value-of select="substring-before($startEnd, '-')"/>
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:value-of select="$startEnd"/>
                      </xsl:otherwise>
                    </xsl:choose>
                  </xsl:variable>
                  <xsl:variable name="end">
                    <xsl:choose>
                      <xsl:when test="substring-before($startEnd, '-')">
                        <xsl:value-of select="substring-after($startEnd, '-')"/>
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:value-of select="$startEnd"/>
                      </xsl:otherwise>
                    </xsl:choose>
                  </xsl:variable>
                  <xsl:if test="$start &lt;= 21 and not(matches(., 'Length'))">
                    <code>
                      <!-- Character position in XPath/XSLT is 1-based -->
                      <xsl:variable name="position">
                        <xsl:value-of select="number($start) + 1"/>
                      </xsl:variable>
                      <xsl:attribute name="position">
                        <xsl:value-of select="$position"/>
                      </xsl:attribute>
                      <xsl:variable name="length">
                        <xsl:value-of select="(number($end) - number($start)) + 1"/>
                      </xsl:variable>
                      <xsl:attribute name="length">
                        <xsl:value-of select="$length"/>
                      </xsl:attribute>
                      <xsl:variable name="desc">
                        <xsl:value-of select="normalize-space(substring-after(., ' - '))"
                        />
                      </xsl:variable>
                      <xsl:variable name="valueSpace">
                        <xsl:for-each select="$group/*:line[position() &gt; 1]">
                          <xsl:value-of
                            select="normalize-space(substring-before(., ' - '))"/>
                        </xsl:for-each>
                        <!-- To add values permitted by OCLC in the past, uncomment the lines below. -->
                        <!--<xsl:if test="$position = 18">
                          <xsl:text>IKLMEJ</xsl:text>
                        </xsl:if>-->
                      </xsl:variable>
                      <xsl:attribute name="desc">
                        <xsl:value-of
                          select="replace(normalize-space($desc), '--', '&#x2014;')"/>
                      </xsl:attribute>
                      <xsl:attribute name="values">
                        <xsl:text>'</xsl:text>
                        <xsl:choose>
                          <xsl:when test="($position = 11) or ($position = 12)">
                            <xsl:text>2</xsl:text>
                          </xsl:when>
                          <xsl:when test="$start + 1 = 21">
                            <xsl:text>4500</xsl:text>
                          </xsl:when>
                          <xsl:when test="normalize-space($valueSpace) = ''">
                            <xsl:text>\d</xsl:text>
                            <xsl:if test="$length &gt; 1">
                              <xsl:value-of select="concat('{', $length, '}')"/>
                            </xsl:if>
                          </xsl:when>
                          <xsl:otherwise>
                            <xsl:value-of
                              select="concat('[', replace($valueSpace, '#', '\\p{Zs}'), ']')"/>
                            <xsl:if test="$length &gt; 1">
                              <xsl:value-of select="concat('{', $length, '}')"/>
                            </xsl:if>
                          </xsl:otherwise>
                        </xsl:choose>
                        <xsl:text>'</xsl:text>
                      </xsl:attribute>
                      <xsl:if test="$includeValueDefs != 'false'">
                        <xsl:for-each
                          select="$group/*:line[position() &gt; 1][not(matches(., '\[REDEFINED\]'))]">
                          <valuedef>
                            <xsl:if test="matches(., '\[OBSOLETE\]')">
                              <xsl:attribute name="use">
                                <xsl:text>obsolete</xsl:text>
                              </xsl:attribute>
                            </xsl:if>
                            <xsl:value-of
                              select="normalize-space(replace(., '((- )?\[)?OBSOLETE\]?', ''))"
                            />
                          </valuedef>
                        </xsl:for-each>
                      </xsl:if>
                    </code>
                  </xsl:if>
                </xsl:if>
              </xsl:for-each-group>
            </xsl:copy>
          </xsl:for-each>

          <xsl:comment>&#32;Control fields&#32;</xsl:comment>
          <!-- Pass through 001, 003, and 005 -->
          <xsl:copy-of select="$pass3/*:controlfield[matches(@tag, '00[135]')]"/>

          <!-- Create generic 006 description -->
          <xsl:for-each select="$pass3/*:controlfield[matches(@tag, '006')]">
            <xsl:copy>
              <xsl:copy-of select="@*"/>
              <xsl:text>&#xa;</xsl:text>
              <length>
                <xsl:for-each
                  select="*:format[position() = 2]/*:line[matches(., '^\s+\d\d(-\d\d)? -')][last()]">
                  <xsl:variable name="length">
                    <xsl:value-of select="normalize-space(substring-before(., ' - '))"/>
                  </xsl:variable>
                  <xsl:choose>
                    <xsl:when test="matches($length, '-')">
                      <xsl:value-of select="number(substring-after($length, '-')) + 1"/>
                    </xsl:when>
                    <xsl:otherwise>
                      <xsl:value-of select="number($length) + 1"/>
                    </xsl:otherwise>
                  </xsl:choose>
                </xsl:for-each>
              </length>
              <code position="1" length="1" desc="Form of material">
                <xsl:attribute name="values">
                  <xsl:text>'[</xsl:text>
                  <xsl:variable name="formOfMaterial006">
                    <xsl:for-each select="*:format[position() &gt; 1]">
                      <xsl:for-each-group select="*:line"
                        group-starting-with="*:line[matches(., '^\s+\d\d[^\d]')]">
                        <xsl:variable name="group">
                          <xsl:copy-of select="current-group()"/>
                        </xsl:variable>
                        <xsl:if test="matches($group/*:line[1], '00 - ')">
                          <xsl:for-each select="$group/*:line[position() &gt; 1]">
                            <value>
                              <xsl:value-of
                                select="substring-before(normalize-space(.), ' - ')"/>
                            </value>
                          </xsl:for-each>
                        </xsl:if>
                      </xsl:for-each-group>
                    </xsl:for-each>
                  </xsl:variable>
                  <xsl:for-each select="$formOfMaterial006/*:value">
                    <xsl:sort/>
                    <xsl:value-of select="."/>
                  </xsl:for-each>
                  <xsl:text>]'</xsl:text>
                </xsl:attribute>
              </code>
            </xsl:copy>
          </xsl:for-each>

          <!-- Create 007 descriptions -->
          <xsl:variable name="processed007s">
            <xsl:for-each select="$pass3/*:controlfield[matches(@tag, '007')]">
              <!-- Create 007 description for each material code -->
              <xsl:variable name="pass1">
                <xsl:for-each select="*:format[position() &gt; 1]">
                  <controlfield tag="007">
                  <xsl:variable name="desc">
                    <xsl:value-of select="normalize-space(substring-after(*:line[1], '--'))"/>
                  </xsl:variable>
                  <xsl:attribute name="materialCategory">
                    <xsl:choose>
                      <xsl:when test="matches($desc, 'MAP')">a</xsl:when>
                      <xsl:when test="matches($desc, 'ELECTRONIC RESOURCE')">c</xsl:when>
                      <xsl:when test="matches($desc, 'GLOBE')">d</xsl:when>
                      <xsl:when test="matches($desc, 'TACTILE MATERIAL')">f</xsl:when>
                      <xsl:when test="matches($desc, 'NONPROJECTED GRAPHIC')">k</xsl:when>
                      <xsl:when test="matches($desc, 'PROJECTED GRAPHIC')">g</xsl:when>
                      <xsl:when test="matches($desc, 'MICROFORM')">h</xsl:when>
                      <xsl:when test="matches($desc, 'MOTION PICTURE')">m</xsl:when>
                      <xsl:when test="matches($desc, 'KIT')">o</xsl:when>
                      <xsl:when test="matches($desc, 'NOTATED MUSIC')">q</xsl:when>
                      <xsl:when test="matches($desc, 'REMOTE-SENSING IMAGE')">r</xsl:when>
                      <xsl:when test="matches($desc, 'SOUND RECORDING')">s</xsl:when>
                      <xsl:when test="matches($desc, 'TEXT')">t</xsl:when>
                      <xsl:when test="matches($desc, 'VIDEORECORDING')">v</xsl:when>
                      <xsl:when test="matches($desc, 'UNSPECIFIED')">z</xsl:when>
                    </xsl:choose>
                  </xsl:attribute>
                  <xsl:attribute name="desc">
                    <xsl:value-of select="replace(normalize-space($desc), '--', '&#x2014;')"/>
                  </xsl:attribute>
                  <xsl:text>&#xa;</xsl:text>
                  <!-- Length derived from HTML -->
                  <length>
                    <xsl:for-each select="*:line[matches(., '^\s+\d\d(-\d\d)?')][last()]">
                      <xsl:variable name="length">
                        <xsl:value-of select="normalize-space(substring-before(., ' - '))"/>
                      </xsl:variable>
                      <xsl:choose>
                        <xsl:when test="matches($length, '-')">
                          <xsl:value-of select="number(substring-after($length, '-')) + 1"/>
                        </xsl:when>
                        <xsl:otherwise>
                          <xsl:value-of select="number($length) + 1"/>
                        </xsl:otherwise>
                      </xsl:choose>
                    </xsl:for-each>
                  </length>
                  <!-- Length hard-coded -->
                  <!--<length>
                    <xsl:choose>
                      <xsl:when test="matches($desc, 'MAP')">8</xsl:when>
                      <xsl:when test="matches($desc, 'ELECTRONIC RESOURCE')">14</xsl:when>
                      <xsl:when test="matches($desc, 'GLOBE')">6</xsl:when>
                      <xsl:when test="matches($desc, 'TACTILE MATERIAL')">10</xsl:when>
                      <xsl:when test="matches($desc, 'PROJECTED GRAPHIC')">9</xsl:when>
                      <xsl:when test="matches($desc, 'MICROFORM')">13</xsl:when>
                      <xsl:when test="matches($desc, 'NONPROJECTED GRAPHIC')">6</xsl:when>
                      <xsl:when test="matches($desc, 'MOTION PICTURE')">23</xsl:when>
                      <xsl:when test="matches($desc, 'KIT')">2</xsl:when>
                      <xsl:when test="matches($desc, 'NOTATED MUSIC')">2</xsl:when>
                      <xsl:when test="matches($desc, 'REMOTE-SENSING IMAGE')">11</xsl:when>
                      <xsl:when test="matches($desc, 'SOUND RECORDING')">14</xsl:when>
                      <xsl:when test="matches($desc, 'TEXT')">2</xsl:when>
                      <xsl:when test="matches($desc, 'VIDEORECORDING')">9</xsl:when>
                      <xsl:when test="matches($desc, 'UNSPECIFIED')">2</xsl:when>
                    </xsl:choose>
                  </length>-->
                  <xsl:for-each-group select="*:line[position() &gt; 4]" group-starting-with="*:line[matches(., '^\s+\d\d[^\d]')]">
                    <xsl:variable name="group">
                      <xsl:copy-of select="current-group()"/>
                    </xsl:variable>
                    <xsl:for-each select="$group/*:line[1]">
                      <xsl:if test="not(matches(., '\[OBSOLETE\]'))">
                        <xsl:variable name="startEnd">
                          <xsl:value-of select="normalize-space(substring-before(., ' - '))"/>
                        </xsl:variable>
                        <xsl:variable name="start">
                          <xsl:choose>
                            <xsl:when test="substring-before($startEnd, '-')">
                              <xsl:value-of select="substring-before($startEnd, '-')"/>
                            </xsl:when>
                            <xsl:otherwise>
                              <xsl:value-of select="$startEnd"/>
                            </xsl:otherwise>
                          </xsl:choose>
                        </xsl:variable>
                        <xsl:variable name="end">
                          <xsl:choose>
                            <xsl:when test="substring-before($startEnd, '-')">
                              <xsl:value-of select="substring-after($startEnd, '-')"/>
                            </xsl:when>
                            <xsl:otherwise>
                              <xsl:value-of select="$startEnd"/>
                            </xsl:otherwise>
                          </xsl:choose>
                        </xsl:variable>
                        <code>
                          <xsl:variable name="position">
                            <xsl:value-of select="number($start) + 1"/>
                          </xsl:variable>
                          <xsl:attribute name="position">
                            <xsl:value-of select="$position"/>
                          </xsl:attribute>
                          <xsl:variable name="length">
                            <xsl:value-of select="(number($end) - number($start)) + 1"/>
                          </xsl:variable>
                          <xsl:attribute name="length">
                            <xsl:value-of select="$length"/>
                          </xsl:attribute>
                          <xsl:variable name="desc">
                            <xsl:value-of select="normalize-space(substring-after(., ' - '))"/>
                          </xsl:variable>
                          <xsl:variable name="valueSpace">
                            <xsl:variable name="rawValues">
                              <xsl:for-each select="$group/*:line[position() &gt; 1]">
                                <value>
                                  <!-- This is a kludge for 007 VIDEORECORDING position 05 (0-based) in which there's no space
                                    following the initial | -->
                                  <xsl:value-of select="normalize-space(substring-before(replace(., '^( +.)(- .*)', '$1 - $2'), ' - '))"/>
                                </value>
                              </xsl:for-each>
                            </xsl:variable>
                            <xsl:choose>
                              <xsl:when test="matches($desc, '^(Image bit depth)$', 'i')">
                                <xsl:text>(</xsl:text>
                                <xsl:for-each select="distinct-values($rawValues/*:value)">
                                  <xsl:value-of select="replace(replace(replace(., '\|', '\\|'), '#', '\\p{Zs}'), '00[01]-999', '\\d\\d\\d')"/>
                                  <xsl:if test="position() != last()">
                                    <xsl:text>|</xsl:text>
                                  </xsl:if>
                                </xsl:for-each>
                                <xsl:text>)</xsl:text>
                              </xsl:when>
                              <xsl:when test="matches($desc, '^(Data type)$', 'i')">
                                <xsl:text>(</xsl:text>
                                <xsl:for-each select="distinct-values($rawValues/*:value)">
                                  <xsl:value-of select="replace(replace(., '\|', '\\|'), '#', '\\p{Zs}')"/>
                                  <xsl:if test="position() != last()">
                                    <xsl:text>|</xsl:text>
                                  </xsl:if>
                                </xsl:for-each>
                                <xsl:text>)</xsl:text>
                              </xsl:when>
                              <xsl:when test="matches($desc, '^(Reduction ratio)$', 'i')">
                                <text>\d-|</text>
                              </xsl:when>
                              <xsl:otherwise>
                                <xsl:for-each select="distinct-values($rawValues/*:value)">
                                  <!--<xsl:value-of select="replace(., '\|', '\\|')"/>-->
                                  <xsl:value-of select="."/>
                                </xsl:for-each>
                              </xsl:otherwise>
                            </xsl:choose>
                          </xsl:variable>
                          <xsl:attribute name="desc">
                            <xsl:value-of select="replace(normalize-space($desc), '--', '&#x2014;')"/>
                          </xsl:attribute>
                          <xsl:attribute name="values">
                            <xsl:text>'</xsl:text>
                            <xsl:choose>
                              <xsl:when test="matches($desc, 'undefined', 'i')">
                                <xsl:text>[\p{Zs}\|]</xsl:text>
                              </xsl:when>
                              <xsl:when test="normalize-space($valueSpace) = ''">
                                <xsl:text>\d</xsl:text>
                              </xsl:when>
                              <xsl:when test="matches($desc, '^(Image bit depth|Data type)$', 'i')">
                                <xsl:value-of select="$valueSpace"/>
                              </xsl:when>
                              <xsl:otherwise>
                                <xsl:value-of select="replace(concat('[', replace($valueSpace, '#', '\\p{Zs}'), ']'), '\|', '\\|')"/>
                              </xsl:otherwise>
                            </xsl:choose>
                            <xsl:if test="$length &gt; 1 and not(matches($desc, '^(Image bit depth|Data type)$', 'i'))">
                              <xsl:value-of select="concat('{', $length, '}')"/>
                            </xsl:if>
                            <xsl:text>'</xsl:text>
                          </xsl:attribute>
                          <xsl:if test="$includeValueDefs != 'false'">
                          <xsl:for-each select="$group/*:line[position() &gt; 1]">
                            <valuedef>
                              <xsl:if test="matches(., '\[OBSOLETE\]')">
                                <xsl:attribute name="use">
                                  <xsl:text>obsolete</xsl:text>
                                </xsl:attribute>
                              </xsl:if>
                              <xsl:value-of select="normalize-space(replace(., '((- )?\[)?OBSOLETE\]?', ''))"/>
                            </valuedef>
                          </xsl:for-each>
                        </xsl:if>
                        </code>
                      </xsl:if>
                    </xsl:for-each>
                  </xsl:for-each-group>
                </controlfield>
                </xsl:for-each>
              </xsl:variable>
              <!-- Create generic 007 description from $pass1 -->
              <controlfield tag="007" desc="PHYSICAL DESCRIPTION FIXED FIELD--GENERAL INFORMATION" repeat="R">
                <code position="1" length="1" desc="Category of material">
                  <xsl:attribute name="values">
                    <xsl:text>'[</xsl:text>
                    <xsl:for-each select="$pass1/*:controlfield">
                      <xsl:value-of select="@materialCategory"/>
                    </xsl:for-each>
                    <xsl:text>]'</xsl:text>
                  </xsl:attribute>              
                </code>
              </controlfield>
              <!-- Save $pass1 in $processed007s -->
              <xsl:copy-of select="$pass1"/>
            </xsl:for-each>
          </xsl:variable>

          <!-- Create 008 descriptions -->
          <xsl:variable name="processed008s">
            <xsl:for-each select="$pass3/*:controlfield[matches(@tag, '008')]">
              <xsl:copy>
                <!-- First 008 has general info -->
                <xsl:copy-of select="@*"/>
                <xsl:text>&#xa;</xsl:text>
                <length>
                  <xsl:for-each
                    select="*:format[2]/*:line[matches(., '^\s+\d\d(-\d\d)? -')][last()]">
                    <xsl:variable name="length">
                      <xsl:value-of select="normalize-space(substring-before(., ' - '))"/>
                    </xsl:variable>
                    <xsl:choose>
                      <xsl:when test="matches($length, '-')">
                        <xsl:value-of select="number(substring-after($length, '-')) + 1"/>
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:value-of select="number($length) + 1"/>
                      </xsl:otherwise>
                    </xsl:choose>
                  </xsl:for-each>
                </length>
                <xsl:for-each select="*:format[2]">
                  <xsl:for-each-group select="*:line[position() &gt; 2]"
                    group-starting-with="*:line[matches(., '^\s+\d\d')]">
                    <xsl:variable name="group">
                      <xsl:copy-of select="current-group()"/>
                    </xsl:variable>
                    <xsl:for-each select="$group/*:line[1]">
                      <xsl:variable name="startEnd">
                        <xsl:value-of select="normalize-space(substring-before(., ' - '))"
                        />
                      </xsl:variable>
                      <xsl:variable name="start">
                        <xsl:choose>
                          <xsl:when test="substring-before($startEnd, '-')">
                            <xsl:value-of select="substring-before($startEnd, '-')"/>
                          </xsl:when>
                          <xsl:otherwise>
                            <xsl:value-of select="$startEnd"/>
                          </xsl:otherwise>
                        </xsl:choose>
                      </xsl:variable>
                      <xsl:variable name="end">
                        <xsl:choose>
                          <xsl:when test="substring-before($startEnd, '-')">
                            <xsl:value-of select="substring-after($startEnd, '-')"/>
                          </xsl:when>
                          <xsl:otherwise>
                            <xsl:value-of select="$startEnd"/>
                          </xsl:otherwise>
                        </xsl:choose>
                      </xsl:variable>
                      <code>
                        <xsl:variable name="position">
                          <xsl:value-of select="number($start) + 1"/>
                        </xsl:variable>
                        <xsl:attribute name="position">
                          <xsl:value-of select="$position"/>
                        </xsl:attribute>
                        <xsl:variable name="length">
                          <xsl:value-of select="(number($end) - number($start)) + 1"/>
                        </xsl:variable>
                        <xsl:attribute name="length">
                          <xsl:value-of select="$length"/>
                        </xsl:attribute>
                        <xsl:variable name="desc">
                          <xsl:value-of
                            select="normalize-space(substring-after(., ' - '))"/>
                        </xsl:variable>
                        <xsl:variable name="valueSpace">
                          <xsl:variable name="rawValues">
                            <xsl:for-each select="$group/*:line[position() &gt; 1]">
                              <value>
                                <xsl:value-of
                                  select="normalize-space(substring-before(., ' - '))"/>
                              </value>
                            </xsl:for-each>
                          </xsl:variable>
                          <xsl:for-each select="distinct-values($rawValues/*:value)">
                            <xsl:value-of select="."/>
                          </xsl:for-each>
                        </xsl:variable>
                        <xsl:attribute name="desc">
                          <xsl:value-of
                            select="replace(normalize-space($desc), '--', '&#x2014;')"/>
                        </xsl:attribute>
                        <xsl:attribute name="values">
                          <xsl:text>'</xsl:text>
                          <xsl:choose>
                            <xsl:when test="normalize-space($valueSpace) = ''">
                              <xsl:choose>
                                <xsl:when test="matches($position, '16')">
                                  <xsl:text>[a-z\p{Zs}\|]</xsl:text>
                                </xsl:when>
                                <xsl:when test="matches($position, '36')">
                                  <xsl:text>[a-z\p{Zs}\|\s]</xsl:text>
                                </xsl:when>
                                <xsl:otherwise>
                                  <xsl:text>\d</xsl:text>
                                </xsl:otherwise>
                              </xsl:choose>
                              <xsl:if
                                test="$length &gt; 1 and not(matches($desc, '^(Form of composition|Projection$|Running time)', 'i'))">
                                <xsl:value-of select="concat('{', $length, '}')"/>
                              </xsl:if>
                            </xsl:when>
                            <xsl:when test="matches($desc, 'Running time', 'i')">
                              <xsl:value-of select="$valueSpace"/>
                            </xsl:when>
                            <xsl:otherwise>
                              <xsl:value-of
                                select="replace(concat('[', replace($valueSpace, '#', '\\p{Zs}'), ']'), '\|', '\\|')"/>
                              <xsl:if
                                test="$length &gt; 1 and not(matches($desc, '^(Form of composition|Projection|Running time)', 'i'))">
                                <xsl:value-of select="concat('{', $length, '}')"/>
                              </xsl:if>
                            </xsl:otherwise>
                          </xsl:choose>
                          <xsl:text>'</xsl:text>
                        </xsl:attribute>
                        <xsl:if test="$includeValueDefs != 'false'">
                          <xsl:for-each select="$group/*:line[position() &gt; 1]">
                            <valuedef>
                              <xsl:if test="matches(., '\[OBSOLETE\]')">
                                <xsl:attribute name="use">
                                  <xsl:text>obsolete</xsl:text>
                                </xsl:attribute>
                              </xsl:if>
                              <xsl:value-of
                                select="normalize-space(replace(., '((- )?\[)?OBSOLETE\]?', ''))"
                              />
                            </valuedef>
                          </xsl:for-each>
                        </xsl:if>
                      </code>
                    </xsl:for-each>
                  </xsl:for-each-group>
                </xsl:for-each>
              </xsl:copy>
              <!-- Succeeding 008s have format-specific info -->
              <xsl:for-each select="*:format[position() &gt; 2]">
                <controlfield tag="008">
                  <xsl:variable name="desc">
                    <xsl:value-of select="normalize-space(substring-after(*:line[1], '--'))"/>
                  </xsl:variable>
                  <xsl:variable name="materialType">
                    <xsl:choose>
                      <xsl:when test="matches($desc, 'BOOKS')">BK</xsl:when>
                      <xsl:when test="matches($desc, 'COMPUTER FILES')">CF</xsl:when>
                      <xsl:when test="matches($desc, 'MAPS')">MP</xsl:when>
                      <xsl:when test="matches($desc, 'MUSIC')">MU</xsl:when>
                      <xsl:when test="matches($desc, 'CONTINUING RESOURCE')">CR</xsl:when>
                      <xsl:when test="matches($desc, 'VISUAL MATERIALS')">VM</xsl:when>
                      <xsl:when test="matches($desc, 'MIXED MATERIAL')">MX</xsl:when>
                    </xsl:choose>
                  </xsl:variable>
                  <xsl:attribute name="materialType">
                    <xsl:value-of select="$materialType"/>
                  </xsl:attribute>
                  <xsl:attribute name="desc">
                    <xsl:value-of select="replace($desc, '--', '&#x2014;')"/>
                  </xsl:attribute>
                  <xsl:for-each-group select="*:line[position() &gt; 2]" group-starting-with="*:line[matches(., '^\s+\d\d[^\d]')]">
                    <xsl:variable name="group">
                      <xsl:copy-of select="current-group()"/>
                    </xsl:variable>
                    <xsl:for-each select="$group/*:line[1]">
                      <xsl:if test="not(matches(., '\[OBSOLETE\]'))">
                        <xsl:variable name="startEnd">
                          <xsl:value-of select="normalize-space(substring-before(., ' - '))"/>
                        </xsl:variable>
                        <xsl:variable name="start">
                          <xsl:choose>
                            <xsl:when test="substring-before($startEnd, '-')">
                              <xsl:value-of select="substring-before($startEnd, '-')"/>
                            </xsl:when>
                            <xsl:otherwise>
                              <xsl:value-of select="$startEnd"/>
                            </xsl:otherwise>
                          </xsl:choose>
                        </xsl:variable>
                        <xsl:variable name="end">
                          <xsl:choose>
                            <xsl:when test="substring-before($startEnd, '-')">
                              <xsl:value-of select="substring-after($startEnd, '-')"/>
                            </xsl:when>
                            <xsl:otherwise>
                              <xsl:value-of select="$startEnd"/>
                            </xsl:otherwise>
                          </xsl:choose>
                        </xsl:variable>
                        <code>
                          <xsl:variable name="position">
                            <xsl:value-of select="number($start) + 1"/>
                          </xsl:variable>
                          <xsl:attribute name="position">
                            <xsl:value-of select="$position"/>
                          </xsl:attribute>
                          <xsl:variable name="length">
                            <xsl:value-of select="(number($end) - number($start)) + 1"/>
                          </xsl:variable>
                          <xsl:attribute name="length">
                            <xsl:value-of select="$length"/>
                          </xsl:attribute>
                          <xsl:variable name="desc">
                            <xsl:value-of select="normalize-space(substring-after(., ' - '))"/>
                          </xsl:variable>
                          <xsl:variable name="valueSpace">
                            <xsl:variable name="rawValues">
                              <xsl:for-each select="$group/*:line[position() &gt; 1]">
                                <value>
                                  <xsl:value-of select="normalize-space(substring-before(., ' - '))"/>
                                </value>
                              </xsl:for-each>
                            </xsl:variable>
                            <xsl:choose>
                              <xsl:when test="matches($desc, '^(Form of composition|Projection)$')">
                                <xsl:text>(</xsl:text>
                                <xsl:for-each select="distinct-values($rawValues/*:value)">
                                  <xsl:value-of select="replace(replace(., '\|', '\\|'), '#', '\\p{Zs}')"/>
                                  <xsl:if test="position() != last()">
                                    <xsl:text>|</xsl:text>
                                  </xsl:if>
                                </xsl:for-each>
                                <!-- Compensate for missing pipe char in documentation -->
                                <xsl:if test="matches($desc, '^(Projection)$')">
                                  <xsl:text>\|</xsl:text>
                                </xsl:if>
                                <xsl:text>)</xsl:text>
                              </xsl:when>
                              <!-- Space and pipe values are legal but aren't provided in the documentation, so
                                they're added here --> 
                              <xsl:when test="matches($materialType, 'CF') and matches($desc, '^Form of item')">
                                <xsl:for-each select="distinct-values($rawValues/*:value)">
                                  <xsl:value-of select="."/>
                                </xsl:for-each>
                                <xsl:text>\p{Zs}|</xsl:text>
                              </xsl:when>
                              <xsl:when test="matches($desc, 'Running time', 'i')">
                                <xsl:text>(</xsl:text>
                                <xsl:for-each select="distinct-values($rawValues/*:value)">
                                  <xsl:value-of select="replace(replace(replace(., '\|', '\\|'), '#', '\\p{Zs}'), '001-999', '00[1-9]|0[1-9][0-9]|[1-9][0-9][0-9]')"/>
                                  <xsl:if test="position() != last()">
                                    <xsl:text>|</xsl:text>
                                  </xsl:if>
                                </xsl:for-each>
                                <xsl:text>)</xsl:text>
                              </xsl:when>
                              <xsl:otherwise>
                                <xsl:for-each select="distinct-values($rawValues/*:value)">
                                  <xsl:value-of select="."/>
                                </xsl:for-each>
                              </xsl:otherwise>
                            </xsl:choose>
                          </xsl:variable>
                          <xsl:attribute name="desc">
                            <xsl:value-of select="replace(normalize-space($desc), '--', '&#x2014;')"/>
                          </xsl:attribute>
                          <xsl:attribute name="values">
                            <xsl:text>'</xsl:text>
                            <xsl:choose>
                              <xsl:when test="matches($desc, 'undefined', 'i')">
                                <xsl:text>[\p{Zs}\|]</xsl:text>
                              </xsl:when>
                              <xsl:when test="normalize-space($valueSpace) = ''">
                                <xsl:text>\d</xsl:text>
                              </xsl:when>
                              <xsl:when test="matches($desc, '^(Form of composition|Projection|Running time)', 'i')">
                                <xsl:value-of select="$valueSpace"/>
                              </xsl:when>
                              <xsl:otherwise>
                                <xsl:value-of select="replace(concat('[', replace($valueSpace, '#', '\\p{Zs}'), ']'), '\|', '\\|')"/>
                              </xsl:otherwise>
                            </xsl:choose>
                            <xsl:if test="$length &gt; 1 and not(matches($desc, '^(Form of composition|Projection|Running time)', 'i'))">
                              <xsl:value-of select="concat('{', $length, '}')"/>
                            </xsl:if>
                            <xsl:text>'</xsl:text>
                          </xsl:attribute>
                          <xsl:if test="$includeValueDefs != 'false'">
                            <xsl:for-each select="$group/*:line[position() &gt; 1]">
                              <valuedef>
                                <xsl:if test="matches(., '\[OBSOLETE\]')">
                                  <xsl:attribute name="use">
                                    <xsl:text>obsolete</xsl:text>
                                  </xsl:attribute>
                                </xsl:if>
                                <xsl:value-of select="normalize-space(replace(., '((- )?\[)?OBSOLETE\]?', ''))"/>
                              </valuedef>
                            </xsl:for-each>
                          </xsl:if>
                        </code>
                      </xsl:if>
                    </xsl:for-each>
                  </xsl:for-each-group>
                </controlfield>
              </xsl:for-each>
            </xsl:for-each>
          </xsl:variable>

          <!-- Use $processed008s info to generate 006 descriptions -->
          <xsl:for-each select="$processed008s/*:controlfield[position() &gt; 1]">
            <controlfield tag="006">
              <xsl:copy-of select="@materialType, @desc"/>
              <xsl:for-each select="*:code">
                <xsl:copy>
                  <xsl:attribute name="position">
                    <xsl:value-of select="@position - 17"/>
                  </xsl:attribute>
                  <xsl:copy-of select="@length, @desc, @values"/>
                  <xsl:if test="$includeValueDefs != 'false'">
                    <xsl:for-each select="*:valuedef">
                      <xsl:copy-of select="."/>
                    </xsl:for-each>
                  </xsl:if>
                </xsl:copy>
              </xsl:for-each>
            </controlfield>
          </xsl:for-each>

          <!-- Output 007 and 008 descriptions -->
          <xsl:copy-of select="$processed007s"/>
          <xsl:copy-of select="$processed008s"/>

          <!-- 009 is currently marked as obsolete -->
          <xsl:for-each select="$pass3/*:controlfield[@tag = '009']">
            <xsl:if
              test="(not(matches(@desc, '\[OBSOLETE\]'))) or (matches(@desc, '\[OBSOLETE\]') and $includeObsoleteFields = 'true')">
              <xsl:copy>
                <xsl:copy-of select="@tag"/>
                <xsl:if test="matches(@desc, '\[OBSOLETE\]')">
                  <xsl:attribute name="use">
                    <xsl:text>obsolete</xsl:text>
                  </xsl:attribute>
                </xsl:if>
                <xsl:copy-of select="@repeat"/>
                <xsl:attribute name="desc">
                  <xsl:value-of
                    select="replace(normalize-space(replace(@desc, '((- )?\[)?OBSOLETE\]?', '')), '--', '&#x2014;')"
                  />
                </xsl:attribute>
              </xsl:copy>
            </xsl:if>
          </xsl:for-each>

          <xsl:comment>&#32;Data fields&#32;</xsl:comment>
          <xsl:for-each select="$pass3/*:datafield[not(matches(@tag, '880|886'))]">
            <xsl:sort select="number(@tag)"/>
            <!-- Datafields marked as obsolete are skipped unless $includeObsoleteFields = 'true' -->
            <xsl:if
              test="(not(matches(@desc, '\[OBSOLETE\]'))) or (matches(@desc, '\[OBSOLETE\]') and $includeObsoleteFields = 'true')">
              <xsl:copy>
                <!-- Reorder attributes for better readability -->
                <xsl:copy-of select="@tag"/>
                <xsl:if test="matches(@desc, '\[OBSOLETE\]')">
                  <xsl:attribute name="use">
                    <xsl:text>obsolete</xsl:text>
                  </xsl:attribute>
                </xsl:if>
                <xsl:copy-of select="@repeat"/>
                <xsl:attribute name="desc">
                  <xsl:value-of
                    select="replace(normalize-space(replace(@desc, '((- )?\[)?OBSOLETE\]?', '')), '--', '&#x2014;')"
                  />
                </xsl:attribute>
                <xsl:for-each select="*:ind1">
                  <ind1>
                    <xsl:attribute name="values">
                      <xsl:variable name="rawValues">
                        <xsl:for-each select="*:line[position() &gt; 1]">
                          <value>
                            <xsl:value-of
                              select="replace(replace(substring-before(normalize-space(.), ' - '), '#', ' '), '\s+', ' ')"
                            />
                          </value>
                        </xsl:for-each>
                      </xsl:variable>
                      <xsl:for-each select="distinct-values($rawValues/*:value)">
                        <xsl:value-of select="."/>
                      </xsl:for-each>
                    </xsl:attribute>
                    <xsl:attribute name="desc">
                      <xsl:value-of
                        select="replace(substring-after(normalize-space(*:line[1]), ' - '), '--', '&#x2014;')"
                      />
                    </xsl:attribute>
                    <xsl:if test="not(matches(*:line[1], 'Undefined', 'i'))">
                      <xsl:for-each select="*:line[position() &gt; 1]">
                        <xsl:if test="$includeValueDefs != 'false'">
                          <valuedef>
                            <xsl:attribute name="token">
                              <xsl:value-of
                                select="replace(replace(substring-before(normalize-space(.), ' - '), '#', ' '), ' +', ' ')"
                              />
                            </xsl:attribute>
                            <xsl:if test="matches(., 'OBSOLETE')">
                              <xsl:attribute name="use">
                                <xsl:text>obsolete</xsl:text>
                              </xsl:attribute>
                            </xsl:if>
                            <xsl:attribute name="desc">
                              <xsl:value-of
                                select="replace(substring-after(normalize-space(replace(., '\[?OBSOLETE\]?', '')), ' - '), '--', '&#x2014;')"
                              />
                            </xsl:attribute>
                          </valuedef>
                        </xsl:if>
                      </xsl:for-each>
                    </xsl:if>
                  </ind1>
                </xsl:for-each>
                <xsl:for-each select="*:ind2">
                  <ind2>
                    <xsl:attribute name="values">
                      <xsl:variable name="rawValues">
                        <xsl:for-each select="*:line[position() &gt; 1]">
                          <value>
                            <xsl:value-of
                              select="replace(replace(substring-before(normalize-space(.), ' - '), '#', ' '), '\s+', ' ')"
                            />
                          </value>
                        </xsl:for-each>
                      </xsl:variable>
                      <xsl:for-each select="distinct-values($rawValues/*:value)">
                        <xsl:value-of select="."/>
                      </xsl:for-each>
                    </xsl:attribute>
                    <xsl:attribute name="desc">
                      <xsl:value-of
                        select="replace(substring-after(normalize-space(*:line[1]), ' - '), '--', '&#x2014;')"
                      />
                    </xsl:attribute>
                    <xsl:if test="not(matches(*:line[1], 'Undefined', 'i'))">
                      <xsl:for-each select="*:line[position() &gt; 1]">
                        <xsl:if test="$includeValueDefs != 'false'">
                          <valuedef>
                            <xsl:attribute name="token">
                              <xsl:value-of
                                select="replace(replace(substring-before(normalize-space(.), ' - '), '#', ' '), ' +', ' ')"
                              />
                            </xsl:attribute>
                            <xsl:if test="matches(., 'OBSOLETE')">
                              <xsl:attribute name="use">
                                <xsl:text>obsolete</xsl:text>
                              </xsl:attribute>
                            </xsl:if>
                            <xsl:attribute name="desc">
                              <xsl:value-of
                                select="replace(substring-after(normalize-space(replace(., '\[?OBSOLETE\]?', '')), ' - '), '--', '&#x2014;')"
                              />
                            </xsl:attribute>
                          </valuedef>
                        </xsl:if>
                      </xsl:for-each>
                    </xsl:if>
                  </ind2>
                </xsl:for-each>
                <xsl:for-each select="*:subfields">
                  <!-- For each line in <subfields> not marked with '[REDEFINED]', create <subfield> element -->
                  <xsl:for-each
                    select="*:line[matches(., '^ +\$')][not(matches(., '\[REDEFINED\]'))]">
                    <subfield>
                    <xsl:attribute name="code">
                      <xsl:value-of select="replace(substring-before(normalize-space(.), ' - '), '\$', '')"/>
                    </xsl:attribute>
                    <xsl:if test="matches(., 'OBSOLETE')">
                      <xsl:attribute name="use">
                        <xsl:text>obsolete</xsl:text>
                      </xsl:attribute>
                    </xsl:if>
                    <xsl:attribute name="repeat">
                      <xsl:choose>
                        <xsl:when test="matches(., '\(NR\)')">
                          <xsl:text>NR</xsl:text>
                        </xsl:when>
                        <xsl:otherwise>
                          <xsl:text>R</xsl:text>
                        </xsl:otherwise>
                      </xsl:choose>
                    </xsl:attribute>
                    <xsl:attribute name="desc">
                      <xsl:value-of select="replace(replace(substring-after(normalize-space(replace(., '\[?OBSOLETE\]?', '')), ' - '), ' +\(N?R\)', ''), '--', '&#x2014;')"/>
                    </xsl:attribute>                  
                  </subfield>
                  </xsl:for-each>
                </xsl:for-each>
              </xsl:copy>
            </xsl:if>
          </xsl:for-each>

          <!-- 880 is special; hard-code its subfields -->
          <xsl:for-each select="$pass3/*:datafield[@tag = '880']">
            <xsl:if
              test="(not(matches(@desc, '\[OBSOLETE\]'))) or (matches(@desc, '\[OBSOLETE\]') and $includeObsoleteFields = 'true')">
              <xsl:copy>
                <xsl:copy-of select="@*"/>
                <ind1 values=" 0-9" desc="Same as associated field"/>
                <ind2 values=" 0-9" desc="Same as associated field"/>
                <subfield code="a-z" repeat="R" desc="Same as associated field"/>
                <subfield code="0-5" repeat="R" desc="Same as associated field"/>
                <subfield code="6" repeat="NR" desc="Linkage"/>
                <subfield code="7-9" repeat="R" desc="Same as associated field"/>
              </xsl:copy>
            </xsl:if>
          </xsl:for-each>

          <!-- 886 is special; hard-code its subfields -->
          <xsl:for-each select="$pass3/*:datafield[@tag = '886']">
            <xsl:if
              test="(not(matches(@desc, '\[OBSOLETE\]'))) or (matches(@desc, '\[OBSOLETE\]') and $includeObsoleteFields = 'true')">
              <xsl:copy>
                <xsl:copy-of select="@*"/>
                <ind1 values="012" desc="Type of field">
                  <xsl:if test="$includeValueDefs != 'false'">
                    <valuedef token="0" desc="Leader"/>
                    <valuedef token="1" desc="Variable control fields (002-009)"/>
                    <valuedef token="2" desc="Variable data fields (010-999)"/>
                  </xsl:if>
                </ind1>
                <ind2 values=" " desc="Undefined"/>
                <subfield code="a-z" repeat="R" desc="Tag/content of the foreign MARC field"/>
                <subfield code="0-9" repeat="R" desc="Foreign MARC subfield"/>
              </xsl:copy>
            </xsl:if>
          </xsl:for-each>

          <xsl:if test="$includeLocalFields = 'true'">
            <xsl:copy-of select="$localFields"/>
          </xsl:if>

          <xsl:if test="$includeUvaFields = 'true'">
            <xsl:copy-of select="$uvaFields"/>
          </xsl:if>
        </xsl:variable>

        <!-- Output result of the final pass -->
        <xsl:comment>
          <xsl:value-of select="$topComment"/>
        </xsl:comment>

        <marcDesc xmlns:sch="http://purl.oclc.org/dsdl/schematron"
          xmlns:sqf="http://www.schematron-quickfix.com/validator/process"
          xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
          <xsl:copy-of select="$pass4/*:leader, $pass4/*:controlfield"/>
          <xsl:for-each select="$pass4/*:datafield">
            <xsl:sort select="number(@tag)"/>
            <xsl:copy-of select="."/>
          </xsl:for-each>
        </marcDesc>

      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="error">
          <xsl:text>Error reading "</xsl:text>
          <xsl:value-of select="$text-uri"/>
          <xsl:text>".</xsl:text>
        </xsl:variable>
        <xsl:message>
          <xsl:value-of select="$error"/>
        </xsl:message>
        <xsl:value-of select="$error"/>
      </xsl:otherwise>
    </xsl:choose>

  </xsl:template>
</xsl:stylesheet>
