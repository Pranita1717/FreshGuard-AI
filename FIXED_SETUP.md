# FreshGuard AI – Fixed Project Setup

## What was fixed

- Fixed sidebar/drawer navigation `Scaffold.of(context)` exception.
- Added missing `/manager/edit-product`, `/products` compatibility and `/manager/scan-barcode` compatibility routes.
- Fixed manager/employee inventory action names (`INCREASE` / `DECREASE`).
- Fixed product status usage to `expiryStatus`.
- Fixed discount suggestion field mismatch and added `daysUntilExpiry`.
- Added Android INTERNET and CAMERA permissions and local HTTP support.
- Removed Flutter Web-incompatible `dart:io` imports from shared application code.
- Added real Android OCR using Google ML Kit and retained browser Tesseract OCR.
- Backend no longer pretends that raw JPEG bytes are OCR text.
- Fixed month/year OCR dates to use the actual last day of the month.
- New accounts only see products belonging to their own store.
- Product creation uses the authenticated user's store; client store names cannot leak products across stores.
- Barcode lookup, inventory, shelf priority, restocking, discounts and reports are store-scoped.
- Notifications are user/store-scoped and `read-all` no longer marks every user's notifications as read.
- Employee tasks are restricted to the assigned employee and store.
- Removed the employee fallback that returned every task when no tasks were assigned.
- Reports and PDF reports are restricted to Store Manager and current store.
- PDF reports are actually saved/downloaded instead of only showing a fake "ready" message.
- Admin analytics no longer exposes store inventory/expiry details.
- Profile cannot change the account's store assignment.
- Added inventory quantity validation and manufacturing-date/expiry-date validation.
- Restocking is clearly rule-based rather than advertised as AI prediction.

## Demo accounts

- Admin: `admin@freshguard.local` / `Admin@123`
- Store Manager: `manager@freshguard.local` / `Manager@123`
- Employee: `employee@freshguard.local` / `Employee@123`

The demo manager and employee share the demo store and therefore intentionally see the demo inventory. A newly registered account using a different store name starts with an empty inventory.

## Backend

1. Start MongoDB locally on port `27017`.
2. Open `backend`.
3. Windows:
   `gradlew.bat bootRun`
4. Or:
   `./gradlew bootRun`

Backend runs on `http://localhost:8080`.

## Flutter

1. Open `frontend`.
2. Run:
   `flutter pub get`
3. Android emulator:
   `flutter run -d <android-device>`
4. Web:
   `flutter run -d chrome`
5. Windows desktop:
   `flutter run -d windows`

For a physical Android phone, configure the backend gateway to the PC's LAN address, for example:
`http://192.168.1.50:8080/api`

## Important

- Camera scanning requires a real camera-capable device/browser. Windows desktop shows manual/gallery barcode options because the mobile scanner plugin does not provide the same camera support there.
- Android OCR uses Google ML Kit. The first OCR use may require the device to download the recognition model.
- Web OCR uses the Tesseract.js code already included in `web/index.html`.
- The included ZIP intentionally excludes generated `build`, `.gradle`, `.dart_tool` and similar folders. Run `flutter pub get` before building.
