'''
Created on 30 Jan 2015

@author: mrfg
'''
from HTMLParser import HTMLParser
from urlparse import urlparse

root_path ='/home/mrfg/git/ukriversguidebook.co.uk.core/tmp/'
infile = 'rivers-south-east-england.html'


class MyHTMLParser(HTMLParser):

    def handle_starttag(self, tag, attrs):
        # Only parse the 'anchor' tag.
        if tag == "a":
            # Check the list of defined attributes.
            for name, value in attrs:
                # If href is defined, print it.
                if name == "href":
                    #print name, "=", value
                    url = urlparse(value)[2]
                    
                    if url[0:8] == '/rivers/':
                        print url[1:]
                    elif url == '/reports/general/grades-in-the-guidebook':
                        print '----------------------------------------------'


doc_string = ''
src = open (root_path + infile, 'r')
doc = src.readlines ()
for l in doc:
    doc_string = doc_string + l
    
parser = MyHTMLParser()
parser.feed(doc_string)
print "Done."