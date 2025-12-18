# Code Changes for Rent-a-Wheel Project Migration

## Overview
This document outlines the recommended code changes to migrate the existing Oracle-based monolithic car rental system to a modern microservices architecture with event-driven design and bitemporal database modeling. The changes are based on the schema_diagram.md and interaction_diagram.md specifications.

**Key Architectural Changes:**
- Database migration from Oracle to PostgreSQL (better support for JSON, enums, bitemporal modeling)
- Introduction of microservices pattern with event sourcing
- Implementation of CQRS with read models
- Bitemporal data modeling for audit and temporal queries
- Event-driven architecture using Apache Kafka

**Assumptions:**
- Target database: PostgreSQL 15+
- Message broker: Apache Kafka 3.0+
- Programming language: Java 17 with Spring Boot for services
- Containerization: Docker
- Existing Oracle data will be migrated using ETL scripts

---

## 1. Database Schema Migration (schema_changes.sql)

### File Purpose
Create the new PostgreSQL schema with bitemporal tables, enums, and constraints as specified in schema_diagram.md.

### Step-by-Step Changes

#### 1.1 Create Enums
```sql
-- Define enums for better type safety
CREATE TYPE user_role AS ENUM ('CUSTOMER', 'OWNER', 'ADMIN');
CREATE TYPE admin_level AS ENUM ('TIER1', 'TIER2', 'TIER3');
CREATE TYPE vehicle_category AS ENUM ('ECONOMY', 'COMPACT', 'SEDAN', 'SUV', 'LUXURY');
CREATE TYPE fuel_type AS ENUM ('PETROL', 'DIESEL', 'HYBRID', 'ELECTRIC');
CREATE TYPE availability_status AS ENUM ('AVAILABLE', 'RESERVED', 'RENTED', 'MAINTENANCE');
CREATE TYPE reservation_status AS ENUM ('HOLD', 'CONFIRMED', 'ACTIVE', 'COMPLETED', 'CANCELLED');
CREATE TYPE loyalty_tier AS ENUM ('BRONZE', 'SILVER', 'GOLD', 'PLATINUM');
CREATE TYPE payment_type AS ENUM ('CREDIT_CARD', 'DEBIT_CARD', 'WALLET');
CREATE TYPE transaction_type AS ENUM ('DEPOSIT', 'AUTH', 'CAPTURE', 'REFUND', 'DISPUTE');
CREATE TYPE transaction_status AS ENUM ('PENDING', 'APPROVED', 'FAILED', 'EXPIRED', 'DISPUTED');
CREATE TYPE claim_status AS ENUM ('NO_DAMAGE', 'PENDING', 'APPROVED', 'DISPUTED', 'RESOLVED');
CREATE TYPE operation_type AS ENUM ('INSERT', 'UPDATE', 'DELETE');
```

#### 1.2 Create User Domain Tables
```sql
-- Base user accounts table
CREATE TABLE user_accounts (
    id BIGSERIAL PRIMARY KEY,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role user_role NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Customer-specific data
CREATE TABLE customers (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES user_accounts(id) ON DELETE CASCADE,
    driver_license_token VARCHAR(50),
    date_of_birth DATE,
    license_expiry_date DATE,
    total_rentals INTEGER DEFAULT 0,
    loyalty_tier loyalty_tier DEFAULT 'BRONZE',
    preferred_location_id BIGINT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Fleet owner data
CREATE TABLE fleet_owners (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES user_accounts(id) ON DELETE CASCADE,
    company_name VARCHAR(255) UNIQUE NOT NULL,
    tax_id VARCHAR(50) UNIQUE NOT NULL,
    registration_number VARCHAR(50),
    total_vehicles INTEGER DEFAULT 0,
    total_revenue DECIMAL(15,2) DEFAULT 0,
    primary_location_id BIGINT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Admin data
CREATE TABLE admins (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES user_accounts(id) ON DELETE CASCADE,
    admin_level admin_level NOT NULL,
    department VARCHAR(100),
    can_refund BOOLEAN DEFAULT FALSE,
    can_disable_vehicles BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
```

