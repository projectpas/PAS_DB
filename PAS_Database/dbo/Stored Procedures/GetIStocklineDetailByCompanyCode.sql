/*************************************************************             
 ** File:   [GetIStocklineDetailByCompanyCode]            
 ** Author:  RAJESH GAMI
 ** Description: This stored procedure is used to get stockline details by company code
 ** Purpose:           
 ** Date:  09 Mar 2026        
            
 ** PARAMETERS: @companyCode VARCHAR(30)  
           
 ** RETURN VALUE:             
 **************************************************************             
 ** Change History             
 **************************************************************             
 ** PR   Date			 Author			Change Description              
 ** --   --------		-------			--------------------------------            
    1    09 Mar 2026		RAJESH GAMI	 Created  
**************************************************************
 EXEC GetIStocklineDetailByCompanyCode 'SA'
**************************************************************/
CREATE       PROCEDURE [dbo].[GetIStocklineDetailByCompanyCode] 
 @companyCode VARCHAR(30),
 @stocklineId bigint =NULL
AS
BEGIN
  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  BEGIN TRY
  BEGIN TRANSACTION
	BEGIN
					DECLARE @MasterCompanyId BIGINT = (SELECT TOP 1  MasterCompanyId FROM Dbo.MasterCompany WITH(NOLOCK) WHERE MasterCompanyCode = @companyCode)
					DECLARE @StocklineMSModuleId INT = 0;
		DECLARE @CustomerModuleId INT=0,@VendorModuleId INT=0,@CompanyModuleId INT=0,@OthersModuleId INT=0;
		DECLARE @CustomerModuleName VARCHAR(50)='',@VendorModuleName VARCHAR(50)='',@CompanyModuleName VARCHAR(50)='',@OthersModuleName VARCHAR(50)=''; 		
		
		SELECT @CustomerModuleId = [ModuleId] , @CustomerModuleName = [ModuleName] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName]  = 'Customer';
		SELECT @VendorModuleId = [ModuleId] , @VendorModuleName = [ModuleName] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName]  = 'Vendor';
		SELECT @CompanyModuleId = [ModuleId] , @CompanyModuleName = [ModuleName] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName]  = 'Company';
		SELECT @OthersModuleId = [ModuleId] , @OthersModuleName = [ModuleName] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName]  = 'Others';


		SELECT @StocklineMSModuleId = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE [ModuleName] = 'Stockline';

			SELECT 
				  stl.StockLineId
				, stl.PartNumber AS [Part Number]
				, stl.PNDescription AS [Part Description]
				, stl.Manufacturer
				, stl.StockLineNumber AS [StockLine Number]
				, stl.ControlNumber AS [Control Number]
				, stl.IdNumber AS [Control Id Number]
				, stl.Condition
				, stl.SerialNumber AS [Serial Number]
				, stl.ExpirationDate AS [Expiration Date]
				, stl.ReceivedDate AS [Received Date]
				, ISNULL(po.PurchaseOrderNumber,'') AS [PurchaseOrder Number]
				, ISNULL(ro.RepairOrderNumber,'') AS [RepairOrder Number]
				, stl.WorkOrderNumber AS [WorkOrder Number]
				, stl.ReceiverNumber AS [Receiver Number]

				, CASE 
					WHEN stl.OwnerType = @CustomerModuleId THEN cust.Name
					WHEN stl.OwnerType = @VendorModuleId THEN ven.VendorName
					WHEN stl.OwnerType = @CompanyModuleId THEN com.Name
					WHEN stl.OwnerType = @OthersModuleId THEN stl.OwnerName
					ELSE ''
				  END AS [Owner Name]

				, CASE 
					WHEN stl.TraceableToType = @CustomerModuleId THEN custTTN.Name
					WHEN stl.TraceableToType = @VendorModuleId THEN venTTN.VendorName
					WHEN stl.TraceableToType = @CompanyModuleId THEN comTTN.Name
					WHEN stl.TraceableToType = @OthersModuleId THEN stl.TraceableToName
					ELSE ''
				  END AS [Traceable To Name]

				, CASE 
					WHEN stl.ObtainFromType = @CustomerModuleId THEN custOBF.Name
					WHEN stl.ObtainFromType = @VendorModuleId THEN venOBF.VendorName
					WHEN stl.ObtainFromType = @CompanyModuleId THEN comOBF.Name
					WHEN stl.ObtainFromType = @OthersModuleId THEN stl.ObtainFromName
					ELSE ''
				  END AS [Obtain From Name]

				, ISNULL(stl.Quantity,0) AS Quantity
				, stl.QuantityOnHand AS [Quantity On Hand]
				, ISNULL(stl.QuantityReserved,0) AS [Quantity Reserved]
				, ISNULL(stl.QuantityIssued,0) AS [Quantity Issued]
				, ISNULL(stl.QuantityAvailable,0) AS [Quantity Available]

				, ROUND(ISNULL(stl.PurchaseOrderUnitCost,0),2) AS [PurchaseOrder UnitCost]
				, ROUND(ISNULL(stl.RepairOrderUnitCost,0),2) AS [RepairOrder UnitCost]
				, stl.UnitCost
				, uom.ShortName AS [Unit Of Measure]

				, CASE WHEN ISNULL(stl.IsCustomerStock,0) = 1 THEN 'Yes' ELSE 'No' END AS [Customer Stock]
				, CASE WHEN stl.IsSerialized = 1 THEN 'Yes' ELSE 'No' END AS Serialized
				, CASE WHEN ISNULL(stl.IsStkTimeLife, im.IsTimeLife) = 1 THEN 'Yes' ELSE 'No' END AS IsTimeLife

				, CASE 
					WHEN stl.IsPma = 1 AND stl.IsDER = 1 THEN 'PMA&DER'
					WHEN stl.IsPma = 1 AND stl.IsDER = 0 THEN 'PMA'
					WHEN stl.IsPma = 0 AND stl.IsDER = 1 THEN 'DER'
					WHEN ISNULL(stl.OEM,'') <> '' THEN 'OEM'
					ELSE ''
				  END AS [Stock Type]

				, stl.Site
				, stl.Warehouse
				, stl.Location
				, stl.ItemGroup
				, ISNULL(iaty.Name,'') AS [Acquisition Type]
				, ROUND(ISNULL(stl.Adjustment,0),2) AS Adjustment

			FROM dbo.StockLine stl WITH(NOLOCK)
			INNER JOIN dbo.ItemMaster im WITH(NOLOCK)	ON stl.ItemMasterId = im.ItemMasterId
			INNER JOIN dbo.StocklineManagementStructureDetails msd WITH(NOLOCK)	ON stl.StockLineId = msd.ReferenceID AND msd.ModuleID = @StocklineMSModuleId
			LEFT JOIN dbo.PurchaseOrder po WITH(NOLOCK)	ON stl.PurchaseOrderId = po.PurchaseOrderId
			LEFT JOIN dbo.RepairOrder ro WITH(NOLOCK)ON stl.RepairOrderId = ro.RepairOrderId
			LEFT JOIN dbo.AssetAcquisitionType iaty WITH(NOLOCK) ON stl.AcquistionTypeId = iaty.AssetAcquisitionTypeId
			LEFT JOIN dbo.Customer cust WITH(NOLOCK) ON cust.CustomerId = stl.Owner
			LEFT JOIN dbo.Vendor ven WITH(NOLOCK) ON ven.VendorId = stl.Owner
			LEFT JOIN dbo.LegalEntity com WITH(NOLOCK)	ON com.LegalEntityId = stl.Owner
			LEFT JOIN dbo.Customer custTTN WITH(NOLOCK) ON custTTN.CustomerId = stl.TraceableTo
			LEFT JOIN dbo.Vendor venTTN WITH(NOLOCK)ON venTTN.VendorId = stl.TraceableTo
			LEFT JOIN dbo.LegalEntity comTTN WITH(NOLOCK)ON comTTN.LegalEntityId = stl.TraceableTo
			LEFT JOIN dbo.Customer custOBF WITH(NOLOCK)	ON custOBF.CustomerId = stl.ObtainFrom
			LEFT JOIN dbo.Vendor venOBF WITH(NOLOCK) ON venOBF.VendorId = stl.ObtainFrom
			LEFT JOIN dbo.LegalEntity comOBF WITH(NOLOCK)ON comOBF.LegalEntityId = stl.ObtainFrom
			LEFT JOIN dbo.UnitOfMeasure uom WITH(NOLOCK)ON stl.PurchaseUnitOfMeasureId = uom.UnitOfMeasureId
			WHERE 
				stl.MasterCompanyId = @MasterCompanyId
				AND stl.IsDeleted = 0
				AND (@stocklineId IS NULL OR stl.StockLineId = @stocklineId);
		
	END
	COMMIT  TRANSACTION
  END TRY
  BEGIN CATCH
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
		DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            ,@AdhocComments varchar(150) = '[GetIStocklineDetailByCompanyCode]',
            @ProcedureParameters varchar(3000) = '@companyCode = ''' + CAST(ISNULL(@companyCode, '') AS varchar(100)),
            @ApplicationName varchar(100) = 'PAS'
    -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
    EXEC spLogException @DatabaseName = @DatabaseName,
                        @AdhocComments = @AdhocComments,
                        @ProcedureParameters = @ProcedureParameters,
                        @ApplicationName = @ApplicationName,
                        @ErrorLogID = @ErrorLogID OUTPUT;
    RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
    RETURN (1);
  END CATCH
END