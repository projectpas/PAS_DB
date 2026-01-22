/*************************************************************             
 ** File:   [USP_GetNonPOInvoiceDetails_ById]            
 ** Author:   Devendra    
 ** Description: Get NonPOInvoice part details by nonpoinvoiceid
 ** Purpose:           
 ** Date:   21st September 20234       
            
 ** PARAMETERS:             
           
 ** RETURN VALUE:             
    
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** S NO	  Date			Author			Change Description              
 ** --		--------		-------		--------------------------------            
	1		21-09-2023		Devendra			created  
	2		26-10-2023		Devendra			added new columns  
       
EXECUTE   [dbo].[USP_GetNonPOInvoicePartDetails_ById] 1,1  
**************************************************************/  
CREATE   PROCEDURE [dbo].[USP_GetNonPOInvoicePartDetails_ById]  
@NonPOInvoiceId BIGINT,  
@MasterCompanyId BIGINT
AS  
BEGIN  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;  
  
  BEGIN TRY  
  BEGIN TRANSACTION  
   BEGIN   
      
    SELECT   
		[NonPOInvoicePartDetailsId],
		[NonPOInvoiceId],
		[EntryDate],
		[Amount],
		[CurrencyId],
		[FXRate],
		[GlAccountId],
		[InvoiceNum],
		[Invoicedate],
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
		NPD.[TaxTypeId]
    FROM [DBO].[NonPOInvoicePartDetails] NPD WITH (NOLOCK)   
    WHERE NPD.[NonPOInvoiceId] = @NonPOInvoiceId and NPD.MasterCompanyId = @MasterCompanyId 
                  
   END  
  COMMIT  TRANSACTION  
  
  END TRY      
  BEGIN CATCH        
   IF @@trancount > 0  
    --PRINT 'ROLLBACK'  
    ROLLBACK TRAN;  
    DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
  
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
              , @AdhocComments     VARCHAR(150)    = 'USP_GetNonPOInvoicePartDetails_ById'   
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@NonPOInvoiceId, '') + '@Parameter2 = '''+ ISNULL(@MasterCompanyId, '') +''  
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