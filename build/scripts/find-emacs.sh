#!/bin/bash
#### Blackthorn -- Lisp Game Engine
####
#### Copyright (c) 2011, Elliott Slaughter <elliottslaughter@gmail.com>
####
#### Permission is hereby granted, free of charge, to any person
#### obtaining a copy of this software and associated documentation
#### files (the "Software"), to deal in the Software without
#### restriction, including without limitation the rights to use, copy,
#### modify, merge, publish, distribute, sublicense, and/or sell copies
#### of the Software, and to permit persons to whom the Software is
#### furnished to do so, subject to the following conditions:
####
#### The above copyright notice and this permission notice shall be
#### included in all copies or substantial portions of the Software.
####
#### THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
#### EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
#### MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
#### NONINFRINGEMENT.  IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
#### HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
#### WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#### OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
#### DEALINGS IN THE SOFTWARE.
####

cached_result_file=.find-emacs

if [[ -e $cached_result_file ]]; then
  result=$(<"$cached_result_file")
  if [[ -n $result ]]; then
    echo "$result"
    exit 0
  fi
fi

# find-program <program> <result>
function find-program () {
  program="$1"
  ignore=$(which "$program" 2>&1)
  if [[ $? -eq 0 ]]; then
    echo "$program"
    echo "$program" > "$cached_result_file"
    exit 0
  fi
}

# test-path <program>
function test-path () {
  program="$1"
  if [[ -x $program ]]; then
    echo "$program"
    echo "$program" > "$cached_result_file"
    exit 0
  fi
}

find-program runemacs
find-program emacs
test-path "C:\\Emacs-23.2\\bin\\runemacs.exe"

exit 1
