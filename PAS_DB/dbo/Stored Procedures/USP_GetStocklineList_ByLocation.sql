/*************************************************************               
 ** File:   [USP_GetStocklineList_ByLocation]               
 ** Author:   Sumit Kumar
 ** Description: Stored procedure to get stockline list filtered by exact Location, Shelf, or Bin label value
 ** Purpose:             
 ** Date:   17/06/2026
 **********************
 ** Change History
 **********************
 ** PR   Date        Author          Change Description
 ** --   --------    -------         --------------------------------
 ** 1    17/06/2026  Sumit Kumar     Created get stockline list filtered by exact Location, Shelf, or Bin label value
 2    09/July/2026  RAJESH GAMI     [PN-17009] - Merge Non-Stock Inventory to Stockline : Get only Stock Inventory Data Where IsNonStock = 0
 **************************************************************/
 
CREATE PROCEDURE [dbo].[USP_GetStocklineList_ByLocation]
	@PageNumber int = NULL,        
	@PageSize int = NULL,        
	@SortColumn varchar(50) = NULL,        
	@SortOrder int = NULL,        
	@Location varchar(100) = NULL,
	@Shelf varchar(100) = NULL,
	@Bin varchar(100) = NULL,
	@EmployeeId BIGINT = NULL,     
	@MasterCompanyId BIGINT = NULL
