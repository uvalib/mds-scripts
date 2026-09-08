"""
Author: Ethan Gruber
Date modified: September 2026
Function: Transform JSON from SNAC Cooperative into basic Linked Art JSON-LD 
"""

import os, json, sys, re, argparse
import xml.etree.ElementTree as ET

def load_rows(path):
    with open(path, "r", encoding="utf-8") as f:
        data = json.load(f)    
    return data

def process_json(data):    
    entity = {
        "@context": "https://linked.art/ns/v1/linked-art.json"
        }
    
    names = {}
    
    entity["id"] = data["ark"]
    
    if data["entityType"]["term"] == 'person':
        entity["type"] = "Person"
    else:
        entity["type"] = "Group"
    
    #parse useful names and include the preference score for sorting   
    for nameEntry in data["nameEntries"]:
        #note: preferenceScore in SNAC JSON is a string not number
        if int(nameEntry["preferenceScore"]) > 0:
            names[int(nameEntry["preferenceScore"])] = nameEntry["original"]
    
    
    #force sorting of names in case the order is not already sorted in the source SNAC JSON
    names = tuple(reversed(sorted(names.items())))
    
    entity["_label"] = names[0][1]
    
    #including preferred name so far, will expand for alternative names
    entity["identified_by"] = [
            {
                "type": "Name",
                "content": names[0][1],
                "classified_as": [
                    {
                        "id": "http://vocab.getty.edu/aat/300404670",
                        "type": "Type",
                        "_label": "Primary Name"
                    }
                ]
            }
        ]
       
    #parse the first biogHist from the embedded text property in the JSON and join paragraphs into one statement that does not include escaped XML elements
    if "biogHists" in data:
        bio = ""
        
        text = data["biogHists"][0]["text"]
        text = f"<text>{text}</text>"
        
        root = ET.fromstring(text)
        
        nodes = root.findall('biogHist')
        
        if len(nodes) == 0:
            bio = root.find('text').text
        else:
            paragraphs = []
            for p in nodes[0].findall("{urn:isbn:1-931666-33-4}p"):
                paragraphs.append(p.text)
                
            if len(paragraphs) > 0:
                bio = " ".join(paragraphs)
        
        #if any string has been parsed from the biogHist, then include the biography statement in Linked Art output 
        if len(bio) > 0:
            entity["referred_to_by"] = [
                {
                    "type": "LinguisticObject",
                    "content": bio,
                    "classified_as": [
                        {
                            "id": "http://vocab.getty.edu/aat/300435422",
                            "type": "Type",
                            "_label": "Biography Statement",
                            "classified_as": [
                                {
                                    "id": "http://vocab.getty.edu/aat/300418049",
                                    "type": "Type",
                                    "_label": "Brief Text"
                                }
                            ]
                        }
                    ]
                }
            ]
       
    #classified_as
    if "occupations" in data or "nationalities" in data:
        classified_as = []
        if "occupations" in data:
            for occupation in data["occupations"]:
                obj = {
                    "id": "null",
                    "type": "Type",
                    "_label": occupation["term"]["term"],
                    "classified_as": [
                        {
                            "id": "http://vocab.getty.edu/aat/300263369",
                            "type": "Type",
                            "_label": "Occupation"
                        }
                    ]
                }
                classified_as.append(obj)
                
        if "nationalities" in data:
            for nationality in data["nationalities"]:
                obj = {
                "id": "null",
                "type": "Type",
                "_label": nationality["term"]["term"],
                "classified_as": [
                    {
                        "id": "http://vocab.getty.edu/aat/300379842",
                        "type": "Type",
                        "_label": "Nationality"
                    }
                ]
            }
            classified_as.append(obj)
        entity["classified_as"] = classified_as

    
    #extract birth and death dates
    if "dates" in data:
        for date in data["dates"]:
            if "fromDate" in date:
                if date["fromType"]["term"] == "Birth":
                    fromDate = date["fromDate"]                    
                    if re.search("^\\d{4}$", fromDate):
                        entity["born"] = {
                        "type": "Birth",
                        "timespan": {
                            "type": "TimeSpan",
                            "begin_of_the_begin": fromDate + "01-01T00:00:00Z",
                            "end_of_the_end": fromDate + "-12-31T23:59:59Z"
                            }
                        }
                    elif re.search("^\\d{4}-\\d{2}-\\d{2}$", fromDate):
                        entity["born"] = {
                        "type": "Birth",
                        "timespan": {
                            "type": "TimeSpan",
                            "begin_of_the_begin": fromDate + "T00:00:00Z",
                            "end_of_the_end": fromDate + "T23:59:59Z"
                            }
                        }
            if "toDate" in date:
                if date["toType"]["term"] == "Death":
                    toDate = date["toDate"]                    
                    if re.search("^\\d{4}$", toDate):
                        entity["died"] = {
                        "type": "Death",
                        "timespan": {
                            "type": "TimeSpan",
                            "begin_of_the_begin": toDate + "01-01T00:00:00Z",
                            "end_of_the_end": toDate + "-12-31T23:59:59Z"
                            }
                        }
                    elif re.search("^\\d{4}-\\d{2}-\\d{2}$", toDate):
                        entity["died"] = {
                        "type": "Death",
                        "timespan": {
                            "type": "TimeSpan",
                            "begin_of_the_begin": toDate + "T00:00:00Z",
                            "end_of_the_end": toDate + "T23:59:59Z"
                            }
                        }
                        
    #equivalent URIs
    #NOTE: VIAF, Wikidata, and id.loc.gov canonical URIs are http, not https
    if "sameAsRelations" in data:
        equivalent = []
        
        for relation in data["sameAsRelations"]:
            if relation["dataType"] == "SameAs":
                equivalent.append(relation["uri"])
                
        if len(equivalent) > 0:
            entity["equivalent"] = equivalent
			
    return entity
    

def main():
    parser = argparse.ArgumentParser(
        description="Convert JSON from SNAC into Linked Art JSON-LD"
    )
    parser.add_argument("json_file", help="Path to the JSON source file")
    parser.add_argument("-o", "--output", default="out.json", help="Output filename")
    
    args = parser.parse_args()

    data = load_rows(args.json_file)
    if not data:
        sys.exit("Error: input JSON contained no rows.")
        
    result = process_json(data)
    
    print(f"Writing {args.output}")
    with open(args.output, 'w') as f:
        json.dump(result, f, indent=4)
    
    #print(result)

if __name__ == "__main__":
    main()