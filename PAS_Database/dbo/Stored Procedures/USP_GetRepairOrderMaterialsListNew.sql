/*************************************************************           
 ** File:   [USP_GetRepairOrderMaterialsListNew]           
 ** Author:   Abhishek Jirawla
 ** Description: This stored procedure is used retrieve Repair Order Materials List With Pagination
 ** Purpose:         
 ** Date:   08/05/2024        
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author					Change Description            
 ** --   --------     -------				--------------------------------          
    1	08/05/2024    Abhishek Jirawla			Created
	
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetRepairOrderMaterialsListNew]
(    
	@PageNumber INT,  
	@PageSize INT,  
	@SortColumn VARCHAR(50) = NULL,  
	@SortOrder INT,  
	@RepairOrderId BIGINT = NULL
)    
AS    
BEGIN    

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON    

	BEGIN TRY
		--BEGIN TRANSACTION
			BEGIN  
				--Local Param For Reading SP Params Values : Start
				DECLARE @Local_PageNumber int, @Local_PageSize int, @Local_SortColumn varchar(50)=null, @Local_SortOrder int, @Local_RepairOrderId BIGINT = NULL, @Local_WFWOId BIGINT  = NULL, @Local_ShowPendingToIssue BIT  = 0;
				SELECT @Local_PageNumber = @PageNumber,
					@Local_PageSize = @PageSize, @Local_SortColumn = @SortColumn, @Local_SortOrder = @SortOrder, 
					@Local_RepairOrderId = @RepairOrderId
				--Local Param For Reading SP Params Values : End

				DECLARE @RecordFrom int;  
				DECLARE @MasterCompanyId INT;
				DECLARE @Count Int;  ;
				DECLARE @ModuleId BIGINT;

				IF @Local_SortColumn IS NULL
				BEGIN  
					SET @Local_SortColumn = ('PartNumber')
				END

				SELECT @MasterCompanyId = MasterCompanyId FROM dbo.RepairOrder WITH (NOLOCK) WHERE RepairOrderId = @Local_RepairOrderId;
				SELECT @ModuleId = ManagementStructureModuleId FROM dbo.ManagementStructureModule WITH (NOLOCK) WHERE ModuleName = 'ROPart';
				
				SET @RecordFrom = (@Local_PageNumber-1)*@Local_PageSize;  

				IF OBJECT_ID(N'tempdb..#TMPROPartParentListData') IS NOT NULL
				BEGIN
				DROP TABLE #TMPROPartParentListData
				END

				IF OBJECT_ID(N'tempdb..#TMPROPartResultListData') IS NOT NULL
				BEGIN
				DROP TABLE #TMPROPartResultListData
				END

				CREATE TABLE #TMPROPartParentListData
				(
					[ParentID] BIGINT NOT NULL IDENTITY, 						 
					[RepairOrderPartRecordId] [bigint] NULL,
				)

				--Inserting Data For Parent Level- For Pagination : Start
				INSERT INTO #TMPROPartParentListData
				([RepairOrderPartRecordId])
				SELECT DISTINCT	[RepairOrderPartRecordId] FROM [DBO].[RepairOrderPart] WOM WITH(NOLOCK) WHERE WOM.IsDeleted = 0 AND WOM.IsParent = 1 AND WOM.RepairOrderId = @RepairOrderId

				SELECT * INTO #TMPROPartResultListData FROM #TMPROPartParentListData tmp 
				ORDER BY tmp.RepairOrderPartRecordId ASC
				OFFSET @RecordFrom ROWS   
				FETCH NEXT @Local_PageSize ROWS ONLY
				--Inserting Data For Parent Level- For Pagination : End

				IF OBJECT_ID(N'tempdb..#RepairOrderParts') IS NOT NULL
				BEGIN
				DROP TABLE #RepairOrderParts
				END
				
				-- Temporary table to store the main parts
				CREATE TABLE #RepairOrderParts (
					RepairOrderPartRecordId BIGINT,
					RepairOrderId BIGINT,
					PartNumber VARCHAR(250),
					SerialNumber VARCHAR(30),
					ManufacturerPN VARCHAR(250),
					AssetModel VARCHAR(250),
					AssetClass VARCHAR(250),
					ItemMasterId BIGINT,
					ManufacturerId BIGINT,
					GLAccountId BIGINT,
					UOMId BIGINT,
					NeedByDate DATETIME2,
					ConditionId BIGINT,
					QuantityOrdered INT,
					QuantityBackOrdered INT,
					QuantityRejected INT,
					QuantityDrafted INT,
					QuantityRepaired INT,
					UnitCost DECIMAL(18, 2),
					VendorListPrice DECIMAL(18, 2),
					DiscountAmount DECIMAL(18, 2),
					DiscountPercent VARCHAR(100),
					ExtendedCost DECIMAL(18, 2),
					FunctionalCurrencyId INT,
					ReportCurrencyId INT,
					ForeignExchangeRate DECIMAL(18, 6),
					WorkOrderId BIGINT,
					SubWorkOrderId BIGINT,
					SalesOrderId BIGINT,
					ManagementStructureId BIGINT,
					Memo VARCHAR(MAX),
					MasterCompanyId BIGINT,
					CreatedBy VARCHAR(255),
					CreatedDate DATETIME2,
					UpdatedBy VARCHAR(255),
					UpdatedDate DATETIME2,
					IsActive BIT,
					DiscountPerUnit DECIMAL(18, 2),
					AltEquiPartNumberId VARCHAR(255),
					PriorityId BIGINT,
					StockType VARCHAR(255),
					StockLineId VARCHAR(255),
					RevisedPartId VARCHAR(255),
					RevisedPartNumber VARCHAR(200),
					WorkPerformedId BIGINT,
					EstRecordDate DATETIME2,
					VendorQuoteNoId INT,
					VendorQuoteDate DATETIME,
					ACTailNum VARCHAR(200),
					QuantityReserved INT,
					ItemType VARCHAR(200),
					ItemTypeId BIGINT,
					isAsset BIT,
					PartDescription VARCHAR(255),
					AltEquiPartNumber VARCHAR(200),
					AltEquiPartDescription VARCHAR(255),
					ControlId VARCHAR(255),
					ControlNumber VARCHAR(200),
					IsLotAssigned BIT,
					LotId BIGINT,
					TraceableTo BIGINT,
					TraceableToName VARCHAR(200),
					TraceableToType BIGINT,
					TagTypeId BIGINT,
					TaggedBy BIGINT,
					TaggedByName VARCHAR(200),
					TaggedByType BIGINT,
					TaggedByTypeName VARCHAR(200),
					TagDate DATETIME2,
					AllMSlevels VARCHAR(MAX),
					LastMSLevel VARCHAR(200),
					ROChargesCount INT,
					ROFrightsCount INT
				);

				IF OBJECT_ID(N'tempdb..#RepairOrderSplitParts') IS NOT NULL
				BEGIN
				DROP TABLE #RepairOrderSplitParts
				END

				-- Temporary table to store the split parts
				CREATE TABLE #RepairOrderSplitParts (
					RepairOrderPartRecordId BIGINT,
					ItemMasterId BIGINT,
					ManagementStructureId BIGINT,
					NeedByDate DATETIME2,
					RoPartSplitAddressId BIGINT,
					RoPartSplitUserId BIGINT,
					RoPartSplitUserTypeId BIGINT,
					RoPartSplitSiteId BIGINT,
					RoPartSplitSiteName VARCHAR(200),
					RepairOrderId BIGINT,
					QuantityOrdered INT,
					QuantityBackOrdered INT,
					QuantityRejected INT,
					QuantityDrafted INT,
					QuantityRepaired INT,
					UOMId BIGINT,
					RoPartSplitAddress1 VARCHAR(200),
					RoPartSplitAddress2 VARCHAR(200),
					RoPartSplitAddress3 VARCHAR(200),
					RoPartSplitCity VARCHAR(200),
					RoPartSplitStateOrProvince VARCHAR(200),
					RoPartSplitCountryId BIGINT,
					RoPartSplitPostalCode VARCHAR(200),
					PriorityId BIGINT,
					IsLotAssigned BIT,
					LotId BIGINT,
					ParentId BIGINT
				);

				-- Insert the main parts into the temporary table
				INSERT INTO #RepairOrderParts
				SELECT 
					pop.RepairOrderPartRecordId,
					pop.RepairOrderId,
					ISNULL(
					CASE WHEN pop.isAsset = 1 
						THEN (SELECT AssetId FROM Asset WHERE AssetRecordId = pop.ItemMasterId)
						ELSE (SELECT PartNumber FROM ItemMaster WHERE ItemMasterId = pop.ItemMasterId)
					END, '') AS PartNumber,
					pop.SerialNumber,
					pop.ManufacturerPN,
					pop.AssetModel,
					pop.AssetClass,
					pop.ItemMasterId,
					pop.ManufacturerId,
					pop.GLAccountId,
					pop.UOMId,
					pop.NeedByDate,
					pop.ConditionId,
					pop.QuantityOrdered,
					pop.QuantityBackOrdered,
					pop.QuantityRejected,
					ISNULL((
						CASE 
							WHEN pop.isAsset = 1 THEN (
								SELECT SUM(Qty)
								FROM AssetInventoryDraft
								WHERE RepairOrderPartRecordId = pop.RepairOrderPartRecordId 
									AND IsDeleted = 0 
									AND IsParent = 1 
									AND StklineNumber <> null AND StklineNumber <> ''
									AND IsActive = 1
									AND IsDeleted = 0
							)
							ELSE (
								SELECT SUM(Quantity)
								FROM StockLineDraft
								WHERE RepairOrderPartRecordId = pop.RepairOrderPartRecordId 
									AND IsDeleted = 0 
									AND IsParent = 1 
									AND (StockLineId = 0 OR StockLineId IS NULL)
							)
						END
					), 0) AS QuantityDrafted,
					ISNULL((
						CASE 
							WHEN pop.isAsset = 1 THEN (
								SELECT SUM(Qty) FROM AssetInventory WHERE RepairOrderPartRecordId = pop.RepairOrderPartRecordId AND IsDeleted = 0 AND IsParent = 1
							)
							ELSE (
								SELECT SUM(Quantity)
								FROM StockLine
								WHERE RepairOrderPartRecordId = pop.RepairOrderPartRecordId 
									AND IsDeleted = 0 
									AND IsParent = 1
							)
						END
					), 0) AS QuantityRepaired,
					pop.UnitCost,
					pop.VendorListPrice,
					pop.DiscountAmount,
					pop.DiscountPercent,
					pop.ExtendedCost,
					pop.FunctionalCurrencyId,
					pop.ReportCurrencyId,
					pop.ForeignExchangeRate,
					pop.WorkOrderId,
					pop.SubWorkOrderId,
					pop.SalesOrderId,
					pop.ManagementStructureId,
					pop.Memo,
					pop.MasterCompanyId,
					pop.CreatedBy,
					pop.CreatedDate,
					pop.UpdatedBy,
					pop.UpdatedDate,
					pop.IsActive,
					pop.DiscountPerUnit,
					pop.AltEquiPartNumberId,
					pop.PriorityId,
					pop.StockType,
					pop.StockLineId,
					pop.RevisedPartId,
					ISNULL((
						CASE 
							WHEN pop.isAsset = 1 THEN (
								SELECT AssetId
								FROM Asset
								WHERE AssetRecordId = pop.RevisedPartId
							)
							ELSE (
								SELECT PartNumber
								FROM ItemMaster
								WHERE ItemMasterId = pop.RevisedPartId
							)
						END
					), '') AS RevisedPartNumber,
					pop.WorkPerformedId,
					pop.EstRecordDate,
					pop.VendorQuoteNoId,
					pop.VendorQuoteDate,
					pop.ACTailNum,
					pop.QuantityReserved,
					pop.ItemType,
					pop.ItemTypeId,
					pop.isAsset,
					pop.PartDescription,
					pop.AltEquiPartNumber,
					pop.AltEquiPartDescription,
					pop.ControlId,
					pop.ControlNumber,
					pop.IsLotAssigned,
					pop.LotId,
					pop.TraceableTo,
					pop.TraceableToName,
					pop.TraceableToType,
					pop.TagTypeId,
					pop.TaggedBy,
					pop.TaggedByName,
					pop.TaggedByType,
					pop.TaggedByTypeName,
					pop.TagDate,
					popms.AllMSlevels,
					popms.LastMSLevel,
					(SELECT COUNT(*) FROM RepairOrderFreight WHERE RepairOrderPartRecordId = pop.RepairOrderPartRecordId AND IsDeleted = 0) AS ROChargesCount,
					(SELECT COUNT(*) FROM RepairOrderCharges WHERE RepairOrderPartRecordId = pop.RepairOrderPartRecordId AND IsDeleted = 0) AS ROFrightsCount
				FROM 
					RepairOrderPart pop
				LEFT JOIN RepairOrderManagementStructureDetails AS popms ON popms.ReferenceID = pop.RepairOrderPartRecordId AND popms.ModuleID = @ModuleId
				WHERE 
					pop.RepairOrderId = @RepairOrderId AND pop.IsDeleted = 0 AND pop.IsParent = 1
					AND pop.RepairOrderPartRecordId IN (SELECT RepairOrderPartRecordId FROM #TMPROPartResultListData);

				-- Insert the split parts into the temporary table
				INSERT INTO #RepairOrderSplitParts
				SELECT 
					splitPart.RepairOrderPartRecordId,
					splitPart.ItemMasterId,
					splitPart.ManagementStructureId,
					splitPart.NeedByDate,
					splitPart.RoPartSplitAddressId,
					splitPart.RoPartSplitUserId,
					splitPart.RoPartSplitUserTypeId,
					splitPart.RoPartSplitSiteId,
					splitPart.RoPartSplitSiteName,
					splitPart.RepairOrderId,
					splitPart.QuantityOrdered,
					splitPart.QuantityBackOrdered,
					splitPart.QuantityRejected,
					ISNULL((
						SELECT SUM(Quantity)
						FROM StockLineDraft
						WHERE RepairOrderPartRecordId = splitPart.RepairOrderPartRecordId 
							AND IsDeleted = 0 
							AND IsParent = 1 
							AND (StockLineId = 0 OR StockLineId IS NULL)
					), 0) AS QuantityDrafted,
					ISNULL((
						SELECT SUM(Quantity)
						FROM StockLine
						WHERE RepairOrderPartRecordId = splitPart.RepairOrderPartRecordId 
							AND IsDeleted = 0 
							AND IsParent = 1
					), 0) AS QuantityRepaired,
					splitPart.UOMId,
					splitPart.RoPartSplitAddress1,
					splitPart.RoPartSplitAddress2,
					splitPart.RoPartSplitAddress3,
					splitPart.RoPartSplitCity,
					splitPart.RoPartSplitStateOrProvince,
					splitPart.RoPartSplitCountryId,
					splitPart.RoPartSplitPostalCode,
					splitPart.PriorityId,
					splitPart.IsLotAssigned,
					splitPart.LotId,
					splitPart.ParentId
				FROM 
					RepairOrderPart splitPart
				WHERE 
					splitPart.ParentId IN (SELECT RepairOrderPartRecordId FROM #RepairOrderParts) 
					AND splitPart.IsParent = 0 
					AND splitPart.IsDeleted = 0;


				SELECT @Count = COUNT(ParentID) from #TMPROPartParentListData;

				SELECT *, @Count As NumberOfItems FROM #RepairOrderParts
				ORDER BY    
					--CASE WHEN (@Local_SortOrder=1 and @Local_SortColumn='taskName')  THEN taskName END ASC,
					CASE WHEN (@Local_SortOrder=1 and @Local_SortColumn='PartNumber')  THEN PartNumber END ASC ,
					CASE WHEN (@Local_SortOrder=1 and @Local_SortColumn='AltEquiPartNumber')  THEN AltEquiPartNumber END ASC,  
					CASE WHEN (@Local_SortOrder=1 and @Local_SortColumn='PartDescription')  THEN PartDescription END ASC,  
					CASE WHEN (@Local_SortOrder=1 and @Local_SortColumn='ManufacturerPN')  THEN ManufacturerPN END ASC,  
					CASE WHEN (@Local_SortOrder=1 and @Local_SortColumn='ConditionId')  THEN ConditionId END ASC,    
					CASE WHEN (@Local_SortOrder=1 and @Local_SortColumn='QuantityReserved')  THEN QuantityReserved END ASC,
					CASE WHEN (@Local_SortOrder=1 and @Local_SortColumn='UOMId')  THEN UOMId END ASC,  
					CASE WHEN (@Local_SortOrder=1 and @Local_SortColumn='StockType')  THEN StockType END ASC,  
					--CASE WHEN (@Local_SortOrder=1 and @Local_SortColumn='needDate')  THEN needDate END ASC,  
					CASE WHEN (@Local_SortOrder=1 and @Local_SortColumn='FunctionalCurrencyId') THEN FunctionalCurrencyId END ASC,  
					CASE WHEN (@Local_SortOrder=1 and @Local_SortColumn='UnitCost')  THEN UnitCost END ASC,  
					CASE WHEN (@Local_SortOrder=1 and @Local_SortColumn='ExtendedCost')  THEN ExtendedCost END ASC, 
					CASE WHEN (@Local_SortOrder=1 and @Local_SortColumn='Memo')  THEN Memo END ASC,  

					--CASE WHEN (@Local_SortOrder=1 and @Local_SortColumn='taskName')  THEN taskName END ASC,
					CASE WHEN (@Local_SortOrder=-1 and @Local_SortColumn='PartNumber')  THEN PartNumber END DESC,  
					CASE WHEN (@Local_SortOrder=-1 and @Local_SortColumn='AltEquiPartNumber')  THEN AltEquiPartNumber END DESC,  
					CASE WHEN (@Local_SortOrder=-1 and @Local_SortColumn='PartDescription')  THEN PartDescription END DESC,  
					CASE WHEN (@Local_SortOrder=-1 and @Local_SortColumn='ManufacturerPN')  THEN ManufacturerPN END DESC,  
					CASE WHEN (@Local_SortOrder=-1 and @Local_SortColumn='ConditionId')  THEN ConditionId END DESC,    
					CASE WHEN (@Local_SortOrder=-1 and @Local_SortColumn='QuantityReserved')  THEN QuantityReserved END DESC,
					CASE WHEN (@Local_SortOrder=-1 and @Local_SortColumn='UOMId')  THEN UOMId END DESC,  
					CASE WHEN (@Local_SortOrder=-1 and @Local_SortColumn='StockType')  THEN StockType END DESC,  
					--CASE WHEN (@Local_SortOrde-r=1 and @Local_SortColumn='needDate')  THEN needDate END ASC,  
					CASE WHEN (@Local_SortOrder=-1 and @Local_SortColumn='FunctionalCurrencyId') THEN FunctionalCurrencyId END DESC,  
					CASE WHEN (@Local_SortOrder=-1 and @Local_SortColumn='UnitCost')  THEN UnitCost END DESC,  
					CASE WHEN (@Local_SortOrder=-1 and @Local_SortColumn='ExtendedCost')  THEN ExtendedCost END DESC, 
					CASE WHEN (@Local_SortOrder=-1 and @Local_SortColumn='Memo')  THEN Memo END DESC

					SELECT * FROM #RepairOrderSplitParts
				
				IF OBJECT_ID(N'tempdb..#RepairOrderParts') IS NOT NULL
				BEGIN
				    DROP TABLE #RepairOrderParts;
				END

				IF OBJECT_ID(N'tempdb..#RepairOrderSplitParts') IS NOT NULL
				BEGIN
					DROP TABLE #RepairOrderSplitParts;
				END
			END
		--COMMIT  TRANSACTION
		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				--ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetWorkOrderMaterialsListNew' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@RepairOrderId, '')
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