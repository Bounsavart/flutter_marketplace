# Room Rental Marketplace

ແອັບ Flutter + API Node.js ສຳລັບຄົ້ນຫາ ແລະ ຈອງຫ້ອງເຊົ່າໃນນະຄອນຫຼວງວຽງຈັນ

## ໂຄງສ້າງ

- `lib/` — ແອັບມືຖື Flutter (Tenant / Owner / Admin)
- `room-rental-api/` — Backend Express + Sequelize + MySQL + JWT

## ແລ່ນ Backend

ຕ້ອງມີ MySQL (ຫຼື ໃຊ້ Docker ໃນໂຟນເດີ API)

```bash
cd room-rental-api
cp .env.example .env
docker compose up -d
npm install
npm run seed
npm run dev
```

ບັນຊີຕົວຢ່າງຫຼັງ seed:
- Admin: `admin@marketplace.la` / `Admin123!`
- Owner: `owner@marketplace.la` / `Owner123!`
- Tenant: `tenant@marketplace.la` / `Tenant123!`
npm run dev
cd /d D:\flutter_Marketplace\room-rental-api

## ແລ່ນແອັບ Flutter



flutter pub get
flutter run
```

- Android emulator ຊີ້ API ທີ່ `http://10.0.2.2:3000`
- iOS simulator / web ຊີ້ `http://127.0.0.1:3000`
- ກຳນົດເອງດ້ວຍ `--dart-define=API_BASE_URL=http://IP:3000`
