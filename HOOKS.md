# Integration with Google Spreadsheet

## install

```bash
npm install
node app.js
```

database:

```bash
pg_dump -s postgresql://localhost/timesheet > sql/timesheet.sql
```

## Setup

creates two routes:

* /spreadsheet/snapshot/SPREADSHEET_ID
* /spreadsheet/change/SPREADSHEET_ID

## Testing

```bash
curl -X POST http://localhost:3000/spreadsheet/snapshot/1234 -H "Content-Type: application/json" -d @coderbunker-intranet-timesheet.json
```