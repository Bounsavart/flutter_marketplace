require('dotenv').config();

const bcrypt = require('bcrypt');
const { sequelize, User, Property, Room, Amenity } = require('./models');
const { syncDatabase } = require('./config/sync');

async function seed() {
  await sequelize.authenticate();
  await syncDatabase();

  const amenityNames = ['Wi-Fi', 'ແອ', 'ບ່ອນຈອດລົດ', 'ເຄື່ອງເຮັດນ້ຳອຸ່ນ', 'ຕູ້ເຢັນ', 'ເຄື່ອງຊັກຜ້າ'];
  const amenities = [];
  for (const name of amenityNames) {
    const [row] = await Amenity.findOrCreate({ where: { name }, defaults: { name } });
    amenities.push(row);
  }

  const adminEmail = process.env.ADMIN_EMAIL || 'admin@marketplace.la';
  const adminPassword = process.env.ADMIN_PASSWORD || 'Admin123!';
  const [admin] = await User.findOrCreate({
    where: { email: adminEmail },
    defaults: {
      name: 'ຜູ້ດູແລລະບົບ',
      email: adminEmail,
      phone: '2055550000',
      password_hash: await bcrypt.hash(adminPassword, 10),
      role: 'admin',
    },
  });

  const [owner] = await User.findOrCreate({
    where: { email: 'owner@marketplace.la' },
    defaults: {
      name: 'ນາງ ສົມສີ Owner',
      email: 'owner@marketplace.la',
      phone: '2055511111',
      password_hash: await bcrypt.hash('Owner123!', 10),
      role: 'owner',
    },
  });

  await User.findOrCreate({
    where: { email: 'tenant@marketplace.la' },
    defaults: {
      name: 'ທ້າວ ບຸນມີ Tenant',
      email: 'tenant@marketplace.la',
      phone: '2055522222',
      password_hash: await bcrypt.hash('Tenant123!', 10),
      role: 'tenant',
    },
  });

  let property = await Property.findOne({ where: { name: 'ວິວລາວ ອາພາດເມັນ', owner_id: owner.id } });
  if (!property) {
    property = await Property.create({
      owner_id: owner.id,
      name: 'ວິວລາວ ອາພາດເມັນ',
      description: 'ທີ່ພັກໃຈກາງນະຄອນຫຼວງວຽງຈັນ ໃກ້ຕະຫຼາດເຊົ້າ ແລະ ແຄມແມ່ນ້ຳຂອງ',
      province: 'ນະຄອນຫຼວງວຽງຈັນ',
      district: 'ຈັນທະບູລີ',
      address: 'ບ້ານ ຫ້ວຍຫົງ, ວຽງຈັນ',
      latitude: 17.9757,
      longitude: 102.6331,
      approval_status: 'approved',
    });
  }

  let pendingProperty = await Property.findOne({
    where: { name: 'ໂຮງແຮມນ້ອຍ ສີສັດຕະນາກ', owner_id: owner.id },
  });
  if (!pendingProperty) {
    pendingProperty = await Property.create({
      owner_id: owner.id,
      name: 'ໂຮງແຮມນ້ອຍ ສີສັດຕະນາກ',
      description: 'ຫ້ອງເຊົ່າລາຄາປະຢັດ ເຂດສີສັດຕະນາກ ລໍຖ້າແອັດມິນກວດສອບ',
      province: 'ນະຄອນຫຼວງວຽງຈັນ',
      district: 'ສີສັດຕະນາກ',
      address: 'ບ້ານ ດົງປ່າແຫຼບ',
      latitude: 17.962,
      longitude: 102.641,
      approval_status: 'pending',
    });
    await Room.create({
      property_id: pendingProperty.id,
      room_number: 'A1',
      room_type: 'Studio',
      price: 1200000,
      description: 'ຫ້ອງສະຕູດິໂອ ຊັ້ນ 1 ຂະໜາດປະມານ 22 ຕາແມັດ',
      status: 'available',
    });
  }

  let room = await Room.findOne({ where: { property_id: property.id, room_number: '101' } });
  if (!room) {
    room = await Room.create({
      property_id: property.id,
      room_number: '101',
      room_type: '1 Bedroom',
      price: 2500000,
      description: 'ຫ້ອງນອນ 1 ຫ້ອງ ຂະໜາດ 32 ຕາແມັດ ຊັ້ນ 2 ມີລະບຽງ',
      status: 'available',
    });
    await room.setAmenities(amenities.slice(0, 4));
  }

  let room2 = await Room.findOne({ where: { property_id: property.id, room_number: '202' } });
  if (!room2) {
    room2 = await Room.create({
      property_id: property.id,
      room_number: '202',
      room_type: 'Studio',
      price: 1800000,
      description: 'ສະຕູດິໂອ ຊັ້ນ 3 ຂະໜາດ 24 ຕາແມັດ ເຟີນີເຈີຄົບ',
      status: 'available',
    });
    await room2.setAmenities(amenities.slice(0, 3));
  }

  console.log('Seed completed');
  console.log(`Admin: ${admin.email} / ${adminPassword}`);
  console.log('Owner: owner@marketplace.la / Owner123!');
  console.log('Tenant: tenant@marketplace.la / Tenant123!');
  await sequelize.close();
}

seed().catch((err) => {
  console.error(err);
  process.exit(1);
});
