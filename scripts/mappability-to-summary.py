#!/usr/bin/env python3

# this looks for unique mapping mostly
import sys,re

exact_match = '!'
chrmatch = re.compile("^~(\S+)")
infile = sys.argv[1]
seenencoding = False
can_read_mappability = False #false
seq_mappability = {}
cur_chrom = ""
with open(infile,"r") as fh:
    for line in fh:
        if line.startswith("~~ENCODING"):
            seenencoding = True
        elif seenencoding and line.startswith("~"):
            line = line.strip("\n")
            m = chrmatch.search(line)
            if( m ):
                chrname = m.group(1)
                cur_chrom = chrname
                seq_mappability[chrname] = 0
            else:
                print("no chrname match when expected for",line)
            can_read_mappability = True # true

        elif can_read_mappability:
            line = line.strip("\n")
            seq_mappability[chrname] += line.count(exact_match)
total = 0
for chrom in seq_mappability:
    print(chrom,seq_mappability[chrom])
    total += seq_mappability[chrom]

print("total exact mappable sites = %d"%(total))
