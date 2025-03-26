
/*************************************************************           
 ** File:   [USP_GetPublicationNameByWOId_OR_WOPartId]
 ** Author:   Moin Bloch 
 ** Description: This stored procedure is used to Get Publication Name
 ** Purpose:         
 ** Date:   25/03/2025      
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    25/03/2025   Moin Bloch    Created
     
--   EXEC [USP_GetPublicationNameByWOId_OR_WOPartId] 8387,8026,''
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetPublicationNameByWOId_OR_WOPartId]
@WorkOrderId BIGINT = NULL,
@WorkOrderPartNumberId BIGINT = NULL,
@Result VARCHAR(MAX)='' OUTPUT
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY
	    DECLARE @CMMIds VARCHAR(256)=''
		
		IF(@WorkOrderId <= 0 AND @WorkOrderPartNumberId <= 0)
		BEGIN
			SET @Result = '';
		END
		ELSE
		BEGIN
			IF(@WorkOrderPartNumberId > 0)
			BEGIN
				SELECT @CMMIds = [CMMIds] FROM [dbo].[WorkOrderPartNumber] WITH(NOLOCK) WHERE [ID] = @WorkOrderPartNumberId;
			END
			ELSE
			BEGIN
				SELECT TOP 1 @CMMIds = [CMMIds] FROM [dbo].[WorkOrderPartNumber] WITH(NOLOCK) WHERE [WorkOrderId] = @WorkOrderId;
			END			
			IF(@CMMIds IS NOT NULL AND LEN(@CMMIds) > 0)
			BEGIN
				SET @Result = (SELECT STRING_AGG([PublicationId], ',') FROM [dbo].[Publication] WITH(NOLOCK) WHERE [PublicationRecordId] IN(SELECT [Item] FROM [dbo].[SplitString](@CMMIds,',')));				
			END	
			ELSE
			BEGIN
				SET @Result = '';
			END	
		END	
				
		END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
		PRINT 'ROLLBACK'
              DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetPublicationNameByWOId_OR_WOPartId' 
			  , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@WorkOrderId, '') AS VARCHAR(100))
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