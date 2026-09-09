"""
Author: Ethan Gruber
Date: September 2026
Function: Read ProQuest PDF filenames and metadata from CSV and embed metadata into the PDF documents
This requires the installation of exiftool for command line use. On Windows, exiftool.exe and exiftool_files should be placed in C:/Windows
"""

import os, csv, exiftool
from exiftool import ExifTool, ExifToolHelper

def main():    
    count = 0
    with open('ProQuest-UVA-DAAP-Delivery-1-2026-INDEX.csv', 'r', encoding="utf-8") as file:
        reader = csv.DictReader(file)
        for row in reader:
            pdf = "FullTextPdfs/" + row["PUB NUMBER"] + ".pdf"
            print("Setting tags for", pdf)    
            
            #remove line breaks and limit abstract to 1999 characters, as per PDF limitation
            abstract = row["ABSTRACT"].replace("\n", " ")[:1999]
            keywords = ",".join(row["KEYWORD"].split("|"))   
            
            with ExifToolHelper() as et:
                                          
                et.set_tags(
                    pdf,
                    tags={"Author": row["AUTHOR"],
                          "Title": row["TITLE"],
                          "Subject": abstract,
                        "Keywords": keywords},
                    params=["-P", "-overwrite_original"]
                )
                
            
            #replace OCR with all ETDs published before 2000    
            if int(row["YEAR"]) < 2000:
                print("Replacing OCR")
                
                lang = row["DISS LANG"]
                
                if lang == "French":
                    lang = "fra"
                elif lang == "German":
                    lang = "deu"
                elif lang == "Spanish":
                    lang = "spa"
                else:
                    lang = "eng"
                    
                command = f"ocrmypdf --redo-ocr --output-type pdf --optimize 0 -l {lang} {pdf} {pdf}"
                
                #print(command)
                
                os.system(command)
                
                count = count + 1

if __name__ == "__main__":
    main()