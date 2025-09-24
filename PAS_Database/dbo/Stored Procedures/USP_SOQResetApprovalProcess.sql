/*************************************************************           
 ** File:   [USP_SOQResetApprovalProcess]           
 ** Author:   Amit Ghediya
 ** Description: This stored procedure is used to SOQ Reset Approval process
 ** Purpose:         
 ** Date: 25-06-2025    
          
 ** PARAMETERS: 

 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    15-09-2025	  Amit Ghediya	  Created 
	
************************************************************************/
CREATE     PROCEDURE [dbo].[USP_SOQResetApprovalProcess]
	@SalesOrderQuoteId BIGINT = 0,
	@SalesOrderQuotePartId BIGINT = 0,
	@MasterCompanyId BIGINT = 0
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY

		DECLARE @OpenStatusId INT = (select TOP 1 ID from [dbo].[MasterSalesOrderQuoteStatus] WITH(NOLOCK) WHERE [Name] = 'Open');
		DECLARE @PartialStatusId INT = (select TOP 1 ID from [dbo].[MasterSalesOrderQuoteStatus] WITH(NOLOCK) WHERE [Name] = 'Partially Approved');

		IF(ISNULL(@SalesOrderQuoteId,0) = 0 AND ISNULL(@SalesOrderQuotePartId,0) > 0)
		BEGIN
			 SELECT @SalesOrderQuoteId = [SalesOrderQuoteId], @MasterCompanyId = [MasterCompanyId] FROM [dbo].[SalesOrderQuotePartV1] WITH(NOLOCK) WHERE [SalesOrderQuoteId] = @SalesOrderQuoteId;
		END

		UPDATE [dbo].[SalesOrderQuoteApproval]
			SET CustomerApprovedDate = NULL,
			    CustomerApprovedById = NULL,
				ApprovalActionId = NULL,
				CustomerStatusId = NULL,
				InternalStatusId = NULL,
				CustomerApprovedBy = NULL,
				CustomerSentDate = NULL,
				ApprovalAction = NULL,
				CustomerStatus = NULL,
				InternalStatus = NULL,
				RejectedById = NULL,
				RejectedByName = NULL,
				RejectedDate = NULL,
				CustomerMemo = NULL
		WHERE [SalesOrderQuoteId] = @SalesOrderQuoteId AND [SalesOrderQuotePartId] = @SalesOrderQuotePartId 
			  AND [MasterCompanyId] = @MasterCompanyId

		DECLARE @IsHeaderStatusUpdate INT = 0;
		SET  @IsHeaderStatusUpdate = (SELECT COUNT(*) FROM [dbo].[SalesOrderQuoteApproval] WITH(NOLOCK) WHERE [SalesOrderQuoteId]= @SalesOrderQuoteId AND ApprovalActionId IS NOT NULL);

		IF(ISNULL(@IsHeaderStatusUpdate,0) = 0)
		BEGIN
			 UPDATE dbo.SalesOrderQuote WITH (ROWLOCK, UPDLOCK, READPAST)
				SET StatusId = @OpenStatusId,
				UpdatedDate = GETUTCDATE()
			WHERE [SalesOrderQuoteId] = @SalesOrderQuoteId;
		END
		ELSE
		BEGIN
			UPDATE dbo.SalesOrderQuote WITH (ROWLOCK, UPDLOCK, READPAST)
				SET StatusId = @PartialStatusId,
				UpdatedDate = GETUTCDATE()
			WHERE [SalesOrderQuoteId] = @SalesOrderQuoteId;
		END
	END TRY
	BEGIN CATCH
	DECLARE @ErrorLogID INT
	,@DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
	,@AdhocComments VARCHAR(150) = 'USP_SOQResetApprovalProcess'
	, @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ CAST(ISNULL(@SalesOrderQuoteId, '') as Varchar(100)) + 
											  '@Parameter2 = '''+ CAST(ISNULL(@SalesOrderQuotePartId, '') as Varchar(100))		
	,@ApplicationName VARCHAR(100) = 'PAS'

-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
	EXEC spLogException @DatabaseName = @DatabaseName
	,@AdhocComments = @AdhocComments
	,@ProcedureParameters = @ProcedureParameters
	,@ApplicationName = @ApplicationName
	,@ErrorLogID = @ErrorLogID OUTPUT;

	RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)

	RETURN (1);
	END CATCH
END