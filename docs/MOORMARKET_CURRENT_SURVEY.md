# รายงานสำรวจ MoorMarket

**สถานะ ณ วันที่ 24 พฤศจิกายน 2026**  
**Branch:** `community-pivot`  
**Commits ล่าสุด:** `05c09eb phase 8: local persistence`, `1920055 docs: update persistence status`

## 1. ภาพรวมโปรเจกต์

MoorMarket คือ prototype ตลาดซื้อขาย แลกเปลี่ยน และบริจาคในระดับชุมชน
ชื่อแอปสำหรับผู้ใช้ทั่วไป ไม่ผูกมหาวิทยาลัย และใช้ Flutter สำหรับหน้าจอ
ข้อมูลหลักอยู่ใน AppState และเก็บถาวรในเครื่องผ่านชั้น persistence

สถานะปัจจุบันผ่านการตรวจด้วยอัตโนมัติเบื้อฐาน แต่ยังไม่ได้ทดสอบการใช้งานจริงครบทุก flow
บนอุปกรณ์ Pixel 6 และยังไม่พร้อมเชื่อม SMS, payment gateway, push notification,
หรือ backend แบบ production

## 2. สถานะฟีเจอร์ปัจจุบัน

| ด้าน | สถานะปัจจุบัน |
|---|---|
| Auth เบอร์โทร/OTP mock | ทำงานใน prototype; OTP เป็น mock ไม่ส่ง SMS จริง |
| แบรนด์และธีม community | ใช้ชื่อ/ธีม dolp และแก้เลิกข้อความมหาวิทยาลัยใน flow หลัก |
| ตำแหน่งและระยะทาง | มีพื้นที่ผู้ใช้ ตั้งรัศมี และคำนวณระยะทางจากค่าที่ผู้ใช้ตั้งไว้ |
| ผู้ซื้อเห็นตำแหน่งประมาณ | พิกัดสาธารณะถูกปัดประมาณ 100–300 ม. |
| ที่อยู่จริง | แยกจาก ProductModel; แสดงเฉพาะสิทธิ์ owner หรือ buyer หลัง meetup accepted |
| ลงประกาศ | เพิ่ม/แก้/ซ่อน/ขาย/จอง; รองรับขาย แลกเปลี่ยน และบริจาค |
| ตะกร้าและออเดอร์ | จัดกลุ่มตามผู้ขาย; สั่งซื้อหนึ่งรายการต่อผู้ขาย; กันสินค้าซ้ำ |
| การกันขายซ้ำ | สร้างออเดอร์แล้วสินค้าเป็น reserved; complete เป็น sold; cancel กลับ available |
| สถานะออเดอร์ | pending, completed, cancelled, disputed; บันทึก OrderEvent ทุกการเปลี่ยน |
| การชำระ | บันทึก cashOnHandover หรือ transferOnHandover เท่านั้น ไม่มีเก็บเงิน |
| แชทและนัดรับ | ข้อความ รูป สนทนานัด Meetup และแชร์ที่อยู่หลังตกลง |
| รีวิว | บันทึกใน AppState/เครื่อง; คะแนนและจำนวนคำนวณจาก ReviewModel จริง |
| รายงานและแอดมิน | รองรับ report, block, suspension, dispute และ action ตรวจสอบสิทธิ์ฝั่ง client |
| แจ้งเตือนในแอป | สร้าง notification และ area subscription ในแอป และเก็บในเครื่อง |
| Push notification | ยังไม่มี FCM/APNs หรือ background delivery |

## 3. Local persistence

รายการดังต่อไปนี้คงอยู่หลังปิดและเปิดแอปใหม่:

- users และ mock credentials แบบ salted SHA-256 hash
- current session
- products และ private exact-location map แยกจาก JSON ของ ProductModel
- cart
- orders และ OrderEvent
- reviews
- conversations, messages และรูปที่เก็บเป็นไฟล์
- meetup agreements
- reports, blocks, suspension reasons
- notifications และ area subscriptions
- safety acknowledgments
- sequence counters

