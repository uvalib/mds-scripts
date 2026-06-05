<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs" version="2.0">
  
  <!-- Based on MARC Initial Definite and Indefinite Articles, rev. Oct 2001, https://www.loc.gov/marc/bibliographic/bdapndxf.html, retrieved 2020/10/11 -->
  <xsl:variable name="marcArticleList">
    <entry>
      <article>a </article>
      <lang codes="cpe|eng|enm|ang|sco|sgn">English</lang>
      <lang codes="glg|gag">Galician</lang>
      <lang codes="hun">Hungarian</lang>
      <lang codes="cpp|nic|por">Portuguese</lang>
      <lang codes="rup|rum">Romanian</lang>
      <lang codes="sco|gla">Scots</lang>
      <lang codes="yid">Yiddish</lang>
    </entry>
    <entry>
      <article>a'</article>
      <lang codes="gla">Scottish Gaelic</lang>
    </entry>
    <entry>
      <article>aik </article>
      <lang codes="sgn|urd">Urdu</lang>
    </entry>
    <entry>
      <article>ake </article>
      <lang codes="jpr|peo|pal|per">Persian</lang>
    </entry>
    <entry>
      <article>al </article>
      <lang codes="rup|rum">Romanian</lang>
    </entry>
    <entry>
      <article>al-</article>
      <lang codes="ara|jrb|sem">Arabic</lang>
      <lang codes="bal">Baluchi</lang>
      <lang codes="dra">Brahui</lang>
      <lang codes="lah|pan">Panjabi</lang>
      <lang codes="pan">Punjabi</lang>
      <lang codes="jpr|peo|pal|per">Persian</lang>
      <lang codes="tut|crh|tur|ota">Turkish</lang>
      <lang codes="sgn|urd">Urdu</lang>
    </entry>
    <entry>
      <article>am </article>
      <lang codes="gla">Scottish Gaelic</lang>
    </entry>
    <entry>
      <article>an </article>
      <lang codes="cpe|eng|enm|ang|sco|sgn">English</lang>
      <lang codes="gle|iri|mga|sga">Irish</lang>
      <lang codes="sco|gla">Scots</lang>
      <lang codes="gla">Scottish Gaelic</lang>
      <lang codes="yid">Yiddish</lang>
    </entry>
    <entry>
      <article>an t-</article>
      <lang codes="gle|iri|mga|sga">Irish</lang>
      <lang codes="gla">Scottish Gaelic</lang>
    </entry>
    <entry>
      <article>ane </article>
      <lang codes="sco|gla">Scots</lang>
    </entry>
    <entry>
      <article>ang </article>
      <lang codes="tgl|tag">Tagalog</lang>
    </entry>
    <entry>
      <article>ang mga </article>
      <lang codes="tgl|tag">Tagalog</lang>
    </entry>
    <entry>
      <article>as </article>
      <lang codes="glg|gag">Galician</lang>
      <lang codes="cpp|nic|por">Portuguese</lang>
    </entry>
    <entry>
      <article>az </article>
      <lang codes="hun">Hungarian</lang>
    </entry>
    <entry>
      <article>bat </article>
      <lang codes="baq">Basque</lang>
    </entry>
    <entry>
      <article>bir </article>
      <lang codes="tut|crh|tur|ota">Turkish</lang>
    </entry>
    <entry>
      <article>d'</article>
      <lang codes="cpe|eng|enm|ang|sco|sgn">English</lang>
    </entry>
    <entry>
      <article>da </article>
      <lang codes="">Shetland English</lang>
    </entry>
    <entry>
      <article>das </article>
      <lang codes="ger|gmh|goh|gem|nds|sco|gsw|yid">German</lang>
    </entry>
    <entry>
      <article>de </article>
      <lang codes="dan|gem|sgn">Danish</lang>
      <lang codes="afr|dut|dum|gem">Dutch</lang>
      <lang codes="cpe|eng|enm|ang|sco|sgn">English</lang>
      <lang codes="frs|fry|fri|gem|frr">Frisian</lang>
      <lang codes="nor|nob|nno|non">Norwegian</lang>
      <lang codes="gem|smj|swe">Swedish</lang>
    </entry>
    <entry>
      <article>dei </article>
      <lang codes="nor|nob|nno|non">Norwegian</lang>
    </entry>
    <entry>
      <article>dem </article>
      <lang codes="ger|gmh|goh|gem|nds|sco|gsw|yid">German</lang>
    </entry>
    <entry>
      <article>den </article>
      <lang codes="dan|gem|sgn">Danish</lang>
      <lang codes="ger|gmh|goh|gem|nds|sco|gsw|yid">German</lang>
      <lang codes="nor|nob|nno|non">Norwegian</lang>
      <lang codes="gem|smj|swe">Swedish</lang>
    </entry>
    <entry>
      <article>der </article>
      <lang codes="ger|gmh|goh|gem|nds|sco|gsw|yid">German</lang>
      <lang codes="yid">Yiddish</lang>
    </entry>
    <entry>
      <article>des </article>
      <lang codes="ger|gmh|goh|gem|nds|sco|gsw|yid">German</lang>
      <lang codes="wln">Walloon</lang>
    </entry>
    <entry>
      <article>det </article>
      <lang codes="dan|gem|sgn">Danish</lang>
      <lang codes="nor|nob|nno|non">Norwegian</lang>
      <lang codes="gem|smj|swe">Swedish</lang>
    </entry>
    <entry>
      <article>di </article>
      <lang codes="yid">Yiddish</lang>
    </entry>
    <entry>
      <article>die </article>
      <lang codes="afr">Afrikaans</lang>
      <lang codes="ger|gmh|goh|gem|nds|sco|gsw|yid">German</lang>
      <lang codes="yid">Yiddish</lang>
    </entry>
    <entry>
      <article>dos </article>
      <lang codes="yid">Yiddish</lang>
    </entry>
    <entry>
      <article>e </article>
      <lang codes="nor|nob|nno|non">Norwegian</lang>
    </entry>
    <entry>
      <article>'e </article>
      <lang codes="frs|fry|fri|gem|frr">Frisian</lang>
    </entry>
    <entry>
      <article>een </article>
      <lang codes="afr|dut|dum|gem">Dutch</lang>
    </entry>
    <entry>
      <article>eene </article>
      <lang codes="afr|dut|dum|gem">Dutch</lang>
    </entry>
    <entry>
      <article>egy </article>
      <lang codes="hun">Hungarian</lang>
    </entry>
    <entry>
      <article>ei </article>
      <lang codes="nor|nob|nno|non">Norwegian</lang>
    </entry>
    <entry>
      <article>ein </article>
      <lang codes="ger|gmh|goh|gem|nds|sco|gsw|yid">German</lang>
      <lang codes="nor|nob|nno|non">Norwegian</lang>
      <lang codes="wln">Walloon</lang>
    </entry>
    <entry>
      <article>eine </article>
      <lang codes="ger|gmh|goh|gem|nds|sco|gsw|yid">German</lang>
    </entry>
    <entry>
      <article>einem </article>
      <lang codes="ger|gmh|goh|gem|nds|sco|gsw|yid">German</lang>
    </entry>
    <entry>
      <article>einen </article>
      <lang codes="ger|gmh|goh|gem|nds|sco|gsw|yid">German</lang>
    </entry>
    <entry>
      <article>einer </article>
      <lang codes="ger|gmh|goh|gem|nds|sco|gsw|yid">German</lang>
    </entry>
    <entry>
      <article>eines </article>
      <lang codes="ger|gmh|goh|gem|nds|sco|gsw|yid">German</lang>
    </entry>
    <entry>
      <article>eit </article>
      <lang codes="nor|nob|nno|non">Norwegian</lang>
    </entry>
    <entry>
      <article>el </article>
      <lang codes="cat">Catalan</lang>
      <lang codes="arg|crp|lad|roa|spa">Spanish</lang>
    </entry>
    <entry>
      <article>el-</article>
      <lang codes="ara|jrb|sem">Arabic</lang>
    </entry>
    <entry>
      <article>els </article>
      <lang codes="cat">Catalan</lang>
    </entry>
    <entry>
      <article>en </article>
      <lang codes="cat">Catalan</lang>
      <lang codes="dan|gem|sgn">Danish</lang>
      <lang codes="nor|nob|nno|non">Norwegian</lang>
      <lang codes="gem|smj|swe">Swedish</lang>
    </entry>
    <entry>
      <article>enne </article>
      <lang codes="wln">Walloon</lang>
    </entry>
    <entry>
      <article>et </article>
      <lang codes="dan|gem|sgn">Danish</lang>
      <lang codes="nor|nob|nno|non">Norwegian</lang>
    </entry>
    <entry>
      <article>ett </article>
      <lang codes="gem|smj|swe">Swedish</lang>
    </entry>
    <entry>
      <article>eyn </article>
      <lang codes="yid">Yiddish</lang>
    </entry>
    <entry>
      <article>eyne </article>
      <lang codes="yid">Yiddish</lang>
    </entry>
    <entry>
      <article>gl'</article>
      <lang codes="ita|nap|roa|scn">Italian</lang>
    </entry>
    <entry>
      <article>gli </article>
      <lang codes="ita|nap|roa|scn">Italian</lang>
    </entry>
    <entry>
      <article>ha-</article>
      <lang codes="heb|ira|yid">Hebrew</lang>
    </entry>
    <entry>
      <article>hai </article>
      <lang codes="grc">Classical Greek</lang>
      <lang codes="tut|grc|gre">Greek</lang>
    </entry>
    <entry>
      <article>he </article>
      <lang codes="cpe|haw">Hawaiian</lang>
    </entry>
    <entry>
      <article>hē</article>
      <lang codes="grc">Classical Greek</lang>
      <lang codes="tut|grc|gre">Greek</lang>
    </entry>
    <entry>
      <article>he-</article>
      <lang codes="heb|ira|yid">Hebrew</lang>
    </entry>
    <entry>
      <article>heis </article>
      <lang codes="tut|grc|gre">Greek</lang>
    </entry>
    <entry>
      <article>hen </article>
      <lang codes="tut|grc|gre">Greek</lang>
    </entry>
    <entry>
      <article>hena </article>
      <lang codes="tut|grc|gre">Greek</lang>
    </entry>
    <entry>
      <article>henas </article>
      <lang codes="tut|grc|gre">Greek</lang>
    </entry>
    <entry>
      <article>het </article>
      <lang codes="afr|dut|dum|gem">Dutch</lang>
    </entry>
    <entry>
      <article>hin </article>
      <lang codes="ice|non|sgn">Icelandic</lang>
    </entry>
    <entry>
      <article>hina </article>
      <lang codes="ice|non|sgn">Icelandic</lang>
    </entry>
    <entry>
      <article>hinar </article>
      <lang codes="ice|non|sgn">Icelandic</lang>
    </entry>
    <entry>
      <article>hinir </article>
      <lang codes="ice|non|sgn">Icelandic</lang>
    </entry>
    <entry>
      <article>hinn </article>
      <lang codes="ice|non|sgn">Icelandic</lang>
    </entry>
    <entry>
      <article>hinna </article>
      <lang codes="ice|non|sgn">Icelandic</lang>
    </entry>
    <entry>
      <article>hinnar </article>
      <lang codes="ice|non|sgn">Icelandic</lang>
    </entry>
    <entry>
      <article>hinni </article>
      <lang codes="ice|non|sgn">Icelandic</lang>
    </entry>
    <entry>
      <article>hins </article>
      <lang codes="ice|non|sgn">Icelandic</lang>
    </entry>
    <entry>
      <article>hinu </article>
      <lang codes="ice|non|sgn">Icelandic</lang>
    </entry>
    <entry>
      <article>hinum </article>
      <lang codes="ice|non|sgn">Icelandic</lang>
    </entry>
    <entry>
      <article>hið</article>
      <lang codes="ice|non|sgn">Icelandic</lang>
    </entry>
    <entry>
      <article>ho </article>
      <lang codes="grc">Classical Greek</lang>
      <lang codes="tut|grc|gre">Greek</lang>
    </entry>
    <entry>
      <article>hoi </article>
      <lang codes="grc">Classical Greek</lang>
      <lang codes="tut|grc|gre">Greek</lang>
    </entry>
    <entry>
      <article>i </article>
      <lang codes="ita|nap|roa|scn">Italian</lang>
    </entry>
    <entry>
      <article>ih'</article>
      <lang codes="oci|pro|roa">Provençal</lang>
    </entry>
    <entry>
      <article>iha </article>
      <lang codes="lah|pan">Panjabi</lang>
      <lang codes="pan">Punjabi</lang>
    </entry>
    <entry>
      <article>ika </article>
      <lang codes="lah|pan">Panjabi</lang>
      <lang codes="pan">Punjabi</lang>
    </entry>
    <entry>
      <article>il </article>
      <lang codes="ita|nap|roa|scn">Italian</lang>
      <lang codes="oci|lan|pro">Occitan</lang>
      <lang codes="oci|pro|roa">Provençal</lang>
    </entry>
    <entry>
      <article>il-</article>
      <lang codes="mlt">Maltese</lang>
    </entry>
    <entry>
      <article>in </article>
      <lang codes="frs|fry|fri|gem|frr">Frisian</lang>
    </entry>
    <entry>
      <article>it </article>
      <lang codes="frs|fry|fri|gem|frr">Frisian</lang>
    </entry>
    <entry>
      <article>ka </article>
      <lang codes="cpe|haw">Hawaiian</lang>
    </entry>
    <entry>
      <article>ke </article>
      <lang codes="cpe|haw">Hawaiian</lang>
    </entry>
    <entry>
      <article>l'</article>
      <lang codes="cat">Catalan</lang>
      <lang codes="cpf|fre|frm|fro|hat|roa|sgn">French</lang>
      <lang codes="ita|nap|roa|scn">Italian</lang>
      <lang codes="oci|lan|pro">Occitan</lang>
      <lang codes="oci|pro|roa">Provençal</lang>
      <lang codes="wln">Walloon</lang>
    </entry>
    <entry>
      <article>l-</article>
      <lang codes="mlt">Maltese</lang>
    </entry>
    <entry>
      <article>la </article>
      <lang codes="cat">Catalan</lang>
      <lang codes="epo|esp">Esperanto</lang>
      <lang codes="cpf|fre|frm|fro|hat|roa|sgn">French</lang>
      <lang codes="ita|nap|roa|scn">Italian</lang>
      <lang codes="oci|lan|pro">Occitan</lang>
      <lang codes="oci|pro|roa">Provençal</lang>
      <lang codes="arg|crp|lad|roa|spa">Spanish</lang>
    </entry>
    <entry>
      <article>las </article>
      <lang codes="oci|lan|pro">Occitan</lang>
      <lang codes="oci|pro|roa">Provençal</lang>
      <lang codes="arg|crp|lad|roa|spa">Spanish</lang>
    </entry>
    <entry>
      <article>le </article>
      <lang codes="cpf|fre|frm|fro|hat|roa|sgn">French</lang>
      <lang codes="ita|nap|roa|scn">Italian</lang>
      <lang codes="oci|lan|pro">Occitan</lang>
      <lang codes="oci|pro|roa">Provençal</lang>
    </entry>
    <entry>
      <article>les </article>
      <lang codes="cat">Catalan</lang>
      <lang codes="cpf|fre|frm|fro|hat|roa|sgn">French</lang>
      <lang codes="oci|lan|pro">Occitan</lang>
      <lang codes="oci|pro|roa">Provençal</lang>
      <lang codes="wln">Walloon</lang>
    </entry>
    <entry>
      <article>lh </article>
      <lang codes="oci|lan|pro">Occitan</lang>
      <lang codes="oci|pro|roa">Provençal</lang>
    </entry>
    <entry>
      <article>lhi </article>
      <lang codes="oci|lan|pro">Occitan</lang>
      <lang codes="oci|pro|roa">Provençal</lang>
    </entry>
    <entry>
      <article>li </article>
      <lang codes="oci|lan|pro">Occitan</lang>
      <lang codes="oci|pro|roa">Provençal</lang>
    </entry>
    <entry>
      <article>lis </article>
      <lang codes="oci|lan|pro">Occitan</lang>
      <lang codes="oci|pro|roa">Provençal</lang>
    </entry>
    <entry>
      <article>lo </article>
      <lang codes="ita|nap|roa|scn">Italian</lang>
      <lang codes="oci|lan|pro">Occitan</lang>
      <lang codes="oci|pro|roa">Provençal</lang>
      <lang codes="arg|crp|lad|roa|spa">Spanish</lang>
    </entry>
    <entry>
      <article>los </article>
      <lang codes="oci|lan|pro">Occitan</lang>
      <lang codes="oci|pro|roa">Provençal</lang>
      <lang codes="arg|crp|lad|roa|spa">Spanish</lang>
    </entry>
    <entry>
      <article>lou </article>
      <lang codes="oci|lan|pro">Occitan</lang>
      <lang codes="oci|pro|roa">Provençal</lang>
    </entry>
    <entry>
      <article>lu </article>
      <lang codes="oci|lan|pro">Occitan</lang>
      <lang codes="oci|pro|roa">Provençal</lang>
    </entry>
    <entry>
      <article>mga </article>
      <lang codes="tgl|tag">Tagalog</lang>
    </entry>
    <entry>
      <article>mia </article>
      <lang codes="tut|grc|gre">Greek</lang>
    </entry>
    <entry>
      <article>'n </article>
      <lang codes="afr">Afrikaans</lang>
      <lang codes="afr|dut|dum|gem">Dutch</lang>
      <lang codes="frs|fry|fri|gem|frr">Frisian</lang>
    </entry>
    <entry>
      <article>na </article>
      <lang codes="cpe|haw">Hawaiian</lang>
      <lang codes="gle|iri|mga|sga">Irish</lang>
      <lang codes="gla">Scottish Gaelic</lang>
    </entry>
    <entry>
      <article>na h-</article>
      <lang codes="gle|iri|mga|sga">Irish</lang>
      <lang codes="gla">Scottish Gaelic</lang>
    </entry>
    <entry>
      <article>njē</article>
      <lang codes="alb">Albanian</lang>
    </entry>
    <entry>
      <article>ny </article>
      <lang codes="mlg|mla">Malagasy</lang>
    </entry>
    <entry>
      <article>'o </article>
      <lang codes="nap">Neapolitan Italian</lang>
    </entry>
    <entry>
      <article>o </article>
      <lang codes="glg|gag">Galician</lang>
      <lang codes="cpe|haw">Hawaiian</lang>
      <lang codes="cpp|nic|por">Portuguese</lang>
      <lang codes="rup|rum">Romanian</lang>
    </entry>
    <entry>
      <article>os </article>
      <lang codes="cpp|nic|por">Portuguese</lang>
    </entry>
    <entry>
      <article>'r </article>
      <lang codes="ice|non|sgn">Icelandic</lang>
    </entry>
    <entry>
      <article>'s </article>
      <lang codes="ger|gmh|goh|gem|nds|sco|gsw|yid">German</lang>
    </entry>
    <entry>
      <article>'t </article>
      <lang codes="afr|dut|dum|gem">Dutch</lang>
      <lang codes="frs|fry|fri|gem|frr">Frisian</lang>
    </entry>
    <entry>
      <article>ta </article>
      <lang codes="grc">Classical Greek</lang>
      <lang codes="tut|grc|gre">Greek</lang>
    </entry>
    <entry>
      <article>tais </article>
      <lang codes="grc">Classical Greek</lang>
    </entry>
    <entry>
      <article>tas </article>
      <lang codes="grc">Classical Greek</lang>
    </entry>
    <entry>
      <article>tē</article>
      <lang codes="grc">Classical Greek</lang>
    </entry>
    <entry>
      <article>tēn </article>
      <lang codes="grc">Classical Greek</lang>
      <lang codes="tut|grc|gre">Greek</lang>
    </entry>
    <entry>
      <article>tēs </article>
      <lang codes="grc">Classical Greek</lang>
      <lang codes="tut|grc|gre">Greek</lang>
    </entry>
    <entry>
      <article>the </article>
      <lang codes="cpe|eng|enm|ang|sco|sgn">English</lang>
    </entry>
    <entry>
      <article>to </article>
      <lang codes="grc">Classical Greek</lang>
      <lang codes="tut|grc|gre">Greek</lang>
    </entry>
    <entry>
      <article>tō</article>
      <lang codes="grc">Classical Greek</lang>
    </entry>
    <entry>
      <article>tois </article>
      <lang codes="grc">Classical Greek</lang>
    </entry>
    <entry>
      <article>ton </article>
      <lang codes="grc">Classical Greek</lang>
      <lang codes="tut|grc|gre">Greek</lang>
    </entry>
    <entry>
      <article>tōn </article>
      <lang codes="grc">Classical Greek</lang>
      <lang codes="tut|grc|gre">Greek</lang>
    </entry>
    <entry>
      <article>tou </article>
      <lang codes="grc">Classical Greek</lang>
      <lang codes="tut|grc|gre">Greek</lang>
    </entry>
    <entry>
      <article>um </article>
      <lang codes="cpp|nic|por">Portuguese</lang>
    </entry>
    <entry>
      <article>uma </article>
      <lang codes="cpp|nic|por">Portuguese</lang>
    </entry>
    <entry>
      <article>un </article>
      <lang codes="cat">Catalan</lang>
      <lang codes="cpf|fre|frm|fro|hat|roa|sgn">French</lang>
      <lang codes="ita|nap|roa|scn">Italian</lang>
      <lang codes="oci|lan|pro">Occitan</lang>
      <lang codes="oci|pro|roa">Provençal</lang>
      <lang codes="rup|rum">Romanian</lang>
      <lang codes="arg|crp|lad|roa|spa">Spanish</lang>
    </entry>
    <entry>
      <article>un'</article>
      <lang codes="ita|nap|roa|scn">Italian</lang>
    </entry>
    <entry>
      <article>una </article>
      <lang codes="cat">Catalan</lang>
      <lang codes="ita|nap|roa|scn">Italian</lang>
      <lang codes="oci|lan|pro">Occitan</lang>
      <lang codes="oci|pro|roa">Provençal</lang>
      <lang codes="arg|crp|lad|roa|spa">Spanish</lang>
    </entry>
    <entry>
      <article>une </article>
      <lang codes="cpf|fre|frm|fro|hat|roa|sgn">French</lang>
    </entry>
    <entry>
      <article>unei </article>
      <lang codes="rup|rum">Romanian</lang>
    </entry>
    <entry>
      <article>unha </article>
      <lang codes="glg|gag">Galician</lang>
    </entry>
    <entry>
      <article>uno </article>
      <lang codes="ita|nap|roa|scn">Italian</lang>
      <lang codes="oci|lan|pro">Occitan</lang>
      <lang codes="oci|pro|roa">Provençal</lang>
    </entry>
    <entry>
      <article>uns </article>
      <lang codes="oci|lan|pro">Occitan</lang>
      <lang codes="oci|pro|roa">Provençal</lang>
    </entry>
    <entry>
      <article>unui </article>
      <lang codes="rup|rum">Romanian</lang>
    </entry>
    <entry>
      <article>us </article>
      <lang codes="oci|lan|pro">Occitan</lang>
      <lang codes="oci|pro|roa">Provençal</lang>
    </entry>
    <entry>
      <article>y </article>
      <lang codes="cel|wel">Welsh</lang>
    </entry>
    <entry>
      <article>ye </article>
      <lang codes="cpe|eng|enm|ang|sco|sgn">English</lang>
    </entry>
    <entry>
      <article>yr </article>
      <lang codes="cel|wel">Welsh</lang>
    </entry>
  </xsl:variable>
</xsl:stylesheet>
