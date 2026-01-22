CREATE TABLE [dbo].[CustomerContact] (
    [CustomerContactId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [CustomerId]        BIGINT        NOT NULL,
    [ContactId]         BIGINT        NOT NULL,
    [IsDefaultContact]  BIT           CONSTRAINT [CustomerContact_DC_IsDefaultContact] DEFAULT ((0)) NOT NULL,
    [MasterCompanyId]   INT           NOT NULL,
    [CreatedBy]         VARCHAR (256) NOT NULL,
    [UpdatedBy]         VARCHAR (256) NOT NULL,
    [CreatedDate]       DATETIME2 (7) CONSTRAINT [DF_CustomerContact_CreatedDate] DEFAULT (sysdatetime()) NOT NULL,
    [UpdatedDate]       DATETIME2 (7) CONSTRAINT [DF_CustomerContact_UpdatedDate] DEFAULT (sysdatetime()) NOT NULL,
    [IsActive]          BIT           CONSTRAINT [CustomerContact_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]         BIT           DEFAULT ((0)) NOT NULL,
    [IsRestrictedParty] BIT           NULL,
    CONSTRAINT [PK_CustomerContact] PRIMARY KEY CLUSTERED ([CustomerContactId] ASC),
    CONSTRAINT [FK_CustomerContact_Contact] FOREIGN KEY ([ContactId]) REFERENCES [dbo].[Contact] ([ContactId]),
    CONSTRAINT [FK_CustomerContact_Customer] FOREIGN KEY ([CustomerId]) REFERENCES [dbo].[Customer] ([CustomerId]),
    CONSTRAINT [FK_CustomerContact_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);


GO




---------------



CREATE TRIGGER [dbo].[Trg_AuditCustomerContact]

   ON  [dbo].[CustomerContact]

   AFTER INSERT,UPDATE

AS 

BEGIN



	INSERT INTO [dbo].[AuditCustomerContact]

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END