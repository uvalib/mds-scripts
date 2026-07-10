#!/usr/bin/env python3

"""
Author: Ethan Gruber
Date: July 2026
Function: iterate through a directory structure of newspaper METS/ALTO files and perform validation and report errors 
"""

import glob, os, mmap, subprocess
import xml.etree.ElementTree as ET
from datetime import datetime

SAXON_PATH = "../../saxon/SaxonHE12-4J/saxon-he-12.4.jar"
ALTO_VERSION = "alto3"
#DOCUMENT_PATH = "\\topaz.storage.virginia.edu\digiserv-production\african-american-newspaper-project"
#african american newspapers: \\topaz.storage.virginia.edu\digiserv-production\african-american-newspaper-project

errors = []
warnings = []
namespaces = {'mods': 'http://www.loc.gov/mods/v3', 
              'mets': 'http://www.loc.gov/METS/',
              'alto2': 'http://www.loc.gov/standards/alto/ns-v2#',
              'alto3': 'http://www.loc.gov/standards/alto/ns-v3#',
              'xlink': 'http://www.w3.org/1999/xlink'}
#---------------------
#ALTO VALIDATION
#---------------------
def validate_alto(filename, fp):
    global errors
    global warnings
    
    hasError = False
    
    #print("Validating ALTO", fp)
    
    tree = ET.parse(fp)
    root = tree.getroot()
    
    for text_block in root.findall(f".//{ALTO_VERSION}:TextBlock", namespaces):
        lang = text_block.get('language')
        
        #evaluate the heights of empty text blocks
        if len(text_block) == 0:
            height = text_block.get('HEIGHT')
            if height is not None:
                height = int(height)
                
                if height >= 250:
                    hasError = True
                    msg = f"Error :: {fp} :: TextBlock {text_block.get('ID')} :: no content (height: {height})"
                    print(msg)
                    errors.append(msg)
                else:
                    msg = f"Warning :: {fp} :: TextBlock {text_block.get('ID')} :: no content (height: {height})"
                    warnings.append(msg)
        
        #search for missing or invalid language attributes on TextBlocks that contain TextLines
        text_lines = text_block.findall(f".//{ALTO_VERSION}:TextLine", namespaces)
        if len(text_lines) > 0:
            if not lang:
                msg = f"Error :: {fp} :: TextBlock {text_block.get('ID')} :: no language"
                warnings.append(msg)
            else:
                if len(lang) < 2 or len(lang) > 3:
                    hasError = True
                    msg = f"Error :: {fp} :: TextBlock {text_block.get('ID')} :: invalid language ({lang})"
                    errors.append(msg)
                     
        #evaluate the content length of child String elements
        for string in text_block.iter('{http://www.loc.gov/standards/alto/ns-v2#}String'):
            content = string.get("CONTENT")
            cc = string.get("CC").replace(" ", "")
            
            if len(content) != len (cc):
                hasError = True
                msg = f"Error :: {fp} :: String {string.get('ID')} :: content length mismatch"
                print(msg)
                errors.append(msg)
    
    if hasError == True:
        print("ALTO file contains errors: ", fp)

#---------------------
#METS VALIDATION
#---------------------
def validate_mets(filename, path):
    global errors
    global warnings
    
    hasError = False
    
    fp = os.path.join(path, filename)
    
    tree = ET.parse(fp)
    root = tree.getroot()
    
    #load and combine associated ALTO files
    combined = ET.Element("fileGrp")
    for alto in root.findall(".//mets:fileGrp[@ID = 'ALTOGRP']/mets:file", namespaces):
        fileID = alto.get("ID")
        fileElement = ET.SubElement(combined, "file", {"ID": fileID})
        
        flocat = alto.find("mets:FLocat", namespaces)
                
        #print(alto.get("ID"))
        altoFile = flocat.get("{http://www.w3.org/1999/xlink}href").replace("file://./", "").replace("/", "\\")
        altoFile = os.path.join(path, altoFile)
        
        data = ET.parse(altoFile).getroot()
        fileElement.append(data)
        
    #validate MODS
    for mods in root.iter("{http://www.loc.gov/mods/v3}mods"):
        for descendant in mods.iter("*"):
            #print(descendant.tag)
            if "date" in descendant.tag or "Date" in descendant.tag:
                tag = descendant.tag.replace('{http://www.loc.gov/mods/v3}', 'mods:')
                if descendant.get('encoding') != 'iso8601':
                    msg = f"Error :: {fp} :: {tag} :: encoding not iso8601"
                    warnings.append(msg)
                    
                #test the ISO8601 content
                date = descendant.text
                valid = is_valid_date(date)
                if valid == False:        
                    msg = f"Error :: {fp} :: {tag} :: invalid ISO date: {descendant.text}"
                    warnings.append(msg)
                    
    #validate METS
    dmdSec = {}
    
    #evaluate dmdSecs and load their ID and boolean value of whether they contain a mods:title into a dict
    for section in root.findall(".//mets:dmdSec", namespaces):
        id = section.get("ID")
        title = section.find(".//mods:title", namespaces)
        if title is not None:
            hasTitle = True
        else:
            hasTitle = False
        
        dmdSec[id] = hasTitle
        
        #ignore certain dmdSecs
        if id != 'MODSMD_PRINT' and id != 'MODSMD_ELEC':        
            div = root.find(f".//mets:div[@DMDID = '{id}']", namespaces)
            
            if div is not None:
                #proceed with validating the div
                divError = validate_div(div, hasTitle, fp, combined)
                if divError == True:
                    hasError = True
            else:
                hasError = True
                msg = f"Error :: {fp} :: dmdSec {id} :: No div in structMap"
                errors.append(msg)
                
    if hasError == True:
        print("METS file contains errors: ", fp)