ใช้ SharedPreferences เป็น local key-value store และ JSON envelope
`dolp.persistence.v1` พร้อม schema version 1

### ข้อจำกัดบนแพลตฟอร์ม

- Android/iOS เก็บรูปไบต์ในโฟลเดอร์ application support แยกจาก JSON
- Web เก็บ structured state ใน browser แต่รูป bytes อยู่ในหน่วยความจำและหายหลัง reload
- ข้อมูลในเครื่องไม่ซิงก์กับอุปกรณ์อื่นหรือ backend
- ไฟล์ทั้งหมดยังไม่ได้เข้ารหัสครบชุด
- รหัสผ่าน mock ไม่เก็บ plaintext แต่ production authentication ต้องอยู่ฝั่ง server
- OTP ชั่วคราวไม่ถูกบันทึกถาวร
- ข้อมูลเสียหายจะสำรองเป็น key `dolp.persistence.corrupted.<timestamp>` และ seed ใหม่

## 4. ผลการทดสอบอัตโนมัติ

| รายการ | ผล |
|---|---|
| `flutter pub get` | ผ่าน |
| `flutter analyze` | ผ่าน ไม่มี issues |
| `flutter test` | ผ่าน 86 tests |
| `flutter build apk --debug` | ผ่าน |
| `flutter build web` | ผ่าน |
| Persistence restart tests | ผ่าน |
| Corruption/migration tests | ผ่าน |
| Password/session tests | ผ่าน |
| Layout stress tests | ผ่าน 320/360 px และ text scale |

การทดสอบเป็น unit/widget/build; ยังไม่ถือว่าเป็นการทดสอบการใช้งานจริง

## 5. สิ่งที่ตรวจบนเครื่องจริงยังไม่ครบ

- เปิด Guest สมัครสมาชิก และขออนุญาตตำแหน่ง
- เปลี่ยนรัศมีและสลับแผนที่
- ลงประกาศกับบัญชีผู้ขายและยืนยันมุมมองของผู้ซื้อ
- เสนอ/ตอบ meetup และแชร์ที่อยู่จริง
- สั่งสินค้าจาก 2 ผู้ขาย
- รับของ รีวิว และทดสอบรีวิวซ้ำ
- หน้ามุมมอง member/guest และ route admin
- member รายงานและ admin ระงับบัญชี
- notification ใหม่ใน/นอก radius
- สีและไอคอน dolp บนหน้าจอจริง
- กล้อง ภาพ แชท location permissions และ lifecycle ปิดแอปกะทันหัน

## 6. สิ่งที่ยังต้องเตรียมสำหรับ backend

ต้องเตรียมฝั่ง production แยกต่างหาก:

1. API และ database สำหรับ users, listings, orders, reviews, reports, chats, meetups
2. PostgreSQL หรือฐานข้อมูลเดียวกัน พร้อม migration และ audit log
3. Auth ด้วยเบอร์โทรและ SMS OTP provider
4. JWT/session, refresh token, server-side authorization และ rate limiting
5. Object storage สำหรับรูปสินค้า/รูปแชท; ขนาดและชนิดไฟล์ตรวจบน server
6. Push notification backend และ FCM/APNs สำหรับ Android/iOS
7. Payment provider หรือแนวทางยืนยันการโอนที่ปลอดภัย
8. Location privacy: เก็บพิกัดสาธารณะ/พิกัดจริงแยก ไม่ส่งที่อยู่ก่อน accepted
9. E2E/location/permission tests บน emulator และอุปกรณ์จริง
10. Policy สำหรับ retention, deletion, backup, corruption และ GDPR/privacy

การใช้ local persistence ช่วยเก็บข้อมูล prototype ต่อ restart แต่ไม่เป็น backend,
ไม่ใช้ร่วมกันหลายอุปกรณ์ และไม่สามารถรับรองสิทธิ์ security ให้ production ได้
