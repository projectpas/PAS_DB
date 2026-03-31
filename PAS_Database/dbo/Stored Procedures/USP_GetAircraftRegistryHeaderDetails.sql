/*************************************************************           
 ** File:   [USP_GetAircraftRegistryHeaderDetails]           
 ** Author: Bhargav Saliya
 ** Description: This stored procedure is used to Get repair Order Cost Details for WO Materials.
 ** Purpose:         
 ** jira id :  PN-15843       
 ** Date:   03/23/2026

 ** PARAMETERS:           
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    27-Mar-2026  Bhargav Saliya		CREATED	
 
EXEC [dbo].[USP_GetAircraftRegistryHeaderDetails] 61501 ,10242  
**************************************************************/
CREATE    PROCEDURE [dbo].[USP_GetAircraftRegistryHeaderDetails]
(
	@AircraftRegistryId BIGINT,
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
				AR.AircraftRegistryId,
				AR.MakeTypeId,
				AR.MakeType,
				AR.AircraftModelId,
				AR.AircraftModel,
				AR.AircraftSubModel,
				AR.NumOfEngines,
				AR.TailNum,
				AR.SerialNum,
				AR.ManufacturedDate,
				AR.PlaceInServiceDate,
				AR.TotalTSN,
				AR.TotalCSN,
				AR.Hobbs,
				AR.AircraftLocation,
				AR.NextScheduled,
				AR.MEL,
				AR.AircraftStatusId,
				AR.AircraftStatus,
				AR.MaintenanceStatusId,
				AR.MaintenanceStatus,
				AR.MasterCompanyId,
				AR.Memo,
				AR.AircraftRegistryNumber
			FROM dbo.[AircraftRegistryHeader] AR WITH(NOLOCK) 
			WHERE AR.AircraftRegistryId = @AircraftRegistryId AND AR.MasterCompanyId = @MasterCompanyId 
		END
	COMMIT  TRANSACTION
	END TRY
	BEGIN CATCH
	IF @@trancount > 0
		PRINT 'ROLLBACK'
		ROLLBACK TRAN;
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
		-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetAircraftRegistryHeaderDetails' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@AircraftRegistryId, '') + ''', @Parameter2 = ' + ISNULL(@MasterCompanyId,'') + ''
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