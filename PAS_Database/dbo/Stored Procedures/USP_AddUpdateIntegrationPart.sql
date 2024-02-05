/*************************************************************           
 ** File:   [USP_AddUpdateIntegrationPart]           
 ** Author:  Rajesh Gami
 ** Description: This stored procedure is used to add update integration part like ILS,145 etc...
 ** Purpose:         
 ** Date:   23/01/2024      
          
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   ----------  -----------	--------------------------------          
    1    23/01/2024  Rajesh Gami	Created
     
************************************************************************/
CREATE     PROCEDURE [dbo].[USP_AddUpdateIntegrationPart]
	@PartNumber varchar(200),
	@PartDescription varchar(MAX),
	@RepairStation varchar(100)=NULL,
	@PhoneNumber varchar(20) = NULL,
	@IntegrationPortalId int = NULL,
	@IntegrationPortal varchar(50) = '',
	@RepairCertiNo varchar(50) = '',
	@LastUpdate varchar(50) = '', 
	@QuoteDate datetime2(7) = NULL,
	@OHPrice decimal(18, 2) = NULL,
	@OHTAT int = NULL,
	@RepairPrice decimal(18, 2) = NULL,
	@RepairTAT int = NULL,
	@TestPrice decimal(18, 2) = NULL, 
	@TestTAT int = NULL, 
	@WebLink varchar(MAX) = NULL,
	@Location varchar(100) = NULL,
	@AltPartNumber varchar(200) = NULL, 
	@Qty int = NULL,
	@Cage varchar(100) = NULL,
	@Condition varchar(50) = NULL,
	@Distance varchar(50) = NULL,
	@ExchangeOption varchar(50) = NULL,	
	@MasterCompanyId int,
	@UserName varchar(256)
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		BEGIN TRANSACTION
		BEGIN		
			DECLARE @ILSName varchar(20) = 'ILS', @145Name varchar(20) ='145.COM',@AEXName varchar(20) ='AEX',@IntegrationMasterId BIGINT =0;
			DECLARE @ExistOtherConCount INT , @IlsIntegrationPortalId INT = 0, @OneFourtyIntegrationPortalId INT = 0;
			DECLARE @PortalType varchar(20) = (SELECT TOP 1 Description FROM DBO.IntegrationPortal WITH(NOLOCK) WHERE IntegrationPortalId = @IntegrationPortalId);
			DECLARE @LatestId BIGINT = 0;


			IF OBJECT_ID(N'tempdb..#tempTableIntegration') IS NOT NULL
			BEGIN
				DROP TABLE #tempTableIntegration
			END
			CREATE TABLE #tempTableIntegration(
			   [ID] [bigint] NULL
			)
			
			IF(@IntegrationPortalId IS NULL OR @IntegrationPortalId = 0) /** Start IF: @IntegrationPortalId IS NULL OR @IntegrationPortalId = 0**/
			BEGIN
				SET @IlsIntegrationPortalId = (SELECT TOP 1 IntegrationPortalId FROM DBO.IntegrationPortal WITH(NOLOCK) WHERE UPPER(Description) =  UPPER(@ILSName) AND MasterCompanyId = @MasterCompanyId)
				SET @OneFourtyIntegrationPortalId = (SELECT TOP 1 IntegrationPortalId FROM DBO.IntegrationPortal WITH(NOLOCK) WHERE UPPER(Description) =  UPPER(@145Name) AND MasterCompanyId = @MasterCompanyId)
				
					SET @IntegrationPortalId = @OneFourtyIntegrationPortalId;
					IF((SELECT COUNT (1) FROM DBO.IntegrationMaster WITH (NOLOCK) WHERE PartNumber = @PartNumber AND IntegrationPortalId = @IntegrationPortalId AND MasterCompanyId = @MasterCompanyId) > 0)
					BEGIN
						DELETE FROM DBO.OneFourtyFiveChildPartDetail WHERE IntegrationMasterId in (SELECT IntegrationMasterId FROM DBO.IntegrationMaster WITH(NOLOCK)  WHERE PartNumber = @PartNumber AND IntegrationPortalId = @IntegrationPortalId  AND MasterCompanyId = @MasterCompanyId)
						DELETE FROM DBO.IntegrationMaster WHERE PartNumber = @PartNumber AND IntegrationPortalId = @IntegrationPortalId  AND MasterCompanyId = @MasterCompanyId
					END
				
					/******* Insert into IntegrationMaster Table ********/
						INSERT INTO [dbo].[IntegrationMaster]
							   ([PartNumber]
							   ,[PartDescription]
							   ,[RepairStation]
							   ,[IsRepair]
							   ,[PhoneNumber]
							   ,[IntegrationPortalId]
							   ,[IntegrationPortal]
							   ,[MasterCompanyId]
							   ,[CreatedBy]
							   ,[UpdatedBy]
							   ,[CreatedDate]
							   ,[UpdatedDate]
							   ,[IsDeleted]
							   ,[IsActive])
							 VALUES
								   (@PartNumber,
								   @PartDescription,
								   @RepairStation,
								   (CASE WHEN ISNULL(@RepairStation,'') = '' THEN 0 ELSE 1 END), 
								   @PhoneNumber,
								   @IntegrationPortalId,
								   @IntegrationPortal,
								   @MasterCompanyId,
								   @UserName,
								   @UserName,
								   GETUTCDATE(),
								   GETUTCDATE(),
								   0,
								   1 )
						SET @LatestId = SCOPE_IDENTITY();

						INSERT INTO #tempTableIntegration(ID)Values(@LatestId)

						/******* Insert into OneFourtyFiveChildPartDetail Table ********/
						INSERT INTO [dbo].[OneFourtyFiveChildPartDetail]
					   ([IntegrationMasterId]
					   ,[RepairCertiNo]
					   ,[LastUpdate]
					   ,[QuoteDate]
					   ,[OHPrice]
					   ,[OHTAT]
					   ,[RepairPrice]
					   ,[RepairTAT]
					   ,[TestPrice]
					   ,[TestTAT]
					   ,[WebLink]
					   ,[Location]
					   ,[MasterCompanyId]
					   ,[CreatedBy]
					   ,[UpdatedBy]
					   ,[CreatedDate]
					   ,[UpdatedDate]
					   ,[IsDeleted]
					   ,[IsActive])
				 VALUES
					   (@LatestId
					   ,@RepairCertiNo
					   ,@LastUpdate
					   ,@QuoteDate
					   ,@OHPrice
					   ,@OHTAT
					   ,@RepairPrice
					   ,@RepairTAT
					   ,@TestPrice
					   ,@TestTAT
					   ,@WebLink
					   ,@Location
					   ,@MasterCompanyId
					   ,@UserName
					   ,@UserName
					   ,GETUTCDATE()
					   ,GETUTCDATE()
					   ,0
					   ,1)	

					 

			 
			
				SET @IntegrationPortalId = @IlsIntegrationPortalId;
				IF((SELECT COUNT (1) FROM DBO.IntegrationMaster WITH (NOLOCK) WHERE PartNumber = @PartNumber AND IntegrationPortalId = @IntegrationPortalId AND MasterCompanyId = @MasterCompanyId) > 0)
					BEGIN
						SET @ExistOtherConCount = (SELECT COUNT(1) FROM DBO.ILSChildPartDetail WITH(NOLOCK) WHERE  IntegrationMasterId in (SELECT IntegrationMasterId FROM DBO.IntegrationMaster WITH(NOLOCK) WHERE PartNumber = @PartNumber AND IntegrationPortalId = @IntegrationPortalId AND Condition != @Condition AND MasterCompanyId = @MasterCompanyId)) 
						DELETE FROM DBO.ILSChildPartDetail WHERE IntegrationMasterId in (SELECT IntegrationMasterId FROM DBO.IntegrationMaster WITH(NOLOCK) WHERE PartNumber = @PartNumber AND IntegrationPortalId = @IntegrationPortalId AND Condition = @Condition AND MasterCompanyId = @MasterCompanyId)
						
						IF(@ExistOtherConCount = 0)
						BEGIN
							DELETE FROM DBO.IntegrationMaster WHERE PartNumber = @PartNumber AND IntegrationPortalId = @IntegrationPortalId  AND MasterCompanyId = @MasterCompanyId

							/******* Insert into IntegrationMaster Table ********/
							INSERT INTO [dbo].[IntegrationMaster]
								   ([PartNumber]
								   ,[PartDescription]
								   ,[RepairStation]
								   ,[IsRepair]
								   ,[PhoneNumber]
								   ,[IntegrationPortalId]
								   ,[IntegrationPortal]
								   ,[MasterCompanyId]
								   ,[CreatedBy]
								   ,[UpdatedBy]
								   ,[CreatedDate]
								   ,[UpdatedDate]
								   ,[IsDeleted]
								   ,[IsActive])
								 VALUES
									   (@PartNumber,
									   @PartDescription,
									   @RepairStation,
									   (CASE WHEN ISNULL(@RepairStation,'') = '' THEN 0 ELSE 1 END), 
									   @PhoneNumber,
									   @IntegrationPortalId,
									   @IntegrationPortal,
									   @MasterCompanyId,
									   @UserName,
									   @UserName,
									   GETUTCDATE(),
									   GETUTCDATE(),
									   0,
									   1 )
							SET @LatestId = SCOPE_IDENTITY();
							INSERT INTO #tempTableIntegration(ID)Values(@LatestId)

						END
						IF(@ExistOtherConCount > 0)
						BEGIN
							SET @IntegrationMasterId = ISNULL((SELECT TOP 1 IntegrationMasterId FROM DBO.ILSChildPartDetail WITH(NOLOCK) WHERE  IntegrationMasterId = (SELECT TOP 1 IntegrationMasterId FROM DBO.IntegrationMaster WITH(NOLOCK) WHERE PartNumber = @PartNumber AND IntegrationPortalId = @IntegrationPortalId AND Condition != @Condition AND MasterCompanyId = @MasterCompanyId)),0);
							UPDATE DBO.IntegrationMaster SET RepairStation = @RepairStation, IsRepair =  (CASE WHEN ISNULL(@RepairStation,'') = '' THEN 0 ELSE 1 END), PhoneNumber = @PhoneNumber, UpdatedBy = @UserName, UpdatedDate = GETUTCDATE() WHERE IntegrationMasterId = @IntegrationMasterId; 
							INSERT INTO #tempTableIntegration(ID)Values(@IntegrationMasterId)
							SET @LatestId = @IntegrationMasterId;
						END
					END

					/******* Insert into ILSChildPartDetail Table ********/

				  INSERT INTO [dbo].[ILSChildPartDetail]
					   ([IntegrationMasterId]
					   ,[AltPartNumber]
					   ,[Qty]
					   ,[Cage]
					   ,[Condition]
					   ,[Distance]
					   ,[ExchangeOption]
					   ,[MasterCompanyId]
					   ,[CreatedBy]
					   ,[UpdatedBy]
					   ,[CreatedDate]
					   ,[UpdatedDate]
					   ,[IsDeleted]
					   ,[IsActive])
				    VALUES
					   (@LatestId
					   ,@AltPartNumber
					   ,@Qty
					   ,@Cage
					   ,@Condition
					   ,@Distance
					   ,@ExchangeOption
					   ,@MasterCompanyId
					   ,@UserName
					   ,@UserName
					   ,GETUTCDATE()
					   ,GETUTCDATE()
					   ,0
					   ,1)	
				
				 SELECT im.IntegrationMasterId,
						im.PartNumber,
						im.PartDescription,
						im.RepairStation,
						im.IsRepair,
						im.PhoneNumber,
						im.IntegrationPortalId,
						im.IntegrationPortal,
						ils.ILSChildPartId,
						ils.AltPartNumber,
						ils.Qty,
						ils.Cage,
						ils.Condition,
						ils.Distance,
						ils.ExchangeOption,
						im.MasterCompanyId,
						im.UpdatedBy,
						im.UpdatedDate,
						ofc.OneFourtyFiveChildPartId,
						ofc.RepairCertiNo,
						ofc.LastUpdate,
						ofc.QuoteDate,
						ofc.OHPrice,
						ofc.OHTAT,
						ofc.RepairPrice,
						ofc.RepairTAT,
						ofc.TestPrice,
						ofc.TestTAT,
						ofc.WebLink,
						ofc.[Location] AS Location
					FROM DBO.IntegrationMaster IM WITH (NOLOCK) 
					LEFT JOIN [dbo].[ILSChildPartDetail] ILS WITH (NOLOCK) ON IM.IntegrationMasterId = ILS.IntegrationMasterId
					LEFT JOIN [dbo].[OneFourtyFiveChildPartDetail] OFC WITH (NOLOCK) ON IM.IntegrationMasterId = OFC.IntegrationMasterId
					WHERE IM.IntegrationMasterId IN(SELECT ID FROM #tempTableIntegration)

				
			 
			END /** END IF : @IntegrationPortalId IS NULL OR @IntegrationPortalId = 0**/
			ELSE /** Start ELSE : @IntegrationPortalId IS NULL OR @IntegrationPortalId = 0**/
			BEGIN
				IF(UPPER(@PortalType) = UPPER(@145Name))  /**** Start:  145 Integration ******/
				BEGIN
					IF((SELECT COUNT (1) FROM DBO.IntegrationMaster WITH (NOLOCK) WHERE PartNumber = @PartNumber AND IntegrationPortalId = @IntegrationPortalId AND MasterCompanyId = @MasterCompanyId) > 0)
					BEGIN
						DELETE FROM DBO.OneFourtyFiveChildPartDetail WHERE IntegrationMasterId in (SELECT IntegrationMasterId FROM DBO.IntegrationMaster WITH(NOLOCK)  WHERE PartNumber = @PartNumber AND IntegrationPortalId = @IntegrationPortalId  AND MasterCompanyId = @MasterCompanyId)
						DELETE FROM DBO.IntegrationMaster WHERE PartNumber = @PartNumber AND IntegrationPortalId = @IntegrationPortalId  AND MasterCompanyId = @MasterCompanyId
					END
				
					/******* Insert into IntegrationMaster Table ********/
						INSERT INTO [dbo].[IntegrationMaster]
							   ([PartNumber]
							   ,[PartDescription]
							   ,[RepairStation]
							   ,[IsRepair]
							   ,[PhoneNumber]
							   ,[IntegrationPortalId]
							   ,[IntegrationPortal]
							   ,[MasterCompanyId]
							   ,[CreatedBy]
							   ,[UpdatedBy]
							   ,[CreatedDate]
							   ,[UpdatedDate]
							   ,[IsDeleted]
							   ,[IsActive])
							 VALUES
								   (@PartNumber,
								   @PartDescription,
								   @RepairStation,
								   (CASE WHEN ISNULL(@RepairStation,'') = '' THEN 0 ELSE 1 END), 
								   @PhoneNumber,
								   @IntegrationPortalId,
								   @IntegrationPortal,
								   @MasterCompanyId,
								   @UserName,
								   @UserName,
								   GETUTCDATE(),
								   GETUTCDATE(),
								   0,
								   1 )
						SET @LatestId = SCOPE_IDENTITY();

						INSERT INTO #tempTableIntegration(ID)Values(@LatestId)

						/******* Insert into OneFourtyFiveChildPartDetail Table ********/
						INSERT INTO [dbo].[OneFourtyFiveChildPartDetail]
					   ([IntegrationMasterId]
					   ,[RepairCertiNo]
					   ,[LastUpdate]
					   ,[QuoteDate]
					   ,[OHPrice]
					   ,[OHTAT]
					   ,[RepairPrice]
					   ,[RepairTAT]
					   ,[TestPrice]
					   ,[TestTAT]
					   ,[WebLink]
					   ,[Location]
					   ,[MasterCompanyId]
					   ,[CreatedBy]
					   ,[UpdatedBy]
					   ,[CreatedDate]
					   ,[UpdatedDate]
					   ,[IsDeleted]
					   ,[IsActive])
				 VALUES
					   (@LatestId
					   ,@RepairCertiNo
					   ,@LastUpdate
					   ,@QuoteDate
					   ,@OHPrice
					   ,@OHTAT
					   ,@RepairPrice
					   ,@RepairTAT
					   ,@TestPrice
					   ,@TestTAT
					   ,@WebLink
					   ,@Location
					   ,@MasterCompanyId
					   ,@UserName
					   ,@UserName
					   ,GETUTCDATE()
					   ,GETUTCDATE()
					   ,0
					   ,1)	

					   SELECT im.IntegrationMasterId,
						im.PartNumber,
						im.PartDescription,
						im.RepairStation,
						im.IsRepair,
						im.PhoneNumber,
						im.IntegrationPortalId,
						im.IntegrationPortal,
						ofc.OneFourtyFiveChildPartId,
						ofc.RepairCertiNo,
						ofc.LastUpdate,
						ofc.QuoteDate,
						ofc.OHPrice,
						ofc.OHTAT,
						ofc.RepairPrice,
						ofc.RepairTAT,
						ofc.TestPrice,
						ofc.TestTAT,
						ofc.WebLink,
						ofc.[Location] AS Location,
						im.MasterCompanyId,
						im.UpdatedBy,
						im.UpdatedDate
					FROM DBO.IntegrationMaster IM WITH (NOLOCK) 
					INNER JOIN [dbo].[OneFourtyFiveChildPartDetail] OFC WITH (NOLOCK) ON IM.IntegrationMasterId = OFC.IntegrationMasterId
					WHERE IM.IntegrationMasterId IN(SELECT ID FROM #tempTableIntegration)

			END   /**** End:  145 Integration ******/
			ELSE IF(UPPER(@PortalType) = UPPER(@ILSName)) /**** Start:  ILS Integration ******/
			BEGIN
						SET @ExistOtherConCount = (SELECT COUNT(1) FROM DBO.ILSChildPartDetail WITH(NOLOCK) WHERE  IntegrationMasterId in (SELECT IntegrationMasterId FROM DBO.IntegrationMaster WITH(NOLOCK) WHERE PartNumber = @PartNumber AND IntegrationPortalId = @IntegrationPortalId AND Condition != @Condition AND MasterCompanyId = @MasterCompanyId)) 
						DELETE FROM DBO.ILSChildPartDetail WHERE IntegrationMasterId in (SELECT IntegrationMasterId FROM DBO.IntegrationMaster WITH(NOLOCK) WHERE PartNumber = @PartNumber AND IntegrationPortalId = @IntegrationPortalId AND Condition = @Condition AND MasterCompanyId = @MasterCompanyId)
						PRINT @ExistOtherConCount
						IF(@ExistOtherConCount = 0)
						BEGIN
							DELETE FROM DBO.IntegrationMaster WHERE PartNumber = @PartNumber AND IntegrationPortalId = @IntegrationPortalId  AND MasterCompanyId = @MasterCompanyId

							/******* Insert into IntegrationMaster Table ********/
							INSERT INTO [dbo].[IntegrationMaster]
								   ([PartNumber]
								   ,[PartDescription]
								   ,[RepairStation]
								   ,[IsRepair]
								   ,[PhoneNumber]
								   ,[IntegrationPortalId]
								   ,[IntegrationPortal]
								   ,[MasterCompanyId]
								   ,[CreatedBy]
								   ,[UpdatedBy]
								   ,[CreatedDate]
								   ,[UpdatedDate]
								   ,[IsDeleted]
								   ,[IsActive])
								 VALUES
									   (@PartNumber,
									   @PartDescription,
									   @RepairStation,
									   (CASE WHEN ISNULL(@RepairStation,'') = '' THEN 0 ELSE 1 END), 
									   @PhoneNumber,
									   @IntegrationPortalId,
									   @IntegrationPortal,
									   @MasterCompanyId,
									   @UserName,
									   @UserName,
									   GETUTCDATE(),
									   GETUTCDATE(),
									   0,
									   1 )
							SET @LatestId = SCOPE_IDENTITY();
							INSERT INTO #tempTableIntegration(ID)Values(@LatestId)

						END
						IF(@ExistOtherConCount > 0)
						BEGIN
							SET @IntegrationMasterId =  ISNULL((SELECT TOP 1 IntegrationMasterId FROM DBO.ILSChildPartDetail WITH(NOLOCK) WHERE  IntegrationMasterId = (SELECT TOP 1 IntegrationMasterId FROM DBO.IntegrationMaster WITH(NOLOCK) WHERE PartNumber = @PartNumber AND IntegrationPortalId = @IntegrationPortalId AND Condition != @Condition AND MasterCompanyId = @MasterCompanyId)),0);
							UPDATE DBO.IntegrationMaster SET RepairStation = @RepairStation, IsRepair =  (CASE WHEN ISNULL(@RepairStation,'') = '' THEN 0 ELSE 1 END), PhoneNumber = @PhoneNumber, UpdatedBy = @UserName, UpdatedDate = GETUTCDATE() WHERE IntegrationMasterId = @IntegrationMasterId; 
							INSERT INTO #tempTableIntegration(ID)Values(@IntegrationMasterId)
							SET @LatestId = @IntegrationMasterId;
						END
					PRINT @LatestId;
					/******* Insert into ILSChildPartDetail Table ********/

				  INSERT INTO [dbo].[ILSChildPartDetail]
					   ([IntegrationMasterId]
					   ,[AltPartNumber]
					   ,[Qty]
					   ,[Cage]
					   ,[Condition]
					   ,[Distance]
					   ,[ExchangeOption]
					   ,[MasterCompanyId]
					   ,[CreatedBy]
					   ,[UpdatedBy]
					   ,[CreatedDate]
					   ,[UpdatedDate]
					   ,[IsDeleted]
					   ,[IsActive])
				    VALUES
					   (@LatestId
					   ,@AltPartNumber
					   ,@Qty
					   ,@Cage
					   ,@Condition
					   ,@Distance
					   ,@ExchangeOption
					   ,@MasterCompanyId
					   ,@UserName
					   ,@UserName
					   ,GETUTCDATE()
					   ,GETUTCDATE()
					   ,0
					   ,1)	
				
				 SELECT im.IntegrationMasterId,
						im.PartNumber,
						im.PartDescription,
						im.RepairStation,
						im.IsRepair,
						im.PhoneNumber,
						im.IntegrationPortalId,
						im.IntegrationPortal,
						ils.ILSChildPartId,
						ils.AltPartNumber,
						ils.Qty,
						ils.Cage,
						ils.Condition,
						ils.Distance,
						ils.ExchangeOption,
						im.MasterCompanyId,
						im.UpdatedBy,
						im.UpdatedDate
					FROM DBO.IntegrationMaster IM WITH (NOLOCK) 
					INNER JOIN [dbo].[ILSChildPartDetail] ILS WITH (NOLOCK) ON IM.IntegrationMasterId = ILS.IntegrationMasterId
					WHERE IM.IntegrationMasterId IN(SELECT ID FROM #tempTableIntegration)
				END  /**** End:  ILS Integration ******/
			END	 /** END ELSE : @IntegrationPortalId IS NULL OR @IntegrationPortalId = 0**/	
			
		END
	COMMIT  TRANSACTION
		END TRY    
		BEGIN CATCH      
		    SELECT  
			 ERROR_NUMBER() AS ErrorNumber  
            ,ERROR_SEVERITY() AS ErrorSeverity  
            ,ERROR_STATE() AS ErrorState  
            ,ERROR_PROCEDURE() AS ErrorProcedure  
            ,ERROR_LINE() AS ErrorLine  
            ,ERROR_MESSAGE() AS ErrorMessage;  

			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_AddUpdateIntegrationPart' 
               , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@PartNumber, '') + ''',
														@Parameter2 = ' + ISNULL(@PartDescription,'') + ', 
														@Parameter3 = ' + ISNULL(@RepairStation,'') + ', 
														@Parameter4 = ' + ISNULL(@PhoneNumber,'') + ', 
														@Parameter5 = ' + ISNULL(@IntegrationPortalId,'') + ', 
														@Parameter6 = ' + ISNULL(@IntegrationPortal,'') + ', 
														@Parameter7 = ' + ISNULL(@RepairCertiNo,'') + ', 
														@Parameter8 = ' + ISNULL(@LastUpdate,'') + ', 
														@Parameter10 = ' + ISNULL(@OHPrice,'') + ', 
														@Parameter11 = ' + ISNULL(@OHTAT,'') + ', 
														@Parameter12 = ' + ISNULL(@RepairPrice,'') + ', 
														@Parameter13 = ' + ISNULL(@RepairTAT,'') + ', 
														@Parameter14 = ' + ISNULL(@TestPrice,'') + ', 
														@Parameter15 = ' + ISNULL(@TestTAT,'') + ', 
														@Parameter16 = ' + ISNULL(@WebLink,'') + ', 
														@Parameter17 = ' + ISNULL(@MasterCompanyId,'') + ''

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