import { PrismaClient, Role } from '@prisma/client';
import * as bcrypt from 'bcrypt';

const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Starting database seeding...');

  try {
    // Clean existing data
    await prisma.orderGarment.deleteMany();
    await prisma.order.deleteMany();
    await prisma.measurement.deleteMany();
    await prisma.staffProfile.deleteMany();
    await prisma.tailorProfile.deleteMany();
    await prisma.user.deleteMany();
    await prisma.sequence.deleteMany();

    console.log('🧹 Cleaned existing data');

    // Create sequences
    await prisma.sequence.createMany({
      data: [
        { id: 'TR_KARACHI', prefix: 'TR', last_value: 0 },
        { id: 'CL_KARACHI', prefix: 'CL', last_value: 0 },
        { id: 'TR_UNKNOWN', prefix: 'TR', last_value: 0 },
        { id: 'CL_UNKNOWN', prefix: 'CL', last_value: 0 },
      ]
    });

    // Create demo users
    const demoTailorPassword = await bcrypt.hash('demo123', 12);
    const demoClientPassword = await bcrypt.hash('client123', 12);

    const tailor = await prisma.user.create({
      data: {
        readable_id: 'TR-KARACHI-001',
        role: Role.TAILOR,
        full_name: 'Ahmad Tailor',
        username: 'ahmad_tailor',
        password_hash: demoTailorPassword,
        email: 'ahmad@stitchflow.com',
        location_city: 'Karachi',
        is_verified: true,
        account_status: 'ACTIVE',
      }
    });

    await prisma.tailorProfile.create({
      data: {
        tailor_id: tailor.id,
        business_name: 'Ahmad Bespoke Tailoring',
        specializations: ['Suits', 'Sherwani', 'Waistcoats'],
        price_per_suit_min: 5000,
        price_per_suit_max: 15000,
        availability_status: 'ACTIVE',
        max_active_orders: 10,
        current_active_orders: 3,
      }
    });

    const client = await prisma.user.create({
      data: {
        readable_id: 'CL-KARACHI-001',
        role: Role.CLIENT,
        full_name: 'Khan Client',
        username: 'khan_client',
        password_hash: demoClientPassword,
        email: 'khan@stitchflow.com',
        location_city: 'Karachi',
        is_verified: true,
        account_status: 'ACTIVE',
      }
    });

    // Create sample order
    const order = await prisma.order.create({
      data: {
        id: 'SF-O-DEMO-001',
        client_id: client.id,
        tailor_id: tailor.id,
        booking_status: 'CONFIRMED',
        preferred_date_start: new Date(),
        preferred_date_end: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000), // 7 days from now
        requirements_verified: true,
        confirmed_at: new Date(),
        created_at: new Date(),
      }
    });

    // Create sample garments
    await prisma.orderGarment.createMany({
      data: [
        {
          order_id: order.id,
          garment_type: 'Suit',
          delivery_stage: 'QC_PASSED',
          stage_history: [
            { stage: 'PENDING', timestamp: new Date().toISOString() },
            { stage: 'CONFIRMED', timestamp: new Date(Date.now() + 3600000).toISOString() },
            { stage: 'QC_PASSED', timestamp: new Date(Date.now() + 7200000).toISOString() }
          ],
          requirements: {
            fabric_type: 'Wool Blend',
            color: 'Navy Blue',
            fit_preference: 'Slim Fit',
            special_instructions: 'Add monogram on chest pocket'
          }
        },
        {
          order_id: order.id,
          garment_type: 'Sherwani',
          delivery_stage: 'MEASUREMENT_CONFIRMED',
          stage_history: [
            { stage: 'PENDING', timestamp: new Date().toISOString() }
          ],
          requirements: {
            fabric_type: 'Cotton',
            color: 'Black',
            fit_preference: 'Regular Fit'
          }
        }
      ]
    });

    // Create sample measurements
    await prisma.measurement.create({
      data: {
        id: 'SF-M-AHMD-KHAN-001',
        client_id: client.id,
        tailor_id: tailor.id,
        version: 1,
        is_current: true,
        neck: 38.5,
        chest: 96.0,
        waist: 84.0,
        hips: 98.0,
        shoulder_width: 45.0,
        sleeve_length: 62.0,
        inseam: 82.0,
        custom_notes: 'Standard measurements for demo client',
      }
    });

    // Create sample staff
    const staffPassword = await bcrypt.hash('staff123', 12);
    const staff = await prisma.user.create({
      data: {
        readable_id: 'ST-001',
        role: Role.TAILOR,
        full_name: 'Ali Assistant',
        username: 'ali_assistant',
        password_hash: staffPassword,
        email: 'ali@stitchflow.com',
        location_city: 'Karachi',
        is_verified: true,
        account_status: 'ACTIVE',
      }
    });

    await prisma.staffProfile.create({
      data: {
        tailor_id: tailor.id,
        name: 'Ali Assistant',
        specialty: 'Cutting & Stitching',
        phone: '+923001234567',
        is_active: true,
        total_completed_on_time: 15,
        total_assigned: 20,
      }
    });

    console.log('✅ Database seeded successfully!');
    console.log('👤 Demo Users:');
    console.log('   Tailor: ahmad_tailor / demo123');
    console.log('   Client: khan_client / client123');
    console.log('   Staff: ali_assistant / staff123');

  } catch (error) {
    console.error('❌ Seeding failed:', error);
    throw error;
  } finally {
    await prisma.$disconnect();
  }
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  });
