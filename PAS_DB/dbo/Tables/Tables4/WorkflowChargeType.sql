CREATE TABLE [dbo].[WorkflowChargeType] (
    [WorkflowChargeTypeId] TINYINT       IDENTITY (1, 1) NOT NULL,
    [Description]          VARCHAR (100) NOT NULL,
    [MasterCompanyId]      INT           NOT NULL,
    [RecordCreateDate]     DATETIME2 (7) NOT NULL,
    [RecordModifiedDate]   DATETIME2 (7) NULL,
    [LastModifiedBy]       INT           NOT NULL,
    [CreatedBy]            VARCHAR (256) NULL,
    [UpdatedBy]            VARCHAR (256) NULL,
    [CreatedDate]          DATETIME2 (7) CONSTRAINT [DF_WorkflowChargeType_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]          DATETIME2 (7) CONSTRAINT [DF_WorkflowChargeType_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]             BIT           CONSTRAINT [DF_WorkflowChargeType_IsActive] DEFAULT ((1)) NULL,
    [IsDeleted]            BIT           DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_ProcessChargeType] PRIMARY KEY CLUSTERED ([WorkflowChargeTypeId] ASC),
    CONSTRAINT [FK_ProcessChargeType_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [Unique_WorkflowChargeType] UNIQUE NONCLUSTERED ([Description] ASC, [MasterCompanyId] ASC)
);


GO




CREATE TRIGGER [dbo].[Trg_WorkflowChargeTypeAudit]

   ON  [dbo].[WorkflowChargeType]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO WorkflowChargeTypeAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END