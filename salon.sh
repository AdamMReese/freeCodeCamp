#!/bin/bash
# Program that sets up a scheduler for salon appointments

# Database connection details
DB_USER="freecodecamp"
DB_NAME="salon"

# execute a SQL query and return the result
run_query() {
    psql --username=$DB_USER --dbname=$DB_NAME -t -A -c "$1"
}

# check if a table exists
table_exists() {
    TABLE=$1
    result=$(run_query "SELECT to_regclass('$TABLE');")
    if [[ $result == "null" ]]; then
        return 1  # Table doesn't exist
    else
        return 0  # Table exists
    fi
}

# create the services table if it doesn't exist
create_services_table() {
    if ! table_exists "services"; then
        echo "Creating services table..."
        run_query "CREATE TABLE services (
            service_id SERIAL PRIMARY KEY,
            name VARCHAR(100) NOT NULL
        );"
        # Insert sample services
        run_query "INSERT INTO services (name) VALUES 
            ('Cut'), 
            ('Shave'), 
            ('Facial');"
    else
        echo "Services table already exists."
    fi
}

# create the customers table if it doesn't exist
create_customers_table() {
    if ! table_exists "customers"; then
        echo "Creating customers table..."
        run_query "CREATE TABLE customers (
            customer_id SERIAL PRIMARY KEY,
            phone VARCHAR(20) UNIQUE NOT NULL,
            name VARCHAR(100) NOT NULL
        );"
    else
        echo "Customers table already exists."
    fi
}

# create the appointments table if it doesn't exist
create_appointments_table() {
    if ! table_exists "appointments"; then
        echo "Creating appointments table..."
        run_query "CREATE TABLE appointments (
            appointment_id SERIAL PRIMARY KEY,
            customer_id INT NOT NULL,
            service_id INT NOT NULL,
            time VARCHAR(20) NOT NULL,
            FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
            FOREIGN KEY (service_id) REFERENCES services(service_id)
        );"
    else
        echo "Appointments table already exists."
    fi
}

# Initialize the database (create tables if they don't exist)
initialize_database() {
    create_services_table
    create_customers_table
    create_appointments_table
}

# list available services
list_services() {
    SERVICES=$(run_query "SELECT service_id, name FROM services ORDER BY service_id;")
    echo "$SERVICES" | while IFS="|" read -r SERVICE_ID SERVICE_NAME; do
        echo "$SERVICE_ID) $SERVICE_NAME"
    done
}

# check if the customer exists
customer_exists() {
    run_query "SELECT customer_id FROM customers WHERE phone = '$1';"
}

# insert a new customer
insert_customer() {
    run_query "INSERT INTO customers (phone, name) VALUES ('$1', '$2');"
}

# insert an appointment
insert_appointment() {
    run_query "INSERT INTO appointments (customer_id, service_id, time) VALUES ($1, $2, '$3');"
}

# Show the list of services
echo -e "\n~~~~ Welcome to Adam's Beauty Salon!~~~~\n"
echo "Available services:"
list_services

# Prompt for service ID
while true; do
    echo "Please enter the service ID:"
    read SERVICE_ID_SELECTED

    # Validate service_id exists
    SERVICE_EXISTS=$(run_query "SELECT name FROM services WHERE service_id = $SERVICE_ID_SELECTED;")
    if [[ -n "$SERVICE_EXISTS" ]]; then
        break
    else
        echo "Invalid service ID. Please select a valid service."
        list_services
    fi
done

# Prompt for phone number
echo "Please enter your phone number:"
read CUSTOMER_PHONE

# Check if customer exists
CUSTOMER_ID=$(customer_exists "$CUSTOMER_PHONE")

if [[ -z "$CUSTOMER_ID" ]]; then
    # If customer doesn't exist, ask for name and insert the customer
    echo "We don't have a record for this phone number. Please enter your name:"
    read CUSTOMER_NAME
    insert_customer "$CUSTOMER_PHONE" "$CUSTOMER_NAME"
    # Fetch customer_id after insertion
    CUSTOMER_ID=$(run_query "SELECT customer_id FROM customers WHERE phone = '$CUSTOMER_PHONE';")
else
    # If customer exists, fetch their customer_id
    CUSTOMER_NAME=$(run_query "SELECT name FROM customers WHERE customer_id = $CUSTOMER_ID;")
fi

# Prompt for appointment time
echo "Please enter the appointment time (e.g., 10:30, 11am, etc.):"
read SERVICE_TIME

# Insert the appointment
insert_appointment "$CUSTOMER_ID" "$SERVICE_ID_SELECTED" "$SERVICE_TIME"

# Output confirmation
SERVICE_NAME=$(run_query "SELECT name FROM services WHERE service_id = $SERVICE_ID_SELECTED;")
echo "I have put you down for a $SERVICE_NAME at $SERVICE_TIME, $CUSTOMER_NAME."