AS        
BEGIN         
     SET NOCOUNT ON;        
     DECLARE @RecordFROM INT;        
     DECLARE @MSModuelId int = 2; -- For Stockline        
     DECLARE @Count Int;        
     DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';
     DECLARE @BaseUtcOffsetSec INT;
     DECLARE @AttachmentModuleId INT = 0;
     DECLARE @isElse bit = 1; -- Show both customer and non-customer stock
     DECLARE @StockLineIds varchar(1000) = NULL;
     DECLARE @ItemMasterId BIGINT = 0;
     
     SELECT 
         @CurrntEmpTimeZoneDesc = COALESCE(
             ETZ.[Description],
             LTZ.[Description]
         )
     FROM 
         dbo.Employee E WITH (NOLOCK) 
     LEFT JOIN 
         dbo.TimeZone ETZ WITH (NOLOCK) ON E.TimeZoneId = ETZ.TimeZoneId
     LEFT JOIN 
         dbo.LegalEntity LE WITH (NOLOCK) ON E.LegalEntityId = LE.LegalEntityId
     LEFT JOIN 
         dbo.TimeZone LTZ WITH (NOLOCK) ON LE.TimeZoneId = LTZ.TimeZoneId
     WHERE E.EmployeeId = @EmployeeId;
     
     SET @RecordFROM = (@PageNumber - 1) * @PageSize;         
     SELECT @AttachmentModuleId = [AttachmentModuleId] FROM [DBO].[AttachmentModule] WITH(NOLOCK) WHERE [Name] = 'StockLine';
     
     SELECT TOP 1 @BaseUtcOffsetSec = BaseUtcOffsetSec  
     FROM dbo.TimeZone WITH(NOLOCK)  
     WHERE [Description] = @CurrntEmpTimeZoneDesc 
     
     IF @SortColumn IS NULL        
     BEGIN        
         SET @SortColumn = Upper('CreatedDate')        
     END         
     ELSE        
     BEGIN         
         Set @SortColumn = Upper(@SortColumn)        
     END         

     BEGIN TRY        
         ;WITH Result AS(        
             SELECT DISTINCT stl.StockLineId,            
                 (ISNULL(stl.ItemMasterId,0)) 'ItemMasterId',        
                 (ISNULL(stl.PartNumber,'')) 'MainPartNumber',        
                 (ISNULL(stl.PNDescription,'')) 'PartDescription',        
                 (ISNULL(stl.Manufacturer,'')) 'Manufacturer',          
                 (ISNULL(RevicedPNNumber,'')) 'RevisedPN',                  
                 (ISNULL(stl.ItemGroup,'')) 'ItemGroup',         
                 (ISNULL(stl.UnitOfMeasure,'')) 'UnitOfMeasure',
                 CAST(stl.QuantityOnHand AS varchar) 'QuantityOnHand',        
                 stl.QuantityOnHand as QuantityOnHandnew,        
                 CAST(stl.QuantityAvailable AS varchar) 'QuantityAvailable',        
                 stl.QuantityAvailable as QuantityAvailablenew,        
                 CAST(stl.QuantityReserved AS varchar) 'QuantityReserved',        
                 stl.QuantityReserved as QuantityReservednew,        
                 (ISNULL(stl.SerialNumber,'')) 'SerialNumber',        
                 (ISNULL(stl.StockLineNumber,'')) 'StocklineNumber',         
                 stl.ControlNumber,        
                 stl.IdNumber,        
                 (ISNULL(stl.Condition,'')) 'Condition',                 
                 (ISNULL(stl.ReceivedDate,'')) 'ReceivedDate',        
                 (ISNULL(stl.ShippingReference,'')) 'AWB',               
                 (ISNULL(stl.ExpirationDate,'')) 'ExpirationDate',        
                 (ISNULL(stl.TagDate,'')) 'TagDate',        
                 (ISNULL(stl.TaggedByName,'')) 'TaggedByName',        
                 (ISNULL(stl.TagType,'')) 'TagType',         
                 (ISNULL(stl.TraceableToName,'')) 'TraceableToName',                
                 (ISNULL(stl.itemType,'')) 'ItemCategory',         
                 stl.ItemTypeId,       
                 stl.IsActive,                             
                 stl.CreatedDate,        
                 stl.CreatedBy,        
                 stl.PartCertificationNumber,        
                 stl.CertifiedBy,        
                 stl.CertifiedDate,        
                 CASE WHEN CAST(stl.UpdatedDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE Cast(stl.UpdatedDate AS DATE) END UpdatedDate,
                 stl.UpdatedBy,        
                 stl.level1 AS CompanyName,        
                 stl.level2 AS BuName,        
                 stl.level3 AS DivName,        
                 stl.level4 AS DeptName,         
                 CASE WHEN stl.IsCustomerStock = 1 THEN 'Yes' ELSE 'No' END AS IsCustomerStock,
                 CASE WHEN stl.[IsTurnIn] = 1 THEN 'Yes' ELSE 'No' END AS IsTurnIn,
                 CASE WHEN ISNULL(stl.IsStkTimeLife,0) = 0 THEN 'No' ELSE 'Yes' END AS IsTimeLife,
                 CASE WHEN ISNULL(stl.IsCustomerStock, 0) = 1 AND ISNULL(stl.QuantityAvailable, 0) > 0 THEN 1 ELSE (CASE WHEN ISNULL(stl.customerId,0) > 0 AND ISNULL(stl.QuantityAvailable, 0) > 0 THEN 1 ELSE 0 END) END AS 'IsAllowCreateWO',     
                 stl.ObtainFromName AS obtainFrom,        
                 stl.OwnerName AS ownerName,        
                 MSD.LastMSLevel,        
                 MSD.AllMSlevels,        
                 stl.WorkOrderId,        
                 stl.WorkOrderNumber,      
                 stl.Location,    
                 stl.LocationId,
                 stl.Shelf,
                 stl.ShelfId,
                 stl.Bin,
                 stl.BinId,
                 stl.LotNumber,
                 Stl.Site,
                 Stl.SiteId,
                 Stl.Warehouse,
                 stl.CustomerName 'CustomerName',
                 ISNULL(stl.CustomerId,0) as CustomerId,
                 '' as WorkOrderStage,
                 ISNULL(stl.PurchaseOrderNumber,'') AS 'PONumber',
                 ISNULL(stl.RepairOrderNumber,'') AS 'RONumber',
                 ISNULL(stl.ReceiverNumber,'') as 'ReceiverNumber',
                 CAST(stl.QuantityAdjustment AS varchar) 'QuantityAdjustment',
                 CASE WHEN ISNULL(STL.IsDocument, 0) = 0 THEN 'No' ELSE 'Yes' END AS 'IsDocument',
                 CASE WHEN stl.IsRepairManagement = 1 THEN 'Yes' ELSE 'No' END AS IsRepairManagement,
                 ISNULL(stl.[IsBatchStock],0) [IsBatchStock],
                 stl.[BatchNumber],
                 stl.[UnitCost] UnitCost,
                 -- ISNULL(uom.DecimalPlaces,2) DecimalPlaces,
                 -- ISNULL(uom.Class,'Decimal') Class,
                 stl.[InventoryGLAccName] AS 'GLAccount',
                 CASE 
                     WHEN stl.[IsPMA] = 1 THEN 'PMA'
                     WHEN stl.[IsDER] = 1 THEN 'DER'
                     WHEN stl.[OEM] = 1 THEN 'OEM'
                     ELSE ''
                 END AS 'PNSource'
                 -- stl.Model
             FROM DBO.StockLine stl WITH (NOLOCK)    
             INNER JOIN dbo.StocklineManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @MSModuelId AND MSD.ReferenceID = stl.StockLineId        
             INNER JOIN dbo.RoleManagementStructure RMS WITH (NOLOCK) ON stl.ManagementStructureId = RMS.EntityStructureId
             INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId
             WHERE stl.MasterCompanyId = @MasterCompanyId 
               AND ISNULL(stl.IsParent, 0) = 1 
               AND ISNULL(stl.IsDeleted, 0) = 0
               AND (@Location IS NULL OR @Location = '' OR stl.Location = @Location)
               AND (@Shelf IS NULL OR @Shelf = '' OR stl.Shelf = @Shelf)
               AND (@Bin IS NULL OR @Bin = '' OR stl.Bin = @Bin)
               AND stl.QuantityOnHand > 0 AND ISNULL(stl.IsNonStock,0) = 0
         ), ResultCount AS(Select COUNT(StockLineId) AS totalItems FROM Result)        
         SELECT *,
             (SELECT TOP 1 wos.Status FROM DBO.WorkOrder wo WITH (NOLOCK) inner join DBO.WorkOrderStatus wos WITH (NOLOCK) on wo.WorkOrderStatusId=wos.Id where wo.WorkOrderId=WorkOrderId) as WorkOrderStatus,        
             (SELECT TOP 1 isnull(RS.WorkOrderId,0) FROM DBO.ReceivingCustomerWork RS WITH (NOLOCK) where RS.StockLineId=r.StockLineId) as rsworkOrderId INTO #TempResult FROM Result r         
         
         SELECT @Count = COUNT(StockLineId) FROM #TempResult       		
         
         SELECT *, @Count AS NumberOfItems FROM #TempResult ORDER BY          
             CASE WHEN (@SortOrder=1 AND @SortColumn='MainPartNumber') THEN MainPartNumber END ASC,        
             CASE WHEN (@SortOrder=-1 AND @SortColumn='MainPartNumber') THEN MainPartNumber END DESC,        
             CASE WHEN (@SortOrder=1 AND @SortColumn='PartDescription') THEN PartDescription END ASC,        
             CASE WHEN (@SortOrder=-1 AND @SortColumn='PartDescription') THEN PartDescription END DESC,        
             CASE WHEN (@SortOrder=1 AND @SortColumn='Manufacturer') THEN Manufacturer END ASC,        
             CASE WHEN (@SortOrder=-1 AND @SortColumn='Manufacturer') THEN Manufacturer END DESC,           
             CASE WHEN (@SortOrder=1 AND @SortColumn='RevisedPN') THEN RevisedPN END ASC,        
             CASE WHEN (@SortOrder=-1 AND @SortColumn='RevisedPN') THEN RevisedPN END DESC,        
             CASE WHEN (@SortOrder=1 AND @SortColumn='ItemGroup') THEN ItemGroup END ASC,        
             CASE WHEN (@SortOrder=-1 AND @SortColumn='ItemGroup') THEN ItemGroup END DESC,        
             CASE WHEN (@SortOrder=1 AND @SortColumn='UnitOfMeasure') THEN UnitOfMeasure END ASC,        
             CASE WHEN (@SortOrder=-1 AND @SortColumn='UnitOfMeasure') THEN UnitOfMeasure END DESC,            
             CASE WHEN (@SortOrder=1 AND @SortColumn='QuantityOnHand') THEN QuantityOnHandnew END ASC,        
             CASE WHEN (@SortOrder=-1 AND @SortColumn='QuantityOnHand') THEN QuantityOnHandnew END DESC,         
             CASE WHEN (@SortOrder=1 AND @SortColumn='QuantityAvailable') THEN QuantityAvailablenew END ASC,        
             CASE WHEN (@SortOrder=-1 AND @SortColumn='QuantityAvailable') THEN QuantityAvailablenew END DESC,         
             CASE WHEN (@SortOrder=1 AND @SortColumn='QuantityReserved') THEN QuantityReservednew END ASC,        
             CASE WHEN (@SortOrder=-1 AND @SortColumn='QuantityReserved') THEN QuantityReservednew END DESC,        
             CASE WHEN (@SortOrder=1 AND @SortColumn='SerialNumber') THEN SerialNumber END ASC,        
             CASE WHEN (@SortOrder=-1 AND @SortColumn='SerialNumber') THEN SerialNumber END DESC,        
             CASE WHEN (@SortOrder=1 AND @SortColumn='StocklineNumber') THEN StocklineNumber END ASC,        
             CASE WHEN (@SortOrder=-1 AND @SortColumn='StocklineNumber') THEN StocklineNumber END DESC,           
             CASE WHEN (@SortOrder=1 AND @SortColumn='ControlNumber') THEN ControlNumber END ASC,        
             CASE WHEN (@SortOrder=-1 AND @SortColumn='ControlNumber') THEN ControlNumber END DESC,        
             CASE WHEN (@SortOrder=1 AND @SortColumn='TaggedByName') THEN TaggedByName END ASC,        
             CASE WHEN (@SortOrder=-1 AND @SortColumn='TaggedByName') THEN TaggedByName END DESC,         
             CASE WHEN (@SortOrder=1 AND @SortColumn='TagType') THEN TagType END ASC,        
             CASE WHEN (@SortOrder=-1 AND @SortColumn='TagType') THEN TagType END DESC,         
             CASE WHEN (@SortOrder=1 AND @SortColumn='TraceableToName') THEN TraceableToName END ASC,        
             CASE WHEN (@SortOrder=-1 AND @SortColumn='TraceableToName') THEN TraceableToName END DESC,        
             CASE WHEN (@SortOrder=1 AND @SortColumn='IdNumber') THEN IdNumber END ASC,        
             CASE WHEN (@SortOrder=-1 AND @SortColumn='IdNumber') THEN IdNumber END DESC,         
             CASE WHEN (@SortOrder=1 AND @SortColumn='Condition') THEN Condition END ASC,        
             CASE WHEN (@SortOrder=-1 AND @SortColumn='Condition') THEN Condition END DESC,         
             CASE WHEN (@SortOrder=1 AND @SortColumn='ReceivedDate') THEN ReceivedDate END ASC,        
             CASE WHEN (@SortOrder=-1 AND @SortColumn='ReceivedDate') THEN ReceivedDate END DESC,        
             CASE WHEN (@SortOrder=1 AND @SortColumn='ExpirationDate') THEN ExpirationDate END ASC,        
             CASE WHEN (@SortOrder=-1 AND @SortColumn='ExpirationDate') THEN ExpirationDate END DESC,           
             CASE WHEN (@SortOrder=1 AND @SortColumn='TagDate') THEN TagDate END ASC,        
             CASE WHEN (@SortOrder=-1 AND @SortColumn='TagDate') THEN TagDate END DESC,         
             CASE WHEN (@SortOrder=1 AND @SortColumn='ItemCategory') THEN ItemCategory END ASC,        
             CASE WHEN (@SortOrder=-1 AND @SortColumn='ItemCategory') THEN ItemCategory END DESC,        
             CASE WHEN (@SortOrder=1 AND @SortColumn='CompanyName') THEN CompanyName END ASC,        
             CASE WHEN (@SortOrder=-1 AND @SortColumn='CompanyName') THEN CompanyName END DESC,        
             CASE WHEN (@SortOrder=1 AND @SortColumn='BuName') THEN BuName END ASC,        
             CASE WHEN (@SortOrder=-1 AND @SortColumn='BuName') THEN BuName END DESC,        
             CASE WHEN (@SortOrder=1 AND @SortColumn='DivName') THEN DivName END ASC,        
             CASE WHEN (@SortOrder=-1 AND @SortColumn='DivName') THEN DivName END DESC,        
             CASE WHEN (@SortOrder=1 AND @SortColumn='DeptName') THEN DeptName END ASC,        
             CASE WHEN (@SortOrder=-1 AND @SortColumn='DeptName') THEN DeptName END DESC,        
             CASE WHEN (@SortOrder=1 AND @SortColumn='CreatedDate') THEN CreatedDate END ASC,        
             CASE WHEN (@SortOrder=-1 AND @SortColumn='CreatedDate') THEN CreatedDate END DESC,        
             CASE WHEN (@SortOrder=1 AND @SortColumn='PartCertificationNumber') THEN PartCertificationNumber END ASC,        
             CASE WHEN (@SortOrder=-1 AND @SortColumn='PartCertificationNumber') THEN PartCertificationNumber END DESC,        
             CASE WHEN (@SortOrder=1 AND @SortColumn='CertifiedBy') THEN CertifiedBy END ASC,        
             CASE WHEN (@SortOrder=-1 AND @SortColumn='CertifiedBy') THEN CertifiedBy END DESC,         
             CASE WHEN (@SortOrder=1 AND @SortColumn='CertifiedDate') THEN CertifiedDate END ASC,        
             CASE WHEN (@SortOrder=-1 AND @SortColumn='CertifiedDate') THEN CertifiedDate END DESC,         
             CASE WHEN (@SortOrder=1 AND @SortColumn='IsCustomerStock') THEN IsCustomerStock END ASC,        
             CASE WHEN (@SortOrder=-1 AND @SortColumn='IsCustomerStock') THEN IsCustomerStock END DESC,
             CASE WHEN (@SortOrder=1 AND @SortColumn='IsTurnIn') THEN IsTurnIn END ASC,        
             CASE WHEN (@SortOrder=-1 AND @SortColumn='IsTurnIn') THEN IsTurnIn END DESC,      
             CASE WHEN (@SortOrder=1 AND @SortColumn='UpdatedBy') THEN UpdatedBy END ASC,        
             CASE WHEN (@SortOrder=-1 AND @SortColumn='UpdatedBy') THEN UpdatedBy END DESC,        
             CASE WHEN (@SortOrder=1 AND @SortColumn='UpdatedDate') THEN UpdatedDate END ASC,        
             CASE WHEN (@SortOrder=-1 AND @SortColumn='UpdatedDate') THEN UpdatedDate END DESC,         
             CASE WHEN (@SortOrder=1 AND @SortColumn='obtainFrom') THEN obtainFrom END ASC,        
             CASE WHEN (@SortOrder=-1 AND @SortColumn='obtainFrom') THEN obtainFrom END DESC,              
             CASE WHEN (@SortOrder=1 and @SortColumn='LASTMSLEVEL') THEN LastMSLevel END ASC,        
             CASE WHEN (@SortOrder=-1 and @SortColumn='LASTMSLEVEL') THEN LastMSLevel END DESC,        
             CASE WHEN (@SortOrder=1 and @SortColumn='WorkOrderStage') THEN WorkOrderStage END ASC,        
             CASE WHEN (@SortOrder=-1 and @SortColumn='WorkOrderStage') THEN WorkOrderStage END DESC,        
             CASE WHEN (@SortOrder=1 AND @SortColumn='ownerName') THEN ownerName END ASC,        
             CASE WHEN (@SortOrder=-1 AND @SortColumn='ownerName') THEN ownerName END DESC,    
             CASE WHEN (@SortOrder=1 AND @SortColumn='Location') THEN Location END ASC,        
             CASE WHEN (@SortOrder=-1 AND @SortColumn='Location') THEN Location END DESC,
             CASE WHEN (@SortOrder=1 AND @SortColumn='Site') THEN Site END ASC,        
             CASE WHEN (@SortOrder=-1 AND @SortColumn='Site') THEN Site END DESC,
             CASE WHEN (@SortOrder=1 AND @SortColumn='Warehouse') THEN Warehouse END ASC,        
             CASE WHEN (@SortOrder=-1 AND @SortColumn='Warehouse') THEN Warehouse END DESC,
             CASE WHEN (@SortOrder=1 AND @SortColumn='Shelf') THEN Shelf END ASC,        
             CASE WHEN (@SortOrder=-1 AND @SortColumn='Shelf') THEN Shelf END DESC,
             CASE WHEN (@SortOrder=1 AND @SortColumn='Bin') THEN Bin END ASC,        
             CASE WHEN (@SortOrder=-1 AND @SortColumn='Bin') THEN Bin END DESC,
             CASE WHEN (@SortOrder=1 AND @SortColumn='IsTimeLife') THEN IsTimeLife END ASC,        
             CASE WHEN (@SortOrder=-1 AND @SortColumn='IsTimeLife') THEN IsTimeLife END DESC,
             CASE WHEN (@SortOrder=1 AND @SortColumn='CustomerName') THEN CustomerName END ASC,        
             CASE WHEN (@SortOrder=-1 AND @SortColumn='CustomerName') THEN CustomerName END DESC,
             CASE WHEN (@SortOrder=1 AND @SortColumn='PONumber') THEN PONumber END ASC,        
             CASE WHEN (@SortOrder=-1 AND @SortColumn='PONumber') THEN PONumber END DESC,
             CASE WHEN (@SortOrder=1 AND @SortColumn='RONumber') THEN RONumber END ASC,        
             CASE WHEN (@SortOrder=-1 AND @SortColumn='RONumber') THEN RONumber END DESC,
             CASE WHEN (@SortOrder=1 AND @SortColumn='ReceiverNumber') THEN ReceiverNumber END ASC,        
             CASE WHEN (@SortOrder=-1 AND @SortColumn='ReceiverNumber') THEN ReceiverNumber END DESC,
             CASE WHEN (@SortOrder=1 AND @SortColumn='QuantityAdjustment') THEN QuantityAdjustment END ASC,        
             CASE WHEN (@SortOrder=-1 AND @SortColumn='QuantityAdjustment') THEN QuantityAdjustment END DESC,
             CASE WHEN (@SortOrder=1 AND @SortColumn='IsDocument') THEN IsDocument END ASC,        
             CASE WHEN (@SortOrder=-1 AND @SortColumn='IsDocument') THEN IsDocument END DESC,
             CASE WHEN (@SortOrder=1 AND @SortColumn='IsRepairManagement') THEN IsDocument END ASC,        
             CASE WHEN (@SortOrder=-1 AND @SortColumn='IsRepairManagement') THEN IsDocument END DESC,
             CASE WHEN (@SortOrder=1 AND @SortColumn='BATCHNUMBER') THEN BatchNumber END ASC,
             CASE WHEN (@SortOrder=-1 AND @SortColumn='BATCHNUMBER') THEN BatchNumber END DESC,
             CASE WHEN (@SortOrder=1 AND @SortColumn='UnitCost') THEN CAST(UnitCost AS varchar(20)) END ASC,
             CASE WHEN (@SortOrder=-1 AND @SortColumn='UnitCost') THEN CAST(UnitCost AS varchar(20)) END DESC,
             CASE WHEN (@SortOrder=1 AND @SortColumn='GLAccount') THEN GLAccount END ASC,        
             CASE WHEN (@SortOrder=-1 AND @SortColumn='GLAccount') THEN GLAccount END DESC,
             CASE WHEN (@SortOrder=1 AND @SortColumn='PNSource') THEN PNSource END ASC,        
             CASE WHEN (@SortOrder=-1 AND @SortColumn='PNSource') THEN PNSource END DESC
             -- CASE WHEN (@SortOrder=1 AND @SortColumn='Model') THEN Model END ASC,        
             -- CASE WHEN (@SortOrder=-1 AND @SortColumn='Model') THEN Model END DESC
             
         OFFSET @RecordFROM ROWS         
         FETCH NEXT @PageSize ROWS ONLY        
         
     END TRY        
      BEGIN CATCH          
          DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name() 
          , @AdhocComments VARCHAR(150) = 'USP_GetStocklineList_ByLocation' 
          , @ProcedureParameters VARCHAR(3000) = CONCAT(
              'PageNumber = ', ISNULL(CAST(@PageNumber AS VARCHAR(10)), 'null'), 
              ', PageSize = ', ISNULL(CAST(@PageSize AS VARCHAR(10)), 'null'), 
              ', SortColumn = ', ISNULL(@SortColumn, 'null'), 
              ', SortOrder = ', ISNULL(CAST(@SortOrder AS VARCHAR(10)), 'null'), 
              ', Location = ', ISNULL(@Location, 'null'), 
              ', Shelf = ', ISNULL(@Shelf, 'null'), 
              ', Bin = ', ISNULL(@Bin, 'null'), 
              ', EmployeeId = ', ISNULL(CAST(@EmployeeId AS VARCHAR(10)), 'null'), 
              ', MasterCompanyId = ', ISNULL(CAST(@MasterCompanyId AS VARCHAR(10)), 'null')
          )
          , @ApplicationName varchar(100) = 'PAS'
          
          EXEC spLogException @DatabaseName = @DatabaseName,    
                              @AdhocComments = @AdhocComments,    
                              @ProcedureParameters = @ProcedureParameters,    
                              @ApplicationName = @ApplicationName,    
                              @ErrorLogID = @ErrorLogID OUTPUT;    
          RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)    
      END CATCH
END