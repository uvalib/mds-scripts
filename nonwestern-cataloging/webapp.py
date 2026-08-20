#!/usr/bin/env python3

"""
Author: Ethan Gruber
Date modified: August 2026
Function: Simple Python Flask web app to interact with Amazon Bedrock AI API 
    to process images to generate MARC records for non-Western materials
"""

import os, sys
from flask import Flask, flash, request, redirect, url_for, render_template, session
from werkzeug.utils import secure_filename

import extract_book_metadata, marc_from_image

#import 

UPLOAD_FOLDER = 'uploads'
ALLOWED_EXTENSIONS = {'jpg', 'jpeg'}
api_key = os.environ.get("AWS_BEARER_TOKEN_BEDROCK")
if not api_key:
    sys.exit("Error: no API key found. Set the AWS_BEARER_TOKEN_BEDROCK environment variable")

app = Flask(__name__)
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER
app.config['MAX_CONTENT_LENGTH'] = 16 * 1024 * 1024
app.secret_key = os.urandom(24)

def allowed_file(filename):
    return '.' in filename and \
           filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

@app.route('/', methods=['GET', 'POST'])
def upload_file():
    if request.method == 'POST':
        # check if the post request has the file part
        if 'file' not in request.files:
            flash('No file part')
            return redirect(request.url)
        
        #file = request.files['file']
        files = request.files.getlist("file")
        process_type = request.form.get("type")
        session['process_type'] = process_type
        
        for file in files:
            if file and allowed_file(file.filename):            
                filename = secure_filename(file.filename)
                
                #upload file
                file.save(os.path.join(app.config['UPLOAD_FOLDER'], filename))
                

            
        #initiate OCR process
        
         
        return redirect(url_for('report'))
    
    #display upload page if that is not being POSTed
    return render_template('upload.html')

@app.route('/report')
def report():    
    process_type = session.get('process_type', None)
    
    return render_template("report.html", process_type=process_type)



if __name__ == '__main__':  
    #run debug with flask --app webapp run --debug
   app.run(debug=True)  