#!/usr/bin/env python3
import base64
import json
import os
import time
import urllib.error
import urllib.request
from pathlib import Path
from typing import Dict, List

PROJECT_ID = os.environ.get('FIREBASE_PROJECT_ID', 'fiyatradar-611967')
PRODUCTS_FILE = Path('assets/fiyatradar_urunler.json')
COLLECTION = 'products'
BATCH_GET_SIZE = 100
COMMIT_SIZE = 250
TOKEN_URI = 'https://oauth2.googleapis.com/token'
SCOPE = 'https://www.googleapis.com/auth/datastore'


def _b64url(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).rstrip(b'=').decode('ascii')


def _load_service_account() -> Dict:
    raw_json = os.environ.get('FIREBASE_SERVICE_ACCOUNT_JSON')
    file_path = os.environ.get('GOOGLE_APPLICATION_CREDENTIALS')

    if raw_json:
        return json.loads(raw_json)
    if file_path and Path(file_path).exists():
        return json.loads(Path(file_path).read_text(encoding='utf-8'))

    raise RuntimeError(
        'Kimlik doğrulama bulunamadı. FIREBASE_SERVICE_ACCOUNT_JSON veya GOOGLE_APPLICATION_CREDENTIALS ayarlayın.'
    )


def _sign_rs256(private_key_pem: str, message: bytes) -> bytes:
    from cryptography.hazmat.primitives import hashes, serialization
    from cryptography.hazmat.primitives.asymmetric import padding

    private_key = serialization.load_pem_private_key(private_key_pem.encode('utf-8'), password=None)
    return private_key.sign(message, padding.PKCS1v15(), hashes.SHA256())


def _get_access_token(service_account: Dict) -> str:
    now = int(time.time())
    header = {'alg': 'RS256', 'typ': 'JWT'}
    payload = {
        'iss': service_account['client_email'],
        'scope': SCOPE,
        'aud': TOKEN_URI,
        'iat': now,
        'exp': now + 3600,
    }

    encoded_header = _b64url(json.dumps(header, separators=(',', ':')).encode('utf-8'))
    encoded_payload = _b64url(json.dumps(payload, separators=(',', ':')).encode('utf-8'))
    signing_input = f'{encoded_header}.{encoded_payload}'.encode('ascii')
    signature = _sign_rs256(service_account['private_key'], signing_input)
    assertion = f'{encoded_header}.{encoded_payload}.{_b64url(signature)}'

    body = urllib.parse.urlencode(
        {
            'grant_type': 'urn:ietf:params:oauth:grant-type:jwt-bearer',
            'assertion': assertion,
        }
    ).encode('utf-8')
    req = urllib.request.Request(TOKEN_URI, data=body, method='POST')
    req.add_header('Content-Type', 'application/x-www-form-urlencoded')

    with urllib.request.urlopen(req, timeout=30) as resp:
        token_resp = json.loads(resp.read().decode('utf-8'))
    return token_resp['access_token']


def _firestore_headers(token: str) -> Dict[str, str]:
    return {'Authorization': f'Bearer {token}', 'Content-Type': 'application/json'}


def _full_doc_name(barcode: str) -> str:
    return f'projects/{PROJECT_ID}/databases/(default)/documents/{COLLECTION}/{barcode}'


def _to_firestore_doc(raw: Dict) -> Dict:
    category = str(raw.get('category') or '').strip()
    fields = {
        'barcode': {'stringValue': str(raw.get('barcode') or '').strip()},
        'name': {'stringValue': str(raw.get('name') or '').strip()},
        'brand': {'stringValue': str(raw.get('brand_name') or '').strip()},
        'imageUrl': {'stringValue': str(raw.get('image_url') or '').strip()},
        'category': {'stringValue': category},
        'category_legacy': {'stringValue': category},
        'categories': {'arrayValue': {'values': [{'stringValue': category}] if category else []}},
    }
    return {'fields': fields}


def _post_json(url: str, payload: Dict, headers: Dict[str, str]) -> Dict:
    req = urllib.request.Request(url, data=json.dumps(payload).encode('utf-8'), method='POST')
    for key, value in headers.items():
        req.add_header(key, value)
    with urllib.request.urlopen(req, timeout=60) as resp:
        return json.loads(resp.read().decode('utf-8'))


def _existing_barcodes(rows: List[Dict], headers: Dict[str, str]) -> set[str]:
    url = f'https://firestore.googleapis.com/v1/projects/{PROJECT_ID}/databases/(default)/documents:batchGet'
    doc_names = [_full_doc_name(str(r['barcode']).strip()) for r in rows if str(r.get('barcode') or '').strip()]
    if not doc_names:
        return set()

    existing = set()
    for i in range(0, len(doc_names), BATCH_GET_SIZE):
        payload = {'documents': doc_names[i : i + BATCH_GET_SIZE]}
        req = urllib.request.Request(url, data=json.dumps(payload).encode('utf-8'), method='POST')
        for key, value in headers.items():
            req.add_header(key, value)
        with urllib.request.urlopen(req, timeout=60) as resp:
            for line in resp:
                if not line.strip():
                    continue
                item = json.loads(line.decode('utf-8'))
                found = item.get('found', {})
                name = found.get('name', '')
                if name:
                    existing.add(name.rsplit('/', 1)[-1])
    return existing


def _commit_new(rows: List[Dict], headers: Dict[str, str]) -> int:
    url = f'https://firestore.googleapis.com/v1/projects/{PROJECT_ID}/databases/(default)/documents:commit'
    inserted = 0

    for i in range(0, len(rows), COMMIT_SIZE):
        chunk = rows[i : i + COMMIT_SIZE]
        writes = []
        for row in chunk:
            barcode = str(row.get('barcode') or '').strip()
            if not barcode:
                continue
            doc = _to_firestore_doc(row)
            writes.append(
                {
                    'update': {'name': _full_doc_name(barcode), 'fields': doc['fields']},
                    'updateMask': {
                        'fieldPaths': ['barcode', 'name', 'brand', 'imageUrl', 'category', 'category_legacy', 'categories']
                    },
                }
            )

        if not writes:
            continue

        _post_json(url, {'writes': writes}, headers)
        inserted += len(writes)

    return inserted


def main() -> None:
    if not PRODUCTS_FILE.exists():
        raise FileNotFoundError(f'Dosya bulunamadı: {PRODUCTS_FILE}')

    rows = json.loads(PRODUCTS_FILE.read_text(encoding='utf-8'))
    if not isinstance(rows, list):
        raise ValueError('assets/fiyatradar_urunler.json bir dizi (array) formatında olmalı.')

    service_account = _load_service_account()
    token = _get_access_token(service_account)
    headers = _firestore_headers(token)

    existing = _existing_barcodes(rows, headers)
    new_rows = [r for r in rows if str(r.get('barcode') or '').strip() and str(r.get('barcode')).strip() not in existing]

    inserted = _commit_new(new_rows, headers)
    print(f'Yeni eklenen ürün sayısı: {inserted}')


if __name__ == '__main__':
    main()
