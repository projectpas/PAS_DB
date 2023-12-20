CREATE PROCEDURE [dbo].[GetSOSOQDashboardDataCount]
	@MasterCompanyId INT = 1,
	@EmployeeId BIGINT = 61,
	@Type varchar(50)
	--@IsInternal BIT,
	--@IsExternal BIT,
	--@IsAll BIT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    SET NOCOUNT ON

	BEGIN TRY
	BEGIN
		DECLARE @Qty AS INT;
		DECLARE @CustomerAffiliation varchar(20);
		IF(@Type = 'internal')
		BEGIN
			SET @CustomerAffiliation = '1';
		END
		ELSE IF(@Type = 'external')
		BEGIN
			SET @CustomerAffiliation = '2';
		END
		ELSE IF(@Type = 'all')
		BEGIN
			SET @CustomerAffiliation = '1,2,3';
		END
		ELSE
		BEGIN
			SET @CustomerAffiliation = '1,2,3';
		END

		DECLARE @SOQReceivedId AS INT =1
		DECLARE @SOQApprovedInternalId AS INT =2
		DECLARE @SOQApprovedCustomerId AS INT =3
		DECLARE @SOApprovedInternalId AS INT =1
		DECLARE @SOApprovedCustomerId AS INT =2
		DECLARE @SOFullfillingStatusId AS INT =10
		DECLARE @SOShippingStatusId AS INT =3
		DECLARE @SOInvoicedStatusId AS INT =3

		DECLARE @SOQReceivedCount AS INT =0
		DECLARE @SOQApprovedInternalCount AS INT =0
		DECLARE @SOQApprovedCustomerCount AS INT =0
		DECLARE @SOApprovedInternalCount AS INT =0
		DECLARE @SOApprovedCustomerCount AS INT =0
		DECLARE @SOFullfillingStatusCount AS INT =0
		DECLARE @SOShippingStatusCount AS INT =0
		DECLARE @SOInvoicedStatusCount AS INT =0

		DECLARE @SOQReceivedAmount AS DECIMAL(20, 2);
		DECLARE @SOQApprovedInternalAmount AS DECIMAL(20, 2);
		DECLARE @SOQApprovedCustomerAmount AS DECIMAL(20, 2);
		DECLARE @SOApprovedInternalAmount AS DECIMAL(20, 2);
		DECLARE @SOApprovedCustomerAmount AS DECIMAL(20, 2);
		DECLARE @SOFullfillingAmount AS DECIMAL(20, 2);
		DECLARE @SOShippingAmount AS DECIMAL(20, 2);
		DECLARE @SOInvoicedAmount AS DECIMAL(20, 2);
		DECLARE @SOQMSModuleID INT = 18;
		DECLARE @SOMSModuleID INT = 17;
			

		SELECT  @SOQReceivedCount=count(SOQ.SalesOrderQuoteId)  FROM 
				DBO.SalesOrderQuote SOQ 
				--INNER JOIN DBO.SalesOrderQuotePart SOQP ON SOQP.SalesOrderQuoteId = SOQ.SalesOrderQuoteId
			    INNER JOIN dbo.SalesOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @SOQMSModuleID AND MSD.ReferenceID = SOQ.SalesOrderQuoteId
			    INNER JOIN dbo.RoleManagementStructure RMS WITH (NOLOCK) ON SOQ.ManagementStructureId = RMS.EntityStructureId
			    INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId
				INNER JOIN dbo.Customer C WITH (NOLOCK) ON C.CustomerId = SOQ.CustomerId
				Where  (SOQ.IsDeleted = 0) and (SOQ.StatusId =@SOQReceivedId) AND C.CustomerAffiliationId IN (SELECT Item FROM DBO.SPLITSTRING(@CustomerAffiliation, ','))
				AND SOQ.MasterCompanyId = @MasterCompanyId
				GROUP BY SOQ.StatusId

		SELECT @SOQReceivedAmount = SUM(POP.NetSales) FROM 
				DBO.SalesOrderQuotePart POP INNER JOIN DBO.SalesOrderQuote PO ON PO.SalesOrderQuoteId = POP.SalesOrderQuoteId
				INNER JOIN dbo.SalesOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @SOQMSModuleID AND MSD.ReferenceID = PO.SalesOrderQuoteId
	            INNER JOIN dbo.RoleManagementStructure RMS WITH (NOLOCK) ON PO.ManagementStructureId = RMS.EntityStructureId
	            INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId
				INNER JOIN dbo.Customer C WITH (NOLOCK) ON C.CustomerId = PO.CustomerId
				Where  (PO.IsDeleted = 0) and (POP.IsDeleted = 0) and (PO.StatusId =@SOQReceivedId) AND C.CustomerAffiliationId IN (SELECT Item FROM DBO.SPLITSTRING(@CustomerAffiliation, ','))
				AND PO.MasterCompanyId = @MasterCompanyId
				GROUP BY PO.StatusId

	   SELECT  @SOQApprovedInternalCount=count(distinct PO.SalesOrderQuoteId)  FROM 
				DBO.SalesOrderQuote PO 
				INNER JOIN DBO.SalesOrderQuotePart SOQP ON SOQP.SalesOrderQuoteId = PO.SalesOrderQuoteId
				INNER JOIN dbo.SalesOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @SOQMSModuleID AND MSD.ReferenceID = PO.SalesOrderQuoteId
			    INNER JOIN dbo.RoleManagementStructure RMS WITH (NOLOCK) ON PO.ManagementStructureId = RMS.EntityStructureId
			    INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId
				INNER JOIN dbo.Customer C WITH (NOLOCK) ON C.CustomerId = PO.CustomerId
				INNER JOIN dbo.SalesOrderQuoteApproval SOQAP WITH (NOLOCK) ON SOQAP.SalesOrderQuotePartId = SOQP.SalesOrderQuotePartId AND SOQAP.InternalStatusId=4
				--Where  (PO.IsDeleted = 0) and (PO.IsEnforceApproval = 1) AND C.CustomerAffiliationId IN (SELECT Item FROM DBO.SPLITSTRING(@CustomerAffiliation, ','))
				Where  (PO.IsDeleted = 0) AND C.CustomerAffiliationId IN (SELECT Item FROM DBO.SPLITSTRING(@CustomerAffiliation, ','))
				AND PO.MasterCompanyId = @MasterCompanyId
				--GROUP BY PO.StatusId

	  SELECT @SOQApprovedInternalAmount = SUM(POP.NetSales)  FROM 
				DBO.SalesOrderQuotePart POP INNER JOIN DBO.SalesOrderQuote PO ON PO.SalesOrderQuoteId = POP.SalesOrderQuoteId
				INNER JOIN dbo.SalesOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @SOQMSModuleID AND MSD.ReferenceID = PO.SalesOrderQuoteId
	            INNER JOIN dbo.RoleManagementStructure RMS WITH (NOLOCK) ON PO.ManagementStructureId = RMS.EntityStructureId
	            INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId
				INNER JOIN dbo.Customer C WITH (NOLOCK) ON C.CustomerId = PO.CustomerId
				INNER JOIN dbo.SalesOrderQuoteApproval SOQAP WITH (NOLOCK) ON SOQAP.SalesOrderQuotePartId = POP.SalesOrderQuotePartId AND SOQAP.InternalStatusId=4
				--Where (PO.IsDeleted = 0) and (POP.IsDeleted = 0) and (PO.IsEnforceApproval = 1) AND C.CustomerAffiliationId IN (SELECT Item FROM DBO.SPLITSTRING(@CustomerAffiliation, ','))
				Where (PO.IsDeleted = 0) and (POP.IsDeleted = 0) AND C.CustomerAffiliationId IN (SELECT Item FROM DBO.SPLITSTRING(@CustomerAffiliation, ','))
				AND PO.MasterCompanyId = @MasterCompanyId
				--GROUP BY PO.StatusId

	 SELECT  @SOQApprovedCustomerCount=count(distinct PO.SalesOrderQuoteId)  FROM 
				DBO.SalesOrderQuote PO 
				INNER JOIN DBO.SalesOrderQuotePart SOQP ON SOQP.SalesOrderQuoteId = PO.SalesOrderQuoteId
				INNER JOIN dbo.SalesOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @SOQMSModuleID AND MSD.ReferenceID = PO.SalesOrderQuoteId
			    INNER JOIN dbo.RoleManagementStructure RMS WITH (NOLOCK) ON PO.ManagementStructureId = RMS.EntityStructureId
			    INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId
				INNER JOIN dbo.Customer C WITH (NOLOCK) ON C.CustomerId = PO.CustomerId
				INNER JOIN dbo.SalesOrderQuoteApproval SOQAP WITH (NOLOCK) ON SOQAP.SalesOrderQuotePartId = SOQP.SalesOrderQuotePartId AND SOQAP.CustomerStatusId=4
				--Where  (PO.IsDeleted = 0) and (PO.IsEnforceApproval = 0) AND C.CustomerAffiliationId IN (SELECT Item FROM DBO.SPLITSTRING(@CustomerAffiliation, ','))
				Where  (PO.IsDeleted = 0) AND C.CustomerAffiliationId IN (SELECT Item FROM DBO.SPLITSTRING(@CustomerAffiliation, ','))
				AND PO.MasterCompanyId = @MasterCompanyId
				--GROUP BY PO.StatusId

       SELECT @SOQApprovedCustomerAmount = SUM(POP.NetSales)  FROM 
				DBO.SalesOrderQuotePart POP INNER JOIN DBO.SalesOrderQuote PO ON PO.SalesOrderQuoteId = POP.SalesOrderQuoteId
				INNER JOIN dbo.SalesOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @SOQMSModuleID AND MSD.ReferenceID = PO.SalesOrderQuoteId
	            INNER JOIN dbo.RoleManagementStructure RMS WITH (NOLOCK) ON PO.ManagementStructureId = RMS.EntityStructureId
	            INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId
				INNER JOIN dbo.Customer C WITH (NOLOCK) ON C.CustomerId = PO.CustomerId
				INNER JOIN dbo.SalesOrderQuoteApproval SOQAP WITH (NOLOCK) ON SOQAP.SalesOrderQuotePartId = POP.SalesOrderQuotePartId AND SOQAP.CustomerStatusId=4
				--Where (PO.IsDeleted = 0) and (POP.IsDeleted = 0) and (PO.IsEnforceApproval = 0) AND C.CustomerAffiliationId IN (SELECT Item FROM DBO.SPLITSTRING(@CustomerAffiliation, ','))
				Where (PO.IsDeleted = 0) and (POP.IsDeleted = 0) AND C.CustomerAffiliationId IN (SELECT Item FROM DBO.SPLITSTRING(@CustomerAffiliation, ','))
				AND PO.MasterCompanyId = @MasterCompanyId
				--GROUP BY PO.StatusId

				
	   SELECT @SOApprovedInternalCount=count(distinct RO.SalesOrderId)  FROM 
			    DBO.SalesOrder RO
			   INNER JOIN DBO.SalesOrderPart SOP ON SOP.SalesOrderId = RO.SalesOrderId
			   INNER JOIN dbo.SalesOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @SOMSModuleID AND MSD.ReferenceID = RO.SalesOrderId
			   INNER JOIN dbo.RoleManagementStructure RMS WITH (NOLOCK) ON RO.ManagementStructureId = RMS.EntityStructureId
			   INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId
			   INNER JOIN dbo.Customer C WITH (NOLOCK) ON C.CustomerId = RO.CustomerId
			   INNER JOIN dbo.SalesOrderApproval SOAPR WITH (NOLOCK) ON SOAPR.SalesOrderPartId = SOP.SalesOrderPartId AND SOAPR.InternalStatusId=4
			   --Where (RO.IsDeleted = 0) and (RO.IsEnforceApproval = 0) AND C.CustomerAffiliationId IN (SELECT Item FROM DBO.SPLITSTRING(@CustomerAffiliation, ','))
			   Where (RO.IsDeleted = 0) AND C.CustomerAffiliationId IN (SELECT Item FROM DBO.SPLITSTRING(@CustomerAffiliation, ','))
			   AND RO.MasterCompanyId = @MasterCompanyId
			   --GROUP BY RO.StatusId

	   SELECT @SOApprovedInternalAmount = SUM(ROP.NetSales) FROM 
				DBO.SalesOrderPart ROP INNER JOIN DBO.SalesOrder RO ON RO.SalesOrderId = ROP.SalesOrderId
				INNER JOIN dbo.SalesOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @SOMSModuleID AND MSD.ReferenceID = ROP.SalesOrderId
	            INNER JOIN dbo.RoleManagementStructure RMS WITH (NOLOCK) ON RO.ManagementStructureId = RMS.EntityStructureId
	            INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId
				INNER JOIN dbo.Customer C WITH (NOLOCK) ON C.CustomerId = RO.CustomerId
				INNER JOIN dbo.SalesOrderApproval SOAPR WITH (NOLOCK) ON SOAPR.SalesOrderPartId = ROP.SalesOrderPartId AND SOAPR.InternalStatusId=4
				--Where (RO.IsDeleted = 0) and (ROP.IsDeleted = 0) and (RO.IsEnforceApproval = 0) AND C.CustomerAffiliationId IN (SELECT Item FROM DBO.SPLITSTRING(@CustomerAffiliation, ','))
				Where (RO.IsDeleted = 0) and (ROP.IsDeleted = 0) AND C.CustomerAffiliationId IN (SELECT Item FROM DBO.SPLITSTRING(@CustomerAffiliation, ','))
				AND RO.MasterCompanyId = @MasterCompanyId
				--GROUP BY RO.StatusId

	  SELECT @SOApprovedCustomerCount=count(distinct RO.SalesOrderId)  FROM 
			    DBO.SalesOrder RO
			   INNER JOIN DBO.SalesOrderPart SOP ON SOP.SalesOrderId = RO.SalesOrderId
			   INNER JOIN dbo.SalesOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @SOMSModuleID AND MSD.ReferenceID = RO.SalesOrderId
			   INNER JOIN dbo.RoleManagementStructure RMS WITH (NOLOCK) ON RO.ManagementStructureId = RMS.EntityStructureId
			   INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId
			   INNER JOIN dbo.Customer C WITH (NOLOCK) ON C.CustomerId = RO.CustomerId
			   INNER JOIN dbo.SalesOrderApproval SOAPR WITH (NOLOCK) ON SOAPR.SalesOrderPartId = SOP.SalesOrderPartId AND SOAPR.CustomerStatusId=4
				--Where (RO.IsDeleted = 0) and (RO.IsEnforceApproval = 1) AND C.CustomerAffiliationId IN (SELECT Item FROM DBO.SPLITSTRING(@CustomerAffiliation, ','))
				Where (RO.IsDeleted = 0) AND C.CustomerAffiliationId IN (SELECT Item FROM DBO.SPLITSTRING(@CustomerAffiliation, ','))
				AND RO.MasterCompanyId = @MasterCompanyId
				--GROUP BY RO.StatusId

	  SELECT @SOApprovedCustomerAmount = SUM(ROP.NetSales)  FROM 
				DBO.SalesOrderPart ROP INNER JOIN DBO.SalesOrder RO ON RO.SalesOrderId = ROP.SalesOrderId
				INNER JOIN dbo.SalesOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @SOMSModuleID AND MSD.ReferenceID = ROP.SalesOrderId
	            INNER JOIN dbo.RoleManagementStructure RMS WITH (NOLOCK) ON RO.ManagementStructureId = RMS.EntityStructureId
	            INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId
				INNER JOIN dbo.Customer C WITH (NOLOCK) ON C.CustomerId = RO.CustomerId
				INNER JOIN dbo.SalesOrderApproval SOAPR WITH (NOLOCK) ON SOAPR.SalesOrderPartId = ROP.SalesOrderPartId AND SOAPR.CustomerStatusId=4
				--Where (RO.IsDeleted = 0) and (ROP.IsDeleted = 0) and (RO.IsEnforceApproval = 1) AND C.CustomerAffiliationId IN (SELECT Item FROM DBO.SPLITSTRING(@CustomerAffiliation, ','))
				Where (RO.IsDeleted = 0) and (ROP.IsDeleted = 0) AND C.CustomerAffiliationId IN (SELECT Item FROM DBO.SPLITSTRING(@CustomerAffiliation, ','))
				AND RO.MasterCompanyId = @MasterCompanyId
				--GROUP BY RO.StatusId
	
	SELECT @SOFullfillingStatusCount=count(distinct RO.SalesOrderId)  FROM 
			    DBO.SalesOrder RO
			   INNER JOIN DBO.SalesOrderPart SOP ON SOP.SalesOrderId = RO.SalesOrderId
			   INNER JOIN dbo.SalesOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @SOMSModuleID AND MSD.ReferenceID = RO.SalesOrderId
			   INNER JOIN dbo.RoleManagementStructure RMS WITH (NOLOCK) ON RO.ManagementStructureId = RMS.EntityStructureId
			   INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId
			   INNER JOIN dbo.Customer C WITH (NOLOCK) ON C.CustomerId = RO.CustomerId
			   --LEFT JOIN DBO.SalesOrderShipping SOS WITH (NOLOCK) ON RO.SalesOrderId = SOS.SalesOrderId
			   --LEFT JOIN DBO.SalesOrderShippingItem SOSI WITH (NOLOCK) ON RO.SalesOrderId = SOS.SalesOrderId AND SOP.SalesOrderPartId = SOSI.SalesOrderPartId
			  -- OUTER APPLY
			  --  (
					--select count(distinct RO.SalesOrderId) as shippingcount from DBO.SalesOrder RO
					--INNER JOIN DBO.SalesOrderPart SOP ON SOP.SalesOrderId = RO.SalesOrderId
					--INNER JOIN dbo.SalesOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @SOMSModuleID AND MSD.ReferenceID = RO.SalesOrderId
					--INNER JOIN dbo.RoleManagementStructure RMS WITH (NOLOCK) ON RO.ManagementStructureId = RMS.EntityStructureId
					--INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId
					--INNER JOIN dbo.Customer C WITH (NOLOCK) ON C.CustomerId = RO.CustomerId
					--INNER JOIN DBO.SalesOrderShipping SOS WITH (NOLOCK) ON RO.SalesOrderId = SOS.SalesOrderId
					--INNER JOIN DBO.SalesOrderShippingItem SOSI WITH (NOLOCK) ON RO.SalesOrderId = SOS.SalesOrderId AND SOP.SalesOrderPartId = SOSI.SalesOrderPartId
					--Where (RO.IsDeleted = 0) and (RO.StatusId = @SOFullfillingStatusId) AND C.CustomerAffiliationId IN (SELECT Item FROM DBO.SPLITSTRING(@CustomerAffiliation, ','))
					--AND RO.MasterCompanyId = @MasterCompanyId
		   --     ) F
				Where (RO.IsDeleted = 0) and (RO.StatusId = @SOFullfillingStatusId) AND C.CustomerAffiliationId IN (SELECT Item FROM DBO.SPLITSTRING(@CustomerAffiliation, ','))
				AND RO.MasterCompanyId = @MasterCompanyId
				--GROUP BY RO.StatusId
				--GROUP BY F.shippingcount


	 SELECT @SOFullfillingAmount = SUM(ROP.NetSales)  FROM 
				DBO.SalesOrderPart ROP INNER JOIN DBO.SalesOrder RO ON RO.SalesOrderId = ROP.SalesOrderId
				--INNER JOIN DBO.SalesOrderPart SOP ON SOP.SalesOrderId = RO.SalesOrderId
				INNER JOIN dbo.SalesOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @SOMSModuleID AND MSD.ReferenceID = ROP.SalesOrderId
	            INNER JOIN dbo.RoleManagementStructure RMS WITH (NOLOCK) ON RO.ManagementStructureId = RMS.EntityStructureId
	            INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId
				INNER JOIN dbo.Customer C WITH (NOLOCK) ON C.CustomerId = RO.CustomerId
				--OUTER APPLY
			 --   (
				--	select SUM(SOP.NetSales) as shippingcount from DBO.SalesOrder RO
				--	INNER JOIN DBO.SalesOrderPart SOP ON SOP.SalesOrderId = RO.SalesOrderId
				--	INNER JOIN dbo.SalesOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @SOMSModuleID AND MSD.ReferenceID = RO.SalesOrderId
				--	INNER JOIN dbo.RoleManagementStructure RMS WITH (NOLOCK) ON RO.ManagementStructureId = RMS.EntityStructureId
				--	INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId
				--	INNER JOIN dbo.Customer C WITH (NOLOCK) ON C.CustomerId = RO.CustomerId
				--	INNER JOIN DBO.SalesOrderShipping SOS WITH (NOLOCK) ON RO.SalesOrderId = SOS.SalesOrderId
				--	INNER JOIN DBO.SalesOrderShippingItem SOSI WITH (NOLOCK) ON RO.SalesOrderId = SOS.SalesOrderId AND SOP.SalesOrderPartId = SOSI.SalesOrderPartId
				--	Where (RO.IsDeleted = 0) and (RO.StatusId = @SOFullfillingStatusId) AND C.CustomerAffiliationId IN (SELECT Item FROM DBO.SPLITSTRING(@CustomerAffiliation, ','))
				--	AND RO.MasterCompanyId = @MasterCompanyId
		  --      ) F
				Where (RO.IsDeleted = 0) and (ROP.IsDeleted = 0) and (RO.StatusId = @SOFullfillingStatusId) AND C.CustomerAffiliationId IN (SELECT Item FROM DBO.SPLITSTRING(@CustomerAffiliation, ','))
				AND RO.MasterCompanyId = @MasterCompanyId 
				--AND ROP.SalesOrderPartId NOT IN(select SalesOrderPartId From SalesOrderShippingItem)
				--GROUP BY RO.StatusId
				--GROUP BY F.shippingcount

	SELECT @SOShippingStatusCount=count(distinct RO.SalesOrderId)  FROM 
			    DBO.SalesOrder RO
			   INNER JOIN DBO.SalesOrderPart ROP WITH (NOLOCK) ON RO.SalesOrderId = ROP.SalesOrderId
			   --INNER JOIN DBO.SalesOrderShipping SOS WITH (NOLOCK) ON RO.SalesOrderId = SOS.SalesOrderId
			   --INNER JOIN DBO.SalesOrderShippingItem SOSI WITH (NOLOCK) ON RO.SalesOrderId = SOS.SalesOrderId AND ROP.SalesOrderPartId = SOSI.SalesOrderPartId
			   INNER JOIN DBO.SalesOrderApproval SOAPR WITH (NOLOCK) ON RO.SalesOrderId = SOAPR.SalesOrderId AND ROP.SalesOrderPartId = SOAPR.SalesOrderPartId AND SOAPR.CustomerStatusId=2
			   INNER JOIN dbo.SalesOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @SOMSModuleID AND MSD.ReferenceID = RO.SalesOrderId
			   INNER JOIN dbo.RoleManagementStructure RMS WITH (NOLOCK) ON RO.ManagementStructureId = RMS.EntityStructureId
			   INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId
			   INNER JOIN dbo.Customer C WITH (NOLOCK) ON C.CustomerId = RO.CustomerId
				Where (RO.IsDeleted = 0 AND RO.StatusId != 2)
				AND RO.MasterCompanyId = @MasterCompanyId AND C.CustomerAffiliationId IN (SELECT Item FROM DBO.SPLITSTRING(@CustomerAffiliation, ','))
				--AND RO.SalesOrderId NOT IN(select SalesOrderId From SalesOrderBillingInvoicing)
				--AND RO.SalesOrderId NOT IN(select SOB.SalesOrderId From SalesOrderBillingInvoicing SOB INNER JOIN SalesOrderBillingInvoicingItem SOBI
				--ON SOBI.SalesOrderPartId = SOSI.SalesOrderPartId)
				AND ROP.SalesOrderPartId NOT IN(select SalesOrderPartId From SalesOrderShippingItem)
				--GROUP BY RO.StatusId


	 SELECT @SOShippingAmount = SUM(ROP.NetSales)  FROM 
				DBO.SalesOrder RO INNER JOIN DBO.SalesOrderPart ROP ON RO.SalesOrderId = ROP.SalesOrderId
				--INNER JOIN DBO.SalesOrderShipping SOS WITH (NOLOCK) ON RO.SalesOrderId = SOS.SalesOrderId
			    --INNER JOIN DBO.SalesOrderShippingItem SOSI WITH (NOLOCK) ON RO.SalesOrderId = SOS.SalesOrderId AND ROP.SalesOrderPartId = SOSI.SalesOrderPartId
				--INNER JOIN DBO.SalesOrderShippingItem SOSI WITH (NOLOCK) ON RO.SalesOrderId = SOS.SalesOrderId AND SOS.SalesOrderShippingId = SOSI.SalesOrderShippingId AND ROP.SalesOrderPartId = SOSI.SalesOrderPartId
				INNER JOIN DBO.SalesOrderApproval SOAPR WITH (NOLOCK) ON RO.SalesOrderId = SOAPR.SalesOrderId AND ROP.SalesOrderPartId = SOAPR.SalesOrderPartId AND SOAPR.CustomerStatusId=2
				INNER JOIN dbo.SalesOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @SOMSModuleID AND MSD.ReferenceID = ROP.SalesOrderId
	            INNER JOIN dbo.RoleManagementStructure RMS WITH (NOLOCK) ON RO.ManagementStructureId = RMS.EntityStructureId
	            INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId
				INNER JOIN dbo.Customer C WITH (NOLOCK) ON C.CustomerId = RO.CustomerId
				Where (RO.IsDeleted = 0) and (ROP.IsDeleted = 0) AND RO.StatusId != 2
				AND RO.MasterCompanyId = @MasterCompanyId AND C.CustomerAffiliationId IN (SELECT Item FROM DBO.SPLITSTRING(@CustomerAffiliation, ','))
				--AND RO.SalesOrderId NOT IN(select SOB.SalesOrderId From SalesOrderBillingInvoicing SOB INNER JOIN SalesOrderBillingInvoicingItem SOBI
				--ON SOBI.SalesOrderPartId = SOSI.SalesOrderPartId)
				AND ROP.SalesOrderPartId NOT IN(select SalesOrderPartId From SalesOrderShippingItem)
				--GROUP BY RO.StatusId

	SELECT @SOInvoicedStatusCount=count(distinct RO.SalesOrderId)  FROM 
			    DBO.SalesOrder RO
			   INNER JOIN DBO.SalesOrderPart ROP WITH (NOLOCK) ON RO.SalesOrderId = ROP.SalesOrderId
			   --INNER JOIN DBO.SalesOrderBillingInvoicing SOS WITH (NOLOCK) ON RO.SalesOrderId = SOS.SalesOrderId
			   INNER JOIN DBO.SalesOrderShipping SOS WITH (NOLOCK) ON RO.SalesOrderId = SOS.SalesOrderId
			   INNER JOIN DBO.SalesOrderShippingItem SOSI WITH (NOLOCK) ON RO.SalesOrderId = SOS.SalesOrderId AND ROP.SalesOrderPartId = SOSI.SalesOrderPartId
			   --INNER JOIN DBO.SalesOrderBillingInvoicingItem SOSI WITH (NOLOCK) ON RO.SalesOrderId = SOS.SalesOrderId AND ROP.SalesOrderPartId = SOSI.SalesOrderPartId
			   INNER JOIN dbo.SalesOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @SOMSModuleID AND MSD.ReferenceID = RO.SalesOrderId
			   INNER JOIN dbo.RoleManagementStructure RMS WITH (NOLOCK) ON RO.ManagementStructureId = RMS.EntityStructureId
			   INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId
			   INNER JOIN dbo.Customer C WITH (NOLOCK) ON C.CustomerId = RO.CustomerId
				Where (RO.IsDeleted = 0)
				AND RO.MasterCompanyId = @MasterCompanyId AND C.CustomerAffiliationId IN (SELECT Item FROM DBO.SPLITSTRING(@CustomerAffiliation, ','))
				AND ROP.SalesOrderPartId NOT IN(select SalesOrderPartId From SalesOrderBillingInvoicingItem)
				--GROUP BY RO.StatusId


	 SELECT @SOInvoicedAmount = SUM(ROP.NetSales)  FROM 
				DBO.SalesOrderPart ROP INNER JOIN DBO.SalesOrder RO ON RO.SalesOrderId = ROP.SalesOrderId
				--INNER JOIN DBO.SalesOrderBillingInvoicing SOS WITH (NOLOCK) ON RO.SalesOrderId = SOS.SalesOrderId
			 --   INNER JOIN DBO.SalesOrderBillingInvoicingItem SOSI WITH (NOLOCK) ON RO.SalesOrderId = SOS.SalesOrderId AND ROP.SalesOrderPartId = SOSI.SalesOrderPartId AND SOS.SOBillingInvoicingId = SOSI.SOBillingInvoicingId
				--INNER JOIN DBO.SalesOrderShipping SOS WITH (NOLOCK) ON RO.SalesOrderId = SOS.SalesOrderId
			    INNER JOIN DBO.SalesOrderShippingItem SOSI WITH (NOLOCK) ON ROP.SalesOrderPartId = SOSI.SalesOrderPartId
				INNER JOIN dbo.SalesOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @SOMSModuleID AND MSD.ReferenceID = ROP.SalesOrderId
	            INNER JOIN dbo.RoleManagementStructure RMS WITH (NOLOCK) ON RO.ManagementStructureId = RMS.EntityStructureId
	            INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId
				INNER JOIN dbo.Customer C WITH (NOLOCK) ON C.CustomerId = RO.CustomerId
				Where (RO.IsDeleted = 0) and (ROP.IsDeleted = 0)
				AND RO.MasterCompanyId = @MasterCompanyId AND C.CustomerAffiliationId IN (SELECT Item FROM DBO.SPLITSTRING(@CustomerAffiliation, ','))
				AND ROP.SalesOrderPartId NOT IN(select SalesOrderPartId From SalesOrderBillingInvoicingItem)
				--GROUP BY RO.StatusId

		SELECT ISNULL(@SOQReceivedCount, 0) AS 'SOQReceivedCount', ISNULL(@SOQApprovedInternalCount, 0) AS 'SOQApprovedInternalCount', ISNULL(@SOQApprovedCustomerCount, 0) AS 'SOQApprovedCustomerCount', 
		ISNULL(@SOApprovedInternalCount, 0) AS 'SOApprovedInternalCount', ISNULL(@SOApprovedCustomerCount, 0) AS 'SOApprovedCustomerCount', ISNULL(@SOFullfillingStatusCount, 0) AS 'SOFullfillingStatusCount',
		 ISNULL(@SOShippingStatusCount, 0) AS 'SOShippingStatusCount', ISNULL(@SOInvoicedStatusCount, 0) AS 'SOInvoicedStatusCount',
		ISNULL(@SOQReceivedAmount, 0) AS 'SOQReceivedAmount',
		--ISNULL(@SOQReceivedAmount, 0) 'SOQReceivedAmount',
		ISNULL(@SOQApprovedInternalAmount, 0) AS 'SOQApprovedInternalAmount', ISNULL(@SOQApprovedCustomerAmount, 0) AS 'SOQApprovedCustomerAmount',
		ISNULL(@SOApprovedInternalAmount, 0) AS 'SOApprovedInternalAmount',ISNULL(@SOApprovedCustomerAmount, 0) AS 'SOApprovedCustomerAmount',
		ISNULL(@SOFullfillingAmount, 0) AS 'SOFullfillingAmount',ISNULL(@SOShippingAmount, 0) AS 'SOShippingAmount',ISNULL(@SOInvoicedAmount, 0) AS 'SOInvoicedAmount'
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