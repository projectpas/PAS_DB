CREATE TABLE [dbo].[ItemMasterATAMapping] (
    [ItemMasterATAMappingId]   BIGINT        IDENTITY (1, 1) NOT NULL,
    [ItemMasterId]             BIGINT        NOT NULL,
    [PartNumber]               VARCHAR (50)  NOT NULL,
    [ATAChapterId]             BIGINT        NULL,
    [ATAChapterCode]           VARCHAR (256) NULL,
    [ATAChapterName]           VARCHAR (250) NULL,
    [ATASubChapterId]          BIGINT        NULL,
    [ATASubChapterDescription] VARCHAR (250) NULL,
    [MasterCompanyId]          INT           NOT NULL,
    [CreatedBy]                VARCHAR (256) NOT NULL,
    [UpdatedBy]                VARCHAR (256) NOT NULL,
    [CreatedDate]              DATETIME2 (7) NULL,
    [UpdatedDate]              DATETIME2 (7) NULL,
    [IsActive]                 BIT           NOT NULL,
    [IsDeleted]                BIT           NOT NULL,
    [Level1]                   VARCHAR (50)  NULL,
    [Level2]                   VARCHAR (50)  NULL,
    [Level3]                   VARCHAR (50)  NULL,
    CONSTRAINT [PK_PNATAMapping] PRIMARY KEY CLUSTERED ([ItemMasterATAMappingId] ASC),
    CONSTRAINT [FK_ItemMasterATAMapping_ItemMaster] FOREIGN KEY ([ItemMasterId]) REFERENCES [dbo].[ItemMaster] ([ItemMasterId]),
    CONSTRAINT [FK_ItemMasterATAMapping_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);




GO






CREATE TRIGGER [dbo].[Trg_ItemMasterATAMapping]

   ON  [dbo].[ItemMasterATAMapping]

   AFTER INSERT,DELETE,UPDATE

AS 

BEGIN



IF EXISTS (SELECT 1 FROM inserted)

	INSERT INTO ItemMasterATAMappingAudit

	SELECT * FROM INSERTED

ELSE

	INSERT INTO ItemMasterATAMappingAudit

	SELECT * FROM DELETED



	SET NOCOUNT ON;



END