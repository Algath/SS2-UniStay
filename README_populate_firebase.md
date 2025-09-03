# Firebase Population Script

This script directly populates your Firebase Firestore database with properties from the CSV file, all belonging to the specified user UID.

## Setup Instructions

### 1. Install Python Dependencies
```bash
pip install -r requirements.txt
```

### 2. Get Firebase Service Account Key
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Go to Project Settings (gear icon)
4. Go to Service Accounts tab
5. Click "Generate new private key"
6. Download the JSON file
7. Place it in the same directory as the script
8. Update the filename in `populate_firebase.py` line 15

### 3. Verify Files
Make sure you have:
- `populate_firebase.py` (the script)
- `synthetic_valais_price.csv` (your CSV file)
- `your-firebase-service-account-key.json` (Firebase key)

### 4. Run the Script
```bash
python populate_firebase.py
```

## What the Script Does

1. **Reads CSV data** from `synthetic_valais_price.csv`
2. **Maps CSV columns** to your Room model fields:
   - `price_chf` → `price`
   - `city` → `city`
   - `postal_code` → `postcode`
   - `latitude` → `lat`
   - `longitude` → `lng`
   - `surface_m2` → `sizeSqm`
   - `num_rooms` → `rooms`
   - `type` → `type` (room/whole)
   - `is_furnished` → `furnished`
   - `wifi_incl` → `internetMbps` (if True)
   - `charges_incl` → `utilitiesIncluded`
   - `car_park` → `Parking` amenity
   - `dist_public_transport_km` → `walkMins` (calculated)

3. **Generates realistic data**:
   - Random titles and descriptions
   - Realistic street names for Valais cities
   - Mix of past and future availability dates
   - Sample photo URLs from Unsplash
   - Amenities based on CSV data

4. **Sets all properties** to belong to UID: `aeVihIkzCzWVfunVtkpeZdcL5aJ3`

5. **Directly writes to Firestore** using Firebase Admin SDK

## Expected Output
```
Starting to populate Firebase with properties for owner: aeVihIkzCzWVfunVtkpeZdcL5aJ3
Created property 1: Cozy Student Room Near University in Saxon
Created property 2: Modern Apartment with Mountain View in Sion
...
Successfully populated Firebase with properties for owner: aeVihIkzCzWVfunVtkpeZdcL5aJ3
```

## Troubleshooting

- **Permission Error**: Make sure your Firebase service account has write permissions
- **CSV Not Found**: Ensure `synthetic_valais_price.csv` is in the same directory
- **Firebase Key Error**: Verify the service account key filename matches line 15 in the script
