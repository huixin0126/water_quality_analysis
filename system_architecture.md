# System Architecture and Navigation Flow Diagrams

## 1. System Architecture Diagram

```mermaid
graph TB
    subgraph "Frontend Layer"
        A[Flutter Mobile App]
        A1[UI Components]
        A2[State Management]
        A3[API Client]
        A4[Local Storage]
        A5[Error Handling]
        A6[Form Validation]
    end

    subgraph "Backend Layer"
        B[Flask API Server]
        B1[Data Validation]
        B2[Error Handling]
        B3[CORS Middleware]
        B4[Request Processing]
        B5[Response Formatting]
    end

    subgraph "ML Processing Layer"
        C[ML Models]
        C1[2-Feature Model]
        C2[9-Feature Model]
        C3[Data Scaler]
        C4[Prediction Engine]
    end

    subgraph "Data Storage"
        D[Firebase]
        D1[Authentication]
        D2[Firestore]
        D3[User Profiles]
        D4[Analysis History]
    end

    %% Data Flow
    A -->|HTTP Requests| B
    B -->|Process Data| C
    C -->|Return Predictions| B
    B -->|JSON Response| A
    A -->|User Data| D
    D -->|Auth State| A

    %% Component Details
    A1 -->|User Input| A3
    A2 -->|State Updates| A1
    A6 -->|Validated Input| A3
    B1 -->|Validated Data| B4
    B4 -->|Processed Data| B5
    C1 -->|Scaled Data| C3
    C2 -->|Scaled Data| C3
    D1 -->|Auth Token| A
    D2 -->|User Data| A
    D3 -->|Profile Updates| A
    D4 -->|History Data| A
```

## 2. Navigation Flow Diagram

```mermaid
graph TD
    A[Start] --> B[Welcome Page]
    B -->|Sign In| C[Sign In Page]
    B -->|Sign Up| D[Sign Up Page]
    
    C -->|Authentication| E[Home Page]
    D -->|Create Account| E
    
    E -->|Water Quality Analysis| F[Water Quality Analysis Page]
    E -->|Water Turbidity| G[Water Turbidity Page]
    E -->|Filter Prediction| H[Filter Prediction Page]
    E -->|Profile| I[Profile Page]
    E -->|Reminders| J[Reminder Page]
    
    F -->|Basic Analysis| F1[Water Analysis Page]
    F -->|Advanced Analysis| F2[Water Analysis Page]
    F1 -->|Results| F3[Water Analysis Result Page]
    F2 -->|Results| F3
    F3 -->|Save| F4[Water Analysis History]
    
    G -->|Input Parameters| G1[Water Turbidity Result Page]
    G1 -->|Save| G2[Water Turbidity History]
    G2 -->|View Details| G3[Water Turbidity Detail Page]
    
    H -->|Input Parameters| H1[Filter Prediction Result]
    H1 -->|Save| H2[Filter Prediction History]
    H2 -->|View Details| H3[Filter Product Details]
    
    J -->|Add Reminder| J1[Add Reminder Page]
    J -->|Water Intake| J2[Water Intake Reminder Page]
    
    F4 -->|Back| E
    G2 -->|Back| E
    H2 -->|Back| E
    I -->|Back| E
    J -->|Back| E
    
    F3 -->|New Analysis| F
    G1 -->|New Analysis| G
    H1 -->|New Analysis| H
```

## Component Descriptions

### Frontend Layer
- **Flutter Mobile App**: Cross-platform mobile application
- **UI Components**: Material Design widgets and custom components
- **State Management**: Manages application state and data flow
- **API Client**: Handles communication with the Flask backend
- **Local Storage**: Manages local data caching
- **Error Handling**: Client-side error management
- **Form Validation**: Input validation and user feedback

### Backend Layer
- **Flask API Server**: RESTful API endpoints for water quality analysis
- **Data Validation**: Input validation and sanitization
- **Error Handling**: Comprehensive error management
- **CORS Middleware**: Cross-origin resource sharing support
- **Request Processing**: Handles incoming requests
- **Response Formatting**: Standardizes API responses

### ML Processing Layer
- **ML Models**: Pre-trained machine learning models
- **2-Feature Model**: Basic water quality analysis (pH and TDS)
- **9-Feature Model**: Comprehensive water quality analysis
- **Data Scaler**: Normalizes input data for predictions
- **Prediction Engine**: Generates water quality predictions

### Data Storage
- **Firebase**: Cloud-based backend services
- **Authentication**: User authentication and authorization
- **Firestore**: NoSQL database for storing analysis results
- **User Profiles**: Manages user information
- **Analysis History**: Stores past water quality analyses

### Navigation Flow
1. **Authentication**
   - Welcome Page
   - Sign In Page
   - Sign Up Page

2. **Main Features**
   - Water Quality Analysis
     - Basic Analysis (2-feature)
     - Advanced Analysis (9-feature)
     - Results Display
     - Analysis History
   - Water Turbidity Analysis
     - Input Parameters
     - Results Display
     - History and Details
   - Filter Prediction
     - Input Parameters
     - Results Display
     - Product Details
     - History

3. **Additional Features**
   - Profile Management
   - Reminder System
     - Add Reminders
     - Water Intake Reminders 