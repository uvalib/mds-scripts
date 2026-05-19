#!/usr/bin/env python3

"""
Author: Ethan Gruber
Date: May 2026
Function: Intended to be executed by cron nightly, this script iterates through Sirsi in blocks of 50,000 MARC records
and then executes an XSLT transformation to fix known errors, and then reports unfixed errors and warnings to catalogers.
The stdout from the fixMarcErrors.xsl is also written into a log file.
"""

import argparse, os, re, subprocess, requests, sqlite3, pymarc
import xml.etree.ElementTree as ET
import pymarc
from datetime import datetime
from datetime import timedelta

#load local function for processing reports into SQLite
from marcRemediation_reports import update_db

#ENV should be "test" or "prod"
ENV = "test"

dir = "/software/UVUL/Unicorn/Bincustom/MARC-maint/Validate" if ENV == "prod" else ""
SAXON_PATH = "../../saxon/SaxonHE12-4J/saxon-he-12.4.jar"

#FUNCTIONS
def process_marcxml (today, url):
        #define XML file names
    xml_file = today + ".xml"
    xml_upd = today + "-updated.xml"
    
    response = requests.get(url)
    if response.status_code == 200:
        with open(xml_file, 'wb') as file:
            file.write(response.content)
        file.close()
            
        #below this point is executed after file.write
        print('Downloaded ' + url + " to " + xml_file)
        
        #execute Saxon XSLT transformation of MARC XML extracted from Sirsi into fixed file
        cmd = 'java -jar ' + SAXON_PATH + ' -xsl:fixMarcErrors.xsl -s:' + xml_file + ' -o:' + xml_upd + ' 2> ' + today + '.changes.log'        
        result = subprocess.call(cmd, shell=True, text=True)
        
        print("Fixed MARC XML: " + xml_upd)
        
        create_report(today)
        
    else:
        print('Failed to download MARC XML from server.')


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

    #write lines back to text file, if there are any
    with open(today + ".errors.log", 'w+', encoding="utf-8") as file:  
        for line in lines:
            file.write('%s\n' %line) 
        file.close()    

    if len(lines) > 0:            
        # write elements of list
        print("Wrote error log to " + today + ".errors.log")
 
    #delete the XML report file after writing the text file
    print("Removed " + xml_report)
    os.remove(xml_report)
    
    #insert function call for processing logs into SQLite below
    update_db(today)
    
def cleanup(today, dryrun):
    print("Cleaning up XML. Moving log files to log folder.")

    #remove MARC XML
    os.remove(today + ".xml")
    os.remove(today + "-updated.xml")
    
    #if the script is a dryrun, then move the MARC 21 to marc folder, otherwise delete it
    if dryrun == 1:
        if not os.path.exists("marc"):
            os.makedirs("marc")
        os.replace(today + ".marc", "marc/" + today + ".marc")
    else:
        os.remove(today + ".marc")
    
    #create logs folder if it doesn't exist and move the logs there
    if not os.path.exists("logs"):
        os.makedirs("logs")
    os.replace(today + ".errors.log", "logs/" + today + ".errors.log")
    os.replace(today + ".changes.log", "logs/" + today + ".changes.log")

"""
BEGIN PROCESSING OF ARGUMENTS 
"""
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

# read the previous last key from yesterday's ckeys file, if it exists; default to 0 if it doesn't
today = datetime.today().strftime('%Y-%m-%d')
yesterday = (datetime.today() - timedelta(days = 1)).strftime('%Y-%m-%d')

#if the start argument is not set, then read prevLastKey from file
if not args.start:
    prevLastKey = 0
    try:
        with open(yesterday + ".ckeys", "r", encoding="utf-8") as file:
            line = file.readlines()[0]
            try:
                prevLastKey = int(line)
            except ValueError:
                print("prevLastKey is not an integer. Starting from 0")
                
    except IOError:
        print("There is no ckeys file from yesterday. Starting from 0")
else:
    prevLastKey = int(args.start)
    

#this is where the HTTP request goes to get the start and end ckeys 

#Request MARC XML file via command line or HTTP request based on ckeys extracted in previous step

ckeys = "u" + str(prevLastKey) + "-" + "u" + str(prevLastKey + rows)
url = "https://ils.lib.virginia.edu/uhtbin/getMarc?ckey=" + ckeys + "&type=xml"
process_marcxml(today, url)

#use PyMarc to convert the updated MARC XML back to MARC 21 for upload
with open(today + '.marc', 'wb') as file:
    for record in pymarc.parse_xml_to_array(open(today + '-updated.xml', 'rb')):
        file.write(record.as_marc())
print("MARC 21 written to " + today + ".marc")
file.close()

#code to upload to Sirsi goes here
if dryrun != 1:
    print("MARC 21 posted to Sirsi")    

#cleanup old files
cleanup(today, dryrun)

#outputting the last ckey to a text file [rewrite this after ckeys can be extracted via API]
print("Processing completed. Writing " + today + ".ckeys")
ckeys_last = str(prevLastKey + rows)
with open(today + ".ckeys", 'w') as file:
    file.write(ckeys_last)

