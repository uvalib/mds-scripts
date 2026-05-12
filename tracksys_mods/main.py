#!/usr/bin/env python3

#Author: Ethan Gruber
#Date: May 2026
#Function: Instantiate a FastAPI to parse an EDTF date and return a valid ISO 8601 date range

from fastapi import FastAPI
from edtf import parse_edtf
from edtf import struct_time_to_date

app = FastAPI()

@app.get("/")
def read_root():
    return {"API": "Pass 'date' request parameter to /parse path for JSON response of the parsed start and end date"}

@app.get("/parse")
def read_item(date: Union[str, None] = None):
    try:
        date
    except NameError:
        return {"error": "date parameter undefined"}
    else:
        
        if len(date) > 0:
            e = parse_edtf(date)
            fromDate = struct_time_to_date(e.lower_strict())
            toDate = struct_time_to_date(e.upper_strict())
            
            object = {"fromDate": fromDate, "toDate": toDate}
            
            return object
        else: 
            return {"error": "date parameter is zero length"}