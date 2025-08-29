/*************************************************************           
 ** File:   [USP_CreateEmployeeTraining]           
 ** Author:   Sahdev Saliya
 ** Description: This stored procedure is used to Create EmployeeTraining List
 ** Purpose:         
 ** Date:   28-08-2025       
          
 ** RETURN VALUE:           
  
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** S NO   Date            Author          Change Description              
 ** --   --------         -------          --------------------------------            
    1    28-08-2025    Sahdev Saliya       Created  

	exec [USP_CreateEmployeeTraining] 
**************************************************************/ 
CREATE   PROCEDURE [dbo].[USP_CreateEmployeeTraining]
    @EmployeeId BIGINT,
    @AircraftManufacturerId INT = NULL,
	@AircraftModelId BIGINT = NULL,
	@Provider VARCHAR(256) = NULL,
    @IndustryCode VARCHAR(256) = NULL,
    @EmployeeTrainingTypeId BIGINT = NULL,
    @FrequencyOfTrainingId BIGINT= NULL,
    @Cost DECIMAL(18, 2) = NULL,
	@Duration INT = NULL,
	@DurationTypeId INT = NULL,
    @ScheduleDate DATETIME = NULL,
    @CompletionDate DATETIME = NULL,
    @ExpirationDate DATETIME = NULL,
    @InternalReference VARCHAR(256) = NULL,
	@Memo NVARCHAR(MAX) = NULL,
    @MasterCompanyId INT,
    @CreatedBy VARCHAR(256),
    @UpdatedBy VARCHAR(256),
    @IsActive BIT = NULL,
    @IsDeleted BIT = NULL,
	@AircraftModelIds VARCHAR(256) = NULL
AS
BEGIN
    SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    BEGIN TRY
        BEGIN TRANSACTION;
        INSERT INTO EmployeeTraining
        (   EmployeeId, 
			AircraftManufacturerId, 
			AircraftModelId, 
			Provider, 
			IndustryCode, 
			EmployeeTrainingTypeId ,
			FrequencyOfTrainingId, 
			Cost, 
			Duration,  
			DurationTypeId ,
			ScheduleDate, 
			CompletionDate, 
			ExpirationDate,
			InternalReference,
			Memo, 
			MasterCompanyId, 
			CreatedBy,
			UpdatedBy,
			CreatedDate,
            UpdatedDate,
			IsActive, 
			IsDeleted )
        VALUES
        (   @EmployeeId ,
			@AircraftManufacturerId, 
			@AircraftModelId, 
			@Provider, 
			@IndustryCode, 
			@EmployeeTrainingTypeId ,
			@FrequencyOfTrainingId, 
			@Cost, 
			@Duration,  
			@DurationTypeId ,
			@ScheduleDate, 
			@CompletionDate, 
			@ExpirationDate,
			@InternalReference,
			@Memo, 
			@MasterCompanyId, 
			@CreatedBy,
			@UpdatedBy,
			GETUTCDATE(),
            GETUTCDATE(),
			@IsActive, 
			@IsDeleted );
		
		IF ( ISNULL(@AircraftModelIds, 0) > 0)
        BEGIN
            ;WITH CTE_AircraftModels AS
            (
                SELECT value AS AircraftModelId
                FROM STRING_SPLIT(@AircraftModelIds, ',')
                WHERE TRY_CAST(value AS BIGINT) IS NOT NULL
            )
            INSERT INTO EmployeeAircraftModelMapping
            (   EmployeeId,
                AircraftManufacturerId,
                AircraftModelId,
                MasterCompanyId,
                CreatedBy,
                UpdatedBy,
                CreatedDate,
                UpdatedDate,
                IsActive,
                IsDeleted )

            SELECT
                @EmployeeId,
                @AircraftManufacturerId,
                CAST(AC.AircraftModelId AS BIGINT),
                @MasterCompanyId,
                @CreatedBy,
                @UpdatedBy,
                GETUTCDATE(),
                GETUTCDATE(),
                @IsActive,
                @IsDeleted
            FROM CTE_AircraftModels AC;
        END;

        COMMIT TRANSACTION;
    END TRY
  BEGIN CATCH      
				IF @@trancount > 0
					PRINT 'ROLLBACK'
					DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

	-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
				  , @AdhocComments     VARCHAR(150)    = 'USP_CreateEmployeeTraining' 
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