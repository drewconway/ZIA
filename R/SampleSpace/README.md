- Purpose:    This code will produce a series of comma-separated files to rank NFL football players for the 2011 fantasy football season. 
- Contact:    Drew Conway
- Email:      drew.conway@nyu.edu
- Date:       2011-08-30

Copyright (c) 2010, under the Simplified BSD License.
For more information on FreeBSD see: [http://www.opensource.org/licenses/bsd-license.php](http://www.opensource.org/licenses/bsd-license.php)
All rights reserved.

## How it works ##

The code in `draft_position.R` attempts to estimate the _true_ ranking of a player by analyzing their relative draft position across many mock drafts.  Using data from [http://fantasyfootballcalculator.com/](http://fantasyfootballcalculator.com/) we can mining several drafts that match our own leagues specifications to get a better sense of how the fantasy football marketplace is valuing different NFL players, and also estimate the amount of variance, i.e., error, in these estimates for these players.

The script has a few global variables:

 - `num.teams` (Number of teams in league)
 - `rounds` (Number of rounds completed in the mock draft)
 - `humans` (Number of human drafters in the draft)
 - `num.obs` (Number of drafts to scrape and parse)

For my own league I play in a standard scoring system, with 10 teams.  With ten teams, the standard number of rounds required to complete a draft is 15.  For my purposes, I want at least half of the drafters to be human, so I set `humans` to 5.  The purpose of this code is to get a sense of how the market is valuing the players, not how "experts" are ranking them.  Computer drafts rely only on expert rankings, so we want to limit the number of computer drafts.  Finally, I want to limit the amount of historic uncertainty that enters the data---especially given the abbreviated off-season this year.  So, I will only scrape the last 500 mock drafts that match my criteria.

## The Results ##

The code will take this information and begin building a data set of matching mock drafts, until the number of observations is greater than or equal to `num.obs`. It will then output two files:

 - `raw_drafts.csv` (The raw draft position data from all scraped data)
 - `stats_drafts.csv` (A file containing summary statistics from the raw data)
 
For analytical purposes, we are more interested in `stats_drafts.csv`, because this will provide the insight about player valuation we want.  To understand how to read the table, let's look at the top ten players by mean draft position (default ordering):

<TABLE FRAME=VOID CELLSPACING=0 COLS=8 RULES=NONE BORDER=0 ALIGN=CENTER>
	<COLGROUP><COL WIDTH=150><COL WIDTH=97><COL WIDTH=97><COL WIDTH=117><COL WIDTH=108><COL WIDTH=97><COL WIDTH=97><COL WIDTH=97></COLGROUP>
	<TBODY>
		<TR>
			<TD STYLE="border-top: 1px solid #000000; border-bottom: 3px solid #000000; border-left: 1px solid #000000; border-right: 1px solid #000000" WIDTH=150 HEIGHT=18 ALIGN=LEFT BGCOLOR="#FFFFCC"><B>Player</B></TD>
			<TD STYLE="border-top: 1px solid #000000; border-bottom: 3px solid #000000; border-left: 1px solid #000000; border-right: 1px solid #000000" WIDTH=97 ALIGN=LEFT BGCOLOR="#FFFFCC"><B>Position</B></TD>
			<TD STYLE="border-top: 1px solid #000000; border-bottom: 3px solid #000000; border-left: 1px solid #000000; border-right: 1px solid #000000" WIDTH=97 ALIGN=LEFT BGCOLOR="#FFFFCC"><B>Team</B></TD>
			<TD STYLE="border-top: 1px solid #000000; border-bottom: 3px solid #000000; border-left: 1px solid #000000; border-right: 1px solid #000000" WIDTH=117 ALIGN=LEFT BGCOLOR="#FFFFCC"><B>Mean</B></TD>
			<TD STYLE="border-top: 1px solid #000000; border-bottom: 3px solid #000000; border-left: 1px solid #000000; border-right: 1px solid #000000" WIDTH=108 ALIGN=LEFT BGCOLOR="#FFFFCC"><B>StdDev</B></TD>
			<TD STYLE="border-top: 1px solid #000000; border-bottom: 3px solid #000000; border-left: 1px solid #000000; border-right: 1px solid #000000" WIDTH=97 ALIGN=LEFT BGCOLOR="#FFFFCC"><B>Freq</B></TD>
			<TD STYLE="border-top: 1px solid #000000; border-bottom: 3px solid #000000; border-left: 1px solid #000000; border-right: 1px solid #000000" WIDTH=97 ALIGN=LEFT BGCOLOR="#FFFFCC"><B>MAD</B></TD>
			<TD STYLE="border-top: 1px solid #000000; border-bottom: 3px solid #000000; border-left: 1px solid #000000; border-right: 1px solid #000000" WIDTH=97 ALIGN=LEFT BGCOLOR="#FFFFCC"><B>Median</B></TD>
		</TR>
		<TR>
			<TD STYLE="border-top: 1px solid #000000; border-bottom: 1px solid #000000; border-left: 1px solid #000000; border-right: 1px solid #000000" HEIGHT=18 ALIGN=LEFT>ArianFoster</TD>
			<TD STYLE="border-top: 1px solid #000000; border-bottom: 1px solid #000000; border-left: 1px solid #000000; border-right: 1px solid #000000" ALIGN=LEFT>RB</TD>
			<TD STYLE="border-top: 1px solid #000000; border-bottom: 1px solid #000000; border-left: 1px solid #000000; border-right: 1px solid #000000" ALIGN=LEFT>HOU</TD>
			<TD STYLE="border-top: 1px solid #000000; border-bottom: 1px solid #000000; border-left: 1px solid #000000; border-right: 1px solid #000000" ALIGN=RIGHT SDVAL="1.83233532934132" SDNUM="1033;">1.8323353293</TD>
			<TD STYLE="border-top: 1px solid #000000; border-bottom: 1px solid #000000; border-left: 1px solid #000000; border-right: 1px solid #000000" ALIGN=RIGHT SDVAL="0.846068753311066" SDNUM="1033;">0.8460687533</TD>
			<TD STYLE="border-top: 1px solid #000000; border-bottom: 1px solid #000000; border-left: 1px solid #000000; border-right: 1px solid #000000" ALIGN=RIGHT SDVAL="1" SDNUM="1033;">1</TD>
			<TD STYLE="border-top: 1px solid #000000; border-bottom: 1px solid #000000; border-left: 1px solid #000000; border-right: 1px solid #000000" ALIGN=RIGHT SDVAL="1.4826" SDNUM="1033;">1.4826</TD>
			<TD STYLE="border-top: 1px solid #000000; border-bottom: 1px solid #000000; border-left: 1px solid #000000; border-right: 1px solid #000000" ALIGN=RIGHT SDVAL="2" SDNUM="1033;">2</TD>
		</TR>
		<TR>
			<TD STYLE="border-top: 1px solid #000000; border-bottom: 1px solid #000000; border-left: 1px solid #000000; border-right: 1px solid #000000" HEIGHT=18 ALIGN=LEFT>AdrianPeterson</TD>
			<TD STYLE="border-top: 1px solid #000000; border-bottom: 1px solid #000000; border-left: 1px solid #000000; border-right: 1px solid #000000" ALIGN=LEFT>RB</TD>
			<TD STYLE="border-top: 1px solid #000000; border-bottom: 1px solid #000000; border-left: 1px solid #000000; border-right: 1px solid #000000" ALIGN=LEFT>MIN</TD>
			<TD STYLE="border-top: 1px solid #000000; border-bottom: 1px solid #000000; border-left: 1px solid #000000; border-right: 1px solid #000000" ALIGN=RIGHT SDVAL="2" SDNUM="1033;">2</TD>
			<TD STYLE="border-top: 1px solid #000000; border-bottom: 1px solid #000000; border-left: 1px solid #000000; border-right: 1px solid #000000" ALIGN=RIGHT SDVAL="1.12782977438973" SDNUM="1033;">1.1278297744</TD>
			<TD STYLE="border-top: 1px solid #000000; border-bottom: 1px solid #000000; border-left: 1px solid #000000; border-right: 1px solid #000000" ALIGN=RIGHT SDVAL="1" SDNUM="1033;">1</TD>
			<TD STYLE="border-top: 1px solid #000000; border-bottom: 1px solid #000000; border-left: 1px solid #000000; border-right: 1px solid #000000" ALIGN=RIGHT SDVAL="1.4826" SDNUM="1033;">1.4826</TD>
			<TD STYLE="border-top: 1px solid #000000; border-bottom: 1px solid #000000; border-left: 1px solid #000000; border-right: 1px solid #000000" ALIGN=RIGHT SDVAL="2" SDNUM="1033;">2</TD>
		</TR>
		<TR>
			<TD STYLE="border-top: 1px solid #000000; border-bottom: 1px solid #000000; border-left: 1px solid #000000; border-right: 1px solid #000000" HEIGHT=20 ALIGN=LEFT>JamaalCharles</TD>
			<TD STYLE="border-top: 1px solid #000000; border-bottom: 1px solid #000000; border-left: 1px solid #000000; border-right: 1px solid #000000" ALIGN=LEFT>RB</TD>
			<TD STYLE="border-top: 1px solid #000000; border-bottom: 1px solid #000000; border-left: 1px solid #000000; border-right: 1px solid #000000" ALIGN=LEFT>KC</TD>
			<TD STYLE="border-top: 1px solid #000000; border-bottom: 1px solid #000000; border-left: 1px solid #000000; border-right: 1px solid #000000" ALIGN=RIGHT SDVAL="3.61077844311377" SDNUM="1033;">3.6107784431</TD>
			<TD STYLE="border-top: 1px solid #000000; border-bottom: 1px solid #000000; border-left: 1px solid #000000; border-right: 1px solid #000000" ALIGN=RIGHT SDVAL="1.44020956558911" SDNUM="1033;">1.4402095656</TD>
			<TD STYLE="border-top: 1px solid #000000; border-bottom: 1px solid #000000; border-left: 1px solid #000000; border-right: 1px solid #000000" ALIGN=RIGHT SDVAL="1" SDNUM="1033;">1</TD>
			<TD STYLE="border-top: 1px solid #000000; border-bottom: 1px solid #000000; border-left: 1px solid #000000; border-right: 1px solid #000000" ALIGN=RIGHT SDVAL="1.4826" SDNUM="1033;">1.4826</TD>
			<TD STYLE="border-top: 1px solid #000000; border-bottom: 1px solid #000000; border-left: 1px solid #000000; border-right: 1px solid #000000" ALIGN=RIGHT SDVAL="4" SDNUM="1033;">4</TD>
		</TR>
		<TR>
			<TD STYLE="border-top: 1px solid #000000; border-bottom: 1px solid #000000; border-left: 1px solid #000000; border-right: 1px solid #000000" HEIGHT=18 ALIGN=LEFT>RayRice</TD>
			<TD STYLE="border-top: 1px solid #000000; border-bottom: 1px solid #000000; border-left: 1px solid #000000; border-right: 1px solid #000000" ALIGN=LEFT>RB</TD>
			<TD STYLE="border-top: 1px solid #000000; border-bottom: 1px solid #000000; border-left: 1px solid #000000; border-right: 1px solid #000000" ALIGN=LEFT>BAL</TD>
			<TD STYLE="border-top: 1px solid #000000; border-bottom: 1px solid #000000; border-left: 1px solid #000000; border-right: 1px solid #000000" ALIGN=RIGHT SDVAL="3.98802395209581" SDNUM="1033;">3.9880239521</TD>
			<TD STYLE="border-top: 1px solid #000000; border-bottom: 1px solid #000000; border-left: 1px solid #000000; border-right: 1px solid #000000" ALIGN=RIGHT SDVAL="1.75267118633963" SDNUM="1033;">1.7526711863</TD>
			<TD STYLE="border-top: 1px solid #000000; border-bottom: 1px solid #000000; border-left: 1px solid #000000; border-right: 1px solid #000000" ALIGN=RIGHT SDVAL="1" SDNUM="1033;">1</TD>
			<TD STYLE="border-top: 1px solid #000000; border-bottom: 1px solid #000000; border-left: 1px solid #000000; border-right: 1px solid #000000" ALIGN=RIGHT SDVAL="1.4826" SDNUM="1033;">1.4826</TD>
			<TD STYLE="border-top: 1px solid #000000; border-bottom: 1px solid #000000; border-left: 1px solid #000000; border-right: 1px solid #000000" ALIGN=RIGHT SDVAL="4" SDNUM="1033;">4</TD>
		</TR>
		<TR>
			<TD STYLE="border-top: 1px solid #000000; border-bottom: 1px solid #000000; border-left: 1px solid #000000; border-right: 1px solid #000000" HEIGHT=18 ALIGN=LEFT>ChrisJohnson</TD>
			<TD STYLE="border-top: 1px solid #000000; border-bottom: 1px solid #000000; border-left: 1px solid #000000; border-right: 1px solid #000000" ALIGN=LEFT>RB</TD>
			<TD STYLE="border-top: 1px solid #000000; border-bottom: 1px solid #000000; border-left: 1px solid #000000; border-right: 1px solid #000000" ALIGN=LEFT>TEN</TD>
			<TD STYLE="border-top: 1px solid #000000; border-bottom: 1px solid #000000; border-left: 1px solid #000000; border-right: 1px solid #000000" ALIGN=RIGHT SDVAL="6.54491017964072" SDNUM="1033;">6.5449101796</TD>
			<TD STYLE="border-top: 1px solid #000000; border-bottom: 1px solid #000000; border-left: 1px solid #000000; border-right: 1px solid #000000" ALIGN=RIGHT SDVAL="1.0828107137982" SDNUM="1033;">1.0828107138</TD>
			<TD STYLE="border-top: 1px solid #000000; border-bottom: 1px solid #000000; border-left: 1px solid #000000; border-right: 1px solid #000000" ALIGN=RIGHT SDVAL="1" SDNUM="1033;">1</TD>
			<TD STYLE="border-top: 1px solid #000000; border-bottom: 1px solid #000000; border-left: 1px solid #000000; border-right: 1px solid #000000" ALIGN=RIGHT SDVAL="1.4826" SDNUM="1033;">1.4826</TD>
			<TD STYLE="border-top: 1px solid #000000; border-bottom: 1px solid #000000; border-left: 1px solid #000000; border-right: 1px solid #000000" ALIGN=RIGHT SDVAL="6" SDNUM="1033;">6</TD>
		</TR>
		<TR>
			<TD STYLE="border-top: 1px solid #000000; border-bottom: 1px solid #000000; border-left: 1px solid #000000; border-right: 1px solid #000000" HEIGHT=18 ALIGN=LEFT>LeSeanMcCoy</TD>
			<TD STYLE="border-top: 1px solid #000000; border-bottom: 1px solid #000000; border-left: 1px solid #000000; border-right: 1px solid #000000" ALIGN=LEFT>RB</TD>
			<TD STYLE="border-top: 1px solid #000000; border-bottom: 1px solid #000000; border-left: 1px solid #000000; border-right: 1px solid #000000" ALIGN=LEFT>PHI</TD>
			<TD STYLE="border-top: 1px solid #000000; border-bottom: 1px solid #000000; border-left: 1px solid #000000; border-right: 1px solid #000000" ALIGN=RIGHT SDVAL="6.89820359281437" SDNUM="1033;">6.8982035928</TD>
			<TD STYLE="border-top: 1px solid #000000; border-bottom: 1px solid #000000; border-left: 1px solid #000000; border-right: 1px solid #000000" ALIGN=RIGHT SDVAL="1.5124869475361" SDNUM="1033;">1.5124869475</TD>
			<TD STYLE="border-top: 1px solid #000000; border-bottom: 1px solid #000000; border-left: 1px solid #000000; border-right: 1px solid #000000" ALIGN=RIGHT SDVAL="1" SDNUM="1033;">1</TD>
			<TD STYLE="border-top: 1px solid #000000; border-bottom: 1px solid #000000; border-left: 1px solid #000000; border-right: 1px solid #000000" ALIGN=RIGHT SDVAL="1.4826" SDNUM="1033;">1.4826</TD>
			<TD STYLE="border-top: 1px solid #000000; border-bottom: 1px solid #000000; border-left: 1px solid #000000; border-right: 1px solid #000000" ALIGN=RIGHT SDVAL="7" SDNUM="1033;">7</TD>
		</TR>
		<TR>
			<TD STYLE="border-top: 1px solid #000000; border-bottom: 1px solid #000000; border-left: 1px solid #000000; border-right: 1px solid #000000" HEIGHT=20 ALIGN=LEFT>MichaelVick</TD>
			<TD STYLE="border-top: 1px solid #000000; border-bottom: 1px solid #000000; border-left: 1px solid #000000; border-right: 1px solid #000000" ALIGN=LEFT>QB</TD>
			<TD STYLE="border-top: 1px solid #000000; border-bottom: 1px solid #000000; border-left: 1px solid #000000; border-right: 1px solid #000000" ALIGN=LEFT>PHI</TD>
			<TD STYLE="border-top: 1px solid #000000; border-bottom: 1px solid #000000; border-left: 1px solid #000000; border-right: 1px solid #000000" ALIGN=RIGHT SDVAL="7.23952095808383" SDNUM="1033;">7.2395209581</TD>
			<TD STYLE="border-top: 1px solid #000000; border-bottom: 1px solid #000000; border-left: 1px solid #000000; border-right: 1px solid #000000" ALIGN=RIGHT SDVAL="4.45269749366155" SDNUM="1033;">4.4526974937</TD>
			<TD STYLE="border-top: 1px solid #000000; border-bottom: 1px solid #000000; border-left: 1px solid #000000; border-right: 1px solid #000000" ALIGN=RIGHT SDVAL="1" SDNUM="1033;">1</TD>
			<TD STYLE="border-top: 1px solid #000000; border-bottom: 1px solid #000000; border-left: 1px solid #000000; border-right: 1px solid #000000" ALIGN=RIGHT SDVAL="2.9652" SDNUM="1033;">2.9652</TD>
			<TD STYLE="border-top: 1px solid #000000; border-bottom: 1px solid #000000; border-left: 1px solid #000000; border-right: 1px solid #000000" ALIGN=RIGHT SDVAL="7" SDNUM="1033;">7</TD>
		</TR>
		<TR>
			<TD STYLE="border-top: 1px solid #000000; border-bottom: 1px solid #000000; border-left: 1px solid #000000; border-right: 1px solid #000000" HEIGHT=18 ALIGN=LEFT>AndreJohnson</TD>
			<TD STYLE="border-top: 1px solid #000000; border-bottom: 1px solid #000000; border-left: 1px solid #000000; border-right: 1px solid #000000" ALIGN=LEFT>WR</TD>
			<TD STYLE="border-top: 1px solid #000000; border-bottom: 1px solid #000000; border-left: 1px solid #000000; border-right: 1px solid #000000" ALIGN=LEFT>HOU</TD>
			<TD STYLE="border-top: 1px solid #000000; border-bottom: 1px solid #000000; border-left: 1px solid #000000; border-right: 1px solid #000000" ALIGN=RIGHT SDVAL="9.04191616766467" SDNUM="1033;">9.0419161677</TD>
			<TD STYLE="border-top: 1px solid #000000; border-bottom: 1px solid #000000; border-left: 1px solid #000000; border-right: 1px solid #000000" ALIGN=RIGHT SDVAL="5.25283157172949" SDNUM="1033;">5.2528315717</TD>
			<TD STYLE="border-top: 1px solid #000000; border-bottom: 1px solid #000000; border-left: 1px solid #000000; border-right: 1px solid #000000" ALIGN=RIGHT SDVAL="1" SDNUM="1033;">1</TD>
			<TD STYLE="border-top: 1px solid #000000; border-bottom: 1px solid #000000; border-left: 1px solid #000000; border-right: 1px solid #000000" ALIGN=RIGHT SDVAL="2.9652" SDNUM="1033;">2.9652</TD>
			<TD STYLE="border-top: 1px solid #000000; border-bottom: 1px solid #000000; border-left: 1px solid #000000; border-right: 1px solid #000000" ALIGN=RIGHT SDVAL="7" SDNUM="1033;">7</TD>
		</TR>
		<TR>
			<TD STYLE="border-top: 1px solid #000000; border-bottom: 1px solid #000000; border-left: 1px solid #000000; border-right: 1px solid #000000" HEIGHT=20 ALIGN=LEFT>RashardMendenhall</TD>
			<TD STYLE="border-top: 1px solid #000000; border-bottom: 1px solid #000000; border-left: 1px solid #000000; border-right: 1px solid #000000" ALIGN=LEFT>RB</TD>
			<TD STYLE="border-top: 1px solid #000000; border-bottom: 1px solid #000000; border-left: 1px solid #000000; border-right: 1px solid #000000" ALIGN=LEFT>PIT</TD>
			<TD STYLE="border-top: 1px solid #000000; border-bottom: 1px solid #000000; border-left: 1px solid #000000; border-right: 1px solid #000000" ALIGN=RIGHT SDVAL="9.86826347305389" SDNUM="1033;">9.8682634731</TD>
			<TD STYLE="border-top: 1px solid #000000; border-bottom: 1px solid #000000; border-left: 1px solid #000000; border-right: 1px solid #000000" ALIGN=RIGHT SDVAL="3.76066626788966" SDNUM="1033;">3.7606662679</TD>
			<TD STYLE="border-top: 1px solid #000000; border-bottom: 1px solid #000000; border-left: 1px solid #000000; border-right: 1px solid #000000" ALIGN=RIGHT SDVAL="1" SDNUM="1033;">1</TD>
			<TD STYLE="border-top: 1px solid #000000; border-bottom: 1px solid #000000; border-left: 1px solid #000000; border-right: 1px solid #000000" ALIGN=RIGHT SDVAL="1.4826" SDNUM="1033;">1.4826</TD>
			<TD STYLE="border-top: 1px solid #000000; border-bottom: 1px solid #000000; border-left: 1px solid #000000; border-right: 1px solid #000000" ALIGN=RIGHT SDVAL="9" SDNUM="1033;">9</TD>
		</TR>
		<TR>
			<TD STYLE="border-top: 1px solid #000000; border-bottom: 1px solid #000000; border-left: 1px solid #000000; border-right: 1px solid #000000" HEIGHT=20 ALIGN=LEFT>AaronRodgers</TD>
			<TD STYLE="border-top: 1px solid #000000; border-bottom: 1px solid #000000; border-left: 1px solid #000000; border-right: 1px solid #000000" ALIGN=LEFT>QB</TD>
			<TD STYLE="border-top: 1px solid #000000; border-bottom: 1px solid #000000; border-left: 1px solid #000000; border-right: 1px solid #000000" ALIGN=LEFT>GB</TD>
			<TD STYLE="border-top: 1px solid #000000; border-bottom: 1px solid #000000; border-left: 1px solid #000000; border-right: 1px solid #000000" ALIGN=RIGHT SDVAL="13.1137724550898" SDNUM="1033;">13.1137724551</TD>
			<TD STYLE="border-top: 1px solid #000000; border-bottom: 1px solid #000000; border-left: 1px solid #000000; border-right: 1px solid #000000" ALIGN=RIGHT SDVAL="5.73140732631347" SDNUM="1033;">5.7314073263</TD>
			<TD STYLE="border-top: 1px solid #000000; border-bottom: 1px solid #000000; border-left: 1px solid #000000; border-right: 1px solid #000000" ALIGN=RIGHT SDVAL="1" SDNUM="1033;">1</TD>
			<TD STYLE="border-top: 1px solid #000000; border-bottom: 1px solid #000000; border-left: 1px solid #000000; border-right: 1px solid #000000" ALIGN=RIGHT SDVAL="5.9304" SDNUM="1033;">5.9304</TD>
			<TD STYLE="border-top: 1px solid #000000; border-bottom: 1px solid #000000; border-left: 1px solid #000000; border-right: 1px solid #000000" ALIGN=RIGHT SDVAL="16" SDNUM="1033;">16</TD>
		</TR>
	</TBODY>
</TABLE>

The first three columns provide identifying information about the players: name, position, and team.  The next six are the summary statistics from the mock draft data mining.  The `Mean` and `StdDev` columns provide basic numeric estimate of the true rank of a player; i.e., market value, and the variance of that rank; i.e., market uncertainty.  From this analysis it seems that both Arian Foster and Adrian Peterson are very close to being tied for second, with neither being the clear first overall pick.  That said, it seems the market has slightly more confidence in Arian Foster's rank, as the standard deviation for his rank is much closer to zero.  

The next column is `Freq`, and this tells you the percentage of drafts from the total mined wherein the player was drafted.  Obviously, looking at the top 10 picks, all of these players were drafted in 100% of the drafts.  But, as you look further down the rankings you will notice that many players were not.  For example, Mark Sanchez (QB-NYJ) is ranked 125th overall but was only drafted in ~9% of the mock drafts (presumedly all Jets fans).  While Kyle Orton (QB-DEN) is ranked 127th overall, but was drafted in 100% of the mock drafts.  Something to keep in mind when making later round selections.

Finally, the `MAD` and `Median` provide a discrete ranking of the players.  Because we are dealing with rankings, the median value can be easier to interpret because median have an inherent rank ordering.  Likewise `MAD` (median absolute deviation) provides a numeric estimate of the variance of that ranking.  Like standard deviation, the lower the MAD score, the less uncertainty the market has in the player's rank.  Note, both Arian Foster and Adrian Peterson have a median rank of 2, with identical MAD scores.  This reinforces out previous observation that the current market does not believe either is the clear #1.

## Analyzing Uncertainty ##

In the `images/` folder I have also generated one visualization of the data, called `hard_valution.png`

<p align="center"><a href="https://github.com/drewconway/ZIA/raw/master/R/SampleSpace/images/hard_valuation.png" target="_blank"><img src="https://github.com/drewconway/ZIA/raw/master/R/SampleSpace/images/hard_valuation.png" width=800 alt="Most Variant Player Rankings in 2011 Fantasy Football"></a></p>

Using the MAD score as our measure of variance, the above visualization highlights the players in the 95th percentile of this statistics.  These are the players that have the highest variance in their ranking.  Along the x-axis are the players median ranks, and along the y-axis as the MAD scores.  What is nice about this is we can see how uncertainty peaks between draft selections 80 and 100, then sharply declines.  This makes sense, as the best and worst players are likely well-known, but those with risk and upside are drafted in the middle rounds.

This image was generated at about 12:00PM (EDT) on August 30, 2011, and you can see from it the timing of your analysis makes a big difference in the market's uncertainty in a player's rank.  If we look at the names highlighted above we see that we see many players who have had mediocre pre-seasons, or are on new teams where their performance may be in question.  

**Because the data source is constantly changing, no two tuns of this code will produce exactly the same results**.  You will find, however, that after multiple runs many of the same names keep popping up.  In this case: Ben Roethlisbeger, Mercedes Lewis, Rob Gronkowski, and C.J. Spiller were all players who were consistently among those with the most uncertainty in the 2011 fantasy football season.


### Bonus Data ###

In the `Players/` folder you will find separate CSV files for 2010 player statistics by position.  This data is provided by [http://www.advancednflstats.com/](http://www.advancednflstats.com/).

### Running Code after 2011 ###

Please note that this code may break if you attempt to run it after the 2011 season.  The supporting websites may change their policies or formats, which could cause the code to break.  In that case, you're on your own!