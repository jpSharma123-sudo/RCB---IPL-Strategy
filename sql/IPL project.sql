-- OBJECTIVE QUESTIONS
use ipl;
-- Q1. List the different dtypes of columns in table "Ball_by_Ball" (using information schema)
SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'ipl'
  AND TABLE_NAME   = 'Ball_by_Ball'
ORDER BY ORDINAL_POSITION;

-- Q2. What is the total number of runs scored in the 1st season by RCB (including extras)?
SELECT SUM(bb.Runs_Scored) AS batting_runs,
       SUM(er.Extra_Runs)  AS extra_runs,
       SUM(bb.Runs_Scored) + IFNULL(SUM(er.Extra_Runs),0) AS total_runs
FROM Ball_by_Ball bb
JOIN Matches m       ON m.Match_Id = bb.Match_Id
LEFT JOIN Extra_Runs er
       ON  er.Match_Id = bb.Match_Id AND er.Over_Id = bb.Over_Id
       AND er.Ball_Id  = bb.Ball_Id  AND er.Innings_No = bb.Innings_No
WHERE bb.Team_Batting = 2   -- Royal Challengers Bangalore
  AND m.Season_Id = (SELECT MIN(Season_Id) FROM Matches);

-- Q3. How many players were more than the age of 25 during season 2014?
SELECT COUNT(DISTINCT p.Player_Id) AS players_over_25
     FROM Player p
     JOIN Player_Match pm ON pm.Player_Id = p.Player_Id
     JOIN Matches m        ON m.Match_Id  = pm.Match_Id
     WHERE m.season_id = 7
       AND (2014 - YEAR(p.DOB)) > 25;


-- Q4. How many matches did RCB win in 2013?
SELECT COUNT(*) AS rcb_wins_2013
FROM Matches m
JOIN Season s ON s.Season_Id = m.Season_Id
WHERE s.Season_Year = 2013
  AND m.Match_Winner = 2; 
  
--   Q5. List the top 10 players according to their strike rate in the last 4 seasons
WITH wide_balls AS (
  SELECT Match_Id, Over_Id, Ball_Id, Innings_No
  FROM Extra_Runs WHERE Extra_Type_Id = 2   -- 'wides'
),
balls_faced AS (
  SELECT bb.Striker AS Player_Id, bb.Runs_Scored,
         bb.Match_Id, bb.Over_Id, bb.Ball_Id, bb.Innings_No
  FROM Ball_by_Ball bb
  LEFT JOIN wide_balls w
    ON  w.Match_Id = bb.Match_Id AND w.Over_Id = bb.Over_Id
    AND w.Ball_Id  = bb.Ball_Id  AND w.Innings_No = bb.Innings_No
  WHERE w.Match_Id IS NULL
)
SELECT p.Player_Name,
       SUM(bf.Runs_Scored) AS total_runs,
       COUNT(*) AS balls_faced,
       ROUND(SUM(bf.Runs_Scored) * 100.0 / COUNT(*),2) AS strike_rate
FROM balls_faced bf
JOIN Player p ON p.Player_Id = bf.Player_Id
GROUP BY bf.Player_Id
HAVING balls_faced >= 200
ORDER BY strike_rate DESC
LIMIT 10;

-- Q6. What are the average runs scored by each batsman, considering all the seasons?
SELECT p.Player_Name, ROUND(AVG(t.runs_per_match),2) AS avg_runs
FROM (
  SELECT bb.Striker AS Player_Id, bb.Match_Id, SUM(bb.Runs_Scored) AS runs_per_match
  FROM Ball_by_Ball bb
  GROUP BY bb.Striker, bb.Match_Id
) t
JOIN Player p ON p.Player_Id = t.Player_Id
GROUP BY t.Player_Id
ORDER BY avg_runs DESC;

-- Q7. What are the average wickets taken by each bowler, considering all the seasons?
SELECT p.Player_Name, ROUND(AVG(t.wkts),2) AS avg_wickets, COUNT(*) AS matches_bowled
FROM (
  SELECT bb.Bowler AS Player_Id, bb.Match_Id, COUNT(*) AS wkts
  FROM Wicket_Taken w
  JOIN Ball_by_Ball bb
    ON  bb.Match_Id = w.Match_Id AND bb.Over_Id = w.Over_Id
    AND bb.Ball_Id  = w.Ball_Id  AND bb.Innings_No = w.Innings_No
  WHERE w.Kind_Out <> 3   -- exclude 'run out'
  GROUP BY bb.Bowler, bb.Match_Id
) t
JOIN Player p ON p.Player_Id = t.Player_Id
GROUP BY t.Player_Id
ORDER BY avg_wickets DESC limit 10;

