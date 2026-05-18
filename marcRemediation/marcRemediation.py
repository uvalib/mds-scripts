#!/usr/bin/env python3

"""
Author: Ethan Gruber
Date: May 2026
Function: Intended to be executed by cron nightly, this script iterates through Sirsi in blocks of 50,000 MARC records
and then executes an XSLT transformation to fix known errors, and then reports unfixed errors and warnings to catalogers.
The stdout from the fixMarcErrors.xsl is also written into a log file.
"""

import argparse, os, re, subprocess, requests, sqlite3
import xml.etree.ElementTree as ET
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
    if len(lines) > 0:
        with open(today + ".errors.log", 'w+', encoding="utf-8") as file:    
            # write elements of list
            for line in lines:
                file.write('%s\n' %line)
        
            print("Wrote error log to " + today + ".errors.log")
        file.close()
    else:
        print("No errors to report.")
        
    #delete the XML report file after writing the text file
    print("Removed " + xml_report)
    os.remove(xml_report)
    
    #insert function call for processing logs into SQLite below
    update_db(today)

"""
BEGIN PROCESSING OF ARGUMENTS 
"""
#define and parse command line arguments
parser = argparse.ArgumentParser()
parser.add_argument("-s", "--start", help="Sirsi ckey to start")
parser.add_argument("-r", "--rows", help="Number of ckeys to extract")

args = parser.parse_args()
rows = 100 if not args.rows else int(args.rows)

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

#outputting the last ckey to a text file [rewrite this after ckeys can be extracted via API]
print("Processing completed. Writing " + today + ".ckeys")
ckeys_last = str(prevLastKey + rows)
with open(today + ".ckeys", 'w') as file:
    file.write(ckeys_last)


