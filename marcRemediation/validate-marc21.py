#!/usr/bin/env python3

# validate a MARC 21 file

from pymarc import MARCReader
from pymarc import exceptions as exc

filename = 'marc/2026-05-22.marc'

success = 0
errors = 0

with open(filename, 'rb') as file:
    reader = MARCReader(file)
    for record in reader:
        if record:
            # consume the record:
            success = success + 1
        elif isinstance(reader.current_exception, exc.FatalReaderError):
            errors = errors + 1
            # data file format error
            # reader will raise StopIteration
            #print(reader.current_exception)
            #print(reader.current_chunk)
        else:
            errors = errors + 1
            # fix the record data, skip or stop reading:
            #print(reader.current_exception)
            #print(reader.current_chunk)
            # break/continue/raise
            
            
print("Valid records:", success, " / Errors:", errors)