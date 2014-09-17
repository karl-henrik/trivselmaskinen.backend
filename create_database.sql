/*

This creates the schemas, tables, and procedures for trivselmaskinen database.
Run this script in SSMS in a database of choice to get the sample.

This will be put into a VS/SQL Server Data Tools/SQL Project and a database will be put into a "Windows Azure SQL Database".

Views and procedures to fullfill the data contracts will be created.

*/
-- USE master;
-- GO
-- DROP DATABASE TrivselMatareDB;
-- GO
-- CREATE DATABASE TrivselMatareDB;
-- GO
-- USE TrivselMatareDB;
-- GO
CREATE SCHEMA DeviceLayer;
GO
CREATE SCHEMA ServiceLayer;
GO
CREATE TABLE ServiceLayer.Questions
(
	QuestionID int NOT NULL IDENTITY(1,1) CONSTRAINT pk_ServiceLayer_Questions PRIMARY KEY CLUSTERED,
	Question nvarchar(max) NOT NULL,
	Created datetime2 NOT NULL CONSTRAINT df_ServiceLayer_Questions_Created DEFAULT(sysdatetime())	
);
CREATE TABLE ServiceLayer.Devices
(
	DeviceID int NOT NULL IDENTITY(1,1) CONSTRAINT pk_ServiceLayer_Devices PRIMARY KEY CLUSTERED,
	DeviceName nvarchar(max) NOT NULL ,
	DeviceToken uniqueidentifier NOT NULL CONSTRAINT df_ServiceLayer_Devices_DeviceToken DEFAULT(newid()),
	CreatedPosition geography NULL,
	LatestPosition geography NULL,
	Created datetime2 NOT NULL CONSTRAINT df_ServiceLayer_Devices_Created DEFAULT(sysdatetime()),
	Approved datetime2 NULL
);
CREATE TABLE ServiceLayer.Locations
(
	LocationID int NOT NULL IDENTITY(1,1) CONSTRAINT pk_ServiceLayer_Locations PRIMARY KEY CLUSTERED,
	Location nvarchar(max) NOT NULL,
	Position geography NULL,
	Created datetime2 NOT NULL CONSTRAINT df_ServiceLayer_Locations_Created DEFAULT(sysdatetime())	
);
CREATE TABLE ServiceLayer.QuestionTypes
(
	QuestionTypeID int NOT NULL IDENTITY(1,1) CONSTRAINT pk_ServiceLayer_QuestionTypes PRIMARY KEY CLUSTERED,
	QuestionType nvarchar(max) NOT NULL,
	Created datetime2 NOT NULL CONSTRAINT df_ServiceLayer_QuestionTypes_Created DEFAULT(sysdatetime())	
);
GO
CREATE TABLE ServiceLayer.QuestionTypeValues
(
	QuestionTypeID int NOT NULL,
	Value decimal(4,3) NOT NULL,
	ValueLabel nvarchar(max) NOT NULL,
	Created datetime2 NOT NULL CONSTRAINT df_ServiceLayer_QuestionTypeValues_Created DEFAULT(sysdatetime()),
	CONSTRAINT pk_ServiceLayer_QuestionTypeValues 
		PRIMARY KEY CLUSTERED(QuestionTypeID, Value),
	CONSTRAINT fk_ServiceLayer_QuestionTypeValues_QuestionType 
		FOREIGN KEY (QuestionTypeID) REFERENCES ServiceLayer.QuestionTypes(QuestionTypeID),
	CONSTRAINT ck_ServiceLayer_QuestionTypeValues_Value 
		CHECK(Value BETWEEN -1 AND 1)
);
CREATE TABLE ServiceLayer.QuestionScenarios
(
	QuestionScenarioID int NOT NULL IDENTITY(1,1) CONSTRAINT pk_ServiceLayer_QuestionScenarios PRIMARY KEY CLUSTERED,
	LocationID int NOT NULL 
		CONSTRAINT fk_ServiceLayer_QuestionScenarios_Location 
		FOREIGN KEY REFERENCES ServiceLayer.Locations(LocationID),
	QuestionID int NOT NULL
		CONSTRAINT fk_ServiceLayer_QuestionScenarios_Question 
		FOREIGN KEY REFERENCES ServiceLayer.Questions(QuestionID),
	QuestionTypeID int NOT NULL
		CONSTRAINT fk_ServiceLayer_QuestionScenarios_QuestionType 
		FOREIGN KEY REFERENCES ServiceLayer.QuestionTypes(QuestionTypeID),
	Created datetime2 NOT NULL CONSTRAINT df_ServiceLayer_QuestionScenarios_Created DEFAULT(sysdatetime())
);
GO
CREATE TABLE ServiceLayer.QuestionScenarioDevices
(
	QuestionScenarioID int NOT NULL
		CONSTRAINT fk_ServiceLayer_QuestionScenarioDevices_QuestionScenario 
		FOREIGN KEY REFERENCES ServiceLayer.QuestionScenarios(QuestionScenarioID),
	DeviceID int NOT NULL
		CONSTRAINT fk_ServiceLayer_QuestionScenarios_Device 
		FOREIGN KEY REFERENCES ServiceLayer.Devices(DeviceID),
	Created datetime2 NOT NULL CONSTRAINT df_ServiceLayer_QuestionScenarioDevices_Created DEFAULT(sysdatetime()),
		CONSTRAINT pk_ServiceLayer_QuestionScenarioDevices 
		PRIMARY KEY CLUSTERED (QuestionScenarioID, DeviceID)
);
GO
CREATE TABLE DeviceLayer.RawValues
(
	QuestionScenarioID int NOT NULL
		CONSTRAINT fk_DeviceLayer_RawValues_QuestionScenario 
		FOREIGN KEY REFERENCES ServiceLayer.QuestionScenarios(QuestionScenarioID),
	ValueTime datetime2 NOT NULL,
	DeviceID int NOT NULL
		CONSTRAINT fk_DeviceLayer_RawValues_Device 
		FOREIGN KEY REFERENCES ServiceLayer.Devices(DeviceID),
	Value decimal(4,3) NOT NULL,
	Position geography NULL,
	Created datetime2 NOT NULL CONSTRAINT df_DeviceLayer_RawValues_Created DEFAULT(sysdatetime()),
	CONSTRAINT pk_DeviceLayer_RawValues PRIMARY KEY CLUSTERED (QuestionScenarioID, ValueTime, DeviceID),
	CONSTRAINT ck_DeviceLayer_RawValues_Value CHECK (Value BETWEEN -1 AND 1)
);
GO
CREATE TYPE DeviceLayer.paramRawValues AS TABLE (
	DeviceName nvarchar(max) NOT NULL,
	DeviceToken nvarchar(max) NOT NULL,
	Question int NOT NULL,
	Value decimal(4,3) NOT NULL CHECK(Value BETWEEN -1 AND 1),
	ValueTimeStamp datetime2 NOT NULL,
	Position nvarchar(max) NULL
)
GO
CREATE PROCEDURE DeviceLayer.addRawValues 
	@Values DeviceLayer.paramRawValues READONLY
