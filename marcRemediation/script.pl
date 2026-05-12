#!/usr/local/sirsi/bin/perl
BEGIN {
	unshift @INC, "/software/UVUL/Unicorn/Bincustom/Perl";
}
use UVa::lib;
do_environ();
$dir = "/software/UVUL/Unicorn/Bincustom/MARC-maint/Validate";
chdir($dir);
$saxon_dir = "$dir/Saxon"; # 

if ($ARGV[0] =~ m/^[1-9][0-9]*$/) {
	$number = $ARGV[0];
}
else {
	$number = 50000;
}
chomp($today = `transdate -d-0`);
chomp($yest  = `transdate -d-1`);
if (-s "$yest.ckeys") {
	chomp($prevLastKey = `tail -1 $yest.ckeys`); 
	$prevLastKey =~ s/\|$//;
}
else {
	$prevLastKey = 0;
}
$today_sql   = gen_sql($today,$prevLastKey,$number); 
$ckeys_file  = "$today.ckeys";
$xml_file    = "$today.xml";
$xml_upd     = "$today-updated.xml";
$xml_rpt_a   = "$today-report-a.xml";
$xml_rpt_b   = "$today-report-b.xml";
$marc_reload = "$today-updated.mrc";
system("sirsisql < $today_sql 2>sirsisql.$today.msg | selcatalog -iC -f MONOGRAPH,MAP,MANUSCRPT,MUSIC,MRDF,SERIAL,VM,MARC > $ckeys_file 2> selcatalog.$today.msg ");
$params  = "ckeys_file=$ckeys_file";
$params .= " type=xml";
$params .= " include999=yes";
$getMarcPath = "/software/apache/UVUL/cgi-bin/";
system("$getMarcPath/getMarc $params |  grep -vE '^Expires:|^Date:|^Content-Type:|^.\$' > $xml_file");

# PATH in environ to java is /usr/local/java/latest-jdk8/bin/java. Using it instead of $java8 or $java11
#$java11 = "/usr/local/java/latest-jdk11/bin/java"; # 
#$java11 = "/usr/local/java/amazon-corretto-11.0.5.10.1-linux-x64/bin/java";
#$java8  = "/usr/local/java/jdk1.8.0_151/bin/java";
#$java8  = "/usr/local/java/latest-jdk8/bin/java";

chomp($bincustom = `gpn bincustom`);
$marc4j_jar = "$bincustom/marc4j-2.8.2.jar";
$saxon_jar  = "$saxon_dir/SaxonHE12-4J/saxon-he-12.4.jar";

system("java -jar $saxon_jar -s:$xml_file -xsl:$saxon_dir/fixMarcErrors.xsl -o:$xml_upd 2> $today.messages ");
system("java -jar $marc4j_jar to_utf8 -combine 999 < $xml_upd > $marc_reload");
system("java -jar $saxon_jar -s:$xml_file -xsl:$saxon_dir/marcValidation.xsl -o:$xml_rpt_a");
system("java -jar $saxon_jar -s:$xml_upd  -xsl:$saxon_dir/marcValidation.xsl -o:$xml_rpt_b");

sub gen_sql {
	$today2 = shift(@_);
	$start = shift(@_);
	$count = shift(@_);
	$sql = "SELECT catalog_key FROM catalog WHERE catalog_key > $start AND rownum <= $count ORDER BY catalog_key\n";
	open(SQL, ">$today2.sql") or die "Failed to create $today2.sql\n";
	print SQL $sql;
	#print STDOUT $sql;
	close(SQL); 
	return "$today2.sql";
}
