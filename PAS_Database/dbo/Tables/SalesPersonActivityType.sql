CREATE TABLE [dbo].[SalesPersonActivityType] (
    [SalesPersonActivityTypeId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [CustomerId]                BIGINT        NOT NULL,
    [DropdownTypeId]            BIGINT        NOT NULL,
    [ActivityTypeId]            BIGINT        NOT NULL,
    [RevenuePercentageId]       BIGINT        NULL,
    [MarginPercentageId]        BIGINT        NULL,
    [EffectiveDate]             DATETIME2 (7) NOT NULL,
    [EntityStructureId]         BIGINT        NULL,
    [Level1]                    VARCHAR (256) NULL,
    [Level2]                    VARCHAR (256) NULL,
    [Level3]                    VARCHAR (256) NULL,
    [Level4]                    VARCHAR (256) NULL,
    [MasterCompanyId]           INT           CONSTRAINT [SalesPersonActivityType_MasterCompanyId] DEFAULT ((1)) NOT NULL,
    [CreatedBy]                 VARCHAR (256) CONSTRAINT [SalesPersonActivityType_CreatedBy] DEFAULT ('admin') NOT NULL,
    [UpdatedBy]                 VARCHAR (256) CONSTRAINT [SalesPersonActivityType_UpdatedBy] DEFAULT ('admin') NOT NULL,
    [CreatedDate]               DATETIME2 (7) CONSTRAINT [SalesPersonActivityType_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]               DATETIME2 (7) CONSTRAINT [SalesPersonActivityType_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                  BIT           CONSTRAINT [SalesPersonActivityType_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                 BIT           CONSTRAINT [SalesPersonActivityType_Delete] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_SalesPersonActivityType] PRIMARY KEY CLUSTERED ([SalesPersonActivityTypeId] ASC),
    CONSTRAINT [FK_SalesPersonActivityType_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);




GO
CREATE   TRIGGER [dbo].[Trg_SalesPersonActivityTypeAudit]
   ON  [dbo].[SalesPersonActivityType]
   AFTER INSERT,DELETE,UPDATE
AS 
BEGIN
	INSERT INTO SalesPersonActivityTypeAudit
	SELECT * FROM INSERTED
	SET NOCOUNT ON;
END