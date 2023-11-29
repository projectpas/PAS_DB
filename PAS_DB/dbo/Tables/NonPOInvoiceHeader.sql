CREATE TABLE [dbo].[NonPOInvoiceHeader] (
    [NonPOInvoiceId]         BIGINT        IDENTITY (1, 1) NOT NULL,
    [VendorId]               BIGINT        NOT NULL,
    [VendorName]             VARCHAR (256) NOT NULL,
    [VendorCode]             VARCHAR (256) NOT NULL,
    [PaymentTermsId]         BIGINT        NOT NULL,
    [StatusId]               INT           NOT NULL,
    [ManagementStructureId]  INT           NOT NULL,
    [MasterCompanyId]        INT           NOT NULL,
    [CreatedBy]              VARCHAR (50)  NOT NULL,
    [CreatedDate]            DATETIME2 (7) CONSTRAINT [DF_NonPOInvoiceHeader_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]              VARCHAR (50)  NOT NULL,
    [UpdatedDate]            DATETIME2 (7) CONSTRAINT [DF_NonPOInvoiceHeader_UpdatedDate] DEFAULT (getutcdate()) NOT NULL,
    [IsActive]               BIT           CONSTRAINT [DF__NonPOInvoiceHeader__IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]              BIT           CONSTRAINT [DF__NonPOInvoiceHeader__IsDeleted] DEFAULT ((0)) NOT NULL,
    [PaymentMethodId]        BIGINT        NULL,
    [EmployeeId]             BIGINT        NULL,
    [IsEnforceNonPoApproval] BIT           NULL,
    [ApproverId]             BIGINT        NULL,
    [ApprovedBy]             VARCHAR (100) NULL,
    [DateApproved]           DATETIME2 (7) NULL,
    [NPONumber]              VARCHAR (150) NULL,
    CONSTRAINT [PK_NonPOInvoiceHeader] PRIMARY KEY CLUSTERED ([NonPOInvoiceId] ASC),
    CONSTRAINT [FK_NonPOInvoiceHeader_Vendor] FOREIGN KEY ([VendorId]) REFERENCES [dbo].[Vendor] ([VendorId])
);


GO
/*************************************************************             
 ** File:   [Trg_NonPOInvoiceHeaderAudit]             
 ** Author:   Devendra Shekh  
 ** Description: This trigger is used to insert data into  [NonPOInvoiceHeaderAudit]
 ** Purpose:  
 ** Date:       09/13/2023
            
 ** PARAMETERS:             

 ** RETURN VALUE:             
    
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** PR   Date			Author				Change Description              
 ** --   --------		-------			--------------------------------            
 1    09/13/2023		Devendra Shekh		created 

**************************************************************/  
CREATE   TRIGGER [dbo].[Trg_NonPOInvoiceHeaderAudit]

   ON  [dbo].[NonPOInvoiceHeader]

   AFTER INSERT,DELETE,UPDATE 

AS 

BEGIN

	INSERT INTO [dbo].[NonPOInvoiceHeaderAudit]

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END