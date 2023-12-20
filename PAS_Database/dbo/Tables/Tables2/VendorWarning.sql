CREATE TABLE [dbo].[VendorWarning] (
    [VendorWarningId]     BIGINT        IDENTITY (1, 1) NOT NULL,
    [VendorId]            BIGINT        NOT NULL,
    [Allow]               BIT           CONSTRAINT [VendorWarning_DC_Allow] DEFAULT ((0)) NOT NULL,
    [Warning]             BIT           CONSTRAINT [VendorWarning_DC_Warning] DEFAULT ((0)) NOT NULL,
    [Restrict]            BIT           CONSTRAINT [VendorWarning_DC_Restrict] DEFAULT ((0)) NOT NULL,
    [WarningMessage]      VARCHAR (300) NULL,
    [RestrictMessage]     VARCHAR (300) NULL,
    [MasterCompanyId]     INT           NOT NULL,
    [CreatedBy]           VARCHAR (256) NOT NULL,
    [UpdatedBy]           VARCHAR (256) NOT NULL,
    [CreatedDate]         DATETIME2 (7) CONSTRAINT [VendorWarning_DC_CD] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]         DATETIME2 (7) CONSTRAINT [VendorWarning_DC_UD] DEFAULT (getdate()) NOT NULL,
    [IsActive]            BIT           DEFAULT ((1)) NOT NULL,
    [IsDeleted]           BIT           CONSTRAINT [DF_VendorWarning_IsDeleted] DEFAULT ((0)) NOT NULL,
    [VendorWarningListId] BIGINT        NULL,
    CONSTRAINT [PK_VendorWarning] PRIMARY KEY CLUSTERED ([VendorWarningId] ASC),
    CONSTRAINT [FK_VendorWarning_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_VendorWarning_Vendor] FOREIGN KEY ([VendorId]) REFERENCES [dbo].[Vendor] ([VendorId]),
    CONSTRAINT [UC_VendorWarning_VendorId_VendorWarningListId] UNIQUE NONCLUSTERED ([VendorId] ASC, [VendorWarningListId] ASC)
);


GO


CREATE TRIGGER [dbo].[Trg_VendorWarningAudit]

   ON  [dbo].[VendorWarning]

   AFTER INSERT,UPDATE

AS 

BEGIN



	INSERT INTO [dbo].[VendorWarningAudit]

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END