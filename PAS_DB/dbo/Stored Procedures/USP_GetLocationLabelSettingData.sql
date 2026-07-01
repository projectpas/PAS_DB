
/*********************     
** Author:  <Sumit Kumar>    
** Create date: <10/06/2026>    
** Description: <get Location Label (Setting) by mastercompanyId>    
    
EXEC [USP_GetLocationLabelSettingData]   
**********************   
** Change History   
**********************     
** PR   Date        Author          Change Description    
** --   --------    -------         --------------------------------  
** 1    10/06/2026  Sumit Kumar    Created Get Location Label Mapping(Setting) by mastercompanyId


exec dbo.USP_GetLocationLabelSettingData 1  
**********************/   

CREATE   PROCEDURE [dbo].[USP_GetLocationLabelSettingData]
@MasterCompanyId bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN 
				
				SELECT 
					LocationLabelSettingId,
					MasterCompanyId,
					FieldWidth,
					FieldHeight,
					FieldDPI,
					MarginLeft,
					MarginRight,
					MarginTop,
					MarginBottom
				FROM [DBO].[LocationLabelSetting] 
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
              , @AdhocComments     VARCHAR(150)    = 'USP_GetLocationLabelSettingData' 
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