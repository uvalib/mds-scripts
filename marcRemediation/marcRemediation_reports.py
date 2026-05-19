#!/usr/bin/env python3

"""
Author: Ethan Gruber
Date: May 2026
Function: Read error report logs from the nightly marcRemediation process 
and update an SQLite database with error or warning listings for MARC records.
Old errors and warnings should be removed after the same record has been reprocessed.
"""

import sqlite3, uuid, sys
from datetime import datetime
import xml.etree.ElementTree as ET

#read error logs for the today variable
def update_db(today):
    db = 'report.db'
    filename = "logs/" + today + ".errors.log"
    
    #create tables if necessary
    create_tables(db)    
    
    #purge all bib numbers from this batch from the database before reloading updated error list    
    all_bibs = read_bibs_from_xml(today)
    delete_bibs_from_db(db, all_bibs)    
    
    #get the messages list from the messages table, to prevent from creating duplicate messages
    messages = load_messages(db)
    bibs = []
    
    #lists of tuples for updated the database
    messages_rows = []
    bibs_rows = []
    bibs_messages_rows = []
    
    #load error log for processing 
    try:
        with open(filename, 'r') as file:
            for line in file:
                line = line.strip()
                
                parts = line.split(' :: ')
                
                #insert unique bib number and today's date into bibs table
                if parts[0] not in bibs:
                    bibs.append(parts[0])
                    bib_row = (parts[0], today)
                    bibs_rows.append(bib_row)
                
                #begin parsing of the lines into tuples. generate a new unique list that isn't already in the messages table
                if parts[1] not in messages:
                    messages.append(parts[1])
                    id = str(uuid.uuid3(uuid.NAMESPACE_URL, parts[1]))
                    
                    message_row = (id, parts[1], parts[2])
                    messages_rows.append(message_row)
                    
                #insert, potentially repeated error messages bibs into bibs_messages table
                bib_message_row = (parts[0], str(uuid.uuid3(uuid.NAMESPACE_URL, parts[1])))
                bibs_messages_rows.append(bib_message_row)
                
    except OSError:
        print("Could not open/read file:", filename)
        
        
    #SQLite CRUD
    
    #succcessfully tested
    if len(messages_rows) > 0:
        insert_data(db, 'messages', messages_rows)
    else:
        print("No new error messages to update.")
    
    if len(bibs_rows) > 0:
        insert_data(db, 'bibs', bibs_rows)
        insert_data(db, 'bibs_messages', bibs_messages_rows)
    else:
        print("No errors to report.")

#insert rows into table
def insert_data(db, table, rows):
    print("Inserting", len(rows), "rows into", table)
    
    if table == 'messages':
        sql = 'INSERT INTO messages(id, message, type) VALUES(?,?,?)'
    elif table == 'bibs':
        sql = 'INSERT INTO bibs(id, date) VALUES(?,date(?))'
    elif table == 'bibs_messages':
        sql = 'INSERT INTO bibs_messages(bib_id, message_id) VALUES(?,?)'
    
    conn = sqlite3.connect(db)
    cursor = conn.cursor()
    cursor.executemany(sql, rows)
    conn.commit()

#load existing messages from messages table into list to prevent duplication        
def load_messages(db):
    messages = []
    conn = sqlite3.connect(db)
    cursor = conn.cursor()
    cursor.execute('SELECT message FROM messages')            
    rows = cursor.fetchall()
    
    for row in rows:
        messages.append(row[0])
    
    return messages


#create SQLite tables if they don't exist
def create_tables(db):
    create_messages = """
    CREATE TABLE IF NOT EXISTS messages (
        id text PRIMARY KEY,
        message text,
        type text);
    """    
    create_bibs = """
    CREATE TABLE IF NOT EXISTS bibs (
        id text PRIMARY KEY,
        date text);
    """    
    #bib_id matches the Sirsi control id in the bibs table and the message_id matches the UUID id in the messages table
    create_bibs_messages = """
    CREATE TABLE IF NOT EXISTS bibs_messages (
        bib_id text,
        message_id text,
        foreign key(bib_id) references bibs(id),
        foreign key(message_id) references messages(id));
    """    
    try:
        with sqlite3.connect(db) as conn:
            cursor = conn.cursor()
            #create table if it doesn't exist
            cursor.execute(create_messages)   
            cursor.execute(create_bibs)   
            cursor.execute(create_bibs_messages)
            conn.commit()
    
    except sqlite3.OperationalError as e:
        print(e) 
        sys.exit(1)


#purge all bibs and associated error messages from the current batch so that the current error list is always up to date
def delete_bibs_from_db(db, bibs):
    
    conn = sqlite3.connect(db)
    cursor = conn.cursor()
    
    print("Removing", len(bibs), "records and associated error messages from database.")
    for id in bibs:
        cursor.execute('DELETE FROM bibs WHERE id = ?', (id,))
        cursor.execute('DELETE FROM bibs_messages WHERE bib_id = ?', (id,))        
    
    conn.commit()

#parse the updated MARC XML file and extract a full list of bib IDs
def read_bibs_from_xml(today):
    xml_upd = today + "-updated.xml"
    namespaces = {'marc': 'http://www.loc.gov/MARC21/slim'}
    
    bibs = []
    tree = ET.parse(xml_upd)
    root = tree.getroot()
    
    ids = root.findall(".//marc:controlfield[@tag = '001']", namespaces)
    for id in ids:
        bibs.append(id.text)
        
    #print(bibs)
    return bibs
 
def main():
    #define variables. now is the ISO date
    today = datetime.today().strftime('%Y-%m-%d')
    update_db(today)
    
if __name__=="__main__":
    main()