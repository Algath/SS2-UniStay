import csv
import random
import firebase_admin
from firebase_admin import credentials, firestore
from datetime import datetime, timedelta
import json

# Configuration
OWNER_UID = "aeVihIkzCzWVfunVtkpeZdcL5aJ3"
CSV_FILE = "synthetic_valais_price.csv"

# Initialize Firebase Admin SDK
# Firebase service account key JSON file path
cred = credentials.Certificate("assets/face-api_server/firebase-service-account.json")
firebase_admin.initialize_app(cred)
db = firestore.client()

# Sample data for generating realistic properties
PROPERTY_TITLES = [
    'Cozy Student Room Near University',
    'Modern Apartment with Mountain View',
    'Charming Studio in City Center',
    'Spacious Room with Private Bathroom',
    'Luxury Apartment with Lake View',
    'Budget-Friendly Student Housing',
    'Premium Room with Balcony',
    'Family-Friendly Apartment',
    'Quiet Room in Residential Area',
    'Contemporary Studio Near Transport'
]

PROPERTY_DESCRIPTIONS = [
    'Beautiful and modern room perfect for students. Located in a quiet neighborhood with easy access to public transportation.',
    'Spacious apartment with stunning mountain views. Fully furnished with all modern amenities included.',
    'Charming studio apartment in the heart of the city. Perfect location for both work and leisure.',
    'Large room with private bathroom and balcony. Great for students or young professionals.',
    'Luxury apartment with breathtaking lake views. High-end finishes and premium amenities.',
    'Affordable student housing with all basic amenities. Clean and comfortable living space.',
    'Premium room with private balcony and mountain views. Modern furnishings and excellent location.',
    'Family-friendly apartment with multiple bedrooms. Safe neighborhood with parks nearby.',
    'Peaceful room in a residential area. Perfect for those who prefer quiet surroundings.',
    'Contemporary studio with excellent transport links. Modern design and convenient location.'
]

# Realistic street names for Valais cities
STREET_NAMES = {
    'Sion': [
        'Rue de Lausanne', 'Avenue de la Gare', 'Rue du Scex', 'Avenue de la Tour',
        'Rue de la Majorie', 'Avenue de la Gare', 'Rue de la Planta', 'Avenue du Midi',
        'Rue du Grand-Pont', 'Avenue de la Gare', 'Rue de la Tannerie', 'Avenue du Rhône'
    ],
    'Martigny': [
        'Avenue de la Gare', 'Rue de la Bâtiaz', 'Avenue du Grand-Saint-Bernard',
        'Rue de Lausanne', 'Avenue de la Gare', 'Rue du Bourg', 'Avenue du Rhône',
        'Rue de la Morge', 'Avenue de la Gare', 'Rue du Léman', 'Avenue du Simplon'
    ],
    'Saxon': [
        'Route de Martigny', 'Rue de la Gare', 'Route de Sion', 'Rue du Village',
        'Route de Fully', 'Rue de la Poste', 'Route de Martigny', 'Rue du Rhône'
    ],
    'Vétroz': [
        'Route de Sion', 'Rue du Village', 'Route de Martigny', 'Rue de la Gare',
        'Route de Fully', 'Rue du Rhône', 'Route de Sion', 'Rue de la Poste'
    ],
    'Riddes': [
        'Route de Martigny', 'Rue du Village', 'Route de Sion', 'Rue de la Gare',
        'Route de Saxon', 'Rue du Rhône', 'Route de Martigny', 'Rue de la Poste'
    ],
    'Sierre': [
        'Avenue de la Gare', 'Rue de la Planta', 'Avenue du Rhône', 'Rue du Bourg',
        'Avenue de la Gare', 'Rue de Lausanne', 'Avenue du Midi', 'Rue de la Tour'
    ],
    'Leuk': [
        'Hauptgasse', 'Bahnhofstrasse', 'Kirchgasse', 'Rathausgasse',
        'Schlossgasse', 'Marktgasse', 'Kirchplatz', 'Bahnhofplatz'
    ],
    'Visp': [
        'Bahnhofstrasse', 'Hauptgasse', 'Kirchgasse', 'Marktgasse',
        'Rathausgasse', 'Schlossgasse', 'Bahnhofplatz', 'Kirchplatz'
    ],
    'Fully': [
        'Route de Martigny', 'Rue du Village', 'Route de Sion', 'Rue de la Gare',
        'Route de Saxon', 'Rue du Rhône', 'Route de Martigny', 'Rue de la Poste'
    ],
    'Conthey': [
        'Route de Sion', 'Rue du Village', 'Route de Martigny', 'Rue de la Gare',
        'Route de Vétroz', 'Rue du Rhône', 'Route de Sion', 'Rue de la Poste'
    ],
    'Brig': [
        'Bahnhofstrasse', 'Hauptgasse', 'Kirchgasse', 'Marktgasse',
        'Rathausgasse', 'Schlossgasse', 'Bahnhofplatz', 'Kirchplatz'
    ],
    'St-Maurice': [
        'Avenue de la Gare', 'Rue du Bourg', 'Avenue du Simplon', 'Rue de Lausanne',
        'Avenue de la Gare', 'Rue de la Tour', 'Avenue du Rhône', 'Rue de la Morge'
    ],
    'Monthey': [
        'Avenue de la Gare', 'Rue du Bourg', 'Avenue du Rhône', 'Rue de Lausanne',
        'Avenue de la Gare', 'Rue de la Tour', 'Avenue du Simplon', 'Rue de la Morge'
    ]
}

