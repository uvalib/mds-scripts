#!/usr/bin/env python3

"""
Author: Ethan Gruber
Date: May 2026
Function: Intended to be executed by cron nightly, this script iterates through Sirsi in blocks of 50,000 MARC records
and then executes an XSLT transformation to fix known errors, and then reports unfixed errors and warnings to catalogers.
The stdout from the fixMarcErrors.xsl is also written into a log file.
"""

import argparse, os, re, subprocess, requests, sqlite3, pymarc, math
import xml.etree.ElementTree as ET
from datetime import datetime
from datetime import timedelta

#load local function for processing reports into SQLite
from marcRemediation_reports import update_db

#ENV should be "test" or "prod"
ENV = "test"
SAXON_PATH = "../../saxon/SaxonHE12-4J/saxon-he-12.4.jar"
MAX = 10000

#FUNCTIONS
def process_marcxml (today, url):
    #define XML file names
    xml_file = download_file(today, url)
    xml_upd = today + "-updated.xml"
    
    #below this point is executed after file.write
    print('Downloaded ' + url + " to " + xml_file)
    
    #execute Saxon XSLT transformation of MARC XML extracted from Sirsi into fixed file
    cmd = 'java -jar ' + SAXON_PATH + ' -xsl:fixMarcErrors.xsl -s:' + xml_file + ' -o:' + xml_upd + ' 2>> ' + 'logs/' + today + '.changes.log'        
    result = subprocess.call(cmd, shell=True, text=True)
    
    print("Fixed MARC XML: " + xml_upd)
    
    #generate the errors.log file from the updated MARC XML
    create_report(today)
    
    to_marc21(today)

#large HTTP request requires chunking
def download_file(today, url):
    xml_file = today + ".xml"
     
    # NOTE the stream=True parameter below
    with requests.get(url, stream=True) as r:
        r.raise_for_status()
        with open(xml_file, 'wb') as f:
            for chunk in r.iter_content(chunk_size=8192): 
                # If you have chunk encoded response uncomment if
                # and set chunk_size parameter to None.
                #if chunk: 
                f.write(chunk)
    return xml_file

def create_report(today):
    xml_upd = today + "-updated.xml"
    xml_report = today + "-report.xml"
    lines = []
    
    #execute Saxon XSLT tranformation of the updated XML in order to generate a report
    cmd = 'java -jar ' + SAXON_PATH + ' -xsl:marcValidation.xsl -s:' + xml_upd + ' -o:' + xml_report
    result = subprocess.call(cmd, shell=True, text=True)
    
    print("Generated " + xml_report)
    
    #parse report XML file and extract only the text messages for the report
    tree = ET.parse(xml_report)
    root = tree.getroot()
    namespaces = {'svrl': 'http://purl.oclc.org/dsdl/svrl'}
    for message in root.findall('./*', namespaces):
        type = message.get('role')
        
        #strip whitespaces from the XSLT file from the message, insert the @role attribute into the line
        #so that the SQLite db can be reloaded from text files if necessary
        text = message.find('svrl:text', namespaces).text.strip()
        line = re.sub('\\s+', ' ', text) + " :: " + type
        
        #write text back into array, which will be written to a text file
        lines.append(line)                    

    #append lines back to text file, if there are any
    with open("logs/" + today + ".errors.log", 'a', encoding="utf-8") as file:  
        for line in lines:
            file.write('%s\n' %line) 
        file.close()    

    if len(lines) > 0:            
        # write elements of list
        print("Wrote/appended error log to logs/" + today + ".errors.log")
        
    #write all ckeys to file so they can be removed from SQLite, and also write the last ckey as a single integer
    ckeys = extract_ckeys_from_xml(today)
 
    #delete the XML report file after writing the text file
    print("Removed " + xml_report)
    os.remove(xml_report)
    
#read ckeys via regex from XML file
def extract_ckeys_from_xml(today):
    ckeys = []
    
    with open(today + "-updated.xml", encoding="utf-8") as file:
        for line in file:
            m = re.findall('<controlfield tag="001">(u[0-9]+)</controlfield>', line)
            if m:
                ckeys.append(m[0])
                
    
    #append 
    with open(today + ".ckeys", 'a') as file:
        for ckey in ckeys:
            file.write('%s\n' %ckey) 
        file.close()    
     
    #writing the last ckey to a file
    ckeys_last = ckeys[-1].replace("u", "")
    print("Writing " + today + ".last.ckeys")
    with open(today + ".last.ckeys", 'w') as file:
        file.write(ckeys_last)
    
    return ckeys
    
