CREATE TABLE [dbo].[WorkOrderPackaginSlipItems] (
    [PackagingSlipItemId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [PackagingSlipId]     BIGINT         NOT NULL,
    [WOPickTicketId]      BIGINT         NOT NULL,
    [WOPartNoId]          BIGINT         NOT NULL,
    [MasterCompanyId]     INT            NOT NULL,
    [CreatedBy]           VARCHAR (256)  NOT NULL,
    [UpdatedBy]           VARCHAR (256)  NOT NULL,
    [CreatedDate]         DATETIME2 (7)  NOT NULL,
    [UpdatedDate]         DATETIME2 (7)  NOT NULL,
    [IsActive]            BIT            NOT NULL,
    [IsDeleted]           BIT            NOT NULL,
    [PDFPath]             NVARCHAR (MAX) NULL,
    CONSTRAINT [PK_WorkOrderPackaginSlipItems] PRIMARY KEY CLUSTERED ([PackagingSlipItemId] ASC)
);


GO




CREATE TRIGGER [dbo].[Trg_WorkOrderPackaginSlipItemsAudit]

   ON  [dbo].[WorkOrderPackaginSlipItems]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO WorkOrderPackaginSlipItemsAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END