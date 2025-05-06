/*************************************************************           
** File:   [USP_GetWorkOrderQuoteSettingsList]        
** Author:  Ayushi Patel
** Description: This stored procedure is used to get a list of Work Order Quote Settings by MasterCompanyId
** Purpose:         
** Date:   24/04/2025     
        
** PARAMETERS: 
    @MasterCompanyId INT

** RETURN VALUE:           
**************************************************************           
** Change History           
**************************************************************           
** PR   Date         Author		    Change Description            
** --   --------     -------		--------------------------------          
   1    24/04/2025  Ayushi Patel    Created

 -- EXEC [USP_GetWorkOrderQuoteSettingsList] 1
************************************************************************/

CREATE   PROCEDURE [dbo].[USP_GetWorkOrderQuoteSettingsList]
    @MasterCompanyId INT
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
    
    BEGIN TRY
        SELECT 
            wos.WorkOrderQuoteSettingId,
            wos.WorkOrderTypeId,
            wos.Prefix,
            wos.Sufix,
            wos.StartCode,
            wot.Description AS WorkOrderType,
            wos.ValidDays,
            wos.MasterCompanyId,
            ISNULL(wos.IsActive,0) AS IsActive,
            wos.CreatedBy,
            wos.CreatedDate,
            wos.UpdatedBy,
            wos.UpdatedDate,
            wos.effectivedate,
            ISNULL(wos.IsApprovalRule, 0) AS IsApprovalRule,
            wos.TearDownTypes,
            ISNULL(wos.IsFlatRate, 0) AS IsFlatRate
        FROM dbo.WorkOrderQuoteSettings wos WITH (NOLOCK)
        INNER JOIN dbo.WorkOrderType wot WITH (NOLOCK) ON wos.WorkOrderTypeId = wot.Id
        WHERE ISNULL(wos.IsDeleted,0) != 1 AND wos.MasterCompanyId = @MasterCompanyId;
    END TRY
    BEGIN CATCH
        DECLARE 
            @ErrorLogID INT,
            @DatabaseName VARCHAR(100) = DB_NAME(),
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            @AdhocComments VARCHAR(150) = 'USP_GetWorkOrderQuoteSettingsList',
            @ProcedureParameters VARCHAR(3000) = '@MasterCompanyId=' + CAST(@MasterCompanyId AS VARCHAR),
            @ApplicationName VARCHAR(100) = 'PAS';
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
        EXEC spLogException 
            @DatabaseName = @DatabaseName,
            @AdhocComments = @AdhocComments,
            @ProcedureParameters = @ProcedureParameters,
            @ApplicationName = @ApplicationName,
            @ErrorLogID = @ErrorLogID OUTPUT;

        RAISERROR('Unexpected Error Occurred. Contact support with Error ID: %d', 16, 1, @ErrorLogID);
        RETURN (1);
    END CATCH
END;