def to_marc21(today):
    #use PyMarc to convert the updated MARC XML back to MARC 21 for upload
    with open(today + '.marc', 'ab') as file:
        for record in pymarc.parse_xml_to_array(open(today + '-updated.xml', 'rb')):
            file.write(record.as_marc())
    print("MARC 21 written to " + today + ".marc")
    file.close()  

#create folders as necessary and delete residual files that might be used for iterations
def prepare_files(today):  
    #create logs folder if it doesn't exist
    if not os.path.exists("logs"):
        os.makedirs("logs")
        
    #delete log files for today if they exist.
    try:
        os.remove("logs/" + today + ".changes.log")
    except OSError:
        pass
    try:
        os.remove("logs/" + today + ".errors.log")
    except OSError:
        pass
    
    #delete existing ckeys file from today
    try:
        os.remove(today + ".ckeys")
    except OSError:
        pass

def cleanup(today, dryrun):
    print("Cleaning up XML.")

    #remove MARC XML
    os.remove(today + ".xml")
    os.remove(today + "-updated.xml")
    
    #delete existing ckeys file from today
    try:
        os.remove(today + ".ckeys")
    except OSError:
        pass
    
    #if the script is a dryrun, then move the MARC 21 to marc folder, otherwise delete it
    if dryrun == 1:
        if not os.path.exists("marc"):
            os.makedirs("marc")
        os.replace(today + ".marc", "marc/" + today + ".marc")
    else:
        #remove MARC 21 file after posting to Sirsi
        os.remove(today + ".marc")
        
    print("Process completed")


"""
BEGIN PROCESSING OF ARGUMENTS 
"""

# read the previous last key from yesterday's ckeys file, if it exists; default to 0 if it doesn't
today = datetime.today().strftime('%Y-%m-%d')
yesterday = (datetime.today() - timedelta(days = 1)).strftime('%Y-%m-%d')

#create folders and purge existing files for today on initial execution of this script
prepare_files(today)

#define and parse command line arguments
parser = argparse.ArgumentParser()
parser.add_argument("-s", "--start", help="Sirsi ckey to start")
parser.add_argument("-r", "--rows", help="Number of ckeys to extract")
parser.add_argument("-d", "--dryrun", help="Any value set to dryrun will generate all log files, but will not post MARC 21 to Sirsi")

args = parser.parse_args()
rows = 100 if not args.rows else int(args.rows)

dryrun = 1 if args.dryrun is not None else 0

if dryrun == 1:
    print("Script is running in dryrun mode. MARC 21 file will be stored in marc folder, but not posted to Sirsi.")

#if the start argument is not set, then read prevLastKey from file
if not args.start:
    prevLastKey = 0
    try:
        with open(yesterday + ".last.ckeys", "r", encoding="utf-8") as file:
            line = file.readlines()[0]
            try:
                prevLastKey = int(line)
            except ValueError:
                print("prevLastKey is not an integer. Starting from 0")
                
    except IOError:
        print("There is no ckeys file from yesterday. Starting from 0")
else:
    prevLastKey = int(args.start)

#Request MARC XML file via HTTP request based on ckeys extracted in previous step
record_count = rows if rows < 10000 else 10000

for i in range(math.ceil(rows / MAX)):  
    if (rows > 10000):
        print("Requesting batch " + str(i + 1) + " of " + str(math.ceil(rows / MAX)))  
    if i == 0:
        start_ckey = "u" + str(prevLastKey)
        url = "https://ils.lib.virginia.edu/uhtbin/getMarc?start_ckey=" + start_ckey + "&record_count=" + str(record_count) + "&type=xml"
        process_marcxml(today, url)
    else:
        with open(today + ".last.ckeys", "r", encoding="utf-8") as file:
            start_ckey = "u" + file.readlines()[0]
            url = "https://ils.lib.virginia.edu/uhtbin/getMarc?start_ckey=" + start_ckey + "&record_count=" + str(record_count) + "&type=xml"
            process_marcxml(today, url)
            
#code to upload to Sirsi goes here
if dryrun != 1:
    print("MARC 21 posted to Sirsi") 

#the SQLite database is updated once from the aggregated error log, at the end of the iterative process.
update_db(today)

#cleanup old files
cleanup(today, dryrun)
