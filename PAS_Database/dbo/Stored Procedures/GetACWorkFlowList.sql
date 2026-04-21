/*************************************************************           
 ** File:   [[GetACWorkFlowList]]           
 ** Author:   Priyansh Patel
 ** Description: Get Search Data for Work Flow List    
 ** Purpose:         
 ** Date:   20-APR-2026       
          
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		    Change Description            
 ** --   --------     -------		    --------------------------------          
    1    20/04/2026   Priyansh Patel    Created


**************************************************************/ 
 CREATE   PROCEDURE [dbo].[GetACWorkFlowList]
    @AircraftRegistryId BIGINT,
    @MasterCompanyId INT,
    @MaintenanceTypeId BIGINT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    BEGIN TRY
    DECLARE @TemplateType INT = 2
    BEGIN TRANSACTION

        SELECT  wf.WorkflowId,  wf.[WorkOrderNumber] + '_' + wf.[Version] AS WorkFlowNo, wf.TailNum,wf.SerialNum,
            wf.AircraftModelId, wf.MakeTypeId, wf.TemplateType,  wf.MaintenanceTypeId, wf.WorkOrderNumber, wf.Version,
            UPPER(wf.WorkflowDescription) AS TemplateDescription
        FROM dbo.Workflow wf WITH (NOLOCK)
        INNER JOIN dbo.AircraftRegistryHeader ar WITH (NOLOCK) 
            ON  ar.TailNum          = wf.TailNum
            AND ar.SerialNum        = wf.SerialNum
            AND ar.AircraftModelId  = wf.AircraftModelId
            AND ar.MakeTypeId       = wf.MakeTypeId
        WHERE
            ar.AircraftRegistryId   = @AircraftRegistryId
            AND wf.IsDeleted        = 0
            AND wf.IsActive         = 1
            AND wf.MasterCompanyId  = @MasterCompanyId
            AND (@TemplateType      IS NULL OR wf.TemplateType      = @TemplateType)
            AND (@MaintenanceTypeId IS NULL OR wf.MaintenanceTypeId = @MaintenanceTypeId)
        ORDER BY wf.WorkflowDescription;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            PRINT 'ROLLBACK'
            ROLLBACK TRAN;
            DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = DB_NAME()
                , @AdhocComments        VARCHAR(150)    = 'GetWorkFlowDropdownList'
                , @ProcedureParameters  VARCHAR(3000)   = '@Parameter1 = ''' + ISNULL(CAST(@AircraftRegistryId AS VARCHAR), '') + ''',
                                                           @Parameter2 = ''' + ISNULL(CAST(@MasterCompanyId    AS VARCHAR), '') + ''',
                                                           @Parameter3 = ''' + ISNULL(CAST(@TemplateType       AS VARCHAR), '') + ''',
                                                           @Parameter4 = ''' + ISNULL(CAST(@MaintenanceTypeId  AS VARCHAR), '') + ''''
                , @ApplicationName      VARCHAR(100)    = 'PAS'

            EXEC spLogException
                  @DatabaseName         = @DatabaseName
                , @AdhocComments        = @AdhocComments
                , @ProcedureParameters  = @ProcedureParameters
                , @ApplicationName      = @ApplicationName
                , @ErrorLogID           = @ErrorLogID OUTPUT;

            RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
            RETURN(1);
    END CATCH
END