*! version 0.2.0 19May2017 Mauricio Caceres Bravo, mauricio.caceres.bravo@gmail.com
*! -egen- implementation using C for faster processing

/*
 * syntax:
 *     gegen [type] varname = fun(args) [if] [in], [options]
 *     passed to fun are
 *         [type] varname = fun(args) [if] [in], [options]
 */

* Adapted from egen.ado
capture program drop gegen
program define gegen, byable(onecall)
    version 13

    * Time the entire function execution
    {
        cap timer off 98
        cap timer clear 98
        timer on 98
    }

    * Time program setup
    {
        cap timer off 97
        cap timer clear 97
        timer on 97
    }

    * Parse egen call
    * ---------------

	gettoken type 0 : 0, parse(" =(")
	gettoken name 0 : 0, parse(" =(")

	if (`"`name'"' == "=" ) {
		local name `"`type'"'
		local type : set type
	}
	else {
		gettoken eqsign 0 : 0, parse(" =(")
		if ( `"`eqsign'"' != "=" ) {
			error 198
		}
	}

	confirm new variable `name'
	gettoken fcn 0 : 0, parse(" =(")
	gettoken args 0 : 0, parse(" ,") match(par)

    if ( "`fcn'" == "total" ) local fcn sum
	if ( `"`par'"' != "("  ) exit 198

    * TODO: Figure this out // 2017-05-19 18:00 EDT
	* if ( (`"`args'"' == "_all" ) | (`"`args'"' == "*") ) {
	* 	unab args : _all
	* 	local args : subinstr local args "`_sortindex'"  "", all word
	* }

    * Parse egen by, if, in, and options
    * ----------------------------------

    syntax          /// main call; must parse manually
        [if] [in] , /// subset
    [               ///
        by(varlist) /// collapse by variabes
        Verbose     /// debugging
        Benchmark   /// print benchmark info
        smart       /// check if data is sorted to speed up hashing
        multi    *  /// Multi-threaded version
    ]

	if ( _by() ) {
		* local byopt "by(`_byvars')"
        local by `_byvars'
		local cma ","
	}
	else if ( `"`options'"' != "" ) {
		local cma ","
	}

    * egen to summary stat
    * --------------------

	if ( "`by'" == "" ) {
		* tempvar byvar
		* gen byte `byvar' = 0
		* local by `byvar'
        di as err "-gegen- only provides support for by-able egen functions"
        exit 198
	}
    else {
        qui ds `by'
        local by `r(varlist)'
    }

	tempvar dummy
    qui ds `args'
    local gtools_vars    `r(varlist)'
    local gtools_targets `dummy'
    local gtools_stats   `fcn'

    * Tag and group are handled sepparately
    if inlist("`fcn'", "tag", "group") local by `gtools_vars'

    * Verbose and benchmark printing
    * ------------------------------

    if ("`verbose'" == "") {
        local verbose = 0
        scalar __gtools_verbose = 0
    }
    else {
        local verbose = 1
        scalar __gtools_verbose = 1
    }

    if ("`benchmark'" == "") {
        local benchmark = 0
        scalar __gtools_benchmark = 0
    }
    else {
        local benchmark = 1
        scalar __gtools_benchmark = 1
    }

    * If data already sorted, create index
    * ------------------------------------

    local bysmart ""
	local smart = ("`smart'" != "") & ("`anything'" != "") & ("`by'" != "")
    qui if ( `smart' ) {
        local sortedby: sortedby
        local indexed = (`=_N' < 2^31)
        if ( "`sortedby'" == "" ) {
            local indexed = 0
        }
        else if ( `: list by == sortedby' ) {
            if (`verbose') di as text "data already sorted; indexing in stata"
        }
        else if ( `:list by === sortedby' ) {
            local byorig `by'
            local by `sortedby'
            if ( `verbose' & `indexed' ) di as text "data sorted in similar order (`sortedby'); indexing in stata"
        }
        else {
            forvalues k = 1 / `:list sizeof by' {
                if ("`:word `k' of `by''" != "`:word `k' of `sortedby''") local indexed = 0
                di "`:word `k' of `by'' vs `:word `k' of `sortedby''"
            }
        }

        if ( `indexed' ) {
            if inlist("`fcn'", "tag", "group") local restrict `if' `in'
            tempvar bysmart
            by `by': gen long `bysmart' = (_n == 1) `restrict'
            if ( "`fcn'" == "tag" ) {
                quietly count if missing(`bysmart')
                if ( `r(N)' ) {
                    local s = cond(r(N) > 1, "s", "")
                    di in bl "(" r(N) " missing value`s' generated)"
                }
                rename `bysmart' `name'
                exit
            }
            if ( "`fcn'" == "group" ) {
                replace `bysmart' = sum(`bysmart')
                quietly count if missing(`bysmart')
                if ( `r(N)' ) {
                    local s = cond(r(N) > 1, "s", "")
                    di in bl "(" r(N) " missing value`s' generated)"
                }
                rename `bysmart' `name'
                exit
            }
        }
    }
    else local indexed 0

    * Info for C
    * ----------

    scalar __gtools_l_stats = length("`gtools_stats'")
    scalar __gtools_k_vars  = `:list sizeof gtools_vars'

    * Available functions
    local funcs tag      ///
                group    ///
                sum      ///
                mean     ///
                sd       ///
                max      ///
                min      ///
                count    ///
                median   ///
                iqr      ///
                percent  ///
                first    ///
                last     ///
                firstnm  ///
                lastnm   ///
                quantile

    * Parse quantiles
	if ( "`fcn'" == "quantile" ) {
        local quantbad = !regexm("`options'", "^p[0-9][0-9]?(\.[0-9]+)?$")
		if (`quantbad' | ("`options'" == "p0")) {
			di as error "Invalid quantile: (`options')"
			error 110
		}
        local fcn `options'
	}

    * Parse type of each by variable
    ParseByTypes `by'
    scalar __gtools_merge = 1

    * Add dummy variable; will rename to target variable
    qui mata: st_addvar("`type'", "`dummy'")

    * Position of string variables
    cap matrix drop __gtools_strpos
    foreach var of local bystr_orig {
        matrix __gtools_strpos = nullmat(__gtools_strpos), `:list posof `"`var'"' in by'
    }

    * Position of numeric variables
    cap matrix drop __gtools_numpos
    local bynum `:list by - bystr_orig'
    foreach var of local bynum {
        matrix __gtools_numpos = nullmat(__gtools_numpos), `:list posof `"`var'"' in by'
    }

    * If benchmark, output program setup time
    {
        timer off 97
        qui timer list
        if ( `benchmark' ) di "Program set up executed in `:di trim("`:di %21.4gc r(t97)'")' seconds"
        timer off 97
        timer clear 97
    }

    * Run the plugin
    * --------------

    * Time just the plugin
    {
        cap timer off 99
        cap timer clear 99
        timer on 99
    }

    if ( `verbose'  | `benchmark' ) local noi noisily
    local plugvars `by' `gtools_vars' `gtools_targets' `bysmart'
    scalar __gtools_indexed = cond(`indexed', `:list sizeof plugvars', 0)
    cap `noi' plugin call gtools`multi'_plugin `plugvars' `if' `in', egen `fcn' `options'
    if ( _rc != 0 ) exit _rc

    if ( "`fcn'" == "tag" ) replace `dummy' = 0 if mi(`dummy')
	quietly count if missing(`dummy')
	if ( `r(N)' ) {
		local s = cond(r(N) > 1, "s", "")
		di in bl "(" r(N) " missing value`s' generated)"
	}
	rename `dummy' `name'
end

* Set up plugin call
* ------------------

capture program drop ParseByTypes
program ParseByTypes
    syntax varlist
    cap matrix drop __gtools_byk
    cap matrix drop __gtools_bymin
    cap matrix drop __gtools_bymax

    * See help data_types
    foreach byvar of varlist `varlist' {
        local bytype: type `byvar'
        if inlist("`bytype'", "byte", "int", "long") {
            qui sum `byvar'

            matrix __gtools_byk   = nullmat(__gtools_byk), -1
            matrix __gtools_bymin = nullmat(__gtools_bymin), `r(min)'
            matrix __gtools_bymax = nullmat(__gtools_bymax), `r(max)'
        }
        else {
            matrix __gtools_bymin = J(1, `:list sizeof varlist', 0)
            matrix __gtools_bymax = J(1, `:list sizeof varlist', 0)

            if regexm("`bytype'", "str([1-9][0-9]*|L)") {
                if (regexs(1) == "L") {
                    tempvar strlen
                    gen `strlen' = length(`byvar')
                    qui sum `strlen'
                    matrix __gtools_byk = nullmat(__gtools_byk), `r(max)'
                }
                else {
                    matrix __gtools_byk = nullmat(__gtools_byk), `:di regexs(1)'
                }
            }
            else if inlist("`bytype'", "float", "double") {
                matrix __gtools_byk = nullmat(__gtools_byk), 0
            }
            else {
                di as err "variable `byvar' has unknown type '`bytype''"
            }
        }
    }
end

* Load plugins
* ------------

cap program drop gtools_plugin
if ("`c(os)'" == "Unix") program gtools_plugin, plugin using("gtools.plugin")

cap program drop gtoolsmulti_plugin
if ("`c(os)'" == "Unix") program gtoolsmulti_plugin, plugin using("gtools_multi.plugin")