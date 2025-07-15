
/*************************************************************           
 ** File:   [SP_UpdateSOQHeaderStatusBySOQId]           
 ** Author:  Rajesh Gami
 ** Description: This stored procedure is used to update SOQ Header Status Based on part status
 ** Purpose:         
 ** Date:  14/07/2025  
          
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    14/07/2025  Rajesh Gami		Created
     
************************************************************************/

CREATE   PROCEDURE [dbo].[SP_UpdateSOQHeaderStatusBySOQId]
@SalesOrderQuoteId bigint NULL= 0
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;	
	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN 
		IF(@SalesOrderQuoteId > 0)
		BEGIN
				DECLARE @OpenStatusId INT = (select TOP 1 ID from DBO.MasterSalesOrderQuoteStatus WITH (NOLOCK) WHERE [Name] = 'Open');
				DECLARE @ApprovedStatusId INT = (select TOP 1 ID from DBO.MasterSalesOrderQuoteStatus WITH (NOLOCK) WHERE [Name] = 'Approved');
				DECLARE @PartiallyApprovedStatusId INT = (select TOP 1 ID from DBO.MasterSalesOrderQuoteStatus WITH (NOLOCK) WHERE [Name] = 'Partially Approved');
				
				DECLARE @PartApprovedStatusId INT = (select TOP 1 ApprovalStatusId from DBO.[ApprovalStatus] WITH (NOLOCK) WHERE [Name] = 'Approved');
				DECLARE @PartRejectedStatusId INT = (select TOP 1 ApprovalStatusId from DBO.[ApprovalStatus] WITH (NOLOCK) WHERE [Name] = 'Rejected');
							
				DECLARE @TotalParts INT = (
					SELECT COUNT(*) FROM dbo.SalesOrderQuoteApproval WITH (NOLOCK) WHERE SalesOrderQuoteId = @SalesOrderQuoteId AND ISNULL(IsDeleted,0) = 0
				);
            
				DECLARE @ApprovedParts INT = (
					SELECT COUNT(*) FROM dbo.SalesOrderQuoteApproval WITH (NOLOCK) 
					WHERE SalesOrderQuoteId = @SalesOrderQuoteId AND CustomerStatusId = @PartApprovedStatusId AND ISNULL(IsDeleted,0) = 0
				);

				DECLARE @RejectedParts INT = (
					SELECT COUNT(*) FROM dbo.SalesOrderQuoteApproval WITH (NOLOCK) 
					WHERE SalesOrderQuoteId = @SalesOrderQuoteId AND CustomerStatusId = @PartRejectedStatusId AND ISNULL(IsDeleted,0) = 0
				);
            
				IF @ApprovedParts = @TotalParts AND @TotalParts > 0
				BEGIN            
					UPDATE dbo.SalesOrderQuote
					SET StatusId = @ApprovedStatusId,UpdatedDate = GETUTCDATE()
					WHERE SalesOrderQuoteId = @SalesOrderQuoteId;
				END
				ELSE IF @ApprovedParts >= 1 AND @ApprovedParts < @TotalParts
				BEGIN
               
					UPDATE dbo.SalesOrderQuote
					SET StatusId = @PartiallyApprovedStatusId,UpdatedDate = GETUTCDATE()
					WHERE SalesOrderQuoteId = @SalesOrderQuoteId;
				END
				ELSE IF @RejectedParts = @TotalParts AND @TotalParts > 0
				BEGIN
               
					UPDATE dbo.SalesOrderQuote
					SET StatusId = @OpenStatusId,UpdatedDate = GETUTCDATE()
					WHERE SalesOrderQuoteId = @SalesOrderQuoteId;
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
              , @AdhocComments     VARCHAR(150)    = 'SP_UpdateSOQHeaderStatusBySOQId' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ CAST(ISNULL(@SalesOrderQuoteId, '') AS varchar(100))
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