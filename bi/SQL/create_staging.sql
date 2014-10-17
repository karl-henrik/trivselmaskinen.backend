-- USE master;
-- GO
-- DROP DATABASE TrivselStaging;
-- GO
-- CREATE DATABASE TrivselStaging;
-- GO
-- USE TrivselStaging;
-- GO

CREATE TABLE Staging_RawValues
(
	QuestionScenarioID int NOT NULL,
	ValueTime datetime2(7) NOT NULL,
	DeviceID int NOT NULL,
	Value decimal(4, 3) NOT NULL,
	Position geography NULL
);
GO

CREATE TABLE Staging_QuestionTypeValues
(
	QuestionTypeID int NOT NULL,
	Value decimal(4, 3) NOT NULL,
	ValueLabel nvarchar(max) NOT NULL
);
GO

CREATE TABLE Staging_QuestionTypes
(
	QuestionTypeID int NOT NULL,
	QuestionType nvarchar(max) NOT NULL
);
GO

CREATE TABLE Staging_QuestionScenarios
(
	QuestionScenarioID int NOT NULL,
	LocationID int NOT NULL,
	QuestionID int NOT NULL,
	QuestionTypeID int NOT NULL
);
GO

CREATE TABLE Staging_Questions
(
	QuestionID int NOT NULL,
	Question nvarchar(max) NOT NULL
);
GO


CREATE VIEW view_Locations AS
SELECT 
  ISNULL(LTRIM(STR(Position.Lat, 11, 5)), 'Unknown') AS [Latitude], 
  ISNULL(LTRIM(STR(Position.Long, 11, 5)), 'Unknown') AS [Longitude]
FROM Staging_RawValues;
GO

CREATE VIEW view_Questions AS
SELECT 
  qs.QuestionScenarioID, 
  q.Question, 
  qt.QuestionType
FROM Staging_QuestionScenarios AS qs
INNER JOIN Staging_Questions AS q ON q.QuestionID = qs.QuestionID
INNER JOIN Staging_QuestionTypes AS qt ON qt.QuestionTypeID = qs.QuestionTypeID;
GO

CREATE VIEW view_QuestionValues AS
SELECT
  qt.QuestionTypeID,
  qt.Value,
  qt.ValueLabel
FROM Staging_QuestionTypeValues AS qt;
GO

CREATE VIEW view_RawValues AS
SELECT 
  qs.QuestionScenarioID,
  qs.QuestionTypeID,
  REPLACE(CONVERT(CHAR(10), r.ValueTime, 126), '-', '') AS [DateID],
  DATEPART(hour, r.ValueTime) * 10000 + DATEPART(minute, r.ValueTime)* 100 + DATEPART(second, r.ValueTime)*1 AS [TimeID],
  r.ValueTime,
  r.Value,
  ISNULL(LTRIM(STR(Position.Lat, 11, 5)), 'Unknown') AS [Latitude], 
  ISNULL(LTRIM(STR(Position.Long, 11, 5)), 'Unknown') AS [Longitude]
FROM Staging_RawValues AS r
INNER JOIN Staging_QuestionScenarios AS qs ON qs.QuestionScenarioID = r.QuestionScenarioID
INNER JOIN Staging_Questions AS q ON q.QuestionID = qs.QuestionID;
GO
