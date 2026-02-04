
---TABLES CREATION----------------------------------------
--Hotel_rooms
CREATE TABLE Hotel (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL ,
    country TEXT NOT NULL,
    city TEXT NOT NULL ,
    street TEXT,
    star_rating INT,

    CONSTRAINT star_rating_max_5 CHECK (star_rating BETWEEN 1 AND 5)
);

CREATE TABLE Room(
    number VARCHAR(50) NOT NULL,
    hotel_id INT NOT NULL REFERENCES Hotel(id),
    category VARCHAR(50) NOT NULL ,
    price_per_night DECIMAL(10,2) NOT NULL ,
    total_area DECIMAL(7,2),
    description TEXT,
    PRIMARY KEY (hotel_id, number)
);
ALTER TABLE Room
    ADD CONSTRAINT Room_price_is_positive CHECK ( price_per_night >= 0 );
--Hotel_rooms

--Bed
CREATE TABLE Bed_type (
    name VARCHAR(50) PRIMARY KEY ,
    bed_capacity SMALLINT NOT NULL
);

CREATE TABLE Beds_in_room (
    quantity SMALLINT NOT NULL,
    hotel_id INT NOT NULL,
    room_number VARCHAR(50) NOT NULL,
    bed_type_name VARCHAR(50) NOT NULL REFERENCES Bed_type(name),
    FOREIGN KEY (hotel_id, room_number) REFERENCES Room(hotel_id, number),
    PRIMARY KEY (hotel_id, room_number, bed_type_name)
);
--Bed

--Customer
CREATE TABLE Customer(
    id SERIAL PRIMARY KEY,
    first_name VARCHAR(80) NOT NULL ,
    second_name VARCHAR(80) NOT NULL,
    birth_year SMALLINT,
    email TEXT UNIQUE NOT NULL,
    phone VARCHAR(30) UNIQUE
);
ALTER TABLE Customer
    ADD CONSTRAINT check_customer_birthYear_is_acceptable_and_adult CHECK (birth_year BETWEEN 1900 AND (EXTRACT(YEAR FROM CURRENT_DATE) - 18) );
--Customer

--Price_plan
CREATE TABLE Price_plan(
    type VARCHAR(35) PRIMARY KEY NOT NULL ,
    price DECIMAL (10,2) NOT NULL,
    description TEXT
);
--Price_plan

--Booking
CREATE TABLE Booking(
    id SERIAL PRIMARY KEY,
    guests_count INT,
    status VARCHAR(35) NOT NULL DEFAULT 'empty', --I want to make it automatically being calculated using some trigger
    total_price DECIMAL(16,2) NOT NULL DEFAULT 0, --I want to make it automatically being calculated using some trigger
    price_plan_id VARCHAR(50) NOT NULL REFERENCES Price_plan(type),
    customer_id INT NOT NULL REFERENCES Customer(id),
    rooms_total INT DEFAULT 0 NOT NULL,
    CONSTRAINT rooms_total_more_or_equal_zero CHECK ( rooms_total >= 0 )
);
ALTER TABLE Booking ADD
    CONSTRAINT total_price_is_positive CHECK ( total_price >= 0 );

CREATE TABLE Booking_item(
    booking_id INT NOT NULL REFERENCES Booking(id),
    hotel_id INT NOT NULL,
    room_number VARCHAR(50) NOT NULL,
    nights INT NOT NULL,
    price_per_night DECIMAL(10,2) NOT NULL,
    check_in DATE NOT NULL ,
    check_out DATE,
    FOREIGN KEY (hotel_id, room_number) REFERENCES Room(hotel_id, number),
    PRIMARY KEY (booking_id, hotel_id, room_number),
    CONSTRAINT check_out_is_after_check_in CHECK (check_out > check_in),
    CONSTRAINT check_out_correspond_with_check_in_and_nights CHECK (check_out = check_in + (nights * INTERVAL '1 day'))
);
ALTER TABLE Booking_item
    ADD CONSTRAINT check_in_on_valid_date CHECK (check_in >= CURRENT_DATE);
--Booking

--Payment
CREATE TABLE Payment_status(
    id SERIAL PRIMARY KEY,
    status VARCHAR(35) UNIQUE NOT NULL,
    CONSTRAINT check_if_valid_status CHECK ( status IN ('succeed', 'failed', 'pending', 'refunded', 'under_review') )
);

