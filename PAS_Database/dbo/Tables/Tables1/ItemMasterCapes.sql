CREATE TABLE [dbo].[ItemMasterCapes] (
    [ItemMasterCapesId]     BIGINT         IDENTITY (1, 1) NOT NULL,
    [ItemMasterId]          BIGINT         NOT NULL,
    [CapabilityTypeId]      INT            NOT NULL,
    [ManagementStructureId] BIGINT         NOT NULL,
    [IsVerified]            BIT            NULL,
    [VerifiedById]          BIGINT         NULL,
    [VerifiedDate]          DATETIME2 (7)  NULL,
    [Memo]                  NVARCHAR (MAX) NULL,
    [MasterCompanyId]       INT            NOT NULL,
    [CreatedBy]             VARCHAR (256)  NOT NULL,
    [UpdatedBy]             VARCHAR (256)  NOT NULL,
    [CreatedDate]           DATETIME2 (7)  CONSTRAINT [DF_ItemMasterCapes_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]           DATETIME2 (7)  CONSTRAINT [DF_ItemMasterCapes_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]              BIT            CONSTRAINT [DF_ItemMasterCapes_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]             BIT            CONSTRAINT [DF_ItemMasterCapes_IsDeleted] DEFAULT ((0)) NOT NULL,
    [AddedDate]             DATETIME2 (7)  NULL,
    [PartNumber]            VARCHAR (250)  NULL,
    [PartDescription]       NVARCHAR (MAX) NULL,
    [CapabilityType]        VARCHAR (250)  NULL,
    [VerifiedBy]            VARCHAR (250)  NULL,
    [Level1]                VARCHAR (200)  NULL,
    [Level2]                VARCHAR (200)  NULL,
    [Level3]                VARCHAR (200)  NULL,
    [Level4]                VARCHAR (200)  NULL,
    CONSTRAINT [PK_ItemMasterCapes] PRIMARY KEY CLUSTERED ([ItemMasterCapesId] ASC),
    CONSTRAINT [FK_ItemMasterCapes_CapabilityTypeId] FOREIGN KEY ([CapabilityTypeId]) REFERENCES [dbo].[CapabilityType] ([CapabilityTypeId]),
    CONSTRAINT [FK_ItemMasterCapes_ItemMasterId] FOREIGN KEY ([ItemMasterId]) REFERENCES [dbo].[ItemMaster] ([ItemMasterId]),
    CONSTRAINT [FK_ItemMasterCapes_MasterCompanyId] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);


GO








CREATE TRIGGER [dbo].[Trg_ItemMasterCapesDelete]

   ON  [dbo].[ItemMasterCapes]

   AFTER DELETE

AS 

BEGIN

	INSERT INTO [dbo].[ItemMasterCapesAudit]

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END
GO






CREATE TRIGGER [dbo].[Trg_ItemMasterCapesAudit]

   ON  [dbo].[ItemMasterCapes]

   AFTER INSERT,UPDATE

AS 

BEGIN

	INSERT INTO [dbo].[ItemMasterCapesAudit]

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END