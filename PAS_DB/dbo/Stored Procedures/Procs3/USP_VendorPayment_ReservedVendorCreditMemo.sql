/*************************************************************           
 ** File:   [USP_VendorPayment_ReservedVendorCreditMemo]           
 ** Author: AMIT GHEDIYA
 ** Description: This stored procedure is used to Reserved VendorCreditMemo.
 ** Date:   09/29/2023
 ** PARAMETERS:           
 ** RETURN VALUE:
 ******************************************************************************           
  ** Change History           
 ******************************************************************************           
 ** PR   Date         Author  		Change Description            
 ** --   --------     -------		---------------------------     
    1    09/29/2023   AMIT GHEDIYA     Created

*******************************************************************************/
CREATE    PROCEDURE [dbo].[USP_VendorPayment_ReservedVendorCreditMemo]
	@ReceivingReconciliationId BIGINT
AS
BEGIN
  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  BEGIN TRY    
	BEGIN TRANSACTION

		DECLARE @VendorCreditMemoId BIGINT, @CreditMemoLoopID AS INT,@VendorPaymentDetailsId BIGINT;

		IF OBJECT_ID(N'tempdb..#tmpVendorCreditMemoMapping') IS NOT NULL
		BEGIN
			DROP TABLE #tmpVendorCreditMemoMapping
		END
				
		CREATE TABLE #tmpVendorCreditMemoMapping
		(
			[ID] INT IDENTITY,
			[VendorCreditMemoMappingId] INT,
			[VendorCreditMemoId] BIGINT NULL,
			[VendorPaymentDetailsId] BIGINT NULL,
			[VendorId] BIGINT NULL,
			[Amount] DECIMAL(18,2) NULL
		)

		INSERT #tmpVendorCreditMemoMapping ([VendorCreditMemoMappingId],[VendorCreditMemoId],[VendorPaymentDetailsId],
											[VendorId],[Amount])
		SELECT [VendorCreditMemoMappingId],[VendorCreditMemoId],[VendorPaymentDetailsId],
											[VendorId],[Amount] FROM [dbo].[VendorCreditMemoMapping] WITH (NOLOCK) WHERE VendorPaymentDetailsId = @ReceivingReconciliationId;
		
		SELECT  @CreditMemoLoopID = MAX(ID) FROM #tmpVendorCreditMemoMapping
		WHILE(@CreditMemoLoopID > 0)
		BEGIN
			SELECT @VendorCreditMemoId = [VendorCreditMemoId],@VendorPaymentDetailsId = [VendorPaymentDetailsId]
			FROM #tmpVendorCreditMemoMapping WHERE ID  = @CreditMemoLoopID;

			----Reserve CreditMemo for Used
			UPDATE [dbo].[VendorCreditMemo] SET IsVendorPayment = 1
			WHERE VendorCreditMemoId = @VendorCreditMemoId;

			SET @VendorCreditMemoId = 0;
			SET @CreditMemoLoopID = @CreditMemoLoopID - 1;
		END

		SELECT [VendorCreditMemoId]
			  ,[VendorPaymentDetailsId]
			  ,[VendorId]
			  ,[Amount]
		FROM [dbo].[VendorCreditMemoMapping] WITH (NOLOCK) WHERE VendorPaymentDetailsId = @VendorPaymentDetailsId;

	COMMIT TRANSACTION
  END TRY
  BEGIN CATCH
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRANSACTION;
		    DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            ,@AdhocComments varchar(150) = '[USP_VendorPayment_ReservedVendorCreditMemo]'			
			,@ProcedureParameters VARCHAR(3000) = ''				 
            ,@ApplicationName varchar(100) = 'PAS'
    -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
    EXEC spLogException @DatabaseName = @DatabaseName,
                        @AdhocComments = @AdhocComments,
                        @ProcedureParameters = @ProcedureParameters,
                        @ApplicationName = @ApplicationName,
                        @ErrorLogID = @ErrorLogID OUTPUT;
    RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
    RETURN (1);
  END CATCH
END