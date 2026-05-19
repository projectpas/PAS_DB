/*************************************************************           
 ** File:   [USP_UpdateEmployeeTraining]           
 ** Author:   Sahdev Saliya
 ** Description: This stored procedure is used to Update EmployeeTraining List
 ** Purpose:         
 ** Date:   24-09-2025       
          
 ** RETURN VALUE:           
  
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** S NO   Date            Author          Change Description              
 ** --   --------         -------          --------------------------------            
    1    24-09-2025    Sahdev Saliya       Created  
	2    14-APR-2026   Sahdev Saliya       Added TrainingName, ProviderId, ProviderType, IsRecurring, DurationHours, DurationMinutes (PN-15932)
	3    04-May-2026   Sahdev Saliya       Added CategoryId, CategoryType, CurrencyId (PN-16203)

	exec [USP_UpdateEmployeeTraining] 
**************************************************************/ 
CREATE   PROCEDURE [dbo].[USP_UpdateEmployeeTraining]
    @Id BIGINT = NULL,
    @MasterCompanyId BIGINT,
    @AircraftModelId BIGINT = NULL,
    @EmployeeTrainingTypeId BIGINT = NULL,
    @ScheduleDate DATETIME = NULL,
    @CompletionDate DATETIME = NULL,
    @Provider VARCHAR(256) = NULL,
    @Cost DECIMAL(18,2) = NULL,
    @Duration INT = NULL,
    @IndustryCode VARCHAR(256) = NULL,
    @ExpirationDate DATETIME = NULL,
    @UpdatedBy VARCHAR(256),
    @AircraftManufacturerId BIGINT = NULL,
    @DurationTypeId BIGINT = NULL,
    @FrequencyOfTrainingId BIGINT = NULL,
    @Memo NVARCHAR(MAX) = NULL,
    @InternalReference VARCHAR(256) = NULL,
	@EmployeeId BIGINT,
    @CreatedBy VARCHAR(256),
    @IsActive BIT = NULL,
    @IsDeleted BIT = NULL,
    @AircraftModelIds VARCHAR(256) = NULL, 
	@TrainingNameId BIGINT = NULL,
	@ProviderId BIGINT = NULL,
    @ProviderType VARCHAR(50) = NULL,
	@IsRecurring BIT = NULL,
	@DurationHours VARCHAR(200) = NULL,
	@DurationMinutes VARCHAR(200) = NULL,
	@CategoryId BIGINT= NULL,
	@CategoryType VARCHAR(50) = NULL,
	@CurrencyId BIGINT = NULL

AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF EXISTS (SELECT 1 FROM [DBO].EmployeeTraining WITH(NOLOCK) WHERE EmployeeTrainingId = @id)
        BEGIN

            UPDATE EmployeeTraining
            SET MasterCompanyId       = @MasterCompanyId,
                AircraftModelId       = @AircraftModelId,
                EmployeeTrainingTypeId= @EmployeeTrainingTypeId,
                ScheduleDate          = @ScheduleDate,
                CompletionDate        = @CompletionDate,
                Provider              = @Provider,
                Cost                  = @Cost,
                IndustryCode          = @IndustryCode,
                ExpirationDate        = @ExpirationDate,
                UpdatedDate           = GETUTCDATE(),
                UpdatedBy             = @UpdatedBy,
                AircraftManufacturerId= @AircraftManufacturerId,
                DurationTypeId        = @DurationTypeId,
                FrequencyOfTrainingId = @FrequencyOfTrainingId,
                Memo                  = @Memo,
                InternalReference     = @InternalReference,
				TrainingNameId        = @TrainingNameId,
				ProviderId            = @ProviderId,
                ProviderType          = @ProviderType,
				IsRecurring           = @IsRecurring,
				DurationHours         = @DurationHours,
                DurationMinutes       = @DurationMinutes,
				CategoryId            = @CategoryId,
                CategoryType          = @CategoryType,
				CurrencyId            = @CurrencyId
            WHERE EmployeeTrainingId = @id;

            IF (LEN(@AircraftModelIds) > 0)
            BEGIN
                DELETE FROM [DBO].EmployeeAircraftModelMapping
                WHERE EmployeeId = (SELECT EmployeeId FROM [DBO].EmployeeTraining WITH(NOLOCK) WHERE EmployeeTrainingId = @id);

                ;WITH CTE_AircraftModels AS
                (
                    SELECT TRIM([value]) AS AircraftModelId
                    FROM STRING_SPLIT(@AircraftModelIds, ',')
				    WHERE TRY_CAST(value AS BIGINT) IS NOT NULL

                )
                INSERT INTO EmployeeAircraftModelMapping
                (
                    EmployeeId, 
					AircraftManufacturerId,
					AircraftModelId,
                    MasterCompanyId,
					CreatedBy,
					UpdatedBy,
                    CreatedDate,
					UpdatedDate, 
					IsActive,
					IsDeleted
                )
                SELECT
                    @EmployeeId,
                    @AircraftManufacturerId,
                    CAST(AM.AircraftModelId AS BIGINT),
                    @MasterCompanyId,
                    @CreatedBy,
                    @UpdatedBy,
                    GETUTCDATE(),
                    GETUTCDATE(),
                    @IsActive,
                    @IsDeleted
                FROM CTE_AircraftModels AM WITH(NOLOCK)
            END

			SELECT [EmployeeTrainingId]
			,[MasterCompanyId]
			,[AircraftModelId]
			,[EmployeeTrainingTypeId]
			,[ScheduleDate]
			,[CompletionDate]
			,[Provider]
			,[Cost]
			,[Duration]
			,[IndustryCode]
			,[ExpirationDate]
			,[UpdatedDate]
			,[UpdatedBy]
			,[AircraftManufacturerId]
			,[DurationTypeId]
			,[FrequencyOfTrainingId]
			,[Memo]
			,[InternalReference]
			,[TrainingNameId]
			,[ProviderId]
			,[ProviderType]
			,[IsRecurring]
			,[DurationHours]
			,[DurationMinutes]
			,[CategoryId]
			,[CategoryType]
			,[CurrencyId]
		    FROM [DBO].[EmployeeTraining] WITH(NOLOCK) 
		    WHERE [EmployeeTrainingId] = @id;

        END
        ELSE
        BEGIN
           SELECT 0 AS EmployeeTrainingId
        END;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH      
				IF @@trancount > 0
					PRINT 'ROLLBACK'
					DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

	-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
				  , @AdhocComments     VARCHAR(150)    = 'USP_UpdateEmployeeTraining' 
				  , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = ''' + CAST(ISNULL(@EmployeeId, '') AS VARCHAR(100))

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