CREATE TABLE [dbo].[CheckPayment] (
    [CheckPaymentId]  BIGINT        IDENTITY (1, 1) NOT NULL,
    [RoutingNumber]   VARCHAR (30)  NULL,
    [AccountNumber]   VARCHAR (30)  NULL,
    [SiteName]        VARCHAR (100) NULL,
    [IsPrimayPayment] BIT           NOT NULL,
    [AddressId]       BIGINT        NOT NULL,
    [MasterCompanyId] INT           NOT NULL,
    [CreatedBy]       VARCHAR (256) NOT NULL,
    [UpdatedBy]       VARCHAR (256) NOT NULL,
    [CreatedDate]     DATETIME2 (7) NOT NULL,
    [UpdatedDate]     DATETIME2 (7) NOT NULL,
    [IsActive]        BIT           CONSTRAINT [CheckPayment_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT           CONSTRAINT [CheckPayment_DC_Delete] DEFAULT ((0)) NOT NULL,
    [ContactTagId]    BIGINT        NULL,
    [Attention]       VARCHAR (250) NULL,
    CONSTRAINT [PK_CheckPayment] PRIMARY KEY CLUSTERED ([CheckPaymentId] ASC),
    CONSTRAINT [FK_CheckPayment_Address] FOREIGN KEY ([AddressId]) REFERENCES [dbo].[Address] ([AddressId]),
    CONSTRAINT [FK_CheckPayment_ContactTagId] FOREIGN KEY ([ContactTagId]) REFERENCES [dbo].[ContactTag] ([ContactTagId]),
    CONSTRAINT [FK_CheckPayment_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);


GO




CREATE TRIGGER [dbo].[Trg_CheckPaymentAudit]

   ON  [dbo].[CheckPayment]

   AFTER INSERT,DELETE,UPDATE

AS 

BEGIN

	INSERT INTO [dbo].[CheckPaymentAudit]

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END