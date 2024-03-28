/*********************             
 ** File:   USP_UpdateCreditMemoStatus_Refund           
 ** Author:  Devendra Shekh   
 ** Description: Get Credit Memo data for refund
 ** Purpose:           
 ** Date:  17-OCT-2023        
            
    
 **********************             
  ** Change History             
 **********************             
 ** PR   Date			Author				Change Description              
 ** --   --------		-------				--------------------------------            
    1    17/10/2023		Devendra Shekh        Created  
    2    18/10/2023		Devendra Shekh        MOdified to insert data for customer-refund  
    3    20/10/2023		Devendra Shekh        added mslevel data for customerrefund 
    4    27/10/2023		Devendra Shekh        changed refund to Refund Requested
    5    27/03/2024		Devendra Shekh        added vendorId
   
 -- exec USP_UpdateCreditMemoStatus_Refund 
**********************/   
  
CREATE   PROCEDURE [dbo].[USP_UpdateCreditMemoStatus_Refund]  
	@HeaderIds VARCHAR(150),
	@MasterCompanyId BIGINT,
	@ManagementStructureId BIGINT,
	@RefundReqDate DATETIME2,
	@UserName VARCHAR(100),
	@VendorId BIGINT
AS  
BEGIN  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;  
 BEGIN TRY    
   
	BEGIN

		DECLARE @TotalRec BIGINT, @Start BIGINT = 1, @CustomerId BIGINT, @SumAmount BIGINT = 0, @CustomerCode VARCHAR(100) = '',@MsModuleId BIGINT = 0,
		@CustRefStatus VARCHAR(100) = 'Refund Requested', @CustRefundId  BIGINT = 0, @StartCMMapping BIGINT = 1, @CreditMemoHeaderId BIGINT = 0;

		SELECT @MsModuleId = (SELECT ManagementStructureModuleId FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE [ModuleName] = 'CustomerRefund')

		IF OBJECT_ID('tempdb.dbo.#TempTableName', 'U') IS NOT NULL
		BEGIN
			DROP TABLE #TempTableName; 
		END
	
		IF OBJECT_ID('tempdb.dbo.#CredtiTemp', 'U') IS NOT NULL
		BEGIN
			DROP TABLE #CredtiTemp; 
		END

		CREATE TABLE #CredtiTemp(
			[ID] BIGINT NOT NULL IDENTITY,
			[CreditMemoHeaderId] BIGINT NULL,
			[CustomerId] BIGINT NULL,
			[Amount] BIGINT NULL,
		)

		SELECT [CreditMemoHeaderId], [CustomerId], [Amount] INTO #TempTableName
		FROM [dbo].[CreditMemo] WITH(NOLOCK)
		WHERE CreditMemoHeaderId IN(
			SELECT CAST(Item AS BIGINT) AS CreditMemoHeaderId
			FROM dbo.SplitString(@HeaderIds, ','))

		INSERT INTO #CredtiTemp([CreditMemoHeaderId], [CustomerId], [Amount]) SELECT [CreditMemoHeaderId], [CustomerId], [Amount] FROM #TempTableName
		SELECT @TotalRec = COUNT([CreditMemoHeaderId]), @CustomerId = MAX([CustomerId]), @SumAmount = ABS(SUM([Amount]))  FROM #CredtiTemp

		SELECT @CustomerCode = CustomerCode FROM [dbo].[Customer] WITH(NOLOCK) WHERE [CustomerId] = @CustomerId

		INSERT INTO [dbo].[CustomerRefund]([CustomerId],[CustomerCode],[RefundRequestDate],[Status],[MasterCompanyId],[ManagementStructureId],[CreatedBy],[CreatedDate],[UpdatedBy],[UpdatedDate],[IsActive],[IsDeleted],[VendorId])
		VALUES (@CustomerId,@CustomerCode,@RefundReqDate,@CustRefStatus,@MasterCompanyId,@ManagementStructureId,@UserName,GETUTCDATE(),@UserName,GETUTCDATE(),1,0,@VendorId)

		SELECT @CustRefundId = SCOPE_IDENTITY()    

		EXEC [PROCAddUpdateCreditMemoMSData] @CustRefundId,@ManagementStructureId,@MasterCompanyId,@UserName,@UserName,@MsModuleId,1
		--- updating CreditMemo Header status and customerrefund data insert -----------------------------
		WHILE @Start <= @TotalRec
		BEGIN

			SELECT @CreditMemoHeaderId = CreditMemoHeaderId FROM #CredtiTemp WHERE [ID] = @Start

			UPDATE [dbo].[CreditMemo]
			SET StatusId = (SELECT Id FROM [dbo].[CreditMemoStatus] WHERE [Name] = 'Refund Requested'), [Status] = (SELECT [Name] FROM [dbo].[CreditMemoStatus] WHERE [Name] = 'Refund Requested'), [CustomerRefundId] = @CustRefundId
			WHERE CreditMemoHeaderId = (SELECT CreditMemoHeaderId FROM #CredtiTemp WHERE [ID] = @Start)

			INSERT INTO [dbo].[RefundCreditMemoMapping]([CustomerRefundId],[CreditMemoHeaderId],[MasterCompanyId],[CreatedBy],[CreatedDate],[UpdatedBy],[UpdatedDate],[IsActive],[IsDeleted])
			VALUES (@CustRefundId,@CreditMemoHeaderId,@MasterCompanyId,@UserName,GETUTCDATE(),@UserName,GETUTCDATE(),1,0)

			SET @Start = @Start + 1
		END
		-----------------------------------------------------------------------------------------------------
		EXEC [dbo].[USP_PostCreditMemo_RefundBatchDetails] @CustRefundId;
	END
  
 END TRY      
 BEGIN CATCH  
  DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
        , @AdhocComments     VARCHAR(150)    = 'USP_UpdateCreditMemoStatus_Refund'   
        ,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@HeaderIds, '') AS varchar(100))  
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
 END CATCH  
END