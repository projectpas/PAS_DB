CREATE TABLE [dbo].[VendorContactATAMapping] (
    [VendorContactATAMappingId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [VendorId]                  BIGINT        NOT NULL,
    [VendorContactId]           BIGINT        NOT NULL,
    [ATAChapterId]              BIGINT        NOT NULL,
    [ATASubChapterId]           BIGINT        NULL,
    [MasterCompanyId]           INT           NOT NULL,
    [CreatedBy]                 VARCHAR (256) NOT NULL,
    [UpdatedBy]                 VARCHAR (256) NOT NULL,
    [CreatedDate]               DATETIME2 (7) NOT NULL,
    [UpdatedDate]               DATETIME2 (7) NOT NULL,
    [IsActive]                  BIT           CONSTRAINT [D_VCAM_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                 BIT           CONSTRAINT [ VendorContactATAMapping_DC_Delete] DEFAULT ((0)) NOT NULL,
    [Level1]                    VARCHAR (50)  NULL,
    [Level2]                    VARCHAR (50)  NULL,
    [Level3]                    VARCHAR (50)  NULL,
    CONSTRAINT [PK_VendorContactATAMapping] PRIMARY KEY CLUSTERED ([VendorContactATAMappingId] ASC),
    CONSTRAINT [FK_VendorContactATAMapping_ATASubChapter] FOREIGN KEY ([ATASubChapterId]) REFERENCES [dbo].[ATASubChapter] ([ATASubChapterId]),
    CONSTRAINT [FK_VendorContactATAMapping_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_VendorContactATAMapping_Vendor] FOREIGN KEY ([VendorId]) REFERENCES [dbo].[Vendor] ([VendorId]),
    CONSTRAINT [FK_VendorContactATAMapping_VendorContact] FOREIGN KEY ([VendorContactId]) REFERENCES [dbo].[VendorContact] ([VendorContactId])
);


GO


CREATE TRIGGER [dbo].[Trg_VendorContactATAMappingAudit]

   ON  [dbo].[VendorContactATAMapping]

   AFTER INSERT,UPDATE

AS 

BEGIN

	INSERT INTO [dbo].[VendorContactATAMappingAudit]

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END
GO


CREATE TRIGGER [dbo].[Trg_VendorContactATAMappingDelete]

   ON  [dbo].[VendorContactATAMapping]

   AFTER DELETE

AS 

BEGIN

	INSERT INTO [dbo].[VendorContactATAMappingAudit]

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END