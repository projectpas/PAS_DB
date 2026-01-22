/*************************************************************             
 ** File:   [USP_GetVendorProformaInvoicePartDetails_ById]            
 ** Author:   RAJESH GAMI    
 ** Description: Get Vendor Proforma Invoice Part Details by VendorProformaInvoiceId
 ** Purpose:           
 ** Date:   17-DEC-2024       
            
 ** PARAMETERS:             
           
 ** RETURN VALUE:             
    
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** S NO	  Date			Author			Change Description              
 ** --		--------		-------		--------------------------------            
	1		17-DEC-2024		RAJESH GAMI			CREATED  
       
EXECUTE   [dbo].[USP_GetVendorProformaInvoicePartDetails_ById] 1,1  
**************************************************************/  
CREATE     PROCEDURE [dbo].[USP_GetVendorProformaInvoicePartDetails_ById]  
@VendorProformaInvoiceId BIGINT,  
@MasterCompanyId BIGINT
AS  
BEGIN  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;  
  
  BEGIN TRY  
  BEGIN TRANSACTION  
   BEGIN   
      
    SELECT   
		[VendorProformaInvoicePartDetailsId],
		[VendorProformaInvoiceId],
		[EntryDate],
		[Amount],
		[CurrencyId],
		[FXRate],
		[GlAccountId],
		[InvoiceNumber],
		[InvoiceDate],
		[ManagementStructureId],
		[LastMSLevel],
		[AllMSlevels],
		[Memo],
		[JournalType],
		[MasterCompanyId],
		[CreatedBy],
		[CreatedDate],
		[UpdatedBy],
		[UpdatedDate],
		[IsActive],
		[IsDeleted],
		ISNULL(Item , '') AS [Item],
		ISNULL(Description , '') AS [Description],
		ISNULL(UnitOfMeasureId , 0) AS [UnitOfMeasureId],
		ISNULL(Qty , 0) AS [Qty],
		ISNULL(ExtendedPrice , 0) AS [ExtendedPrice],
		Part.[TaxTypeId]
    FROM [DBO].[VendorProformaInvoicePartDetails] Part WITH (NOLOCK)   
    WHERE Part.[VendorProformaInvoiceId] = @VendorProformaInvoiceId and Part.MasterCompanyId = @MasterCompanyId 
                  
   END  
  COMMIT  TRANSACTION  
  
  END TRY      
  BEGIN CATCH        
   IF @@trancount > 0  
    --PRINT 'ROLLBACK'  
    ROLLBACK TRAN;  
    DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
  
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
              , @AdhocComments     VARCHAR(150)    = 'USP_GetVendorProformaInvoicePartDetails_ById'   
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@VendorProformaInvoiceId, '') + '@Parameter2 = '''+ ISNULL(@MasterCompanyId, '') +''  
              , @ApplicationName VARCHAR(100) = 'PAS'  
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------  
  
              exec spLogException   
                       @DatabaseName   = @DatabaseName  
                     , @AdhocComments   = @AdhocComments  
                     , @ProcedureParameters  = @ProcedureParameters  
                     , @ApplicationName         = @ApplicationName  
                     , @ErrorLogID              = @ErrorLogID OUTPUT ;  
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)  
              RETURN(1);  
  END CATCH  
END