#### 1.3 Create Location Domain Tables
```sql
CREATE TABLE locations (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    address VARCHAR(255),
    city VARCHAR(100),
    country VARCHAR(100),
    latitude DECIMAL(10,8),
    longitude DECIMAL(11,8),
    max_capacity INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
```

#### 1.4 Create Vehicle Domain Tables
```sql
CREATE TABLE vehicle_types (
    id BIGSERIAL PRIMARY KEY,
    make VARCHAR(50) NOT NULL,
    model VARCHAR(50) NOT NULL,
    transmission_type VARCHAR(50),
    category vehicle_category NOT NULL,
    fuel_type fuel_type NOT NULL,
    seats INTEGER,
    base_hourly_rate DECIMAL(10,2),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE vehicles (
    id BIGSERIAL PRIMARY KEY,
    vehicle_type_id BIGINT NOT NULL REFERENCES vehicle_types(id),
    fleet_owner_id BIGINT NOT NULL REFERENCES fleet_owners(id),
    current_location_id BIGINT REFERENCES locations(id),
    registration_id VARCHAR(50) UNIQUE NOT NULL,
    vin_number VARCHAR(17) UNIQUE NOT NULL,
    availability_status availability_status DEFAULT 'AVAILABLE',
    miles_driven INTEGER DEFAULT 0,
    passenger_capacity INTEGER,
    version INTEGER DEFAULT 1,
    hourly_rate DECIMAL(10,2),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    valid_start_time TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    valid_end_time TIMESTAMP WITH TIME ZONE DEFAULT 'infinity'
);

CREATE TABLE vehicle_rate_history (
    id BIGSERIAL PRIMARY KEY,
    vehicle_type_id BIGINT NOT NULL REFERENCES vehicle_types(id),
    effective_from DATE NOT NULL,
    effective_to DATE,
    base_hourly_rate DECIMAL(10,2) NOT NULL,
    surge_multiplier DECIMAL(3,2) DEFAULT 1.0,
    early_bird_discount DECIMAL(5,2) DEFAULT 0,
    loyalty_discount DECIMAL(5,2) DEFAULT 0,
    version INTEGER DEFAULT 1,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
```

#### 1.5 Create Reservation Domain Tables
```sql
CREATE TABLE insurance_types (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    coverage_amount DECIMAL(10,2) NOT NULL,
    daily_rate DECIMAL(10,2) NOT NULL,
    description TEXT,
    is_mandatory BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE reservations (
    id BIGSERIAL PRIMARY KEY,
    customer_id BIGINT NOT NULL REFERENCES customers(id),
    vehicle_id BIGINT NOT NULL REFERENCES vehicles(id),
    pickup_location_id BIGINT NOT NULL REFERENCES locations(id),
    dropoff_location_id BIGINT NOT NULL REFERENCES locations(id),
    insurance_type_id BIGINT REFERENCES insurance_types(id),
    status reservation_status DEFAULT 'HOLD',
    pickup_date TIMESTAMP WITH TIME ZONE NOT NULL,
    dropoff_date TIMESTAMP WITH TIME ZONE NOT NULL,
    passenger_count INTEGER,
    estimated_charge DECIMAL(10,2),
    final_charge DECIMAL(10,2),
    hold_expires_at TIMESTAMP WITH TIME ZONE,
    confirmed_at TIMESTAMP WITH TIME ZONE,
    version INTEGER DEFAULT 1,
    valid_start_time TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    valid_end_time TIMESTAMP WITH TIME ZONE DEFAULT 'infinity',
    transaction_start_time TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    transaction_end_time TIMESTAMP WITH TIME ZONE DEFAULT 'infinity',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
```

