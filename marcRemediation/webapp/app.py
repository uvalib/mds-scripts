#!/usr/bin/env python3

"""
Author: Ethan Gruber
Date modified: May 2026
Function: Simple Python Flask web app to display marcRemediation reports stored in SQLite
"""

from flask import Flask, render_template, request
import sqlite3, math

DATABASE = '../report.db'
LIMIT = 25

app = Flask(__name__)

@app.route('/')
@app.route('/home')
def index():
    page = request.args.get('page', 1, type=int)  # Get page number from query params (default = 1)
    offset = (page - 1) * LIMIT
    
    bibs_count_sql = """SELECT COUNT(id)
    FROM bibs
    """
        
    #query bibs, order by most recent by default
    bibs_sql = """SELECT DISTINCT(bib_id), bibs.date
    FROM bibs_messages
    INNER JOIN bibs ON bibs.id = bibs_messages.bib_id
    INNER JOIN messages ON messages.id = bibs_messages.message_id
    ORDER BY bibs.date DESC
    """    
    pagination = 'LIMIT ' + str(LIMIT) + ' OFFSET ' + str(offset)
    
    connect = sqlite3.connect(DATABASE)
    cursor = connect.cursor()
    
    #fetch bibs
    cursor.execute(bibs_sql + ' ' + pagination)
    bibs = cursor.fetchall()
    
    #get total count of bibs for the message and then formulate the last page for pagination
    cursor.execute(bibs_count_sql)
    count = cursor.fetchone()
    count = int(count[0])
    
    last = math.ceil(count / LIMIT)
    
    
    return render_template('page.html', page="index", bibs=bibs, limit=LIMIT, count=count, page_num=page, last=last)

#make query for a single bib_id and return a list of all errors and warnings
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

#get a list of all messages. These are relatively limited and do not need to be paginated
@app.route('/message')
def page_messages():
    sql = """SELECT messages.id, messages.message, messages.type, COUNT(DISTINCT bibs_messages.bib_id)
    FROM messages
    INNER JOIN bibs_messages ON bibs_messages.message_id = messages.id
    GROUP BY messages.id
    ORDER BY messages.type ASC, COUNT(DISTINCT bibs_messages.bib_id) DESC
    """
    connect = sqlite3.connect(DATABASE)
    cursor = connect.cursor()
    
    #fetch bibs
    cursor.execute(sql)
    rows = cursor.fetchall()
    
    return render_template("page.html", page="messages", rows=rows)

#get bibs associated with a message id, paginated.
@app.route('/message/<message>')
def page_message(message):
    page = request.args.get('page', 1, type=int)  # Get page number from query params (default = 1)
    offset = (page - 1) * LIMIT
    
    bibs_count_sql = """SELECT COUNT(DISTINCT(bib_id))
    FROM bibs_messages
    WHERE message_id = ? 
    """
    
    #query bibs associated with the error message id, order by most recent by default
    bibs_sql = """SELECT DISTINCT(bib_id), bibs.date
    FROM bibs_messages
    INNER JOIN bibs ON bibs.id = bibs_messages.bib_id
    WHERE message_id = ?
    ORDER BY bibs.date DESC
    """    
    pagination = 'LIMIT ' + str(LIMIT) + ' OFFSET ' + str(offset)
    
    #query message metadata based on message id
    message_sql = """SELECT id, message, type
    FROM messages
    WHERE id = ?
    """
    
    connect = sqlite3.connect(DATABASE)
    cursor = connect.cursor()
    
    #fetch bibs
    cursor.execute(bibs_sql + ' ' + pagination, (message,))
    bibs = cursor.fetchall()
    
    #get total count of bibs for the message and then formulate the last page for pagination
    cursor.execute(bibs_count_sql, (message,))
    count = cursor.fetchone()
    count = int(count[0])
    
    last = math.ceil(count / LIMIT)
    
    #fetch message
    cursor.execute(message_sql, (message,))
    message_row = cursor.fetchone()

    return render_template("page.html", page="message", message=message_row, bibs=bibs, limit=LIMIT, count=count, page_num=page, last=last)

if __name__ == '__main__':
    app.run(debug=False)