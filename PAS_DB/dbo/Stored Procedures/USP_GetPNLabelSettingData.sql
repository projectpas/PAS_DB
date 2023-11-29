/*********************     
** Author:  <Devendra Shekh>    
** Create date: <06/07/2023>    
** Description: <get PN Label Mapping(Setting) by mastercompanyId>    
    
EXEC [USP_GetPNLabelSettingData]   
**********************   
** Change History   
**********************     
** PR   Date        Author          Change Description    
** --   --------    -------         --------------------------------  
** 1    06/07/2023  Devendra Shekh    get PN Label Mapping(Setting) by mastercompanyId

exec dbo.USP_GetPNLabelSettingData 1  
**********************/   

Create   PROCEDURE [dbo].[USP_GetPNLabelSettingData]
@MasterCompanyId bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN 
				
				SELECT 
					PNLabelMappingId,
					PNLabelId,
					Description,
					MasterCompanyId,
					FieldWidth,
					FieldHeight,
					AllPNLabelSelected
				FROM [DBO].[PNLabelMapping] 
				WHERE MasterCompanyId = @MasterCompanyId
                
			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				--PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetPNLabelSettingData' 
              , @ProcedureParameters VARCHAR(3000)  = '@MasterCompanyId = '''+ ISNULL(@MasterCompanyId, '') + ''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

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