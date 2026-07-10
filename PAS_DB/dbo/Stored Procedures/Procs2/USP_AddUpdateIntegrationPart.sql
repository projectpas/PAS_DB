
-- ---------------------------------------------------------------------------------------------------
-- Stored Procedure: dbo.USP_AddUpdateIntegrationPart   (source: PAS_DB/dbo/Stored Procedures/Procs2/USP_AddUpdateIntegrationPart.sql)
-- ---------------------------------------------------------------------------------------------------
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
	2    23-07-2025  Amit Ghediya   MOdify for get RFQ part is in our inventory or not (ItemMasterId)
	3    23-07-2025  Devendra Shekh	Modify to get customerId and address Details
	4	 25-07-2025  Devendra Shekh	added IsMRO Field
	5	 28-07-2025  Amit Ghediya	added For Check NUll IsMRO Field
	6	 25-12-2025  Amit Ghediya	added For save PartsBase
	7	 28-01-2026  Vishal Suthar	changed the logic to delete and save partsbase search result
	8    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
     
exec USP_AddUpdateIntegrationPart @PartNumber=N'10-0114-5',@PartDescription=N'EXIT LIGHT',@RepairStation=NULL,@PhoneNumber=N'+1305-716-0128',@IntegrationPortalId=54,@IntegrationPortal=N'PartsBase',@RepairCertiNo=NULL,@LastUpdate=NULL,@QuoteDate='2026-01-16 00:00:00',@OHPrice=NULL,@OHTAT=NULL,@RepairPrice=NULL,@RepairTAT=NULL,@TestPrice=NULL,@TestTAT=NULL,@WebLink=N'http://www.gmair.com',@Location=NULL,@AltPartNumber=NULL,@Qty=4,@Cage=N'5A964',@Condition=NULL,@Distance=NULL,@ExchangeOption=NULL,@MasterCompanyId=1,@UserName=N'ADMIN User',@AddressLine1=NULL,@AddressLine2=NULL,@City=N'DORAL',@State=N'FL',@PostalCode=N'33178',@Country=N'United States',@IsMRO=0,@Index=1,@InventoryId=N'2201221029',@Currency=N'dollars',@Manufacturer=N'',@UnitPrice=0.0,@UoM=N'EA'

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
	@UserName varchar(256),
	@AddressLine1 varchar(100) = '',
	@AddressLine2 varchar(100) = '',
	@City varchar(50) = '',
	@State varchar(50) = '',
	@PostalCode varchar(50) = '',
	@Country varchar(100) = '',
	@IsMRO bit = null,
	@Index bigint = NULL,
	@InventoryId varchar(200) = NULL,
	@Currency varchar(50) = NULL,
	@Manufacturer varchar(50) = NULL,
	@UnitPrice decimal(18, 2) = NULL,
	@UoM varchar(50) = ''
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		BEGIN TRANSACTION
		BEGIN		
			DECLARE @ILSName varchar(20) = 'ILS', @145Name varchar(20) ='145.COM',@AEXName varchar(20) ='AEX',@PartsBaseName varchar(20) = 'PartsBase',@IntegrationMasterId BIGINT =0;
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
						DELETE FROM DBO.OneFourtyFiveChildPartDetail WHERE IntegrationMasterId in (SELECT IntegrationMasterId FROM DBO.IntegrationMaster WITH(NOLOCK)  WHERE PartNumber = @PartNumber AND RepairStation = @RepairStation AND IntegrationPortalId = @IntegrationPortalId  AND MasterCompanyId = @MasterCompanyId)
						DELETE FROM DBO.IntegrationMaster WHERE PartNumber = @PartNumber AND RepairStation = @RepairStation AND IntegrationPortalId = @IntegrationPortalId  AND MasterCompanyId = @MasterCompanyId
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
							   ,[IsActive]
							   ,[AddressLine1]
							   ,[AddressLine2]
							   ,[City]
							   ,[State]
							   ,[PostalCode]
							   ,[Country]
							   ,[IsMRO]
							   )
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
								   1,
								   @AddressLine1,
								   @AddressLine2,
								   @City,
								   @State,
								   @PostalCode,
								   @Country,
								   @IsMRO
								   )
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
								   ,[IsActive]
								   ,[AddressLine1]
								   ,[AddressLine2]
								   ,[City]
								   ,[State]
								   ,[PostalCode]
								   ,[Country]
								   ,[IsMRO]
								   )
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
									   1,
									   @AddressLine1,
								       @AddressLine2,
									   @City,
									   @State,
									   @PostalCode,
									   @Country,
									   @IsMRO
									   )
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

					   /******* Insert into PartsBaseChildPartDetail Table ********/
				INSERT INTO [dbo].[PartsBaseChildPartDetail]
					   ([IntegrationMasterId]
						,[Index]
						,[InventoryId]
						,[AltPartNumber]
						,[Cage]
						,[Condition]
						,[Currency]
						,[Manufacturer]
						,[PartDescription]
						,[PartNumber]
						,[Quantity]
						,[UnitPrice]
						,[UoM]
						,[MasterCompanyId]
						,[CreatedBy]
						,[UpdatedBy]
						,[CreatedDate]
						,[UpdatedDate]
						,[IsDeleted]
						,[IsActive])
				 VALUES
					   (@LatestId
						,@Index
						,@InventoryId
						,@AltPartNumber
						,@Cage
						,@Condition
						,@Currency
						,@Manufacturer
						,@PartDescription
						,@PartNumber
						,@Qty
						,@UnitPrice
						,@UoM
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
						ofc.[Location] AS Location,
						(CASE WHEN LOWER(TRIM(IM.[PartNumber])) = LOWER(TRIM(IMS.[partnumber])) THEN IMS.[ItemMasterId] ELSE 0 END) ItemMasterId,
						(CASE WHEN LOWER(TRIM(ILS.[AltPartNumber])) = LOWER(TRIM(IMSC.[partnumber])) THEN IMSC.[ItemMasterId] ELSE 0 END) ChildItemMasterId,
						IM.AddressLine1,
						IM.AddressLine2,
						IM.City,
						IM.State,
						IM.PostalCode,
						IM.Country,
						(CASE WHEN LOWER(TRIM(CU.[Name])) = LOWER(TRIM(IM.RepairStation)) THEN CU.CustomerId ELSE 0 END) CustomerId,
						IM.IsMRO
					FROM DBO.IntegrationMaster IM WITH (NOLOCK) 
					LEFT JOIN [dbo].[ILSChildPartDetail] ILS WITH (NOLOCK) ON IM.IntegrationMasterId = ILS.IntegrationMasterId
					LEFT JOIN [dbo].[OneFourtyFiveChildPartDetail] OFC WITH (NOLOCK) ON IM.IntegrationMasterId = OFC.IntegrationMasterId
					LEFT JOIN dbo.ItemMaster IMS WITH(NOLOCK) ON IM.[PartNumber] = IMS.[partnumber] AND IMS.[IsActive] = 1 AND IMS.[IsDeleted] = 0 AND IM.[MasterCompanyId] = IMS.[MasterCompanyId]
					 AND ISNULL(IMS.IsNonStock,0) = 0
					 LEFT JOIN dbo.ItemMaster IMSC WITH(NOLOCK) ON ILS.[AltPartNumber] = IMSC.[partnumber] AND IMSC.[IsActive] = 1 AND IMSC.[IsDeleted] = 0 AND ILS.[MasterCompanyId] = IMSC.[MasterCompanyId]
					 AND ISNULL(IMSC.IsNonStock,0) = 0
					  LEFT JOIN [dbo].[Customer] CU WITH(NOLOCK) ON IM.RepairStation = CU.[Name] AND IM.MasterCompanyId = CU.MasterCompanyId AND CU.[IsActive] = 1 AND CU.[IsDeleted] = 0
					WHERE IM.IntegrationMasterId IN(SELECT ID FROM #tempTableIntegration)

				
			 
			END /** END IF : @IntegrationPortalId IS NULL OR @IntegrationPortalId = 0**/
			ELSE /** Start ELSE : @IntegrationPortalId IS NULL OR @IntegrationPortalId = 0**/
			BEGIN
				IF(UPPER(@PortalType) = UPPER(@145Name))  /**** Start:  145 Integration ******/
				BEGIN
					IF((SELECT COUNT (1) FROM DBO.IntegrationMaster WITH (NOLOCK) WHERE PartNumber = @PartNumber AND IntegrationPortalId = @IntegrationPortalId AND MasterCompanyId = @MasterCompanyId) > 0)
					BEGIN
						DELETE FROM DBO.OneFourtyFiveChildPartDetail WHERE IntegrationMasterId in (SELECT IntegrationMasterId FROM DBO.IntegrationMaster WITH(NOLOCK)  WHERE PartNumber = @PartNumber AND RepairStation = @RepairStation AND IntegrationPortalId = @IntegrationPortalId  AND MasterCompanyId = @MasterCompanyId)
						DELETE FROM DBO.IntegrationMaster WHERE PartNumber = @PartNumber AND RepairStation = @RepairStation AND IntegrationPortalId = @IntegrationPortalId  AND MasterCompanyId = @MasterCompanyId
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
							   ,[IsActive]
							   ,[AddressLine1]
							   ,[AddressLine2]
							   ,[City]
							   ,[State]
							   ,[PostalCode]
							   ,[Country]
							   ,[IsMRO]
							   )
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
								   1,
								   @AddressLine1,
								   @AddressLine2,
								   @City,
								   @State,
								   @PostalCode,
								   @Country,
								   @IsMRO
								   )
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
						im.UpdatedDate,
						(CASE WHEN LOWER(TRIM(IM.[PartNumber])) = LOWER(TRIM(IMS.[partnumber])) THEN IMS.[ItemMasterId] ELSE 0 END) ItemMasterId,
						0 ChildItemMasterId,
						IM.AddressLine1,
						IM.AddressLine2,
						IM.City,
						IM.State,
						IM.PostalCode,
						IM.Country,
						(CASE WHEN LOWER(TRIM(CU.[Name])) = LOWER(TRIM(IM.RepairStation)) THEN CU.CustomerId ELSE 0 END) CustomerId,
						IM.IsMRO
					FROM DBO.IntegrationMaster IM WITH (NOLOCK) 
					INNER JOIN [dbo].[OneFourtyFiveChildPartDetail] OFC WITH (NOLOCK) ON IM.IntegrationMasterId = OFC.IntegrationMasterId
					LEFT JOIN dbo.ItemMaster IMS WITH(NOLOCK) ON IM.[PartNumber] = IMS.[partnumber] AND IMS.[IsActive] = 1 AND IMS.[IsDeleted] = 0 AND IM.[MasterCompanyId] = IMS.[MasterCompanyId]
					 AND ISNULL(IMS.IsNonStock,0) = 0
					 LEFT JOIN [dbo].[Customer] CU WITH(NOLOCK) ON IM.RepairStation = CU.[Name] AND IM.MasterCompanyId = CU.MasterCompanyId AND CU.[IsActive] = 1 AND CU.[IsDeleted] = 0
					WHERE IM.IntegrationMasterId IN(SELECT ID FROM #tempTableIntegration)

			END   /**** End:  145 Integration ******/
				ELSE IF(UPPER(@PortalType) = UPPER(@ILSName)) /**** Start:  ILS Integration ******/
				BEGIN
						SET @ExistOtherConCount = (SELECT COUNT(1) FROM DBO.ILSChildPartDetail WITH(NOLOCK) WHERE  IntegrationMasterId in (SELECT IntegrationMasterId FROM DBO.IntegrationMaster WITH(NOLOCK) WHERE PartNumber = @PartNumber AND IntegrationPortalId = @IntegrationPortalId AND Condition != @Condition AND MasterCompanyId = @MasterCompanyId)) 
						--For MRO without Condition.
						IF(@IsMRO > 0)
						BEGIN 
							 DELETE FROM DBO.ILSChildPartDetail WHERE IntegrationMasterId in (SELECT IntegrationMasterId FROM DBO.IntegrationMaster WITH(NOLOCK) WHERE PartNumber = @PartNumber AND IntegrationPortalId = @IntegrationPortalId AND MasterCompanyId = @MasterCompanyId AND ISNULL(IsMRO,0) = @IsMRO)
						END
						ELSE
						BEGIN 
							 DELETE FROM DBO.ILSChildPartDetail WHERE IntegrationMasterId in (SELECT IntegrationMasterId FROM DBO.IntegrationMaster WITH(NOLOCK) WHERE PartNumber = @PartNumber AND IntegrationPortalId = @IntegrationPortalId AND Condition = @Condition AND MasterCompanyId = @MasterCompanyId AND ISNULL(IsMRO,0) = @IsMRO)
						END	
						
						
						PRINT @ExistOtherConCount
						IF(@ExistOtherConCount = 0)
						BEGIN 
							
							DELETE FROM DBO.IntegrationMaster WHERE PartNumber = @PartNumber AND IntegrationPortalId = @IntegrationPortalId  AND MasterCompanyId = @MasterCompanyId AND ISNULL(IsMRO,0) = @IsMRO
							
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
								   ,[IsActive]
								   ,[AddressLine1]
								   ,[AddressLine2]
								   ,[City]
								   ,[State]
								   ,[PostalCode]
								   ,[Country]
								   ,[IsMRO]
								   )
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
									   1,
									   @AddressLine1,
									   @AddressLine2,
									   @City,
									   @State,
									   @PostalCode,
									   @Country,
									   @IsMRO
									   )
							SET @LatestId = SCOPE_IDENTITY();
							INSERT INTO #tempTableIntegration(ID)Values(@LatestId)

						END
						IF(@ExistOtherConCount > 0)
						BEGIN
							SET @IntegrationMasterId =  ISNULL((SELECT TOP 1 IntegrationMasterId FROM DBO.ILSChildPartDetail WITH(NOLOCK) WHERE  IntegrationMasterId = (SELECT TOP 1 IntegrationMasterId FROM DBO.IntegrationMaster WITH(NOLOCK) WHERE PartNumber = @PartNumber AND IntegrationPortalId = @IntegrationPortalId AND Condition != @Condition AND MasterCompanyId = @MasterCompanyId AND ISNULL(IsMRO,0) = @IsMRO)),0);
							UPDATE DBO.IntegrationMaster SET RepairStation = @RepairStation, IsRepair =  (CASE WHEN ISNULL(@RepairStation,'') = '' THEN 0 ELSE 1 END), PhoneNumber = @PhoneNumber, UpdatedBy = @UserName, UpdatedDate = GETUTCDATE() WHERE IntegrationMasterId = @IntegrationMasterId AND ISNULL(IsMRO,0) = @IsMRO; 
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
						im.UpdatedDate,
						(CASE WHEN LOWER(TRIM(IM.[PartNumber])) = LOWER(TRIM(IMS.[partnumber])) THEN IMS.[ItemMasterId] ELSE 0 END) ItemMasterId,
						(CASE WHEN LOWER(TRIM(ILS.[AltPartNumber])) = LOWER(TRIM(IMSC.[partnumber])) THEN IMSC.[ItemMasterId] ELSE 0 END) ChildItemMasterId,
						IM.AddressLine1,
						IM.AddressLine2,
						IM.City,
						IM.State,
						IM.PostalCode,
						IM.Country,
						(CASE WHEN LOWER(TRIM(CU.[Name])) = LOWER(TRIM(IM.RepairStation)) THEN CU.CustomerId ELSE 0 END) CustomerId,
						IM.IsMRO
					FROM DBO.IntegrationMaster IM WITH (NOLOCK) 
					INNER JOIN [dbo].[ILSChildPartDetail] ILS WITH (NOLOCK) ON IM.IntegrationMasterId = ILS.IntegrationMasterId
					LEFT JOIN dbo.ItemMaster IMS WITH(NOLOCK) ON IM.[PartNumber] = IMS.[partnumber] AND IMS.[IsActive] = 1 AND IMS.[IsDeleted] = 0 AND IM.[MasterCompanyId] = IMS.[MasterCompanyId]
					 AND ISNULL(IMS.IsNonStock,0) = 0
					 LEFT JOIN dbo.ItemMaster IMSC WITH(NOLOCK) ON ILS.[AltPartNumber] = IMSC.[partnumber] AND IMSC.[IsActive] = 1 AND IMSC.[IsDeleted] = 0 AND ILS.[MasterCompanyId] = IMSC.[MasterCompanyId]
					 AND ISNULL(IMSC.IsNonStock,0) = 0
					  LEFT JOIN [dbo].[Customer] CU WITH(NOLOCK) ON IM.RepairStation = CU.[Name] AND IM.MasterCompanyId = CU.MasterCompanyId AND CU.[IsActive] = 1 AND CU.[IsDeleted] = 0
					WHERE IM.IntegrationMasterId IN(SELECT ID FROM #tempTableIntegration) AND ISNULL(IsMRO,0) = @IsMRO
				END  /**** End:  ILS Integration ******/
				ELSE IF (UPPER(@PortalType) = UPPER(@PartsBaseName))  -- Start: PartBase Integration
				BEGIN
					PRINT 'IsMRO';
					PRINT @IsMRO;

					------------------------------------------------------------------
					-- Get IntegrationMasterId (if exists)
					------------------------------------------------------------------
					SELECT TOP 1 
						   @IntegrationMasterId = IntegrationMasterId
					FROM DBO.IntegrationMaster WITH (NOLOCK)
					WHERE PartNumber = @PartNumber
					  AND IntegrationPortalId = @IntegrationPortalId
					  AND MasterCompanyId = @MasterCompanyId
					  AND ISNULL(IsMRO, 0) = @IsMRO;

					------------------------------------------------------------------
					-- Delete existing child records
					------------------------------------------------------------------
					DELETE PBC
					FROM DBO.PartsBaseChildPartDetail PBC
					WHERE PBC.IntegrationMasterId = @IntegrationMasterId;

					------------------------------------------------------------------
					-- Re-check child count AFTER delete
					------------------------------------------------------------------
					SELECT @ExistOtherConCount = COUNT(1)
					FROM DBO.PartsBaseChildPartDetail WITH (NOLOCK)
					WHERE IntegrationMasterId = @IntegrationMasterId;

					PRINT @ExistOtherConCount;
					PRINT 'final';

					------------------------------------------------------------------
					-- If no child records → delete & insert IntegrationMaster
					------------------------------------------------------------------
					IF (@ExistOtherConCount = 0)
					BEGIN
						PRINT 'delete IntegrationMaster';

						DELETE FROM DBO.IntegrationMaster
						WHERE IntegrationMasterId = @IntegrationMasterId
						  AND ISNULL(IsMRO, 0) = @IsMRO;

						INSERT INTO [dbo].[IntegrationMaster]
						(
							PartNumber,
							PartDescription,
							RepairStation,
							IsRepair,
							PhoneNumber,
							IntegrationPortalId,
							IntegrationPortal,
							MasterCompanyId,
							CreatedBy,
							UpdatedBy,
							CreatedDate,
							UpdatedDate,
							IsDeleted,
							IsActive,
							AddressLine1,
							AddressLine2,
							City,
							State,
							PostalCode,
							Country,
							IsMRO
						)
						VALUES
						(
							@PartNumber,
							@PartDescription,
							@RepairStation,
							CASE WHEN ISNULL(@RepairStation, '') = '' THEN 0 ELSE 1 END,
							@PhoneNumber,
							@IntegrationPortalId,
							@IntegrationPortal,
							@MasterCompanyId,
							@UserName,
							@UserName,
							GETUTCDATE(),
							GETUTCDATE(),
							0,
							1,
							@AddressLine1,
							@AddressLine2,
							@City,
							@State,
							@PostalCode,
							@Country,
							@IsMRO
						);

						SET @LatestId = SCOPE_IDENTITY();
						INSERT INTO #tempTableIntegration (ID) VALUES (@LatestId);
					END
					ELSE
					BEGIN
						------------------------------------------------------------------
						-- Update existing IntegrationMaster
						------------------------------------------------------------------
						UPDATE DBO.IntegrationMaster
						SET RepairStation = @RepairStation,
							IsRepair = CASE WHEN ISNULL(@RepairStation,'') = '' THEN 0 ELSE 1 END,
							PhoneNumber = @PhoneNumber,
							UpdatedBy = @UserName,
							UpdatedDate = GETUTCDATE()
						WHERE IntegrationMasterId = @IntegrationMasterId
						  AND ISNULL(IsMRO, 0) = @IsMRO;

						SET @LatestId = @IntegrationMasterId;
						INSERT INTO #tempTableIntegration (ID) VALUES (@LatestId);
					END

					------------------------------------------------------------------
					-- Insert Child Part Detail
					------------------------------------------------------------------
					INSERT INTO [dbo].[PartsBaseChildPartDetail]
					(
						[IntegrationMasterId]
						,[Index]
						,[InventoryId]
						,[AltPartNumber]
						,[Cage]
						,[Condition]
						,[Currency]
						,[Manufacturer]
						,[PartDescription]
						,[PartNumber]
						,[Quantity]
						,[UnitPrice]
						,[UoM]
						,[MasterCompanyId]
						,[CreatedBy]
						,[UpdatedBy]
						,[CreatedDate]
						,[UpdatedDate]
						,[IsDeleted]
						,[IsActive])
				 VALUES
					   (@LatestId
						,@Index
						,@InventoryId
						,@AltPartNumber
						,@Cage
						,@Condition
						,@Currency
						,@Manufacturer
						,@PartDescription
						,@PartNumber
						,@Qty
						,@UnitPrice
						,@UoM
						,@MasterCompanyId
						,@UserName
						,@UserName
						,GETUTCDATE()
						,GETUTCDATE()
						,0
						,1);

					------------------------------------------------------------------
					-- Final SELECT
					------------------------------------------------------------------
					SELECT
						IM.IntegrationMasterId,
						IM.PartNumber,
						IM.PartDescription,
						IM.RepairStation,
						IM.IsRepair,
						IM.PhoneNumber,
						IM.IntegrationPortalId,
						IM.IntegrationPortal,
						0 AS OneFourtyFiveChildPartId,
						'' AS RepairCertiNo,
						OFC.CreatedDate AS LastUpdate,
						OFC.CreatedDate AS QuoteDate,
						OFC.InventoryId,
						OFC.UoM,
						OFC.AltPartNumber,
						OFC.Quantity AS Qty,
						OFC.Cage,
						OFC.Condition,
						'' AS Location,
						IM.MasterCompanyId,
						IM.UpdatedBy,
						IM.UpdatedDate,
						CASE 
							WHEN LOWER(TRIM(IM.PartNumber)) = LOWER(TRIM(IMS.PartNumber))
							THEN IMS.ItemMasterId ELSE 0 
						END AS ItemMasterId,
						0 AS ChildItemMasterId,
						IM.AddressLine1,
						IM.AddressLine2,
						IM.City,
						IM.State,
						IM.PostalCode,
						IM.Country,
						CASE 
							WHEN LOWER(TRIM(CU.Name)) = LOWER(TRIM(IM.RepairStation))
							THEN CU.CustomerId ELSE 0 
						END AS CustomerId,
						IM.IsMRO
					FROM DBO.IntegrationMaster IM WITH (NOLOCK)
					INNER JOIN DBO.PartsBaseChildPartDetail OFC WITH (NOLOCK)
						ON IM.IntegrationMasterId = OFC.IntegrationMasterId
					LEFT JOIN DBO.ItemMaster IMS WITH (NOLOCK)
						ON IM.PartNumber = IMS.PartNumber
					   AND IMS.IsActive = 1
					   AND IMS.IsDeleted = 0
					   AND IM.MasterCompanyId = IMS.MasterCompanyId
					 AND ISNULL(IMS.IsNonStock,0) = 0
					    LEFT JOIN DBO.Customer CU WITH (NOLOCK)
						ON IM.RepairStation = CU.Name
					   AND IM.MasterCompanyId = CU.MasterCompanyId
					   AND CU.IsActive = 1
					   AND CU.IsDeleted = 0
					WHERE IM.IntegrationMasterId IN (SELECT ID FROM #tempTableIntegration);
				END  -- End: PartBase Integration
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