# Hotel Booking Database System

This project is a relational database system designed to manage bookings for multiple hotels.
It was created as part of a university database course and focuses on proper database design and SQL implementation.

## Features
- Support for managing multiple hotels with location details and star ratings
- Room management per hotel, including room category, price per night, area, and descriptions
- Bed configuration system with different bed types and capacities per room
- Customer management with unique email and phone validation
- Flexible price plans applied to bookings
- Booking system with support for multiple rooms per booking
- Automatic validation of booking dates, nights, and check-in/check-out consistency
- Tracking of booking status, total price, and total number of rooms
- Payment management with separate payment methods and payment statuses
- Support for multiple payment states such as pending, succeed, failed, and refunded
- Extra services per hotel with pricing and optional usage limits per booking
- Strong data integrity using primary keys, foreign keys, and CHECK constraints


## Technologies
- PostgreSQL (server)
- SQL (DDL & DML)

## Project Structure
- `schema_ddl.sql` – database schema (tables, constraints, triggers, functions)
- `data_dml.sql` – sample data for testing

## Notes
All data is for demonstration purposes only.
This is a practice project. Business rules and design choices are based on my own assumptions and may differ from real systems.
