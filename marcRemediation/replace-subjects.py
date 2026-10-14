"""
Author: Ethan Gruber
Date: October 2026
Function: Iterate through ckeys in spreadsheet to download MARC file from getMarc API and replace deprecrated subject term with new one, in correct MARC field
"""

import csv, re, os, requests, math
from pymarc import MARCReader, MARCWriter

ROWS = 100

def main():
    count = 0
    ckeys = []
    marc = ""
   
    csv_data = list(csv.DictReader(open('all unauthorized 651.csv', newline='', encoding="utf-8")))
    
     #read unique Sirsi ckeys    
    for row in csv_data:
        if len(row["Catalog Id / Virgo link"]) > 0:
            ckey = "u" + row["Catalog Id / Virgo link"]
            if ckey not in ckeys:                                        
                ckeys.append(ckey)
                    
    
    #if the MARC data file doesn't exist, then fetch all related ckeys from getMarc API and combine into subjects.marc
    if not os.path.exists("marc/subjects.marc"):
        download_marc(ckeys)
    else:
        print("MARC already downloaded")
    
    #open file for processing    
    with open('marc/subjects.marc', 'rb') as file:
        reader = MARCReader(file)
        for record in reader:
            id = record["001"].value().replace("u", "")
            
            #fetch related 651 rows from the CSV file            
            rows = []
            for row in csv_data:
                if row["Catalog Id / Virgo link"] == id:
                    rows.append(row)
                    
            
            for f in record.get_fields('651'):
                print(f)
                
                #ask: does the trailing period need to be inserted back in?
        

def download_marc(ckeys):
    print("Downloading MARC")
    
    marc = ""
    total = len(ckeys)
    page = 0 #start page at 0 for the beginning
    while (page * ROWS) < 300:
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
    with open("marc/subjects.marc", 'w', encoding="utf-8") as file:
        file.write(marc)
    

if __name__=="__main__":
    main()