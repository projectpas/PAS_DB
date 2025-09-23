/*************************************************************           
 ** File:   [USP_SOResetApprovalProcess]           
 ** Author:   Amit Ghediya
 ** Description: This stored procedure is used to SO Reset Approval process
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
CREATE     PROCEDURE [dbo].[USP_SOResetApprovalProcess]
	@SalesOrderId BIGINT = 0,
	@SalesOrderPartId BIGINT = 0,
	@MasterCompanyId BIGINT = 0
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY

		DECLARE @OpenStatusId INT = (select TOP 1 ID from DBO.MasterSalesOrderStatus WITH(NOLOCK) WHERE [Name] = 'Open');
		DECLARE @PartialStatusId INT = (select TOP 1 ID from DBO.MasterSalesOrderStatus WITH(NOLOCK) WHERE [Name] = 'Partially Approved');

		IF(ISNULL(@SalesOrderId,0) = 0 AND ISNULL(@SalesOrderPartId,0) > 0)
		BEGIN
			 SELECT @SalesOrderId = [SalesOrderId], @MasterCompanyId = [MasterCompanyId] FROM [dbo].[SalesOrderPartV1] WITH(NOLOCK) WHERE [SalesOrderPartId] = @SalesOrderPartId;
		END

		UPDATE [dbo].[SalesOrderApproval]
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
		WHERE [SalesOrderId] = @SalesOrderId AND [SalesOrderPartId] = @SalesOrderPartId 
			  AND [MasterCompanyId] = @MasterCompanyId

		DECLARE @IsHeaderStatusUpdate INT = 0;
		SET  @IsHeaderStatusUpdate = (SELECT COUNT(*) FROM [dbo].[SalesOrderApproval] WITH(NOLOCK) WHERE salesorderid= @SalesOrderId AND ApprovalActionId IS NOT NULL);

		IF(ISNULL(@IsHeaderStatusUpdate,0) = 0)
		BEGIN
			 EXEC dbo.SP_UpdateSOHeaderStatusBySOId @SalesOrderId
		END
		ELSE
		BEGIN
			UPDATE dbo.SalesOrder WITH (ROWLOCK, UPDLOCK, READPAST)
				SET StatusId = @PartialStatusId,
				UpdatedDate = GETUTCDATE()
			WHERE SalesOrderId = @SalesOrderId;
		END
		
		--UPDATE dbo.SalesOrder
		--SET StatusId = @OpenStatusId,UpdatedDate = GETUTCDATE()
		--WHERE SalesOrderId = @SalesOrderId;
		--IF NOT EXISTS(SELECT TOP 1 SalesOrderId FROM [dbo].[SalesOrder] WITH(NOLOCK) WHERE StatusId = @OpenStatusId AND SalesOrderId = @SalesOrderId)
		--BEGIN
		--	UPDATE dbo.SalesOrder WITH (ROWLOCK, UPDLOCK, READPAST)
		--		SET StatusId = @OpenStatusId,
		--		UpdatedDate = GETUTCDATE()
		--	WHERE SalesOrderId = @SalesOrderId;					
		--END
		
	END TRY
	BEGIN CATCH
	DECLARE @ErrorLogID INT
	,@DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
	,@AdhocComments VARCHAR(150) = 'USP_SOResetApprovalProcess'
	, @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ CAST(ISNULL(@SalesOrderId, '') as Varchar(100)) + 
											  '@Parameter2 = '''+ CAST(ISNULL(@SalesOrderPartId, '') as Varchar(100))		
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