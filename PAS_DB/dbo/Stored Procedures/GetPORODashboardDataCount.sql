CREATE PROCEDURE [dbo].[GetPORODashboardDataCount] 
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
		DECLARE @POModuleId int =5;
		DECLARE @ROModuleId int =25;
		DECLARE @POMSModuleID INT = 4;
		DECLARE @ROMSModuleID INT = 24;
			

		SELECT  @POOpenCount=count(PO.PurchaseOrderId)  FROM 
				DBO.PurchaseOrder PO 
			    INNER JOIN dbo.PurchaseOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @POMSModuleID AND MSD.ReferenceID = PO.PurchaseOrderId
			    INNER JOIN dbo.RoleManagementStructure RMS WITH (NOLOCK) ON PO.ManagementStructureId = RMS.EntityStructureId
			    INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId			  
				Where  (PO.IsDeleted = 0) and (PO.StatusId =@POOpenStatusId)
				AND PO.MasterCompanyId = @MasterCompanyId
				GROUP BY PO.StatusId

		SELECT @POOpenAmount = SUM(POP.ExtendedCost) FROM 
				DBO.PurchaseOrderPart POP INNER JOIN DBO.PurchaseOrder PO ON PO.PurchaseOrderId = POP.PurchaseOrderId
				INNER JOIN dbo.PurchaseOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @POModuleId AND MSD.ReferenceID = POP.PurchaseOrderPartRecordId
	            INNER JOIN dbo.RoleManagementStructure RMS WITH (NOLOCK) ON POP.ManagementStructureId = RMS.EntityStructureId
	            INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId
				Where  (PO.IsDeleted = 0) and POP.isParent=1 and (POP.IsDeleted = 0) and (PO.StatusId =@POOpenStatusId)
				AND PO.MasterCompanyId = @MasterCompanyId
				GROUP BY PO.StatusId

	   SELECT  @POApprovedCount=count(PO.PurchaseOrderId)  FROM 
				DBO.PurchaseOrder PO 
				INNER JOIN dbo.PurchaseOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @POMSModuleID AND MSD.ReferenceID = PO.PurchaseOrderId
			    INNER JOIN dbo.RoleManagementStructure RMS WITH (NOLOCK) ON PO.ManagementStructureId = RMS.EntityStructureId
			    INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId	
				Where  (PO.IsDeleted = 0) and (PO.StatusId =@POApprovedStatusId)
				AND PO.MasterCompanyId = @MasterCompanyId
				GROUP BY PO.StatusId

	  SELECT @POApprovedAmount = SUM(POP.ExtendedCost)  FROM 
				DBO.PurchaseOrderPart POP INNER JOIN DBO.PurchaseOrder PO ON PO.PurchaseOrderId = POP.PurchaseOrderId
				INNER JOIN dbo.PurchaseOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @POModuleId AND MSD.ReferenceID = POP.PurchaseOrderPartRecordId
	            INNER JOIN dbo.RoleManagementStructure RMS WITH (NOLOCK) ON POP.ManagementStructureId = RMS.EntityStructureId
	            INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId
				Where (PO.IsDeleted = 0) and POP.isParent=1 and (POP.IsDeleted = 0) and (PO.StatusId =@POApprovedStatusId)
				AND PO.MasterCompanyId = @MasterCompanyId
				GROUP BY PO.StatusId

	 SELECT  @POFulfillmentCount=count(PO.PurchaseOrderId)  FROM 
				DBO.PurchaseOrder PO 
				INNER JOIN dbo.PurchaseOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @POMSModuleID AND MSD.ReferenceID = PO.PurchaseOrderId
			    INNER JOIN dbo.RoleManagementStructure RMS WITH (NOLOCK) ON PO.ManagementStructureId = RMS.EntityStructureId
			    INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId	
				Where  (PO.IsDeleted = 0) and (PO.StatusId =@POFulfillingStatusId)
				AND PO.MasterCompanyId = @MasterCompanyId
				GROUP BY PO.StatusId

       SELECT @POFulfillmentAmount = SUM(POP.ExtendedCost)  FROM 
				DBO.PurchaseOrderPart POP INNER JOIN DBO.PurchaseOrder PO ON PO.PurchaseOrderId = POP.PurchaseOrderId
				INNER JOIN dbo.PurchaseOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @POModuleId AND MSD.ReferenceID = POP.PurchaseOrderPartRecordId
	            INNER JOIN dbo.RoleManagementStructure RMS WITH (NOLOCK) ON POP.ManagementStructureId = RMS.EntityStructureId
	            INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId
				Where (PO.IsDeleted = 0) and POP.isParent=1 and (POP.IsDeleted = 0) and (PO.StatusId =@POFulfillingStatusId)
				AND PO.MasterCompanyId = @MasterCompanyId
				GROUP BY PO.StatusId

				
	   SELECT @ROOpenCount=count(RO.RepairOrderId)  FROM 
			    DBO.RepairOrder RO
			   INNER JOIN dbo.RepairOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @ROMSModuleID AND MSD.ReferenceID = RO.RepairOrderId
			   INNER JOIN dbo.RoleManagementStructure RMS WITH (NOLOCK) ON RO.ManagementStructureId = RMS.EntityStructureId
			   INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId		
				Where (RO.IsDeleted = 0) and (RO.StatusId = @ROOpenStatusId)
				AND RO.MasterCompanyId = @MasterCompanyId
				GROUP BY RO.StatusId

	   SELECT @ROOpenAmount = SUM(ROP.ExtendedCost) FROM 
				DBO.RepairOrderPart ROP INNER JOIN DBO.RepairOrder RO ON RO.RepairOrderId = ROP.RepairOrderId
				INNER JOIN dbo.RepairOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @ROModuleId AND MSD.ReferenceID = ROP.RepairOrderPartRecordId
	            INNER JOIN dbo.RoleManagementStructure RMS WITH (NOLOCK) ON ROP.ManagementStructureId = RMS.EntityStructureId
	            INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId
				Where (RO.IsDeleted = 0) and ROP.isParent=1 and (ROP.IsDeleted = 0) and (RO.StatusId = @ROOpenStatusId)
				AND RO.MasterCompanyId = @MasterCompanyId
				GROUP BY RO.StatusId

	  SELECT @ROApprovedCount=count(RO.RepairOrderId)  FROM 
			    DBO.RepairOrder RO
			   INNER JOIN dbo.RepairOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @ROMSModuleID AND MSD.ReferenceID = RO.RepairOrderId
			   INNER JOIN dbo.RoleManagementStructure RMS WITH (NOLOCK) ON RO.ManagementStructureId = RMS.EntityStructureId
			   INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId	
				Where (RO.IsDeleted = 0) and (RO.StatusId = @ROApprovedStatusId)
				AND RO.MasterCompanyId = @MasterCompanyId
				GROUP BY RO.StatusId

	  SELECT @ROApprovedAmount = SUM(ROP.ExtendedCost)  FROM 
				DBO.RepairOrderPart ROP INNER JOIN DBO.RepairOrder RO ON RO.RepairOrderId = ROP.RepairOrderId
				INNER JOIN dbo.RepairOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @ROModuleId AND MSD.ReferenceID = ROP.RepairOrderPartRecordId
	            INNER JOIN dbo.RoleManagementStructure RMS WITH (NOLOCK) ON ROP.ManagementStructureId = RMS.EntityStructureId
	            INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId
				Where (RO.IsDeleted = 0) and ROP.isParent=1 and (ROP.IsDeleted = 0) and (RO.StatusId = @ROApprovedStatusId)
				AND RO.MasterCompanyId = @MasterCompanyId
				GROUP BY RO.StatusId
	
	SELECT @ROFulfillmentCount=count(RO.RepairOrderId)  FROM 
			    DBO.RepairOrder RO
			   INNER JOIN dbo.RepairOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @ROMSModuleID AND MSD.ReferenceID = RO.RepairOrderId
			   INNER JOIN dbo.RoleManagementStructure RMS WITH (NOLOCK) ON RO.ManagementStructureId = RMS.EntityStructureId
			   INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId	
				Where (RO.IsDeleted = 0) and (RO.StatusId = @ROFulfillingStatusId)
				AND RO.MasterCompanyId = @MasterCompanyId
				GROUP BY RO.StatusId


	 SELECT @ROFulfillmentAmount = SUM(ROP.ExtendedCost)  FROM 
				DBO.RepairOrderPart ROP INNER JOIN DBO.RepairOrder RO ON RO.RepairOrderId = ROP.RepairOrderId
				INNER JOIN dbo.RepairOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @ROModuleId AND MSD.ReferenceID = ROP.RepairOrderPartRecordId
	            INNER JOIN dbo.RoleManagementStructure RMS WITH (NOLOCK) ON ROP.ManagementStructureId = RMS.EntityStructureId
	            INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId
				Where (RO.IsDeleted = 0) and ROP.isParent=1 and (ROP.IsDeleted = 0) and (RO.StatusId = @ROFulfillingStatusId)
				AND RO.MasterCompanyId = @MasterCompanyId
				GROUP BY RO.StatusId

		

		SELECT ISNULL(@POOpenCount, 0) AS 'POOpenCount', ISNULL(@POApprovedCount, 0) AS 'POApprovedCount', ISNULL(@POFulfillmentCount, 0) AS 'POFulfillmentCount', 
		ISNULL(@ROOpenCount, 0) AS 'ROOpenCount', ISNULL(@ROApprovedCount, 0) AS 'ROApprovedCount', ISNULL(@ROFulfillmentCount, 0) AS 'ROFulfillmentCount', 
		ISNULL(@POOpenAmount, 0) AS 'POOpenAmount', ISNULL(@POApprovedAmount, 0) 'POApprovedAmount',
		ISNULL(@POFulfillmentAmount, 0) AS 'POFulfillmentAmount', ISNULL(@ROOpenAmount, 0) AS 'ROOpenAmount', ISNULL(@ROApprovedAmount, 0) AS 'ROApprovedAmount', ISNULL(@ROFulfillmentAmount, 0) AS 'ROFulfillmentAmount'
	END
	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
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