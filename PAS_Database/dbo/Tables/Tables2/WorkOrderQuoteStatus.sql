CREATE TABLE [dbo].[WorkOrderQuoteStatus] (
    [WorkOrderQuoteStatusId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [Description]            VARCHAR (50)   NOT NULL,
    [Memo]                   NVARCHAR (MAX) NULL,
    [MasterCompanyId]        INT            NOT NULL,
    [CreatedBy]              VARCHAR (256)  NOT NULL,
    [UpdatedBy]              VARCHAR (256)  NOT NULL,
    [CreatedDate]            DATETIME2 (7)  CONSTRAINT [DF_WorkOrderQuoteStatus_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]            DATETIME2 (7)  CONSTRAINT [DF_WorkOrderQuoteStatus_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]               BIT            CONSTRAINT [WorkOrderQuoteStatuss_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]              BIT            CONSTRAINT [WorkOrderQuoteStatuss_DC_Delete] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_WorkOrderQuoteStatus] PRIMARY KEY CLUSTERED ([WorkOrderQuoteStatusId] ASC)
);


GO




CREATE TRIGGER [dbo].[Trg_WorkOrderQuoteStatusAudit]

   ON  [dbo].[WorkOrderQuoteStatus]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO WorkOrderQuoteStatusAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END