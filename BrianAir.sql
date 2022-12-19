/*
TDDD81 Assignment 4 - BrianAir Project
Max Wallhem, maxwa237
Jakob Berggren, jakbe841
*/

SET FOREIGN_KEY_CHECKS=OFF; #Foreign key checks off to allow deletion of tables. 

DROP TABLE IF EXISTS Flight;
DROP TABLE IF EXISTS Weekly_schedule;
DROP TABLE IF EXISTS Day_of_week;
DROP TABLE IF EXISTS Year;
DROP TABLE IF EXISTS Passenger;
DROP TABLE IF EXISTS Credit_card;
DROP TABLE IF EXISTS Booking;
DROP TABLE IF EXISTS Reservation;
DROP TABLE IF EXISTS Contact;
DROP TABLE IF EXISTS Route;
DROP TABLE IF EXISTS Airport;
DROP TABLE IF EXISTS Passenger_reservation;
DROP TABLE IF EXISTS Ticket;

DROP PROCEDURE IF EXISTS addYear;
DROP PROCEDURE IF EXISTS addDay;
DROP PROCEDURE IF EXISTS addDestination;
DROP PROCEDURE IF EXISTS addRoute;
DROP PROCEDURE IF EXISTS addFlight;

DROP FUNCTION IF EXISTS calculateFreeSeats;
DROP FUNCTION IF EXISTS calculatePrice;

DROP TRIGGER IF EXISTS random_ticket_number;

DROP PROCEDURE IF EXISTS addReservation;
DROP PROCEDURE IF EXISTS addPassenger;
DROP PROCEDURE IF EXISTS addContact;
DROP PROCEDURE IF EXISTS addPayment;

DROP VIEW IF EXISTS allFlights;

SET FOREIGN_KEY_CHECKS=ON;

CREATE TABLE Airport (
	Airport_code VARCHAR(3) NOT NULL,
    Airport_name VARCHAR(30),
    Country VARCHAR(30),
    
    PRIMARY KEY(Airport_code)
);

CREATE TABLE Route (
	ID INTEGER NOT NULL AUTO_INCREMENT,
    Departs_ID VARCHAR(3) NOT NULL,
	Arrives_ID VARCHAR(3) NOT NULL,
    Year INTEGER,
	Route_price DOUBLE,
    
    PRIMARY KEY (ID)
);

CREATE TABLE Flight (
	Flight_number INTEGER NOT NULL AUTO_INCREMENT,
    Weekly_schedule_ID INTEGER NOT NULL,
    Week INTEGER,
    
    PRIMARY KEY(Flight_number)
);
    
CREATE TABLE Weekly_schedule (
	ID INTEGER AUTO_INCREMENT,
    Day VARCHAR(10) NOT NULL,
	Route_ID INTEGER NOT NULL,
    Departure_time TIME,
    
    PRIMARY KEY(ID)
);

CREATE TABLE Day_of_week (
	Year INTEGER,
	Day VARCHAR(10),
    Week_day_factor DOUBLE,
    
    PRIMARY KEY(Day)
);

CREATE TABLE Year (
	Year INTEGER,
    Profit_factor DOUBLE,
    
    PRIMARY KEY(Year)
);

CREATE TABLE Passenger (
	Passport_number INTEGER,
    Full_Name VARCHAR(30),
    
    PRIMARY KEY(Passport_number)
);

CREATE TABLE Credit_card (
	Card_number BIGINT,
    Card_holder VARCHAR(30),
    Reservation_number INTEGER,
    
    PRIMARY KEY(Card_number)
);

CREATE TABLE Booking (
	Booking_number INTEGER,
    Credit_card_number BIGINT,
    Price DOUBLE,
    
    PRIMARY KEY(Booking_number)
);

CREATE TABLE Contact (
	Phone_number BIGINT,
    Email VARCHAR(30),
    Passport_number INTEGER
    
    #PRIMARY KEY(Passport_number)
);

CREATE TABLE Reservation (
	Reservation_number INTEGER AUTO_INCREMENT,
    Flight_number INTEGER,
    Contact_passport_number INTEGER,
    No_of_passengers INTEGER,
    
    PRIMARY KEY(Reservation_number)
);

