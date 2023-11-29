/*************************************************************           
 ** File:   [USP_ReportingStructure_StatusUpdate]
 ** Author:   Devendra Shekh
 ** Description: This stored procedure is used active/inactive reporting structure
 ** Purpose:         
 ** Date:    09/13/2023
          
 ** PARAMETERS:  
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date			 Author						Change Description            
 ** --   --------		 -------					--------------------------------          
    1    09/13/2023		Devendra Shekh					Created

exec USP_ReportingStructure_StatusUpdate 1,0
************************************************************************/

CREATE   PROCEDURE [dbo].[USP_ReportingStructure_StatusUpdate]
@ReportingStructureId bigint,
@isActive bit,
@UpdatedBy varchar(50)
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN 
				IF(@isActive = 'false') 
					BEGIN
						UPDATE	[dbo].[ReportingStructure]
						SET		IsActive = 0,
								UpdatedBy = @UpdatedBy
						WHERE [ReportingStructureId] = @ReportingStructureId
					END
				ELSE
					BEGIN
						UPDATE	[dbo].[ReportingStructure]
						SET		IsActive = 1,
								UpdatedBy = @UpdatedBy
						WHERE [ReportingStructureId] = @ReportingStructureId
					END
				
			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				--PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_ReportingStructure_StatusUpdate' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@ReportingStructureId, '') + ''
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