CREATE TABLE Payment_method(
    id SERIAL PRIMARY KEY,
    method VARCHAR(50) UNIQUE NOT NULL
);

CREATE TABLE Payment(
    id SERIAL PRIMARY KEY ,
    method_id INT NOT NULL REFERENCES Payment_method(id),
    created_date DATE DEFAULT CURRENT_DATE,
    amount decimal(16,2) NOT NULL,
    status_id INT NOT NULL REFERENCES Payment_status(id),
    booking_id INT NOT NULL REFERENCES Booking(id)
);
--Payment

--Extra Services
CREATE TABLE Extra_service(
    name TEXT NOT NULL,
    hotel_id INT NOT NULL,
    price DECIMAL(10,2) NOT NULL ,
    description TEXT,
    usage_limit_per_booking INT,
    FOREIGN KEY (hotel_id) REFERENCES Hotel(id),
    PRIMARY KEY (hotel_id, name)
);
ALTER TABLE Extra_service ADD
    CONSTRAINT extra_service_price_is_positive CHECK ( price >= 0 );

CREATE TABLE Service_usage(
    service_name TEXT NOT NULL,
    hotel_id INT NOT NULL,
    booking_id INT NOT NULL,
    quantity INT NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (hotel_id, service_name) REFERENCES Extra_service(hotel_id, name),
    FOREIGN KEY (booking_id) REFERENCES Booking(id),
    PRIMARY KEY (hotel_id, service_name, booking_id)
);
--Extra_services
---TABLES CREATION----------------------------------------




--FUNCTIONS------------------------------------------------
--helper functions----
CREATE OR REPLACE FUNCTION bring_booking_status(targeted_booking_id INT)
RETURNS VARCHAR(35) AS $$
DECLARE
    booking_status VARCHAR(35);
BEGIN
    SELECT status
    INTO booking_status
    FROM Booking
    WHERE id = targeted_booking_id;

    RETURN booking_status;
END;
$$ LANGUAGE plpgsql;

-- calculated_total = SUM(Room_items(price*nights)) + SUM(Service_usage(quantity*price))
CREATE OR REPLACE FUNCTION calculate_booking_total_price(id_booking INT)
RETURNS VOID AS $$
DECLARE
    temp_total DECIMAL(16,2);
    BEGIN
        temp_total := (SELECT COALESCE(SUM(price_per_night * nights), 0) FROM Booking_item WHERE booking_id = id_booking)
                        + (SELECT COALESCE(SUM(price * quantity), 0) FROM Service_usage WHERE booking_id = id_booking)
                        + (SELECT price FROM Price_plan WHERE type = (SELECT price_plan_id FROM booking WHERE id = id_booking));
        IF temp_total < 0 THEN
            UPDATE Booking
            SET total_price = 0
            WHERE id = id_booking;
        ELSE
            UPDATE Booking
            SET total_price = temp_total
            WHERE id = id_booking;
        END IF;
    END;
$$  LANGUAGE plpgsql;
--helper functions----

--Payment functions----
CREATE OR REPLACE FUNCTION set_booking_status_on_valid_payment_insert()
RETURNS TRIGGER AS $$
DECLARE
booking_status VARCHAR(35);
status_of_payment VARCHAR(35);
    BEGIN
        booking_status := bring_booking_status(NEW.booking_id);

        IF booking_status != 'not confirmed' THEN
            RAISE EXCEPTION 'Cannot pay for already confirmed, cancelled, pending, or empty bookings.';
        ELSE
            SELECT status INTO status_of_payment
            FROM Payment_status
            WHERE id = NEW.status_id;

            IF status_of_payment = 'succeed' THEN
               IF ABS(NEW.amount - (SELECT total_price FROM booking WHERE id = NEW.booking_id)) <= 0.01 THEN
                        UPDATE Booking
                        SET status = 'confirmed'
                        WHERE id = NEW.booking_id;
                    ELSE
                        UPDATE Booking
                        SET status = 'not confirmed'
                        WHERE id = NEW.booking_id;
                        NEW.status_id := (SELECT id FROM Payment_status WHERE status = 'under_review');

               END IF;
            ELSIF status_of_payment = 'pending' THEN
                UPDATE Booking
                SET status = 'pending'
                WHERE id = NEW.booking_id;
            ELSIF status_of_payment = 'refunded' THEN
                IF (SELECT price_plan_id FROM Booking WHERE id = NEW.booking_id) = 'non_refundable' THEN
                    RAISE EXCEPTION
                        'Refunding is not allowed for non-refundable price plans';
                END IF;

                UPDATE Booking
                SET status = 'cancelled'
                WHERE id = NEW.booking_id;
            END IF;
        END IF;
        RETURN NEW;
    END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION check_before_payment_delete()
