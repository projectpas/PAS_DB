/*************************************************************           
 ** File:   [SP_UpdateSOHeaderStatusBySOId]           
 ** Author:  Rajesh Gami
 ** Description: This stored procedure is used to update SO Header Status Based on part status
 ** Purpose:         
 ** Date:  14/07/2025  
          
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    14/07/2025  Rajesh Gami		Created
    2    23/07/2025  Bhargav Saliya		Modified and select @TotalParts from the [SalesOrderPartV1] instead of [SalesOrderApproval]
     
************************************************************************/

CREATE   PROCEDURE [dbo].[SP_UpdateSOHeaderStatusBySOId]
@SalesOrderId bigint NULL= 0
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;	
	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN 
		IF(@SalesOrderId > 0)
		BEGIN
				DECLARE @OpenStatusId INT = (select TOP 1 ID from DBO.MasterSalesOrderStatus WITH (NOLOCK) WHERE [Name] = 'Open');
				DECLARE @ApprovedStatusId INT = (select TOP 1 ID from DBO.MasterSalesOrderStatus WITH (NOLOCK) WHERE [Name] = 'Approved');
				DECLARE @PartiallyApprovedStatusId INT = (select TOP 1 ID from DBO.MasterSalesOrderStatus WITH (NOLOCK) WHERE [Name] = 'Partially Approved');
				DECLARE @PendingStatusId INT = (select TOP 1 ID from DBO.MasterSalesOrderStatus WITH (NOLOCK) WHERE [Name] = 'Pending');
				
				DECLARE @PartApprovedStatusId INT = (select TOP 1 ApprovalStatusId from DBO.[ApprovalStatus] WITH (NOLOCK) WHERE [Name] = 'Approved');
				DECLARE @PartRejectedStatusId INT = (select TOP 1 ApprovalStatusId from DBO.[ApprovalStatus] WITH (NOLOCK) WHERE [Name] = 'Rejected');

				DECLARE @WaitingForApprovalStatusId INT = (select TOP 1 ApprovalStatusId from DBO.[ApprovalStatus] WITH (NOLOCK) WHERE [Name] = 'Waiting for Approval');
							
				DECLARE @TotalParts INT = (
					SELECT COUNT(*) FROM dbo.SalesOrderPartV1 WITH (NOLOCK) WHERE SalesOrderId = @SalesOrderId AND ISNULL(IsDeleted,0) = 0
				);
            
				DECLARE @ApprovedParts INT = (
					SELECT COUNT(*) FROM dbo.SalesOrderApproval WITH (NOLOCK) 
					WHERE SalesOrderId = @SalesOrderId AND CustomerStatusId = @PartApprovedStatusId AND ISNULL(IsDeleted,0) = 0
				);

				DECLARE @RejectedParts INT = (
					SELECT COUNT(*) FROM dbo.SalesOrderApproval WITH (NOLOCK) 
					WHERE SalesOrderId = @SalesOrderId AND CustomerStatusId = @PartRejectedStatusId AND ISNULL(IsDeleted,0) = 0
				);

				DECLARE @WaitingForApprovalParts INT = (
					SELECT COUNT(*) FROM dbo.SalesOrderApproval WITH (NOLOCK) 
					WHERE SalesOrderId = @SalesOrderId AND CustomerStatusId = @WaitingForApprovalStatusId AND ISNULL(IsDeleted,0) = 0
				);
            
				IF @ApprovedParts = @TotalParts AND @TotalParts > 0
				BEGIN            
					UPDATE dbo.SalesOrder
					SET StatusId = @ApprovedStatusId,UpdatedDate = GETUTCDATE()
					WHERE SalesOrderId = @SalesOrderId;
				END
				ELSE IF @ApprovedParts >= 1 AND @ApprovedParts < @TotalParts
				BEGIN
               
					UPDATE dbo.SalesOrder
					SET StatusId = @PartiallyApprovedStatusId,UpdatedDate = GETUTCDATE()
					WHERE SalesOrderId = @SalesOrderId;
				END
				ELSE IF @RejectedParts = @TotalParts AND @TotalParts > 0
				BEGIN
               
					UPDATE dbo.SalesOrder
					SET StatusId = @OpenStatusId,UpdatedDate = GETUTCDATE()
					WHERE SalesOrderId = @SalesOrderId;
				END
				ELSE IF @WaitingForApprovalParts > 0
				BEGIN
					UPDATE dbo.SalesOrder
					SET StatusId = @PendingStatusId,UpdatedDate = GETUTCDATE()
					WHERE SalesOrderId = @SalesOrderId;
				END
				ELSE
				BEGIN
					UPDATE dbo.SalesOrder
					SET StatusId = @OpenStatusId,UpdatedDate = GETUTCDATE()
					WHERE SalesOrderId = @SalesOrderId;
				END


		END
	END	
	COMMIT  TRANSACTION
	END TRY 
	BEGIN CATCH      
		IF @@trancount > 0
		PRINT 'ROLLBACK'
				ROLLBACK TRANSACTION;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'SP_UpdateSOHeaderStatusBySOId' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ CAST(ISNULL(@SalesOrderId, '') AS varchar(100))
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------------------------------------
              exec spLogException 
                       @DatabaseName           = @DatabaseName
                     , @AdhocComments          = @AdhocComments
                     , @ProcedureParameters	   = @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID                    = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
	END CATCH
END