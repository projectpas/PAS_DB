CREATE TABLE [dbo].[LeaseStocklineServiceComponent] (
    [LeaseStocklineServiceComponentId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [LeaseStocklineId]                 BIGINT          NOT NULL,
    [ComponentName]                    NVARCHAR (200)  NOT NULL,
    [Amount]                           DECIMAL (18, 6) NULL,
    [Per]                              NVARCHAR (50)   NULL,
    [MasterCompanyId]                  INT             NOT NULL,
    [CreatedBy]                        VARCHAR (256)   NOT NULL,
    [UpdatedBy]                        VARCHAR (256)   NOT NULL,
    [CreatedDate]                      DATETIME        CONSTRAINT [DF_LeaseStocklineServiceComponent_CreatedDate] DEFAULT (getutcdate()) NULL,
    [UpdatedDate]                      DATETIME        CONSTRAINT [DF_LeaseStocklineServiceComponent_UpdatedDate] DEFAULT (getutcdate()) NULL,
    [IsActive]                         BIT             CONSTRAINT [DF_LeaseStocklineServiceComponent_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                        BIT             CONSTRAINT [DF_LeaseStocklineServiceComponent_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_LeaseStocklineServiceComponent] PRIMARY KEY CLUSTERED ([LeaseStocklineServiceComponentId] ASC),
    CONSTRAINT [FK_LeaseStocklineServiceComponent_LeaseStockline] FOREIGN KEY ([LeaseStocklineId]) REFERENCES [dbo].[LeaseStockline] ([LeaseStocklineId]),
    CONSTRAINT [FK_LeaseStocklineServiceComponent_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);


GO
CREATE TRIGGER [dbo].[Trg_LeaseStocklineServiceComponentAudit]
   ON  [dbo].[LeaseStocklineServiceComponent]
   AFTER INSERT, UPDATE, DELETE
AS
BEGIN
	SET NOCOUNT ON;

	-- Handles INSERT and UPDATE (rows exist in INSERTED)
	IF EXISTS (SELECT 1 FROM INSERTED)
	BEGIN
		INSERT INTO [dbo].[LeaseStocklineServiceComponentAudit]
		SELECT * FROM INSERTED
	END

	-- Handles DELETE (rows exist only in DELETED)
	IF EXISTS (SELECT 1 FROM DELETED) AND NOT EXISTS (SELECT 1 FROM INSERTED)
	BEGIN
		INSERT INTO [dbo].[LeaseStocklineServiceComponentAudit]
		SELECT * FROM DELETED
	END
END
