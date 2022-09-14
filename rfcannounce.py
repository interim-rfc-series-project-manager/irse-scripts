#!/usr/local/bin/python3
# read a message, strip out the good bits about a new RFC
#

import sys
import re
import sys

def dorfc(f, fname="stdin", doabstract=False):
    print("===",fname,file=sys.stderr)
    msg = tuple(l.strip() for l in f)   # slurp in message

    msgok = False
    intitle = False
    title = None
    author = None
    inauthor = False
    rfcno = None
    doiline = 0
    abstract = None
    inabstract = None
    for l in msg:
        if 'A new Request for Comments is now available' in l:
            msgok = True
            continue
        r = re.match(r'^RFC (\d+)$', l)
        if r:
            rfcno = r.group(1)
            continue
        if 'Title:  ' in l:
            title = l.split(maxsplit=1)[1]
            intitle = True
            continue
        if intitle:
            if 'Author: ' in l:
                intitle = False
                author = l.split(maxsplit=1)[1]
                inauthor = True
            else:
                title += ' '+l
            continue
        if inauthor:    
            if 'Status:  ' not in l:    # check for multiple authors
                author += " et al."
            inauthor = False
            continue
        if 'URL:   ' in l:
            url = l.split(maxsplit=1)[1]
        if 'DOI:  ' in l:
            doiline = 1
        elif doiline == 1 and l == "":
            doiline = 2
        elif doiline == 2:
            abstract = l
            doiline = 0
            inabstract = True
            continue
        if inabstract:
            if l:
                abstract += ' '+l
            else:
                inabstract = False

    if doabstract:
        print("RFC {0}: {1}, {2}, {3}, {4}".format(rfcno, title, author, url, abstract))
    else:
        print("RFC {0}: {1}, {2}, {3}".format(rfcno, title, author, url))


################################################################
if __name__=="__main__":
    import argparse

    parser = argparse.ArgumentParser(description='Make tweets from RFC announcements')
    parser.add_argument('-s', action='store_true', help="read stdin")
    parser.add_argument('-a', action='store_true', help="include abstract")
    parser.add_argument('file', nargs='*', help="File(s) to read")
    args = parser.parse_args()

    if (args.s and args.file) or (not args.s and not args.file):
        parser.print_help()
        exit()



    if args.s:
        dorfc(sys.stdin, doabstract=args.a)
    else:
        for fn in args.file:
            with open(fn, "r") as f:
                dorfc(f, fn, doabstract=args.a)
