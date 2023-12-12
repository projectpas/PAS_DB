CREATE TABLE [dbo].[DealLossReasonAudit] (
    [AuditDealLossReasonId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [DealLossReasonId]      BIGINT         NOT NULL,
    [DealLossOutComeName]   VARCHAR (256)  NOT NULL,
    [Sequence]              INT            NULL,
    [Memo]                  NVARCHAR (MAX) NULL,
    [MasterCompanyId]       INT            NOT NULL,
    [CreatedBy]             VARCHAR (256)  NOT NULL,
    [UpdatedBy]             VARCHAR (256)  NOT NULL,
    [CreatedDate]           DATETIME2 (7)  NOT NULL,
    [UpdatedDate]           DATETIME2 (7)  NOT NULL,
    [IsActive]              BIT            NOT NULL,
    [IsDeleted]             BIT            NOT NULL,
    CONSTRAINT [PK_DealLossReasonAudit] PRIMARY KEY CLUSTERED ([AuditDealLossReasonId] ASC)
);

