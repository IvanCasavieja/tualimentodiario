const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { onSchedule } = require('firebase-functions/v2/scheduler');
const { setGlobalOptions } = require('firebase-functions/v2');
const { getMessaging } = require('firebase-admin/messaging');
const { getFirestore } = require('firebase-admin/firestore');
const { initializeApp } = require('firebase-admin/app');

initializeApp();

const db = getFirestore();
const langs = ['es', 'en', 'pt', 'it'];

// Usa la misma región que tu Firestore (ajusta si tu proyecto está en otra).
setGlobalOptions({ region: 'southamerica-east1' });

// Envía push al crear un dailyFoods publicado y visible hoy.
exports.sendDailyFoodPush = onDocumentCreated('dailyFoods/{id}', async (event) => {
  const data = event.data?.data();
  if (!data) return;
  if (data.isPublished !== true) return;
  const today = isoToday();
  if ((data.date ?? '') > today) return; // todavía no debe mostrarse
  await sendForDoc(event.params.id, data);
});

// Opcional: envía cada medianoche para los contenidos programados para hoy.
exports.sendDailyFoodPushScheduled = onSchedule('0 0 * * *', async () => {
  const today = isoToday();
  const snap = await db
    .collection('dailyFoods')
    .where('isPublished', '==', true)
    .where('date', '==', today)
    .get();
  for (const doc of snap.docs) {
    await sendForDoc(doc.id, doc.data());
  }
});

async function sendForDoc(id, data) {
  const translations = data.translations || {};
  const promises = [];
  for (const lang of langs) {
    const tr = translations[lang] || {};
    const title = tr.title || 'Nuevo alimento diario';
    const body = tr.verse || '';
    promises.push(
      getMessaging().send({
        topic: `lang-${lang}`,
        notification: { title, body },
        data: { dailyFoodId: id, lang },
      }),
    );
  }
  await Promise.all(promises);
}

function isoToday() {
  return new Date().toISOString().slice(0, 10); // yyyy-MM-dd
}
