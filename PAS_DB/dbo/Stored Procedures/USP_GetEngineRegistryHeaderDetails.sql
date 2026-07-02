/*************************************************************           
 ** File:   [USP_GetEngineRegistryHeaderDetails]           
 ** Author: Amit Ghediya 
 ** Description: 
 ** Purpose:         
 ** jira id :  PN-17037       
 ** Date:   03/23/2026

 ** PARAMETERS:           
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
 ** 1    29/06/2026   Amit Ghediya		Created [PN-17037]
 
 
EXEC [dbo].[USP_GetEngineRegistryHeaderDetails] 61501 ,10242  
**************************************************************/
CREATE    PROCEDURE [dbo].[USP_GetEngineRegistryHeaderDetails]
(
	@EngineRegistryId BIGINT,
	@MasterCompanyId BIGINT
)
AS
BEGIN 
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    SET NOCOUNT ON
	BEGIN TRY
		BEGIN TRANSACTION
		BEGIN
			SELECT
				AR.EngineRegistryId,
				AR.MakeTypeId,
				AR.MakeType,
				AR.EngineModelId,
				AR.EngineModel,
				AR.EngineSubModel,
				AR.NumOfEngines,
				AR.TailNum,
				AR.SerialNum,
				AR.ManufacturedDate,
				AR.PlaceInServiceDate,
				AR.TotalTSN,
				AR.TotalTSNMM,
				AR.TotalCSN,
				AR.TotalCSNMM,
				AR.Hobbs,
				AR.EngineLocation,
				AR.NextScheduled,
				AR.MEL,
				AR.EngineStatusId,
				AR.EngineStatus,
				AR.MaintenanceStatusId,
				AR.MaintenanceStatus,
				AR.MasterCompanyId,
				AR.Memo,
				AR.EngineRegistryNumber,
				AR.[Description],
				AR.[EngineName]
			FROM dbo.[EngineRegistryHeader] AR WITH(NOLOCK) 
			WHERE AR.EngineRegistryId = @EngineRegistryId AND AR.MasterCompanyId = @MasterCompanyId 
		END
	COMMIT  TRANSACTION
	END TRY
	BEGIN CATCH
	IF @@trancount > 0
		PRINT 'ROLLBACK'
		ROLLBACK TRAN;
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
		-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetEngineRegistryHeaderDetails' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@EngineRegistryId, '') + ''', @Parameter2 = ' + ISNULL(@MasterCompanyId,'') + ''
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