/*************************************************************             
 ** File:   [GetPORODashboardDataCount]             
 ** Author:   Satish Gohil  
 ** Description: This stored procedure is used to display PO/RO records Count
 ** Purpose:           
 ** Date:   18/05/2023     
         
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** PR   Date         Author		Change Description              
 ** --   --------     -------		-------------------------------            
    1    18/05/2023   Satish Gohil    Count Showing issue fixed
	2	 12 NOV 2024  HEMANT SALIYA	  Verify the count AND removed un used code 
	3	 15 jan 2025  BHARGAV SALIYA	 Resolved Count issue 
	4	 05 Jun 2025  Devendra Shekh	 Resolved Count issue for Remaning 

**************************************************************/ 

--exec DBO.GetPORODashboardDataCount @MasterCompanyId=1,@EmployeeId=2

CREATE   PROCEDURE [dbo].[GetPORODashboardDataCount]   
 @MasterCompanyId INT = NULL,  
 @EmployeeId BIGINT = NULL  
AS  
BEGIN  
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
SET NOCOUNT ON  
  
	BEGIN TRY  
	BEGIN  
		DECLARE @Qty AS INT;  
    
		DECLARE @POOpenStatusId AS INT =1  
		DECLARE @POApprovedStatusId AS INT =2  
		DECLARE @POFulfillingStatusId AS INT =3  
		DECLARE @ROOpenStatusId AS INT =1  
		DECLARE @ROApprovedStatusId AS INT =2  
		DECLARE @ROFulfillingStatusId AS INT =3  
  
		DECLARE @POOpenCount AS INT =0  
		DECLARE @POApprovedCount AS INT =0  
		DECLARE @POFulfillmentCount AS INT =0  
		DECLARE @ROOpenCount AS INT =0  
		DECLARE @ROApprovedCount AS INT =0  
		DECLARE @ROFulfillmentCount AS INT =0  
  
		DECLARE @POOpenAmount AS DECIMAL(20, 2);  
		DECLARE @POApprovedAmount AS DECIMAL(20, 2);  
		DECLARE @POFulfillmentAmount AS DECIMAL(20, 2);  
		DECLARE @ROOpenAmount AS DECIMAL(20, 2);  
		DECLARE @ROApprovedAmount AS DECIMAL(20, 2);  
		DECLARE @ROFulfillmentAmount AS DECIMAL(20, 2);  
		DECLARE @POMSModuleID INT = 4;		--(POHeader)
		DECLARE @POModuleId INT =5;			--(POPart)
		DECLARE @ROMSModuleID INT = 24;		--(ROHeader)
		DECLARE @ROModuleId INT =25;		--(ROPart)
     

	    IF OBJECT_ID(N'tempdb..#tmpPurchaseOrderUserRole') IS NOT NULL    
		BEGIN    
			DROP TABLE #tmpPurchaseOrderUserRole
		END
		
		SELECT * INTO #tmpPurchaseOrderUserRole FROM (SELECT DISTINCT MSD.[ReferenceID],RMS.[EntityStructureId] 
			FROM [dbo].PurchaseOrderManagementStructureDetails MSD WITH (NOLOCK)
			INNER JOIN [dbo].[RoleManagementStructure] RMS WITH (NOLOCK) ON MSD.[EntityMsId] = RMS.[EntityStructureId]
			INNER JOIN [dbo].[EmployeeUserRole] EUR WITH (NOLOCK) ON EUR.[RoleId] = RMS.[RoleId]
		WHERE MSD.[ModuleID] = @POMSModuleID AND EUR.[EmployeeId] = @EmployeeId) AS PurchaseOrderUserRole

		IF OBJECT_ID(N'tempdb..#tmpPurchaseOrderPartUserRole') IS NOT NULL    
		BEGIN    
			DROP TABLE #tmpPurchaseOrderPartUserRole
		END
		
		SELECT * INTO #tmpPurchaseOrderPartUserRole FROM (SELECT DISTINCT MSD.[ReferenceID],RMS.[EntityStructureId] 
			FROM [dbo].PurchaseOrderManagementStructureDetails MSD WITH (NOLOCK)
			INNER JOIN [dbo].[RoleManagementStructure] RMS WITH (NOLOCK) ON MSD.[EntityMsId] = RMS.[EntityStructureId]
			INNER JOIN [dbo].[EmployeeUserRole] EUR WITH (NOLOCK) ON EUR.[RoleId] = RMS.[RoleId]
		WHERE MSD.[ModuleID] = @POModuleId AND EUR.[EmployeeId] = @EmployeeId) AS PurchaseOrderUserRole

		IF OBJECT_ID(N'tempdb..#tmpRepairOrderUserRole') IS NOT NULL    
		BEGIN    
			DROP TABLE #tmpRepairOrderUserRole
		END

		SELECT * INTO #tmpRepairOrderUserRole FROM (SELECT DISTINCT MSD.[ReferenceID],RMS.[EntityStructureId] 
			FROM [dbo].RepairOrderManagementStructureDetails MSD WITH (NOLOCK)
			INNER JOIN [dbo].[RoleManagementStructure] RMS WITH (NOLOCK) ON MSD.[EntityMsId] = RMS.[EntityStructureId]
			INNER JOIN [dbo].[EmployeeUserRole] EUR WITH (NOLOCK) ON EUR.[RoleId] = RMS.[RoleId]
		WHERE MSD.[ModuleID] = @ROMSModuleID AND EUR.[EmployeeId] = @EmployeeId) AS PurchaseOrderUserRole

		IF OBJECT_ID(N'tempdb..#tmpRepairOrderPartUserRole') IS NOT NULL    
		BEGIN    
			DROP TABLE #tmpRepairOrderPartUserRole
		END

		SELECT * INTO #tmpRepairOrderPartUserRole FROM (SELECT DISTINCT MSD.[ReferenceID],RMS.[EntityStructureId] 
			FROM [dbo].RepairOrderManagementStructureDetails MSD WITH (NOLOCK)
			INNER JOIN [dbo].[RoleManagementStructure] RMS WITH (NOLOCK) ON MSD.[EntityMsId] = RMS.[EntityStructureId]
			INNER JOIN [dbo].[EmployeeUserRole] EUR WITH (NOLOCK) ON EUR.[RoleId] = RMS.[RoleId]
		WHERE MSD.[ModuleID] = @ROModuleId AND EUR.[EmployeeId] = @EmployeeId) AS PurchaseOrderUserRole
  
		SELECT  @POOpenCount=count(PO.PurchaseOrderId)  FROM   
		DBO.PurchaseOrder PO WITH (NOLOCK)   
			INNER JOIN #tmpPurchaseOrderUserRole MSD WITH (NOLOCK) ON MSD.ReferenceID = PO.PurchaseOrderId  
			LEFT JOIN dbo.PurchaseOrderPart POP  WITH (NOLOCK) ON PO.PurchaseOrderId = POP.PurchaseOrderId  AND isParent = 1
		WHERE  ISNULL(PO.IsDeleted, 0) = 0 AND (PO.StatusId =@POOpenStatusId)  
		AND PO.MasterCompanyId = @MasterCompanyId  
		GROUP BY PO.StatusId  
  
		SELECT @POOpenAmount = SUM(POP.ExtendedCost) 
		FROM DBO.PurchaseOrderPart POP  WITH (NOLOCK) 
			INNER JOIN DBO.PurchaseOrder PO  WITH (NOLOCK) ON PO.PurchaseOrderId = POP.PurchaseOrderId  
			INNER JOIN #tmpPurchaseOrderPartUserRole TMP ON POP.PurchaseOrderPartRecordId = TMP.ReferenceID
			--INNER JOIN dbo.PurchaseOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @POModuleId AND MSD.ReferenceID = POP.PurchaseOrderPartRecordId  
			--INNER JOIN dbo.RoleManagementStructure RMS WITH (NOLOCK) ON POP.ManagementStructureId = RMS.EntityStructureId  
			--INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId  
		WHERE  ISNULL(PO.IsDeleted, 0) = 0 AND ISNULL(POP.isParent, 0) = 1 AND ISNULL(POP.IsDeleted, 0) = 0 AND (PO.StatusId =@POOpenStatusId)  
			AND PO.MasterCompanyId = @MasterCompanyId  
		GROUP BY PO.StatusId  
  
		SELECT  @POApprovedCount=count(PO.PurchaseOrderId)  FROM   
		DBO.PurchaseOrder PO WITH (NOLOCK)   
			INNER JOIN #tmpPurchaseOrderUserRole TMP ON PO.PurchaseOrderId = TMP.ReferenceID
			--INNER JOIN dbo.PurchaseOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @POMSModuleID AND MSD.ReferenceID = PO.PurchaseOrderId  
			--INNER JOIN dbo.RoleManagementStructure RMS WITH (NOLOCK) ON PO.ManagementStructureId = RMS.EntityStructureId  
			--INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId   
			LEFT JOIN dbo.PurchaseOrderPart POP WITH (NOLOCK) ON PO.PurchaseOrderId = POP.PurchaseOrderId  AND isParent = 1
		WHERE ISNULL(PO.IsDeleted, 0) = 0 AND (PO.StatusId =@POApprovedStatusId)  
		AND PO.MasterCompanyId = @MasterCompanyId  
		GROUP BY PO.StatusId  
  
		SELECT @POApprovedAmount = SUM(POP.ExtendedCost)  FROM   
		DBO.PurchaseOrderPart POP WITH (NOLOCK) INNER JOIN DBO.PurchaseOrder PO WITH (NOLOCK) ON PO.PurchaseOrderId = POP.PurchaseOrderId  
		INNER JOIN #tmpPurchaseOrderPartUserRole TMP ON POP.PurchaseOrderPartRecordId = TMP.ReferenceID
		--INNER JOIN dbo.PurchaseOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @POModuleId AND MSD.ReferenceID = POP.PurchaseOrderPartRecordId  
		--INNER JOIN dbo.RoleManagementStructure RMS WITH (NOLOCK) ON POP.ManagementStructureId = RMS.EntityStructureId  
		--INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId
		WHERE ISNULL(PO.IsDeleted, 0) = 0 AND ISNULL(POP.isParent, 0) = 1 AND ISNULL(POP.IsDeleted, 0) = 0 AND (PO.StatusId =@POApprovedStatusId)  
		AND PO.MasterCompanyId = @MasterCompanyId  
		GROUP BY PO.StatusId  
  
		SELECT  @POFulfillmentCount=count(PO.PurchaseOrderId)  FROM   
		DBO.PurchaseOrder PO WITH (NOLOCK)   
		INNER JOIN #tmpPurchaseOrderUserRole TMP ON PO.PurchaseOrderId = TMP.ReferenceID
		--INNER JOIN dbo.PurchaseOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @POMSModuleID AND MSD.ReferenceID = PO.PurchaseOrderId  
		--INNER JOIN dbo.RoleManagementStructure RMS WITH (NOLOCK) ON PO.ManagementStructureId = RMS.EntityStructureId  
		--INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId 
		LEFT JOIN dbo.PurchaseOrderPart POP ON PO.PurchaseOrderId = POP.PurchaseOrderId  AND isParent = 1
		WHERE  ISNULL(PO.IsDeleted, 0) = 0 AND (PO.StatusId =@POFulfillingStatusId)  
		AND PO.MasterCompanyId = @MasterCompanyId  
		GROUP BY PO.StatusId  
  
		SELECT @POFulfillmentAmount = SUM(POP.ExtendedCost)  FROM   
		DBO.PurchaseOrderPart POP WITH (NOLOCK) INNER JOIN DBO.PurchaseOrder PO WITH (NOLOCK) ON PO.PurchaseOrderId = POP.PurchaseOrderId  
		INNER JOIN #tmpPurchaseOrderPartUserRole TMP ON POP.PurchaseOrderPartRecordId = TMP.ReferenceID
		--INNER JOIN dbo.PurchaseOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @POModuleId AND MSD.ReferenceID = POP.PurchaseOrderPartRecordId  
		--INNER JOIN dbo.RoleManagementStructure RMS WITH (NOLOCK) ON POP.ManagementStructureId = RMS.EntityStructureId  
		--INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId  
		WHERE ISNULL(PO.IsDeleted, 0) = 0 AND ISNULL(POP.isParent, 0) = 1 AND ISNULL(POP.IsDeleted, 0) = 0 AND (PO.StatusId =@POFulfillingStatusId)  
		AND PO.MasterCompanyId = @MasterCompanyId  
		GROUP BY PO.StatusId  
  
      
		SELECT @ROOpenCount=count(RO.RepairOrderId)  FROM   
		DBO.RepairOrder RO WITH (NOLOCK)  
		INNER JOIN #tmpRepairOrderUserRole TMP ON RO.RepairOrderId = TMP.ReferenceID
		--INNER JOIN dbo.RepairOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @ROMSModuleID AND MSD.ReferenceID = RO.RepairOrderId  
		--INNER JOIN dbo.RoleManagementStructure RMS WITH (NOLOCK) ON RO.ManagementStructureId = RMS.EntityStructureId  
		--INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId 
		LEFT JOIN  DBO.RepairOrderPart ROP WITH (NOLOCK) ON RO.RepairOrderId = ROP.RepairOrderId AND ISNULL(ROP.isParent, 0) = 1 AND ISNULL(ROP.IsDeleted, 0) = 0
		WHERE ISNULL(RO.IsDeleted, 0) = 0 AND (RO.StatusId = @ROOpenStatusId)  
		AND RO.MasterCompanyId = @MasterCompanyId  
		GROUP BY RO.StatusId  
  
		SELECT @ROOpenAmount = SUM(ROP.ExtendedCost) FROM   
		DBO.RepairOrderPart ROP WITH (NOLOCK) INNER JOIN DBO.RepairOrder RO WITH (NOLOCK) ON RO.RepairOrderId = ROP.RepairOrderId  
		INNER JOIN #tmpRepairOrderPartUserRole TMP ON ROP.RepairOrderPartRecordId = TMP.ReferenceID
		--INNER JOIN dbo.RepairOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @ROModuleId AND MSD.ReferenceID = ROP.RepairOrderPartRecordId  
		--INNER JOIN dbo.RoleManagementStructure RMS WITH (NOLOCK) ON ROP.ManagementStructureId = RMS.EntityStructureId  
		--INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId  
		WHERE ISNULL(RO.IsDeleted, 0) = 0 AND ISNULL(ROP.isParent, 0) = 1 AND ISNULL(ROP.IsDeleted, 0) = 0 AND (RO.StatusId = @ROOpenStatusId)  
		AND RO.MasterCompanyId = @MasterCompanyId  
		GROUP BY RO.StatusId  
  
		SELECT @ROApprovedCount=count(RO.RepairOrderId)  FROM   
		DBO.RepairOrder RO WITH (NOLOCK) 
		INNER JOIN #tmpRepairOrderUserRole TMP ON RO.RepairOrderId = TMP.ReferenceID
		--INNER JOIN dbo.RepairOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @ROMSModuleID AND MSD.ReferenceID = RO.RepairOrderId  
		--INNER JOIN dbo.RoleManagementStructure RMS WITH (NOLOCK) ON RO.ManagementStructureId = RMS.EntityStructureId  
		--INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId 
		LEFT JOIN  DBO.RepairOrderPart ROP WITH (NOLOCK) ON RO.RepairOrderId = ROP.RepairOrderId AND ISNULL(ROP.isParent, 0) = 1 AND ISNULL(ROP.IsDeleted, 0) = 0
		WHERE ISNULL(RO.IsDeleted, 0) = 0 AND (RO.StatusId = @ROApprovedStatusId)  
		AND RO.MasterCompanyId = @MasterCompanyId  
		GROUP BY RO.StatusId  
  
		SELECT @ROApprovedAmount = SUM(ROP.ExtendedCost)  FROM   
		DBO.RepairOrderPart ROP WITH (NOLOCK) INNER JOIN DBO.RepairOrder RO WITH (NOLOCK) ON RO.RepairOrderId = ROP.RepairOrderId  
		INNER JOIN #tmpRepairOrderPartUserRole TMP ON ROP.RepairOrderPartRecordId = TMP.ReferenceID
		--INNER JOIN dbo.RepairOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @ROModuleId AND MSD.ReferenceID = ROP.RepairOrderPartRecordId  
		--INNER JOIN dbo.RoleManagementStructure RMS WITH (NOLOCK) ON ROP.ManagementStructureId = RMS.EntityStructureId  
		--INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId  
		WHERE ISNULL(RO.IsDeleted, 0) = 0 AND ISNULL(ROP.isParent, 0) = 1 AND ISNULL(ROP.IsDeleted, 0) = 0 AND (RO.StatusId = @ROApprovedStatusId)  
		AND RO.MasterCompanyId = @MasterCompanyId  
		GROUP BY RO.StatusId  
   
		SELECT @ROFulfillmentCount=count(RO.RepairOrderId)  FROM   
		DBO.RepairOrder RO WITH (NOLOCK)  
		INNER JOIN #tmpRepairOrderUserRole TMP ON RO.RepairOrderId = TMP.ReferenceID
		--INNER JOIN dbo.RepairOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @ROMSModuleID AND MSD.ReferenceID = RO.RepairOrderId  
		--INNER JOIN dbo.RoleManagementStructure RMS WITH (NOLOCK) ON RO.ManagementStructureId = RMS.EntityStructureId  
		--INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId 
		LEFT JOIN  DBO.RepairOrderPart ROP WITH (NOLOCK) ON RO.RepairOrderId = ROP.RepairOrderId AND ISNULL(ROP.isParent, 0) = 1 AND ISNULL(ROP.IsDeleted, 0) = 0
		Where ISNULL(RO.IsDeleted, 0) = 0 AND (RO.StatusId = @ROFulfillingStatusId)  
		AND RO.MasterCompanyId = @MasterCompanyId  
		GROUP BY RO.StatusId  
  
  
		SELECT @ROFulfillmentAmount = SUM(ROP.ExtendedCost)  FROM   
		DBO.RepairOrderPart ROP WITH (NOLOCK) INNER JOIN DBO.RepairOrder RO WITH (NOLOCK) ON RO.RepairOrderId = ROP.RepairOrderId  
		INNER JOIN #tmpRepairOrderPartUserRole TMP ON ROP.RepairOrderPartRecordId = TMP.ReferenceID
		--INNER JOIN dbo.RepairOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @ROModuleId AND MSD.ReferenceID = ROP.RepairOrderPartRecordId  
		--INNER JOIN dbo.RoleManagementStructure RMS WITH (NOLOCK) ON ROP.ManagementStructureId = RMS.EntityStructureId  
		--INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId  
		WHERE ISNULL(RO.IsDeleted, 0) = 0 AND ISNULL(ROP.isParent, 0) = 1 AND ISNULL(ROP.IsDeleted, 0) = 0 AND (RO.StatusId = @ROFulfillingStatusId)  
		AND RO.MasterCompanyId = @MasterCompanyId  
		GROUP BY RO.StatusId  
  
		SELECT ISNULL(@POOpenCount, 0) AS 'POOpenCount', ISNULL(@POApprovedCount, 0) AS 'POApprovedCount', ISNULL(@POFulfillmentCount, 0) AS 'POFulfillmentCount',   
		ISNULL(@ROOpenCount, 0) AS 'ROOpenCount', ISNULL(@ROApprovedCount, 0) AS 'ROApprovedCount', ISNULL(@ROFulfillmentCount, 0) AS 'ROFulfillmentCount',   
		ISNULL(@POOpenAmount, 0) AS 'POOpenAmount', ISNULL(@POApprovedAmount, 0) 'POApprovedAmount',  
		ISNULL(@POFulfillmentAmount, 0) AS 'POFulfillmentAmount', ISNULL(@ROOpenAmount, 0) AS 'ROOpenAmount', ISNULL(@ROApprovedAmount, 0) AS 'ROApprovedAmount', ISNULL(@ROFulfillmentAmount, 0) AS 'ROFulfillmentAmount'  
	END  
 END TRY      
 BEGIN CATCH        
	DECLARE	@ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()  
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
            , @AdhocComments     VARCHAR(150)    = 'GetPORODashboardDataCount'   
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '  
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