CREATE TABLE [dbo].[MeasurementsAudit] (
    [MeasurementsAuditId] INT            IDENTITY (1, 1) NOT NULL,
    [Id]                  INT            NOT NULL,
    [CreatedBy]           VARCHAR (50)   NULL,
    [CreatedDate]         DATETIME       NOT NULL,
    [UpdatedBy]           VARCHAR (50)   NULL,
    [UpdatedDate]         DATETIME       NULL,
    [IsDeleted]           BIT            NULL,
    [PN]                  VARCHAR (256)  NULL,
    [Sequence]            VARCHAR (256)  NULL,
    [Stage]               VARCHAR (256)  NULL,
    [Min]                 VARCHAR (256)  NULL,
    [Max]                 VARCHAR (256)  NULL,
    [Expected]            VARCHAR (256)  NULL,
    [Diagram]             VARCHAR (256)  NULL,
    [Memo]                NVARCHAR (MAX) NULL,
    [ActionId]            BIGINT         NOT NULL,
    [WorkFlowId]          BIGINT         NOT NULL,
    CONSTRAINT [PK_MeasurementsAudit] PRIMARY KEY CLUSTERED ([MeasurementsAuditId] ASC)
);


GO




CREATE TRIGGER [dbo].[Trg_MeasurementsAuditAudit]

   ON  [dbo].[MeasurementsAudit]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO MeasurementsAuditAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END