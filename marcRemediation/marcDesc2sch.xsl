<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://purl.oclc.org/dsdl/schematron"
  xmlns:sch="http://purl.oclc.org/dsdl/schematron"
  xmlns:sqf="http://www.schematron-quickfix.com/validator/process"
  xmlns:xi="http://www.w3.org/2001/XInclude"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs sch"
  version="2.0" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:axsl="output">

  <!--
     This stylesheet reads marcDesc.xml, an XML description of the MARC format based
     on https://www.loc.gov/marc/bibliographic/ecbdlist.html, and creates a Schematron
     schema that can be used to enforce occurrence, repeatability, and value restrictions
     on MarcXML files.  It relies on mandatorySubfields.xml being in the same directory
     as this stylesheet.
  -->

  <xsl:namespace-alias stylesheet-prefix="axsl" result-prefix="xsl"/>

  <xsl:output method="xml" indent="yes"/>
  <xsl:strip-space elements="*"/>

  <!-- ======================================================================= -->
  <!-- PARAMETERS                                                              -->
  <!-- ======================================================================= -->

  <!-- Controls level of country code checking -->
  <xsl:param name="countryCodeCheck" select="'strict'"/>

  <!-- Controls level of language code checking -->
  <xsl:param name="languageCodeCheck" select="'strict'"/>

  <!-- Controls inclusion of warnings/recommendations -->
  <xsl:param name="warnOthers" select="'true'"/>

  <!-- Controls whether warnings are issued re: undefined fields -->
  <xsl:param name="warnUndefinedFields" select="'true'"/>

  <!-- Controls whether warnings are issued re: obsolete fields -->
  <xsl:param name="warnObsoleteFields" select="'true'"/>

  <!-- Relator codes from vocabularies other than MARC;
    e.g., 'foo|bar|bee' -->
  <xsl:param name="non-marcRelatorCodes" select="''"/>

  <!-- Relator terms from vocabularies other than MARC;
    e.g., 'butcher|baker|candlestick maker' -->
  <xsl:param name="non-marcRelatorTerms" select="''"/>

  <!-- ======================================================================= -->
  <!-- GLOBAL VARIABLES                                                        -->
  <!-- ======================================================================= -->

  <xsl:variable name="progName">marcDesc2sch.xsl</xsl:variable>
  <xsl:variable name="progVersion">v. 1.0</xsl:variable>

  <!-- MARC language codes currently in use -->
  <xsl:variable name="currentMarcLangCodes">
    <xsl:text>aar|abk|ace|ach|ada|ady|afa|afh|afr|ain|aka|akk|alb|ale|alg|alt|amh|ang|anp|apa|ara|arc|arg|arm|arn|arp|art|arw|asm|ast|ath|aus|ava|ave|awa|aym|aze|bad|bai|bak|bal|bam|ban|baq|bas|bat|bej|bel|bem|ben|ber|bho|bih|bik|bin|bis|bla|bnt|bos|bra|bre|btk|bua|bug|bul|bur|byn|cad|cai|car|cat|cau|ceb|cel|cha|chb|che|chg|chi|chk|chm|chn|cho|chp|chr|chu|chv|chy|cmc|cnr|cop|cor|cos|cpe|cpf|cpp|cre|crh|crp|csb|cus|cze|dak|dan|dar|day|del|den|dgr|din|div|doi|dra|dsb|dua|dum|dut|dyu|dzo|efi|egy|eka|elx|eng|enm|epo|est|ewe|ewo|fan|fao|fat|fij|fil|fin|fiu|fon|fre|frm|fro|frr|frs|fry|ful|fur|gaa|gay|gba|gem|geo|ger|gez|gil|gla|gle|glg|glv|gmh|goh|gon|gor|got|grb|grc|gre|grn|gsw|guj|gwi|hai|hat|hau|haw|heb|her|hil|him|hin|hit|hmn|hmo|hrv|hsb|hun|hup|iba|ibo|ice|ido|iii|ijo|iku|ile|ilo|ina|inc|ind|ine|inh|ipk|ira|iro|ita|jav|jbo|jpn|jpr|jrb|kaa|kab|kac|kal|kam|kan|kar|kas|kau|kaw|kaz|kbd|kha|khi|khm|kho|kik|kin|kir|kmb|kok|kom|kon|kor|kos|kpe|krc|krl|kro|kru|kua|kum|kur|kut|lad|lah|lam|lao|lat|lav|lez|lim|lin|lit|lol|loz|ltz|lua|lub|lug|lui|lun|luo|lus|mac|mad|mag|mah|mai|mak|mal|man|mao|map|mar|mas|may|mdf|mdr|men|mga|mic|min|mis|mkh|mlg|mlt|mnc|mni|mno|moh|mon|mos|mul|mun|mus|mwl|mwr|myn|myv|nah|nai|nap|nau|nav|nbl|nde|ndo|nds|nep|new|nia|nic|niu|nno|nob|nog|non|nor|nqo|nso|nub|nwc|nya|nym|nyn|nyo|nzi|oci|oji|ori|orm|osa|oss|ota|oto|paa|pag|pal|pam|pan|pap|pau|peo|per|phi|phn|pli|pol|pon|por|pra|pro|pus|que|raj|rap|rar|roa|roh|rom|rum|run|rup|rus|sad|sag|sah|sai|sal|sam|san|sas|sat|scn|sco|sel|sem|sga|sgn|shn|sid|sin|sio|sit|sla|slo|slv|sma|sme|smi|smj|smn|smo|sms|sna|snd|snk|sog|som|son|sot|spa|srd|srn|srp|srr|ssa|ssw|suk|sun|sus|sux|swa|swe|syc|syr|tah|tai|tam|tat|tel|tem|ter|tet|tgk|tgl|tha|tib|tig|tir|tiv|tkl|tlh|tli|tmh|tog|ton|tpi|tsi|tsn|tso|tuk|tum|tup|tur|tut|tvl|twi|tyv|udm|uga|uig|ukr|umb|und|urd|uzb|vai|ven|vie|vol|vot|wak|wal|war|was|wel|wen|wln|wol|xal|xho|yao|yap|yid|yor|ypk|zap|zbl|zen|zha|znd|zul|zun|zxx|zza</xsl:text>
  </xsl:variable>

  <!-- Deprecated MARC language codes -->
  <xsl:variable name="obsoleteMarcLangCodes">
    <xsl:text>ajm|cam|esk|esp|eth|far|fri|gae|gag|gal|gua|int|iri|kus|lan|lap|max|mla|mol|sao|scc|scr|sho|snh|sso|swz|tag|taj|tar|tru|tsw</xsl:text>
  </xsl:variable>

  <xsl:variable name="marcLangCodesStrict">
    <xsl:value-of
      select="concat(&quot;&apos;^(&quot;, $currentMarcLangCodes, &quot;)$&apos;&quot;)"/>
  </xsl:variable>

  <!-- Union of current and deprecated MARC language codes -->
  <xsl:variable name="marcLangCodesLoose">
    <xsl:value-of
      select="concat(&quot;&apos;^(&quot;, $currentMarcLangCodes, &quot;|&quot;, $obsoleteMarcLangCodes, &quot;|\p{Zs}{3}|\\{3}|\|{3})$&apos;&quot;)"
    />
  </xsl:variable>

  <!-- $marcLangCodes depends on the value of $languageCodeCheck -->
  <xsl:variable name="marcLangCodes">
    <xsl:choose>
      <xsl:when test="$languageCodeCheck = 'strict'">
        <xsl:value-of select="$marcLangCodesStrict"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$marcLangCodesLoose"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:variable name="currentMarcCountryCodes">
    <xsl:text>aa |abc|aca|ae |af |ag |ai |aj |aku|alu|am |an |ao |aq |aru|as |at |au |aw |ay |azu|ba |bb |bcc|bd |be |bf |bg |bh |bi |bl |bm |bn |bo |bp |br |bs |bt |bu |bv |bw |bx |ca |cau|cb |cc |cd |ce |cf |cg |ch |ci |cj |ck |cl |cm |co |cou|cq |cr |ctu|cu |cv |cw |cx |cy |dcu|deu|dk |dm |dq |dr |ea |ec |eg |em |enk|er |es |et |fa |fg |fi |fj |fk |flu|fm |fp |fr |fs |ft |gau|gb |gd |gg |gh |gi |gl |gm |go |gp |gr |gs |gt |gu |gv |gw |gy |gz |hiu|hm |ho |ht |hu |iau|ic |idu|ie |ii |ilu|im |inu|io |iq |ir |is |it |iv |iy |ja |je |ji |jm |jo |ke |kg |kn |ko |ksu|ku |kv |kyu|kz |lau|lb |le |lh |li |lo |ls |lu |lv |ly |mau|mbc|mc |mdu|meu|mf |mg |miu|mj |mk |ml |mm |mnu|mo |mou|mp |mq |mr |msu|mtu|mu |mv |mw |mx |my |mz |nbu|ncu|ndu|ne |nfc|ng |nhu|nik|nju|nkc|nl |nmu|nn |no |np |nq |nr |nsc|ntc|nu |nuc|nvu|nw |nx |nyu|nz |ohu|oku|onc|oru|ot |pau|pc |pe |pf |pg |ph |pic|pk |pl |pn |po |pp |pr |pw |py |qa |qea|quc|rb |re |rh |riu|rm |ru |rw |sa |sc |scu|sd |sdu|se |sf |sg |sh |si |sj |sl |sm |sn |snc|so |sp |sq |sr |ss |st |stk|su |sw |sx |sy |sz |ta |tc |tg |th |ti |tk |tl |tma|tnu|to |tr |ts |tu |tv |txu|tz |ua |uc |ug |un |up |utu|uv |uy |uz |vau|vb |vc |ve |vi |vm |vp |vra|vtu|wau|wea|wf |wiu|wj |wk |wlk|ws |wvu|wyu|xa |xb |xc |xd |xe |xf |xga|xh |xj |xk |xl |xm |xn |xna|xo |xoa|xp |xr |xra|xs |xv |xx |xxc|xxk|xxu|ye |ykc|za </xsl:text>
  </xsl:variable>

  <xsl:variable name="obsoleteMarcCountryCodes">
    <xsl:text>ac |ai |air|ajr|bwr|cn |cp |cs |cz |err|ge |gn |gsr|hk |iu |iw |jn |kgr|kzr|lir|ln |lvr|mh |mvr|na |nm |pt |rur|ry |sb |sk |sv |tar|tkr|tt |ui |uik|uk |unr|ur |us |uzr|vn |vs |wb |xi |xxr|ys |yu </xsl:text>
  </xsl:variable>

  <xsl:variable name="marcCountryCodesStrict">
    <xsl:value-of
      select="concat(&quot;&apos;^(&quot;, $currentMarcCountryCodes, &quot;)$&apos;&quot;)"
    />
  </xsl:variable>

  <!-- Union of current and deprecated MARC country codes -->
  <xsl:variable name="marcCountryCodesLoose">
    <xsl:value-of
      select="concat(&quot;&apos;^(&quot;, $currentMarcCountryCodes, &quot;|&quot;, $obsoleteMarcCountryCodes, &quot;|\p{Zs}{3}|\\{3}|\|{3})$&apos;&quot;)"
    />
  </xsl:variable>

  <!-- $marcCountryCodes depends on $languageCodeCheck -->
  <xsl:variable name="marcCountryCodes">
    <xsl:choose>
      <xsl:when test="$countryCodeCheck = 'strict'">
        <xsl:value-of select="$marcCountryCodesStrict"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$marcCountryCodesLoose"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <!-- MARC relator codes -->
  <xsl:variable name="marcRelatorCodes">
    <text>abr|acp|act|adi|adp|aft|anc|anl|anm|ann|ant|ape|apl|app|aqt|arc|ard|arr|art|asg|asn|ato|att|auc|aud|aue|aui|aup|aus|aut|bdd|bjd|bka|bkd|bkp|blw|bnd|bpd|brd|brl|bsl|cad|cas|ccp|chr|clb|cli|cll|clr|clt|cmm|cmp|cmt|cnd|cng|cns|coe|col|com|con|cop|cor|cos|cot|cou|cov|cpc|cpe|cph|cpl|cpt|cre|crp|crr|crt|csl|csp|cst|ctb|cte|ctg|ctr|cts|ctt|cur|cwt|dbd|dbp|dfd|dfe|dft|dgc|dgg|dgs|dis|djo|dln|dnc|dnr|dpc|dpt|drm|drt|dsr|dst|dtc|dte|dtm|dto|dub|edc|edd|edm|edt|egr|elg|elt|eng|enj|etr|evp|exp|fac|fds|fld|flm|fmd|fmk|fmo|fmp|fnd|fon|fpy|frg|gis|grt|his|hnr|hst|ill|ilu|ins|inv|isb|itr|ive|ivr|jud|jug|lbr|lbt|ldr|led|lee|lel|len|let|lgd|lie|lil|lit|lsa|lse|lso|ltg|lyr|mcp|mdc|med|mfp|mfr|mka|mod|mon|mrb|mrk|msd|mte|mtk|mup|mus|mxe|nan|nrt|onp|opn|org|orm|osp|oth|own|pad|pan|pat|pbd|pbl|pdr|pfr|pht|plt|pma|pmn|pop|ppm|ppt|pra|prc|prd|pre|prf|prg|prm|prn|pro|prp|prs|prt|prv|pta|pte|ptf|pth|ptt|pup|rap|rbr|rcd|rce|rcp|rdd|red|ren|res|rev|rpc|rps|rpt|rpy|rse|rsg|rsp|rsr|rst|rth|rtm|rxa|sad|sce|scl|scr|sde|sds|sec|sfx|sgd|sgn|sht|sll|sng|spk|spn|spy|srv|std|stg|stl|stm|stn|str|swd|tau|tcd|tch|ths|tld|tlg|tlh|tlp|trc|trl|tyd|tyg|uvp|vac|vdg|vfx|voc|wac|wal|wam|wat|wdc|wde|win|wit|wpr</text>
  </xsl:variable>

  <!-- MARC relator terms -->
  <xsl:variable name="marcRelatorTerms"
    select="'^(Abridger|Art copyist|Actor|Art director|Adapter|Author of afterword, colophon, etc.|Announcer|Analyst|Animator|Annotator|Bibliographic antecedent|Appellee|Appellant|Applicant|Author in quotations or text abstracts|Architect|Artistic director|Arranger|Artist|Assignee|Associated name|Autographer|Attributed name|Auctioneer|Author of dialog|Audio engineer|Author of introduction, etc.|Audio producer|Screenwriter|Author|Binding designer|Bookjacket designer|Book artist|Book designer|Book producer|Blurb writer|Binder|Bookplate designer|Broadcaster|Braille embosser|Bookseller|Casting director|Caster|Conceptor|Choreographer|Collaborator|Client|Calligrapher|Colorist|Collotyper|Commentator|Composer|Compositor|Conductor|Cinematographer|Censor|Contestant-appellee|Collector|Compiler|Conservator|Camera operator|Collection registrar|Contestant|Contestant-appellant|Court governed|Cover designer|Copyright claimant|Complainant-appellee|Copyright holder|Complainant|Complainant-appellant|Creator|Correspondent|Corrector|Court reporter|Consultant|Consultant to a project|Costume designer|Contributor|Contestee-appellee|Cartographer|Contractor|Contestee|Contestee-appellant|Curator|Commentator for written text|Dubbing director|Distribution place|Defendant|Defendant-appellee|Defendant-appellant|Degree committee member|Degree granting institution|Degree supervisor|Dissertant|DJ|Delineator|Dancer|Donor|Depicted|Depositor|Draftsman|Director|Designer|Distributor|Data contributor|Dedicatee|Data manager|Dedicator|Dubious author|Editor of compilation|Editorial director|Editor of moving image work|Editor|Engraver|Electrician|Electrotyper|Engineer|Enacting jurisdiction|Etcher|Event place|Expert|Facsimilist|Film distributor|Field director|Film editor|Film director|Filmmaker|Former owner|Film producer|Funder|Founder|First party|Forger|Geographic information specialist|Graphic technician|Host institution|Honoree|Host|Illustrator|Illuminator|Inscriber|Inventor|Issuing body|Instrumentalist|Interviewee|Interviewer|Judge|Jurisdiction governed|Laboratory|Librettist|Laboratory director|Lead|Libelee-appellee|Libelee|Lender|Libelee-appellant|Lighting designer|Libelant-appellee|Libelant|Libelant-appellant|Landscape architect|Licensee|Licensor|Lithographer|Lyricist|Music copyist|Metadata contact|Medium|Manufacture place|Manufacturer|Makeup artist|Moderator|Monitor|Marbler|Markup editor|Musical director|Metal-engraver|Minute taker|Music programmer|Musician|Mixing engineer|News anchor|Narrator|Onscreen participant|Opponent|Originator|Organizer|Onscreen presenter|Other|Owner|Place of address|Panelist|Patron|Publishing director|Publisher|Project director|Proofreader|Photographer|Platemaker|Permitting agency|Production manager|Printer of plates|Papermaker|Puppeteer|Praeses|Process contact|Production personnel|Presenter|Performer|Programmer|Printmaker|Production company|Producer|Production place|Production designer|Printer|Provider|Patent applicant|Plaintiff-appellee|Plaintiff|Patent holder|Plaintiff-appellant|Publication place|Rapporteur|Rubricator|Recordist|Recording engineer|Addressee|Radio director|Redaktor|Renderer|Researcher|Reviewer|Radio producer|Repository|Reporter|Responsible party|Respondent-appellee|Restager|Respondent|Restorationist|Respondent-appellant|Research team head|Research team member|Remix artist|Scientific advisor|Scenarist|Sculptor|Scribe|Sound engineer|Sound designer|Secretary|Special effects provider|Stage director|Signer|Supporting host|Seller|Singer|Speaker|Sponsor|Second party|Surveyor|Set designer|Setting|Storyteller|Stage manager|Standards body|Stereotyper|Software developer|Television writer|Technical director|Teacher|Thesis advisor|Television director|Television guest|Television host|Television producer|Transcriber|Translator|Type designer|Typographer|University place|Voice actor|Videographer|Visual effects provider|Vocalist|Writer of added commentary|Writer of added lyrics|Writer of accompanying material|Writer of added text|Woodcutter|Wood engraver|Writer of introduction|Witness|Writer of preface|Writer of supplementary textual content)$'"/>

  <!-- Union of MARC and non-MARC relator codes -->
  <xsl:variable name="relatorCodes">
    <xsl:choose>
      <xsl:when test="$non-marcRelatorCodes != ''">
        <xsl:value-of
          select="concat(&quot;&apos;^(&quot;, string-join(($marcRelatorCodes, $non-marcRelatorCodes), '|'), &quot;)$&apos;&quot;)"
        />
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of
          select="concat(&quot;&apos;^(&quot;, $marcRelatorCodes, &quot;)$&apos;&quot;)"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <!-- Union of MARC and non-MARC relator codes  -->
  <xsl:variable name="relatorTerms">
    <xsl:choose>
      <xsl:when test="$non-marcRelatorTerms != ''">
        <xsl:value-of
          select="concat(&quot;&apos;^(&quot;, string-join(($marcRelatorTerms, $non-marcRelatorTerms), '|'), &quot;)$&apos;&quot;)"
        />
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of
          select="concat(&quot;&apos;^(&quot;, $marcRelatorTerms, &quot;)$&apos;&quot;)"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <!-- Record identifier; that is, the 001 -->
  <xsl:variable name="createRecord001Variable">
    <let name="record001">
      <xsl:attribute name="value">
        <xsl:text>ancestor::*:record/*:controlfield[@tag = '001']</xsl:text>
      </xsl:attribute>
    </let>
  </xsl:variable>

  <!-- Label boilerplate -->
  <xsl:variable name="useRecord001Variable">
    <value-of>
      <xsl:attribute name="select">
        <xsl:text>concat($record001, ' :: ')</xsl:text>
      </xsl:attribute>
    </value-of>
  </xsl:variable>

  <!-- The following variables hold Schematron constraints that can't be derived from the MARC spec. -->
  <xsl:variable name="linkingSubfieldConstraints">
    <pattern>
      <title>Subfield 6 (value pattern)</title>
      <rule context="*:subfield[@code = '6']">
        <let name="record001" value="ancestor::*:record/*:controlfield[@tag = '001']"/>
        <assert
          test="matches(., '^\d{{3}}-\d{{2}}(/(\([BNS23]|\$1|\d{{3}}|[A-Za-z]{{4}})(/r)?)?$')"
          role="error"><value-of select="concat($record001, ' :: ')"/>
          <value-of select="concat('Datafield ', ../@tag)"/> subfield ǂ6 must match regex:
          '^\d{3}-\d{2}(/(\([BNS23]|\$1|\d{3}|[A-Za-z]{4})(/r)?)?$'.</assert>
      </rule>
    </pattern>
    <pattern>
      <title>Subfield 8 (value pattern)</title>
      <rule context="*:subfield[@code = '8']">
        <let name="record001" value="ancestor::*:record/*:controlfield[@tag = '001']"/>
        <!-- Value -->
        <assert test="matches(., '^[0-9]+(\.[0-9]+)?(\\[apux])?$')" role="error">
          <value-of select="concat($record001, ' :: ')"/><value-of
            select="concat('Datafield ', ../@tag)"/> subfield ǂ8 must match regex:
          '^[0-9]+(\.[0-9]+)?(\\[apux])?$'.</assert>
      </rule>
    </pattern>
    <xsl:if test="$warnOthers = 'true'">
      <pattern>
        <title>Subfield 8 (matching linking number)</title>
        <rule context="*:subfield[@code = '8'][matches(., '^[0-9]')]">
          <let name="linkingNumber" value="replace(., '^([0-9]+).*$', '$1')"/>
          <let name="recordID" value="generate-id(ancestor::*:record)"/>
          <let name="record001" value="ancestor::*:record/*:controlfield[@tag = '001']"/>
          <assert
            test="count(preceding::*:subfield[generate-id(ancestor::*:record) = $recordID][@code = '8'][matches(substring(., 1, string-length($linkingNumber)), $linkingNumber)]) + count(following::*:subfield[generate-id(ancestor::*:record) = $recordID][@code = '8'][matches(substring(., 1, string-length($linkingNumber)), $linkingNumber)]) &gt; 0"
            role="warning"><value-of select="concat($record001, ' :: ')"/>There are
            usually at least two subfield ǂ8s with the same linkingNumber (<value-of
              select="$linkingNumber"/>).</assert>
        </rule>
      </pattern>
    </xsl:if>
    <pattern>
      <title>Subfield 8 (unique sequence number)</title>
      <rule context="*:subfield[@code = '8'][matches(., '^[0-9]+\.[0-9]+')]">
        <let name="linkingSequence" value="replace(., '^([0-9]+\.[0-9]+).*$', '$1')"/>
        <let name="recordID" value="generate-id(ancestor::*:record)"/>
        <let name="record001" value="ancestor::*:record/*:controlfield[@tag = '001']"/>
        <assert
          test="count(preceding::*:subfield[generate-id(ancestor::*:record) = $recordID][@code = '8'][matches(substring(., 1, string-length($linkingSequence)), $linkingSequence)]) + count(following::*:subfield[generate-id(ancestor::*:record) = $recordID][@code = '8'][matches(substring(., 1, string-length($linkingSequence)), $linkingSequence)]) = 0"
          role="error"><value-of select="concat($record001, ' :: ')"/>Linking sequence
            (<value-of select="$linkingSequence"/>) is not unique.</assert>
      </rule>
    </pattern>
  </xsl:variable>
  <xsl:variable name="recordConstraints">
    <pattern>
      <title>General record constraints</title>
      <rule context="*:record">
        <let name="record001" value="*:controlfield[@tag = '001']"/>
        <report test="count(*:datafield[matches(@tag, '100|110|111|130')]) &gt; 1"
          role="error">
          <value-of select="concat($record001, ' :: ')"/>Only one 1XX datafield is allowed
          per record.</report>
        <!--<xsl:if test="$warnOthers = 'true'">
          <report test="count(*:datafield[matches(@tag,
          '100|110|111|130|700|710|711|730')]) = 0" role="error">
          <value-of select="concat($record001, ' :: ')"/>A main entry (datafield
          100|110|111|130) or added entry (datafield 700|710|711|730) is recommended.</report>
        </xsl:if>-->
        <!--<assert
          test="*:datafield[@tag = '035'][*:subfield[@code = 'a'][matches(., 'OCo?LC', 'i')]]"
          role="warning">
          <value-of select="concat($record001, ' :: ')"/>Datafield 035 with OCLC number is
          recommended.</assert>-->
        <assert test="*:datafield[@tag = '040']" role="error">
          <value-of select="concat($record001, ' :: ')"/>Datafield 040 is
          required.</assert>
        <assert test="*:datafield[@tag = '245']" role="error">
          <value-of select="concat($record001, ' :: ')"/>Datafield 245 is
          required.</assert>
        <!-- In spite of what https://www.loc.gov/marc/bibliographic/nlr/nlr3xx.html says,
          there are many serial records in Sirsi without a 300. So, serials are
          excluded in the following report. -->
        <report test="count(*:datafield[matches(@tag, '300')]) &lt; 1            and
          *:leader[not(matches(substring(., 8, 1), '[bims]'))]" role="error">
          <value-of select="concat($record001, ' :: ')"/>Datafield 300 is required for
          non-electronic, non-serial resources.</report>
        <!-- In spite of what https://www.loc.gov/marc/bibliographic/nlr/nlr00x.html says,
          there are many records in Sirsi without an 005. So, the following rule is
          ignored. -->
        <!--<xsl:if test="$warnOthers = 'true'">
          <assert test="*:controlfield[@tag = '005']" role="warning">
            <value-of select="concat($record001, ' :: ')"/>Controlfield 005 is
            recommended.</assert>
        </xsl:if>-->
      </rule>
    </pattern>
    <pattern>
      <title>Datafield 260 or 264 with subfields ǂa and ǂb required for full level serials
        record</title>
      <rule context="*:record[substring(*:leader, 8, 1) = 's'][matches(substring(*:leader,
        18, 1), '[\s1]')]">
        <let name="record001" value="*:controlfield[@tag = '001']"/>
        <assert
          test="count(*:datafield[@tag = '260' and *:subfield[@code = 'a'][normalize-space(.) != ''] and *:subfield[@code = 'b'][normalize-space(.) != '']]) &gt; 0 or count(*:datafield[@tag = '264' and *:subfield[@code = 'a'][normalize-space(.) != ''] and *:subfield[@code = 'b'][normalize-space(.) != '']]) &gt; 0"
          role="error">
          <value-of select="concat($record001, ' :: ')"/>Datafield 260 or 264 with
          subfields ǂa and ǂb is required for full level serial records.</assert>
      </rule>
    </pattern>
    <pattern>
      <title>Datafield 260 or 264 with subfield ǂc required for full level map
        records</title>
      <rule context="*:record[matches(substring(*:leader, 7, 1),
        '[ef]')][matches(substring(*:leader,         18, 1), '[\s1]')]">
        <let name="record001" value="*:controlfield[@tag = '001']"/>
        <assert
          test="count(*:datafield[@tag = '260' and *:subfield[@code = 'c'][normalize-space(.) != '']]) &gt; 0 or count(*:datafield[@tag = '264' and *:subfield[@code = 'c'][normalize-space(.) != '']]) &gt; 0"
          role="error">
          <value-of select="concat($record001, ' :: ')"/>Datafield 260 or 264 with
          subfield ǂc is required for full level map records.</assert>
      </rule>
    </pattern>
    <xsl:if test="$warnOthers = 'true'">
      <pattern>
        <title>Datafield 260 or 264 recommended for non-archival, non-serial
          record</title>
        <rule context="*:record[substring(*:leader, 9, 1) != 'a' and substring(*:leader,
          8, 1) != 's']">
          <let name="record001" value="*:controlfield[@tag = '001']"/>
          <assert test="count(*:datafield[matches(@tag, '260|264')]) &gt; 0"
            role="warning">
            <value-of select="concat($record001, ' :: ')"/>Datafield 260 or 264 is
            recommended.</assert>
        </rule>
      </pattern>
    </xsl:if>
  </xsl:variable>
  <xsl:variable name="coConstraints">
    <pattern>
      <title>Leader co-constraint with 008/06</title>
      <rule context="*:leader[matches(substring(text(), 8, 1), 'm')]">
        <let name="record001" value="ancestor::*:record/*:controlfield[@tag = '001']"/>
        <assert
          test="not(../*:controlfield[@tag = '008'][matches(substring(text(), 7, 1), '[cdiku]')])"
          role="error"><value-of select="concat($record001, ' :: ')"/>When Leader 07
          matches 'm', 008/06 (Type of date/publication status flag) cannot match
          '[cdiku]'.</assert>
      </rule>
    </pattern>
    <xsl:if test="$warnOthers = 'true'">
      <pattern>
        <title>Controlfield 007 co-constraints with leader</title>
        <!-- Language material -->
        <rule context="*:controlfield[@tag = '007'][../*:leader[matches(substring(., 7,
          1),         '[at]')]]">
          <let name="record001" value="ancestor::*:record/*:controlfield[@tag = '001']"/>
          <assert test="matches(substring(., 1, 1), '[cfhtz]')" role="warning">
            <value-of select="concat($record001, ' :: ')"/>Material category <value-of
              select="substring(., 1, 1)"/> (controlfield 007, position 1) does not
            correspond with record type <value-of select="substring(../*:leader, 7, 1)"/>
            (leader, position 7).</assert>
        </rule>
        <!-- Notated music -->
        <rule context="*:controlfield[@tag = '007'][../*:leader[matches(substring(., 7,
          1),         '[cd]')]]">
          <let name="record001" value="ancestor::*:record/*:controlfield[@tag = '001']"/>
          <assert test="matches(substring(., 1, 1), '[cfghkqz]')" role="warning">
            <value-of select="concat($record001, ' :: ')"/>Material category <value-of
              select="substring(., 1, 1)"/> (controlfield 007, position 1) does not
            correspond with record type <value-of select="substring(../*:leader, 7, 1)"/>
            (leader, position 7).</assert>
        </rule>
        <!-- Projected graphic -->
        <rule context="*:controlfield[@tag = '007'][../*:leader[matches(substring(., 7,
          1),         '[g]')]]">
          <let name="record001" value="ancestor::*:record/*:controlfield[@tag = '001']"/>
          <assert test="matches(substring(., 1, 1), '[acgmqrtvz]')" role="warning">
            <value-of select="concat($record001, ' :: ')"/>Material category <value-of
              select="substring(., 1, 1)"/> (controlfield 007, position 1) does not
            correspond with record type <value-of select="substring(../*:leader, 7, 1)"/>
            (leader, position 7).</assert>
        </rule>
        <!-- Cartographic material -->
        <rule context="*:controlfield[@tag = '007'][../*:leader[matches(substring(., 7,
          1),         '[ef]')]]">
          <let name="record001" value="ancestor::*:record/*:controlfield[@tag = '001']"/>
          <assert test="matches(substring(., 1, 1), '[acdfghkoz]')" role="warning">
            <value-of select="concat($record001, ' :: ')"/>Material category <value-of
              select="substring(., 1, 1)"/> (controlfield 007, position 1) does not
            correspond with record type <value-of select="substring(../*:leader, 7, 1)"/>
            (leader, position 7).</assert>
        </rule>
        <!-- Sound recording -->
        <rule context="*:controlfield[@tag = '007'][../*:leader[matches(substring(., 7,
          1),         '[ij]')]]">
          <let name="record001" value="ancestor::*:record/*:controlfield[@tag = '001']"/>
          <assert test="matches(substring(., 1, 1), '[cmsz]')" role="warning">
            <value-of select="concat($record001, ' :: ')"/>Material category <value-of
              select="substring(., 1, 1)"/> (controlfield 007, position 1) does not
            correspond with record type <value-of select="substring(../*:leader, 7, 1)"/>
            (leader, position 7).</assert>
        </rule>
        <!-- Nonprojectable graphic -->
        <rule context="*:controlfield[@tag = '007'][../*:leader[matches(substring(., 7,
          1),         '[k]')]]">
          <let name="record001" value="ancestor::*:record/*:controlfield[@tag = '001']"/>
          <assert test="matches(substring(., 1, 1), '[acdfghkoz]')" role="warning">
            <value-of select="concat($record001, ' :: ')"/>Material category <value-of
              select="substring(., 1, 1)"/> (controlfield 007, position 1) does not
            correspond with record type <value-of select="substring(../*:leader, 7, 1)"/>
            (leader, position 7).</assert>
        </rule>
        <!-- Computer -->
        <rule context="*:controlfield[@tag = '007'][../*:leader[matches(substring(., 7,
          1),         '[m]')]]">
          <let name="record001" value="ancestor::*:record/*:controlfield[@tag = '001']"/>
          <assert test="matches(substring(., 1, 1), '[acgkqstvz]')" role="warning">
            <value-of select="concat($record001, ' :: ')"/>Material category <value-of
              select="substring(., 1, 1)"/> (controlfield 007, position 1) does not
            correspond with record type <value-of select="substring(../*:leader, 7, 1)"/>
            (leader, position 7).</assert>
        </rule>
        <!-- Kit/Mixed material -->
        <rule context="*:controlfield[@tag = '007'][../*:leader[matches(substring(., 7,
          1),         '[acdfghkmoqrstvz]')]]">
          <let name="record001" value="ancestor::*:record/*:controlfield[@tag = '001']"/>
          <assert test="matches(substring(., 1, 1), '[op]')" role="warning">
            <value-of select="concat($record001, ' :: ')"/>Material category <value-of
              select="substring(., 1, 1)"/> (controlfield 007, position 1) does not
            correspond with record type <value-of select="substring(../*:leader, 7, 1)"/>
            (leader, position 7).</assert>
        </rule>
        <!-- Artifact/object -->
        <rule context="*:controlfield[@tag = '007'][../*:leader[matches(substring(., 7,
          2),         '[z]')]]">
          <let name="record001" value="ancestor::*:record/*:controlfield[@tag = '001']"/>
          <assert test="matches(substring(., 1, 2), 'z[muz]')" role="warning">
            <value-of select="concat($record001, ' :: ')"/>Material category <value-of
              select="substring(., 1, 1)"/> (controlfield 007, position 1) does not
            correspond with record type <value-of select="substring(../*:leader, 7, 1)"/>
            (leader, position 7).</assert>
        </rule>
      </pattern>
    </xsl:if>
    <pattern>
      <title>008 co-constraint with leader</title>
      <rule context="*:controlfield[@tag = '008'][matches(substring(text(), 7, 1),
        '[cdiku]')]">
        <let name="record001" value="ancestor::*:record/*:controlfield[@tag = '001']"/>
        <assert
          test="preceding-sibling::*:leader[not(matches(substring(text(), 8, 1), 'm'))]"
          role="error">
          <value-of select="concat($record001, ' :: ')"/>When 008/06 (Type of
          date/publication status flag) matches '[cdiku]', Leader 07 (Bibliographic level)
          cannot match 'm'.</assert>
      </rule>
    </pattern>
    <xsl:if test="$warnOthers = 'true'">
      <pattern>
        <title>008 co-constraint with 6xx</title>
        <rule context="*:controlfield[@tag = '008'][not(matches(substring(., 34, 1),
          '[1dfhijpu\|]'))]           [matches(substring(../*:leader, 7, 1), '[at]') and
          matches(substring(../*:leader, 8, 1), '[acdm]')           and
          matches(substring(../*:leader, 18, 1), '[\s1]')]">
          <let name="record001" value="ancestor::*:record/*:controlfield[@tag = '001']"/>
          <assert test="following-sibling::*:datafield[matches(@tag, '^6')]"
            role="warning">
            <value-of select="concat($record001, ' :: ')"/>Non-fiction text material
            typically has at least one subject heading.</assert>
        </rule>
      </pattern>
    </xsl:if>
    <!--<pattern>
      <title>Co-constraint between 008/33 and 6xx datafield(s)</title>
      <rule
        context="*:record[matches(substring(*:leader, 7, 1), 'a|m') and matches(substring(*:leader, 8, 1), 'a|c|d|m') and 
        *:datafield[matches(@tag, '^6') and not(*:subfield[@code = 'v'][matches(., 'fiction', 'i')])]]">
        <assert test="*:controlfield[@tag = '008'][matches(substring(text(), 34, 1), '0|\||\s')]"
          role="warning"><value-of select="concat($record001, ' :: ')"/>Typically, subject headings without subfield 'v' containing 'fiction' are only applied to non-fiction items.</assert>
      </rule>
    </pattern>-->
    <pattern>
      <title>Datafield 037 ǂa and ǂb co-constraint</title>
      <rule context="*:datafield[@tag = '037']/*:subfield[@code = 'a']">
        <let name="record001" value="ancestor::*:record/*:controlfield[@tag = '001']"/>
        <assert test="../*:subfield[@code = 'b']" role="error">
          <value-of select="concat($record001, ' :: ')"/><value-of
            select="concat('Datafield ', ../@tag)"/> when subfield ǂa is present, subfield
          ǂb must also be present.</assert>
      </rule>
    </pattern>
    <xsl:if test="$warnOthers = 'true'">
      <pattern>
        <title>Datafield 490 co-constraint with 8xx</title>
        <rule context="*:datafield[@tag = '490' and @ind1 = '1']">
          <let name="record001" value="ancestor::*:record/*:controlfield[@tag = '001']"/>
          <assert test="../*:datafield[matches(@tag, '800|810|811|830')]" role="warning">
            <value-of select="concat($record001, ' :: ')"/>When <value-of select="@tag"/>
            @ind1 = "1", a corresponding 8xx field is recommended.</assert>
        </rule>
      </pattern>
    </xsl:if>
  </xsl:variable>
  <xsl:variable name="validate005">
    <pattern>
      <title>005 date/time</title>
      <rule context="*:controlfield[matches(@tag, '005')]">
        <let name="record001" value="ancestor::*:record/*:controlfield[@tag = '001']"/>
        <xsl:comment>&#32;Field repeatability&#32;</xsl:comment>
        <assert test="not(count(../*:controlfield[matches(@tag, '005')]) &gt; 1)"
          role="error">
          <value-of select="concat($record001, ' :: ')"/>
          <value-of select="concat('Controlfield ', @tag)"/> is not repeatable.</assert>
        <xsl:if test="$warnOthers = 'true'">
          <assert test="matches(., '^\d{{14}}\.\d$')" role="warning">
            <value-of select="concat($record001, ' :: ')"/><value-of
              select="concat('Controlfield ', @tag)"/> Date and time of latest transaction
            should match 'YYYYMMDDHHMMSS.F'.</assert>
        </xsl:if>
      </rule>
    </pattern>
  </xsl:variable>
  <xsl:variable name="validate008">
    <pattern>
      <title>008 country code</title>
      <rule context="*:controlfield[@tag = '008']">
        <let name="record001" value="ancestor::*:record/*:controlfield[@tag = '001']"/>
        <assert test="matches(substring(., 16, 3), $marcCountryCodes)" role="error"
            ><value-of select="concat($record001, ' :: ')"/><value-of
            select="concat('Controlfield ', @tag)"/> Place of publication (position 15-17)
          must match a valid MARC country code.</assert>
      </rule>
    </pattern>
    <pattern>
      <title>008 language code</title>
      <rule context="*:controlfield[@tag = '008']">
        <let name="record001" value="ancestor::*:record/*:controlfield[@tag = '001']"/>
        <assert test="matches(substring(., 36, 3), $marcLangCodes)" role="error"><value-of
            select="concat($record001, ' :: ')"/><value-of
            select="concat('Controlfield ', @tag)"/> Language (position 35-37) must match
          a valid MARC language code.</assert>
      </rule>
    </pattern>
    <pattern>
      <title>008 Date 1</title>
      <rule context="*:controlfield[@tag = '008']">
        <let name="record001" value="ancestor::*:record/*:controlfield[@tag = '001']"/>
        <assert test="matches(substring(., 8, 4), '[\du]{{4}}|\s{{4}}|\|{{4}}|u{{4}}')"
          role="error">
          <value-of select="concat($record001, ' :: ')"/>
          <value-of select="concat('Controlfield ', @tag)"/> Date 1 (position 8-11) must
          match 4 digits or 'u' chars, 4 spaces, 4 pipes, or 4 'u' chars.</assert>
      </rule>
    </pattern>
    <pattern>
      <title>008 Date 2</title>
      <rule context="*:controlfield[@tag = '008']">
        <let name="record001" value="ancestor::*:record/*:controlfield[@tag = '001']"/>
        <assert test="matches(substring(., 12, 4), '[\du]{{4}}|\s{{4}}|\|{{4}}|u{{4}}')"
          role="error">
          <value-of select="concat($record001, ' :: ')"/>
          <value-of select="concat('Controlfield ', @tag)"/> Date 2 (position 12-15) must
          match 4 digits or 'u' chars, 4 spaces, 4 pipes, or 4 'u' chars.</assert>
      </rule>
    </pattern>
  </xsl:variable>
  <xsl:variable name="validate022">
    <pattern>
      <title>Validate 022 ǂa</title>
      <rule context="*:datafield[@tag = '022']/*:subfield[@code = 'a']">
        <let name="record001" value="ancestor::*:record/*:controlfield[@tag = '001']"/>
        <assert role="warning" test="matches(normalize-space(.), '\d{{4}}-\d{{3}}[\dX]')">
          <value-of select="concat($record001, ' :: ')"/>
          <value-of select="concat('Datafield ', ../@tag)"/> subfield ǂa must match
          '\d{4}-\d{3}[\dX]'.</assert>

        <!-- The Schematron generated by the following code works fine; however, converting
          it to XSLT using transpile(_edited).xsl results in a non-functional rule. -->
        <!--<xsl:if test="$warnOthers = 'true'">
          <axsl:variable name="normalizedValue" select="normalize-space(.)"/>
          <axsl:variable name="sum"
            select="(number(substring($normalizedValue, 1, 1)) * 8) + (number(substring($normalizedValue, 2, 1)) * 7) + (number(substring($normalizedValue, 3, 1)) * 6) + (number(substring($normalizedValue, 4, 1)) * 5) + (number(substring($normalizedValue, 6, 1)) * 4) + (number(substring($normalizedValue, 7, 1)) * 3) + (number(substring($normalizedValue, 8, 1)) * 2)"/>
          <axsl:variable name="modulus" select="$sum mod 11"/>
          <axsl:variable name="checkDigit" select="11 - $modulus"/>
          <axsl:variable name="checkDigit2">
            <axsl:choose>
              <axsl:when test="$checkDigit &gt; 10">
                <axsl:value-of select="$checkDigit mod 11"/>
              </axsl:when>
              <axsl:when test="$checkDigit = 10">
                <axsl:text>X</axsl:text>
              </axsl:when>
              <axsl:otherwise>
                <axsl:value-of select="$checkDigit"/>
              </axsl:otherwise>
            </axsl:choose>
          </axsl:variable>
          <assert test="substring($normalizedValue, 9, 1) = $checkDigit2" role="warning">
            <value-of select="concat($record001, ' :: ')"/>
            <value-of select="concat('Datafield ', ../@tag)"/> subfield ǂa contains an
            invalid ISSN.</assert>
        </xsl:if>-->
      </rule>
    </pattern>
  </xsl:variable>
  <xsl:variable name="validate040">
    <pattern>
      <!-- According to https://www.oclc.org/bibformats/en/0xx/040.html ǂb is mandatory. -->
      <title>Validate 040 ǂb</title>
      <rule context="*:datafield[@tag = '040']/*:subfield[@code = 'b']">
        <let name="record001" value="ancestor::*:record/*:controlfield[@tag = '001']"/>
        <assert test="matches(., $marcLangCodes)" role="error">
          <value-of select="concat($record001, ' :: ')"/>
          <value-of select="concat('Datafield ', ../@tag)"/> subfield ǂb must match a
          valid MARC language code.</assert>
      </rule>
    </pattern>
  </xsl:variable>
  <xsl:variable name="validate041">
    <pattern>
      <title>Validate 041 subfields</title>
      <rule context="*:datafield[@tag = '041']">
        <let name="record001" value="ancestor::*:record/*:controlfield[@tag = '001']"/>
        <assert test="matches(*:subfield[@code = 'a'], $marcLangCodes)" role="error"
            ><value-of select="concat($record001, ' :: ')"/><value-of
            select="concat('Datafield ', @tag)"/> subfield ǂa must match a valid MARC
          language code.</assert>
        <assert test="matches(*:subfield[@code = 'b'], $marcLangCodes)" role="error"
            ><value-of select="concat($record001, ' :: ')"/><value-of
            select="concat('Datafield ', @tag)"/> subfield ǂb must match a valid MARC
          language code.</assert>
        <assert test="matches(*:subfield[@code = 'd'], $marcLangCodes)" role="error"
            ><value-of select="concat($record001, ' :: ')"/><value-of
            select="concat('Datafield ', @tag)"/> subfield ǂd must match a valid MARC
          language code.</assert>
        <assert test="matches(*:subfield[@code = 'e'], $marcLangCodes)" role="error"
            ><value-of select="concat($record001, ' :: ')"/><value-of
            select="concat('Datafield ', @tag)"/> subfield ǂe must match a valid MARC
          language code.</assert>
        <assert test="matches(*:subfield[@code = 'f'], $marcLangCodes)" role="error"
            ><value-of select="concat($record001, ' :: ')"/><value-of
            select="concat('Datafield ', @tag)"/> subfield ǂf must match a valid MARC
          language code.</assert>
        <assert test="matches(*:subfield[@code = 'g'], $marcLangCodes)" role="error"
            ><value-of select="concat($record001, ' :: ')"/><value-of
            select="concat('Datafield ', @tag)"/> subfield ǂg must match a valid MARC
          language code.</assert>
        <assert test="matches(*:subfield[@code = 'h'], $marcLangCodes)" role="error"
            ><value-of select="concat($record001, ' :: ')"/><value-of
            select="concat('Datafield ', @tag)"/> subfield ǂh must match a valid MARC
          language code.</assert>
        <assert test="matches(*:subfield[@code = 'i'], $marcLangCodes)" role="error"
            ><value-of select="concat($record001, ' :: ')"/><value-of
            select="concat('Datafield ', @tag)"/> subfield ǂi must match a valid MARC
          language code.</assert>
        <assert test="matches(*:subfield[@code = 'j'], $marcLangCodes)" role="error"
            ><value-of select="concat($record001, ' :: ')"/><value-of
            select="concat('Datafield ', @tag)"/> subfield ǂj must match a valid MARC
          language code.</assert>
        <assert test="matches(*:subfield[@code = 'k'], $marcLangCodes)" role="error"
            ><value-of select="concat($record001, ' :: ')"/><value-of
            select="concat('Datafield ', @tag)"/> subfield ǂk must match a valid MARC
          language code.</assert>
        <assert test="matches(*:subfield[@code = 'm'], $marcLangCodes)" role="error"
            ><value-of select="concat($record001, ' :: ')"/><value-of
            select="concat('Datafield ', @tag)"/> subfield ǂm must match a valid MARC
          language code.</assert>
        <assert test="matches(*:subfield[@code = 'n'], $marcLangCodes)" role="error"
            ><value-of select="concat($record001, ' :: ')"/><value-of
            select="concat('Datafield ', @tag)"/> subfield ǂn must match a valid MARC
          language code.</assert>
        <assert test="matches(*:subfield[@code = 'p'], $marcLangCodes)" role="error"
            ><value-of select="concat($record001, ' :: ')"/><value-of
            select="concat('Datafield ', @tag)"/> subfield ǂp must match a valid MARC
          language code.</assert>
        <assert test="matches(*:subfield[@code = 'q'], $marcLangCodes)" role="error"
            ><value-of select="concat($record001, ' :: ')"/><value-of
            select="concat('Datafield ', @tag)"/> subfield ǂq must match a valid MARC
          language code.</assert>
        <assert test="matches(*:subfield[@code = 'r'], $marcLangCodes)" role="error"
            ><value-of select="concat($record001, ' :: ')"/><value-of
            select="concat('Datafield ', @tag)"/> subfield ǂr must match a valid MARC
          language code.</assert>
        <assert test="matches(*:subfield[@code = 't'], $marcLangCodes)" role="error"
            ><value-of select="concat($record001, ' :: ')"/><value-of
            select="concat('Datafield ', @tag)"/> subfield ǂt must match a valid MARC
          language code.</assert>
      </rule>
    </pattern>
  </xsl:variable>
  <xsl:variable name="validate044">
    <pattern>
      <title>Validate 044 ǂa</title>
      <rule context="*:datafield[@tag = '044']/*:subfield[@code = 'a']">
        <let name="record001" value="ancestor::*:record/*:controlfield[@tag = '001']"/>
        <assert test="matches(., $marcCountryCodes)" role="error"><value-of
            select="concat($record001, ' :: ')"/><value-of
            select="concat('Datafield ', ../@tag)"/> subfield ǂa must match a valid
          country code.</assert>
      </rule>
    </pattern>
  </xsl:variable>
  <xsl:variable name="validate050">
    <pattern>
      <title>Validate 050 content</title>
      <rule context="*:datafield[@tag = '050']">
        <let name="record001" value="ancestor::*:record/*:controlfield[@tag = '001']"/>
        <report test="count(*:subfield[@code = 'b']) &gt; 1" role="error">
          <value-of select="concat($record001, ' :: ')"/>
          <value-of select="concat('Datafield ', @tag)"/> subfield ǂb may only occur
          once.</report>
        <report test="count(*:subfield[@code = 'b']/preceding-sibling::*:subfield[@code =
          'a']) &gt; 1" role="error">
          <value-of select="concat($record001, ' :: ')"/>
          <value-of select="concat('Datafield ', @tag)"/> contains an improperly
          subfielded value.</report>
      </rule>
      <xsl:if test="$warnOthers = 'true'">
        <rule context="*:datafield[@tag = '050']/*:subfield[@code = 'a']">
          <let name="record001" value="ancestor::*:record/*:controlfield[@tag = '001']"/>
          <assert test="matches(normalize-space(.), '^[A-Z]+\s?\d+(\.\d+)?')"
            role="warning">
            <value-of select="concat($record001, ' :: ')"/>
            <value-of select="concat('Datafield ', ../@tag)"/> subfield ǂa contains a
            suspect value.</assert>
        </rule>
      </xsl:if>
      <xsl:if test="$warnOthers = 'true'">
        <rule context="*:datafield[@tag = '050']/*:subfield[@code = 'b']">
          <let name="record001" value="ancestor::*:record/*:controlfield[@tag = '001']"/>
          <assert test="matches(normalize-space(.), '^(\.?[A-Z]+(\s?\d+)?|\d+)')"
            role="warning">
            <value-of select="concat($record001, ' :: ')"/>
            <value-of select="concat('Datafield ', ../@tag)"/> subfield ǂb contains a
            suspect value.</assert>
        </rule>
      </xsl:if>
    </pattern>
  </xsl:variable>
  <xsl:variable name="validate090">
    <pattern>
      <title>Validate 090 content</title>
      <rule context="*:datafield[@tag = '090']">
        <let name="record001" value="ancestor::*:record/*:controlfield[@tag = '001']"/>
        <report test="count(*:subfield[@code = 'b']) &gt; 1" role="error">
          <value-of select="concat($record001, ' :: ')"/>
          <value-of select="concat('Datafield ', @tag)"/> subfield ǂb may only occur
          once.</report>
        <report test="count(*:subfield[@code = 'b']/preceding-sibling::*:subfield[@code
          =             'a']) &gt; 1" role="error">
          <value-of select="concat($record001, ' :: ')"/>
          <value-of select="concat('Datafield ', @tag)"/> contains an improperly
          subfielded value.</report>
      </rule>
      <xsl:if test="$warnOthers = 'true'">
        <rule context="*:datafield[@tag = '090']/*:subfield[@code = 'a']">
          <let name="record001" value="ancestor::*:record/*:controlfield[@tag = '001']"/>
          <assert test="matches(normalize-space(.), '^[A-Z]+\s?\d+(\.\d+)?')"
            role="warning">
            <value-of select="concat($record001, ' :: ')"/>
            <value-of select="concat('Datafield ', ../@tag)"/> subfield ǂa contains a
            suspect value.</assert>
        </rule>
      </xsl:if>
      <xsl:if test="$warnOthers = 'true'">
        <rule context="*:datafield[@tag = '090']/*:subfield[@code = 'b']">
          <let name="record001" value="ancestor::*:record/*:controlfield[@tag = '001']"/>
          <assert test="matches(normalize-space(.), '^(\.?[A-Z]+(\s?\d+)?|\d+)')"
            role="warning">
            <value-of select="concat($record001, ' :: ')"/>
            <value-of select="concat('Datafield ', ../@tag)"/> subfield ǂb contains a
            suspect value.</assert>
        </rule>
      </xsl:if>
    </pattern>
  </xsl:variable>
  <xsl:variable name="validate242">
    <pattern>
      <title>Validate 242 ǂy</title>
      <rule context="*:datafield[@tag = '242']/*:subfield[@code = 'y']">
        <let name="record001" value="ancestor::*:record/*:controlfield[@tag = '001']"/>
        <assert test="matches(., $marcLangCodes)" role="error">
          <value-of select="concat($record001, ' :: ')"/><value-of
            select="concat('Datafield ', ../@tag)"/> subfield ǂy must match a valid MARC
          language code.</assert>
      </rule>
    </pattern>
  </xsl:variable>
  <xsl:variable name="validate260">
    <xsl:if test="$warnOthers = 'true'">
      <pattern>
        <title>Validate 260 ǂa, ǂb, and ǂc</title>
        <rule context="*:datafield[@tag = '260' and matches(substring(../*:leader,
          8, 1), '[am]') and matches(substring(../*:leader,           18, 1), '[\s1]') and
          not(../*:datafield[@tag = '502'])]">
          <let name="record001" value="ancestor::*:record/*:controlfield[@tag = '001']"/>
          <assert test="*:subfield[@code = 'a']" role="warning"><value-of
              select="concat($record001, ' :: ')"/><value-of select="@tag"/> subfield ǂa
            is recommended.</assert>
          <assert test="*:subfield[@code = 'b']" role="warning"><value-of
              select="concat($record001, ' :: ')"/><value-of select="@tag"/> subfield ǂb
            is recommended.</assert>
          <assert test="*:subfield[@code = 'c']" role="warning"><value-of
              select="concat($record001, ' :: ')"/><value-of select="@tag"/> subfield ǂc
            is recommended.</assert>
        </rule>
      </pattern>
    </xsl:if>
  </xsl:variable>
  <xsl:variable name="validate300">
    <xsl:if test="$warnOthers = 'true'">
      <pattern>
        <title>Validate 300 ǂc</title>
        <rule context="*:datafield[@tag = '300' and matches(substring(../*:leader, 7, 1),
          '[at]') and matches(substring(../*:leader, 8, 1), '[am]') and
          matches(substring(../*:leader, 18, 1), '[\s1]') and not(substring(../*:leader,
          9, 1) = 'a')][not(ancestor::*:record/*:controlfield[@tag =
          '007'][matches(substring(., 1, 1),
          'm')])][not(ancestor::*:record/*:controlfield[@tag = '006'][matches(substring(.,
          1, 1), 'm')])]">
          <let name="record001" value="ancestor::*:record/*:controlfield[@tag = '001']"/>
          <assert test="*:subfield[@code = 'c']" role="warning">
            <value-of select="concat($record001, ' :: ')"/>
            <value-of select="@tag"/> subfield ǂc is recommended.</assert>
        </rule>
      </pattern>
    </xsl:if>
  </xsl:variable>
  <xsl:variable name="validate355">
    <pattern>
      <title>Validate 355 ǂf</title>
      <rule context="*:datafield[@tag = '355']/*:subfield[@code = 'f'] | *:datafield[@tag
        = '880']         [matches(*:subfield[@code = '6'], '^355')]/*:subfield[@code =
        'f']">
        <let name="record001" value="ancestor::*:record/*:controlfield[@tag = '001']"/>
        <assert test="matches(., $marcCountryCodes)" role="error">
          <value-of select="concat($record001, ' :: ')"/>
          <value-of select="concat('Datafield ', ../@tag)"/> subfield ǂb must match a
          valid country code.</assert>
      </rule>
    </pattern>
  </xsl:variable>
  <xsl:variable name="validate365">
    <pattern>
      <title>Validate 365 ǂk</title>
      <rule context="*:datafield[@tag = '365']/*:subfield[code = 'k'] | *:datafield[@tag =
        '880']         [matches(*:subfield[@code = '6'], '^365')]/*:subfield[@code = 'k']">
        <let name="record001" value="ancestor::*:record/*:controlfield[@tag = '001']"/>
        <assert test="matches(., $marcCountryCodes)" role="error">
          <value-of select="concat($record001, ' :: ')"/>
          <value-of select="concat('Datafield ', ../@tag)"/> subfield ǂk must match a
          valid MARC country code.</assert>
      </rule>
    </pattern>
  </xsl:variable>
  <xsl:variable name="validate366">
    <pattern>
      <title>Validate 366 ǂk</title>
      <rule context="*:datafield[@tag = '366']/*:subfield[code = 'k'] | *:datafield[@tag =
        '880']         [matches(*:subfield[@code = '6'], '^366')]/*:subfield[@code = 'k']">
        <let name="record001" value="ancestor::*:record/*:controlfield[@tag = '001']"/>
        <assert test="matches(., $marcCountryCodes)" role="error">
          <value-of select="concat($record001, ' :: ')"/><value-of
            select="concat('Datafield ', ../@tag)"/> subfield ǂk must match a valid MARC
          country code.</assert>
      </rule>
    </pattern>
  </xsl:variable>
  <xsl:variable name="validate502">
    <pattern>
      <title>Validate 502 requirements</title>
      <rule context="*:datafield[@tag =
        '502'][matches(substring(preceding-sibling::*:leader, 18, 1), '[\s1]')]         |
        *:datafield[@tag = '880'][matches(*:subfield[@code = '6'],
        '^502')][matches(substring(preceding-sibling::*:leader, 18, 1), '[\s1]')]">
        <let name="record001" value="ancestor::*:record/*:controlfield[@tag = '001']"/>
        <assert
          test="*:subfield[matches(@code, 'a')][normalize-space(.) != ''] or (*:subfield[matches(@code, 'b')][normalize-space(.) != ''] and *:subfield[matches(@code, 'c')][normalize-space(.) != ''] and *:subfield[matches(@code, 'd')][normalize-space(.) != ''])">
          <value-of select="concat($record001, ' :: ')"/>
          <value-of select="concat('Datafield ', @tag)"/> subfield ǂa is required or
          subfields ǂb, ǂc, and ǂd are required for a full level record.</assert>
      </rule>
    </pattern>
  </xsl:variable>
  <xsl:variable name="validate505">
    <pattern>
      <title>Validate 505 with ind2 = '0'</title>
      <rule context="*:datafield[@tag = '505'][@ind2 eq '0'] | *:datafield[@tag = '880']
        [matches(*:subfield[@code = '6'], '^505')][@ind2 eq '0']">
        <let name="record001" value="ancestor::*:record/*:controlfield[@tag = '001']"/>
        <report test="*:subfield[matches(@code, 'a')]" role="error">
          <value-of select="concat($record001, ' :: ')"/>
          <value-of select="concat('Datafield ', @tag)"/> subfield ǂa is not permitted in
          extended contents note</report>
      </rule>
    </pattern>
  </xsl:variable>
  <xsl:variable name="validate654">
    <pattern>
      <title>Validate 654</title>
      <rule context="*:datafield[@tag = '654'] | *:datafield[@tag = '880']
        [matches(*:subfield[@code = '6'], '^654')]">
        <let name="record001" value="ancestor::*:record/*:controlfield[@tag = '001']"/>
        <assert test="*:subfield[matches(@code, '[ab]')][normalize-space(.) != '']"
          role="error"><value-of select="concat($record001, ' :: ')"/><value-of
            select="@tag"/> Either subfield ǂa or subfield ǂb is required.</assert>
      </rule>
    </pattern>
  </xsl:variable>
  <xsl:variable name="validate655">
    <pattern>
      <title>Validate 655</title>
      <rule context="*:datafield[@tag = '655'] | *:datafield[@tag = '880']
        [matches(*:subfield[@code = '6'], '^655')]">
        <let name="record001" value="ancestor::*:record/*:controlfield[@tag = '001']"/>
        <assert test="*:subfield[matches(@code, '[ab]')][normalize-space(.) != '']"
          role="error"><value-of select="concat($record001, ' :: ')"/><value-of
            select="@tag"/> Either subfield ǂa or subfield ǂb is required.</assert>
      </rule>
    </pattern>
  </xsl:variable>
  <xsl:variable name="validate775">
    <pattern>
      <title>Validate 775 ǂf</title>
      <rule context="*:datafield[@tag = '775']/*:subfield[code = 'f'] | *:datafield[@tag =
        '880']         [matches(*:subfield[@code = '6'], '^775')]/*:subfield[code = 'f']">
        <let name="record001" value="ancestor::*:record/*:controlfield[@tag = '001']"/>
        <assert test="matches(., $marcCountryCodes)" role="error">
          <value-of select="concat($record001, ' :: ')"/>
          <value-of select="concat('Datafield ', ../@tag)"/> subfield ǂf must match a
          valid MARC country code.</assert>
      </rule>
    </pattern>
  </xsl:variable>
  <xsl:variable name="validate841">
    <pattern>
      <title>Validate 841 ǂa</title>
      <rule context="*:datafield[@tag = '841']/*:subfield[@code = 'a'] | *:datafield[@tag
        = '880']         [matches(*:subfield[@code = '6'], '^841')]/*:subfield[@code =
        'a']">
        <let name="record001" value="ancestor::*:record/*:controlfield[@tag = '001']"/>
        <assert test="string-length(.) = 4" role="error">
          <value-of select="concat($record001, ' :: ')"/>
          <value-of select="concat('Datafield ', ../@tag)"/> subfield ǂa must match 4
          characters.</assert>
        <assert test="matches(substring(., 1, 1), '[acdefgijkmoprt]')" role="error">
          <value-of select="concat($record001, ' :: ')"/>
          <value-of select="concat('Datafield ', ../@tag)"/> subfield ǂa Bibl type code
          (char 1) must match a letter (a, c, d, e, f, g, i, j, k, m, o, p, r, or
          t).</assert>
        <assert test="matches(substring(., 2, 2), '[\p{Zs}]{{2}}')" role="error">
          <value-of select="concat($record001, ' :: ')"/>
          <value-of select="concat('Datafield ', ../@tag)"/> subfield ǂa characters 2 and
          3 must be blank.</assert>
        <assert test="matches(substring(., 4, 1), '[\p{Zs}a]')" role="error">
          <value-of select="concat($record001, ' :: ')"/>
          <value-of select="concat('Datafield ', ../@tag)"/> subfield ǂa Type of control
          (char 4) must match a space or a letter (a).</assert>
      </rule>
    </pattern>
    <pattern>
      <title>Validate 841 ǂb</title>
      <rule context="*:datafield[@tag = '841']/*:subfield[@code = 'b'] | *:datafield[@tag
        = '880']         [matches(*:subfield[@code = '6'], '^841')]/*:subfield[@code =
        'b']">
        <let name="record001" value="ancestor::*:record/*:controlfield[@tag = '001']"/>
        <assert test="string-length(.) = 32" role="error">
          <value-of select="concat($record001, ' :: ')"/>
          <value-of select="concat('Datafield ', ../@tag)"/> subfield ǂb must match 32
          characters.</assert>
        <assert test="matches(substring(., 1, 6), '\d{{6}}')" role="error">
          <value-of select="concat($record001, ' :: ')"/>
          <value-of select="concat('Datafield ', ../@tag)"/> subfield ǂb Date entered
          (chars 1-6) must match 6 digits.</assert>
        <assert test="matches(substring(., 7, 1), '[012345]')" role="error">
          <value-of select="concat($record001, ' :: ')"/>
          <value-of select="concat('Datafield ', ../@tag)"/> subfield ǂb Receipt or
          acquisition status (char 7) must match a digit (0-5).</assert>
        <assert test="matches(substring(., 8, 1), '[cdefglmnpquz]')" role="error">
          <value-of select="concat($record001, ' :: ')"/>
          <value-of select="concat('Datafield ', ../@tag)"/> subfield ǂb Method of
          acquisition (char 8) must match a letter (c, d, e, f, g, l, m, n, p, q, u, or
          z).</assert>
        <assert test="matches(substring(., 9, 4), '(\d{{4}}|\p{Zs}{}4}}|uuuu)')"
          role="error">
          <value-of select="concat($record001, ' :: ')"/>
          <value-of select="concat('Datafield ', ../@tag)"/> subfield ǂb Expected
          acquisition end date (chars 9-12) must match 4 digits, 4 spaces, or
          'uuuu'.</assert>
        <assert test="matches(substring(., 13, 1), '[012345678]')" role="error">
          <value-of select="concat($record001, ' :: ')"/>
          <value-of select="concat('Datafield ', ../@tag)"/> subfield ǂb General retention
          policy (char 13) must match a digit (0-8).</assert>
        <assert
          test="matches(substring(., 14, 3), '(\p{Zs}{{3}}|[lp][\p{Zs}1-9][mwyeis])')"
          role="error">
          <value-of select="concat($record001, ' :: ')"/>
          <value-of select="concat('Datafield ', ../@tag)"/> subfield ǂb Specific
          retention policy (chars 14-16) must match 3 spaces or a letter (l or p),
          followed by a space or a digit, followed by a letter (m, w, y, e, i, or
          s).</assert>
        <assert test="matches(substring(., 17, 1), '[01234]')" role="error">
          <value-of select="concat($record001, ' :: ')"/>
          <value-of select="concat('Datafield ', ../@tag)"/> subfield ǂb Completeness
          (char 17) must match a digit (0-4).</assert>
        <assert test="matches(substring(., 18, 3), '[01][0-9][0-9]')" role="error">
          <value-of select="concat($record001, ' :: ')"/>
          <value-of select="concat('Datafield ', ../@tag)"/> subfield ǂb Number of copies
          reported (chars 18-20) must match a number, left-justified with zeros.</assert>
        <assert test="matches(substring(., 21, 1), '[abclu]')" role="error">
          <value-of select="concat($record001, ' :: ')"/>
          <value-of select="concat('Datafield ', ../@tag)"/> subfield ǂb Lending policy
          (char 20) must match a letter (a, b, c, l, or u).</assert>
        <assert test="matches(substring(., 22, 1), '[abu]')" role="error">
          <value-of select="concat($record001, ' :: ')"/>
          <value-of select="concat('Datafield ', ../@tag)"/> subfield ǂb Reproduction
          policy (char 21) must match a letter (a, b, or u).</assert>
        <assert test="matches(substring(., 23, 3), '(\p{Zs}{{3}}|und)')" role="error">
          <value-of select="concat($record001, ' :: ')"/>
          <value-of select="concat('Datafield ', ../@tag)"/> subfield ǂb Language (chars
          23-25) must match 3 spaces or 'und'.</assert>
        <assert test="matches(substring(., 26, 1), '[01]')" role="error">
          <value-of select="concat($record001, ' :: ')"/>
          <value-of select="concat('Datafield ', ../@tag)"/> subfield ǂb Separate or
          composite copy report (char 26) must match a digit (0-1).</assert>
        <assert test="matches(substring(., 27, 6), '\d{{6}}')" role="error">
          <value-of select="concat($record001, ' :: ')"/>
          <value-of select="concat('Datafield ', ../@tag)"/> subfield ǂb Date of report
          (chars 27-32) must match 6 digits.</assert>
      </rule>
    </pattern>
    <pattern>
      <title>Validate 841 ǂe</title>
      <rule context="*:datafield[@tag = '841']/*:subfield[@code = 'e'] | *:datafield[@tag
        = '880']         [matches(*:subfield[@code = '6'], '^841')]/*:subfield[@code =
        'e']">
        <let name="record001" value="ancestor::*:record/*:controlfield[@tag = '001']"/>
        <assert test="matches(., '^[12345muz]$')" role="error">
          <value-of select="concat($record001, ' :: ')"/>
          <value-of select="concat('Datafield ', ../@tag)"/> subfield ǂe must match a
          digit (1-5) or a letter (m, u, or z).</assert>
      </rule>
    </pattern>
  </xsl:variable>
  <xsl:variable name="validate843">
    <pattern>
      <title>Validate 843 $7</title>
      <rule context="*:datafield[@tag = '843']/*:subfield[@code = '7'] | *:datafield[@tag
        = '880']         [matches(*:subfield[@code = '6'], '^843')]/*:subfield[@code =
        '7']">
        <let name="record001" value="ancestor::*:record/*:controlfield[@tag = '001']"/>
        <assert test="matches(substring(., 1, 1), '[besikmptnqcdu]')" role="error">
          <value-of select="concat($record001, ' :: ')"/>
          <value-of select="concat('Datafield ', ../@tag)"/> subfield ǂ7 Type of
          date/publication status flag (char 1) must match a letter (b, e, s, i, k, m, p,
          t, n, q, c, d, or u).</assert>
        <assert
          test="matches(substring(., 2, 4), '[0-9]{{4}}|[\p{Zs}u\\\|]{{4}}|[0-9\p{Zs}u\\\|]{{4}}')"
          role="error">
          <value-of select="concat($record001, ' :: ')"/>
          <value-of select="concat('Datafield ', ../@tag)"/> subfield ǂ7 Date 1 (chars
          2-5) must match 4 digits, 4 "fill characters" (space, backslash, pipe, or 'u')
          or 1 or more digits followed by "fill characters".</assert>
        <assert
          test="matches(substring(., 6, 4), '[0-9]{{4}}|[\p{Zs}u\\\|]{{4}}|[0-9\p{Zs}u\\\|]{{4}}')"
          role="error">
          <value-of select="concat($record001, ' :: ')"/>
          <value-of select="concat('Datafield ', ../@tag)"/> subfield ǂ7 Date 2 (chars
          6-9) must match 4 digits, 4 "fill characters" (space, backslash, pipe, or 'u')
          or 1 or more digits followed by "fill characters".</assert>
        <assert test="matches(substring(., 10, 3), '$marcCountryCodes')" role="error">
          <value-of select="concat($record001, ' :: ')"/>
          <value-of select="concat('Datafield ', ../@tag)"/> subfield ǂ7 Country code
          (chars 10-12) must match a valid MARC country code.</assert>
        <assert test="matches(substring(., 13, 1), '[\p{Zs}a-kmnqtuwz]')" role="error">
          <value-of select="concat($record001, ' :: ')"/>
          <value-of select="concat('Datafield ', ../@tag)"/> subfield ǂ7 Frequency (char
          13) must match a space or a letter (a-k, m-n, q, t, u,w, or z).</assert>
        <assert test="matches(substring(., 14, 1), '[\p{Zs}nrxu]')" role="error">
          <value-of select="concat($record001, ' :: ')"/>
          <value-of select="concat('Datafield ', ../@tag)"/> subfield ǂ7 Regularity (char
          14) must match a space or a letter (n, r, x, or u).</assert>
        <assert test="matches(substring(., 15, 1), '[\p{Zs}a-dfoqrs\|]')" role="error">
          <value-of select="concat($record001, ' :: ')"/>
          <value-of select="concat('Datafield ', ../@tag)"/> subfield ǂ7 Form of item
          (char 15) must match a space, a letter (a-d, f, o, q, r, or s), or a
          pipe.</assert>
      </rule>
    </pattern>
  </xsl:variable>
  <xsl:variable name="validate852">
    <pattern>
      <title>Validate 852 ǂn</title>
      <rule context="*:datafield[@tag = '852']/*:subfield[@code = 'n'] | *:datafield[@tag
        = '880']         [matches(*:subfield[@code = '6'], '^852')]/*:subfield[@code =
        'n']">
        <let name="record001" value="ancestor::*:record/*:controlfield[@tag = '001']"/>
        <assert test="matches(., $marcCountryCodes)" role="error">
          <value-of select="concat($record001, ' :: ')"/>
          <value-of select="concat('Datafield ', ../@tag)"/> subfield ǂn must match a
          valid MARC country code.</assert>
      </rule>
    </pattern>
  </xsl:variable>
  <xsl:variable name="validate991">
    <pattern>
      <title>991 required subfields</title>
      <rule context="*:datafield[@tag = '991']">
        <let name="record001" value="ancestor::*:record/*:controlfield[@tag = '001']"/>
        <assert
          test="*:subfield[@code = 'a'][normalize-space(.) != ''] and *:subfield[@code = 'b'][normalize-space(.) != ''] and *:subfield[@code = '5'][normalize-space(.) != '']"
          role="error">
          <value-of select="concat($record001, ' :: ')"/>
          <value-of select="concat('Datafield ', ../@tag)"/> subfields ǂa and ǂb are
          required.</assert>
      </rule>
    </pattern>
    <pattern>
      <title>Validate 991 ǂb</title>
      <rule context="*:datafield[@tag = '991'][matches(*:subfield[@code = '5'],
        '^viu$')]/*:subfield[@code = 'b']">
        <let name="record001" value="ancestor::*:record/*:controlfield[@tag = '001']"/>
        <assert test="matches(., '^\d{{8}}\d{{6}}\.\d$')" role="error">
          <value-of select="concat($record001, ' :: ')"/>
          <value-of select="concat('Datafield ', ../@tag)"/> subfield ǂb must match
          'YYYYMMDDhhmmss.f'.</assert>
      </rule>
    </pattern>
  </xsl:variable>
  <xsl:variable name="validate994">
    <pattern>
      <title>Validate 994 ǂa, ǂb</title>
      <let name="record001" value="ancestor::*:record/*:controlfield[@tag = '001']"/>
      <rule context="*:datafield[@tag = '994']/*:subfield[@code = 'a'] | *:datafield[@tag
        = '880']         [matches(*:subfield[@code = '6'], '^994')]/*:subfield[@code =
        'a']">
        <assert test="matches(., '(01|02|03|10|11|12|50|90|91|92|93|A1|C0|E0|X0|Z0)')"
          role="error">
          <value-of select="concat($record001, ' :: ')"/>
          <value-of select="concat('Datafield ', ../@tag)"/> subfield ǂa must match
          '(01|02|03|10|11|12|50|90|91|92|93|A1|C0|E0|X0|Z0)'.</assert>
      </rule>
      <rule context="*:datafield[@tag = '994']/*:subfield[@code = 'b'] | *:datafield[@tag
        = '880']         [matches(*:subfield[@code = '6'], '^994')]/*:subfield[@code =
        'b']">
        <assert test="not(matches(normalize-space(.), '^$'))" role="error">
          <value-of select="concat($record001, ' :: ')"/><value-of
            select="concat('Datafield ', ../@tag)"/> subfield ǂb must have a
          value.</assert>
      </rule>
    </pattern>
  </xsl:variable>
  <xsl:variable name="validate999">
    <pattern>
      <title>999 required subfields</title>
      <rule context="*:datafield[@tag = '999']">
        <let name="record001" value="ancestor::*:record/*:controlfield[@tag = '001']"/>
        <assert
          test="*:subfield[@code = 'a'][normalize-space(.) != ''] and *:subfield[@code = 'w'][normalize-space(.) != '']"
          role="error">
          <value-of select="concat($record001, ' :: ')"/>
          <value-of select="concat('Datafield ', ../@tag)"/> subfields ǂa and ǂw are
          required.</assert>
      </rule>
    </pattern>
  </xsl:variable>

  <!-- The following variables hold information from which constraints not derivable 
    from the MARC spec can be created programmatically. -->
  <!-- Mandatory subfields from https://www.loc.gov/marc/bibliographic/nlr/nlr.html -->
  <xsl:variable name="mandatorySubfields">
    <xsl:copy-of select="document('mandatorySubfields.xml')"/>
  </xsl:variable>

  <!-- Recommended subfields -->
  <xsl:variable name="recommendedSubfields">
    <reqd tag="321" subfield="b"/>
    <reqd tag="539" subfield="a"/>
    <reqd tag="539" subfield="b"/>
    <reqd tag="539" subfield="c"/>
    <reqd tag="539" subfield="d"/>
    <reqd tag="539" subfield="e"/>
    <reqd tag="539" subfield="f"/>
    <!--<reqd tag="999" subfield="i"/>
    <reqd tag="999" subfield="l"/>
    <reqd tag="999" subfield="m"/>
    <reqd tag="999" subfield="t"/>-->
  </xsl:variable>


  <!-- ======================================================================= -->
  <!-- MAIN OUTPUT TEMPLATE                                                    -->
  <!-- ======================================================================= -->

  <xsl:template match="/">
    <xsl:variable name="topComment">
      <xsl:value-of select="concat('&#32;', 
        replace(normalize-space(
        replace(
        replace(
        substring-before(*:marcDesc/preceding-sibling::comment(), 'LAST GENERATED'), 
        'marcHTML2XML.xsl', $progName), 
        'describes', 'validates records in')), 'bibliographic format', 'bibliographic&#xa;format'), '&#32;')"/>
    </xsl:variable>
    <xsl:comment>
      <xsl:value-of select="$topComment"/>
      <xsl:text>&#xa;&#xa;</xsl:text>
      <xsl:text>LAST UPDATED: </xsl:text>
      <xsl:value-of select="format-date(current-date(), '[Y]-[M01]-[D01]')"/>
      <xsl:text>&#xa;&#xa;</xsl:text>
      <xsl:value-of
        select="concat(&quot;PARAMETERS:&#xa;&#32;&#32;countryCodeCheck = &apos;&quot;, $countryCodeCheck, &quot;&apos;&#xa;&#32;&#32;languageCodeCheck = &apos;&quot;, $languageCodeCheck, &quot;&apos;&#xa;&#32;&#32;warnOthers = &apos;&quot;, $warnOthers, &quot;&apos;&#xa;&#32;&#32;warnUndefinedFields = &apos;&quot;, $warnUndefinedFields, &quot;&apos;&#xa;&#32;&#32;warnObsoleteFields = &apos;&quot;, $warnObsoleteFields, &quot;&apos;&#xa;&#32;&#32;non-marcRelatorCodes = &apos;&quot;, $non-marcRelatorCodes, &quot;&apos;&#xa;&#32;&#32;non-marcRelatorTerms = &apos;&quot;, $non-marcRelatorTerms, &quot;&apos; &quot;)"
      />
      <xsl:text>&#xa;</xsl:text>
    </xsl:comment>
    
    <schema xmlns="http://purl.oclc.org/dsdl/schematron" queryBinding="xslt3"
      xmlns:sch="http://purl.oclc.org/dsdl/schematron">

      <ns uri="http://www.w3.org/1999/xlink" prefix="xlink"/>
      <ns uri="http://www.w3.org/1999/XSL/Transform" prefix="xsl"/>

      <xsl:comment>&#32;GLOBAL VARIABLES&#32;</xsl:comment>
      <let name="marcCountryCodes" value="{$marcCountryCodes}"/>
      <let name="marcLangCodes" value="{$marcLangCodes}"/>
      <let name="relatorCodes" value="{$relatorCodes}"/>
      <let name="relatorTerms" value="{$relatorTerms}"/>

      <xsl:comment>&#32;GENERAL&#32;</xsl:comment>
      <!-- Allowed fields -->
      <pattern>
        <title>Valid fields</title>
        <!-- Valid controlfield and datafield tag value required -->
        <xsl:variable name="validTags">
          <xsl:text>(0([0-9A-Z][0-9A-Z])|0([1-9a-z][0-9a-z]))|(([1-9A-Z][0-9A-Z]{2})|([1-9a-z][0-9a-z]{2}))</xsl:text>
        </xsl:variable>
        <rule context="*:record/*[matches(local-name(), 'controlfield|datafield')]">
          <let name="localName" value="local-name()"/>
          <xsl:copy-of select="$createRecord001Variable"/>
          <assert test="matches(@tag, '^({$validTags})$')" role="error">
            <xsl:copy-of select="$useRecord001Variable"/>
            <value-of select="concat('invalid ', lower-case($localName), ' ', @tag, '.')"
            />
          </assert>
        </rule>
      </pattern>

      <!-- Valid, but undefined tags -->
      <xsl:if test="$warnUndefinedFields eq 'true'">
        <pattern>
          <title>Undefined fields</title>
          <!-- Tags defined in marcDesc.xml -->
          <xsl:variable name="definedTags">
            <xsl:value-of
              select="string-join(distinct-values(//*:marcDesc/*[matches(local-name(), 'controlfield|datafield')]/@tag), '|')"
            />
          </xsl:variable>
          <rule context="*:record/*[matches(local-name(), 'controlfield|datafield')]">
            <let name="localName" value="local-name()"/>
            <xsl:copy-of select="$createRecord001Variable"/>
            <assert test="matches(@tag, '^({$definedTags})$')" role="warning">
              <xsl:copy-of select="$useRecord001Variable"/>
              <value-of
                select="concat('Undefined ', lower-case($localName), ' ', @tag, '.')"/>
            </assert>
          </rule>
        </pattern>
      </xsl:if>

      <!-- Obsolete tags -->
      <xsl:if test="$warnObsoleteFields eq 'true'">
        <pattern>
          <title>Obsolete fields</title>
          <!-- Obsolete in marcDesc.xml -->
          <xsl:variable name="obsoleteTags">
            <xsl:value-of
              select="string-join(distinct-values(//*:marcDesc/*[matches(local-name(), 'controlfield|datafield') and @use = 'obsolete']/@tag), '|')"
            />
          </xsl:variable>
          <rule context="*:record/*[matches(local-name(), 'controlfield|datafield')]">
            <let name="localName" value="local-name()"/>
            <xsl:copy-of select="$createRecord001Variable"/>
            <report test="matches(@tag, '^({$obsoleteTags})$')" role="warning">
              <xsl:copy-of select="$useRecord001Variable"/>
              <value-of
                select="concat('Obsolete ', lower-case($localName), ' ', @tag, '.')"/>
            </report>
          </rule>
        </pattern>
      </xsl:if>

      <xsl:if test="$warnOthers = 'true'">
        <pattern>
          <title>Unicode replacement character</title>
          <rule context="*:subfield">
            <let name="record001" value="ancestor::*:record/*:controlfield[@tag = '001']"/>
            <report test="matches(., '�') or matches(., 'U\+FFFD', 'i')" role="warning">
              <value-of select="concat($record001, ' :: ')"/>
              <value-of select="concat('Datafield ', ../@tag)"/> subfield ǂ<value-of
                select="@code"/> contains Unicode replacement character (U+FFFD)</report>
          </rule>
        </pattern>
      </xsl:if>

      <xsl:comment>&#32;CO-CONSTRAINTS&#32;</xsl:comment>
      <xsl:copy-of select="$coConstraints"/>

      <xsl:comment>&#32;RECORD&#32;</xsl:comment>
      <xsl:copy-of select="$recordConstraints"/>

      <xsl:comment>&#32;LINKING SUBFIELDS&#32;</xsl:comment>
      <xsl:copy-of select="$linkingSubfieldConstraints"/>

      <xsl:comment>&#32;LEADER&#32;</xsl:comment>
      <xsl:apply-templates select="*:marcDesc/*:leader"/>

      <xsl:comment>&#32;CONTROL FIELDS&#32;</xsl:comment>
      <xsl:apply-templates select="*:marcDesc/*:controlfield">
        <xsl:sort select="@tag" data-type="number"/>
      </xsl:apply-templates>

      <xsl:comment>&#32;DATA FIELDS&#32;</xsl:comment>
      <!-- Obsolete fields are not included in the output; however, a warning will
        be raised if an obsolete field appears in the data. -->
      <xsl:apply-templates select="*:marcDesc/*:datafield[not(@use = 'obsolete')]">
        <xsl:sort select="@tag" data-type="number"/>
      </xsl:apply-templates>

    </schema>
  </xsl:template>

  <!-- ======================================================================= -->
  <!-- MATCH TEMPLATES                                                         -->
  <!-- ======================================================================= -->

  <xsl:template match="*:leader">
    <pattern>
      <title>Leader</title>
      <rule context="*:leader">
        <xsl:copy-of select="$createRecord001Variable"/>
        <xsl:if test="*:length">
          <let name="currentLength" value="string-length(.)"/>
          <xsl:variable name="expectedLength" select="*:length"/>
          <assert test="string-length(.) = {$expectedLength}" role="error">
            <xsl:copy-of select="$useRecord001Variable"/>Leader contains <value-of
              select="$currentLength"/> characters, expected <xsl:value-of
              select="$expectedLength"/>.</assert>
        </xsl:if>
        <xsl:for-each select="*:code">
          <assert role="error">
            <xsl:attribute name="test">
              <xsl:value-of
                select="concat('matches(substring(., ', @position, ', ', @length, '), ', @values, ')')"
              />
            </xsl:attribute>
            <xsl:copy-of select="$useRecord001Variable"/>
            <xsl:value-of
              select="concat(normalize-space(@desc), ' (leader, ', @position, ', ', @length, ') must match ', @values, '.')"
            />
          </assert>
        </xsl:for-each>
      </rule>
    </pattern>
  </xsl:template>

  <xsl:template match="*:controlfield">
    <xsl:variable name="tag" select="@tag"/>
    <xsl:variable name="commentText">
      <xsl:text>&#32;</xsl:text>
      <xsl:value-of
        select="concat($tag, ' ', replace(upper-case(normalize-space(@desc)), '--', '&#x2014;'))"/>
      <xsl:text>&#32;</xsl:text>
    </xsl:variable>
    <!--<xsl:comment>
      <xsl:value-of select="$commentText"/>
    </xsl:comment>-->
    <xsl:choose>
      <!-- @materialType is used on 006 and 008 -->
      <xsl:when test="@materialType">
        <!-- $materialContext holds the string to be written to sch:assert/@context -->
        <xsl:variable name="materialContext">
          <xsl:choose>
            <xsl:when test="matches(@materialType, 'BK')">
              <xsl:choose>
                <xsl:when test="$tag = '006'">
                  <xsl:text>matches(substring(., 1, 1), '[at]')</xsl:text>
                </xsl:when>
                <xsl:when test="$tag = '008'">
                  <xsl:text>matches(substring(../*:leader, 7, 1), '[at]') and matches(substring(../*:leader, 8, 1), '[acdm]')</xsl:text>
                </xsl:when>
              </xsl:choose>
            </xsl:when>
            <xsl:when test="matches(@materialType, 'CF')">
              <xsl:choose>
                <xsl:when test="$tag = '006'">
                  <xsl:text>matches(substring(., 1, 1), 'm')</xsl:text>
                </xsl:when>
                <xsl:when test="$tag = '008'">
                  <xsl:text>matches(substring(../*:leader, 7, 1), 'm')</xsl:text>
                </xsl:when>
              </xsl:choose>
            </xsl:when>
            <xsl:when test="matches(@materialType, 'MP')">
              <xsl:choose>
                <xsl:when test="$tag = '006'">
                  <xsl:text>matches(substring(., 1, 1), '[ef]')</xsl:text>
                </xsl:when>
                <xsl:when test="$tag = '008'">
                  <xsl:text>matches(substring(../*:leader, 7, 1), '[ef]')</xsl:text>
                </xsl:when>
              </xsl:choose>
            </xsl:when>
            <xsl:when test="matches(@materialType, 'MU')">
              <xsl:choose>
                <xsl:when test="$tag = '006'">
                  <xsl:text>matches(substring(., 1, 1), '[cdij]')</xsl:text>
                </xsl:when>
                <xsl:when test="$tag = '008'">
                  <xsl:text>matches(substring(../*:leader, 7, 1), '[cdij]')</xsl:text>
                </xsl:when>
              </xsl:choose>
            </xsl:when>
            <xsl:when test="matches(@materialType, 'CR')">
              <xsl:choose>
                <xsl:when test="$tag = '006'">
                  <xsl:text>matches(substring(., 1, 1), 's')</xsl:text>
                </xsl:when>
                <xsl:when test="$tag = '008'">
                  <xsl:text>matches(substring(../*:leader, 7, 1), 'a') and matches(substring(../*:leader, 8, 1), '[bis]')</xsl:text>
                </xsl:when>
              </xsl:choose>
            </xsl:when>
            <xsl:when test="matches(@materialType, 'VM')">
              <xsl:choose>
                <xsl:when test="$tag = '006'">
                  <xsl:text>matches(substring(., 1, 1), '[gkor]')</xsl:text>
                </xsl:when>
                <xsl:when test="$tag = '008'">
                  <xsl:text>matches(substring(../*:leader, 7, 1), '[gkor]')</xsl:text>
                </xsl:when>
              </xsl:choose>
            </xsl:when>
            <xsl:when test="matches(@materialType, 'MX')">
              <xsl:choose>
                <xsl:when test="$tag = '006'">
                  <xsl:text>matches(substring(., 1, 1), 'p')</xsl:text>
                </xsl:when>
                <xsl:when test="$tag = '008'">
                  <xsl:text>matches(substring(../*:leader, 7, 1), 'p')</xsl:text>
                </xsl:when>
              </xsl:choose>
            </xsl:when>
          </xsl:choose>
        </xsl:variable>
        <pattern>
          <title>
            <xsl:value-of select="concat(@tag, ' ', normalize-space(@desc))"/>
          </title>
          <rule>
            <!-- Construct sch:assert/@context -->
            <xsl:attribute name="context">
              <xsl:text>*:controlfield[@tag = '</xsl:text>
              <xsl:value-of select="$tag"/>
              <xsl:text>']</xsl:text>
              <xsl:value-of select="concat('[', $materialContext, ']')"/>
            </xsl:attribute>
            <xsl:copy-of select="$createRecord001Variable"/>
            <xsl:comment>&#32;Requirements&#32;</xsl:comment>
            <xsl:for-each select="*:code">
              <assert role="error">
                <xsl:attribute name="test">
                  <xsl:value-of
                    select="concat('matches(substring(., ', @position, ', ', @length, '), ', @values, ')')"
                  />
                </xsl:attribute>
                <xsl:copy-of select="$useRecord001Variable"/>
                <xsl:value-of
                  select="concat(normalize-space(@desc), ' (controlfield ', $tag, ', ', @position, ', ', @length, ') must match ', @values, '.')"
                />
              </assert>
            </xsl:for-each>
          </rule>
        </pattern>
      </xsl:when>

      <!-- @materialCategory is used on 007 -->
      <xsl:when test="@materialCategory">
        <pattern>
          <title>
            <xsl:value-of select="concat(@tag, ' ', normalize-space(@desc))"/>
          </title>
          <rule>
            <!-- Construct sch:assert/@context -->
            <xsl:attribute name="context">
              <xsl:text>*:controlfield[@tag = '</xsl:text>
              <xsl:value-of select="@tag"/>
              <xsl:text>'][matches(substring(., 1, 1), '</xsl:text>
              <xsl:value-of select="@materialCategory"/>
              <xsl:text>')]</xsl:text>
            </xsl:attribute>
            <xsl:copy-of select="$createRecord001Variable"/>
            <xsl:comment>&#32;Requirements&#32;</xsl:comment>
            <!-- Length of 007 depends on material code as opposed to 006 and 008 which have fixed lengths -->
            <xsl:if test="*:length">
              <let name="currentLength" value="string-length(.)"/>
              <xsl:variable name="expectedLength" select="*:length"/>
              <assert test="string-length(.) = {$expectedLength}" role="error">
                <xsl:copy-of select="$useRecord001Variable"/>
                <xsl:value-of select="$tag"/> contains <value-of select="$currentLength"/>
                characters, expected <xsl:value-of select="$expectedLength"/>.</assert>
            </xsl:if>
            <xsl:for-each select="*:code">
              <assert role="error">
                <xsl:attribute name="test">
                  <xsl:value-of
                    select="concat('matches(substring(., ', @position, ', ', @length, '), ', @values, ')')"
                  />
                </xsl:attribute>
                <xsl:copy-of select="$useRecord001Variable"/>
                <xsl:value-of
                  select="concat(normalize-space(@desc), ' (controlfield ', $tag, ', ', @position, ', ', @length, ') must match ', @values, '.')"
                />
              </assert>
            </xsl:for-each>
          </rule>
        </pattern>
      </xsl:when>

      <xsl:when test="matches(@tag, '005')">
        <xsl:copy-of select="$validate005"/>
      </xsl:when>

      <!-- Controlfields 006, 007, and 008 without @materialType or @materialCategory hold 
        generic constraints -->
      <xsl:when
        test="matches(@tag, '006|007|008') and not(@materialCategory) and not(@materialType)">
        <xsl:variable name="tag" select="@tag"/>
        <pattern>
          <title>
            <xsl:value-of select="concat(@tag, ' ', normalize-space(@desc))"/>
          </title>
          <rule>
            <!-- Construct sch:assert/@context -->
            <xsl:attribute name="context">
              <xsl:text>*:controlfield[@tag = '</xsl:text>
              <xsl:value-of select="$tag"/>
              <xsl:text>']</xsl:text>
            </xsl:attribute>
            <xsl:copy-of select="$createRecord001Variable"/>
            <!-- Repeatability based on @repeat -->
            <xsl:if test="matches(@repeat, 'NR')">
              <xsl:comment>&#32;Field not repeatable&#32;</xsl:comment>
              <assert test="not(count(../*:controlfield[matches(@tag, '{@tag}')]) &gt; 1)"
                role="error">
                <value-of select="concat('Controlfield ', @tag)"/>
                <xsl:text> is not repeatable.</xsl:text>
              </assert>
            </xsl:if>
            <xsl:comment>&#32;Requirements&#32;</xsl:comment>
            <!-- Length of 007 depends on material code as opposed to 006 and 008 which have fixed lengths -->
            <xsl:if test="*:length">
              <let name="currentLength" value="string-length(.)"/>
              <xsl:variable name="expectedLength" select="*:length"/>
              <assert test="string-length(.) = {$expectedLength}" role="error">
                <xsl:copy-of select="$useRecord001Variable"/>
                <xsl:value-of select="$tag"/> contains <value-of select="$currentLength"/>
                characters, expected <xsl:value-of select="$expectedLength"/>.</assert>
            </xsl:if>
            <xsl:for-each select="*:code">
              <assert role="error">
                <xsl:attribute name="test">
                  <xsl:value-of
                    select="concat('matches(substring(., ', @position, ', ', @length, '), ', @values, ')')"
                  />
                </xsl:attribute>
                <xsl:copy-of select="$useRecord001Variable"/>
                <value-of select="concat('Controlfield ', @tag)"/>
                <xsl:value-of
                  select="concat(' ', normalize-space(@desc), ' (controlfield ', $tag, ', ', @position, ', ', @length, ') must match ', @values, '.')"
                />
              </assert>
            </xsl:for-each>
          </rule>
        </pattern>
        <xsl:choose>
          <xsl:when test="$tag = '008'">
            <xsl:copy-of select="$validate008"/>
          </xsl:when>
        </xsl:choose>
      </xsl:when>
      <!-- Controlfields 001, 002, 004, and 009 -->
      <xsl:otherwise>
        <pattern>
          <title>
            <xsl:value-of select="concat(@tag, ' ', normalize-space(@desc))"/>
          </title>
          <rule>
            <!-- Construct sch:assert/@context -->
            <xsl:attribute name="context">
              <xsl:text>*:controlfield[@tag = '</xsl:text>
              <xsl:value-of select="@tag"/>
              <xsl:text>']</xsl:text>
            </xsl:attribute>
            <xsl:copy-of select="$createRecord001Variable"/>
            <!-- Repeatability based on @repeat -->
            <xsl:if test="matches(@repeat, 'NR')">
              <xsl:comment>&#32;Field repeatability&#32;</xsl:comment>
              <xsl:text>&#xa;</xsl:text>
              <assert test="not(count(../*:controlfield[matches(@tag, '{@tag}')]) &gt; 1)"
                role="error">
                <xsl:copy-of select="$useRecord001Variable"/>
                <value-of select="concat('Controlfield ', @tag)"/>
                <xsl:text> is not repeatable.</xsl:text>
              </assert>
            </xsl:if>
            <!-- At present, these have no <code> subelements, so the following
              for-each instruction has no effect. -->
            <xsl:for-each select="*:code">
              <assert role="error">
                <xsl:attribute name="test">
                  <xsl:text>matches(substring(., </xsl:text>
                  <xsl:value-of select="@position"/>
                  <xsl:text>, </xsl:text>
                  <xsl:value-of select="@length"/>
                  <xsl:text>), </xsl:text>
                  <xsl:value-of select="@values"/>
                  <xsl:text>)</xsl:text>
                </xsl:attribute>
                <xsl:copy-of select="$useRecord001Variable"/>
                <xsl:value-of
                  select="concat(@tag, ' ', normalize-space(@desc), ' ( controlfield ', @tag, ' ', @position, ', ', @length, ' chars) must match ')"/>
                <xsl:value-of select="@values"/>
                <xsl:text>.</xsl:text>
              </assert>
            </xsl:for-each>
          </rule>
        </pattern>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="*:datafield[@tag != '041']">
    <xsl:variable name="tag" select="@tag"/>
    <xsl:if test="*:ind1 | *:ind2 | *:subfield">
      <xsl:variable name="commentText">
        <xsl:text>&#32;</xsl:text>
        <xsl:value-of
          select="concat($tag, ' ', replace(upper-case(normalize-space(@desc)), '--', '&#x2014;'))"/>
        <xsl:if test="@use = 'obsolete'">
          <xsl:text> [OBSOLETE]</xsl:text>
        </xsl:if>
        <xsl:text>&#32;</xsl:text>
      </xsl:variable>
      <xsl:comment>
        <xsl:value-of select="$commentText"/>
      </xsl:comment>
      <pattern>
        <title>
          <xsl:value-of select="concat($tag, ' ', normalize-space(@desc))"/>
          <xsl:if test="@use = 'obsolete'">
            <xsl:text> [OBSOLETE]</xsl:text>
          </xsl:if>
        </title>
        <rule context="*:datafield[@tag = '{$tag}'] | *:datafield[@tag =
          '880'][matches(*:subfield[@code = '6'], '^{$tag}')]">
          <xsl:copy-of select="$createRecord001Variable"/>
          <xsl:if test="matches(@repeat, 'NR')">
            <xsl:comment>&#32;Field repeatability&#32;</xsl:comment>
            <assert test="not(count(../*[@tag = '{$tag}']) &gt; 1)" role="error">
              <xsl:copy-of select="$useRecord001Variable"/>
              <value-of select="concat('Datafield ', @tag)"/>
              <xsl:text> is not repeatable.</xsl:text>
            </assert>
          </xsl:if>
          <xsl:if test="*:ind1 or *:ind2">
            <xsl:comment>&#32;Indicators&#32;</xsl:comment>
            <xsl:variable name="ind1Values" select="replace(*:ind1/@values, 'blank', ' ')"/>
            <xsl:variable name="ind2Values" select="replace(*:ind2/@values, 'blank', ' ')"/>
            <assert test="matches(@ind1, '^[{$ind1Values}]$')" role="error">
              <xsl:copy-of select="$useRecord001Variable"/>
              <value-of select="concat('Datafield ', @tag)"/>
              <xsl:value-of
                select="concat(' ind1 must match &quot;[', replace(*:ind1/@values, ' ', '\\s'), ']&quot;.')"
              />
            </assert>
            <assert test="matches(@ind2, '^[{$ind2Values}]$')" role="error">
              <xsl:copy-of select="$useRecord001Variable"/>
              <value-of select="concat('Datafield ', @tag)"/>
              <xsl:value-of
                select="concat(' ind2 must match &quot;[', replace(*:ind2/@values, ' ', '\\s'), ']&quot;.')"
              />
            </assert>
          </xsl:if>
          <xsl:variable name="validSubfields">
            <xsl:for-each select="*:subfield">
              <xsl:value-of select="@code"/>
            </xsl:for-each>
          </xsl:variable>
          <xsl:if test="normalize-space($validSubfields) ne ''">
            <xsl:comment>&#32;Valid subfields&#32;</xsl:comment>
            <report test="*:subfield[not(matches(@code, '^[{$validSubfields}]$'))]"
              role="error">
              <xsl:copy-of select="$useRecord001Variable"/>
              <value-of select="concat('Datafield ', @tag)"/> invalid subfield @code(s):
                <value-of
                select="string-join(*:subfield[not(matches(@code, '^[{$validSubfields}]$'))]/@code, ', ')"
              />
            </report>
            <xsl:if test="*:subfield[@repeat = 'NR']">
              <xsl:comment>&#32;Non-repeatable subfields&#32;</xsl:comment>
              <xsl:for-each select="*:subfield[@repeat = 'NR']">
                <xsl:variable name="code" select="@code"/>
                <assert test="not(count(*:subfield[@code = '{$code}']) &gt; 1)"
                  role="error">
                  <xsl:copy-of select="$useRecord001Variable"/>
                  <value-of select="concat('Datafield ', @tag)"/>
                  <xsl:value-of select="concat(' subfield ǂ', $code)"/> is not
                  repeatable.</assert>
              </xsl:for-each>
            </xsl:if>
          </xsl:if>
        </rule>
      </pattern>
      <xsl:if test="$mandatorySubfields//*:datafield[@tag = $tag]">
        <pattern>
          <title>
            <xsl:value-of select="concat(@tag, ' required subfields full level record')"/>
          </title>
          <rule context="*:datafield[@tag =
            '{$tag}'][matches(substring(preceding-sibling::*:leader, 18, 1), '[\s1]')]
            [matches(substring(preceding-sibling::*:leader, 18, 1), '[\s1]')]
            | *:datafield[@tag = '880'][matches(*:subfield[@code = '6'],
            '{$tag}')][matches(substring(preceding-sibling::*:leader, 18, 1), '[\s1]')]
            ">
            <let name="record001" value="ancestor::*:record/*:controlfield[@tag = '001']"/>
            <xsl:for-each
              select="$mandatorySubfields//*:datafield[@tag = $tag]/*:subfield">
              <xsl:variable name="code">
                <xsl:value-of select="@code"/>
              </xsl:variable>
              <assert test="*:subfield[@code = '{$code}'][normalize-space(.) != '']"
                role="error">
                <value-of select="concat($record001, ' :: ')"/>
                <value-of select="concat('Datafield ', @tag)"/>
                <xsl:value-of select="concat(' subfield ǂ', $code)"/> is required for a
                full level record.</assert>
            </xsl:for-each>
          </rule>
        </pattern>
      </xsl:if>
      <!-- Include tag-specific patterns -->
      <xsl:choose>
        <xsl:when test="$tag = '022'">
          <xsl:copy-of select="$validate022"/>
        </xsl:when>
        <xsl:when test="$tag = '040'">
          <xsl:copy-of select="$validate040"/>
        </xsl:when>
        <xsl:when test="$tag = '044'">
          <xsl:copy-of select="$validate044"/>
        </xsl:when>
        <xsl:when test="$tag = '050'">
          <xsl:copy-of select="$validate050"/>
        </xsl:when>
        <xsl:when test="$tag = '090'">
          <xsl:copy-of select="$validate090"/>
        </xsl:when>
        <xsl:when test="$tag = '242'">
          <xsl:copy-of select="$validate242"/>
        </xsl:when>
        <xsl:when test="$tag = '260'">
          <xsl:copy-of select="$validate260"/>
        </xsl:when>
        <xsl:when test="$tag = '300'">
          <xsl:copy-of select="$validate300"/>
        </xsl:when>
        <xsl:when test="$tag = '355'">
          <xsl:copy-of select="$validate355"/>
        </xsl:when>
        <xsl:when test="$tag = '365'">
          <xsl:copy-of select="$validate365"/>
        </xsl:when>
        <xsl:when test="$tag = '366'">
          <xsl:copy-of select="$validate366"/>
        </xsl:when>
        <xsl:when test="$tag = '502'">
          <xsl:copy-of select="$validate502"/>
        </xsl:when>
        <xsl:when test="$tag = '505'">
          <xsl:copy-of select="$validate505"/>
        </xsl:when>
        <xsl:when test="$tag = '654'">
          <xsl:copy-of select="$validate654"/>
        </xsl:when>
        <xsl:when test="$tag = '655'">
          <xsl:copy-of select="$validate655"/>
        </xsl:when>
        <xsl:when test="$tag = '775'">
          <xsl:copy-of select="$validate775"/>
        </xsl:when>
        <xsl:when test="$tag = '841'">
          <xsl:copy-of select="$validate841"/>
        </xsl:when>
        <xsl:when test="$tag = '843'">
          <xsl:copy-of select="$validate843"/>
        </xsl:when>
        <xsl:when test="$tag = '852'">
          <xsl:copy-of select="$validate852"/>
        </xsl:when>
        <xsl:when test="$tag = '991'">
          <xsl:copy-of select="$validate991"/>
        </xsl:when>
        <xsl:when test="$tag = '994'">
          <xsl:copy-of select="$validate994"/>
        </xsl:when>
        <xsl:when test="$tag = '999'">
          <xsl:copy-of select="$validate999"/>
        </xsl:when>
      </xsl:choose>
      <xsl:if
        test="descendant::*:valuedef[matches(@desc, 'Source specified in subfield \$2')]">
        <xsl:for-each
          select="descendant::*:valuedef[matches(@desc, 'Source specified in subfield \$2')]">
          <pattern>
            <xsl:variable name="indicator">
              <xsl:value-of select="local-name(..)"/>
            </xsl:variable>
            <title>
              <xsl:value-of
                select="concat($tag, ' @', $indicator, ' co-constraint with ǂ2')"/>
            </title>
            <xsl:variable name="token">
              <xsl:value-of select="@token"/>
            </xsl:variable>
            <rule>
              <xsl:attribute name="context">
                <xsl:value-of
                  select="concat(&quot;*:datafield[@tag = &apos;&quot;, $tag, &quot;&apos; and @&quot;, $indicator, &quot; = &apos;&quot;, $token, &quot;&apos;]&quot;)"
                />
              </xsl:attribute>
              <let name="record001" value="ancestor::*:record/*:controlfield[@tag =
                '001']"/>
              <assert>
                <xsl:attribute name="test">
                  <xsl:text>*:subfield[@code = &apos;2&apos;][normalize-space(.) != '']</xsl:text>
                </xsl:attribute>
                <xsl:attribute name="role">error</xsl:attribute>
                <value-of select="concat($record001, ' :: ')"/>
                <value-of select="concat('Datafield ', @tag)"/>
                <xsl:text> subfield ǂ2 is required when @</xsl:text>
                <xsl:value-of select="$indicator"/>
                <xsl:text> = '</xsl:text>
                <xsl:value-of select="$token"/>
                <xsl:text>'.</xsl:text>              
              </assert>
            </rule>
          </pattern>
        </xsl:for-each>
      </xsl:if>
    </xsl:if>
  </xsl:template>

  <xsl:template match="*:datafield[@tag = '041']">
    <xsl:variable name="tag" select="@tag"/>
    <xsl:if test="*:ind1 | *:ind2 | *:subfield">
      <xsl:variable name="commentText">
        <xsl:text>&#32;</xsl:text>
        <xsl:value-of
          select="concat($tag, ' ', replace(upper-case(normalize-space(@desc)), '--', '&#x2014;'))"/>
        <xsl:if test="@use = 'obsolete'">
          <xsl:text> [OBSOLETE]</xsl:text>
        </xsl:if>
        <xsl:text>&#32;</xsl:text>
      </xsl:variable>
      <xsl:comment>
        <xsl:value-of select="$commentText"/>
      </xsl:comment>
      <pattern>
        <title>
          <xsl:value-of select="concat($tag, ' ', normalize-space(@desc))"/>
        </title>
        <rule context="*:datafield[@tag = '{$tag}'] | *:datafield[@tag =
          '880'][matches(*:subfield[@code = '6'], '^{$tag}')]">
          <xsl:copy-of select="$createRecord001Variable"/>
          <xsl:if test="matches(@repeat, 'NR')">
            <xsl:comment>&#32;Field repeatability&#32;</xsl:comment>
            <assert test="not(count(../*[@tag = '{$tag}']) &gt; 1)" role="error">
              <xsl:copy-of select="$useRecord001Variable"/>
              <value-of select="concat('Datafield ', @tag)"/>
              <xsl:text> is not repeatable.</xsl:text>
            </assert>
          </xsl:if>
          <xsl:if test="*:ind1 or *:ind2">
            <xsl:comment>&#32;Indicators&#32;</xsl:comment>
            <xsl:variable name="ind1Values" select="replace(*:ind1/@values, 'blank', ' ')"/>
            <xsl:variable name="ind2Values" select="replace(*:ind2/@values, 'blank', ' ')"/>
            <xsl:comment>
              <xsl:value-of
                select="concat(' ind1: ', replace(normalize-space(*:ind1/@desc), '--', '&#x2014;'), ' ')"
              />
            </xsl:comment>
            <assert test="matches(@ind1, '^[{$ind1Values}]$')" role="error">
              <xsl:copy-of select="$useRecord001Variable"/>
              <value-of select="concat('Datafield ', @tag)"/>
              <xsl:value-of
                select="concat(' ind1 must match &quot;[', replace(*:ind1/@values, ' ', '\\s'), ']&quot;.')"
              />
            </assert>
            <xsl:comment>
              <xsl:value-of
                select="concat(' ind2: ', replace(normalize-space(*:ind2/@desc), '--', '&#x2014;'), ' ')"
              />
            </xsl:comment>
            <assert test="matches(@ind2, '^[{$ind2Values}]$')" role="error">
              <xsl:copy-of select="$useRecord001Variable"/>
              <value-of select="concat('Datafield ', @tag)"/>
              <xsl:value-of
                select="concat(' ind2 must match &quot;[', replace(*:ind2/@values, ' ', '\\s'), ']&quot;.')"
              />
            </assert>
          </xsl:if>
          <xsl:variable name="validSubfields">
            <xsl:for-each select="*:subfield">
              <xsl:value-of select="@code"/>
            </xsl:for-each>
          </xsl:variable>
          <xsl:if test="normalize-space($validSubfields) ne ''">
            <xsl:comment>&#32;Valid subfields&#32;</xsl:comment>
            <report test="*:subfield[not(matches(@code, '^[{$validSubfields}]$'))]"
              role="error">
              <xsl:copy-of select="$useRecord001Variable"/>
              <value-of select="concat('Datafield ', @tag)"/> invalid subfield @code(s):
                <value-of
                select="string-join(*:subfield[not(matches(@code, '^[{$validSubfields}]$'))]/@code, ', ')"
              /></report>
            <xsl:comment>&#32;Required subfields&#32;</xsl:comment>
            <assert test="*:subfield[not(normalize-space(.) eq '')]" role="error">
              <xsl:copy-of select="$useRecord001Variable"/>
              <value-of select="concat('Datafield ', @tag)"/> must have at least 1
              non-empty subfield.</assert>
            <xsl:if test="*:subfield[@occurs = 'M']">
              <xsl:for-each select="*:subfield[@occurs = 'M']">
                <xsl:variable name="code" select="@code"/>
                <assert test="*:subfield[@code = '{$code}'][normalize-space(.) != '']"
                  role="error">
                  <xsl:copy-of select="$useRecord001Variable"/>
                  <value-of select="concat('Datafield ', @tag)"/>
                  <xsl:value-of select="concat(' subfield ǂ', $code)"/> is
                  required.</assert>
              </xsl:for-each>
            </xsl:if>
            <!--<xsl:if test="$warnOthers ne 'false' and *:subfield[@occurs = 'R']">
              <xsl:comment>&#32;Recommended subfields&#32;</xsl:comment>
              <xsl:for-each select="*:subfield[@occurs = 'R']">
                <xsl:variable name="code" select="@code"/>
                <assert test="*:subfield[@code = '{$code}']" role="warning">
                  <xsl:copy-of select="$useRecord001Variable"/>
                  <value-of select="concat('Datafield ', @tag)"/>
                  <xsl:value-of select="concat(' subfield ǂ', $code)"/> is
                  recommended.</assert>
              </xsl:for-each>
            </xsl:if>-->
            <xsl:comment>&#32;Subfield repeatability&#32;</xsl:comment>
            <xsl:if test="*:subfield[@repeat = 'NR']">
              <xsl:for-each select="*:subfield[@repeat = 'NR']">
                <xsl:variable name="code" select="@code"/>
                <assert test="not(count(*:subfield[@code = '{$code}']) &gt; 1)"
                  role="error">
                  <xsl:copy-of select="$useRecord001Variable"/>
                  <value-of select="concat('Datafield ', @tag)"/>
                  <xsl:value-of select="concat(' subfield ǂ', $code)"/> is not
                  repeatable.</assert>
              </xsl:for-each>
            </xsl:if>
          </xsl:if>
        </rule>
      </pattern>
      <xsl:if
        test="descendant::*:valuedef[matches(@desc, 'Source specified in subfield \$2')]">
        <xsl:for-each
          select="descendant::*:valuedef[matches(@desc, 'Source specified in subfield \$2')]">
          <pattern>
            <xsl:variable name="indicator">
              <xsl:value-of select="local-name(..)"/>
            </xsl:variable>
            <title>
              <xsl:value-of
                select="concat($tag, ' @', $indicator, ' co-constraint with ǂ2')"/>
              <!--<xsl:value-of
                select="concat($tag, ' co-constraint between @', $indicator, ' and ǂ2')"/>-->
            </title>
            <xsl:variable name="token">
              <xsl:value-of select="@token"/>
            </xsl:variable>
            <rule>
              <xsl:attribute name="context">
                <xsl:value-of
                  select="concat(&quot;*:datafield[@tag = &apos;&quot;, $tag, &quot;&apos; and @&quot;, $indicator, &quot; = &apos;&quot;, $token, &quot;&apos;]&quot;)"
                />
              </xsl:attribute>
              <let name="record001" value="ancestor::*:record/*:controlfield[@tag =
                '001']"/>
              <assert>
                <xsl:attribute name="test">
                  <xsl:text>*:subfield[@code = &apos;2&apos;][normalize-space(.) != '']</xsl:text>
                </xsl:attribute>
                <xsl:attribute name="role">error</xsl:attribute>
                <value-of select="concat($record001, ' :: ')"/>
                <value-of select="concat('Datafield ', @tag)"/>
                <xsl:text> subfield ǂ2 is required when @</xsl:text>
                <xsl:value-of select="$indicator"/>
                <xsl:text> = '7'.</xsl:text>
              </assert>
            </rule>
          </pattern>
        </xsl:for-each>
      </xsl:if>
    </xsl:if>
  </xsl:template>
  
  <!-- DROP COMMENTS -->
  <xsl:template match="comment() | @*" mode="#all"/>
    
  
  

</xsl:stylesheet>
