/*************************************************************             
 ** File:   [USP_GetWorksheetHeaderByIdSSRS]          
 ** Author:   
 ** Description: This stored procedure is used to get records from [WorksheetHeader].
 ** Purpose:           
 ** Date:  [21-May-2026] 
            
    
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** PR   Date         Author              Change Description              
 ** --   --------     -------          --------------------------------     
    1    21/05/2026  Ayushi Patel              Created
**************************************************************/

CREATE PROCEDURE [dbo].[USP_GetWorksheetHeaderByIdSSRS]
    @WorksheetHeaderId BIGINT,
    @MasterCompanyId INT
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    SET NOCOUNT ON;
    BEGIN TRY

        SELECT
            WH.WorksheetHeaderId,
            WH.WorksheetNumber,
            WH.MakeTypeId,
            WH.MakeType,
            WH.AircraftModelId,
            WH.AircraftModel,
            WH.WorksheetType,
            WH.WorksheetTypeId,
            WH.WorkOrderNo,
            WH.TailNum,
            WH.SerialNum,
            WH.AFHours,
            WH.InspectionType,
            WH.InspectionDate,
            WH.QualitySafetyDeptSignOutBy,
            WH.QualitySafetyDeptSignOutDate,
            WH.QualitySafetyDeptSignInBy,
            WH.QualitySafetyDeptSignInDate,
            WH.ReleaseToServiceBy,
            WH.ReleaseDate,
            WH.ReleaseLicenseNumber,
            WH.AMONumber,
            WH.AircraftReg,
            WH.TechnicalRecordsWO,
            WH.CalmSysWO,
            WH.CertificationStatement,
            WH.IsActive,
            WH.IsDeleted,
            WH.MasterCompanyId,
            WH.CreatedBy,
            WH.UpdatedBy,
            WH.CreatedDate,
            WH.UpdatedDate,
            MT.MaintenanceType AS InspectionTypeName
        FROM [dbo].[WorksheetHeader] WH WITH (NOLOCK)
        LEFT JOIN [dbo].[MaintenanceType] MT WITH (NOLOCK) ON MT.MaintenanceTypeId = WH.InspectionType
        WHERE WH.WorksheetHeaderId = @WorksheetHeaderId AND WH.MasterCompanyId =  @MasterCompanyId
          AND WH.IsDeleted = 0;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorLogID            INT,
                @DatabaseName          VARCHAR(100)  = DB_NAME(),
                @AdhocComments         VARCHAR(150)  = 'USP_GetWorksheetHeaderById',
                @ProcedureParameters   VARCHAR(3000)  = '@WorksheetHeaderId = ' + CAST(@WorksheetHeaderId AS VARCHAR(20)),
                @ApplicationName       VARCHAR(100)  = 'PAS';

        EXEC spLogException
            @DatabaseName         = @DatabaseName,
            @AdhocComments        = @AdhocComments,
            @ProcedureParameters  = @ProcedureParameters,
            @ApplicationName      = @ApplicationName,
            @ErrorLogID           = @ErrorLogID OUTPUT;

        RAISERROR(
            'Unexpected Error Occured in the database. Please let the support team know of the error number : %d',
            16, 1, @ErrorLogID
        );
        RETURN(1);
    END CATCH
END