CREATE TABLE Passenger_reservation (
	Passenger_ID INTEGER,
    Reservation_ID INTEGER,
    
    PRIMARY KEY(Passenger_ID, Reservation_ID)
);

CREATE TABLE Ticket (
	Passenger_passport_number INTEGER,
    Booking_number INTEGER,
	Ticket_number INTEGER DEFAULT 0,
    
	PRIMARY KEY(Ticket_number)
);

/*
Add foreign keys to above tables.
*/

ALTER TABLE Route
ADD FOREIGN KEY (Arrives_ID) REFERENCES Airport(Airport_code),
ADD FOREIGN KEY (Year) REFERENCES Year(Year),
ADD FOREIGN KEY (Departs_ID) REFERENCES Airport(Airport_code) ON DELETE CASCADE;

ALTER TABLE Flight
ADD FOREIGN KEY (Weekly_schedule_ID) REFERENCES Weekly_schedule(ID) ON DELETE CASCADE;

ALTER TABLE Weekly_schedule
ADD FOREIGN KEY (Route_ID) REFERENCES Route(ID),
ADD FOREIGN KEY (Day) REFERENCES Day_of_week(Day) ON DELETE CASCADE;

ALTER TABLE Day_of_week
ADD FOREIGN KEY (Year) REFERENCES Year(Year) ON DELETE CASCADE;

ALTER TABLE Credit_card
ADD FOREIGN KEY (Reservation_number) REFERENCES Reservation(Reservation_number) ON DELETE CASCADE;

ALTER TABLE Booking
ADD FOREIGN KEY (Booking_number) REFERENCES Reservation(Reservation_number),
ADD FOREIGN KEY (Credit_card_number) REFERENCES Credit_card(Card_number) ON DELETE CASCADE;

ALTER TABLE Contact
ADD FOREIGN KEY (Passport_number) REFERENCES Passenger(Passport_number);

ALTER TABLE Reservation
ADD FOREIGN KEY (Flight_number) REFERENCES Flight(Flight_number),
ADD FOREIGN KEY (Contact_passport_number) REFERENCES Contact(Passport_number) ON DELETE CASCADE;

ALTER TABLE Passenger_reservation
ADD FOREIGN KEY (Passenger_ID) REFERENCES Passenger(Passport_number),
ADD FOREIGN KEY (Reservation_ID) REFERENCES Reservation(Reservation_number) ON DELETE CASCADE;

ALTER TABLE Ticket
ADD FOREIGN KEY (Booking_number) REFERENCES Booking(Booking_number),
ADD FOREIGN KEY (Passenger_passport_number) REFERENCES Passenger(Passport_number) ON DELETE CASCADE;

###################################################
################   PROCEDURES   ###################
###################################################


DELIMITER //
CREATE PROCEDURE addYear(IN year INTEGER, IN factor DOUBLE)
BEGIN
	INSERT INTO Year
	VALUES(year, factor);
END;
//

CREATE PROCEDURE addDay(IN year INTEGER, IN day VARCHAR(10), In factor DOUBLE)
BEGIN
	INSERT INTO Day_of_week
    VALUES(year, day, factor);
END;
//

CREATE PROCEDURE addDestination(IN airport_code VARCHAR(3),
								IN name VARCHAR(30),
								IN country VARCHAR(30))
                                
BEGIN
	INSERT INTO Airport
    VALUES(airport_code, name, country);
END;
//

CREATE PROCEDURE addRoute(IN departure_airport_code VARCHAR(3),
						  IN arrival_airport_code VARCHAR(3), 
						  IN year INTEGER, IN routeprice DOUBLE)
                          
BEGIN
	INSERT INTO Route(Departs_ID, Arrives_ID, year, Route_price)
    VALUES(departure_airport_code, arrival_airport_code, year, routeprice);
END;
//

CREATE PROCEDURE addFlight(IN departure_airport_code VARCHAR(3), IN arrival_airport_code VARCHAR(3), 
						   IN inyear INTEGER, IN inday VARCHAR(10), IN departure_time TIME)