#### 1.6 Create Payment Domain Tables
```sql
CREATE TABLE payment_methods (
    id BIGSERIAL PRIMARY KEY,
    customer_id BIGINT NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    payment_token VARCHAR(100) NOT NULL, -- PCI-DSS tokenized
    last_four_digits VARCHAR(4),
    payment_type payment_type NOT NULL,
    expiration_date DATE NOT NULL,
    billing_address VARCHAR(255),
    is_active BOOLEAN DEFAULT TRUE,
    is_primary BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    valid_start_time TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    valid_end_time TIMESTAMP WITH TIME ZONE DEFAULT 'infinity'
);

CREATE TABLE payment_transactions (
    id BIGSERIAL PRIMARY KEY,
    reservation_id BIGINT REFERENCES reservations(id),
    payment_method_id BIGINT REFERENCES payment_methods(id),
    discount_type_id BIGINT,
    idempotency_key UUID UNIQUE NOT NULL,
    transaction_type transaction_type NOT NULL,
    status transaction_status DEFAULT 'PENDING',
    amount DECIMAL(10,2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'USD',
    approval_code VARCHAR(50),
    gateway_transaction_id VARCHAR(100) UNIQUE,
    version INTEGER DEFAULT 1,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    valid_start_time TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    valid_end_time TIMESTAMP WITH TIME ZONE DEFAULT 'infinity',
    transaction_start_time TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    transaction_end_time TIMESTAMP WITH TIME ZONE DEFAULT 'infinity'
);

CREATE TABLE discount_types (
    id BIGSERIAL PRIMARY KEY,
    code VARCHAR(50) UNIQUE NOT NULL,
    discount_percent DECIMAL(5,2),
    discount_amount DECIMAL(10,2),
    min_eligible_charge DECIMAL(10,2),
    valid_from DATE,
    valid_to DATE,
    max_uses INTEGER,
    uses_count INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
```

#### 1.7 Create Post-Rental Domain Tables
```sql
CREATE TABLE post_rental_inspections (
    id BIGSERIAL PRIMARY KEY,
    reservation_id BIGINT NOT NULL REFERENCES reservations(id),
    inspection_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    vehicle_odometer_start INTEGER,
    vehicle_odometer_end INTEGER,
    distance_driven INTEGER,
    fuel_level_start DECIMAL(5,2),
    fuel_level_end DECIMAL(5,2),
    general_condition VARCHAR(50) DEFAULT 'EXCELLENT',
    damage_description TEXT,
    damage_photos_urls JSONB,
    estimated_damage_cost DECIMAL(10,2),
    claim_status claim_status DEFAULT 'NO_DAMAGE',
    claim_approved_by VARCHAR(100),
    claim_approved_at TIMESTAMP WITH TIME ZONE,
    version INTEGER DEFAULT 1,
    created_by VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
```

#### 1.8 Create Audit & Analytics Tables
```sql
CREATE TABLE events (
    event_id BIGSERIAL PRIMARY KEY,
    event_type VARCHAR(50) NOT NULL,
    aggregate_type VARCHAR(50) NOT NULL,
    aggregate_id BIGINT NOT NULL,
    version INTEGER NOT NULL,
    created_by VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    event_data JSONB NOT NULL,
    metadata JSONB,
    correlation_id UUID NOT NULL
);

CREATE TABLE audit_log (
    audit_id BIGSERIAL PRIMARY KEY,
    table_name VARCHAR(50) NOT NULL,
    record_id BIGINT NOT NULL,
    operation operation_type NOT NULL,
    old_value JSONB,
    new_value JSONB,
    changed_by VARCHAR(100),
    changed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    correlation_id UUID UNIQUE NOT NULL
);

CREATE TABLE availability_index (
    id BIGSERIAL PRIMARY KEY,
    vehicle_id BIGINT NOT NULL REFERENCES vehicles(id),
    location_id BIGINT NOT NULL REFERENCES locations(id),
    available_count INTEGER DEFAULT 0,
    reserved_count INTEGER DEFAULT 0,
    rented_count INTEGER DEFAULT 0,
    last_updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
```