-- Q8. List all players who have average runs scored greater than the overall average AND have taken wickets greater than the overall average
WITH batting AS (
  SELECT t.Striker AS Player_Id, AVG(t.runs_per_match) AS avg_runs
  FROM (SELECT Striker, Match_Id, SUM(Runs_Scored) AS runs_per_match
        FROM Ball_by_Ball GROUP BY Striker, Match_Id) t
  GROUP BY t.Striker
),
bowling AS (
  SELECT t.Player_Id, AVG(t.wkts) AS avg_wkts
  FROM (
    SELECT bb.Bowler AS Player_Id, bb.Match_Id, COUNT(*) AS wkts
    FROM Wicket_Taken w
    JOIN Ball_by_Ball bb
      ON bb.Match_Id=w.Match_Id AND bb.Over_Id=w.Over_Id
     AND bb.Ball_Id=w.Ball_Id AND bb.Innings_No=w.Innings_No
    WHERE w.Kind_Out <> 3
    GROUP BY bb.Bowler, bb.Match_Id
  ) t GROUP BY t.Player_Id
)
SELECT p.Player_Name, ROUND(bat.avg_runs,2) AS avg_runs, ROUND(bowl.avg_wkts,2) AS avg_wkts
FROM batting bat
JOIN bowling bowl ON bat.Player_Id = bowl.Player_Id
JOIN Player p      ON p.Player_Id  = bat.Player_Id
WHERE bat.avg_runs > (SELECT AVG(avg_runs) FROM batting)
  AND bowl.avg_wkts > (SELECT AVG(avg_wkts) FROM bowling)
ORDER BY bat.avg_runs DESC;

-- Q9. Create an rcb_record table showing wins and losses of RCB at each venue
CREATE TABLE rcb_record AS
SELECT v.Venue_Name,
       SUM(CASE WHEN m.Match_Winner = 2 THEN 1 ELSE 0 END) AS Wins,
       SUM(CASE WHEN (m.Team_1 = 2 OR m.Team_2 = 2)
                 AND m.Match_Winner IS NOT NULL AND m.Match_Winner <> 2
                THEN 1 ELSE 0 END) AS Losses,
       COUNT(*) AS Total_Matches
FROM Matches m
JOIN Venue v ON v.Venue_Id = m.Venue_Id
WHERE m.Team_1 = 2 OR m.Team_2 = 2
GROUP BY v.Venue_Name
ORDER BY Wins DESC;
select * from rcb_record;

-- Q10. What is the impact of bowling style on wickets taken?
SELECT bs.Bowling_skill AS bowling_style, COUNT(*) AS wickets_taken
FROM Wicket_Taken w
JOIN Ball_by_Ball bb
  ON bb.Match_Id=w.Match_Id AND bb.Over_Id=w.Over_Id
 AND bb.Ball_Id=w.Ball_Id AND bb.Innings_No=w.Innings_No
JOIN Player p        ON p.Player_Id = bb.Bowler
JOIN Bowling_Style bs ON bs.Bowling_Id = p.Bowling_skill
WHERE w.Kind_Out <> 3
GROUP BY bs.Bowling_skill
ORDER BY wickets_taken DESC;

-- Q11. Write a query to flag whether a team's performance (runs scored & wickets taken) improved vs. the previous season
WITH team_season AS (
  SELECT m.Season_Id, s.Season_Year, bb.Team_Batting AS Team_Id,
         SUM(bb.Runs_Scored) AS Runs,
         (SELECT COUNT(*) FROM Wicket_Taken w
          JOIN Ball_by_Ball b2
            ON b2.Match_Id=w.Match_Id AND b2.Over_Id=w.Over_Id
           AND b2.Ball_Id=w.Ball_Id AND b2.Innings_No=w.Innings_No
          WHERE b2.Team_Bowling = bb.Team_Batting
            AND w.Kind_Out <> 3
            AND b2.Match_Id IN (SELECT Match_Id FROM Matches WHERE Season_Id = m.Season_Id)
         ) AS Wickets
  FROM Ball_by_Ball bb
  JOIN Matches m ON m.Match_Id = bb.Match_Id
  JOIN Season s  ON s.Season_Id = m.Season_Id
  GROUP BY m.Season_Id, bb.Team_Batting
)
SELECT t.Team_Id, ts.Season_Year, ts.Runs, ts.Wickets,
       CASE
         WHEN LAG(ts.Runs) OVER (PARTITION BY ts.Team_Id ORDER BY ts.Season_Year) IS NULL
              THEN 'No prior season'
         WHEN ts.Runs    > LAG(ts.Runs)    OVER (PARTITION BY ts.Team_Id ORDER BY ts.Season_Year)
          AND ts.Wickets > LAG(ts.Wickets) OVER (PARTITION BY ts.Team_Id ORDER BY ts.Season_Year)
              THEN 'Improved'
         WHEN ts.Runs    < LAG(ts.Runs)    OVER (PARTITION BY ts.Team_Id ORDER BY ts.Season_Year)
          AND ts.Wickets < LAG(ts.Wickets) OVER (PARTITION BY ts.Team_Id ORDER BY ts.Season_Year)
              THEN 'Declined'
         ELSE 'Mixed'
       END AS Performance_Status
