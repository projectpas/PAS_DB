CREATE TABLE [dbo].[ExchangeBillingStatus] (
    [ExchangeBillingStatusId] INT          IDENTITY (1, 1) NOT NULL,
    [Name]                    VARCHAR (50) NOT NULL,
    [MasterCompanyId]         INT          NOT NULL,
    [CreatedBy]               VARCHAR (50) NOT NULL,
    [CreatedOn]               DATETIME     CONSTRAINT [DF_ExchangeBillingStatus_CreatedOn] DEFAULT (getdate()) NOT NULL,
    [UpdatedBy]               VARCHAR (50) NULL,
    [UpdatedOn]               DATETIME     CONSTRAINT [DF_ExchangeBillingStatus_UpdatedOn] DEFAULT (getdate()) NULL,
    [IsActive]                BIT          CONSTRAINT [DF_ExchangeBillingStatus_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]               BIT          CONSTRAINT [DF_ExchangeBillingStatus_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_ExchangeBillingStatus] PRIMARY KEY CLUSTERED ([ExchangeBillingStatusId] ASC)
);


GO


CREATE TRIGGER [dbo].[Trg_ExchangeBillingStatusAudit]

   ON  [dbo].[ExchangeBillingStatus]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO ExchangeBillingStatusAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END