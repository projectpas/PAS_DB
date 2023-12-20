CREATE TABLE [dbo].[CustomerCreditTermsHistory] (
    [CustomerCreditTermsHistoryId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [AppModuleId]                  INT             NOT NULL,
    [ReffranceId]                  BIGINT          NOT NULL,
    [CustomerId]                   BIGINT          NOT NULL,
    [ARBalance]                    DECIMAL (18, 2) NOT NULL,
    [Amount]                       DECIMAL (18, 2) NOT NULL,
    [Notes]                        VARCHAR (500)   NOT NULL,
    [MasterCompanyId]              INT             NOT NULL,
    [CreatedBy]                    VARCHAR (256)   NOT NULL,
    [UpdatedBy]                    VARCHAR (256)   NOT NULL,
    [CreatedDate]                  DATETIME2 (7)   CONSTRAINT [DF_CustomerCreditTermsHistory_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]                  DATETIME2 (7)   CONSTRAINT [DF_CustomerCreditTermsHistory_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsDeleted]                    BIT             CONSTRAINT [DF_CustomerCreditTermsHistory_IsDeleted] DEFAULT ((0)) NOT NULL,
    [IsActive]                     BIT             CONSTRAINT [DF_CustomerCreditTermsHistory_IsActive] DEFAULT ((1)) NOT NULL,
    CONSTRAINT [PK_CustomerCreditTermsHistory] PRIMARY KEY CLUSTERED ([CustomerCreditTermsHistoryId] ASC)
);


GO
CREATE TRIGGER [dbo].[Trg_CustomerCreditTermsHistoryAudit]
   ON  [dbo].[CustomerCreditTermsHistory]
   AFTER INSERT,DELETE,UPDATE
AS 
BEGIN
	INSERT INTO CustomerCreditTermsHistoryAudit
	SELECT * FROM INSERTED
	SET NOCOUNT ON;
END