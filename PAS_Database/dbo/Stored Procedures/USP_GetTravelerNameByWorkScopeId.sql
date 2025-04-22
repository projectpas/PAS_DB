/*************************************************************  
** Author:  <RAJESH GAMI>  
** Create date: 22 Apr 2025  
** Description: <Get Traveler Name By WorkScopeId and ItemmasterId>  
 
**************************************************************
** Change History
**************************************************************  
** PR   Date        Author          Change Description  
** --   --------    -------         --------------------------------
** 1    22 Apr 2025  RAJESH GAMI    CREATED 
EXEC [dbo].[USP_GetTravelerNameByWorkScopeId] 2,23  
**************************************************************/
CREATE     PROCEDURE [dbo].[USP_GetTravelerNameByWorkScopeId]              
@WorkOrderScopeId bigint,              
@ItemMasterId bigint = 0             
AS              
BEGIN              
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED              
 SET NOCOUNT ON;              
             
  BEGIN TRY              
		DECLARE @TravelerName VARCHAR(250) = '';

		SELECT TOP 1 @TravelerName = CONVERT(VARCHAR(250), ISNULL(TravelerId, ''))
		FROM dbo.Traveler_Setup WITH (NOLOCK)
		WHERE WorkScopeId = @WorkOrderScopeId
		  AND ItemMasterId = @ItemMasterId
		  AND ISNULL(IsVersionIncrease, 0) = 0;

		IF (@TravelerName = '' OR @TravelerName = '0')
		BEGIN
			SELECT TOP 1 @TravelerName = CONVERT(VARCHAR(250), ISNULL(TravelerId, ''))
			FROM dbo.Traveler_Setup WITH (NOLOCK)
			WHERE WorkScopeId = @WorkOrderScopeId
			  AND ISNULL(ItemMasterId, 0) = 0
			  AND ISNULL(IsVersionIncrease, 0) = 0;
		END
		SET @TravelerName = CASE WHEN @TravelerName = '0' THEN '' ELSE @TravelerName END;
		SELECT @TravelerName AS TravelerName;
  END TRY                  
  BEGIN CATCH                    
   IF @@trancount > 0              
    PRINT 'ROLLBACK'              
	SELECT
    ERROR_NUMBER() AS ErrorNumber,
    ERROR_STATE() AS ErrorState,
    ERROR_SEVERITY() AS ErrorSeverity,
    ERROR_PROCEDURE() AS ErrorProcedure,
    ERROR_LINE() AS ErrorLine,
    ERROR_MESSAGE() AS ErrorMessage;
    DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()              
             
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------              
              , @AdhocComments     VARCHAR(150)    = 'USP_GetTravelerNameByWorkScopeId'                            
			  , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@WorkOrderScopeId, '') AS VARCHAR(100)) + '@Parameter2 = ''' + CAST(ISNULL(@ItemMasterId, '') AS VARCHAR(100))             
              , @ApplicationName VARCHAR(100) = 'PAS'              
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------              
             
              exec spLogException              
                       @DatabaseName           = @DatabaseName              
                     , @AdhocComments          = @AdhocComments              
                     , @ProcedureParameters    = @ProcedureParameters              
                     , @ApplicationName        = @ApplicationName              
                     , @ErrorLogID                    = @ErrorLogID OUTPUT ;              
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)              
              RETURN(1);              
  END CATCH              
END