BEGIN

	DECLARE week_nr INTEGER DEFAULT 0;
    DECLARE route INTEGER;
    DECLARE schedule INTEGER;
    
    SELECT ID INTO route 
    FROM Route
    WHERE Arrives_ID = arrival_airport_code 
		AND Departs_ID = departure_airport_code 
        AND year = inyear;
	
    INSERT INTO Weekly_schedule(Day, Route_ID, Departure_time)
    VALUES(inday, route, departure_time);
    
    SELECT ID INTO schedule
    FROM Weekly_schedule
    WHERE ID = LAST_INSERT_ID();
    
	insert_flight_loop: LOOP
		SET week_nr = week_nr + 1;
            
		IF week_nr > 52 THEN
			LEAVE insert_flight_loop;
		END IF;
            
		INSERT INTO Flight(Week, Weekly_schedule_ID)
		VALUES(week_nr, schedule);
	END LOOP;
END;
//

###################################################
#############   HELPER FUNCTIONS   ################
###################################################

CREATE FUNCTION calculateFreeSeats(flightnumber INTEGER)
		RETURNS INTEGER
BEGIN   
	DECLARE total INTEGER;
    
    SELECT SUM(No_of_passengers) INTO total
			FROM Reservation r, Booking b
            WHERE r.Flight_number = flightnumber
            AND b.Booking_number = r.Reservation_number;
	IF total IS NULL THEN
		RETURN 40;
	ELSE
		RETURN (40 - total);
	END IF;
END;
//

CREATE FUNCTION calculatePrice(flightnumber INTEGER)
	RETURNS DOUBLE
BEGIN
	DECLARE calc_route_price DOUBLE DEFAULT 0.0;
	DECLARE calc_day VARCHAR(10);
	DECLARE calc_weekdayfactor DOUBLE DEFAULT 0.0;
    DECLARE calc_profitfactor DOUBLE DEFAULT 0.0;
    DECLARE total_price DOUBLE(10,3) DEFAULT 0.0;
    
		SELECT Route_price INTO calc_route_price 
        FROM Route r, Flight f, Weekly_schedule w
        WHERE f.Flight_number = flightnumber 
			AND f.Weekly_schedule_ID = w.ID
            AND r.ID = w.Route_ID;
    
		SELECT Week_day_factor INTO calc_weekdayfactor 
        FROM Day_of_week dow, Weekly_schedule w, Flight f
        WHERE f.Flight_number = flightnumber
			AND f.Weekly_schedule_ID = w.ID
             AND dow.Day = w.Day;
		
        #SELECT Week_day_factor INTO calc_weekdayfactor 
        #FROM Day_of_week
        #WHERE Day = calc_day;
        
        SELECT Profit_factor INTO calc_profitfactor 
        FROM Year y, Flight f, Weekly_schedule w, Route r
		WHERE f.Flight_number = flightnumber 
			AND f.Weekly_schedule_ID = w.ID
            AND r.ID = w.Route_ID
            AND r.year = y.Year;
		
        SET total_price = (calc_route_price * calc_weekdayfactor * (40 - calculateFreeSeats(flightnumber) + 1) / 40 *  calc_profitfactor);
        RETURN total_price;
END;
//

###################################################
#################   TRIGGER   #####################
###################################################

CREATE TRIGGER random_ticket_number 
BEFORE INSERT ON Ticket
FOR EACH ROW SET NEW.Ticket_number = RAND()*(999999999-100000000) + 100000000;
//

###################################################
################   PROCEDURES   ###################
###################################################

CREATE PROCEDURE addReservation(IN departure_airport_code VARCHAR(3), IN arrival_airport_code VARCHAR(3),
								IN inyear INTEGER, IN inweek INTEGER, IN inday VARCHAR(10), IN intime TIME,
                                IN number_of_passengers INTEGER, OUT output_reservation_nr INTEGER)
                                
