/*************************************************************           
** Author:  <SHREY CHANDEGARA>  
** Create date: <13/01/2025>  [mm/dd/yyyy]
** Description: <Get Saved Cash Receipt Params ById>  
************************************************************** 
** Change History 
**************************************************************   
** PR   Date			Author					Change Description  
** --   --------		-------					--------------------------------
** 1	20/11/2024		SHREY CHANDEGARA			Created

-- EXEC USP_CashReceiptSearchParams_ById 2,1
**************************************************************/ 
CREATE    PROCEDURE [dbo].[USP_CashReceiptSearchParams_ById]
	@cashReceiptSearchParamsId BIGINT = NULL,
	@MasterCompanyId BIGINT = NULL
AS
BEGIN

  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  SET NOCOUNT ON  
  BEGIN TRY
		BEGIN TRANSACTION
			BEGIN
				SELECT	
					CashReceiptSearchParamsId,
					UrlName,
					FromInvoiceDate,
					ToInvoiceDate,
					ISNULL(FromCheckNum, '') AS 'FromCheckNum',
					ISNULL(ToCheckNum, '') AS 'ToCheckNum',
					FromReceiptDate AS 'FromReceiptDate',
					ToReceiptDate AS 'ToReceiptDate',
					ISNULL(FromInvoiceNum, '') AS 'FromInvoiceNum',
					ISNULL(ToInvoiceNum, '') AS 'ToInvoiceNum',
					FromPostDate AS 'FromPostDate',
					ToPostDate AS 'ToPostDate',
					ISNULL(PaymentMethodId, '') AS 'PaymentMethodId',
					ISNULL(BankAcct, '') AS 'BankAcct',
					ISNULL(CustomerId, '') AS 'CustomerId',
					ISNULL(Level1, '') AS 'Level1',
					ISNULL(Level2, '') AS 'Level2',
					ISNULL(Level3, '') AS 'Level3',
					ISNULL(Level4, '') AS 'Level4',
					ISNULL(Level5, '') AS 'Level5',
					ISNULL(Level6, '') AS 'Level6',
					ISNULL(Level7, '') AS 'Level7',
					ISNULL(Level8, '') AS 'Level8',
					ISNULL(Level9, '') AS 'Level9',
					ISNULL(Level10, '') AS 'Level10',
					MasterCompanyId,
					CreatedBy,
					CreatedDate,
					UpdatedBy,
					UpdatedDate,
					IsActive,
					IsDeleted
				FROM dbo.CashReceiptSearchParams SISP WITH (NOLOCK)
				WHERE	SISP.CashReceiptSearchParamsId = @cashReceiptSearchParamsId AND SISP.MasterCompanyId = @MasterCompanyId

			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_CashReceiptSearchParams_ById' 
              , @ProcedureParameters VARCHAR(3000)  = '@integrationID = '''+ ISNULL(@cashReceiptSearchParamsId, '') + ''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException 
                       @DatabaseName           =  @DatabaseName
                     , @AdhocComments          =  @AdhocComments
                     , @ProcedureParameters	   =  @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID             =  @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
		END CATCH	
			            
END