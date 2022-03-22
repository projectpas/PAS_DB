CREATE TABLE [dbo].[ExchangeStatus] (
    [ExchangeStatusId] INT          IDENTITY (1, 1) NOT NULL,
    [Name]             VARCHAR (50) NOT NULL,
    [MasterCompanyId]  INT          NOT NULL,
    [CreatedBy]        VARCHAR (50) NOT NULL,
    [CreatedOn]        DATETIME     CONSTRAINT [DF_ExchangeStatus_CreatedOn] DEFAULT (getdate()) NOT NULL,
    [UpdatedBy]        VARCHAR (50) NULL,
    [UpdatedOn]        DATETIME     CONSTRAINT [DF_ExchangeStatus_UpdatedOn] DEFAULT (getdate()) NULL,
    [IsActive]         BIT          CONSTRAINT [DF_ExchangeStatus_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]        BIT          CONSTRAINT [DF_ExchangeStatus_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_ExchangeStatus] PRIMARY KEY CLUSTERED ([ExchangeStatusId] ASC)
);


GO




CREATE TRIGGER [dbo].[Trg_ExchangeStatusAudit]

   ON  [dbo].[ExchangeStatus]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO ExchangeStatusAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END