#### 1.9 Create Indexes
```sql
-- Performance indexes
CREATE INDEX idx_reservations_customer_id ON reservations(customer_id);
CREATE INDEX idx_reservations_vehicle_id ON reservations(vehicle_id);
CREATE INDEX idx_reservations_status ON reservations(status);
CREATE INDEX idx_reservations_pickup_date ON reservations(pickup_date);
CREATE INDEX idx_reservations_hold_expires_at ON reservations(hold_expires_at);
CREATE INDEX idx_payment_transactions_idempotency_key ON payment_transactions(idempotency_key);
CREATE INDEX idx_payment_transactions_reservation_id ON payment_transactions(reservation_id);
CREATE INDEX idx_vehicles_availability_status ON vehicles(availability_status);
CREATE INDEX idx_vehicles_current_location_id ON vehicles(current_location_id);
CREATE INDEX idx_events_aggregate_id ON events(aggregate_id);
CREATE INDEX idx_events_correlation_id ON events(correlation_id);
CREATE INDEX idx_audit_log_correlation_id ON audit_log(correlation_id);
```

---

## 2. Microservices Implementation

### 2.1 API Gateway Service (api-gateway/)

#### File: pom.xml
```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0
         http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>3.1.0</version>
        <relativePath/>
    </parent>
    <groupId>com.rentawheel</groupId>
    <artifactId>api-gateway</artifactId>
    <version>1.0.0</version>
    <name>API Gateway</name>
    <description>API Gateway for Rent-a-Wheel microservices</description>

    <properties>
        <java.version>17</java.version>
        <spring-cloud.version>2022.0.3</spring-cloud.version>
    </properties>

    <dependencies>
        <dependency>
            <groupId>org.springframework.cloud</groupId>
            <artifactId>spring-cloud-starter-gateway</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.cloud</groupId>
            <artifactId>spring-cloud-starter-netflix-eureka-client</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-data-redis</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-actuator</artifactId>
        </dependency>
    </dependencies>

    <dependencyManagement>
        <dependencies>
            <dependency>
                <groupId>org.springframework.cloud</groupId>
                <artifactId>spring-cloud-dependencies</artifactId>
                <version>${spring-cloud.version}</version>
                <type>pom</type>
                <scope>import</scope>
            </dependency>
        </dependencies>
    </dependencyManagement>
</project>
```

#### File: src/main/resources/application.yml
```yaml
server:
  port: 8080

spring:
  application:
    name: api-gateway
  cloud:
    gateway:
      routes:
        - id: reservation-service
          uri: lb://reservation-service
          predicates:
            - Path=/api/reservations/**
          filters:
            - RewritePath=/api/reservations/(?<path>.*), /${path}
        - id: payment-service
          uri: lb://payment-service
          predicates:
            - Path=/api/payments/**
          filters:
            - RewritePath=/api/payments/(?<path>.*), /${path}
        - id: inventory-service
          uri: lb://inventory-service
          predicates:
            - Path=/api/inventory/**
          filters:
            - RewritePath=/api/inventory/(?<path>.*), /${path}
      default-filters:
        - DedupeResponseHeader=Access-Control-Allow-Origin Access-Control-Allow-Credentials, RETAIN_FIRST

eureka:
  client:
    service-url:
      defaultZone: http://localhost:8761/eureka/

management:
  endpoints:
    web:
      exposure:
        include: health,info,gateway
```

### 2.2 Reservation Service (reservation-service/)

#### File: src/main/java/com/rentawheel/reservation/ReservationServiceApplication.java
```java
package com.rentawheel.reservation;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.client.discovery.EnableDiscoveryClient;
import org.springframework.kafka.annotation.EnableKafka;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication
@EnableDiscoveryClient
@EnableKafka
@EnableScheduling
public class ReservationServiceApplication {
    public static void main(String[] args) {
        SpringApplication.run(ReservationServiceApplication.class, args);
    }
}
```