BEGIN
	DECLARE current_route_id INTEGER DEFAULT 0;
    DECLARE current_weekly_schedule INTEGER DEFAULT 0;
	DECLARE current_flight_id INTEGER DEFAULT 0;
    DECLARE current_week INTEGER DEFAULT 0;

    SELECT ID INTO current_route_id
    FROM Route
    WHERE Departs_ID = departure_airport_code 
		AND Arrives_ID = arrival_airport_code
        AND year = inyear;
        
	SELECT ID INTO current_weekly_schedule
    FROM Weekly_schedule
    WHERE Route_ID = current_route_id
		AND Day = inday
        AND Departure_time = intime;
    
    SELECT Flight_number INTO current_flight_id
    FROM Flight
    WHERE Week = inweek
		AND Weekly_schedule_ID = current_weekly_schedule;

	IF (current_flight_id != 0) THEN		
		IF (number_of_passengers <= 40) THEN 
			INSERT INTO Reservation(Flight_number, No_of_passengers)
			VALUES(current_flight_id, number_of_passengers);
			
			SELECT Reservation_number INTO output_reservation_nr
			FROM Reservation
			WHERE Reservation_number = LAST_INSERT_ID(); 

		ELSE
			SELECT "There are not enough seats available on the chosen flight" AS "Message";
		END IF;
	ELSE
		SELECT "There exist no flight for the given route, date and time" AS "Message";
	END IF;
END;
//

CREATE PROCEDURE addPassenger(IN reservation_nr INTEGER,
							  IN passport_number INTEGER,
							  IN in_name VARCHAR(30))

BEGIN
	DECLARE current_reservation_nr INTEGER DEFAULT 0;
    
	IF NOT EXISTS (SELECT Booking_number
			   FROM Booking
               WHERE Booking_number = reservation_nr) THEN #Checkar om reservationen är en bokning eller ej. Alltså är den betald?
															   #Om JA -> ska ej vara möjligt att addera fler till reservationen!
		IF EXISTS (SELECT *
					FROM Reservation
					WHERE Reservation_number = reservation_nr) THEN
		
			IF NOT EXISTS (SELECT *
						   FROM Passenger
						   WHERE Passport_number = passport_number
							AND Full_name = in_name) THEN
			
				INSERT INTO Passenger(Passport_number, Full_Name)
				VALUES(passport_number, in_name);
			END IF;
            
			IF NOT EXISTS (SELECT * 
							FROM Passenger_reservation
							WHERE Passenger_ID = passport_number
								AND Reservation_ID = reservation_nr) THEN
			
							INSERT INTO Passenger_reservation(Passenger_ID, Reservation_ID)
							VALUES(passport_number, reservation_nr);
			
			ELSE
				SELECT "This passenger already exists" AS "Message";
			END IF;
            
		ELSE 
			SELECT "The given reservation number does not exist" AS "Message";
		END IF;
	ELSE
		SELECT "The booking has already been payed and no futher passengers can be added" AS "Message";
    END IF;
END;
//

CREATE PROCEDURE addContact(IN reservation_nr INTEGER, IN passport_number INTEGER, 
							IN email VARCHAR(30), IN phone BIGINT)
                            
BEGIN
	IF EXISTS (SELECT Reservation_number
			   FROM Reservation
			   WHERE Reservation_number = reservation_nr) THEN
           
		IF EXISTS (SELECT * FROM Passenger_reservation pr, Reservation r
					WHERE pr.Passenger_ID = passport_number
						AND pr.Reservation_ID = reservation_nr
                        AND r.Reservation_number = reservation_nr) THEN
                       
			INSERT INTO Contact(Phone_number, Email, Passport_number)
			VALUES (phone, email, passport_number);
            
            UPDATE Reservation
            SET contact_passport_number = passport_number
            WHERE Reservation_number = reservation_nr;
            
        ELSE
			SELECT "The person is not a passenger of the reservation" AS "Message";
		END IF;
	ELSE
		SELECT "The given reservation number does not exist" AS "Message";
	END IF;

END;
//

CREATE PROCEDURE addPayment(IN reservation_nr INTEGER,
							 IN cardholder_name VARCHAR(30),
                             IN credit_card_number BIGINT)

