# Backend санал, шийдэл (оптималь загвар)

Энэ баримт бичиг нь Mobile Timekeeping аппын сервер талын шийдлийг богино хугацаанд бүтээх, масштаблах, мөн зардлыг оновчтой байлгах зорилгоор санал болгосон архитектур юм.

## Гол шаардлагууд
- Роль: Manager, Worker (RBAC, multi-tenant)
- Цаг бүртгэл (clock-in/out), чөлөөний хүсэлт, баталгаажуулалт
- Chat + файл хавсаргалт, realtime
- 7 хоногийн тайлан, Excel экспорт
- Map сектор (polygon/geo), гео-шаардлага (geofence) шалгалт
- Offline бодлого (мобайл талд кеш/даалгавар дараалал)

## Санал болгож буй стек (Recommend)
- Supabase (Managed Postgres + Auth + Realtime + Storage + Edge Functions)
  - DB: Postgres + PostGIS (гео өгөгдөл)
  - Auth: Supabase Auth (email/phone, OAuth), Row Level Security (RLS)
  - Realtime: Channels (chat, мэдэгдэл)
  - Storage: Файл/зураг (chat, leave attachments, тайлангийн файл)
  - Edge Functions + Scheduled jobs: Clock-in/out баталгаажуулалт, тайлан Excel үүсгэх
- Яагаад?
  - Postgres/SQL – тайлан, join, aggregation-д илүү тохиромжтой
  - RLS – multi-tenant ба роль-цоожлогоо код бичихгүйгээр бодлогын түвшинд
  - PostGIS – сектор polygon, байршлын шалгалтод бэлэн
  - Realtime – chat болон статус шинэчлэл
  - Developer experience – Flutter-тэй `supabase_flutter` SDK амархан

Альтернативууд:
- Firebase (Firestore + Functions + Storage)
  - Давуу тал: хурдан эхлүүлэх, оффлайн sync суурьтай
  - Сул тал: нарийн тайлан/aggregation, гео-полигон, SQL хэрэгцээтэй үед төвөгтэй болно
- Custom backend (NestJS/FastAPI + Postgres + S3 + Redis)
  - Давуу тал: бүрэн хяналт, уян хатан
  - Сул тал: DevOps зардал өндөр, эхлүүлэх хугацаа урт

## Data model (ERD санаа)

```
organizations ||--o{ profiles : has
organizations ||--o{ projects : has
organizations ||--o{ channels : has
organizations ||--o{ payroll_runs : has

auth_users ||--|| profiles : maps
profiles ||--o{ time_entries : has
profiles ||--o{ leave_requests : has
profiles ||--o{ messages : writes

projects ||--o{ time_entries : used_in
channels ||--o{ messages : contains

organizations {
  uuid id PK
  text name
  timestamptz created_at
}
profiles {
  uuid id PK  // mirrors auth.users.id
  uuid org_id FK
  text role    // manager|worker
  text full_name
  text phone
  timestamptz created_at
}
projects {
  uuid id PK
  uuid org_id FK
  text name
  geometry region  // polygon (PostGIS)
  timestamptz created_at
}
time_entries {
  uuid id PK
  uuid org_id FK
  uuid user_id FK
  uuid project_id FK
  timestamptz clock_in
  timestamptz clock_out
  geometry clock_in_loc  // point
  geometry clock_out_loc // point
  text status  // pending|approved|rejected
  jsonb meta   // device, notes, source
  timestamptz created_at
}
leave_requests {
  uuid id PK
  uuid org_id FK
  uuid user_id FK
  text type    // annual|sick|other
  daterange period
  text status  // pending|approved|rejected
  uuid approver_id FK
  text reason
  timestamptz created_at
}
channels {
  uuid id PK
  uuid org_id FK
  text type    // direct|group|project
  text name
  timestamptz created_at
}
messages {
  uuid id PK
  uuid org_id FK
  uuid channel_id FK
  uuid author_id FK
  text content
  jsonb files   // array of storage paths
  timestamptz created_at
}
payroll_runs {
  uuid id PK
  uuid org_id FK
  daterange period
  text file_url
  jsonb summary
  timestamptz created_at
}
```

