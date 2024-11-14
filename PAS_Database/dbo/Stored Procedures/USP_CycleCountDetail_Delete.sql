/*************************************************************           
 ** File:   [USP_CycleCountDetail_Delete]           
 ** Author: Moin Bloch
 ** Description: This stored procedure is used to Delete Cycle Count Details
 ** Purpose:         
 ** Date:   14/11/2024     
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    14/11/2024   Moin Bloch    Created

  EXEC [dbo].[USP_CycleCountDetail_Delete] 38,42,1
************************************************************************/
CREATE    PROCEDURE [dbo].[USP_CycleCountDetail_Delete]
@CycleCountId BIGINT,
@CycleCountDetailId BIGINT,
@MasterCompanyId INT
AS  
BEGIN  
	SET NOCOUNT ON;	
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
	
		BEGIN TRY
			BEGIN TRANSACTION
				BEGIN
					DELETE FROM [dbo].[CycleCountApproval]
					 WHERE [CycleCountDetailId] = @CycleCountDetailId
					   AND [CycleCountId] = @CycleCountId
					   AND [MasterCompanyId] = @MasterCompanyId
					
					DELETE FROM [dbo].[CycleCountDetail] 
					 WHERE [CycleCountDetailId] = @CycleCountDetailId
					   AND [CycleCountId] = @CycleCountId
					   AND [MasterCompanyId] = @MasterCompanyId
				END
			COMMIT  TRANSACTION
		END TRY  
		BEGIN CATCH      
			IF @@trancount > 0
			PRINT 'ROLLBACK'
            ROLLBACK TRAN;
            DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_CycleCountDetail_Delete' 
			  , @ProcedureParameters VARCHAR(3000) = '@CycleCountId = ''' + CAST(ISNULL(@CycleCountId, '') AS VARCHAR(100))  
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