BEGIN
	DECLARE nr_of_passengers_in_reservation INTEGER DEFAULT 0;
    DECLARE current_flight_nr VARCHAR(3);
	
    IF EXISTS (SELECT Reservation_number 
			   FROM Reservation
               WHERE Reservation_number = reservation_nr) THEN #Check if reservation exists
    
		IF EXISTS (SELECT *
				   FROM Reservation
				   WHERE Reservation_number = reservation_nr
					AND Contact_passport_number IS NOT NULL) THEN #Check if reservation has contact.
				
			SELECT COUNT(*) INTO nr_of_passengers_in_reservation
			FROM Passenger_reservation
            WHERE Reservation_ID = reservation_nr;
            
			SELECT Flight_number INTO current_flight_nr
			FROM Reservation
			WHERE Reservation_number = reservation_nr;
			
			IF (nr_of_passengers_in_reservation <= calculateFreeSeats(current_flight_nr)) THEN             
				INSERT INTO Credit_card(Card_number, Card_holder, Reservation_number)
                VALUES (credit_card_number, cardholder_name, reservation_nr);
                
                SELECT SLEEP(5);
                
                INSERT INTO Booking(Booking_number, Credit_card_number, Price)
                VALUES (reservation_nr, credit_card_number, calculatePrice(current_flight_nr));
                
                INSERT INTO Ticket(Passenger_passport_number, Booking_number)
                SELECT * 
                FROM Passenger_reservation
                WHERE Reservation_ID = reservation_nr;
                
			ELSE
				SELECT "There are not enough seats available on the flight anymore, deleting reservation" AS "Message";
                
                DELETE FROM Reservation
                WHERE Reservation_number = reservation_nr;
                
                #Delete from passenger??
                
			END IF;
		ELSE
			SELECT "The reservation has no contact yet" AS "Message";
		END IF;
	ELSE
		SELECT "The given reservation number does not exist" AS "Message";
	END IF;
END;
//

DELIMITER ;

CREATE VIEW allFlights AS
	
    SELECT D.Airport_name AS departure_city_name,
			A.Airport_name AS destination_city_name,
            Weekly_schedule.Departure_time AS departure_time,
            Weekly_schedule.Day AS departure_day,
            F.Week AS departure_week,
            Year.Year AS departure_year,
            calculateFreeSeats(F.Flight_number) AS nr_of_free_seats,
            calculatePrice(F.Flight_number) AS current_price_per_seat            
    FROM Route 
    LEFT JOIN Airport D
    ON Route.Departs_ID = D.Airport_code
    
    LEFT JOIN Airport A
    ON Route.Arrives_ID = A.Airport_code
    
    LEFT JOIN Weekly_schedule
    ON Route.ID = Weekly_schedule.Route_ID
    
    LEFT JOIN Year
    ON Route.Year = Year.Year
    
    LEFT JOIN Flight F
    ON F.Weekly_schedule_ID = Weekly_schedule.ID
    
    LEFT JOIN Flight F2
    ON F2.Flight_number = F.Flight_number;
    
###################################################
###########   Theoretical Questions   #############
###################################################

