/*********************           
 ** File:   [USP_AddOrUpdateMROPriceMaster]           
 ** Author: Priyansh Patel
 ** Description: This stored procedure inserts or updates MROPriceMaster records.
 ** Date:   26/09/2025

 **********************           
  ** Change History           
 **********************           
 ** PR   Date          Author  			Change Description            
 ** --   --------      -------			---------------------------     
    1    26/09/2025    Priyansh Patel   Created
**********************/

CREATE PROCEDURE [dbo].[USP_AddOrUpdateMROPriceMaster] 
    @MROPriceMasterId BIGINT = NULL,
    @ItemMasterId BIGINT,
    @MasterCompanyId INT,
    @CustomerId BIGINT = NULL,
    @WorkscopeId BIGINT,
    @CurrencyId INT,
    @UnitPrice DECIMAL(18,2),
	 @StartDate DATETIME2(7),
    @CreatedBy VARCHAR(50),
    @UpdatedBy VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    BEGIN TRY
        BEGIN TRAN;

        IF(ISNULL(@MROPriceMasterId,0) = 0)
        BEGIN
		PRINT 'BEGIN';
            INSERT INTO [dbo].[MROPriceMaster]
            (
              [ItemMasterId],
                [MasterCompanyId],
                [CustomerId],
                [WorkscopeId],
                [UnitPrice],
				[CurrencyId],
				[StartDate],
                [CreatedBy],
                [CreatedDate],
                [UpdatedBy],
                [UpdatedDate],
                [IsActive],
                [IsDeleted]
            )
            VALUES
            (
                @ItemMasterId,
                @MasterCompanyId,
                @CustomerId,
                @WorkscopeId,
                @UnitPrice,
				@CurrencyId,
				 @StartDate,
                @CreatedBy,
                GETUTCDATE(),
                @UpdatedBy,
                GETUTCDATE(),
                1, 0
            );

            SET @MROPriceMasterId = SCOPE_IDENTITY();
		PRINT 'End';

        END
        ELSE
        BEGIN
          
            UPDATE [dbo].[MROPriceMaster]
            SET 
                [CustomerId] = @CustomerId,
                [WorkscopeId] = @WorkscopeId,
				[StartDate] = @StartDate,
				[CurrencyId] = @CurrencyId,
                [UnitPrice] = @UnitPrice,
                [UpdatedBy] = @UpdatedBy,
                [UpdatedDate] = GETUTCDATE()
            WHERE [MROPriceMasterId] = @MROPriceMasterId;
        END

        COMMIT TRAN;

        SELECT @MROPriceMasterId AS [MROPriceMasterId];
    END TRY


    BEGIN CATCH
        IF @@TRANCOUNT > 0
        BEGIN
            PRINT 'ROLLBACK';
            ROLLBACK TRAN;
        END

        DECLARE @ErrorLogID INT,
                @DatabaseName VARCHAR(100) = DB_NAME(),
 -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
                @AdhocComments VARCHAR(150) = '[USP_AddOrUpdateMROPriceMaster]',
                @ProcedureParameters VARCHAR(3000) = 
                    '@MROPriceMasterId=''' + CAST(ISNULL(@MROPriceMasterId, 0) AS VARCHAR(100)) + ''',
                     @ItemMasterId=''' + CAST(ISNULL(@ItemMasterId, 0) AS VARCHAR(100)) + ''',
                     @MasterCompanyId=''' + CAST(ISNULL(@MasterCompanyId, 0) AS VARCHAR(100)) + ''',
                     @CustomerId=''' + CAST(ISNULL(@CustomerId, 0) AS VARCHAR(100)) + ''',
                     @WorkscopeId=''' + CAST(ISNULL(@WorkscopeId, 0) AS VARCHAR(100)) + ''',
                     @UnitPrice=''' + CAST(ISNULL(@UnitPrice, 0) AS VARCHAR(100)) + '''',
                  
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