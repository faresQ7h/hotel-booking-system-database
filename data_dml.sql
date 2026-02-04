INSERT INTO payment_method(method) VALUES
                                        ('credit_card'),
                                        ('debit_card'),
                                        ('cash'),
                                        ('paypal'),
                                        ('bank_transfer');

INSERT INTO payment_status(status) VALUES
                                        ('succeed'),
                                        ('failed'),
                                        ('pending'),
                                        ('refunded'),
                                        ('under_review');

INSERT INTO bed_type(name, bed_capacity) VALUES
                                        ('single', 1),
                                        ('king', 2),
                                        ('queen', 2),
                                        ('bunk_bed', 2),
                                        ('futon', 1), --japanese floor bed
                                        ('foldable', 1);

INSERT INTO Price_plan(type, price, description) VALUES
    ('standard', 0.00, 'Regular room price with no discount or additional fees.'),
    ('non_refundable', -10.00, 'Payment is final and cannot be refunded.'),
    ('refundable', 20.00, 'Flexible price plan that allows refunds according to cancellation rules.'),
    ('long_stay', -30.00, 'Discounted price plan for extended stays.'),
    ('corporate', -25.00, 'Special discounted rate for corporate and business clients.'),
    ('seasonal', 40.00, 'Additional charge applied during high-demand seasons.');

INSERT INTO Hotel(name, country, city, street, star_rating) VALUES
    ('Grand Palace Hotel', 'Czech Republic', 'Prague', 'Wenceslas Square 12', 5),
    ('City Comfort Inn', 'Czech Republic', 'Brno', 'Masarykova 45', 3),
    ('River View Hotel', 'Austria', 'Vienna', 'Danube Street 8', 4);



INSERT INTO Room(number, hotel_id, category, price_per_night, total_area, description) VALUES
-- Hotel 1: Grand Palace Hotel (5★, Prague)
('101', 1, 'single', 120.00, 22.0, 'Single room with city view'),
('102', 1, 'double', 180.00, 30.0, 'Double room with queen bed'),
('103', 1, 'double', 190.00, 32.0, 'Double room with city view'),
('201', 1, 'deluxe', 260.00, 40.0, 'Deluxe room with king bed'),
('202', 1, 'deluxe', 280.00, 42.0, 'Deluxe room with balcony'),
('301', 1, 'suite', 420.00, 65.0, 'Luxury suite with living area'),

-- Hotel 2: City Comfort Inn (3★, Brno)
('101', 2, 'single', 70.00, 18.0, 'Basic single room'),
('102', 2, 'double', 95.00, 24.0, 'Standard double room'),
('103', 2, 'double', 100.00, 25.0, 'Double room with workspace'),
('201', 2, 'triple', 130.00, 30.0, 'Triple room for families'),
('202', 2, 'triple', 135.00, 32.0, 'Family room'),
('301', 2, 'apartment', 160.00, 38.0, 'Small apartment with kitchenette'),

-- Hotel 3: River View Hotel (4★, Vienna)
('101', 3, 'single', 90.00, 20.0, 'Single room with river view'),
('102', 3, 'double', 140.00, 28.0, 'Standard double room'),
('103', 3, 'double', 150.00, 30.0, 'Double room with balcony'),
('201', 3, 'deluxe', 210.00, 35.0, 'Deluxe room with river view'),
('202', 3, 'deluxe', 220.00, 36.0, 'Deluxe room with seating area'),
('301', 3, 'suite', 350.00, 55.0, 'Suite with panoramic river view');

INSERT INTO beds_in_room (hotel_id, room_number, bed_type_name, quantity) VALUES
-- Hotel 1: Grand Palace Hotel (5★, Prague)
(1, '101', 'single', 1),
(1, '102', 'queen', 1),
(1, '103', 'queen', 1),
(1, '201', 'king', 1),
(1, '202', 'king', 1),
(1, '301', 'king', 1),
(1, '301', 'single', 1),  -- extra bed in suite

-- Hotel 2: City Comfort Inn (3★, Brno)
(2, '101', 'single', 1),
(2, '102', 'queen', 1),
(2, '103', 'queen', 1),
(2, '201', 'queen', 1),
(2, '201', 'single', 1),  -- triple room
(2, '202', 'queen', 1),
(2, '202', 'bunk_bed', 1), -- family room
(2, '301', 'queen', 1),
(2, '301', 'foldable', 1), -- extra bed

-- Hotel 3: River View Hotel (4★, Vienna)
(3, '101', 'single', 1),
(3, '102', 'queen', 1),
(3, '103', 'queen', 1),
(3, '201', 'king', 1),
(3, '202', 'king', 1),
(3, '301', 'king', 1),
(3, '301', 'single', 1);  -- suite extra bed


