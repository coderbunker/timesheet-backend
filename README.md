# timesheet-backend
Timesheet data warehouse backend

See [[INSTALL.md]] for setup

# timesheet data warehouse

Timesheet data warehouse is the infrastructure and backbone of Coderbunker’s freelancing system. The idea is to streamline and automate the process that record freelancers’ working hours for a number of purposes listed below. Technologies involved: Google Spreadsheet, API, PostgreSQL, Ethereum, and etc. The general dataflow is described below:

Google Spreadsheet > PostgreSQL Database > Aggregated View of Data > Ethereum > JSON > Local Database

**Transaction**
- Payment via cryptocurrency

**Freelancers’ Profile/History**
- Number of hours invested on each skill/technology/language
- Type of freelancing projects involved

**Global File Sharing**
- Transfer of freelancers’ profile to another Coderbunker division

This project is related to [timesheet-dashboard-react](https://github.com/coderbunker/timesheet-dashboard-react).
