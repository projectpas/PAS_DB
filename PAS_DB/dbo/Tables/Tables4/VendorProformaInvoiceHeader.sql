CREATE TABLE [dbo].[VendorProformaInvoiceHeader] (
    [VendorProformaInvoiceId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [VendorProformaInvoiceNo] VARCHAR (150) NULL,
    [VendorId]                BIGINT        NOT NULL,
    [VendorName]              VARCHAR (256) NOT NULL,
    [VendorCode]              VARCHAR (256) NOT NULL,
    [PaymentTermsId]          BIGINT        NOT NULL,
    [PaymentMethodId]         BIGINT        NULL,
    [EmployeeId]              BIGINT        NULL,
    [IsEnforcePoRoApproval]   BIT           NULL,
    [ApproverId]              BIGINT        NULL,
    [ApprovedBy]              VARCHAR (100) NULL,
    [DateApproved]            DATETIME2 (7) NULL,
    [EntryDate]               DATETIME2 (7) NULL,
    [InvoiceNumber]           VARCHAR (150) NULL,
    [InvoiceDate]             DATETIME2 (7) NULL,
    [AccountingCalendarId]    BIGINT        NULL,
    [CurrencyId]              BIGINT        NULL,
    [PostedDate]              DATETIME2 (7) NULL,
    [IsUsedInVendorPayment]   BIT           NULL,
    [StatusId]                INT           NOT NULL,
    [ManagementStructureId]   INT           NOT NULL,
    [MasterCompanyId]         INT           NOT NULL,
    [CreatedBy]               VARCHAR (100) NOT NULL,
    [CreatedDate]             DATETIME2 (7) CONSTRAINT [DF_VendorProformaInvoiceHeader_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]               VARCHAR (100) NOT NULL,
    [UpdatedDate]             DATETIME2 (7) CONSTRAINT [DF_VendorProformaInvoiceHeader_UpdatedDate] DEFAULT (getutcdate()) NOT NULL,
    [IsActive]                BIT           CONSTRAINT [DF__VendorProformaInvoiceHeader__IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]               BIT           CONSTRAINT [DF__VendorProformaInvoiceHeader__IsDeleted] DEFAULT ((0)) NOT NULL,
    [ReferenceId]             BIGINT        NULL,
    [ReferenceNumber]         VARCHAR (150) NULL,
    [ReferenceModuleId]       INT           NULL,
    [ReferenceModuleName]     VARCHAR (150) NULL,
    [IsPurchaseOrder]         BIT           NOT NULL,
    [ControlNumber]           VARCHAR (150) NULL,
    CONSTRAINT [PK_VendorProformaInvoiceHeader] PRIMARY KEY CLUSTERED ([VendorProformaInvoiceId] ASC),
    CONSTRAINT [FK_VendorProformaInvoiceHeader_Vendor] FOREIGN KEY ([VendorId]) REFERENCES [dbo].[Vendor] ([VendorId])
);


GO

/******************************************* TRIGGER *******************************************/

/****** Object:  Trigger [[Trg_VendorProformaInvoiceHeaderAudit]]    Script Date: 04-12-2024 14:42:04 ******/
--DROP TRIGGER [dbo].[Trg_VendorProformaInvoiceHeaderAudit]
--GO

/*************************************************************             
 ** File:   [[Trg_VendorProformaInvoiceHeaderAudit]]             
 ** Author:   RAJESH  
 ** Description: This trigger is used to insert data into  [VendorProformaInvoiceHeaderAudit]
 ** Purpose:  
 ** Date:       12/04/2024
            
 ** PARAMETERS:             

 ** RETURN VALUE:             
    
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** PR   Date			Author				Change Description              
 ** --   --------		-------			--------------------------------            
 1    04/Dec/2024		RAJESH GAMI		CREATED 

**************************************************************/  
CREATE   TRIGGER [dbo].[Trg_VendorProformaInvoiceHeaderAudit]

   ON  [dbo].[VendorProformaInvoiceHeader]

   AFTER INSERT,DELETE,UPDATE 

AS 

BEGIN

	INSERT INTO [dbo].[VendorProformaInvoiceHeaderAudit]

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END