FROM team_season ts
JOIN Team t ON t.Team_Id = ts.Team_Id
WHERE ts.Team_Id = 2   -- RCB example
ORDER BY ts.Season_Year;

-- Q13. Find the average wickets taken by each bowler at each venue; rank bowlers within each venue by that average
WITH bowler_match_wkts AS (
  SELECT bb.Bowler AS Player_Id, bb.Match_Id, m.Venue_Id, COUNT(*) AS wkts
  FROM Wicket_Taken w
  JOIN Ball_by_Ball bb
    ON bb.Match_Id=w.Match_Id AND bb.Over_Id=w.Over_Id
   AND bb.Ball_Id=w.Ball_Id AND bb.Innings_No=w.Innings_No
  JOIN Matches m ON m.Match_Id = bb.Match_Id
  WHERE w.Kind_Out <> 3
  GROUP BY bb.Bowler, bb.Match_Id
),
venue_avg AS (
  SELECT Player_Id, Venue_Id, AVG(wkts) AS avg_wkts
  FROM bowler_match_wkts
  GROUP BY Player_Id, Venue_Id
)
SELECT v.Venue_Name, p.Player_Name, ROUND(va.avg_wkts,2) AS avg_wkts,
       RANK() OVER (PARTITION BY va.Venue_Id ORDER BY va.avg_wkts DESC) AS bowler_rank
FROM venue_avg va
JOIN Player p ON p.Player_Id = va.Player_Id
JOIN Venue v  ON v.Venue_Id  = va.Venue_Id
ORDER BY v.Venue_Name, bowler_rank;

-- Q14. Which players have consistently performed well in past seasons?
SELECT p.Player_Name,
       COUNT(*)                    AS seasons_played,
       ROUND(AVG(sr.runs),1)       AS avg_runs_per_season,
       MIN(sr.runs)                AS worst_season_runs
FROM (
  SELECT bb.Striker AS Player_Id, m.Season_Id, SUM(bb.Runs_Scored) AS runs
  FROM Ball_by_Ball bb JOIN Matches m ON m.Match_Id = bb.Match_Id
  GROUP BY bb.Striker, m.Season_Id
) sr
JOIN Player p ON p.Player_Id = sr.Player_Id
GROUP BY sr.Player_Id
HAVING seasons_played = 4        -- played in all 4 available seasons
ORDER BY avg_runs_per_season DESC
LIMIT 10;

-- Q15. Are there players whose performance is more suited to specific venues or conditions?
SELECT p.Player_Name, v.Venue_Name,
       ROUND(AVG(runs_per_match),1) AS avg_runs_at_venue,
       COUNT(*) AS innings_at_venue
FROM (
  SELECT bb.Striker AS Player_Id, bb.Match_Id, m.Venue_Id, SUM(bb.Runs_Scored) AS runs_per_match
  FROM Ball_by_Ball bb JOIN Matches m ON m.Match_Id = bb.Match_Id
  GROUP BY bb.Striker, bb.Match_Id
) t
JOIN Player p ON p.Player_Id = t.Player_Id
JOIN Venue v  ON v.Venue_Id  = t.Venue_Id
GROUP BY t.Player_Id, t.Venue_Id
HAVING innings_at_venue >= 3
ORDER BY avg_runs_at_venue DESC
LIMIT 10;

-- SUBJECTIVE QUESTIONS

-- Q1. How does the toss decision affect the result of the match, and is the impact limited to specific venues?
SELECT td.Toss_Name,
       SUM(CASE WHEN m.Toss_Winner = m.Match_Winner THEN 1 ELSE 0 END) AS toss_winner_won,
       COUNT(*) AS total_matches,
       ROUND(SUM(CASE WHEN m.Toss_Winner = m.Match_Winner THEN 1 ELSE 0 END)*100.0/COUNT(*),2) AS win_pct
