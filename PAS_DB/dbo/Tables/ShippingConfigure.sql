CREATE TABLE [dbo].[ShippingConfigure] (
    [ShippingConfigureId]   BIGINT        IDENTITY (1, 1) NOT NULL,
    [ShippingViaId]         BIGINT        NOT NULL,
    [ApiURL]                VARCHAR (MAX) NOT NULL,
    [ApiKey]                VARCHAR (MAX) NOT NULL,
    [SecretKey]             VARCHAR (MAX) NOT NULL,
    [ShippingAccountNumber] VARCHAR (100) NOT NULL,
    [IsAuthReq]             BIT           NULL,
    [MasterCompanyId]       INT           NOT NULL,
    [CreatedBy]             VARCHAR (100) NOT NULL,
    [CreatedDate]           DATETIME2 (7) CONSTRAINT [[ShippingConfigure_DC_CDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedBy]             VARCHAR (100) NOT NULL,
    [UpdatedDate]           DATETIME2 (7) CONSTRAINT [ShippingConfigure_DC_UDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]              BIT           CONSTRAINT [DF_ShippingConfigure_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]             BIT           CONSTRAINT [DF_ShippingConfigure_IsDeleted] DEFAULT ((0)) NOT NULL,
    [CarrierId]             BIGINT        NULL,
    CONSTRAINT [PK_ShippingConfigure] PRIMARY KEY CLUSTERED ([ShippingConfigureId] ASC),
    CONSTRAINT [FK_ShippingConfigure_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_ShippingConfigure_ShippingVia] FOREIGN KEY ([ShippingViaId]) REFERENCES [dbo].[ShippingVia] ([ShippingViaId])
);


GO
CREATE   TRIGGER [dbo].[Trg_ShippingConfigureAudit]

   ON  [dbo].[ShippingConfigure]

   AFTER INSERT,DELETE,UPDATE

AS 

BEGIN

	INSERT INTO ShippingConfigureAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;
END