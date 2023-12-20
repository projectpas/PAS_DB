CREATE TABLE [dbo].[StandAloneCreditMemoDetailsAudit] (
    [StandAloneCreditMemoDetailAuditId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [StandAloneCreditMemoDetailId]      BIGINT          NOT NULL,
    [CreditMemoHeaderId]                BIGINT          NOT NULL,
    [GlAccountId]                       BIGINT          NOT NULL,
    [Qty]                               INT             NOT NULL,
    [Rate]                              DECIMAL (18, 2) NOT NULL,
    [Amount]                            DECIMAL (18, 2) NOT NULL,
    [MasterCompanyId]                   INT             NOT NULL,
    [CreatedBy]                         VARCHAR (256)   NOT NULL,
    [UpdatedBy]                         VARCHAR (256)   NOT NULL,
    [CreatedDate]                       DATETIME2 (7)   CONSTRAINT [DF_StandAloneCreditMemoDetailsAudit_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]                       DATETIME2 (7)   CONSTRAINT [DF_StandAloneCreditMemoDetailsAudit_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                          BIT             CONSTRAINT [DF_StandAloneCreditMemoDetailsAudit_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                         BIT             CONSTRAINT [DF_StandAloneCreditMemoDetailsAudit_IsDeleted] DEFAULT ((0)) NOT NULL,
    [Reason]                            VARCHAR (MAX)   NULL,
    [ManagementStructureId]             BIGINT          NULL,
    [LastMSLevel]                       VARCHAR (200)   NULL,
    [AllMSlevels]                       VARCHAR (MAX)   NULL,
    CONSTRAINT [PK_StandAloneCreditMemoDetailsAudit] PRIMARY KEY CLUSTERED ([StandAloneCreditMemoDetailAuditId] ASC)
);

