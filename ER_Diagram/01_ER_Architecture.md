# BooknPlay — Architecture & Design Reference

## 1. Data Models and Relationships

### Entity Descriptions

| Entity | Service Owner | Description |
|---|---|---|
| USER | User Service | All registered users (customers, turf owners, admins) |
| TURF | Turf Service | Sports facility listings |
| TURF_SPORT | Turf Service | Sports types offered by a turf with pricing |
| TURF_SCHEDULE | Turf Service | Operating hours and slot durations per day |
| ONBOARDING_REQUEST | Turf Service | Admin review workflow for new turf listings |
| BOOKING | Booking Service | Customer slot reservations |
| PAYMENT | Payment Service | Payment records linked to bookings |
| NOTIFICATION | Notification Service | All outbound notification records |

### Relationships

- USER (1) → (N) TURF: A turf owner can own many turfs
- USER (1) → (N) BOOKING: A customer can make many bookings
- USER (1) → (N) NOTIFICATION: A user receives many notifications
- TURF (1) → (N) TURF_SPORT: A turf offers multiple sports
- TURF (1) → (N) TURF_SCHEDULE: A turf has schedules for each day
- TURF (1) → (N) ONBOARDING_REQUEST: Admin onboarding workflow
- BOOKING (1) → (1) PAYMENT: Each booking has one payment record
- TURF_SPORT (1) → (N) BOOKING: A sport type can be booked many times

---

## 2. DDL — Database Schema

```sql
-- ============================================================
-- USER SERVICE DATABASE
-- ============================================================
CREATE TABLE users (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username      VARCHAR(50)  NOT NULL UNIQUE,
    email         VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    role          VARCHAR(20)  NOT NULL CHECK (role IN ('CUSTOMER','TURF_OWNER','ADMIN')),
    phone         VARCHAR(15),
    is_active     BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_users_email  ON users(email);
CREATE INDEX idx_users_role   ON users(role);
CREATE INDEX idx_users_active ON users(is_active);

-- ============================================================
-- TURF SERVICE DATABASE
-- ============================================================
CREATE TABLE turfs (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id    UUID         NOT NULL,   -- FK to users.id (cross-service, enforced in app layer)
    name        VARCHAR(100) NOT NULL,
    description TEXT,
    address     TEXT         NOT NULL,
    city        VARCHAR(60)  NOT NULL,
    state       VARCHAR(60)  NOT NULL,
    latitude    DECIMAL(9,6) NOT NULL,
    longitude   DECIMAL(9,6) NOT NULL,
    status      VARCHAR(20)  NOT NULL CHECK (status IN ('PENDING','ACTIVE','REJECTED','SUSPENDED')),
    created_at  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_turfs_owner_id ON turfs(owner_id);
CREATE INDEX idx_turfs_status   ON turfs(status);
CREATE INDEX idx_turfs_location ON turfs(latitude, longitude);

CREATE TABLE turf_sports (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    turf_id         UUID           NOT NULL REFERENCES turfs(id) ON DELETE CASCADE,
    sport_type      VARCHAR(50)    NOT NULL,
    base_price      DECIMAL(10,2)  NOT NULL,
    weekend_price   DECIMAL(10,2)  NOT NULL,
    peak_price      DECIMAL(10,2)  NOT NULL,
    UNIQUE (turf_id, sport_type)
);
CREATE INDEX idx_turf_sports_turf_id ON turf_sports(turf_id);

CREATE TABLE turf_schedules (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    turf_id             UUID        NOT NULL REFERENCES turfs(id) ON DELETE CASCADE,
    day_of_week         VARCHAR(10) NOT NULL CHECK (day_of_week IN ('MON','TUE','WED','THU','FRI','SAT','SUN')),
    open_time           TIME        NOT NULL,
    close_time          TIME        NOT NULL,
    slot_duration_mins  INT         NOT NULL DEFAULT 60,
    UNIQUE (turf_id, day_of_week)
);
CREATE INDEX idx_schedules_turf_id ON turf_schedules(turf_id);

CREATE TABLE onboarding_requests (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id         UUID        NOT NULL,
    turf_id          UUID        NOT NULL REFERENCES turfs(id),
    status           VARCHAR(20) NOT NULL CHECK (status IN ('PENDING','APPROVED','REJECTED','EXPIRED')),
    rejection_reason TEXT,
    submitted_at     TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    reviewed_at      TIMESTAMP,
    expires_at       TIMESTAMP   NOT NULL,
    reviewer_id      UUID
);
CREATE INDEX idx_onboarding_owner_id ON onboarding_requests(owner_id);
CREATE INDEX idx_onboarding_status   ON onboarding_requests(status);
CREATE INDEX idx_onboarding_expires  ON onboarding_requests(expires_at);

-- ============================================================
-- BOOKING SERVICE DATABASE
-- ============================================================
CREATE TABLE bookings (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id     UUID           NOT NULL,
    turf_id         UUID           NOT NULL,
    turf_sport_id   UUID           NOT NULL,
    booking_date    DATE           NOT NULL,
    start_time      TIME           NOT NULL,
    end_time        TIME           NOT NULL,
    total_amount    DECIMAL(10,2)  NOT NULL,
    status          VARCHAR(20)    NOT NULL CHECK (status IN ('PENDING','CONFIRMED','CANCELLED','COMPLETED','EXPIRED')),
    created_at      TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_bookings_customer_id   ON bookings(customer_id);
CREATE INDEX idx_bookings_turf_id       ON bookings(turf_id);
CREATE INDEX idx_bookings_booking_date  ON bookings(booking_date);
CREATE INDEX idx_bookings_status        ON bookings(status);
CREATE UNIQUE INDEX idx_bookings_slot ON bookings(turf_id, turf_sport_id, booking_date, start_time)
    WHERE status NOT IN ('CANCELLED','EXPIRED');

-- ============================================================
-- PAYMENT SERVICE DATABASE
-- ============================================================
CREATE TABLE payments (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_id      UUID           NOT NULL UNIQUE,
    payment_method  VARCHAR(20)    NOT NULL CHECK (payment_method IN ('CREDIT_CARD','WALLET','UPI')),
    amount          DECIMAL(10,2)  NOT NULL,
    status          VARCHAR(20)    NOT NULL CHECK (status IN ('INITIATED','SUCCESS','FAILED','REFUNDED','PENDING')),
    transaction_ref VARCHAR(100),
    paid_at         TIMESTAMP,
    created_at      TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_payments_booking_id ON payments(booking_id);
CREATE INDEX idx_payments_status     ON payments(status);

-- ============================================================
-- NOTIFICATION SERVICE DATABASE
-- ============================================================
CREATE TABLE notifications (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id    UUID         NOT NULL,
    type       VARCHAR(30)  NOT NULL,  -- BOOKING_CONFIRMED, PAYMENT_SUCCESS, etc.
    channel    VARCHAR(10)  NOT NULL CHECK (channel IN ('EMAIL','SMS')),
    subject    VARCHAR(255),
    message    TEXT         NOT NULL,
    is_sent    BOOLEAN      NOT NULL DEFAULT FALSE,
    sent_at    TIMESTAMP,
    created_at TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_is_sent ON notifications(is_sent);
```

