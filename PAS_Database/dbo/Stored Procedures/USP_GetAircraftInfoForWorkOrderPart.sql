/************************************************************************************
 ** File:   [USP_GetAircraftInfoForWorkOrderPart]
 ** Author: Amit Ghediya
 ** Description: Given a WorkOrderPartNumber row (the "Line #" on a Work Order), returns the
 **              aircraft it's linked to (if any), so the Work Order's "Worksheet" tab can
 **              auto-populate AC Make/Type, AC Model, AC Tail Num and AC Serial Num the same
 **              way the Aircraft Maintenance tab's "Create Worksheet" action does. Returns an
 **              empty result set when the Work Order was not created from an aircraft.
 ** Purpose:
 ** Date:   01-Oct-2026

 ** PARAMETERS:
 @WorkOrderPartNumberId BIGINT

 ** RETURN VALUE:

 **************************************************************************************
  ** Change History
 **************************************************************************************
 ** PR    Date					Author				Change Description
 ** --    --------			-----------				--------------------------------
	 1    01-Oct-2026			Amit Ghediya			Created	 

	 EXEC [dbo].[USP_GetAircraftInfoForWorkOrderPart] 1
****************************************************************************************/
CREATE PROCEDURE [dbo].[USP_GetAircraftInfoForWorkOrderPart]
	@WorkOrderPartNumberId BIGINT
AS
BEGIN
		SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
        SET NOCOUNT ON  
        BEGIN TRY

			SELECT
				ARH.AircraftRegistryId  AS aircraftRegistryId,
				ARH.MakeTypeId          AS makeTypeId,
				ARH.MakeType            AS makeType,
				ARH.AircraftModelId     AS aircraftModelId,
				ARH.AircraftModel       AS aircraftModel,
				ARH.TailNum             AS tailNum,
				ARH.SerialNum           AS serialNum
			FROM dbo.WorkOrderPartNumber WOP WITH (NOLOCK)
			INNER JOIN dbo.AircraftRegistryHeader ARH WITH (NOLOCK) ON ARH.AircraftRegistryId = WOP.AircraftRegistryId
			WHERE WOP.ID = @WorkOrderPartNumberId
			  AND ISNULL(WOP.IsFromAircraft, 0) = 1
			  AND ISNULL(WOP.AircraftRegistryId, 0) > 0;

	  END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetAircraftInfoForWorkOrderPart' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@WorkOrderPartNumberId, '')
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException 
                       @DatabaseName			= @DatabaseName
                     , @AdhocComments			= @AdhocComments
                     , @ProcedureParameters		= @ProcedureParameters
                     , @ApplicationName			= @ApplicationName
                     , @ErrorLogID              = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN
		END CATCH
END