/*
Question 8

a) How can you protect the credit card information in the database from hackers?
	
	The credit card information should be stored as hashed values in the database using some sort of strong encryption. 
	Moreover it is important to protect the database against SQL-injection. (This applies to the database as o whole. 
	Not only regarding credit card information).
    
b) Give three advantages of using stored procedures in the database (and thereby execute them on the server) 
   instead of writing the same functions in the front- end of the system (in for example java-script on a web-page)?
   
	1. Stored procedures offer higher perfomance due to the procedures only having to compile once. 
	   These can then be executed more quickly and efficiently compared to front-end functions, 
	   which increases response time.
	2. Stored procedures also offer better scalability since everything is done on server.
	3. Furthermore stored procedures offer easier maintainability since everything is stored in one location, 
	   instead of being stored on different clients.

--------------------------------------------------------------------------------------------------------------------------------

Question 9

Open two MySQL sessions. We call one of them A and the other one B. Write START TRANSACTION; in both terminals

a) In session A, add a new reservation.

	-- SELECT "Step2, add a bunch of bookings to the flights" AS "Message";
	-- CALL addReservation("MIT","HOB",2010,1,"Monday","09:00:00",3,@a);

b) Is this reservation visible in session B? Why? Why not?

	No, it is not visable since querys in Session A is done in its own transaction. This is not visible in Session B until it has 
	been commited. Once commited it will be visable.

c) What happens if you try to modify the reservation from A in B? Explain what happens and why this happens and how this relates 
   to the concept of isolation of transactions.
   
   If we try to modify the reservation from A in B the query stalls. From B we know that we cannot see the tuple we want to modify, 
   since this is done in its own transaction. This also implies that we can't modify it. It's only when transacton A has been commited, 
   we can see and modify the tuple through Session B. This is due to the principle of isolation.

--------------------------------------------------------------------------------------------------------------------------------

Question 10

Is your BryanAir implementation safe when handling multiple concurrent transactions? Let two customers try to simultaneously 
book more seats than what are available on a flight and see what happens. This is tested by executing the testscripts available 
on the course-page using two different MySQL sessions. Note that you should not use explicit transaction control unless this is 
your solution on 10c.

a) Did overbooking occur when the scripts were executed? If so, why? If not, why not?

	No, no overbooking occured. One of the sessions was started slightly ahead and therefore one of the sessions succeded
    and the other one got the message that there were not enough seats.

b) Can an overbooking theoretically occur? If an overbooking is possible, in what order must the lines of code in your 
   procedures/functions be executed.
   
	Yes this could theoreticaly occur in addPayment if both sessions read the IF-statement that checks free seats 
	before the booking table is updated. 
    
		CODE:
        
		IF (nr_of_passengers_in_reservation <= calculateFreeSeats(current_flight_nr)) THEN             
					INSERT INTO Credit_card(Card_number, Card_holder, Reservation_number)
					VALUES (credit_card_number, cardholder_name, reservation_nr);
					
					INSERT INTO Booking(Booking_number, Credit_card_number, Price)
					VALUES (reservation_nr, credit_card_number, calculatePrice(current_flight_nr));
	   
c) Try to make the theoretical case occur in reality by simulating that multiple sessions call the procedure at the same time. 
   To specify the order in which the lines of code are executed use the MySQL query SELECT sleep(5); which makes the session sleep 
   for 5 seconds. Note that it is not always possible to make the theoretical case occur, if not, motivate why.
   
	CODE:
        
		IF (nr_of_passengers_in_reservation <= calculateFreeSeats(current_flight_nr)) THEN             
					INSERT INTO Credit_card(Card_number, Card_holder, Reservation_number)
					VALUES (credit_card_number, cardholder_name, reservation_nr);
					
                    SELECT SLEEP(5);
                    
					INSERT INTO Booking(Booking_number, Credit_card_number, Price)
					VALUES (reservation_nr, credit_card_number, calculatePrice(current_flight_nr));
           
	By implementing a sleep as the code shows above, the theoretical case can occur. 

d) Modify the testscripts so that overbookings are no longer possible using (some of) the commands START TRANSACTION, 
   COMMIT, LOCK TABLES, UNLOCK TABLES, ROLLBACK, SAVEPOINT, and SELECT...FOR UPDATE. Motivate why your solution solves 
   the issue, and test that this also is the case using the sleep implemented in 10c. Note that it is not ok that one 
   of the sessions ends up in a deadlock scenario. Also, try to hold locks on the common resources for as short time as 
   possible to allow multiple sessions to be active at the same time.

	CODE:
    
		CALL addContact(@a,00000001,"saruman@magic.mail",080667989); 
		SELECT SLEEP(5);
		SELECT "Making payment, supposed to work for one session and be denied for the other" as "Message";

		START TRANSACTION;
		LOCK TABLES
		Flight READ,
		Reservation READ,
		Credit_card WRITE,
		Passenger_reservation READ,
		Booking WRITE,
		Ticket WRITE,
		Route READ,
		Weekly_schedule READ,
		Day_of_week READ,
		Year READ;

		CALL addPayment (@a, "Sauron",7878787877);
        
        
	The above code locks the necessary tables which addPayment either writes to or reads from. This allows the first session 
	to complete before the second session can execute and therefore preventing overbooking. 
    
*/