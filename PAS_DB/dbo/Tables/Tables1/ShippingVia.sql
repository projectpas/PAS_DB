CREATE TABLE [dbo].[ShippingVia] (
    [ShippingViaId]   BIGINT         IDENTITY (1, 1) NOT NULL,
    [Name]            NVARCHAR (200) NOT NULL,
    [Memo]            NVARCHAR (MAX) NULL,
    [MasterCompanyId] INT            NOT NULL,
    [CreatedBy]       VARCHAR (256)  NOT NULL,
    [UpdatedBy]       VARCHAR (256)  NOT NULL,
    [CreatedDate]     DATETIME2 (7)  CONSTRAINT [DF_ShippingVia_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]     DATETIME2 (7)  CONSTRAINT [DF_ShippingVia_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]        BIT            CONSTRAINT [D_ShippingVia_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT            CONSTRAINT [D_ShippingVia_Delete] DEFAULT ((0)) NOT NULL,
    [Description]     VARCHAR (500)  NULL,
    [CarrierId]       BIGINT         NULL,
    PRIMARY KEY CLUSTERED ([ShippingViaId] ASC),
    CONSTRAINT [FK_ShippingVia_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [Unique_ShippingVia] UNIQUE NONCLUSTERED ([Name] ASC, [MasterCompanyId] ASC)
);




GO






-- =============================================

CREATE TRIGGER [dbo].[Trg_ShippingViaAudit]

   ON  [dbo].[ShippingVia]

   AFTER INSERT,DELETE,UPDATE

AS 

BEGIN



	INSERT INTO [ShippingViaAudit]

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END