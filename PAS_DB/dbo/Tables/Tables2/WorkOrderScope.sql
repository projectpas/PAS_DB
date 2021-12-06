CREATE TABLE [dbo].[WorkOrderScope] (
    [ID]              BIGINT        IDENTITY (1, 1) NOT NULL,
    [Description]     VARCHAR (50)  NOT NULL,
    [MasterCompanyId] INT           NOT NULL,
    [CreatedBy]       VARCHAR (256) NOT NULL,
    [UpdatedBy]       VARCHAR (256) NOT NULL,
    [CreatedDate]     DATETIME2 (7) CONSTRAINT [DF_WorkOrderScope_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]     DATETIME2 (7) CONSTRAINT [DF_WorkOrderScope_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]        BIT           CONSTRAINT [DF_WorkOrderScope_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT           CONSTRAINT [DF_WorkOrderScope_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_WorkOrderScope] PRIMARY KEY CLUSTERED ([ID] ASC),
    CONSTRAINT [FK_WorkOrderScope_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);


GO




CREATE TRIGGER [dbo].[Trg_WorkOrderScopeAudit]

   ON  [dbo].[WorkOrderScope]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO WorkOrderScopeAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END