RETURNS TRIGGER AS $$
DECLARE
status_of_payment VARCHAR(35);
    BEGIN
        SELECT status INTO status_of_payment
        FROM Payment_status
        WHERE id = OLD.status_id;

        IF status_of_payment != 'failed' THEN
            RAISE EXCEPTION 'Only failed payments can be deleted';
        END IF;
        RETURN OLD;
    END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION set_booking_status_on_valid_payment_update()
RETURNS TRIGGER AS $$
DECLARE
payment_status_before_update VARCHAR(35);
payment_status_after_update VARCHAR(35);
    BEGIN
        SELECT status INTO payment_status_before_update
        FROM Payment_status
        WHERE id = OLD.status_id;

        IF payment_status_before_update NOT IN ('pending', 'succeed', 'under_review') THEN
        RAISE EXCEPTION 'Cannot update failed and refunded payments.';
        ELSE
            SELECT status INTO payment_status_after_update
            FROM Payment_status
            WHERE id = NEW.status_id;

            IF payment_status_before_update = 'pending' THEN
                IF payment_status_after_update = 'succeed' THEN
                    IF ABS(NEW.amount - (SELECT total_price FROM booking WHERE id = NEW.booking_id)) <= 0.01 THEN
                        UPDATE Booking
                        SET status = 'confirmed'
                        WHERE id = NEW.booking_id;
                    ELSE
                        UPDATE Booking
                        SET status = 'not confirmed'
                        WHERE id = NEW.booking_id;
                        NEW.status_id := (SELECT id FROM Payment_status WHERE status = 'under_review');

                    END IF;
                ELSIF payment_status_after_update IN ('failed', 'refunded') THEN
                    UPDATE Booking
                    SET status = 'not confirmed'
                    WHERE id = NEW.booking_id;
                ELSIF payment_status_after_update != 'pending' THEN
                    RAISE EXCEPTION 'Not a valid payment status. valid:(succeed, pending, refunded, failed)';
                END IF;
            ELSIF payment_status_before_update = 'succeed' THEN
                IF payment_status_after_update = 'refunded' THEN
                    IF (SELECT price_plan_id FROM Booking WHERE id = NEW.booking_id) = 'non_refundable' THEN
                        RAISE EXCEPTION
                        'Refunding is not allowed for non-refundable price plans';
                    END IF;

                    UPDATE Booking
                    SET status = 'cancelled'
                    WHERE id = NEW.booking_id;
                ELSE
                    RAISE EXCEPTION 'Only refunded status changes are allowed for succeed payments.';
                END IF;
            ELSIF payment_status_before_update = 'under_review' THEN
                IF payment_status_after_update = 'refunded' THEN
                    UPDATE Booking
                    SET status = 'not confirmed'
                    WHERE id = NEW.booking_id;
                ELSE
                    RAISE EXCEPTION 'Only refunded status changes are allowed under_review payments.';
                END IF;
            END IF;
        END IF;
        RETURN NEW;
    END;
$$ LANGUAGE plpgsql;
--Payment functions---

