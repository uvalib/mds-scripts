#!/usr/bin/env python3

"""
Author: Ethan Gruber
Date modified: May 2026
Function: Simple Python Flask web app to display marcRemediation reports stored in SQLite
"""

from flask import Flask, render_template, request
import sqlite3

DATABASE = '../report.db'

app = Flask(__name__)

@app.route('/')
@app.route('/home')
def index():
    return render_template('page.html', page="index")

@app.route('/bib/<bib>')
def page_bib(bib):
    sql = """SELECT message_id, message, type
    FROM bibs_messages
    INNER JOIN messages ON messages.id = bibs_messages.message_id
    WHERE bib_id = ?
    """
    connect = sqlite3.connect(DATABASE)
    cursor = connect.cursor()
    
    cursor.execute(sql, (bib,))

    rows = cursor.fetchall()
    return render_template("page.html", page="bib", bib=bib, rows=rows)

@app.route('/message/<message>')
def page_message(message):
    
    #query bibs associated with the error message id
    bibs_sql = """SELECT bib_id, bibs.date
    FROM bibs_messages
    INNER JOIN bibs ON bibs.id = bibs_messages.bib_id
    WHERE message_id = ?
    """
    
    #query message metadata based on message id
    message_sql = """SELECT id, message, type
    FROM messages
    WHERE id = ?
    """
    
    connect = sqlite3.connect(DATABASE)
    cursor = connect.cursor()
    
    #fetch bibs
    cursor.execute(bibs_sql, (message,))
    bibs = cursor.fetchall()
    
    #fetch message
    cursor.execute(message_sql, (message,))
    message_row = cursor.fetchone()
    #return message_row
    return render_template("page.html", page="message", message=message_row, bibs=bibs)

if __name__ == '__main__':
    app.run(debug=False)