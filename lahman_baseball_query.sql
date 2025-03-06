-- LAHMAN BASEBALL DATABASE EXERCISE --

-- 1. Find all players in the database who played at Vanderbilt University. Create a list showing each player's first and last names as well as the total salary they earned in the major leagues. Sort this list in descending order by the total salary earned. Which Vanderbilt player earned the most money in the majors?

SELECT 
    vp.namefirst AS "First Name", 
    vp.namelast AS "Last Name",
    COALESCE(SUM(s.salary), 0) AS "Total Salary"
FROM 
    (SELECT DISTINCT p.playerid, p.namefirst, p.namelast
     FROM people p
     JOIN collegeplaying cp ON p.playerid = cp.playerid
     JOIN schools sc ON cp.schoolid = sc.schoolid
     WHERE sc.schoolname = 'Vanderbilt University') vp
LEFT JOIN salaries s ON vp.playerid = s.playerid
GROUP BY vp.playerid, vp.namefirst, vp.namelast
HAVING SUM(s.salary) IS NOT NULL
ORDER BY SUM(s.salary) DESC;

-- 2.Using the fielding table, group players into three groups based on their position: label players with position OF as "Outfield", those with position "SS", "1B", "2B", and "3B" as "Infield", and those with position "P" or "C" as "Battery". Determine the number of putouts made by each of these three groups in 2016.
SELECT SUM(po) AS total_putouts,
CASE 
	WHEN pos = 'OF' THEN 'Outfield'
	WHEN pos = 'SS' THEN 'Infield'
	WHEN pos = '1B' THEN 'Infield'
	WHEN pos = '2B' THEN 'Infield'
	WHEN pos = '3B' THEN 'Infield'
	WHEN pos = 'P' THEN 'Battery'
	WHEN pos = 'C' THEN 'Battery'
	ELSE 'other'
	END AS grouped_positions
FROM fielding
WHERE yearid = 2016
GROUP BY yearid, grouped_positions
ORDER BY total_putouts DESC;


--- other example --- 
SELECT SUM(po) AS total_putouts,
WHEN pos = 'OF' THEN 'Outfield'
            WHEN pos IN ('SS', '1B', '2B', '3B') THEN 'Infield'
            WHEN pos IN ('P', 'C') THEN 'Battery'
            ELSE 'Other'
			


