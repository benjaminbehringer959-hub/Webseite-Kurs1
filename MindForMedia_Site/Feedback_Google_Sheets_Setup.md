# Feedback to Google Sheets (Apps Script)

This sets up the feedback form on the Abschluss page so submissions go directly into a Google Sheet.

## 1) Create a Google Sheet
- Create a new sheet in Google Drive.
- Name it for example `Mind for Media Feedback`.
- Optional: rename the first tab to `Feedback` (recommended).

## 2) Open Apps Script
- In the sheet: Extensions -> Apps Script.
- Delete any placeholder code.
- Paste the script below.

```javascript
const SHEET_NAME = 'Feedback';

function doPost(e) {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const sheet = ss.getSheetByName(SHEET_NAME) || ss.insertSheet(SHEET_NAME);
  const data = e && e.parameter ? e.parameter : {};

  const row = [
    new Date(),
    data.page || '',
    data.satisfaction || '',
    data.highlight || '',
    data.improvements || '',
  ];

  sheet.appendRow(row);
  return ContentService.createTextOutput('ok');
}
```

## 3) Deploy as Web App
- Deploy -> New deployment -> Select type: Web app.
- Execute as: Me.
- Who has access: Anyone.
- Deploy and copy the Web App URL.

## 4) Paste the URL into the site
- Open `MindForMedia_Site/build_site.ps1`.
- Replace the `feedbackEndpoint` URL with your Apps Script URL.
- Run the build script to regenerate the site.

## 5) Test
- Open `MindForMedia_Site/site/abschluss.html`.
- Submit the feedback form and check the sheet.
