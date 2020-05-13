cd "pathasstr" //set working directory

import delimited "https://coinmetrics.io/newdata/btc.csv", clear
*import delimited "btc.csv", clear
br

keep date blkcnt splycur priceusd capmrktcurusd

************************
* Calculating the theoretically correct Ammousian SF
* (very slow)
************************
drop if blkcnt == 0
gen blkhght = sum(blkcnt)
gen expFlow = .

local O = _N + 400
set obs `O'


local N = _N
forvalues i = 1/`N'{
gen  temp_blkhght = blkhght
replace  temp_blkhght =  temp_blkhght[_n-1] + 144 if _n > `i' 
gen temp_hper = .

forvalues k = 1/3 {
local j = `k' - 1
replace temp_hper = `j' if  temp_blkhght > `j' * 210000 & _n  >= `i' 
}

gen  temp_flowd = 144*50/2^(temp_hper)
gen temp_stock = sum(temp_flowd)
replace expFlow = temp_stock[`i' + 365] - temp_stock[`i'] if _n == `i'
drop temp*
}

gen realFlow = splycur[_n+365] - splycur[_n]


gen t = date(date, "YMD")
format t %td
tset t
save .\VoB\BTC.dta, replace 


**********************
* Calculate the vars of interest
**********************
use .\VoB\BTC.dta, clear
gen SFa = splycur/exp

gen lnSFa = ln(SFa)
gen lnMC = ln(capmrkt)
gen SF = splycur/(12*splycur[_n]-12*splycur[_n-30])
gen lnSF = ln(SF)

quietly reg lnMC lnSF
predict lnSF_fit
predict lnSF_res, residuals

quietly reg lnMC lnSFa
predict lnSFa_fit
predict lnSFa_res, residuals

drop if price==.
drop blkcnt blkhght date
order t splycur exp
save .\VoB\BTC.dta, replace 

*****************************
* perform Analysis
*****************************

varsoc lnMC, ex(lnSFa) maxlag(30) 

vecrank lnMC lnSFa, lags(7) // cool, very clean CI!

egranger lnMC lnSFa, lags(24)
twoway (line lnMC t) (line lnSFa t, yax(2) )
