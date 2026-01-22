CREATE TABLE [dbo].[AssetAvailableStatus] (
    [AssetAvailableStatusId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [Status]                 VARCHAR (256)  NOT NULL,
    [Memo]                   NVARCHAR (MAX) NULL,
    [MasterCompanyId]        INT            CONSTRAINT [DF_AssetAvailableStatus_MasterCompanyId] DEFAULT ((0)) NOT NULL,
    [CreatedBy]              VARCHAR (256)  NOT NULL,
    [UpdatedBy]              VARCHAR (256)  NOT NULL,
    [CreatedDate]            DATETIME2 (7)  CONSTRAINT [DF_AssetAvailableStatus_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]            DATETIME2 (7)  CONSTRAINT [DF_AssetAvailableStatus_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]               BIT            CONSTRAINT [DF_AssetAvailableStatus_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]              BIT            CONSTRAINT [DF_AssetAvailableStatus_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_AssetAvailableStatus] PRIMARY KEY CLUSTERED ([AssetAvailableStatusId] ASC)
);


GO

----------------------------------------------

CREATE TRIGGER [dbo].[Trg_AssetAvailableStatusAudit]

   ON  [dbo].[AssetAvailableStatus]

   AFTER INSERT,UPDATE

AS 

BEGIN

	

	INSERT INTO [dbo].[AssetAvailableStatusAudit] 

    SELECT * FROM INSERTED 

	SET NOCOUNT ON;



END