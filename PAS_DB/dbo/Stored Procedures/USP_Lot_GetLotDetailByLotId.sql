
/*************************************************************           
 ** File:   [USP_Lot_GetLotDetailByLotId]           
 ** Author: Rajesh Gami
 ** Description: This stored procedure is used to Get Lot detail by id
 ** Date:   30/03/2023
 ** PARAMETERS:           
 ** RETURN VALUE:
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author  		Change Description            
 ** --   --------     -------		---------------------------     
    1    30/03/2023   Rajesh Gami     Created
**************************************************************
 EXEC USP_Lot_GetLotDetailByLotId 2 
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_Lot_GetLotDetailByLotId] 
@LotId bigint =0
AS
BEGIN
  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  BEGIN TRY
  BEGIN TRANSACTION
	BEGIN
		DECLARE @AppModuleCustomerId INT = 0;
		DECLARE @AppModuleVendorId INT = 0;
		DECLARE @AppModuleCompanyId INT = 0;
		DECLARE @AppModuleOthersId INT = 0;   	
		SELECT @AppModuleCustomerId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE ModuleName = 'Customer';
		SELECT @AppModuleVendorId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE ModuleName = 'Vendor';
		SELECT @AppModuleCompanyId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE ModuleName = 'Company';
		SELECT @AppModuleOthersId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE ModuleName = 'Others';
		IF (@LotId >0)
		BEGIN
		    SELECT 
				LT.[LotId] LotId
			   ,LT.LotNumber LotNumber
			   ,LT.LotName LotName
			   ,ISNULL((Select top 1 ISNULL(VendorId,0) from dbo.PurchaseOrder po WITH(NOLOCK) Where po.PurchaseOrderId = Lt.InitialPOId AND ISNULL(po.IsDeleted,0) = 0),0) AS VendorId
			   ,(Select top 1 ISNULL(ven.VendorName,'') from dbo.PurchaseOrder po WITH(NOLOCK) INNER JOIN dbo.Vendor ven WITH(NOLOCK) on po.VendorId = ven.VendorId Where po.PurchaseOrderId = Lt.InitialPOId AND ISNULL(po.IsDeleted,0) = 0) AS VendorName
			   ,ISNULL((Select top 1 ISNULL(PurchaseOrderNumber,'') from dbo.PurchaseOrder po WITH(NOLOCK) Where po.PurchaseOrderId = Lt.InitialPOId AND ISNULL(po.IsDeleted,0) = 0),'') AS ReferenceNumber
			   ,LT.OpenDate
			   --,ISNULL(LT.OriginalCost,0.00)OriginalCost
			   ,LT.LotStatusId
			   ,S.StatusName
			   ,LT.ConsignmentId
			   ,LC.ConsignmentNumber
			   ,LC.ConsigneeName
			   ,LT.EmployeeId
			   ,(R.FirstName +' '+ R.LastName)EmployeeName
			   ,LT.ObtainFromId
			   --,LT.ObtainFromTypeId
			   ,(CASE WHEN LT.ObtainFromTypeId IS NULL AND (Select Count(purchaseOrderid) from dbo.PurchaseOrder po WITH(NOLOCK) Where po.LotId = Lt.LotId AND ISNULL(po.IsDeleted,0) = 0) >0 THEN  @AppModuleVendorId ELSE LT.ObtainFromTypeId END) ObtainFromTypeId
			   ,LT.TraceableToId
			   --,LT.TraceableToTypeId
			   ,(CASE WHEN LT.TraceableToTypeId IS NULL AND (Select Count(purchaseOrderid) from dbo.PurchaseOrder po WITH(NOLOCK) Where po.LotId = Lt.LotId AND ISNULL(po.IsDeleted,0) = 0) >0 THEN  @AppModuleVendorId ELSE LT.TraceableToTypeId END) TraceableToTypeId
			   ,(CASE WHEN LT.[ObtainFromTypeId] = @AppModuleCustomerId THEN CU.[Name] 
						    WHEN LT.[ObtainFromTypeId] = @AppModuleVendorId THEN VE.[VendorName]
						    WHEN LT.[ObtainFromTypeId] = @AppModuleCompanyId THEN CO.[Name]	
						    WHEN LT.[ObtainFromTypeId] = @AppModuleOthersId THEN LD.[ObtainFromName]
							END) AS ObtainFromName
				,(CASE WHEN LT.[TraceableToTypeId] = @AppModuleCustomerId THEN CUT.[Name] 
						    WHEN LT.[TraceableToTypeId] = @AppModuleVendorId THEN VET.[VendorName]
						    WHEN LT.[TraceableToTypeId] = @AppModuleCompanyId THEN CTT.[Name]	
						    WHEN LT.[TraceableToTypeId] = @AppModuleOthersId THEN LD.TraceableToName
							END) AS TraceableToName
			   ,LT.ManagementStructureId
			   ,LT.[MasterCompanyId]
			   ,LT.[CreatedBy]
			   ,LT.[UpdatedBy]
			   ,LT.[CreatedDate]
			   ,LT.[UpdatedDate]
			   ,LT.InitialPOCost AS OriginalCost
			   --,ISNULL((SELECT TOP 1 ISNULL(OriginalCost,0) FROM DBO.LotCalculationDetails LCD WHERE LCD.LotId = LD.LotId ORDER BY LCD.LotCalculationId DESC),0) AS OriginalCost
				FROM [dbo].[Lot] LT 
				INNER JOIN dbo.LotDetail LD WITH(NOLOCK) on LT.LotId = LD.LotId
				--LEFT JOIN [dbo].[Vendor] V WITH(NOLOCK) ON LT.[VendorId] = V.[VendorId] 
				LEFT JOIN [dbo].[Employee] R WITH(NOLOCK) ON LT.[EmployeeId] = R.[EmployeeId]
				LEFT JOIN [dbo].[LotStatus] S WITH(NOLOCK) ON LT.[LotStatusId] = S.[LotStatusId]
				LEFT JOIN [dbo].[Customer] CU WITH (NOLOCK) ON CU.[CustomerId] = LT.[ObtainFromId]
				LEFT JOIN [dbo].[Vendor] VE WITH (NOLOCK) ON VE.[VendorId] = LT.[ObtainFromId]
				LEFT JOIN [dbo].[LegalEntity] CO WITH (NOLOCK) ON CO.[LegalEntityId] = LT.[ObtainFromId]
				LEFT JOIN [dbo].[Customer] CUT WITH (NOLOCK) ON CUT.[CustomerId] = LT.[TraceableToId]
				LEFT JOIN [dbo].[Vendor] VET WITH (NOLOCK) ON VET.[VendorId] = LT.[TraceableToId]
				LEFT JOIN [dbo].[LegalEntity] CTT WITH (NOLOCK) ON CTT.[LegalEntityId] = LT.[TraceableToId]
				LEFT JOIN [dbo].[LotConsignment] LC WITH (NOLOCK) ON LT.ConsignmentId = LC.ConsignmentId
			WHERE LT.LotId = @LotId AND ISNULL(LT.IsDeleted,0) = 0 AND ISNULL(LT.IsActive,1) = 1		  
		END
		
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
            ,@AdhocComments varchar(150) = '[USP_Lot_GetLotDetailLotId]',
            @ProcedureParameters varchar(3000) = '@LotId = ''' + CAST(ISNULL(@LotId, '') AS varchar(100)),
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