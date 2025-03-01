-- LAHMAN BASEBALL DATABASE EXERCISE --

-- 1. Find all players in the database who played at Vanderbilt University. Create a list showing each player's first and last names as well as the total salary they earned in the major leagues. Sort this list in descending order by the total salary earned. Which Vanderbilt player earned the most money in the majors?
WITH s AS (
	SELECT schoolid
	FROM schools
	WHERE schoolid = 'vandy'
),
cp AS (
	SELECT schoolid, playerid
	FROM collegeplaying
),
sal AS(
	SELECT playerid, salary
	FROM salaries
)
SELECT 
	p.namefirst,
	p.namelast, 
	sal.salary
FROM people AS p
INNER JOIN cp
ON p.playerid = cp.playerid 
INNER JOIN s
ON cp.schoolid = s.schoolid
INNER JOIN sal
ON sal.playerid = p.playerid
GROUP BY p.playerid, p.namefirst, p.namelast, s.schoolid, cp.schoolid, cp.playerid, sal.playerid, sal.salary
ORDER BY sal.salary DESC
LIMIT 1;

-- 2.Using the fielding table, group players into three groups based on their position: label players with position OF as "Outfield", those with position "SS", "1B", "2B", and "3B" as "Infield", and those with position "P" or "C" as "Battery". Determine the number of putouts made by each of these three groups in 2016.
SELECT SUM(po) AS total_putouts, yearid,
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

SELECT upper, lower, ROUND(AVG(so), 2) AS avg_hr_per_game, ROUND(AVG(hr), 2) AS avg_hr_per_game
FROM decades
LEFT JOIN strikeouts
	ON	yearid >= lower
	AND yearid < upper
GROUP BY upper, lower;

-- 4. Find the player who had the most success stealing bases in 2016, where __success__ is measured as the percentage of stolen base attempts which are successful. (A stolen base attempt results either in a stolen base or being caught stealing.) Consider only players who attempted _at least_ 20 stolen bases. Report the players' names, number of stolen bases, number of attempts, and stolen base percentage.