--Booking_functions---
CREATE OR REPLACE FUNCTION validate_booking_room_item_insert()
RETURNS TRIGGER AS $$
DECLARE
id_of_hotel INT;
booking_status VARCHAR(35);
room_price_per_night DECIMAL(10,2);
    BEGIN
        booking_status := bring_booking_status(NEW.booking_id);

        IF booking_status IN ('confirmed', 'pending', 'cancelled') THEN
            RAISE EXCEPTION 'Cannot modify rooms for confirmed, pending and cancelled bookings.';
        END IF;

        --same hotel check
        IF EXISTS(
                SELECT 1 FROM Booking_item
                WHERE booking_id = NEW.booking_id
            ) THEN
                SELECT hotel_id INTO id_of_hotel
                FROM Booking_item
                WHERE booking_id = NEW.booking_id
                LIMIT 1;

                IF NEW.hotel_id != id_of_hotel THEN
                    RAISE EXCEPTION 'Adding rooms from different Hotels is not allowed';
                END IF;
        END IF;
        --same hotel check


        --check_in and check_out are not overlapping with another item for the same room
        IF EXISTS (
            SELECT 1
            FROM Booking_item
            WHERE hotel_id = NEW.hotel_id
              AND room_number = NEW.room_number
              AND NEW.check_in < check_out
              AND NEW.check_out > check_in
        ) THEN
            RAISE EXCEPTION 'The room is already booked for the selected check-in and check-out dates.';
        END IF;
        --check_in and check_out are not overlapping with another item for the same room


        SELECT price_per_night INTO room_price_per_night
        FROM Room
        WHERE (hotel_id,number) = (NEW.hotel_id, NEW.room_number);
        NEW.price_per_night := room_price_per_night;

        UPDATE Booking
        SET rooms_total = rooms_total + 1,
            status = CASE
                        WHEN status = 'empty' THEN 'not confirmed'
                        ELSE status
                     END
        WHERE id = NEW.booking_id;

        RETURN NEW; --you can insert the new row
    END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION validate_booking_room_item_delete()
RETURNS TRIGGER AS $$
DECLARE
booking_status VARCHAR(35);
remaining_rooms INT;
    BEGIN
        booking_status := bring_booking_status(OLD.booking_id);

        IF booking_status IN ('confirmed', 'pending', 'cancelled') THEN
            RAISE EXCEPTION 'Cannot modify rooms for confirmed, pending and cancelled bookings.';
        END IF;

        UPDATE Booking
        SET rooms_total = rooms_total - 1
        WHERE id = OLD.booking_id;

        SELECT rooms_total INTO remaining_rooms
        FROM Booking
        WHERE OLD.booking_id = Booking.id;

        IF remaining_rooms = 0 THEN
            UPDATE Booking
            SET status = 'empty'
            WHERE OLD.Booking_id = Booking.id;
        END IF;
        RETURN OLD; --you can delete the intended row
    END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION validate_booking_room_item_update()
RETURNS TRIGGER AS $$
DECLARE
id_of_hotel INT;
old_booking_status VARCHAR(35);
new_booking_status VARCHAR(35);
    BEGIN
        old_booking_status := bring_booking_status(OLD.booking_id);
        new_booking_status := bring_booking_status(NEW.booking_id);
         IF new_booking_status  IN ('confirmed', 'pending', 'cancelled') OR old_booking_status IN ('confirmed', 'pending', 'cancelled') THEN
            RAISE EXCEPTION 'Cannot modify rooms for confirmed, pending and cancelled bookings.';
        END IF;


        --check the same hotel
        IF EXISTS(
                SELECT 1 FROM Booking_item
                WHERE booking_id = NEW.booking_id
                AND (booking_id, hotel_id, room_number) <> (OLD.booking_id, OLD.hotel_id, OLD.room_number)
            ) THEN
                SELECT hotel_id INTO id_of_hotel
                FROM Booking_item
                WHERE booking_id = NEW.booking_id
                AND (booking_id, hotel_id, room_number) <> (OLD.booking_id, OLD.hotel_id, OLD.room_number)
                LIMIT 1;

                IF NEW.hotel_id != id_of_hotel THEN
                    RAISE EXCEPTION 'Adding rooms from different Hotels is not allowed';
                END IF;
        END IF;
        --check the same hotel


        --check dates overlapping
        IF  EXISTS (
            SELECT 1
            FROM Booking_item
            WHERE hotel_id = NEW.hotel_id
                AND room_number = NEW.room_number
                AND NEW.check_in < check_out
                AND NEW.check_out > check_in
                AND (booking_id, hotel_id, room_number) <> (OLD.booking_id, OLD.hotel_id, OLD.room_number)

        ) THEN
            RAISE EXCEPTION 'The room is already booked for the selected check-in and check-out dates.';
        END IF;
        --check dates overlapping

        RETURN NEW;
    END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION calculate_booking_total_price_after_item_insert()
RETURNS TRIGGER AS $$
    BEGIN
        PERFORM calculate_booking_total_price(NEW.booking_id);
        RETURN NEW;
    END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION calculate_booking_total_price_after_item_delete()
RETURNS TRIGGER AS $$
    BEGIN
        PERFORM calculate_booking_total_price(OLD.booking_id);
        RETURN OLD;
    END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION calculate_booking_total_price_after_item_update()
