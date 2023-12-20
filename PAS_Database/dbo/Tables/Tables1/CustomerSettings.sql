CREATE TABLE [dbo].[CustomerSettings] (
    [Id]              BIGINT          IDENTITY (1, 1) NOT NULL,
    [LegalEntityId]   BIGINT          NOT NULL,
    [CreditTermsId]   INT             NOT NULL,
    [CreditLimit]     DECIMAL (18, 2) NOT NULL,
    [CurrencyId]      INT             NOT NULL,
    [MasterCompanyId] INT             NOT NULL,
    [CreatedBy]       VARCHAR (256)   NOT NULL,
    [UpdatedBy]       VARCHAR (256)   NOT NULL,
    [CreatedDate]     DATETIME2 (7)   CONSTRAINT [DF__CustomerSettings__Creat__3B969E48] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]     DATETIME2 (7)   CONSTRAINT [CustomerSettings_DC_UDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]        BIT             CONSTRAINT [CustomerSettings_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT             CONSTRAINT [CustomerSettings_DC_Delete] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_CustomerSettings] PRIMARY KEY CLUSTERED ([Id] ASC)
);


GO
CREATE   TRIGGER [dbo].[Trg_CustomerSettingsAudit]

   ON  [dbo].[CustomerSettings]

   AFTER INSERT,UPDATE

AS 

BEGIN

DECLARE @LegalEntityName VARCHAR(256),@CreditTerms VARCHAR(256),@Currency  VARCHAR(256)
DECLARE @LegalEntityId BIGINT,@CreditTermsId BIGINT,@CurrencyId BIGINT

SELECT @LegalEntityId=LegalEntityId,@CreditTermsId=CreditTermsId,@CurrencyId=CurrencyId FROM INSERTED

	SELECT @LegalEntityName=Name FROM LegalEntity WHERE LegalEntityId=@LegalEntityId
	SELECT @CreditTerms=Name FROM CreditTerms WHERE CreditTermsId=@CreditTermsId
	SELECT @Currency=Code FROM Currency WHERE CurrencyId=@CurrencyId

	INSERT INTO [dbo].[CustomerSettingsAudit]

	SELECT *,@LegalEntityName,@CreditTerms,@Currency FROM INSERTED



	SET NOCOUNT ON;



END