#---------------------
#VALIDATE DIV, pass in the div element, boolean(hasTitle), file path, and the combined ALTO ElementTree
#---------------------
def validate_div(div, hasTitle, fp, combined):
    global errors
    global warnings
    
    hasError = False
    
    id = div.get("ID")
    dmdid = div.get("DMDID")
    
    advertisement = False
    
    #evaluate title
    for descendant in div.iter("{http://www.loc.gov/METS/}div"):
        if descendant.get("TYPE").lower() == 'advertisement':
            advertisement = True
    
    if hasTitle == False and advertisement == True:
        hasError = True
        msg = f"Error :: {fp} :: dmdSec {dmdid} :: No MODS title"        
        errors.append(msg)
        
    areas = div.findall(".//mets:fptr/mets:area", namespaces)
    
    if len(areas) == 0:
        hasError = True
        msg = f"Error :: {fp} :: div {id} :: No associated area element, or missing attributes"
        errors.append(msg)
    else:
        for area in areas:
            fileId = area.get("FILEID")
            blockId = area.get("BEGIN")

            altoFile = combined.find(f".//file[@ID = '{fileId}']")
            
            if altoFile is None:
                hasError = True
                msg = f"Error :: {fp} :: area in div {id} :: File ID not found in ALTO fileGrp"
                errors.append(msg)
            else:
                #xpath = ".//"
                descendant = altoFile.find(f".//{ALTO_VERSION}:*[@ID = '{blockId}']", namespaces)
                if descendant is None:
                    hasError = True
                    msg = f"Error :: {fp} :: area in div {id} :: Block ID {blockId} not found in ALTO XML"
                    errors.append(msg)
    
    return hasError    

#found this function here: https://www.slingacademy.com/article/python-ways-to-check-if-a-date-string-is-valid/  
def is_valid_date(date_str):
    # Checks if a date string is valid ISO 8601 format
    # Returns True if valid, False otherwise
    try:
        datetime.fromisoformat(date_str)
        return True
    except ValueError:
        return False

def main():    
    #iterate recursively through the 'current' folder relative to this Python script to look for XML files
    for path, dirs, files in os.walk(r"\\topaz.storage.virginia.edu\digiserv-production\african-american-newspaper-project\UVA_24-217-01\Article_Segmentation"):        
        
        xml_folder = [filename for filename in files if ".xml" in filename]
        if xml_folder:
            print("Examining", path)

        for filename in files:
            fp = os.path.join(path, filename)
            if ".xml" in filename:
                #print("Reading " + fp)
                
                # read the XML file and look for the METS or ALTO namespace string
                with open(fp, "r", encoding="utf-8") as file:
                    s = mmap.mmap(file.fileno(), 0, access=mmap.ACCESS_READ)
                    if s.find(b'http://www.loc.gov/METS/') != -1:    
                        validate_mets(filename, path)                 
                    elif s.find(b'http://www.loc.gov/standards/alto/') != -1:
                        validate_alto(filename, fp)
                        
    print("Process completed. Writing log file, if applicable.")
    
    #write all warnings and errors to single error.log text file, if there are any
    if len(errors) > 0:
        #create errors folder if it doesn't exist
        if not os.path.isdir("errors"):
            os.makedirs("errors")
        with open('errors/errors.log', 'w', encoding="utf-8") as file:
            text = '\n'.join(errors)
            file.write(text)
            
    if len(warnings) > 0:
        #create errors folder if it doesn't exist
        if not os.path.isdir("errors"):
            os.makedirs("errors")
        with open('errors/warnings.log', 'w', encoding="utf-8") as file:
            text = '\n'.join(warnings)
            file.write(text)
        
if __name__=="__main__":
    main()        
        