import * as admin from 'firebase-admin';
import * as functions from 'firebase-functions';
import XLSX from 'xlsx';

type TimeEntry = {
  orgId: string;
  userId: string;
  projectId?: string;
  clockIn?: admin.firestore.Timestamp;
  clockOut?: admin.firestore.Timestamp;
  status: 'pending'|'approved'|'rejected';
};

type PayrollSummary = {
  totalHours: number;
  users: Record<string, { hours: number }>
};

admin.initializeApp();
const db = admin.firestore();

export const generateWeeklyReport = functions.pubsub
  .schedule('every monday 03:00')
  .timeZone('Asia/Ulaanbaatar')
  .onRun(async () => {
    const now = admin.firestore.Timestamp.now();
    const start = admin.firestore.Timestamp.fromDate(new Date(now.toDate().getTime() - 7 * 24 * 60 * 60 * 1000));

    const snap = await db
      .collection('time_entries')
      .where('clockIn', '>=', start)
      .where('clockIn', '<', now)
      .where('status', '==', 'approved')
      .get();

    const summary: PayrollSummary = { totalHours: 0, users: {} };

  snap.forEach((doc: admin.firestore.QueryDocumentSnapshot) => {
      const te = doc.data() as TimeEntry;
      if (!te.clockIn || !te.clockOut) return;
      const hours = (te.clockOut.toDate().getTime() - te.clockIn.toDate().getTime()) / 36e5;
      summary.totalHours += hours;
      summary.users[te.userId] = summary.users[te.userId] || { hours: 0 };
      summary.users[te.userId].hours += hours;
    });

    // Create simple Excel file
  const rows: (string | number)[][] = [['User ID', 'Hours']];
  Object.entries(summary.users).forEach(([uid, v]) => rows.push([uid, Number(v.hours.toFixed(2))]));
    const ws = XLSX.utils.aoa_to_sheet(rows);
    const wb = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(wb, ws, 'Weekly');

    const buf = XLSX.write(wb, { type: 'buffer', bookType: 'xlsx' }) as Buffer;

    // Store result in Storage
    const bucket = admin.storage().bucket();
    const filename = `payroll/${now.toDate().toISOString().slice(0,10)}.xlsx`;
    const file = bucket.file(filename);
    await file.save(buf, { contentType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' });

    await db.collection('payroll_runs').add({
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      filePath: filename,
      summary,
    });

    return null;
  });
