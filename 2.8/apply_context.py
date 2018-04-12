#!/usr/bin/env python
from __future__ import absolute_import, division, print_function
'''
    File name: apply_context.py
    Description: Change the default context in the metacat web.xml file
    Author: Valerie Hendrix <vchendrix@lbl.gov>
    Date created: 11/28/2017
    Python Version: 2.7
'''
import xml.etree.ElementTree as ET

import sys

# The namespace
javaee = {'javaee': 'http://java.sun.com/xml/ns/javaee'}


if __name__ == "__main__":

    # Check for args
    if len(sys.argv) < 3:
        print("Usage: {}  old_context new_context".format(sys.argv[0]),file=sys.stderr)
        sys.exit(-1)

    old_context = sys.argv[1]
    new_context = sys.argv[2]

    # Update the metacat.properties.path in the metaca-index application
    metacat_index_web_xml = "/usr/local/tomcat/webapps/metacat-index/WEB-INF/web.xml"
    tree = ET.parse(metacat_index_web_xml)
    root = tree.getroot()

    # Iterate over the servlet-mappings and change the url pattern to the
    # new application context
    mappings = root.findall("./context-param", javaee)
    for mapping in mappings:

        param_name = mapping.find("param-name", javaee)
        param_value = mapping.find("param-value", javaee)
        if param_name is not None and param_name.text == "metacat.properties.path":
            param_value.text = str(param_value.text.replace("/{}/WEB-INF".format(old_context), "/{}/WEB-INF".format(new_context)))
            break

    # Overwrite the web xml file
    tree.write(metacat_index_web_xml)



