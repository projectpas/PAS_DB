CREATE TABLE [dbo].[VendorProformaInvoicePartDetails] (
    [VendorProformaInvoicePartDetailsId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [VendorProformaInvoiceId]            BIGINT          NOT NULL,
    [EntryDate]                          DATETIME2 (7)   NOT NULL,
    [Amount]                             DECIMAL (18, 2) NULL,
    [CurrencyId]                         BIGINT          NULL,
    [FXRate]                             DECIMAL (18, 2) NULL,
    [GlAccountId]                        BIGINT          NOT NULL,
    [InvoiceNumber]                      VARCHAR (256)   NULL,
    [InvoiceDate]                        DATETIME2 (7)   NULL,
    [ManagementStructureId]              INT             NOT NULL,
    [LastMSLevel]                        VARCHAR (200)   NULL,
    [AllMSlevels]                        VARCHAR (MAX)   NULL,
    [Memo]                               VARCHAR (MAX)   NULL,
    [JournalType]                        VARCHAR (200)   NULL,
    [Item]                               VARCHAR (250)   NULL,
    [Description]                        VARCHAR (500)   NULL,
    [UnitOfMeasureId]                    BIGINT          NULL,
    [Qty]                                BIGINT          NULL,
    [ExtendedPrice]                      DECIMAL (18, 2) NULL,
    [TaxTypeId]                          BIGINT          NULL,
    [MasterCompanyId]                    INT             NOT NULL,
    [CreatedBy]                          VARCHAR (100)   NOT NULL,
    [CreatedDate]                        DATETIME2 (7)   CONSTRAINT [DF_VendorProformaInvoicePartDetails_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]                          VARCHAR (100)   NOT NULL,
    [UpdatedDate]                        DATETIME2 (7)   CONSTRAINT [DF_VendorProformaInvoicePartDetails_UpdatedDate] DEFAULT (getutcdate()) NOT NULL,
    [IsActive]                           BIT             CONSTRAINT [DF__VendorProformaInvoicePartDetails_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                          BIT             CONSTRAINT [DF__VendorProformaInvoicePartDetails_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_VendorProformaInvoicePartDetails] PRIMARY KEY CLUSTERED ([VendorProformaInvoicePartDetailsId] ASC),
    CONSTRAINT [FK_VendorProformaInvoicePartDetails_VendorProformaInvoiceHeader] FOREIGN KEY ([VendorProformaInvoiceId]) REFERENCES [dbo].[VendorProformaInvoiceHeader] ([VendorProformaInvoiceId])
);


GO


/******************************************* TRIGGER *******************************************/

/****** Object:  Trigger [[Trg_VendorProformaInvoicePartDetailsAudit]]    Script Date: 04-12-2024 14:42:04 ******/
--DROP TRIGGER [dbo].[Trg_VendorProformaInvoicePartDetailsAudit]
--GO

/*************************************************************             
 ** File:   [[Trg_VendorProformaInvoicePartDetailsAudit]]             
 ** Author:   RAJESH  
 ** Description: This trigger is used to insert data into  [VendorProformaInvoicePartDetailsAudit]
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
CREATE   TRIGGER [dbo].[Trg_VendorProformaInvoicePartDetailsAudit]

   ON  [dbo].[VendorProformaInvoicePartDetails]

   AFTER INSERT,DELETE,UPDATE 

AS 

BEGIN

	INSERT INTO [dbo].[VendorProformaInvoicePartDetailsAudit]

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END