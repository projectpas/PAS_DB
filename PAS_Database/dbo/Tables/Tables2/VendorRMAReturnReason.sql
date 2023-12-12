CREATE TABLE [dbo].[VendorRMAReturnReason] (
    [VendorRMAReturnReasonId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [Reason]                  VARCHAR (256)  NULL,
    [Memo]                    VARCHAR (1000) NULL,
    [MasterCompanyId]         INT            NOT NULL,
    [CreatedBy]               VARCHAR (50)   NOT NULL,
    [UpdatedBy]               VARCHAR (50)   NOT NULL,
    [CreatedDate]             DATETIME2 (7)  CONSTRAINT [DF_VendorRMAReturnReason_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedDate]             DATETIME2 (7)  CONSTRAINT [DF_VendorRMAReturnReason_UpdatedDate] DEFAULT (getutcdate()) NOT NULL,
    [IsActive]                BIT            CONSTRAINT [DF__VendorRMAReturnReason__IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]               BIT            CONSTRAINT [DF__VendorRMAReturnReason__IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_VendorRMAReturnReason] PRIMARY KEY CLUSTERED ([VendorRMAReturnReasonId] ASC)
);


GO
CREATE   TRIGGER [dbo].[Trg_VendorRMAReturnReasonAudit]

   ON  [dbo].[VendorRMAReturnReason]

   AFTER INSERT,UPDATE

AS 

BEGIN



	INSERT INTO [dbo].[VendorRMAReturnReasonAudit]

	SELECT * FROM INSERTED

	SET NOCOUNT ON;



END