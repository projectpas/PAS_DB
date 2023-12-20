CREATE TABLE [dbo].[PublicationItemMasterMapping] (
    [PublicationItemMasterMappingId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [PublicationRecordId]            BIGINT        NOT NULL,
    [ItemMasterId]                   BIGINT        NOT NULL,
    [MasterCompanyId]                INT           NOT NULL,
    [CreatedBy]                      VARCHAR (256) NOT NULL,
    [UpdatedBy]                      VARCHAR (256) NOT NULL,
    [CreatedDate]                    DATETIME2 (7) NOT NULL,
    [UpdatedDate]                    DATETIME2 (7) NOT NULL,
    [IsActive]                       BIT           NOT NULL,
    [IsDeleted]                      BIT           NOT NULL,
    CONSTRAINT [PK__ItemMast__730ECB10C16E3BE5] PRIMARY KEY CLUSTERED ([PublicationItemMasterMappingId] ASC),
    CONSTRAINT [FK_PublicationItemMasterMapping_ItemMaster] FOREIGN KEY ([ItemMasterId]) REFERENCES [dbo].[ItemMaster] ([ItemMasterId]),
    CONSTRAINT [FK_PublicationItemMasterMapping_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [PublicationItemMasterMappingConstraint] UNIQUE NONCLUSTERED ([PublicationRecordId] ASC, [ItemMasterId] ASC, [MasterCompanyId] ASC)
);


GO








CREATE TRIGGER [dbo].[Trg_PublicationItemMasterMappingAudit]

   ON  [dbo].[PublicationItemMasterMapping]

   AFTER INSERT,UPDATE

AS 

BEGIN

	INSERT INTO [dbo].[PublicationItemMasterMappingAudit]

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END