RETURNS TRIGGER AS $$
    BEGIN
        PERFORM calculate_booking_total_price(NEW.booking_id);
        RETURN NEW;
    END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION recalc_booking_total_price_on_booking_update()
RETURNS TRIGGER AS $$
BEGIN
    PERFORM calculate_booking_total_price(NEW.id);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
--Booking functions---

--Extra_service function---
CREATE OR REPLACE FUNCTION set_service_usage_price_and_check_limit_on_insert()
RETURNS TRIGGER AS $$
DECLARE
    booking_status VARCHAR(35);
    usage_limit INT;
    service_price DECIMAL(10,2);
    id_of_hotel INT;
    BEGIN
        booking_status := bring_booking_status(NEW.booking_id);
        IF booking_status IN ('confirmed', 'pending', 'cancelled') THEN
            RAISE EXCEPTION
                'Cannot modify services for confirmed, pending or cancelled bookings';
        END IF;

        SELECT usage_limit_per_booking INTO usage_limit
        FROM Extra_service
        WHERE (hotel_id, name) = (NEW.hotel_id, NEW.service_name);

        IF usage_limit IS NOT NULL AND NEW.quantity > usage_limit THEN
                RAISE EXCEPTION 'This service "%" has usage limit of % per one booking', NEW.service_name,usage_limit;
        END IF;

        -- same hotel check
        SELECT hotel_id INTO id_of_hotel
        FROM Booking_item
        WHERE booking_id = NEW.booking_id
        LIMIT 1;

        IF id_of_hotel IS NULL THEN
            RAISE EXCEPTION
                'Cannot add services before adding at least one room to the booking';
        END IF;

        IF NEW.hotel_id != id_of_hotel THEN
            RAISE EXCEPTION
                'Adding service from different hotel is not allowed';
        END IF;
        --same hotel check

        SELECT price INTO service_price
        FROM Extra_service
        WHERE (hotel_id, name) = (NEW.hotel_id, NEW.service_name);
        NEW.price := service_price;
        RETURN NEW;
    END;
$$  LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION set_service_usage_price_and_check_limit_on_update()
RETURNS TRIGGER AS $$
DECLARE
    booking_status VARCHAR(35);
    id_of_hotel INT;
    usage_limit INT;
    BEGIN
        --same booking chack
        IF NEW.booking_id <> OLD.booking_id THEN
        RAISE EXCEPTION 'Changing booking_id of a service usage is not allowed';
        END IF;
        --same booking chack

        --allowed to make changes for the booking chack
        booking_status := bring_booking_status(NEW.booking_id);
        IF booking_status NOT IN ('not confirmed', 'empty') THEN
            RAISE EXCEPTION
                'Updating service for already confirmed, cancelled, and pending bookings is not allowed.';
        END IF;
        --allowed to make changes for the booking chack

        --same hotel check
        SELECT hotel_id INTO id_of_hotel
        FROM Booking_item
        WHERE booking_id = NEW.booking_id
        LIMIT 1;
        IF id_of_hotel IS NULL THEN
            RAISE EXCEPTION
                'Cannot add services before adding at least one room to the booking';
        END IF;
        IF NEW.hotel_id != id_of_hotel THEN
            RAISE EXCEPTION
                'Adding service from different hotel is not allowed';
        END IF;
        --same hotel check

        --not exceeding usage limit check
        SELECT usage_limit_per_booking INTO usage_limit
        FROM Extra_service
        WHERE (hotel_id, name) = (NEW.hotel_id, NEW.service_name);

        IF usage_limit IS NOT NULL AND NEW.quantity > usage_limit THEN
                RAISE EXCEPTION 'This service "%" has usage limit of % per one booking', NEW.service_name,usage_limit;
        END IF;
        --not exceeding usage limit check

        NEW.price := (SELECT price FROM Extra_service WHERE (hotel_id, name) = (NEW.hotel_id, NEW.service_name));
        RETURN NEW;
    END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION validate_service_usage_delete()
RETURNS TRIGGER AS $$
DECLARE
    booking_status VARCHAR(35);
BEGIN
    -- check if booking is allowed to be deleted
    booking_status := bring_booking_status(OLD.booking_id);

    IF booking_status NOT IN ('not confirmed', 'empty') THEN
        RAISE EXCEPTION
            'Deleting service for already confirmed, cancelled, or pending bookings is not allowed.';
    END IF;

    RETURN OLD;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION recalc_booking_price_after_service_insert()
