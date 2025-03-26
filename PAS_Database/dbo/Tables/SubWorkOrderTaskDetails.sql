CREATE TABLE [dbo].[SubWorkOrderTaskDetails] (
    [SubWorkOrderTaskDetailsId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [SubWorkOrderTaskId]        BIGINT        NOT NULL,
    [OpenDate]                  DATETIME2 (7) NULL,
    [OpenBy]                    VARCHAR (100) NULL,
    [TechId]                    BIGINT        NULL,
    [TechName]                  VARCHAR (100) NULL,
    [TechUpdatedDate]           DATETIME2 (7) NULL,
    [InspectorId]               BIGINT        NULL,
    [InspectorName]             VARCHAR (100) NULL,
    [InspectorUpdatedDate]      DATETIME2 (7) NULL,
    [Descrepancy]               VARCHAR (MAX) NULL,
    [Resolution]                VARCHAR (MAX) NULL,
    [HasInstruction]            BIT           NULL,
    [MasterCompanyId]           INT           NULL,
    [CreatedBy]                 VARCHAR (100) NULL,
    [UpdatedBy]                 VARCHAR (100) NULL,
    [CreatedDate]               DATETIME2 (7) NULL,
    [UpdatedDate]               DATETIME2 (7) NULL,
    [IsActive]                  BIT           NULL,
    [IsDeleted]                 BIT           NULL,
    [PrintInWO]                 BIT           NULL,
    [PrintInWOQ]                BIT           NULL,
    [IsPrintInspector]          BIT           NULL,
    [IsPrintTechnician]         BIT           NULL,
    CONSTRAINT [PK_SubWorkOrderTaskDetails] PRIMARY KEY CLUSTERED ([SubWorkOrderTaskDetailsId] ASC)
);


GO
CREATE   TRIGGER [dbo].[Trg_SubWorkOrderTaskDetails]
   ON  [dbo].[SubWorkOrderTaskDetails]
   AFTER INSERT,DELETE,UPDATE
AS
BEGIN
	INSERT INTO SubWorkOrderTaskDetailsAudit
	SELECT * FROM INSERTED
SET NOCOUNT ON;
END