AS
BEGIN
-- Do some logic to make sure the values are genuine and ready to be inserted into the table.
-- Do not insert duplicates!
-- Right now it only returns a set of the set-parameter.
-- @values is a TVP, Table Valued Parameter. And it requires the CREATE TYPE as the custom datatype must be defined when working with TVPs.
/*
-- Sample code for using the procedure
DECLARE @values DeviceLayer.paramRawValues

INSERT INTO @values
VALUES 
	( 'Ett','One',1,-1,sysdatetime(),'15.213 60.123' )
INSERT INTO @values
VALUES 
	( 'Två','Two',2,-0.333,sysdatetime(),'15.213 60.123' )
INSERT INTO @values
VALUES 
	( 'Tre','Three',3,0.333,sysdatetime(),'15.213 60.123' ), 
	( 'Fyra','Four',4,1,sysdatetime(),'15.213 60.123' )

EXEC DeviceLayer.addRawValues 
	@Values = @values
*/
SELECT * FROM @Values
END
GO
CREATE PROCEDURE DeviceLayer.addRawValue
	@DeviceID int,
	@QuestionID int,
	@ValueTime datetime2,
	@Value decimal(4,3),
	@Position geography NULL
AS
BEGIN
BEGIN TRY
INSERT INTO DeviceLayer.RawValues(
	DeviceID,
	QuestionScenarioID,
	ValueTime,
	Value,
	Position
)
VALUES(
	@DeviceID,
	@QuestionID,
	@ValueTime,
	@Value,
	@Position
)
RETURN 0
END TRY
BEGIN CATCH
RETURN -1
END CATCH
END
GO
CREATE PROCEDURE ServiceLayer.addDevice
	@DeviceName nvarchar(max),
	@CreatedPosition geography NULL,
	@DeviceToken nvarchar(max) NULL OUTPUT
AS
BEGIN
DECLARE @DeviceID int
BEGIN TRY
INSERT INTO ServiceLayer.Devices(
	DeviceName,
	CreatedPosition,
	LatestPosition
)
VALUES(
	@DeviceName,
	@CreatedPosition,
	@CreatedPosition
)
SET @DeviceID = SCOPE_IDENTITY()
SELECT @DeviceToken = CAST(DeviceToken as nvarchar(max)) FROM ServiceLayer.Devices
RETURN 0
END TRY
BEGIN CATCH
RETURN -1
END CATCH
END
GO
CREATE PROCEDURE ServiceLayer.modDevice
	@DeviceName nvarchar(max),
	@DeviceToken nvarchar(max),
	@LatestPosition geography NULL,
	@Approved datetime2 NULL
AS
BEGIN
DECLARE @DeviceID int, @PreviousPosition geography, @PreviousApproved datetime2
BEGIN TRY
SELECT @DeviceID = DeviceID, @PreviousPosition = LatestPosition, @PreviousApproved = Approved FROM ServiceLayer.Devices WHERE DeviceName = @DeviceName AND DeviceToken = CAST(@DeviceToken as uniqueidentifier)
UPDATE ServiceLayer.Devices
SET LatestPosition = ISNULL(@LatestPosition, @PreviousPosition), Approved = ISNULL(@Approved, @PreviousApproved)
WHERE DeviceID = @DeviceID
RETURN 0
END TRY
BEGIN CATCH
RETURN -1
END CATCH
END
GO
CREATE PROCEDURE ServiceLayer.delDevice
	@DeviceName nvarchar(max),
	@DeviceToken nvarchar(max)
AS
BEGIN
BEGIN TRY
UPDATE ServiceLayer.Devices
SET Approved = NULL
WHERE DeviceName = @DeviceName AND DeviceToken = CAST(@DeviceToken as uniqueidentifier)
RETURN 0
END TRY
BEGIN CATCH
RETURN -1
END CATCH
END
