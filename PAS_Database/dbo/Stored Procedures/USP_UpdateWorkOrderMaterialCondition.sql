/***************************************************************  
 ** File:  [USP_UpdateWorkOrderMaterialCondition]             
 ** Author:   Moin Bloch
 ** Description: This stored procedure is used to update Work Order Material Condition
 ** Date:  12-01-2026
            
  ** Change History             
 **************************************************************             
 ** PR   Date				Author  			Change Description              
 ** --   --------			-------				--------------------------------            
    1    12-01-2026		   Moin Bloch		    Created
 
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_UpdateWorkOrderMaterialCondition]
@workOrderId BIGINT=NULL,
@conditionId BIGINT=NULL,
@workOrderMaterialsId BIGINT=NULL,
@isKitType BIT=0,
@masterCompanyId INT=NULL, 
@updatedBy varchar(50) = NULL
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
		BEGIN TRY
			BEGIN TRANSACTION  
			BEGIN  
				IF(ISNULL(@isKitType,0) = 0)
				BEGIN
					UPDATE [dbo].[WorkOrderMaterials] 
					   SET [ConditionCodeId] = @conditionId,
						   [UpdatedBy] = @updatedBy
					 WHERE [WorkOrderMaterialsId] = @workOrderMaterialsId
					   AND [MasterCompanyId] = @masterCompanyId
				END
				ELSE
				BEGIN					
					UPDATE [dbo].[WorkOrderMaterialsKit] 
					   SET [ConditionCodeId] = @conditionId,
						   [UpdatedBy] = @updatedBy
					 WHERE [WorkOrderMaterialsKitId] = @workOrderMaterialsId
					   AND [MasterCompanyId] = @masterCompanyId
				END				
			END
		COMMIT  TRANSACTION  
		END TRY    
		BEGIN CATCH      
		IF @@trancount > 0
		    ROLLBACK TRANSACTION;  
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'USP_UpdateWorkOrderMaterialCondition'            
			, @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@workOrderId, '') AS VARCHAR(100))  
            , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW---------------------------------------------------------------------
            exec spLogException 
                    @DatabaseName			= @DatabaseName
                    , @AdhocComments			= @AdhocComments
                    , @ProcedureParameters		= @ProcedureParameters
                    , @ApplicationName         = @ApplicationName
                    , @ErrorLogID              = @ErrorLogID OUTPUT ;
            RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
            RETURN(1);
	END CATCH
END