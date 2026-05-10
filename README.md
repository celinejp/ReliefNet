# ReliefNet

> Offline-first AI-powered disaster response and emergency coordination platform

---

## Inspiration

During disasters, the systems people depend on most often fail first. Internet connectivity disappears, communication networks become overloaded, and emergency responders are overwhelmed with fragmented and duplicate information. At the same time, volunteers, supplies, and victims may exist only blocks apart without any reliable coordination system connecting them.

We built **ReliefNet** to address this breakdown. Our goal was to create a disaster-response platform capable of functioning in unstable or completely offline environments while still supporting intelligent coordination, emergency reporting, and real-time response workflows.

ReliefNet is designed not simply as a mobile application, but as a resilient operational coordination system for chaotic, high-stakes disaster environments.

---

## Problem Statement

Disaster response systems often fail when communication infrastructure collapses. Victims, volunteers, and responders struggle to coordinate emergency alerts, aid distribution, and missing-person reports in real time.

ReliefNet solves three major disaster-response failures:

- Communication collapse during internet/network outages
- No system to match aid with nearby needs
- Duplicate missing-person reports wasting responder time

---

## What It Does

ReliefNet is a hybrid disaster-response ecosystem built using Flutter and Node.js. It combines cloud-based AI triage with offline local-network communication to maintain emergency coordination even during infrastructure collapse.

### Core Capabilities

- Offline emergency alerts through hotspot/LAN communication
- Real-time responder dashboard across connected devices
- AI-powered emergency triage and severity prioritization
- Missing-person matching with duplicate detection
- Volunteer and donation coordination workflows
- Voice-to-text emergency reporting
- Automatic cloud synchronization after reconnection

---

## Features

### 1. Offline Emergency Alerts

- Laptop acts as local server
- Phones connect through hotspot
- Alerts work without internet
- Live responder dashboard
- Automatic cloud sync when online

### 2. AI Emergency Triage

- Online emergency reporting
- AI cleans messy reports
- Automatic severity detection
- Real-time prioritized alerts

### 3. Missing Person Matching

- Lost and found reporting
- Photo and voice support
- AI compares all reports
- Duplicate cases merged

### 4. Volunteer & Donation Matching

- Request or offer help
- GPS-based volunteer matching
- One-tap emergency calling
- Live donation tracking

---

## How We Built It

### Frontend

- Flutter (Dart)
- Material 3 UI

### Backend

- Node.js + Express
- MongoDB + Mongoose
- Anthropic Claude API
- Socket.IO
- Auth0 authentication

### Offline Infrastructure

- Laptop-based local emergency server
- WiFi hotspot communication between devices
- Local persistence and delayed synchronization
- Zero-internet emergency reporting

---

## Tech Stack

Flutter (Dart) · Node.js · Express.js · MongoDB · Mongoose · Socket.IO · Anthropic Claude API · Auth0 · connectivity_plus · socket_io_client · shared_preferences · flutter_secure_storage · REST APIs · Multer · Android Studio · VS Code · Git · GitHub · LAN/Hotspot Networking

---

## System Workflow

### Online Workflow

1. User submits emergency alert
2. Alert stored in MongoDB
3. Claude AI categorizes and prioritizes report
4. Responders receive ranked incident feed
5. Response status updates in real time

### Offline Workflow

1. Laptop creates local hotspot hub
2. Phones connect directly to local network
3. Alerts transmitted without internet
4. Local server stores emergency reports
5. Data synchronizes to cloud after reconnection

---

## Challenges We Ran Into

- Building reliable communication without internet access
- Synchronizing offline and cloud data safely
- Preventing duplicate missing-person reports
- Managing real-time updates across local and cloud systems
- Handling merge conflicts across multiple integrated features
- Ensuring alerts were never lost during network failures

---

## Accomplishments We're Proud Of

- Built a functioning offline-first disaster coordination system
- Implemented AI-powered emergency triage workflows
- Created duplicate missing-person detection using semantic matching
- Developed volunteer and donation matching infrastructure
- Successfully integrated cloud and LAN-based emergency operations
- Designed a resilient architecture for real-world disaster response

---

## What We Learned

- Offline-first system design requires fundamentally different thinking
- Reliability and graceful degradation are critical in emergency systems
- AI can significantly reduce responder overload during crises
- Real-time synchronization introduces complex operational challenges
- Disaster-response software must prioritize accessibility and resilience

---

## What's Next for ReliefNet

- Bluetooth mesh networking between phones
- GIS disaster heatmaps and responder routing
- Multilingual emergency translation
- Satellite and drone integration
- Enhanced responder authentication and verification
- Improved synchronization and distributed offline networking

---

## Installation

### Clone Repository

```bash
git clone https://github.com/USERNAME/ReliefNet.git
cd ReliefNet
```

### Frontend Setup

```bash
flutter pub get
flutter run
```

### Backend Setup

```bash
cd server
npm install
npm start
```

---

## Environment Variables

Create a `server/.env` file:

```env
MONGODB_URI=your_mongodb_uri
ANTHROPIC_API_KEY=your_claude_api_key
AUTH0_DOMAIN=your_auth0_domain
AUTH0_AUDIENCE=your_auth0_audience
PORT=3000
```

---

## Team

| Name | Email |
|---|---|
| Aayusha Hadke | ahadke@ucdavis.edu |
| Celine John Philip | cjphilp@ucdavis.edu |
| Sayali Lokhande | slokhande@ucdavis.edu |

---

## Built For

**HackDavis 2026**

---

## License

MIT License
