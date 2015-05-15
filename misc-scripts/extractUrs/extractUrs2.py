'''
Created on 30 Jan 2015

@author: mrfg
'''
import csv
from HTMLParser import HTMLParser
from urlparse import urlparse
from tidylib import tidy_document

root_path ='/home/mrfg/git/ukriversguidebook.co.uk.core/tmp/'
#infile = 'rivers-south-east-england.html'
infile = 'rivers-north-east-england.html'
#infile = 'rivers-north-west-england.html'
#infile = 'rivers-midlands-england.html'


class MyHTMLParser(HTMLParser):
    
    def __init__(self):
        self.river_line = False
        self.in_text = False
        self.in_articleBody = False
        self.curent_url = ''
        self.sequence = []
        self.result = dict()
           
        HTMLParser.__init__(self)
        
    def dump(self):
        
        with open(root_path + infile +'.csv', 'wb') as csvfile:
            mywriter = csv.writer(csvfile, delimiter=',',quotechar='"', quoting=csv.QUOTE_MINIMAL)
        
        
            max_length = 0
            for key in self.sequence:
                l = len(self.result[key])
                if l > max_length:
                    max_length = l
                print key,',',self.result[key]
                mywriter.writerow([key, self.result[key]])
    
        print "max Len:", max_length
    def handle_starttag(self, tag, attrs):
        # Only parse the 'anchor' tag.
        #print tag
        if tag == "a":
            # Check the list of defined attributes.
            for name, value in attrs:
                # If href is defined, print it.
                if name == "href":
                    #print name, "=", value
                    url = urlparse(value)[2]
                    #print url
                    if self.in_articleBody:
                        self.curent_url = url[1:]
                        if url[0:16] == '/rivers/england/':
                            self.sequence.append(self.curent_url)
                            self.result[self.curent_url] = ''
                            self.river_line = True
                        elif url == '/reports/general/grades-in-the-guidebook':
                            self.sequence.append(self.curent_url)
                            self.river_line = False
                            self.result[self.curent_url] = '-----------------------------'
        elif tag == "div":
            for name, value in attrs:
                if name == "itemprop" and value == "articleBody":
                    self.in_articleBody = True
        
                if name == "id" and value[0:14] == "jfusioncontent":
                    self.in_articleBody = False
                    
                    
    def handle_endtag(self, tag):
        if self.river_line and tag == "a":
            self.in_text = True 
        
        if self.river_line and tag == "p":
            self.in_text = False
            self.river_line = True
            self.curent_url = ''
      
            
    def handle_data(self, data):
        #print data
        if self.river_line and data == "/a":
            self.in_text = True 
   
        if self.river_line and data == "/p":
            self.in_text = False
            self.river_line = True
            self.curent_url = ''
            
        if data == "articleBody":
            print "-- start --"
            self.in_articleBody = True
            
        if data == "/main":
            self.in_articleBody = False
            
        if  self.in_text and self.in_articleBody and len(data) > 2 and self.river_line:
            #print data
            self.result[self.curent_url] = data

doc_string = ''
src = open (root_path + infile, 'r')
doc = src.readlines ()
for l in doc:
    doc_string = doc_string + l

document, errors = tidy_document (doc_string, 
                                  options={'output-xhtml': 1, 
                                           'numeric-entities':1,
                                           'indent': 0})

    
parser = MyHTMLParser()
parser.feed(document)

parser.dump();

print "Done."