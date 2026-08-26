"""
Author: Ethan Gruber
Date: July 2026
Function: Read ProQuest PDF filenames and metadata from CSV and embed metadata into the PDF documents
This requires the installation of exiftool for command line use. On Windows, exiftool.exe and exiftool_files should be placed in C:/Windows
"""

import os, csv, exiftool
from exiftool import ExifTool, ExifToolHelper

#ExifTool(executable="../../../../../Program Files/ExifTool/ExifTool.exe")

def main():
    with open('ProQuest-test.csv', 'r', encoding="utf-8") as file:
        reader = csv.DictReader(file)
        for row in reader:
            pdf = "FullTextPdfs/" + row["ID"] + ".pdf"
            print("Setting tags for", pdf)
            with ExifToolHelper() as et:
                et.set_tags(
                    pdf,
                    tags={"Author": row["AUTHOR"],
                          "Title": row["TITLE"],
                          "Subject": row["ABSTRACT"],
                        "Keywords": ",".join(row["KEYWORD"].split("|"))},
                    params=["-P", "-overwrite_original"]
                )


if __name__ == "__main__":
    main()