CREATE TABLE [dbo].[LeaseStocklineUsageHistory] (
    [LeaseStocklineUsageHistoryId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [LeaseStocklineId]             BIGINT          NOT NULL,
    [UsageType]                    CHAR (1)        NOT NULL,
    [EntryDate]                    DATETIME2 (7)   NOT NULL,
    [FromDate]                     DATETIME2 (7)   NULL,
    [ToDate]                       DATETIME2 (7)   NULL,
    [TSNHours]                     DECIMAL (18, 6) NULL,
    [TSNMinutes]                   DECIMAL (18, 6) NULL,
    [CSN]                          DECIMAL (18, 6) NULL,
    [Notes]                        NVARCHAR (MAX)  NULL,
    [MasterCompanyId]              INT             NOT NULL,
    [CreatedBy]                    VARCHAR (256)   NOT NULL,
    [UpdatedBy]                    VARCHAR (256)   NOT NULL,
    [CreatedDate]                  DATETIME2 (7)   CONSTRAINT [DF_LeaseStocklineUsageHistory_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedDate]                  DATETIME2 (7)   CONSTRAINT [DF_LeaseStocklineUsageHistory_UpdatedDate] DEFAULT (getutcdate()) NOT NULL,
    [IsActive]                     BIT             CONSTRAINT [DF_LeaseStocklineUsageHistory_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                    BIT             CONSTRAINT [DF_LeaseStocklineUsageHistory_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_LeaseStocklineUsageHistory] PRIMARY KEY CLUSTERED ([LeaseStocklineUsageHistoryId] ASC),
    CONSTRAINT [CK_LeaseStocklineUsageHistory_UsageType] CHECK ([UsageType]='C' OR [UsageType]='T'),
    CONSTRAINT [FK_LeaseStocklineUsageHistory_LeaseStockline] FOREIGN KEY ([LeaseStocklineId]) REFERENCES [dbo].[LeaseStockline] ([LeaseStocklineId]),
    CONSTRAINT [FK_LeaseStocklineUsageHistory_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);


GO
CREATE TRIGGER [dbo].[Trg_LeaseStocklineUsageHistoryAudit]
   ON  [dbo].[LeaseStocklineUsageHistory]
   AFTER INSERT, UPDATE, DELETE
AS
BEGIN
	SET NOCOUNT ON;

	-- Handles INSERT and UPDATE (rows exist in INSERTED)
	IF EXISTS (SELECT 1 FROM INSERTED)
	BEGIN
		INSERT INTO [dbo].[LeaseStocklineUsageHistoryAudit]
		SELECT * FROM INSERTED
	END

	-- Handles DELETE (rows exist only in DELETED)
	IF EXISTS (SELECT 1 FROM DELETED) AND NOT EXISTS (SELECT 1 FROM INSERTED)
	BEGIN
		INSERT INTO [dbo].[LeaseStocklineUsageHistoryAudit]
		SELECT * FROM DELETED
	END
END

GO
CREATE NONCLUSTERED INDEX [IX_LeaseStocklineUsageHistory_LeaseStocklineId]
    ON [dbo].[LeaseStocklineUsageHistory]([LeaseStocklineId] ASC, [UsageType] ASC)
    INCLUDE([EntryDate]);

