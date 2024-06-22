# cocr

General purpose OCR for Mac from the terminal. Tell cocr where to read on the screen and it will output what it thinks is written there. Uses the Vision framework.

```
usage: cocr [options]

  Description:
    A general purpose CLI on-screen OCR for Mac

  Arguments:
    * --disable-overlay/-o -- Disable capture overlay
    * --color/-c -- Background color for capture overlay (Hex or RGBA)
    * --disable-border/-b -- Disable border on capture overlay
    * --frame/-f -- Capture frame (x,y,w,h)
    * --keep-alive/-k -- Capture periodically, see -i
    * --interval/-i -- Capture timer interval (default: 1 second)
    * --fullscreen/-F -- Set capture frame to screen size
    * --disable-statusbar/-s -- Disable status bar icon to quit app
    * --disable-md5check/-m -- Disable MD5 duplicate check
    * --clipboard/-p -- Output OCR result to clipboard instead of STDOUT
    * --language/-l -- Set the target language, default "en-US"
    * --verbose/-v -- Enable logging
    * --help/-h -- Display this message

```

## LICENSE
```
 The MIT License (MIT)
 
 Copyright (c) 2024 George Watson
 
 Permission is hereby granted, free of charge, to any person
 obtaining a copy of this software and associated documentation
 files (the "Software"), to deal in the Software without restriction,
 including without limitation the rights to use, copy, modify, merge,
 publish, distribute, sublicense, and/or sell copies of the Software,
 and to permit persons to whom the Software is furnished to do so,
 subject to the following conditions:
 
 The above copyright notice and this permission notice shall be
 included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
 CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
 TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
```