#### File: src/main/java/com/rentawheel/reservation/domain/Reservation.java
```java
package com.rentawheel.reservation.domain;

import jakarta.persistence.*;
import lombok.Data;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "reservations")
@Data
@EntityListeners(AuditingEntityListener.class)
public class Reservation {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "customer_id", nullable = false)
    private Long customerId;

    @Column(name = "vehicle_id", nullable = false)
    private Long vehicleId;

    @Column(name = "pickup_location_id", nullable = false)
    private Long pickupLocationId;

    @Column(name = "dropoff_location_id", nullable = false)
    private Long dropoffLocationId;

    @Column(name = "insurance_type_id")
    private Long insuranceTypeId;

    @Enumerated(EnumType.STRING)
    private ReservationStatus status = ReservationStatus.HOLD;

    @Column(name = "pickup_date", nullable = false)
    private LocalDateTime pickupDate;

    @Column(name = "dropoff_date", nullable = false)
    private LocalDateTime dropoffDate;

    @Column(name = "passenger_count")
    private Integer passengerCount;

    @Column(name = "estimated_charge", precision = 10, scale = 2)
    private BigDecimal estimatedCharge;

    @Column(name = "final_charge", precision = 10, scale = 2)
    private BigDecimal finalCharge;

    @Column(name = "hold_expires_at")
    private LocalDateTime holdExpiresAt;

    @Column(name = "confirmed_at")
    private LocalDateTime confirmedAt;

    @Version
    private Integer version = 1;

    @Column(name = "valid_start_time")
    private LocalDateTime validStartTime = LocalDateTime.now();

    @Column(name = "valid_end_time")
    private LocalDateTime validEndTime = LocalDateTime.of(9999, 12, 31, 23, 59, 59);

    @Column(name = "transaction_start_time")
    private LocalDateTime transactionStartTime = LocalDateTime.now();

    @Column(name = "transaction_end_time")
    private LocalDateTime transactionEndTime = LocalDateTime.of(9999, 12, 31, 23, 59, 59);

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
}
```

#### File: src/main/java/com/rentawheel/reservation/service/ReservationService.java
```java
package com.rentawheel.reservation.service;

import com.rentawheel.reservation.domain.Reservation;
import com.rentawheel.reservation.domain.ReservationStatus;
import com.rentawheel.reservation.event.ReservationEventPublisher;
import com.rentawheel.reservation.repository.ReservationRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Slf4j
public class ReservationService {

    private final ReservationRepository reservationRepository;
    private final ReservationEventPublisher eventPublisher;

    @Transactional
    public Reservation createReservationHold(CreateReservationCommand command) {
        // Validate inputs
        validateReservationCommand(command);

        // Create reservation with HOLD status
        Reservation reservation = new Reservation();
        reservation.setCustomerId(command.getCustomerId());
        reservation.setVehicleId(command.getVehicleId());
        reservation.setPickupLocationId(command.getPickupLocationId());
        reservation.setDropoffLocationId(command.getDropoffLocationId());
        reservation.setInsuranceTypeId(command.getInsuranceTypeId());
        reservation.setPickupDate(command.getPickupDate());
        reservation.setDropoffDate(command.getDropoffDate());
        reservation.setPassengerCount(command.getPassengerCount());
        reservation.setEstimatedCharge(command.getEstimatedCharge());
        reservation.setHoldExpiresAt(LocalDateTime.now().plusMinutes(15));
        reservation.setStatus(ReservationStatus.HOLD);

        Reservation saved = reservationRepository.save(reservation);

        // Publish event
        eventPublisher.publishReservationHoldCreated(saved);

        log.info("Created reservation hold: {}", saved.getId());
        return saved;
    }

    @Transactional
    public Reservation confirmReservation(Long reservationId) {
        Reservation reservation = reservationRepository.findById(reservationId)
            .orElseThrow(() -> new RuntimeException("Reservation not found"));

        if (reservation.getStatus() != ReservationStatus.HOLD) {
            throw new IllegalStateException("Reservation is not in HOLD status");
        }

        reservation.setStatus(ReservationStatus.CONFIRMED);
        reservation.setConfirmedAt(LocalDateTime.now());
        reservation.setVersion(reservation.getVersion() + 1);

        Reservation saved = reservationRepository.save(reservation);

        eventPublisher.publishReservationConfirmed(saved);

        log.info("Confirmed reservation: {}", saved.getId());
        return saved;
    }

    @Transactional
    public Reservation completeRental(Long reservationId, CompleteRentalCommand command) {
        Reservation reservation = reservationRepository.findById(reservationId)
            .orElseThrow(() -> new RuntimeException("Reservation not found"));

        if (reservation.getStatus() != ReservationStatus.ACTIVE) {
            throw new IllegalStateException("Reservation is not active");
        }

        reservation.setStatus(ReservationStatus.COMPLETED);
        reservation.setFinalCharge(command.getFinalCharge());
        reservation.setVersion(reservation.getVersion() + 1);

        Reservation saved = reservationRepository.save(reservation);

        eventPublisher.publishRentalCompleted(saved);

        log.info("Completed rental: {}", saved.getId());
        return saved;
    }

    @Scheduled(fixedRate = 60000) // Every minute
    @Transactional
    public void cleanupExpiredHolds() {
        LocalDateTime now = LocalDateTime.now();
        List<Reservation> expiredHolds = reservationRepository
            .findByStatusAndHoldExpiresAtBefore(ReservationStatus.HOLD, now);

        for (Reservation reservation : expiredHolds) {
            reservation.setStatus(ReservationStatus.CANCELLED);
            reservation.setVersion(reservation.getVersion() + 1);
            reservationRepository.save(reservation);

            eventPublisher.publishHoldExpired(reservation);

            log.info("Expired hold for reservation: {}", reservation.getId());
        }
    }

    private void validateReservationCommand(CreateReservationCommand command) {
        // Add validation logic
        if (command.getPickupDate().isAfter(command.getDropoffDate())) {
            throw new IllegalArgumentException("Pickup date must be before dropoff date");
        }
        // Additional validations...
    }
}
```

