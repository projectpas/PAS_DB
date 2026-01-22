/*************************************************************           
** File:  [USP_CreateIntegrationMappings]  
** Author:   Ayushi Patel  
** Description: Create Integration Mappings
** Purpose:  
** Date:   07-07-2025  
**************************************************************           
** Change History           
**************************************************************           
** PR     Date         Author           Change Description            
** --    --------     -------           -------------------------------          
** 1     07-07-2025   Ayushi Patel      Created  
**************************************************************/
create   PROCEDURE [dbo].[USP_CreateIntegrationMappings]
    @IntegrationMappings TVP_BigInt READONLY,
    @ModuleId INT,
    @ReferenceId BIGINT,
    @CreatedBy NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        INSERT INTO dbo.IntegrationPortalMapping (
            IntegrationPortalId,
            ModuleId,
            ReferenceId,
            IsActive,
            IsDeleted,
            CreatedDate,
            UpdatedDate,
            CreatedBy,
            UpdatedBy
        )
        SELECT 
            Value,
            @ModuleId,
            @ReferenceId,
            1, -- IsActive = true
            0, -- IsDeleted = false
            GETUTCDATE(),
            GETUTCDATE(),
            @CreatedBy,
            @CreatedBy
        FROM @IntegrationMappings;
    END TRY
    BEGIN CATCH
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'USP_CreateIntegrationMappings' 
            , @ProcedureParameters VARCHAR(3000)  = ''
            , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
            exec spLogException 
                    @DatabaseName			= @DatabaseName
                    , @AdhocComments			= @AdhocComments
                    , @ProcedureParameters		= @ProcedureParameters
                    , @ApplicationName			=  @ApplicationName
                    , @ErrorLogID              = @ErrorLogID OUTPUT ;
            RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
            RETURN(1);
    END CATCH
END