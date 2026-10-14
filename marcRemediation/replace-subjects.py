"""
Author: Ethan Gruber
Date: October 2026
Function: Iterate through ckeys in spreadsheet to download MARC file from getMarc API and replace deprecrated subject term with new one, in correct MARC field
"""

import csv, re, os, requests
from pymarc import MARCReader, MARCWriter

def main():
    count = 0
    ckeys = []
    with open('all unauthorized 651.csv', newline='', encoding="utf-8") as csvfile:
        reader = list(csv.DictReader(csvfile))
        
        #read unique Sirsi ckeys 
        for row in reader:
            if len(row["Catalog Id / Virgo link"] > 0):
                ckey = "u" + row["Catalog Id / Virgo link"]
                if ckey not in ckeys:  
                    #ensure the API request is only made once per ckey                    
                    ckeys.append(ckey)
        

def load_marc(ckey):
    url = f"https://ils.lib.virginia.edu/uhtbin/getMarc?ckey={ckey}&type=marc21"
                
    response = requests.get(url)
    reader = MARCReader(response.content)
    for record in reader:
        for f in record.get_fields('651'):
            print(f["a"])

if __name__=="__main__":
    main()