"""
Author: Ethan Gruber
Date: October 2026
Function: Analyze MARC Geographic subject fields (651) in Sirsi to distinguish which should be moved to 650, and which geographic terms are missing, wrong, or deprecated
"""

import csv, re, os, requests, urllib, time, unicodedata
from xml.etree import ElementTree as ET
from rdflib import Graph, URIRef, Literal, Namespace, BNode
from rdflib.namespace import RDF, XSD, SKOS, RDFS

MADS = Namespace('http://www.loc.gov/mads/rdf/v1#')

subjects = {}

def query_lc_name(term, subfield):
    #attempt to fix UTF-8 encoding issues
    term = fix(term)
    
    escaped = urllib.parse.quote(term)
    url = f"https://id.loc.gov/authorities/label/{escaped}"
    headers = {"Range": "bytes=0-0"}
    response = requests.head(url)
    
    #if the response code is 302 see other, then extract URI and examine contents
    if response.status_code == 302:
        h = response.headers
        
        uri = h["x-uri"]
        prefLabel = h["x-prefLabel"]
        
        if prefLabel != term:
            print(f"Using {prefLabel} instead of {term}")
            
        if "childrensSubjects" in uri:
            print(f"{term} resolved to childrensSubjects. Performing text search instead")
            concept = search_lc(term=term, subfield=subfield, scheme='lcsh', rdftype='rdftype:Topic', subdivision=None)
            if concept is not None:
                return concept
            else:
                return {"uri": "", "prefLabel": "", "geo": ""}
        else:
            #read RDF in order to evaluate concept type and replacement URIs
            concept = get_rdf(term, uri, prefLabel, subfield)        
            return concept
    else:
        #if the label does not immediately resolve to an LC URI, then perform a keyword search with the Atom XML API
        print("Not found:", term)
        
        if subfield == "a":
            concept = search_lc(term=term, subfield=subfield, scheme='lcsh_lcnaf', rdftype='rdftype:Topic OR rdftype:Name OR rdftype:Geographic', subdivision="-memberOf:http://id.loc.gov/authorities/subjects/collection_GeographicSubdivisions")
        elif subfield == "v":
            concept = search_lc(term=term, subfield=subfield, scheme='lcsh', rdftype='rdftype:GenreForm', subdivision=None)
        elif subfield == "x" or subfield == "y":
            concept = search_lc(term=term, subfield=subfield, scheme='lcsh', rdftype='rdftype:Topic', subdivision="memberOf:http://id.loc.gov/authorities/subjects/collection_Subdivisions")
        elif subfield == "z":
            concept = search_lc(term=term, subfield=subfield, scheme='lcnaf', rdftype='rdftype:Geographic', subdivision="memberOf:http://id.loc.gov/authorities/subjects/collection_GeographicSubdivisions")
        else:
            concept = search_lc(term=term, subfield=subfield, scheme='lcsh', rdftype='rdftype:Topic', subdivision=None)
            
        if concept is not None:
            return concept
        else:
            return {"uri": "", "prefLabel": "", "geo": ""}
        

def search_lc (term, subfield, scheme, rdftype, subdivision):
    schemes = {"lcnaf": "scheme:http://id.loc.gov/authorities/names", 
               "lcsh": "scheme:http://id.loc.gov/authorities/subjects", 
               "lcgft": "scheme:http://id.loc.gov/authorities/genreForms",
               "lctgm": "scheme:http://id.loc.gov/vocabulary/graphicMaterials",
               "relators": "scheme:http://id.loc.gov/vocabulary/relators", 
               "lcsh_lcnaf": "scheme:http://id.loc.gov/authorities/names OR scheme:http://id.loc.gov/authorities/subjects"}
    
    if subdivision is not None:    
        url = "http://id.loc.gov/search/?q=" + urllib.parse.quote('"' + term + '"') + "&q=" + schemes[scheme] + "&q=" + rdftype + "&q=" + urllib.parse.quote(subdivision) + "&format=atom-xml"
    else:
        url = "http://id.loc.gov/search/?q=" + urllib.parse.quote('"' + term + '"') + "&q=" + schemes[scheme] + "&q=" + rdftype + "&format=atom-xml"
    
    print(f"Querying {term} in Library of Congress")
    
    headers = {"User-Agent": "EntityNormalization/UVALibrary"}
    
    response = requests.get(url, headers=headers)
    root = ET.fromstring(response.content)
    
    namespaces = {'atom': 'http://www.w3.org/2005/Atom'}
    
    #skip string matching on relators due to abbreviations
    entry = root.find('.//atom:entry', namespaces)
    if entry is not None:    
        prefLabel = entry.find('atom:title', namespaces).text
        uri = entry.find('atom:link', namespaces).get('href')
        concept = get_rdf(term, uri, prefLabel, subfield)
        return concept
    else:
        print(f"No search result for {term}")
        #tuple = (term, title, link)                      
        #return tuple   
    

