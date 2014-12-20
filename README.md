mruby-pure-regexp
=================

Pure mruby Regexp

[![Build Status](https://travis-ci.org/h2so5/mruby-pure-regexp.svg?branch=master)](https://travis-ci.org/h2so5/mruby-pure-regexp)

## Metacharacters

* ```.``` Any single character
* ```?``` Zero or one
* ```??``` Zero or one (reluctant)
* ```*``` Zero or more
* ```*?``` Zero or more (reluctant)
* ```+``` One or more
* ```+?``` One or more (reluctant)
* ```{N}``` N times
* ```{N,}``` N or more
* ```{,N}``` N or less
* ```{N,M}``` Between N and M
* ```{N,}?``` N or more (reluctant)
* ```{,N}?``` N or less (reluctant)
* ```{N,M}?``` Between N and M (reluctant)
* ```^``` Start of line
* ```$``` End of line
* ```[]``` Character class
* ```[^]``` Negated character class
* ```()``` Group
* ```(?:)``` Non-capturing group
* ```\w``` Word character
* ```\W``` Non-word character
* ```\s``` Whitespace character
* ```\S``` Non-whitespace character
* ```\d``` Digit
* ```\D``` Non-digit
* ```\h``` Hexadecimal digit
* ```\H``` Non-hexadecimal digit

## Options

* ```/i``` Case insensitive
* ```/m``` Multiline mode