INSERT INTO Extra_service(name, hotel_id, price, description, usage_limit_per_booking) VALUES
    ('breakfast', 1, 15.00, 'Buffet breakfast served daily', NULL),
    ('spa_access', 1, 40.00, 'Access to hotel spa and wellness area', 2),
    ('airport_transfer', 1, 60.00, 'Private airport pickup or drop-off', 1),
    ('parking', 1, 25.00, 'Secure underground parking', 1),
    ('late_checkout', 1, 30.00, 'Late checkout until 3 PM', 1),

    ('breakfast', 2, 8.00, 'Simple continental breakfast', NULL),
    ('parking', 2, 10.00, 'Outdoor parking space', 1),
    ('extra_bed', 2, 20.00, 'Additional foldable bed', 1),
    ('early_checkin', 2, 15.00, 'Early check-in from 10 AM', 1),

    ('breakfast', 3, 12.00, 'Breakfast with river view', NULL),
    ('parking', 3, 18.00, 'Covered parking near hotel', 1),
    ('bike_rental', 3, 10.00, 'Daily bicycle rental', 2),
    ('airport_transfer', 3, 50.00, 'Shared airport transfer service', 1),
    ('late_checkout', 3, 25.00, 'Late checkout until 2 PM', 1);


INSERT INTO customer (first_name, second_name, birth_year, email, phone)
VALUES
('Jakob', 'Robert', 2007, 'jakob.robert@email.com', '+201698765437'),
('Ahmed', 'Hassan', 1998, 'ahmed.hassan@email.com', '+201012345678'),
('Sara', 'Mahmoud', 2006, 'sara.mahmoud@email.com', '+201098765432'),
('Omar', 'Youssef', 1995, 'omar.youssef@email.com', '+420601234567'),
('Lina', 'Khaled', 1999, 'lina.khaled@email.com', '+420608987654'),
('Fares', 'Mohamed', 2002, 'fares.mohamed@email.com', '+96551560245'),
('Frank', 'Wilson', 1999, 'frank.wilson@email.com', '+11234567895');

--status, total_price, and rooms_total are calculated automatically using the Booking_item + Payment
INSERT INTO Booking (guests_count, price_plan_id, customer_id)
VALUES
(1, 'standard', 1),
(2, 'standard', 2),
(2, 'non_refundable', 3),
(3, 'refundable', 1),
(4, 'seasonal', 4),
(2, 'non_refundable', 2),
(2, 'standard', 5);


--inserting Booking items
--Booking_1 items
INSERT INTO booking_item (booking_id, hotel_id, room_number, nights, check_in, check_out)
VALUES
(1, 1, '101', 6, '2025-12-20', '2025-12-26'),
(1, 1,  '102', 5, '2025-12-20', '2025-12-25');

--Booking_2 items
INSERT INTO booking_item (booking_id, hotel_id, room_number, nights, check_in, check_out)
VALUES
(2, 3, '101', 7, '2026-01-01', '2026-01-08'),
(2, 3 , '102', 4, '2026-01-01', '2026-01-05'),
(2, 3 , '103', 5 , '2026-01-02', '2026-01-07'),
(2, 3 , '201', 4, '2026-01-01', '2026-01-05');

--Booking_3 item
INSERT INTO booking_item (booking_id, hotel_id, room_number, nights, check_in, check_out)
VALUES
(3, 3 , '103', 3, '2026-01-07', '2026-01-10'),
(3, 3, '101', 2, '2026-01-08', '2026-01-10');

--Booking_4 items
INSERT INTO booking_item (booking_id, hotel_id, room_number, nights, check_in, check_out)
VALUES
(4, 2,'101', 6,'2025-12-25', '2025-12-31'),
(4, 2,'103',5,'2025-12-25','2025-12-30'),
(4, 2,'301',2,'2025-12-25','2025-12-27');

--Booking_5 items
INSERT INTO booking_item (booking_id, hotel_id, room_number, nights, check_in, check_out)
VALUES
(5,2, '202', 8, '2025-12-28', '2026-01-5'),
(5,2,'301', 8 ,'2025-12-28', '2026-01-5');

--Booking_8 items
INSERT INTO booking_item(booking_id, hotel_id, room_number, nights, check_in, check_out)
VALUES
(8,1, '301', 2,'2026-02-01', '2026-02-03'  );


INSERT INTO payment(method_id, amount, status_id, booking_id)
VALUES
(1,1620, 1, 1),
(2,2780, 2, 2),
(4,620, 3, 3),
(5,1260, 4, 4),
(1,2400, 5, 5),
(1 ,  2400, 1, 5),
(4, 2775, 1, 2);

INSERT INTO service_usage (service_name, hotel_id, booking_id, quantity)
VALUES
-- Booking 2
('breakfast',3, 2, 2),
('late_checkout',3,2, 1),
('parking',3,2, 1),
('bike_rental', 3 , 2 , 2),
('airport_transfer', 3, 2, 1),
('welcome_drink', 3, 2, 5),

--Booking 8
('spa_access', 1, 8, 1);