def get_rdf(term, uri, prefLabel, subfield):
    print(f"Querying {uri} in LC")
    
    g = Graph()
    g.parse(uri + ".rdf")
    
    concept = {"uri": uri, "prefLabel": prefLabel}
    
    entity = URIRef(uri)
    
    if ((entity, RDF.type, MADS.Geographic ) in g) == True:
        concept["geo"] = "true"
        
        #look for replacement URIs
        if g.value(entity, MADS.hasLaterEstablishedForm):
            uri = str(g.value(entity, MADS.hasLaterEstablishedForm))
            prefLabel = str(g.value(entity, MADS.hasLaterEstablishedForm / MADS.authoritativeLabel))
            print(f"{term} has later established form of {prefLabel}")
            concept["uri"] = uri
            concept["prefLabel"] = prefLabel
        elif g.value(entity, MADS.useInstead):
            uri = str(g.value(entity, MADS.useInstead))
            prefLabel = str(g.value(entity, MADS.useInstead / MADS.authoritativeLabel))
            print(f"{term} has been replaced with {prefLabel}")
            concept["uri"] = uri
            concept["prefLabel"] = prefLabel
        elif g.objects(entity, MADS.editorialNote):
            notes = g.objects(entity, MADS.editorialNote)
            
            #parse new name from editorial note
            for note in notes:
                if "SUBJECT USAGE" in note:
                    p = re.compile(".*Works about this place are entered under (.*)\\.]")
                    result = p.search(note)
                    if result is not None:
                        term = result.group(1)
                        print(f"Extracted {term} from editorial note")
                        return query_lc_name(term, subfield)
    
    else:
        concept["geo"] = "false"
        
        #look for replacement URIs
        if g.value(entity, MADS.hasLaterEstablishedForm):
            uri = str(g.value(entity, MADS.hasLaterEstablishedForm))
            prefLabel = str(g.value(entity, MADS.hasLaterEstablishedForm / MADS.authoritativeLabel))
            print(f"{term} has later established form of {prefLabel}")
            concept["uri"] = uri
            concept["prefLabel"] = prefLabel
        elif g.value(entity, MADS.useInstead):
            uri = str(g.value(entity, MADS.useInstead))
            prefLabel = str(g.value(entity, MADS.useInstead / MADS.authoritativeLabel))
            print(f"{term} has been replaced with {prefLabel}")
            concept["uri"] = uri
            concept["prefLabel"] = prefLabel
        elif g.objects(entity, MADS.editorialNote):
            notes = g.objects(entity, MADS.editorialNote)
            
            #parse new name from editorial note
            for note in notes:
                if "SUBJECT USAGE" in note:
                    p = re.compile(".*Works about this place are entered under (.*)\\.]")
                    result = p.search(note)
                    if result is not None:                    
                        term = result.group(1)
                        print(f"Extracted {term} from editorial note")
                        return query_lc_name(term, subfield)
    
    return concept

#attempt to fix garbled Unicode characters
def fix(s):
    # Try the exact reversal first, in case the control bytes survived
    try:
        return unicodedata.normalize("NFC", s.encode("latin-1").decode("utf-8"))
    except (UnicodeEncodeError, UnicodeDecodeError):
        pass

    # Ì not followed by a visible continuation byte (0x80-0xBF) lost its second byte
    lost = '\u00cc(?![\u0080-\u00bf])'

    s = re.sub('I' + lost, 'I\u0307', s)                                   # İ (dotted capital I)
    s = re.sub('([aeiouAEIOU])' + lost, lambda m: m.group(1) + '\u0301', s)  # guess: acute accent
    s = s.replace('\u00cc\u00a7', '\u0327')                                # combining cedilla
    return unicodedata.normalize("NFC", s)

def main():
    count = 0
    
    with open('all unauthorized 651.csv', newline='', encoding="utf-8") as csvfile:
        reader = csv.DictReader(csvfile)
        for row in reader:
            if count <= 1000:
                value = row["Tag value"].replace("|?UNAUTHORIZED", "")
                
                #strip trailing period, if applicable
                if value[-1] == ".":
                    value = value[0:-1]
                    
                
                topics = value.split("|")
                
                position = 0
                for term in topics:
                    #extract the subfield code, which informs the LC API lookup
                    if position == 0:
                        subfield = "a"
                    else:
                        subfield = term[0]
                        term = term[1:]                   
                    
                    if term not in subjects:
                        concept = query_lc_name(term, subfield)
                        
                        subjects[term] = concept
                        #create a space between HTTP requests    
                        time.sleep(1)
                    
                    position += 1
                
                #increase row count    
                count += 1
                    
    print(subjects)

if __name__=="__main__":
    main()