Гол индексүүд:
- time_entries: (org_id, user_id, clock_in), (org_id, project_id, clock_in), GIST(geometry)
- leave_requests: (org_id, user_id, period)
- messages: (org_id, channel_id, created_at desc)

## RLS бодлого (үлгэр)
- Бүх хүснэгтүүд `org_id = (auth.jwt() ->> 'org_id')::uuid` шалгалттай.
- profiles: хэрэглэгч өөрийн мөрийг унших/засах; manager – тухайн org-ийн бүх хүнийг харах
- time_entries: worker – өөрийнхөө мөр үүсгэх/унших; manager – org-ийн бүх мөр унших/засах/батлах
- leave_requests: worker – өөрийн хүсэлтээ үүсгэх/унших; manager – org-ийн бүх хүсэлтийг харах/батлах
- channels/messages: гишүүнчлэлд суурилсан унших/бичих бодлого

## Функцүүд (Edge Functions/RPC)
- rpc.clock_in(user_location)
  - Оролт: lat, lon, project_id
  - Логик: sector polygon-т багтаж буй эсэх `ST_Contains(project.region, point)`; active open entry байгаа эсэх шалгах
  - Гаралт: шинэ эсвэл update хийсэн entry JSON
- rpc.clock_out(user_location)
- rpc.request_leave(start_date, end_date, type, reason)
- edge: reports/generate_weekly(period, org_id)
  - Excel үүсгээд signed URL буцаах (xlsx lib)
- edge: chat/signed_upload (pre-signed URL өгнө)

Scheduled jobs:
- Долоо хоног бүрийн тайлан generate (Edge function schedule)
- Хугацаа дууссан pending leave/time approvals-т сануулга

## Storage (Buckets)
- chat-attachments/{org_id}/{channel_id}/...
- leave-attachments/{org_id}/{leave_id}/...
- reports/{org_id}/{period}/report.xlsx (manager-д л унших эрх)

## Realtime
- Messages – channel бүрт live feed
- Approvals/Statuses – time_entries, leave_requests шинэчлэлд event push

## Offline бодлого (Flutter тал)
- Клиент талд локал queue/caching (ж: `isar`/`hive`) – clock-in/out, messages түр хадгалж, сүлжээ орж ирмэгц sync
- UI: queued state, conflict resolution (manager override rules)

## Тайлан, Excel
- Postgres агрегаци: ажилтнаар, төслөөр, цагийн төрөлөөр
- Edge function: Excel (xlsx) үүсгэх, Storage-д байрлуулж signed URL буцаах
- Нэмэлт: BigQuery/ClickHouse зэрэг OLAP-т экспорт (хожим)

## Аюулгүй байдал ба аудит
- JWT-д org_id, role claim (Supabase Custom JWT claims)
- Audit log триггер: critical хүснэгтүүд дээр INSERT/UPDATE/DELETE бүртгэл
- Файл хадгалалт: bucket policy-гаар org_id урьдчилсан нөхцөл, signed URL

## Release ба DevOps
- Supabase Hosted – хурдан эхлүүлж, бага Ops
- Орчны хувьсагч: Flutter `--dart-define` ашиглан URL/Keys дамжуулах
- Миграци: SQL миграци (db/schema.sql), seed
- Мониторинг: Supabase metrics, pg_stat_statements, Storage usage

## Зардал/Масштаб
- Dev/POC: Supabase free/Pro – хангалттай
- Масштаб: Postgres vertical scale + read replicas, Storage/CDN, Edge functions автоматаар масштаблана

## Next steps
1) Стек батлах (Supabase эсвэл өөр)
2) Schema SQL + RLS бодлого бэлдэх (миграци)
3) Edge functions (clock-in/out, reports) scaffold
4) Flutter app-д Supabase интеграц + auth flow
5) Offline queue

Хэрэв та Supabase сонговол, би нэг командын scaffolding-тай миграцийн суурийг нэмээд өгч чадна (db/schema, бодлого, sample functions).