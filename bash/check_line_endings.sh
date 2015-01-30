#!/bin/sh

# Written by Rich FitzJohn for the BAAD plant biomass and 
# allometry database (https://github.com/dfalster/baad).
# Modifications by Chris Black ($'\r$' -> $'\r').

# Copyright (c) 2014, Daniel Falster All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
#
# Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
#
# Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# This is probably a bit harsh because it also matches windows endings
# and they should be OK.

# Run as 
#   check_line_endings.sh csv
# to search all csv files in the working directory.  Or run without
# any argument to search the index (what will be commited) but
# checking *all* files.

if [[ $1 == "csv" ]]
then
    # echo "checking all csv files"
    BAD_ENDINGS=$(find . -name '*.csv' -print0 | xargs -0 grep -l $'\r')
else
    # echo "checking index"
    BAD_ENDINGS=$(git diff-index --cached -S$'\r' --name-only HEAD)
fi

if test -z "$BAD_ENDINGS"
then
    exit 0
else
    echo "## Files with bad line endings:"
    echo "$BAD_ENDINGS"
    exit 1
fi