-- 3. Find the average number of strikeouts per game by decade since 1920. Round the numbers you report to 2 decimal places. Do the same for home runs per game. Do you see any trends? (Hint: For this question, you might find it helpful to look at the **generate_series** function (https://www.postgresql.org/docs/9.1/functions-srf.html). If you want to see an example of this in action, check out this DataCamp video: https://campus.datacamp.com/courses/exploratory-data-analysis-in-sql/summarizing-and-aggregating-numeric-data?ex=6)
WITH decades AS (
	SELECT generate_series(1920, 2010, 10) AS lower,
			generate_series(1929, 2016, 10) AS upper
),
strikeouts AS(
	SELECT so, yearid, hr
	FROM teams
	WHERE yearid BETWEEN 1920 AND 2016
)

SELECT upper, lower, ROUND(AVG(so), 2) AS avg_so_per_game, ROUND(AVG(hr), 2) AS avg_hr_per_game
FROM decades
LEFT JOIN strikeouts
	ON	yearid >= lower
	AND yearid < upper
GROUP BY upper, lower;

---
WITH bins AS(
     SELECT generate_series(1920,2010,10) AS lower,
	        generate_series(1930,2020,10) AS upper)
SELECT 
	lower, 
	upper, 
	ROUND((CAST(SUM(so) AS NUMERIC))/(CAST(SUM(g) AS NUMERIC)/2), 2) AS avg_strikeout_per_game, 
	ROUND((CAST(SUM(hr) AS NUMERIC))/(CAST(SUM(g) AS NUMERIC)/2), 2) AS avg_hr
	 FROM bins
		 LEFT JOIN teams
		 ON yearid >= lower 
		 AND yearid <= upper
 GROUP BY lower, upper
 ORDER BY lower, upper;
-- 4. Find the player who had the most success stealing bases in 2016, where __success__ is measured as the percentage of stolen base attempts which are successful. (A stolen base attempt results either in a stolen base or being caught stealing.) Consider only players who attempted _at least_ 20 stolen bases. Report the players' names, number of stolen bases, number of attempts, and stolen base percentage.
WITH stolen_bases AS(
	SELECT playerid, sb, cs, yearid, (sb + cs) AS stolen_attempts, ROUND((sb * 1.0 / (sb + cs)), 2) * 100 AS stolen_successful
	FROM batting
	WHERE yearid = 2016
)

SELECT people.playerid, people.namefirst, people.namelast, stolen_bases.sb, stolen_bases.cs, stolen_bases.stolen_attempts, stolen_bases.stolen_successful
FROM people
LEFT JOIN stolen_bases
	ON people.playerid = stolen_bases.playerid
WHERE stolen_bases.stolen_attempts >= 20
ORDER BY stolen_bases.stolen_successful DESC
LIMIT 1;

-- 5. From 1970 to 2016, what is the largest number of wins for a team that did not win the world series? What is the smallest number of wins for a team that did win the world series? Doing this will probably result in an unusually small number of wins for a world series champion; determine why this is the case. Then redo your query, excluding the problem year. How often from 1970 to 2016 was it the case that a team with the most wins also won the world series? What percentage of the time?

SELECT teamID, MAX(W) as max_wins
FROM teams
WHERE yearID BETWEEN 1970 AND 2016 
	AND WSWin = 'N'
GROUP BY teamID
ORDER BY max_wins DESC
LIMIT 1;

		-- 2001 SEA with 116 wins 
SELECT teamID, MIN(W) AS min_wins, yearID
FROM teams
WHERE yearID BETWEEN 1970 AND 2016 
	AND WSWin = 'Y'
GROUP BY teamID, yearID
ORDER BY min_wins ASC
LIMIT 2;
		-- Then redo your query, excluding the problem year.
SELECT teamID, MIN(W) AS min_wins, yearID
FROM teams
WHERE yearID BETWEEN 1970 AND 2016 
	AND WSWin = 'Y'
	AND yearID != 1981
GROUP BY teamID, yearID
ORDER BY min_wins ASC
LIMIT 2;
	-- How often from 1970 to 2016 was it the case that a team with the most wins also won the world series? What percentage of the time?
WITH max_win_teams AS (
    SELECT yearid, MAX(w) as max_wins
    FROM teams
    WHERE yearid BETWEEN 1970 AND 2016 AND yearid != 1981
    GROUP BY yearid
),
winners AS (
    SELECT m.yearid
    FROM max_win_teams m
    JOIN teams t ON m.yearid = t.yearid AND m.max_wins = t.w AND t.wswin = 'Y'
)
SELECT 
    COUNT(*) AS total_matching_years,
    (COUNT(*)::FLOAT / 46 * 100)::NUMERIC(5,2) AS percentage
FROM winners;
-- team with the most wins only wins 26.09% of the time 


-- 6. Which managers have won the TSN Manager of the Year award in both the National League (NL) and the American League (AL)? Give their full name and the teams that they were managing when they won the award.

WITH TSN_manager AS (
    SELECT playerid, yearid
    FROM awardsmanagers
    WHERE awardid = 'TSN Manager of the Year'
        AND (lgid = 'ML' OR lgid = 'NL')
),
winning_managers AS (
    SELECT TSN_manager.yearid AS award_year, people.namefirst, people.namelast
    FROM TSN_manager
    LEFT JOIN people ON TSN_manager.playerid = people.playerid
),
matched_managers AS (
    SELECT winning_managers.award_year, winning_managers.namefirst, winning_managers.namelast, managershalf.teamid, managershalf.yearid AS managershalf_year
    FROM winning_managers
    LEFT JOIN managershalf ON winning_managers.award_year = managershalf.yearid
)
SELECT matched_managers.award_year, matched_managers.namefirst, matched_managers.namelast, teams.name AS team_name
FROM matched_managers
LEFT JOIN teams ON matched_managers.teamid = teams.teamid
ORDER BY matched_managers.award_year;

-- 7. Which pitcher was the least efficient in 2016 in terms of salary / strikeouts? Only consider pitchers who started at least 10 games (across all teams). Note that pitchers often play for more than one team in a season, so be sure that you are counting all stats for each player.
WITH pitcher_stats AS (
    SELECT 
        p.playerid, 
        SUM(p.SO) AS total_strikeouts, 
        SUM(s.salary) AS total_salary
    FROM pitching p
    JOIN salaries s ON p.playerid = s.playerid
    WHERE p.GS >= 10
      AND s.yearid = 2016
    GROUP BY p.playerid
)
SELECT pep.namefirst, pep.namelast, ROUND((ps.total_salary / ps.total_strikeouts)::numeric, 2) AS salary_per_strikeout
FROM pitcher_stats ps
JOIN people pep ON ps.playerid = pep.playerid
ORDER BY salary_per_strikeout ASC
LIMIT 1;

--8. Find all players who have had at least 3000 career hits. Report those players' names, total number of hits, and the year they were inducted into the hall of fame (If they were not inducted into the hall of fame, put a null in that column.) Note that a player being inducted into the hall of fame is indicated by a 'Y' in the **inducted** column of the halloffame table.
WITH ch AS (
    SELECT b.playerid, SUM(b.H) AS total_hits, pep.namefirst, pep.namelast
    FROM batting b
    JOIN people pep ON b.playerid = pep.playerid
    GROUP BY b.playerid, pep.namefirst, pep.namelast
    HAVING SUM(b.H) >= 3000
)
SELECT ch.namefirst, ch.namelast, ch.total_hits,
       CASE
           WHEN hf.inducted = 'Y' THEN hf.yearid
           ELSE NULL
       END AS yearid
FROM ch
LEFT JOIN halloffame hf ON ch.playerid = hf.playerid
ORDER BY hf.yearid;


-- 9. Find all players who had at least 1,000 hits for two different teams. Report those players' full names.