RETURNS TRIGGER AS $$
BEGIN
    PERFORM calculate_booking_total_price(NEW.booking_id);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION recalc_booking_price_after_service_update()
RETURNS TRIGGER AS $$
BEGIN
    PERFORM calculate_booking_total_price(NEW.booking_id);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION recalc_booking_price_after_service_delete()
RETURNS TRIGGER AS $$
BEGIN
    PERFORM calculate_booking_total_price(OLD.booking_id);
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;
--Extra_Services function---
--FUNCTIONS------------------------------------------------



--TRIGGERS-------------------------------------------------
--Payment triggers---
CREATE OR REPLACE TRIGGER before_inserting_into_payment
BEFORE INSERT ON Payment
FOR EACH ROW
EXECUTE FUNCTION set_booking_status_on_valid_payment_insert();

CREATE OR REPLACE TRIGGER before_deleting_from_payment
BEFORE DELETE ON Payment
FOR EACH ROW
EXECUTE FUNCTION check_before_payment_delete();

CREATE OR REPLACE TRIGGER before_payment_update
BEFORE UPDATE ON Payment
FOR EACH ROW
EXECUTE FUNCTION set_booking_status_on_valid_payment_update();
--Payment triggers---

--Booking triggers---
CREATE OR REPLACE TRIGGER before_insert_booking_room_item
BEFORE INSERT ON Booking_item
    FOR EACH ROW
    EXECUTE FUNCTION validate_booking_room_item_insert();
CREATE OR REPLACE TRIGGER calculate_booking_price_total_after_insert
AFTER INSERT ON Booking_item
    FOR EACH ROW
    EXECUTE FUNCTION calculate_booking_total_price_after_item_insert();

CREATE OR REPLACE TRIGGER before_delete_booking_room_item
BEFORE DELETE ON Booking_item
    FOR EACH ROW
    EXECUTE FUNCTION validate_booking_room_item_delete();
CREATE OR REPLACE TRIGGER calculate_booking_price_total_after_delete
AFTER DELETE ON Booking_item
    FOR EACH ROW
    EXECUTE FUNCTION calculate_booking_total_price_after_item_delete();

CREATE OR REPLACE TRIGGER before_update_booking_room_item
BEFORE UPDATE ON Booking_item
    FOR EACH ROW
    EXECUTE FUNCTION validate_booking_room_item_update();
CREATE OR REPLACE TRIGGER calculate_booking_price_total_after_update
AFTER UPDATE ON Booking_item
    FOR EACH ROW
    EXECUTE FUNCTION calculate_booking_total_price_after_item_update();

CREATE OR REPLACE TRIGGER after_booking_update_recalc_booking_price
AFTER UPDATE OF price_plan_id
ON Booking
FOR EACH ROW
EXECUTE FUNCTION recalc_booking_total_price_on_booking_update();
--Booking triggers---

--Extra service triggers---
CREATE OR REPLACE TRIGGER before_insert_service_usage
BEFORE INSERT OR UPDATE ON Service_usage
FOR EACH ROW
EXECUTE FUNCTION set_service_usage_price_and_check_limit_on_insert();
CREATE OR REPLACE TRIGGER after_insert_service_usage
AFTER INSERT ON Service_usage
FOR EACH ROW
EXECUTE FUNCTION recalc_booking_price_after_service_insert();

CREATE OR REPLACE TRIGGER before_update_service_usage
BEFORE UPDATE ON Service_usage
FOR EACH ROW
EXECUTE FUNCTION set_service_usage_price_and_check_limit_on_update();
CREATE OR REPLACE TRIGGER  after_update_service_usage
AFTER UPDATE ON Service_usage
FOR EACH ROW
EXECUTE FUNCTION recalc_booking_price_after_service_update();

CREATE OR REPLACE TRIGGER before_delete_service_usage
BEFORE DELETE ON Service_usage
FOR EACH ROW
EXECUTE FUNCTION validate_service_usage_delete();
CREATE OR REPLACE TRIGGER  after_delete_service_usage
AFTER DELETE ON Service_usage
FOR EACH ROW
EXECUTE FUNCTION recalc_booking_price_after_service_delete();
--Extra service triggers---
--TRIGGERS-------------------------------------------------