### 2.3 Event Publishing (reservation-service/src/main/java/com/rentawheel/reservation/event/ReservationEventPublisher.java)
```java
package com.rentawheel.reservation.event;

import com.rentawheel.reservation.domain.Reservation;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Component;

import java.util.UUID;

@Component
@RequiredArgsConstructor
@Slf4j
public class ReservationEventPublisher {

    private final KafkaTemplate<String, Object> kafkaTemplate;

    public void publishReservationHoldCreated(Reservation reservation) {
        ReservationEvent event = ReservationEvent.builder()
            .eventId(UUID.randomUUID())
            .eventType("ReservationHoldCreated")
            .aggregateType("Reservation")
            .aggregateId(reservation.getId())
            .version(reservation.getVersion())
            .createdBy("system")
            .correlationId(UUID.randomUUID())
            .eventData(reservation)
            .build();

        kafkaTemplate.send("reservation-events", event);
        log.info("Published ReservationHoldCreated event for reservation: {}", reservation.getId());
    }

    public void publishReservationConfirmed(Reservation reservation) {
        // Similar implementation
    }

    public void publishRentalCompleted(Reservation reservation) {
        // Similar implementation
    }

    public void publishHoldExpired(Reservation reservation) {
        // Similar implementation
    }
}
```

### 2.4 Docker Configuration

