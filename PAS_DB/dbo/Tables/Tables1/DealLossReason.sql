CREATE TABLE [dbo].[DealLossReason] (
    [DealLossReasonId]    BIGINT         IDENTITY (1, 1) NOT NULL,
    [DealLossOutComeName] VARCHAR (256)  NOT NULL,
    [Sequence]            INT            NOT NULL,
    [Memo]                NVARCHAR (MAX) NULL,
    [MasterCompanyId]     INT            NOT NULL,
    [CreatedBy]           VARCHAR (256)  NOT NULL,
    [UpdatedBy]           VARCHAR (256)  NOT NULL,
    [CreatedDate]         DATETIME2 (7)  CONSTRAINT [DealLoss_DC_CDate] DEFAULT (sysdatetime()) NOT NULL,
    [UpdatedDate]         DATETIME2 (7)  CONSTRAINT [DealLoss_DC_UDate] DEFAULT (sysdatetime()) NOT NULL,
    [IsActive]            BIT            CONSTRAINT [DealLoss_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]           BIT            CONSTRAINT [DealLoss_DC_Delete] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_DealLossReason] PRIMARY KEY CLUSTERED ([DealLossReasonId] ASC),
    CONSTRAINT [FK_DealLoss_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [Unique_DealLoss] UNIQUE NONCLUSTERED ([DealLossOutComeName] ASC, [MasterCompanyId] ASC)
);


GO




CREATE TRIGGER [dbo].[Trg_DealLossAudit]

   ON  [dbo].[DealLossReason]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

INSERT INTO DealLossReasonAudit

SELECT * FROM INSERTED

SET NOCOUNT ON;

END