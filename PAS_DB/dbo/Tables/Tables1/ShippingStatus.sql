CREATE TABLE [dbo].[ShippingStatus] (
    [ShippingStatusId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [Status]           VARCHAR (50)   NOT NULL,
    [Memo]             NVARCHAR (MAX) NULL,
    [MasterCompanyId]  INT            NOT NULL,
    [CreatedBy]        VARCHAR (256)  NOT NULL,
    [UpdatedBy]        VARCHAR (256)  NOT NULL,
    [CreatedDate]      DATETIME2 (7)  CONSTRAINT [DF_ShippingStatus_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]      DATETIME2 (7)  CONSTRAINT [DF_ShippingStatus_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]         BIT            CONSTRAINT [DF_SS_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]        BIT            CONSTRAINT [DF_SS_IsDeleted] DEFAULT ((0)) NOT NULL,
    [SequenceNo]       INT            NULL,
    CONSTRAINT [PK_ShippingStatus] PRIMARY KEY CLUSTERED ([ShippingStatusId] ASC),
    CONSTRAINT [Unique_ShippingStatus] UNIQUE NONCLUSTERED ([Status] ASC, [MasterCompanyId] ASC)
);


GO




----------------------------------------------

CREATE TRIGGER [dbo].[Trg_ShippingStatusAudit]

   ON  [dbo].[ShippingStatus]

   AFTER INSERT,UPDATE

AS 

BEGIN

	

	INSERT INTO [dbo].[ShippingStatusAudit] 

    SELECT * FROM INSERTED 

	SET NOCOUNT ON;



END