#!/usr/bin/env python

__author__ = 'Veronique Ivashchenko and Frederic Escudie'
__copyright__ = 'Copyright (C) 2020 CHU Toulouse'
__license__ = 'GNU General Public License'
__version__ = '1.0.0'

import argparse
import logging
import os
import re
import sys

if __name__ == "__main__":
    # Manage parameters
    parser = argparse.ArgumentParser('Convert ChimerDb dump file to TSV.')
    parser.add_argument('-d', '--input-dump', required=True, help="Path to ChimerDb dump file (format: SQL).")
    parser.add_argument('-v', '--version', action='version', version=__version__)
    args = parser.parse_args()

    # Logger
    logging.basicConfig(format='%(asctime)s -- [%(filename)s][pid:%(process)d][%(levelname)s] -- %(message)s')
    log = logging.getLogger(os.path.basename(__file__))
    log.setLevel(logging.INFO)
    log.info("Command: " + " ".join(sys.argv))

    # Process
    fields_by_table = dict()
    with open(args.input_dump) as reader:
        for line in reader:
            line = line.strip()
            # TABLE NAME
            if line.startswith("DROP TABLE IF EXISTS "):
                selected_table = line.split("`")[1]
            # CREATE TABLE
            elif line.startswith("CREATE TABLE"):
                table_name = line.split("`")[1]
                create_open = True
                tbl_fields = []
                while create_open:
                    line = reader.readline().strip()
                    if line.startswith(")"):
                        create_open = False
                    elif not re.match(r"PRIMARY KEY ", line):
                        fields = [elt.strip() for elt in line.split()]
                        if not fields[0].endswith("`"):
                            raise
                        tbl_fields.append({
                            "name": fields[0].replace("`", ""),
                            "type": fields[1],
                            "py_type": "number" if fields[1].startswith("int") or fields[1].startswith("float") else "str"
                        })
                fields_by_table[table_name] = tbl_fields
                if table_name == selected_table:
                    print("\t".join([elt["name"] for elt in tbl_fields]))
            # INSERT VALUE
            elif line.startswith("INSERT INTO `{}` VALUES ".format(selected_table)):
                line = line.replace("INSERT INTO `{}` VALUES ".format(selected_table), "").strip()
                line = line[1:-2]  # remove parentheses
                for curr_record in line.split("),("):
                    fields = curr_record.split(",")
                    if len(fields) == len(fields_by_table[selected_table]):
                        cleaned_fields = []
                        for idx, curr_field in enumerate(fields):
                            curr_field = curr_field.replace("\t", "  ").replace("\\\'", "'").strip()
                            if fields_by_table[table_name][idx]["py_type"] == "str":
                                curr_field = curr_field[1:-1]
                            cleaned_fields.append(curr_field)
                        print("\t".join(cleaned_fields))
                    else:
                        new_fields = []
                        previous = ""
                        idx = 0
                        for curr_field in fields:
                            if fields_by_table[table_name][idx]["py_type"] == "number":
                                new_fields.append(curr_field)
                                previous = ""
                                idx += 1
                            elif (curr_field.strip().startswith("'") and curr_field.strip().endswith("'") and not len(curr_field) == 1) and not curr_field.strip().endswith("\\\'"):
                                new_fields.append(curr_field)
                                previous = ""
                                idx += 1
                            else:
                                if previous == "":
                                    previous = curr_field
                                else:
                                    previous += "," + curr_field
                                if (previous.strip().startswith("'") and previous.strip().endswith("'") and not len(previous) == 1) and not previous.strip().endswith("\\\'"):
                                    new_fields.append(previous)
                                    previous = ""
                                    idx += 1
                        fields = new_fields
                        if len(fields) == len(fields_by_table[selected_table]):
                            cleaned_fields = []
                            for idx, curr_field in enumerate(fields):
                                curr_field = curr_field.replace("\t", "  ").replace("\\\'", "'").strip()
                                if fields_by_table[table_name][idx]["py_type"] == "str":
                                    curr_field = curr_field[1:-1]
                                cleaned_fields.append(curr_field)
                            print("\t".join(cleaned_fields))
                        else:
                            raise Exception(len(fields), fields, curr_record)
    log.info("End of job")
