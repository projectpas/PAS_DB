CREATE TABLE [dbo].[VendorType] (
    [VendorTypeId]    INT            IDENTITY (1, 1) NOT NULL,
    [Description]     NVARCHAR (256) NOT NULL,
    [MasterCompanyId] INT            NOT NULL,
    [CreatedBy]       VARCHAR (256)  NOT NULL,
    [UpdatedBy]       VARCHAR (256)  NOT NULL,
    [CreatedDate]     DATETIME2 (7)  CONSTRAINT [VT_DC_CD] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]     DATETIME2 (7)  CONSTRAINT [VT_DC_UD] DEFAULT (getdate()) NOT NULL,
    [IsActive]        BIT            CONSTRAINT [VT_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT            CONSTRAINT [VT_DC_Delete] DEFAULT ((0)) NOT NULL,
    [Memo]            NVARCHAR (MAX) NULL,
    [VendorTypeName]  VARCHAR (256)  NOT NULL,
    CONSTRAINT [PK_VendorType] PRIMARY KEY CLUSTERED ([VendorTypeId] ASC),
    CONSTRAINT [Unique_VendorType] UNIQUE NONCLUSTERED ([VendorTypeName] ASC, [MasterCompanyId] ASC)
);


GO


CREATE TRIGGER [dbo].[Trg_VendorTypeAudit]

   ON  [dbo].[VendorType]

   AFTER INSERT,UPDATE

AS 

BEGIN



	INSERT INTO [dbo].[VendorTypeAudit]

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END