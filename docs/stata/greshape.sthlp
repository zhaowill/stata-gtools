{smcl}
{* *! version 0.1.0  30Jan2019}{...}
{viewerdialog greshape "dialog greshape"}{...}
{vieweralsosee "[R] greshape" "mansection R greshape"}{...}
{viewerjumpto "Syntax" "greshape##syntax"}{...}
{viewerjumpto "Description" "greshape##description"}{...}
{title:Title}

{p2colset 5 17 23 2}{...}
{p2col :{cmd:greshape} {hline 2}} Fast alternative to reshape using C for speed. {p_end}
{p2colreset}{...}

{pstd}
{it:Important}: Please run {stata gtools, upgrade} to update {cmd:gtools} to
the latest stable version.

{pstd}
{it:Note}: {cmd:greshape} relies on temporary files written to your disk
storage to reshape the data in memory. For particularly large reshapes
this might deteriorate performance.

{marker syntax}{...}
{title:Syntax}

{pstd}
{opt greshape} is a fast alternative to {opt reshape} that additionally
implements the equivalents to R's {cmd:spread} and {cmd:gather} from
{cmd:tidyr}.

{p 4 8 2}
Basic syntax

{phang2}
Convert data from wide form to long form

{p 12 16 2}
{cmd:greshape} {helpb greshape##overview:long}
{it:stubnames}{cmd:,}
{cmd:i(}{varlist}{cmd:)}
[{it:{help greshape##options_table:options}}]

{p 12 16 2}
{cmd:greshape} {helpb greshape##overview:gather}
{varlist}{cmd:,}
{cmd:j(}{varlist}{cmd:)}
{cmd:values(}{varname}{cmd:)}
[{it:{help greshape##options_table:options}}]

{phang2}
Convert data from long form to wide form

{p 12 16 2}
{cmd:greshape} {helpb greshape##overview:wide}
{it:stubnames}{cmd:,}
{cmd:i(}{varlist}{cmd:)}
{cmd:j(}{varname}{cmd:)}
[{it:{help greshape##options_table:options}}]

{p 12 16 2}
{cmd:greshape} {helpb greshape##overview:spread}
{varlist}{cmd:,}
{cmd:j(}{varname}{cmd:)}
[{it:{help greshape##options_table:options}}]

{p 4 8 2}
Details

        The {it:stubnames} are a list of variable {it:prefixes}. The suffixes are either
        saved or taken from {opt j()}, depending on the shape of the data.  Remember
        this picture:


           {it:long}
        {c TLC}{hline 12}{c TRC}                   {it:wide}
        {c |} {it:i  j}  {it:stub} {c |}                  {c TLC}{hline 16}{c TRC}
        {c |}{hline 12}{c |}                  {c |} {it:i}  {it:stub}{bf:1} {it:stub}{bf:2} {c |}
        {c |} 1  {bf:1}   4.1 {c |}     greshape     {c |}{hline 16}{c |}
        {c |} 1  {bf:2}   4.5 {c |}   <{hline 10}>   {c |} 1    4.1   4.5 {c |}
        {c |} 2  {bf:1}   3.3 {c |}                  {c |} 2    3.3   3.0 {c |}
        {c |} 2  {bf:2}   3.0 {c |}                  {c BLC}{hline 16}{c BRC}
        {c BLC}{hline 12}{c BRC}

        To go from long to wide:

     {col 45}{it:j} existing variable
     {col 44}/
     	        {cmd:greshape wide} {it:stub}{cmd:, i(}{it:i}{cmd:) j(}{it:j}{cmd:)}

        To go from wide to long:

     	        {cmd:greshape long} {it:stub}{cmd:, i(}{it:i}{cmd:) j(}{it:j}{cmd:)}
     {col 44}\
     {col 45}{it:j} new variable

        Additionally, the user can reshape in the style of R's {cmd:tidyr} package.
        To go from long to wide:

     	        {cmd:greshape spread} {it:varlist}{cmd:, j(}{it:j}{cmd:)}

        Note that {cmd:spread} (and {cmd:gather}) both require variable {it:names}, not prefixes.
        Further, all variables not specified in the reshape are assumed to be 
        part of {cmd:i()} and the new variables are simply named after the values of
        {cmd:j()}. To go from wide to long:

     	        {cmd:greshape gather} {it:varlist}{cmd:, j(}{it:j}{cmd:) values(}{it:values}{cmd:)}

        This does {opt not} check for duplicates or sorts the data. Variables not
        named are assumed to be part of {cmd:i()}).  The values of the variables in
        {it:varlist} are saved in {cmd:values()}, with their names saved in {it:j()}.

        {cmd:reshape}'s extended syntax is not supported; that is, {cmd:greshape} does
        not implement "reshape mode" where a user can type {cmd:reshape long} or
        {cmd:reshape wide} after the first reshape. This syntax is cumbersome to
        support and prone to errors given the degree to which {cmd:greshape} had
        to rewrite the base code. This also means the "advanced" commands
        are not supported, including: clear, error, query, i, j, xij, and xi.

{synoptset 19 tabbed}{...}
{marker table_options}{...}
{synopthdr}
{synoptline}
{syntab :Long}
{synopt :* {opth i(varlist)}} use {it:varlist} as the ID variables.
{p_end}
{synopt :{opth j(varname)}} wide->long: {it:varname}, new variable to store stub suffixes (default {it:_j}).
{p_end}
{synopt :{opt s:tring}} Whether to allow for string matches to each {it:stub}
{p_end}

{syntab :Wide}
{synopt :* {opth i(varlist)}} use {it:varlist} as the ID variables.
{p_end}
{synopt :* {opth j(varlist)}} long->wide: {it:varlist}, existing variable with stub suffixes.
{p_end}
{synopt :{opth cols:epparate(str)}} Column separator when multiple variables are passed to {opt j()}.
{p_end}

{syntab :Common long and wide options}
{synopt :{opt fast}} Do not wrap the reshape in preserve/restore pairs.
{p_end}
{synopt :{opt unsorted}} Leave the data unsorted (faster). Original sort order is {opt not} preserved.
{p_end}
{synopt :{opt nodupcheck}} wide->long, allow duplicate {opt i()} values (faster).
{p_end}
{synopt :{opt nomisscheck}} long->wide, allow missing values and/or leading blanks in {opt j()} (faster).
{p_end}
{synopt :{opt nochecks}} This is equivalent to all 4 of the above options (fastest).
{p_end}
{synopt :{opt xi(drop)}} Drop variables not in the reshape, {opt i()}, or {opt j()}.
{p_end}

{synoptline}
{syntab :Gather}
{synopt :* {opth values(varname)}} Store values in {it:varname}.
{p_end}
{synopt :{opth j(varname)}} wide->long: {it:varname}, new variable to store variable names (default {it:_j}).
{p_end}
{synopt :{opt s:tring}} Whether to allow for string matches to each {it:stub}
{p_end}

{syntab :Spread}
{synopt :* {opth j(varlist)}} long->wide: {it:varlist}, existing variable with variable names.
{p_end}

{syntab :Common gather and spread options}
{synopt :{opth i(varlist)}} check {it:varlist} are the ID variables. Throws an error otherwise.
{p_end}
{synopt :{opt xi(drop)}} Drop variables not in the reshape or in {opt i()}.
{p_end}
{synopt :{opt fast}} Do not wrap the reshape in preserve/restore pairs.
{p_end}

{synoptline}
{syntab:Gtools Options}
{synopt :{opt compress}}Try to compress strL to str#.
{p_end}
{synopt :{opt forcestrl}}Skip binary variable check and force gtools to read strL variables.
{p_end}
{synopt :{opt v:erbose}}Print info during function execution.
{p_end}
{synopt :{opt bench}{it:[(int)]}}Benchmark various steps of the plugin. Optionally specify depth level.
{p_end}
{synopt :{opth hash:method(str)}}Hash method (default, biject, or spooky). Intended for debugging.
{p_end}
{synopt :{opth oncollision(str)}}Collision handling (fallback or error). Intended for debugging.
{p_end}

{synoptline}
{syntab:* options are required for that subcommand.}
{p2colreset}{...}

{marker description}{...}
{title:Description}

{pstd}
{cmd:greshape} converts data from wide to long form and vice versa.  It
is a fast alternative to {cmd:reshape}, and it additionally implements
{cmd:greshape spread} and {cmd:greshape gather}, both of which are
marginally faster and in the style of the equivalent R commands from
{cmd:tidyr}.

{pstd}
It is well-known that {cmd:reshape} is a slow command, and there are several
alternatives that I have encountered to speed up reshape, incuding: {opt fastreshape},
{opt sreshape}, and various custom solutions (e.g. {browse "http://www.nber.org/stata/efficient/reshape.html":here}).
In my benchmarks their performance improvements are either minor or not robust to
complex data configurations (e.g. many unsorted groups, many extra variables, mixed types, etc.).

{pstd}
The only solution that consistently outperforms {cmd:reshape} is
{cmd:parallel}, which improves performance by 1.5x to 3x, depending on
the data configuration. {cmd:greshape} typically speeds up {cmd:reshape}
by 4x to 10x, so it is much faster than even the next-fastest known
improvement to {cmd:reshape}.

{marker example}{...}
{title:Examples}

{pstd}
See the
{browse "http://gtools.readthedocs.io/en/latest/usage/greshape/index.html#examples":online documentation}
for examples.

{marker author}{...}
{title:Author}

{pstd}Mauricio Caceres{p_end}
{pstd}{browse "mailto:mauricio.caceres.bravo@gmail.com":mauricio.caceres.bravo@gmail.com }{p_end}
{pstd}{browse "https://mcaceresb.github.io":mcaceresb.github.io}{p_end}

{title:Website}

{pstd}{cmd:greshape} is maintained as part of the {manhelp gtools R:gtools} project at {browse "https://github.com/mcaceresb/stata-gtools":github.com/mcaceresb/stata-gtools}{p_end}

{marker acknowledgment}{...}
{title:Acknowledgment}

{pstd}
This help file was based on StataCorp's own help file for {it:reshape}.
{p_end}

{pstd}
{opt gtools} was largely inspired by Sergio Correia's {it:ftools}:
{browse "https://github.com/sergiocorreia/ftools"}.
{p_end}

{pstd}
The OSX version of gtools was implemented with invaluable help from @fbelotti;
see {browse "https://github.com/mcaceresb/stata-gtools/issues/11"}.
{p_end}

{title:Also see}

{p 4 13 2}
help for
{help gtools}; {help reshape}