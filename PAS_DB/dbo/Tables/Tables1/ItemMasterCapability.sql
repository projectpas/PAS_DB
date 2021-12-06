CREATE TABLE [dbo].[ItemMasterCapability] (
    [ItemMasterCapability] BIGINT        IDENTITY (1, 1) NOT NULL,
    [ItemMasterId]         BIGINT        NOT NULL,
    [CapabilityId]         BIGINT        NOT NULL,
    [MasterCompanyId]      INT           NOT NULL,
    [CreatedBy]            VARCHAR (256) NULL,
    [UpdatedBy]            VARCHAR (256) NULL,
    [CreatedDate]          DATETIME2 (7) NOT NULL,
    [UpdatedDate]          DATETIME2 (7) NOT NULL,
    [IsActive]             BIT           NULL,
    [IsDelete]             BIT           NULL,
    CONSTRAINT [PK_ItemMasterCapability] PRIMARY KEY CLUSTERED ([ItemMasterCapability] ASC),
    CONSTRAINT [FK_ItemMasterCapability_Capability] FOREIGN KEY ([CapabilityId]) REFERENCES [dbo].[Capability] ([CapabilityId]),
    CONSTRAINT [FK_ItemMasterCapability_ItemMaster] FOREIGN KEY ([ItemMasterId]) REFERENCES [dbo].[ItemMaster] ([ItemMasterId]),
    CONSTRAINT [FK_ItemMasterCapability_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);


GO




CREATE TRIGGER [dbo].[Trg_ItemMasterCapabilityAudit]

   ON  [dbo].[ItemMasterCapability]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO ItemMasterCapabilityAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END