FROM Matches m
JOIN Toss_Decision td ON td.Toss_Id = m.Toss_Decide
WHERE m.Match_Winner IS NOT NULL
GROUP BY td.Toss_Name;

-- Q2. Suggest some players who would be best fit for the team
WITH batting AS (
	SELECT t.Striker AS Player_Id, AVG(t.runs_per_match) AS avg_runs
       FROM (SELECT Striker, Match_Id, SUM(Runs_Scored) AS runs_per_match
             FROM Ball_by_Ball GROUP BY Striker, Match_Id) t
       GROUP BY t.Striker
     ),
     bowling AS (
       SELECT t.Player_Id, AVG(t.wkts) AS avg_wkts
       FROM (
         SELECT bb.Bowler AS Player_Id, bb.Match_Id, COUNT(*) AS wkts
         FROM Wicket_Taken w
         JOIN Ball_by_Ball bb ON bb.Match_Id=w.Match_Id AND bb.Over_Id=w.Over_Id
          AND bb.Ball_Id=w.Ball_Id AND bb.Innings_No=w.Innings_No
         WHERE w.Kind_Out <> 3
         GROUP BY bb.Bowler, bb.Match_Id
       ) t GROUP BY t.Player_Id
     ),
     mom AS (
       SELECT Man_of_the_Match AS Player_Id, COUNT(*) AS awards
       FROM Matches GROUP BY Man_of_the_Match
     )
     SELECT p.Player_Name,
            ROUND(bat.avg_runs,1)               AS avg_runs,
            ROUND(IFNULL(bowl.avg_wkts,0),2)    AS avg_wkts,
           IFNULL(mom.awards,0)                AS mom_awards,
            ROUND(bat.avg_runs + IFNULL(bowl.avg_wkts,0)*15
                  + IFNULL(mom.awards,0)*3, 1)  AS impact_score
     FROM batting bat
     JOIN Player p       ON p.Player_Id = bat.Player_Id
     LEFT JOIN bowling bowl ON bowl.Player_Id = bat.Player_Id
     LEFT JOIN mom          ON mom.Player_Id  = bat.Player_Id
     ORDER BY impact_score DESC
     LIMIT 10;

-- Q3. What parameters should be focused on while selecting players?
 SELECT p.Player_Name,
            ROUND(AVG(CASE WHEN m.Season_Id = 9 THEN t.runs_per_match END), 1) AS avg_runs_2016,
            ROUND(AVG(t.runs_per_match), 1)                                    AS avg_runs_career
     FROM (
       SELECT bb.Striker AS Player_Id, bb.Match_Id, SUM(bb.Runs_Scored) AS runs_per_match
       FROM Ball_by_Ball bb GROUP BY bb.Striker, bb.Match_Id
     ) t
     JOIN Matches m ON m.Match_Id = t.Match_Id
     JOIN Player p  ON p.Player_Id = t.Player_Id
     GROUP BY t.Player_Id
     HAVING avg_runs_2016 IS NOT NULL
     ORDER BY avg_runs_2016 DESC
     LIMIT 10;

-- Q4. Which players offer versatility in their skills and can contribute effectively with both bat and ball
WITH batting AS (
       SELECT t.Striker AS Player_Id, AVG(t.runs_per_match) AS avg_runs
       FROM (SELECT Striker, Match_Id, SUM(Runs_Scored) AS runs_per_match
             FROM Ball_by_Ball GROUP BY Striker, Match_Id) t
       GROUP BY t.Striker
     ),
     bowling AS (
       SELECT t.Player_Id, AVG(t.wkts) AS avg_wkts
       FROM (
         SELECT bb.Bowler AS Player_Id, bb.Match_Id, COUNT(*) AS wkts
         FROM Wicket_Taken w
         JOIN Ball_by_Ball bb
           ON bb.Match_Id=w.Match_Id AND bb.Over_Id=w.Over_Id
          AND bb.Ball_Id=w.Ball_Id AND bb.Innings_No=w.Innings_No
         WHERE w.Kind_Out <> 3
         GROUP BY bb.Bowler, bb.Match_Id
       ) t GROUP BY t.Player_Id
     )
     SELECT p.Player_Name, ROUND(bat.avg_runs,2) AS avg_runs, ROUND(bowl.avg_wkts,2) AS avg_wkts
     FROM batting bat
     JOIN bowling bowl ON bat.Player_Id = bowl.Player_Id
     JOIN Player p      ON p.Player_Id  = bat.Player_Id
     WHERE bat.avg_runs > (SELECT AVG(avg_runs) FROM batting)
       AND bowl.avg_wkts > (SELECT AVG(avg_wkts) FROM bowling)
     ORDER BY bat.avg_runs DESC;
     
