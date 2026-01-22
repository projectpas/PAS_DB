CREATE TABLE [dbo].[VendorContact] (
    [VendorContactId]   BIGINT        IDENTITY (1, 1) NOT NULL,
    [VendorId]          BIGINT        NOT NULL,
    [ContactId]         BIGINT        NOT NULL,
    [Tag]               VARCHAR (255) CONSTRAINT [DF__VendorConta__Tag__24134F1B] DEFAULT ('') NOT NULL,
    [IsDefaultContact]  BIT           NOT NULL,
    [MasterCompanyId]   INT           NOT NULL,
    [CreatedBy]         VARCHAR (256) NOT NULL,
    [UpdatedBy]         VARCHAR (256) NOT NULL,
    [CreatedDate]       DATETIME2 (7) CONSTRAINT [VendorContact_DC_CD] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]       DATETIME2 (7) CONSTRAINT [VendorContact_DC_UD] DEFAULT (getdate()) NOT NULL,
    [IsActive]          BIT           CONSTRAINT [VendorContact_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]         BIT           CONSTRAINT [VC_DC_Delete] DEFAULT ((0)) NOT NULL,
    [ContactTagId]      BIGINT        NULL,
    [Attention]         VARCHAR (250) NULL,
    [IsRestrictedParty] BIT           NULL,
    CONSTRAINT [PK_VendorContact] PRIMARY KEY CLUSTERED ([VendorContactId] ASC),
    CONSTRAINT [FK_VendorContact_Contact] FOREIGN KEY ([ContactId]) REFERENCES [dbo].[Contact] ([ContactId]),
    CONSTRAINT [FK_VendorContact_ContactTagId] FOREIGN KEY ([ContactTagId]) REFERENCES [dbo].[ContactTag] ([ContactTagId]),
    CONSTRAINT [FK_VendorContact_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_VendorContact_Vendor] FOREIGN KEY ([VendorId]) REFERENCES [dbo].[Vendor] ([VendorId])
);


GO


CREATE TRIGGER [dbo].[Trg_VendorContactAudit]

   ON  [dbo].[VendorContact]

   AFTER INSERT,DELETE,UPDATE

AS 

BEGIN



	INSERT INTO [dbo].[VendorContactAudit]

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END