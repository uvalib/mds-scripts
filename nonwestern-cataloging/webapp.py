#!/usr/bin/env python3

"""
Author: Ethan Gruber
Date modified: August 2026
Function: Simple Python Flask web app to interact with Amazon Bedrock AI API 
    to process images to generate MARC records for non-Western materials
"""

import os, sys, uuid, json
from flask import Flask, flash, request, redirect, url_for, render_template, session, send_from_directory
from werkzeug.utils import secure_filename
from pathlib import Path

import extract_book_metadata, json_to_marc, marc_from_image

#import 
DEFAULT_MODEL = "anthropic.claude-sonnet-5"
AGENCY_CODE = "ViU"
ALLOWED_EXTENSIONS = {'jpg', 'jpeg'}
UPLOAD_FOLDER = "uploads"
DOWNLOAD_FOLDER = "downloads"
api_key = os.environ.get("AWS_BEARER_TOKEN_BEDROCK")
if not api_key:
    sys.exit("Error: no API key found. Set the AWS_BEARER_TOKEN_BEDROCK environment variable")

app = Flask(__name__)
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER
app.config['DOWNLOAD_FOLDER'] = DOWNLOAD_FOLDER
app.config['MAX_CONTENT_LENGTH'] = 16 * 1024 * 1024
app.secret_key = os.urandom(24)


def process_file(files, process_type, lang):
    if not os.path.isdir(DOWNLOAD_FOLDER):
        os.mkdir(DOWNLOAD_FOLDER)
            
    #generate a UUID for output files, but will remain consistent upon first uploaded filename
    data_filename = str(uuid.uuid3(uuid.NAMESPACE_DNS, files[0].filename))
    session['data_filename'] = data_filename
    prefix = Path(os.path.join(app.config['DOWNLOAD_FOLDER'], data_filename))
    
    if process_type == 'printout':
        image_path = os.path.join(app.config['UPLOAD_FOLDER'], files[0].filename)
        
        #Use LLM to perform OCR and generate MARC records
        print("Sending printout scan to LLM.")
        parsed = marc_from_image.call_claude(image_path, DEFAULT_MODEL, api_key)
        
        record = marc_from_image.build_record(parsed)    
        print("\n--- Parsed record preview ---")
        print(record)
        marc_from_image.write_outputs(record, prefix)        
        
    elif process_type == 'page':
        image_paths = []
        for file in files:
            image_paths.append(os.path.join(app.config['UPLOAD_FOLDER'], file.filename))
        
        #use LLM to OCR page images
        print("Sending page images to LLM.")
        raw_response = extract_book_metadata.call_claude(image_paths, DEFAULT_MODEL, api_key)
        
        print("Output raw response\n")
        print(raw_response)
        
        """cleaned_text = extract_book_metadata.clean_text(raw_response)
        
        rows = json.loads(cleaned_text)
        #process JSON response from LLM into MARC
        record = json_to_marc.build_record(rows, orig_lang=lang, country_override=None, agency=AGENCY_CODE)
        
        print("\n--- Parsed record preview ---")
        print(record)
        marc_from_image.write_outputs(record, prefix)
        
        
        try:
            rows = json.loads(cleaned_text)
        except:
            print("Error loading JSON response.")
            return redirect(url_for('error'))
        else:
        """
            
            
    return data_filename
        

def allowed_file(filename):
    return '.' in filename and \
           filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS


# ---------------------
# PAGES
# ---------------------
@app.route('/', methods=['GET', 'POST'])
def upload_file():
    if request.method == 'POST':
        if not os.path.isdir(UPLOAD_FOLDER):
            os.mkdir(UPLOAD_FOLDER)
        
        # check if the post request has the file part
        if 'file' not in request.files:
            flash('No file part')
            return redirect(request.url)
        
        files = request.files.getlist("file")
        process_type = request.form.get("type")
        lang = request.form.get("lang")
        session['process_type'] = process_type
        
        for file in files:
            if file and allowed_file(file.filename):            
                filename = secure_filename(file.filename)                
                #upload file
                file.save(os.path.join(app.config['UPLOAD_FOLDER'], filename))
        
        #initiate OCR process        
        data_filename = process_file(files, process_type, lang)
        
        return redirect(url_for('report', id=data_filename))
        
    
    #display upload page if that is not being POSTed
    return render_template('upload.html')
    
@app.route('/downloads/<filename>', methods=['GET', 'POST'])
def download_file (filename):
    return send_from_directory(app.config['DOWNLOAD_FOLDER'], filename)    

@app.route('/report/<id>')
def report(id):    
    #    process_type = session.get('process_type', None)    
    if os.path.isfile(os.path.join(app.config['DOWNLOAD_FOLDER'], id + ".mrk")) == True:
        with open(os.path.join(app.config['DOWNLOAD_FOLDER'], id + ".mrk"), 'r') as file:
            data = file.read()
            return render_template("report.html", data_filename=id, data=data)    
    else:
        return "Error: no associated MARC metadata found for ID provided."
    
@app.route('/error')
def error():    
    return "Indeterminate error page."
        
    

if __name__ == '__main__':  
    #run debug with flask --app webapp run --debug
   app.run(debug=True)  