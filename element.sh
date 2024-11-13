#!/bin/bash

# Set up the PSQL command
PSQL="psql --username=freecodecamp --dbname=periodic_table -t --no-align -c"

# Check if an argument is provided
if [ -z "$1" ]; then
  echo "Please provide an element as an argument."
  exit 0
fi

# Handle the case where the input is an atomic number (integer) or a symbol/name (string)
if [[ "$1" =~ ^[0-9]+$ ]]; then
  # If it's a number, treat it as an atomic number
  QUERY="SELECT e.atomic_number, e.symbol, e.name, p.type_id, p.atomic_mass, p.melting_point_celsius, p.boiling_point_celsius
         FROM elements e
         JOIN properties p ON e.atomic_number = p.atomic_number
         WHERE e.atomic_number = $1;"
else
  # Otherwise, treat it as a symbol or name (case insensitive comparison)
  QUERY="SELECT e.atomic_number, e.symbol, e.name, p.type_id, p.atomic_mass, p.melting_point_celsius, p.boiling_point_celsius
         FROM elements e
         JOIN properties p ON e.atomic_number = p.atomic_number
         WHERE UPPER(e.symbol) = UPPER('$1') OR UPPER(e.name) = UPPER('$1');"
fi

# Execute the query
ELEMENT_INFO=$($PSQL "$QUERY")

# Check if element was found
if [ -z "$ELEMENT_INFO" ]; then
  echo "I could not find that element in the database."
  exit 0
fi

# Parse the result
IFS="|" read -r ATOMIC_NUMBER SYMBOL NAME TYPE_ID ATOMIC_MASS MELTING_POINT BOILING_POINT <<< "$ELEMENT_INFO"

# Define the element types
case $TYPE_ID in
  1) TYPE="nonmetal" ;;
  2) TYPE="metal" ;;
  3) TYPE="metalloid" ;;
  *) TYPE="unknown" ;;
esac

# Format the output
echo "The element with atomic number $ATOMIC_NUMBER is $NAME ($SYMBOL). It's a $TYPE, with a mass of $ATOMIC_MASS amu. $NAME has a melting point of $MELTING_POINT celsius and a boiling point of $BOILING_POINT celsius."
