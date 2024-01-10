CREATE TABLE [dbo].[WorkOrderQuoteCharges] (
    [WorkOrderQuoteChargesId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [WorkOrderQuoteDetailsId] BIGINT          NOT NULL,
    [ChargesTypeId]           BIGINT          NOT NULL,
    [VendorId]                BIGINT          NULL,
    [Quantity]                INT             NOT NULL,
    [MarkupPercentageId]      BIGINT          NULL,
    [Description]             VARCHAR (256)   NULL,
    [UnitCost]                DECIMAL (20, 2) NOT NULL,
    [ExtendedCost]            DECIMAL (20, 2) NOT NULL,
    [MasterCompanyId]         INT             NOT NULL,
    [CreatedBy]               VARCHAR (256)   NOT NULL,
    [UpdatedBy]               VARCHAR (256)   NOT NULL,
    [CreatedDate]             DATETIME2 (7)   CONSTRAINT [DF_WorkOrderQuoteCharges_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]             DATETIME2 (7)   CONSTRAINT [DF_WorkOrderQuoteCharges_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                BIT             DEFAULT ((1)) NOT NULL,
    [IsDeleted]               BIT             DEFAULT ((0)) NOT NULL,
    [TaskId]                  BIGINT          NOT NULL,
    [MarkupFixedPrice]        VARCHAR (15)    NULL,
    [BillingAmount]           DECIMAL (20, 2) NULL,
    [BillingRate]             DECIMAL (20, 2) NULL,
    [HeaderMarkupId]          BIGINT          NULL,
    [RefNum]                  VARCHAR (20)    NULL,
    [BillingMethodId]         INT             NULL,
    [TaskName]                VARCHAR (100)   NULL,
    [ChargeType]              VARCHAR (50)    NULL,
    [GlAccountName]           VARCHAR (50)    NULL,
    [VendorName]              VARCHAR (50)    NULL,
    [BillingName]             VARCHAR (50)    NULL,
    [MarkUp]                  VARCHAR (50)    NULL,
    [UOMId]                   BIGINT          NULL,
    CONSTRAINT [PK_WorkOrderQuoteCharges] PRIMARY KEY CLUSTERED ([WorkOrderQuoteChargesId] ASC),
    CONSTRAINT [FK_WorkOrderQuoteCharges_Charge] FOREIGN KEY ([ChargesTypeId]) REFERENCES [dbo].[Charge] ([ChargeId]),
    CONSTRAINT [FK_WorkOrderQuoteCharges_MarkupPercentage] FOREIGN KEY ([MarkupPercentageId]) REFERENCES [dbo].[Percent] ([PercentId]),
    CONSTRAINT [FK_WorkOrderQuoteCharges_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_WorkOrderQuoteCharges_Task] FOREIGN KEY ([TaskId]) REFERENCES [dbo].[Task] ([TaskId]),
    CONSTRAINT [FK_WorkOrderQuoteCharges_Vendor] FOREIGN KEY ([VendorId]) REFERENCES [dbo].[Vendor] ([VendorId]),
    CONSTRAINT [FK_WorkOrderQuoteCharges_WorkOrderQuoteDetails] FOREIGN KEY ([WorkOrderQuoteDetailsId]) REFERENCES [dbo].[WorkOrderQuoteDetails] ([WorkOrderQuoteDetailsId])
);




GO


----------------------------------------------

CREATE TRIGGER [dbo].[Trg_WorkOrderQuoteChargesAudit]

   ON  [dbo].[WorkOrderQuoteCharges]

   AFTER INSERT,UPDATE

AS 

BEGIN



	INSERT INTO [dbo].[WorkOrderQuoteChargesAudit] 

    SELECT * 

	FROM INSERTED 

	SET NOCOUNT ON;



END