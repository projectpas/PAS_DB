/*************************************************************           
 ** File:   [USP_DELETE_VendorReadyToPayChecks]           
 ** Author:   AMIT GHEDIYA
 ** Description: This stored procedure is used USP_DELETE_VendorReadyToPayChecks 
 ** Purpose:         
 ** Date:   11/03/2024    
          
 ** PARAMETERS:           
 @ReadyToPayDetailsId BIGINT,@ReadyToPayId  BIGINT
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
	1    11/03/2024   AMIT GHEDIYA		Crated
	2    05/04/2024   AMIT GHEDIYA		Update to delete CM as well.
     
-- EXEC USP_DELETE_VendorReadyToPayChecks 356,271 
**************************************************************/
CREATE      PROCEDURE [dbo].[USP_DELETE_VendorReadyToPayChecks]  
@ReadyToPayDetailsId BIGINT = NULL,  
@ReadyToPayId BIGINT = NULL
AS  
BEGIN  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;  
 BEGIN TRY  

	DECLARE @VendorPaymentDetailsId BIGINT,
			@VendorId BIGINT,
			@VendorCreditMemoId BIGINT,
			@MasterLoopID INT;

	SELECT @VendorPaymentDetailsId = VendorPaymentDetailsId FROM [DBO].[VendorReadyToPayDetails] WITH(NOLOCK) WHERE ReadyToPayDetailsId = @ReadyToPayDetailsId;
	
	If(@VendorPaymentDetailsId > 0)
	BEGIN 
		--SELECT @VendorCreditMemoId = VendorCreditMemoId, @VendorId = VendorId FROM [DBO].[VendorCreditMemoMapping] WITH(NOLOCK) WHERE VendorPaymentDetailsId = @VendorPaymentDetailsId;
		
		IF OBJECT_ID(N'tempdb..#tmpVendorCreditMemoMapping') IS NOT NULL
		BEGIN
			DROP TABLE #tmpVendorCreditMemoMapping
		END
				
		CREATE TABLE #tmpVendorCreditMemoMapping
		(
			[ID] INT IDENTITY,
			[VendorCreditMemoId] BIGINT NULL,
			[VendorId] BIGINT NULL
		)

		INSERT INTO #tmpVendorCreditMemoMapping ([VendorCreditMemoId],[VendorId])
				SELECT  [VendorCreditMemoId],[VendorId]
		FROM [DBO].[VendorCreditMemoMapping] WITH(NOLOCK) WHERE VendorPaymentDetailsId = @VendorPaymentDetailsId AND ISNULL(IsPosted,0) = 0;
		
		SELECT  @MasterLoopID = MAX(ID) FROM #tmpVendorCreditMemoMapping
		WHILE(@MasterLoopID > 0)
		BEGIN
			SELECT @VendorCreditMemoId = [VendorCreditMemoId] , @VendorId = VendorId
				FROM #tmpVendorCreditMemoMapping WHERE [ID] = @MasterLoopID;

			IF(@VendorCreditMemoId > 0)
			BEGIN
				UPDATE [DBO].[VendorCreditMemo] set IsVendorPayment = NULL 
				WHERE VendorCreditMemoId = @VendorCreditMemoId;
				
				DELETE [DBO].[VendorCreditMemoMapping] 
				WHERE VendorCreditMemoId = @VendorCreditMemoId;

				UPDATE [DBO].[ManualJournalDetails] set IsVendorPayment = NULL 
				WHERE ManualJournalHeaderId = @VendorCreditMemoId AND ReferenceId = @VendorId;
			END

			SET @VendorCreditMemoId = 0;
			SET @VendorId = 0;
			SET @MasterLoopID = @MasterLoopID - 1;
		END
	END

	DELETE [DBO].[VendorReadyToPayDetails] WHERE ReadyToPayDetailsId = @ReadyToPayDetailsId AND ReadyToPayId = @ReadyToPayId;

  END TRY      
  BEGIN CATCH        
   IF @@trancount > 0  
    PRINT 'ROLLBACK'  
    DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
              , @AdhocComments     VARCHAR(150)    = 'USP_DELETE_VendorReadyToPayChecks'   
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@ReadyToPayDetailsId, '') + ''  
              , @ApplicationName VARCHAR(100) = 'PAS'  
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------  
              exec spLogException   
                       @DatabaseName           =  @DatabaseName  
                     , @AdhocComments          =  @AdhocComments  
                     , @ProcedureParameters    =  @ProcedureParameters  
                     , @ApplicationName        =  @ApplicationName  
                     , @ErrorLogID             =  @ErrorLogID OUTPUT ;  
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)  
              RETURN(1);  
  END CATCH  
END