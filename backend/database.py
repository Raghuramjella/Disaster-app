import firebase_admin
from firebase_admin import credentials, firestore, storage
from config import FIREBASE_CREDENTIALS_PATH, FIREBASE_STORAGE_BUCKET

# Initialise Firebase once
cred = credentials.Certificate(FIREBASE_CREDENTIALS_PATH)
firebase_admin.initialize_app(cred, {"storageBucket": FIREBASE_STORAGE_BUCKET})

# Firestore client  (synchronous — FastAPI runs sync handlers in a thread pool)
db: firestore.Client = firestore.client()

# Firebase Storage bucket
bucket = storage.bucket()


def get_next_id(collection_name: str) -> int:
    """
    Auto-incrementing integer ID via a Firestore counters document.
    Thread-safe — uses a Firestore transaction.
    """
    counter_ref = db.collection("counters").document(collection_name)

    @firestore.transactional
    def _increment(transaction, ref):
        snapshot = ref.get(transaction=transaction)
        next_id = (snapshot.get("value") or 0) + 1
        transaction.set(ref, {"value": next_id})
        return next_id

    txn = db.transaction()
    return _increment(txn, counter_ref)
