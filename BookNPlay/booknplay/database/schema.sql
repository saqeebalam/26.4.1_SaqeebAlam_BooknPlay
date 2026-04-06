-- ============================================================
-- USER SERVICE DATABASE
-- ============================================================

create database bookNPlay;

use bookNPlay;

CREATE TABLE users (
    user_id 	  INT AUTO_INCREMENT PRIMARY KEY,
    username      VARCHAR(50)  NOT NULL UNIQUE,
    email         VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    first_name	  VARCHAR(255),
    last_name	  VARCHAR(255),
	phone         VARCHAR(15),
    role          ENUM('CUSTOMER','TURF_OWNER','ADMIN') NOT NULL,
    is_active     BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE INDEX idx_users_email  ON users(email);
CREATE INDEX idx_users_role   ON users(role);
CREATE INDEX idx_users_active ON users(is_active);

-- ============================================================
-- TURF SERVICE DATABASE
-- ============================================================
CREATE TABLE turf (
    turf_id     INT AUTO_INCREMENT PRIMARY KEY,
    name        VARCHAR(100) NOT NULL,
    address     TEXT NOT NULL,
    latitude    DECIMAL(9,6) NOT NULL,
    longitude   DECIMAL(9,6) NOT NULL,
    description TEXT,
    created_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    is_active     BOOLEAN      NOT NULL DEFAULT TRUE
);

CREATE INDEX idx_turf_owner_id ON turfs(owner_id);
CREATE INDEX idx_turf_status   ON turfs(status);
CREATE INDEX idx_turf_location ON turfs(latitude, longitude);

CREATE TABLE turf_sports (
    id            BINARY(16) PRIMARY KEY DEFAULT (UUID_TO_BIN(UUID())),
    turf_id       BINARY(16) NOT NULL,
    sport_type    VARCHAR(50) NOT NULL,
    base_price    DECIMAL(10,2) NOT NULL,
    weekend_price DECIMAL(10,2) NOT NULL,
    peak_price    DECIMAL(10,2) NOT NULL,

    UNIQUE (turf_id, sport_type),

    FOREIGN KEY (turf_id) REFERENCES turfs(id) ON DELETE CASCADE
);

CREATE INDEX idx_turf_sports_turf_id ON turf_sports(turf_id);

CREATE TABLE turf_schedules (
    id                  BINARY(16) PRIMARY KEY DEFAULT (UUID_TO_BIN(UUID())),
    turf_id             BINARY(16) NOT NULL,
    day_of_week         ENUM('MON','TUE','WED','THU','FRI','SAT','SUN') NOT NULL,
    open_time           TIME NOT NULL,
    close_time          TIME NOT NULL,
    slot_duration_mins  INT NOT NULL DEFAULT 60,

    UNIQUE (turf_id, day_of_week),

    FOREIGN KEY (turf_id) REFERENCES turfs(id) ON DELETE CASCADE
);

CREATE INDEX idx_schedules_turf_id ON turf_schedules(turf_id);

CREATE TABLE onboarding_requests (
    id               BINARY(16) PRIMARY KEY DEFAULT (UUID_TO_BIN(UUID())),
    owner_id         BINARY(16) NOT NULL,
    turf_id          BINARY(16) NOT NULL,
    status           ENUM('PENDING','APPROVED','REJECTED','EXPIRED') NOT NULL,
    rejection_reason TEXT,
    submitted_at     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    reviewed_at      TIMESTAMP NULL,
    expires_at       TIMESTAMP NOT NULL,
    reviewer_id      BINARY(16),

    FOREIGN KEY (turf_id) REFERENCES turfs(id)
);

CREATE INDEX idx_onboarding_owner_id ON onboarding_requests(owner_id);
CREATE INDEX idx_onboarding_status   ON onboarding_requests(status);
CREATE INDEX idx_onboarding_expires  ON onboarding_requests(expires_at);

-- ============================================================
-- BOOKING SERVICE DATABASE
-- ============================================================
CREATE TABLE bookings (
    id              BINARY(16) PRIMARY KEY DEFAULT (UUID_TO_BIN(UUID())),
    customer_id     BINARY(16) NOT NULL,
    turf_id         BINARY(16) NOT NULL,
    turf_sport_id   BINARY(16) NOT NULL,
    booking_date    DATE NOT NULL,
    start_time      TIME NOT NULL,
    end_time        TIME NOT NULL,
    total_amount    DECIMAL(10,2) NOT NULL,
    status          ENUM('PENDING','CONFIRMED','CANCELLED','COMPLETED','EXPIRED') NOT NULL,
    created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE INDEX idx_bookings_customer_id  ON bookings(customer_id);
CREATE INDEX idx_bookings_turf_id      ON bookings(turf_id);
CREATE INDEX idx_bookings_booking_date ON bookings(booking_date);
CREATE INDEX idx_bookings_status       ON bookings(status);

/* MySQL DOES NOT support partial index (WHERE clause)
   So enforce this in application logic OR use trigger */
CREATE UNIQUE INDEX idx_bookings_slot 
ON bookings(turf_id, turf_sport_id, booking_date, start_time);

-- ============================================================
-- PAYMENT SERVICE DATABASE
-- ============================================================
CREATE TABLE payments (
    id              BINARY(16) PRIMARY KEY DEFAULT (UUID_TO_BIN(UUID())),
    booking_id      BINARY(16) NOT NULL UNIQUE,
    payment_method  ENUM('CREDIT_CARD','WALLET','UPI') NOT NULL,
    amount          DECIMAL(10,2) NOT NULL,
    status          ENUM('INITIATED','SUCCESS','FAILED','REFUNDED','PENDING') NOT NULL,
    transaction_ref VARCHAR(100),
    paid_at         TIMESTAMP NULL,
    created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE INDEX idx_payments_booking_id ON payments(booking_id);
CREATE INDEX idx_payments_status     ON payments(status);

-- ============================================================
-- NOTIFICATION SERVICE DATABASE
-- ============================================================
CREATE TABLE notifications (
    id         BINARY(16) PRIMARY KEY DEFAULT (UUID_TO_BIN(UUID())),
    user_id    BINARY(16) NOT NULL,
    type       VARCHAR(30) NOT NULL,
    channel    ENUM('EMAIL','SMS') NOT NULL,
    subject    VARCHAR(255),
    message    TEXT NOT NULL,
    is_sent    BOOLEAN NOT NULL DEFAULT FALSE,
    sent_at    TIMESTAMP NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_is_sent ON notifications(is_sent);