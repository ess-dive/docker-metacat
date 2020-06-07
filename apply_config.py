#!/usr/bin/env python

from __future__ import absolute_import, division, print_function
'''
    File name: apply_config.py
    Description: Apply a local set of application properties to the default metacat.properties
    Author: Valerie Hendrix <vchendrix@lbl.gov>
    Date created: 10/12/2017
    Python Version: 2.7
'''

import argparse
import sys
import os
import uuid
from collections import OrderedDict


def get_properties(properties_file, include_comments=False, expand_variables=False):
    """
    Load properties file into a file into a dictionary

    :param properties_file: the properties file to parse
    :param include_comments: include the blanklines and comments
    :return:

    """

    # Check for the file existence
    if not os.path.exists(properties_file):
        print("Properties file '{}' is missing".format(properties_file), file=sys.stderr)
        sys.exit(-2)

    # Setup
    properties = OrderedDict()
    key = None
    concat_next = False # is the property value on multiple lines?

    # Open properties file and save the
    # contents to a dictionary
    with open(properties_file) as f:
        for line in f:
            # Strip line new line and spaces from the end
            line = line.strip('\n').rstrip()

            if not line.startswith("#") and line.strip():
                # This is a line with a property
                if not concat_next:
                    key, value = line.split("=", 1)
                    properties[key] = value
                else:
                    # the property is on multiple lines
                    # so, the entire line will be captured
                    value = line
                    properties[key] += '\n'
                    properties[key] += value

                concat_next = False
                if value.endswith('\\'):
                    # found a line continuation character
                    concat_next = True

                # resolve environment variables
                if expand_variables:
                    properties[key] = os.path.expandvars(properties[key])
            elif include_comments:
                # This is a blank line or a comment
                key = "#{}".format(uuid.uuid4())
                properties[key]=line

    return properties


def parse_cron(config_file, expand_variables=False, include_comments=False):
    """
    Returns the contents of a cron file as a list.
    """

    # Since cron files define their jobs through single lines, this just
    # uses readlines to return the content. Implementing an actual cronfile
    # parser is a lot of work and might require importing a library.
    cron_conf = OrderedDict()
    cron_entry_count = 0
    with open(config_file) as f:
        for line in f:
            if not line.startswith("#"):
                cron_conf[cron_entry_count] = line.strip()
                if expand_variables:
                    cron_conf[cron_entry_count] = os.path.expandvars(cron_conf[cron_entry_count])
                cron_entry_count += 1
            elif include_comments:
                cron_conf["#{}".format(uuid.uuid4())] = line.strip()
    return cron_conf


def parse_logrotate(config_file, expand_variables=False, include_comments=False):
    """
    Parse and return the contents of a logrotate configuration file.
    """
    logrotate_conf = OrderedDict()
    with open(config_file) as f:
        for line in f:
            if not line.startswith("#"):
                keys = line.strip().split()
                if expand_variables:
                    logrotate_conf[num] = os.path.expandvars(logrotate_conf[num])
            elif include_comments:
                logrotate_conf[num] = line.strip()
    return logrotate_conf


def get_config_parameters_with_variables(config_file, config_type):
    if config_type == "cron":
        return parse_cron(config_file, expand_variables=True)
    elif config_type == "logrotate":
        return parse_logrotate(config_file, expand_variables=True)
    else:
        return get_properties(config_file, expand_variables=True)


def get_config_parameters_with_comments(config_file, config_type):
    if config_type == "cron":
        return parse_cron(config_file, include_comments=True)
    elif config_type == "logrotate":
        return parse_logrotate(config_file, include_comments=True)
    else:
        return get_properties(config_file, include_comments=True)


def config_diff(new_config, default_config):
    return set(new_config.keys()).difference(set(default_config.keys()))


def write_properties(app_conf, default_conf, default_conf_file):
    with open(default_conf_file,'w') as f:
        for key, value in default_conf.items():
            if key in app_conf.keys():
                value = app_conf[key]

            if key.startswith("#"):
                f.write("{}\n".format(value))
            else:
                f.write("{}={}\n".format(key,value))


def write_cron(app_conf, default_conf, default_conf_file):
    #TODO: If the original file has comments and the new one doesnt
    # this will fail because they key is not in default
    # ie the default will have a key of 1 and the new one will have a key
    # of 0 because of the addition of comments
    with open(default_conf_file, 'w') as f:
        for key, value in default_conf.items():
            if key in app_conf.items():
                value = app_conf[key] 
                f.write("{}\n".format(value))


def write_logrotate(app_conf, default_conf, default_conf_file):
    with open(default_conf_file, 'w') as f:
        for key, value in default_conf.items():
            if key in app_conf.ites():
                value = app_conf[key]
                f.write("{}\n".format(value))


def write(new_conf, default_conf, filename, conf_type):
    if conf_type == "cron":
        write_cron(new_conf, default_conf, filename)
    elif conf_type == "logrotate":
        write_logrotate(new_conf, default_conf, filename)
    else:
        write_properties(new_conf, default_conf, filename)


if __name__ == "__main__":

    # Check for args
    parser = argparse.ArgumentParser(description="Merge configuration files")
    parser.add_argument("new_config_file", help="Configuration file that contains changes to merged in")
    parser.add_argument("default_config_file", help="Configuration file that holds the default values")
    parser.add_argument("-t", "--type", help="The type of the configuration file")

    args = parser.parse_args()

    app_config_file = args.new_config_file
    default_config_file = args.default_config_file
    config_type = args.type

    # Load the default configuration and the new configuration
    app_conf = get_config_parameters_with_variables(app_config_file, config_type)
    default_conf = get_config_parameters_with_comments(default_config_file, config_type)

    # Check to see if the application properties exist in the metacat properties
    difference = config_diff(app_conf, default_conf)

    if len(difference) > 0:
        print("The following properties do not exist in '{}':".format(metacat_properties_file), file=sys.stderr)
        for p in difference:
            print("\t{}".format(p), file=sys.stderr)
        sys.exit(-4)

    # Merge the application and metacat properties
    write(app_conf, default_conf, default_config, config_type)