---

## 3. System Components

| Component | Technology | Responsibility |
|---|---|---|
| API Gateway | Spring Cloud Gateway | Single entry point, JWT filter, routing, rate limiting |
| Eureka Server | Spring Cloud Netflix | Service registry and discovery |
| User Service | Spring Boot | Auth, registration, profile, JWT issuance |
| Turf Service | Spring Boot | Onboarding, listings, pricing, schedules |
| Booking Service | Spring Boot | Slot search, availability, booking lifecycle |
| Payment Service | Spring Boot | Payment simulation, status tracking |
| Notification Service | Spring Boot | Email/SMS dispatch, event-driven |
| Message Broker | RabbitMQ / Kafka | Async event routing between services |
| Redis | Redis | Caching turf data, availability, session tokens |
| PostgreSQL | PostgreSQL (per service) | Primary RDBMS, one DB per microservice |
| Swagger UI | SpringDoc OpenAPI 3 | Interactive API documentation |
| Spring Scheduler | Spring @Scheduled | Auto-cancel, onboarding expiry, reminders |

---

## 4. Maven Project Structure

```
booknplay/
├── eureka-server/                      # Port 8761
├── api-gateway/                        # Port 8080
├── user-service/                       # Port 8081
├── turf-service/                       # Port 8082
├── booking-service/                    # Port 8083
├── payment-service/                    # Port 8084
├── notification-service/               # Port 8085
└── common-lib/                         # Shared DTOs, exceptions, response wrapper
```

Each service uses the same package root: `com.booknplay.<service>`

```
com.booknplay.userservice/
├── config/          # Security, Swagger, WebClient beans
├── controller/      # REST controllers
├── service/         # Business logic interfaces + impls
├── repository/      # Spring Data JPA repositories
├── entity/          # JPA entities
├── dto/             # Request/Response DTOs
├── mapper/          # MapStruct mappers
├── exception/       # Custom exceptions + global handler
├── event/           # Domain event classes
├── scheduler/       # @Scheduled tasks
└── util/            # Utility/helper classes
```

