CREATE TABLE [dbo].[LeaseStocklineUsage] (
    [LeaseStocklineUsageId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [LeaseStocklineId]      BIGINT          NOT NULL,
    [CurrentTSNHours]       DECIMAL (18, 6) NULL,
    [CurrentTSNMinutes]     DECIMAL (18, 6) NULL,
    [CurrentTSNFromDate]    DATETIME2 (7)   NULL,
    [CurrentTSNToDate]      DATETIME2 (7)   NULL,
    [CurrentTSNDate]        DATETIME2 (7)   NULL,
    [LatestTimeNotes]       NVARCHAR (MAX)  NULL,
    [CurrentCSN]            DECIMAL (18, 6) NULL,
    [CurrentCSNFromDate]    DATETIME2 (7)   NULL,
    [CurrentCSNToDate]      DATETIME2 (7)   NULL,
    [CurrentCSNDate]        DATETIME2 (7)   NULL,
    [LatestCycleNotes]      NVARCHAR (MAX)  NULL,
    [MasterCompanyId]       INT             NOT NULL,
    [CreatedBy]             VARCHAR (256)   NOT NULL,
    [UpdatedBy]             VARCHAR (256)   NOT NULL,
    [CreatedDate]           DATETIME2 (7)   CONSTRAINT [DF_LeaseStocklineUsage_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedDate]           DATETIME2 (7)   CONSTRAINT [DF_LeaseStocklineUsage_UpdatedDate] DEFAULT (getutcdate()) NOT NULL,
    [IsActive]              BIT             CONSTRAINT [DF_LeaseStocklineUsage_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]             BIT             CONSTRAINT [DF_LeaseStocklineUsage_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_LeaseStocklineUsage] PRIMARY KEY CLUSTERED ([LeaseStocklineUsageId] ASC),
    CONSTRAINT [FK_LeaseStocklineUsage_LeaseStockline] FOREIGN KEY ([LeaseStocklineId]) REFERENCES [dbo].[LeaseStockline] ([LeaseStocklineId]),
    CONSTRAINT [FK_LeaseStocklineUsage_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [UQ_LeaseStocklineUsage_LeaseStocklineId] UNIQUE NONCLUSTERED ([LeaseStocklineId] ASC)
);


GO
CREATE TRIGGER [dbo].[Trg_LeaseStocklineUsageAudit]
   ON  [dbo].[LeaseStocklineUsage]
   AFTER INSERT, UPDATE, DELETE
AS
BEGIN
	SET NOCOUNT ON;

	-- Handles INSERT and UPDATE (rows exist in INSERTED)
	IF EXISTS (SELECT 1 FROM INSERTED)
	BEGIN
		INSERT INTO [dbo].[LeaseStocklineUsageAudit]
		SELECT * FROM INSERTED
	END

	-- Handles DELETE (rows exist only in DELETED)
	IF EXISTS (SELECT 1 FROM DELETED) AND NOT EXISTS (SELECT 1 FROM INSERTED)
	BEGIN
		INSERT INTO [dbo].[LeaseStocklineUsageAudit]
		SELECT * FROM DELETED
	END
END
