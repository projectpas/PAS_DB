CREATE TABLE [dbo].[VendorProcess1099] (
    [VendorProcess1099Id] BIGINT        IDENTITY (1, 1) NOT NULL,
    [VendorId]            BIGINT        NOT NULL,
    [Master1099Id]        BIGINT        NOT NULL,
    [IsDefaultCheck]      BIT           NOT NULL,
    [IsDefaultRadio]      BIT           NOT NULL,
    [MasterCompanyId]     INT           NOT NULL,
    [CreatedBy]           VARCHAR (256) NOT NULL,
    [UpdatedBy]           VARCHAR (256) NOT NULL,
    [CreatedDate]         DATETIME2 (7) CONSTRAINT [VendorProcess1099_DC_CD] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]         DATETIME2 (7) CONSTRAINT [VendorProcess1099_DC_UD] DEFAULT (getdate()) NOT NULL,
    [IsActive]            BIT           CONSTRAINT [VendorProcess1099_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]           BIT           CONSTRAINT [VendorProcess1099_DC_Delete] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_VendorProcess1099] PRIMARY KEY CLUSTERED ([VendorProcess1099Id] ASC),
    CONSTRAINT [FK_VendorProcess1099_Master1099] FOREIGN KEY ([Master1099Id]) REFERENCES [dbo].[Master1099] ([Master1099Id]),
    CONSTRAINT [FK_VendorProcess1099_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_VendorProcess1099_Vendor] FOREIGN KEY ([VendorId]) REFERENCES [dbo].[Vendor] ([VendorId])
);


GO




CREATE TRIGGER [dbo].[Trg_VendorProcess1099Audit]

   ON  [dbo].[VendorProcess1099]

   AFTER INSERT,UPDATE

AS 

BEGIN



	INSERT INTO [dbo].[VendorProcess1099Audit]

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END