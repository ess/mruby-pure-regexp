mruby-pure-regexp
=================

Pure mruby Regexp

[![Build Status](https://travis-ci.org/h2so5/mruby-pure-regexp.svg?branch=master)](https://travis-ci.org/h2so5/mruby-pure-regexp)

## Metacharacters

* ```.``` Any single character
* ```?``` Zero or one
* ```*``` Zero or more
* ```+``` One or more
* ```??``` Zero or one (reluctant)
* ```*?``` Zero or more (reluctant)
* ```+?``` One or more (reluctant)
* ```?+``` Zero or one (possessive)
* ```*+``` Zero or more (possessive)
* ```++``` One or more (possessive)
* ```{N}``` N times
* ```{N,}``` N or more
* ```{,N}``` N or less
* ```{N,M}``` Between N and M
* ```{N,}?``` N or more (reluctant)
* ```{,N}?``` N or less (reluctant)
* ```{N,M}?``` Between N and M (reluctant)
* ```^``` Start of line
* ```$``` End of line
* ```|``` Alternation
* ```[]``` Character class
* ```[^]``` Negated character class
* ```()``` Group
* ```(?<name>)``` Named group
* ```(?'name')``` Named group
* ```(?:)``` Non-capturing group
* ```(?>)``` Atomic group
* ```\w``` Word character
* ```\W``` Non-word character
* ```\s``` Whitespace character
* ```\S``` Non-whitespace character
* ```\d``` Digit
* ```\D``` Non-digit
* ```\h``` Hexadecimal digit
* ```\H``` Non-hexadecimal digit

## Replacement metacharacters

* ```\N``` Submatch
* ```\&``` Entire match
* ```\` ``` Substring before match
* ```\'``` Substring after match
* ```\+``` Last submatch
* ```\k<name>``` Named submatch

## Options

* ```/i``` Case insensitive
* ```/m``` Multiline mode
