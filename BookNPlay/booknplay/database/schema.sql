-- ============================================================
-- USER SERVICE DATABASE
-- ============================================================

create database bookNPlay;

use bookNPlay;

CREATE TABLE users (
    user_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    phone VARCHAR(15),
    role ENUM('CUSTOMER','TURF_OWNER','ADMIN') NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_users_active ON users(is_active);

-- ============================================================
-- TURF SERVICE DATABASE
-- ============================================================
CREATE TABLE turf (
    turf_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    owner_id BIGINT NOT NULL,
    name VARCHAR(100) NOT NULL,
    address TEXT NOT NULL,
    latitude DECIMAL(9,6) NOT NULL,
    longitude DECIMAL(9,6) NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (owner_id) REFERENCES users(user_id)
);

CREATE INDEX idx_turf_owner ON turf(owner_id);
CREATE INDEX idx_turf_location ON turf(latitude, longitude);
CREATE INDEX idx_turf_active ON turf(is_active);

CREATE TABLE turf_sports (
    turf_sport_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    turf_id BIGINT NOT NULL,
    sport_type VARCHAR(50) NOT NULL,
    base_price DECIMAL(10,2) NOT NULL,
    weekend_price DECIMAL(10,2) DEFAULT 0,
    peak_price DECIMAL(10,2) DEFAULT 0,

    UNIQUE (turf_id, sport_type),

    FOREIGN KEY (turf_id) REFERENCES turf(turf_id) ON DELETE CASCADE
);

CREATE INDEX idx_turf_sports_turf_id ON turf_sports(turf_id);

CREATE TABLE turf_schedules (
    schedule_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    turf_id BIGINT NOT NULL,
    day_of_week ENUM('MON','TUE','WED','THU','FRI','SAT','SUN') NOT NULL,
    open_time TIME NOT NULL,
    close_time TIME NOT NULL,
    slot_duration_mins INT DEFAULT 60,

    UNIQUE (turf_id, day_of_week),

    FOREIGN KEY (turf_id) REFERENCES turf(turf_id) ON DELETE CASCADE
);

CREATE INDEX idx_schedule_turf ON turf_schedules(turf_id);

CREATE TABLE onboarding_requests (
    request_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    owner_id BIGINT NOT NULL,
    turf_id BIGINT,
    status ENUM('PENDING','APPROVED','REJECTED','EXPIRED') NOT NULL,
    rejection_reason TEXT,
    submitted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    reviewed_at TIMESTAMP NULL,
    expires_at TIMESTAMP NOT NULL,
    reviewer_id BIGINT,

    FOREIGN KEY (owner_id) REFERENCES users(user_id),
    FOREIGN KEY (turf_id) REFERENCES turf(turf_id),
    FOREIGN KEY (reviewer_id) REFERENCES users(user_id)
);

CREATE INDEX idx_onboarding_owner ON onboarding_requests(owner_id);
CREATE INDEX idx_onboarding_status ON onboarding_requests(status);
CREATE INDEX idx_onboarding_expiry ON onboarding_requests(expires_at);

-- ============================================================
-- BOOKING SERVICE DATABASE
-- ============================================================
CREATE TABLE bookings (
    booking_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    customer_id BIGINT NOT NULL,
    turf_id BIGINT NOT NULL,
    turf_sport_id BIGINT NOT NULL,
    booking_date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    total_amount DECIMAL(10,2) NOT NULL,
    status ENUM('PENDING','CONFIRMED','CANCELLED','COMPLETED','EXPIRED') NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (customer_id) REFERENCES users(user_id),
    FOREIGN KEY (turf_id) REFERENCES turf(turf_id),
    FOREIGN KEY (turf_sport_id) REFERENCES turf_sports(turf_sport_id)
);

-- Prevent double booking
CREATE UNIQUE INDEX idx_booking_slot 
ON bookings(turf_id, turf_sport_id, booking_date, start_time);

-- Performance indexes
CREATE INDEX idx_booking_user ON bookings(customer_id);
CREATE INDEX idx_booking_date ON bookings(booking_date);
CREATE INDEX idx_booking_status ON bookings(status);
CREATE INDEX idx_booking_user_status ON bookings(customer_id, status);

-- ============================================================
-- PAYMENT SERVICE DATABASE
-- ============================================================
CREATE TABLE payments (
    payment_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    booking_id BIGINT NOT NULL UNIQUE,
    payment_method ENUM('CREDIT_CARD','WALLET','UPI') NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    status ENUM('PENDING','SUCCESS','FAILED','REFUNDED') NOT NULL,
    transaction_ref VARCHAR(100),
    paid_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (booking_id) REFERENCES bookings(booking_id)
);

CREATE INDEX idx_payment_status ON payments(status);

-- ============================================================
-- NOTIFICATION SERVICE DATABASE
-- ============================================================
CREATE TABLE notifications (
    notification_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    type VARCHAR(30) NOT NULL,
    channel ENUM('EMAIL','SMS') NOT NULL,
    subject VARCHAR(255),
    message TEXT NOT NULL,
    is_sent BOOLEAN DEFAULT FALSE,
    sent_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

CREATE INDEX idx_notification_user ON notifications(user_id);
CREATE INDEX idx_notification_status ON notifications(is_sent);
CREATE INDEX idx_notification_user_sent ON notifications(user_id, is_sent);