/*********************           
 ** File:   [USP_GetMROPriceMasterByItemMasterId]           
 ** Author: Priyansh Patel
 ** Description: This stored procedure returns all MRO Price Master records
 **              by ItemMasterId 
 ** Date:   26/09/2025

 **********************           
  ** Change History           
 **********************           
 ** PR   Date          Author  			Change Description            
 ** --   --------      -------			---------------------------     
    1    26/09/2025    Priyansh Patel   Created
	2	 10/11/2025	   Priyansh Patel	Updated column name UnitPrice to FlatRatePrice
    3    13/11/2025    Ayushi Patel     Sort By created Date
	4    14/11/2025    Moin Bloch       Added Some Field
**********************/
-- Example: EXEC USP_GetMROPriceMasterByItemMasterId 97005, 0, 1

CREATE PROCEDURE [dbo].[USP_GetMROPriceMasterByItemMasterId] 
    @ItemMasterId BIGINT = NULL, 
	@IsDeleted BIT,
	@MasterCompanyId int = 0
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
    SET NOCOUNT ON;

    BEGIN TRY

		IF @ItemMasterId=0
		BEGIN
			SET @ItemMasterId=NULL
		END

        BEGIN
            SELECT 
                  MPM.[MROPriceMasterId],
                  MPM.[ItemMasterId],
				  (ISNULL(UPPER(IM.[PartNumber]),'')) 'PartNumber',
				  (ISNULL(UPPER(IM.[PartDescription]),'')) 'PartDescription',
				  (ISNULL(UPPER(IM.[ManufacturerName]),'')) 'ManufacturerName',
                  MPM.[MasterCompanyId],
                  MPM.[CustomerId],
				  CM.[Name] [CustomerName],
				  WS.[WorkScopeCode] [WorkScopeName],
				  CR.[Code] [CurrencyName],
                  MPM.[WorkscopeId],
                  MPM.[FlatRatePrice],
				  MPM.[CurrencyId],
                  MPM.[StartDate],
				  MPM.[EndDate],
                  MPM.[CreatedBy],
                  MPM.[CreatedDate],
                  MPM.[UpdatedBy],
                  MPM.[UpdatedDate],
                  MPM.[IsActive],
                  MPM.[IsDeleted]
            FROM [dbo].[MROPriceMaster] MPM WITH(NOLOCK)
			INNER JOIN [dbo].[ItemMaster] IM WITH(NOLOCK) ON MPM.ItemMasterId = IM.ItemMasterId
			 LEFT JOIN [dbo].[Customer] CM   WITH(NOLOCK) ON CM.CustomerId = MPM.CustomerId
			 LEFT JOIN [dbo].[WorkScope] WS  WITH(NOLOCK) ON WS.WorkScopeId = MPM.WorkScopeId
			 LEFT JOIN [dbo].[Currency] CR   WITH(NOLOCK) ON CR.CurrencyId = MPM.CurrencyId
			WHERE (@ItemMasterId IS NULL OR  MPM.[ItemMasterId] = @ItemMasterId)
              AND MPM.[MasterCompanyId] = @MasterCompanyId
              AND MPM.[IsActive] = 1
              AND MPM.[IsDeleted] = @IsDeleted
            ORDER BY MPM.[ItemMasterId], MPM.[CreatedDate] DESC;
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
		-----------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
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