CREATE TABLE [dbo].[WorkOrderStageAndStatus] (
    [WOStageStatusId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [WOStageId]       BIGINT        NOT NULL,
    [WOStatusId]      BIGINT        NOT NULL,
    [MasterCompanyId] INT           NOT NULL,
    [CreatedBy]       VARCHAR (256) NOT NULL,
    [UpdatedBy]       VARCHAR (256) NOT NULL,
    [CreatedDate]     DATETIME2 (7) CONSTRAINT [DF_WorkOrderStageAndStatus_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]     DATETIME2 (7) CONSTRAINT [DF_WorkOrderStageAndStatus_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]        BIT           CONSTRAINT [DF_WorkOrderStageAndStatus_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT           CONSTRAINT [DF_WorkOrderStageAndStatus_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_WorkOrderStageAndStatus] PRIMARY KEY CLUSTERED ([WOStageStatusId] ASC)
);


GO




CREATE TRIGGER [dbo].[Trg_WorkOrderStageAndStatusAudit]

   ON  [dbo].[WorkOrderStageAndStatus]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO WorkOrderStageAndStatusAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END