CREATE TABLE [dbo].[WorkOrderType] (
    [Id]              BIGINT        IDENTITY (1, 1) NOT NULL,
    [Description]     VARCHAR (50)  NOT NULL,
    [MasterCompanyId] INT           NOT NULL,
    [CreatedBy]       VARCHAR (256) NOT NULL,
    [UpdatedBy]       VARCHAR (256) NOT NULL,
    [CreatedDate]     DATETIME2 (7) CONSTRAINT [DF_WorkOrderType_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]     DATETIME2 (7) CONSTRAINT [DF_WorkOrderType_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]        BIT           CONSTRAINT [WorkOrderType_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT           CONSTRAINT [WorkOrderType_DC_Delete] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_WorkOrderType] PRIMARY KEY CLUSTERED ([Id] ASC)
);


GO




CREATE TRIGGER [dbo].[Trg_WorkOrderTypeAudit]

   ON  [dbo].[WorkOrderType]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO WorkOrderTypeAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END