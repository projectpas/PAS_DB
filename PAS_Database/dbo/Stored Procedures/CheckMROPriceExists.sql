
/*************************************************************               
 ** File:   [CheckMROPriceExists]               
 ** Author:  Priyansh Patel
 ** Description:  This Store Procedure use to check MRO Price exist for the item master  
 ** Purpose:             
 ** Date:   30/09/2025         
              
 ** RETURN VALUE:               
 **********************************************************               
 ** Check MRO Price exist             
 **********************************************************               
 ** Example Usage:
 ** EXEC [dbo].[CheckMROPriceExists] 
 **     @ItemMasterId = 1001,
 **     @CustomerId = NULL,
 **     @MasterCompanyId = 1,
 **     @WorkscopeId = 5,
 **     @IsDeleted = 0,
 **     @MROPriceMasterId = NULL;
 ******************************************************************************************/
CREATE PROCEDURE [dbo].[CheckMROPriceExists]
    @ItemMasterId BIGINT,
    @CustomerId BIGINT = NULL,
    @MasterCompanyId INT,
    @WorkscopeId BIGINT,
    @IsDeleted BIT,
    @MROPriceMasterId BIGINT = NULL
AS
BEGIN
    BEGIN TRY
        SET NOCOUNT ON;

        DECLARE @ReturnStatus INT = 1;
        DECLARE @ReturnMsg VARCHAR(150) = 'No Conflict';

        IF EXISTS (
            SELECT 1
            FROM [dbo].[MROPriceMaster] WITH (NOLOCK)
            WHERE 
                [ItemMasterId] = @ItemMasterId AND
                [MasterCompanyId] = @MasterCompanyId AND
                [WorkscopeId] = @WorkscopeId AND
                [IsDeleted] = @IsDeleted AND
                (([CustomerId] IS NULL AND @CustomerId IS NULL) OR [CustomerId] = @CustomerId) AND
                (@MROPriceMasterId IS NULL OR [MROPriceMasterId] <> @MROPriceMasterId)
        )
        BEGIN
            SET @ReturnStatus = -1;
            SET @ReturnMsg = 'Conflict: A record with the same unique fields already exists.';
        END

        SELECT @ReturnStatus AS Status, @ReturnMsg AS Msg;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRAN;

        DECLARE @ErrorLogID INT,
                @DatabaseName VARCHAR(100) = DB_NAME(),
                @AdhocComments VARCHAR(150) = 'CheckMROPriceExists',
                @ProcedureParameters VARCHAR(3000),
                @ApplicationName VARCHAR(100) = 'PAS';

        SET @ProcedureParameters = 
            '@ItemMasterId = ' + ISNULL(CAST(@ItemMasterId AS VARCHAR), 'NULL') + ', ' +
            '@CustomerId = ' + ISNULL(CAST(@CustomerId AS VARCHAR), 'NULL') + ', ' +
            '@MasterCompanyId = ' + ISNULL(CAST(@MasterCompanyId AS VARCHAR), 'NULL') + ', ' +
            '@WorkscopeId = ' + ISNULL(CAST(@WorkscopeId AS VARCHAR), 'NULL') + ', ' +
            '@IsDeleted = ' + ISNULL(CAST(@IsDeleted AS VARCHAR), 'NULL') + ', ' +
            '@MROPriceMasterId = ' + ISNULL(CAST(@MROPriceMasterId AS VARCHAR), 'NULL');

        EXEC spLogException 
            @DatabaseName = @DatabaseName,
            @AdhocComments = @AdhocComments,
            @ProcedureParameters = @ProcedureParameters,
            @ApplicationName = @ApplicationName,
            @ErrorLogID = @ErrorLogID OUTPUT;

        RAISERROR (
            'Unexpected Error Occurred in the database. Please let the support team know of the error number : %d', 
            16, 1, @ErrorLogID
        );

        RETURN(1);
    END CATCH
END