#### File: docker-compose.yml
```yaml
version: '3.8'
services:
  postgres:
    image: postgres:15
    environment:
      POSTGRES_DB: rentawheel
      POSTGRES_USER: rentawheel
      POSTGRES_PASSWORD: password
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./schema_changes.sql:/docker-entrypoint-initdb.d/01-schema.sql

  zookeeper:
    image: confluentinc/cp-zookeeper:7.4.0
    environment:
      ZOOKEEPER_CLIENT_PORT: 2181
      ZOOKEEPER_TICK_TIME: 2000

  kafka:
    image: confluentinc/cp-kafka:7.4.0
    depends_on:
      - zookeeper
    environment:
      KAFKA_BROKER_ID: 1
      KAFKA_ZOOKEEPER_CONNECT: zookeeper:2181
      KAFKA_LISTENER_SECURITY_PROTOCOL_MAP: PLAINTEXT:PLAINTEXT,PLAINTEXT_INTERNAL:PLAINTEXT
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://localhost:9092,PLAINTEXT_INTERNAL://kafka:29092
      KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 1
      KAFKA_TRANSACTION_STATE_LOG_MIN_ISR: 1
      KAFKA_TRANSACTION_STATE_LOG_REPLICATION_FACTOR: 1

  api-gateway:
    build: ./api-gateway
    ports:
      - "8080:8080"
    depends_on:
      - eureka-server
    environment:
      EUREKA_CLIENT_SERVICE_URL_DEFAULTZONE: http://eureka-server:8761/eureka/

  reservation-service:
    build: ./reservation-service
    depends_on:
      - postgres
      - kafka
      - eureka-server
    environment:
      SPRING_DATASOURCE_URL: jdbc:postgresql://postgres:5432/rentawheel
      SPRING_KAFKA_BOOTSTRAP_SERVERS: kafka:29092
      EUREKA_CLIENT_SERVICE_URL_DEFAULTZONE: http://eureka-server:8761/eureka/

  payment-service:
    build: ./payment-service
    depends_on:
      - postgres
      - kafka
      - eureka-server
    environment:
      SPRING_DATASOURCE_URL: jdbc:postgresql://postgres:5432/rentawheel
      SPRING_KAFKA_BOOTSTRAP_SERVERS: kafka:29092
      EUREKA_CLIENT_SERVICE_URL_DEFAULTZONE: http://eureka-server:8761/eureka/

  inventory-service:
    build: ./inventory-service
    depends_on:
      - postgres
      - kafka
      - eureka-server
    environment:
      SPRING_DATASOURCE_URL: jdbc:postgresql://postgres:5432/rentawheel
      SPRING_KAFKA_BOOTSTRAP_SERVERS: kafka:29092
      EUREKA_CLIENT_SERVICE_URL_DEFAULTZONE: http://eureka-server:8761/eureka/

  eureka-server:
    image: springcloud/eureka
    ports:
      - "8761:8761"

volumes:
  postgres_data:
```

---

## 3. Data Migration Scripts

### File: migrate_oracle_to_postgres.py
```python
import cx_Oracle
import psycopg2
import os
from datetime import datetime

# Oracle connection
oracle_conn = cx_Oracle.connect(
    user="cr_app_admin",
    password="BlightPass#111",
    dsn="localhost:1521/ORCL"
)

# PostgreSQL connection
postgres_conn = psycopg2.connect(
    dbname="rentawheel",
    user="rentawheel",
    password="password",
    host="localhost",
    port="5432"
)

def migrate_users():
    """Migrate users from Oracle to PostgreSQL"""
    oracle_cursor = oracle_conn.cursor()
    postgres_cursor = postgres_conn.cursor()

    # Migrate locations first (needed for users)
    oracle_cursor.execute("SELECT id, name FROM locations")
    locations = oracle_cursor.fetchall()

    for location in locations:
        postgres_cursor.execute("""
            INSERT INTO locations (id, name, created_at)
            VALUES (%s, %s, CURRENT_TIMESTAMP)
            ON CONFLICT (id) DO NOTHING
        """, (location[0], location[1]))

    # Migrate users
    oracle_cursor.execute("""
        SELECT id, role, fname, lname, current_location_id,
               driver_license, age, company_name, tax_id
        FROM users
    """)
    users = oracle_cursor.fetchall()

    for user in users:
        user_id, role, fname, lname, location_id, dl, age, company, taxid = user

        # Create user account
        email = f"{fname.lower()}.{lname.lower()}@example.com"  # Generate email
        password_hash = "hashed_password"  # Would hash actual password

        postgres_cursor.execute("""
            INSERT INTO user_accounts (id, email, password_hash, role, created_at)
            VALUES (%s, %s, %s, %s, CURRENT_TIMESTAMP)
        """, (user_id, email, password_hash, role.upper()))

        if role == 'customer':
            postgres_cursor.execute("""
                INSERT INTO customers (user_id, driver_license_token, total_rentals, preferred_location_id)
                VALUES (%s, %s, 0, %s)
            """, (user_id, dl, location_id))
        elif role == 'vendor':
            postgres_cursor.execute("""
                INSERT INTO fleet_owners (user_id, company_name, tax_id, primary_location_id)
                VALUES (%s, %s, %s, %s)
            """, (user_id, company, taxid, location_id))

    postgres_conn.commit()
    oracle_cursor.close()
    postgres_cursor.close()

def migrate_vehicles():
    """Migrate vehicles and related data"""
    # Implementation for vehicles, vehicle_types, etc.
    pass

def migrate_reservations():
    """Migrate existing reservations"""
    # Implementation for reservations migration
    pass

if __name__ == "__main__":
    try:
        migrate_users()
        migrate_vehicles()
        migrate_reservations()
        print("Migration completed successfully")
    except Exception as e:
        print(f"Migration failed: {e}")
        postgres_conn.rollback()
    finally:
        oracle_conn.close()
        postgres_conn.close()
```

