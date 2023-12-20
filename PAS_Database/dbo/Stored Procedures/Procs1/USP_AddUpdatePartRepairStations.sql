/*************************************************************           
 ** File:   [AddUpdatePartRepairStations]           
 ** Author:  Amit Ghediya
 ** Description: This stored procedure is used AddUpdatePartRepairStations
 ** Purpose:         
 ** Date:   07/02/2023      
          
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    07/02/2023  Amit Ghediya    Created
     
-- EXEC AddUpdatePartRepairStations
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_AddUpdatePartRepairStations]
@Tbl_PartRepairStationsDetailsType PartRepairStationsDetailsType READONLY,
@PartRepairStationsId BIGINT,
@PartNumber VARCHAR(250),
@Manufacturer VARCHAR(150),
@AirCraftType VARCHAR(150),
@ATAChapterId VARCHAR(150),
@ItemMasterId BIGINT,
@MasterCompanyId BIGINT,
@CreatedBy VARCHAR(200) ,
@UpdatedBy VARCHAR(200) ,
@CreatedDate DATETIME,
@UpdatedDate DATETIME,
@IsActive BIT,
@IsDeleted BIT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY

		DECLARE @mcount INT,
				@TotalCounts INT,
				@ReturnPartRepairStationsId BIGINT;
		SET @mcount = 1;

		IF(@PartRepairStationsId = 0)
		BEGIN
			
			INSERT INTO [dbo].[PartRepairStations]
					   ([PartNumber],[Manufacturer],[AirCraftType],[ATAChapterId],[ItemMasterId],[MasterCompanyId],		
					    [CreatedBy],[UpdatedBy] ,[CreatedDate] ,[UpdatedDate] ,[IsActive] ,[IsDeleted])
				 VALUES(@PartNumber,@Manufacturer,@AirCraftType,@ATAChapterId,@ItemMasterId,@MasterCompanyId,
						@CreatedBy,@UpdatedBy,GETDATE(),GETDATE(),1,0);

				SELECT @ReturnPartRepairStationsId = SCOPE_IDENTITY()

					IF OBJECT_ID(N'tempdb..#tmpPartRepairStationsDetails') IS NOT NULL
					BEGIN
						DROP TABLE #tmpUnReserveWOMaterialsStockline
					END
			
					CREATE TABLE #tmpPartRepairStationsDetails
					(
						ID BIGINT NOT NULL IDENTITY, 
						[PartRepairStationsDetailsId] [BIGINT] IDENTITY(1,1) NOT NULL,
						[PartRepairStationsId] [BIGINT] NOT NULL,
						[City] [VARCHAR](250) NULL,
						[Country] [VARCHAR](150) NULL,
						[FacilityId] [BIGINT] NULL,
						[FacilityName] [VARCHAR](250) NULL,
						[OverhaulPrice] [VARCHAR](250) NULL,
						[OverHTat] [VARCHAR](50) NULL,
						[Phone] [VARCHAR](20) NULL,
						[PostalCode] [VARCHAR](50) NULL,
						[QuoteSpeed] [VARCHAR](50) NULL,
						[RepairHTat] [VARCHAR](20) NULL,
						[RepairPrice] [VARCHAR](20) NULL,
						[State] [VARCHAR](50) NULL,
						[TestPrice] [VARCHAR](20) NULL,
						[TestTat] [VARCHAR](20) NULL,
						[WebLink] [VARCHAR](150) NULL,
						[Response] [VARCHAR](250) NULL,		
						[CreatedBy] [VARCHAR](50) NOT NULL,
						[CreatedDate] [datetime2](7) NOT NULL,
						[UpdatedBy] [VARCHAR](50) NOT NULL,
						[UpdatedDate] [DATETIME2](7) NOT NULL,
						[IsActive] [BIT] NOT NULL,
						[IsDeleted] [BIT] NOT NULL,
					)

					INSERT INTO #tmpPartRepairStationsDetails ([PartRepairStationsDetailsId],[PartRepairStationsId],[City],[Country],[FacilityId],	[FacilityName] ,[OverhaulPrice] ,[OverHTat] ,
							[Phone],[PostalCode],[QuoteSpeed],[RepairHTat],[RepairPrice],[State],[TestPrice],[TestTat] ,[WebLink] ,[Response] ,[CreatedBy] ,
							[CreatedDate] ,[UpdatedBy] ,[UpdatedDate] ,[IsActive] ,[IsDeleted])
					SELECT [PartRepairStationsDetailsId],@ReturnPartRepairStationsId,[City],[Country],[FacilityId],	[FacilityName] ,[OverhaulPrice] ,[OverHTat] ,
							[Phone],[PostalCode],[QuoteSpeed],[RepairHTat],[RepairPrice],[State],[TestPrice],[TestTat] ,[WebLink] ,[Response] ,@CreatedBy ,
							GETDATE() ,@UpdatedBy ,GETDATE() ,1 ,0
					FROM @Tbl_PartRepairStationsDetailsType;

					SELECT @TotalCounts = COUNT(ID) FROM #tmpPartRepairStationsDetails;

					--WHILE @mcount<= @TotalCounts
					--BEGIN
						INSERT INTO [dbo].[PartRepairStationsDetails] ([PartRepairStationsId],[City],[Country],[FacilityId],	[FacilityName] ,[OverhaulPrice] ,[OverHTat] ,
									[Phone],[PostalCode],[QuoteSpeed],[RepairHTat],[RepairPrice],[State],[TestPrice],[TestTat] ,[WebLink] ,[Response] ,[CreatedBy] ,
									[CreatedDate] ,[UpdatedBy] ,[UpdatedDate] ,[IsActive] ,[IsDeleted])
						SELECT @ReturnPartRepairStationsId,[City],[Country],[FacilityId],	[FacilityName] ,[OverhaulPrice] ,[OverHTat] ,
									[Phone],[PostalCode],[QuoteSpeed],[RepairHTat],[RepairPrice],[State],[TestPrice],[TestTat] ,[WebLink] ,[Response] ,@CreatedBy ,
									GETDATE() ,@UpdatedBy ,GETDATE() ,1 ,0
						FROM @Tbl_PartRepairStationsDetailsType;
						--SET @mcount = @mcount + 1;
					--END;


					IF OBJECT_ID(N'tempdb..##tmpPartRepairStationsDetails') IS NOT NULL
					BEGIN
						DROP TABLE #tmpPartRepairStationsDetails
					END
		END
		ELSE
		BEGIN
				UPDATE [dbo].[PartRepairStations]
				   SET [PartNumber] = @PartNumber,
					   [Manufacturer] = @Manufacturer,
					   [AirCraftType] = @AirCraftType,
					   [ATAChapterId] = @ATAChapterId,
					   [ItemMasterId] = @ItemMasterId,
					   [MasterCompanyId] = @MasterCompanyId,
					   [UpdatedBy] = @UpdatedBy,
					   UpdatedDate = GETDATE()
					WHERE PartRepairStationsId = @PartRepairStationsId;

				DELETE FROM PartRepairStationsDetails WHERE PartRepairStationsId = @PartRepairStationsId;

				INSERT INTO [dbo].[PartRepairStationsDetails] ([PartRepairStationsId],[City],[Country],[FacilityId],	[FacilityName] ,[OverhaulPrice] ,[OverHTat] ,
									[Phone],[PostalCode],[QuoteSpeed],[RepairHTat],[RepairPrice],[State],[TestPrice],[TestTat] ,[WebLink] ,[Response] ,[CreatedBy] ,
									[CreatedDate] ,[UpdatedBy] ,[UpdatedDate] ,[IsActive] ,[IsDeleted])
				SELECT @PartRepairStationsId,[City],[Country],[FacilityId],	[FacilityName] ,[OverhaulPrice] ,[OverHTat] ,
									[Phone],[PostalCode],[QuoteSpeed],[RepairHTat],[RepairPrice],[State],[TestPrice],[TestTat] ,[WebLink] ,[Response] ,@CreatedBy ,
									GETDATE() ,@UpdatedBy ,GETDATE() ,1 ,0
				FROM @Tbl_PartRepairStationsDetailsType;
		END

    END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'AddUpdatePartRepairStations' 
            , @ProcedureParameters VARCHAR(3000)  = '@PartRepairStationsId = '''+ ISNULL(@PartRepairStationsId, '') + ''
            , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
            exec spLogException 
                    @DatabaseName           = @DatabaseName
                    , @AdhocComments          = @AdhocComments
                    , @ProcedureParameters = @ProcedureParameters
                    , @ApplicationName        =  @ApplicationName
                    , @ErrorLogID                    = @ErrorLogID OUTPUT ;
            RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
            RETURN(1);
	END CATCH
END