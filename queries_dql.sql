-- 1.Display all customers who have at least one confirmed booking, including their personal details and their booking information.
SELECT DISTINCT
    Customer.id AS customer_id,
    Customer.first_name,
    Customer.second_name,
    Customer.email,
    Booking.id AS booking_id,
    Booking.guests_count,
    Booking.status AS booking_status,
    Booking.total_price,
    Booking.rooms_total
FROM Customer
JOIN Booking ON (Booking.customer_id = Customer.id AND Booking.status = 'confirmed');



-- 2.List customers who do not have any confirmed bookings.
SELECT DISTINCT * FROM Customer c
WHERE NOT EXISTS(
    SELECT customer_id
    FROM Booking b
    WHERE c.id = b.customer_id
    AND b.status = 'confirmed');



-- 3.List rooms that have 'single' bed type only.
-- rooms related to 'single' bed type, we did that to exclude rooms with no beds
SELECT DISTINCT *
FROM Room R
WHERE EXISTS (
    SELECT 1
    FROM beds_in_room B
    WHERE (R.hotel_id, R.number) = (B.hotel_id, B.room_number)
    AND B.bed_type_name = 'single'
)

EXCEPT
-- except rooms that has any other bed type
SELECT DISTINCT *
FROM Room R
WHERE EXISTS (
    SELECT 1
    FROM beds_in_room B
    WHERE (R.hotel_id, R.number) = (B.hotel_id, B.room_number)
      AND B.bed_type_name != 'single'
);



-- 4.List bookings for which all extra services defined by the hotel were used in that booking.
SELECT * FROM Booking B
WHERE NOT EXISTS (
        SELECT hotel_id, name
        FROM Extra_service E
        WHERE  E.hotel_id = (SELECT hotel_id FROM Booking_item T
                            WHERE B.id = T.booking_id
                            LIMIT 1)
        --two possipilities:
        --1- there is a booking item and it will work normally in this case finding the hotel_id
        --2- there is no any booking item and it will will not return any set
        EXCEPT

        SELECT hotel_id, service_name
        FROM Service_usage S
        WHERE S.hotel_id = (SELECT hotel_id FROM Booking_item T
                            WHERE B.id = T.booking_id
                            LIMIT 1)
            AND S.booking_id = B.id
)
AND rooms_total > 0;



-- 5.List every booking together with the customer’s details and payment details.
SELECT DISTINCT
    b.booking_id,
    b.rooms_total,
    b.guests_count,
    b.price_plan_id,
    b.total_price,
    b.status AS booking_status,

    c.id AS customer_id,
    c.first_name,
    c.second_name,
    c.email,
    c.phone,

    p.id AS payment_id,
    p.created_date,
    p.amount
FROM (
    SELECT id AS booking_id, *
    FROM Booking
) b
JOIN Customer c
    ON c.id = b.customer_id
LEFT JOIN Payment p
    USING (booking_id);



-- 6.List all rooms with assigned beds, including rooms that have no beds assigned and bed assignments that are not linked to any room
SELECT r.hotel_id,
        r.number AS room_number,
        r.category AS room_category,
        r.price_per_night AS room_price_per_night,

        bir.quantity AS bed_quantity,

        bt.name AS bed_type,
        bt.bed_capacity AS bed_capacity
FROM Room r
    FULL OUTER JOIN Beds_in_room bir
            ON (r.hotel_id, r.number) = (bir.hotel_id, bir.room_number)
    FULL OUTER JOIN Bed_type bt
            ON bir.bed_type_name = bt.name;



-- 7.Show the total revenue each hotel earned from confirmed bookings.Find all bookings that have not been paid yet (status = not cnfirmed).
SELECT
    (
        SELECT COALESCE(SUM(total_price), 0)
        FROM Booking b
        WHERE status = 'confirmed'
          AND h.id = (
                SELECT hotel_id
                FROM Booking_item bi
                WHERE b.id = bi.booking_id
                LIMIT 1
          )
    ) AS total_revenue,
    *
FROM Hotel h;



-- 8.List all rooms that are either currently unavailable(not free) or have at least one bed of type 'single' assigned using UNION.
SELECT *
FROM Room r1
WHERE EXISTS(SELECT 1 FROM Booking_item bi
                WHERE (r1.hotel_id, r1.number) = (bi.hotel_id, bi.room_number)
                AND bi.check_in <= CURRENT_DATE
                AND CURRENT_DATE < bi.check_out)

UNION

SELECT *
FROM Room r2
WHERE EXISTS(SELECT 1 FROM beds_in_room bir
            WHERE (r2.hotel_id, r2.number) = (bir.hotel_id, bir.room_number)
            AND bir.bed_type_name = 'single');



-- 9.List all hotels that have deluxe rooms and offer the extra service' airport_transfer' using IINTERSECT.
SELECT * FROM Hotel
WHERE id IN(
        SELECT DISTINCT r.hotel_id
        FROM Room r
        WHERE r.category = 'deluxe'

        INTERSECT

        SELECT DISTINCT es.hotel_id
        FROM Extra_service es
        WHERE es.name = 'airport_transfer'
    );



