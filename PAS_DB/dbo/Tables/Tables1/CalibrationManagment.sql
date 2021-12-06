CREATE TABLE [dbo].[CalibrationManagment] (
    [CalibrationId]       BIGINT          IDENTITY (1, 1) NOT NULL,
    [AssetRecordId]       BIGINT          NOT NULL,
    [LastCalibrationDate] DATETIME        NULL,
    [NextCalibrationDate] DATETIME        NULL,
    [LastCalibrationBy]   VARCHAR (50)    NULL,
    [VendorId]            BIGINT          NULL,
    [VendorName]          VARCHAR (100)   NULL,
    [EmployeeId]          BIGINT          NULL,
    [EmployeeName]        VARCHAR (100)   NULL,
    [CalibrationDate]     DATETIME        NULL,
    [CurrencyId]          INT             NULL,
    [CurrencyName]        VARCHAR (50)    NULL,
    [UnitCost]            DECIMAL (18, 2) CONSTRAINT [CalibrationManagment_UnitCost] DEFAULT ((0)) NULL,
    [CertifyType]         VARCHAR (200)   NULL,
    [CertifyId]           BIGINT          NULL,
    [Memo]                NVARCHAR (MAX)  NULL,
    [MasterCompanyId]     INT             NOT NULL,
    [IsDeleted]           BIT             CONSTRAINT [CalibrationManagment_DC_Delete] DEFAULT ((0)) NOT NULL,
    [IsActive]            BIT             CONSTRAINT [CalibrationManagment_DC_Active] DEFAULT ((1)) NOT NULL,
    [CreatedBy]           VARCHAR (256)   NOT NULL,
    [UpdatedBy]           VARCHAR (256)   NOT NULL,
    [CreatedDate]         DATETIME2 (7)   CONSTRAINT [CalibrationManagment_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]         DATETIME2 (7)   CONSTRAINT [CalibrationManagment_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsVendororEmployee]  VARCHAR (20)    NULL,
    CONSTRAINT [PK_CalibrationManagment] PRIMARY KEY CLUSTERED ([CalibrationId] ASC),
    CONSTRAINT [FK_CalibrationManagment_AssetRecordId] FOREIGN KEY ([AssetRecordId]) REFERENCES [dbo].[Asset] ([AssetRecordId]),
    CONSTRAINT [FK_CalibrationManagment_CurrencyId] FOREIGN KEY ([CurrencyId]) REFERENCES [dbo].[Currency] ([CurrencyId]),
    CONSTRAINT [FK_CalibrationManagment_EmployeeId] FOREIGN KEY ([EmployeeId]) REFERENCES [dbo].[Employee] ([EmployeeId])
);


GO








Create TRIGGER [dbo].[Trg_CalibrationManagmentAudit]

   ON  [dbo].[CalibrationManagment]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

INSERT INTO CalibrationManagmentAudit

SELECT * FROM INSERTED

SET NOCOUNT ON;

END