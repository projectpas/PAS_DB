CREATE TABLE [dbo].[Condition] (
    [ConditionId]     BIGINT         IDENTITY (1, 1) NOT NULL,
    [Description]     VARCHAR (256)  NOT NULL,
    [Memo]            NVARCHAR (MAX) NULL,
    [CreatedDate]     DATETIME2 (7)  CONSTRAINT [DF_Condition_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]     DATETIME2 (7)  CONSTRAINT [DF_Condition_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]        BIT            CONSTRAINT [DF_Condition_IsActive] DEFAULT ((1)) NULL,
    [MasterCompanyId] INT            NOT NULL,
    [CreatedBy]       VARCHAR (256)  NULL,
    [UpdatedBy]       VARCHAR (256)  NULL,
    [IsDeleted]       BIT            CONSTRAINT [DF_Condition_IsDeleted] DEFAULT ((0)) NULL,
    [SequenceNo]      INT            NOT NULL,
    [Code]            VARCHAR (100)  NULL,
    [GroupCode]       VARCHAR (20)   NULL,
    CONSTRAINT [PK_Condition] PRIMARY KEY CLUSTERED ([ConditionId] ASC),
    CONSTRAINT [FK_Condition_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [Unique_ConditionSeqNo] UNIQUE NONCLUSTERED ([SequenceNo] ASC, [MasterCompanyId] ASC),
    CONSTRAINT [UQ_Condition_codes] UNIQUE NONCLUSTERED ([Description] ASC, [MasterCompanyId] ASC)
);


GO


-- =============================================

CREATE TRIGGER [dbo].[Trg_ConditionAudit]

   ON  [dbo].[Condition]

   AFTER INSERT,DELETE,UPDATE

AS 

BEGIN



	INSERT INTO [dbo].[ConditionAudit]

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END