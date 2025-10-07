/*********************           
 ** File:   [USP_GetMROPriceMasterByItemMasterId]           
 ** Author: Priyansh Patel
 ** Description: This stored procedure returns all Price Master records
 **              by ItemMasterId 
 ** Date:   26/09/2025

 **********************           
  ** Change History           
 **********************           
 ** PR   Date          Author  			Change Description            
 ** --   --------      -------			---------------------------     
    1    26/09/2025    Priyansh Patel   Created
**********************/
-- Example: EXEC USP_GetMROPriceMasterByItemMasterId 1001, 0, 1

CREATE PROCEDURE [dbo].[USP_GetMROPriceMasterByItemMasterId] 
    @ItemMasterId BIGINT,
	@IsDeleted BIT,
	@MasterCompanyId int = 0
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN
            SELECT 
                  MPM.[MROPriceMasterId],
                  MPM.[ItemMasterId],
                  MPM.[MasterCompanyId],
                  MPM.[CustomerId],
                  MPM.[WorkscopeId],
                  MPM.[UnitPrice],
				   MPM.[CurrencyId],
                  MPM.[StartDate],
                  MPM.[CreatedBy],
                  MPM.[CreatedDate],
                  MPM.[UpdatedBy],
                  MPM.[UpdatedDate],
                  MPM.[IsActive],
                  MPM.[IsDeleted]
            FROM [dbo].[MROPriceMaster] MPM WITH(NOLOCK)
            WHERE MPM.[ItemMasterId] = @ItemMasterId
              AND MPM.[MasterCompanyId] = @MasterCompanyId
              AND MPM.[IsActive] = 1
              AND MPM.[IsDeleted] = @IsDeleted
            ORDER BY MPM.[StartDate] DESC;
        END
    END TRY



 BEGIN CATCH
        IF @@TRANCOUNT > 0
        BEGIN
            PRINT 'ROLLBACK';
            ROLLBACK TRAN;
        END

        DECLARE @ErrorLogID INT,
                @DatabaseName VARCHAR(100) = DB_NAME(),
                @AdhocComments VARCHAR(150) = '[USP_GetMROPriceMasterByItemMasterId]',
                @ProcedureParameters VARCHAR(3000) = 
                    '@ItemMasterId=''' + CAST(ISNULL(@ItemMasterId, 0) AS VARCHAR(100)) + ''',
                     @MasterCompanyId=''' + CAST(ISNULL(@MasterCompanyId, 0) AS VARCHAR(100)) + ''',
                     @IsDeleted=''' + CAST(ISNULL(@IsDeleted, 0) AS VARCHAR(100)) + '''',
                @ApplicationName VARCHAR(100) = 'PAS';
        -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
        EXEC spLogException 
            @DatabaseName = @DatabaseName,
            @AdhocComments = @AdhocComments,
            @ProcedureParameters = @ProcedureParameters,
            @ApplicationName = @ApplicationName,
            @ErrorLogID = @ErrorLogID OUTPUT;

        RAISERROR ('Unexpected Error Occurred in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID);
        RETURN (1);
    END CATCH
END