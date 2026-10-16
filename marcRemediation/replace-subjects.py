"""
Author: Ethan Gruber
Date: October 2026
Function: Iterate through ckeys in spreadsheet to download MARC file from getMarc API and replace deprecrated subject term with new one, in correct MARC field
"""

import csv, re, os, requests, math
from pymarc import MARCReader, MARCWriter, XMLWriter
from pymarc import Record, Field, Subfield, Indicators

ROWS = 100
INFILE = "marc/subjects.marc"
OUTFILE = "marc/subjects-updated.marc"

def main():
    count = 0
    ckeys = []
    marc = ""
   
    csv_data = list(csv.DictReader(open('new.csv', newline='', encoding="utf-8")))
    
     #read unique Sirsi ckeys    
    for row in csv_data:
        if len(row["Catalog Id / Virgo link"]) > 0:
            ckey = "u" + row["Catalog Id / Virgo link"]
            if ckey not in ckeys:                                        
                ckeys.append(ckey)
                    
    
    #if the MARC data file doesn't exist, then fetch all related ckeys from getMarc API and combine into subjects.marc
    if not os.path.exists(INFILE):
        download_marc(ckeys)
    else:
        print("MARC already downloaded")
    
    #delete updated marc file if it exists
    if os.path.exists(OUTFILE):
        os.remove(OUTFILE)
    
    #open file for processing    
    with open(INFILE, 'rb') as file:
        reader = MARCReader(file)
        for record in reader:
            id = record["001"].value().replace("u", "")
            
            #fetch related 651 rows from the CSV file            
            rows = []
            for row in csv_data:
                if row["Catalog Id / Virgo link"] == id:
                    rows.append(row)
                    
            
            for f in record.get_fields('651'):
                field = dict(f)
                
                #create a string that matches the structure of the tag in the CSV file
                string_match = ""
                for k, v in field.items():
                    if v[-1] == ".":
                        v = v[0:-1]               
                    if k != "a":
                        string_match += f"|{k}"
                    string_match += v
                
                string_match += ".|?UNAUTHORIZED"
                
                #iterate through CSV rows associated with ckey to look to see if it matches an invalid subject
                for row in rows:
                    if row["Tag value"] == string_match:
                        
                        #only add validated fields
                        if len(row["geo"]) > 0:
                            #if geo is false, then this field needs to be moved to a 650
                            if row["geo"] == "false":                                
                                tag = "650"
                            else:             
                                tag = "651"
                            
                            #compile the subfields
                            subfield_values = []                            
                            
                            #TODO! These must be reconstructed in the original order, not alpabetical by subfield code
                            for k, v in row.items():
                                if "label" in k:
                                    code = k[0]
                                    #look for labels: extract the subfield code and verify it is authorized by determining if the URI exists
                                    if len(row[f"{code}_uri"]) > 0:
                                        subfield_values.append({"code": code,
                                                                "value": v})
                            
                            #append trailing period to final value
                            subfield_values[-1]["value"] = subfield_values[-1]["value"] + "."
                            
                            #construct subfields object for Field
                            subfields = []
                            for subfield in subfield_values:
                                subfields.append(Subfield(code=subfield["code"], value=subfield["value"]))
                                        
                            #add the replacement field                        
                            record.add_ordered_field(
                                Field(
                                    tag = tag,
                                    indicators = Indicators(' ','0'),
                                    subfields = subfields                                   
                                    ))
                                    
                            #remove the old field
                            record.remove_field(f)
            if id == "3762509":            
                print(record)
            #with open(OUTFILE, 'ab') as out:
            #    out.write(record.as_marc())

def download_marc(ckeys):
    print("Downloading MARC")
    
    marc = ""
    total = len(ckeys)
    page = 0 #start page at 0 for the beginning
    while (page * ROWS) < total:
        start = page * ROWS
        end = (page + 1) * ROWS
        
        print("Page", str(page + 1), "of", str(math.ceil(total / ROWS)))
        
        ckey_param = ','.join(ckeys[start:end])
        
        #fetch and append MARC to marc variable
        url = "https://ils.lib.virginia.edu/uhtbin/getMarc?ckey=" + ckey_param + "&type=marc21"   
        response = requests.get(url)      
        marc += response.text
        
        page = page + 1
    
    #write aggregated MARC file
    if not os.path.exists("marc"):
        os.makedirs("marc")
    
    with open("marc/subjects.marc", 'w', encoding="utf-8") as file:
        file.write(marc)
    

if __name__=="__main__":
    main()
    