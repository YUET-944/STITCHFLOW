/// ─────────────────────────────────────────────────────────────────────────────
///  StitchFlow Demo Mode — Mock Data Provider
///  Used when no backend is available. Activated via demo login.
/// ─────────────────────────────────────────────────────────────────────────────

class MockData {
  MockData._();

  // ── Demo Users ─────────────────────────────────────────────────────────────

  static const demoTailor = {
    'id': 'demo-tailor-khan-001',
    'readable_id': 'TR-KHAN',
    'role': 'TAILOR',
    'full_name': 'Khan Tailors',
    'phone': '+923001110001',
    'business_name': 'Khan Premium Stitching',
    'city': 'Lahore',
    'specializations': ['Sherwani', 'Shalwar Kameez', 'Suit'],
    'max_active_orders': 10,
    'current_active_orders': 4,
    'availability_status': 'ACTIVE',
    'price_per_suit_min': 5000,
    'price_per_suit_max': 25000,
    'rating': 4.8,
    'total_orders': 312,
  };

  static const demoClient = {
    'id': 'demo-client-khan-002',
    'readable_id': 'CL-KHAN',
    'role': 'CLIENT',
    'full_name': 'Khan Sahib',
    'phone': '+923001110002',
    'city': 'Lahore',
  };

  // ── Demo Orders ────────────────────────────────────────────────────────────

  static final demoOrders = [
    {
      'id': 'order-demo-001',
      'booking_status': 'CONFIRMED',
      'tailor': {'full_name': 'Khan Tailors', 'readable_id': 'TR-KHAN'},
      'garments': [
        {'garment_type': 'Sherwani', 'delivery_stage': 'BODY_STITCHED'},
        {'garment_type': 'Shalwar', 'delivery_stage': 'FABRIC_CUT'},
      ],
      'invoice': {'payment_status': 'ADVANCE_RECEIVED', 'balance_due': 15000},
      'preferred_date_start': '2026-04-01T00:00:00Z',
      'preferred_date_end': '2026-05-01T00:00:00Z',
      'created_at': '2026-04-01T10:00:00Z',
    },
    {
      'id': 'order-demo-002',
      'booking_status': 'PENDING',
      'tailor': {'full_name': 'Ahmed Stitching House', 'readable_id': 'TR-AHMD'},
      'garments': [
        {'garment_type': 'Suit', 'delivery_stage': 'MEASUREMENT_CONFIRMED'},
      ],
      'invoice': null,
      'preferred_date_start': '2026-04-10T00:00:00Z',
      'preferred_date_end': '2026-05-10T00:00:00Z',
      'created_at': '2026-04-10T14:00:00Z',
    },
    {
      'id': 'order-demo-003',
      'booking_status': 'COMPLETED',
      'tailor': {'full_name': 'Khan Tailors', 'readable_id': 'TR-KHAN'},
      'garments': [
        {'garment_type': 'Waistcoat', 'delivery_stage': 'READY'},
      ],
      'invoice': {'payment_status': 'FULLY_PAID', 'balance_due': 0},
      'preferred_date_start': '2026-03-01T00:00:00Z',
      'preferred_date_end': '2026-03-20T00:00:00Z',
      'created_at': '2026-03-15T09:00:00Z',
    },
  ];

  // ── Demo Booking Queue (for Tailor view) ───────────────────────────────────

  static final demoQueue = [
    {
      'id': 'order-q-001',
      'booking_status': 'PENDING',
      'client': {
        'full_name': 'Ali Raza',
        'readable_id': 'CL-ALIR',
        'profile_photo_url': null,
      },
      'garments': [
        {'garment_type': 'Sherwani'},
        {'garment_type': 'Shalwar'},
      ],
      'notes': 'Wedding on 20th April. Need urgent delivery.',
      'created_at': '2026-04-12T10:00:00Z',
    },
    {
      'id': 'order-q-002',
      'booking_status': 'PENDING',
      'client': {
        'full_name': 'Usman Khan',
        'readable_id': 'CL-USMK',
        'profile_photo_url': null,
      },
      'garments': [
        {'garment_type': 'Suit'},
      ],
      'notes': 'Corporate meeting suit, prefer navy blue.',
      'created_at': '2026-04-13T08:30:00Z',
    },
  ];

  // ── Demo Active Orders (Tailor) ────────────────────────────────────────────

