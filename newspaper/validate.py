#!/usr/bin/env python3

#Author: Ethan Gruber
#Date: April 2026
#Function: iterate through a directory structure of newspaper METS/ALTO files and perform validation and report errors 

import glob
import os
import mmap
import subprocess
import xml.etree.ElementTree as ET

SAXON_PATH = "../../saxon/SaxonHE12-4J/saxon-he-12.4.jar"
errors = 0

#create errors folder
if not os.path.exists("errors"):
    os.makedirs("errors")

def validate(path, filename, fp, schema):
    global errors
    print("Processing " + schema + ": " + filename)
    #print(path)
    
    #execute XSLT process for XML content error report
    cmd = ''
    
    if schema == 'alto':
        cmd = 'java -jar ' + SAXON_PATH + ' -xsl:validate-alto.xsl -s:' + fp + " filename=" + filename
    else:
        cmd = 'java -jar ' + SAXON_PATH + ' -xsl:validate-mets.xsl -s:' + fp + " path=" + path + " filename=" + filename
    
    result = subprocess.check_output(cmd, shell=True, text=True)
    #print(result)
    
    #process XML response
    root = ET.fromstring(result)
    if root.get('error') == 'true' or root.get('warning') == 'true':
        print("Errors or warnings reported")
        errors += 1
        with open("errors/" + filename.replace('.xml', '') + "-errors.xml", "w", encoding="utf-8") as f:
            f.write(result)


#report number of errors
if errors > 0:
    print("File errors reported: " + errors + ". See errors folder for individual reports.")

#iterate recursively through the 'current' folder relative to this Python script to look for XML files
for path, dirs, files in os.walk(r"current"):
    for filename in files:
        fp = os.path.join(path, filename)
        if ".xml" in filename:
            #print("Reading " + fp)
            
            # read the XML file and look for the METS or ALTO namespace string
            with open(fp, "r", encoding="utf-8") as file:
                s = mmap.mmap(file.fileno(), 0, access=mmap.ACCESS_READ)
                if s.find(b'http://www.loc.gov/METS/') != -1:    
                    out = validate(path, filename, fp, schema='mets')                    
                elif s.find(b'http://www.loc.gov/standards/alto/ns-v2#') != -1:
                    out = validate(path, filename, fp, schema='alto')