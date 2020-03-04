clear
cd "#Path#\Daylight Trading"

import delimited "btc.csv", clear
keep priceusd date
drop if priceusd ==.
gen t = date(date, "YMD", 2020) 
format t %td

tset t
gen day = 5
replace day = mod(day[_n-1] + 1, 7) if _n != 1
replace day = day + 1

gen year = substr(date, 1, 4)
destring year, replace

gen week = wofd(t)
sort week
by week: egen wkmean = mean(priceusd)
drop if year == 2009
sort t
gen pwkl = priceusd / L.wkmean - 1
*basic data set complete
sort day
forvalues i = 11/21{
local j = `i' - 2
local k = `i' - 1
by day: egen y20`k' = mean(pwkl) if t > date("31.12.20`j'", "DMY") & t < date("01.01.20`i'", "DMY")
}

sort year day
duplicates drop (year day), force

forvalues j = 1/10{
forvalues i = 10/20{
replace y20`i' = y20`i'[_n+7] if y20`i' ==.
}
}
*end loop
drop if y2010 ==.
keep day y20* 


sort t
br t priceusd pwkl


twoway (line pwkl L7.pwkl) (sc pwkl L7.pwkl) if t>date("1.1.2020", "DMY")
reg pwkl L7.pwkl if t>date("1.1.2020", "DMY")

*Funny findings in AC-plot: lesser than 1-week lags are "significant" but
	*this is only due to the fact that priceusd is divided by a variable that is 
	*constant on a weekly base. Thus these correlations should be spurious.
	*at the same time, no 7*n-th lag is significant.
ac pwkl