  static final demoActiveOrders = [
    {
      'id': 'order-demo-001',
      'booking_status': 'CONFIRMED',
      'client': {'full_name': 'Khan Sahib', 'readable_id': 'CL-KHAN'},
      'garments': [
        {
          'id': 'g-001',
          'garment_type': 'Sherwani',
          'delivery_stage': 'BODY_STITCHED',
          'staff_master': {'name': 'Rashid Ustad'},
        },
        {
          'id': 'g-002',
          'garment_type': 'Shalwar',
          'delivery_stage': 'FABRIC_CUT',  // Fixed: was 'CUTTING' (not a valid GarmentStage)
          'staff_master': null,
        },
      ],
      'invoice': {'payment_status': 'ADVANCE_RECEIVED', 'balance_due': 15000}, // Fixed: was 'PARTIAL'
    },
    {
      'id': 'order-active-002',
      'booking_status': 'CONFIRMED',
      'client': {'full_name': 'Sara Malik', 'readable_id': 'CL-SARM'},
      'garments': [
        {
          'id': 'g-003',
          'garment_type': 'Suit',
          'delivery_stage': 'PRESSING_FINISHING',
          'staff_master': {'name': 'Tariq Ustad'},
        },
      ],
      'invoice': {'payment_status': 'FULLY_PAID', 'balance_due': 0},
    },
  ];

  // ── Demo Staff ─────────────────────────────────────────────────────────────

  static final demoStaff = [
    {
      'id': 'staff-001',
      'name': 'Rashid Ustad',
      'specialty': 'Sherwani & Formal Wear',
      'phone': '+923001234001',
      'is_active': true,
      'on_time_rate': 94,
      'orders_completed': 87,
    },
    {
      'id': 'staff-002',
      'name': 'Tariq Ustad',
      'specialty': 'Suits & Western',
      'phone': '+923001234002',
      'is_active': true,
      'on_time_rate': 88,
      'orders_completed': 64,
    },
    {
      'id': 'staff-003',
      'name': 'Imran Helper',
      'specialty': 'Cutting & Finishing',
      'phone': '+923001234003',
      'is_active': false,
      'on_time_rate': 72,
      'orders_completed': 31,
    },
  ];

  // ── Demo Measurements ──────────────────────────────────────────────────────

  static final demoMeasurements = [
    {
      'id': 'meas-001',
      'version': 1,
      'is_current': true,
      'parent_id': null,
      'tailor': {'full_name': 'Khan Tailors', 'readable_id': 'TR-KHAN'},
      'recorded_at': '2026-04-01T10:00:00Z',
      'chest': 40, 'waist': 36, 'hips': 42,
      'shoulder': 18, 'sleeve': 25, 'neck': 15,
      'shirt_length': 30, 'trouser_length': 42,
      'notes': 'Slightly broad shoulders',
    },
    {
      'id': 'meas-002',
      'version': 1,
      'is_current': true,
      'parent_id': null,
      'tailor': {'full_name': 'Ahmed Stitching', 'readable_id': 'TR-AHMD'},
      'recorded_at': '2025-12-10T12:00:00Z',
      'chest': 40, 'waist': 35, 'hips': 41,
      'shoulder': 18, 'sleeve': 25, 'neck': 15,
      'shirt_length': 30, 'trouser_length': 42,
      'notes': '',
    },
  ];

  // ── Demo Tailor Discovery Results ──────────────────────────────────────────

  static final demoTailors = [
    {
      'id': 'demo-tailor-khan-001',
      'full_name': 'Khan Tailors',
      'readable_id': 'TR-KHAN',
      'tailor_profile': {
        'business_name': 'Khan Premium Stitching',
        'specializations': ['Sherwani', 'Shalwar Kameez', 'Suit'],
        'price_per_suit_min': 5000,
        'price_per_suit_max': 25000,
        'rating': 4.8,
        'total_orders_completed': 312,
        'current_active_orders': 4,
        'max_active_orders': 10,
        'availability_status': 'ACTIVE',
        'city': 'Lahore',
      },
    },
    {
      'id': 'tailor-demo-002',
      'full_name': 'Ahmed Stitching House',
      'readable_id': 'TR-AHMD',
      'tailor_profile': {
        'business_name': 'Ahmed Premium Tailors',
        'specializations': ['Suit', 'Blazer'],
        'price_per_suit_min': 8000,
        'price_per_suit_max': 40000,
        'rating': 4.5,
        'total_orders_completed': 198,
        'current_active_orders': 8,
        'max_active_orders': 10,
        'availability_status': 'ACTIVE',
        'city': 'Karachi',
      },
    },
    {
      'id': 'tailor-demo-003',
      'full_name': 'Waqar Master Ji',
      'readable_id': 'TR-WAQR',
      'tailor_profile': {
        'business_name': 'Master Ji Creations',
        'specializations': ['Shalwar Kameez', 'Kurta'],
        'price_per_suit_min': 2500,
        'price_per_suit_max': 12000,
        'rating': 4.9,
        'total_orders_completed': 540,
        'current_active_orders': 10,
        'max_active_orders': 10,
        'availability_status': 'FULLY_BOOKED',
        'city': 'Lahore',
      },
    },
  ];
}
