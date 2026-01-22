
/*************************************************************           
 ** File:   [PROCDeleteePublicationMSData]           
 ** Author:  Subhash saliya
 ** Description: This stored procedure is used to store Publication Management Structure Details
 ** Purpose:         
 ** Date:   26/25/2022      
          
 ** PARAMETERS: @ReferenceId bigint,@EntityStructureId bigint,@MasterCompanyId int,@CreatedBy varchar,@UpdatedBy varchar,@ModuleId bigint,@Opr int
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    26/25/2022   Subhash Saliya     Created
     
-- EXEC PROCDeleteePublicationMSData 47,3,2,'subhash','subhash',47,2,2
************************************************************************/

CREATE PROCEDURE [dbo].[PROCDeleteePublicationMSData]
@PublicationRecordId int

AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;	
	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN  

		DELETE from PublicationManagementStructureDetails where PublicationRecordId = @PublicationRecordId

		DELETE from PublicationManagementStructureMapping where PublicationRecordId = @PublicationRecordId
	END	
	COMMIT  TRANSACTION
	END TRY 
	BEGIN CATCH      
		IF @@trancount > 0
		PRINT 'ROLLBACK'
				ROLLBACK TRANSACTION;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'PROCDeleteePublicationMSDat' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ CAST(ISNULL(@PublicationRecordId, '') AS varchar(100))
			                     
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