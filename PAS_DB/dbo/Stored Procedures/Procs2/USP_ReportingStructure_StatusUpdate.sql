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
    2    09/11/2025		Devendra Shekh					added Delete/Restore Operation

exec USP_ReportingStructure_StatusUpdate 1,0
************************************************************************/

CREATE   PROCEDURE [dbo].[USP_ReportingStructure_StatusUpdate]
@ReportingStructureId bigint,
@isActive bit,
@UpdatedBy varchar(50),
@IsDeleted bit,
@Opr int
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN 
				--@Opr : 0 -- Delete/Restore
				--@Opr : 1 -- Active/InActive

				IF(ISNULL(@Opr, 0) = 1)
				BEGIN
					IF(@isActive = 'false') 
					BEGIN
						UPDATE	[dbo].[ReportingStructure]
						SET		IsActive = 0,
								UpdatedBy = @UpdatedBy,
								UpdatedDate = GETUTCDATE()
						WHERE [ReportingStructureId] = @ReportingStructureId
					END
				ELSE
					BEGIN
						UPDATE	[dbo].[ReportingStructure]
						SET		IsActive = 1,
								UpdatedBy = @UpdatedBy,
								UpdatedDate = GETUTCDATE()
						WHERE [ReportingStructureId] = @ReportingStructureId
					END
				END
				ELSE
				BEGIN
					IF(@IsDeleted = 'false') 
					BEGIN
						UPDATE	[dbo].[ReportingStructure]
						SET		IsDeleted = 0,
								UpdatedBy = @UpdatedBy,
								UpdatedDate = GETUTCDATE()
						WHERE [ReportingStructureId] = @ReportingStructureId
					END
				ELSE
					BEGIN
						UPDATE	[dbo].[ReportingStructure]
						SET		IsDeleted = 1,
								UpdatedBy = @UpdatedBy,
								UpdatedDate = GETUTCDATE()
						WHERE [ReportingStructureId] = @ReportingStructureId
					END
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