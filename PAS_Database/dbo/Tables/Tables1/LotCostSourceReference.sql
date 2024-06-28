CREATE TABLE [dbo].[LotCostSourceReference] (
    [LotSourceId]     INT           IDENTITY (1, 1) NOT NULL,
    [SourceName]      VARCHAR (50)  NOT NULL,
    [Code]            VARCHAR (20)  NULL,
    [SequenceNo]      INT           NULL,
    [MasterCompanyId] INT           NOT NULL,
    [CreatedBy]       VARCHAR (256) NOT NULL,
    [UpdatedBy]       VARCHAR (256) NOT NULL,
    [CreatedDate]     DATETIME2 (7) NOT NULL,
    [UpdatedDate]     DATETIME2 (7) NULL,
    [IsActive]        BIT           NOT NULL,
    [IsDeleted]       BIT           NOT NULL,
    CONSTRAINT [PK_LotCostSourceReference] PRIMARY KEY CLUSTERED ([LotSourceId] ASC)
);






GO


Create TRIGGER [dbo].[Trg_LotCostSourceReferenceAudit]

   ON  [dbo].[LotCostSourceReference]

   AFTER INSERT,UPDATE

AS 

BEGIN



	INSERT INTO [dbo].[LotCostSourceReferenceAudit]

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END