/*************************************************************
 ** File:   [USP_GetCustomerAircraftMappingByFilters]
 ** Author: EKTA CHANDEGRA
 ** Description: This stored procedure is used to search Customer AircraftMappingData By MultiTypeId , ModelID and DashID
 ** Purpose:
 ** Date:   05/20/2025
    
 ** PARAMETERS: @CustomerId BIGINT, @AircraftTypeId NVARCHAR(MAX), @AircraftModelId NVARCHAR(MAX), @DashNumberId NVARCHAR(MAX)

 ** RETURN VALUE:

 **************************************************************
  ** Change History               
 **************************************************************
 ** PR   Date         Author			Change Description
 ** --   --------     -------			--------------------------------   
	1    05/20/2025   EKTA CHANDEGRA	Created
	

exec dbo.USP_GetCustomerAircraftMappingByFilters @CustomerId=4301,@AircraftTypeId=N'',@AircraftModelId=NULL,@DashNumberId=NULL
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetCustomerAircraftMappingByFilters]
    @CustomerId BIGINT,
    @AircraftTypeId NVARCHAR(MAX),
    @AircraftModelId NVARCHAR(MAX),
    @DashNumberId NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
	BEGIN TRY
		-- Temp tables to hold split values
		DECLARE @AircraftTypeTable TABLE (Id BIGINT);
		DECLARE @AircraftModelTable TABLE (Id BIGINT);
		DECLARE @DashNumberTable TABLE (Id BIGINT);

		-- Split comma-separated inputs
		IF (@AircraftTypeId IS NOT NULL AND @AircraftTypeId <> 'null')
		BEGIN
			INSERT INTO @AircraftTypeTable (Id)
			SELECT TRY_CAST(value AS BIGINT)
			FROM STRING_SPLIT(@AircraftTypeId, ',')
			WHERE ISNUMERIC(value) = 1;
		END

		IF (@AircraftModelId IS NOT NULL AND @AircraftModelId <> 'null')
		BEGIN
			INSERT INTO @AircraftModelTable (Id)
			SELECT TRY_CAST(value AS BIGINT)
			FROM STRING_SPLIT(@AircraftModelId, ',')
			WHERE ISNUMERIC(value) = 1;
		END

		IF (@DashNumberId IS NOT NULL AND @DashNumberId <> 'null')
		BEGIN
			INSERT INTO @DashNumberTable (Id)
			SELECT TRY_CAST(value AS BIGINT)
			FROM STRING_SPLIT(@DashNumberId, ',')
			WHERE ISNUMERIC(value) = 1;
		END

		-- Main query with dynamic filters
		SELECT DISTINCT
			cam.CustomerAircraftMappingId,
			cam.CustomerId,
			cam.AircraftTypeId,
			ISNULL(cam.AircraftModelId,0) AS AircraftModelId,
			ISNULL(cam.DashNumberId,0) AS DashNumberId,
			ISNULL(cam.DashNumber,'') AS DashNumber,
			cam.AircraftType,
			cam.AircraftModel,
			cam.Inventory,
			cam.MasterCompanyId,
			cam.CreatedDate,
			cam.CreatedBy,
			cam.UpdatedDate,
			cam.UpdatedBy
		FROM [dbo].[CustomerAircraftMapping] cam WITH(NOLOCK)
		WHERE ISNULL(cam.IsDeleted,0) = 0
		  AND cam.CustomerId = @CustomerId
		  AND (
				NOT EXISTS (SELECT 1 FROM @AircraftTypeTable) OR
				cam.AircraftTypeId IN (SELECT Id FROM @AircraftTypeTable)
			  )
		  AND (
				NOT EXISTS (SELECT 1 FROM @AircraftModelTable) OR
				cam.AircraftModelId IN (SELECT Id FROM @AircraftModelTable)
			  )
		  AND (
				NOT EXISTS (SELECT 1 FROM @DashNumberTable) OR
				cam.DashNumberId IN (SELECT Id FROM @DashNumberTable)
			  );
	END TRY
	BEGIN CATCH
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
        , @AdhocComments     VARCHAR(150)    = 'USP_GetCustomerAircraftMappingByFilters'
        , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = ' + ISNULL(CAST(@CustomerId AS varchar(10)) ,'') +''',
												 @Parameter2 = ' + ISNULL(CAST(@AircraftTypeId AS varchar(10)) ,'') +'''
												 @Parameter3 = ' + ISNULL(CAST(@AircraftModelId AS varchar(10)) ,'') +'''
												 @Parameter4 = ' + ISNULL(CAST(@DashNumberId AS varchar(10)) ,'') +''

        , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
        exec spLogException
                @DatabaseName           =  @DatabaseName
                , @AdhocComments          =  @AdhocComments
                , @ProcedureParameters    =  @ProcedureParameters
                , @ApplicationName        =  @ApplicationName
                , @ErrorLogID             =  @ErrorLogID OUTPUT;
        RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
        RETURN(1);
	END CATCH
END