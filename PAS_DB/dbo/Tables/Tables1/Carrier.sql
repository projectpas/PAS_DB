CREATE TABLE [dbo].[Carrier] (
    [CarrierId]       BIGINT         IDENTITY (1, 1) NOT NULL,
    [Description]     VARCHAR (100)  NOT NULL,
    [Memo]            NVARCHAR (MAX) NULL,
    [MasterCompanyId] INT            NULL,
    [CreatedBy]       VARCHAR (256)  NOT NULL,
    [UpdatedBy]       VARCHAR (256)  NOT NULL,
    [CreatedDate]     DATETIME2 (7)  CONSTRAINT [DF_Carrier_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]     DATETIME2 (7)  CONSTRAINT [DF_Carrier_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]        BIT            CONSTRAINT [Carrier_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT            CONSTRAINT [Carrier_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_Carrier] PRIMARY KEY CLUSTERED ([CarrierId] ASC)
);


GO




CREATE TRIGGER [dbo].[Trg_CarrierAudit]

   ON  [dbo].[Carrier]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO CarrierAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END