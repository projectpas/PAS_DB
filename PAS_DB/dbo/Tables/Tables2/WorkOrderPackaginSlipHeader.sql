CREATE TABLE [dbo].[WorkOrderPackaginSlipHeader] (
    [PackagingSlipId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [PackagingSlipNo] VARCHAR (50)  NOT NULL,
    [WorkOrderId]     BIGINT        NOT NULL,
    [MasterCompanyId] INT           NOT NULL,
    [CreatedBy]       VARCHAR (256) NOT NULL,
    [UpdatedBy]       VARCHAR (256) NOT NULL,
    [CreatedDate]     DATETIME2 (7) NOT NULL,
    [UpdatedDate]     DATETIME2 (7) NOT NULL,
    [IsActive]        BIT           NOT NULL,
    [IsDeleted]       BIT           NOT NULL,
    CONSTRAINT [PK_WorkOrderPackaginSlipHeader] PRIMARY KEY CLUSTERED ([PackagingSlipId] ASC)
);


GO




CREATE TRIGGER [dbo].[Trg_WorkOrderPackaginSlipHeaderAudit]

   ON  [dbo].[WorkOrderPackaginSlipHeader]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO WorkOrderPackaginSlipHeaderAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END