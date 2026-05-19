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
def profile(bib):
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

if __name__ == '__main__':
    app.run(debug=False)