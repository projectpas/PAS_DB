/*************************************************************   
** Author:  <SHREY CHANDEGARA>  
** Create date: <12/01/2025>  [mm/dd/yyyy]
** Description: <INSERT/UPDATE  DATA IN THE PARAMS TABLE>  
************************************************************** 
** Change History 
**************************************************************   
** PR   Date			Author					Change Description  
** --   --------		-------					--------------------------------
** 1	12/01/2025		SHREY CHANDEGARA			Created

-- exec USP_CashReceiptSearchParams_ById @cashReceiptSearchParamsId=1,@MasterCompanyId=1
**************************************************************/
-----------------------------------------------------------------------------
CREATE   PROCEDURE [dbo].[USP_SaveCashReceiptSearchParams]
	@tblType_CashReceiptSearchParamsType [CashReceiptSearchParamsType] READONLY,
	@UserRoleId BIGINT = NULL,
	@CurrentUserEmployeeId BIGINT = NULL,
	@UserName VARCHAR(256) = NULL
AS
BEGIN
	
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
		
		BEGIN TRY
			BEGIN

				DECLARE @SaveCashReceiptSearchParams BIGINT = 0;
				DECLARE @UserlName VARCHAR(500) = NULL;
				DECLARE @MasterCompanyId INT = 0;

				INSERT INTO [dbo].[CashReceiptSearchParams] 
						([UrlName] ,[FromInvoiceDate] ,[ToInvoiceDate] ,[FromCheckNum] ,[ToCheckNum] ,[FromReceiptDate] ,[ToReceiptDate] ,[FromInvoiceNum] ,[ToInvoiceNum] ,
							[FromPostDate] ,[ToPostDate] ,[PaymentMethodId] ,[BankAcct] ,[CustomerId] ,[Level1] ,[Level2] ,[Level3] ,[Level4] ,[Level5] ,[Level6] ,[Level7] ,[Level8] ,
							[Level9] ,[Level10] ,[MasterCompanyId] ,[CreatedBy] ,[CreatedDate] ,[UpdatedBy] ,[UpdatedDate] ,[IsActive] ,[IsDeleted]) 

				SELECT	[UrlName],[FromInvoiceDate],[ToInvoiceDate] ,[FromCheckNum],[ToCheckNum],[FromReceiptDate],[ToReceiptDate],[FromInvoiceNum] ,[ToInvoiceNum],[FromPostDate]
						,[ToPostDate],[PaymentMethodId] ,[BankAcct],[CustomerId],Level1, Level2, Level3, Level4, Level5, Level6, Level7, Level8, Level9, Level10, MasterCompanyId, CreatedBy,
						GETUTCDATE(), CreatedBy, GETUTCDATE(), 1, 0
						
				FROM @tblType_CashReceiptSearchParamsType WHERE ISNULL(CashReceiptSearchParamsId, 0) = 0;

				SET @SaveCashReceiptSearchParams = SCOPE_IDENTITY();

				IF(ISNULL(@SaveCashReceiptSearchParams, 0) > 0)
				BEGIN
					SELECT @MasterCompanyId = [MasterCompanyId], @UserlName = [CreatedBy] FROM [dbo].[CashReceiptSearchParams] WITH(NOLOCK) WHERE [CashReceiptSearchParamsId] = @SaveCashReceiptSearchParams;

					EXEC [USP_CashReceiptEmployeeMappingData] @SaveCashReceiptSearchParams, @CurrentUserEmployeeId, @MasterCompanyId, @UserlName;
				END
				ELSE
				BEGIN
					UPDATE GLS
					SET 
						GLS.FromInvoiceDate = t.FromInvoiceDate,
						GLS.ToInvoiceDate = t.ToInvoiceDate,
						GLS.FromCheckNum = t.FromCheckNum,
						GLS.ToCheckNum = t.ToCheckNum,
						GLS.FromReceiptDate = t.FromReceiptDate,
						GLS.ToReceiptDate = t.ToReceiptDate,
						GLS.FromInvoiceNum = t.FromInvoiceNum,
						GLS.ToInvoiceNum = t.ToInvoiceNum,
						GLS.FromPostDate = t.FromPostDate,
						GLS.ToPostDate = t.ToPostDate,
						GLS.PaymentMethodId = t.PaymentMethodId,
						GLS.BankAcct = t.BankAcct,
						GLS.CustomerId = t.CustomerId,
						GLS.Level1 = t.Level1,
						GLS.Level2 = t.Level2,
						GLS.Level3 = t.Level3,
						GLS.Level4 = t.Level4,
						GLS.Level5 = t.Level5,
						GLS.Level6 = t.Level6,
						GLS.Level7 = t.Level7,
						GLS.Level8 = t.Level8,
						GLS.Level9 = t.Level9,
						GLS.Level10 = t.Level10,
						GLS.UpdatedBy = t.CreatedBy,
						
						GLS.UpdatedDate = GETUTCDATE()
					FROM [dbo].[CashReceiptSearchParams] GLS WITH(NOLOCK)
					INNER JOIN @tblType_CashReceiptSearchParamsType t ON GLS.CashReceiptSearchParamsId = t.CashReceiptSearchParamsId
					WHERE ISNULL(t.CashReceiptSearchParamsId, 0) <> 0;
				END

			END
		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
                    ROLLBACK TRAN;
              DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_SaveCashReceiptSearchParams' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
              exec spLogException 
                       @DatabaseName           = @DatabaseName
                     , @AdhocComments          = @AdhocComments
                     , @ProcedureParameters = @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID                    = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
        END CATCH     
END