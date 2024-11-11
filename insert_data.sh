#! /bin/bash

if [[ $1 == "test" ]]
then
  PSQL="psql --username=postgres --dbname=worldcuptest -t --no-align -c"
else
  PSQL="psql --username=freecodecamp --dbname=worldcup -t --no-align -c"
fi

# Do not change code above this line. Use the PSQL variable above to query your database.

# Step 0: Clear out the tables (if necessary)
# Ensure no duplicate or residual data is left over from previous runs.
echo "Clearing out tables..."
$PSQL "TRUNCATE TABLE games, teams CASCADE;"

# Step 1: Insert teams (skip duplicates)
# Read the CSV file once, and insert teams if they don't already exist
while IFS=, read -r year round winner opponent winner_goals opponent_goals
do
  # Skip the header line
  if [[ "$year" != "year" ]]; then
    # Insert winner if not already present
    $PSQL "INSERT INTO teams (name) VALUES ('$winner') ON CONFLICT (name) DO NOTHING;"
    # Insert opponent if not already present
    $PSQL "INSERT INTO teams (name) VALUES ('$opponent') ON CONFLICT (name) DO NOTHING;"
  fi
done < games.csv

# Step 2: Insert games
# Re-read the CSV file to insert games into the 'games' table
while IFS=, read -r year round winner opponent winner_goals opponent_goals
do
  # Skip the header line
  if [[ "$year" != "year" ]]; then
    # Get the team IDs for winner and opponent in one query, to avoid separate SELECT calls for each
    winner_id=$($PSQL "SELECT team_id FROM teams WHERE name = '$winner';")
    opponent_id=$($PSQL "SELECT team_id FROM teams WHERE name = '$opponent';")

    # Ensure both team IDs are found (otherwise skip the insertion)
    if [[ -n "$winner_id" && -n "$opponent_id" ]]; then
      # Insert the game into the 'games' table
      $PSQL "INSERT INTO games (year, round, winner_id, opponent_id, winner_goals, opponent_goals)
             VALUES ($year, '$round', $winner_id, $opponent_id, $winner_goals, $opponent_goals);"
    else
      echo "Error: Could not find team IDs for $winner and/or $opponent for the $year $round game."
    fi
  fi
done < games.csv