-- 10.List hotel IDs, countries, cities and names whose average room price for double rooms is less than or equal to 150, ordered in ascending order.
SELECT
    h.id AS hotel_id,
    h.name AS hotel_name,
    h.country AS hotel_country,
    h.city AS hotel_city,
    AVG(r.price_per_night) AS avg_room_price
FROM Room r
JOIN Hotel h ON h.id = r.hotel_id
WHERE r.category = 'double'
GROUP BY h.id, h.name
HAVING AVG(r.price_per_night) <= 150
ORDER BY avg_room_price ASC;



-- 11.List all customers who have any booking record.
SELECT c.id, c.first_name, c.second_name
FROM Customer c
WHERE EXISTS (
    SELECT 1
    FROM Booking b
    WHERE b.customer_id = c.id
);



SELECT c.id, c.first_name, c.second_name
FROM Customer c
WHERE c.id IN (
    SELECT b.customer_id
    FROM Booking b
);



SELECT c.id, c.first_name, c.second_name
FROM Customer c

EXCEPT

SELECT c.id, c.first_name, c.second_name
FROM Customer c
WHERE c.id NOT IN (
    SELECT b.customer_id
    FROM Booking b
);



-- 12.Create a view that shows all rooms that are currently available(free), meaning they are not booked at the present time.
CREATE OR REPLACE VIEW list_currently_free_rooms AS (
    SELECT *
    FROM Room r
    WHERE NOT EXISTS(SELECT 1 FROM Booking_item bi
                WHERE (r.hotel_id, r.number) = (bi.hotel_id, bi.room_number)
                AND bi.check_in <= CURRENT_DATE
                AND CURRENT_DATE < bi.check_out)
);



-- 13.List all currently available deluxe rooms whose total area is less than or equal to 40 square meters.
SELECT *
FROM list_currently_free_rooms
WHERE category = 'deluxe'
AND total_area <= 40;



-- 14.Insert a free extra service called welcome_drink for hotels with IDs 1 and 3.
INSERT INTO Extra_service (name, hotel_id, price, description)
SELECT
    'welcome_drink',
    h.id,
    0,
    'Free welcome drink'
FROM Hotel h
WHERE h.id in (1 , 3);



-- 15.Update the guest count to 6 for all bookings of customer with ID 2 and not confirmed.
UPDATE Booking
SET guests_count = 5
WHERE id IN (
    SELECT id
    FROM Booking
    WHERE customer_id = 2
    AND status = 'not confirmed');



-- 16.Delete all payments whose status is marked as failed.
DELETE FROM Payment
WHERE status_id IN (
    SELECT id
    FROM Payment_status
    WHERE status = 'failed'
);



-- 17.Show the maximum guest capacity of each room based on the number and type of beds in that room.
SELECT SUM(bir.quantity*( SELECT bed_capacity FROM bed_type bt
                            WHERE bir.bed_type_name = bt.name))
        AS maximum_room_capacity,
        bir.hotel_id,
        bir.room_number
FROM beds_in_room bir
GROUP BY (bir.hotel_id,bir.room_number)
ORDER BY (bir.hotel_id, bir.room_number) ASC;



-- 18.List the names and details of all extra services provided by hotel with ID 1.
SELECT DISTINCT *
FROM Extra_service
WHERE hotel_id = 1;



-- 19.Show all customers who booked room 101 in hotel with ID 2 during the date range from 2025-12-01 to 2026-01-20. (any overlapping counts)
SELECT DISTINCT *
FROM Customer c
WHERE EXISTS (
    SELECT 1
    FROM Booking_item bt
    WHERE bt.booking_id IN (
            SELECT b.id
            FROM Booking b
            WHERE b.customer_id = c.id
    )
      AND bt.hotel_id = 2
      AND bt.room_number = '101'
      AND bt.check_in < DATE '2026-01-20'
      AND bt.check_out > DATE '2025-12-01'
);



-- 20.Show all bookings that included at least one extra service.
SELECT *
FROM Booking b
WHERE EXISTS (
    SELECT 1
    FROM Service_usage su
    WHERE su.booking_id = b.id
);



-- 21.List all rooms that were not booked at all by any confirmed booking.
SELECT *
FROM Room r
WHERE NOT EXISTS (
    SELECT 1
    FROM Booking_item bi
    JOIN Booking b
        ON b.id = bi.booking_id
    WHERE (bi.hotel_id, bi.room_number) = (r.hotel_id, r.number)
      AND b.status = 'confirmed'
);



-- 22.List all customers who have never made any payment.
SELECT *
FROM Customer c
WHERE NOT EXISTS (SELECT customer_id
                FROM Booking b
                JOIN Payment p
                ON b.id = p.booking_id
                AND b.customer_id = c.id
);



-- 23.List all bookings together with their price plan details, where the price plan used is seasonal.
SELECT DISTINCT *
FROM Booking b
JOIN Price_plan p ON p.type = b.price_plan_id
WHERE p.type = 'seasonal';



-- 24.List each hotel and the total number of confirmed bookings made for that hotel.
SELECT
    h.id AS hotel_id,
    COUNT(DISTINCT b.id) AS confirmed_bookings_count
FROM Hotel h
LEFT JOIN Booking_item bi
    ON bi.hotel_id = h.id
LEFT JOIN Booking b
    ON b.id = bi.booking_id
   AND b.status = 'confirmed'
GROUP BY h.id;

