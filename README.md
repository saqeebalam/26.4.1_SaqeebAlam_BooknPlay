# 🏟️ BooknPlay - Microservices Sports Booking Platform

## 📌 Overview

**BooknPlay** is a microservices-based sports facility booking platform that allows users to discover, book, and manage sports turfs. Turf owners can onboard and manage their facilities, while admins oversee approvals and governance.

This project is designed using **Spring Boot Microservices Architecture** with industry-standard practices like API Gateway, Service Discovery, Event-Driven Communication, and Caching.

---

## 🏗️ Architecture

The system follows a **Microservices Architecture** with the following components:

* **API Gateway** – Central entry point for all client requests
* **Service Registry (Eureka)** – Dynamic service discovery
* **Independent Microservices** – User, Turf, Booking, Payment, Notification
* **Message Broker** – Asynchronous communication (Kafka/RabbitMQ)
* **Cache Layer** – Redis for performance optimization
* **Database** – MySQL (separate DB per service)

---

## 📦 Microservices

| Service              | Description                      | Port |
| -------------------- | -------------------------------- | ---- |
| Eureka Server        | Service Registry                 | 8761 |
| API Gateway          | Routing & Security               | 8080 |
| User Service         | Authentication & User Management | 8081 |
| Turf Service         | Turf Onboarding & Management     | 8082 |
| Booking Service      | Slot Booking & Availability      | 8083 |
| Payment Service      | Payment Processing               | 8084 |
| Notification Service | Email/SMS Notifications          | 8085 |

---

## 🧩 Project Structure

```
booknplay/
├── common-lib/
├── eureka-server/
├── api-gateway/
├── user-service/
├── turf-service/
├── booking-service/
├── payment-service/
├── notification-service/
├── docs/
├── database/
└── pom.xml
```

---

## 🗄️ Database Design

* Designed using normalized relational schema

* Includes entities like:

  * User
  * Turf
  * Turf Slot
  * Booking
  * Payment
  * Notification

* Prevents double booking using **slot-based design**

* Optimized with **indexes and foreign keys**

---

## 🔄 Communication

### 🔹 Synchronous

* REST APIs using:

  * Feign Client
  * WebClient

### 🔹 Asynchronous

* Event-driven architecture using:

  * Kafka / RabbitMQ

---

## ⚡ Features

* ✅ JWT Authentication & Role-based Access
* ✅ Turf Search with Filters (location, sport, price)
* ✅ Real-time Slot Booking
* ✅ Dynamic Pricing (weekend/peak hours)
* ✅ Async Notifications (Email/SMS)
* ✅ Redis Caching for performance
* ✅ Scheduler for auto-expiry & reminders
* ✅ Standard API Response format
* ✅ Global Exception Handling
* ✅ Pagination support for GET APIs

---

## 🔐 Security

* JWT-based authentication
* Role-based authorization:

  * CUSTOMER
  * TURF_OWNER
  * ADMIN
* Input validation using annotations

---

## 📘 API Documentation

* Swagger/OpenAPI integration (planned per service)
* Provides interactive API testing

---

## 🧪 Testing

* Unit testing using:

  * JUnit
  * Mockito
* Covers:

  * Positive scenarios
  * Negative scenarios
  * Edge cases

---

## 🐳 Setup Instructions

### 🔹 Prerequisites

* Java 17+
* Maven
* MySQL
* Redis
* Kafka / RabbitMQ (optional)

---

### 🔹 Steps to Run

1. Clone repository

```
git clone <repo-url>
cd booknplay
```

2. Build project

```
mvn clean install
```

3. Start services in order:

```
1. Eureka Server
2. API Gateway
3. Other Microservices
```

4. Access Eureka Dashboard:

```
http://localhost:8761
```

---

## 📂 Additional Resources

* `docs/` → Architecture & design documents
* `database/` → SQL schema & scripts

---

## 📈 Future Enhancements

* Kubernetes Deployment
* CI/CD Pipeline
* Advanced Search (Geo-based)
* Real Payment Integration
* Mobile App Integration

---

## 👨‍💻 Author

**BooknPlay Project**
Designed for learning and demonstrating real-world microservices architecture.

---

## ⭐ Notes

This project follows best practices in:

* Clean Code
* Design Patterns
* Scalable Architecture
* Modular Development
