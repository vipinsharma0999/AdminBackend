-- Create the database
CREATE DATABASE IF NOT EXISTS donation_system;

-- Use the newly created database
USE donation_system;

-- Create the roles table
CREATE TABLE roles (
    role_id INT AUTO_INCREMENT PRIMARY KEY,
    role_name VARCHAR(50) UNIQUE NOT NULL
);

-- Create the users table
CREATE TABLE users (
    user_id VARCHAR(100) PRIMARY KEY,
    first_name VARCHAR(255) NOT NULL,
    last_name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE,
    contact VARCHAR(15) UNIQUE NOT NULL,
    address TEXT NOT NULL,
    pan_card VARCHAR(10),
    is_verified BOOLEAN DEFAULT FALSE,
    role_id INT,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (role_id) REFERENCES roles(role_id)
);

-- Create the user authentication table
CREATE TABLE user_auth (
    user_id VARCHAR(100) PRIMARY KEY,
    password_hash VARCHAR(255) NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

-- Create the user tokens table
CREATE TABLE user_tokens (
    user_id VARCHAR(100),
    token VARCHAR(255) NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

-- Create the donation purposes table
CREATE TABLE donation_purposes (
    purpose_id INT AUTO_INCREMENT PRIMARY KEY,
    purpose_name VARCHAR(255) UNIQUE NOT NULL
);

-- Create the slots table
CREATE TABLE slots (
    slot_id INT AUTO_INCREMENT PRIMARY KEY,
    purpose_id INT,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    FOREIGN KEY (purpose_id) REFERENCES donation_purposes(purpose_id)
);

-- Create the donations table
CREATE TABLE donations (
    donation_id VARCHAR(100) PRIMARY KEY,
    user_id VARCHAR(100),
    transaction_id VARCHAR(100),
    amount DECIMAL(10, 2) NOT NULL,
    donation_time DATETIME NOT NULL,
    purpose_id INT,
    referral_id VARCHAR(100),
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (purpose_id) REFERENCES donation_purposes(purpose_id),
    FOREIGN KEY (referral_id) REFERENCES users(user_id)
);

-- Create the bookings table
CREATE TABLE bookings (
    booking_id VARCHAR(100) PRIMARY KEY,
    donation_id VARCHAR(100),
    user_id VARCHAR(100),
    slot_id INT,
    booking_time DATETIME NOT NULL,
    is_completed BOOLEAN DEFAULT FALSE,
    completion_time DATETIME,
    FOREIGN KEY (donation_id) REFERENCES donations(donation_id),
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (slot_id) REFERENCES slots(slot_id)
);

-- Create the feedback table
CREATE TABLE feedback (
    feedback_id VARCHAR(100) PRIMARY KEY,
    booking_id VARCHAR(100),
    rating INT NOT NULL,
    comments TEXT,
    FOREIGN KEY (booking_id) REFERENCES bookings(booking_id)
);

-- Create the queries table
CREATE TABLE queries (
    query_id VARCHAR(100) PRIMARY KEY,
    contact VARCHAR(15) NOT NULL,
    query_text TEXT NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Create the otp table
CREATE TABLE otp (
    otp_id VARCHAR(100) PRIMARY KEY,
    user_id VARCHAR(100),
    otp_code VARCHAR(6) NOT NULL,
    expiration DATETIME NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);


DELIMITER //

CREATE PROCEDURE GetDonationsAndBookingsReport(IN startDate DATETIME, IN endDate DATETIME)
BEGIN
    -- Declare variables to hold results
    DECLARE userCount INT;
    DECLARE bookingCount INT;
    DECLARE totalDonation DECIMAL(10, 2);
    
    -- Get the number of users who registered within the date range
    SELECT COUNT(*) INTO userCount
    FROM users
    WHERE created_at BETWEEN startDate AND endDate;

    -- Get the number of bookings within the date range
    SELECT COUNT(*) INTO bookingCount
    FROM bookings
    WHERE booking_time BETWEEN startDate AND endDate;

    -- Get the total donation amount within the date range
    SELECT SUM(amount) INTO totalDonation
    FROM donations
    WHERE donation_time BETWEEN startDate AND endDate;

    -- Output the results
    SELECT 
        userCount AS 'Number of Users Registered',
        bookingCount AS 'Number of Bookings',
        totalDonation AS 'Total Donation Amount';

    -- Get the referral statistics
    SELECT 
        u.user_id,
        CONCAT(u.first_name, ' ', u.last_name) AS 'User Name',
        COUNT(d.referral_id) AS 'Number of Referrals',
        IFNULL(SUM(d.amount), 0) AS 'Total Referral Donations'
    FROM users u
    LEFT JOIN donations d ON u.user_id = d.referral_id
    WHERE d.donation_time BETWEEN startDate AND endDate
    GROUP BY u.user_id
    ORDER BY 'Total Referral Donations' DESC;

END //

DELIMITER ;

