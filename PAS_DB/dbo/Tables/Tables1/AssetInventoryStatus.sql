CREATE TABLE [dbo].[AssetInventoryStatus] (
    [AssetInventoryStatusId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [Status]                 VARCHAR (256)  NOT NULL,
    [Memo]                   NVARCHAR (MAX) NULL,
    [MasterCompanyId]        INT            NOT NULL,
    [CreatedBy]              VARCHAR (256)  NOT NULL,
    [UpdatedBy]              VARCHAR (256)  NOT NULL,
    [CreatedDate]            DATETIME2 (7)  CONSTRAINT [AssetInventoryStatus_DC_CDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]            DATETIME2 (7)  CONSTRAINT [AssetInventoryStatus_DC_UDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]               BIT            CONSTRAINT [AssetInventoryStatuss_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]              BIT            CONSTRAINT [AssetInventoryStatuss_DC_Delete] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_AssetInventoryStatus] PRIMARY KEY CLUSTERED ([AssetInventoryStatusId] ASC),
    CONSTRAINT [Unique_AssetInventoryStatus] UNIQUE NONCLUSTERED ([Status] ASC, [MasterCompanyId] ASC)
);


GO




----------------------------------------------

CREATE TRIGGER [dbo].[Trg_AssetInventoryStatusAudit]

   ON  [dbo].[AssetInventoryStatus]

   AFTER INSERT,UPDATE

AS 

BEGIN

	

	INSERT INTO [dbo].[AssetInventoryStatusAudit] 

    SELECT * FROM INSERTED 

	SET NOCOUNT ON;



END