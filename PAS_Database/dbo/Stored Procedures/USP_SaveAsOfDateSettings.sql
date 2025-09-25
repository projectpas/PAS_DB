/*************************************************************             
 ** File:  [USP_SaveAsOfDateSettings]
 ** Author:  Moin Bloch  
 ** Description: This stored procedure is used to store As Of Date Settings
 ** Purpose:           
 ** Date:   22/09/2025            
 ** PARAMETERS:            
 ** RETURN VALUE:             
 **************************************************************             
 ** Change History             
 **************************************************************             
 ** PR   Date         Author		Change Description              
 ** --   --------     -------		--------------------------------            
    1    22/09/2025   MOIN BLOCH		Created  
    2    25/09/2025   Devendra Shekh	Added GroupById for Insert/Update  

--  EXEC [dbo].[USP_SaveAsOfDateSettings] 
************************************************************************/  
CREATE     PROCEDURE [dbo].[USP_SaveAsOfDateSettings]
@Id BIGINT = NULL, 
@IsWeeklyOrMonthly INT = NULL,
@ExecutionDate DATETIME2(7) = NULL,
@WeeklyName VARCHAR(10) = NULL,
@ExcludedLocations NVARCHAR(500) = NULL,
@SiteIds NVARCHAR(500) = NULL,
@WarehouseIds NVARCHAR(500) = NULL,
@LocationIds NVARCHAR(500) = NULL,
@ShelfIds NVARCHAR(500) = NULL,
@BinIds NVARCHAR(500) = NULL,
@Level1Ids NVARCHAR(500) = NULL,
@Level2Ids NVARCHAR(500) = NULL,
@Level3Ids NVARCHAR(500) = NULL,
@Level4Ids NVARCHAR(500) = NULL,
@Level5Ids NVARCHAR(500) = NULL,
@Level6Ids NVARCHAR(500) = NULL,
@Level7Ids NVARCHAR(500) = NULL,
@Level8Ids NVARCHAR(500) = NULL,
@Level9Ids NVARCHAR(500) = NULL,
@Level10Ids NVARCHAR(500) = NULL,    
@ManagementStructureId  BIGINT = NULL, 
@MasterCompanyId INT = NULL,
@CreatedBy VARCHAR(256) = NULL,
@UpdatedBy VARCHAR(256) = NULL,
@GroupById INT = NULL
AS
BEGIN  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;   
 BEGIN TRY  
 BEGIN TRANSACTION  
 BEGIN  

	SET @SiteIds  = CASE WHEN @SiteIds = '0' THEN NULL ELSE @SiteIds END;  
    SET @WarehouseIds = CASE WHEN @WarehouseIds = '0' THEN NULL ELSE @WarehouseIds END;
    SET @LocationIds = CASE WHEN @LocationIds = '0' THEN NULL ELSE @LocationIds END;
    SET @ShelfIds = CASE WHEN @ShelfIds = '0' THEN NULL ELSE @ShelfIds END;
    SET @BinIds = CASE WHEN @BinIds = '0' THEN NULL ELSE @BinIds END;

	SET @Level1Ids = CASE WHEN @Level1Ids = '0'  THEN NULL ELSE @Level1Ids END;
	SET @Level2Ids = CASE WHEN @Level2Ids = '0'  THEN NULL ELSE @Level2Ids END;
	SET @Level3Ids = CASE WHEN @Level3Ids = '0'  THEN NULL ELSE @Level3Ids END;
	SET @Level4Ids = CASE WHEN @Level4Ids = '0'  THEN NULL ELSE @Level4Ids END;
	SET @Level5Ids = CASE WHEN @Level5Ids = '0'  THEN NULL ELSE @Level5Ids END;
	SET @Level6Ids = CASE WHEN @Level6Ids = '0'  THEN NULL ELSE @Level6Ids END;
	SET @Level7Ids = CASE WHEN @Level7Ids = '0'  THEN NULL ELSE @Level7Ids END;
	SET @Level8Ids = CASE WHEN @Level8Ids = '0'  THEN NULL ELSE @Level8Ids END;
	SET @Level9Ids = CASE WHEN @Level9Ids = '0'  THEN NULL ELSE @Level9Ids END;
	SET @Level10Ids =CASE WHEN @Level10Ids = '0' THEN NULL ELSE @Level10Ids END;

    IF NOT EXISTS(SELECT 1 FROM [dbo].[AsOfDateSettings] WITH(NOLOCK) WHERE [MasterCompanyId] = @MasterCompanyId)
    BEGIN
        INSERT INTO [dbo].[AsOfDateSettings]
        (
            [SiteIds],
            [WarehouseIds],
            [LocationIds],
            [ShelfIds],
            [BinIds],
            [Level1Ids],
            [Level2Ids],
            [Level3Ids],
            [Level4Ids],
            [Level5Ids],
            [Level6Ids],
            [Level7Ids],
            [Level8Ids],
            [Level9Ids],
            [Level10Ids],
            [IsWeeklyOrMonthly],
            [ExecutionDate],
            [WeeklyName],
            [ExcludedLocations],
			[ManagementStructureId],
            [MasterCompanyId],
            [CreatedBy],
            [UpdatedBy],
            [CreatedDate],
            [UpdatedDate],
            [IsActive],
            [IsDeleted],
			[GroupById]
        )
        VALUES
        (
            @SiteIds,
            @WarehouseIds,
            @LocationIds,
            @ShelfIds,
            @BinIds,
            @Level1Ids,
            @Level2Ids,
            @Level3Ids,
            @Level4Ids,
            @Level5Ids,
            @Level6Ids,
            @Level7Ids,
            @Level8Ids,
            @Level9Ids,
            @Level10Ids,
            @IsWeeklyOrMonthly,
            @ExecutionDate,
            @WeeklyName,
            @ExcludedLocations,
			@ManagementStructureId,
            @MasterCompanyId,
            @CreatedBy,
            @UpdatedBy,
            GETUTCDATE(),
            GETUTCDATE(),
            1, 
            0,
			@GroupById
        );
    END
    ELSE
    BEGIN
        UPDATE [dbo].[AsOfDateSettings]
        SET 
            [SiteIds] = @SiteIds,
            [WarehouseIds] = @WarehouseIds,
            [LocationIds] = @LocationIds,
            [ShelfIds] = @ShelfIds,
            [BinIds] = @BinIds,
            [Level1Ids] = @Level1Ids,
            [Level2Ids] = @Level2Ids,
            [Level3Ids] = @Level3Ids,
            [Level4Ids] = @Level4Ids,
            [Level5Ids] = @Level5Ids,
            [Level6Ids] = @Level6Ids,
            [Level7Ids] = @Level7Ids,
            [Level8Ids] = @Level8Ids,
            [Level9Ids] = @Level9Ids,
            [Level10Ids] = @Level10Ids,
            [IsWeeklyOrMonthly] = @IsWeeklyOrMonthly,
            [ExecutionDate] = @ExecutionDate,
            [WeeklyName] = @WeeklyName,
            [ExcludedLocations] = @ExcludedLocations,            
            [UpdatedBy] = @UpdatedBy,
            [UpdatedDate] = GETUTCDATE(),
            [GroupById] = @GroupById
      WHERE [MasterCompanyId] = @MasterCompanyId;
    END
 END   
 COMMIT  TRANSACTION  
 END TRY   
 BEGIN CATCH        
  IF @@trancount > 0  
  PRINT 'ROLLBACK'  
    ROLLBACK TRANSACTION;  
	SELECT
    ERROR_NUMBER() AS ErrorNumber,
    ERROR_STATE() AS ErrorState,
    ERROR_SEVERITY() AS ErrorSeverity,
    ERROR_PROCEDURE() AS ErrorProcedure,
    ERROR_LINE() AS ErrorLine,
    ERROR_MESSAGE() AS ErrorMessage;
    DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
              , @AdhocComments     VARCHAR(150)    = 'USP_SaveAsOfDateSettings'   
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ CAST(ISNULL(@Id, '') AS VARCHAR(100))  
             + '@Parameter2 = ''' + CAST(ISNULL(@SiteIds, '') AS VARCHAR(100))   
             + '@Parameter3 = ''' + CAST(ISNULL(@WarehouseIds, '') AS VARCHAR(100))   
             + '@Parameter4 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS VARCHAR(100))              
              , @ApplicationName VARCHAR(100) = 'PAS'  
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------------------------------------  
              exec spLogException   
                       @DatabaseName           = @DatabaseName  
                     , @AdhocComments          = @AdhocComments  
                     , @ProcedureParameters    = @ProcedureParameters  
                     , @ApplicationName        =  @ApplicationName  
                     , @ErrorLogID                    = @ErrorLogID OUTPUT ;  
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)  
              RETURN(1);  
 END CATCH  
END