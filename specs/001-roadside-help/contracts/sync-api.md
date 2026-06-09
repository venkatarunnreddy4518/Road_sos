# API Contract: Helper Data Sync

This document defines the interface between the mobile application and the backend server for synchronizing helper data.

## Overview

The app performs a periodic sync (or a manual "Pull to Refresh") to update the local SQLite cache of helpers. The backend provides a curated list of helpers and supplements it with third-party data.

## Endpoint: GET `/v1/helpers/sync`

Retrieves the current dataset of helpers to be cached locally.

### Request Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `last_sync` | Timestamp | No | ISO 8601 timestamp of the last successful sync. If provided, the server MAY return only delta updates. |
| `api_key` | String | Yes | Authentication key for the application. |

### Response: 200 OK

**Content-Type**: `application/json`

#### Response Body

```json
{
  "metadata": {
    "sync_timestamp": "2026-06-09T10:00:00Z",
    "total_count": 150,
    "has_more": false
  },
  "helpers": [
    {
      "id": "h-12345",
      "name": "QuickFix Puncture Shop",
      "type": "PUNCTURE_SHOP",
      "latitude": 12.9716,
      "longitude": 77.5946,
      "phone": "+919876543210",
      "sms_capable": true,
      "opening_hours": "08:00-20:00",
      "source": "CURATED",
      "updated_at": "2026-06-08T15:30:00Z"
    },
    {
      "id": "h-67890",
      "name": "City Petrol Pump",
      "type": "PETROL_PUMP",
      "latitude": 12.9800,
      "longitude": 77.6000,
      "phone": "+911234567890",
      "sms_capable": false,
      "opening_hours": null,
      "source": "THIRD_PARTY",
      "updated_at": "2026-06-09T01:00:00Z"
    }
  ]
}
```

### Error Responses

- **401 Unauthorized**: Invalid or missing `api_key`.
- **429 Too Many Requests**: Sync rate limit exceeded.
- **500 Internal Server Error**: Unexpected server failure.

## Sync Logic (Client Side)

1. **Fetch**: Call `/v1/helpers/sync?last_sync={AppConfig.lastSyncTime}`.
2. **Parse**: Validate JSON structure and types.
3. **Merge**:
   - For each `helper` in response:
     - If `source == 'CURATED'`, `INSERT OR REPLACE` into SQLite.
     - If `source == 'THIRD_PARTY'`, `INSERT` only if `id` does not already exist.
4. **Update**: Set `AppConfig.lastSyncTime = metadata.sync_timestamp`.