def generate_street_name(city):
    """Generate realistic street name based on city"""
    if city in STREET_NAMES:
        return random.choice(STREET_NAMES[city])
    else:
        default_streets = [
            'Route Principale', 'Rue du Village', 'Avenue de la Gare', 'Rue du Bourg',
            'Route de la Ville', 'Rue de la Poste', 'Avenue du Rhône', 'Rue de la Tour'
        ]
        return random.choice(default_streets)

def generate_availability_ranges():
    """Generate realistic availability ranges (mix of past and future dates)"""
    now = datetime.now()
    ranges = []
    
    # Generate 3-4 availability ranges
    for j in range(3 + random.randint(0, 1)):
        if j < 2:
            # Past dates (for realistic reviews)
            past_months = random.randint(1, 6)
            start_month = now.month - past_months
            start_year = now.year
            
            if start_month <= 0:
                start_month += 12
                start_year -= 1
            
            start_date = datetime(start_year, start_month, 1 + random.randint(0, 20))
            end_date = start_date + timedelta(days=15 + random.randint(0, 30))
        else:
            # Future dates (for current availability)
            start_month = now.month + 1 + (j - 2) * 2
            start_date = datetime(now.year, start_month, 1 + random.randint(0, 15))
            end_date = start_date + timedelta(days=30 + random.randint(0, 60))
        
        ranges.append({
            'start': start_date,
            'end': end_date
        })
    
    return ranges

def generate_amenities(csv_row):
    """Generate amenities based on CSV data"""
    amenities = []
    
    if csv_row['wifi_incl'] == 'True':
        amenities.append('Internet')
    if csv_row['car_park'] == 'True':
        amenities.append('Parking')
    if random.choice([True, False]):
        amenities.append('Private bathroom')
    if random.choice([True, False]):
        amenities.append('Kitchen access')
    
    return amenities

def generate_photo_urls():
    """Generate sample photo URLs"""
    return [
        'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=500',
        'https://images.unsplash.com/photo-1560448075-bb485b067938?w=500',
        'https://images.unsplash.com/photo-1560448204-603b3fc33ddc?w=500',
    ]

def populate_firebase():
    """Main function to populate Firebase with properties from CSV"""
    print(f"Starting to populate Firebase with properties for owner: {OWNER_UID}")
    
    with open(CSV_FILE, 'r', encoding='utf-8') as file:
        reader = csv.DictReader(file)
        
        for i, row in enumerate(reader):
            try:
                # Generate random property data
                title = random.choice(PROPERTY_TITLES)
                description = random.choice(PROPERTY_DESCRIPTIONS)
                street_name = generate_street_name(row['city'])
                house_number = str(random.randint(1, 50))
                
                # Calculate walk time from distance
                walk_mins = int(float(row['dist_public_transport_km']) * 1000 / 80)  # 80m/min walking speed
                
                # Generate amenities
                amenities = generate_amenities(row)
                
                # Generate availability ranges
                availability_ranges = generate_availability_ranges()
                
                # Generate photo URLs
                photo_urls = generate_photo_urls()
                
                # Create property document
                property_data = {
                    'title': title,
                    'price': float(row['price_chf']),
                    'street': street_name,
                    'houseNumber': house_number,
                    'city': row['city'],
                    'postcode': row['postal_code'],
                    'country': 'Switzerland',
                    'description': description,
                    'lat': float(row['latitude']),
                    'lng': float(row['longitude']),
                    'ownerUid': OWNER_UID,
                    'photoUrls': photo_urls,
                    'walkMins': walk_mins,
                    'type': 'whole' if row['type'] == 'entire_home' else 'room',
                    'furnished': row['is_furnished'] == 'True',
                    'sizeSqm': int(float(row['surface_m2'])),
                    'rooms': int(float(row['num_rooms'])),
                    'bathrooms': random.randint(1, 2),
                    'utilitiesIncluded': row['charges_incl'] == 'True',
                    'internetMbps': int(50 + random.randint(0, 150)) if row['wifi_incl'] == 'True' else None,
                    'availabilityRanges': availability_ranges,
                    'amenities': amenities,
                    'status': 'active',
                    'createdAt': firestore.SERVER_TIMESTAMP,
                    'updatedAt': firestore.SERVER_TIMESTAMP,
                }
                
                # Add to Firestore
                doc_ref = db.collection('rooms').document()
                doc_ref.set(property_data)
                
                print(f"Created property {i+1}: {title} in {row['city']}")
                
            except Exception as e:
                print(f"Error creating property {i+1}: {e}")
                continue
    
    print(f"Successfully populated Firebase with properties for owner: {OWNER_UID}")

if __name__ == "__main__":
    # Instructions for setup
    print("SETUP INSTRUCTIONS:")
    print("1. Firebase service account key is already configured at: assets/face-api_server")
    print("2. Make sure the CSV file is in the same directory")
    print("3. Run: python populate_firebase.py")
    print()
    
    # Uncomment the line below to run the population
    populate_firebase()