-- 	Q5. Are there players whose presence positively influences the morale and performance of the team?
 SELECT p.Player_Name, COUNT(*) AS man_of_match_awards
     FROM Matches m
     JOIN Player p ON p.Player_Id = m.Man_of_the_Match
     GROUP BY p.Player_Name
     ORDER BY man_of_match_awards DESC
     LIMIT 10;

-- Q6. What would you suggest to RCB before going to the mega auction?
 WITH season_totals AS (
       -- pulled from the RCB season-wise runs/wickets query (see Subjective Q9)
       SELECT 2013 AS Season, 2460 AS Runs, 96 AS Wickets
       UNION ALL SELECT 2014, 1992, 67
       UNION ALL SELECT 2015, 2190, 92
       UNION ALL SELECT 2016, 2859, 90
     )
     SELECT Season,
            ROUND(Runs    * 100.0 / FIRST_VALUE(Runs)    OVER (ORDER BY Season), 0) AS Batting_Runs_Index,
            ROUND(Wickets * 100.0 / FIRST_VALUE(Wickets) OVER (ORDER BY Season), 0) AS Bowling_Wkts_Index
     FROM season_totals
     ORDER BY Season;

-- Q7. What factors contribute to high-scoring matches, and what is the impact on viewership and team strategy?
SELECT v.Venue_Name, ROUND(AVG(inn.runs),1) AS avg_innings_score, COUNT(*) AS innings_played
     FROM (
       SELECT bb.Match_Id, bb.Innings_No, m.Venue_Id, SUM(bb.Runs_Scored) AS runs
       FROM Ball_by_Ball bb JOIN Matches m ON m.Match_Id = bb.Match_Id
       WHERE bb.Innings_No IN (1,2)
       GROUP BY bb.Match_Id, bb.Innings_No
     ) inn
     JOIN Venue v ON v.Venue_Id = inn.Venue_Id
     GROUP BY v.Venue_Name
     HAVING innings_played >= 6
     ORDER BY avg_innings_score DESC
     LIMIT 5;
	
-- Q8. Analyze the impact of home-ground advantage on team performance and identify strategies to maximize this advantage for RCB
SELECT
       CASE WHEN v.Venue_Name = 'M Chinnaswamy Stadium' THEN 'Home' ELSE 'Away' END AS Location,
       COUNT(*) AS Matches,
       SUM(CASE WHEN m.Match_Winner = 2 THEN 1 ELSE 0 END) AS Wins,
       ROUND(SUM(CASE WHEN m.Match_Winner = 2 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS Win_Pct
     FROM Matches m
     JOIN Venue v ON v.Venue_Id = m.Venue_Id
     WHERE m.Team_1 = 2 OR m.Team_2 = 2
     GROUP BY Location;

-- Q9. Come up with a visual and analytical analysis of RCB's past season's performance and potential reasons for them not winning a trophy
SELECT s.Season_Year AS Season, ts.Runs AS Runs_Scored, ts.Wickets AS Wickets_Taken
     FROM (
       SELECT m.Season_Id, bb.Team_Batting AS Team_Id, SUM(bb.Runs_Scored) AS Runs,
              (SELECT COUNT(*) FROM Wicket_Taken w
               JOIN Ball_by_Ball b2
                 ON b2.Match_Id=w.Match_Id AND b2.Over_Id=w.Over_Id
                AND b2.Ball_Id=w.Ball_Id AND b2.Innings_No=w.Innings_No
               WHERE b2.Team_Bowling = bb.Team_Batting AND w.Kind_Out <> 3
                 AND b2.Match_Id IN (SELECT Match_Id FROM Matches WHERE Season_Id = m.Season_Id)
              ) AS Wickets
       FROM Ball_by_Ball bb JOIN Matches m ON m.Match_Id = bb.Match_Id
       WHERE bb.Team_Batting = 2
       GROUP BY m.Season_Id
     ) ts
     JOIN Season s ON s.Season_Id = ts.Season_Id
     ORDER BY s.Season_Year;

-- Q11. In the Match table, correct misspelled "Delhi_Capitals" to "Delhi_Daredevils"
UPDATE Team
     SET Team_Name = 'Delhi Daredevils'
     WHERE Team_Name = 'Delhi_Capitals';
