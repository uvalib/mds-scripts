#!/usr/bin/env python3

"""
Author: Ethan Gruber
Date: May 2026
Function: Read error report logs from the nightly marcRemediation process 
and update an SQLite database with error or warning listings for MARC records.
Old errors and warnings should be removed after the same record has been reprocessed.
"""

import sqlite3
from datetime import datetime

#read error logs for the today variable
def update_db(today):
    print(today)
    create_table = """
    CREATE TABLE IF NOT EXISTS bib (
        id INTEGER PRIMARY KEY);
    """
    
    """
    try:
        with sqlite3.connect('report.db') as conn:
            cursor = conn.cursor()
            #create table if it doesn't exist
            cursor.execute(create_table)   
            conn.commit()
    
    except sqlite3.OperationalError as e:
        print(e) 
    """
    
now = datetime.now().isoformat()
print(now)
today = datetime.today().strftime('%Y%m%d')
update_db(today)