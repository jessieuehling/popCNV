#!/usr/bin/env python3

from os import listdir
import os.path
import pybedtools
import csv, re

import argparse

def flatten(lis):
    """Given a list, possibly nested to any level, return it flattened."""
    new_lis = []
    for item in lis:
        if type(item) == type([]):
            new_lis.extend(flatten(item))
        else:
            new_lis.append(item)
    return new_lis

parser = argparse.ArgumentParser(description="Data file for genome plots: binsize and windowsize")

parser.add_argument('-w','--window','--windowsize',
                    help='Window size',default=10000,type=int)
parser.add_argument('-o','--offset',type=int,
                    help='Window offset (default is non-overlapping windows)')

parser.add_argument('-f','--fai', help='Genome fai file')

args = parser.parse_args()

windowsize = int(args.window)
offset     = windowsize

binfile = "tracks/binfile.%d.bed"%(windowsize)
if args.offset:
    offset = int(args.offset)
    
if not os.path.isfile(binfile):
    counter = 0
    genomefai = args.fai
    with open(binfile,"w") as binout:
        with open(genomefai,"r") as fh:
            reader = csv.reader(fh, delimiter="\t")
            bedwrite = csv.writer(binout, delimiter="\t",
                                  quoting=csv.QUOTE_MINIMAL)
            for row in reader:
                stop = 0
                for n in range(0,int(row[1]),offset):
                    end = n + windowsize - 1
                    if end > int(row[1]):
                        end = int(row[1])
                        stop = 1

                    bedwrite.writerow([row[0],n, end, counter,
                                       ".","+"])
                    counter += 1
                    if stop:
                        break
