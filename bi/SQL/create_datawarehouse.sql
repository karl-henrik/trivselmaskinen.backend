-- USE master;
-- GO
-- DROP DATABASE TrivselDW;
-- GO
-- CREATE DATABASE TrivselDW;
-- GO
-- USE TrivselDW;
-- GO

CREATE TABLE DimDate
(
	DateID int NOT NULL CONSTRAINT pk_DimDate PRIMARY KEY CLUSTERED,
	FullDate smalldatetime NULL,
	[DayOfWeek] tinyint NULL,
	DayNumInMonth tinyint NULL,
	DayNumOverall smallint NULL,
	[DayName] varchar(9) NULL,
	DayAbbrev char(4) NULL,
	WeekDayFlag char(1) NULL,
	WeekNumInYear tinyint NULL,
	WeekNumOverall smallint NULL,
	WeekBeginDate smalldatetime NULL,
	WeekBeginDateKey int NULL,
	[Month] tinyint NULL,
	MonthNumOverall smallint NULL,
	[MonthName] varchar(9) NULL,
	MonthAbbrev char(3) NULL,
	[Quarter] tinyint NULL,
	[Year] int NULL,
	YearMo int NULL,
	FiscalMonth tinyint NULL,
	FiscalQuarter tinyint NULL,
	FiscalYear smallint NULL,
	LastDayInMonth_flag char(1) NULL,
	SameDayYearAgo_date smalldatetime NULL
);
GO

CREATE TABLE DimTime
(
	TimeID int NOT NULL CONSTRAINT pk_DimTime PRIMARY KEY CLUSTERED,
	[Time] char(8) NOT NULL,
	[Hour] int NOT NULL,
	[Minute] int NOT NULL,
	[Second] int NOT NULL,
	Period varchar(20) NOT NULL
);
GO

CREATE TABLE DimLocation
(
	LocationID int NOT NULL IDENTITY(1,1) CONSTRAINT pk_DimLocation PRIMARY KEY CLUSTERED,
	Latitude varchar(11) NOT NULL,
	Longitude varchar(11) NOT NULL
);
GO

CREATE TABLE DimQuestion
(
	QuestionID int NOT NULL CONSTRAINT pk_DimQuestion PRIMARY KEY CLUSTERED,
	Question nvarchar(max) NOT NULL,
	QuestionType nvarchar(max) NOT NULL
);
GO

CREATE TABLE DimQuestionValue
(
	QuestionTypeID int NOT NULL,
	Value decimal(4, 3) NOT NULL,
	ValueLabel nvarchar(max) NOT NULL
    CONSTRAINT pk_DimQuestionValue
	    PRIMARY KEY CLUSTERED (QuestionTypeID ASC, Value ASC)
);
GO

CREATE TABLE FactAnswer
(
	QuestionID int NOT NULL,
	QuestionTypeID int NOT NULL,
	LocationID int NOT NULL,
	DateID int NOT NULL,
	TimeID int NOT NULL,
	ValueTime datetime2(7) NOT NULL,
	Value decimal(4, 3) NOT NULL
    CONSTRAINT pk_FactAnswer 
	    PRIMARY KEY CLUSTERED (QuestionID ASC, QuestionTypeID ASC, LocationID ASC, DateID ASC, TimeID ASC, ValueTime ASC),
	CONSTRAINT fk_FactAnswer_QuestionID 
	    FOREIGN KEY(QuestionID) REFERENCES DimQuestion (QuestionID),
	CONSTRAINT fk_FactAnswer_QuestionValueID
	    FOREIGN KEY(QuestionTypeID, Value) REFERENCES DimQuestionValue (QuestionTypeID, Value),
	CONSTRAINT fk_FactAnswer_LocationID
	    FOREIGN KEY(LocationID) REFERENCES DimLocation (LocationID),
	CONSTRAINT fk_FactAnswer_DateID
	    FOREIGN KEY(DateID) REFERENCES DimDate (DateID),
	CONSTRAINT fk_FactAnswer_TimeID
	    FOREIGN KEY(TimeID) REFERENCES DimTime (TimeID)
);
GO

WITH a(col) AS (SELECT NULL UNION ALL SELECT NULL UNION ALL SELECT NULL UNION ALL SELECT NULL UNION ALL SELECT NULL), 
b1 (col) AS (SELECT NULL FROM a a1 CROSS JOIN a a2), 
b2 (col) AS (SELECT NULL FROM b1 a1 CROSS JOIN b1 a2), 
b3 (col) AS (SELECT NULL FROM b2 a1 CROSS JOIN b2 a2), 
nums(num) AS (SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1 FROM b3),
times(hhmmss) AS (SELECT CAST(DATEADD(second, num, '00:00:00') AS TIME(0)) FROM nums WHERE num < 86400),
dimTempTime([TimeID], [Time], [Hour], [Minute], [Second]) AS (
SELECT 
	DATEPART(HOUR, hhmmss) * 10000 + DATEPART(MINUTE, hhmmss)* 100 + DATEPART(SECOND, hhmmss)*1, 
	hhmmss,
	DATEPART(HOUR, hhmmss), 
	DATEPART(MINUTE, hhmmss), 
	DATEPART(SECOND, hhmmss)  
FROM times)

INSERT INTO DimTime([TimeID], [Time], [Hour], [Minute], [Second], [Period])
SELECT [TimeID], [Time], [Hour], [Minute], [Second], 
  CASE
	WHEN [Hour] < 6 OR [Hour] > 21 THEN 'Natt'
	WHEN [Hour] BETWEEN 17 AND 21 THEN 'Kväll'
	WHEN [Hour] BETWEEN 6 AND 12 THEN 'Förmiddag'
	ELSE 'Eftermiddag' 
  END AS Period
FROM dimTempTime ORDER BY 1 ASC



