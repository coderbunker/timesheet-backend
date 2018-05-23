# timesheet-backend
Timesheet Datawarehouse backend

See server/README.md for setup

# Timesheet Data Warehouse

Timesheet data warehouse is the infrastructure and backbone for Coderbunker’s freelancing system. The idea is to streamline and automate the process that record freelancers’ working hours for a number of purposes listed below. Technologies involved: Google Spreadsheet, API, PostgreSQL, Ethereum, and etc. The following flowchart describes the general data flow.

Google Spreadsheet > PostgreSQL Database > Aggregated View of Data > Ethereum > JSON > Local Database

This project is related to timesheet-dashboard-react.

- **Transaction**
- Payment via cryptocurrency

- **Freelancers’ Profile/History**
- Number of hours invested on each skill/technology/language
- Type of freelancing projects involved

- **Global File Sharing**
- Transfer of freelancers’ profile to another Coderbunker division