---

## 4. Testing and Validation

### File: integration_tests.py
```python
import requests
import time
import pytest

BASE_URL = "http://localhost:8080"

def test_reservation_flow():
    """Test complete reservation flow"""
    # Create reservation hold
    reservation_data = {
        "customerId": 1,
        "vehicleId": 1,
        "pickupLocationId": 1,
        "dropoffLocationId": 2,
        "pickupDate": "2025-12-20T10:00:00Z",
        "dropoffDate": "2025-12-22T10:00:00Z",
        "passengerCount": 4,
        "estimatedCharge": 150.00
    }

    response = requests.post(f"{BASE_URL}/api/reservations", json=reservation_data)
    assert response.status_code == 201
    reservation = response.json()

    # Process payment
    payment_data = {
        "reservationId": reservation["id"],
        "amount": 150.00,
        "paymentMethodId": 1,
        "idempotencyKey": "test-key-123"
    }

    response = requests.post(f"{BASE_URL}/api/payments", json=payment_data)
    assert response.status_code == 200

    # Verify reservation status changed
    response = requests.get(f"{BASE_URL}/api/reservations/{reservation['id']}")
    assert response.json()["status"] == "CONFIRMED"

def test_expired_hold_cleanup():
    """Test that expired holds are cleaned up"""
    # Create hold
    reservation_data = {
        "customerId": 1,
        "vehicleId": 2,
        "pickupLocationId": 1,
        "dropoffLocationId": 2,
        "pickupDate": "2025-12-20T10:00:00Z",
        "dropoffDate": "2025-12-22T10:00:00Z",
        "passengerCount": 2,
        "estimatedCharge": 100.00
    }

    response = requests.post(f"{BASE_URL}/api/reservations", json=reservation_data)
    reservation_id = response.json()["id"]

    # Wait for hold to expire (15 minutes simulated)
    time.sleep(1)  # In real test, would fast-forward time

    # Check status (would be CANCELLED after cleanup job runs)
    response = requests.get(f"{BASE_URL}/api/reservations/{reservation_id}")
    # Assert status is CANCELLED
```

---

## Implementation Order

1. **Database Setup**: Run schema_changes.sql to create PostgreSQL schema
2. **Infrastructure**: Set up Docker containers for PostgreSQL, Kafka, Eureka
3. **Services**: Implement API Gateway first, then Reservation Service
4. **Event Handling**: Add Payment and Inventory services with event consumers
5. **Data Migration**: Migrate existing Oracle data to PostgreSQL
6. **Testing**: Run integration tests to validate end-to-end flows
7. **Monitoring**: Add health checks, metrics, and logging

## Key Considerations for Implementation

- **Idempotency**: All operations must handle duplicate requests gracefully
- **Optimistic Locking**: Use version fields to prevent concurrent modification conflicts
- **Eventual Consistency**: Services react to events asynchronously
- **Bitemporal Queries**: Implement temporal queries for audit and historical analysis
- **PCI Compliance**: Payment data must be tokenized and secured
- **Scalability**: Design for horizontal scaling of microservices
- **Observability**: Implement distributed tracing and centralized logging

This migration transforms the monolithic Oracle system into a modern, scalable microservices architecture following industry best practices for event-driven systems and temporal data management.</content>
<parameter name="filePath">/Users/nivedhithaagovindaraj/projects/rent_a_wheel/code_changes.md