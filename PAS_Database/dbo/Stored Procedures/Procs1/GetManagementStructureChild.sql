﻿CREATE PROCEDURE [dbo].[GetManagementStructureChild]
@ManagementStructureId bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    SET NOCOUNT ON

	 BEGIN TRY
		BEGIN TRANSACTION
			BEGIN
				;with temp (
                             ManagementStructureId, ParentId
                            ) as (
                             select ManagementStructureId, ParentId
                             from   dbo.ManagementStructure WITH (NOLOCK)
                             where  ParentId = @ManagementStructureId 
                             union  all
                             select e.ManagementStructureId, e.ParentId
                             from   temp oc
                             join   dbo.ManagementStructure e WITH (NOLOCK)
                             on     e.ParentId = oc.ManagementStructureId
                            )
                            select ManagementStructureId from temp;
			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'GetManagementStructureChild' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@ManagementStructureId, '') +''
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