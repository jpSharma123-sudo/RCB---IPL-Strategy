# RCB IPL Data Dictionary

## 📌 Overview

This document provides an overview of the tables and key fields
used in the RCB IPL performance analysis.

The dataset is used to analyze team performance, player performance,
match outcomes, venues, bowling styles and other factors relevant
to the 2017 Mega Auction strategy.

---

## 🗂️ Database Tables

| Table | Description |
|---|---|
| Match | Contains match-level information |
| Ball_by_Ball | Contains delivery-level information |
| Player | Contains player-related information |
| Extra_Runs | Contains extra-run information |

---

## 🏏 Match Table

| Column | Description |
|---|---|
| Match_Id | Unique identifier for each match |
| Season | IPL season |
| Venue | Venue where the match was played |
| Toss_Decision | Decision taken after winning the toss |
| Winner | Team that won the match |
| Opponent_Team | Opposing team |

---

## 🏏 Ball_by_Ball Table

| Column | Description |
|---|---|
| Match_Id | Unique match identifier |
| Inning_Id | Identifier for the innings |
| Over_Id | Over number |
| Ball_Id | Ball number |
| Batsman | Batsman involved in the delivery |
| Bowler | Bowler involved in the delivery |
| Runs | Runs scored from the delivery |
| Wickets | Wicket-related information |

---

## 👤 Player Table

| Column | Description |
|---|---|
| Player_Id | Unique player identifier |
| Player_Name | Name of the player |
| Age | Player age |
| Gender | Player gender |
| Bowling_Style | Player's bowling style |

---

## ➕ Extra_Runs Table

| Column | Description |
|---|---|
| Match_Id | Unique match identifier |
| Extra_Runs | Runs scored through extras |
| Extra_Type | Type of extra |

---

## 🔗 Key Relationships

The analysis uses relationships between match-level,
player-level and ball-by-ball data to derive team and
player performance metrics.

Typical relationships include:

- Match → Ball_by_Ball
- Player → Ball_by_Ball
- Match → Extra_Runs

---

## 📊 Analytical Metrics

The project derives metrics such as:

- Total Runs
- Batting Average
- Strike Rate
- Total Wickets
- Average Wickets
- Win Percentage
- Venue-wise Performance
- Toss Impact
- Player Consistency
- All-round Performance

---

## 🎯 Business Application

The data model supports the evaluation of players and team
performance to provide data-driven recommendations for RCB's
2017 Mega Player Auction.
